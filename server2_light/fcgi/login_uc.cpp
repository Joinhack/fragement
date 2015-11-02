#include "login_uc.h"
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


CLoginUC::CLoginUC()
{
	m_str_plat_name = "uc";
}

CLoginUC::~CLoginUC()
{

}



//校验请求是否正确
int CLoginUC::check_login(const char* plat_name, const char* pszReq, string& strAccountGot)
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
	string cfg_cpId = this->get_cfg_value("cpId", "");
	string cfg_gameId = this->get_cfg_value("gameId", "");	
	string cfg_apiKey = this->get_cfg_value("apiKey", "");
	string cfg_severId = this->get_cfg_value("severId", "");
	string cfg_channelId = this->get_cfg_value("channelId", "");

    {
        string resp = "";

		ostringstream url_params;
		ostringstream pre_md5;

		//MD5(cpId+sid=...+apiKey)
		pre_md5 <<cfg_cpId.c_str() << "sid=" << strTocken.c_str() << cfg_apiKey.c_str();

		string req_sign = getmd5(pre_md5.str());

		url_params << "{\r\n";
		url_params <<"\"id\":"<<time(NULL)<<",\r\n";
		url_params <<"\"service\":\"ucid.user.sidInfo\",\r\n";
		url_params <<"\"data\":{\"sid\":\""<< strTocken.c_str() << "\"},\r\n";
		url_params <<"\"game\":{\"cpId\":"<< cfg_cpId.c_str() << ",\"gameId\":"<< cfg_gameId.c_str() <<",\"channelId\":\""<<cfg_channelId.c_str()<<"\",\"serverId\":"<<cfg_severId.c_str()<<"},\r\n";
		url_params <<"\"sign\":\""<<req_sign.c_str()<<"\"\r\n";
		url_params <<"}";


		string req_url = cfg_url;
		int ret = http_post(req_url.c_str(), url_params.str().c_str(), resp); //这里是post请求
        if (ret != CURLE_OK)
        {
            LogWarning("check_login", "ret=%d;req=%s, params=%s", ret, req_url.c_str(),url_params.str().c_str() );
            return ENUM_LOGIN_SERVER_BUSY;
        }

		LogDebug("check_login", "http_post ok ret = %s, params=%s", resp.c_str(),url_params.str().c_str());

        Trim(resp);

		JsonHelper jsonhp(resp);

		int state = 0;
		if (!jsonhp.GetJsonItem2("state", "code", state))
		{
			LogWarning("parse json", "state.code not found in %s", resp.c_str());
			return ENUM_LOGIN_SDK_VERIFY_FAILED;
		}

		if (state != 1 )
		{
			LogWarning("parse json", "state.code(%d) != 1 ", state);
			return ENUM_LOGIN_SDK_VERIFY_FAILED;
		}

		int  ucid = 0;
		if (!jsonhp.GetJsonItem2("data", "ucid", ucid))
		{
			LogWarning("parse json error", "data.ucid not found in %s", resp.c_str());
			return ENUM_LOGIN_SDK_VERIFY_FAILED;
		}
		ostringstream oss_ucid;
		oss_ucid<<ucid;

		//需要返回的参数值
		strAccountGot.assign(oss_ucid.str());		


	}

    
	//strAccountGot.assign(oss_ucid.str());

	LogInfo("login_req", "%s", pszReq);
	return ENUM_LOGIN_SUCCESS;
}
