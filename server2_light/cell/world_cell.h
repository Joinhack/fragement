#ifndef __WORLD_CELL_HEAD
#define __WORLD_CELL_HEAD

#include "world.h"
#include "space.h"
#include "entity_cell.h"
//#include "event.h"

namespace mogo
{
    class CWorldCell : public world
    {
        public:
            CWorldCell();
            ~CWorldCell();

        public:
            int init(const char* pszEtcFile);
            void Clear();
            int OpenMogoLib(lua_State* L);
            CSpace* CreateNewSpace();

        public:
            int FromRpcCall(CPluto& u);
            bool IsCanAcceptedClient(const string& strClientAddr);

        private:
            int FromLuaCellRpcCall(T_VECTOR_OBJECT* p);
            int DebugLuaCode(T_VECTOR_OBJECT* p);
            int CreateCellViaMycell(T_VECTOR_OBJECT* p);
            int OnEntityAttriSync(T_VECTOR_OBJECT* p);
            int DestroyCellEntity(T_VECTOR_OBJECT* p);
            int PickleClientAttris(T_VECTOR_OBJECT* p);
            int PickleAoiEntities(T_VECTOR_OBJECT* p);
            int OnClientMoveReq(T_VECTOR_OBJECT* p);
            int OnLoseClient(T_VECTOR_OBJECT* p);
            int OnTimeMove(T_VECTOR_OBJECT* p);
            int SetCellVisiable(T_VECTOR_OBJECT* p);
            int CreateCellInNewSpace(T_VECTOR_OBJECT* p, bool insertAOI=false);
            int OnClientOthersMoveReq(T_VECTOR_OBJECT* p);

        public:
            inline TSPACEID GetNextSpaceId()
            {
                return ++m_nSpaceSeq;
            }

        public:
            bool AddEntity(CEntityCell* );
            bool DelEntity(CEntityCell*);
            CEntityParent* GetEntity(TENTITYID id);

            bool ActiveSpace(TSPACEID id);
            bool InActiveSpace(TSPACEID id);

        public:
            CSpace* GetSpace(TSPACEID id);

#ifdef __AOI_PRUNING
            inline uint16_t GetMaxObserverCount()
            {
                return this->m_nMaxObserverCount;
            }

            inline uint16_t GetMaxFollowerCount()
            {
                return this->m_nMaxFollowerCount;
            }
#endif

        private:
            //创建cell失败给base的消息
            void CreateCellFailed(CEntityMailbox& emb, uint8_t err_id);
            bool UnpickleCellProps(uint16_t etype, charArrayDummy& ad, map<string, VOBJECT*>& cellProps);

        protected:
            void InitEntityCall();

        private:
            map<TSPACEID, CSpace*> m_spaces;

            map<TSPACEID, CSpace*> m_idleSpaces;

            CEntityMgr<CEntityCell> m_enMgr;
            TSPACEID m_nSpaceSeq;

            uint8_t moveTimes;

            CWorldCell(const CWorldCell&);
            CWorldCell& operator=(const CEntityCell&);


#ifdef __TEST
            uint32_t sumMoveCost;
            uint8_t movePackets;
#endif

#ifdef __AOI_PRUNING
            uint16_t m_nMaxObserverCount;
            uint16_t m_nMaxFollowerCount;
#endif
    };


}



#endif
