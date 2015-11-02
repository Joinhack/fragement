#ifndef __TIMER_ACTION_HEAD__
#define __TIMER_ACTION_HEAD__


#include "global_config.h"
#include "timer.h"


MOGO_BEGIN


template < class T1, class T2 >
class CLuaTimer : public CTimerActionBase
{
private:
    uint16_t    m_u16TotalTimes;    //总次数
    uint32_t    m_u32IntervalTick;  //间隔毫秒
    uint32_t    m_u32EntityID;      //对象ID
    string      m_strLuaFuncName;   //Lua下的对象成员函数名称
    T1          m_Param1;           //参数1
    T2          m_Param2;           //参数2

public:
    CLuaTimer(uint32_t u32EntityID, string strLuaFuncName, uint32_t u32IntervalTick, uint16_t u16TotalTimes);
    CLuaTimer(const CLuaTimer& rOther);
    ~CLuaTimer(void);

    void    InitParam(T1 param1, T2 param2);

public:
    virtual CLuaTimer& operator = (const CLuaTimer& rOther);
    virtual CTimerActionBase*   Clone() const;
    virtual uint64_t            GetNextTick();
    virtual bool                operator()();
};


//////////////////////////////////////////////////////////////////////////

struct CEmptyClass{};

struct stLuaTimerData
{
    lua_State*  lua;                    //lua对象
    int         nLuaParamStackStart;    //首个扩展参数在栈上的位置(5)
    uint32_t    u32EntityID;            //实体ID
    string      strLuaFuncName;         //实体成员函数名
    uint32_t    u32IntervalTick;        //定时器间隔时间
    uint16_t    u16TotalTimes;          //定时器触发次数，若为0则代表无限次
};

extern CTimerActionBase& LuaTimerFactory(stLuaTimerData& rData);


MOGO_END


#endif


