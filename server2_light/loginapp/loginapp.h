#ifndef __LOGINAPP_HEAD__
#define __LOGINAPP_HEAD__

#include "epoll_server.h"


class CLoginappServer : public CEpollServer
{
    public:
        CLoginappServer();
        ~CLoginappServer();

    protected:
        int HandlePluto();

};


#endif

