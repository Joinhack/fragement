#ifndef __DBMGR_HEAD__
#define __DBMGR_HEAD__

#include "epoll_server.h"


class CDbMgrServer : public CEpollServer
{
    public:
        CDbMgrServer();
        ~CDbMgrServer();

    protected:
        inline int HandlePluto()
        {
            return 0;
        }

        int HandleSendPluto();

    protected:
        void AddRecvMsg(CPluto* u);

};


#endif

