//数据中心api游戏处理cgi

#include <unistd.h>

#include "iffactory.h"
#include "world_base.h"
#include <fcgi_config.h>
#include <fcgi_stdio.h>
#include "cgicfg.h"
#include "../logapp/dboper.h"
#include "rpc_mogo.h"
#include "URLDecode.h"
#include <openssl/md5.h>




world* g_pTheWorld = new CWorldBase;
CDbOper* g_db = new CDbOper(1);
extern int GetUrl_new(const char* url, string& result);
string url = "";
string key = "";
string log_path = "";


enum
{
	ENUM_CARD_SUCCSEE = 0,                      //激活码可用，请等待
	ENUM_DB_QUERY_ERROR ,                   //数据库查询错误
	ENUM_NUMBER_ERROR,                   //激活码错误
	ENUM_NUMBER_ALREADY_USED,                   //激活码已经被使用
	ENUM_SERVER_NOT_FOUND,                   //未发现选择的服务器
	ENUM_ERROR_SAME_TYPE,                   //已经领取过相同类型的礼包
};


void send_err_resp(int nRet)
{
	FCGI_printf("Content-type: text/html\r\n\r\n%d", nRet);
}



void string_replace(std::string& strBig, const std::string & strsrc, const std::string &strdst)
{
	std::string::size_type pos = 0;
	while( (pos = strBig.find(strsrc, pos)) != string::npos)
	{
		strBig.replace(pos, strsrc.length(), strdst);
		pos += strdst.length();
	}
}


void key_check(const char* pszReq)
{
	g_logger.SetLogPath(log_path);
	//先解码，可能有中文
	LogDebug("key_check","pszReq=[%s]", pszReq);
	string decode_params_str =  HttpUtility::URLDecode(pszReq);
	map<string, string> dictParams;
	SplitStringToMap(decode_params_str, '&', '=', dictParams);	

 	string dbid = get_dict_field(dictParams, "dbid");
 	string server = get_dict_field(dictParams, "server");
 	string serial_number = get_dict_field(dictParams, "serial_number");		

	if (dbid == "" || server == "" || serial_number == "")
	{
		LogError("key_check","params error");
		send_err_resp(ENUM_NUMBER_ERROR); //激活码不能为空
		return;
	}


	
	string tmp_dbid = dbid;
	string tmp_server = server;
	string tmp_serial_number = serial_number;
	string_replace(tmp_dbid, "'","''");//替换所有单引号 防止注入	
	string_replace(tmp_server, "'","''");//替换所有单引号 防止注入	
	string_replace(tmp_serial_number, "'","''");//替换所有单引号 防止注入	

	ostringstream oss;
		
	oss << "select server, dbid ,type, create_item_id from card where card_id = '"<< tmp_serial_number.c_str() <<"'";
	vector<string> cols, data;
	if (0 != g_db->SqlQuery(oss.str(), cols, data))
	{
		LogError("key_check","ENUM_DB_QUERY_ERROR");
		send_err_resp(ENUM_DB_QUERY_ERROR);
		return;
	}

	LogDebug("key_check","query ok");
	if (data.size() < 4)
	{
		LogError("key_check","ENUM_NUMBER_ERROR");
		send_err_resp(ENUM_NUMBER_ERROR);
		return;
	}

	string got_server		= data[0];  //查询得到的域名
	string got_dbid			= data[1];
	string got_type			= data[2];
	string create_item_id	= data[3];

	if (got_server != "" && got_dbid != ""  ) //已经被人使用过
	{
		LogError("key_check","ENUM_NUMBER_ALREADY_USED");
		send_err_resp(ENUM_NUMBER_ALREADY_USED);
		return;
	}

	LogDebug("key_check","not used");

	oss.clear();
	oss.str("");
	oss << "select type from card where  dbid= "<< tmp_dbid.c_str() <<" and server = "<<"'"<< tmp_server.c_str() <<"'";

	cols.clear();
	data.clear();
	if (0 != g_db->SqlQuery(oss.str(), cols, data))
	{
		LogError("key_check","ENUM_DB_QUERY_ERROR");
		send_err_resp(ENUM_DB_QUERY_ERROR);
		return;
	}

	LogDebug("key_check","query ok _____2");

	for (vector<string>::size_type i =0; i<data.size(); ++i)
	{
		if(data[i] == got_type)
		{
			LogError("key_check"," already get same type card , active failed");
			send_err_resp(ENUM_ERROR_SAME_TYPE);
			return;			
		}
	}
	

	LogDebug("key_check","number was not used,and no same card, begin to update");

	oss.clear();
	oss.str("");

	oss<<"UPDATE card SET server = '"<<tmp_server.c_str()<<"', dbid = "<< tmp_dbid.c_str()<<"	WHERE card_id = '"<< tmp_serial_number.c_str()<<"'";
		
	if (0 <= g_db->SqlUpdate(oss.str()))
	{
		ostringstream pre_md5;
		ostringstream str_send;
		map<string, string> params;
		params["dbid"] = dbid;	
		params["item_id"] = create_item_id;
		//params["role_name"] = role_name;
		map<string, string>::iterator itor = params.begin(); //这里md5加密参数是有顺序的 按照map的顺序
		for (; itor != params.end(); ++itor)
		{
			pre_md5<<itor->first << itor->second;
			str_send<<itor->first << "=" << itor->second << "&";
		}

		pre_md5 << key.c_str();

		string md5 = getmd5(pre_md5.str());
		str_send <<"flag="<< md5.c_str();

		oss.clear();
		oss.str("");
		//key/complain_reply?compain_id=123&content=3123&time=1385551681&user_name=123123&v=2.0&flag=9EB10EB5116BA00D2497536764247ACE
		//构造链接
		oss<<"http://"<<server.c_str()<<"/cgi-bin/gift_sender/add_giftbag?"<<str_send.str().c_str();
		string result; 
		LogDebug("begin to req url"," URL:\n%s", oss.str().c_str());	
		int nRet = GetUrl_new(oss.str().c_str(), result);
		if (0 == nRet)
		{
			send_err_resp(ENUM_CARD_SUCCSEE);			
		}		
		LogDebug("GetUrl_new","OK: ret=[%d]  URL:\n%s",nRet, oss.str().c_str());			
	}

	LogDebug("key_check"," return");

	return ;

}
int init()
{
	
	SDBCfg dbcfg;
	dbcfg.m_strDbName	= g_cgi_cfg->GetValue("config", "db");
	dbcfg.m_strHost		= g_cgi_cfg->GetValue("config", "host");
	dbcfg.m_strPasswd	= g_cgi_cfg->GetValue("config", "passwd");
	dbcfg.m_strUser		= g_cgi_cfg->GetValue("config", "user");
	dbcfg.m_unPort		= atoi(g_cgi_cfg->GetValue("config", "port").c_str());

	url = g_cgi_cfg->GetValue("config", "url");
	key = g_cgi_cfg->GetValue("config", "key");
	log_path = g_cgi_cfg->GetValue("config", "log");
	
	
	string strError;
	if(!g_db->Connect(dbcfg,  strError))
	{
		LogError("card.init","db error[%s]", strError.c_str());
		cout << "db err:" << strError << endl;
		return -1;
	}

	
	return 1;

}



int main ()
{
	char **initialEnv = environ; 

	g_cgi_cfg = new CCgiCfg("/data/server/cgi-bin/sh/card_cfg.txt");	

	int nRet = init();

	if(1 != nRet){return nRet;}	

	while (FCGI_Accept() >= 0) 
	{	
		char* pszReq = my_getenv("QUERY_STRING");	
		key_check(pszReq);
	}
	
	delete (CWorldBase*)g_pTheWorld;

	return 0;
}
