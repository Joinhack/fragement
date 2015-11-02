#ifndef __ENTITY_BASE_HEAD__
#define __ENTITY_BASE_HEAD__

#include "entity.h"
#include "memory_pool.h"

namespace mogo
{

    enum ECELLSTATE
    {
        E_HASNT_CELL       = 0,     //no cell
        E_CELL_IN_CREATING = 1,     //cell is  creating
        E_CELL_CREATED     = 2,     //cell has created
        E_CELL_IN_DESTROYING = 3,   //cell is destroying
    };
    class CEntityBase : public CEntityParent
    {
        public:
            CEntityBase(TENTITYTYPE etype, TENTITYID nid);
            ~CEntityBase();

            //void * operator new(size_t size, void *ptr);

            //void operator delete(void* p, size_t size);

            //static void NewMemPool()
            //{
            //    expandMemoryPool();
            //}

            //static void DeleteMemPool();

        public:
            int init(lua_State* L);

        public:
            //record cell mailbox
            void AddCellMailbox(int32_t n, uint16_t nCellSvrId);
            void RemoveCellMailbox();
            // get cell server_id
            int GetCellServerId();
            //get client fd
            int GetClientFd();

            inline void SetClientFd(int32_t fd)
            {
                this->m_ClientFd = fd;
            }

        public:
            int lRegisterGlobally(lua_State* L);
            int lRegisterCrossServer(lua_State*);

            int lGiveClientTo(lua_State* L);
            //through the loginapp to create account, and then loginapp notity client to connect baseapp.
            int lNotifyClientToAttach(lua_State* L);
            //account创建以后，被人顶号时，通过loginapp告诉新客户端，断开连接
            int lNotifyClientMultiLogin(lua_State* L);
            //create new space and create cell part of entity.
            int lCreateInNewSpace(lua_State* L);
            //accourding to a mb, create a new cell entity
            int lCreateCellEntity(lua_State* L);
            int lHasCell(lua_State* L);
            //destory the part of cell
            int lDestroyCellEntity(lua_State* L);
            int lSetCellVisiable(lua_State*);
            int lNotifyDbDestroyAccountCache(lua_State*);
            //直接指定回调方法名的数据库操作接口
            int lTableSelectSql(lua_State*);
            int lTableInsertSql(lua_State*);
            int lTableExcuteSql(lua_State*);
            //使用回调id的数据库操作接口
            int lTable2Select(lua_State*);
            int lTable2Insert(lua_State*);
            int lTable2Excute(lua_State*);
            int lKickedOut(lua_State*);
            int lHasClient(lua_State* L);
            int lGetIPAddr(lua_State* L);
            //int lCollector(lua_State*);
        public:
            int GiveClient(lua_State* L, int fd);
            void RemoveClient();

        public:
            bool PickleClientToPluto(CPluto& u);
            //synchronize the attribution between cell and base
            void SyncBaseAndCellProp(int32_t nPropId, const VOBJECT& v);
            //notify cell to package client attributoins to client
            void NotifyCellSyncClientAttris();
            void UnpickleCellDataFromPluto(CPluto& u);

#ifdef __OPTIMIZE_PROP_SYN
            void DoSyncClientProp();
#endif

#ifdef __PLUTO_ORDER
            inline uint16_t GetPlutoOrder()
            {
                return m_PlutoOrder;
            }

            inline void IncreasePlutoOrder()
            {
                enum {MAX_PLUTO_ORDER = 1<<16 - 1};
                if ((m_PlutoOrder + 1) > MAX_PLUTO_ORDER)
                {
                    m_PlutoOrder = 0;
                }
                else
                {
                    m_PlutoOrder++;
                }
            }
#endif

       public:
            inline void SetCellState(ECELLSTATE s)
            {
                m_nCellState = s;
            }

#ifdef __RELOGIN
            inline const string& GetClientReLoginKey()
            {
                return s_clientReLoginKey;
            }
#endif

            //saved the syschronized aoordinate data from cell to m_data
            void SetMapXY(int16_t x, int16_t y);

        protected:
            uint16_t GetMailboxId();

        private:
            //package base/cell common data attributions
            bool PickleCellPropsToPluto(CPluto& u);

        private:
            uint16_t m_nCellSvrId;
            ECELLSTATE m_nCellState;

            //base的entity，当它没有cell部分时，会把cell的属性存到这里
            map<string, VOBJECT*> m_cellData;

            int32_t m_ClientFd;

            CEntityBase(const CEntityBase&);
            CEntityBase& operator=(const CEntityBase&);

#ifdef __PLUTO_ORDER
            uint16_t m_PlutoOrder;
#endif

#ifdef __RELOGIN
            string s_clientReLoginKey;
#endif

    };

}

#endif

