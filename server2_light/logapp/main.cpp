#include "other.h"
#include "world_other.h"
#include "db_task.h"
#include "world_select.h"
#include "debug.h"
#include <signal.h>
#include "other_def.h"
#include "threadpool.h"
#include <curl/curl.h> 
#include "cjson.h"
#include "type_mogo.h"

///////////////////////////////////////////////////////////////////////////

world* g_pTheWorld = new CWorldOther;
CWorldOther& g_worldOther = (CWorldOther&)(*g_pTheWorld);
extern int InitLib();

struct threadpool* g_threadpool = NULL;
extern int GetUrl(const char* url, OUT string& result);



void* RunDbTask(void* arg)
{
    int nSeq = *(int*)arg;      //每个线程编一个流水号
   // printf("other runDbTask,seq=%d\n", nSeq);

    LogDebug("other RunDbTask", "db connect begin!!");

    mysql_thread_init();
    CDbTask t(g_worldOther, nSeq);

    string strErr;
    if(!t.Init(GetWorld()->GetDefParser().GetLogDbCfg(), strErr))
    {
        LogDebug("CWorldLog::init().error", "connect db:%s", strErr.c_str());
        printf("CWorldLog::init().error, thread id = %d , connect db:%s", nSeq , strErr.c_str());
        mysql_thread_end();
        return NULL;
    }
    LogDebug("RunDbTask", "db connect ok!!!");

    t.Run();
    mysql_thread_end();
    return NULL;
}

int create_threads(vector<pthread_t> & pid_list)
{
	pthread_t pid;
	//static int a[MYSQL_THREAD_NUM ] = {0};
	for(int i=0; i<MYSQL_THREAD_NUM ; ++i)
	{	//a[i] = i;
        int *ptrI = new int(i);
		if(pthread_create(&pid, NULL, RunDbTask, ptrI) != 0)
		{
			printf("pthread_create error:%d,%s\n", errno, strerror(errno));
			return -2;
		}
		pid_list.push_back(pid);
	}
	return 0;

}

int InitThreadPool()
{
	curl_version_info_data* info = curl_version_info(CURLVERSION_NOW);
	//if (info->features & CURL_VERSION_ASYNCHDNS)
		//std::cout << "ares enabled" << endl;
	//else
		//std::cout << "ares NOT enabled" << endl;
	g_threadpool = (struct threadpool *) threadpool_init(POOL_THREAD_NUM, POOL_QUEUE_NUM);
	curl_global_init(CURL_GLOBAL_ALL);
	return 0;
}

void* ThreadJob_SdkServerVerify(void* arg)
{
	CPluto& u = *((CPluto*)arg);
	pluto_msgid_t msg_id = u.GetMsgId();;
	mogo::T_VECTOR_OBJECT* p = NULL;

	CMailBox* pmb = u.GetMailbox();
	if(!pmb)
	{
		//如果没有mb,是从本进程发来的包
		delete &u;
		return (void*)-1;
	}
	uint8_t authz = pmb->GetAuthz();
	if(authz != MAILBOX_CLIENT_TRUSTED)
	{
		LogWarning("ThreadJob_SdkServerVerify", "invalid rpcall error.unknown msgid:%d\n", msg_id);
		delete &u;
		return (void*)-1;
	}

	p = g_worldOther.GetRpcUtil().Decode(u);
	if(p == NULL)
	{
		LogWarning("ThreadJob_SdkServerVerify", "rpc Decode error.unknown msgid:%d\n", msg_id);
		delete &u;
		return (void*)-2;
	}

	if(u.GetDecodeErrIdx() > 0)
	{
		ClearTListObject(p);
		//PrintHexPluto(u);
		LogWarning("ThreadJob_SdkServerVerify", "rpc Decode error.msgid:%d;pluto err idx=%d\n", msg_id, u.GetDecodeErrIdx());
		delete &u;
		return (void*)-3;
	}

	if (p->size() != 4)
	{
		delete &u;
		return (void*)-4;
	}
	string& url = VOBJECT_GET_SSTR((*p)[0]);
	int32_t nFd = VOBJECT_GET_I32((*p)[1]);
	string& strAccount = VOBJECT_GET_SSTR((*p)[2]);
	string& strPlatId = VOBJECT_GET_SSTR((*p)[3]);
	//CMailBox* pmb = u.GetMailbox();

	string resp = "";
	int ret = GetUrl(url.c_str(), resp);
	if (ret != CURLE_OK)
	{
		LogWarning("CWorldOther::SdkServerVerify", "%s ret = %d", strAccount.c_str(), ret);
		//todo:faild.
		pmb->RpcCall(g_worldOther.GetRpcUtil(), MSGID_LOGINAPP_LOGIN_VERIFY_CALLBACK, ret, nFd, strAccount, strPlatId);
		delete &u;
		return 0;
	}
	Trim(resp);
	cJSON* json = cJSON_Parse(resp.c_str());
	cJSON* childJs = cJSON_GetObjectItem(json, "code");
	int rst = cJSON_GetObjectItem(json, "code")->valueint;

	if (rst == 1)
	{
		//succeed.
		if (strAccount.c_str() != cJSON_GetObjectItem(json, "msg")->valuestring)
		{
			ret = 0;
		}
		else
		{
			LogWarning("CWorldOther::SdkServerVerify", "strAccount[%s] msg[%s]", 
				strAccount.c_str(), cJSON_GetObjectItem(json, "msg")->valuestring);
			ret = 1;
			//pmb->RpcCall(GetRpcUtil(), MSGID_LOGINAPP_LOGIN_VERIFY_CALLBACK, int32_t(1), nFd, strAccount, strPlatId);
		}
	}
	else
	{
		//failed.
		LogWarning("CWorldOther::SdkServerVerify", "strAccount[%s] rst[%d]", 
			strAccount.c_str(), rst);
		ret = -1;
		//pmb->RpcCall(GetRpcUtil(), MSGID_LOGINAPP_LOGIN_VERIFY_CALLBACK, -1, nFd, strAccount, strPlatId);
	}
	pmb->RpcCall(g_worldOther.GetRpcUtil(), MSGID_LOGINAPP_LOGIN_VERIFY_CALLBACK, ret, nFd, strAccount, strPlatId);
	delete &u;
	return (void*)0;
}

int DestroyThreadPool()
{
	threadpool_destroy(g_threadpool);
}

void SigHandler(int signo)
{
    if(signo == SIGALRM)
    {
        LogInfo("logapp.SIGALRM", "");
        signal(SIGALRM, SigHandler);
        return;
    }
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
    uint16_t nServerId = SERVER_LOG;
    const char* pszLogPath = argv[3];

    signal(SIGPIPE, SIG_IGN);
	//curl_global_init(CURL_GLOBAL_ALL);
    CDebug::Init();
    InitLib();

    //printf("%d\n", mysql_thread_safe() );
    {
        MYSQL* dummy = mysql_init(NULL);
        mysql_close(dummy);
    }

    g_logger_mutex = new pthread_mutex_t;

    if(!g_pluto_recvlist.InitMutex() || !g_pluto_sendlist.InitMutex() || !g_worldOther.InitMutex()
        || pthread_mutex_init(g_logger_mutex, NULL) != 0 )
    {
        printf("pthead_mutext_t init error:%d,%s\n", errno, strerror(errno));
        return -1;
    }

    g_logger.SetLogPath(pszLogPath);
    CWorldOther& world = g_worldOther;
    int nRet = world.init(pszEtcFn);
    if(nRet != 0)
    {
        printf("CWorldLog init error:%d\n", nRet);
        return nRet;
    }

    COtherServer s;
    s.SetMailboxId(nServerId);
    s.SetWorld(&world);
    world.SetServer(&s);

    vector<pthread_t> pid_list;

	int ret = create_threads(pid_list);
	if ( 0 != ret)
	{
		return ret;
	}
	
    signal(SIGALRM, SigHandler);

    uint16_t unPort = world.GetServerPort(nServerId);
	////初始化线程池以及相关的多线程的检查
	//InitThreadPool();
    
	s.Service("", unPort);

	//处理完了所有的包后再关闭线程池
	//DestroyThreadPool();

	for(size_t i = 0; i < pid_list.size(); ++i)
    {
        if(pthread_join(pid_list[i], NULL) != 0)
        {           
            return -3;
        }
    }

}
