#include "baseapp.h"
#include "world_select.h"
#include "world_base.h"
#include "pluto.h"
#include "world.h"
#include "util.h"
#include "debug.h"
#include <signal.h>
#include "lua_base.h"
#include <uuid/uuid.h>
//#include "logger.h"
//#include "memory_pool.h"


world* g_pTheWorld = new CWorldBase;

int main(int argc, char* argv[])
{
    if(argc < 4)
    {
        printf("Usage:%s etc_fn server_id log_fn\n", argv[0]);
        return -1;
    }

    //first args[1] is configure file name
    const char* pszEtcFn = argv[1];
    //second args[2] is server id for self
    uint16_t nServerId = (uint16_t)atoi(argv[2]);
    //third args[3] is log file path
    const char* pszLogPath = argv[3];

    signal(SIGPIPE, SIG_IGN);
	CDebug::Init();

    g_logger.SetLogPath(pszLogPath);
    CWorldBase& worldbase = GetWorldbase();
    int nRet = worldbase.init(pszEtcFn);
    if(nRet != 0)
    {
        printf("world init error:%d\n", nRet);
        return nRet;
    }


    CBaseappServer s;
    s.SetMailboxId(nServerId);
    s.SetWorld(&worldbase);
    worldbase.SetServer(&s);

    uint16_t unPort = worldbase.GetServerPort(nServerId);
    s.Service("", unPort);

#ifdef _DEBUG_FINAL_GC
	//内存泄漏测试,正式运行时不需要
	ClearLuaAndGc(g_pTheWorld->GetLuaState());
	delete (CWorldBase*)g_pTheWorld;
#endif

    return 0;
}
