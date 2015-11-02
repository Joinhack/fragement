#ifndef __DB_OPER__
#define __DB_OPER__

#include <mysql.h>

#include "pluto.h"
#include "defparser.h"
#include "other_def.h"




namespace mogo
{
    class CDbOper
    {
        public:
            CDbOper(int seq);
            ~CDbOper();

        public:
            //连接数据库
            bool Connect(const SDBCfg& cfg, string& strErr);
            void DisConnect();

            TDBID TableInsert(const string& strSql, string& strErr);

			int SqlQuery(const string& strSql,  OUT vector<string> & cols, OUT vector<string> & data);

			int SqlUpdate(const string& strSql);

        public:
            inline MYSQL* GetMySql()
            {
                return m_mysql;
            }

        private:
            MYSQL* m_mysql;
            bool m_bConnectDb;			
            bool m_bFirstThread;    //第一个子线程

    };



}


#endif

