#include <iostream>
#include <algorithm>
#include <iomanip>
#include <lua.hpp>

#include "lua_mogo.h"
#include "space.h"
#include "world_cell.h"
#include "lua_cell.h"
#include "world_base.h"
#include "lua_base.h"
#include "pluto.h"
#include "world_cwmd.h"
#include "dboper.h"
#include "world_select.h"
#include "world_dbmgr.h"
#include "path_founder.h"

//extern int create_base_with_data(lua_State* L, map<string, VOBJECT*>& new_data);

world* g_pTheWorld = new CWorldBase;
//world* g_pTheWorld = new CWorldCell;
//world* g_pTheWorld = new CWorldDbmgr;

int SyncDb(int argc, char* argv[])
{
    world& the_world = *GetWorld();

    //由cwmd传入配置文件名
    if(argc < 2)
    {
        cout << "Usage:" << argv[0] << " cfg_file" << endl;
        return -1;
    }

    int nRet = the_world.init(argv[1]);
    
    //cout << nRet << endl; 
    if(nRet != 0)
    {
        return nRet;
    }

    CDefParser& def = the_world.GetDefParser();
    CDbOper db(0);
    string strErr;
    if(!db.Connect(def.GetDbCfg(), def.GetRedisCfg(), strErr))
    {
        cout << "db err:" << strErr << endl;
        return -1;
    }

    MYSQL* mysql = db.GetMySql();
    cout << "==========================SYNC_DB BEGIN================================" << endl;
    cout << "==========================CREATE SQL===================================" << endl;

    //redis_hash表
    const char szRhSql[] = \
        "CREATE TABLE `redis_hash` ("
        "`key` varchar(64) collate utf8_bin NOT NULL,"
        "`hash_key` int(11) NOT NULL,"
        "`hash_value` text collate utf8_bin NOT NULL,"
        "KEY `key` (`key`)"
        ") ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin";
    cout << "create redis_hash sql:" << endl << szRhSql << endl;
    int n = mysql_real_query(mysql, szRhSql, (unsigned long)sizeof(szRhSql));
    if(n != 0)
    {
        cout << "run create redis_hash ret:" << n << "," << mysql_error(mysql) << endl;
    }

    //def定义的entity映射的表
    const map<string, TENTITYTYPE>& ens = def.GetDefTypes();
    map<string, TENTITYTYPE>::const_iterator iter = ens.begin();
    for(; iter != ens.end(); ++iter)
    {
        const string& strEntityName = iter->first;
        cout << "Entity name:" << strEntityName << endl;

        string strCreateSql;
        if(db.MakeCreateSql(strEntityName, strCreateSql))
        {
            cout << "create sql:" << endl << strCreateSql << endl;

            int n = mysql_real_query(mysql, strCreateSql.c_str(), (unsigned long)strCreateSql.size());
            if(n != 0)
            {
                cout << "run create ret:" << n << "," << mysql_error(mysql) << endl;
            }
        }
        else
        {
            cout << "make create sql err---------------------------" << endl;
        }

        string strAlterSql;
        ostringstream oss;
        oss << "ATLER TABLE `tbl_" << strEntityName << "` AUTO_INCREMENT=" << GetWorld()->GetCfgReader()->GetOptValue("params", "init_auto_increment", "1").c_str();
        strAlterSql.assign(oss.str());

        cout << "alter sql:" << endl << strAlterSql << endl;
        int n = mysql_real_query(mysql, strAlterSql.c_str(), (unsigned long)strAlterSql.size());
        if (n != 0)
        {
            cout << "run atler ret:" << n << "," << mysql_error(mysql) << endl;
        }
    }

    cout << "==========================ALTER SQL===================================" << endl;
    iter = ens.begin();
    for(; iter != ens.end(); ++iter)
    {
        const string& strEntityName = iter->first;
        cout << "Entity name:" << strEntityName << endl;

        string strCreateSql;
        if(db.MakeAlterSql(strEntityName, strCreateSql))
        {
            cout << "alter sql:" << endl << strCreateSql << endl;

            int n = mysql_real_query(mysql, strCreateSql.c_str(), (unsigned long)strCreateSql.size());
            if(n != 0)
            {
                cout << "run atler ret:" << n << "," << mysql_error(mysql) << endl;
            }
            else
            {
                string strAlterSql;
                ostringstream oss;
                oss << "ATLER TABLE `tbl_" << strEntityName << "` AUTO_INCREMENT=" << GetWorld()->GetCfgReader()->GetOptValue("params", "init_auto_increment", "1").c_str();
                strAlterSql.assign(oss.str());

                cout << "alter sql:" << endl << strAlterSql << endl;
                n = mysql_real_query(mysql, strAlterSql.c_str(), (unsigned long)strAlterSql.size());
                if (n != 0)
                {
                    cout << "run atler ret:" << n << "," << mysql_error(mysql) << endl;
                }
            }
        }
        else
        {
            cout << "make alter sql err---------------------------" << endl;
        }
    }

    cout << "==========================SYNC_DB END==================================" << endl;

    return 0;
}

int main(int argc, char* argv[])
{
    using namespace std;
    using namespace mogo;

    delete g_pTheWorld;
    g_pTheWorld = new CWorldDbmgr;
    int nRet = SyncDb(argc, argv);
    cout << "sync db, ret=" << nRet << endl;
    return nRet;

}

