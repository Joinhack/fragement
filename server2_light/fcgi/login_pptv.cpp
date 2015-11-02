#include "login_pptv.h"
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

CLoginPPTV::CLoginPPTV()
{
	m_str_plat_name = "pptv";
}

CLoginPPTV::~CLoginPPTV()
{

}



//校验请求是否正确
int CLoginPPTV::check_login(const char* plat_name, const char* pszReq, string& strAccountGot)
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
	

	string cfg_url = this->get_cfg_value("url", ""); 
	 
    {
        string resp = "";
		string req_url  = cfg_url;

		stringstream ss_url_params;
		
		//?Act=3&AppId=1078&SessionId=d891b6f03f361128b10c69d440c92c34&Uin=1326&Version=1.07&Sign=090868eeaaf9ba3d8fcfecdeb1e6bc2e
		ss_url_params << "?type=login&sessionid=" <<strTocken.c_str() << "&username=" <<strAccount.c_str()<<"&app=mobgame";

		req_url += ss_url_params.str().c_str();

		LogDebug("check_login", "plat :%s  get url:%s ", m_str_plat_name.c_str(), req_url.c_str());
        int ret = GetUrl_new(req_url.c_str(), resp); //这里是post请求
        if (ret != CURLE_OK)
        {
            LogWarning("check_login", "ret=%d;req=%s, params=%s", ret, req_url.c_str(), ss_url_params.str().c_str());
            return ENUM_LOGIN_SERVER_BUSY;
        }
		LogDebug("check_login", "http_post ok ret = %s", resp.c_str());



        Trim(resp);

		JsonHelper jsonhp(resp);
		int rst = 0;
		if (!jsonhp.GetJsonItem("status", rst))
		{
			//平台返回字符串解析失败
			LogWarning("login_jsonfailed", "json=%s", resp.c_str());
			return ENUM_LOGIN_SDK_VERIFY_FAILED;
		}	

	
		if (rst != 1) 
		{
			//结果码为0表示验证成功,其他值都是失败
			LogWarning("login_verifyfailed", "rst=%d;req=%s", rst, pszReq);
			return ENUM_LOGIN_SDK_VERIFY_FAILED;            
		}

    }

    //需要返回的参数值
	strAccountGot.assign(strSuid);

	LogInfo("login_req", "%s", pszReq);
	return ENUM_LOGIN_SUCCESS;
}
