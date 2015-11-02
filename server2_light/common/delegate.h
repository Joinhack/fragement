/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：delegate
// 创建者：senfer
// 修改者列表：
// 创建日期：2013.3.22
// 模块描述：事件机制托管模块
//----------------------------------------------------------------*/

#ifndef _DELEGATE_H
#define _DELEGATE_H
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include <iostream>
#include <typeinfo>
#include <string.h>

using namespace std;
class NullType
{
        //todo: nothing
};
//封装lua压栈操作
inline void push(lua_State* L, string arg)
{
    lua_pushstring(L, arg.c_str());
}
inline void push(lua_State* L, char *arg)
{
    lua_pushstring(L, arg);
}
inline void push(lua_State* L, const char *arg)
{
    lua_pushstring(L, arg);
}
inline void push(lua_State* L, bool arg)
{
    lua_pushboolean(L, arg);
}
inline void push(lua_State* L, int arg)
{
    lua_pushnumber(L, arg);
}
inline void push(lua_State* L, long arg)
{
    lua_pushnumber(L, arg);
}
inline void push(lua_State* L, double arg)
{
    lua_pushnumber(L, arg);
}
inline void push(lua_State* L, float arg)
{
    lua_pushnumber(L, arg);
}
inline void push(lua_State* L, unsigned int arg)
{
    lua_pushnumber(L, arg);
}
inline void push(lua_State* L, unsigned long arg)
{
    lua_pushnumber(L, arg);
}

//仿函数构建基类
class IFuncBase
{
    public:
        virtual ~IFuncBase() {}
        virtual void operator()(const char* _arg1, const char*  _arg2, const char*  _arg3) {}
        virtual void operator()(const char*  _arg1, const char*  _arg2) {}
        virtual void operator()(const char*  _arg1) {}
        virtual void operator()() {}
};
//成员函数构建
//三个参数
template<typename Class, typename P1 = NullType, typename P2 = NullType, typename P3 = NullType>
class CFuncOfMem : public IFuncBase
{
    public:
        typedef void(Class::*MemFuncType)(P1, P2, P3);
        MemFuncType mpfunc;
        Class* mobj;


        CFuncOfMem(MemFuncType func, Class* obj)
        {
            mpfunc = func;
            mobj = obj;
        }
        virtual void operator()(const char* _arg1, const char*  _arg2, const char*  _arg3)
        {
            (mobj->*mpfunc)(_arg1, _arg2, _arg3);
        }
};
//成员函数类模板偏特化
//两个参数
template<typename Class, typename P1, typename P2>
class CFuncOfMem<Class, P1, P2> : public IFuncBase
{
    public:
        typedef void(Class::*MemFuncType)(P1, P2);
        MemFuncType mpfunc;
        Class* mobj;
        CFuncOfMem(MemFuncType func, Class* obj)
        {
            mpfunc = func;
            mobj = obj;
        }
        virtual void operator()(const char*  _arg1, const char*  _arg2)
        {
            (mobj->*mpfunc)(_arg1, _arg2);
        }
};
//一个参数
template<typename Class, typename P1>
class CFuncOfMem<Class, P1> : public IFuncBase
{
    public:
        typedef void(Class::*MemFuncType)(P1);
        MemFuncType mpfunc;
        Class* mobj;
        CFuncOfMem(MemFuncType func, Class* obj)
        {
            mpfunc = func;
            mobj = obj;
        }
        virtual void operator()(const char*  _arg1)
        {
            (mobj->*mpfunc)(_arg1);
        }
};
//没有参数
template<typename Class>
class CFuncOfMem<Class> : public IFuncBase
{
    public:
        typedef void(Class::*MemFuncType)();
        MemFuncType mpfunc;
        Class* mobj;
        CFuncOfMem(MemFuncType func, Class* obj)
        {
            mpfunc = func;
            mobj = obj;
        }
        virtual void operator()()
        {
            (mobj->*mpfunc)();
        }
};

//普通函数构建
template<typename P1 = NullType, typename P2 = NullType, typename P3 = NullType>
class CFuncOfPtr : public IFuncBase
{
    public:
        typedef void(*PtrFuncType)(P1, P2, P3);
        PtrFuncType mpfunc;
        CFuncOfPtr(PtrFuncType pf)
        {
            mpfunc = pf;
        }
        virtual void operator()(P1 _arg1, P2 _arg2, P3 _arg3)
        {
            (*mpfunc)(_arg1, _arg2, _arg3);
        }
};
//两个参数
template<typename P1, typename P2>
class CFuncOfPtr<P1, P2> : public IFuncBase
{
    public:
        typedef void(*PtrFuncType)(P1, P2);
        PtrFuncType mpfunc;
        CFuncOfPtr(PtrFuncType pf)
        {
            mpfunc = pf;
        }
        virtual void operator()(P1 _arg1, P2 _arg2)
        {
            (*mpfunc)(_arg1, _arg2);
        }
};
//一个参数
template<typename P1>
class CFuncOfPtr<P1> : public IFuncBase
{
    public:
        typedef void(*PtrFuncType)(P1);
        PtrFuncType mpfunc;
        CFuncOfPtr(PtrFuncType pf)
        {
            mpfunc = pf;
        }
        virtual void operator()(P1 _arg1)
        {
            (*mpfunc)(_arg1);
        }
};
//没有参数
template<>
class CFuncOfPtr<> : public IFuncBase
{
    public:
        typedef void(*PtrFuncType)();
        PtrFuncType mpfunc;
        CFuncOfPtr(PtrFuncType pf)
        {
            mpfunc = pf;
        }
        virtual void operator()()
        {
            (*mpfunc)();
        }
};
//构建lua仿函数
//三个参数类模板
template<typename P1 = NullType, typename P2 = NullType, typename P3 = NullType>
class CFuncOfLua : public IFuncBase
{
    public:
        lua_State *_L;
        const char *_tName;
        const char *_fName;
        CFuncOfLua(lua_State *L, const char *tName, const char *fName)
        {
            _L = L;
            _tName = tName;
            _fName = fName;
        }
        virtual void operator()(P1 _arg1, P2 _arg2, P3 _arg3)
        {
            //todo:
            int n = lua_gettop(_L);
            lua_pop(_L, n);
            if( !strcasecmp(_tName, "") )
            {
                if( !strcasecmp(_fName, "") )
                {
                    cout<<"invoke lua event, parameters error\n";
                    return ;
                }
                lua_getglobal(_L, _fName);
            }
            else
            {
                lua_getglobal(_L, _tName);
                lua_pushstring(_L, _fName);
                lua_gettable(_L, 1);
            }
            push(_L, _arg1);
            push(_L, _arg2);
            push(_L, _arg3);
            int ret = lua_pcall(_L, 3, 0, 0);
            if( ret != 0 )
            {
                cout<<"invoke lua event error"<<endl;
            }
            return ;
        }
};
//两个参数的类模板
template<typename P1, typename P2>
class CFuncOfLua<P1, P2> : public IFuncBase
{
    public:
        lua_State *_L;
        const char *_tName;
        const char *_fName;
        CFuncOfLua(lua_State *L, const char *tName, const char *fName)
        {
            _L = L;
            _tName = tName;
            _fName = fName;
        }
        virtual void operator()(P1 _arg1, P2 _arg2)
        {
            //todo:
            int n = lua_gettop(_L);
            lua_pop(_L, n);
            if( !strcasecmp(_tName, "") )
            {
                if( !strcasecmp(_fName, "") )
                {
                    cout<<"invoke lua event, parameters error\n";
                    return ;
                }
                lua_getglobal(_L, _fName);
            }
            else
            {
                lua_getglobal(_L, _tName);
                lua_pushstring(_L, _fName);
                lua_gettable(_L, 1);
            }
            push(_L, _arg1);
            push(_L, _arg2);
            int ret = lua_pcall(_L, 2, 0, 0);
            if( ret != 0 )
            {
                cout<<"invoke lua event error"<<endl;
            }
            return ;
        }
};
//一个参数的类模板
template<typename P1>
class CFuncOfLua<P1> : public IFuncBase
{
    public:
        lua_State *_L;
        const char *_tName;
        const char *_fName;
        P1 _arg1;
        CFuncOfLua(lua_State *L, const char *tName, const char *fName)
        {
            _L = L;
            _tName = tName;
            _fName = fName;
        }
        virtual void operator()(P1 _arg1)
        {
            //todo:
            int n = lua_gettop(_L);
            lua_pop(_L, n);
            if( !strcasecmp(_tName, "") )
            {
                if( !strcasecmp(_fName, "") )
                {
                    cout<<"invoke lua event, parameters error\n";
                    return ;
                }
                lua_getglobal(_L, _fName);
            }
            else
            {
                lua_getglobal(_L, _tName);
                lua_pushstring(_L, _fName);
                lua_gettable(_L, 1);
            }
            push(_L, _arg1);
            int ret = lua_pcall(_L, 1, 0, 0);
            if( ret != 0 )
            {
                cout<<"invoke lua event error"<<endl;
            }
            return ;
        }
};
//没有参数的类模板
template<>
class CFuncOfLua<> : public IFuncBase
{
    public:
        lua_State *_L;
        const char *_tName;
        const char *_fName;
        CFuncOfLua(lua_State *L, const char *tName, const char *fName)
        {
            _L = L;
            _tName = tName;
            _fName = fName;
        }
        virtual void operator()()
        {
            //todo:
            //cout<<"invoke lua event 000000"<<endl;
            int n = lua_gettop(_L);
            lua_pop(_L, n);
            if( !strcasecmp(_tName, "") )
            {
                if( !strcasecmp(_fName, "") )
                {
                    cout<<"invoke lua event, parameters error\n";
                    return ;
                }
                lua_getglobal(_L, _fName);
            }
            else
            {
                lua_getglobal(_L, _tName);
                lua_pushstring(_L, _fName);
                lua_gettable(_L, 1);
            }
            int ret = lua_pcall(_L, 0, 0, 0);
            if( ret != 0 )
            {
                cout<<"invoke lua event error"<<endl;
            }
            return ;
        }
};



//仿函数
class IFunctorBase
{
    public:
        virtual ~IFunctorBase() {}
        virtual void operator()(const char* _arg1, const char*  _arg2, const char*  _arg3) {}
        virtual void operator()(const char*  _arg1, const char*  _arg2) {}
        virtual void operator()(const char*  _arg1) {}
        virtual void operator()() {}

};
//三个参数
template<typename P1 = NullType, typename P2 = NullType, typename P3 = NullType>
class CFunctor : public IFunctorBase
{
    public:
        IFuncBase* mpfunc;
        CFunctor() : mpfunc(NULL) {}
        ~CFunctor()
        {
            if (mpfunc != NULL)
            {
                delete mpfunc;
                mpfunc = NULL;
            }
        }
        template<typename Class>
        CFunctor(void(Class::*pMemFunc)(P1, P2, P3), Class* obj)
        {
            mpfunc = new CFuncOfMem<Class, P1, P2, P3>(pMemFunc, obj);
        }
        CFunctor(void(*pPtrFunc)(P1, P2, P3))
        {
            mpfunc = new CFuncOfPtr<P1, P2, P3>(pPtrFunc);
        }
        CFunctor(lua_State *L, const char* tName, const char* fName)
        {
            mpfunc = new CFuncOfLua<P1, P2, P3>(L, tName, fName);
        }
        virtual void operator()(P1 _arg1, P2 _arg2, P3 _arg3)
        {
            (*mpfunc)(_arg1, _arg2, _arg3);
        }
        CFunctor& operator=(CFunctor& f)
        {
            mpfunc = f.mpfunc;
            f.mpfunc = NULL;
            return *this;
        }

};
//以下类模板为仿函数对不同参数实现的偏特化
//两个参数
template<typename P1, typename P2>
class CFunctor<P1, P2> : public IFunctorBase
{
    public:
        IFuncBase* mpfunc;
        CFunctor() : mpfunc(NULL) {}
        ~CFunctor()
        {
            if (mpfunc != NULL)
            {
                delete mpfunc;
                mpfunc = NULL;
            }
        }
        template<typename Class>
        CFunctor(void(Class::*pMemFunc)(P1, P2), Class* obj)
        {
            mpfunc = new CFuncOfMem<Class, P1, P2>(pMemFunc, obj);
        }
        CFunctor(void(*pPtrFunc)(P1, P2))
        {
            mpfunc = new CFuncOfPtr<P1, P2>(pPtrFunc);
        }
        CFunctor(lua_State *L, const char* tName, const char* fName)
        {
            mpfunc = new CFuncOfLua<P1, P2>(L, tName, fName);
        }
        void operator()(P1 _arg1, P2 _arg2)
        {
            (*mpfunc)(_arg1, _arg2);
        }
        CFunctor& operator=(CFunctor& f)
        {
            mpfunc = f.mpfunc;
            f.mpfunc = NULL;
            return *this;
        }
};
//一个参数
template<typename P1>
class CFunctor<P1> : public IFunctorBase
{
    public:
        IFuncBase* mpfunc;
        CFunctor() : mpfunc(NULL) {}
        ~CFunctor()
        {
            if (mpfunc != NULL)
            {
                delete mpfunc;
                mpfunc = NULL;
            }
        }
        template<typename Class>
        CFunctor(void(Class::*pMemFunc)(P1), Class* obj)
        {
            mpfunc = new CFuncOfMem<Class, P1>(pMemFunc, obj);
        }
        CFunctor(void(*pPtrFunc)(P1))
        {
            mpfunc = new CFuncOfPtr<P1>(pPtrFunc);
        }
        CFunctor(lua_State *L, const char* tName, const char* fName)
        {
            mpfunc = new CFuncOfLua<P1>(L, tName, fName);
        }
        void operator()(P1 _arg1)
        {
            (*mpfunc)(_arg1);
        }
        CFunctor& operator=(CFunctor& f)
        {
            mpfunc = f.mpfunc;
            f.mpfunc = NULL;
            return *this;
        }

};
//没有参数
template<>
class CFunctor<> : public IFunctorBase
{
    public:
        IFuncBase* mpfunc;
        CFunctor() : mpfunc(NULL) {}
        ~CFunctor()
        {
            if (mpfunc != NULL)
            {
                delete mpfunc;
                mpfunc = NULL;
            }
        }
        template<typename Class>
        CFunctor(void(Class::*pMemFunc)(), Class* obj)
        {
            mpfunc = new CFuncOfMem<Class>(pMemFunc, obj);
        }
        CFunctor(void(*pPtrFunc)())
        {
            mpfunc = new CFuncOfPtr<>(pPtrFunc);
        }
        CFunctor(lua_State *L, const char* tName, const char* fName)
        {
            mpfunc = new CFuncOfLua<>(L, tName, fName);
        }
        void operator()()
        {
            (*mpfunc)();
        }
        CFunctor& operator=(CFunctor& f)
        {
            mpfunc = f.mpfunc;
            f.mpfunc = NULL;
            return *this;
        }

};


//以下模板函数为对成员函数和非成员函数绑定全特化
//成员函数绑定到仿函数
//带有三个参数的绑定函数
template<typename Class, typename P1, typename P2, typename P3>
CFunctor<P1, P2, P3>* bind(void(Class::*pMemFunc)(P1, P2, P3), Class* obj)
{
    return  new CFunctor<P1, P2, P3>(pMemFunc, obj);
}
//带有两个参数的绑定函数
template<typename Class, typename P1, typename P2>
CFunctor<P1, P2>* bind(void(Class::*pMemFunc)(P1, P2), Class* obj)
{
    return new CFunctor<P1, P2>(pMemFunc, obj);
}
//带有一个参数的绑定函数
template<typename Class, typename P1>
CFunctor<P1>* bind(void(Class::*pMemFunc)(P1), Class* obj)
{
    return new CFunctor<P1>(pMemFunc, obj);
}
//没有参数的绑定函数
template<typename Class>
CFunctor<>* bind(void(Class::*pMemFunc)(), Class* obj)
{
    return new CFunctor<>(pMemFunc, obj);
}

//非成员函数绑定到仿函数
//带有三个参数的绑定函数
template<typename P1, typename P2, typename P3>
CFunctor<P1, P2, P3>* bind(void(*pFunc)(P1, P2, P3))
{
    return  new CFunctor<P1, P2, P3>(pFunc);
}
//带有两个参数的绑定函数
template<typename P1, typename P2>
CFunctor<P1, P2>* bind(void(*pFunc)(P1, P2))
{
    return  new CFunctor<P1, P2>(pFunc);
}
//带有一个参数的绑定函数
template<typename P1>
CFunctor<P1>* bind(void(*pFunc)(P1))
{
    return  new CFunctor<P1>(pFunc);
}
//没有参数的绑定函数
//template<>
static CFunctor<>* bind(void(*pFunc)())
{
    return  new CFunctor<>(pFunc);
}

//面向lua层的调用，表函数和全局函数绑定到仿函数
//带有三个参数的绑定函数
template<typename P1, typename P2, typename P3>
static CFunctor<P1, P2, P3>* bind(lua_State *L, const char *tName, const char *fName,
                                  P1 arg1, P2 arg2, P3 arg3)
{
    return  new CFunctor<P1, P2, P3>(L, tName, fName);

}

//带有两个参数的绑定函数
template<typename P1, typename P2>
static CFunctor<P1, P2>* bind(lua_State *L, const char *tName, const char *fName,
                              P1 arg1, P2 arg2)
{
    return  new CFunctor<P1, P2>(L, tName, fName);
}
//带有一个参数的绑定函数
template<typename P1>
static CFunctor<P1>* bind(lua_State *L, const char *tName, const char *fName, P1 arg1)
{
    return  new CFunctor<P1>(L, tName, fName);
}
//没有参数的绑定函数
//template<>
static CFunctor<>* bind(lua_State *L, const char *tName, const char *fName)
{
    return  new CFunctor<>(L, tName, fName);
}


#endif
