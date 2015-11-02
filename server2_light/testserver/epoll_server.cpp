/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：epoll_server
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.5
// 模块描述：epoll 相关。
//----------------------------------------------------------------*/

#include "epoll_server.h"
#include "net_util.h"
#include "util.h"
#include "world.h"


using mogo::LogDebug;


CEpollServer::CEpollServer() : m_epfd(0), m_fds(), the_world(NULL), m_unMailboxId(0), m_bShutdown(false)
{

}


CEpollServer::~CEpollServer()
{

}

int CEpollServer::StartServer(const char* pszAddr, uint16_t unPort)
{
    m_strAddr.assign(pszAddr);
    m_unPort = unPort;

    int fd = MogoSocket();
    if(fd == -1)
    {
        ERROR_RETURN2("Failed to create socket");
    }

    MogoSetNonblocking(fd);

    int n = MogoBind(fd, pszAddr, unPort);
    if(n != 0)
    {
        ERROR_RETURN2("Failed to bind");
    }

    n = MogoListen(fd);
    if(n != 0)
    {
        ERROR_RETURN2("Failed to listen");
    }

    m_epfd = epoll_create(MAX_EPOLL_SIZE);
    if(m_epfd == -1)
    {
        ERROR_RETURN2("Failed to epoll_create");
    }

    struct epoll_event ev;
    //ev.events = EPOLLIN | EPOLLOUT | EPOLLET;
	ev.events = EPOLLIN | EPOLLOUT;
    ev.data.fd = fd;

    if(epoll_ctl(m_epfd, EPOLL_CTL_ADD, fd, &ev) == -1)
    {
        ERROR_RETURN2("Failed to epoll_ctl_add listen fd");
    }

    AddFdAndMb(fd, FD_TYPE_SERVER, pszAddr, unPort);

    LogDebug("start_server", "%s:%d,success.", m_strAddr.c_str(), m_unPort);
    return 0;
}

int CEpollServer::ConnectMailboxs(const char* pszCfgFile)
{
    list<CMailBox*>& mbs = GetWorld()->GetMbMgr().GetMailboxs();

    //todo,这里还要修改一下
    //m_serverMbs.reserve(mbs.size());
    m_serverMbs.reserve(SERVER_MAILBOX_RESERVE_SIZE);
    for(int i=0;i<SERVER_MAILBOX_RESERVE_SIZE;++i)
    {
        m_serverMbs.push_back(NULL);
    }

    ////printf("mbs.size()=%d\n", mbs.size());

    list<CMailBox*>::iterator iter = mbs.begin();
    for(; iter != mbs.end(); ++iter)
    {
        CMailBox* pmb = *iter;
        if(m_unMailboxId == pmb->GetMailboxId())
        {
            continue;
            ////printf("this mail box is self!\n");
        }

        m_serverMbs[pmb->GetMailboxId()] = pmb;
        ////printf("111_get_server_mailbox:%x\n", get_server_mailbox(pmb->get_mailbox_id()));

        int nRet = pmb->ConnectServer(m_epfd);
        if(nRet != 0)
        {
            return nRet;
        }

        AddFdAndMb(pmb->GetFd(), pmb);

        LogDebug("try_to_connect_mailbox", "server=%s;port=%d", 
            pmb->GetServerName().c_str(), pmb->GetServerPort());
    }

    ////printf("get_server_mailbox:%x\n", get_server_mailbox(3));

    return 0;
}

int CEpollServer::Service(const char* pszAddr, unsigned int unPort)
{
    int nRet = StartServer(pszAddr, unPort);
    if(nRet != 0)
    {
        return nRet;
    }

    nRet = ConnectMailboxs("");
    if(nRet != 0)
    {
        return nRet;
    }

    //call lua
   // GetWorld()->OnServerReady();

    struct epoll_event ev;
    struct epoll_event events[MAX_EPOLL_SIZE];

	enum { _EPOLL_TIMEOUT = 100, };

#ifdef _MYPROF
	CGetTimeOfDay time_prof;
#endif

    while (!m_bShutdown) 
    {
        int event_count = m_fds.size();
        int nfds = epoll_wait(m_epfd, events, event_count, _EPOLL_TIMEOUT);
        ////printf("epoll to wait in Service!\n");
        if (nfds == -1)
        {
            ERROR_RETURN2("Failed to epoll_wait");
            break;
        }
        else if(nfds == 0)
        {
            //timeout
            this->HandleTimeout();
        }

#ifdef _MYPROF
		int nTimeEpoll = time_prof.GetLapsedTime();
#endif

        for (int n = 0; n < nfds; ++n)
        {
            int fd = events[n].data.fd;
            CMailBox* mb = GetFdMailbox(fd);
            if(mb == NULL)
            {
                //todo
                continue;
            }
            EFDTYPE tfd = mb->GetFdType();

            //printf("nfds=%d,fd=%d\n", nfds, fd);

            //FD types define in file rpc_mogo.h
                     
            switch(tfd)
            {   
                case FD_TYPE_SERVER://1
                {   
                    //printf("handle new connection in Service! : start!\n");
                    int _nRet = HandleNewConnection(fd);
                    
                    if(_nRet == 0)
                    {
                        ++event_count;
                    }
                    //printf("handle new connection in Service! : end!\n");
                    break;
                }
                case FD_TYPE_ACCEPT://3
                {
                     
                    //printf("handle fd event in Service! : start!\n");
                    if(this->HandleFdEvent(fd, events[n].events, mb) != 0)
                    {
                        //--event_count;
                    }
                    //printf("handle fd event in Service! : end!\n");
                    break;
                }
                case FD_TYPE_MAILBOX://2
                {
                    //printf("Handle Mail box Event in Service! : start!\n");
                    if(this->HandleMailboxEvent(fd, events[n].events, mb) != 0)
                    {
                        //--event_count;
                    }
                    //printf("Handle Mail box Event in Service! : start!\n");
                    break;
                }
                default:
                {
                    //FD_TYPE_ERROR
                    break;
                }
            }

        }

#ifdef _MYPROF
		int nTimeEvent = time_prof.GetLapsedTime();
#endif

        //处理包
        this->HandlePluto();

#ifdef _MYPROF
		int nTimeHdlRecv = time_prof.GetLapsedTime();
#endif

        //发送响应包
        this->HandleSendPluto();

#ifdef _MYPROF
		int nTimeHdlSend = time_prof.GetLapsedTime();
#endif

        //
        this->HandleMailboxReconnect();

#ifdef _MYPROF
		LogInfo("time_prof_1", "epoll=%d;event=%d;recv=%d;send=%d", nTimeEpoll, nTimeEvent, nTimeHdlRecv, nTimeHdlSend);
#endif


    }

	OnShutdownServer();

    return 0;
}

void CEpollServer::OnShutdownServer()
{
	LogInfo("goto_shutdown", "shutdown after 2 seconds.");
	sleep(2);
}

int CEpollServer::HandleNewConnection(int fd)
{
    //printf("handle fd in HandleNewConnection(): start!\n");
    struct sockaddr_in their_addr;
    socklen_t their_len = sizeof(their_addr);
    int new_fd = accept(fd, (struct sockaddr *) &their_addr, &their_len);
    if (new_fd < 0)
    {
        if(errno == EAGAIN)
        {
            ERROR_PRINT2("Failed to accept new connection,try EAGAIN\n")
            return -1;
        }
        else
        {
            ERROR_PRINT2("Failed to accept new connection")
            return -2;
        }
    } 
    
    char* pszClientAddr = inet_ntoa(their_addr.sin_addr);
    uint16_t unClientPort = ntohs(their_addr.sin_port);
    LogInfo("new_connection", "connected from %s:%d, assigned socket is:%d", pszClientAddr, unClientPort, new_fd);

    MogoSetNonblocking(new_fd);
    struct epoll_event ev;
    ev.events = EPOLLIN | EPOLLET;
    ev.data.fd = new_fd;
    if (epoll_ctl(m_epfd, EPOLL_CTL_ADD, new_fd, &ev) < 0) 
    {
        ERROR_PRINT2("Failed to epoll_ctl_add new accepted socket");
        return -3;
    }
    //printf("handle client connection: start!\n");
    this->OnNewFdAccepted(new_fd, their_addr);
    //printf("handle client connection: end!\n");
    //printf("handle fd in HandleNewConnection(): end!\n");
    return 0;
}

int CEpollServer::HandleMailboxEvent(int fd, uint32_t event, CMailBox* pmb)
{
    //CMailBox* pmb = getFdMailbox(fd);
    //printf("handle fd in HandleMailboxEvent(): start!\n");
    if(pmb != NULL)
    {
        if(!pmb->IsConnected())
        {
            int nConnErr = 0;
            socklen_t _tl = sizeof(nConnErr);
            //可写之后判断
            if(getsockopt(fd, SOL_SOCKET, SO_ERROR, &nConnErr, &_tl) == 0)
            {
                if(nConnErr == 0)
                {
                    pmb->SetConnected();
                    LogInfo("connected_2_mb", "mb %d connected", fd);
                }
                else
                {
                    LogInfo("connect_2_mb", "connect %s:%d error:%d,%s", pmb->GetServerName().c_str(),
                        pmb->GetServerPort(), nConnErr, strerror(nConnErr));


                    RemoveFd(fd);
                    //int nRet = pmb->ConnectServer(m_epfd);
                    //if(nRet != 0)
                    //{
                    //    return nRet;
                    //}
                    //addFdAndMb(pmb->GetFd(), pmb);

                    //ERROR_PRINT2("reconncet");

                    return 0;
                }
            }
            else
            {
                return -2;
            }
        }

        if(event & EPOLLIN)
        {
            return this->HandleFdEvent(fd, event, pmb);
        }
        else
        {
            return 0;
        }
    }

    //todo,assert??
	//如果服务器的某一个进程退出之后,是否需要关闭所有服务器进程
    //printf("handle fd in HandleMailboxEvent(): end!\n");
    return -1;
}

int CEpollServer::HandleFdEvent(int fd, uint32_t event, CMailBox* mb)
{
    ////printf("event:%d\n", event);
    //printf("handle fd event in HandleFdEvent()! : start!\n");
    int ret = this->HandleMessage(fd, mb);
    //if (ret < 1 && errno != EAGAIN) 
	if(ret < 0)
    {
        this->OnFdClosed(fd);
        epoll_ctl(m_epfd, EPOLL_CTL_DEL, fd, NULL);
        RemoveFd(fd);
        return -1;
    }
    //printf("handle fd event in HandleFdEvent()! : end!\n");
    return 0;
}

//服务器主动关闭一个socket
void CEpollServer::CloseFdFromServer(int fd)
{
	this->OnFdClosed(fd);
	::close(fd);
	epoll_ctl(m_epfd, EPOLL_CTL_DEL, fd, NULL);
	RemoveFd(fd);
}

//顶掉一个连接
void CEpollServer::KickoffFd(int fd)
{
	epoll_ctl(m_epfd, EPOLL_CTL_DEL, fd, NULL);
	RemoveFd(fd);
	::close(fd);
}

//连接其他服务器mailbox会直接调用这个方法
void CEpollServer::AddFdAndMb(int fd, CMailBox* pmb)
{
    //printf("handle fd in AddFdAndMb(): start!\n");
    pmb->SetFd(fd);

	map<int, CMailBox*>::iterator iter = m_fds.lower_bound(fd);
	if(iter != m_fds.end() && iter->first == fd)
	{
		//异常情况,有一个老的mb未删除		
		CMailBox* p2 = iter->second;
		iter->second = pmb;
		delete p2;
		LogWarning("CEpollServer::addFdAndMb_err", "desc=old_fd_mb;fd=%d", fd);
	}
	else
	{
		//正常情况
		m_fds.insert(iter, make_pair(fd, pmb));
	}
    
    LogDebug("CEpollServer::addFdAndMb", "fd=%d;fd_type=%d;addr=%s;port=%d;authz=%d", fd,\
        pmb->GetFdType(), pmb->GetServerName().c_str(), pmb->GetServerPort(), pmb->GetAuthz());
    //printf("handle fd in AddFdAndMb(): start!\n");
}

//来自客户端的连接会直接调用这个方法
void CEpollServer::AddFdAndMb(int fd, EFDTYPE efd, const char* pszAddr, uint16_t unPort)
{
    CMailBox* pmb = new CMailBox(0, efd, pszAddr, unPort);

    //来自可信任客户端地址的连接,免认证
    if(this->GetWorld()->IsTrustedClient(pmb->GetServerName()))
    {
        pmb->SetAuthz(MAILBOX_CLIENT_TRUSTED);
    }

    //设置已连接标记
    pmb->SetConnected();

    AddFdAndMb(fd, pmb);
}

void CEpollServer::RemoveFd(int fd)
{
    //printf("handle fd in RemoveFd(): start!\n");
    map<int, CMailBox*>::iterator iter = m_fds.find(fd);
	if(iter == m_fds.end())
	{
		return;
	}

    CMailBox* pmb = iter->second;
    m_fds.erase(iter);

    ////printf("%s:%d,%x\n", __FILE__, __LINE__, pmb);
    LogDebug("CEpollServer::removeFd", "fd=%d;fd_type=%d;addr=%s;port=%d", fd,\
        pmb->GetFdType(), pmb->GetServerName().c_str(), pmb->GetServerPort());

    if(pmb->GetFdType() == FD_TYPE_ACCEPT)
    {
        delete pmb;
    }
    else if (pmb->GetFdType() == FD_TYPE_MAILBOX)
    {
        ////printf("%s:%d,%x\n", __FILE__, __LINE__, pmb);
        int nRet = pmb->ConnectServer(m_epfd);
        if(nRet != 0)
        {
            m_mb4reconn.push_back(pmb);
            return;
        }
        AddFdAndMb(pmb->GetFd(), pmb);
        //ERROR_PRINT2("reconnect");
		//LogInfo("reconnect", "file=%s,line=%d,errno=%d,err=%s", __FILE__, __LINE__, errno, strerror(errno));
    }
    //printf("handle fd in RemoveFd(): end!\n");
}

int CEpollServer::HandleMailboxReconnect()
{
    ////printf("handle fd in HandleMailboxReconnect(): start!\n");
    if(m_mb4reconn.empty())
    {
        return 0;
    }

    for(int i = (int)m_mb4reconn.size()-1; i >= 0; --i)
    {
        CMailBox* pmb = m_mb4reconn[i];
        int nRet = pmb->ConnectServer(m_epfd);
        if(nRet == 0)
        {
            m_mb4reconn.erase(m_mb4reconn.begin()+i);
            AddFdAndMb(pmb->GetFd(), pmb);
        }
    }
   //  //printf("handle fd in HandleMailboxReconnect(): end!\n");
    return 0;
}

EFDTYPE CEpollServer::GetFdType(int fd)
{
    map<int, CMailBox*>::const_iterator iter = m_fds.find(fd);
    if(iter == m_fds.end())
    {
        return FD_TYPE_ERROR;
    }
    else
    {
        return iter->second->GetFdType();
    }
}

CMailBox* CEpollServer::GetFdMailbox(int fd)
{
    map<int, CMailBox*>::const_iterator iter = m_fds.find(fd);
    if(iter == m_fds.end())
    {
        return NULL;
    }
    else
    {
        return iter->second;
    }
}

int CEpollServer::OnNewFdAccepted(int new_fd, sockaddr_in& addr)
{
    //printf("handle fd in OnNewFdAccepted(): start!\n");
    char* pszClientAddr = inet_ntoa(addr.sin_addr);
    uint16_t unClientPort = ntohs(addr.sin_port);

    AddFdAndMb(new_fd, FD_TYPE_ACCEPT, pszClientAddr, unClientPort);
    ////printf("on_new_fd_accepted\n");
    //printf("handle fd in OnNewFdAccepted(): end!\n");
    return 0;
}

int CEpollServer::OnFdClosed(int fd)
{
    LogInfo("on_fd_closed", "fd=%d", fd);
	the_world->OnFdClosed(fd);
    return 0;
}

int CEpollServer::HandleTimeout()
{
    ////printf("handle fd in HandleTimeout(): start!\n");
    time_t now_time = time(NULL);
    ////printf("handle_timeout:%d\n", now_time);

    map<int, CMailBox*>::iterator iter = m_fds.begin();
    for(; iter != m_fds.end(); ++iter)
    {
        CMailBox* p = iter->second;
        if(p->m_lastTickTime + p->m_timeout < now_time)
        {
            //TODO:先忽略连接超时处理
            ////printf("timeout:%d\n", iter->first);
        }
    }
    ////printf("handle fd in HandleTimeout(): end!\n");
    return 0;
}

#ifdef _USE_RECV_BUFF
int CEpollServer::HandleMessage(int fd, CMailBox* mb)
{
    //TODO:收到消息后刷新上一次收到消息的时间
    //TODO:每一个连接的流量控制
    //printf("handle fd in HandleMessage(): start!\n");
    uint16_t nLeft = mb->GetRecvBuffLen();
    char* szBuff = mb->GetRecvBuff();

	enum{ _MAILBOX_RECV_BUFF_SIZE2 = MAILBOX_RECV_BUFF_SIZE - 10, };
	int nRecvWant = _MAILBOX_RECV_BUFF_SIZE2-nLeft;
    int nLen = ::recv(fd, szBuff+nLeft, nRecvWant, 0);
    if(nLen > 0)
    {
        ////printf("%d recved:'%s'，%d\n",fd, szBuff+nLeft, nLen);
        LogInfo("handle_message", "fd=%d;left=%d;recved=%d bytes",fd, nLeft, nLen);
        //print_hex(szBuff, nLen + nLeft);

        uint16_t nBuffSize = 0;
        uint16_t nBeginIndex = 0;
        for(;;)
        {
            nBuffSize = nLeft + (uint16_t)nLen - nBeginIndex;
            if(nBuffSize < PLUTO_MSGLEN_HEAD)
            {
                break;
            }
            uint32_t nMsgLen = sz_to_uint32((unsigned char*)szBuff + nBeginIndex);
			if(nMsgLen < PLUTO_FILED_BEGIN_POS)
			{
				LogWarning("handle_message_err", "message length err,size=%d,min=%d", nMsgLen, PLUTO_FILED_BEGIN_POS);
				close(fd);
				return -2;
			}
            if(nMsgLen > _MAILBOX_RECV_BUFF_SIZE2)
            {
                LogWarning("handle_message_err", "too long message,size=%d,max=%d", nMsgLen, _MAILBOX_RECV_BUFF_SIZE2);
                close(fd);
                return -3;
            }
            if(nBuffSize < nMsgLen)
            {
                break;
            }

            //print_hex(szBuff, nMsgLen);
            ////printf("%d\n", nMsgLen);
            CPluto* c = new CPluto(szBuff+nBeginIndex, nMsgLen);
            c->SetMailbox(mb);
            AddRecvMsg(c);        //增加一个方法,以便不同的接收队列的处理
            //m_recvMsgs.push_back(c);
            //print_hex_pluto(*c);

            nBeginIndex += nMsgLen;
            //break;
        }

        if(nBuffSize == 0)
        {
            //hasn't left buff
            mb->SetRecvBuffLen(0);
        }
        else
        {
            //has left buff
            mb->SetRecvBuffLen(nBuffSize);
            if(nBeginIndex > 0)
            {
                memmove(szBuff, szBuff+nBeginIndex, nBuffSize);
            }
        }

		//接受到的字节数和已经收到的相等,可能还有剩余的数据
		if(nLen == nRecvWant)
		{
			LogWarning("handle_message", "recv full.%d", nLen);
			return HandleMessage(fd, mb);
		}
        //printf("handle fd in HandleMessage(): waiting for nexting!\n");
        return nLen;
    }

    if(nLen == 0)
    {
        ////printf("client close\n");
    }
    else //if(nLen < 0)
    {
        LogWarning("handle_message_err", "failed, %d,'%s'",errno, strerror(errno));
        if(errno == EAGAIN)
        {
            return 0;
        }
    }
    //printf("handle fd in HandleMessage(): end!\n");
    close(fd);
    return -1;
}
#else

//检查包头长度是否合理,预防客户端设定一个很大的包头长度来进行攻击
#define PLUTO_HEAD_SIZE_CHECK(fd, mb, nMsgLen) \
{\
	if(nMsgLen < PLUTO_FILED_BEGIN_POS)\
	{\
		LogWarning("handle_message_err", "message_length_err,size=%d,min=%d", nMsgLen, PLUTO_FILED_BEGIN_POS);\
		close(fd);\
		return -2;\
	}\
	\
	if(mb->GetAuthz() != MAILBOX_CLIENT_TRUSTED)\
	{\
		if(nMsgLen > PLUTO_CLIENT_MSGLEN_MAX)\
		{\
			LogWarning("handle_message_err", "max_message_length,size=%d,max=%d", nMsgLen, PLUTO_CLIENT_MSGLEN_MAX);\
			close(fd);\
			return -3;\
		}\
	}\
}

//直接接收数据至pluto,不需要先接收到buff再copy
int CEpollServer::HandleMessage(int fd, CMailBox* mb)
{
	//errno = 0;
    //printf("handle fd event in HandleMessage()! : start!\n");
	int nLen = -1;
	CPluto* u = mb->GetRecvPluto();
    /*
        if the pluto is null that indicated new data has recived
    */
	if(u == NULL)
	{
		//新包
		//接收包头
        //printf("HandleMessage() new  message head! u == NULL !\n");
		char szHead[PLUTO_MSGLEN_HEAD];//PLUTO_MSGLEN_HEAD = 4
		nLen = ::recv(fd, szHead, PLUTO_MSGLEN_HEAD, 0);
		//LogDebug("hdm_recv1", "fd=%d;want=%d;recv=%d", fd, PLUTO_MSGLEN_HEAD, nLen);
		if(nLen > 0)
		{
			if(nLen == PLUTO_MSGLEN_HEAD)
			{   
                //printf("message head length: %d \n", nLen);
                //sz_to_uint32 function convert the binary stream to  unsigned int
				uint32_t nMsgLen = sz_to_uint32((unsigned char*)szHead);
                //printf("message length: %d\n", nMsgLen );
                
				PLUTO_HEAD_SIZE_CHECK(fd, mb, nMsgLen);

				u = new CPluto(nMsgLen);

				//copy head
				char* szBuff = u->GetRecvBuff();
				memcpy(szBuff, szHead, PLUTO_MSGLEN_HEAD);
               
				//nMsgLen includes the 4 bytes for PLUTO_MSGLEN_HEAD
				int nWanted = nMsgLen-PLUTO_MSGLEN_HEAD;
				nLen = ::recv(fd, szBuff+PLUTO_MSGLEN_HEAD, nWanted, 0);
				//LogDebug("hdm_recv2", "fd=%d;want=%d;recv=%d", fd, nWanted, nLen);
                //printf("message body recived length : %d nWanted : %d \n", nLen, nWanted);
				if(nLen > 0)
				{
					if(nLen == nWanted)
					{
						//接收完整
						u->EndRecv(nMsgLen);
						u->SetMailbox(mb);
						AddRecvMsg(u);

						////printf("recv all\n");
						//print_hex_pluto(*u);
						//可能还有其他包要收
                        //printf("HandleMessage() new  message body recived over !\n");
						return HandleMessage(fd, mb);
					}
					else
					{
                        //printf("HandleMessage() new  message body recived uncomplete!\n");
						//接收不完整,留到下次接着处理
						u->SetLen(PLUTO_MSGLEN_HEAD+nLen);
						mb->SetRecvPluto(u);

						//print_hex_pluto(*u);
						////printf("recv part11\n");
						return PLUTO_MSGLEN_HEAD+nLen;
					}					
				}
			}
			else
			{   
                //printf("HandleMessage() new  message head recived uncomplete!\n");
				//包头没有接收完
				u = new CPluto(PLUTO_MSGLEN_HEAD);
				char* szBuff = u->GetRecvBuff();
				memcpy(szBuff, szHead, nLen);
				u->SetLen(nLen);
				mb->SetRecvPluto(u);

				//print_hex_pluto(*u);
			    ////printf("recv part22\n");
				return nLen;
			}
		}
	}
	else
	{
        //printf("HandleMessage() continue to recive new  message head!\n");
		char* szBuff = u->GetRecvBuff();
		int nLastLen = u->GetLen();		//上次接收到的数据长度
		if(nLastLen < PLUTO_MSGLEN_HEAD)
		{
			//包头未收完
			int nWanted = PLUTO_MSGLEN_HEAD - nLastLen;
			nLen = ::recv(fd, szBuff+nLastLen, nWanted, 0);
			//LogDebug("hdm_recv3", "fd=%d;want=%d;recv=%d", fd, nWanted, nLen);
			if(nLen > 0)
			{
				if(nLen == nWanted)
				{   
                    //printf("HandleMessage() new  message head recived over!\n");
					int nMsgLen = sz_to_uint32((unsigned char*)szBuff);
					PLUTO_HEAD_SIZE_CHECK(fd, mb, nMsgLen);

					CPluto* u2 = new CPluto(nMsgLen);
					memcpy(u2->GetRecvBuff(), szBuff, PLUTO_MSGLEN_HEAD);
					u2->SetLen(PLUTO_MSGLEN_HEAD);
					mb->SetRecvPluto(u2);
					delete u;
                    //printf("HandleMessage() message head recive success!\n");
					////printf("recv all88\n");
					//print_hex_pluto(*u2);

					return HandleMessage(fd, mb);
				}
				else
				{
                    //printf("HandleMessage() new  message head recived uncomplete!\n");
					////printf("recv part99\n");
					//仍然未接收完
					u->SetLen(nLastLen+nLen);
					//print_hex_pluto(*u);
                    //printf("handle fd event in HandleMessage()! : waiting for next!\n");
					return nLen;
				}
			}
		}
		else
		{
			int nWanted = u->GetBuffSize() - nLastLen;
			nLen = ::recv(fd, szBuff+nLastLen, nWanted, 0);
			//LogDebug("hdm_recv4", "fd=%d;want=%d;recv=%d", fd, nWanted, nLen);
			if(nLen > 0)
			{
				if(nLen == nWanted)
				{
                    //printf("HandleMessage() new  message body over!\n");
					//接收完整
					u->EndRecv(nLastLen+nLen);
					u->SetMailbox(mb);
					AddRecvMsg(u);
					mb->SetRecvPluto(NULL); //置空
                    //printf("HandleMessage() one pluto success!\n");
					////printf("recv part33\n");
					//print_hex_pluto(*u);
					//可能还有其他包要处理
					return HandleMessage(fd, mb);
				}
				else
				{
                    //printf("HandleMessage() new  message body recived uncomplete!\n");
					////printf("recv part44\n");
					//接收不完整,留到下次接着处理
					u->SetLen(nLastLen+nLen);
					//print_hex_pluto(*u);
                    //printf("handle fd event in HandleMessage()! : waiting for next!\n");
					return nLen;
				}					
			}
		}
	}

	if(nLen == 0)
	{
		//client close
	}
	else
	{
        
		if(errno == EAGAIN)
		{
			return 0;
		}
		LogWarning("handle_message_err", "failed, %d,'%s'",errno, strerror(errno));
	}
	LogDebug("hdm_recv_err", "fd=%d;recv=%d;err=%d", fd, nLen, errno);
	close(fd);
    printf("HandleMessage() nLen : %d!\n", nLen);
	return -1;
}
#endif

void CEpollServer::AddRecvMsg(CPluto* u)
{
    m_recvMsgs.push_back(u);
}

int CEpollServer::HandlePluto()
{
    ////printf("CEpollServer::handle_pluto:start!\n");
    static uint32_t cnt = 0;
    static clock_t starttime, endtime;
    static double  totaltime;
    while(!m_recvMsgs.empty())
    {

        starttime = clock();
        CPluto* u = m_recvMsgs.front();
        //printf("len: %d max_len: %d\n", (*u).GetLen(), (*u).GetMaxLen());
        uint32_t count = (*u).GetLen();
        char *pbuff = (*u).GetRecvBuff();
       // printf("pluto content\n[");
       // for( uint32_t i = 0; i < count; i++)
       // {

       //    printf("%02X", *(pbuff+i) & 0xFF);


       // }
       // printf("]\n");
        //printf("the plutos : %d\n", cnt++);
        m_recvMsgs.pop_front();
     //   PrintHexPluto(*mb);

        world* w = GetWorld();
        w->FromRpcCall(*u);

        delete u;
        endtime = clock();
        totaltime  += (double)(endtime - starttime)/(double)CLOCKS_PER_SEC;
        printf("plutos :%d using time : %lf\n", cnt++, totaltime);
    }
   // //printf("CEpollServer::handle_pluto:end!\n");
    
    return 0;
}

//void CEpollServer::add_sEndPluto(CPluto* u)
//{
//    m_sendMsgs.push_back(u);
//}

int CEpollServer::HandleSendPluto()
{
	list<int> ls4del;
    map<int, CMailBox*>::iterator iter = m_fds.begin();
    for(; iter != m_fds.end(); ++iter)
    {
		CMailBox* mb = iter->second;
        int n = mb->SendAll();
		if(n != 0)
		{
			//发送失败需要关闭的连接
			ls4del.push_back(mb->GetFd());
		}
    }

	//关闭连接
	while(!ls4del.empty())
	{
		int fd = ls4del.front();
		CloseFdFromServer(fd);
		ls4del.pop_front();
	}
}

//把剩余的pluto包发送完毕
int CEpollServer::HandleLeftPluto()
{	
	LogInfo("CEpollServer::HandleLeftPluto", "");

	for(;;)
	{
		bool bSendAll = true;

		map<int, CMailBox*>::iterator iter = m_fds.begin();
		for(; iter != m_fds.end(); ++iter)
		{
			CMailBox* mb = iter->second;
			mb->SendAll();

			if(!mb->IsSendEmpty())
			{
				bSendAll = false;
			}
		}

		if(bSendAll)
		{
			break;
		}

		LogInfo("CEpollServer::HandleLeftPluto", "wait_1_second_to_send_left");
		sleep(1);
	}

	return 0;
}

void CEpollServer::SetWorld(world* w)
{
    this->the_world = w;
}

world* CEpollServer::GetWorld()
{
    return the_world;
}

CMailBox* CEpollServer::GetClientMailbox(int32_t fd)
{
    map<int, CMailBox*>::iterator iter = m_fds.find((int)fd);
    if(iter == m_fds.end())
    {
        return NULL;
    }
    else
    {
        return iter->second;
    }
}

void CEpollServer::Shutdown()
{
	m_bShutdown = true;
	LogInfo("recv_shutdown", "...");
}

////////////////////////////////////////////////////////////////////////////////////////////

