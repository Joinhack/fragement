/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：lua_mogo
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.5
// 模块描述：mogo 相关的 lua 封装
//----------------------------------------------------------------*/

#include <math.h>


#include "lua_mogo.h"
#include "entity.h"
#include "my_stl.h"
#include "defparser.h"
#include "timer.h"
#include "pluto.h"
#include "world_select.h"
#include "path_founder.h"
#include "lua_mogo_impl.h"
#include "debug.h"

const char* s_szMogoLibName = "mogo";
const char* s_szEntityName = "Entity";
const char* s_szListObject = "ListObject";
const char* g_szlistMap = "G_LISTMAP";
const char* s_szSpaceName = "Space";
const char* s_szCallback = "callback_objs";         //所有回调object的集合
const char* g_szMailboxMt = "Mailbox_Mt";
const char* g_szBaseClientMailboxMt = "BaseClientMailboxMt";
const char* g_szClientMailboxMt = "ClientMailbox_Mt";
const char* g_szCellMailboxMt = "CellMailbox_Mt";
const char* g_szGlobalBases = "globalBases";
const char* g_szUserDataEntity = "mogo_entities";
const char* g_szXmlUtil = "XmlUtil_udata";
const char* g_szLUATABLES = "G_LUATABLES";


using namespace mogo;

//清除lua栈
void ClearLuaStack(lua_State* L)
{
    //int n = lua_gettop(L);
    //lua_pop(L, n);
    lua_settop(L, 0);
}

//自定义一个redis hash对应的类
namespace mogo
{

    CRedisHash::CRedisHash(): m_nLoadFlag(ENUM_REDIS_HASH_FIELD_INIT)
    {

    }

    CRedisHash::~CRedisHash()
    {

    }

    void CRedisHash::MakeKey()
    {
        if(m_strKey.empty())
        {
            TDBID dbid = m_pEntity->GetDbid();
            if(dbid == 0)
            {
                return;
            }

            const string& strEntityType = GetWorld()->GetDefParser().GetTypeName(m_pEntity->GetEntityType());
            ostringstream oss;
            oss << strEntityType << ":" << dbid << ":" << m_strAttri;
            m_strKey.assign(oss.str());
        }
    }

    //从redis load数据
    void CRedisHash::Load(lua_State* L)
    {
		//不处理状态了,由脚本层代码维护
        //if(m_nLoadFlag != ENUM_REDIS_HASH_FIELD_INIT)
        //{
        //    //已经开始load了或者已经load完了
        //    return;
        //}

		if(lua_gettop(L) > 1)
		{
			//脚本层指定了key
			const char* pszKey = luaL_checkstring(L, 2);
			//通知dbmgr load数据
			m_nLoadFlag = ENUM_REDIS_HASH_FIELD_LOADING;
			//LogDebug("CRedisHash::Load", "pszKey=%s",pszKey);
			GetWorld()->RpcCall(SERVER_DBMGR, MSGID_DBMGR_REDIS_HASH_LOAD, m_pEntity->GetMyMailbox(), pszKey, pszKey );

			return;
		}

		//脚本层未指定key
        MakeKey();
        if(m_strKey.empty())
        {
            //还没有dbid
            lua_pushfstring(L, "redis_hash filed %s load error, dbid=0", m_strAttri.c_str());
            lua_error(L);
            return;
        }

        //通知dbmgr load数据
        m_nLoadFlag = ENUM_REDIS_HASH_FIELD_LOADING;
		//LogDebug("CRedisHash::Load", "pszKey=%s",m_strKey.c_str());
        GetWorld()->RpcCall(SERVER_DBMGR, MSGID_DBMGR_REDIS_HASH_LOAD, m_pEntity->GetMyMailbox(), m_strAttri, m_strKey);

    }

    void CRedisHash::OnLoaded(const string& strValue)
    {
        m_nLoadFlag = ENUM_REDIS_HASH_FIELD_LOADED;
    }

    void CRedisHash::Set(lua_State* L, uint32_t nSeq, const char* pszValue)
    {
		if(lua_gettop(L) > 3)
		{
			//脚本层指定了key
			const char* pszKey = luaL_checkstring(L, 4);
			GetWorld()->RpcCall(SERVER_DBMGR, MSGID_DBMGR_REDIS_HASH_SET, pszKey, nSeq, pszValue);
			return;
		}

        MakeKey();
        GetWorld()->RpcCall(SERVER_DBMGR, MSGID_DBMGR_REDIS_HASH_SET, m_strKey, (int32_t)nSeq, pszValue);
    }

    void CRedisHash::Del(lua_State* L, uint32_t nSeq)
    {
		if(lua_gettop(L) > 2)
		{
			//脚本层指定了key
			const char* pszKey = luaL_checkstring(L, 3);
			GetWorld()->RpcCall(SERVER_DBMGR, MSGID_DBMGR_REDIS_HASH_DEL, pszKey, nSeq);
			return;
		}

        MakeKey();
        GetWorld()->RpcCall(SERVER_DBMGR, MSGID_DBMGR_REDIS_HASH_DEL, m_strKey, (int32_t)nSeq);
    }

};

int ListMethodCall(lua_State* L)
{
    CRedisHash* p = (CRedisHash*)luaL_checkudata(L, 1, s_szListObject);
    const char* pszAttri = luaL_checkstring(L, lua_upvalueindex(1));

    if(strcmp(pszAttri, "set") == 0)
    {
        int nSeq = luaL_checkint(L, 2);
        const char* pszValue = luaL_checkstring(L, 3);
        p->Set(L, nSeq, pszValue);
    }
    else if(strcmp(pszAttri, "del") == 0)
    {
        int nSeq = luaL_checkint(L, 2);
        p->Del(L, nSeq);
    }
    else if(strcmp(pszAttri, "load") == 0)
    {
        p->Load(L);
    }
    else
    {
        lua_pushfstring(L, "ListMethodCall,error field %s", pszAttri);
        lua_error(L);
    }
	
    return 0;
}


int ListIndex(lua_State* L)
{
    CRedisHash* p = (CRedisHash*)luaL_checkudata(L, 1, s_szListObject);
    const char* pszAttri = luaL_checkstring(L, 2);

    //特殊处理的属性值
    if(strcmp(pszAttri, "is_load") == 0)
    {
        if(p->IsLoaded())
        {
            lua_pushboolean(L, 1);
        }
        else
        {
            lua_pushboolean(L, 0);
        }
        return 1;
    }
    else
    {
        //其他视为方法
        lua_pushstring(L, pszAttri);
        lua_pushcclosure(L, ListMethodCall, 1);
        return 1;
    }

    return 0;
}

int ListNewIndex(lua_State* L)
{
    return 0;


}

int ListGC(lua_State* L)
{
    CRedisHash* pf = (CRedisHash*)luaL_checkudata(L, 1, s_szListObject);
    pf->~CRedisHash();      //只调析构函数不delete

    return 0;
}

//call lua code collectgarbage("count"), returns the total memory in use by Lua (in Kbytes)
float GetGCCount(lua_State* L)
{
    //int n1 = lua_gettop(L);
    lua_getglobal(L, "collectgarbage");
    lua_pushstring(L, "count");
    lua_pcall(L, 1, 1, 0);
    float f = (float)lua_tonumber(L, -1);
    //int n2 = lua_gettop(L);
    lua_pop(L, 1);
    return f;
}

//call lua code collectgarbage("collect")
void GetGCCollect(lua_State* L)
{
    //int n1 = lua_gettop(L);
    lua_getglobal(L, "collectgarbage");
    lua_pushstring(L, "collect");
    lua_pcall(L, 1, 0, 0);
    //int n2 = lua_gettop(L);
}

//清理lua的全局变量并回收垃圾,仅用于内存泄漏检查,真正运行时不用
void ClearLuaAndGc(lua_State* L)
{
	float f1 = GetGCCount(L);		//啥也不做前的内存

	//清理全局变量
	{
		ClearLuaStack(L);		
		lua_getglobal(L, "_G");
		lua_pushnil(L);	
		list<int> lsKeyInt;
		list<string> lsKeyStr;
		while(lua_next(L, 1) != 0)
		{
			//key
			int nKeyType = lua_type(L, -2);
			switch(nKeyType)
			{
			case LUA_TNUMBER:
				{
					lua_pushvalue(L, -2);
					int n = (int)lua_tointeger(L, -1);
					lsKeyInt.push_back(n);
					lua_pop(L, 1);	//复制的key
					break;
				}
			case LUA_TSTRING:
				{
					lua_pushvalue(L, -2);
					const char* s = lua_tostring(L, -1);
					lsKeyStr.push_back(s);
					lua_pop(L, 1);
					break;
				}			
			}
			lua_pop(L, 1);	//value
		}

		list<int>::iterator iter1 = lsKeyInt.begin();
		for(; iter1 != lsKeyInt.end(); ++iter1)
		{
			lua_pushinteger(L, *iter1);
			lua_pushnil(L);
			lua_rawset(L, -3);
		}

		list<string>::iterator iter2 = lsKeyStr.begin();
		for(; iter2 != lsKeyStr.end(); ++iter2)
		{
			lua_pushstring(L, iter2->c_str());
			lua_pushnil(L);
			lua_rawset(L, -3);
		}

		ClearLuaStack(L);
	}

	float f2 = GetGCCount(L);		//清理了全局变量后的内存
	GetGCCollect(L);				//强制垃圾收集
	float f3 = GetGCCount(L);		//垃圾收集后的内存

	printf("lua_gc:f1=%.4f;f2=%.4f;f3=%.4f\n", f1, f2, f3);
}


#ifdef _GC_DEBUG
int __EntityMethodCall(lua_State*L, CEntityParent* e, const char* szFunc,
                       uint8_t nInput, uint8_t nOutput);

int EntityMethodCall(lua_State*L, CEntityParent* e, const char* szFunc,
                     uint8_t nInput, uint8_t nOutput)
{
    GetGCCollect(L);
    float f1 = GetGCCount(L);
    int n = __EntityMethodCall(L, e, szFunc, nInput, nOutput);
    \
    GetGCCollect(L);
    float f2 = GetGCCount(L);
    LogInfo("GC_entity_method_call", "func=%s;diff=%.6f;f1=%.6f;f2=%.6f", szFunc, f2-f1, f1, f2);
    return n;
}

int __EntityMethodCall(lua_State*L, CEntityParent* e, const char* szFunc,
                       uint8_t nInput, uint8_t nOutput)
#else
int EntityMethodCall(lua_State*L, CEntityParent* e, const char* szFunc,
                     uint8_t nInput, uint8_t nOutput)
#endif
{
    if(e == NULL)
    {
        LogDebug("EntityMethodCall", "entity is null.");
        return nInput;
    }

#ifdef __TEST
    CGetTimeOfDay time_prof;
#endif

    lua_pushcfunction(L, pcall_handler);    //pcall_handler

    //根据指针获得lua userdata
    luaL_getmetatable(L, g_szUserDataEntity);
    //LogDebug("Entity method call", "user data entity %s", g_szUserDataEntity);
    lua_pushlightuserdata(L, e);
    lua_rawget(L, -2);

    //int nnnn = lua_isnil(L, -1);

    //是否拥有调用的那个方法
    const string& szEntityType = GetWorld()->GetDefParser().GetTypeName(e->GetEntityType());
    lua_getglobal(L, szEntityType.c_str());
    //LogDebug("Entity method call", "entity type %s", szEntityType.c_str());
    if(lua_isnil(L, -1))
    {
        LogError("EntityMethodCall entity_method_call", "entity '%s' hasn't script", szEntityType.c_str());
        return 4 + nInput;
    }

    lua_getfield(L, -1, szFunc);
    //LogDebug("Entity method call", "entity funz %s", szFunc);

    if(lua_isnil(L, -1))
    {
        LogError("EntityMethodCall entity_method_call", "entity '%s' hasn't method '%s'", szEntityType.c_str(), szFunc);
        return 5+nInput;
    }

    lua_pushvalue(L, -3);

    //cout << "gettop:" << lua_gettop(L) << endl;
    //LogInfo("EntityMethodCall", "gettop=%d", lua_gettop(L));

    for(int i = nInput; i > 0 ; --i)
    {
        lua_pushvalue(L, -6 - nInput);
    }

    //调用之前:lua_stack从顶向下依次为: 输入参数(nInput),entity
    //调用方法名,entity_type_name,entity,userdata_table,输入参数(nInput)
    //
    //调用之后:lua_stack从顶向下依次为: 返回参数(nOutput),
    //entity_type_name,entity,userdata_table,输入参数(nInput)
    //
    int nRet = lua_pcall(L, 1 + nInput, nOutput, -6-nInput);
    if (nRet != 0)
    {
        if (nRet == LUA_ERRRUN)
        {
            LogError("EntityMethodCall entity_method_call", "call %s.%s error:%s", \
                     szEntityType.c_str(), szFunc, lua_tostring(L, -1));
        }

#ifdef __TEST
        LogInfo("time_prof_2", "EntityMethodCall cost=%d,func=%s", time_prof.GetLapsedTime(), szFunc);
#endif

        //栈里多了一条错误信息
        return 5+nInput;
    }

#ifdef __TEST
    LogInfo("time_prof_2", "EntityMethodCall cost=%d,func=%s", time_prof.GetLapsedTime(),szFunc);
#endif

    //由调用的方法使用lua_pop来清理栈
    return 4+nInput+nOutput;
}

//int entity_method_call(lua_State*L, CEntityParent* e, const char* szFunc,
//                     uint8_t nInput, uint8_t nOutput)
//{
//  int n1 = lua_gettop(L);
//  int n2 = __entity_method_call(L, e, szFunc, nInput, nOutput);
//  int n3 = lua_gettop(L);
//  printf("n1=%d;n2=%d;n=%d\n", n1, n2, n3);
//  return n2;
//}

//不需要entity调用一个脚本的方法
void _ScriptMethodCall(lua_State* L, const char* szEntityType, const char* szFunc, uint8_t nInput, uint8_t nOutput)
{
    //是否拥有调用的那个方法
    lua_getglobal(L, szEntityType);
    if(lua_isnil(L, -1))
    {
        LogError("_ScriptMethodCall entity_method_call", "entity '%s' hasn't script", szEntityType);
        return;
    }

    lua_getfield(L, -1, szFunc);
    if(lua_isnil(L, -1))
    {
        LogError("_ScriptMethodCall entity_method_call", "entity '%s' hasn't method '%s'", szEntityType, szFunc);
        return;
    }

    for(int i = nInput; i > 0 ; --i)
    {
        lua_pushvalue(L, -2 - nInput);
    }

    int nRet = lua_pcall(L, nInput, nOutput, 0);
    if (nRet != 0)
    {
        if (nRet == LUA_ERRRUN)
        {
            LogError("_ScriptMethodCall entity_method_call", "call %s.%s error:%s", \
                     szEntityType, szFunc, lua_tostring(L, -1));
        }
        return;
    }

    return;
}

void ScriptMethodCall(lua_State* L, const char* szEntityType, const char* szFunc, uint8_t nInput, uint8_t nOutput)
{
    int n1 = lua_gettop(L);     //调用前
    _ScriptMethodCall(L, szEntityType, szFunc, nInput, nOutput);
    int n2 = lua_gettop(L);     //调用后

    int n = n2 - n1 + nInput;   //调用后增加的数目 以及 输入参数数目
    if(n> 0 && n <= n2)
    {
        //清理栈
        lua_pop(L, n);
    }

    //int n3 = lua_gettop(L);       //清理后

    return;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

int NewBaseMailbox(lua_State* L, uint16_t nServerId, TENTITYTYPE etype, TENTITYID eid)
{
    lua_newtable(L);
    luaL_getmetatable(L, g_szMailboxMt);
    lua_setmetatable(L, -2);

    lua_pushinteger(L, nServerId);
    lua_rawseti(L, -2, g_nMailBoxServerIdKey);
    lua_pushinteger(L, etype);
    lua_rawseti(L, -2, g_nMailBoxClassTypeKey);
    lua_pushinteger(L, eid);
    lua_rawseti(L, -2, g_nMailBoxEntityIdKey);

    return 0;
}

int NewCellMailbox(lua_State* L, uint16_t nServerId, TENTITYTYPE etype, TENTITYID eid)
{
    lua_newtable(L);
    luaL_getmetatable(L, g_szCellMailboxMt);
    lua_setmetatable(L, -2);

    lua_pushinteger(L, nServerId);
    lua_rawseti(L, -2, g_nMailBoxServerIdKey);
    lua_pushinteger(L, etype);
    lua_rawseti(L, -2, g_nMailBoxClassTypeKey);
    lua_pushinteger(L, eid);
    lua_rawseti(L, -2, g_nMailBoxEntityIdKey);

    return 0;
}

int NewClientMailbox(lua_State* L, int32_t nServerId, TENTITYTYPE etype, TENTITYID eid)
{
    lua_newtable(L);
    luaL_getmetatable(L, g_szClientMailboxMt);
    lua_setmetatable(L, -2);

    lua_pushinteger(L, nServerId);
    lua_rawseti(L, -2, g_nMailBoxServerIdKey);

    lua_pushinteger(L, etype);
    lua_rawseti(L, -2, g_nMailBoxClassTypeKey);
    lua_pushinteger(L, eid);
    lua_rawseti(L, -2, g_nMailBoxEntityIdKey);

    return 0;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//base mailbox

int MailboxMtRpc(lua_State* L)
{
    //printf("mailbox_mt_rpc\n");

    //printf("arg:%d\n", lua_gettop(L));

    //检查参数
    luaL_checktype(L, lua_upvalueindex(1), LUA_TTABLE);
    const char* pszFunc = luaL_checkstring(L, lua_upvalueindex(2));   //rpc方法名

    //读取mailbox的参数
    CEntityMailbox em;

    lua_rawgeti(L, lua_upvalueindex(1), g_nMailBoxServerIdKey);
    em.m_nServerMailboxId = (uint16_t)luaL_checkint(L, -1);

    lua_rawgeti(L, lua_upvalueindex(1), g_nMailBoxClassTypeKey);
    em.m_nEntityType = (TENTITYTYPE)luaL_checkint(L, -1);

    lua_rawgeti(L, lua_upvalueindex(1), g_nMailBoxEntityIdKey);
    em.m_nEntityId = (TENTITYID)luaL_checkint(L, -1);

    lua_pop(L, 3);

    //printf("arg:%d\n", lua_gettop(L));

    GetWorld()->RpcCallFromLua(pszFunc, em, L);

    //CEpollServer* s = g_worldbase.get_server();
    //CMailBox* mb = s->get_server_mailbox(em.m_nServerMailboxId);
    //if(mb)
    //{
    //    mb->rpc_call_from_lua(g_worldbase.GetRpcUtil(), msgid, em);
    //}

    return 0;
}

int _MailboxBaseClientIndex(lua_State* L);

int MailboxMtIndex(lua_State* L)
{
    //printf("mailbox_mt_index\n");
    luaL_checktype(L, 1, LUA_TTABLE);
    const char* szFunc = luaL_checkstring(L, 2);   //rpc方法名

    //base.client.rpc(p1, p2)的转发功能
    if(strcmp(szFunc, "client") == 0)
    {
        return _MailboxBaseClientIndex(L);
    }

    lua_rawgeti(L, 1, g_nMailBoxClassTypeKey);

    TENTITYTYPE etype = (TENTITYTYPE)luaL_checkint(L, -1);
    const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByType(etype);
    int32_t nFuncId = pDef->m_baseMethodsMap.GetIntByStr(szFunc);
    if(nFuncId == -1)
    {
        lua_pushfstring(L, "Entity %s hasn't method %s",
                        GetWorld()->GetDefParser().GetTypeName(etype).c_str(), szFunc);
        lua_error(L);
        return 0;
    }

    lua_pushvalue(L, 1);
    lua_pushstring(L, szFunc);
    lua_pushcclosure(L, MailboxMtRpc, 2);

    return 1;
}

int MailboxMtNewIndex(lua_State* L)
{
    ////printf("mailbox_mt_newindex\n");
    //luaL_checktype(L, 1, LUA_TTABLE);
    //const char* k = luaL_checkstring(L, 2);
    //const char* v = luaL_checkstring(L, 3);

    //if(strcmp(k, "x") == 0)
    //{
    //    lua_rawset(L, 1);
    //}

    return 0;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//base.client.rpc的index
int BaseClientMailboxMtIndex(lua_State* L)
{
    luaL_checktype(L, 1, LUA_TTABLE);
    const char* szFunc = luaL_checkstring(L, 2);   //rpc方法名

    lua_rawgeti(L, 1, g_nMailBoxClassTypeKey);

    TENTITYTYPE etype = (TENTITYTYPE)luaL_checkint(L, -1);
    const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByType(etype);
    int32_t nFuncId = pDef->m_clientMethodsMap.GetIntByStr(szFunc);
    if(nFuncId == -1)
    {
        lua_pushfstring(L, "Entity %s hasn't method %s",
                        GetWorld()->GetDefParser().GetTypeName(etype).c_str(), szFunc);
        lua_error(L);
        return 0;
    }

    lua_pushvalue(L, 1);
    lua_pushstring(L, szFunc);
    lua_pushcclosure(L, BaseClientMailboxMtRpc, 2);

    return 1;
}

//base.client.rpc(p1,p2)的rpc
int BaseClientMailboxMtRpc(lua_State* L)
{
    //检查参数
    luaL_checktype(L, lua_upvalueindex(1), LUA_TTABLE);
    const char* pszFunc = luaL_checkstring(L, lua_upvalueindex(2));   //rpc方法名

    //读取mailbox的参数
    CEntityMailbox em;

    lua_rawgeti(L, lua_upvalueindex(1), g_nMailBoxServerIdKey);
    em.m_nServerMailboxId = (uint16_t)luaL_checkint(L, -1);

    lua_rawgeti(L, lua_upvalueindex(1), g_nMailBoxClassTypeKey);
    em.m_nEntityType = (TENTITYTYPE)luaL_checkint(L, -1);

    lua_rawgeti(L, lua_upvalueindex(1), g_nMailBoxEntityIdKey);
    em.m_nEntityId = (TENTITYID)luaL_checkint(L, -1);

    lua_pop(L, 3);

    GetWorld()->RpcCallToClientViaBase(pszFunc, em, L);

    return 0;
}

//base.client的特殊index
int _MailboxBaseClientIndex(lua_State* L)
{
    //复制mailbox的table
    lua_newtable(L);
    luaL_getmetatable(L, g_szBaseClientMailboxMt);
    lua_setmetatable(L, -2);

    lua_rawgeti(L, 1, g_nMailBoxServerIdKey);
    lua_rawseti(L, -2, g_nMailBoxServerIdKey);

    lua_rawgeti(L, 1, g_nMailBoxClassTypeKey);
    lua_rawseti(L, -2, g_nMailBoxClassTypeKey);

    lua_rawgeti(L, 1, g_nMailBoxEntityIdKey);
    lua_rawseti(L, -2, g_nMailBoxEntityIdKey);

    return 1;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

int CellMailboxMtRpc(lua_State* L)
{
    //检查参数
    luaL_checktype(L, lua_upvalueindex(1), LUA_TTABLE);
    const char* pszFunc = luaL_checkstring(L, lua_upvalueindex(2));   //rpc方法名

    //读取mailbox的参数
    CEntityMailbox em;

    lua_rawgeti(L, lua_upvalueindex(1), g_nMailBoxServerIdKey);
    em.m_nServerMailboxId = (uint16_t)luaL_checkint(L, -1);

    lua_rawgeti(L, lua_upvalueindex(1), g_nMailBoxClassTypeKey);
    em.m_nEntityType = (TENTITYTYPE)luaL_checkint(L, -1);

    lua_rawgeti(L, lua_upvalueindex(1), g_nMailBoxEntityIdKey);
    em.m_nEntityId = (TENTITYID)luaL_checkint(L, -1);

    lua_pop(L, 3);

    GetWorld()->RpcCall2CellFromLua(pszFunc, em, L);

    return 0;
}

int CellMailboxMtIndex(lua_State* L)
{
    luaL_checktype(L, 1, LUA_TTABLE);
    const char* szFunc = luaL_checkstring(L, 2);   //rpc方法名

    lua_rawgeti(L, 1, g_nMailBoxClassTypeKey);

    TENTITYTYPE etype = (TENTITYTYPE)luaL_checkint(L, -1);
    const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByType(etype);
    int32_t nFuncId = pDef->m_cellMethodsMap.GetIntByStr(szFunc);
    if(nFuncId == -1)
    {
        lua_pushfstring(L, "Entity %s hasn't method %s",
                        GetWorld()->GetDefParser().GetTypeName(etype).c_str(), szFunc);
        lua_error(L);
        return 0;
    }

    lua_pushvalue(L, 1);
    lua_pushstring(L, szFunc);
    lua_pushcclosure(L, CellMailboxMtRpc, 2);

    return 1;
}

int CellMailboxMtNewIndex(lua_State* L)
{
    return 0;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

int ClientMailboxMtRpc(lua_State* L)
{
    //printf("client_mailbox_mt_rpc\n");

    //printf("arg:%d\n", lua_gettop(L));

    //检查参数
    luaL_checktype(L, lua_upvalueindex(1), LUA_TTABLE);
    const char* pszFunc = luaL_checkstring(L, lua_upvalueindex(2));   //rpc方法名

    //读取mailbox的参数
    CClientMailbox em;

    lua_rawgeti(L, lua_upvalueindex(1), g_nMailBoxServerIdKey);
    em.m_fd = (int32_t)luaL_checkint(L, -1);

    lua_rawgeti(L, lua_upvalueindex(1), g_nMailBoxClassTypeKey);
    em.m_nEntityType = (TENTITYTYPE)luaL_checkint(L, -1);

    lua_rawgeti(L, lua_upvalueindex(1), g_nMailBoxEntityIdKey);
    em.m_nEntityId = (TENTITYID)luaL_checkint(L, -1);

    lua_pop(L, 3);

    //printf("arg:%d\n", lua_gettop(L));

    GetWorld()->RpcCall2ClientFromLua(pszFunc, em, L);

    return 0;
}

int ClientMailboxMtIndex(lua_State* L)
{
    //printf("client_mailbox_mt_index\n");
    luaL_checktype(L, 1, LUA_TTABLE);
    const char* szFunc = luaL_checkstring(L, 2);   //rpc方法名

    lua_rawgeti(L, 1, g_nMailBoxClassTypeKey);

    TENTITYTYPE etype = (TENTITYTYPE)luaL_checkint(L, -1);
    const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByType(etype);
    int32_t nFuncId = pDef->m_clientMethodsMap.GetIntByStr(szFunc);
    if(nFuncId == -1)
    {
        lua_pushfstring(L, "Entity %s hasn't client method %s",
                        GetWorld()->GetDefParser().GetTypeName(etype).c_str(), szFunc);
        lua_error(L);
        return 0;
    }

    lua_pushvalue(L, 1);
    lua_pushstring(L, szFunc);
    lua_pushcclosure(L, ClientMailboxMtRpc, 2);

    return 1;
}

int ClientMailboxMtNewIndex(lua_State* L)
{
    //printf("client_mailbox_mt_newindex\n");
    //luaL_checktype(L, 1, LUA_TTABLE);
    //const char* k = luaL_checkstring(L, 2);
    //const char* v = luaL_checkstring(L, 3);

    //if(strcmp(k, "x") == 0)
    //{
    //    lua_rawset(L, 1);
    //}

    return 0;
}

#ifndef _WIN32

//mogo.EntityAllclientsRpc(a, 'rpc', ...)
int EntityAllclientsRpc(lua_State* L)
{
	CEntityCell* pCell = (CEntityCell*)luaL_checkudata(L, 1, s_szEntityName);
	const char* pszFunc = luaL_checkstring(L, 2);

	//检查该entity.def是否定义了这个方法	
	const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByType(pCell->GetEntityType());
	int32_t nFuncId = pDef->m_clientMethodsMap.GetIntByStr(pszFunc);
	if(nFuncId == -1)
	{
		lua_pushfstring(L, "Entity hasn't client method %s", pszFunc);
		lua_error(L);
		return 0;
	}

	if(pCell)
	{
		//去掉1,2两个参数
		lua_remove(L, 1);
		lua_remove(L, 1);
		pCell->AllclientsRpc(pszFunc, L);
	}

	return 0;
}

//mogo.EntityOwnclientRpc(a, 'rpc', ...)
int EntityOwnclientRpc(lua_State* L)
{
	CEntityCell* pCell = (CEntityCell*)luaL_checkudata(L, 1, s_szEntityName);
	const char* pszFunc = luaL_checkstring(L, 2);

	//检查entity.def是否定义了这个方法	
	const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByType(pCell->GetEntityType());
	int32_t nFuncId = pDef->m_clientMethodsMap.GetIntByStr(pszFunc);
	if(nFuncId == -1)
	{
		lua_pushfstring(L, "Entity hasn't client method %s", pszFunc);
		lua_error(L);
		return 0;
	}

	if(pCell)
	{
		//去掉1,2两个参数
		lua_remove(L, 1);
		lua_remove(L, 1);
		pCell->OwnclientRpc(pszFunc, L);
	}

	return 0;
}

#endif


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//将entity的mailbox打包为一个字符串
int PickleMailbox(lua_State* L)
{
    CEntityParent* p = (CEntityParent*)luaL_checkudata(L, 1, s_szEntityName);
    const CEntityMailbox& emb = p->GetMyMailbox();

    char szTmp[128];
    memset(szTmp, 0, sizeof(szTmp));
    snprintf(szTmp, sizeof(szTmp), "{%d=%d,%d=%d,%d=%d}",
             g_nMailBoxServerIdKey, emb.m_nServerMailboxId, g_nMailBoxClassTypeKey, emb.m_nEntityType,
             g_nMailBoxEntityIdKey, emb.m_nEntityId);

    lua_pushstring(L, szTmp);
    return 1;
}

int UnpickleBaseMailbox(lua_State* L)
{
    const char* s = luaL_checkstring(L, 1);
    if(LuaUnpickleFromString(L, s))
    {
        luaL_getmetatable(L, g_szMailboxMt);
        lua_setmetatable(L, -2);
        return 1;
    }

    return 0;
}

int UnpickleCellMailbox(lua_State* L)
{
    const char* s = luaL_checkstring(L, 1);
    if(LuaUnpickleFromString(L, s))
    {
        luaL_getmetatable(L, g_szCellMailboxMt);
        lua_setmetatable(L, -2);
        return 1;
    }

    return 0;
}

int _MakeMailbox(lua_State* L, const char* pszMetatable)
{
    LogDebug("_MakeMailbox", "");
    
    CEntityParent* pf = (CEntityParent*)luaL_checkudata(L, 1, s_szEntityName);
    const char* pszPropName = luaL_checkstring(L, 2);
    const char* pszMailbox = luaL_checkstring(L, 3);

    if(LuaUnpickleFromString(L, pszMailbox))
    {
        luaL_getmetatable(L, pszMetatable);
        lua_setmetatable(L, -2);

        CLuaCallback& cb = GetWorld()->GetLuaTables();
        int nRef = cb.Ref(L);
        if(pf->AddAnyMailbox(pszPropName, nRef))
        {
            lua_pushboolean(L, 1);
            return 1;
        }
        else
        {
            cb.Unref(L, nRef);
        }
    }

    return 0;
}

//根据字符串生成base mailbox
int MakeBaseMailbox(lua_State* L)
{
    return _MakeMailbox(L, g_szMailboxMt);
}

//根据字符串生成cell mailbox
int MakeCellMailbox(lua_State* L)
{
    return _MakeMailbox(L, g_szCellMailboxMt);
}

#ifdef __USE_MSGPACK

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//msgpack unpack to lua table
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

bool MsgUnpackToTable(lua_State* L, const char* src, size_t len)
{
   msgpack_unpacked result;
   msgpack_unpacked_init(&result);
   bool ret = msgpack_unpack_next(&result, src, len, NULL);
   if( !ret )
   {
       return false;
   }
   ret = MsgPushMap(L, result.data);
   msgpack_unpacked_destroy(&result);
   return ret;
}

bool MsgPushKey(lua_State* L, msgpack_object& obj)
{
   unsigned int mType = obj.type;
   switch(mType)
   {
        case MSGPACK_OBJECT_DOUBLE:
        {
            double d = obj.via.dec;
            lua_pushnumber(L, (lua_Number)d);
            break;
        }
        case MSGPACK_OBJECT_RAW:
        {
            //string str(obj.via.raw.ptr, obj.via.raw.size);
            //lua_pushstring(L, str.c_str());
            lua_pushlstring(L, obj.via.raw.ptr, obj.via.raw.size);
            break;
        }
        default:
        {
            //cout<<"key type error"<<endl;
            //printf("key type error\n");
            LogError("MsgPushKey", "key type error");
            return false;
        }
   }
   return true;
}

bool MsgPushValue(lua_State* L, msgpack_object& obj)
{
    unsigned int mType = obj.type;
    switch(mType)
    {
        case MSGPACK_OBJECT_DOUBLE:
        {
            double d = obj.via.dec;
            lua_pushnumber(L, (lua_Number)d);
            break;
        }
        case MSGPACK_OBJECT_BOOLEAN:
        {
            bool b = obj.via.boolean;
            lua_pushboolean(L, b);
            break;
        }
        case MSGPACK_OBJECT_RAW:
        {
            //string str(obj.via.raw.ptr, obj.via.raw.size);
            //lua_pushstring(L, str.c_str());
            lua_pushlstring(L, obj.via.raw.ptr, obj.via.raw.size);
            break;
        }
        case MSGPACK_OBJECT_MAP:
        {
            if( !MsgPushMap(L, obj) )
            {
                return false;
            }
            break;
        }
        default:
        {
            // printf("value type error\n");
            LogError("MsgPushValue", "value type error");
            return false;
        }
    }
    return true;
}
bool MsgPushMap(lua_State* L, msgpack_object& msgObj)
{
   msgpack_object_kv *kv;
   unsigned int i = 0;
   int ret = 1;
   if( MSGPACK_OBJECT_MAP != msgObj.type )
   {
        return false;
   }
   lua_newtable(L);
   int idx = lua_gettop(L);
   for(; i < msgObj.via.map.size; i++)
   {
        kv = &msgObj.via.map.ptr[i];
        if( MsgPushKey(L, kv->key) && MsgPushValue(L, kv->val) )
        {
            lua_rawset(L, idx);
            continue;
        }
        return false;
   }
   return true;
}

#endif

void _LuaPickleTable(lua_State* L, int nTableIdx, int nDeepth, string& s)
{
    if(nDeepth > 5)
    {
        s.assign("");
        return;
    }

    ostringstream oss;
    oss << "{";
    lua_pushnil(L);
    int i = 0;

    if (lua_type(L, nTableIdx) != LUA_TTABLE)
    {
        lua_pushfstring(L, "error pickle stack error! : nTableIdx=%d;lua_type(L, nTableIdx)=%d",
                                                        nTableIdx, lua_type(L, nTableIdx));
        lua_error(L);
    }

    while(lua_next(L, nTableIdx) != 0)
    {
        //printf("%s_%s\n", lua_typename(L, lua_type(L, -2)), lua_typename(L, lua_type(L, -1)));

        if(++i > 1)
        {
            oss << ",";
        }

        //key
        int nKeyType = lua_type(L, -2);
        switch(nKeyType)
        {
            case LUA_TNUMBER:
            {
                lua_pushvalue(L, -2);   //复制一份,以防tostring改变了类型
                //oss << lua_tostring(L, -2);
                const char* ss = lua_tostring(L, -1);
                oss << ss;
                lua_pop(L, 1);
                break;
            }
            case LUA_TSTRING:
            {
                lua_pushvalue(L, -2);   //复制一份,以防tostring改变了类型
                //oss << lua_tostring(L, -2);
                size_t nn = 0;
                const char* ss = lua_tolstring(L, -1, &nn);
                char ssnn[5];
                snprintf(ssnn, sizeof(ssnn), "s%03d", nn);
                ssnn[sizeof(ssnn)-1] = '\0';
                oss << ssnn << ss;
                lua_pop(L, 1);
                break;
            }
            default:
            {
                const string& s11 = oss.str();
                const char* pre = s11.c_str();
                lua_pushfstring(L, "error pickle type:%s;pre=%s", lua_typename(L, nKeyType), pre);
                lua_error(L);
            }
        }

        oss << "=";

        //value
        int nValueType = lua_type(L, -1);
        switch(nValueType)
        {
            case LUA_TNUMBER:
            {
                lua_pushvalue(L, -1);  //复制一份,以防tostring改变了类型
                oss << lua_tostring(L, -1) ;
                lua_pop(L, 1);
                break;
            }
            case LUA_TSTRING:
            {
                lua_pushvalue(L, -1);   //复制一份,以防tostring改变了类型
                //oss << lua_tostring(L, -1);
                size_t nn = 0;
                const char* ss = lua_tolstring(L, -1, &nn);
                char ssnn[5];
                snprintf(ssnn, sizeof(ssnn), "s%03d", nn);
                ssnn[sizeof(ssnn)-1] = '\0';
                oss << ssnn << ss;
                lua_pop(L, 1);
                break;
            }
            case LUA_TTABLE:
            {
                string s2;
                int nTop = lua_gettop(L);
                _LuaPickleTable(L, nTop, nDeepth + 1, s2);
                oss << s2;
                break;
            }
            case LUA_TUSERDATA:
            {
                oss << "";
                break;
            }
            default:
            {
                const string& s11 = oss.str();
                const char* pre = s11.c_str();
                lua_pushfstring(L, "error pickle type:%s;pre=%s", lua_typename(L, nValueType), pre);
                lua_error(L);
            }
        }

        lua_pop(L, 1);
    }
    oss << "}";
    
    s.assign(oss.str());
}

//将lua中的table打包为字符串,用于网路传送
bool LuaPickleToString(lua_State* L, string& str)
{
    if(lua_istable(L, -1))
    {
        int idx = lua_gettop(L);
        _LuaPickleTable(L, idx, 1, str);
        //CPluto* u = new CPluto();
        //u->FillBuff(str.c_str(), str.size());
        //u->SetMaxLen(u->GetLen());
        //PrintHexPluto(*u);
        return true;
    }
    return false;
}

#ifdef __USE_MSGPACK
bool LuaPickleToBlob(lua_State* L, msgpack::packer<msgpack::sbuffer>& pker)
{
    if( MsgPackTable(L, pker, 1))
    {
        //LogDebug("LuaPickleToString", "len=%d", sbuff.size());
        //str.assign((const char*)sbuff.data(), sbuff.size());
        //enum {MaxSize = 1<<16 - 1};
        //if (sbuff.size() > MaxSize)
        //{
        //    LogError("LuaPickleToBlob", "sbuff.data()=%s;sbuff.size()=%d", sbuff.data(), sbuff.size());
        //    return false;
        //}
        //CPluto* u = new CPluto();
        //u->FillBuff(str.c_str(), str.size());
        //u->SetMaxLen(u->GetLen());
        //PrintHexPluto(*u);
        //LogDebug("LuaPickleToString", "success");
        return true;
    }
    MG_CONFIRM(false, "LuaPickleToBlob");
    //LogDebug("LuaPickleToString", "failure");
    return false;
}

bool LuaPickleToBlob(lua_State* L, int nLuaStackPos, msgpack::sbuffer& sbuff)
{
    msgpack::packer<msgpack::sbuffer> pker(&sbuff);
    if( MsgPackTable(L, nLuaStackPos, pker, 1) )
    {
        //LogDebug("LuaPickleToString  3", "len=%d", sbuff.size());
        //str.assign((const char*)sbuff.data(), sbuff.size());
        enum {MaxSize = 1<<16 - 1};
        if (sbuff.size() > MaxSize)
        {
            LogError("LuaPickleToBlob", "sbuff.data()=%s;sbuff.size()=%d", sbuff.data(), sbuff.size());
            return false;
        }
        //CPluto* u = new CPluto();
        //u->FillBuff(str.c_str(), str.size());
        //u->SetMaxLen(u->GetLen());
        //PrintHexPluto(*u);
        //LogDebug("LuaPickleToString", "success");
        return true;
    }
    MG_CONFIRM(false, "LuaPickleToBlob");
    //LogDebug("LuaPickleToString", "failure");
    return false;
}

bool LuaUnpickleFromBlob(lua_State* L, char*s, uint16_t len)
{
    return MsgUnpackToTable(L, s, len);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//msgpack pack to lua table
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
bool MsgPackKey(lua_State* L, int idx, msgpack::packer<msgpack::sbuffer>& pker)
{
    int kType = lua_type(L, idx);
    switch( kType )
    {
        case LUA_TSTRING: 
        {
            lua_pushvalue(L, idx);
            const char* s = luaL_checkstring(L, -1); 
            size_t len = strlen(s);
            pker.pack_raw(len);
            pker.pack_raw_body(s, len);
            lua_pop(L, 1);
            break;
        }
        case LUA_TNUMBER:
        {
            lua_pushvalue(L, idx);
            pker.pack_double(luaL_checknumber(L, -1));
            lua_pop(L, 1);
            break;
        }
        default:
        {
            // printf("key type error\n");
            return false;
        }
    }
    return true;
}
bool MsgPackValue(lua_State* L, int idx, msgpack::packer<msgpack::sbuffer>& pker, int deep)
{
    int vType = lua_type(L, idx);
    switch( vType )
    {
        case LUA_TSTRING:
        {
            lua_pushvalue(L, idx);
            const char* s = luaL_checkstring(L, -1);
            size_t len = strlen(s);
            pker.pack_raw(len);
            pker.pack_raw_body(s, len);
            lua_pop(L, 1);
            break;
        }
        case LUA_TBOOLEAN:
        {
            lua_pushvalue(L, idx);
            if( lua_toboolean(L, -1) == 0 )
            {
                pker.pack_false();
            }
            else
            {
                pker.pack_true();
            }
            lua_pop(L, 1);
            break;
        }
        case LUA_TNUMBER:
        {
            lua_pushvalue(L, idx);
            pker.pack_double(luaL_checknumber(L, -1));
            lua_pop(L, 1);
            break;
        }
        case LUA_TTABLE:
        {
            lua_pushvalue(L, idx);
            MsgPackTable(L, idx + 1, pker, deep+1);
            lua_pop(L, 1);
            break;
        }
        default:
        {
            // printf("value type error\n");
            return false;
        }
    }
    return true;
}
unsigned int NumberOfPairs(lua_State* L, int idx)
{
    int nRet = 0;
    lua_pushnil(L);
    while( lua_next(L, idx) != 0 )
    {
        lua_pop(L, 1);
        nRet++;
    }
    return nRet;
}

bool MsgPackTable(lua_State* L, msgpack::packer<msgpack::sbuffer>& pker, int deep)
{
    if (deep >= 5)
    {
        LogError("MsgPackTable", "too deep");
        return false;
    }

    if( lua_istable(L, -1) )
    {
        int idx = lua_gettop(L);
        unsigned int n = NumberOfPairs(L, idx);
        pker.pack_map(n);
        lua_pushnil(L);
        while( lua_next(L, idx) != 0  )
        {
            MsgPackKey(L, idx + 1, pker);
            MsgPackValue(L, idx + 2, pker, deep);
            lua_pop(L, 1);
        }
        return true;
    }
    return false;
}
bool MsgPackTable(lua_State* L, int idx, msgpack::packer<msgpack::sbuffer>& pker, int deep)
{
    if (deep >= 5)
    {
        LogError("MsgPackTable", "too deep");
        return false;
    }

    if( lua_istable(L, idx) )
    {
        lua_pushvalue(L, idx);
        if( MsgPackTable(L, pker, deep) )
        {
            lua_pop(L, 1);
            return true;
        }
        lua_pop(L, 1);
        return false;
    }
    return false;
}

#endif

bool LuaPickleToString(lua_State* L, int nLuaStackPos, string& str)
{
    if( lua_istable(L, nLuaStackPos) )
    {
        _LuaPickleTable(L, nLuaStackPos, 1, str);
        //CPluto* u = new CPluto();
        //u->FillBuff(str.c_str(), str.size());
        //u->SetMaxLen(u->GetLen());
        //PrintHexPluto(*u);
        return true;
    }
    return false;
}

//将lua中的table打包为字符串,用于lua中使用
int LuaPickle(lua_State* L)
{
    luaL_checktype(L, 1, LUA_TTABLE);

    string s;
    _LuaPickleTable(L, 1, 1, s);

    lua_pushstring(L, s.c_str());
    //LogDebug("LuaPickle", "len=%d", s.size());
    return 1;
}

//deepcopy table的第一层
int DeepCopyTable1(lua_State* L)
{
    luaL_checktype(L, 1, LUA_TTABLE);   //检查输入是否是一个table

    lua_newtable(L);                    //生成目标表

    enum { SRC_TABLE_IDX = 1, DEST_TABLE_IDX = 2 }; //src和dest两个table在L里的index

    lua_pushnil(L);
    while(lua_next(L, SRC_TABLE_IDX) != 0)
    {
        lua_pushvalue(L, -2);           //复制key
        lua_pushvalue(L, -2);           //复制value

        lua_rawset(L, DEST_TABLE_IDX);  //set目标表(pop掉了复制的key和value)

        lua_pop(L, 1);                  //pop掉value,留着key继续next
    }

    lua_remove(L, SRC_TABLE_IDX);   //移除src table

    return 1;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//自己写的解析lua_table的打包字符串

class CLuaTableStringDecoder
{
    public:
        CLuaTableStringDecoder(lua_State* L, const char* s, size_t n);
        ~CLuaTableStringDecoder();

    public:
        bool Decode(string& err);

    private:
        bool DecodeKey(string& err);
        bool WaitChar(char c, string& err);
        bool DecodeValue(string& err);
        bool DecodeTable(string& err);

    private:
        lua_State* m_L;
        const char* m_s;
        size_t m_slen;
        size_t m_idx;

};

CLuaTableStringDecoder::CLuaTableStringDecoder(lua_State* L, const char* s, size_t n)
    : m_L(L), m_s(s), m_idx(0), m_slen(n)
{
}

CLuaTableStringDecoder::~CLuaTableStringDecoder()
{
}

bool CLuaTableStringDecoder::Decode(string& err)
{
    int n1 = lua_gettop(m_L);   //初始lua栈大小
    bool b = DecodeTable(err);
    if(!b || m_idx!=m_slen)
    {
        //解析失败,丢弃掉中间值
        int n2 = lua_gettop(m_L);
        if(n2 > n1)
        {
            lua_pop(m_L, n2-n1);
        }
    }

    return b;
}

bool CLuaTableStringDecoder::DecodeTable(string& err)
{
    if(m_s[m_idx] != '{')
    {
        return false;
    }

    //特殊处理"{}"
    if(m_s[m_idx+1] == '}')
    {
        lua_newtable(m_L);
        m_idx += 2;
        return true;
    }

    lua_newtable(m_L);

    //解析key
    ++m_idx;
    while(DecodeKey(err) && WaitChar('=', err) && DecodeValue(err) )
    {
        //printf("idx=%d,top1:%d\n", m_idx, lua_gettop(m_L));
        lua_rawset(m_L, -3);
        //printf("idx=%d,top2:%d\n", m_idx, lua_gettop(m_L));

        if(!WaitChar(',', err))
        {
            break;
        }
    }

    return WaitChar('}', err);
}

bool CLuaTableStringDecoder::DecodeKey(string& err)
{
    if(m_s[m_idx] == 's')
    {
        //key is string
        char szLen[4];
        szLen[0] = m_s[m_idx+1];
        szLen[1] = m_s[m_idx+2];
        szLen[2] = m_s[m_idx+3];
        szLen[3] = '\0';

        int nLen = atoi(szLen);
        if(nLen > 0)
        {
            lua_pushlstring(m_L, m_s+m_idx+4, nLen);
            m_idx += 4 + nLen;
            return true;
        }
		else if(nLen == 0)
		{
			lua_pushstring(m_L, "");
			m_idx += 4;
			return true;
		}

        return false;
    }
    else
    {
        //key is number
        size_t i = m_idx;
        while(++m_idx < m_slen)
        {
            if(m_s[m_idx] == '=')
            {
                if(m_idx > i)
                {
                    lua_pushlstring(m_L, m_s+i, m_idx-i);
                    lua_Number n1 = lua_tonumber(m_L, -1);
                    lua_pushnumber(m_L, n1);
                    lua_replace(m_L, -2);
                    return true;
                }
            }
        }

        return false;
    }

    return false;
}

bool CLuaTableStringDecoder::WaitChar(char c, string& err)
{
    if(m_s[m_idx] == c)
    {
        ++m_idx;
        return true;
    }

    return false;
}

bool CLuaTableStringDecoder::DecodeValue(string& err)
{
    char c = m_s[m_idx];
    if(c == 's')
    {
        //key is string
        char szLen[4];
        szLen[0] = m_s[m_idx+1];
        szLen[1] = m_s[m_idx+2];
        szLen[2] = m_s[m_idx+3];
        szLen[3] = '\0';

        int nLen = atoi(szLen);
        if(nLen > 0)
        {
            lua_pushlstring(m_L, m_s+m_idx+4, nLen);
            m_idx += 4 + nLen;
            return true;
        }
        else if (nLen == 0)
        {
            lua_pushstring(m_L, "");
            m_idx += 4 + nLen;
            return true;
        }     

        return false;
    }
    else if(c == '{')
    {
        return DecodeTable(err);
    }
    else
    {
        //key is number
        size_t i = m_idx;
        while(++m_idx < m_slen)
        {
            if(m_s[m_idx] == ',' || m_s[m_idx] == '}')
            {
                if(m_idx > i)
                {
                    lua_pushlstring(m_L, m_s+i, m_idx-i);
                    lua_Number n1 = lua_tonumber(m_L, -1);
                    lua_pushnumber(m_L, n1);
                    lua_replace(m_L, -2);
                    return true;
                }
            }
        }

        return false;
    }

    return false;
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////

//将字符串解包为字符串,用于lua中使用
int LuaUnpickle(lua_State* L)
{
    size_t nLen = 0;
    const char* s = luaL_checklstring(L, 1, &nLen);

    CLuaTableStringDecoder dc(L, s, nLen);
    string err;
    if(!dc.Decode(err))
    {
        LogWarning("my_lua_cunpickle_err 1", "%s", s);
        return 0;
    }

    return 1;

}

//老的算法,用dostring会有很多识别错误的问题
//例如:{dfee=12,33123e=9,xiaodi=3}, 含中文, 含换行符
int __LuaUnpickle(lua_State* L)
{
    const char* s = luaL_checkstring(L, 1);
    ostringstream oss;
    oss << "do local ret =" << s << " return ret end";
    int n1 = luaL_dostring(L, oss.str().c_str());

    if (n1 != 0)
    {
        //if (n1 == LUA_ERRRUN)
        //{
        LogWarning("my_lua_cunpickle_err 2", "%s", lua_tostring(L, -1));
        //cout << "lua_pcall error:" << lua_tostring(L, -1) << endl;
        //}

        return 0;
    }

    return 1;

}

//根据def中配置的缺省值生成table,如果返回true,则table在栈顶
bool LuaUnpickleFromString(lua_State*L, const string& s)
{
    CLuaTableStringDecoder dc(L, s.c_str(), s.size());
    string err;
    if(!dc.Decode(err))
    {
        LogWarning("my_lua_cunpickle_err 3", "%s", s.c_str());
        return false;
    }
    return true;
}

int LuaLogScript(const char* level, lua_State* L)
{
    const char* head = luaL_checkstring(L, 1);
    const char* msg = luaL_checkstring(L, 2);
    LogScript(level, "[%s]%s", head, msg);

    return 0;
}

int LuaLogDebug(lua_State* L)
{
    const static char level[] = "DEBUG";
    return LuaLogScript(level, L);
}

int LuaLogInfo(lua_State* L)
{
    const static char level[] = "INFO";
    return LuaLogScript(level, L);
}

int LuaLogWarning(lua_State* L)
{
    const static char level[] = "WARNING";
    return LuaLogScript(level, L);
}

int LuaLogError(lua_State* L)
{
    const static char level[] = "ERROR";
    return LuaLogScript(level, L);
}

//lua脚本中根据eid获取entity对象
int GetEntity(lua_State* L)
{
    TENTITYID eid = (TENTITYID)luaL_checkint(L, 1);
    CEntityParent* p = GetWorld()->GetEntity(eid);
    if(p)
    {
        luaL_getmetatable(L, g_szUserDataEntity);
        lua_pushlightuserdata(L, p);
        lua_rawget(L, -2);
        lua_remove(L, -2);

        return 1;
    }
    return 0;
}

////////////////////////////////////////////////////////////////////////////////////

//用来保存可回调的callable object
CLuaCallback::CLuaCallback(const char* pszRefTable)
#ifdef _MYLUAREF
    : m_ref(0)
#endif
{
    m_pszRefTable = new char[strlen(pszRefTable)+1];
    strcpy(m_pszRefTable, pszRefTable);
}

CLuaCallback::~CLuaCallback()
{
    delete[] m_pszRefTable;
}

int CLuaCallback::Ref(lua_State* L)
{
#ifdef _MYLUAREF
    luaL_getmetatable(L, m_pszRefTable);    
    lua_pushvalue(L, -2);
    ++m_ref;
    lua_rawseti(L, -2, m_ref);
    lua_pop(L, 2);

    //printf("CLuaCallback::Ref=%d\n", m_ref);
    return m_ref;
#else
    luaL_getmetatable(L, m_pszRefTable);
    lua_pushvalue(L, -2);
    int nRef = luaL_ref(L, -2);
    lua_pop(L, 2);   //将需要ref的object一起pop掉

    return nRef;
#endif
}

void CLuaCallback::Unref(lua_State* L, int ref)
{
#ifdef _MYLUAREF
    luaL_getmetatable(L, m_pszRefTable);
    lua_pushnil(L);
    lua_rawseti(L, -2, ref);
    lua_pop(L, 1);

    //printf("CLuaCallback::Unref=%d\n", ref);
#else
    luaL_getmetatable(L, m_pszRefTable);
    luaL_unref(L, -1, ref);
    lua_pop(L, 1);
#endif
}

int CLuaCallback::GetObj(lua_State* L, int ref)
{
#ifdef _MYLUAREF
    luaL_getmetatable(L, m_pszRefTable);    
    lua_rawgeti(L, -1, ref);

    //printf("CLuaCallback::GetObj=%d\n", m_ref);
    return 2;
#else
    luaL_getmetatable(L, m_pszRefTable);
    //printf("GetObj, lua_isnil:%d\n", lua_istable(L, -1));
    lua_rawgeti(L, -1, ref);
    //printf("GetObj, lua_isnil:%d\n", lua_isnil(L, -1));

    return 2;
#endif
}

////////////////////////////////////////////////////////////////////////////////////

void ParseNode(lua_State* L, TiXmlNode* p)
{
     if(p->Type() == TiXmlNode::TINYXML_ELEMENT)
     {
         //cout << p->Value() << "-----" << endl;

         TiXmlNode* p2 = p->FirstChild();
         if(p2 && p2->Type() == TiXmlNode::TINYXML_TEXT )
         {
             //cout << p2->Value() << endl;
             //key : value
             lua_pushstring(L, p->Value());
             lua_pushstring(L, p2->Value());
             lua_rawset(L, -3);
             return;
         }

         //value还有嵌套结构,生成子table
         lua_newtable(L);
         lua_pushstring(L, p->Value());
         lua_pushvalue(L, -2);
         lua_rawset(L, -4);

         for(; p2 != NULL; p2 = p2->NextSibling())
         {
             ParseNode(L, p2);
         }

         //pop掉子table
         lua_pop(L, 1);
     }
}

void ParseNodeByKey(lua_State* L, TiXmlNode* p, const char* pszKey)
{
    if(p->Type() == TiXmlNode::TINYXML_ELEMENT)
    {
        //cout << p->Value() << "-----" << endl;

        TiXmlNode* p2 = p->FirstChild();
        if(p2 == NULL)
        {
            return;
        }

        if(p2->Type() == TiXmlNode::TINYXML_TEXT )
        {
            //cout << p2->Value() << endl;
            //key : value
            lua_pushstring(L, p->Value());
            lua_pushstring(L, p2->Value());
            lua_rawset(L, -3);
            return;
        }

        TiXmlNode* pKeyNode = p->FirstChild(pszKey);
        if(pKeyNode && pKeyNode->Type() == TiXmlNode::TINYXML_ELEMENT)
        {
            TiXmlNode* pKeyValueNode = pKeyNode->FirstChild();
            if(pKeyValueNode && pKeyValueNode->Type() == TiXmlNode::TINYXML_TEXT )
            {
                //value还有嵌套结构,生成子table
                lua_newtable(L);
                lua_pushstring(L, pKeyValueNode->Value());
                lua_pushvalue(L, -2);
                lua_rawset(L, -4);

                //LogDebug("ParseNodeByKey", "pszKey=%s;key=%s", pszKey, pKeyValueNode->Value());

                for(; p2 != NULL; p2 = p2->NextSibling())
                {
                    ParseNode(L, p2);
                }

                //pop掉子table
                lua_pop(L, 1);
            }
        }
    }
}

enum ENUM_XML_READ_DS
{
    XML_RESULT_DS_LIST = 0,
    XML_RESULT_DS_MAP = 1,
    XML_RESULT_DS_MAP_BY_KEY = 2,
};

//将一个xml的数据全部读到一个数据结构
int XmlReadToDs(lua_State* L, ENUM_XML_READ_DS ds_type)
{
    const char* pszFile = luaL_checkstring(L, 1);
    const char* pszKey = NULL;
    if(ds_type == XML_RESULT_DS_MAP_BY_KEY)
    {
        pszKey = luaL_checkstring(L, 2);
    }

    TiXmlDocument doc;
    if(doc.LoadFile(pszFile))
    {
        TiXmlElement* root = doc.RootElement();
        if(root)
        {
            lua_newtable(L);
            int i = 0;
            TiXmlNode* node = root->FirstChild();
            for(; node != NULL; node = node->NextSibling())
            {
                if(ds_type == XML_RESULT_DS_MAP_BY_KEY)
                {
                    //LogDebug("XmlReadToDs", "%s", pszKey);
                    ParseNodeByKey(L, node, pszKey);
                }
                else if(ds_type == XML_RESULT_DS_LIST)
                {
                    //生成一个序号和子table的对应结构
                    lua_newtable(L);
                    lua_pushvalue(L, -1);
                    lua_rawseti(L, -3, ++i);

                    ParseNode(L, node);

                    //pop掉这个子table
                    lua_pop(L, 1);
                }
                else if(ds_type == XML_RESULT_DS_MAP)
                {
                    ParseNode(L, node);
                }
            }
            return 1;
        }
    }

    return 0;
}

int XmlReadToList(lua_State* L)
{
    return XmlReadToDs(L, XML_RESULT_DS_LIST);
}

int XmlReadToMap(lua_State* L)
{
    return XmlReadToDs(L, XML_RESULT_DS_MAP);
}

int XmlReadToMapByKey(lua_State* L)
{
    return XmlReadToDs(L, XML_RESULT_DS_MAP_BY_KEY);
}

//读取xml中的<key> value </key>到lua table
bool ReadXmlKeyValue(TiXmlNode* p, lua_State* L, bool bAtoi)
{
    if(p != NULL && p->Type() == TiXmlNode::TINYXML_ELEMENT)
    {
        TiXmlNode* p2 = p->FirstChild();
        //LogDebug("ReadXmlKeyValue", "key=%s;value=%d", p->Value(), atoi(p2->Value()));
        if(p2 != NULL && p2->Type() == TiXmlNode::TINYXML_TEXT)
        {
            lua_pushstring(L, p->Value());

            if(bAtoi)
            {
                lua_pushinteger(L, atoi(p2->Value()));

                //LogDebug("ReadXmlKeyValue", "key=%s;value=%d", p->Value(), atoi(p2->Value()));
            }
            else
            {
                lua_pushstring(L, p2->Value());

                //LogDebug("ReadXmlKeyValue", "key=%s;value=%s", p->Value(), p2->Value());
            }

            lua_rawset(L, -3);

            return true;
        }
    }

    return false;
}

//读取xml中的<key> value </key>的value
const char* _ReadXmlValue(TiXmlNode* p)
{
    if(p != NULL && p->Type() == TiXmlNode::TINYXML_ELEMENT)
    {
        TiXmlNode* p2 = p->FirstChild();
        if(p2 && p2->Type() == TiXmlNode::TINYXML_TEXT)
        {
            return p2->Value();
        }
    }

    return NULL;
}

//专门写的读取场景配置表
int XmlReadSpace(lua_State* L)
{
    const char* pszFile = luaL_checkstring(L, 1);

    TiXmlDocument doc;
    if(doc.LoadFile(pszFile))
    {
        TiXmlElement* root = doc.RootElement();
        if(root)
        {
            lua_newtable(L);
            int i = 0;
            TiXmlNode* node = root->FirstChild();
            for(; node != NULL; node = node->NextSibling())
            {
                const char* pszNodeName = node->Value();
                if( strcmp(pszNodeName, "entities") == 0)
                {
                    lua_newtable(L);
                    lua_pushstring(L, "entities");
                    lua_pushvalue(L, -2);
                    lua_rawset(L, -4);

                    TiXmlNode* p2 = node->FirstChild();
                    for(; p2 != NULL; p2 = p2->NextSibling())
                    {
                        TiXmlNode* p3 = p2->FirstChild("id");
                        if(p3)
                        {
                            lua_newtable(L);
                            lua_pushinteger(L, atoi(_ReadXmlValue(p3)));
                            lua_pushvalue(L, -2);
                            lua_rawset(L, -4);

                            //LogDebug("XmlReadSpace", "%s", p3->FirstChild()->Value());

                            //LogDebug("XmlReadSpace", "%s", p2->FirstChild("posx")->FirstChild()->Value());
                            //LogDebug("XmlReadSpace", "%s", p2->FirstChild("posy")->FirstChild()->Value());
                            //LogDebug("XmlReadSpace", "%s", p2->FirstChild("type")->FirstChild()->Value());

                            //ReadXmlKeyValue(p2->FirstChild("posx"), L, true);
                            //ReadXmlKeyValue(p2->FirstChild("posy"), L, true);
                            ////ReadXmlKeyValue(p2->FirstChild("classid"), L, true);
                            //ReadXmlKeyValue(p2->FirstChild("type"), L, false);

                            TiXmlNode* p4 = p2->FirstChild();
                            for(; p4 != NULL; p4 = p4->NextSibling())
                            {
                                if (p3 == p4)
                                {
                                    continue;
                                }

                                //LogDebug("XmlReadSpace 1", "key=%s", p4->Value());
                                //只有“posx”和“posy”两个属性是以整形读取，其余的都以字符串读取
                                if (strcasecmp(p4->Value(), "posx") == 0 || strcasecmp(p4->Value(), "posy") == 0)
                                {
                                    //LogDebug("XmlReadSpace 2", "key=%s", p4->Value());
                                    ReadXmlKeyValue(p4, L, true);
                                }
                                else
                                {
                                    //LogDebug("XmlReadSpace 3", "key=%s", p4->Value());
                                    ReadXmlKeyValue(p4, L, false);
                                }
                            }

                            lua_pop(L, 1);
                        }
                    }

                    lua_pop(L, 1);
                }
                else
                {
                    TiXmlNode* p2 = node->FirstChild();
                    if(p2 != NULL && p2->Type() == TiXmlNode::TINYXML_TEXT)
                    {
                        lua_pushstring(L, pszNodeName);
                        if(strcmp(pszNodeName, "width") == 0 || strcmp(pszNodeName, "height")==0)
                        {
                            lua_pushinteger(L, atoi(p2->Value()));
                        }
                        else
                        {
                            lua_pushstring(L, p2->Value());
                        }

                        lua_rawset(L, -3);
                    }
                }
            }
            return 1;
        }
    }
    return 0;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

int bit_stest(lua_State* L)
{
    int n = 0;
    const char* s = luaL_checklstring(L, 1, (size_t*)&n);
    //printf("bit_stest  :");print_hex(s, n);

    int nIdx = luaL_checkint(L, 2);
    if(nIdx < 0)
    {
        lua_pushinteger(L, 0);
        return 1;
    }

    enum { LSHIFT_SIZE = 3, CHAR_MASK = 0x7, };
    int nCharIdx = nIdx >> LSHIFT_SIZE;
    if(nCharIdx > n)
    {
        lua_pushinteger(L, 0);
        return 1;
    }

    unsigned char c = (unsigned char)s[nCharIdx];
    unsigned int nRet = c & (1 << (nIdx & CHAR_MASK ) );
    lua_pushinteger(L, nRet);

    return 1;
}

int bit_sset(lua_State* L)
{
    int n = 0;
    const char* s = luaL_checklstring(L, 1, (size_t*)&n);

    int nIdx = luaL_checkint(L, 2);
    if(nIdx < 0)
    {
        lua_pushfstring(L, "mogo.sset,nIdx", nIdx);
        lua_error(L);
        return 0;
    }

    enum { LSHIFT_SIZE = 3, CHAR_MASK = 0x7, MAX_BUFF_SIZE = 1024, MAX_IDX_VALUE = (MAX_BUFF_SIZE << 3) - 1,};

    if(nIdx > MAX_IDX_VALUE)
    {
        lua_pushfstring(L, "mogo.sset,input_value(%d)>max_value(%d)", nIdx, MAX_IDX_VALUE);
        lua_error(L);
        return 0;
    }

    int nCharIdx = nIdx >> LSHIFT_SIZE;

    unsigned char szTmp[1024];  //最大值1024<<3
    memset(szTmp, 0, sizeof(szTmp));

    if(n > 0)
    {
        memcpy(szTmp, s, n);
    }

    unsigned char c = (unsigned char)szTmp[nCharIdx];
    unsigned char c2 = c | (1 << (nIdx & CHAR_MASK) ) ;
    szTmp[nCharIdx] = c2;
    //printf("c=%d;c2=%d", c, c2);

    int nRealLen = (nCharIdx+1) > n ? (nCharIdx+1) : n;
    lua_pushlstring(L, (char*)szTmp, nRealLen);

    //LogDebug("bit_sset", "nRealLen=%d;nIdx=%d;n=%d", nRealLen, nIdx, n);
    //PrintHex((char*)szTmp, nRealLen);

    return 1;
}

int bit_sunset(lua_State* L)
{
    int n = 0;
    char* s0 = (char*)luaL_checklstring(L, 1, (size_t*)&n);
    //printf("bit_sunset1:");print_hex(s, n);

    char* s = new char[n+1];
    memset(s, 0, n+1);
    if(n > 0)
    {
        memcpy(s, s0, n);
    }

    int nIdx = luaL_checkint(L, 2);
    if(nIdx >= 0)
    {
        enum { LSHIFT_SIZE = 3, CHAR_MASK = 0x7,};
        int nCharIdx = nIdx >> LSHIFT_SIZE;
        if(nCharIdx <= n)
        {
            unsigned char c = (unsigned char)s[nCharIdx];
            s[nCharIdx] = c &~ (1 << (nIdx & CHAR_MASK) );
        }
    }
    //printf("bit_sunset2:");print_hex(s, n);

    lua_pushlstring(L, s, n);
    delete[] s;
    return 1;
}

int bit_wtest(lua_State* L)
{
    int n = 0;
    const char* s = luaL_checklstring(L, 1, (size_t*)&n);
    //printf("bit_stest  :");print_hex(s, n);

    int nIdx = luaL_checkint(L, 2);
    if(nIdx < 0)
    {
        lua_pushinteger(L, 0);
        return 1;
    }

    enum { LSHIFT_SIZE = 2, CHAR_MASK = 0x3, };
    int nCharIdx = nIdx >> LSHIFT_SIZE;
    if(nCharIdx > n)
    {
        lua_pushinteger(L, 0);
        return 1;
    }

    unsigned char c = (unsigned char)s[nCharIdx];
    //unsigned int nRet = (c & (CHAR_MASK << ( (nIdx & CHAR_MASK) << 1))) >> ( (nIdx & CHAR_MASK) << 1);
    unsigned int nRet2 = (c >> ( (nIdx & CHAR_MASK) << 1)) & CHAR_MASK;
    //unsigned int nRet3 = (c >> ( (nIdx & CHAR_MASK) << 1));
    //printf("1=%d;2=%d;3=%d\n", nRet, nRet2,nRet3);
    lua_pushinteger(L, nRet2);

    return 1;
}

int bit_wset(lua_State* L)
{
    enum { MAX_VALUE_VALUE = (1 << 2) - 1 };

    int n = 0;
    const char* s = luaL_checklstring(L, 1, (size_t*)&n);

    int nIdx = luaL_checkint(L, 2);
    if(nIdx < 0)
    {
        return 0;
    }

    int nValue = luaL_checkint(L, 3);
    if(nValue < 0 || nValue > MAX_VALUE_VALUE)
    {
        return 0;
    }

    enum { LSHIFT_SIZE = 2,};
    int nCharIdx = nIdx >> LSHIFT_SIZE;

    unsigned char szTmp[1024];  //最大值1024<<2
    memset(szTmp, 0, sizeof(szTmp));

    if(n > 0)
    {
        memcpy(szTmp, s, n);
    }

    unsigned char c = (unsigned char)szTmp[nCharIdx];
    unsigned char c2 = (c &~ (MAX_VALUE_VALUE << ( (nIdx & MAX_VALUE_VALUE) << 1)) ) | (nValue << ( (nIdx & MAX_VALUE_VALUE) << 1)) ;
    szTmp[nCharIdx] = c2;
    //printf("idx=%d;value=%d;ncharid=%d;c=%d;c2=%d\n", nIdx, nValue, nCharIdx, c, c2);

    int nRealLen = (nCharIdx+1) > n ? (nCharIdx+1) : n;
    lua_pushlstring(L, (char*)szTmp, nRealLen);

    printf("bit_sset   :");PrintHex((char*)szTmp, nRealLen);

    return 1;
}


//根据entity和属性名获取该属性的编号
int GetEntityPropId(lua_State* L)
{
    const static char szDefaultEntity[] = "Avatar"; //缺省查询的entity
    const char* pszEntity = NULL;
    const char* pszProp = NULL;
    int nArgCount = lua_gettop(L);
    if(nArgCount > 1)
    {
        pszEntity = luaL_checkstring(L, 1);
        pszProp = luaL_checkstring(L, 2);
    }
    else
    {
        pszEntity = szDefaultEntity;
        pszProp = luaL_checkstring(L, 1);
    }

    CDefParser& defparser = GetWorld()->GetDefParser();
    const SEntityDef* pDef = defparser.GetEntityDefByName(pszEntity);
    if(pDef)
    {
        int n = pDef->m_propertiesMap.GetIntByStr(pszProp);
        if(n > 0)
        {
            lua_pushinteger(L, n);
            return 1;
        }
    }

    return 0;
}

//计算点与点的距离
float Point2PointDistance(int x1, int y1, int x2, int y2)
{
    int dx = x1 - x2;
    int dy = y1 - y2;
    return sqrt((float)(dx*dx+dy*dy));
}

int LuaPoint2PointDistance(lua_State* L)
{
    int x1 = luaL_checkint(L, 1);
    int y1 = luaL_checkint(L, 2);
    int x2 = luaL_checkint(L, 3);
    int y2 = luaL_checkint(L, 4);

    int d = (int)Point2PointDistance(x1, y1, x2, y2);
    lua_pushinteger(L, d);
    return 1;
}

//初略的处理一下0值
inline float _CheckZero(float f)
{
    if(f > -0.0001 && f < 0.0001)
    {
        return (float)0.1;
    }

    return f;
}

//计算点与直线间的距离
float Point2lineDistance(int x, int y, int x1, int y1, int x2, int y2)
{
    float a = _CheckZero(Point2PointDistance(x, y, x1, y1));
    float b = _CheckZero(Point2PointDistance(x, y, x2, y2));
    float c = _CheckZero(Point2PointDistance(x1, y1, x2, y2));
    float hl = (a+b+c)/2;       //半周长
    float s = sqrt(hl*(hl-a)*(hl-b)*(hl-c));    //面积
    float h = 2*s/c;
    return h;
}

int LuaPoint2LineDistance(lua_State* L)
{
    int x1 = luaL_checkint(L, 1);
    int y1 = luaL_checkint(L, 2);
    int x2 = luaL_checkint(L, 3);
    int y2 = luaL_checkint(L, 4);
    int x3 = luaL_checkint(L, 5);
    int y3 = luaL_checkint(L, 6);

    int d = (int)Point2lineDistance(x1, y1, x2, y2, x3, y3);
    lua_pushinteger(L, d);
    return 1;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//读取障碍信息
int LoadBlockMap(lua_State* L)
{
#ifndef _WIN32
    uint16_t unMapId = (uint16_t)luaL_checkint(L, 1);
    const char* pszFn = luaL_checkstring(L, 2);

    CBlockMapMgr& bmm = GetWorld()->GetBlockMapMgr();
    bmm.ReadBlockMap(unMapId, pszFn);
#endif
    return 0;
}

//简单寻路
int MoveSimple(lua_State* L)
{
#ifdef _WIN32
	return 0;
#else
    int x1 = luaL_checkint(L, 1);
    int y1 = luaL_checkint(L, 2);
    int x2 = luaL_checkint(L, 3);
    int y2 = luaL_checkint(L, 4);
    int speed = luaL_checkint(L, 5);
    int map_id = luaL_checkint(L, 6);
    //printf("lmove,%d,%d,%d,%d\n",x1,y1,x2,y2);

    int x3=0,y3=0;
    if(CSimplePathFounder::FindWay(x1, y1, x2, y2, speed, GetWorld()->GetBlockMapMgr(), map_id, x3, y3))
    {
        lua_pushinteger(L, x3);
        lua_pushinteger(L, y3);

        return 2;
    }
    else
    {
        return 0;
    }
#endif
}

int LuaGetTickCount(lua_State* L)
{
    lua_pushnumber(L, _GetTickCount64());
    return 1;
}

int LuaConfirm(lua_State* L)
{
#ifndef _WIN32
    if (lua_type(L, 1) == LUA_TBOOLEAN)
    {
        MG_CONFIRM(lua_toboolean(L, 1) != 0, "Lua Assert Error!");
    }
    else
    {
        MG_CONFIRM(luaL_checkinteger(L, 1) != 0, "Lua Assert Error!");
    }
#endif
    return 0;
}

//lua_pcall的错误处理方法
int pcall_handler(lua_State* L)
{
    lua_getglobal(L, "debug");
    if (!lua_istable(L, -1)) {
        lua_pop(L, 1);
        return 1;
    }
    lua_getfield(L, -1, "traceback");
    if (!lua_isfunction(L, -1)) {
        lua_pop(L, 2);
        return 1;
    }
    lua_pushvalue(L, 1);
    lua_pushinteger(L, 2);
    lua_call(L, 2, 1);
    return 1;
}

int AddStopWord(lua_State* L)
{
    //屏蔽字类型
    enum{
        EReserved = 1,      //保留字符集
        EStopWord = 2,      //敏感词汇
        ERegex    = 3,      //正则表达式
    };

    int nWordType = luaL_checkint(L, 1);
    const char* pszWord = luaL_checkstring(L, 2);
    if(nWordType == EStopWord)
    {
        GetWorld()->GetStopWord().AddStopWord(pszWord);
    }
    else if(nWordType == ERegex)
    {
        GetWorld()->GetStopWord().AddReWord(pszWord);
    }
    else
    {
        GetWorld()->GetStopWord().InitReservedWords(pszWord);
    }

    return 0;
}


int IsStopWord(lua_State* L)
{
    const char* pszWord = luaL_checkstring(L, 1);
    if(GetWorld()->GetStopWord().IsStopWord(pszWord))
    {
        lua_pushboolean(L, 1);
    }
    else
    {
        lua_pushboolean(L, 0);
    }

    return 1;
}

//原始服向跨服服务器的globalbase发出的rpc调用
//参数: 发出调用的entity,跨服服务名称,globalbase_name,rpc_name,rpc参数1,rpc参数2,...,rpc参数n
int CrossServerRpc(lua_State* L)
{
    CMailBox* mb = GetWorld()->GetServerMailbox(SERVER_CROSSCLIENT);
    if(mb == NULL)
    {
        lua_pushstring(L, "mogo.crossServerRpc,crossclient_not_ready");
        lua_error(L);
        return 0;
    }

    CEntityBase* pBase = (CEntityBase*)luaL_checkudata(L, 1, s_szEntityName);
    const char* pszCrossName = luaL_checkstring(L, 2);
    const char* pszGlobalBase = luaL_checkstring(L, 3); //同时也是entity名
    const char* pszRpc = luaL_checkstring(L, 4);

    const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByName(pszGlobalBase);
    if(pDef == NULL)
    {
        lua_pushfstring(L, "mogo.crossServerRpc,error_entity_name,%s", pszGlobalBase);
        lua_error(L);
        return 0;
    }
    map<string, _SEntityDefMethods*>::const_iterator iter1 = pDef->m_baseMethods.find(pszRpc);
    if(iter1 == pDef->m_baseMethods.end())
    {
        lua_pushfstring(L, "mogo.crossServerRpc,error_rpc_name,%s", pszRpc);
        lua_error(L);
        return 0;
    }

    pluto_msgid_t msg_id = MSGID_CROSSCLIENT_SERVER_RPC_PROXY;
    uint16_t nFuncId = (uint16_t)pDef->m_baseMethodsMap.GetIntByStr(pszRpc);

    CPluto* u = new CPluto;
    u->Encode(msg_id) << pszCrossName << pBase->GetMyMailbox() << pszGlobalBase << nFuncId;

    int nTopCount = lua_gettop(L);
    enum { OTHER_PARAM_COUNT = 4 };
    int nParamCount = nTopCount - OTHER_PARAM_COUNT;    //前面已经检查了4个参数了,这里nParamCount必定>=0
    if(nParamCount > 0)
    {        
        const list<VTYPE>& args = iter1->second->m_argsType;
        int idx = OTHER_PARAM_COUNT;
        bool bFirst = true;
        list<VTYPE>::const_iterator iter = args.begin();
        for(; iter != args.end(); ++iter)
        {
            if(bFirst)
            {
                //第一个参数忽略之,应该设为UINT32,对应rpc调用流水号;不用调用者输入,后面会自动补上
                bFirst = false;
            }
            else
            {
                ++idx;
                u->FillPlutoFromLua(*iter, L, idx);
            }

        }        

        if(u->IsEncodeErr())
        {
            //编码过程中出错了
            delete u;
            lua_pushfstring(L, "mogo.crossServerRpc,error_to_rpc_'%s'", pszRpc);
            lua_error(L);
            return 0;
        }
    }

    (*u) << EndPluto;
    mb->PushPluto(u);

    return 0;
}

//跨服服务器向原始服发出的rpc回调
int CrossClientResp(lua_State* L)
{
    CMailBox* mb = GetWorld()->GetServerMailbox(SERVER_CROSSSERVER);
    if(mb == NULL)
    {
        lua_pushstring(L, "mogo.CrossClientRpc,crossserver_not_ready");
        lua_error(L);
        return 0;
    }

    uint32_t nSeq = (uint32_t)luaL_checkint(L, 1);
    const char* pszEntityName = luaL_checkstring(L, 2);    
    const char* pszRpc = luaL_checkstring(L, 3);

    const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByName(pszEntityName);
    if(pDef == NULL)
    {
        lua_pushfstring(L, "mogo.crossClientRpc,error_entity_name,%s", pszEntityName);
        lua_error(L);
        return 0;
    }
    map<string, _SEntityDefMethods*>::const_iterator iter1 = pDef->m_baseMethods.find(pszRpc);
    if(iter1 == pDef->m_baseMethods.end())
    {
        lua_pushfstring(L, "mogo.crossClientRpc,error_rpc_name,%s", pszRpc);
        lua_error(L);
        return 0;
    }

    pluto_msgid_t msg_id = MSGID_CROSSSERVER_CLIENT_RESP_PROXY;
    uint16_t nFuncId = (uint16_t)pDef->m_baseMethodsMap.GetIntByStr(pszRpc);

    CPluto* u = new CPluto;
    u->Encode(msg_id) << nSeq  << nFuncId;

    int nTopCount = lua_gettop(L);
    enum { OTHER_PARAM_COUNT = 3 };
    int nParamCount = nTopCount - OTHER_PARAM_COUNT;    //前面已经检查了4个参数了,这里nParamCount必定>=0
    if(nParamCount > 0)
    {        
        const list<VTYPE>& args = iter1->second->m_argsType;
        int idx = OTHER_PARAM_COUNT;
        list<VTYPE>::const_iterator iter = args.begin();
        for(; iter != args.end(); ++iter)
        {
            ++idx;
            u->FillPlutoFromLua(*iter, L, idx);
        }        

        if(u->IsEncodeErr())
        {
            //编码过程中出错了
            delete u;
            lua_pushfstring(L, "mogo.crossClientRpc,error_to_rpc_'%s'", pszRpc);
            lua_error(L);
            return 0;
        }
    }

    (*u) << EndPluto;
    mb->PushPluto(u);

    return 0;

}

//跨服服务器向原始服发出的广播
int CrossClientBroadcast(lua_State* L)
{
    CMailBox* mb = GetWorld()->GetServerMailbox(SERVER_CROSSSERVER);
    if(mb == NULL)
    {
        lua_pushstring(L, "mogo.CrossClientBroadcast,crossserver_not_ready");
        lua_error(L);
        return 0;
    }

    uint16_t n1 = (uint16_t)luaL_checkint(L, 1);
    const char* s2 = luaL_checkstring(L, 2);

    CPluto* u = new CPluto;
    u->Encode(MSGID_CROSSSERVER_CLIENT_BC_PROXY) << n1 << s2 << EndPluto;
    mb->PushPluto(u);

    return 0;
}

