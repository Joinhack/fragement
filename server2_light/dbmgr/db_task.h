#ifndef __DB_TASK_HEAD__
#define __DB_TASK_HEAD__

#include <list>

#ifndef _WIN32
#include <pthread.h>
#else
typedef int pthread_mutex_t;
typedef int pthread_t;
#endif

#include "dboper.h"

namespace mogo
{
    class CWorldDbmgr;
}

using mogo::CWorldDbmgr;


extern CPlutoList g_pluto_recvlist;
extern CPlutoList g_pluto_sendlist;
extern CWorldDbmgr& g_worldDbmgr;
extern bool g_bShutdown;


class CDbTask
{
    public:
        CDbTask(CWorldDbmgr& w, int seq);
        ~CDbTask();

    public:
        void Run();
        //连接数据库
        bool ConnectDB(const SDBCfg& cfg, const SRedisCfg& redisCfg, string& strErr);

    private:
        CWorldDbmgr& m_world;
        CDbOper m_db;
};


#endif

