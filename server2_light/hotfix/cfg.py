# -*- coding:utf-8 -*-

#base服务器的地址
BaseServers = [('127.0.0.1', 8006)]
#BaseServers = [('192.168.200.100', 8006), ('192.168.200.101', 8006)] ##多个地址的填写范例

#cell服务器的地址
CellServers = [('127.0.0.1', 8007)]
#CellServers = [('192.168.200.100', 8007), ('192.168.200.101', 8007)] ##多个地址的填写范例

#消息ID定义
SERVER_NONE          = 0
SERVER_LOGINAPP      = 1
SERVER_BASEAPPMGR    = 2
SERVER_DBMGR         = 3
SERVER_TIMERD        = 4
SERVER_LOG           = 5
SERVER_BASEAPP       = 6
SERVER_CELLAPP       = 7
	
MSGTYPE_LOGINAPP     = SERVER_LOGINAPP << 12
MSGTYPE_BASEAPPMGR   = SERVER_BASEAPPMGR << 12
MSGTYPE_BASEAPP      = SERVER_BASEAPP << 12
MSGTYPE_CELLAPP      = SERVER_CELLAPP << 12
MSGTYPE_DBMGR        = SERVER_DBMGR << 12
MSGTYPE_LOG          = SERVER_LOG << 12

#在base上调试lua脚本
MSGID_BASEAPP_LUA_DEBUG                 = MSGTYPE_BASEAPP + 90

#在cell上调试lua脚本
MSGID_CELLAPP_LUA_DEBUG                 = MSGTYPE_CELLAPP + 90

#停止服务器
MSGID_BASEAPPMGR_SHUTDOWN_SERVERS       = MSGTYPE_BASEAPPMGR + 6


