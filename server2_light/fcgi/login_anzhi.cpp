#include "login_anzhi.h"
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
#include "base64.h"
#include "json_helper.h"

CLoginAnzhi::CLoginAnzhi()
{
	m_str_plat_name = "anzhi";
}

CLoginAnzhi::~CLoginAnzhi()
{

}



//校验请求是否正确
int CLoginAnzhi::check_login(const char* plat_name, const char* pszReq, string& strAccountGot)
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

	string app_secret = this->get_cfg_value("key", ""); 
	string cfg_url = this->get_cfg_value("url", ""); 
	string app_key = this->get_cfg_value("app_id", ""); 

	char sz_time[32] = {0};
	//sprintf(sz_time, "%04d%02d%02d%2d%02d%2d%03d", )  



	struct timeval tv;
	if(gettimeofday(&tv, NULL)==0)
	{
		time_t& t = tv.tv_sec;
		struct tm* tm2 = localtime(&t);

		//请求时间 yyyyMMddHHmmssSSS 精确到毫秒,	例如：20130703103856771
		snprintf(sz_time, 32, "%04d%02d%02d%2d%02d%2d%03d",\
			tm2->tm_year +1900 , tm2->tm_mon +1, tm2->tm_mday,tm2->tm_hour,tm2->tm_min, tm2->tm_sec, tv.tv_usec/1000);
	}
	
// 		time=20130228101059123&
// 		appkey=fds12121&
// 		sid=xxxxxx&
// 		sign=xxxx

    {
        string resp = "";
		string req_url  = cfg_url;

		stringstream ss_pre_md5;
		stringstream ss_url_params;

		//Base64.encodeToString (appkey+sid+appsecret);  //sid为 sessionid
		ss_pre_md5 <<app_key.c_str() <<strTocken.c_str()<<app_secret.c_str();

		string req_sign = base64_encode((unsigned const char*)ss_pre_md5.str().c_str(), ss_pre_md5.str().length());


		// 1.time  请求时间 yyyyMMddHHmmssSSS 精确到毫秒
		// 例如：20130703103856771
		// 2.appkey 应用 key
		// 3.sid 当前登录用户会话 id
		// 4.sign 签名串，格式
		// Base64.encodeToString (appkey+sid+appsecret);
		//?time=3&appkey=1078&sid=d891b6f03f361128b10c69d440c92c34&sign=
		ss_url_params << "time=" << sz_time << "&appkey=" <<app_key.c_str() << "&sid=" <<strTocken.c_str()<<"&sign="<< req_sign.c_str();

				
		LogDebug("check_login", "plat :%s  post url:%s params:%s", m_str_plat_name.c_str(), req_url.c_str(), ss_url_params.str().c_str());
        int ret = http_post(req_url.c_str(), ss_url_params.str().c_str(), resp); //这里是post请求
        if (ret != CURLE_OK)
        {
            LogWarning("check_login", "ret=%d;req=%s, params=%s", ret, req_url.c_str(), ss_url_params.str().c_str());
            return ENUM_LOGIN_SERVER_BUSY;
        }

		LogDebug("check_login", "http_post ok ret = %s", resp.c_str());

        Trim(resp);
		string_replace(resp, "'","\"");//呵呵，安智 ，返回个错误的json结构 还要我来处理

		JsonHelper jsonhp(resp);
		string rst;
		if (!jsonhp.GetJsonItem("sc", rst))
		{
			//平台返回字符串解析失败
			LogWarning("login_jsonfailed", "json=%s", resp.c_str());
			return ENUM_LOGIN_SDK_VERIFY_FAILED;
		}	

        if (rst != "1" && rst != "200")
        {
            //结果码为0表示验证成功,其他值都是失败
            LogWarning("login_verifyfailed", "rst=%s;req=%s", rst.c_str(), pszReq);
            return ENUM_LOGIN_SDK_VERIFY_FAILED;            
        }		

	}



    //需要返回的参数值
	strAccountGot.assign(strSuid);

	LogInfo("login_req", "%s", pszReq);
	return ENUM_LOGIN_SUCCESS;
}


void CLoginAnzhi::string_replace(std::string& strBig, const std::string & strsrc, const std::string &strdst)
{
	std::string::size_type pos = 0;
	while( (pos = strBig.find(strsrc, pos)) != string::npos)
	{
		strBig.replace(pos, strsrc.length(), strdst);
		pos += strdst.length();
	}
}

