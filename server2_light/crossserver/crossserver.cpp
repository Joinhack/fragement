#include "crossserver.h"
#include "world_crossserver.h"
#include "world_select.h"


CCrossserverServer::CCrossserverServer() : CEpollServer(), m_tLastCrossFileTime(time(NULL))
{

}

CCrossserverServer::~CCrossserverServer()
{

}

int CCrossserverServer::HandlePluto()
{
    //printf("CLoginappServer::handle_pluto\n");
    CEpollServer::HandlePluto();

    return 0;
}

int CCrossserverServer::HandleTimeout()
{
	//return CEpollServer::handle_client_timeout();
	return 0;
}

int CCrossserverServer::HandleMailboxReconnect()
{
	//调用基类的方法
	CEpollServer::HandleMailboxReconnect();

	//重新扫描配置文件
	this->ReloadCrossClientCfg();

	return 0;
}

//重新扫描配置文件
int CCrossserverServer::ReloadCrossClientCfg()
{
	enum
	{ 
		FILE_INTERVAL = 10,				//重新读取配置文件的间隔时间
	};

	time_t tNow = time(NULL);

	//重新读取配置文件
	if(tNow - m_tLastCrossFileTime >= FILE_INTERVAL)
	{
		m_tLastCrossFileTime = tNow;
		this->LoadCfg();
	}

	return 0;
}

//读取配置文件
int CCrossserverServer::LoadCfg()
{
	CCfgReader* cfg = GetWorld()->GetCfgReader();
	try
	{
		string fn = cfg->GetValue("init", "cross_server_fn");
		ifstream file(fn.c_str(), ios::in);
		if(!file.is_open())
		{
			LogError("load_cfg", "err=cfg_file_not_exist");
			return -1;
		}

		m_setTrustedIp.clear();	//清除
        char szLine[128];
		while(!file.eof() && file.getline(szLine, sizeof(szLine), 0x0A))
		{
			Trim(szLine);

			if(szLine[0] != '\0')
			{
				m_setTrustedIp.insert(szLine);
			}
		}
	}
	catch(const CException& ex)
	{
		//没有配置跨服功能,什么都不做
		LogError("load_cfg", "err=no_cfg");
		return -9;
	}

	return 0;
}

//广播消息给分服
void CCrossserverServer::OnCrossClientBroadcast(CPluto& u)
{
    //printf("CCrossserverServer::OnCrossClientBroadcast\n");
    map<int, CMailBox*>::iterator iter1 = m_fds.begin();
    for(; iter1 != m_fds.end(); ++iter1)
    {
        CMailBox* mb = iter1->second;
        //printf("fd=%d;mbtype=%d;auth=%d;fdtype=%d\n", iter1->first, mb->GetServerMbType(), mb->GetAuthz(), mb->GetFdType());
        //除了发给连上来的分服客户端,还发给内部的baseapp/cellapp/cwmd等进程,忽略这个消息即可
        if(mb->GetAuthz() == MAILBOX_CLIENT_TRUSTED)
        {
            CPluto* u2 = new CPluto(u.GetBuff(), u.GetMaxLen());
            u2->ReplaceField<uint16_t>(6, MSGID_CROSSCLIENT_BROADCAST);
            mb->PushPluto(u2);
            //printf("add....\n");
        }        
    }
}


