#ifndef __IF_BASE_HEAD__
#define __IF_BASE_HEAD__

#include "my_stl.h"
#include "fcgi_def.h"


//ƽ̨�ӿڵ�ʵ�ֳ������
class CIfBase
{
public:
	CIfBase();
	virtual ~CIfBase();

public:
	virtual void login(const char* pszPathInfo, const char* pszReq) = 0;
	//��������api
	virtual void data_center_api(const char* pszFunc, const char* pszParams) = 0;
	//ƽ̨api
	virtual void plat_api(const char* pszFunc, const char* pszParams) = 0;
	//���������ķ����ķ������
	virtual void add_gift(const char* remote_addr, const char* pszFunc, const char* pszParams) = 0;

	virtual void charge(const char* remote_addr, const char* pszPathInfo, const char* pszReq)=0;
	

public:
    void SetServName(const char* pszServName);

protected:
    string m_strServName;

};


extern const string& get_dict_field(const map<string, string>& dict, const string& strKey);
//����getenv����NULL��""�������
extern char* my_getenv(const char* s);

extern string getmd5(const string& src) ;


#endif
