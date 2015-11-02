/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：type_mogo
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.11
// 模块描述：def相关数据类型定义。
//----------------------------------------------------------------*/

#include "type_mogo.h"
#include "pluto.h"
#include "util.h"
#include "world_select.h"

//#include <mysql++/mysql.h>


namespace mogo
{

VOBJECT::~VOBJECT()
{
    switch(vt)
    {
    case V_STR:
        {
            delete vv.s;
            break;
        }
    case V_BLOB:
        {
            delete (charArrayDummy*)vv.p;
            break;
        }
    //case V_LIST:
    //    {
    //        clearContainer(*(vv.l));
    //        delete vv.l;
    //        break;
    //    }
    //case V_MAP:
    //    {
    //        clearMap(*(vv.m));
    //        delete vv.m;
    //        break;
    //    }
    case V_ENTITY:
        {
            delete (SEntityPropFromPluto*)vv.p;
            break;
        }
	 

    }
}

//map<int, delegate>  2013.01.18
/*
bool PushVObjectToLua(lua_State* L, VOBJECT& v)
{
   map<>   [L]   2013.01.18
    switch(v.vt)
    {
    case V_UINT8:
        {
            lua_pushinteger(L, (lua_Integer)v.vv.u8);
            break;
        }
    case V_INT8:
        {
            lua_pushinteger(L, (lua_Integer)v.vv.i8);
            break;
        }
    case V_UINT16:
        {
            lua_pushinteger(L, (lua_Integer)v.vv.u16);
            break;
        }
    case V_INT16:
        {
            lua_pushinteger(L, (lua_Integer)v.vv.i16);
            break;
        }
    case V_UINT32:
        {
            lua_pushinteger(L, (lua_Integer)v.vv.u32);
            break;
        }
    case V_INT32:
        {
            lua_pushinteger(L, (lua_Integer)v.vv.i32);
            break;
        }
    //case V_UINT64:
    //    {
    //        lua_pushinteger(L, (lua_Integer)v.vv.u64);
    //        break;
    //    }
    //case V_INT64:
    //    {
    //        lua_pushinteger(L, (lua_Integer)v.vv.i64);
    //        break;
    //    }
    case V_FLOAT32:
        {
            lua_pushnumber(L, (lua_Number)v.vv.f32);
            break;
        }
    //case V_FLOAT64:
    //    {
    //        lua_pushnumber(L, (lua_Number)v.vv.f64);
    //        break;
    //    }
    case V_STR:
        {
            lua_pushstring(L, v.vv.s->c_str());
            break;
        }
    case V_BLOB:
        {
            charArrayDummy* d = (charArrayDummy*)v.vv.p;
            lua_pushlstring(L, d->m_s, d->m_l);
            break;
        }
    case V_LUATABLE:
        {
            world* the_world = GetWorld();
            CLuaCallback& cb = the_world->GetLuaTables();
            cb.getobj(L, v.vv.i32);
            lua_remove(L, -2);  //metatable
            break;
        }
	case V_LUA_OBJECT:
		{
			if(v.vv.i32 > 0)
			{
				world* the_world = GetWorld();
				CLuaCallback& cb = the_world->GetLuaTables();
				cb.getobj(L, v.vv.i32);
				lua_remove(L, -2);  //metatable
			}
			else
			{
				lua_pushnil(L);
			}

			break;
		}
	case V_REDIS_HASH:
		{
			CRedisHash* p = (CRedisHash*)v.vv.p;
			get_redis_hash(L, p);
			break;
		}
    default:
        {
            //未找到匹配的类型处理
            return false;
        }
    }
    

    return true;
}
/*
bool FillVObjectFromLua(lua_State* L, VOBJECT& v, int idx)
{
    switch(v.vt)
    {
    case V_UINT8:
        {
            v.vv.u8 = (uint8_t)luaL_checkint(L, idx);
            break;
        }
    case V_INT8:
        {
            v.vv.i8 = (int8_t)luaL_checkint(L, idx);
            break;
        }
    case V_UINT16:
        {
            v.vv.u16 = (uint16_t)luaL_checkint(L, idx);
            break;
        }
    case V_INT16:
        {
            v.vv.i16 = (int16_t)luaL_checkint(L, idx);
            break;
        }
    case V_UINT32:
        {
            v.vv.u32 = (uint32_t)luaL_checkint(L, idx);
            break;
        }
    case V_INT32:
        {
            v.vv.i32 = (int32_t)luaL_checkint(L, idx);
            break;
        }
    //case V_UINT64:
    //    {
    //        v.vv.u64 = (uint64_t)luaL_checkint(L, idx);
    //        break;
    //    }
    //case V_INT64:
    //    {
    //        v.vv.i64 = (int64_t)luaL_checkint(L, idx);
    //        break;
    //    }
    case V_FLOAT32:
        {
            v.vv.f32 = (float32_t)luaL_checknumber(L, idx);
            break;
        }
    //case V_FLOAT64:
    //    {
    //        v.vv.f64 = (float64_t)luaL_checknumber(L, idx);
    //        break;
    //    }
    case V_STR:
        {
            v.vv.s = new string(luaL_checkstring(L, idx));
            break;
        }
    case V_BLOB:
        {
            size_t _l;
            const char* _s = luaL_checklstring(L, idx, &_l);
            charArrayDummy* d = new charArrayDummy;
            d->m_l = (uint16_t)_l;
            char* _s2 = new char[_l];
            memcpy(_s2, _s, _l);
            d->m_s = _s2;
            v.vv.p = d;
            break;
        }
    }
    return true;
}
*/
void FillVObjectInitValue(const CEntityParent* pEntity, const string& strAttri, VOBJECT& v)
{
    switch(v.vt)
    {
    case V_UINT8:
        {
            v.vv.u8 = (uint8_t)0;
            break;
        }
    case V_INT8:
        {
            v.vv.i8 = (int8_t)0;
            break;
        }
    case V_UINT16:
        {
            v.vv.u16 = (uint16_t)0;
            break;
        }
    case V_INT16:
        {
            v.vv.i16 = (int16_t)0;
            break;
        }
    case V_UINT32:
        {
            v.vv.u32 = (uint32_t)0;
            break;
        }
    case V_INT32:
        {
            v.vv.i32 = (int32_t)0;
            break;
        }
    //case V_UINT64:
    //    {
    //        v.vv.u64 = (uint64_t)0;
    //        break;
    //    }
    //case V_INT64:
    //    {
    //        v.vv.i64 = (int64_t)0;
    //        break;
    //    }
    case V_FLOAT32:
        {
            v.vv.f32 = (float32_t)0;
            break;
        }
    //case V_FLOAT64:
    //    {
    //        v.vv.f64 = (float64_t)0;
    //        break;
    //    }
    case V_STR:
        {
            v.vv.s = new string("");
            break;
        }
    case V_BLOB:
        {
            v.vv.p = new charArrayDummy;
            break;
        }
     
    default:
        {
            //nothing to do
        }
    }
}

void FillVObjectDefaultValue(const CEntityParent* pEntity, const string& strAttri, VOBJECT& v, const string& strDefault)
{
    if(strDefault.empty())
    {
        FillVObjectInitValue(pEntity, strAttri, v);
        return;
    }

    switch(v.vt)
    {
    case V_UINT8:
        {
            v.vv.u8 = (uint8_t)atoi(strDefault.c_str());
            break;
        }
    case V_INT8:
        {
            v.vv.i8 = (int8_t)atoi(strDefault.c_str());
            break;
        }
    case V_UINT16:
        {
            v.vv.u16 = (uint16_t)atoi(strDefault.c_str());
            break;
        }
    case V_INT16:
        {
            v.vv.i16 = (int16_t)atoi(strDefault.c_str());
            break;
        }
    case V_UINT32:
        {
            v.vv.u32 = (uint32_t)atoll(strDefault.c_str());
            break;
        }
    case V_INT32:
        {
            v.vv.i32 = (int32_t)atoll(strDefault.c_str());
            break;
        }
    //case V_UINT64:
    //    {
    //        v.vv.u64 = (uint64_t)atoll(strDefault.c_str());
    //        break;
    //    }
    //case V_INT64:
    //    {
    //        v.vv.i64 = (int64_t)atoll(strDefault.c_str());
    //        break;
    //    }
    case V_FLOAT32:
        {
            v.vv.f32 = (float32_t)atof(strDefault.c_str());
            break;
        }
    //case V_FLOAT64:
    //    {
    //        v.vv.f64 = (float64_t)atof(strDefault.c_str());
    //        break;
    //    }
    case V_STR:
        {
            v.vv.s = new string(strDefault);
            break;
        }
    case V_BLOB:
        {
            v.vv.p = new charArrayDummy;
            break;
        }
    
    default:
        {
            //nothing to do
        }
    }

}
/*
bool PushVObjectToOstream(MYSQL* mysql, ostringstream& oss, VOBJECT& v)
{
    switch(v.vt)
    {
    case V_UINT8:
        {
            oss << (unsigned int)v.vv.u8;
            break;
        }
    case V_UINT16:
        {
            oss << v.vv.u16;
            break;
        }
    case V_UINT32:
        {
            oss << v.vv.u32;
            break;
        }
    //case V_UINT64:
    //    {
    //        oss << v.vv.u64;
    //        break;
    //    }
    case V_INT8:
        {
            oss << (int)v.vv.i8;
            break;
        }
    case V_INT16:
        {
            oss << v.vv.i16;
            break;
        }
    case V_INT32:
        {
            oss << v.vv.i32;
            break;
        }
    //case V_INT64:
    //    {
    //        oss << v.vv.i64;
    //        break;
    //    }
    case V_FLOAT32:
        {
            oss << v.vv.f32;
            break;
        }
    //case V_FLOAT64:
    //    {
    //        oss << v.vv.f64;
    //        break;
    //    }
    case V_STR:
        {
			string& s = (*(v.vv.s));
			char _s[10240];
			mysql_real_escape_string(mysql, _s, s.c_str(), (unsigned long)s.size());
            oss << "'" << _s << "'";
            break;
        }
    case V_BLOB:
        {
            charArrayDummy* d = (charArrayDummy*)v.vv.p;
            char _s[10240];
            mysql_real_escape_string(mysql, _s, d->m_s, (unsigned long)d->m_l);
            oss << "'" << _s << "'";
            break;
        }
     
    default:
        {
            return false;
        }
    }

    return true;
}
*/
void _CopyStringToRedisCmd(int idx, const string& k, char** argv, size_t* argvlen)
{
	char* s = new char[k.size() + 1];
	strcpy(s, k.c_str());
	argv[idx] = s;
	argvlen[idx] = int(k.size());
}

void PushVObjectToRedisCmd(int idx, const string& k, VOBJECT& v, char** argv, size_t* argvlen)
{
	//key
	_CopyStringToRedisCmd(idx, k, argv, argvlen);
	++idx;

	//value
	ostringstream oss;
	switch(v.vt)
	{
	case V_UINT8:
		{
			oss << (unsigned int)v.vv.u8;
			break;
		}
	case V_UINT16:
		{
			oss << v.vv.u16;
			break;
		}
	case V_UINT32:
		{
			oss << v.vv.u32;
			break;
		}
	//case V_UINT64:
	//	{
	//		oss << v.vv.u64;
	//		break;
	//	}
	case V_INT8:
		{
			oss << (int)v.vv.i8;
			break;
		}
	case V_INT16:
		{
			oss << v.vv.i16;
			break;
		}
	case V_INT32:
		{
			oss << v.vv.i32;
			break;
		}
	//case V_INT64:
	//	{
	//		oss << v.vv.i64;
	//		break;
	//	}
	case V_FLOAT32:
		{
			oss << v.vv.f32;
			break;
		}
	//case V_FLOAT64:
	//	{
	//		oss << v.vv.f64;
	//		break;
	//	}
	case V_STR:
		{
			string& s = (*(v.vv.s));
			_CopyStringToRedisCmd(idx, s, argv, argvlen);
			return;
		}
	case V_BLOB:
		{
			charArrayDummy* d = (charArrayDummy*)v.vv.p;
			
			char* s = new char[d->m_l];
			memcpy(s, d->m_s, d->m_l);

			argv[idx] = s;
			argvlen[idx] = d->m_l;
			
			return;
		}
	 
	default:
		{
			return;
		}
	}

	_CopyStringToRedisCmd(idx, oss.str(), argv, argvlen);
	return;
}



};




