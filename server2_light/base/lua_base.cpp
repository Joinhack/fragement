/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：lua_base
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.5
// 模块描述：脚本层base相关
//----------------------------------------------------------------*/

#ifndef _WIN32
#include <uuid/uuid.h>
#endif

#include "lua_base.h"
#include "entity_base.h"
#include "defparser.h"
#include "world_base.h"
#include "world_select.h"
#include "lua_mogo_impl.h"
#include <vector>
#include <list>

using namespace mogo;

const static char* s_entity_ctor_name = "__ctor__";       //构造函数
const static char* s_entity_dctor_name = "__dctor__";     //析构函数


int lIncrementalUpdateItems(lua_State* L)
{

    int n  = lua_gettop(L);
    if( n != 4 )
    {
        LogError("lIncrementalUpdateItems", "Parameters number from lua not enough");
        lua_pop(L, n);
        lua_pushnumber(L, -1);
        return 1;
    }
    if( LUA_TTABLE != lua_type(L, 1) && LUA_TSTRING != lua_type(L, 2) && LUA_TSTRING != lua_type(L, 3))
    {
        LogError("Parameters type lua error", "%d", -1);
        lua_pop(L, n);
        lua_pushnumber(L, -1);
        return 1;
    }

    luaL_checkany(L, 4);

    const char* tName = lua_tostring(L, 2);
    const string tblName(tName); //更新的表名字

    const SEntityDef* pDef = GetWorldbase().GetDefParser().GetEntityDefByName(tblName);
    if( !pDef )
    {
        LogError("world:init().error", "%s", "Not the Entitydef");

        lua_pushnumber(L, -1);
        return 1;
    }

    CLuaCallback& cb = GetWorld()->GetCallback();
    int32_t ref = (int32_t)cb.Ref(L);

    const char* oName = lua_tostring(L, 3);
    lua_pop(L, 2);

    const string optName(oName); //操作内型
    uint16_t nBaseappId = GetWorld()->GetMailboxId();

    CPluto *u = new CPluto();
    u->Encode(MSGID_DBMGR_INCREMENTAL_UPDATE_ITEMS);

    *u << tblName << optName << nBaseappId << ref << (uint16_t)0;

    int i = 1;
    while(true)
    {
        map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.begin();

        lua_pushnumber(L, i++);
        lua_gettable(L, -2);
        if( lua_type(L, -1) != LUA_TTABLE )
        {
            break;
        }

        //独立处理道具的id字段
        lua_pushstring(L, "id");
        lua_gettable(L, -2);
        if( lua_type(L, -1) == LUA_TNIL )
        {
            LogError("table Item data is not enough: ", "%s", "id");
            delete u;
            u = NULL;

            cb.Unref(L, ref);

            lua_pushnumber(L, -1);
            return 1;
        }

        u->FillPlutoFromLua(V_INT64, L, -1);
        lua_pop(L, 1);

        //处理def中存盘字段
        for(; iter != pDef->m_properties.end(); ++iter)
        {
            const _SEntityDefProperties* pProp = iter->second;
            if( IsBaseFlag( pProp->m_nFlags ) && pProp->m_bSaveDb )
            {
                //cout<<"attribution name = "<<pProp->m_name.c_str()<<endl;
                lua_pushstring(L, pProp->m_name.c_str());

                lua_gettable(L, -2);
                if( lua_type(L, -1) == LUA_TNIL )
                {
                    LogError("table Item data is not enough: ", "%s", pProp->m_name.c_str());
                    delete u;
                    u = NULL;

                    cb.Unref(L, ref);

                    lua_pushnumber(L, -1);
                    return 1;
                }
                u->FillPlutoFromLua(pProp->m_nType, L, -1);

                lua_pop(L, 1);
            }
        }
        lua_pop(L, 1);
    }

    (*u) << EndPluto;
    
    uint32_t pos = (MSGLEN_TEXT_POS + sizeof(uint16_t)*2 + tblName.size() + optName.size() + sizeof(nBaseappId) + sizeof(int32_t));
    uint16_t value = (u->GetLen() - pos - sizeof(uint16_t));

    u->ReplaceField(pos, value);
    //PrintHexPluto(*u);

    CMailBox* mb = GetWorldbase().GetServerMailbox(SERVER_DBMGR);
    if(mb)
    {
        mb->PushPluto(u);

        lua_pushnumber(L, 0);
        return 1;
    }
    else
    {
        delete u;
        u = NULL;

        cb.Unref(L, ref);

        lua_pushnumber(L, -1);
        return 1;
    }

}


int lWriteArrayToDb(lua_State* L)
{

    int n  = lua_gettop(L);
    if( n != 4 )
    {
        LogError("lWriteArrayToDb", "Parameters number from lua not enough");
        lua_pop(L, n);
        lua_pushnumber(L, -1);
        return 1;
    }
    if( LUA_TTABLE != lua_type(L, 1) && LUA_TSTRING != lua_type(L, 2) && LUA_TNUMBER != lua_type(L, 3) )
    {
        LogError("Parameters type lua error", "%d", -1);
        lua_pop(L, n);
        lua_pushnumber(L, -1);
        return 1;
    }

    luaL_checkany(L, 4);

    const char* item = lua_tostring(L, 2);
    const string itemName(item);


    const SEntityDef* pDef = GetWorldbase().GetDefParser().GetEntityDefByName(itemName);
    if( !pDef )
    {
        LogError("world:init().error", "%s", "Not the Entitydef");

        lua_pushnumber(L, -1);
        return 1;
    }

    CLuaCallback& cb = GetWorld()->GetCallback();
    int32_t ref = (int32_t)cb.Ref(L);
    TDBID dbid = lua_tonumber(L, 3);

    lua_pop(L, 2);

    uint16_t nBaseappId = GetWorld()->GetMailboxId();
    CPluto *u = new CPluto();
    u->Encode(MSGID_DBMGR_UPDATE_ITEMS);

    *u << itemName << dbid << nBaseappId << ref << (uint16_t)0;


    int i = 1;
    while(true)
    {
        map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.begin();

        //CPluto *u = new CPluto();
        //cout<<u->GetLen()<<endl;
        //LogDebug("parse table list start", "%d", 1);
        //oss <<"[";
        lua_pushnumber(L, i++);
        lua_gettable(L, -2);
        if( lua_type(L, -1) != LUA_TTABLE )
        {
            break;
        }
        for(; iter != pDef->m_properties.end(); ++iter)
        {

            const _SEntityDefProperties* pProp = iter->second;
            //VOBJECT *v = new VOBJECT();

            if(IsBaseFlag(pProp->m_nFlags) && pProp->m_bSaveDb )
            {
                //cout<<"attribution name = "<<pProp->m_name.c_str()<<endl;
                lua_pushstring(L, pProp->m_name.c_str());

                lua_gettable(L, -2);
                if( lua_type(L, -1) == 0 )
                {
                    LogError("table Item data is not enough", "%s", pProp->m_name.c_str());
                    delete u;
                    u = NULL;

                    cb.Unref(L, ref);

                    lua_pushnumber(L, -1);
                    return 1;
                }
                u->FillPlutoFromLua(pProp->m_nType, L, -1);

                lua_pop(L, 1);
            }
        }
        lua_pop(L, 1);
        //LogDebug("parse table list end", "%d", 1);
    }

    //printf("%d", u->GetLen());

    (*u) << EndPluto;
    // PrintHexPluto(*u);
    //printf("%d, %d", u->GetLen(), itemName.size());
    uint32_t pos = (MSGLEN_TEXT_POS + sizeof(uint16_t) + itemName.size() + 
        sizeof(dbid) + sizeof(nBaseappId) + sizeof(int32_t));
    uint16_t value = (u->GetLen() - pos - sizeof(uint16_t));
    //printf("%d %d", pos, value);
    u->ReplaceField(pos, value);
    //PrintHexPluto(*u);

    CMailBox* mb = GetWorldbase().GetServerMailbox(SERVER_DBMGR);
    if(mb)
    {
        //LogInfo("lWriteArrayToDb", "msg_id = %d, itemName = %s, status = %d", MSGID_DBMGR_UPDATE_ITEMS, itemName.c_str(), 1);
        mb->PushPluto(u);

        lua_pushnumber(L, 0);
        return 1;
    }
    else
    {
        delete u;
        u = NULL;

        cb.Unref(L, ref);

        lua_pushnumber(L, -1);
        return 1;
    }

}
//mogo.UpdateBatchToDb(arrayList, table, uniq, cbF)
int lUpdateBatchToDb(lua_State* L)
{
	int n  = lua_gettop(L);
	if( n != 4 && n != 3)
	{
		LogError("lUpdateBatchToDb", "Parameters number from lua not enough");
		lua_pop(L, n);
		lua_pushnumber(L, 1);
		return 1;
	}
	if( LUA_TTABLE != lua_type(L, 1) || LUA_TSTRING != lua_type(L, 2) || LUA_TSTRING != lua_type(L, 3) )
	{
		LogError("Parameters type lua error", "%d", -1);
		lua_pop(L, n);
		lua_pushnumber(L, 2);
		//lua_pop(L, 2);
		return 1;
	}
	CLuaCallback& cb = GetWorld()->GetCallback();
	int32_t ref = LUA_REFNIL;
	if(n == 4)
	{
		luaL_checkany(L, 4);
		ref = (int32_t)cb.Ref(L);
	}

	//cout<<lua_gettop(L)<<endl;

	const char* pszUniqKey = lua_tostring(L, 3);
	lua_pop(L, 1);
	const string uniqKey(pszUniqKey);

	const char* item = lua_tostring(L, 2);
	lua_pop(L, 1);
	const string itemName(item);
	uint16_t nBaseappId = GetWorld()->GetMailboxId();
	//map<string, map<string, VOBJECT> > items;
	CPluto *u = new CPluto();
	u->Encode(MSGID_DBMGR_UPDATE_BATCH);
	//ostringstream oss;
	*u << itemName << uniqKey << nBaseappId << ref << (uint16_t)0;
	//char str[10240];
	//const string itemName= "Item";
	const SEntityDef* pDef = GetWorldbase().GetDefParser().GetEntityDefByName(itemName);
	if( !pDef )
	{
		LogError("lUpdateBatchToDb", "Not the Entitydef");
		lua_pushnumber(L, 3);
		delete u;
		u = NULL;
		if(LUA_REFNIL != ref)
			cb.Unref(L, ref);

		return 1;
	}

	int i = 1;
	while(true)
	{
		map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.begin();

		//CPluto *u = new CPluto();
		//cout<<u->GetLen()<<endl;
		//LogDebug("parse table list start", "%d", 1);
		//oss <<"[";
		lua_pushnumber(L, i++);
		lua_gettable(L, -2);
		if( lua_type(L, -1) != LUA_TTABLE )
		{
			break;
		}
		for(; iter != pDef->m_properties.end(); ++iter)
		{

			const _SEntityDefProperties* pProp = iter->second;
			//VOBJECT *v = new VOBJECT();

			if(IsBaseFlag(pProp->m_nFlags))
			{
				//cout<<"attribution name = "<<pProp->m_name.c_str()<<endl;
				lua_pushstring(L, pProp->m_name.c_str());

				lua_gettable(L, -2);
				if( lua_type(L, -1) == LUA_TNIL )
				{
					LogError("lUpdateBatchToDb", "table Item[%s] data is nil. ", pProp->m_name.c_str());
					delete u;
					u = NULL;

					if(LUA_REFNIL != ref)
						cb.Unref(L, ref);

					lua_pushnumber(L, -1);
					return 1;
				}
				u->FillPlutoFromLua(pProp->m_nType, L, -1);

				lua_pop(L, 1);
			}
		}
		lua_pop(L, 1);
		//LogDebug("parse table list end", "%d", 1);

	}

	//printf("%d", u->GetLen());

	(*u) << EndPluto;
	// PrintHexPluto(*u);
	//printf("%d, %d", u->GetLen(), itemName.size());
	//*u << itemName << uniqKey << nBaseappId << ref << (uint16_t)0;
	uint32_t pos = (MSGLEN_TEXT_POS + sizeof(uint16_t) + itemName.size() + sizeof(uint16_t) + uniqKey.size() + sizeof(nBaseappId) + sizeof(int32_t));
	uint16_t value = (u->GetLen() - pos - sizeof(uint16_t));
	//printf("%d %d", pos, value);
	u->ReplaceField(pos, value);
	//PrintHexPluto(*u);

	CMailBox* mb = GetWorldbase().GetServerMailbox(SERVER_DBMGR);
	if(mb)
	{
		//LogInfo("upate items data to db ", "msg_id = %d, itemName = %s, status = %d", MSGID_DBMGR_UPDATE_BATCH, itemName.c_str(), 1);
		mb->PushPluto(u);
		//以下两行为测试数据用
	}
    else
    {
		if(LUA_REFNIL != ref)
			cb.Unref(L, ref);

        delete u;
        u = NULL;
    }
	return 0;
}
int lGetArrayFromDb(lua_State* L)
{
    int n = lua_gettop(L);
    if( n != 3 )
    {
        LogError("lGetArrayFromDb", "Parameters number from lua not enough");
        lua_pushnumber(L, 0);
        return 1;
    }
    if( LUA_TSTRING != lua_type(L, 1) && LUA_TNUMBER != lua_type(L, 2) )
    {
        LogError("Parameters type from lua erroe", "%d", -1);
        lua_pushnumber(L, 0);
        return 1;
    }
    luaL_checkany(L, 3);

    CLuaCallback& cb = GetWorld()->GetCallback();
    lua_pushvalue(L, 3);
    int32_t ref = (int32_t)cb.Ref(L);

    lua_pop(L, 1);

    const char* itemName = lua_tostring(L, 1);
    const TDBID dbid = lua_tonumber(L, 2);
    uint16_t nBaseappId = GetWorld()->GetMailboxId();

    CMailBox* mb = GetWorldbase().GetServerMailbox(SERVER_DBMGR);
    if(mb)
    {
        //cout<<"get arary from db"<<endl;
        //cout<<"ref ="<<ref<<endl;
        mb->RpcCall(GetWorldbase().GetRpcUtil(), MSGID_DBMGR_LOADING_ITEMS, itemName, dbid, nBaseappId, ref);
    }
    else
    {
        cb.Unref(L, ref);
    }
    return 0;
}


int CreateEntityInBase(lua_State* L)
{
    CEntityBase* p = _CreateEntity<CEntityBase>(L);

    if (!p)
    {
        lua_pushstring(L, "CreateEntityInBase, can not create entity");
        lua_error(L);
        return 0;
    }

    GetWorldbase().AddEntity(p);

    if(lua_gettop(L) > 1)
    {
        //附带了初始化参数,注意有一种情况是dbmgr指定了第2个参数是id,两者兼容
        p->UpdateProps(L);
    }

    int n = EntityMethodCall(L, p, s_entity_ctor_name, 0, 0);
    lua_pop(L, n);

    return 1;
}

//由cwmd指定一个baseapp创建base
int CreateBaseAnywhere(lua_State* L)
{
    const char* pszEntity = luaL_checkstring(L, 1);        //entity type name
#ifdef __USE_MSGPACK
    msgpack::sbuffer sbuff;
    msgpack::packer<msgpack::sbuffer> pker(&sbuff);
    charArrayDummy d;       //附加参数的table
#else
    string strParam;        //附加参数的table
#endif
    if(lua_gettop(L) > 1 )
    {
#ifdef __USE_MSGPACK
        if(!LuaPickleToBlob(L, pker))
#else
        if(!LuaPickleToString(L, strParam))
#endif
        {
            lua_pushstring(L, "createBaseAnywhere, param 2 need a table");
            lua_error(L);
            return 0;
        }
    }

    //LogDebug("CreateBaseAnywhere", "pszEntity=%s;strParam.c_str()=%s", pszEntity, strParam.c_str());
#ifdef __USE_MSGPACK
    d.m_s = new char[sbuff.size()];
    d.m_l = sbuff.size();
    memcpy(d.m_s, sbuff.data(), sbuff.size());
    LogDebug("CreateBaseAnywhere", "pszEntity=%s;sbuff.data()=%s;sbuff.size()=%d", pszEntity, sbuff.data(), sbuff.size());
    GetWorld()->RpcCall(SERVER_BASEAPPMGR, MSGID_BASEAPPMGR_CREATEBASE_ANYWHERE, pszEntity, d);

#else
    GetWorld()->RpcCall(SERVER_BASEAPPMGR, MSGID_BASEAPPMGR_CREATEBASE_ANYWHERE, pszEntity, strParam.c_str());
#endif
    return 0;
}

int DestroyBaseEntity(lua_State* L)
{

    TENTITYID eid = (TENTITYID)luaL_checkint(L, 1);
    CEntityBase* pe = (CEntityBase*)(GetWorldbase().GetEntity(eid));
    if(pe)
    {
        //printf("destroy_cellentity,%d\n", eid);

        EntityMethodCall(L, pe, "onDestroy", 0, 0);
        ClearLuaStack(L);

        //从世界中删除
        if (!GetWorldbase().DelEntity(pe))
        {
            LogWarning("DestroyBaseEntity", "GetWorldbase().DelEntity failed.");
        }

        //GetWorldbase().DelEntity(pe);

        //从lua的entity集合中删除
        luaL_getmetatable(L, g_szUserDataEntity);
        lua_pushlightuserdata(L, pe);
        lua_pushnil(L);
        lua_rawset(L, -3);
        //lua_pop(m_L, 1);
        ClearLuaStack(L);

        //显式的删除所有属性字段,不要等到析构函数,以防循环引用
        pe->ClearAllData();

        //test code,检查是否已经从lua中删除掉了
        //int nGcRet = lua_gc(m_L, LUA_GCCOLLECT, 0);
        //printf("lua_gc,ret=%d\n", nGcRet);
        return 0;
    }

    return -1;
}
//发起创建,此时无数据无法真正创建
int CreateEntityFromDbId(lua_State* L)
{
    const char* szEntityType = luaL_checkstring(L, 1);
    TDBID dbid = (TDBID)luaL_checknumber(L, 2);
    luaL_checkany(L, 3);                        //callback

    CWorldBase& worldbase = GetWorldbase();
    CMailBox* mb = worldbase.GetServerMailbox(SERVER_DBMGR);
    if(mb && dbid > 0)
    {
        CLuaCallback& cb = worldbase.GetCallback();
        //lua_pushvalue(L, 3);
        int32_t ref = (int32_t)cb.Ref(L);

        //LogInfo("[create entity from db id]", "[entity type=%s][dbid =%d][ref =%d]",szEntityType, dbid, ref);

        mb->RpcCall(worldbase.GetRpcUtil(), MSGID_DBMGR_SELECT_ENTITY, \
                    worldbase.GetServer()->GetMailboxId(), szEntityType, dbid, ref);
    }
    return 0;
}

//数据库操作成功,根据数据库的数据创建
CEntityBase* CreateEntityFromDbData(lua_State* L, TDBID dbid, SEntityPropFromPluto* pProps)
{
    //printf("top:%d\n", lua_gettop(L));
    CEntityBase* p = _CreateEntity<CEntityBase>(L);
    GetWorldbase().AddEntity(p);
    p->UpdateProps(dbid, pProps);

    int n = EntityMethodCall(L, p, s_entity_ctor_name, 0, 0);
    lua_pop(L, n);

    //此时entity在L顶
    return p;
}

//根据唯一索引的值从数据库创建entity,如果数据库没有对应数据，则新创建一个
int CreateBaseFromDbByNameAnywhere(lua_State* L)
{
    const char* pszEntityType = luaL_checkstring(L, 1);
    const char* pszEntityKey = luaL_checkstring(L, 2);

    world* the_world = GetWorld();
    CMailBox* mb2 = the_world->GetServerMailbox(SERVER_BASEAPPMGR);
    if(mb2)
    {
        //标记1表示如果数据库中不存在,也要创建一个entity
        mb2->RpcCall(the_world->GetRpcUtil(), MSGID_BASEAPPMGR_CREATEBASE_FROM_NAME_ANYWHERE, (uint8_t)1,
                     pszEntityType, pszEntityKey);
    }

    return 0;
}

//根据唯一索引的值从数据库创建entity,如果数据库没有对应数据，则新创建一个
int CreateBaseFromDbByName(lua_State* L)
{
    const char* pszEntityType = luaL_checkstring(L, 1);
    const char* pszEntityKey = luaL_checkstring(L, 2);

    world* the_world = GetWorld();

    CMailBox* mb2 = the_world->GetServerMailbox(SERVER_BASEAPPMGR);
    if(mb2)
    {
        uint16_t nBaseAppId = the_world->GetMailboxId();
        //标记1表示如果数据库中不存在,也要创建一个entity
        mb2->RpcCall(the_world->GetRpcUtil(), MSGID_BASEAPPMGR_CREATEBASE_FROM_NAME, (uint8_t)1,
                     pszEntityType, pszEntityKey, nBaseAppId);
    }

    return 0;
}

int CreateBaseWithData(lua_State* L, map<string, VOBJECT*>& new_data)
{
    CEntityBase* p = _CreateEntity<CEntityBase>(L);
    GetWorldbase().AddEntity(p);
    p->UpdateProps(new_data);

    int n = EntityMethodCall(L, p, s_entity_ctor_name, 0, 0);
    lua_pop(L, n);

    return 1;
}

int LoadAllAvatars(lua_State* L)
{
    const static char szEntity[] = "Avatar";
    const static char szIndex[] = "account_name";

    world* the_world = GetWorld();
    CMailBox* mb = the_world->GetServerMailbox(SERVER_DBMGR);
    if(mb)
    {
        mb->RpcCall(the_world->GetRpcUtil(), MSGID_DBMGR_LOAD_ALL_AVATAR, szEntity, szIndex);
    }

    return 0;
}

int LoadEntitiesOfType(lua_State* L)
{
    const char* pszEntity = luaL_checkstring(L, 1);
    uint16_t nBaseappId = GetWorld()->GetMailboxId();

    world* the_world = GetWorld();
    CMailBox* mb = the_world->GetServerMailbox(SERVER_DBMGR);
    if(mb)
    {
        mb->RpcCall(the_world->GetRpcUtil(), MSGID_DBMGR_LOAD_ENTITIES_OF_TYPE, pszEntity, nBaseappId);
    }

    return 0;
}

int GetUuid(lua_State* L)
{
#ifdef _WIN32
    int n1 = rand();
    int n2 = rand();
    int n3 = (int)(time(NULL) % 10000);

    char s[64];
    memset(s, 0, sizeof(s));
    snprintf(s, sizeof(s), "%d_%d_%d", n3, n1, n2);

    lua_pushstring(L, s);
    return 1;
#else
    uuid_t u;
    uuid_generate(u);

    char s[sizeof(u)*2+1];
    for(size_t i=0; i<sizeof(u); ++i)
    {
        char_to_sz(u[i], s+2*i);
    }
    s[sizeof(u)*2] = '\0';

    lua_pushstring(L, s);
    return 1;
#endif
}

int GetRptName(lua_State* L)
{
    lua_getglobal(L, "G_RPT_PATH");
    const char* pszPath = lua_tostring(L, -1);
    GetUuid(L);
    const char* pszUuid = lua_tostring(L, -1);

    char s[256];
    memset(s, 0, sizeof(s));
    snprintf(s, sizeof(s), "%s%s%s.xml", pszPath, g_cPathSplit, pszUuid);

    char s2[64];
    memset(s2, 0, sizeof(s2));
    snprintf(s2, sizeof(s2), "%s.xml", pszUuid);

    lua_pushstring(L, s);
    lua_pushstring(L, s2);
    return 2;
}

//修改loginapp登录状态
int SetLogin(lua_State* L)
{
    int n = luaL_checkint(L, 1);
    if(n != 0)
    {
        n = 1;
    }

    GetWorld()->RpcCall(SERVER_LOGINAPP, MSGID_LOGINAPP_MODIFY_LOGIN_FLAG, (uint8_t)n);
    return 0;
}

int ForbidLogin(lua_State* L)
{
    const char* account = luaL_checkstring(L, 1);
    int n = luaL_checkint(L, 2);

    GetWorld()->RpcCall(SERVER_LOGINAPP, MSGID_LOGINAPP_FORBIDLOGIN, account, (uint32_t)n);
    return 0;
}
int ForbidLoginByIp(lua_State* L)
{
	const char* ip = luaL_checkstring(L, 1);
	int n = luaL_checkint(L, 2);

	GetWorld()->RpcCall(SERVER_LOGINAPP, MSGID_LOGINAPP_FORBID_IP_UNTIL_TIME, ip, (uint32_t)n);
	return 0;
}
int ForbidLoginByAccount(lua_State* L)
{
	const char* account = luaL_checkstring(L, 1);
	int n = luaL_checkint(L, 2);

	GetWorld()->RpcCall(SERVER_LOGINAPP, MSGID_LOGINAPP_FORBID_ACCOUNT_UNTIL_TIME, account, (uint32_t)n);
	return 0;
}


int LogCollect(lua_State* L)
{
	const char* sql = luaL_checkstring(L, 1);

	GetWorld()->RpcCall(SERVER_LOG, MSGID_LOG_INSERT, sql);
	
	return 0;
}

int HttpReq(lua_State* L)
{
	const char* url = luaL_checkstring(L, 1);

	GetWorld()->RpcCall(SERVER_LOG, MSGID_OTHER_HTTP_REQ, url);

	return 0;
}

int BrowserResponse(lua_State* L)
{	
	int32_t client_fd = (int32_t)luaL_checkint(L, 1);
	const char* result = luaL_checkstring(L, 2);

	GetWorld()->RpcCall(SERVER_LOG, MSGID_OTHER_CLIENT_RESPONSE, client_fd,  result);

	return 0;
}




//设置全局数据
int SetBaseData(lua_State* L)
{
    const char* key = luaL_checkstring(L, 1);
    luaL_checkany(L, 2);

    if(lua_isnil(L, 2))
    {
        BroadcastBaseapp(MSGID_BASEAPP_DEL_BASE_DATA, key);
    }
    else if(lua_isnumber(L, 2))
    {
        const char* value = lua_tostring(L, 2);
//#ifdef __USE_MSGPACK
//
//        BroadcastBaseapp(MSGID_BASEAPP_SET_BASE_DATA, key, (uint8_t)V_UINT8, (charArrayDummy*)value);
//#else
        BroadcastBaseapp(MSGID_BASEAPP_SET_BASE_DATA, key, (uint8_t)V_UINT8, value);
//#endif
    }
    else if(lua_isstring(L, 2))
    {
        const char* value = lua_tostring(L, 2);
//#ifdef __USE_MSGPACK
//
//        BroadcastBaseapp(MSGID_BASEAPP_SET_BASE_DATA, key, (uint8_t)V_STR, (charArrayDummy*)value);
//#else
        BroadcastBaseapp(MSGID_BASEAPP_SET_BASE_DATA, key, (uint8_t)V_STR, value);
//#endif
    }
    else if(lua_istable(L, 2))
    {
#ifdef __USE_MSGPACK
        msgpack::sbuffer sbuff;
        msgpack::packer<msgpack::sbuffer> pker(&sbuff);
        charArrayDummy d;
        LuaPickleToBlob(L, pker);
        d.m_s = new char[sbuff.size()];
        d.m_l = sbuff.size();
        memcpy(d.m_s, sbuff.data(), sbuff.size());
        BroadcastBaseapp(MSGID_BASEAPP_SET_BASE_DATA, key, (uint8_t)V_LUATABLE, d);
#else
        string strValue;
        LuaPickleToString(L, strValue);
        BroadcastBaseapp(MSGID_BASEAPP_SET_BASE_DATA, key, (uint8_t)V_LUATABLE, strValue.c_str());
#endif
    }
    else
    {
        lua_pushstring(L, "invalid type of param 2.");
        lua_error(L);
    }

    return 0;
}

int GetTimeZone(lua_State* L)
{
#ifndef _WIN32
    struct timezone tz;
    if (gettimeofday(NULL, &tz) == 0)
    {
        lua_pushinteger(L, tz.tz_minuteswest);
        return 1;
    }
    else
    {
        lua_pushstring(L, "get timezone error.");
        lua_error(L);
        return 0;
    }
#else
	return 0;
#endif
}

int BroadcastClientRpc(lua_State* L)
{

    const char* pszEntity = luaL_checkstring(L, 1);
    const char* pszFunc = luaL_checkstring(L, 2);

    world* the_world = GetWorld();
    if (!the_world)
    {
        return 0;
    }

    const SEntityDef* pDef = the_world->GetDefParser().GetEntityDefByName(pszEntity);
    if (!pDef)
    {
        return 0;
    }

    map<string, _SEntityDefMethods*>::const_iterator iter11 = \
        pDef->m_clientMethods.find(pszFunc);
    if(iter11 == pDef->m_clientMethods.end())
    {
        return 0;
    }

    //把pszEntity和pszFunc从堆栈中移除掉
    lua_remove(L, 1);
    lua_remove(L, 1);


    const _SEntityDefMethods* pMethods = iter11->second;
    const list<VTYPE>& args = pMethods->m_argsType;
    int nArgCount = lua_gettop(L);
    if(nArgCount != (int)args.size())
    {
        return 0;
    }

    uint16_t nFuncId = (uint16_t)pDef->m_clientMethodsMap.GetIntByStr(pszFunc);

    CPluto* u = new CPluto;
    u->Encode(MSGID_BASEAPP_BROADCAST_CLIENT_PRC);

    (*u) << the_world->GetDefParser().GetTypeId(pszEntity) << nFuncId;

    //打包rpc的所有参数为一个string
    int idx = 0;
    list<VTYPE>::const_iterator iter = args.begin();
    for(; iter != args.end(); ++iter)
    {
        ++idx;
        VTYPE vt = *iter;
        u->FillPlutoFromLua(vt, L, idx);
    }

    (*u) << EndPluto;

    the_world->GetServer()->AddLocalRpcPluto(u);

    vector<CMailBox*>& mbs = the_world->GetServer()->GetAllServerMbs();
    vector<CMailBox*>::iterator iter2 = mbs.begin();
    for(; iter2 != mbs.end(); ++iter2)
    {
        CMailBox* basemb = *iter2;
        if(basemb && basemb->GetServerMbType() == SERVER_BASEAPP)
        {
            //发给每个其他baseapp的mb的pluto都是发给本地进程的那个pluto的拷贝
            CPluto* u2 = new CPluto(u->GetBuff(), u->GetLen());
            basemb->PushPluto(u2);
        }
    }

    return 0;
}

//int iter_entities(lua_State* L)
//{
//    return g_worldbase.iter_entities(L);
//}
//
//int list_entities(lua_State* L)
//{
//    lua_pushlightuserdata(L, g_worldbase.getEnMgrBegin());
//    lua_pushcclosure(L, iter_entities, 1);
//    return 1;
//}

int LuaOpenMogoLibCBase (lua_State *L)
{
    LuaOpenEntityLib<CEntityBase>(L);
    //原始的名称设为mogoLib
    static const luaL_Reg mogoLib[] =
    {
        {"createBase",         CreateEntityInBase},
        {"createBaseAnywhere", CreateBaseAnywhere},
        {"createBaseFromDBID", CreateEntityFromDbId},
        {"createBaseFromDbByNameAnywhere", CreateBaseFromDbByNameAnywhere},
        {"createBaseFromDbByName", CreateBaseFromDbByName},
        {"getEntity",         GetEntity},
        {"getPropId",        GetEntityPropId},
        {"cPickle",            LuaPickle},
        {"cUnpickle",          LuaUnpickle},
        {"readXmlToList",      XmlReadToList},
        {"readXmlToMap",       XmlReadToMap},
        {"readXml",            XmlReadToMapByKey},
        {"readSpace",          XmlReadSpace},
        {"logDebug",     LuaLogDebug},
        {"logInfo",      LuaLogInfo},
        {"logWarning",   LuaLogWarning},
        {"logError",     LuaLogError},
        {"stest",              bit_stest},
        {"sset",               bit_sset},
        {"sunset",             bit_sunset},
        {"wtest",              bit_wtest},
        {"wset",               bit_wset},
        {"loadAllAvatars",     LoadAllAvatars},
        {"loadEntitiesOfType", LoadEntitiesOfType},
        {"pickleMailbox",     PickleMailbox},
        {"UnpickleBaseMailbox",     UnpickleBaseMailbox},
        {"UnpickleCellMailbox",     UnpickleCellMailbox},
        {"makeBaseMailbox",  MakeBaseMailbox},
        {"makeCellMailbox",  MakeCellMailbox},
        {"getUuid",            GetUuid},
        {"getRptName",       GetRptName},
        {"setLogin",           SetLogin},
        {"setBaseData",        SetBaseData},
        {"deepcopy1",          DeepCopyTable1},
        {"dist_p2p",           LuaPoint2PointDistance},
        {"dist_p2l",           LuaPoint2LineDistance},
        {"load_bm",            LoadBlockMap },
        {"moveSimple",        MoveSimple},
        {"getTimeZone",       GetTimeZone},
        {"addStopWord",       AddStopWord},
        {"isStopWord",        IsStopWord},
        {"crossServerRpc",    CrossServerRpc},
        {"crossClientResp",   CrossClientResp},
        {"crossClientBroadcast", CrossClientBroadcast},

        //{"AddEventListener", AddEventListener},
        //{"RemoveEventListener", RemoveEventListener},

        //{"TriggerEvent", TriggerEvent},

        {"DestroyBaseEntity", DestroyBaseEntity},
        {"getTickCount", LuaGetTickCount},
        {"confirm",           LuaConfirm},
        {"WriteArrayToDb", lWriteArrayToDb},
        {"GetArrayFromDb", lGetArrayFromDb},
        {"BroadcastClientRpc", BroadcastClientRpc},
        {"UpdateBatchToDb", lUpdateBatchToDb},
        {"IncrementalUpdateItems", lIncrementalUpdateItems},

        {"forbidLogin", ForbidLogin},
		{"forbidLoginByIp", ForbidLoginByIp},
        {"logCollect", LogCollect},
        {"httpReq", HttpReq},

		{"browserResponse", BrowserResponse},
        {NULL, NULL}
    };

#ifndef __LUA_5_2_1
    luaL_register(L, s_szMogoLibName, mogoLib);
    //luaL_register之后cw位于栈顶

    lua_pushstring(L, "baseData");
    lua_newtable(L);
    lua_rawset(L, -3);

#else

    //以下三行代码替换上面注释的代码语句。lua版本5.2中采用以下格式注册c函数，
    //5.1版本中采用上面的方法注册c函数
    lua_newtable(L);
    luaL_setfuncs(L, mogoLib, 0);

    lua_pushstring(L, "baseData");
    lua_newtable(L);
    lua_rawset(L, -3);

    lua_setglobal(L, s_szMogoLibName);

#endif // !__LUA_5.2.1

    ClearLuaStack(L);

    return 0;
}

