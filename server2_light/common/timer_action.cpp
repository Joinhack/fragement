#include "timer_action.h"
#include "world_select.h"
#include <typeinfo>


MOGO_BEGIN


struct stLuaTable
{
    string  strLuaTable;
};

template < class T >
void _Lua_PushParam(lua_State* lua, T param)
{
    if (typeid(T) == typeid(int))
    {
        lua_pushboolean(lua, *(int*)(void*)(&param));
    }
    else if (typeid(T) == typeid(double))
    {
        lua_pushnumber(lua, *(double*)(void*)(&param));
    }
    else if (typeid(T) == typeid(string))
    {
        lua_pushstring(lua, (*(string*)(void*)(&param)).c_str());
    }
    else if (typeid(T) == typeid(stLuaTable))
    {
        if (LuaUnpickleFromString(lua, (*(stLuaTable*)(void*)(&param)).strLuaTable) == false) lua_pushnil(lua);
    }
    else
    {
        lua_pushnil(lua);
    }
}

//////////////////////////////////////////////////////////////////////////

template < class T1, class T2 >
CLuaTimer< T1, T2 >::CLuaTimer(uint32_t u32EntityID, string strLuaFuncName, uint32_t u32IntervalTick, uint16_t u16TotalTimes) :
 m_u32EntityID(u32EntityID), m_strLuaFuncName(strLuaFuncName), m_u32IntervalTick(u32IntervalTick), m_u16TotalTimes(u16TotalTimes)
{
}

 template < class T1, class T2 >
CLuaTimer< T1, T2 >::CLuaTimer(const CLuaTimer& rOther)
{
    operator = (rOther);
}

template < class T1, class T2 >
CLuaTimer< T1, T2 >::~CLuaTimer(void)
{
}

template < class T1, class T2 >
CLuaTimer< T1, T2 >& CLuaTimer< T1, T2 >::operator = (const CLuaTimer< T1, T2 >& rOther)
{
    if (this != &rOther)
    {
        m_u16TotalTimes     = rOther.m_u16TotalTimes;
        m_u32IntervalTick   = rOther.m_u32IntervalTick;
        m_u32EntityID       = rOther.m_u32EntityID;
        m_strLuaFuncName    = rOther.m_strLuaFuncName;
        m_Param1            = rOther.m_Param1;
        m_Param2            = rOther.m_Param2;

        CTimerActionBase::operator =(rOther);
    }
    return *this;
}

template < class T1, class T2 >
CTimerActionBase* CLuaTimer< T1, T2 >::Clone() const
{
    return new CLuaTimer(*this);
}

template < class T1, class T2 >
uint64_t CLuaTimer< T1, T2 >::GetNextTick()
{
    if (m_u16TotalTimes > 0 && m_u16TotalTimes == m_u32ActionCount) return 0;
    return _GetTickCount64() + m_u32IntervalTick;
}

template < class T1, class T2 >
bool CLuaTimer< T1, T2 >::operator()()
{
    lua_State* lua          = GetWorld()->GetLuaState();
    if (!lua) return false;

    CEntityParent* pEntity  = GetWorld()->GetEntity(m_u32EntityID);
    if (!pEntity) return false;

    lua_pushnumber(lua, m_u64ActionID);
    lua_pushinteger(lua, m_u32ActionCount);
    _Lua_PushParam(lua, m_Param1);
    _Lua_PushParam(lua, m_Param2);
    const int nExtParamCount = 2;
    EntityMethodCall(lua, pEntity, m_strLuaFuncName.c_str(), 2 + nExtParamCount, 0);
    ClearLuaStack(lua);
    return true;
}

template < class T1, class T2 >
void CLuaTimer< T1, T2 >::InitParam(T1 param1, T2 param2)
{
    m_Param1 = param1;
    m_Param2 = param2;
}


//////////////////////////////////////////////////////////////////////////

template < class T1, class T2, uint8_t u8RemainParamCount >
class CLuaTimerFactory;

template < class T1, class T2 >
class CLuaTimerFactory< T1, T2, 2 >
{
public:
    static CTimerActionBase& Get(stLuaTimerData& rData, T1 arg1, T2 arg2)
    {
        int nParam = rData.nLuaParamStackStart++;
        if (nParam > lua_gettop(rData.lua)) return CLuaTimerFactory< T1, T2, 1 >::Get(rData, arg1, arg2);

        switch (lua_type(rData.lua, nParam))
        {
        case LUA_TBOOLEAN:
            {
                int arg1_real = lua_toboolean(rData.lua, nParam);
                return CLuaTimerFactory< decltype(arg1_real), T2, 1 >::Get(rData, arg1_real, arg2);
            }
        case LUA_TNUMBER:
            {
                double arg1_real = lua_tonumber(rData.lua, nParam);
                return CLuaTimerFactory< decltype(arg1_real), T2, 1 >::Get(rData, arg1_real, arg2);
            }
        case LUA_TSTRING:
            {
                string arg1_real = lua_tostring(rData.lua, nParam);
                return CLuaTimerFactory< decltype(arg1_real), T2, 1 >::Get(rData, arg1_real, arg2);
            }
        case LUA_TTABLE:
            {
                stLuaTable arg1_real;
                LuaPickleToString(rData.lua, nParam, arg1_real.strLuaTable);
                return CLuaTimerFactory< decltype(arg1_real), T2, 1 >::Get(rData, arg1_real, arg2);
            }
        }

        return CLuaTimerFactory< T1, T2, 1 >::Get(rData, arg1, arg2);
    }
};

template < class T1, class T2 >
class CLuaTimerFactory< T1, T2, 1 >
{
public:
    static CTimerActionBase& Get(stLuaTimerData& rData, T1 arg1, T2 arg2)
    {
        int nParam = rData.nLuaParamStackStart++;
        if (nParam > lua_gettop(rData.lua)) return CLuaTimerFactory< T1, T2, 0 >::Get(rData, arg1, arg2);

        switch (lua_type(rData.lua, nParam))
        {
        case LUA_TBOOLEAN:
            {
                int arg2_real = lua_toboolean(rData.lua, nParam);
                return CLuaTimerFactory< T1, decltype(arg2_real), 0 >::Get(rData, arg1, arg2_real);
            }
        case LUA_TNUMBER:
            {
                double arg2_real = lua_tonumber(rData.lua, nParam);
                return CLuaTimerFactory< T1, decltype(arg2_real), 0 >::Get(rData, arg1, arg2_real);
            }
        case LUA_TSTRING:
            {
                string arg2_real = lua_tostring(rData.lua, nParam);
                return CLuaTimerFactory< T1, decltype(arg2_real), 0 >::Get(rData, arg1, arg2_real);
            }
        case LUA_TTABLE:
            {
                stLuaTable arg2_real;
                LuaPickleToString(rData.lua, nParam, arg2_real.strLuaTable);
                return CLuaTimerFactory< T1, decltype(arg2_real), 0 >::Get(rData, arg1, arg2_real);
            }
        }

        return CLuaTimerFactory< T1, T2, 0 >::Get(rData, arg1, arg2);
    }
};

template < class T1, class T2 >
class CLuaTimerFactory< T1, T2, 0 >
{
public:
    static CTimerActionBase& Get(stLuaTimerData& rData, T1 arg1, T2 arg2)
    {
        //static CLuaTimer< T1, T2 > s_data(rData.u32EntityID, rData.strLuaFuncName, rData.u32IntervalTick, rData.u16TotalTimes);
        //s_data.InitParam(arg1, arg2);
        CLuaTimer< T1, T2 > data(rData.u32EntityID, rData.strLuaFuncName, rData.u32IntervalTick, rData.u16TotalTimes);
        data.InitParam(arg1, arg2);
        static CLuaTimer< T1, T2 > s_data(rData.u32EntityID, rData.strLuaFuncName, rData.u32IntervalTick, rData.u16TotalTimes);
        s_data = data;
        return s_data;
    }
};

CTimerActionBase& LuaTimerFactory(stLuaTimerData& rData)
{
    return CLuaTimerFactory< CEmptyClass, CEmptyClass, 2 >::Get(rData, CEmptyClass(), CEmptyClass());
}



MOGO_END







