#include <sys/time.h>
#include "timerd.h"
#include "world_timerd.h"

CTimerdServer::CTimerdServer() : CEpollServer(), m_unTick(0), m_unLastSaveTick(0), m_unLastMoveTick(0)
{

}

CTimerdServer::~CTimerdServer()
{

}

int CTimerdServer::Service(const char* pszAddr, unsigned int unPort)
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
    //GetWorld()->OnServerReady();

    struct epoll_event ev;
    struct epoll_event events[MAX_EPOLL_SIZE];

    enum { _EPOLL_TIMEOUT = 100, };

    while (!m_bShutdown)
    {
        int event_count = m_fds.size();
        int nfds = epoll_wait(m_epfd, events, event_count, _EPOLL_TIMEOUT);
        if (nfds == -1)
        {
            if(errno == EINTR)
            {
                continue;
            }

            ERROR_RETURN2("Failed to epoll_wait");
            break;
        }
        else if(nfds == 0)
        {
            //timeout
            this->HandleTimeout();
        }
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

            switch(tfd)
            {
                case FD_TYPE_SERVER:
                {
                    int _nRet = HandleNewConnection(fd);
                    if(_nRet == 0)
                    {
                        ++event_count;
                    }
                    break;
                }
                case FD_TYPE_ACCEPT:
                {
                    if(this->HandleFdEvent(fd, events[n].events, mb) != 0)
                    {
                        //--event_count;
                    }
                    break;
                }
                case FD_TYPE_MAILBOX:
                {
                    if(this->HandleMailboxEvent(fd, events[n].events, mb) != 0)
                    {
                        //--event_count;
                    }
                    break;
                }
                default:
                {
                    //FD_TYPE_ERROR
                    break;
                }
            }

        }

        //处理包
        this->HandlePluto();

        //发送响应包
        this->HandleSendPluto();

        //
        this->HandleMailboxReconnect();

    }

    LogInfo("goto_shutdown", "shutdown after 2 seconds.");
    sleep(2);

    return 0;
}

//发送心跳包给所有的服务器
void CTimerdServer::SendTickMsg()
{
    //心跳包
    CPluto u;
    u.Encode(MSGID_ALLAPP_ONTICK) << ++m_unTick << EndPluto;

    //定时存盘的包
    CPluto* u2 = NULL;
    if(m_unTick - m_unLastSaveTick >= TIME_SAVE_TICKS)
    {
        u2 = new CPluto;
        (*u2).Encode(MSGID_BASEAPP_TIME_SAVE) << EndPluto;
        m_unLastSaveTick = m_unTick;
    }

    //entity move的包
    CPluto* u3 = NULL;
    if(m_unTick - m_unLastMoveTick >= TIME_ENTITY_MOVE)
    {
        u3 = new CPluto;
        (*u3).Encode(MSGID_CELLAPP_ON_TIME_MOVE) << EndPluto;
        m_unLastMoveTick = m_unTick;
    }

    map<int, CMailBox*>::iterator iter = m_fds.begin();
    for(; iter != m_fds.end(); ++iter)
    {
        CMailBox* mb = iter->second;
        //if(mb->getFdType() == FD_TYPE_MAILBOX && mb->isConnected())
        //baseapp和cellapp都发 kevinModify20130327
        if ((mb->GetServerMbType() == SERVER_BASEAPP || mb->GetServerMbType() == SERVER_CELLAPP) 
            && mb->IsConnected())
        {
            
            int nSendRet = ::send(mb->GetFd(), u.GetBuff(), u.GetLen(), 0);
            if(nSendRet != (int)u.GetLen())
            {
                //error handle
                LogInfo("CTimerdServer::send_tick_msg", "error:%d_%d,%d;%s", u.GetLen(), \
                        nSendRet, errno, strerror(errno));
            }
        }
        //目前只发给baseapp

        if(mb->GetServerMbType() == SERVER_BASEAPP && mb->IsConnected())
        {
            if(u2)
            {
                int nSendRet2 = ::send(mb->GetFd(), u2->GetBuff(), u2->GetLen(), 0);
                if(nSendRet2 != (int)u2->GetLen())
                {
                    //error handle
                    LogInfo("CTimerdServer::send_time_save_msg", "error:%d_%d,%d;%s", u2->GetLen(), \
                            nSendRet2, errno, strerror(errno));
                }
            }
        }

        if(u3)
        {
            if(mb->GetServerMbType() == SERVER_CELLAPP && mb->IsConnected())
            {
                int nSendRet3 = ::send(mb->GetFd(), u3->GetBuff(), u3->GetLen(), 0);
                if(nSendRet3 != (int)u3->GetLen())
                {
                    //error handle
                    LogInfo("CTimerdServer::send_time_move_msg", "error:%d_%d,%d;%s", u3->GetLen(), \
                            nSendRet3, errno, strerror(errno));
                }
            }
        }

    }

    if(u2 != NULL)
    {
        delete u2;
    }

    if (u3)
    {
        delete u3;
    }
}

//发送对时包给所有的服务器
void CTimerdServer::SendTimeMsg()
{

}
