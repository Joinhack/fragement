#ifndef __LOGINPPTV_HEAD__
#define __LOGINPPTV_HEAD__

#include "type_mogo.h"
#include "login_base.h"
#include <string>
using namespace std;


//ƽ̨�ӿ�
class CLoginPPTV : public CLoginBase
{
public:
	CLoginPPTV();
	~CLoginPPTV();

public:
	//У�������Ƿ���ȷ
	int check_login(const char* plat_name, const char* pszReq, string& strAccount);	
};


#endif

