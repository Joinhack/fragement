#ifndef __LOGIN4399_HEAD__
#define __LOGIN4399_HEAD__

#include "type_mogo.h"
#include "login_base.h"
#include <string>
using namespace std;


//平台接口
class CLogin4399 :public CLoginBase
{
public:
	CLogin4399();
	~CLogin4399();

public:
	//校验请求是否正确
	int check_login(const char* plat_name, const char* pszReq, string& strAccount);	
};


#endif

