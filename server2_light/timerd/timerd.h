#ifndef __TIMERD_HEAD__
#define __TIMERD_HEAD__

#include "epoll_server.h"


class CTimerdServer : public CEpollServer
{
    public:
        CTimerdServer();
        ~CTimerdServer();

    public:
        int Service(const char* pszAddr, unsigned int unPort);

    public:
        //发送心跳包给所有的服务器
        void SendTickMsg();
        //发送对时包给所有的服务器
        void SendTimeMsg();

    private:
        uint32_t m_unTick;
        uint32_t m_unLastSaveTick;
        uint32_t m_unLastMoveTick;

};


#endif

