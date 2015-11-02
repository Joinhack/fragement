#include "api_data_center.h"



bool CDataCenterApi::check_md5(const char* key, const char* pszReq, const char* apiName)
{

	//pszReq: //port=123&suid=xxx&timestamp=12345&sign=xxx&platid=111&plataccount=xxx&token=xxx

	map<string, string> dictParams;
	SplitStringToMap(pszReq, '&', '=', dictParams);
	string str = make_md5_str(dictParams, key); //得到各自的md5 字符串 用于计算md5

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
			return false;
		}
	}

	return true;
}





string CDataCenterApi::make_md5_str(map<string, string> & dictParams, const char* key)
{
	string str = ParamsToChar(dictParams);
	str += key; //拼装字符串： 连接参数名与参数值,并在尾部加上Key(这里假设Key=testKey)值:

	return str;
}


string CDataCenterApi::ParamsToChar(map<string, string>& params)
{
	string ret;
	map<string, string>::iterator itor = params.begin();
	for (; itor != params.end(); ++itor)
	{
		if (itor->first != "flag") //忽略flag
		{
			ret += itor->first;
			ret += itor->second;
		}
	}
	return ret;
}


