/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：baseapp
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.5
// 模块描述：base服务器进程
//----------------------------------------------------------------*/

#include "baseapp.h"
#include "lua_base.h"
#include "world_base.h"
#include "world_select.h"


CBaseappServer::CBaseappServer() : CEpollServer()
{

}

CBaseappServer::~CBaseappServer()
{

}

int CBaseappServer::HandlePluto()
{
    //printf("CBaseappServer::handle_pluto\n");
    CEpollServer::HandlePluto();

    return 0;
}


void CBaseappServer::OnShutdownServer()
{
    //get over with the left pluto
    this->HandleLeftPluto();

    //response the "cwmd" that it has logout
    GetWorld()->RpcCall(SERVER_BASEAPPMGR, MSGID_BASEAPPMGR_ON_SERVER_SHUTDOWN, GetMailboxId());
    //only the way can send the pluto to "cwmd"
    this->HandleLeftPluto();

    CEpollServer::OnShutdownServer();
}


///////////////////////////////////////////////////////////////////////////
