#include "login4399.h"
#include <stdio.h>
#include <ostream>
#include <sys/types.h>
#include <unistd.h>
#include "logger.h"
#include <curl/curl.h> 
#include "cjson.h"
#include "fcgi_def.h"
#include "pluto.h"
#include "ifbase.h"
#include "json_helper.h"

CLogin4399::CLogin4399()
{
	m_str_plat_name = "4399";
}

CLogin4399::~CLogin4399()
{

}



//校验请求是否正确
int CLogin4399::check_login(const char* plat_name, const char* pszReq, string& strAccountGot)
{  	
// 	if ( m_str_plat_name !=  (string)plat_name)
// 	{
// 		LogWarning("check_login", "plat :%s != %s", plat_name, m_str_plat_name.c_str());
// 		return ENUM_LOGIN_PLAT_NAME_ERROR;
// 	}

	//port=123&suid=xxx&timestamp=12345&sign=xxx&platid=111&plataccount=xxx&token=xxx

	//解析登录是否合法
	map<string, string> dictParams;
	SplitStringToMap(pszReq, '&', '=', dictParams);

	//校验客户端发来的loginapp端口是否在合法
	//uLoginappPort = (uint16_t)atoi(get_dict_field(dictParams, "port").c_str());
	//if(uLoginappPort < LOGINAPP_MIN_PORT || uLoginappPort > LOGINAPP_MAX_PORT)
	//{
	//    LogError("login_porterr", "req=%s", pszReq);
	//    return ENUM_LOGIN_INNER_ERR;
	//}
	//loginapp端口改为读配置
	//uint16_t unPortFromClient = (uint16_t)atoi(get_dict_field(dictParams, "port").c_str());

	//平台的时间戳
	const string&  strTime = get_dict_field(dictParams, "timestamp");	
	int nTimestamp = atoi(strTime.c_str());
	int nTimeNow = time(NULL);
	//比服务器时间滞后超过20分钟，或者超前多于5分钟算时间无效
	if(nTimeNow > nTimestamp + 1200 || nTimestamp > nTimeNow + 300)
	{
		LogError("login_timeout", "req=%s", pszReq);
		return ENUM_LOGIN_TIME_ILLEGAL;		
	}

	const string& strSuid = get_dict_field(dictParams, "suid");
	const string& strSign = get_dict_field(dictParams, "sign");
	//检查md5是否匹配
	//flag=md5("$suid&$timestamp&%key")
	{
		std::ostringstream oss;
		oss << strSuid << '&' << strTime << '&' << this->get_cfg_value("key", sg_szLoginKey);		
		const string& strOss = oss.str();
		
		string __md5 = getmd5(strOss);		

		if(strcasecmp(__md5.c_str(), strSign.c_str()) != 0 )
		{
			//md5签名不匹配,错误的请求
			return ENUM_LOGIN_SIGN_ILLEGAL;
		}
	}

	//到平台验证tocken是否正确
	const string& strTocken = get_dict_field(dictParams, "tocken");
	const string& strAccount = get_dict_field(dictParams, "plataccount");
	{
		string resp = "";
		string strUrl = this->get_cfg_value("url", sg_szVerifyUrl).append(strTocken);
		int ret = GetUrl_new(strUrl.c_str(), resp);
		if (ret != CURLE_OK)
		{
			LogWarning("login_urlerr", "ret=%d;req=%s", ret, pszReq);
			return ENUM_LOGIN_SERVER_BUSY;
		}
		Trim(resp);


		JsonHelper jsonhp(resp);

		int rst = 0;
		if (!jsonhp.GetJsonItem("code", rst))
		{
			//平台返回字符串解析失败
			LogWarning("login_jsonfailed", "json=%s", resp.c_str());
			return ENUM_LOGIN_SDK_VERIFY_FAILED;
		}

		if (rst != 1)
		{
			//结果码为1表示验证成功,其他值都是失败
			LogWarning("login_verifyfailed", "rst=%d;req=%s", rst, pszReq);
			return ENUM_LOGIN_SDK_VERIFY_FAILED;            
		}
	}

	//需要返回的参数值
	strAccountGot.assign(strSuid);

	LogInfo("login_req", "%s", pszReq);
	return ENUM_LOGIN_SUCCESS;
}
