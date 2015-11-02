#ifndef __LOGIN__ANZHI_HEAD__
#define __LOGIN__ANZHI_HEAD__

#include "type_mogo.h"
#include "login_base.h"
#include <string>
#include "cjson.h"
using namespace std;


//ƽ̨�ӿ�
class CLoginAnzhi : public CLoginBase
{
public:
	CLoginAnzhi();
	~CLoginAnzhi();

public:
	//У�������Ƿ���ȷ
	int check_login(const char* plat_name, const char* pszReq, string& strAccount);	
private:
	void string_replace(std::string& strBig, const std::string & strsrc, const std::string &strdst);


};


#endif

