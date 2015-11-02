/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：mailbox
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.5
// 模块描述：对服务器的发送缓冲区的封装： mailbox
//----------------------------------------------------------------*/
#include "mailbox.h"
#include "util.h"
#include "epoll_server.h"
#include "memory_pool.h"


using namespace mogo;

mogo::MemoryPool* CMailBox::memPool = NULL;
mogo::MyLock CMailBox::m_lock;

///////////////////////////////////////////////////////////////////////////////
#ifdef _USE_RECV_BUFF
CMailBox::CMailBox(uint16_t uid, EFDTYPE fdtype, const char* pszAddr, uint16_t unPort)
    : m_bConnected(false), m_fd(0), m_fdType(fdtype), m_connectdTime(0),
      m_serverName(pszAddr), m_serverPort(unPort), m_unRecvBuffLen(0), m_id(uid),
      m_unServerMbType(SERVER_NONE), m_uAuthz(MAILBOX_CLIENT_UNAUTHZ), m_nSendPos(0), m_bDeleteFlag(false)
#else
CMailBox::CMailBox(uint16_t uid, EFDTYPE fdtype, const char* pszAddr, uint16_t unPort)
    : m_bConnected(false), m_fd(0), m_fdType(fdtype), m_connectdTime(0),
      m_serverName(pszAddr), m_serverPort(unPort), m_id(uid), m_pluto(NULL),
      m_unServerMbType(SERVER_NONE), m_uAuthz(MAILBOX_CLIENT_UNAUTHZ), m_nSendPos(0), m_bDeleteFlag(false)
#endif

#ifdef __OPTIMIZE_PLUTO
      , sendBuffPos(0)
#endif

{
    //m_connectdTime = time(NULL);
    m_lastTickTime = m_connectdTime;

    if(fdtype == FD_TYPE_MAILBOX)
    {
        m_timeout = OTHERSERVER_TIMEOUT;
    }
    else
    {
        m_timeout = CLIENT_TIMEOUT;
    }
}

CMailBox::~CMailBox()
{
	if(m_pluto)
	{
		delete m_pluto;
	}

	ClearContainer(m_tobeSend);
}

void * CMailBox::operator new(size_t size)
{
    m_lock.Lock();

    if (NULL == memPool)
    {
        expandMemoryPool();
    }

    MemoryPool *head = memPool;
    memPool = head->next;

    m_lock.Unlock();

    //LogDebug("CMailBox new", "");

    return head;
}

void CMailBox::operator delete(void* p, size_t size)
{
    m_lock.Lock();

    MemoryPool *head = (MemoryPool *)p;
    head->next = memPool;
    memPool = head;

    m_lock.Unlock();

    //LogDebug("CMailBox delete", "");
}

void CMailBox::expandMemoryPool()
{
    size_t size = (sizeof(CMailBox) > sizeof(MemoryPool *)) ? sizeof(CMailBox) : sizeof(MemoryPool *);

    MemoryPool *runner = (MemoryPool *) new char[size];
    memPool = runner;

    enum  { EXPAND_SIZE = 32};
    for (int i=0; i<EXPAND_SIZE; i++)
    {
        runner->next = (MemoryPool *) new char[size];
        runner = runner->next;
    }

    runner->next = NULL;
}

//根据配置初始化
bool CMailBox::init(const MailBoxConfig& cfg)
{
    return true;
}

int CMailBox::ConnectServer(int epfd)
{
    //printf("%s:%d,%x\n", __FILE__, __LINE__, this);
    time_t tNow = time(NULL);
    if(tNow - m_connectdTime < 5)
    {
        return -1;
    }

    if(m_fd > 0)
    {
        close(m_fd);
    }

    m_fd = MogoSocket();
    MogoSetNonblocking(m_fd);

	//修改rcvbuf和sndbuf
	enum{ _BUFF_SIZE = 174760 };
	MogoSetBuffSize(m_fd, _BUFF_SIZE, _BUFF_SIZE);

    struct epoll_event ev;
    memset(&ev, 0, sizeof ev);
    ev.events = EPOLLIN | EPOLLOUT | EPOLLET;
    ev.data.fd = m_fd;

    if(epoll_ctl(epfd, EPOLL_CTL_ADD, m_fd, &ev) == -1)
    {
        ERROR_RETURN2("Failed to epoll_ctl_add connect fd");
    }

    int nRet = MogoConnect(m_fd, GetServerName().c_str(), GetServerPort());
    if(nRet != 0 && errno != EINPROGRESS)
    {
        ERROR_RETURN2("Failed to connect");
    }

    m_connectdTime = tNow;
    return 0;
}

int CMailBox::SendAll()
{
    if(IsConnected())
    {
#ifdef __OPTIMIZE_PLUTO
        while(!m_tobeSend.empty() && this->GetSendBuffPos() < SEND_BUFF)
        {
            CPluto* u = m_tobeSend.front();
            uint32_t CopyBuffLen = this->CopySendBuff(u->GetBuff() + u->GetSendPos(), u->GetLen() - u->GetSendPos());
            u->SetSendPos(u->GetSendPos() + CopyBuffLen);

            if (u->GetSendPos() >= u->GetLen())
            {
                m_tobeSend.pop_front();
                delete u;
            }
        }

        if (this->GetSendBuffPos() > 0)
        {
            int nSendRet = ::send(m_fd, this->GetSendBuff(), this->GetSendBuffPos(), 0);
            int nError   = errno;
            if(nSendRet != (int)this->GetSendBuffPos())
            {
                if (nSendRet >= 0)
                {
                    if (nSendRet > 0)
                    {
                        this->ResizeSendBuff(nSendRet);
                    }
                    else
                    {
                        if (nError != EINPROGRESS && nError != EAGAIN)
                        {
                            LogWarning("CMailBox::sendAll error", "mb=%d;%d;%s",
                                                                   GetMailboxId(), nError, strerror(nError));
                        }
                    }
                    return 0;
                }
                else
                {
                    if (nError == EINPROGRESS || nError == EAGAIN)
                    {
                        return 0;
                    }
                    else
                    {
                        return -1;
                    }
                }
            }
            else
            {
                this->ClearSendBuff();
                return 0;
            }
        }

#else
		if(IsConnected())
		{
			while(!m_tobeSend.empty())
			{
				//log_game_debug("CMailBox::sendAll", "");
				CPluto* u = m_tobeSend.front();
				int nSendWant = (int)u->GetLen()-m_nSendPos;		//期待发送的字节数
				int nSendRet = ::send(m_fd, u->GetBuff()+m_nSendPos, nSendWant, 0);
                //PrintHexPluto(*u);
                //LogDebug("CMailBox::SendAll", "m_fd=%d;msg_id=%d;nSendRet=%d", m_fd, u->GetMsgId(), nSendRet);
				if(nSendRet != nSendWant)
				{
					uint16_t mbid = GetMailboxId();

					//error handle
					LogWarning("CMailBox::sendAll error", "mb=%d;%d_%d,%d;%s", mbid, u->GetLen(), nSendRet, 
						errno, strerror(errno));

					if(mbid == 0 && GetAuthz() != MAILBOX_CLIENT_TRUSTED)
					{
						//客户端连接不重发了,直接关掉
						return -1;
					}

                    if(nSendRet >= 0)
                    {
                        //阻塞了,留到下次继续发送                        
                        m_nSendPos += nSendRet;
                        return 0;
                    }
                    else
                    {
                        if(errno == EINPROGRESS || errno == EAGAIN )
                        {
                            //阻塞了,留到下次继续发送                        
                            return 0;
                        }
                    }

					//判断,如果是客户端则关闭,如果是其他服务器,通知管理器退出
					//保留消息包,等待重发
					//何时选择退出? //todo
					return -1;
				}

				m_tobeSend.pop_front();
				delete u;
				m_nSendPos = 0;
			}

		}
#endif
    }

    return 0;
}

bool CMailBox::RpcCallFromLua(CRpcUtil& r, pluto_msgid_t msg_id, CEntityMailbox& em)
{
    return true;
}

///////////////////////////////////////////////////////////////////////////////




