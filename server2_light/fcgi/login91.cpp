#include "login91.h"
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

CLogin91::CLogin91()
{
	m_str_plat_name = "91";
}

CLogin91::~CLogin91()
{

}



//校验请求是否正确
int CLogin91::check_login(const char* plat_name, const char* pszReq, string& strAccountGot)
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

	string key_91 = this->get_cfg_value("key", ""); 
	string cfg_url = this->get_cfg_value("url", ""); 
	int app_id_91 = this->get_cfg_value("app_id", 1078); 
	
	 
    {
        string resp = "";
		string req_url  = cfg_url;

		stringstream ss_pre_md5;
		stringstream ss_url_params;

		int nAct = 4;
		
		//MD5(Act=3&AppId=1078&SessionId=d891b6f03f361128b10c69d440c92c34&Uin=1326&Version=1.07a123456789b123456789c123456789d1)
		//ss_pre_md5 << "Act=4&AppId=" << app_id_91 << "&SessionId=" <<strTocken.c_str() << "&Uin=" <<strSuid.c_str()<<"&Version=1.07"<< key_91.c_str();

		ss_pre_md5 << app_id_91 << nAct << strSuid.c_str() << strTocken.c_str() << key_91.c_str();
		string req_sign = getmd5(ss_pre_md5.str().c_str());

		//?Act=3&AppId=1078&SessionId=d891b6f03f361128b10c69d440c92c34&Uin=1326&Version=1.07&Sign=090868eeaaf9ba3d8fcfecdeb1e6bc2e
		ss_url_params << "AppId=" << app_id_91 << "&Act="<<nAct << "&Uin=" <<strSuid.c_str() <<"&Sign="<< req_sign.c_str() << "&SessionId=" <<strTocken.c_str() ;

				
		LogDebug("check_login", "plat :%s  post url:%s params:%s", m_str_plat_name.c_str(), req_url.c_str(), ss_url_params.str().c_str());
        int ret = http_post(req_url.c_str(), ss_url_params.str().c_str(), resp); //这里是post请求
        if (ret != CURLE_OK)
        {
            LogWarning("check_login", "ret=%d;req=%s, params=%s", ret, req_url.c_str(), ss_url_params.str().c_str());
            return ENUM_LOGIN_SERVER_BUSY;
        }

		LogDebug("check_login", "http_post ok ret = %s", resp.c_str());

        Trim(resp);

		JsonHelper jsonhp(resp);
		string rst ;
		if (!jsonhp.GetJsonItem("ErrorCode", rst))
		{
			//平台返回字符串解析失败
			LogWarning("login_jsonfailed", "json=%s", resp.c_str());
			return ENUM_LOGIN_SDK_VERIFY_FAILED;
		}

        if (rst != "1") 
        {
            //结果码为"1"表示验证成功,其他值都是失败
            LogWarning("login_verifyfailed", "rst=%s;req=%s", rst.c_str(), pszReq);
            return ENUM_LOGIN_SDK_VERIFY_FAILED;            
        }
    }

    //需要返回的参数值
	strAccountGot.assign(strSuid);

	LogInfo("login_req", "%s", pszReq);
	return ENUM_LOGIN_SUCCESS;
}
