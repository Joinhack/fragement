#ifndef __API_BASE_HEAD__
#define __API_BASE_HEAD__

#include "ifbase.h"
#include "pluto.h"
#include <string>
#include <map>
#include <openssl/md5.h>
using namespace std;

//api接口
class CApiBase
{

public:
	virtual bool check_md5(const char* key, const char* pszReq, const char* apiName = "")=0;
};


#endif

