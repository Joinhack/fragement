#ifndef __LOGIN_UC_HEAD__
#define __LOGIN_UC_HEAD__

#include "type_mogo.h"
#include "login_base.h"
#include <string>
#include "cjson.h"
using namespace std;


//ƽ̨�ӿ�
class CLoginUC : public CLoginBase
{
public:
	CLoginUC();
	~CLoginUC();

public:
	//У�������Ƿ���ȷ
	int check_login(const char* plat_name, const char* pszReq, string& strAccount);	
private:

	
};


#endif

