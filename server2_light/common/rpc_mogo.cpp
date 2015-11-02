/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：rpc_mogo
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.5
// 模块描述：rpc 打包，解包等
//----------------------------------------------------------------*/

#include "rpc_mogo.h"
#include "util.h"
#include "world.h"
#include "world_select.h"
#include "pluto.h"

namespace mogo
{

    CRpcUtil::CRpcUtil() : m_strFuncNameNotfound("")
    {
        this->InitInnerMethods();
    }

    //初始化内嵌(非自定义)的方法
    void CRpcUtil::InitInnerMethods()
    {
        //client
        {
            _SEntityDefMethods* p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);             //baseapp addr
            p->m_argsType.push_back(V_UINT16);          //baseapp port
            p->m_argsType.push_back(V_STR);             //key
            m_methods.insert(make_pair(MSGID_CLIENT_NOTIFY_ATTACH_BASEAPP, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT8);           //ret code
            m_methods.insert(make_pair(MSGID_CLIENT_LOGIN_RESP, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT8);           //ret code
            m_methods.insert(make_pair(MSGID_CLIENT_CHECK_RESP, p));
        }

        //all app
        {
            _SEntityDefMethods* p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT32);
            m_methods.insert(make_pair(MSGID_ALLAPP_ONTICK, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT8);
            m_methods.insert(make_pair(MSGID_ALLAPP_SHUTDOWN_SERVER, p));
        }

        //client -> loginapp
        {
            _SEntityDefMethods* p = new _SEntityDefMethods;
            //p->m_argsType.push_back(V_STR);         //版本号
            p->m_argsType.push_back(V_STR);         //MD5
            m_methods.insert(make_pair(MSGID_LOGINAPP_CHECK, p));

            p = new _SEntityDefMethods;
#if __PLAT_PLUG_IN 
            p->m_argsType.push_back(V_STR);         //account name
            p->m_argsType.push_back(V_STR);         //timestamp
            p->m_argsType.push_back(V_STR);         //strSign
            p->m_argsType.push_back(V_STR);         //strPlatId
            p->m_argsType.push_back(V_STR);         //strPlatAccount
#elif __PLAT_PLUG_IN_NEW
            p->m_argsType.push_back(V_STR);         //account name
            p->m_argsType.push_back(V_STR);         //timestamp
            p->m_argsType.push_back(V_STR);         //strSign
            p->m_argsType.push_back(V_STR);         //strPlatId
            p->m_argsType.push_back(V_STR);         //strPlatAccount
            p->m_argsType.push_back(V_STR);         //strToken
#else
            p->m_argsType.push_back(V_STR);         //account name
            p->m_argsType.push_back(V_STR);         //passwd
#endif
            m_methods.insert(make_pair(MSGID_LOGINAPP_LOGIN, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);         //account name
            p->m_argsType.push_back(V_STR);         //passwd
            m_methods.insert(make_pair(MSGID_LOGINAPP_WEBLOGIN, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_INT32);       //client fd
            p->m_argsType.push_back(V_STR);         //account name
            p->m_argsType.push_back(V_UINT8);       //ret
            m_methods.insert(make_pair(MSGID_LOGINAPP_SELECT_ACCOUNT_CALLBACK, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);         //account
            p->m_argsType.push_back(V_UINT16);      //server id
            p->m_argsType.push_back(V_STR);         //key
            m_methods.insert(make_pair(MSGID_LOGINAPP_NOTIFY_CLIENT_TO_ATTACH, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT8);
            m_methods.insert(make_pair(MSGID_LOGINAPP_MODIFY_LOGIN_FLAG, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);         //account
            p->m_argsType.push_back(V_UINT32);      //forbid time
            m_methods.insert(make_pair(MSGID_LOGINAPP_FORBIDLOGIN, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);         //ip
            p->m_argsType.push_back(V_UINT32);      //forbid time
            m_methods.insert(make_pair(MSGID_LOGINAPP_FORBID_IP_UNTIL_TIME, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);         //account
            p->m_argsType.push_back(V_UINT32);      //forbid time
            m_methods.insert(make_pair(MSGID_LOGINAPP_FORBID_ACCOUNT_UNTIL_TIME, p));


            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT8);         //增加或者减少
            p->m_argsType.push_back(V_UINT8);         //增加或者减少的数量
            m_methods.insert(make_pair(MSGID_LOGINAPP_MODIFY_ONLINE_COUNT, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_INT32);         //err code
            p->m_argsType.push_back(V_INT32);         //client fd
            p->m_argsType.push_back(V_STR);           //account
            p->m_argsType.push_back(V_STR);           //plat id
            m_methods.insert(make_pair(MSGID_LOGINAPP_LOGIN_VERIFY_CALLBACK, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);         //account
            m_methods.insert(make_pair(MSGID_LOGINAPP_NOTIFY_CLIENT_MULTILOGIN, p));

        }

        //mogod,baseappmgr
        {
            _SEntityDefMethods* p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_ENTITYMB);   //mb
            p->m_argsType.push_back(V_STR);        //name
            p->m_argsType.push_back(V_INT32);      //ref
            m_methods.insert(make_pair(MSGID_BASEAPPMGR_REGISTERGLOBALLY, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);         //entity name
#ifdef __USE_MSGPACK
            p->m_argsType.push_back(V_BLOB);        //param
#else
            p->m_argsType.push_back(V_STR);         //param
#endif
            m_methods.insert(make_pair(MSGID_BASEAPPMGR_CREATEBASE_ANYWHERE, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT8);       //create if not exists
            p->m_argsType.push_back(V_STR);         //entity name
            p->m_argsType.push_back(V_STR);         //unique index value
            m_methods.insert(make_pair(MSGID_BASEAPPMGR_CREATEBASE_FROM_NAME_ANYWHERE, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT8);       //create if not exists
            p->m_argsType.push_back(V_STR);         //entity name
            p->m_argsType.push_back(V_STR);         //unique index value
            p->m_argsType.push_back(V_UINT16);      //baseapp id
            m_methods.insert(make_pair(MSGID_BASEAPPMGR_CREATEBASE_FROM_NAME, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_ENTITYMB);    //base mb
            p->m_argsType.push_back(V_UINT16);      //entity type id
#ifdef __USE_MSGPACK
            p->m_argsType.push_back(V_BLOB);
#else
            p->m_argsType.push_back(V_STR);         //other params
#endif
            p->m_argsType.push_back(V_BLOB);        //cell props
            m_methods.insert(make_pair(MSGID_BASEAPPMGR_CREATE_CELL_IN_NEW_SPACE, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT8);       //dummy
            m_methods.insert(make_pair(MSGID_BASEAPPMGR_SHUTDOWN_SERVERS, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT16);      //server id
            m_methods.insert(make_pair(MSGID_BASEAPPMGR_ON_SERVER_SHUTDOWN, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT8);       //dummy
            m_methods.insert(make_pair(MSGID_BASEAPPMGR_SHUTDOWN_SERVERS_CALLBACK, p));
        }

        //baseapp
        {
            _SEntityDefMethods* p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_ENTITYMB);   //mb
            p->m_argsType.push_back(V_UINT8);      //ret
            p->m_argsType.push_back(V_INT32);      //ref
            m_methods.insert(make_pair(MSGID_BASEAPP_REGISTERGLOBALLY_CALLBACK, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);        //name
            p->m_argsType.push_back(V_ENTITYMB);   //mb
            m_methods.insert(make_pair(MSGID_BASEAPP_ADD_GLOBALBASE, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);        //name
            m_methods.insert(make_pair(MSGID_BASEAPP_DEL_GLOBALBASE, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_ENTITYMB);    //mb
            p->m_argsType.push_back(V_UINT64);      //dbid
            p->m_argsType.push_back(V_INT32);       //ref
            p->m_argsType.push_back(V_STR);         //db err
            m_methods.insert(make_pair(MSGID_BASEAPP_INSERT_ENTITY_CALLBACK, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT64);      //dbid
            p->m_argsType.push_back(V_INT32);       //callback
            p->m_argsType.push_back(V_ENTITY);      //entity
            m_methods.insert(make_pair(MSGID_BASEAPP_SELECT_ENTITY_CALLBACK, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT64);      //dbid
            p->m_argsType.push_back(V_UINT32);      //entity id
            p->m_argsType.push_back(V_UINT8);       //create flag
            p->m_argsType.push_back(V_STR);         //key
            p->m_argsType.push_back(V_UINT32);      //other entity id
            p->m_argsType.push_back(V_ENTITY);      //entity
            m_methods.insert(make_pair(MSGID_BASEAPP_LOOKUP_ENTITY_CALLBACK, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT32);      //entity id
            m_methods.insert(make_pair(MSGID_BASEAPP_ENTITY_MULTILOGIN, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT64);      //dbid
            p->m_argsType.push_back(V_UINT32);      //id
            p->m_argsType.push_back(V_ENTITY);      //entity
            m_methods.insert(make_pair(MSGID_BASEAPP_LOAD_ALL_AVATAR, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT64);      //dbid
            p->m_argsType.push_back(V_UINT32);      //id
            p->m_argsType.push_back(V_ENTITY);      //entity
            m_methods.insert(make_pair(MSGID_BASEAPP_LOAD_ENTITIES_OF_TYPE, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);         //entity name
            p->m_argsType.push_back(V_UINT32);      //entity count
            m_methods.insert(make_pair(MSGID_BASEAPP_LOAD_ENTITIES_END_MSG, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);         //key
            m_methods.insert(make_pair(MSGID_BASEAPP_CLIENT_LOGIN, p));

#ifndef _WIN32
            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);         //key
            m_methods.insert(make_pair(MSGID_BASEAPP_CLIENT_RELOGIN, p));
#endif

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);         //lua code
            m_methods.insert(make_pair(MSGID_BASEAPP_LUA_DEBUG, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_ENTITYMB);    //cell mb
            m_methods.insert(make_pair(MSGID_BASEAPP_ON_GET_CELL, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT32);      //entity id
            p->m_argsType.push_back(V_ENTITYMB);    //src base mb
            p->m_argsType.push_back(V_INT16);       //x
            p->m_argsType.push_back(V_INT16);       //y
            p->m_argsType.push_back(V_STR);         //mask string
            p->m_argsType.push_back(V_BLOB);        //props
            m_methods.insert(make_pair(MSGID_BASEAPP_CREATE_CELL_VIA_MYCELL, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT32);      //entity id
            p->m_argsType.push_back(V_UINT8);       //err id
            m_methods.insert(make_pair(MSGID_BASEAPP_CREATE_CELL_FAILED, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT32);      //eid
            p->m_argsType.push_back(V_BLOB);        //params
            m_methods.insert(make_pair(MSGID_BASEAPP_ON_LOSE_CELL, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);         //entity name
#ifdef __USE_MSGPACK
            p->m_argsType.push_back(V_BLOB);         //param
#else
            p->m_argsType.push_back(V_STR);         //param
#endif
            m_methods.insert(make_pair(MSGID_BASEAPP_CREATE_BASE_ANYWHERE, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);         //key
            p->m_argsType.push_back(V_UINT8);       //value type
#ifdef __USE_MSGPACK
            p->m_argsType.push_back(V_BLOB);        //value
#else
            p->m_argsType.push_back(V_STR);         //value
#endif
            m_methods.insert(make_pair(MSGID_BASEAPP_SET_BASE_DATA, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);         //key
            m_methods.insert(make_pair(MSGID_BASEAPP_DEL_BASE_DATA, p));

            //p = new _SEntityDefMethods;
            //p->m_argsType.push_back(V_STR);           //gm cmd
            //m_methods.insert(make_pair(MSGID_BASEAPP_CLIENT_RPCALL, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT32);          //eid
            p->m_argsType.push_back(V_UINT16);          //func id
            p->m_argsType.push_back(V_BLOB);            //params
            m_methods.insert(make_pair(MSGID_BASEAPP_CLIENT_RPC_VIA_BASE, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_ENTITYMB);        //entity mb
            p->m_argsType.push_back(V_STR);             //attri name
            p->m_argsType.push_back(V_STR);             //value
            m_methods.insert(make_pair(MSGID_BASEAPP_ON_REDIS_HASH_LOAD, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT32);          //eid
            p->m_argsType.push_back(V_UINT16);          //msg id
            p->m_argsType.push_back(V_BLOB);            //params
            m_methods.insert(make_pair(MSGID_BASEAPP_CLIENT_MSG_VIA_BASE, p));

            p = new _SEntityDefMethods;
            m_methods.insert(make_pair(MSGID_BASEAPP_TIME_SAVE, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT16);          //发到自己客户端的协议头
            p->m_argsType.push_back(V_UINT32);          //eid
#ifdef __FACE
            p->m_argsType.push_back(V_UINT8);           //face
#endif
            p->m_argsType.push_back(V_INT16);           //pos_x
            p->m_argsType.push_back(V_INT16);           //pos_y
            p->m_argsType.push_back(V_UINT8);           //是否通知client
            m_methods.insert(make_pair(MSGID_BASEAPP_AVATAR_POS_SYNC, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT32);    //base mb
            m_methods.insert(make_pair(MSGID_BASEAPP_DEL_ACCOUNT_CACHE_CALLBACK, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_INT32);     //ref 
            p->m_argsType.push_back(V_UINT16);    //status id
            p->m_argsType.push_back(V_STR);        //item name
            p->m_argsType.push_back(V_STR);       //loading items  data or status content  
            m_methods.insert(make_pair(MSGID_BASEAPP_ITEMS_LOADING_CALLBACK, p));


            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_INT32);     //ref
            p->m_argsType.push_back(V_UINT16);    //status id
            p->m_argsType.push_back(V_STR);    //update items status
            m_methods.insert(make_pair(MSGID_BASEAPP_UPDATE_ITEMS_CALLBACK, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_INT32);     //ref
            p->m_argsType.push_back(V_UINT16);    //status id
            p->m_argsType.push_back(V_STR);       //def name
            p->m_argsType.push_back(V_STR);       //insert items status
            m_methods.insert(make_pair(MSGID_BASEAPP_INSERT_ITEMS_CALLBACK, p));
            

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT32);        //entityId
            p->m_argsType.push_back(V_STR);           //strCallBackFunc
            p->m_argsType.push_back(V_STR);           //strEntityType
            p->m_argsType.push_back(V_UINT16);        //num_fields
            p->m_argsType.push_back(V_BLOB);          //params
            m_methods.insert(make_pair(MSGID_BASEAPP_TABLE_SELECT_CALLBACK, p));

            //p = new _SEntityDefMethods;
            //p->m_argsType.push_back(V_STR);           //entity的类型名
            //p->m_argsType.push_back(V_UINT16);        //entity的nFuncId
            //p->m_argsType.push_back(V_UINT16);        //参数个数
            //p->m_argsType.push_back(V_BLOB);          //params
            //m_methods.insert(make_pair(MSGID_BASEAPP_BROADCAST_CLIENT_PRC, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_INT32);     //ref
            p->m_argsType.push_back(V_UINT16);    //status id
            m_methods.insert(make_pair(MSGID_BASEAPP_TABLE_UPDATE_BATCH_CB, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT32);      //ref
            p->m_argsType.push_back(V_UINT64);      //new dbid 
            m_methods.insert(make_pair(MSGID_BASEAPP_TABLE_INSERT_CALLBACK, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT32);      //ref
            p->m_argsType.push_back(V_UINT8);       //ret
            m_methods.insert(make_pair(MSGID_BASEAPP_TABLE_EXCUTE_CALLBACK, p));

            // p = new _SEntityDefMethods;
            // p->m_argsType.push_back(V_INT32);     //ref
            // p->m_argsType.push_back(V_UINT16);    //status id
            // p->m_argsType.push_back(V_STR);    //update items status
            // m_methods.insert(make_pair(MSGID_BASEAPP_INC_UPDATE_ITEMS_CALLBACK, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT16);      //bc msg_id
            p->m_argsType.push_back(V_STR);         //bc msg_str
            m_methods.insert(make_pair(MSGID_BASEAPP_CROSSCLIENT_BROADCAST, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT32); 
            p->m_argsType.push_back(V_UINT32); 
            p->m_argsType.push_back(V_INT8); 
            p->m_argsType.push_back(V_STR); 
            m_methods.insert(make_pair(MSGID_BASEAPP_TABLE2EXCUTE_RESP, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT32);
            p->m_argsType.push_back(V_UINT32);
            p->m_argsType.push_back(V_UINT64);
            p->m_argsType.push_back(V_STR);
            m_methods.insert(make_pair(MSGID_BASEAPP_TABLE2INSERT_RESP, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT32);      //不走通用解析流程,随便给个值好了
            //p->m_argsType.push_back(V_UINT32);
            //p->m_argsType.push_back(V_STR);
            //p->m_argsType.push_back(V_UINT16);
            //blob
            m_methods.insert(make_pair(MSGID_BASEAPP_TABLE2SELECT_RESP, p));
            
        }

        //cellapp
        {
            _SEntityDefMethods* p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_ENTITYMB);    //base mb
            p->m_argsType.push_back(V_UINT16);      //entity type id
#ifdef __USE_MSGPACK
            p->m_argsType.push_back(V_BLOB);        //other params
#else
            p->m_argsType.push_back(V_STR);         //other params
#endif
            p->m_argsType.push_back(V_BLOB);

            m_methods.insert(make_pair(MSGID_CELLAPP_CREATE_CELL_IN_NEW_SPACE, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);         //lua code
            m_methods.insert(make_pair(MSGID_CELLAPP_LUA_DEBUG, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT32);      //entity id
            p->m_argsType.push_back(V_ENTITYMB);    //src base mb
            p->m_argsType.push_back(V_INT16);       //x
            p->m_argsType.push_back(V_INT16);       //y
            p->m_argsType.push_back(V_STR);         //mask string
            p->m_argsType.push_back(V_BLOB);
            m_methods.insert(make_pair(MSGID_CELLAPP_CREATE_CELL_VIA_MYCELL, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT16);      //baseapp id
            p->m_argsType.push_back(V_UINT32);      //eid
            m_methods.insert(make_pair(MSGID_CELLAPP_DESTROY_CELLENTITY, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT32);      //eid
            m_methods.insert(make_pair(MSGID_CELLAPP_PICKLE_CLIENT_ATTRIS, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT32);      //eid
            m_methods.insert(make_pair(MSGID_CELLAPP_PICKLE_AOI_ENTITIES, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT32);      //eid
            m_methods.insert(make_pair(MSGID_CELLAPP_LOSE_CLIENT, p));

            p = new _SEntityDefMethods;
            m_methods.insert(make_pair(MSGID_CELLAPP_ON_TIME_MOVE, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT32);      //eid
            p->m_argsType.push_back(V_UINT8);
            m_methods.insert(make_pair(MSGID_CELLAPP_SET_VISIABLE, p));
        }

        //dbmgr
        {
            _SEntityDefMethods* p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_ENTITYMB);      //mb
            p->m_argsType.push_back(V_INT32);         //ref
            p->m_argsType.push_back(V_ENTITY);        //entity props
            m_methods.insert(make_pair(MSGID_DBMGR_INSERT_ENTITY, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_ENTITYMB);        //mb
            p->m_argsType.push_back(V_UINT64);          //dbid
            p->m_argsType.push_back(V_ENTITY);          //entity props
            m_methods.insert(make_pair(MSGID_DBMGR_UPDATE_ENTITY, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_ENTITYMB);        //mb
            p->m_argsType.push_back(V_UINT64);          //dbid
            p->m_argsType.push_back(V_ENTITY);          //entity props
            m_methods.insert(make_pair(MSGID_DBMGR_UPDATE_ENTITY_REDIS, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT16);          //server id
            p->m_argsType.push_back(V_STR);             //entity name
            p->m_argsType.push_back(V_UINT64);          //dbid
            p->m_argsType.push_back(V_INT32);           //callback
            m_methods.insert(make_pair(MSGID_DBMGR_SELECT_ENTITY, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT16);          //mb id
            p->m_argsType.push_back(V_INT32);           //client fd
            p->m_argsType.push_back(V_STR);             //account name
#if __PLAT_PLUG_IN || __PLAT_PLUG_IN_NEW
#else
            p->m_argsType.push_back(V_STR);             //passwd
#endif
            m_methods.insert(make_pair(MSGID_DBMGR_SELECT_ACCOUNT, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);             //sql
            m_methods.insert(make_pair(MSGID_DBMGR_RAW_MODIFY_NORESP, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT16);          //baseapp mb id
            p->m_argsType.push_back(V_UINT8);           //create flag
            p->m_argsType.push_back(V_STR);             //entity name
            p->m_argsType.push_back(V_STR);             //key
            m_methods.insert(make_pair(MSGID_DBMGR_CREATEBASE_FROM_NAME, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);             //entity name
            p->m_argsType.push_back(V_STR);             //index name
            m_methods.insert(make_pair(MSGID_DBMGR_LOAD_ALL_AVATAR, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);             //entity name
            p->m_argsType.push_back(V_UINT16);          //baseapp id
            m_methods.insert(make_pair(MSGID_DBMGR_LOAD_ENTITIES_OF_TYPE, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT8);
            m_methods.insert(make_pair(MSGID_DBMGR_SHUTDOWN_SERVER, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_ENTITYMB);        //entity mb
            p->m_argsType.push_back(V_STR);             //attri name
            p->m_argsType.push_back(V_STR);             //hash key
            m_methods.insert(make_pair(MSGID_DBMGR_REDIS_HASH_LOAD, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);             //key
            p->m_argsType.push_back(V_INT32);           //seq
            p->m_argsType.push_back(V_STR);             //value
            m_methods.insert(make_pair(MSGID_DBMGR_REDIS_HASH_SET, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);             //key
            p->m_argsType.push_back(V_INT32);           //seq
            m_methods.insert(make_pair(MSGID_DBMGR_REDIS_HASH_DEL, p));

            p = new _SEntityDefMethods;
            //p->m_argsType.push_back(V_ENTITYMB);        //entity mb
            p->m_argsType.push_back(V_STR);             //account name
            p->m_argsType.push_back(V_STR);             //entity type
            m_methods.insert(make_pair(MSGID_DBMGR_DEL_ACCOUNT_CACHE, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);                //table name
            p->m_argsType.push_back(V_UINT64);             //dbid
            p->m_argsType.push_back(V_UINT16);            //baseapp id
            p->m_argsType.push_back(V_INT32);             //ref
            p->m_argsType.push_back(V_STR);             //update items data
            m_methods.insert(make_pair(MSGID_DBMGR_UPDATE_ITEMS, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);             //item name
            p->m_argsType.push_back(V_UINT64);            //dbid
            p->m_argsType.push_back(V_UINT16);           //baseapp id
            p->m_argsType.push_back(V_INT32);          //ref
            m_methods.insert(make_pair(MSGID_DBMGR_LOADING_ITEMS, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT16);           //baseapp id
            p->m_argsType.push_back(V_UINT32);           //entity id
            p->m_argsType.push_back(V_STR);              //CallBack id
            p->m_argsType.push_back(V_STR);              //table name
            p->m_argsType.push_back(V_STR);              //sql
            m_methods.insert(make_pair(MSGID_DBMGR_TABLE_SELECT, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);                //table name
            p->m_argsType.push_back(V_STR);                //field name
            p->m_argsType.push_back(V_UINT16);            //baseapp id
            p->m_argsType.push_back(V_INT32);             //ref
            p->m_argsType.push_back(V_STR);             //update items data
            m_methods.insert(make_pair(MSGID_DBMGR_UPDATE_BATCH, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT16);           //baseapp id
            p->m_argsType.push_back(V_STR);              //sql
            p->m_argsType.push_back(V_UINT32);           //ref
            m_methods.insert(make_pair(MSGID_DBMGR_TABLE_INSERT, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT16);           //baseapp id
            p->m_argsType.push_back(V_STR);              //sql
            p->m_argsType.push_back(V_UINT32);           //ref 
            m_methods.insert(make_pair(MSGID_DBMGR_TABLE_EXCUTE, p));

            p = new _SEntityDefMethods;  
            p->m_argsType.push_back(V_STR);              //table name
            p->m_argsType.push_back(V_STR);              //option type
            p->m_argsType.push_back(V_UINT16);           //baseapp id
            p->m_argsType.push_back(V_INT32);           //ref 
            p->m_argsType.push_back(V_STR);              //item data
            m_methods.insert(make_pair(MSGID_DBMGR_INCREMENTAL_UPDATE_ITEMS, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT16);
            p->m_argsType.push_back(V_UINT32);
            p->m_argsType.push_back(V_UINT32);
            p->m_argsType.push_back(V_STR);
            m_methods.insert(make_pair(MSGID_DBMGR_TABLE2_EXCUTE, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT16);
            p->m_argsType.push_back(V_UINT32);
            p->m_argsType.push_back(V_UINT32);
            p->m_argsType.push_back(V_ENTITY);
            m_methods.insert(make_pair(MSGID_DBMGR_TABLE2_INSERT, p));   

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_UINT16);
            p->m_argsType.push_back(V_UINT32);
            p->m_argsType.push_back(V_UINT32);
            p->m_argsType.push_back(V_STR);
            p->m_argsType.push_back(V_STR);
            m_methods.insert(make_pair(MSGID_DBMGR_TABLE2_SELECT, p));

        }
        //SERVER_LOG
        {
            _SEntityDefMethods* p = new _SEntityDefMethods;
            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);              //sql
            m_methods.insert(make_pair(MSGID_LOG_INSERT, p));


            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);              //url
            m_methods.insert(make_pair(MSGID_OTHER_HTTP_REQ, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);        //name
            p->m_argsType.push_back(V_ENTITYMB);   //mb
            m_methods.insert(make_pair(MSGID_OTHER_ADD_GLOBALBASE, p));
            
            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);              //func_str
			p->m_argsType.push_back(V_STR);              //params_str
            m_methods.insert(make_pair(MSGID_OTHER_YUNYING_API, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_INT32);              //client fd
            p->m_argsType.push_back(V_STR);              //result
            m_methods.insert(make_pair(MSGID_OTHER_CLIENT_RESPONSE, p));

            p = new _SEntityDefMethods;
            p->m_argsType.push_back(V_STR);              //url
            p->m_argsType.push_back(V_INT32);            //client fd
            p->m_argsType.push_back(V_STR);              //strAccount
            p->m_argsType.push_back(V_STR);              //strPlatId
            m_methods.insert(make_pair(MSGID_OTHER_LOGIN_VERIFY, p));

			p = new _SEntityDefMethods;
			p->m_argsType.push_back(V_STR);              //url
			m_methods.insert(make_pair(MSGID_OTHER_PLAT_API, p));
        }

        ////crossserver
        //{
        //    _SEntityDefMethods* p = new _SEntityDefMethods;
        //    p->m_argsType.push_back(V_ENTITYMB);
        //    p->m_argsType.push_back(V_STR);
        //    m_methods.insert(make_pair(MSGID_CROSSSERVER_REGISTER_SERVER, p));
        //}

    }

    CRpcUtil::~CRpcUtil()
    {
        ClearMap(m_methods);
    }

    _SEntityDefMethods* CRpcUtil::GetDef(pluto_msgid_t msgid)
    {
        map<pluto_msgid_t, _SEntityDefMethods*>::const_iterator iter = m_methods.find(msgid);
        if(iter != m_methods.end())
        {
            return iter->second;
        }
        else
        {
            return NULL;
        }
    }

    T_VECTOR_OBJECT* CRpcUtil::Decode(CPluto& u)
    {
        u.Decode();
        pluto_msgid_t msg_id = u.GetMsgId();

        map<pluto_msgid_t, _SEntityDefMethods*>::const_iterator iter = m_methods.find(msg_id);
        if(iter != m_methods.end())
        {
            list<VTYPE>& refs = iter->second->m_argsType;
            T_VECTOR_OBJECT* ll = new T_VECTOR_OBJECT;
            ll->reserve(refs.size());
            list<VTYPE>::const_iterator iter2 = refs.begin();
            for(; iter2 != refs.end(); ++iter2)
            {
                VOBJECT* v = new VOBJECT;
                u.FillVObject(*iter2, *v);
                ll->push_back(v);

                if(u.GetDecodeErrIdx() > 0)
                {
                    break;
                }
            }
            return ll;
        }
        else
        {
            switch(msg_id)
            {
                case MSGID_BASEAPP_ENTITY_RPC:
                    return DecodeBaseEntityRpc(u);
                case MSGID_CELLAPP_ENTITY_RPC:
                    return DecodeCellEntityRpc(u);
                case MSGID_BASEAPP_CLIENT_RPCALL:
                    return DecodeBaseClientRpc(u);
                case MSGID_BASEAPP_ENTITY_ATTRI_SYNC:
                    return DecodeEntityAttriSync(u);
                case MSGID_CELLAPP_ENTITY_ATTRI_SYNC:
                    return DecodeEntityAttriSync(u);
                case MSGID_CELLAPP_CLIENT_MOVE_REQ:
                    return DecodeClientMoveReq(u);
                case MSGID_BASEAPP_BROADCAST_CLIENT_PRC:
                    return DecodeBroadcastClientRpc(u);
                case MSGID_CELLAPP_CLIENT_OTHERS_MOVE_REQ:
                    return DecodeClientOthersMoveReq(u);
            }
        }

        return NULL;
    }

    //解析通用格式(可以配置在m_method里)的rpc调用
    T_VECTOR_OBJECT* CRpcUtil::DecodeGeneralRpc(CPluto& u)
    {
        return NULL;
    }

    //发到base的entity rpc调用
    T_VECTOR_OBJECT* CRpcUtil::DecodeBaseEntityRpc(CPluto& u)
    {
        T_VECTOR_OBJECT* ll = new T_VECTOR_OBJECT;

        VOBJECT* v = new VOBJECT;
        u.FillVObject(V_ENTITYMB, *v);
        ll->push_back(v);
        if(u.GetDecodeErrIdx() > 0)
        {
            return ll;
        }
        CEntityMailbox& mb = VOBJECT_GET_EMB(v);

        //取funcid
        v = new VOBJECT;
        u.FillVObject(V_UINT16, *v);
        ll->push_back(v);
        if(u.GetDecodeErrIdx() > 0)
        {
            return ll;
        }
        int32_t nFuncId = (int32_t)VOBJECT_GET_U16(v);

        const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByType(mb.m_nEntityType);
        if(pDef)
        {
            const string& strFunc = pDef->m_baseMethodsMap.GetStrByInt(nFuncId);
            map<string, _SEntityDefMethods*>::const_iterator iter11 = pDef->m_baseMethods.find(strFunc);
            if(iter11 != pDef->m_baseMethods.end())
            {
                _SEntityDefMethods* pMethods = iter11->second;
                list<VTYPE>& refs = pMethods->m_argsType;
                list<VTYPE>::const_iterator iter2 = refs.begin();
                for(; iter2 != refs.end(); ++iter2)
                {
                    VOBJECT* v = new VOBJECT;
                    u.FillVObject(*iter2, *v);
                    ll->push_back(v);

                    if(u.GetDecodeErrIdx() > 0)
                    {
                        break;
                    }
                }
                return ll;
            }
        }

        ClearTListObject(ll);
        return NULL;
    }

    //发到cell的entity rpc调用
    T_VECTOR_OBJECT* CRpcUtil::DecodeCellEntityRpc(CPluto& u)
    {
        //特殊处理
        T_VECTOR_OBJECT* ll = new T_VECTOR_OBJECT;

        VOBJECT* v = new VOBJECT;
        u.FillVObject(V_ENTITYMB, *v);
        ll->push_back(v);
        if(u.GetDecodeErrIdx() > 0)
        {
            return ll;
        }
        CEntityMailbox& mb = VOBJECT_GET_EMB(v);

        //取funcid
        v = new VOBJECT;
        u.FillVObject(V_UINT16, *v);
        ll->push_back(v);
        if(u.GetDecodeErrIdx() > 0)
        {
            return ll;
        }
        int32_t nFuncId = (int32_t)VOBJECT_GET_U16(v);

        const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByType(mb.m_nEntityType);
        if(pDef)
        {
            const string& strFunc = pDef->m_cellMethodsMap.GetStrByInt(nFuncId);
            map<string, _SEntityDefMethods*>::const_iterator iter11 = pDef->m_cellMethods.find(strFunc);
            if(iter11 != pDef->m_cellMethods.end())
            {
                _SEntityDefMethods* pMethods = iter11->second;
                list<VTYPE>& refs = pMethods->m_argsType;
                list<VTYPE>::const_iterator iter2 = refs.begin();
                for(; iter2 != refs.end(); ++iter2)
                {
                    VOBJECT* v = new VOBJECT;
                    u.FillVObject(*iter2, *v);
                    ll->push_back(v);

                    if(u.GetDecodeErrIdx() > 0)
                    {
                        break;
                    }
                }
                return ll;
            }
        }

        ClearTListObject(ll);
        return NULL;
    }

    //发到base的来自client的entity rpc调用
    T_VECTOR_OBJECT* CRpcUtil::DecodeBaseClientRpc(CPluto& u)
    {
        CMailBox* mb = u.GetMailbox();
        if(mb == NULL)
        {
            return NULL;
        }
        int fd = mb->GetFd();
        //CWorldBase& the_world = GetWorldbase();
        CWorldBase *pstCWorldBase = dynamic_cast<CWorldBase *>(GetWorld());
        if (pstCWorldBase==NULL)
        {
            LogError("CRpcUtil::DecodeBaseClientRpc", "pstCWorldBase is null.");
            return NULL;
        }
        //CEntityBase* pBase = the_world.GetEntityByFd(fd);
        CEntityBase* pBase = pstCWorldBase->GetEntityByFd(fd);
        if(pBase == NULL)
        {
            return NULL;
        }

#ifdef __PLUTO_ORDER
        //校验rpc包的顺序
        uint16_t PlutoOrder = sz_to_uint16((unsigned char*)u.GetRecvBuff() + MSGLEN_HEAD);
        uint16_t EntityPlutoOrder = pBase->GetPlutoOrder();
        //LogDebug("CRpcUtil::DecodeBaseClientRpc", "PlutoOrder=%d;EntityPlutoOrder=%d", PlutoOrder, EntityPlutoOrder);
#endif

        //const SEntityDef* pDef = the_world.GetDefParser().GetEntityDefByType(pBase->GetEntityType());
        const SEntityDef* pDef = pstCWorldBase->GetDefParser().GetEntityDefByType(pBase->GetEntityType());
        if(pDef == NULL)
        {
            return NULL;
        }

        T_VECTOR_OBJECT* ll = new T_VECTOR_OBJECT;

        VOBJECT* v = new VOBJECT;
        v->vt = V_ENTITY_POINTER;
        v->vv.p = pBase;
        ll->push_back(v);

        uint16_t nFuncId = 0;
        u >> nFuncId;
        if(u.GetDecodeErrIdx() > 0)
        {
            return ll;
        }

        const string& strFunc = pDef->m_baseMethodsMap.GetStrByInt(nFuncId);
        map<string, _SEntityDefMethods*>::const_iterator iter11 = pDef->m_baseMethods.find(strFunc);
        if(iter11 != pDef->m_baseMethods.end())
        {
            _SEntityDefMethods* pMethods = iter11->second;
            if(pMethods->m_bExposed)
            {
                v = new VOBJECT;
                v->vt = V_STR;
                v->vv.s = new string(strFunc);
                ll->push_back(v);

                list<VTYPE>& refs = pMethods->m_argsType;
                list<VTYPE>::const_iterator iter2 = refs.begin();
                for(; iter2 != refs.end(); ++iter2)
                {
                    VOBJECT* v = new VOBJECT;
                    u.FillVObject(*iter2, *v);
                    ll->push_back(v);

                    if(u.GetDecodeErrIdx() > 0)
                    {
                        return ll;
                    }
                }
                return ll;
            }
            //else 该方法不能由客户端调用
        }

        ClearTListObject(ll);
        return NULL;
    }

    T_VECTOR_OBJECT* CRpcUtil::DecodeBroadcastClientRpc(CPluto& u)
    {
        u.Decode();
        T_VECTOR_OBJECT* ll = new T_VECTOR_OBJECT;

        TENTITYTYPE iType = 0;
        u >> iType;
        if(u.GetDecodeErrIdx() > 0)
        {
            return ll;
        }

        uint16_t nFuncId = 0;
        u >> nFuncId;
        if(u.GetDecodeErrIdx() > 0)
        {
            return ll;
        }

        //CWorldBase& the_world = GetWorldbase();
        CWorldBase *pstCWorldBase = dynamic_cast<CWorldBase *>(GetWorld());
        if (pstCWorldBase==NULL)
        {
            return ll;
        }
        const SEntityDef* pDef = pstCWorldBase->GetDefParser().GetEntityDefByType(iType);
        if(pDef == NULL)
        {
            return ll;
        }

        const string& strFunc = pDef->m_clientMethodsMap.GetStrByInt(nFuncId);
        map<string, _SEntityDefMethods*>::const_iterator iter11 = pDef->m_clientMethods.find(strFunc);
        if(iter11 != pDef->m_clientMethods.end())
        {
            _SEntityDefMethods* pMethods = iter11->second;

            VOBJECT* v = new VOBJECT;
            v->vt = V_UINT16;
            v->vv.u16 = iType;
            ll->push_back(v);

            v = new VOBJECT;
            v->vt = V_STR;
            v->vv.s = new string(strFunc);
            ll->push_back(v);

            list<VTYPE>& refs = pMethods->m_argsType;
            list<VTYPE>::const_iterator iter2 = refs.begin();
            for(; iter2 != refs.end(); ++iter2)
            {
                v = new VOBJECT;
                u.FillVObject(*iter2, *v);
                ll->push_back(v);

                if(u.GetDecodeErrIdx() > 0)
                {
                    return ll;
                }
            }
            return ll;
        }

        ClearTListObject(ll);
    }

    //来自客户端的移动请求
    T_VECTOR_OBJECT* CRpcUtil::DecodeClientMoveReq(CPluto& u)
    {
        T_VECTOR_OBJECT* ll = new T_VECTOR_OBJECT;

        u.Decode();

        //entity id
        {
            VOBJECT* v = new VOBJECT;
            u.FillVObject(V_UINT32, *v);

            if(u.GetDecodeErrIdx() > 0)
            {
                delete v;
                return ll;
            }

            ll->push_back(v);
        }

        //list of face,x,y
        //int i = 0;
        while(!u.IsEnd())
        {
            VOBJECT* v = new VOBJECT;

#ifdef __FACE
            u.FillVObject(V_UINT8, *v);
            ll->push_back(v);
            v = new VOBJECT;
#endif

            u.FillVObject(V_INT16, *v);
            ll->push_back(v);

            v = new VOBJECT;
            u.FillVObject(V_INT16, *v);
            ll->push_back(v);

            if(u.GetDecodeErrIdx() > 0)
            {
                return ll;
            }

            ////增加一个判断,只接受某个值以下的坐标对,如果客户端发来的坐标对过多,则丢弃掉一些
            //enum { max_pos_pair_count = 10, };
            //if(++i > max_pos_pair_count)
            //{
            //    return ll;
            //}
        }

        return ll;
    }

    //来自客户端的其他实体移动请求
    T_VECTOR_OBJECT* CRpcUtil::DecodeClientOthersMoveReq(CPluto& u)
    {
        T_VECTOR_OBJECT* ll = new T_VECTOR_OBJECT;

        u.Decode();

        //entity id
        {
            VOBJECT* v = new VOBJECT;
            u.FillVObject(V_UINT32, *v);

            if(u.GetDecodeErrIdx() > 0)
            {
                delete v;
                return ll;
            }

            ll->push_back(v);
        }

        //type UINT8的整数，标识是宠物还是雇佣兵等。。。
        VOBJECT* v = new VOBJECT;
        u.FillVObject(V_UINT8, *v);
        if (u.GetDecodeErrIdx() > 0)
        {
            delete v;
            return ll;
        }
        ll->push_back(v);

        //list of face,x,y
        while(!u.IsEnd())
        {
            VOBJECT* v = new VOBJECT;

#ifdef __FACE
            u.FillVObject(V_UINT8, *v);
            ll->push_back(v);

            v = new VOBJECT;
#endif

            u.FillVObject(V_INT16, *v);
            ll->push_back(v);

            v = new VOBJECT;
            u.FillVObject(V_INT16, *v);
            ll->push_back(v);

            if(u.GetDecodeErrIdx() > 0)
            {
                return ll;
            }
        }

        return ll;
    }

    //属性同步
    T_VECTOR_OBJECT* CRpcUtil::DecodeEntityAttriSync(CPluto& u)
    {
        uint32_t eid;
        uint16_t etype, nPropId;
        u >> eid >> etype >> nPropId;

        const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByType(etype);
        if(pDef)
        {
            const string& strPropName = pDef->m_propertiesMap.GetStrByInt(nPropId);
            map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.find(strPropName);
            if(iter != pDef->m_properties.end())
            {
                if(u.GetDecodeErrIdx() == 0)
                {
                    _SEntityDefProperties* pProp = iter->second;

                    VOBJECT* v = new VOBJECT;
                    u.FillVObject(pProp->m_nType, *v);

                    if(u.GetDecodeErrIdx() == 0)
                    {
                        T_VECTOR_OBJECT* ll = new T_VECTOR_OBJECT;

                        VOBJECT* v2 = new VOBJECT;
                        v2->vt = V_UINT32;
                        v2->vv.u32 = eid;
                        ll->push_back(v2);

                        v2 = new VOBJECT;
                        v2->vt = V_STR;
                        v2->vv.s = new string(strPropName);
                        ll->push_back(v2);

                        ll->push_back(v);

                        //如果带client标记,多添加一个值给world.from_rpc_call
                        if(IsClientFlag(pProp->m_nFlags))
                        {
                            v2 = new VOBJECT;
                            v2->vt = V_UINT16;
                            v2->vv.u16 = nPropId;
                            ll->push_back(v2);
                        }

                        return ll;
                    }
                    else
                    {
                        delete v;
                        return NULL;
                    }
                }
            }

        }

        return NULL;
    }

    //从pluto包解析出entity属性字段列表
    bool CRpcUtil::UnpickleEntityDataFromPluto(CPluto& u, TDBID& dbid, map<string, VOBJECT*> data)
    {
        //const SEntityDef* pDef = GetWorld()->getDefParser().getEntityDefByType();
        //if(pDef)
        //{
        //    TDBID dbid;
        //    u >> dbid;
        //    map<string, VOBJECT*> data;
        //    while(!u.isEnd())
        //    {
        //        uint16_t nPropId;
        //        u >> nPropId;
        //        const string& strPropName = pDef->m_propertiesMap.getStrByInt(nPropId);
        //        map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.find(strPropName);
        //        if(iter == pDef->m_properties.end())
        //        {
        //            return false;
        //        }
        //        VOBJECT* v = new VOBJECT;
        //        u.FillVObject(iter->second->m_nType, *v);
        //        data.insert(make_pair(strPropName, v));
        //    }
        //}

        //return pDef != NULL;

        return false;
    }

}



