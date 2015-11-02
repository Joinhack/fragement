//平台接入游戏处理cgi

#include <unistd.h>

#include "iffactory.h"
#include "world_base.h"
#include <fcgi_config.h>
#include <fcgi_stdio.h>
#include "cgicfg.h"


world* g_pTheWorld = new CWorldBase;


int main ()
{
	char **initialEnv = environ; 

    g_cgi_cfg = new CCgiCfg("/data/server/cgi-bin/sh/cgi_cfg.txt");

	while (FCGI_Accept() >= 0) 
	{	
        CIfBase* ifobj = CIfFactory::getIfObj();
        if(ifobj == NULL)
        {
            LogError("error_env_platform", "");
            continue;
        }
		
        ifobj->SetServName(my_getenv("SERVER_NAME"));
        char* pszReq = my_getenv("QUERY_STRING");
		ifobj->login(pszReq);
        delete ifobj;
	}
	
	delete (CWorldBase*)g_pTheWorld;

	return 0;
}
