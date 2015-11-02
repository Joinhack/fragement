#include <sys/time.h>
#include "timerd.h"
#include "world_timerd.h"
#include "world_select.h"
#include "debug.h"
#include <signal.h>


CTimerdServer g_timerd_server;
world* g_pTheWorld = new CTimerdWorld;

void SigHandler(int signo)
{
    if(signo == SIGALRM)
    {
        struct timeval tv;
        if(gettimeofday(&tv, NULL) == 0)
        {
            //下面这个日志某些情况下有问题,去掉
            //LogInfo("SIGALRM", "sec=%d,usec=%d", tv.tv_sec, tv.tv_usec);
            g_timerd_server.SendTickMsg();
            signal(SIGALRM, SigHandler);
        }
    }
}


int StartTimer()
{
    //int setitimer(int which, const struct itimerval *value,struct itimerval *ovalue);
    //ITIMER_REAL    decrements in real time, and delivers SIGALRM upon expiration.
    //struct itimerval {
    //    struct timeval it_interval; /* next value */
    //    struct timeval it_value;    /* current value */
    //};
    //struct timeval {
    //    long tv_sec;                /* seconds */
    //    long tv_usec;               /* microseconds */
    //};

    struct itimerval tv;
    tv.it_interval.tv_sec = 0;
    tv.it_interval.tv_usec = TIMER_INTERVAL_USEC;   //0.5s
    tv.it_value.tv_sec = 2;
    tv.it_value.tv_usec = 0;

    int nRet;
    if( (nRet = setitimer(ITIMER_REAL, &tv, NULL)) == 0)
    {
        signal(SIGALRM, SigHandler);
    }
    else
    {
        printf("setitimer,errno:%d;strerror:%s\n", errno, strerror(errno));
    }

    return nRet;
}

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
    CTimerdWorld& world = (CTimerdWorld&)*GetWorld();

    int nRet = world.init(pszEtcFn);
    if(nRet != 0)
    {
        printf("world init error:%d\n", nRet);
        return nRet;
    }

    CTimerdServer& s = g_timerd_server;
    s.SetMailboxId(nServerId);
    s.SetWorld(&world);
    world.SetServer(&s);

    StartTimer();

    uint16_t unPort = world.GetServerPort(nServerId);
    s.Service("", unPort);

}

