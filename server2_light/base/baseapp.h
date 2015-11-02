#ifndef __BASEAPP_HEAD__
#define __BASEAPP_HEAD__

#include<signal.h>
#include "epoll_server.h"
#include "event.h"

class CBaseappServer : public CEpollServer
{
    public:
        CBaseappServer();
        ~CBaseappServer();

    protected:
        int HandlePluto();
        //int on_fd_closed(int fd);

        void OnShutdownServer();


};


#endif

