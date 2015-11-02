#ifndef __DB_OPER__
#define __DB_OPER__


#include <mysql.h>
#include "pluto.h"
#include "defparser.h"


#ifdef _USE_REDIS
#include "myredis.h"
#endif

#ifdef __TEST
#include "util.h"
#endif

namespace mogo
{

    class CDbOper
    {
        public:
            CDbOper(int seq);
            ~CDbOper();

        public:
            //连接数据库
            bool Connect(const SDBCfg& cfg, const SRedisCfg& redisCfg, string& strErr);
            void DisConnect();
            //插入一个entity
            TDBID InsertEntity(const string& strEntity, const map<string, VOBJECT*>& props, string& strErr);
            int UpdateEntity(const string& strEntity, const map<string, VOBJECT*>& props, TDBID dbid, string& strErr);
            int UpdateEntityToRedis(const string& strEntity, const map<string, VOBJECT*>& props, TDBID dbid, string& strErr);
            int LookupEntityByDbId(const string& strEntity, TDBID dbid, int32_t ref, CPluto& u, string& strErr);
            //没接平台时的查找帐号
            int SelectAccount(int32_t fd,const char* pszAccount, const char* pszPasswd, CPluto& u, string& strErr);
            //接平台后取消密码验证
            int SelectAccount(int32_t fd,const char* pszAccount, CPluto& u, string& strErr);

            int QueryModifyNoResp(const char* pszSql);

            int LookupEntityByName(uint8_t nCreateFlag, const string& strEntity, const string& strKey, TENTITYID eid,
                                   CPluto& u, uint16_t& nBaseappId, string& strErr);

            int UpdateArrayToDb(const string& itemName, const TDBID dbid, CPluto& u, const uint16_t nBaseappId, int32_t ref, string& strErr);
            int LoadingItemsToInventory(const string& itemName, const TDBID dbid, uint16_t nBaseappId, int32_t ref, string& strErr);

            int TableSelect(uint16_t nBaseappId, uint32_t entityId, const string& strCallBackFunc, const string& strEntityType, const string& strSql);

            int UpdateBatch(const string& itemName, const string& uniqName, CPluto& u, const uint16_t nBaseappId, int32_t ref, string& strErr);

            TDBID TableInsert(const string& strSql, string& strErr);
            //执行sql语句
            int TableExcute(const string& strSql, string& strErr);
            int Table2Excute(const string& strSql, string& strErr);
            int Table2Select(uint16_t nBaseappId, TENTITYID eid, uint32_t, const string& strEntity, const string& strSql, string&);

            int IncrementalUpdateItems(const string& tblName, const uint16_t nBaseappId, CPluto& u, int32_t ref, string& strErr);
            int IncremantalInsertItems(const string& tblName, const uint16_t nBaseappId, CPluto& u, int32_t ref, string& strErr);
        public:
            //读取所有Avatar
            int LoadAllAvatars(const string& strEntity, const string& strIndex, string& strErr);
            //读取某个表的所有entity
            int LoadAllEntitiesOfType(const string& strEntity, uint16_t nBaseappId, string& strErr);

        private:
            void InitTypeMap();
            int insertAccount(const std::string &account, const std::string &password);
            const string& GetPropDbType(VTYPE vt);

        public:
            //根据def文件生成建表sql语句
            bool MakeCreateSql(const string& strEntity, string& strSql);
            //根据pluto解包出来的字段生成insert语句
            bool MakeInsertSql(const string& strEntity, const map<string, VOBJECT*>& props, string& strSql);
            //根据pluto解包出来的字段生成update语句
            bool MakeUpdateSql(const string& strEntity, const map<string, VOBJECT*>& props, TDBID dbid, string& strSql);

            //根据def生成一个table的预期结构
            bool GetEntityData(const string& strEntity, map<string, string>& data);
            //读取desc table的当前结构
            bool GetDescResult(const string& strEntity, string& strErr, map<string, string>& data);
            //根据def和数据库desc生成alert语句
            bool MakeAlterSql(const string& strEntity, string& strSql);

        public:
            void RedisHashLoad(const string& strKey, string& strValue);
            void RedisHashSet(const string& strKey, int32_t nSeq, const string& strValue);
            void RedisHashDel(const string& strKey, int32_t nSeq);

        public:
            inline MYSQL* GetMySql()
            {
                return m_mysql;
            }

        private:
            CStr2IntMap m_typeMap;

        private:
            MYSQL* m_mysql;
            bool m_bConnectDb;

#ifdef _USE_REDIS
            CRedisUtil m_redis;
#endif

            bool m_bFirstThread;    //第一个子线程

#ifdef __TEST
            CGetTimeOfDay time1;
#endif

    };



}


#endif

