#ifndef __LOGIN4399_HEAD__
#define __LOGIN4399_HEAD__

#include "type_mogo.h"
#include "login_base.h"
#include <string>
using namespace std;


//ƽ̨�ӿ�
class CLogin4399 :public CLoginBase
{
public:
	CLogin4399();
	~CLogin4399();

public:
	//У�������Ƿ���ȷ
	int check_login(const char* plat_name, const char* pszReq, string& strAccount);	
};


#endif

