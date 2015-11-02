#ifndef __LOGAPP_HEAD__
#define __LOGAPP_HEAD__

#include "epoll_server.h"


class COtherServer : public CEpollServer
{
    public:
        COtherServer();
        ~COtherServer();

    protected:
        inline int HandlePluto()
        {
            return 0;
        }

        int HandleSendPluto();

        void AddRecvMsg(CPluto* u);

        void OnShutdownServer();

};


#endif

