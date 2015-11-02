#ifndef __LOGIN_UC_HEAD__
#define __LOGIN_UC_HEAD__

#include "type_mogo.h"
#include "login_base.h"
#include <string>
#include "cjson.h"
using namespace std;


//平台接口
class CLoginUC : public CLoginBase
{
public:
	CLoginUC();
	~CLoginUC();

public:
	//校验请求是否正确
	int check_login(const char* plat_name, const char* pszReq, string& strAccount);	
private:

	
};


#endif

