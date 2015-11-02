#ifndef __WORLD_DBMGR_HEAD__
#define __WORLD_DBMGR_HEAD__

#ifdef _WIN32
#include <winsock.h>
#endif

#include "world.h"
#include "dboper.h"
#include "db_task.h"
#include "balance.h"
#include "debug.h"


namespace mogo
{

    struct SEntityLookup
    {
        TENTITYID eid;      //entity id
        uint16_t sid;       //baseapp id
    };

    class CWorldDbmgr : public world
    {
        public:
            CWorldDbmgr();
            ~CWorldDbmgr();

        public:
            virtual int init(const char* pszEtcFile);

        public:
            int FromRpcCall(CPluto& u, CDbOper& db);
            bool IsCanAcceptedClient(const string& strClientAddr);

        private:
            int InsertDB(T_VECTOR_OBJECT* p, CDbOper& db);
            int LookupEntityByDbId(T_VECTOR_OBJECT* p, CDbOper& db);
            int UpdateEntity(T_VECTOR_OBJECT* p, CDbOper& db);
            int UpdateEntityToRedis(T_VECTOR_OBJECT* p, CDbOper& db);
            int SelectAccount(T_VECTOR_OBJECT* p, CDbOper& db);
            int QueryModifyNoResp(T_VECTOR_OBJECT* p, CDbOper& db);

            int LookupEntityByName(T_VECTOR_OBJECT* p, CDbOper& db);
            int LoadAllAvatars(T_VECTOR_OBJECT* p, CDbOper& db);
            int LoadEntitiesOfType(T_VECTOR_OBJECT* p, CDbOper& db);

            int ShutdownServer(T_VECTOR_OBJECT* p);

            int RedisHashLoad(T_VECTOR_OBJECT* p, CDbOper& db);
            int RedisHashSet(T_VECTOR_OBJECT* p, CDbOper& db);
            int RedisHashDel(T_VECTOR_OBJECT* p, CDbOper& db);

            int DestroyAccountCache(T_VECTOR_OBJECT* p);

            int UpdateArrayItemsToDb(T_VECTOR_OBJECT* p, CDbOper& db);
            int LoadingArrayItemsToInventory(T_VECTOR_OBJECT* p, CDbOper& db);

            int TableSelect(T_VECTOR_OBJECT* p, CDbOper& db);
            int TableInsert(T_VECTOR_OBJECT* p, CDbOper& db);
            int TableExcute(T_VECTOR_OBJECT* p, CDbOper& db);
            int TableUpdateBatch(T_VECTOR_OBJECT* p, CDbOper& db);
            int Table2Select(T_VECTOR_OBJECT* p, CDbOper& db);
            int Table2Insert(T_VECTOR_OBJECT* p, CDbOper& db);
            int Table2Excute(T_VECTOR_OBJECT* p, CDbOper& db);

            int IncremantalUpdateItems(T_VECTOR_OBJECT* p, CDbOper& db);
        public:
            inline int FromRpcCall(CPluto& u)
            {
                return 0;
            }

            //此方法无用
            inline int OpenMogoLib(lua_State* L)
            {
                return 0;
            }

            //此方法无用
            inline CEntityParent* GetEntity(TENTITYID id)
            {
                return NULL;
            }

            inline int OnServerReady()
            {
                return 0;
            }

        public:
            bool InitMutex();
            //获取下一个entity id,本方法需要是一个同步方法
            TENTITYID MyGetNextEntityId();
            //获取下一个创建entity所在baseapp id
            uint16_t ChooseABaseApp();
            //往查找结构中加入一个新的entity查找项
            void CreateNewEntityToLookup(TDBID dbid, const string& strEntity, TENTITYID eid, uint16_t sid);
            void CreateNewEntityToLookup(const string& strKey, const string& strEntity, TENTITYID eid, uint16_t sid);
            //根据dbid查找entity信息
            SEntityLookup* LookupEntityInfo(TDBID dbid, const string& strEntity);
            //根据唯一索引查找entity信息
            SEntityLookup* LookupEntityInfo(const string& strKey, const string& strEntity);
            //删除entity相关的信息
            void DeleteEntityInfo(TDBID dbid, const string& strEntity);
            void DeleteEntityInfo(const string& strKey, const string& strEntity);
            //新增一个Avatar的查找项
            void CreateNewAvatarToLookup(const string& strAccount, TENTITYID eid, uint16_t sid);
            //根据账户名查找一个Avatar
            SEntityLookup* LookupAvatarByAccount(const string& strAccount);

        private:
            pthread_mutex_t m_entityMutex;                                          //用于entity管理的mutex
            pthread_mutex_t m_rpcMutex;
            map<string, map<TDBID, SEntityLookup*>*> m_entities4LookupByDbid;       //根据dbid查找对应的entity
            map<string, map<string, SEntityLookup*>*> m_entities4LookupByName;      //根据唯一索引值查找对应的entity
            map<string, SEntityLookup*> m_avatars4LookupByAccount;                  //根据账号名查找对应的Avatar
            CBalance m_baseBalance;
            CWorldDbmgr(const CWorldDbmgr&);
            CWorldDbmgr& operator=(const CWorldDbmgr&);

    };




}




#endif

