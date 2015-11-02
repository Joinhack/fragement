#ifndef __CHARGE_APPSTORE__
#define __CHARGE_APPSTORE__

#include "type_mogo.h"
#include "login_base.h"
#include <string>
#include <map>
using namespace std;


//ƽ̨�ӿ�
class CChargeAppStore : public CLoginBase
{
public:
	CChargeAppStore();
	~CChargeAppStore();

public:
	//У�������Ƿ���ȷ
	int check_login(const char* plat_name, const char* pszReq, string& strAccount);	
private:
	map<string,string> m_mpProductId;
};


#endif

