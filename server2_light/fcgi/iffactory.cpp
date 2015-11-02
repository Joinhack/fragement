#ifdef _WIN32
	#define strcasecmp strcmp
#else
	#include <strings.h>
#endif

#include "iffactory.h"



CLogin4399*		CIfFactory::plogin_4399 =	new CLogin4399;
CLogin91*		CIfFactory::plogin_91 =		new CLogin91;
CLoginPPTV*		CIfFactory::plogin_pptv =	new CLoginPPTV;
CLoginDangle*	CIfFactory::plogin_dangle =	new CLoginDangle;
CLogin360*		CIfFactory::plogin_360 =	new CLogin360;
CLoginUC*		CIfFactory::plogin_uc =		new CLoginUC;
CLoginXiaomi*	CIfFactory::plogin_xiaomi =	new CLoginXiaomi;
CLoginPPS*		CIfFactory::plogin_pps =	new CLoginPPS;
CLoginDuokoo*	CIfFactory::plogin_duokoo =	new CLoginDuokoo;
CLoginAnzhi*		CIfFactory::plogin_anzhi =	new CLoginAnzhi;



CIfBase* CIfFactory::getIfObj()
{
    return new CIf4399;

	//const char* pszPlatform = getenv("PLATFORM");	//从环境变量中获取平台名称
	//if(pszPlatform)
	//{
	//	if(strcasecmp(pszPlatform, "4399") == 0)
	//	{
	//		return new CIf4399;
	//	}
	//}

	//return NULL;
}


CLoginBase* CIfFactory::getLoginObj(const char* plat_name)
{
	if(plat_name)
	{
		if(strcasecmp(plat_name, "4399") == 0)
		{
			return  plogin_4399;
		}
		else if(strcasecmp(plat_name, "91") == 0)
		{
			return  plogin_91;
		}
		else if(strcasecmp(plat_name, "pptv") == 0)
		{
			return  plogin_pptv;
		}
		else if(strcasecmp(plat_name, "dangle") == 0)
		{
			return  plogin_dangle;
		}
		else if(strcasecmp(plat_name, "360") == 0)
		{
			return  plogin_360;
		}
		else if(strcasecmp(plat_name, "uc") == 0)
		{
			return  plogin_uc	;
		}
		else if(strcasecmp(plat_name, "mi") == 0)
		{
			return  plogin_xiaomi;
		}
		else if(strcasecmp(plat_name, "pps") == 0)
		{
			return  plogin_pps;
		}
		else if(strcasecmp(plat_name, "DK") == 0)
		{
			return  plogin_duokoo;
		}
		else if (strcasecmp(plat_name, "anzhi") == 0)
		{
			return plogin_anzhi;
		}
		else if (strcasecmp(plat_name, "appstore") == 0)
		{
			return plogin_4399; //ios登陆用的是4399的账号
		}
		else 
		{
			return plogin_4399; 
		}

		
	}

	return NULL;
}

