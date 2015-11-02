#include "crossserver.h"
#include "world_crossserver.h"
#include <signal.h>
#include "world_select.h"


using namespace mogo;
world* g_pTheWorld = new CWorldCrossserver;

int main(int argc, char* argv[])
{
    if(argc < 4)
    {
        printf("Usage:%s etc_fn server_id log_fn\n", argv[0]);
        return -1;
    }

    //�����в���,����Ϊ: �����ļ�·��,server_id,��־�ļ�·����
    const char* pszEtcFn = argv[1];
    uint16_t nServerId = (uint16_t)atoi(argv[2]);
    const char* pszLogPath = argv[3];

    signal(SIGPIPE, SIG_IGN);

    g_logger.SetLogPath(pszLogPath);
    world& the_world = *GetWorld();
    int nRet = the_world.init(pszEtcFn);
    if(nRet != 0)
    {
        printf("world init error:%d\n", nRet);
        return nRet;
    }

    CCrossserverServer s;
    s.SetMailboxId(nServerId);
    s.SetWorld(&the_world);
    the_world.SetServer(&s);

    uint16_t unPort = the_world.GetServerPort(nServerId);
    s.Service("", unPort);

    return 0;
}

