#include "dbmgr.h"
#include "world_dbmgr.h"
#include "db_task.h"


CDbMgrServer::CDbMgrServer() : CEpollServer()
{

}

CDbMgrServer::~CDbMgrServer()
{

}

void CDbMgrServer::AddRecvMsg(CPluto* u)
{
    LogDebug("CDbMgrServer::AddRecvMsg", "u.GenLen()=%d", u->GetLen());
    g_pluto_recvlist.PushPluto(u);
}

int CDbMgrServer::HandleSendPluto()
{
    enum { SEND_COUNT = 1000, };
    CPluto* u;
    int i = 0;
    while(u = g_pluto_sendlist.PopPluto())
    {
        CMailBox* mb = u->GetMailbox();
        if(mb)
        {
            LogDebug("CDbMgrServer::HandleSendPluto", "u.GenLen()=%d", u->GetLen());
            mb->PushPluto(u);
        }
        //每次只发送一定条数,主要用在loadAllAvatar处
        if(++i > SEND_COUNT)
        {
            break;
        }
    }

    CEpollServer::HandleSendPluto();
}
CPlutoList g_pluto_recvlist;
CPlutoList g_pluto_sendlist;
bool g_bShutdown = false;
