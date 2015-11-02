#ifndef __TIMER_HEAD__
#define __TIMER_HEAD__

#include <vector>
#include <list>
#include <queue>
#include <iostream>
#include "type_mogo.h"


namespace mogo
{

    enum
    {
        TIMER_TICK_COUNT_PER_SECOND = 10,     //1秒=n tick
        TIMER_INTERVAL_USEC = 1000000 / TIMER_TICK_COUNT_PER_SECOND,   //定时器间隔*微秒 = (1秒/每秒的tick数)
        TIME_SAVE_TICKS = 10 * TIMER_TICK_COUNT_PER_SECOND,             //每5秒触发一次定时存盘
        TIME_ENTITY_MOVE = 1,              //移动间隔
        //TIME_ENTITY_AOI_REFRESH = 10,      //刷新entity的AOI列表间隔
    };

    using namespace std;


    struct TimerData
    {
        TimerData(unsigned int nStart, int nInterval, unsigned int nTimerId,
                  TENTITYID nId, int nUserData)
            : m_unNextTick(nStart), m_nInterval(nInterval), m_nTimerId(nTimerId),
              m_nEntityId(nId), m_nUserData(nUserData)
        {
        }

        unsigned int m_nTimerId;
        int m_nInterval;
        unsigned long m_unNextTick;
        TENTITYID m_nEntityId;
        int m_nUserData;
    };

    class world;

    class CTimerHeap
    {
        public:
            CTimerHeap();
            ~CTimerHeap();

        public:
            int AddTimer(unsigned int nStart, int nInterval, TENTITYID nId, int nUserData);
            void DelTimer(unsigned int nTimerId);
            void OnTick(lua_State* L, world& the_world, uint32_t unTick);
            //void onTick(uint32_t unTick);

        private:
            bool OnEntityTick(lua_State* L, world& the_world, TimerData* p);

        private:
            struct TimerDataOp
            {
                bool operator()(TimerData* p1, TimerData* p2)
                {
                    return p1->m_unNextTick > p2->m_unNextTick;
                }
            };

        private:
            uint32_t m_nNextTimerId;
            uint32_t m_unTick;
            priority_queue<TimerData*, vector<TimerData*>, TimerDataOp> m_queue;
            set<uint32_t> m_timerId4Del;

    };


    //----------------------------------------

    class CTimerActionBase
    {
    protected:
        uint64_t    m_u64ActionID;
        uint32_t    m_u32ActionCount;

    protected:
        CTimerActionBase() : m_u64ActionID(0), m_u32ActionCount(0) {};

    public:
        virtual ~CTimerActionBase() {};

        void    InitActionID(uint64_t u64ActionID)
        {
            m_u64ActionID = u64ActionID;
        }

        uint64_t GetActionID() const
        {
            return m_u64ActionID;
        }

        void    IncreaseCount()
        {
            m_u32ActionCount++;
        }

    public:
        virtual CTimerActionBase& operator = (const CTimerActionBase& rOther);
        virtual CTimerActionBase*   Clone() const  = 0;
        virtual uint64_t            GetNextTick()  = 0;
        virtual bool                operator()()   = 0;
    };

    class CTimerActionQueue
    {
    private:
        struct stActionData
        {
            uint64_t            u64ActionTick;
            CTimerActionBase*   pAction;

            stActionData();
            stActionData(const stActionData& rOther);
            stActionData(const CTimerActionBase& rAction);
            ~stActionData();

            stActionData& operator = (const stActionData& rOther);

            bool operator < (const stActionData& rOther) const
            {
                return u64ActionTick < rOther.u64ActionTick;
            }
        };
        typedef multimap< uint64_t, stActionData >              mmapTickToActionType;
        typedef map< uint64_t, mmapTickToActionType::iterator > mapActionToQueueIterType;

    public:
        mmapTickToActionType     m_mmapQueue;
        mapActionToQueueIterType m_mapActionToQueueIter;

    private:
        uint64_t m_u64ActionIDFactory;

    public:
        CTimerActionQueue();
        ~CTimerActionQueue();

    public:
        uint64_t    AddAction(CTimerActionBase& rAction);
        bool        DelAction(uint64_t u64ActionID);
        bool        HasAction(uint64_t u64ActionID);
        void        OnAction();
    };

}


#endif

