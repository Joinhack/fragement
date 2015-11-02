#include "login_base.h"
#include "logger.h"
#include "cgicfg.h"

CLoginBase::CLoginBase()
{

}

CLoginBase::~CLoginBase()
{

}


//�������ļ���ȡ�������ֵ
string CLoginBase::get_cfg_value(const char* pszName, const char* pszDefault)
{
	string section = (string)"login_" + m_str_plat_name;
	string strValue = g_cgi_cfg->GetValue( section.c_str(), pszName); //������ƽ̨��Ϊsection
	if(strValue.empty())
	{
		return string(pszDefault);
	}

	return strValue;
}

int CLoginBase::get_cfg_value(const char* pszName, int nDefault)
{
	string section = (string)"login_" + m_str_plat_name;

	string strValue = g_cgi_cfg->GetValue(+ section.c_str(), pszName); //������ƽ̨��Ϊsection
	if(strValue.empty())
	{
		return nDefault;
	}

	return atoi(strValue.c_str());
}

