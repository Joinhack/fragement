#ifndef __LOGIN_PPS_HEAD__
#define __LOGIN_PPS_HEAD__

#include "type_mogo.h"
#include "login_base.h"
#include <string>
using namespace std;


//ƽ̨�ӿ�
class CLoginPPS : public CLoginBase
{
public:
	CLoginPPS();
	~CLoginPPS();

public:
	//У�������Ƿ���ȷ
	int check_login(const char* plat_name, const char* pszReq, string& strAccount);	
};


#endif

