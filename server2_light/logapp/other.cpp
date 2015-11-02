#include "other.h"
#include "world_other.h"
#include "db_task.h"


COtherServer::COtherServer() : CEpollServer()
{

}

COtherServer::~COtherServer()
{

}

void COtherServer::AddRecvMsg(CPluto* u)
{
    LogDebug("CLogServer::AddRecvMsg", "u.GenLen()=%d", u->GetLen());
    g_pluto_recvlist.PushPluto(u);
}

int COtherServer::HandleSendPluto()
{
    enum { SEND_COUNT = 1000, };
    CPluto* u;
    int i = 0;
    while(u = g_pluto_sendlist.PopPluto())
    {
        CMailBox* mb = u->GetMailbox();
        if(mb)
        {
            LogDebug("CLogServer::HandleSendPluto", "u.GenLen()=%d", u->GetLen());
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

void COtherServer::OnShutdownServer()
{
    //get over with the left pluto
    this->HandleLeftPluto();

    //response the "cwmd" that it has logout
    GetWorld()->RpcCall(SERVER_BASEAPPMGR, MSGID_BASEAPPMGR_ON_SERVER_SHUTDOWN, GetMailboxId());
    //only the way can send the pluto to "cwmd"
    this->HandleLeftPluto();

    CEpollServer::OnShutdownServer();
}



CPlutoList g_pluto_recvlist;
CPlutoList g_pluto_sendlist;
bool g_bShutdown = false;
