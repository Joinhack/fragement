/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：type_mogo
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.11
// 模块描述：def相关数据类型定义。
//----------------------------------------------------------------*/

#ifdef _WIN32
	#include <winsock.h>
#endif
#include "type_mogo.h"
#include "pluto.h"
#include "util.h"
#include "world_select.h"
#include <mysql.h>	
#include "logger.h"


#ifdef _PLUTO_POOL
mogo::MemoryPool* mogo::VOBJECT::memPool = NULL;
mogo::MyLock mogo::VOBJECT::m_lock;
#endif

namespace mogo
{

    VOBJECT::~VOBJECT()
    {
		this->Clear();
    }

	void VOBJECT::Clear()
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
            case V_ENTITY:
            {
                delete (SEntityPropFromPluto*)vv.p;
                break;
            }
            case V_LUATABLE:
			case V_LUA_OBJECT:
            {
                //printf("VOBJECT::~VOBJECT(), V_LUATABLE\n");
				int32_t nRef = vv.i32;
				if(nRef != -1)
				{
					world* the_world = GetWorld();
					lua_State* L = the_world->GetLuaState();
					CLuaCallback& cb = the_world->GetLuaTables();
					cb.Unref(L, vv.i32);
					vv.i32 = -1;
				}
                break;
            }
        }

		vt = V_UINT8;		//修改类型为没有清理操作的类型,以防重复清理
	}

#ifdef _PLUTO_POOL
    void * VOBJECT::operator new(size_t size)
    {

        m_lock.Lock();

        if (NULL == memPool)
        {
            expandMemoryPool();
        }

        MemoryPool *head = memPool;
        memPool = head->next;

        m_lock.Unlock();

        //LogDebug("VOBJECT new", "size=%d", size);

        return head;
    }

    void VOBJECT::operator delete(void* p, size_t size)
    {
        m_lock.Lock();

        MemoryPool *head = (MemoryPool *)p;
        head->next = memPool;
        memPool = head;

        m_lock.Unlock();

        //LogDebug("VOBJECT delete", "size=%d", size);
    }

    void VOBJECT::expandMemoryPool()
    {
        size_t size = (sizeof(VOBJECT) > sizeof(MemoryPool *)) ? sizeof(VOBJECT) : sizeof(MemoryPool *);

        MemoryPool *runner = (MemoryPool *) new char[size];
        memPool = runner;

        enum  { EXPAND_SIZE = 32};
        for (int i=0; i<EXPAND_SIZE; i++)
        {
            runner->next = (MemoryPool *) new char[size];
            runner = runner->next;
        }

        runner->next = NULL;
    }
#endif

    //map<int, delegate>  2013.01.18

    bool PushVObjectToLua(lua_State* L, VOBJECT& v)
    {
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
                  lua_pushnumber(L, (lua_Number)v.vv.u32);
                  break;
              }
          case V_INT32:
              {
                  lua_pushinteger(L, (lua_Integer)v.vv.i32);
                  break;
              }
          case V_UINT64:
              {
                  lua_pushnumber(L, (lua_Number)v.vv.u64);
                  break;
              }
          case V_INT64:
              {
                  lua_pushnumber(L, (lua_Number)v.vv.i64);
                  break;
              }
          case V_FLOAT32:
              {
                  lua_pushnumber(L, (lua_Number)v.vv.f32);
                  break;
              }
          case V_FLOAT64:
              {
                  lua_pushnumber(L, (lua_Number)v.vv.f64);
                  break;
              }
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
                  cb.GetObj(L, v.vv.i32);
                  lua_remove(L, -2);  //metatable
                  break;
              }
          case V_LUA_OBJECT:
              {
                  if(v.vv.i32 > 0)
                  {
                      world* the_world = GetWorld();
                      CLuaCallback& cb = the_world->GetLuaTables();
                      cb.GetObj(L, v.vv.i32);
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
                  GetRedisHash(L, p);
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
            case V_UINT64:
            {
                v.vv.u64 = (uint64_t)luaL_checknumber(L, idx);
                break;
            }
            case V_INT64:
            {
                v.vv.i64 = (int64_t)luaL_checknumber(L, idx);
                break;
            }
            case V_FLOAT32:
            {
                v.vv.f32 = (float32_t)luaL_checknumber(L, idx);
                break;
            }
            case V_FLOAT64:
            {
                v.vv.f64 = (float64_t)luaL_checknumber(L, idx);
                break;
            }
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
            case V_LUATABLE:
            {
                if(!lua_istable(L, idx))
                {
                    v.vv.i32 = -1;
                    lua_pushfstring(L, "arg %d need a table", idx);
                    lua_error(L);
                }
                else
                {
                    CLuaCallback& cb = GetWorld()->GetLuaTables();
					//调用者处理
                    //if(v.vv.i32 > 0)
                    //{
                    //   cb.Unref(L, v.vv.i32);
                    //}

                    lua_pushvalue(L, idx);
                    v.vv.i32 = cb.Ref(L);
                }
                break;
            }
            case V_LUA_OBJECT:
            {
                CLuaCallback& cb = GetWorld()->GetLuaTables();
				//调用者处理
                //if(v.vv.i32 > 0)
                //{
                //    cb.Unref(L, v.vv.i32);
                //}

                lua_pushvalue(L, idx);
                v.vv.i32 = cb.Ref(L);
                break;
            }
            case V_REDIS_HASH:
            {
                //不支持newindex
                return false;
            }
            default:
            {
                return false;
            }
        }

        return true;
    }

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
            case V_UINT64:
            {
                v.vv.u64 = (uint64_t)0;
                break;
            }
            case V_INT64:
            {
                v.vv.i64 = (int64_t)0;
                break;
            }
            case V_FLOAT32:
            {
                v.vv.f32 = (float32_t)0;
                break;
            }
            case V_FLOAT64:
            {
                v.vv.f64 = (float64_t)0;
                break;
            }
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
            case V_LUATABLE:
            {
                lua_State* L = GetWorld()->GetLuaState();
                lua_newtable(L);
                CLuaCallback& cb = GetWorld()->GetLuaTables();
                v.vv.i32 = (int32_t)cb.Ref(L);
                break;
            }
            case V_LUA_OBJECT:
            {
                v.vv.i32 = -1;
                break;
            }
            case V_REDIS_HASH:
            {
                lua_State* L = GetWorld()->GetLuaState();
                CRedisHash* p = CreateRedisHash(L);
                p->SetEntity(pEntity, strAttri);
                v.vv.p = p;
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
            case V_UINT64:
            {
                v.vv.u64 = (uint64_t)atoll(strDefault.c_str());
                break;
            }
            case V_INT64:
            {
                v.vv.i64 = (int64_t)atoll(strDefault.c_str());
                break;
            }
            case V_FLOAT32:
            {
                v.vv.f32 = (float32_t)atof(strDefault.c_str());
                break;
            }
            case V_FLOAT64:
            {
                v.vv.f64 = (float64_t)atof(strDefault.c_str());
                break;
            }
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
            case V_LUATABLE:
            {
                lua_State* L = GetWorld()->GetLuaState();

#ifdef __USE_MSGPACK

                if( LuaUnpickleFromBlob(L, (char*)strDefault.c_str(), (uint16_t)strDefault.size()))
#else
                if( LuaUnpickleFromString(L, strDefault) )
#endif
                {
                    CLuaCallback& cb = GetWorld()->GetLuaTables();
                    v.vv.i32 = (int32_t)cb.Ref(L);
                    break;
                }
                else
                {
                    //初始化失败,give warning,todo
                    v.vv.i32 = -1;
                }
                break;
            }
            case V_LUA_OBJECT:
            {
                v.vv.i32 = -1;
                break;
            }
            case V_REDIS_HASH:
            {
                lua_State* L = GetWorld()->GetLuaState();
                CRedisHash* p = CreateRedisHash(L);
                p->SetEntity(pEntity, strAttri);
                v.vv.p = p;
                break;
            }
            default:
            {
                //nothing to do
            }
        }

    }

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
            case V_UINT64:
            {
                oss << v.vv.u64;
                break;
            }
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
            case V_INT64:
            {
                oss << v.vv.i64;
                break;
            }
            case V_FLOAT32:
            {
                oss << v.vv.f32;
                break;
            }
            case V_FLOAT64:
            {
                oss << v.vv.f64;
                break;
            }
#ifndef _WIN32
            case V_STR:
            {
                string& s = (*(v.vv.s));
                //char _s[10240];
                char _s[65535*2];
                mysql_real_escape_string(mysql, _s, s.c_str(), (unsigned long)s.size());
                oss << "'" << _s << "'";
                break;
            }
            case V_BLOB:
            {
                charArrayDummy* d = (charArrayDummy*)v.vv.p;

                //char _s[10240];
                char _s[65535*2];
                mysql_real_escape_string(mysql, _s, d->m_s, (unsigned long)d->m_l);
                oss << "'" << _s << "'";

                break;
            }
#endif
            case V_LUATABLE:
            {
                //        world* the_world = GetWorld();
                //        lua_State* L = the_world->getLuaState();
                //        CLuaCallback& cb = the_world->GetLuaTables();
                //        cb.getobj(L, v.vv.i32);

                //        string s;
                //        if(lua_cpickle_to_string(L, s))
                //        {
                //static char _s[10240];
                //mysql_real_escape_string(mysql, _s, s.c_str(), (unsigned long)s.size());
                //oss << "'" << _s << "'";
                //            lua_pop(L, 2);      //table and metatable
                //        }
                //        break;

                //dbmgr屏蔽了luatable类型
                return false;
            }
            default:
            {
                return false;
            }
        }

        return true;
    }

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
            case V_UINT64:
            {
                oss << v.vv.u64;
                break;
            }
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
            case V_INT64:
            {
                oss << v.vv.i64;
                break;
            }
            case V_FLOAT32:
            {
                oss << v.vv.f32;
                break;
            }
            case V_FLOAT64:
            {
                oss << v.vv.f64;
                break;
            }
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
            case V_LUATABLE:
            {
                //本方法被调用的地方是dbmgr,这里应该没有luatable类型的数据
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






