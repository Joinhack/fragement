#include "db_task.h"
#include "world_other.h"


#ifdef _WIN32
CPlutoList g_pluto_recvlist;
CPlutoList g_pluto_sendlist;
#endif




CDbTask::CDbTask(CWorldOther& w, int seq) : m_world(w), m_db(seq)
{

}

CDbTask::~CDbTask()
{

}

//连接数据库
bool CDbTask::Init(const SDBCfg& cfg, string& strErr)
{
    return m_db.Connect(cfg, strErr);
}
bool CDbTask::UnInit()
{
	 m_db.DisConnect();
}

void CDbTask::Run()
{
    for(;;)
    {
        CPluto* u = g_pluto_recvlist.PopPluto();
        if(u == NULL)
        {
            //sleep(1);
            usleep(50000);
        }
        else
        {
            m_world.FromRpcCall(*u, m_db);
            delete u;
        }

        if(g_bShutdown)
        {
            //如果设置了退出标记并且已经没有数据需要处理,则退出
            if(g_pluto_recvlist.Empty())
            {
#ifndef _WIN32
                LogInfo("db_task.quit", "pid=%d", (int)pthread_self());
#endif
                break;
            }
        }
    }

	UnInit();
   
}

