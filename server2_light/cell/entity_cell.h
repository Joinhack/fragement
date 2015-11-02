#ifndef __ENTITY_CELL_HEAD__
#define __ENTITY_CELL_HEAD__

#include "entity.h"
#include "aoi.h"
//#include "event.h"

namespace mogo
{

    class CSpace;

    class CEntityCell : public CEntityParent
    {
        public:
            CEntityCell(TENTITYTYPE etype, TENTITYID nid);
            ~CEntityCell();

        public:
            int init(lua_State* L);

        public:
            //记录base的mailbox
            void AddBaseMailbox(int32_t n, uint16_t nBaseSrvId);

        public:
            //获取spaceId
            int lGetSpaceId(lua_State*);
            int lTelePort(lua_State*);
            int lSetVisiable(lua_State*);
            int lSetSpeed(lua_State*);
            int lProcessMove(lua_State*);
            int lProcessPull(lua_State*);
            int lStopMove(lua_State*);
            int lGetXY(lua_State*);
            int lSetXY(lua_State*);
            int lSetFace(lua_State*);
            int lGetFace(lua_State*);
            int lGetPackFace(lua_State*);
            int lGetMovePointStraight(lua_State*);
            int lGetNextEntityId(lua_State*);
            int lUpdateEntityMove(lua_State*);

            //AOI广播,Lua调用参数:广播是否包括自己(布尔值),客户端RPC函数名(字符串),[RPC函数可选参数1],[RPC函数可选参数2]...返回:无
            int lBroadcastAOI(lua_State*);

            //获取AOI列表,Lua调用参数:指定半径范围内的列表(若为0表示不限距离)，返回:AOI列表
            int lGetAOI(lua_State*);
			
			//判断一个实例是否在AOI列表里,Lua调用参数:另一个实体对象的ID,返回:真代表不在AOI里，假代表在AOI里
			int lIsInAOI(lua_State*);

            //获取与另一个实体对象的距离,Lua调用参数:另一个实体对象的ID,返回:距离,若为负数则代表失败(招不到另一个实体对象)
            int lGetDistance(lua_State*);

            //激活该entity所在的space，使它进行AOI计算
            int lActive(lua_State*);

            //反激活entity所在的space，使它不进行AOI计算
            int lInActive(lua_State*);

            //把entity放进一个指定的space
            int lAddToSpace(lua_State*);

            //把entity从一个指定的space拿出来
            int lDelFromSpace(lua_State*);

            //调用所有clients的rpc方法
            void AllclientsRpc(const char* pszFunc, lua_State* L);
            void OwnclientRpc(const char* pszFunc, lua_State* L);
            //调用客户端rpc
            CPluto* ClientRpc(CPluto* u, const char* pszFunc, lua_State* L);

        public:
            void SetVisiable(uint8_t n);

        public:
            //将带client标记的属性打包至pluto,注意:CEntityBase有一个类似的同名方法
            void PickleClientToPluto(CPluto& u);
            //将带other_clients标记的属性打包至pluto
            void PickleOtherClientToPluto(CPluto& u);
            //将带cell标记的属性打包至pluto
            void PickleCellToPluto(CPluto& u);
            //同步带base标记的属性
            void SyncBaseAndCellProp(int32_t nPropId, const VOBJECT& v);
            //获取base的server_id
            int GetBaseServerId();
            //同步带client标记的属性给客户端
            void SyncClientProp(int32_t nPropId, const VOBJECT& v);
            //打包aoi内所有entities
            void PickleAoiEntities(CPluto& u);
            //客户端移动请求
            //void OnClientMoveReq(list<std::pair<int16_t, int16_t>*>* lsPosPairs);
#ifdef __FACE
            void OnClientMoveReq(uint8_t face, int16_t x, int16_t y);
#else
            void OnClientMoveReq(int16_t x, int16_t y);
#endif
            //将某个客户端的移动请求转发给aoi内其他玩家
            CPluto* SendOtherClientMoveReq(CPluto* u, TENTITYID eid, list<std::pair<uint16_t, uint16_t>*>& lsPosPairs);
            void OnLoseClient();
            bool OnMoveTick();

#ifdef __FACE
            //将entity的坐标同步给aoi范围内的玩家
            CPluto* SendOtherEntityPos(CPluto* u, TENTITYID eid, uint8_t newFace, int16_t x, int16_t y, \
                pluto_msgid_t selfCPlutoHead, pluto_msgid_t otherCPlutoHead);
#else
            //将entity的坐标同步给aoi范围内的玩家
            CPluto* SendOtherEntityPos(CPluto* u, TENTITYID eid, int16_t x, int16_t y, uint32_t checkFlag, \
                pluto_msgid_t selfCPlutoHead, pluto_msgid_t otherCPlutoHead);
#endif

            //当某个属性变更时,是否要同步给other_clients
            void OnAttriModified(const string& strPropName, VOBJECT* v);
            //将其他entity的属性变化发给自己的客户端
            CPluto* SyncOtherEntityAttri(CPluto* u, TENTITYID eid, uint16_t nPropId, VOBJECT* v);
            void SyncOwnEntityAttri(uint16_t nPropId, VOBJECT* v);

#ifdef __OPTIMIZE_PROP_SYN
            void DoSyncClientProp();
#endif

            bool BroadcastPos();

        public:
            inline TSPACEID GetSpaceID() const
            {
                return m_spaceId;
            }

            inline void SetSpaceID(TSPACEID sid)
            {
                m_spaceId = sid;
            }

            CSpace* GetMySpace();

        public:
            //有新的entity进入aoi
            void OnEnterAoi(CSpace* sp, TENTITYID eid);
            //检查关注者是否离开了aoi
            bool CheckLeaveAoi();
            //有entity离开了aoi
            void OnLeaveAoi(TENTITYID eid, bool bIsNest);
            //清除所有的关注者
            void ClearAoiEntities();
            //清除路点
            void ClearPosPairs();
            //设置移动过标记
            inline void SetMoved()
            {
                m_bMoved = true;
            }
            //设置路点走完后是否应该通知lua
            inline void SetAfterMoveNotifyLua(bool value)
            {
                m_bAfterMoveNotifyLua = value;
            }

        protected:
            uint16_t GetMailboxId();
            //如果有客户端则获取并返回base的mailbox
            CMailBox* GetBaseMailboxIfClient();

        public:
            inline list<std::pair<int16_t, int16_t>*>* GetLeftPosPairs() const
            {
                return m_lsPosPairs;
            }

#ifdef __AOI_PRUNING
            bool AddInFollowers(TENTITYID eid);
            bool RemoveInFollower(TENTITYID eid);
            bool AddInObservers(TENTITYID eid);
            bool IsObserversFull();
#endif


        protected:
            TSPACEID m_spaceId;

            //AOI模块实际计算出的关注列表
            set<TENTITYID> m_entitiesIds;

            ////考虑到网络问题而裁剪出来的实际广播用的关注列表
            //set<TENTITYID> m_observersIds;

#ifdef __AOI_PRUNING
            set<TENTITYID> m_followers;    //被关注者列表，意思是被该vector里面的人关注，相当于粉丝列表(默认30人)
            set<TENTITYID> m_observers;    //关注者列表，意思是成功关注的人(默认15人)
#endif

            uint16_t m_nBaseSvrId;

#ifdef __SPEED_CHECK
            uint32_t m_nLastMoveTime;      //上一次移动的时间戳
#endif // __SPEED_CHECK


        public:
            position_t m_pos[2];                                    //位置坐标

            uint8_t face;                                           //朝向

            list<std::pair<int16_t, int16_t>*>* m_lsPosPairs;       //路点坐标
            uint16_t m_nSpeed;                                      //速度,每一个移动tick里可以移动的距离
            //bool m_bCanMove;                                      //是否可以移动标记
            bool m_bBroadcast;                                      //本次tick是否需要广播给关注者
            bool m_bMoved;                                          //本次tick是否发生移动行为

            int lastMoveTime;                                       //上一次移动时间
            uint8_t badMoveTimes;                                   //移动不良记录的次数

            bool m_bAfterMoveNotifyLua;                             //路点走完后是否应该通知lua

#ifdef __TEST
            uint8_t movePackets;
            uint32_t sumMoveCost;
#endif

        private:
            CEntityCell(const CEntityCell&);
            CEntityCell& operator=(const CEntityCell&);

    };



}

#endif
