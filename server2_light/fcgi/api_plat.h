#ifndef __IF_PLAT_API_HEAD__
#define __IF_PLAT_API_HEAD__


#include "api_base.h"

typedef const string (*GetMD5Str)(map<string, string> & dictParams);
typedef map<string, GetMD5Str> T_GetMD5Methods;

//平台api接口
class CPlatApi : public CApiBase
{
public:
	CPlatApi();
	~CPlatApi(){};
	void init();
	bool check_md5(const char* key, const char* pszReq, const char* apiName = "");
	
private:

	string make_md5_str(map<string, string> & dictParams, const char* apiName, const char* key);		// 根据dictParams 获得md5运算的字符串
	string ParamsToChar(map<string, string>& params);			// 将各个参数串成一个字符串，用于计算MD5
	T_GetMD5Methods m_getMd5Methods;
};

const string get_md5_str_user_online(map<string, string> & dictParams);
const string get_md5_str_user_role_info(map<string, string> & dictParams);
const string get_md5_str_user_upgrade(map<string, string> & dictParams);
#endif

