#ifndef __LOGINDUOKOO_HEAD__
#define __LOGINDUOKOO_HEAD__

#include "type_mogo.h"
#include "login_base.h"
#include <string>
using namespace std;


//ƽ̨�ӿ�
class CLoginDuokoo : public CLoginBase
{
public:
	CLoginDuokoo();
	~CLoginDuokoo();

public:
	//У�������Ƿ���ȷ
	int check_login(const char* plat_name, const char* pszReq, string& strAccount);	
};


#endif

