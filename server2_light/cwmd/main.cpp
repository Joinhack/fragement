#include "cwmd.h"
#include "world_cwmd.h"
#include "world_select.h"
#include "util.h"
#include "debug.h"
#include <signal.h>

///////////////////////////////////////////////////////////////////////////

//根据完整路径截取路径
bool GetPathName(const string& strFileName, string& strPath)
{
    size_t idx = strFileName.rfind(g_cPathSplit);
    if(idx != string::npos)
    {
        strPath.assign(strFileName.substr(0, idx));
        return true;
    }

    return false;
}

//生成完整路径
string MakeFullFn(const string& strPath, const string& prefix)
{
    char szTmp[256];
    memset(szTmp, 0, sizeof(szTmp));
    snprintf(szTmp, sizeof(szTmp), "%s%s%s", strPath.c_str(), g_cPathSplit, prefix.c_str());
    return szTmp;
}

///////////////////////////////////////////////////////////////////////////


world* g_pTheWorld = new CWorldMgrD;

int main(int argc, char* argv[])
{
    if(argc < 2)
    {
        printf("Usage:%s etc_fn\n", argv[0]);
        return -1;
    }

    //命令行参数,依次为: 配置文件路径
    const char* pszEtcFn = argv[1];
    uint16_t nServerId = SERVER_BASEAPPMGR;

    //设置日志路径
    CWorldMgrD& world = (CWorldMgrD&)*GetWorld();
    string strLogPath;
    {
        try
        {
            strLogPath = world.GetLogPath(pszEtcFn);
            g_logger.SetLogPath(MakeFullFn(strLogPath, "mogod"));
        }
        catch (const CException& ex)
        {
            printf("%s\n", ex.GetMsg().c_str());
            return -2;
        }
    }

    //读取配置文件,如果配置文件有错误可以提前退出,避免启动了其他进程之后才发现
    int nRet = world.init(pszEtcFn);
    if(nRet != 0)
    {
        printf("CWorldMgrD init error:%d\n", nRet);
        return nRet;
    }

    //获取可执行程序的路径
    string strBinPath;
    if(!GetPathName(argv[0], strBinPath))
    {
        printf("cant get bin files path.%s,%s\n", argv[0], strBinPath.c_str());
        return -3;
    }

    //根据配置文件启动其他服务器进程
    list<CMailBox*> mbs = world.GetMbMgr().GetMailboxs();
    list<CMailBox*>::iterator iter = mbs.begin();
    for(; iter != mbs.end(); ++iter)
    {
        uint16_t nOtherServerId = (*iter)->GetMailboxId();
        if(nOtherServerId != SERVER_BASEAPPMGR)
        {
            string strServerTypeName = GetServerTypeNameById((*iter)->GetServerMbType());
            string strLogFn2 = MakeFullFn(strLogPath, strServerTypeName);
            char szAppName[1024];
            memset(szAppName, 0, sizeof(szAppName));
            snprintf(szAppName, sizeof(szAppName), "%s%s%s %s %d %s_%d_ &", strBinPath.c_str(), g_cPathSplit,
                     strServerTypeName.c_str(), pszEtcFn, nOtherServerId, strLogFn2.c_str(), nOtherServerId);

            LogInfo("run_app", szAppName);
//            system(szAppName);
//            sleep(1);
        }
    }

    //启动cwmd
    signal(SIGPIPE, SIG_IGN);
    CDebug::Init();

    CMgrServer s;
    s.SetMailboxId(nServerId);
    s.SetWorld(&world);
    world.SetServer(&s);

    uint16_t unPort = world.GetServerPort(nServerId);
    s.Service("", unPort);

}

