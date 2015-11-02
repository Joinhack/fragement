#ifndef __IF_BASE_HEAD__
#define __IF_BASE_HEAD__

#include "my_stl.h"
#include "fcgi_def.h"


//平台接口的实现抽象基类
class CIfBase
{
public:
	CIfBase();
	virtual ~CIfBase();

public:
	virtual void login(const char* pszPathInfo, const char* pszReq) = 0;
	//数据中心api
	virtual void data_center_api(const char* pszFunc, const char* pszParams) = 0;
	//平台api
	virtual void plat_api(const char* pszFunc, const char* pszParams) = 0;
	//激活码中心发来的发送礼包
	virtual void add_gift(const char* remote_addr, const char* pszFunc, const char* pszParams) = 0;

	virtual void charge(const char* remote_addr, const char* pszPathInfo, const char* pszReq)=0;
	

public:
    void SetServName(const char* pszServName);

protected:
    string m_strServName;

};


extern const string& get_dict_field(const map<string, string>& dict, const string& strKey);
//兼容getenv返回NULL和""两种情况
extern char* my_getenv(const char* s);

extern string getmd5(const string& src) ;


#endif
