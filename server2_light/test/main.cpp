#include <iostream>
#include <algorithm>
#include <iomanip>
#include <lua.hpp>

#ifdef _WIN32
	#include <winsock.h>
#endif

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


#ifndef _WIN32
    #include "epoll_server.h"
	CPlutoList g_pluto_recvlist;
	CPlutoList g_pluto_sendlist;
#endif

bool g_bShutdown;

extern int create_base_with_data(lua_State* L, map<string, VOBJECT*>& new_data);

world* g_pTheWorld = new CWorldBase;
//world* g_pTheWorld = new CWorldCell;
//world* g_pTheWorld = new CWorldDbmgr;

int sync_db(int argc, char* argv[])
{
    world& the_world = *GetWorld();

#ifdef _WIN32
	int nRet = the_world.init("F:\\CW\\cw\\cw\\etc\\cw.etc.txt");
#else
	//由cwmd传入配置文件名
	if(argc < 2)
	{
		cout << "Usage:" << argv[0] << " cfg_file" << endl;
		return -1;
	}

	int nRet = the_world.init(argv[1]);
#endif
    
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
        uint64_t iniInter = (uint64_t)atoi(GetWorld()->GetCfgReader()->GetOptValue("params", "server_id", "1").c_str());
        iniInter = iniInter << 32;
        oss << "ALTER TABLE `tbl_" << strEntityName << "` AUTO_INCREMENT=" << iniInter;
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
                cout << "run alter ret:" << n << "," << mysql_error(mysql) << endl;
            }

            if (n == 0 && argc > 1)
            {
                string strAlterSql;
                ostringstream oss;
                uint64_t iniInter = (uint64_t)atoi(GetWorld()->GetCfgReader()->GetOptValue("params", "server_id", "1").c_str());
                iniInter = iniInter << 32;
                oss << "ALTER TABLE `tbl_" << strEntityName << "` AUTO_INCREMENT=" << iniInter;
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

void pluto_alltype_test()
{
	CPluto c1;
	c1.Encode(123);
	c1 << (uint8_t) 250;
	c1 << (uint16_t) 65530;
	c1 << (uint32_t) 123456677;
	c1 << (uint64_t) 0x12345678 * 100;
	c1 << (int8_t)-12;
	c1 << (int16_t) 65530;
	c1 << (int32_t) -1234567;
	c1 << (int64_t) 1234567;
	c1 << (float32_t) 1.234;
	c1 << (float64_t) -23333399999.46;
	c1 << "abcddef";

	{
		charArrayDummy cc;
		cc.m_l = 4;
        strcpy(cc.m_s, "12\03");
		c1 << cc;
		cc.m_l = 0;
	}
	c1 << EndPluto;

	PrintHexPluto(c1);

	CPluto c2(c1.GetBuff(), c1.GetLen());
	c2.Decode();

	uint8_t u8;uint16_t u16;uint32_t u32;uint64_t u64;
	int8_t i8;int16_t i16;int32_t i32;int64_t i64;
	float32_t f32;float64_t f64;string s;charArrayDummy cc;

	c2 >> u8 >> u16 >> u32 >> u64 >> i8 >> i16 >> i32 >> i64 >> f32 >> f64 >> s >> cc;

	cout << c2.GetDecodeErrIdx() << endl;
}

void test_UpperStrCmp(const char* s1, const char* s2)
{
	bool b = UpperStrCmp(s1, s2);
	printf("%s %s %s\n", s1, b?"==":"!=", s2);
}

//从一个文本中读取pluto的hex格式并解析
void test_error_pluto()
{
	const char szFileName[] = "f:\\err_pluto\\1.txt";
	FILE* f = fopen(szFileName, "r");

	char szLine[128];
	unsigned char szPluto[MSGLEN_MAX];
	int j = 0;
	while(fgets(szLine, sizeof(szLine), f))
	{
		//printf("%s", szLine);
		for(int i=0; i< 16; ++i)
		{
			char s[4];
			s[0] = szLine[i*3];
			s[1] = szLine[i*3 + 1];
			s[2] = szLine[i*3 + 2];
			s[3] = '\0';

			if(s[0] != ' ')
			{
				//printf("%s", s);
				szPluto[j] = sz_to_char(s);
				++j;
			}

			
		}
	}
	fclose(f);


	CPluto u((const char*)szPluto, j);
	PrintHexPluto(u);

	T_VECTOR_OBJECT* ll = GetWorld()->GetRpcUtil().Decode(u);
	if(u.GetDecodeErrIdx() > 0)
	{
		printf("test_err_pluto,%d\n", u.GetDecodeErrIdx());
	}
	int k = 0;
	++k;


}

int main(int argc, char* argv[])
{
    using namespace std;
    using namespace mogo;

    //cout << "aaa" << endl;

	
	//CAStarPathFounder::find_way_astar(200, 200, 800, 1200, NULL);
	//return 0;


//#define  FILE_PLUTO_TEST

#ifdef FILE_PLUTO_TEST
	delete g_pTheWorld;
	g_pTheWorld = new CWorldDbmgr;
	g_pTheWorld->init("F:\\CW\\cw\\cw\\etc\\cw.etc.txt");
	test_error_pluto();
	return 0;
#endif

//#define SYNC_DB_TEST

#ifdef SYNC_DB_TEST
    delete g_pTheWorld;
    g_pTheWorld = new CWorldDbmgr;
    int nRet111 = sync_db(argc, argv);
    cout << "sync_db,ret=" << nRet111 << endl;
    return nRet111;
#endif


#ifndef _WIN32
    CEpollServer es;
    es.Service("127.0.0.1", 5555);

    return 0;
#endif

    //cout << sizeof(float) << ',' << sizeof(double) << endl;

    //pluto test begin
	//pluto_alltype_test();
	//return 0;
    //pluto test end

    //for (int i=0; i <10; ++i)
    //{
    //    s.addEntity(i, i+5, new CEntity(i));
    //    //s.addEntity(i+1, i+7, new CEntity(i));
    //}
    //s.checkInterestChange();

    //return 0;

    //CWorldBase& worldbase = GetWorldbase();

#ifdef _WIN32
    int nRet = GetWorld()->init("F:\\CW\\cw\\cw\\etc\\cw.etc.txt");
	//int nRet = GetWorld()->init("D:\\VS_PROJ\\cw\\cw\\etc\\cw.etc.txt");
	
    cout << nRet << endl;

#else
    int nRet = GetWorld()->init("/home/jh/ddev/cw/etc/cw.etc.linux");
    cout << nRet << endl;
#endif

    //int nRet2 = g_worldcell.init("F:\\CW\\cw\\cw\\etc\\cw.etc.txt");
    //cout << nRet2 << endl;

    return 0;
}

