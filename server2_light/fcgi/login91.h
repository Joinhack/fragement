#ifndef __LOGIN91_HEAD__
#define __LOGIN91_HEAD__

#include "type_mogo.h"
#include "login_base.h"
#include <string>
using namespace std;


//ƽ̨�ӿ�
class CLogin91 : public CLoginBase
{
public:
	CLogin91();
	~CLogin91();

public:
	//У�������Ƿ���ȷ
	int check_login(const char* plat_name, const char* pszReq, string& strAccount);	
};


#endif

