
#include "loginapp.h"
#include "world_login.h"
#include "world_select.h"
#include "signal.h"
#include "world.h"
#include "pluto.h"
#include "lua.hpp"
#include "util.h"

world* g_pTheWorld = new CWorldLogin();

int main(int argc, char* argv[])
{
    if(argc < 4)
    {
        printf("Usage:%s etc_fn server_id log_fn\n", argv[0]);
        return -1;
    }

    //command parameters:
    //argv[1]: configure file path, for example: ./cfg.ini
    //argv[2]: server id for this server, for example: 1
    //argv[3]: log file saved path, for example: ./log/
    const char* pszEtcFn = argv[1];
    uint16_t nServerId = (uint16_t)atoi(argv[2]);
    const char* pszLogPath = argv[3];

    //set ignore the signal PIPE
    signal(SIGPIPE, SIG_IGN);

    //set the log path for global instance  object logger
    g_logger.SetLogPath(pszLogPath);

    //get the global login world 
    world& the_world = *GetWorld();

    //init the login world with the configure file path
    int nRet = the_world.init(pszEtcFn);
    if(nRet != 0)
    {   //if return nRet is zero, that indicates that the error generated 
        //so print message and return 
        printf("world init error:%d\n", nRet);
        return nRet;
    }

    //intance a loginapp server 
    CLoginappServer s;

    //set mail box id with the argv[2]
    s.SetMailboxId(nServerId);

    //set world of the loginapp server with the global login world
    s.SetWorld(&the_world);

    //set server of the global login world with loginapp server
    the_world.SetServer(&s);

    //get the server port from the global login world with the server id
    uint16_t unPort = the_world.GetServerPort(nServerId);
    
    //entry the server service, ready to start the service
    s.Service("", unPort);
}
