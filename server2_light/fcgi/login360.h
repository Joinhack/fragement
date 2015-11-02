#ifndef __LOGIN360_HEAD__
#define __LOGIN360_HEAD__

#include "type_mogo.h"
#include "login_base.h"
#include <string>
#include "cjson.h"
using namespace std;


//平台接口
class CLogin360 : public CLoginBase
{
public:
	CLogin360();
	~CLogin360();

public:
	//校验请求是否正确
	int check_login(const char* plat_name, const char* pszReq, string& strAccount);	
private:

	
};


#endif

