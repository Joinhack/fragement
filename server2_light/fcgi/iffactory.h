#ifndef __IF_FACTORY_HEAD__
#define __IF_FACTORY_HEAD__

#include "ifbase.h"
#include "login_base.h"
#include "if4399.h"
#include "login4399.h"
#include "login91.h"
#include "login_pptv.h"
#include "login_dangle.h"
#include "login360.h"
#include "login_pps.h"
#include "login_uc.h"
#include "login_xiaomi.h"
#include "login_duokoo.h"
#include "login_anzhi.h"




class CIfFactory
{
public:
	static CIfBase* getIfObj();
	static CLoginBase* getLoginObj(const char* plat_name);		
private:
	static CLogin4399*		plogin_4399;
	static CLogin91*		plogin_91;
	static CLoginPPTV*		plogin_pptv;
	static CLoginDangle*	plogin_dangle;
	static CLogin360*		plogin_360;
	static CLoginUC*		plogin_uc;
	static CLoginXiaomi*	plogin_xiaomi;
	static CLoginPPS*		plogin_pps;
	static CLoginDuokoo*	plogin_duokoo;
	static CLoginAnzhi*		plogin_anzhi;
};


#endif

