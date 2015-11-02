#include "login_dangle.h"
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

CLoginDangle::CLoginDangle()
{
	m_str_plat_name = "dangle";
}

CLoginDangle::~CLoginDangle()
{

}



//校验请求是否正确
int CLoginDangle::check_login(const char* plat_name, const char* pszReq, string& strAccountGot)
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
	string app_key = this->get_cfg_value("key", ""); 
	int app_id = this->get_cfg_value("app_id", 0); 
	 
    {
        string resp = "";
		string req_url  = cfg_url;

		stringstream ss_pre_md5;
		stringstream ss_url_params;

		//MD5(token|mid)
		ss_pre_md5 << strTocken.c_str() << "|" <<app_key.c_str();

		string req_sign = getmd5(ss_pre_md5.str().c_str());

		//params
		ss_url_params << "?app_id=" << app_id  << "&mid=" <<strSuid.c_str()<< "&token=" <<strTocken.c_str()<<"&sig="<< req_sign.c_str();

		req_url += ss_url_params.str().c_str();
				
		LogDebug("check_login", "plat :%s  post url:%s params:%s", m_str_plat_name.c_str(), req_url.c_str(), ss_url_params.str().c_str());
        int ret = GetUrl_new(req_url.c_str(), resp); //这里是get请求
        if (ret != CURLE_OK)
        {
            LogWarning("check_login", "ret=%d;req=%s", ret, req_url.c_str());
            return ENUM_LOGIN_SERVER_BUSY;
        }

		LogDebug("check_login", "http_post ok ret = %s", resp.c_str());

        Trim(resp);

		JsonHelper jsonhp(resp);
		int rst = 0;
		if (!jsonhp.GetJsonItem("error_code", rst))
		{
			//平台返回字符串解析失败
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
