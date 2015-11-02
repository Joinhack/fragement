#ifndef __LOGIN_BASE__
#define __LOGIN_BASE__

#include <string>
using namespace std;



class CLoginBase
{
public:
	CLoginBase();
	~CLoginBase();

public:
	//校验请求是否正确
	virtual int check_login(const char* plat_name, const char* pszReq, string& strAccount) = 0;
	

public:
	//从配置文件读取配置项的值 section 为平台名
	string get_cfg_value(const char* pszName, const char* pszDefault);
	int get_cfg_value(const char* pszName, int nDefault);	
	

protected:
	string m_strServName;
	string m_str_plat_name;;
};


#endif

