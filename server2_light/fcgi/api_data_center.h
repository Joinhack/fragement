#ifndef __IF_DATA_CENTER_HEAD__
#define __IF_DATA_CENTER_HEAD__


#include "api_base.h"

//数据中心api接口
class CDataCenterApi : public CApiBase
{
public:

	bool check_md5(const char* key, const char* pszReq, const char* apiName = "");

private:
	
	string make_md5_str(map<string, string> & dictParams, const char* key);		// 根据dictParams 获得md5运算的字符串
	string ParamsToChar(map<string, string>& params);			// 将各个参数串成一个字符串，用于计算MD5


};


#endif

