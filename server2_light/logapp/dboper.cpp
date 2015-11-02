#include "dboper.h"
#include "rpc_mogo.h"
#include "world_select.h"
#include "world_other.h"


namespace mogo
{

    CDbOper::CDbOper(int seq) : m_bConnectDb(false), m_bFirstThread(seq==0)
    {
        m_mysql = mysql_init(NULL);
    }

    CDbOper::~CDbOper()
    {
    }

    void CDbOper::DisConnect()
    {
        mysql_close(m_mysql);

    }


    bool CDbOper::Connect(const SDBCfg& cfg, string& strErr)
    {


		int ml_outtime = 10;
		mysql_options(m_mysql, MYSQL_OPT_CONNECT_TIMEOUT, &ml_outtime);

		if(0 != mysql_options(m_mysql,MYSQL_SET_CHARSET_NAME,"utf8"))//设置字符集utf8
		{
			m_bConnectDb = false;
			strErr.assign(mysql_error(m_mysql));			
		}

        if( mysql_real_connect(m_mysql, cfg.m_strHost.c_str(), cfg.m_strUser.c_str(), cfg.m_strPasswd.c_str(),
                               cfg.m_strDbName.c_str(), cfg.m_unPort, NULL, 0) == NULL)
        {
            m_bConnectDb = false;
			strErr.assign(mysql_error(m_mysql));
		}
		else
		{
			string strSql = "set interactive_timeout=24*3600";
			int nRet = mysql_real_query(m_mysql, strSql.c_str(), (unsigned long)strSql.size());
			if(nRet != 0)
			{
				m_bConnectDb = false;
				strErr.assign(mysql_error(m_mysql));
			}
			else
			{
				m_bConnectDb = true;
				LogDebug("CDbOper::Connect", "connect db success ip = %s, database = %s",cfg.m_strHost.c_str(), cfg.m_strDbName.c_str());
			}


		}
		return m_bConnectDb;
	}

    //插入一个entity
   
    TDBID CDbOper::TableInsert(const string& strSql, string& strErr)
    {
        if(!m_bConnectDb)
        {
            strErr.assign("db not connected");
            return 0;
        }

        int nRet = mysql_real_query(m_mysql, strSql.c_str(), (unsigned long)strSql.size());
        if(nRet != 0)
        {
            strErr.assign(mysql_error(m_mysql));
            return 0;
        }


        TDBID newid = (TDBID)mysql_insert_id(m_mysql);
        //printf("newid:%d\n", newid);
        return newid;
    }

	int CDbOper::SqlQuery(const string& strSql,  OUT vector<string> & cols, OUT vector<string> & data)
	{

		string strErr;

		if(!m_bConnectDb)
		{
			strErr.assign("db not connected");
			LogError("CDbOper::TableSelect", strErr.c_str());
			return -1;
		}
		

		int nRet = mysql_real_query(m_mysql, strSql.c_str(), (unsigned long)strSql.size());
		if(nRet != 0)
		{
			strErr.assign(mysql_error(m_mysql));
			LogError("CDbOper::TableSelect", strErr.c_str());
			return -3;
		}

		MYSQL_RES *result = mysql_store_result(m_mysql);
		int num_fields = mysql_num_fields(result);//字段数
		
		MYSQL_FIELD * fd;
		for(int i=0; fd = mysql_fetch_field(result); ++i)
		{
			char* s = fd->name;

			cols.push_back(s);
		}

		MYSQL_ROW row;

		while ((row = mysql_fetch_row(result)))
		{ 
			unsigned long *lengths;
			lengths = mysql_fetch_lengths(result);

			for(int i = 0; i < num_fields; i++)
			{
				char* s = row[i];
				if(s)
				{
					data.push_back(s);
				}
				else
				{
					data.push_back("");//null 就为空字符串了
				}

			}
		}
		
		mysql_free_result(result);

		return 0;

	}

	int CDbOper::SqlUpdate(const string& strSql)
	{
		string strErr;

		if(!m_bConnectDb)
		{
			strErr.assign("db not connected");
			return -1;
		}


		int nRet = mysql_real_query(m_mysql, strSql.c_str(), (unsigned long)strSql.size());
		if(nRet != 0)
		{
			strErr.assign(mysql_error(m_mysql));
			return -3;
		}

		return (int)mysql_affected_rows(m_mysql); //返回受影响的行数
	}

}//end of namespace


