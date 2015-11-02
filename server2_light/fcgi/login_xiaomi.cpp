#include "login_xiaomi.h"
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
#include <openssl/hmac.h>  
#include <openssl/evp.h>
#include <sstream>
#include <assert.h>
#include "json_helper.h"

CLoginXiaomi::CLoginXiaomi()
{
	m_str_plat_name = "mi";
}

CLoginXiaomi::~CLoginXiaomi()
{

}



//校验请求是否正确
int CLoginXiaomi::check_login(const char* plat_name, const char* pszReq, string& strAccountGot)
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
	int appId = this->get_cfg_value("app_id", 0); 
	 
    {
        string resp = "";
		string req_url  = cfg_url;

		stringstream ss_pre_md5;
		stringstream ss_url_params;

		
		ss_pre_md5 << "appId=" << appId << "&session=" <<strTocken.c_str() << "&uid=" <<strSuid.c_str();

		string req_sign = hmac_sha1(ss_pre_md5.str().c_str(),app_key.c_str());//这里是hmac_sha1签名

		ss_url_params << "?appId=" << appId << "&session=" <<strTocken.c_str() << "&uid=" <<strSuid.c_str()<<"&signature="<< req_sign.c_str();

		req_url +=  ss_url_params.str().c_str();
				
		LogDebug("check_login", "plat :%s  post url:%s params:%s", m_str_plat_name.c_str(), req_url.c_str(), ss_url_params.str().c_str());
        int ret = GetUrl_new(req_url.c_str(),  resp); //这里是get请求
        if (ret != CURLE_OK)
        {
            LogWarning("check_login", "ret=%d;req=%s", ret, req_url.c_str());
            return ENUM_LOGIN_SERVER_BUSY;
        }

		LogDebug("check_login", "http_post ok ret = %s", resp.c_str());

        Trim(resp);
		
		JsonHelper jsonhp(resp);
		int rst = 0;
		if (!jsonhp.GetJsonItem("errcode", rst))
		{
			//平台返回字符串解析失败
			LogWarning("login_jsonfailed", "json=%s", resp.c_str());
			return ENUM_LOGIN_SDK_VERIFY_FAILED;
		}	

        if (rst != 200) //200为成功
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




int CLoginXiaomi::HmacEncode(const char * algo,  
			   const char * key, unsigned int key_length,  
			   const char * input, unsigned int input_length,  
			   unsigned char * &output, unsigned int &output_length) {  
				   const EVP_MD * engine = NULL;  
				   if(strcasecmp("sha512", algo) == 0) {  
					   engine = EVP_sha512();  
				   }  
				   else if(strcasecmp("sha256", algo) == 0) {  
					   engine = EVP_sha256();  
				   }  
				   else if(strcasecmp("sha1", algo) == 0) {  
					   engine = EVP_sha1();  
				   }  
				   else if(strcasecmp("md5", algo) == 0) {  
					   engine = EVP_md5();  
				   }  
				   else if(strcasecmp("sha224", algo) == 0) {  
					   engine = EVP_sha224();  
				   }  
				   else if(strcasecmp("sha384", algo) == 0) {  
					   engine = EVP_sha384();  
				   }  
				   else if(strcasecmp("sha", algo) == 0) {  
					   engine = EVP_sha();  
				   }  
				   else if(strcasecmp("md2", algo) == 0) {  
				   	assert(false);
					   //engine = EVP_md2();  
				   }  
				   else {  
					   cout << "Algorithm " << algo << " is not supported by this program!" << endl;  
					   return -1;  
				   }  

				   output = (unsigned char*)malloc(EVP_MAX_MD_SIZE);  

				   HMAC_CTX ctx;  
				   HMAC_CTX_init(&ctx);  
				   HMAC_Init_ex(&ctx, key, strlen(key), engine, NULL);  
				   HMAC_Update(&ctx, (unsigned char*)input, strlen(input));        // input is OK; &input is WRONG !!!  

				   HMAC_Final(&ctx, output, &output_length);  
				   HMAC_CTX_cleanup(&ctx);  

				   return 0;  
}  




string CLoginXiaomi::hmac_sha1(const string & data, const char * key)
{	

	unsigned char * mac = NULL;
	unsigned int mac_length = 0;

	int ret = HmacEncode("sha1", key, strlen(key), data.c_str(), data.length(), mac, mac_length);

	if(0 != ret) 
	{  
		return "";  
	}  
	
	ostringstream result;
	for(unsigned int i = 0; i < mac_length; i++) 
	{  
		//printf("%-03x", (unsigned int)mac[i]);  
		char tmp[10] ={0};
		snprintf(tmp,10, "%02x", (unsigned int)mac[i]);
		result << tmp;		
	}  


	if(mac) {  
		free(mac);  
	}  

	return result.str();  

}

