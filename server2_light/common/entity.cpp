/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：entity
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.5
// 模块描述：entity 处理相关
//----------------------------------------------------------------*/

#include "lua.hpp"
#include "util.h"
#include "lua_mogo.h"
#include "timer.h"
#include "entity.h"
#include "world_select.h"
#include "timer_action.h"

namespace mogo
{


    /////////////////////////////////////////////////////////////////////////////////////////

    CEntityParent::CEntityParent(TENTITYTYPE etype, TENTITYID nid)
        : m_etype(etype), m_id(nid), m_mymb(), m_dbid(0), m_bIsDirty(false), m_nTimestamp(time(NULL) + 300),
          m_bIsMysqlDirty(false), m_bTimeSaveMysql(false), m_bHasClient(false)
    {
        //cout << "CEntity::CEntity: " << nid << endl;
    }

    CEntityParent::~CEntityParent()
    {
        //cout << "CEntity::~CEntity: " << m_id << endl;
        ClearMap(m_data);
    }

    //void * CEntityParent::operator new(size_t size, CEntityParent& area)
    //{
    //    LogDebug("CEntityParent new", "size=%d", size);

    //    return area.allocate(size);
    //}

    //void CEntityParent::operator delete(void* p, CEntityParent& area)
    //{
    //    LogDebug("CEntityParent delete", "size=%d", size);

    //    arena.deallocate(p);
    //}

    const SEntityDef* CEntityParent::GetEntityDef() const
    {
        return GetWorld()->GetDefParser().GetEntityDefByType(m_etype);
    }

    int CEntityParent::init(lua_State* L)
    {
        m_mymb.m_nEntityId = m_id;
        m_mymb.m_nServerMailboxId = GetMailboxId();
        m_mymb.m_nEntityType = m_etype;

        return 0;
    }


    int CEntityParent::lGetId(lua_State* L)
    {
        lua_pushinteger(L, m_id);
        return 1;
    }

    int CEntityParent::lGetDbid(lua_State* L)
    {
        lua_pushinteger(L, (lua_Integer)m_dbid);
        return 1;
    }

    int CEntityParent::lGetEntityType(lua_State* L)
    {
        lua_pushinteger(L, m_etype);
        return 1;
    }


#define CHECK_UNSIGNED(x, n) \
    if(x < 0)\
    {\
        lua_pushfstring(L, "param %d should be unsigned int.", n);\
        lua_error(L);\
        return 0;\
    }

    int CEntityParent::lAddEventListener(lua_State* L)
    {
        //first param is userdata

        TENTITYID triggerEid = luaL_checkint(L, 2);

        int nEventId = luaL_checkint(L, 3);
        CHECK_UNSIGNED(nEventId, 3);

        const char* szFuncName = luaL_checkstring(L, 4);

        CEventDispatcher * p = GetWorld()->GetEventDispatcher();

        //LogDebug("CEntityParent::lAddEventListener", "triggerEid=%d;nEventId=%d;id=%d;szFuncName=%s",
        //                                              triggerEid, nEventId, GetId(), szFuncName);

        p->AddToMap(triggerEid, nEventId, GetId(), szFuncName);

        return 0;
    }

    int CEntityParent::lDelEventListener(lua_State* L)
    {
        //first param is userdata

        TENTITYID triggerEid = luaL_checkint(L, 2);

        int nEventId = luaL_checkint(L, 3);
        CHECK_UNSIGNED(nEventId, 3);

        CEventDispatcher * p = GetWorld()->GetEventDispatcher();

        //LogDebug("CEntityParent::lDelEventListener", "triggerEid=%d;nEventId=%d;id=%d",
        //                                              triggerEid, nEventId, GetId());

        p->DeleteFromMap(triggerEid, nEventId, GetId());

        return 0;
    }

    int CEntityParent::lTriggerEvent(lua_State* L)
    {
        //first param is userdata
        int nEventId = luaL_checkint(L, 2);
        CHECK_UNSIGNED(nEventId, 2);

        //参数个数
        int nParam = lua_gettop(L) - 2;

        if (nParam >= 0)
        {
            CEventDispatcher * p = GetWorld()->GetEventDispatcher();
            TEventList* l = p->TriggerEvent(GetId(), nEventId);
            if (l)
            {
                TEventList::iterator iter1 = l->begin();
                map<TENTITYID, string> tmap;
                for (;iter1 != l->end(); iter1++)
                {
                    tmap.insert(make_pair(iter1->first, iter1->second));
                }

                map<TENTITYID, string>::iterator iter2 = tmap.begin();
                for (;iter2 != tmap.end(); ++iter2)
                {
                    CEntityParent* pe = GetWorld()->GetEntity(iter2->first);
                    if(pe)
                    {
                        int n = EntityMethodCall(L, pe, iter2->second.c_str(), nParam, 0);
                        lua_pop(L, n);
                        //LogDebug("lTriggerEvent", "%d", l->size());
                    }
                }
            }
        }

        return 0;
    }

    int CEntityParent::lAddTimer(lua_State* L)
    {
        //first param is userdata
        int nStart = luaL_checkint(L, 2);
        CHECK_UNSIGNED(nStart, 2);

        int nInterval = luaL_checkint(L, 3);
        CHECK_UNSIGNED(nInterval, 3);

        int nUserData = luaL_checkint(L, 4);
        CHECK_UNSIGNED(nUserData, 4);

        int nTimerId = GetWorld()->GetTimer().AddTimer(nStart, nInterval, m_id, nUserData);
        lua_pushinteger(L, nTimerId);
        return 1;

    }

    int CEntityParent::lDelTimer(lua_State* L)
    {
        int nTimerId = luaL_checkint(L, 2);
        CHECK_UNSIGNED(nTimerId, 2);

        GetWorld()->GetTimer().DelTimer((uint32_t)nTimerId);

        return 0;
    }

    int CEntityParent::lAddLocalTimer(lua_State* L)
    {
#ifndef _WIN32
        stLuaTimerData data;
        data.lua                    = L;
        data.nLuaParamStackStart    = 5;
        data.u32EntityID            = GetId();
        data.strLuaFuncName         = luaL_checkstring(L, 2);
        data.u32IntervalTick        = luaL_checkint(L, 3);
        data.u16TotalTimes          = (uint16_t)luaL_checkint(L, 4);

        CTimerActionBase& rAction = LuaTimerFactory(data);
        uint64_t n64ActionID = GetWorld()->GetLocalTimer().AddAction(rAction);
        lua_pushnumber(L, n64ActionID);
#endif
        return 1;
    }

    int CEntityParent::lDelLocalTimer(lua_State* L)
    {
        uint64_t u64ActionID = (uint64_t)luaL_checknumber(L, 2);
        bool bRet = GetWorld()->GetLocalTimer().DelAction(u64ActionID);
        lua_pushboolean(L, bRet);
        return 1;
    }

    int CEntityParent::lHasLocalTimer(lua_State* L)
    {
        uint64_t u64ActionID = (uint64_t)luaL_checknumber(L, 2);
        bool bRet = GetWorld()->GetLocalTimer().HasAction(u64ActionID);
        lua_pushboolean(L, bRet);
        return 1;
    }

    int CEntityParent::lWriteToDB(lua_State* L)
    {
        //first param is userdata

        world& the_world = *GetWorld();
        int32_t ref = 0;
        if(m_dbid == 0)
        {
            luaL_checkany(L, 2);   //callable object
            CLuaCallback& cb = the_world.GetCallback();
            lua_pushvalue(L, 2);
            ref = (int32_t)cb.Ref(L);
        }
        else
        {
            //没有设置脏数据标记,返回
            if(!m_bIsMysqlDirty)
            {
                LogDebug("CEntityParent::lWriteToDB", "not_dirty;etype=%d;id=%d;dbid=%d", m_etype, m_id, m_dbid);
                return 0;
            }
        }

        CMailBox* mb = the_world.GetServerMailbox(SERVER_DBMGR);
        if(mb)
        {
            if(m_dbid == 0)
            {
                mb->RpcCall(the_world.GetRpcUtil(), MSGID_DBMGR_INSERT_ENTITY, m_mymb, ref, *this);
            }
            else
            {
                mb->RpcCall(the_world.GetRpcUtil(), MSGID_DBMGR_UPDATE_ENTITY, m_mymb, m_dbid, *this);
            }
        }

        //清理脏数据标记,设置上次存盘时间
        m_nTimestamp = time(NULL);
        m_bIsDirty = false;
        m_bIsMysqlDirty = false;

        LogInfo("CEntityParent::lWriteToDB", "etype=%d;id=%d;dbid=%d;ref=%d", m_etype, m_id, m_dbid, ref);

        return 0;
    }

    //保存至redis
    bool CEntityParent::WriteToRedis()
    {
        if(m_dbid > 0)
        {
            if(m_bIsDirty)
            {
                enum { last_save_delta = 300 };
                time_t nNow = time(NULL);
                //脏数据并且距离上次存盘大于5分钟
                if( (nNow - m_nTimestamp) >= last_save_delta)
                {
                    if(m_bTimeSaveMysql)
                    {
                        //同时写mysql和redis
                        lua_State* L = GetWorld()->GetLuaState();
                        this->lWriteToDB(L);

                        LogInfo("CEntityParent::WriteToRedis db", "etype=%d;id=%d;dbid=%d", m_etype, m_id, m_dbid);
                    }
                    else
                    {
                        //只写redis
                        GetWorld()->RpcCall(SERVER_DBMGR, MSGID_DBMGR_UPDATE_ENTITY_REDIS, m_mymb, m_dbid, *this);

                        m_nTimestamp = nNow;
                        m_bIsDirty = false;
                        //不会影响m_bIsMysqlDirty标记

                        LogInfo("CEntityParent::WriteToRedis redis", "etype=%d;id=%d;dbid=%d", m_etype, m_id, m_dbid);
                    }

                    return true;
                }
                //else
                //{
                //  LogDebug("CEntityParent::writeToRedis2", "last_saved;id=%d;dbid=%d", m_id, m_dbid);
                //}
            }
            //else
            //{
            //  LogDebug("CEntityParent::writeToRedis3", "not_dirty;id=%d;dbid=%d", m_id, m_dbid);
            //}
        }

        return false;
    }

    //注册到定时存盘管理器
    int CEntityParent::lRegisterTimeSave(lua_State* L)
    {
        //可以由脚本层指定定时存盘是写mysql还是redis
        m_bTimeSaveMysql = false;
        if(lua_gettop(L) > 1)
        {
            const char* s = luaL_checkstring(L, 2);
            if(strcmp(s, "clear") == 0)
            {
                //由脚本层判定后清除之前的脏数据标记
                m_bIsDirty = false;
                m_bIsMysqlDirty = false;
            }
            else if(strcmp(s, "mysql") == 0)
            {
                m_bTimeSaveMysql = true;
            }
        }

        GetWorld()->RegisterTimeSave(m_id);
        return 0;
    }

    ////判断entity是否拥有client
    //int CEntityParent::lHasClient(lua_State* L)
    //{
    //    const static string strClient = "client";
    //    if(m_data.find(strClient) == m_data.end())
    //    {
    //        lua_pushboolean(L, 0);
    //    }
    //    else
    //    {
    //        lua_pushboolean(L, 1);
    //    }
    //    return 1;
    //}

    bool CEntityParent::PickleToPluto(CPluto& u) const
    {
        const SEntityDef* pDef = this->GetEntityDef();
        if(pDef)
        {
            //u << m_mymb << m_dbid;   //不需要包含mb和dbid,这两个字段要分离出去
            u << m_etype;              //必须包含entity_type,以便接包时查询def数据
            map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.begin();
            for(; iter != pDef->m_properties.end(); ++iter)
            {
                _SEntityDefProperties* p = iter->second;
                if(!p->m_bSaveDb)
                {
                    //不需要存盘
                    continue;
                }

                const string& strEntityName = iter->first;
                map<string, VOBJECT*>::const_iterator iter2 = m_data.find(strEntityName);
                if(iter2 == m_data.end())
                {
                    //todo warning...
                    continue;
                }

                //u << iter2->first.c_str();
                u << (uint16_t)(pDef->m_propertiesMap.GetIntByStr(iter2->first));
                u.FillPluto(*(iter2->second));
            }
            //print_hex_pluto(u);
        }

        return pDef != NULL;
    }

    bool CEntityParent::UnpickleFromPluto(CPluto& u)
    {
        VOBJECT v;
		v.vt = V_ENTITY;
        bool b = u.UnpickleEntity(v);
        return b;
    }

    //刷新entity的属性,数据一般来自数据库
    void CEntityParent::UpdateProps(TDBID dbid, SEntityPropFromPluto* p)
    {
        m_dbid = dbid;

        map<string, VOBJECT*>& new_data = p->data;
        map<string, VOBJECT*>::iterator iter = new_data.begin();
        for(; iter != new_data.end(); ++iter)
        {
            map<string, VOBJECT*>::iterator iter2 = m_data.find(iter->first);
            if(iter2 != m_data.end())
            {
                //交换指针
                VOBJECT* ptmp = iter2->second;
                iter2->second = iter->second;
                iter->second = ptmp;
            }
        }
    }

    //刷新entity的属性,数据由一个table给出
    void CEntityParent::UpdateProps(map<string, VOBJECT*>& new_data)
    {
        map<string, VOBJECT*>::iterator iter = new_data.begin();
        for(; iter != new_data.end(); ++iter)
        {
            map<string, VOBJECT*>::iterator iter2 = m_data.find(iter->first);
            if(iter2 != m_data.end())
            {
                //交换指针
                VOBJECT* ptmp = iter2->second;
                iter2->second = iter->second;
                iter->second = ptmp;
            }
        }
    }

    //根据L中指定位置的table刷新entity属性
    void CEntityParent::UpdateProps(lua_State* L)
    {
        //附带了初始化参数,注意有一种情况是dbmgr指定了第2个参数是id,两者兼容
        if(lua_istable(L, 2))
        {
            string strEntity = luaL_checkstring(L, 1);
            CDefParser& def = GetWorld()->GetDefParser();
            const SEntityDef* pDef = def.GetEntityDefByName(strEntity);
            SEntityPropFromPluto pData;
            //pData.etype = def.getTypeId(strEntity);       //这个字段用不到

            //循环table的每一个字段
            lua_pushnil(L);
            while(lua_next(L, 2) != 0)
            {
                string strKey = luaL_checkstring(L, -2);
                const _SEntityDefProperties* pp = def.GetEntityPropDef(pDef, strKey);
                if(pp)
                {
                    VOBJECT* v = new VOBJECT;
                    memset(v, 0, sizeof(VOBJECT));

                    v->vt = pp->m_nType;
                    //5是栈顶的value,自底向上依次为:enity_type, data table, entity userdata, key, value
                    FillVObjectFromLua(L, *v, 5);
                    pData.data.insert(make_pair(strKey, v));
                }
                else
                {
                    LogWarning("CEntityParent::update_props", "entity=%s;undef_prop=%s", strEntity.c_str(), strKey.c_str());
                }
                lua_pop(L, 1);
            }

            this->UpdateProps(pData.data);
        }
    }

    //刷新一个属性
    VOBJECT* CEntityParent::UpdateAProp(const string& strPropName, VOBJECT* v, bool& bUpdate)
    {
        map<string, VOBJECT*>::iterator iter = m_data.find(strPropName);
        if(iter == m_data.end())
        {
            bUpdate = false;
            return v;
        }

        VOBJECT* v2 = iter->second;
        iter->second = v;
        bUpdate = true;
        return v2;
    }

    //同步带client标记的属性给客户端
    void CEntityParent::SyncClientProp(int32_t nPropId, const VOBJECT& v)
    {
        //获得当前entity的client fd
        static const string strClient = "client";

        map<string, VOBJECT*>::iterator iter = m_data.find(strClient);
        if(iter != m_data.end())
        {
            //当前已经有client了
            world* pWorld = GetWorld();

            lua_State* L = pWorld->GetLuaState();
            ClearLuaStack(L);

            CLuaCallback& cb = pWorld->GetLuaTables();
            int ref = (int)(iter->second->vv.i32);

            //LogDebug("CEntityParent::SyncClientProp", "m_id=%d;ref=%d", m_id, ref);


            cb.GetObj(L, ref);

            if(lua_istable(L, -1))
            {
                lua_rawgeti(L, -1, g_nMailBoxServerIdKey);

                int fd = (int)lua_tointeger(L, -1);
                CMailBox* mb = pWorld->GetServer()->GetClientMailbox(fd);
                if(mb)
                {
                    //LogDebug("CEntityParent::SyncClientProp", "m_id=%d;nPropId=%d;", m_id, nPropId);

                    CPluto* u =  new CPluto;
                    (*u).Encode(MSGID_CLIENT_AVATAR_ATTRI_SYNC) << (uint16_t)nPropId;
                    u->FillPluto(v);
                    (*u) << EndPluto;

                    mb->PushPluto(u);
                }
            }

            ClearLuaStack(L);
        }
    }

#ifdef __OPTIMIZE_PROP_SYN
    void CEntityParent::SyncClientPropIds(int32_t nPropId)
    {
        //set<int32_t>::iterator iter = this->m_clientPropIds.find(nPropId);
        //if (iter == this->m_clientPropIds.end())
        //{
        //    this->m_clientPropIds.insert(iter, nPropId);
        //}
        if(this->m_clientPropIds.insert(nPropId).second)
        {
            //把自己的eid加到world管理的脏数据列表里面
            world* pWorld = GetWorld();
            if (pWorld)
            {
                pWorld->AddPropSyn(m_id);
            }
        }
    }
#endif

    //从L栈顶获取一个table,以name为名在entity上生成一个mailbox字段
    bool CEntityParent::AddAnyMailbox(const string& name, int32_t nRef)
    {
        //不能使用这几个关键字
        if(name.compare("cell") == 0 || name.compare("base") == 0 || name.compare("client") == 0)
        {
            return false;
        }

        map<string, VOBJECT*>::iterator iter = m_data.lower_bound(name);
        if(iter != m_data.end() && iter->first == name)
        {
            //该名字已经被其他字段占用了
            return false;
        }
        else
        {
            VOBJECT* v = new VOBJECT;
            v->vt = V_LUATABLE;
            v->vv.i32 = nRef;
            m_data.insert(make_pair(name, v) );

            return true;
        }
    }

    //从redis读取到数据的回调方法
    void CEntityParent::OnLoadRedis(const string& strKey, const string& strValue)
    {
        map<string, VOBJECT*>::iterator iter = m_data.find(strKey);
        if(iter != m_data.end())
        {
            VOBJECT* v = iter->second;
            if(v->vt == V_REDIS_HASH)
            {
                CRedisHash* r = (CRedisHash*)v->vv.p;
                r->OnLoaded(strValue);
            }
        }
    }

}//end of namespace

