#include "loginapp.h"
#include "world_login.h"
#include "world_select.h"
#include "debug.h"
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

    //命令行参数,依次为: 配置文件路径,server_id,日志文件路径名
    const char* pszEtcFn = argv[1];
    uint16_t nServerId = (uint16_t)atoi(argv[2]);
    const char* pszLogPath = argv[3];

    signal(SIGPIPE, SIG_IGN);
	CDebug::Init();
	
    g_logger.SetLogPath(pszLogPath);
    world& the_world = *GetWorld();
    int nRet = the_world.init(pszEtcFn);
    if(nRet != 0)
    {
        printf("world init error:%d\n", nRet);
        return nRet;
    }

    CLoginappServer s;
    s.SetMailboxId(nServerId);
    s.SetWorld(&the_world);
    the_world.SetServer(&s);

    uint16_t unPort = the_world.GetServerPort(nServerId);
    s.Service("", unPort);
}
