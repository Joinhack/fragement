#ifndef __CELLAPP_HEAD__
#define __CELLAPP_HEAD__

#include "epoll_server.h"
//#include "event.h"

class CCellappServer : public CEpollServer
{
    public:
        CCellappServer();
        ~CCellappServer();

    protected:
        int HandlePluto();
        //int on_fd_closed(int fd);
};


#endif

