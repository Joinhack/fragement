#ifndef __LUA_CW_HEAD__
#define __LUA_CW_HEAD__


#include "lua.hpp"
#include "type_mogo.h"
#include "entity.h"
#include "defparser.h"
#include <tinyxml.h>
#include <stdlib.h>
//#include "timer.h"
#ifdef __USE_MSGPACK
#include <msgpack.hpp>
#endif

extern "C" {
#include "lua.h"     
#include "lauxlib.h"     
#include "lualib.h"     
};  


extern const char* s_szMogoLibName;
extern const char* s_szEntityName;
extern const char* s_szListObject;
extern const char* g_szlistMap;
extern const char* s_szSpaceName;
extern const char* s_szCallback;         //所有回调object的集合
extern const char* g_szMailboxMt;
extern const char* g_szBaseClientMailboxMt;
extern const char* g_szClientMailboxMt;
extern const char* g_szCellMailboxMt;
extern const char* g_szGlobalBases;
extern const char* g_szUserDataEntity;
extern const char* g_szXmlUtil;
extern const char* g_szLUATABLES;

enum
{
    g_nMailBoxServerIdKey = 1,
    g_nMailBoxClassTypeKey = 2,
    g_nMailBoxEntityIdKey = 3,
};

using namespace mogo;

//extern int luaopen_cwlib (lua_State *L);
//extern T_LIST_OBJECT* create_list(lua_State*);

//清除lua栈
void ClearLuaStack(lua_State* L);

template<typename T>
T* CreateTObject(lua_State* L, const char* pszObjectName, const char* pszMapName)
{
    void* ppl = lua_newuserdata(L, sizeof(T));
    T* pl = new(ppl) T;

    //setmetatable
    luaL_newmetatable(L, pszObjectName);
    lua_setmetatable(L, -2);

    //keep pointer userdata map
    luaL_getmetatable(L, pszMapName);
    lua_pushlightuserdata(L, pl);
    lua_pushvalue(L, -3);
    lua_rawset(L, -3);
    lua_pop(L, 2);

    return pl;
}

//根据指针获取lua中对应的userdata
template<typename T>
void GetTObject(lua_State* L, const T* p, const char* pszMapName)
{
    //根据指针获得lua userdata
    luaL_getmetatable(L, pszMapName);
    lua_pushlightuserdata(L, (void*)p);
    lua_rawget(L, -2);      //userdata
    lua_remove(L, -2);      //metatable
}

//using mogo::T_LIST_OBJECT;
//
//inline T_LIST_OBJECT* create_list(lua_State* L)
//{
//    return create_T_object<T_LIST_OBJECT>(L, s_szListObject, g_szlistMap);
//}

//自定义一个redis hash对应的类
namespace mogo
{

    enum
    {
        ENUM_REDIS_HASH_FIELD_INIT    = 0,
        ENUM_REDIS_HASH_FIELD_LOADING = 1,
        ENUM_REDIS_HASH_FIELD_LOADED  = 2,
    };

    class CRedisHash
    {
        public:
            CRedisHash();
            ~CRedisHash();

        public:
            void Load(lua_State* L);
            void OnLoaded(const string& strValue);
            void Set(lua_State* L, uint32_t nSeq, const char* pszValue);
            void Del(lua_State* L, uint32_t nSeq);

        public:
            inline void SetEntity(const CEntityParent* p, const string& strAttri)
            {
                m_pEntity = p;
                m_strAttri.assign(strAttri);
            }

            inline bool IsLoaded() const
            {
                return m_nLoadFlag == ENUM_REDIS_HASH_FIELD_LOADED;
            }

        private:
            void MakeKey();

        private:
            uint8_t m_nLoadFlag;
            string m_strKey;
            const CEntityParent* m_pEntity;
            string m_strAttri;

    };

};

using mogo::CRedisHash;

inline CRedisHash* CreateRedisHash(lua_State* L)
{
    return CreateTObject<CRedisHash>(L, s_szListObject, g_szlistMap);
}

inline void GetRedisHash(lua_State* L, CRedisHash* p)
{
    return GetTObject(L, p, g_szlistMap);
}

template<typename T>
T* _CreateEntity(lua_State* L);

template<typename T>
int CreateEntity(lua_State* L);

template<typename T>
int EntityGetId(lua_State* L)
{
    //cout << "entity_getId" << endl;
    T* pf = (T*)luaL_checkudata(L, 1, s_szEntityName);
    TENTITYID nId = pf->GetId();
    lua_pushinteger(L, nId);

    return 1;
}


template<typename T>
int EntityFunCall(lua_State* L);

template<typename T>
int EntityIndex(lua_State* L);

template<typename T>
int EntityNewIndex(lua_State* L);


template<typename T>
int EntityGC(lua_State* L)
{
    T* pf = (T*)luaL_checkudata(L, 1, s_szEntityName);
    pf->~T();       //只调析构函数不delete

    return 0;
}

extern int ListIndex(lua_State* L);
extern int ListNewIndex(lua_State* L);
extern int ListGC(lua_State* L);

extern int MailboxMtRpc(lua_State* L);
extern int MailboxMtIndex(lua_State* L);
extern int MailboxMtNewIndex(lua_State* L);

extern int BaseClientMailboxMtRpc(lua_State* L);
extern int BaseClientMailboxMtIndex(lua_State* L);

extern int CellMailboxMtRpc(lua_State* L);
extern int CellMailboxMtIndex(lua_State* L);
extern int CellMailboxMtNewIndex(lua_State* L);

extern int ClientMailboxMtRpc(lua_State* L);
extern int ClientMailboxMtIndex(lua_State* L);
extern int ClientMailboxMtNewIndex(lua_State* L);

//mogo.EntityAllclientsRpc(a, 'rpc', ...)
extern int EntityAllclientsRpc(lua_State* L);
//mogo.EntityOwnclientRpc(a, 'rpc', ...)
extern int EntityOwnclientRpc(lua_State* L);

//将entity的mailbox打包为一个字符串
extern int PickleMailbox(lua_State* L);
extern int UnpickleBaseMailbox(lua_State* L);
extern int UnpickleCellMailbox(lua_State* L);

//根据字符串生成base mailbox
extern int MakeBaseMailbox(lua_State* L);
//根据字符串生成cell mailbox
extern int MakeCellMailbox(lua_State* L);

extern int XmlReadToList(lua_State* L);
extern int XmlReadToMap(lua_State* L);
extern int XmlReadToMapByKey(lua_State* L);
//专门写的读取场景配置表
extern int XmlReadSpace(lua_State* L);

extern int bit_stest(lua_State* L);
extern int bit_sset(lua_State* L);
extern int bit_sunset(lua_State* L);

extern int bit_wtest(lua_State* L);
extern int bit_wset(lua_State* L);
//extern int bit_wunset(lua_State* L);

//读取障碍信息
extern int LoadBlockMap(lua_State* L);
//简单寻路
extern int MoveSimple(lua_State* L);

extern int GetEntityPropId(lua_State* L);

extern int GetEntity(lua_State* L);
extern int LuaLogDebug(lua_State* L);
extern int LuaLogInfo(lua_State* L);
extern int LuaLogWarning(lua_State* L);
extern int LuaLogError(lua_State* L);
extern int LuaLogScript(lua_State* L);
extern int LuaGetTickCount(lua_State* L);
extern int LuaConfirm(lua_State* L);

extern int NewBaseMailbox(lua_State* L, uint16_t nServerId, TENTITYTYPE etype, TENTITYID eid);
extern int NewCellMailbox(lua_State* L, uint16_t nServerId, TENTITYTYPE etype, TENTITYID eid);
extern int NewClientMailbox(lua_State* L, int32_t nServerId, TENTITYTYPE etype, TENTITYID eid);

extern int AddStopWord(lua_State* L);
extern int IsStopWord(lua_State* L);

template<typename T>
int LuaOpenEntityLib (lua_State *L)
{
    luaL_newmetatable(L, g_szlistMap);

    luaL_newmetatable(L, s_szListObject);
    lua_pushstring(L, "__index");
    lua_pushcfunction(L, ListIndex);
    lua_rawset(L, -3);
    lua_pushstring(L, "__newindex");
    lua_pushcfunction(L, ListNewIndex);
    lua_rawset(L, -3);
    lua_pushstring(L, "__gc");
    lua_pushcfunction(L, ListGC);
    lua_rawset(L, -3);

    luaL_newmetatable(L, s_szEntityName);

    lua_pushstring(L, "__index");
    lua_pushcfunction(L, EntityIndex<T>);
    lua_rawset(L, -3);

    lua_pushstring(L, "__newindex");
    lua_pushcfunction(L, EntityNewIndex<T>);
    lua_rawset(L, -3);

    //{
    //    static const luaL_Reg libin[] =
    //    {
    //        {"getId", entity_getId<T>},
    //        {NULL, NULL}
    //    };
    //    luaL_register(L, s_szEntityName, libin);
    //}

    lua_pushstring(L, "__gc");
    lua_pushcfunction(L, EntityGC<T>);
    lua_rawset(L, -3);

    luaL_newmetatable(L, g_szUserDataEntity);
    lua_setglobal(L, g_szUserDataEntity);

    luaL_newmetatable(L, s_szCallback);
    lua_setglobal(L, s_szCallback);

    luaL_newmetatable(L, g_szLUATABLES);
    lua_setglobal(L, g_szLUATABLES);

    //lua中mailbox的metatable
    luaL_newmetatable(L, g_szMailboxMt);
    lua_pushstring(L, "__index");
    lua_pushcfunction(L, MailboxMtIndex);
    lua_rawset(L, -3);
    lua_pushstring(L, "__newindex");
    lua_pushcfunction(L, MailboxMtNewIndex);
    lua_rawset(L, -3);

    //base.client
    luaL_newmetatable(L, g_szBaseClientMailboxMt);
    lua_pushstring(L, "__index");
    lua_pushcfunction(L, BaseClientMailboxMtIndex);
    lua_rawset(L, -3);

    //cell mailbox
    luaL_newmetatable(L, g_szCellMailboxMt);
    lua_pushstring(L, "__index");
    lua_pushcfunction(L, CellMailboxMtIndex);
    lua_rawset(L, -3);
    lua_pushstring(L, "__newindex");
    lua_pushcfunction(L, CellMailboxMtNewIndex);
    lua_rawset(L, -3);

    //lua中client mailbox的metatable
    luaL_newmetatable(L, g_szClientMailboxMt);
    lua_pushstring(L, "__index");
    lua_pushcfunction(L, ClientMailboxMtIndex);
    lua_rawset(L, -3);
    lua_pushstring(L, "__newindex");
    lua_pushcfunction(L, ClientMailboxMtNewIndex);
    lua_rawset(L, -3);

    //globalBases
    lua_newtable(L);
    lua_setglobal(L, g_szGlobalBases);

    return 0;
}

//调用一个entity的脚本方法
extern int EntityMethodCall(lua_State*L, CEntityParent* e, const char* szFunc,
                            uint8_t nInput, uint8_t nOutput);
//不需要entity调用一个脚本的方法
extern void ScriptMethodCall(lua_State* L, const char* szEntityType, const char* szFunc, uint8_t nInput, uint8_t nOutput);

//将lua中的table打包为字符串,用于lua中使用
extern int LuaPickle(lua_State* L);

//将字符串解包为字符串,用于lua中使用
extern int LuaUnpickle(lua_State* L);

#ifdef __USE_MSGPACK
extern bool LuaPickleToBlob(lua_State* L, msgpack::packer<msgpack::sbuffer>& pker);
extern bool LuaPickleToBlob(lua_State* L, int nLuaStackPos, msgpack::packer<msgpack::sbuffer>& pker);
extern bool LuaUnpickleFromBlob(lua_State* L, char*s, uint16_t len);
#endif

//将lua中的table打包为字符串,用于网路传送
extern bool LuaPickleToString(lua_State* L, string& str);

//将lua中指定栈位置的table打包为字符串
extern bool LuaPickleToString(lua_State* L, int nLuaStackPos, string& str);

//根据def中配置的缺省值生成table,如果返回true,则table在栈顶
extern bool LuaUnpickleFromString(lua_State*L, const string& s);

//deepcopy table的第一层
extern int DeepCopyTable1(lua_State* L);

//计算点与点的距离
extern float Point2PointDistance(int x1, int y1, int x2, int y2);
extern int LuaPoint2PointDistance(lua_State* L);

//计算点与直线间的距离
extern float Point2LineDistance(int x, int y, int x1, int y1, int x2, int y2);
extern int LuaPoint2LineDistance(lua_State* L);


//用来保存可回调的callable object
class CLuaCallback
{
    public:
        CLuaCallback(const char* pszRefTable);
        ~CLuaCallback();

    public:
        int Ref(lua_State* L);
        void Unref(lua_State* L, int ref);
        int GetObj(lua_State* L, int ref);

    private:
        char* m_pszRefTable;

#ifdef _MYLUAREF
    private:
        int m_ref;
#endif

};


extern float GetGCCount(lua_State* L);
extern void GetGCCollect(lua_State* L);
extern void ClearLuaAndGc(lua_State* L);
//lua_pcall的错误处理方法
extern int pcall_handler(lua_State* L);

template <typename T1>
void BroadcastBaseapp(pluto_msgid_t msgid, const T1& p1);

template <typename T1, typename T2>
void BroadcastBaseapp(pluto_msgid_t msgid, const T1& p1, const T2& p2);

template <typename T1, typename T2, typename T3>
void BroadcastBaseapp(pluto_msgid_t msgid, const T1& p1, const T2& p2, const T3& p3);

#ifdef __USE_MSGPACK
extern bool MsgPackTable(lua_State* L, msgpack::packer<msgpack::sbuffer>& pker, int nDeep);
extern bool MsgPackTable(lua_State* L, int idx, msgpack::packer<msgpack::sbuffer>& pker, int nDeep);
extern bool MsgPackKey(lua_State* L, int idx, msgpack::packer<msgpack::sbuffer>& pker);
extern bool MsgPackValue(lua_State* L, int idx, msgpack::packer<msgpack::sbuffer>& pker, int nDeep);

extern bool MsgUnpackToTable(lua_State* L, const char* src, size_t len);
extern bool MsgPushKey(lua_State* L, msgpack_object& obj);
extern bool MsgPushValue(lua_State* L, msgpack_object& obj);
extern bool MsgPushMap(lua_State* L, msgpack_object& msgObj);
#endif

//原始服向跨服服务器的globalbase发出的rpc调用
extern int CrossServerRpc(lua_State* L);
//跨服服务器向原始服发出的rpc回调
extern int CrossClientResp(lua_State* L);
//跨服服务器向原始服发出的广播
extern int CrossClientBroadcast(lua_State* L);


#endif
