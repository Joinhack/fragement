#ifndef __CHARGE_APPSTORE__
#define __CHARGE_APPSTORE__

#include "type_mogo.h"
#include "login_base.h"
#include <string>
#include <map>
using namespace std;


//平台接口
class CChargeAppStore : public CLoginBase
{
public:
	CChargeAppStore();
	~CChargeAppStore();

public:
	//校验请求是否正确
	int check_login(const char* plat_name, const char* pszReq, string& strAccount);	
private:
	map<string,string> m_mpProductId;
};


#endif

