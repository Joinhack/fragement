/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：timer
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.5
// 模块描述：定时器
//----------------------------------------------------------------*/

#include "timer.h"
#include "entity.h"
#include "world_select.h"

namespace mogo
{


/////////////////////////////////////////////////////////////////////////////////////

CTimerHeap::CTimerHeap(): m_nNextTimerId(0), m_unTick(0)
{
}


CTimerHeap::~CTimerHeap()
{
    while(!m_queue.empty())
    {
        TimerData* p = m_queue.top();
        delete p;
        m_queue.pop();
    }
}

int CTimerHeap::AddTimer(unsigned int nStart, int nInterval, 
                         TENTITYID nId, int nUserData)
{
	//起始时间会有一个tick的误差,tick精度越高,误差越低
    TimerData* p = new TimerData(m_unTick + 1 + nStart * TIMER_TICK_COUNT_PER_SECOND, 
            nInterval * TIMER_TICK_COUNT_PER_SECOND, ++m_nNextTimerId, nId, nUserData);
    m_queue.push(p);
    return p->m_nTimerId;
}

//void CTimerHeap::onTick(uint32_t unTick)
//{
//    world& the_world = *GetWorld();
//    lua_State* L = the_world.getLuaState();
//    onTick(L, the_world);
//}
/*
void CTimerHeap::OnTick(lua_State* L, world& the_world, uint32_t unTick)
{
    ++m_unTick;
    //cout << "onTick:" << m_unTick << endl;

    while(!m_queue.empty())
    {
        TimerData* p = m_queue.top();
        if(m_unTick >= p->m_unNextTick )
        {
			//LogDebug("onTick", "%ld_%ld", m_unTick, p->m_unNextTick);
			m_queue.pop();
            if(OnEntityTick(L, the_world, p))
			{
				if(p->m_nInterval > 0)
				{
					p->m_unNextTick += p->m_nInterval;
					m_queue.push(p);
				}
				else
				{
					delete p;
				}
			}
            else
            {
                delete p;
            }
        }
        else
        {
            break;
        }
    }
}
*/
/*
bool CTimerHeap::OnEntityTick(lua_State* L, world& the_world, TimerData* p)
{
    //cout << p->m_nTimerId << ',' << p->m_nInterval << ','  << p->m_unNextTick << endl;
    
    CEntityParent* e = the_world.GetEntity(p->m_nEntityId);
	if(e)
	{
		//cout << "gettop:" << lua_gettop(L) << endl;
		lua_pushinteger(L, p->m_nTimerId);
		lua_pushinteger(L, p->m_nUserData);
		int nRet = EntityMethodCall(L, e, "onTimer", 2, 0);
		lua_pop(L, nRet);
		//cout << "gettop:" << lua_gettop(L) << endl;
		return true;
	}
	else
	{
		return false;
	}    
}
*/

}


