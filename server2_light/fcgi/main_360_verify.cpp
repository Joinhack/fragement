//360����ӿ���Ϸ����cgi
#include <unistd.h>

#include "iffactory.h"
#include "world_base.h"
#include <fcgi_config.h>
#include <fcgi_stdio.h>
#include "cgicfg.h"
#include <curl/curl.h> 
#include "cjson.h"
#include "json_helper.h"


world* g_pTheWorld = new CWorldBase;


string& trim_360_json(string& s)
{
    //��libcurl���ص�360json�ַ�������ܸ�����\r\n0\r\n\r\n����Ϣ,��Ҫ����
    //string s = "{\"error_code\":\"4010203\",\"error\":\"auth codeafsfa\"}\r\n0\r\n\r\n";

    string::size_type n = s.rfind("}");
    if(n != string::npos)
    {
        s.erase(n).append("}");
    }

    return s;
}


int get_tocken_by_code(const map<string, string>& dictParams);
int get_userinfo_by_tocken(const map<string, string>& dictParams);


int _dispatch_req(const char* pszReq)
{
    map<string, string> dictParams;
    SplitStringToMap(pszReq, '&', '=', dictParams); 

    const string& strType = get_dict_field(dictParams, "type");
    const static char szGetTocken[] = "get_tocken_by_code";
    const static char szGetUserInfo[] = "get_userinfo_by_token";
    if(strType.compare(szGetTocken) == 0)
    {
        //����֤�뻻tocken
        return get_tocken_by_code(dictParams);
    }
    else if(strType.compare(szGetUserInfo) == 0)
    {
        //��ȡ�û���Ϣ
        return get_userinfo_by_tocken(dictParams);
    }

    return -99;
}

int dispatch_req(const char* pszReq)
{
    int nRet = _dispatch_req(pszReq);
    if(nRet != 0)
    {
        static const char* szRetTpl = "Content-type: text/html\r\n\r\n{\"status\":\"err_%d\",\"data\":{}}";
        FCGI_printf(szRetTpl, nRet);
    }
}

int get_tocken_by_code(const map<string, string>& dictParams)
{
    //url/app_key/app_secretҪ���ó�ȥ
    const string& strCode = get_dict_field(dictParams, "code");
    const static char szUrlTpl[] = "https://openapi.360.cn/oauth2/access_token?grant_type=authorization_code&code=%s&client_id=%s&client_secret=%s&redirect_uri=oob";
    char szUrl[512];
    memset(szUrl, 0, sizeof(szUrl));
    snprintf(szUrl, sizeof(szUrl), szUrlTpl, strCode.c_str(), "2149349215f7798e9a8216779d730385", "d2f33aa24eafc614b4682ee132df95c2");

    string resp;    
    int ret = GetUrl_new(szUrl, resp); //������get https����
    if (ret != CURLE_OK)
    {
        return -1;
    }

    //static const char szRetTpl11[] = "Content-type: text/html\r\n\r\n{\"status\":\"ok\",\"data\":%s\0";
    //FCGI_printf(szRetTpl11, resp.c_str());
    //g_logger.SetLogPath("/data/server/cgi-bin/log/v360");
    //LogError("verify", "%s", resp.c_str());

    Trim(trim_360_json(resp));    

	JsonHelper jsonhp(resp);
	string strError;
	if (jsonhp.GetJsonItem("error_code", strError))
	{
		//����ʧ��,������error_code
		return -3;
	}   

    //�ظ���ʽģ��,ע��:����ɹ���󷵻��������ַ���
    static const char* szRetTpl = "Content-type: text/html\r\n\r\n{\"status\":\"ok\",\"data\":%s}";
    FCGI_printf(szRetTpl, resp.c_str());

    return 0;
}

int get_userinfo_by_tocken(const map<string, string>& dictParams)
{
    //url/app_key/app_secretҪ���ó�ȥ
    const string& strCode = get_dict_field(dictParams, "tocken");
    const static char szUrlTpl[] = "https://openapi.360.cn/user/me.json?access_token=%s&fields=id,name,avatar,sex,area";
    char szUrl[512];
    memset(szUrl, 0, sizeof(szUrl));
    snprintf(szUrl, sizeof(szUrl), szUrlTpl, strCode.c_str());

    string resp;    
    int ret = GetUrl_new(szUrl, resp); //������get https����
    if (ret != CURLE_OK)
    {
        return -1;
    }

    //static const char szRetTpl11[] = "Content-type: text/html\r\n\r\n{\"status\":\"ok\",\"data\":%s\0";
    //FCGI_printf(szRetTpl11, resp.c_str());
    //g_logger.SetLogPath("/data/server/cgi-bin/log/v360");
    //LogError("verify", "%s", resp.c_str());

    Trim(trim_360_json(resp));    


	JsonHelper jsonhp(resp);
	string strError;
	if (jsonhp.GetJsonItem("error_code", strError))
	{
		//����ʧ��,������error_code
		return -3;
	}   
	
    //�ظ���ʽģ��,ע��:����ɹ���󷵻��������ַ���
    static const char* szRetTpl = "Content-type: text/html\r\n\r\n{\"status\":\"ok\",\"data\":%s}";
    FCGI_printf(szRetTpl, resp.c_str());

    return 0;

}

int main()
{
    char **initialEnv = environ; 

    g_cgi_cfg = new CCgiCfg("/data/server/cgi-bin/sh/cgi_cfg.txt");

    while (FCGI_Accept() >= 0) 
    {	
        char* pszReq = my_getenv("QUERY_STRING");
        dispatch_req(pszReq);
    }

    delete (CWorldBase*)g_pTheWorld;

    return 0;
}
