#ifndef __EPOLL_SERVER_HEAD__
#define __EPOLL_SERVER_HEAD__


#include <sys/epoll.h>
#include <time.h>

#include "util.h"
#include "net_util.h"
#include "mailbox.h"
#include "pluto.h"


enum{
    MAX_EPOLL_SIZE = 9999,
    MAXBUF = 1024,
    CLIENT_TIMEOUT = 20,
    OTHERSERVER_TIMEOUT = 5,
};

namespace mogo
{
    class world;
}


class CEpollServer
{
public:
    CEpollServer();
    virtual ~CEpollServer();

public:
    int StartServer(const char* pszAddr, uint16_t unPort);
    int ConnectMailboxs(const char* pszCfgFile);
	void Shutdown();

public:
    int Service(const char* pszAddr, unsigned int unPort);

protected:
    void AddFdAndMb(int fd, CMailBox* pmb);
    void AddFdAndMb(int fd, EFDTYPE efd, const char* pszAddr, uint16_t unPort);
    void RemoveFd(int fd);
    EFDTYPE GetFdType(int fd);
    CMailBox* GetFdMailbox(int fd);

protected:
    virtual int HandleNewConnection(int fd);
    virtual int HandleMailboxEvent(int fd, uint32_t event, CMailBox* mb);
    virtual int HandleFdEvent(int fd, uint32_t event, CMailBox* mb);
    virtual int HandleMessage(int fd, CMailBox* mb);
    virtual int HandleTimeout();
    virtual int HandleMailboxReconnect();

protected:
    virtual int OnNewFdAccepted(int new_fd, sockaddr_in& addr);
    virtual int OnFdClosed(int fd);
    virtual void AddRecvMsg(CPluto* u);

public:
	//服务器主动关闭一个socket
	void CloseFdFromServer(int fd);
	//顶掉一个连接
	void KickoffFd(int fd);

protected:
    virtual int HandlePluto();
    virtual int HandleSendPluto();
	//把剩余的pluto包发送完毕
	int HandleLeftPluto();
	//停止了服务器之后,进程退出之前的一个回调方法
	virtual void OnShutdownServer();

//
//public:
//    void AddSendPluto(CPluto* u);

public:
    void SetWorld(world* w);
    world* GetWorld();

public:
    inline void SetMailboxId(uint16_t mid)
    {
        m_unMailboxId = mid;
    }

    inline uint16_t GetMailboxId() const
    {
        return m_unMailboxId;
    }

    CMailBox* GetServerMailbox(uint16_t nServerId)
    {
        //printf("get_server_mailbox:%d_%d\n", nServerId, m_serverMbs.size());
        if(nServerId < m_serverMbs.size())
        {
            return m_serverMbs[nServerId];
        }
        else
        {
            return NULL;
        }
    }

    CMailBox* GetClientMailbox(int32_t fd);

    inline vector<CMailBox*>& GetAllServerMbs()
    {
        return m_serverMbs;
    }

    inline void AddLocalRpcPluto(CPluto* u)
    {
        m_recvMsgs.push_back(u);
    }

protected:
    int m_epfd;
    map<int, CMailBox*> m_fds;//for client fd and mailbox 
    list<CPluto*> m_recvMsgs;
    //list<CPluto*> m_sendMsgs;
    string m_strAddr;
    uint16_t m_unPort;
    vector<CMailBox*> m_mb4reconn;
    vector<CMailBox*> m_serverMbs;    // for server mailbox index by server id
    uint16_t m_unMailboxId;
    world* the_world;
	bool m_bShutdown;

};



#endif

