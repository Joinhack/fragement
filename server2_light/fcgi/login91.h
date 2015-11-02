#ifndef __LOGIN91_HEAD__
#define __LOGIN91_HEAD__

#include "type_mogo.h"
#include "login_base.h"
#include <string>
using namespace std;


//平台接口
class CLogin91 : public CLoginBase
{
public:
	CLogin91();
	~CLogin91();

public:
	//校验请求是否正确
	int check_login(const char* plat_name, const char* pszReq, string& strAccount);	
};


#endif

