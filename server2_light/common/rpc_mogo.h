#ifndef __RPC__MOGO__HEAD__
#define __RPC__MOGO__HEAD__

#include "type_mogo.h"
#include "pluto.h"
#include "defparser.h"
#include "logger.h"


namespace mogo
{

    enum MSGID_ENUM_TYPE
    {
        //服务器发给客户端的包
        MSGID_CLIENT_LOGIN_RESP                 = 1,                                  //服务器发给客户端的账号登录结果
        MSGID_CLIENT_NOTIFY_ATTACH_BASEAPP      = 2,                                  //连接baseapp通知
        MSGID_CLIENT_ENTITY_ATTACHED            = 3,                                  //通知客户端已经attach到一个服务器entity,同时刷数据
        MSGID_CLIENT_AVATAR_ATTRI_SYNC          = 4,                                  //AVATAR相关属性修改同步
        MSGID_CLIENT_RPC_RESP                   = 5,                                  //服务器发给客户端的rpc
        MSGID_CLIENT_ENTITY_POS_SYNC            = 6,                                  //服务器告诉客户端坐标变化(move)
        //MSGID_CLIENT_ENTITY_SPACE_CHANGE        = 7,                                  //服务器告诉客户端场景变化
        MSGID_CLIENT_AOI_ENTITIES               = 8,                                  //服务器告诉客户端aoi范围内的entity
        MSGID_CLIENT_AOI_NEW_ENTITY             = 9,                                  //服务器告诉客户端aoi范围内新增的entity
        MSGID_CLIENT_ENTITY_CELL_ATTACHED       = 10,                                 //服务器打包给客户端的cell_client属性
        MSGID_CLIENT_OTHER_ENTITY_ATTRI_SYNC    = 11,                                 //其他entity属性变化同步
        MSGID_CLIENT_OTHER_ENTITY_POS_SYNC      = 12,                                 //其他entity坐标变化同步(move)
        MSGID_CLIENT_OTHER_ENTITY_MOVE_REQ      = 13,                                 //服务器转发的其他entity的移动请求
        //MSGID_CLIENT_OTHER_RPC_RESP             = 14,                                 //对其他客户端entity的rpc
        MSGID_CLIENT_AOI_DEL_ENTITY             = 15,                                 //有entity离开了aoi

        MSGID_CLIENT_ENTITY_POS_PULL            = 16,                                 //服务器告诉客户端坐标变化(拉扯)
        MSGID_CLIENT_OTHER_ENTITY_POS_PULL      = 17,                                 //服务器转发的其他entity的移动请求(拉扯)
        MSGID_CLIENT_ENTITY_POS_TELEPORT        = 18,                                 //服务器告诉客户端坐标变化(teleport)
        MSGID_CLIENT_OTHER_ENTITY_TELEPORT      = 19,                                 //服务器转发的其他entity的移动请求(teleport)
        MSGID_CLIENT_CHECK_RESP                 = 20,

#ifdef __RELOGIN
        MSGID_CLIENT_RELOGIN_KEY_NOT_EXIT       = 21,                                 //断线重连时，服务器通知客户端key已经不存在
#endif
        MSGID_CLIENT_NOTIFY_MULTILOGIN          = 22,                                 //服务器通知新的客户端断开连接


        //客户端发给服务器的包
        MSGID_LOGINAPP_CHECK                    = 30,                                 //客户端版本校验
        MSGID_LOGINAPP_LOGIN                    = 31,                                 //客户端输入帐户名/密码进行登录验证
        MSGID_BASEAPP_CLIENT_LOGIN              = 32,
        MSGID_BASEAPP_CLIENT_RPCALL             = 33,                                 //客户端发起的远程调用
        MSGID_BASEAPP_CLIENT_MOVE_REQ           = 34,                                 //客户端发起的移动
        MSGID_BASEAPP_CLIENT_RPC2CELL_VIA_BASE  = 35,                                 //客户端发起的(途经base的)cell方法调用
        MSGID_BASEAPP_CLIENT_OTHERS_MOVE_REQ    = 36,                                 //客户端发起的其他entity的移动(宠物、雇佣兵等)

#ifdef __RELOGIN
        MSGID_BASEAPP_CLIENT_RELOGIN            = 37,                                 //客户端断线重连
#endif

        //暂定50以下的是客户端和服务器的交互包,需要加密
        MAX_CLIENT_SERVER_MSGID                 = 50,

        MSGID_ALLAPP_ONTICK                     = 101,                                //心跳消息
        MSGID_ALLAPP_SETTIME                    = 102,                                //同步时间消息
        MSGID_ALLAPP_SHUTDOWN_SERVER            = 103,                                //关闭服务器通知

        //MSGID_LOGINAPP_LOGIN                    = MSGTYPE_LOGINAPP + 1,             //客户端输入帐户名/密码进行登录验证
        MSGID_LOGINAPP_MODIFY_LOGIN_FLAG        = MSGTYPE_LOGINAPP + 6,               //修改服务器是否可以登录标记
        MSGID_LOGINAPP_SELECT_ACCOUNT_CALLBACK  = MSGTYPE_LOGINAPP + 7,
        MSGID_LOGINAPP_NOTIFY_CLIENT_TO_ATTACH  = MSGTYPE_LOGINAPP + 8,
        MSGID_LOGINAPP_FORBIDLOGIN              = MSGTYPE_LOGINAPP + 9,               //禁止登陆
        MSGID_LOGINAPP_MODIFY_ONLINE_COUNT      = MSGTYPE_LOGINAPP + 10,              //修改服务器当前在线人数
        MSGID_LOGINAPP_LOGIN_VERIFY_CALLBACK    = MSGTYPE_LOGINAPP + 11,              //sdk服务器验证返回
        MSGID_LOGINAPP_FORBID_IP_UNTIL_TIME     = MSGTYPE_LOGINAPP + 12,               //禁止ip登陆到截止时间
        MSGID_LOGINAPP_FORBID_ACCOUNT_UNTIL_TIME= MSGTYPE_LOGINAPP + 13,               //禁止账号登陆到截止时间
        MSGID_LOGINAPP_NOTIFY_CLIENT_MULTILOGIN = MSGTYPE_LOGINAPP + 14,               //通知新的客户端断开连接
        MSGID_LOGINAPP_WEBLOGIN                 = MSGTYPE_LOGINAPP + 15,               //来自自带web服务器的登陆

        MSGID_BASEAPPMGR_REGISTERGLOBALLY       = MSGTYPE_BASEAPPMGR + 1,
        MSGID_BASEAPPMGR_CREATEBASE_ANYWHERE    = MSGTYPE_BASEAPPMGR + 2,               //
        MSGID_BASEAPPMGR_CREATEBASE_FROM_DBID_ANYWHERE = MSGTYPE_BASEAPPMGR + 3,        //
        MSGID_BASEAPPMGR_CREATEBASE_FROM_NAME_ANYWHERE = MSGTYPE_BASEAPPMGR + 4,        //
        MSGID_BASEAPPMGR_CREATE_CELL_IN_NEW_SPACE      = MSGTYPE_BASEAPPMGR + 5,        //
        MSGID_BASEAPPMGR_SHUTDOWN_SERVERS       = MSGTYPE_BASEAPPMGR + 6,               //停止服务器
        MSGID_BASEAPPMGR_ON_SERVER_SHUTDOWN     = MSGTYPE_BASEAPPMGR + 7,               //某个服务器进程停止后的回调方法
        MSGID_BASEAPPMGR_CREATEBASE_FROM_NAME   = MSGTYPE_BASEAPPMGR + 8,               //
        MSGID_BASEAPPMGR_SHUTDOWN_SERVERS_CALLBACK = MSGTYPE_BASEAPPMGR + 9,            //关闭服务器的回应

        MSGID_BASEAPP_REGISTERGLOBALLY_CALLBACK = MSGTYPE_BASEAPP + 1,
        MSGID_BASEAPP_ADD_GLOBALBASE            = MSGTYPE_BASEAPP + 2,
        MSGID_BASEAPP_DEL_GLOBALBASE            = MSGTYPE_BASEAPP + 3,
        MSGID_BASEAPP_INSERT_ENTITY_CALLBACK    = MSGTYPE_BASEAPP + 4,
        MSGID_BASEAPP_SELECT_ENTITY_CALLBACK    = MSGTYPE_BASEAPP + 5,
        MSGID_BASEAPP_UPDATE_ENTITY_CALLBACK    = MSGTYPE_BASEAPP + 6,
        MSGID_BASEAPP_LOOKUP_ENTITY_CALLBACK    = MSGTYPE_BASEAPP + 7,
        MSGID_BASEAPP_ENTITY_MULTILOGIN         = MSGTYPE_BASEAPP + 8,                //多个客户端登录到一个entity
        MSGID_BASEAPP_LOAD_ALL_AVATAR           = MSGTYPE_BASEAPP + 9,                //脚本发起的load所有Avatar
        MSGID_BASEAPP_ON_GET_CELL               = MSGTYPE_BASEAPP + 10,               //get cell
        MSGID_BASEAPP_CREATE_CELL_VIA_MYCELL    = MSGTYPE_BASEAPP + 11,               //通过一个有cell的base来创建另外一个base的cell
        MSGID_BASEAPP_CREATE_CELL_FAILED        = MSGTYPE_BASEAPP + 12,               //创建cell失败的回调方法
        MSGID_BASEAPP_LOAD_ENTITIES_OF_TYPE     = MSGTYPE_BASEAPP + 13,               //脚本发起的load一个类型的所有entity
        MSGID_BASEAPP_LOAD_ENTITIES_END_MSG     = MSGTYPE_BASEAPP + 14,               //load entities的结束消息包
        MSGID_BASEAPP_ON_LOSE_CELL              = MSGTYPE_BASEAPP + 15,               //cell destroy之后的回调方法
        MSGID_BASEAPP_CREATE_BASE_ANYWHERE      = MSGTYPE_BASEAPP + 16,               //
        MSGID_BASEAPP_SET_BASE_DATA             = MSGTYPE_BASEAPP + 17,               //设置全base数据
        MSGID_BASEAPP_DEL_BASE_DATA             = MSGTYPE_BASEAPP + 18,               //删除全base数据
        MSGID_BASEAPP_ON_REDIS_HASH_LOAD        = MSGTYPE_BASEAPP + 19,               //redis_hash数据load之后的回调方法
        MSGID_BASEAPP_CELL_ATTRI_SYNC           = MSGTYPE_BASEAPP + 20,               //cell_and_client属性通过base同步给客户端
        MSGID_BASEAPP_AVATAR_POS_SYNC           = MSGTYPE_BASEAPP + 21,               //avatar自己在cell上的坐标同步给base
        MSGID_BASEAPP_DEL_ACCOUNT_CACHE_CALLBACK= MSGTYPE_BASEAPP + 22,               //通知basedbmgr上的account缓存已经删除

        MSGID_BASEAPP_ENTITY_RPC                = MSGTYPE_BASEAPP + 80,               //服务器端进程发起的基于entity的rpc
        MSGID_BASEAPP_LUA_DEBUG                 = MSGTYPE_BASEAPP + 90,               //调试lua脚本
        MSGID_BASEAPP_ENTITY_ATTRI_SYNC         = MSGTYPE_BASEAPP + 91,
        MSGID_BASEAPP_CLIENT_RPC_VIA_BASE       = MSGTYPE_BASEAPP + 92,               //通过base转发的client rpc调用
        MSGID_BASEAPP_TIME_SAVE                 = MSGTYPE_BASEAPP + 93,               //定时存盘
        MSGID_BASEAPP_CLIENT_MSG_VIA_BASE       = MSGTYPE_BASEAPP + 94,               //通过base转发的client消息包,注意与92的区别
        MSGID_BASEAPP_ITEMS_LOADING_CALLBACK    = MSGTYPE_BASEAPP + 95,               //指定avatar背包数据装载回调请求
        MSGID_BASEAPP_UPDATE_ITEMS_CALLBACK     = MSGTYPE_BASEAPP + 96,               //udpate items data 回调请求
        MSGID_BASEAPP_TABLE_SELECT_CALLBACK     = MSGTYPE_BASEAPP + 97,               //TableSelect的回调
        MSGID_BASEAPP_BROADCAST_CLIENT_PRC      = MSGTYPE_BASEAPP + 98,               //全服广播的client rpc调用
        MSGID_BASEAPP_TABLE_UPDATE_BATCH_CB     = MSGTYPE_BASEAPP + 99,               //TableUpdateBatch的回调
        MSGID_BASEAPP_TABLE_INSERT_CALLBACK     = MSGTYPE_BASEAPP + 100,              //TableInsert的回调
        //MSGID_BASEAPP_CLIENT_LOGIN              = MSGTYPE_BASEAPP + 100,
        //MSGID_BASEAPP_CLIENT_RPCALL             = MSGTYPE_BASEAPP + 101,              //客户端发起的远程调用
        MSGID_BASEAPP_TABLE_EXCUTE_CALLBACK     = MSGTYPE_BASEAPP + 102,              //TableInsert的回调
        MSGID_BASEAPP_INSERT_ITEMS_CALLBACK     = MSGTYPE_BASEAPP + 103,              //insert item call back
        MSGID_BASEAPP_CROSSCLIENT_BROADCAST     = MSGTYPE_BASEAPP + 104,                //broadcast from crossserver
        MSGID_BASEAPP_TABLE2EXCUTE_RESP         = MSGTYPE_BASEAPP + 105,
        MSGID_BASEAPP_TABLE2SELECT_RESP         = MSGTYPE_BASEAPP + 106,
        MSGID_BASEAPP_TABLE2INSERT_RESP         = MSGTYPE_BASEAPP + 107,

        MSGID_CELLAPP_CREATE_CELL_IN_NEW_SPACE  = MSGTYPE_CELLAPP + 1,
        MSGID_CELLAPP_ENTITY_RPC                = MSGTYPE_CELLAPP + 2,
        MSGID_CELLAPP_CREATE_CELL_VIA_MYCELL    = MSGTYPE_CELLAPP + 3,
        MSGID_CELLAPP_DESTROY_CELLENTITY        = MSGTYPE_CELLAPP + 4,
        MSGID_CELLAPP_PICKLE_CLIENT_ATTRIS      = MSGTYPE_CELLAPP + 5,                //BASE通知cell打包所有client属性
        MSGID_CELLAPP_PICKLE_AOI_ENTITIES       = MSGTYPE_CELLAPP + 6,                //base通知cell打包aoi内所有entity
        MSGID_CELLAPP_CLIENT_MOVE_REQ           = MSGTYPE_CELLAPP + 7,                //客户端发起的移动
        MSGID_CELLAPP_LOSE_CLIENT               = MSGTYPE_CELLAPP + 8,
        MSGID_CELLAPP_ON_TIME_MOVE              = MSGTYPE_CELLAPP + 9,                //entity time move
        MSGID_CELLAPP_SET_VISIABLE              = MSGTYPE_CELLAPP + 10,               //
        MSGID_CELLAPP_CLIENT_OTHERS_MOVE_REQ    = MSGTYPE_CELLAPP + 11,               //客户端发起的其他实体移动(宠物、雇佣兵等)


        MSGID_CELLAPP_LUA_DEBUG                 = MSGTYPE_CELLAPP + 90,               //调试lua脚本
        MSGID_CELLAPP_ENTITY_ATTRI_SYNC         = MSGTYPE_CELLAPP + 91,


        MSGID_DBMGR_INSERT_ENTITY               = MSGTYPE_DBMGR + 1,
        MSGID_DBMGR_UPDATE_ENTITY               = MSGTYPE_DBMGR + 2,
        MSGID_DBMGR_DELETE_ENTITY               = MSGTYPE_DBMGR + 3,
        MSGID_DBMGR_SELECT_ENTITY               = MSGTYPE_DBMGR + 4,
        MSGID_DBMGR_SELECT_ACCOUNT              = MSGTYPE_DBMGR + 5,
        MSGID_DBMGR_RAW_SELECT                  = MSGTYPE_DBMGR + 6,                    //指定sql语句的select
        MSGID_DBMGR_RAW_MODIFY                  = MSGTYPE_DBMGR + 7,                    //指定sql语句的DELETE/UPDATE等
        MSGID_DBMGR_RAW_MODIFY_NORESP           = MSGTYPE_DBMGR + 8,                    //(不需要返回结果)指定sql语句的DELETE/UPDATE等
        MSGID_DBMGR_CREATEBASE                  = MSGTYPE_DBMGR + 9,                    //
        MSGID_DBMGR_CREATEBASE_FROM_DBID        = MSGTYPE_DBMGR + 10,                   //
        MSGID_DBMGR_CREATEBASE_FROM_NAME        = MSGTYPE_DBMGR + 11,                   //
        MSGID_DBMGR_LOAD_ALL_AVATAR             = MSGTYPE_DBMGR + 12,
        MSGID_DBMGR_LOAD_ENTITIES_OF_TYPE       = MSGTYPE_DBMGR + 13,
        MSGID_DBMGR_SHUTDOWN_SERVER             = MSGTYPE_DBMGR + 14,
        MSGID_DBMGR_REDIS_HASH_LOAD             = MSGTYPE_DBMGR + 15,
        MSGID_DBMGR_REDIS_HASH_SET              = MSGTYPE_DBMGR + 16,
        MSGID_DBMGR_REDIS_HASH_DEL              = MSGTYPE_DBMGR + 17,
        MSGID_DBMGR_UPDATE_ENTITY_REDIS         = MSGTYPE_DBMGR + 18,
        MSGID_DBMGR_DEL_ACCOUNT_CACHE           = MSGTYPE_DBMGR + 19,                   //删除账号缓存：查找信息
        MSGID_DBMGR_UPDATE_ITEMS                = MSGTYPE_DBMGR + 20,                   //背包道具数据更新
        MSGID_DBMGR_LOADING_ITEMS               = MSGTYPE_DBMGR + 21,                   //背包数据装载
        MSGID_DBMGR_TABLE_SELECT                = MSGTYPE_DBMGR + 22,                   //查询某张表
        MSGID_DBMGR_UPDATE_BATCH                = MSGTYPE_DBMGR + 23,                   //根据某个字段批量更新表数据
        MSGID_DBMGR_TABLE_INSERT                = MSGTYPE_DBMGR + 24,                   //插入某张表
        MSGID_DBMGR_TABLE_EXCUTE                = MSGTYPE_DBMGR + 25,                   //执行某个sql
        MSGID_DBMGR_INCREMENTAL_UPDATE_ITEMS    = MSGTYPE_DBMGR + 26,                   //执行道具更新操作
        MSGID_DBMGR_TABLE2_SELECT               = MSGTYPE_DBMGR + 27,
        MSGID_DBMGR_TABLE2_INSERT               = MSGTYPE_DBMGR + 28,
        MSGID_DBMGR_TABLE2_EXCUTE               = MSGTYPE_DBMGR + 29,        


        MSGID_LOG_INSERT                        = MSGTYPE_LOG + 1,  //日志插入
        MSGID_OTHER_HTTP_REQ                    = MSGTYPE_LOG + 2,  //http请求
        MSGID_OTHER_ADD_GLOBALBASE              = MSGTYPE_LOG + 3,  //把global的mailbox注册到other进程
        MSGID_OTHER_YUNYING_API                 = MSGTYPE_LOG + 4,  //运营支撑接口
	    MSGID_OTHER_CLIENT_RESPONSE             = MSGTYPE_LOG + 5,  //运营支撑接口返回
        
        MSGID_OTHER_LOGIN_VERIFY                = MSGTYPE_LOG + 10, //sdk服务器验证
		MSGID_OTHER_PLAT_API                    = MSGTYPE_LOG + 11, //平台接口

        MSGID_CROSSCLIENT_SERVER_RPC_PROXY      = MSGTYPE_CROSSCLIENT + 1,              //内部进程发给crossclient转发的serverRpc
        MSGID_CROSSCLIENT_RPC                   = MSGTYPE_CROSSCLIENT + 2,
        MSGID_CROSSCLIENT_RESP                  = MSGTYPE_CROSSCLIENT + 3,
        MSGID_CROSSCLIENT_BROADCAST             = MSGTYPE_CROSSCLIENT + 4,

        MSGID_CROSSSERVER_RPC                   = MSGTYPE_CROSSSERVER + 1,
        MSGID_CROSSSERVER_CLIENT_RPC_PROXY      = MSGTYPE_CROSSSERVER + 2,
        MSGID_CROSSSERVER_REGISTER_SERVER       = MSGTYPE_CROSSSERVER + 3,
        MSGID_CROSSSERVER_CLIENT_RESP_PROXY     = MSGTYPE_CROSSSERVER + 4,
        MSGID_CROSSSERVER_CLIENT_BC_PROXY       = MSGTYPE_CROSSSERVER + 5,
        MSGID_CROSSSERVER_CHECK_MD5             = MSGTYPE_CROSSSERVER + 6,

    };


    enum
    {
        MAILBOX_CLIENT_UNAUTHZ = 0,         //来自于客户端的连接,未验证
        MAILBOX_CLIENT_AUTHZ = 1,           //来自于客户端的连接,已验证
        MAILBOX_CLIENT_TRUSTED = 0xf,       //来自于服务器端的可信任连接
    };

    enum EFDTYPE
    {
        FD_TYPE_ERROR = 0,
        FD_TYPE_SERVER = 1,
        FD_TYPE_MAILBOX = 2,
        FD_TYPE_ACCEPT = 3,
    };

    enum ERPCERR
    {	
        ERR_RPC_UNKNOWN_MSGID = -99,   //未知msgid
        ERR_RPC_DECODE        = -98,   //解包错误
        ERR_RPC_LOGIC         = -97,   //逻辑错误
    };

    //检查rpc解包是否出错
    #define CHECK_RPC_DECODE_ERR(u) \
        {\
            if(u.GetDecodeErrIdx()>0)\
            {\
                return ERR_RPC_DECODE;\
            }\
        }

    //检查并获取rpc中的一个字段
    #define CHECK_AND_GET_RPC_FIELD(u, field_var, field_type) \
        field_type field_var;\
        u >> field_var;\
        if(u.GetDecodeErrIdx()>0)\
        {\
            return ERR_RPC_DECODE;\
        }


    //检查并获取rpc中的一个c_str字段
    #define CHECK_AND_GET_RPC_FIELD_CSTR(u, field_var) \
        string _tmp_##field_var;\
        u >> _tmp_##field_var;\
        if(u.GetDecodeErrIdx()>0)\
        {\
            return ERR_RPC_DECODE;\
        }\
        const char* field_var = _tmp_##field_var.c_str();


    //检查并获取rpc中的一个entity属性打包字段
    #define CHECK_AND_GET_RPC_FIELD_PROPS(u, field_var) \
        VOBJECT _tmp_##field_var;\
        _tmp_##field_var.vt = V_ENTITY;\
        _tmp_##field_var.vv.p = new SEntityPropFromPluto;\
        u.UnpickleEntity(_tmp_##field_var);\
        CHECK_RPC_DECODE_ERR(u);\
        SEntityPropFromPluto* field_var = (SEntityPropFromPluto*)(_tmp_##field_var.vv.p);



    class CRpcUtil
    {
        public:
            CRpcUtil();
            ~CRpcUtil();

        private:
            //初始化内嵌(非自定义)的方法
            void InitInnerMethods();

        public:
            template<typename T1>
            void Encode(CPluto& u, pluto_msgid_t msg_id, const T1& p1);
            template<typename T1, typename T2>
            void Encode(CPluto& u, pluto_msgid_t msg_id, const T1& p1, const T2& p2);
            template<typename T1, typename T2, typename T3>
            void Encode(CPluto& u, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3);
            template<typename T1, typename T2, typename T3, typename T4>
            void Encode(CPluto& u, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4);
            template<typename T1, typename T2, typename T3, typename T4, typename T5>
            void Encode(CPluto& u, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5);
            template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6>
            void Encode(CPluto& u, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5, const T6& p6);

        public:
            _SEntityDefMethods* GetDef(pluto_msgid_t msgid);

        public:
            T_VECTOR_OBJECT* Decode(CPluto& u);

        private:
            //解析通用格式(可以配置在m_method里)的rpc调用
            T_VECTOR_OBJECT* DecodeGeneralRpc(CPluto& u);
            T_VECTOR_OBJECT* DecodeBaseEntityRpc(CPluto& u);
            T_VECTOR_OBJECT* DecodeCellEntityRpc(CPluto& u);
            T_VECTOR_OBJECT* DecodeBaseClientRpc(CPluto& u);
            T_VECTOR_OBJECT* DecodeEntityAttriSync(CPluto& u);
            T_VECTOR_OBJECT* DecodeClientMoveReq(CPluto& u);                 //解析客户端移动包
            T_VECTOR_OBJECT* DecodeBroadcastClientRpc(CPluto& u);
            T_VECTOR_OBJECT* DecodeClientOthersMoveReq(CPluto& u);           //解析客户端对其他实体的移动包

        public:
            //从pluto包解析出entity属性字段列表
            bool UnpickleEntityDataFromPluto(CPluto& u, TDBID& dbid, map<string, VOBJECT*> data);

        private:
            map<pluto_msgid_t, _SEntityDefMethods*> m_methods;
            string m_strFuncNameNotfound;

    };

    template<typename T1>
    void CRpcUtil::Encode(CPluto& u, pluto_msgid_t msg_id, const T1& p1)
    {
        //map<pluto_msgid_t, _SEntityDefMethods*>::const_iterator iter = m_methods.find(msg_id);
        //if(iter == m_methods.end())
        //{
        //    LogError("CRpcUtil::encode error", "msg_id=%d", msg_id);
        //    return;
        //}

        u.Encode(msg_id) << p1 << EndPluto;
    }

    template<typename T1, typename T2>
    void CRpcUtil::Encode(CPluto& u, pluto_msgid_t msg_id, const T1& p1, const T2& p2)
    {
        //map<pluto_msgid_t, _SEntityDefMethods*>::const_iterator iter = m_methods.find(msg_id);
        //if(iter == m_methods.end())
        //{
        //    LogError("CRpcUtil::encode error", "msg_id=%d", msg_id);
        //    return;
        //}

        u.Encode(msg_id) << p1 << p2 << EndPluto;
    }

    template<typename T1, typename T2, typename T3>
    void CRpcUtil::Encode(CPluto& u, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3)
    {
        //map<pluto_msgid_t, _SEntityDefMethods*>::const_iterator iter = m_methods.find(msg_id);
        //if(iter == m_methods.end())
        //{
        //    LogError("CRpcUtil::encode error", "msg_id=%d", msg_id);
        //    return;
        //}

        u.Encode(msg_id) << p1 << p2 << p3 << EndPluto;
    }

    template<typename T1, typename T2, typename T3, typename T4>
    void CRpcUtil::Encode(CPluto& u, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4)
    {
        //map<pluto_msgid_t, _SEntityDefMethods*>::const_iterator iter = m_methods.find(msg_id);
        //if(iter == m_methods.end())
        //{
        //    LogError("CRpcUtil::encode error", "msg_id=%d", msg_id);
        //    return;
        //}

        u.Encode(msg_id) << p1 << p2 << p3 << p4 << EndPluto;
    }

    template<typename T1, typename T2, typename T3, typename T4, typename T5>
    void CRpcUtil::Encode(CPluto& u, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5)
    {
        //map<pluto_msgid_t, _SEntityDefMethods*>::const_iterator iter = m_methods.find(msg_id);
        //if(iter == m_methods.end())
        //{
        //    LogError("CRpcUtil::encode error", "msg_id=%d", msg_id);
        //    return;
        //}

        u.Encode(msg_id) << p1 << p2 << p3 << p4 << p5 << EndPluto;
    }

    template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6>
    void CRpcUtil::Encode(CPluto& u, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5, const T6& p6)
    {
        //map<pluto_msgid_t, _SEntityDefMethods*>::const_iterator iter = m_methods.find(msg_id);
        //if(iter == m_methods.end())
        //{
        //    LogError("CRpcUtil::encode error", "msg_id=%d", msg_id);
        //    return;
        //}

        u.Encode(msg_id) << p1 << p2 << p3 << p4 << p5 << p6 << EndPluto;
    }

}



#endif

