#ifndef __LUA_CW_IMPL_HEAD__
#define __LUA_CW_IMPL_HEAD__

#include "lua_mogo.h"


template<typename T>
T* _CreateEntity(lua_State* L)
{
    //cout << "create_entity begin " << endl;

    const char* pszTypeName = luaL_checkstring(L, 1);
    TENTITYTYPE entity_type = GetWorld()->GetDefParser().GetTypeId(pszTypeName);

    if(entity_type == ENTITY_TYPE_NONE)
    {
        lua_pushfstring(L, "error entity type name:%s", pszTypeName);
        lua_error(L);
        return NULL;
    }

    //如果没有传第二个参数,则取本进程的编号,否则取输入的编号(一般来自dbmgr)
    //脚本层不允许自己传第二个参数,否则会出错
    TENTITYID new_eid = 0;
    if((lua_gettop(L) > 1) && !lua_istable(L, 2))
    {
        new_eid = (TENTITYID)luaL_checkint(L, 2);
    }
    else
    {
        new_eid = GetWorld()->GetNextEntityId();
    }

    void* ppf = lua_newuserdata(L, sizeof(T));
    T* pf = new(ppf) T(entity_type, new_eid);

    //用lightuserdata作key保存userdata
    luaL_getmetatable(L, g_szUserDataEntity);
    lua_pushlightuserdata(L, pf);
    lua_pushvalue(L, -3);
    lua_rawset(L, -3);
    lua_pop(L, 1);

    //cout << "create_entity,checkudata" << luaL_checkudata(L, -1,s_szEntityName ) << endl;

    //EntityMethodCall(L, (CEntityParent*)pf, "__init__", 0, 0);

    luaL_getmetatable(L, s_szEntityName);
    lua_setmetatable(L, -2);

    pf->init(L);

    return pf;
}

template<typename T>
int CreateEntity(lua_State* L)
{
    T* p = _CreateEntity<T>(L);
    return 1;
}

template<typename T>
int EntityFunCall(lua_State* L)
{
    T* pf = (T*)luaL_checkudata(L, 1, s_szEntityName);
    const char* s = luaL_checkstring(L, lua_upvalueindex(1));

    map<string, ENTITY_MEMBER_METHOD>& data = GetWorld()->GetEntityCalls();
    map<string, ENTITY_MEMBER_METHOD>::iterator iter = data.find(s);
    if(iter != data.end())
    {
        T& e = *pf;
        ENTITY_MEMBER_METHOD em = iter->second;
        int n = (e.*em)(L);
        return n;
    }

    return 0;
}

template<typename T>
int EntityIndex(lua_State* L)
{
    T* pf = (T*)luaL_checkudata(L, 1, s_szEntityName);
    const char* s = luaL_checkstring(L, 2);

    map<string, VOBJECT*>& data = pf->GetData();
    map<string, VOBJECT*>::iterator iter = data.find(s);
    if(iter != data.end())
    {
        VOBJECT& v = *(iter->second);
        if(PushVObjectToLua(L, v))
        {
            //如果是访问一个lua_table类型的字段,有可能在接下来的操作中改变数据；
            //由于无法判断对table的具体操作(读还是写),这里都做脏数据标记
            if(v.vt == V_LUATABLE)
            {
                //存盘字段才设置脏标记
                CDefParser& defparser = GetWorld()->GetDefParser();
                const string& etypename = defparser.GetTypeName(pf->GetEntityType());
                const _SEntityDefProperties* _p = defparser.GetEntityPropDef(etypename, iter->first);
                if(_p && _p->m_bSaveDb)
                {
                    pf->SetDirty();
                }
            }
            return 1;
        }
        else
        {
            lua_pushfstring(L, "entity_index type error:%s %d", s, v.vt);
            lua_error(L);
            return 0;
        }
    }
    else
    {
        //先查找是否c++实现的脚本层方法
        if(GetWorld()->IsValidEntityCall(s))
        {
            lua_pushstring(L, s);
            lua_pushcclosure(L, EntityFunCall<T>, 1);
            return 1;
        }

        //再查找是否lua脚本定义的方法
        TENTITYTYPE etype = pf->GetEntityType();
        if(etype == ENTITY_TYPE_NONE)
        {
            lua_pushfstring(L, "entity_index error:%s", s);
            lua_error(L);
            return 0;
        }
        else
        {
            const string& etypename = GetWorld()->GetDefParser().GetTypeName(etype);
            lua_getglobal(L, etypename.c_str());
            lua_getfield(L, -1, s);
            return 1;
        }
    }

    return 0;
}

template<typename T>
int EntityNewIndex(lua_State* L)
{
    T* pEntity = (T*)luaL_checkudata(L, 1, s_szEntityName);
    const char* pszPropName = luaL_checkstring(L, 2);

    TENTITYTYPE etype = pEntity->GetEntityType();
    if(etype == ENTITY_TYPE_NONE)
    {
        lua_pushfstring(L, "entity_newindex error:%s", pszPropName);
        lua_error(L);
        return 0;
    }

    CDefParser& defparser = GetWorld()->GetDefParser();
    const string& etypename = defparser.GetTypeName(etype);
    const _SEntityDefProperties* p = defparser.GetEntityPropDef(etypename, pszPropName);
    if(p == NULL)
    {
        lua_pushfstring(L, "unsupport def field:%s", pszPropName);
        lua_error(L);
        return 0;
    }
    else
    {
        map<string, VOBJECT*>& data = pEntity->GetData();
        map<string, VOBJECT*>::iterator iter = data.find(pszPropName);
        if(iter == data.end())
        {
            lua_pushfstring(L, "field not init:%s", pszPropName);
            lua_error(L);
            return 0;
        }

        VOBJECT& obj = *(iter->second);
		obj.Clear();
        obj.vt = p->m_nType;
        if(!FillVObjectFromLua(L, obj, 3))
        {
            lua_pushfstring(L, "entity_newindex, unsupport filed type:%s %d", pszPropName, p->m_nType);
            lua_error(L);
        }

        //存盘字段
        if(p->m_bSaveDb)
        {
            pEntity->SetDirty(); //__newindex设置脏数据标记
        }

        if(pEntity->IsBase())
        {
            //base
            //如果该属性带客户端属性,并且不是table类型,刷新给客户端
            if(IsClientFlag(p->m_nFlags) && obj.vt != V_LUATABLE)
            {
                const SEntityDef* pDef = defparser.GetEntityDefByName(etypename);
                if(pDef)
                {
                    int32_t nPropId = pDef->m_propertiesMap.GetIntByStr(pszPropName);

                    //LogDebug("EntityNewIndex", "pszPropName=%s", pszPropName);

#ifdef __OPTIMIZE_PROP_SYN
                    pEntity->SyncClientPropIds(nPropId);
#else
                    pEntity->SyncClientProp(nPropId, obj);
#endif

                }
            }
        }
        else
        {
            //LogWarning("entity_newidx", "cell_attri_sync");
            ////cell
            ////todo,如果带了base属性,则由base去同步客户端
            ////如果该属性带客户端属性,并且不是table类型,刷新给客户端
            //if(isClientFlag(p->m_nFlags) && obj.vt != V_LUATABLE && pEntity->hasClient())
            //{
            //  const SEntityDef* pDef = defparser.getEntityDefByName(etypename);
            //  if(pDef)
            //  {
            //      int32_t nPropId = pDef->m_propertiesMap.getIntByStr(pszPropName);
            //      pEntity->SyncClientProp(nPropId, obj);
            //  }
            //}

            //cell
            //如果该属性不带base标记,并且不是table类型,刷新给客户端
            if(!IsBaseFlag(p->m_nFlags) && obj.vt != V_LUATABLE)
            {
                //如果标记了客户端
                if(IsClientFlag(p->m_nFlags))
                {
                    const SEntityDef* pDef = defparser.GetEntityDefByName(etypename);
                    if(pDef)
                    {
                        //CEntityCell* pCell = (CEntityCell*)pEntity;
                        int32_t nPropId = pDef->m_propertiesMap.GetIntByStr(pszPropName);

#ifdef __OPTIMIZE_PROP_SYN
                        pEntity->SyncClientPropIds(nPropId);
#else
                        //pCell->SyncOwnEntityAttri(nPropId, &obj);
                        pEntity->SyncOwnEntityAttri(nPropId, &obj);
#endif

                    }
                }

                //如果标记了allClients
                if(IsOtherClientsFlag(p->m_nFlags))
                {

#ifdef __OPTIMIZE_PROP_SYN
                    const SEntityDef* pDef = defparser.GetEntityDefByName(etypename);
                    if (pDef)
                    {
                        int32_t nPropId = pDef->m_propertiesMap.GetIntByStr(pszPropName);
                        pEntity->SyncClientPropIds(nPropId);
                    }

#else
                    //CEntityCell* pCell = (CEntityCell*)pEntity;
                    //pCell->OnAttriModified(pszPropName, &obj);
                    pEntity->OnAttriModified(pszPropName, &obj);
#endif

                }
            }
        }

        //如果是base和cell共有的类型
        //改为只能由base同步给cell,cell不能同步给base!
        if(pEntity->IsBase() && IsBaseFlag(p->m_nFlags) && IsCellFlag(p->m_nFlags) && obj.vt != V_LUATABLE)
        {
            const SEntityDef* pDef = defparser.GetEntityDefByName(etypename);
            if(pDef)
            {
                int32_t nPropId = pDef->m_propertiesMap.GetIntByStr(pszPropName);
                pEntity->SyncBaseAndCellProp(nPropId, obj);
                //LogDebug("EntityNewIndex", "pszPropName=%s", pszPropName);
            }
        }

    }

    return 0;
}

template <typename T1>
void BroadcastBaseapp(pluto_msgid_t msgid, const T1& p1)
{
    world* the_world = GetWorld();
    vector<CMailBox*>& mbs = the_world->GetServer()->GetAllServerMbs();
    vector<CMailBox*>::iterator iter = mbs.begin();
    for(; iter != mbs.end(); ++iter)
    {
        CMailBox* basemb = *iter;
        if(basemb && basemb->GetServerMbType() == SERVER_BASEAPP)
        {
            basemb->RpcCall(the_world->GetRpcUtil(), msgid, p1);
        }
    }

    //加上自己
    the_world->RpcCall(the_world->GetMailboxId(), msgid, p1);
}

template <typename T1, typename T2>
void BroadcastBaseapp(pluto_msgid_t msgid, const T1& p1, const T2& p2)
{
    world* the_world = GetWorld();
    vector<CMailBox*>& mbs = the_world->GetServer()->GetAllServerMbs();
    vector<CMailBox*>::iterator iter = mbs.begin();
    for(; iter != mbs.end(); ++iter)
    {
        CMailBox* basemb = *iter;
        if(basemb && basemb->GetServerMbType() == SERVER_BASEAPP)
        {
            basemb->RpcCall(the_world->GetRpcUtil(), msgid, p1, p2);
        }
    }

    //加上自己
    the_world->RpcCall(the_world->GetMailboxId(), msgid, p1, p2);
}

template <typename T1, typename T2, typename T3>
void BroadcastBaseapp(pluto_msgid_t msgid, const T1& p1, const T2& p2, const T3& p3)
{
    world* the_world = GetWorld();
    vector<CMailBox*>& mbs = the_world->GetServer()->GetAllServerMbs();
    vector<CMailBox*>::iterator iter = mbs.begin();
    for(; iter != mbs.end(); ++iter)
    {
        CMailBox* basemb = *iter;
        if(basemb && basemb->GetServerMbType() == SERVER_BASEAPP)
        {
            basemb->RpcCall(the_world->GetRpcUtil(), msgid, p1, p2, p3);
        }
    }

    //加上自己
    the_world->RpcCall(the_world->GetMailboxId(), msgid, p1, p2, p3);
}

#endif
