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


using namespace mogo;

///////////////////////////////////////////////////////////////////////////////
#ifdef _USE_RECV_BUFF
CMailBox::CMailBox(uint16_t uid, EFDTYPE fdtype, const char* pszAddr, uint16_t unPort) 
    : m_bConnected(false), m_fd(0), m_fdType(fdtype), m_connectdTime(0),
        m_serverName(pszAddr), m_serverPort(unPort), m_unRecvBuffLen(0), m_id(uid),
        m_unServerMbType(SERVER_NONE), m_uAuthz(MAILBOX_CLIENT_UNAUTHZ), m_nSendPos(0)
#else
CMailBox::CMailBox(uint16_t uid, EFDTYPE fdtype, const char* pszAddr, uint16_t unPort) 
    : m_bConnected(false), m_fd(0), m_fdType(fdtype), m_connectdTime(0),
        m_serverName(pszAddr), m_serverPort(unPort), m_id(uid), m_pluto(NULL),
        m_unServerMbType(SERVER_NONE), m_uAuthz(MAILBOX_CLIENT_UNAUTHZ), m_nSendPos(0)
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

    struct epoll_event ev;
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
        while(!m_tobeSend.empty())
        {
            LogDebug("CMailBox::SendAll", "");
            CPluto* u = m_tobeSend.front();
            //PrintHexPluto(*u);
			int nSendWant = (int)u->GetLen() - m_nSendPos;		//期待发送的字节数
            int nSendRet = ::send(m_fd, u->GetBuff()+m_nSendPos, nSendWant, 0);
            if(nSendRet != nSendWant)
            {
                //error handle
                LogWarning("CMailBox::sendAll error", "mb=%d;%d_%d,%d;%s", GetMailboxId(), u->GetLen(), nSendRet, 
                    errno, strerror(errno));

				if(errno == EINPROGRESS || errno == EAGAIN )
				{
					if(nSendRet > 0)
					{
						//阻塞了,留到下次继续发送
						//LogInfo("111", "m_nSendPos111=%d\n", m_nSendPos);
						m_nSendPos += nSendRet;
						//LogInfo("222", "m_nSendPos111=%d\n", m_nSendPos);
					}
					return 0;
				}
				else
				{
					//判断,如果是客户端则关闭,如果是其他服务器,通知管理器退出
					if(GetMailboxId() > 0)
					{
						//保留消息包,等待重发
						//何时选择退出? //todo
						return 0;
					}
					else
					{
						return -1;
					}
				}
            }

            m_tobeSend.pop_front();
            delete u;
			m_nSendPos = 0;
        }

    }

    return 0;
}

bool CMailBox::RpcCallFromLua(CRpcUtil& r, pluto_msgid_t msg_id, CEntityMailbox& em)
{
    return true;
}

///////////////////////////////////////////////////////////////////////////////




