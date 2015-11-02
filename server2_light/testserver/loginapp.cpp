/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：loginapp
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.11
// 模块描述：登录服务器进程
//----------------------------------------------------------------*/

#include "loginapp.h"
#include "world_login.h"
#include "signal.h"

CLoginappServer::CLoginappServer() : CEpollServer()
{

}

CLoginappServer::~CLoginappServer()
{

}

int CLoginappServer::HandlePluto()
{
    //printf("CLoginappServer::HandlePluto\n");
    CEpollServer::HandlePluto();

    return 0;
}


///////////////////////////////////////////////////////////////////////////





