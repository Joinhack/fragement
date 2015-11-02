#ifndef __WORLD_BASE_HEAD__
#define __WORLD_BASE_HEAD__

#include "world.h"
#include "entity_mgr.h"
#include "entity_base.h"


namespace mogo
{


    struct _SClientLoginKey
    {
        time_t m_time;
        string m_key;
        TENTITYID m_eid;
    };

#ifdef __RELOGIN
    struct _SClientReLoginKey
    {
        time_t m_time;       //客户端连接到服务器的时间
        time_t m_offtime;    //客户端跟服务器断开的时间
        string m_key;
        TENTITYID m_eid;
    };
#endif

    class CWorldBase : public world
    {
        public:
            CWorldBase();
            ~CWorldBase();

        public:
            int init(const char* pszEtcFile);

            void Clear();
            int OpenMogoLib(lua_State* L);
            bool AddEntity(CEntityBase* );
            bool DelEntity(CEntityBase*);
            CEntityParent* GetEntity(TENTITYID id);

            //int iter_entities(lua_State* L);

            //map<TENTITYID, CEntityBase*>::const_iterator* getEnMgrBegin()
            //{
            //    return &(m_enMgr.entities().begin());
            //}

        public:
            //remove fd from list
            void KickOffFd(int fd);

        public:
            int FromRpcCall(CPluto& u);

        private:
            int RegisterGloballyCallback(T_VECTOR_OBJECT* p);
            int AddGlobalBase(T_VECTOR_OBJECT* p);
            int InsertEntityCallback(T_VECTOR_OBJECT* p);
            int SelectEntityCallback(T_VECTOR_OBJECT* p);
            int LookupEntityCallback(T_VECTOR_OBJECT* p);
            int ClientLogin(T_VECTOR_OBJECT* p);
            int DebugLuaCode(T_VECTOR_OBJECT* p);
            int EntityMultilogin(T_VECTOR_OBJECT* p);
            int LoadAllAvatar(T_VECTOR_OBJECT* p);
            int LoadEntitiesOfType(T_VECTOR_OBJECT* p);
            int LoadEntitiesEnd(T_VECTOR_OBJECT* p);
            int OnGetCell(T_VECTOR_OBJECT* p);
            int OnLoseCell(T_VECTOR_OBJECT* p);
            int CreateCellViaMyCell(T_VECTOR_OBJECT* p);
            int OnCreateCellFailed(T_VECTOR_OBJECT* p);
            int OnEntityAttriSync(T_VECTOR_OBJECT* p);
            int CreateBaseFromCWMD(T_VECTOR_OBJECT* p);
            int SetBaseData(T_VECTOR_OBJECT* p);
            int DelBaseData(T_VECTOR_OBJECT* p);
            int ClientRpcViaBase(T_VECTOR_OBJECT* p);
            int ClientMsgViaBase(T_VECTOR_OBJECT* p);
            int OnRedisHashLoad(T_VECTOR_OBJECT* p);
            int TimeSave(T_VECTOR_OBJECT* p);
            int OnAvatarPosSync(T_VECTOR_OBJECT* p);
            int NotifyDbDestroyAccountCacheCallBack(T_VECTOR_OBJECT* p);
            int LoadingAvatarItemsCallback(T_VECTOR_OBJECT* p);
            int UpdateItemsCallback(T_VECTOR_OBJECT* p);
            int TableSelectCallback(CPluto& u);
            int TableInsertCallback(T_VECTOR_OBJECT* p);
            int BroadClientRpc(T_VECTOR_OBJECT* p);
            int TableUpdateCallback(T_VECTOR_OBJECT* p);
            int TableExcuteCallback(T_VECTOR_OBJECT* p);
            int Table2ExcuteResp(T_VECTOR_OBJECT* p);
            int Table2SelectResp(CPluto& u);
            int Table2InsertResp(T_VECTOR_OBJECT* p);
            int IncrementalInsertCallback(T_VECTOR_OBJECT* p);
#ifdef __RELOGIN
            int ClientReLogin(T_VECTOR_OBJECT* p);
#endif
            int OnCrossClientBroadcast(T_VECTOR_OBJECT* p);

        private:
            //handle and retransmit the clinet require
            int OnClientMoveReq(CPluto& u);
            //处理客户端对其他实体(宠物、雇佣兵等)的移动
            int OnClientOthersMoveReq(CPluto& u);

        private:
            //overload the base class method
            int ShutdownServer(T_VECTOR_OBJECT* p);

        private:
            int FromClientRpcCall(T_VECTOR_OBJECT* p);
            int FromClientRpc2CellViaBase(CPluto& u);
            int FromLuaRpcCall(T_VECTOR_OBJECT* p);

        public:
            const string& MakeClientLoginKey(const string& strAccount, TENTITYID eid);

#ifdef __RELOGIN
            //生成用于断线重连的使用使用的key
            const string& MakeClientReLoginKey(const string& strAccount, TENTITYID eid);

            _SClientReLoginKey* GetClientReLoginKey(const string& key);

            inline void ClearClientReLoginKeys(TENTITYID eid)
            {
                map<string, _SClientReLoginKey*>::iterator iter = m_clientReLoginKeys.begin();
                for (; iter != m_clientReLoginKeys.end(); ++iter)
                {
                    if(iter->second->m_eid == eid)
                    {
						delete iter->second;
						m_clientReLoginKeys.erase(iter);
						return;
                    }
                }
            }
#endif

        private:
            void _MakeKey(const string& strAccount, string& key, time_t& t);

        public:
            int OnFdClosed(int fd);
            CEntityBase* GetEntityByFd(int fd);
            void UpdateClientInfo(int fd, TENTITYID eid);

        protected:
            void InitEntityCall();

        private:
            CEntityMgr<CEntityBase> m_enMgr;
            map<string, _SClientLoginKey*> m_clientLoginKeys;

#ifdef __RELOGIN
            map<string, _SClientReLoginKey*> m_clientReLoginKeys;
#endif

            map<int, TENTITYID> m_fd2Entity;

            CWorldBase(const CWorldBase&);
            CWorldBase& operator=(const CWorldBase&);
    };




}



#endif

