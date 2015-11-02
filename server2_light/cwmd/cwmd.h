#ifndef __CWMD_HEAD__
#define __CWMD_HEAD__

#include "epoll_server.h"


class CMgrServer : public CEpollServer
{
    public:
        CMgrServer();
        ~CMgrServer();

    protected:
        int HandlePluto();

};


#endif

