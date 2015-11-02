#include "api_plat.h"
#include "logger.h"

CPlatApi::CPlatApi()
{
	init();
}

void CPlatApi::init()
{
	T_GetMD5Methods::iterator itor = m_getMd5Methods.find("user_online");
	if (itor == m_getMd5Methods.end())
	{
		m_getMd5Methods.insert(make_pair("user_online",get_md5_str_user_online));
	}
	itor = m_getMd5Methods.find("user_role_info");
	if (itor == m_getMd5Methods.end())
	{
		m_getMd5Methods.insert(make_pair("user_role_info",get_md5_str_user_role_info));
	}
	itor = m_getMd5Methods.find("user_upgrade");
	if (itor == m_getMd5Methods.end())
	{
		m_getMd5Methods.insert(make_pair("user_upgrade",get_md5_str_user_upgrade));
	}
}

bool CPlatApi::check_md5(const char* key, const char* pszReq, const char* apiName)
{
	//pszReq: //port=123&suid=xxx&timestamp=12345&sign=xxx&platid=111&plataccount=xxx&token=xxx

	map<string, string> dictParams;
	SplitStringToMap(pszReq, '&', '=', dictParams);
	string str = make_md5_str(dictParams, apiName, key); //得到各自的md5 字符串 用于计算md5
	const string& flag = get_dict_field(dictParams, "flag");//发过来的flag

	//检查md5是否匹配
	//flag=md5("$suid&$timestamp&%key")
	{

		enum{ SIZE16 = 16,};
		unsigned char szMd5[SIZE16];
		MD5((unsigned char*)str.c_str(), str.size(), szMd5);

		char szKey[64];
		memset(szKey, 0, sizeof(szKey));
		for (int i=0; i<SIZE16; ++i)
		{
			char_to_sz(szMd5[i], szKey+2*i);
		}
		
		if (strcasecmp(szKey, flag.c_str()) != 0 )
		{		
			//md5签名不匹配,错误的请求
			LogWarning("CPlatApi::check_md5", "apiName[%s], pszReq[%s], md5_str[%S],md5[%s],flag[%s]", apiName, pszReq, str.c_str(),szKey, flag.c_str());
			return false;
		}
	}

	return true;
}



string CPlatApi::make_md5_str(map<string, string> & dictParams, const char* apiName, const char* key)
{
	//string str = ParamsToChar(dictParams);
	string str = "";
	T_GetMD5Methods::iterator itor = m_getMd5Methods.find(apiName);
	if (itor != m_getMd5Methods.end())
	{
		//LogDebug("CPlatApi::make_md5_str", "");
		GetMD5Str pFunc = itor->second;
		str = pFunc(dictParams);
	}
	str += key; //拼装字符串： 连接参数名与参数值,并在尾部加上Key(这里假设Key=testKey)值:

	return str;
}



string CPlatApi::ParamsToChar(map<string, string>& params)
{
	string ret;
	map<string, string>::iterator itor = params.begin();
	for (; itor != params.end(); ++itor)
	{
		if (itor->first != "flag") //忽略flag
		{
			ret += itor->second;  //这里只加value
		}
	}
	return ret;
}
/*
user_online
flag=md5(game_id+server_id+platform_id+time+key);
user_role_info
flag=md5(start_time+end_time+game_id+server_id+platform_id+time+key);
user_upgrade
flag=md5(start_time+end_time+game_id+server_id+platform_id+time+key);
*/
const string get_md5_str_user_online(map<string, string> & dictParams)
{
	string ret;
	ret += get_dict_field(dictParams, "game_id");
	ret += get_dict_field(dictParams, "server_id");
	ret += get_dict_field(dictParams, "platform_id");
	ret += get_dict_field(dictParams, "time");
	return ret; 
}
const string get_md5_str_user_role_info(map<string, string> & dictParams)
{
	string ret;
	ret += get_dict_field(dictParams, "start_time");
	ret += get_dict_field(dictParams, "end_time");
	ret += get_dict_field(dictParams, "game_id");
	ret += get_dict_field(dictParams, "server_id");
	ret += get_dict_field(dictParams, "platform_id");
	ret += get_dict_field(dictParams, "time");
	return ret; 
}
const string get_md5_str_user_upgrade(map<string, string> & dictParams)
{
	string ret;
	ret += get_dict_field(dictParams, "start_time");
	ret += get_dict_field(dictParams, "end_time");
	ret += get_dict_field(dictParams, "game_id");
	ret += get_dict_field(dictParams, "server_id");
	ret += get_dict_field(dictParams, "platform_id");
	ret += get_dict_field(dictParams, "time");
	return ret; 
}