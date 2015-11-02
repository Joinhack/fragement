#include "cellapp.h"
#include "lua_cell.h"
#include "world_cell.h"
#include "world_select.h"
#include "debug.h"
#include <signal.h>

world* g_pTheWorld = new CWorldCell;

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
	//MG_CONFIRM(false, "这是个测试");
	
    CWorldCell& worldcell = GetWorldcell();
    int nRet = worldcell.init(pszEtcFn);
    if(nRet != 0)
    {
        printf("world init error:%d\n", nRet);
        return nRet;
    }

    CCellappServer s;
    s.SetMailboxId(nServerId);
    s.SetWorld(&worldcell);
    worldcell.SetServer(&s);

    uint16_t unPort = worldcell.GetServerPort(nServerId);
    s.Service("", unPort);

#ifdef _DEBUG_FINAL_GC
	//内存泄漏测试,正式运行时不需要
	//ClearLuaAndGc(g_pTheWorld->GetLuaState());
	lua_close(g_pTheWorld->GetLuaState());
	delete (CWorldCell*)g_pTheWorld;
#endif

	return 0;
}
