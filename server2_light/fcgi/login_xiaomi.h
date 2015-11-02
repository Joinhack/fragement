#ifndef __LOGIN_XIAOMI_HEAD__
#define __LOGIN_XIAOMI_HEAD__

#include "type_mogo.h"
#include "login_base.h"
#include <string>
using namespace std;


//平台接口
class CLoginXiaomi : public CLoginBase
{
public:
	CLoginXiaomi();
	~CLoginXiaomi();

public:
	//校验请求是否正确
	int check_login(const char* plat_name, const char* pszReq, string& strAccount);	
private:
	//string get_sign(const char* str, const char* key);
	int HmacEncode(const char * algo,
		const char * key, unsigned int key_length,
		const char * input, unsigned int input_length,
		unsigned char * &output, unsigned int &output_length) ;

	string hmac_sha1(const string & data, const char * key);
};


#endif

