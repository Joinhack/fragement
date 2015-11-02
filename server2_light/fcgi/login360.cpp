#include "login360.h"
#include <stdio.h>
#include <ostream>
#include <sys/types.h>
#include <unistd.h>
#include "logger.h"
#include <curl/curl.h> 
#include "fcgi_def.h"
#include "pluto.h"
#include "ifbase.h"
#include "json_helper.h"

CLogin360::CLogin360()
{
	m_str_plat_name = "360";
}

CLogin360::~CLogin360()
{

}



//校验请求是否正确
int CLogin360::check_login(const char* plat_name, const char* pszReq, string& strAccountGot)
{  	
	if ( m_str_plat_name !=  (string)plat_name)
	{
		LogWarning("check_login", "plat :%s != %s", plat_name, m_str_plat_name.c_str());
		return ENUM_LOGIN_PLAT_NAME_ERROR;
	}

	map<string, string> dictParams;
	SplitStringToMap(pszReq, '&', '=', dictParams); 

	const string& strSuid = get_dict_field(dictParams, "suid"); //账号
    //到平台验证tocken是否正确
    const string& strTocken = get_dict_field(dictParams, "tocken");
    const string& strAccount = get_dict_field(dictParams, "plataccount");

	string app_key = this->get_cfg_value("key", "");
	string cfg_url = this->get_cfg_value("url", ""); 


    {
        string resp = "";

		ostringstream oss;
		oss << "?access_token=" <<strTocken.c_str();


		//请求: https: //openapi.360.cn/oauth2/get_token_info.json?access_token=48318605f40a967b0d0857c6029980aa8406440de382fd15
		string req_url = cfg_url + oss.str();
		int ret = GetUrl_new(req_url.c_str(), resp); //这里是get https请求
        if (ret != CURLE_OK)
        {
            LogWarning("check_login", "ret=%d;req=%s, params=%s", ret, req_url.c_str() );
            return ENUM_LOGIN_SERVER_BUSY;
        }

		LogDebug("check_login", "http_post ok ret = %s", resp.c_str());
        Trim(resp);

		JsonHelper jsonhp(resp);
		
		string get_app_key ;
		string get_user_id ;
		string get_expires_at ;
		string get_expires_in ;
		string error_code_rst = "";

		if (!jsonhp.GetJsonItem("error_code", error_code_rst))
		{
		}
		if (error_code_rst != "") // 返回有错误
		{
			LogWarning("login_jsonfailed", "error_code =%s", error_code_rst.c_str());
			return ENUM_LOGIN_PLAT_RETURN_ERROR;
		}	
		
		if (!jsonhp.GetJsonItem("app_key", get_app_key) )
		{
			LogWarning("login_jsonfailed", "app_key null");
			return ENUM_LOGIN_PLAT_RETURN_ERROR;
		}
		if (!jsonhp.GetJsonItem("user_id", get_user_id))
		{
			LogWarning("login_jsonfailed", "user_id null");
			return ENUM_LOGIN_PLAT_RETURN_ERROR;
		}

		if (!jsonhp.GetJsonItem("expires_at", get_expires_at))
		{
			LogWarning("login_jsonfailed", "expires_at null");
			return ENUM_LOGIN_PLAT_RETURN_ERROR;
		}

		if (!jsonhp.GetJsonItem("expires_in", get_expires_in))
		{
			LogWarning("login_jsonfailed", "expires_in null");
			return ENUM_LOGIN_PLAT_RETURN_ERROR;
		}	
		

		if (get_user_id != strSuid)
		{
			LogWarning("login_jsonfailed", "get_user_id not match  get_user_id(%s) != strSuid(%s)", get_user_id.c_str(), strSuid.c_str());
			return ENUM_LOGIN_PLAT_RETURN_ERROR;
		}
// 		if (get_app_key != app_key)
// 		{
// 			LogWarning("login_jsonfailed", "app_key not match  get_app_key(%s) != app_key(%s)", get_app_key.c_str(), app_key.c_str());
// 			return ENUM_LOGIN_PLAT_RETURN_ERROR;
// 
// 			LogWarning("login_jsonfailed", "app_key not match");
// 			return ENUM_LOGIN_PLAT_RETURN_ERROR;
// 		}

	}

    //需要返回的参数值
	strAccountGot.assign(strSuid);

	LogInfo("login_req", "%s", pszReq);
	return ENUM_LOGIN_SUCCESS;
}
