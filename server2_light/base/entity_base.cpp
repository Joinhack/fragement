/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：entity_base
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.5
// 模块描述：base entity 基类
//----------------------------------------------------------------*/

#include "entity_base.h"
#include "util.h"
#include "lua_mogo.h"
#include "rpc_mogo.h"
#include "world_select.h"
#include "win_adaptor.h"
#include "memory_pool.h"
#include "logger.h"

namespace mogo
{


    //mogo::MemoryPool* mogo::CEntityBase::memPool = NULL;

    CEntityBase::CEntityBase(TENTITYTYPE etype, TENTITYID nid)
        : CEntityParent(etype, nid), m_nCellState(E_HASNT_CELL), m_nCellSvrId(0), m_ClientFd(-1)

#ifdef __PLUTO_ORDER
        , m_PlutoOrder(0)
#endif

    {
        m_bIsBase = true;
        //LogInfo("CEntityBase::CEntityBase", "id=%d", nid);
    }

    CEntityBase::~CEntityBase()
    {
    }

    //void * CEntityBase::operator new(size_t size, void *ptr)
    //{
    //    if (NULL == memPool)
    //    {
    //        expandMemoryPool();
    //    }

    //    MemoryPool *head = memPool;
    //    memPool = head->next;

    //    LogDebug("CEntityBase new", "size=%d");

    //    return head;
    //}

    //void CEntityBase::operator delete(void* p, size_t size)
    //{
    //    MemoryPool *head = (MemoryPool *)p;
    //    head->next = memPool;
    //    memPool = head;

    //    LogDebug("CEntityBase delete", "size=%d", size);
    //}

    //void CEntityBase::expandMemoryPool()
    //{
    //    size_t size = (sizeof(CEntityBase) > sizeof(MemoryPool *)) ? sizeof(CEntityBase) : sizeof(MemoryPool *);

    //    MemoryPool *runner = (MemoryPool *) new char[size];
    //    memPool = runner;

    //    enum  { EXPAND_SIZE = 32};
    //    for (int i=0; i<EXPAND_SIZE; i++)
    //    {
    //        runner->next = (MemoryPool *) new char[size];
    //        runner = runner->next;
    //    }

    //    runner->next = NULL;
    //}

    //void CEntityBase::DeleteMemPool()
    //{
    //    MemoryPool *nextPtr = NULL;
    //    for (nextPtr = memPool; nextPtr != NULL; nextPtr = memPool)
    //    {
    //        memPool = memPool->next;
    //        delete[] nextPtr;
    //    }
    //}

    //traverse all the def property, and fill the property fields of base
    //with default value, and then saved in map<string, VObject>
    int CEntityBase::init(lua_State* L)
    {
        CEntityParent::init(L);

        //init the property fileds of def
        const SEntityDef* pDef = this->GetEntityDef();
        if(!pDef)
        {
            return 0;
        }
        map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.begin();
        for(; iter != pDef->m_properties.end(); ++iter)
        {
            const _SEntityDefProperties* pp = iter->second;
            if(IsBaseFlag(pp->m_nFlags))
            {
                VOBJECT* v = new VOBJECT;
                v->vt = pp->m_nType;
                FillVObjectDefaultValue(this, iter->first, *v, pp->m_defaultValue);
                m_data.insert(make_pair(iter->first, v));
            }
        }
        return 0;

    }



    void CEntityBase::AddCellMailbox(int32_t n, uint16_t nCellSvrId)
    {
        VOBJECT* v = new VOBJECT;
        v->vt = V_LUATABLE;
        v->vv.i32 = n;

        m_data.insert(make_pair("cell", v) );


        m_nCellSvrId = nCellSvrId;
        m_nCellState = E_CELL_CREATED;


        if(m_bHasClient)
        {
            GetWorld()->RpcCall(nCellSvrId, MSGID_CELLAPP_PICKLE_AOI_ENTITIES, m_id);
        }

    }

    void CEntityBase::RemoveCellMailbox()
    {
        map<string, VOBJECT*>::iterator iter = m_data.find("cell");
        if(iter != m_data.end())
        {
            delete iter->second;
            m_data.erase(iter);
            //LogInfo("CEntityBase::removeCellMailbox", "id=%d", m_id);
        }

        m_nCellSvrId = 0;
        m_nCellState = E_HASNT_CELL;
    }


    int CEntityBase::GetCellServerId()
    {
        if(m_nCellState != E_CELL_CREATED)
        {
            return -1;
        }

        if(m_nCellSvrId == 0)
        {
            return -2;
        }

        return m_nCellSvrId;

        //map<string, VOBJECT*>::const_iterator iter = m_data.find("cell");
        //if(iter == m_data.end())
        //{
        //   return -2;
        //}

        //int nRef = iter->second->vv.i32;
        //world* the_world = GetWorld();
        //lua_State* L = the_world->getLuaState();
        //int m = the_world->GetLuaTables().getobj(L, nRef);

        //lua_rawgeti(L, -1, g_nMailBoxServerIdKey);

        //if(lua_isnumber(L, -1))
        //{
        //   int nServerId = (int)lua_tonumber(L, -1);
        //   lua_pop(L, m + 1);
        //   return nServerId;
        //}

        //lua_pop(L, m + 1);
        //return -3;
    }


    int CEntityBase::GetClientFd()
    {
        map<string, VOBJECT*>::const_iterator iter = m_data.find("client");
        if(iter == m_data.end())
        {
            return -1;
        }

        return m_ClientFd;

        //int nRef = iter->second->vv.i32;
        //world* the_world = GetWorld();
        //lua_State* L = the_world->GetLuaState();
        //int m = the_world->GetLuaTables().GetObj(L, nRef);

        //lua_rawgeti(L, -1, g_nMailBoxServerIdKey);

        //if(lua_isnumber(L, -1))
        //{
        //    int nServerId = (int)lua_tonumber(L, -1);
        //    lua_pop(L, m + 1);
        //    return nServerId;
        //}

        //lua_pop(L, m + 1);
        //return -3;
    }

    uint16_t CEntityBase::GetMailboxId()
    {
        return GetWorld()->GetMailboxId();
    }

    int CEntityBase::lRegisterGlobally(lua_State* L)
    {
        //first param is userdata
        const char* szName = luaL_checkstring(L, 2);
        //printf("CEntityBase::lregisterGlobally(),%d,%s\n", SERVER_BASEAPPMGR, szName);
        luaL_checkany(L, 3);   //callable object

        world& the_world = *GetWorld();
        CLuaCallback& cb = the_world.GetCallback();
        lua_pushvalue(L, 3);
        int ref = cb.Ref(L);

        CMailBox* mb = the_world.GetServerMailbox(SERVER_BASEAPPMGR);
        if(mb)
        {
            mb->RpcCall(the_world.GetRpcUtil(), MSGID_BASEAPPMGR_REGISTERGLOBALLY, m_mymb, szName, (int32_t)ref);
        }

        return 0;
    }

    //一个entity(一般是一个已经registerGlobally成功后的entity)在crossserver进程上将自己注册为跨服服务提供者
    int CEntityBase::lRegisterCrossServer(lua_State* L)
    {
        //first param is userdata
        const char* pszName = luaL_checkstring(L, 2);

        GetWorld()->RpcCall(SERVER_CROSSSERVER, MSGID_CROSSSERVER_REGISTER_SERVER, pszName, m_mymb);

        return 0;
    }


    int CEntityBase::lNotifyClientToAttach(lua_State* L)
    {
        //first param is userdata
        const char* pszAccount = luaL_checkstring(L, 2);

        //测试数据日志
        LogDebug("CEntityBase::lNotifyClientToAttach", "id=%d;Account=%s", m_id, pszAccount);
        //only Account can invoke, and control with scripts
        CWorldBase& worldbase = GetWorldbase();
        CMailBox* mb = worldbase.GetServerMailbox(SERVER_LOGINAPP);
        if(mb)
        {
            const string& key = worldbase.MakeClientLoginKey(pszAccount, m_id);
            mb->RpcCall(worldbase.GetRpcUtil(), MSGID_LOGINAPP_NOTIFY_CLIENT_TO_ATTACH, pszAccount,
                        m_mymb.m_nServerMailboxId, key.c_str());
        }

        return 0;
    }

    int CEntityBase::lNotifyClientMultiLogin(lua_State* L)
    {
        //first param is userdata
        const char* pszAccount = luaL_checkstring(L, 2);

        LogDebug("CEntityBase::lNotifyClientMultiLogin", "id=%d;Account=%s", m_id, pszAccount);

        CWorldBase& worldbase = GetWorldbase();
        CMailBox* mb = worldbase.GetServerMailbox(SERVER_LOGINAPP);
        if(mb)
        {
            mb->RpcCall(worldbase.GetRpcUtil(), MSGID_LOGINAPP_NOTIFY_CLIENT_MULTILOGIN, pszAccount);
        }

        return 0;
    }

    int CEntityBase::lGiveClientTo(lua_State* L)
    {

        CEntityBase* pAnother = (CEntityBase*)luaL_checkudata(L, 2, s_szEntityName);


        static const string strClient = "client";

        map<string, VOBJECT*>::iterator iter = m_data.find(strClient);
        if(iter != m_data.end())
        {

            CWorldBase& worldbase = GetWorldbase();
            CLuaCallback& cb = worldbase.GetLuaTables();
            int ref = (int)(iter->second->vv.i32);
            cb.GetObj(L, ref);

            if(lua_istable(L, -1))
            {
                lua_rawgeti(L, -1, g_nMailBoxServerIdKey);

#ifdef __RELOGIN
                //移交client前，把自己的重登陆key删除掉
                worldbase.ClearClientReLoginKeys(m_id);
#endif

                int fd = (int)lua_tointeger(L, -1);
                pAnother->GiveClient(L, fd);


                worldbase.UpdateClientInfo(fd, pAnother->GetId());
            }

            delete iter->second;
            m_data.erase(iter);
        }

        return 0;
    }

    //获取连接的IP地址
    int CEntityBase::lGetIPAddr(lua_State* L)
    {
        if (this->m_bHasClient)
        {
            int fd = this->GetClientFd();
            CMailBox* mb = GetWorld()->GetServer()->GetClientMailbox(fd);
            if (mb)
            {
                lua_pushstring(L, mb->GetServerName().c_str());
                return 1;
            }
            else
            {
                lua_pushstring(L, "GetIPAddr, client not connected");
                lua_error(L);
                return 0;
            }
        }
        else
        {
            lua_pushstring(L, "GetIPAddr, entity has no client");
            lua_error(L);
            return 0;
        }
    }

    int CEntityBase::GiveClient(lua_State* L, int fd)
    {
        static const string strClient = "client";
        int old_fd = -1;

        ClearLuaStack(L);

        map<string, VOBJECT*>::iterator iter = m_data.lower_bound(strClient);
        if(iter != m_data.end() && iter->first == strClient)
        {

            CWorldBase& the_world = GetWorldbase();
            CLuaCallback& cb = the_world.GetLuaTables();
            int ref = (int)(iter->second->vv.i32);
            cb.GetObj(L, ref);

            LogDebug("CEntityBase::GiveClient", "m_id=%d;ref=%d", m_id, ref);

            if(lua_istable(L, -1))
            {

                lua_rawgeti(L, -1, g_nMailBoxServerIdKey);
                old_fd = (int)lua_tointeger(L, -1);
                //printf("old_fd:%d,new_fd:%d\n", old_fd, fd);
                lua_pop(L, 1);


                lua_pushinteger(L, fd);
                lua_rawseti(L, -2, g_nMailBoxServerIdKey);
            }
        }
        else
        {
            //先用table,以后再改为userdata;table的话可以在lua里修改id,sid等几个值
            NewClientMailbox(L, fd, m_etype, m_id);

            CLuaCallback& cb = GetWorld()->GetLuaTables();
            int nRef = cb.Ref(L);

            LogDebug("CEntityBase::GiveClient", "m_id=%d;nRef=%d", m_id, nRef);

            VOBJECT* v = new VOBJECT;
            v->vt = V_LUATABLE;
            v->vv.i32 = nRef;
            m_data.insert(iter, make_pair("client", v) );
        }

        this->SetClientFd(fd);

        m_bHasClient = true;//获得client标记

        //通知客户端attach到entity,并刷所有带CLIENT标记的数据给客户端
        CMailBox* mb = GetWorld()->GetServer()->GetClientMailbox(fd);
        if(mb)
        {
            CPluto* u = new CPluto;
            u->Encode(MSGID_CLIENT_ENTITY_ATTACHED);

#ifdef __RELOGIN
            //客户端一旦登录，则先生成一个key值，用于断线重连时使用
            const string& key = GetWorldbase().MakeClientReLoginKey("", m_id);
            s_clientReLoginKey = key;
            (*u) << key.c_str();
            LogDebug("CEntityBase::GiveClient", "s_clientReLoginKey=%s;m_id=%d", s_clientReLoginKey.c_str(), m_id);
#endif

            if(PickleClientToPluto(*u))
            {
                (*u) << EndPluto;
                mb->PushPluto(u);
                //LogDebug("CEntityBase::GiveClient", "u->GetLen()=%d;", u->GetLen());
            }
            else
            {
                delete u;
            }

            //如果有cell则通知cell同步数据
            this->NotifyCellSyncClientAttris();
        }

        //通知cell刷aoi数据给客户端
        int nCellId = GetCellServerId();
        if(nCellId > 0)
        {
            GetWorld()->RpcCall(nCellId, MSGID_CELLAPP_PICKLE_AOI_ENTITIES, m_id);
        }

        //通知脚本
        {
            //clear_lua_stack(L);
            int _n = EntityMethodCall(L, this, "onClientGetBase", 0, 0);
            lua_pop(L, _n);
        }

        if(old_fd > 0 && old_fd != fd)
        {
            //关闭老的连接
            GetWorldbase().KickOffFd(old_fd);
        }

        return 0;
    }

    void CEntityBase::RemoveClient()
    {
        m_bHasClient = false;//失去client

        map<string, VOBJECT*>::iterator iter = m_data.find("client");
        if(iter != m_data.end())
        {
            delete iter->second;
            m_data.erase(iter);
            LogInfo("CEntityBase::remove_client", "id=%d", m_id);
        }

        //通知cell失去client
        int nCellId = GetCellServerId();
        if(nCellId > 0)
        {
            GetWorld()->RpcCall(nCellId, MSGID_CELLAPP_LOSE_CLIENT, m_id);
        }
    }

    bool CEntityBase::PickleClientToPluto(CPluto& u)
    {
        //类似于CEntityParent::pickle_to_pluto,打包所有需要存盘的字段
        //打包所有待client标记的字段
        const SEntityDef* pDef = this->GetEntityDef();
        if(pDef)
        {
            u << m_etype << m_id << m_dbid;              //必须包含entity_type,以便接包时查询def数据
            LogDebug("CEntityBase::PickleClientToPluto", "m_etype=%d;m_id=%d;m_dbid=%d", m_etype, m_id, m_dbid);
            map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.begin();
            for(; iter != pDef->m_properties.end(); ++iter)
            {
                _SEntityDefProperties* p = iter->second;
                if(IsClientFlag(p->m_nFlags))
                {
                    const string& strEntityName = iter->first;
                    map<string, VOBJECT*>::const_iterator iter2 = m_data.find(strEntityName);
                    if(iter2 == m_data.end())
                    {
                        //todo warning...
                        continue;
                    }

                    //u << iter2->first.c_str();
                    uint16_t attr_id = (uint16_t)(pDef->m_propertiesMap.GetIntByStr(iter2->first));
                    u << attr_id;

                    //LogDebug("CEntityBase::PickleClientToPluto", "attr_id=%d;first=%s", attr_id, iter2->first.c_str());

                    u.FillPluto(*(iter2->second));
                }
            }
            //print_hex_pluto(u);
        }

        return pDef != NULL;
    }

    //创建新的space并在其中创建entity的cell部分
    int CEntityBase::lCreateInNewSpace(lua_State* L)
    {
        //已经有cell或者cell正在创建之中
        if(m_nCellState != E_HASNT_CELL)
        {
            lua_pushinteger(L, 1);
            return 1;
        }

        //first param userdata
        //附加了其他参数
#ifdef __USE_MSGPACK
        charArrayDummy d;
        msgpack::sbuffer sbuff;
        msgpack::packer<msgpack::sbuffer> pker(&sbuff);
#else
        string strOtherParam;
#endif

        if(lua_gettop(L) > 1)
        {
            if(lua_istable(L, 2))
            {
#ifdef __USE_MSGPACK
                LuaPickleToBlob(L, pker);
#else
                LuaPickleToString(L, strOtherParam);
#endif
            }
        }

        world* the_world = GetWorld();
        CMailBox* mb = the_world->GetServerMailbox(SERVER_BASEAPPMGR);
        if(mb)
        {
            m_nCellState = E_CELL_IN_CREATING;
            CPluto* u = new CPluto;
            u->Encode(MSGID_BASEAPPMGR_CREATE_CELL_IN_NEW_SPACE);
#ifdef __USE_MSGPACK
            d.m_s = sbuff.data();
            d.m_l = (uint16_t)sbuff.size();
            (*u) << m_mymb << m_etype << d;
#else
            (*u) << m_mymb << m_etype << strOtherParam.c_str();
#endif
            PickleCellPropsToPluto(*u);
            (*u) << EndPluto;

            //LogDebug("CEntityBase::lCreateInNewSpace", "u->GetLen()=%d;", u->GetLen());

            mb->PushPluto(u);
        }

        lua_pushinteger(L, 0);
        return 1;
    }

    //根据一个已知的mb,坐标等数据创建cell entity
    int CEntityBase::lCreateCellEntity(lua_State* L)
    {

        //已经有cell或者cell正在创建之中
        if(m_nCellState != E_HASNT_CELL)
        {
            lua_pushinteger(L, 1);
            return 1;
        }

        //first param userdata
        //其他参数: base_mailbox, x, y, string
        if(!lua_istable(L, 2))
        {
            lua_pushstring(L, "createCellEntity need a table param");
            lua_error(L);
            return -1;
        }

        //检查目标base的server_id
        lua_rawgeti(L, 2, g_nMailBoxServerIdKey);
        int nServerId = luaL_checkint(L, -1);

        lua_rawgeti(L, 2, g_nMailBoxEntityIdKey);
        TENTITYID nId = (TENTITYID)luaL_checkint(L, -1);

        int16_t x = (int16_t)luaL_checkint(L, 3);
        int16_t y = (int16_t)luaL_checkint(L, 4);
        const char* szMask = luaL_checkstring(L, 5);
        //LogDebug("CEntityBase::lCreateCellEntity", szMask);
        CPluto* u = new CPluto;
        u->Encode(MSGID_BASEAPP_CREATE_CELL_VIA_MYCELL);
        (*u) << nId << m_mymb << x << y << szMask;
        PickleCellPropsToPluto(*u);
        (*u) << EndPluto;

        world* the_world = GetWorld();
        if(nServerId == the_world->GetMailboxId())
        {
            m_nCellState = E_CELL_IN_CREATING;
            the_world->GetServer()->AddLocalRpcPluto(u);
        }
        else
        {
            CMailBox* mb = the_world->GetServerMailbox(nServerId);
            if(mb)
            {
                m_nCellState = E_CELL_IN_CREATING;

                //LogDebug("CEntityBase::lCreateCellEntity", "nServerId=%d;the_world->GetMailboxId()=%d;u->GetLen()=%d;", nServerId, the_world->GetMailboxId(),u->GetLen());

                mb->PushPluto(u);
            }
            else
            {
                delete u;
            }
        }

        lua_pushinteger(L, 0);
        return 1;
    }

    int CEntityBase::lHasCell(lua_State* L)
    {
        int nCellSrvId = GetCellServerId();
        if(nCellSrvId < 0)
        {
            lua_pushboolean(L, 0);
        }
        else
        {
            lua_pushboolean(L, 1);
        }

        return 1;
    }

    //判断entity是否拥有client
    int CEntityBase::lHasClient(lua_State* L)
    {
        const static string strClient = "client";
        if(m_data.find(strClient) == m_data.end())
        {
            lua_pushboolean(L, 0);
        }
        else
        {
            lua_pushboolean(L, 1);
        }
        return 1;
    }

    //销毁cell部分
    int CEntityBase::lDestroyCellEntity(lua_State* L)
    {
        if(m_nCellState != E_CELL_CREATED)
        {
            return 0;
        }

        int nCellId = GetCellServerId();
        if(nCellId < 0)
        {
            return 0;
        }

        m_nCellState = E_CELL_IN_DESTROYING;
        GetWorld()->RpcCall((uint16_t)nCellId, MSGID_CELLAPP_DESTROY_CELLENTITY, m_mymb.m_nServerMailboxId, m_id);

        return 0;
    }
    //通知db销毁account
    int CEntityBase::lNotifyDbDestroyAccountCache(lua_State* L)
    {
        //first param userdata
        const char* pszAccountName = luaL_checkstring(L, 2);
        static const string strEntityType = "Account";
        world& the_world = *GetWorld();
        /*
        luaL_checkany(L, 3);   //callable object

        CLuaCallback& cb = the_world.GetCallback();
        lua_pushvalue(L, 3);
        int ref = cb.Ref(L);
        */
        CMailBox* mb = the_world.GetServerMailbox(SERVER_DBMGR);
        if(mb)
        {
            mb->RpcCall(the_world.GetRpcUtil(), MSGID_DBMGR_DEL_ACCOUNT_CACHE, pszAccountName, strEntityType);
        }
        return 0;
    }

    int CEntityBase::lTableSelectSql(lua_State* L)
    {
        //脚本层直接指定一个sql语句
        //param1 is userdata
        //uint32_t nCallBackId = luaL_checkint(L, 2);            //回调Id
        const char* pszCallBackFunc = luaL_checkstring(L, 2);  //回调函数名
        const char* pszEntity = luaL_checkstring(L, 3);        //表名
        const char* pszSql = luaL_checkstring(L, 4);           //SQL语句

        GetWorld()->RpcCall(SERVER_DBMGR, MSGID_DBMGR_TABLE_SELECT, m_mymb.m_nServerMailboxId, m_id, pszCallBackFunc, pszEntity, pszSql);

        //LogDebug("CEntityBase::lTableSelectSql", "nCallBackId=%d;m_nServerMailboxId=%d;m_id=%d;pszEntity=%s;pszSql=%s", 
        //                                          nCallBackId, m_mymb.m_nServerMailboxId, m_id, pszEntity, pszSql);

        return 0;
    }

	int CEntityBase::lTableInsertSql(lua_State* L)
	{
		//LogDebug("CEntityBase::lTableInsertSql", "");
		//param1 is userdata
		const char* pszSql = luaL_checkstring(L, 2);           //SQL语句
		//LogDebug("CEntityBase::lTableInsertSql", "%s",pszSql);
		luaL_checkany(L, 3);

		CLuaCallback& cb = GetWorld()->GetCallback();
		int32_t ref = (int32_t)cb.Ref(L);

		GetWorld()->RpcCall(SERVER_DBMGR, MSGID_DBMGR_TABLE_INSERT, m_mymb.m_nServerMailboxId, pszSql, ref);
		return 0;
	}

	int CEntityBase::lTableExcuteSql(lua_State* L)
	{
		//param1 is userdata
		const char* pszSql = luaL_checkstring(L, 2);           //SQL语句
		//LogDebug("CEntityBase::lTableExcuteSql", "%s",pszSql);
		//luaL_checkany(L, 3);
		int32_t ref = 0;
		//ref == 0 无返回
		if (lua_isfunction(L, 3))
		{
			CLuaCallback& cb = GetWorld()->GetCallback();
			ref = (int32_t)cb.Ref(L);
		}
		LogDebug("CEntityBase::lTableExcuteSql", "ref %d",ref);
		GetWorld()->RpcCall(SERVER_DBMGR, MSGID_DBMGR_TABLE_EXCUTE, m_mymb.m_nServerMailboxId, pszSql, ref);
		return 0;
	}

    //使用回调id的数据库操作接口
    int CEntityBase::lTable2Select(lua_State* L)
    {
        uint32_t nCbId = (uint32_t)luaL_checkint(L, 2);
        const char* pszTbl = luaL_checkstring(L, 3);	//table name

        if(lua_gettop(L) == 3)
        {		
            GetWorld()->RpcCall(SERVER_DBMGR, MSGID_DBMGR_TABLE2_SELECT, m_mymb.m_nServerMailboxId, m_id, nCbId, pszTbl, "");
        }
        else
        {
            const char* pszSql = luaL_checkstring(L, 4);
            GetWorld()->RpcCall(SERVER_DBMGR, MSGID_DBMGR_TABLE2_SELECT, m_mymb.m_nServerMailboxId, m_id, nCbId, pszTbl, pszSql);
        }

        return 0;
    }

    int CEntityBase::lTable2Insert(lua_State* L)
    {
        //param 1 is userdata

        uint32_t nCbId = (uint32_t)luaL_checkint(L, 2);	//callback id
        const char* pszTbl = luaL_checkstring(L, 3);	//table name
        luaL_checkany(L, 4);							//table

        if(!lua_istable(L, 4))
        {
            lua_pushstring(L, "tableInsert,param 4 need a table.");
            lua_error(L);
            return 0;
        }

        world* the_world = GetWorld();
        CMailBox* mb = the_world->GetServerMailbox(SERVER_DBMGR);
        if(mb == NULL)
        {
            return 0;
        }

        CDefParser& def = the_world->GetDefParser();
        const SEntityDef* pDef = def.GetEntityDefByName(pszTbl);
        if(pDef == NULL)
        {
            lua_pushfstring(L, "error entity name:%s", pszTbl);
            lua_error(L);
            return 0;
        }

        CPluto* u = new CPluto;
        u->Encode(MSGID_DBMGR_TABLE2_INSERT) << m_mymb.m_nServerMailboxId << m_id << nCbId << def.GetTypeId(pszTbl);

        lua_pushnil(L);
        while(lua_next(L, 4) != 0)
        {
            const char* pszKey = luaL_checkstring(L, -2);

            map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.find(pszKey);
            if(iter != pDef->m_properties.end())
            {
                _SEntityDefProperties* p = iter->second;
                if(p && p->m_bSaveDb)
                {
                    u->FillField<uint16_t>(pDef->m_propertiesMap.GetIntByStr(pszKey));
                    u->FillPlutoFromLua(p->m_nType, L, 6);
                    lua_pop(L, 1);
                    continue;
                }
            }

            delete u;
            lua_pushfstring(L, "%s hasn't field %s or field not need to save.", pszTbl, pszKey);
            lua_error(L);
            return 0;
        }

        u->endPluto();
        //print_hex_pluto(*u);

        mb->PushPluto(u);

        return 0;
    }

    int CEntityBase::lTable2Excute(lua_State* L)
    {
        //param 1 is userdata
        uint32_t nCbId = (uint32_t)luaL_checkint(L, 2);	//callback id
        const char* pszSql = luaL_checkstring(L, 3);	//sql

        GetWorld()->RpcCall(SERVER_DBMGR, MSGID_DBMGR_TABLE2_EXCUTE, m_mymb.m_nServerMailboxId, m_id, nCbId, pszSql);

        return 0;
    }

    int CEntityBase::lSetCellVisiable(lua_State* L)
    {
        uint8_t n = (uint8_t)luaL_checkint(L, 2);
        int nCellId = GetCellServerId();
        if(nCellId > 0)
        {
            GetWorld()->RpcCall(nCellId, MSGID_CELLAPP_SET_VISIABLE, m_id, n);
        }

        return 0;
    }

    //同步带cell标记的属性
    void CEntityBase::SyncBaseAndCellProp(int32_t nPropId, const VOBJECT& v)
    {
        int nCellId = GetCellServerId();
        if(nCellId > 0)
        {
            CMailBox* mb = GetWorld()->GetServerMailbox(nCellId);
            if(mb)
            {
                CPluto* u =  new CPluto;
                (*u).Encode(MSGID_CELLAPP_ENTITY_ATTRI_SYNC) << m_id << m_etype << (uint16_t)nPropId;
                u->FillPluto(v);
                (*u) << EndPluto;

                //LogDebug("CEntityBase::SyncBaseAndCellProp", "u->GetLen()=%d;", u->GetLen());

                mb->PushPluto(u);
            }
        }
    }

    //将base/cell共有属性打包
    bool CEntityBase::PickleCellPropsToPluto(CPluto& u1)
    {
        CPluto u;
        const SEntityDef* pDef = this->GetEntityDef();
        if(pDef)
        {
            map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.begin();
            for(; iter != pDef->m_properties.end(); ++iter)
            {
                _SEntityDefProperties* p = iter->second;
                if(IsCellFlag(p->m_nFlags) && IsBaseFlag(p->m_nFlags))
                {
                    const string& strEntityName = iter->first;
                    map<string, VOBJECT*>::const_iterator iter2 = m_data.find(strEntityName);
                    if(iter2 == m_data.end())
                    {

                        //todo warning...
                        continue;
                    }

                    u << (uint16_t)(pDef->m_propertiesMap.GetIntByStr(iter2->first));
                    u.FillPluto(*(iter2->second));
                }
                else if (IsCellFlag(p->m_nFlags))
                {
                    //如果该属性只有cell才有，则到cellData上查找
                    const string& strEntityName = iter->first;
                    map<string, VOBJECT*>::iterator iter3 = m_cellData.find(strEntityName);

                    if (iter3 != m_cellData.end())
                    {
                        u << (uint16_t)(pDef->m_propertiesMap.GetIntByStr(iter3->first));
                        u.FillPluto(*(iter3->second));
                        m_cellData.erase(iter3);

                        LogDebug("CEntityBase::PickleCellPropsToPluto cellData", "strEntityName=%s", strEntityName.c_str());
                    }
                }
                
            }
            //print_hex_pluto(u);
        }

        charArrayDummy ad;
        ad.m_l = u.GetLen();
        ad.m_s = (char*)u.GetBuff();
        u1 << ad;
        ad.m_l = 0;

        return pDef != NULL;
    }

    //通知cell打包client属性给client
    void CEntityBase::NotifyCellSyncClientAttris()
    {
        int fd = GetClientFd();
        if(fd < 0)
        {
            //没有客户端
            return;
        }

        int nCellSvrId = GetCellServerId();
        if(nCellSvrId < 0)
        {
            //没有cell
            return;
        }

        GetWorld()->RpcCall((uint16_t)nCellSvrId, MSGID_CELLAPP_PICKLE_CLIENT_ATTRIS, m_id);

    }

#ifdef __OPTIMIZE_PROP_SYN
    void CEntityBase::DoSyncClientProp()
    {
        if (this->m_clientPropIds.empty())
        {
            return;
        }

        TENTITYTYPE etype = this->GetEntityType();
        CDefParser& defparser = GetWorld()->GetDefParser();
        const string& etypename = defparser.GetTypeName(etype);
        const SEntityDef* pDef = defparser.GetEntityDefByName(etypename);
        if (pDef)
        {
            set<int32_t>::const_iterator iter = this->m_clientPropIds.begin();
            for (; iter != this->m_clientPropIds.end(); iter++)
            {
                const string& strPropName = pDef->m_propertiesMap.GetStrByInt(*iter);
                map<string, VOBJECT*>::iterator iter1 = this->m_data.find(strPropName);
                if (iter1 != this->m_data.end())
                {
                    VOBJECT& obj = *(iter1->second);
                    //LogDebug("CEntityBase::DoSyncClientProp", "m_id=%d;strPropName=%s", m_id, strPropName.c_str());
                    this->SyncClientProp(*iter, obj);
                }
                
            }
        }

        this->m_clientPropIds.clear();
    }
#endif

    //服务器主动踢掉线
    int CEntityBase::lKickedOut(lua_State* L)
    {
        int fd = GetClientFd();
        if(fd < 0)
        {
            //没有客户端
            return 0;
        }

        GetWorld()->GetServer()->CloseFdFromServer(fd);
        return 0;
    }

	//数据采集
// 	int CEntityBase::lCollector(lua_State* L)
// 	{
// 		//first param userdata
// 		int arg_num = lua_gettop(L);	
// 
// 		const char* sql = luaL_checkstring(L, 2);
// 		//printf("arg_num=%d \n sql = %s \n", arg_num, sql);
// 
// 		CMailBox* mb = GetWorld()->GetServerMailbox(SERVER_LOG); //这里发送给log
// 		if(mb)
// 		{
// 			mb->RpcCall(GetWorld()->GetRpcUtil(), MSGID_LOG_INSERT, sql);
// 		}
// 
// 		return 0;
// 	}

	

    //将cell同步来的坐标保存到m_data
    void CEntityBase::SetMapXY(int16_t x, int16_t y)
    {
        //坐标需要存盘的entity必须在def文件定义这两个字段
        const static string strMapX = "map_x";
        const static string strMapY = "map_y";

        map<string, VOBJECT*>::iterator iter = m_data.find(strMapX);
        if(iter != m_data.end())
        {
            iter->second->vv.i16 = x;
        }

        map<string, VOBJECT*>::iterator iter2 = m_data.find(strMapY);
        if(iter2 != m_data.end())
        {
            iter2->second->vv.i16 = y;
        }
    }

    void CEntityBase::UnpickleCellDataFromPluto(CPluto& u)
    {
        //return NULL;
        const SEntityDef *pSEntityDef = this->GetEntityDef();

        if (pSEntityDef)
        {
            while(!u.IsEnd())
            {
                uint16_t nPropId;
                u >> nPropId;
                if(u.GetDecodeErrIdx() > 0)
                {
                    return;
                }

                //LogDebug("CEntityBase::UnpickleCellDataFromPluto", "nPropId=%d", nPropId);

                const string& strPropName = pSEntityDef->m_propertiesMap.GetStrByInt(nPropId);
                map<string, _SEntityDefProperties*>::const_iterator iter = pSEntityDef->m_properties.find(strPropName);
                if(iter == pSEntityDef->m_properties.end())
                {
                    return;
                }

                _SEntityDefProperties* p = iter->second;
                //if(IsCellFlag(p->m_nFlags))
                //{

                VOBJECT *v = new VOBJECT;

                u.FillVObject(p->m_nType, *v);

                if(u.GetDecodeErrIdx() > 0)
                {
                    delete v;
                    return;
                }

                this->m_cellData.insert(make_pair(iter->first, v));

                LogDebug("CEntityBase::UnpickleCellDataFromPluto", "nPropId=%d;strPropName=%s", nPropId, strPropName.c_str());

                    //lua_pushstring(m_L, strPropName.c_str());
                    //PushVObjectToLua(m_L, v);
                    //lua_rawset(m_L, -3);
                //}
            }

            return;
        }
        return;
    }

}
