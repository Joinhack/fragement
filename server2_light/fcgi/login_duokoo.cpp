#include "login_duokoo.h"
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

CLoginDuokoo::CLoginDuokoo()
{
	m_str_plat_name = "DK";
}

CLoginDuokoo::~CLoginDuokoo()
{

}



//校验请求是否正确
int CLoginDuokoo::check_login(const char* plat_name, const char* pszReq, string& strAccountGot)
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
	int cfg_appid = this->get_cfg_value("appid", 0); 
	string cfg_appkey = this->get_cfg_value("appkey", ""); 
	string cfg_appsecret = this->get_cfg_value("appsecret", ""); 

	 
    {
        string resp = "";
		string req_url  = cfg_url;

		stringstream ss_pre_md5;
		stringstream ss_url_params;

		//strtolower(md5($appid$appkey$uid$sessionid$AppSecret));		
		ss_pre_md5 << cfg_appid << cfg_appkey.c_str() << strSuid.c_str() << cfg_appsecret.c_str();

		string req_sign = getmd5(ss_pre_md5.str().c_str());

		//?appid=3&AppId=1078&SessionId=d891b6f03f361128b10c69d440c92c34&Uin=1326&Version=1.07&Sign=090868eeaaf9ba3d8fcfecdeb1e6bc2e
		ss_url_params << "?appid=" << cfg_appid << "&appkey=" <<cfg_appkey.c_str() << "&uid=" <<strSuid.c_str()<<"&sessionid="<< strTocken.c_str() <<"&clientsecret=" <<req_sign.c_str();
		
		req_url += ss_url_params.str();

		LogDebug("check_login", "plat :%s  post url:%s params:%s", m_str_plat_name.c_str(), req_url.c_str(), ss_url_params.str().c_str());
        int ret = GetUrl_new(req_url.c_str(),  resp); //这里是get请求 也可以post
        if (ret != CURLE_OK)
        {
            LogWarning("check_login", "ret=%d;req=%s, params=%s", ret, req_url.c_str(), ss_url_params.str().c_str());
            return ENUM_LOGIN_SERVER_BUSY;
        }

		LogDebug("check_login", "get_url ok ret = %s", resp.c_str());

        Trim(resp);

		int rst = 0;
		JsonHelper jsonhp(resp);
		if (!jsonhp.GetJsonItem("error_code", rst))
		{
			LogWarning("login_jsonfailed", "json=%s", resp.c_str());
			return ENUM_LOGIN_SDK_VERIFY_FAILED;
		}     

        if (rst != 0)
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
