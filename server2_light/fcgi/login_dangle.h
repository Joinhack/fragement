#ifndef __LOGIN_DANGLE_HEAD__
#define __LOGIN_DANGLE_HEAD__

#include "type_mogo.h"
#include "login_base.h"
#include <string>
using namespace std;


//ƽ̨�ӿ�
class CLoginDangle : public CLoginBase
{
public:
	CLoginDangle();
	~CLoginDangle();

public:
	//У�������Ƿ���ȷ
	int check_login(const char* plat_name, const char* pszReq, string& strAccount);	
};


#endif

