#include "login_base.h"
#include "logger.h"
#include "cgicfg.h"

CLoginBase::CLoginBase()
{

}

CLoginBase::~CLoginBase()
{

}


//从配置文件读取配置项的值
string CLoginBase::get_cfg_value(const char* pszName, const char* pszDefault)
{
	string section = (string)"login_" + m_str_plat_name;
	string strValue = g_cgi_cfg->GetValue( section.c_str(), pszName); //这里是平台名为section
	if(strValue.empty())
	{
		return string(pszDefault);
	}

	return strValue;
}

int CLoginBase::get_cfg_value(const char* pszName, int nDefault)
{
	string section = (string)"login_" + m_str_plat_name;

	string strValue = g_cgi_cfg->GetValue(+ section.c_str(), pszName); //这里是平台名为section
	if(strValue.empty())
	{
		return nDefault;
	}

	return atoi(strValue.c_str());
}

