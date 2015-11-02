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
#include "../base/entity_base.h"
//#include "entity.h"
#include "../base/lua_base.h"
#include "../base/world_base.h"
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

    void CTimerHeap::DelTimer(uint32_t nTimerId)
    {
        //TimerData* p = NULL;
        //while (!m_queue.empty())
        //{
        //    p = m_queue.top();
        //    m_queue.pop();
        //    if (p && p->m_nTimerId != nTimerId)
        //    {
        //        m_queue.push(p);
        //    }
        //}
        m_timerId4Del.insert(nTimerId);
    }

    //void CTimerHeap::onTick(uint32_t unTick)
    //{
    //    world& the_world = *GetWorld();
    //    lua_State* L = the_world.getLuaState();
    //    onTick(L, the_world);
    //}

    void CTimerHeap::OnTick(lua_State* L, world& the_world, uint32_t unTick)
    {
        ++m_unTick;
        //cout << "onTick:" << m_unTick << endl;

        while(!m_queue.empty())
        {
            TimerData* p = m_queue.top();

            //检查timer是否需要删除
            set<uint32_t>::iterator iter = m_timerId4Del.find(p->m_nTimerId);
            if(iter != m_timerId4Del.end())
            {
                m_queue.pop();
                delete p;
                m_timerId4Del.erase(iter);
                continue;
            }

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


    //////////////////////////////////////////////////////////////////////////
    
    CTimerActionBase& CTimerActionBase::operator = (const CTimerActionBase& rOther)
    {
        if (this != &rOther)
        {
            m_u64ActionID       = rOther.m_u64ActionID;
            m_u32ActionCount    = rOther.m_u32ActionCount;
        }
        return *this;
    }

    //////////////////////////////////////////////////////////////////////////

    CTimerActionQueue::stActionData::stActionData()
    {
        pAction         = NULL;
        u64ActionTick   = 0;
    }

    CTimerActionQueue::stActionData::stActionData(const CTimerActionBase& rAction)
    {
        assert(rAction.GetActionID());              //传入参数有误

        pAction         = rAction.Clone();
        u64ActionTick   = pAction->GetNextTick();
    }

    CTimerActionQueue::stActionData::stActionData(const stActionData& rOther)
    {
        pAction = NULL;
        operator = (rOther);
    }


    CTimerActionQueue::stActionData::~stActionData()
    {
        delete pAction;
    }

    CTimerActionQueue::stActionData& CTimerActionQueue::stActionData::operator = (const CTimerActionQueue::stActionData& rOther)
    {
        if (this != &rOther)
        {
            delete pAction;
            pAction = rOther.pAction ? rOther.pAction->Clone() : NULL;
            u64ActionTick = rOther.u64ActionTick;
        }
        return *this;
    }


    //////////////////////////////////////////////////////////////////////////
    
    CTimerActionQueue::CTimerActionQueue()
    {
        m_u64ActionIDFactory = 0;
    }

    CTimerActionQueue::~CTimerActionQueue()
    {
    }

    uint64_t CTimerActionQueue::AddAction(CTimerActionBase& rAction)
    {
        rAction.InitActionID(++m_u64ActionIDFactory);

        stActionData data(rAction);
        mmapTickToActionType::iterator iter = m_mmapQueue.insert(mmapTickToActionType::value_type(data.u64ActionTick, data));
        std::pair<mapActionToQueueIterType::iterator, bool> pair = m_mapActionToQueueIter.insert(mapActionToQueueIterType::value_type(m_u64ActionIDFactory, iter));
        if (pair.second == false)
        {
            assert(false);                  //此类设计有BUG
            m_mmapQueue.erase(iter);
            return 0;
        }

        return m_u64ActionIDFactory;
    }

    bool CTimerActionQueue::DelAction(uint64_t u64ActionID)
    {
        mapActionToQueueIterType::iterator iter = m_mapActionToQueueIter.find(u64ActionID);
        if (iter == m_mapActionToQueueIter.end()) return false;

        m_mmapQueue.erase(iter->second);
        m_mapActionToQueueIter.erase(iter);
        return true;
    }

    bool CTimerActionQueue::HasAction(uint64_t u64ActionID)
    {
        return (m_mapActionToQueueIter.find(u64ActionID) != m_mapActionToQueueIter.end());
    }

    void CTimerActionQueue::OnAction()
    {
        while (!m_mmapQueue.empty())
        {
            mmapTickToActionType::iterator iter = m_mmapQueue.begin();
            if (iter->first > _GetTickCount64()) break;

            //需要考虑执行行为时删除定时器的情况,要先复制
            stActionData actionData = iter->second;
            uint64_t u64ActionID    = actionData.pAction->GetActionID();
            actionData.pAction->IncreaseCount();

            //执行行为
            bool bSuccess = (*actionData.pAction)();

            //检查在执行时当前行为定时器是否已被删除
            if (m_mapActionToQueueIter.find(u64ActionID) == m_mapActionToQueueIter.end()) continue;
            m_mapActionToQueueIter.erase(u64ActionID);
            m_mmapQueue.erase(iter);

            if (bSuccess)
            {//重新加入定时器
                actionData.u64ActionTick = actionData.pAction->GetNextTick();
                if (actionData.u64ActionTick > 0)
                {
                    mmapTickToActionType::iterator iter = m_mmapQueue.insert(mmapTickToActionType::value_type(actionData.u64ActionTick, actionData));
                    std::pair<mapActionToQueueIterType::iterator, bool> pair = m_mapActionToQueueIter.insert(mapActionToQueueIterType::value_type(u64ActionID, iter));
                    if (pair.second == false)
                    {
                        assert(false);                  //此类设计有BUG
                        m_mmapQueue.erase(iter);
                    }
                }
            }
        }
    }


}


