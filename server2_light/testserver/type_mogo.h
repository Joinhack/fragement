#ifndef __TYPE__MOGO__HEAD__
#define __TYPE__MOGO__HEAD__

#include <stdlib.h>
#include <list>
//#include "lua.hpp"
#include "util.h"

using std::list;

#ifdef _WIN32
    typedef char int8_t;
    typedef unsigned char uint8_t;
    typedef short int int16_t;
    typedef unsigned short int uint16_t;
    typedef int int32_t;
    typedef unsigned int uint32_t;
    typedef long long int64_t;
    typedef unsigned long long uint64_t;
	#define atoll _atoi64;
#else
    #include <inttypes.h>
#endif

typedef float float32_t;
typedef double float64_t;



namespace mogo
{


typedef uint32_t TENTITYID;
typedef uint32_t TDBID;
typedef uint16_t TENTITYTYPE;
typedef uint32_t TSPACEID;
typedef unsigned short T_INTEREST_SIZE;
typedef int32_t int32;
typedef uint32_t uint32;
typedef uint16_t pluto_msgid_t;


class CEntityParent;
//typedef int (CEntityParent::*ENTITY_MEMBER_METHOD)(lua_State*);

struct VOBJECT;

struct CEntityMailbox
{
    uint16_t m_nServerMailboxId;
	TENTITYTYPE m_nEntityType;
    TENTITYID m_nEntityId;
};

struct CClientMailbox
{
    int32_t m_fd;
    TENTITYID m_nEntityId;
    TENTITYTYPE m_nEntityType;
};

enum VTYPE
{
    V_TYPE_ERR = -1, 

    V_LUATABLE  = 1,
    V_STR       = 2,
    V_INT8      = 3,
    V_UINT8     = 4,
    V_INT16     = 5,
    V_UINT16    = 6,
    V_INT32     = 7,
    V_UINT32    = 8,
    //V_INT64     = 9,
    //V_UINT64    = 10,
    V_FLOAT32   = 11,
    //V_FLOAT64   = 12,
    V_ENTITYMB  = 13,
    V_ENTITY    = 14,
    V_CLSMETHOD = 15,
    V_BLOB      = 16,

    //V_LIST = 4,
    //V_MAP = 5,

	V_REDIS_HASH     = 22,      //redis hash类型数据
	V_LUA_OBJECT     = 23,      //任意lua对象,用在entity_index和newindex,其他地方不支持
	V_ENTITY_POINTER = 24,		//仅用在client rpc处
    V_MAX_VTYPE      = 25,

};

union VVALUE
{
    int i;
    float f;
    string* s;
    list<VOBJECT*>* l;
    map<string, VOBJECT*>* m;
    //ENTITY_MEMBER_METHOD em;
    void* p;

    uint8_t u8;
    uint16_t u16;
    uint32_t u32;
    //uint64_t u64;
    int8_t i8;
    int16_t i16;
    int32_t i32;
    //int64_t i64;
    float32_t f32;
    //float64_t f64;
    CEntityMailbox emb;
    pluto_msgid_t msgid;
};

struct VOBJECT
{
    VTYPE vt;
    
    VVALUE vv;

    ~VOBJECT();
};

//extern bool PushVObjectToLua(lua_State* L, VOBJECT& v);
//extern bool FillVObjectFromLua(lua_State* L, VOBJECT& v, int idx);
extern void FillVObjectInitValue(const CEntityParent* p, const string& strAttri, VOBJECT& v);
extern void FillVObjectDefaultValue(const CEntityParent* p, const string& strAttri, VOBJECT& v, const string& strDefault);
extern void PushVObjectToRedisCmd(int idx, const string& s, VOBJECT& v, char** argv, size_t* argvlen);

typedef list<VOBJECT*> T_LIST_OBJECT;
typedef vector<VOBJECT*> T_VECTOR_OBJECT;

template < template <typename ELEM, 
            typename ALLOC = std::allocator<ELEM>
            > class TC
> 
void ClearTListObject(TC<VOBJECT*, std::allocator<VOBJECT*> >* c1)
{
    ClearContainer(*c1);
    delete c1;
}


template<typename T>
void CopyEntityIdSet(const T& from, T& to)
{
    typename T::const_iterator it = from.begin();
    for(; it != from.end(); ++it)
    {
        to.insert(*it);
    }
}

enum LUA_PICKLE_TYPE
{
    LUA_PICKLE_T_TABLE  = 'T',
    //LUA_PICKLE_T_UINT8  = 'c',
    //LUA_PICKLE_T_UINT16 = 'C',
    //LUA_PICKLE_T_UINT32 = 'i',
    //LUA_PICKLE_T_UINT64 = 'I',
    //LUA_PICKLE_T_STR    = 'S',

};

}

#endif

