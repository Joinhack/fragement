/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：cellapp
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.5
// 模块描述：cellapp 进程相关
//----------------------------------------------------------------*/

#include "cellapp.h"
#include "lua_cell.h"
#include "world_cell.h"

CCellappServer::CCellappServer() : CEpollServer()
{

}

CCellappServer::~CCellappServer()
{

}

int CCellappServer::HandlePluto()
{
    //printf("CBaseappServer::handle_pluto\n");
    CEpollServer::HandlePluto();

    return 0;
}
