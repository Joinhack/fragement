#include "crossclient.h"
#include "world_crossclient.h"
#include "world_select.h"


CCrossclientServer::CCrossclientServer() : CEpollServer()
{
	//进程刚启动的时候不连外系统,在之后的timer中再处理
	time_t t1 = time(NULL);
	m_tLastCrossFileTime = t1;
	m_tLastCrossConnetTime = t1;
}

CCrossclientServer::~CCrossclientServer()
{
	ClearMap(m_externServers);
}

int CCrossclientServer::HandlePluto()
{
    //printf("CLoginappServer::handle_pluto\n");
    CEpollServer::HandlePluto();

    return 0;
}

int CCrossclientServer::HandleTimeout()
{
	//return CEpollServer::handle_client_timeout();
	return 0;
}

int CCrossclientServer::ReloadCrossCfg()
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
int CCrossclientServer::LoadCfg()
{	
	CCfgReader* cfg = GetWorld()->GetCfgReader();
	try
	{
		string fn = cfg->GetValue("init", "cross_client_fn");
		ifstream file(fn.c_str(), ios::in);
		if(!file.is_open())
		{
			LogError("load_cfg", "err=cfg_file_not_exist");
			return -1;
		}

        char szLine[128];
		while(!file.eof() && file.getline(szLine, sizeof(szLine), 0x0A))
		{
			Trim(szLine);

			vector<string> vt;
			SplitStringToVector(szLine, ',', vt);
			
			if(vt.size() < 3)
			{
				if(szLine[0] != '\0')
				{
					LogError("load_cfg", "err=%s", szLine);
				}				
				continue;
			}		

			const string& strName = vt[0];		//跨服服务名称
			map<string, CMailBox*>::iterator iter1 = m_externServers.lower_bound(strName);
			if(iter1 != m_externServers.end() && iter1->first == strName)
			{
				CMailBox* pmb = iter1->second;
				const string& strIp = vt[1];
				uint16_t nPort = (uint16_t)atoi(vt[2].c_str());
				if(pmb->GetServerName() != strIp || pmb->GetServerPort() != nPort)
				{
					//跨服目标服务器ip或port发生变更
					DeleteExternMailbox(pmb);
					CMailBox* pmb2 = NewExternMailbox(strIp, nPort);
					if(pmb2)
					{
						iter1->second = pmb2;
						LogInfo("load_cfg.modify_cfg", "extern=%s:%d", strIp.c_str(), nPort);
					}
				}
			}
			else
			{
				//新增的配置
				const string& strIp = vt[1];
				uint16_t nPort = (uint16_t)atoi(vt[2].c_str());
				CMailBox* pmb2 = NewExternMailbox(strIp, nPort);	
				if(pmb2)
				{
					m_externServers.insert(iter1, make_pair(strName, pmb2));
					LogInfo("load_cfg.new_cfg", "extern=%s:%d", strIp.c_str(), nPort);
				}

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

CMailBox* CCrossclientServer::NewExternMailbox(const string& strIp, uint16_t nPort)
{
	CMailBox* pmb = new CMailBox(EXTERN_MAILBOX_ID, FD_TYPE_MAILBOX, strIp.c_str(), nPort );					
	pmb->SetServerMbType(SERVER_NONE);

	int nRet = pmb->ConnectServer(m_epfd);
	if(nRet != 0)
	{
		delete pmb;
		return NULL;
	}

	AddFdAndMb(pmb->GetFd(), pmb);

	LogDebug("try_to_connect_extern", "server=%s;port=%d", 
		pmb->GetServerName().c_str(), pmb->GetServerPort());

	return pmb;
}

void CCrossclientServer::DeleteExternMailbox(CMailBox* pmb)
{
	int fd = pmb->GetFd();
	if(fd > 0)
	{
		::close(fd);
	}
	
	delete pmb;
}

//重连,区分内部mailbox和外部mailbox
int CCrossclientServer::HandleMailboxReconnect()
{
	if(!m_mb4reconn.empty())
	{
		enum{ CONNECT_INTERVAL = 10, };  //重新尝试连接外系统的间隔时间
		time_t tNow = time(NULL);
		bool bConnectExtern = false;
		//重新尝试连接外系统的间隔时间
		if(tNow - m_tLastCrossConnetTime >= CONNECT_INTERVAL)
		{
			m_tLastCrossConnetTime = tNow;
			bConnectExtern = true;
		}

		for(int i = (int)m_mb4reconn.size()-1; i >= 0; --i)
		{
			CMailBox* pmb = m_mb4reconn[i];

			//到外系统连接的重连要间隔时间长一些
			if(pmb->GetMailboxId() == EXTERN_MAILBOX_ID && !bConnectExtern)
			{
				continue;
			}

			int nRet = pmb->ConnectServer(m_epfd);
			if(nRet == 0)
			{
				m_mb4reconn.erase(m_mb4reconn.begin()+i);
				AddFdAndMb(pmb->GetFd(), pmb);
			}
		}
	}

	//刷新对外系统的配置
	this->ReloadCrossCfg();

	return 0;
}

//根据服务名获取外系统mailbox
CMailBox* CCrossclientServer::GetExternMailbox(const string& strServiceName)
{
	map<string, CMailBox*>::iterator iter1 = m_externServers.find(strServiceName);
	if(iter1 != m_externServers.end())
	{
		CMailBox* p = iter1->second;
		if(p && p->IsConnected())
		{
			return p;
		}
	}

	return NULL;
}

int CCrossclientServer::HandleMailboxEvent(int fd, uint32_t event, CMailBox* pmb)
{
    if(pmb != NULL)
    {
        if(!pmb->IsConnected())
        {
            int nConnErr = 0;
            socklen_t _tl = sizeof(nConnErr);
            //可写之后判断
            if(getsockopt(fd, SOL_SOCKET, SO_ERROR, &nConnErr, &_tl) == 0)
            {
                if(nConnErr == 0)
                {
                    pmb->SetConnected();
                    LogInfo("connected_2_mb2", "mb fd = %d connected severName = %s, port = %d,", fd, pmb->GetServerName().c_str(),pmb->GetServerPort());

                    //增加的代码,发认证信息给外系统服务器
                    CPluto* u = new CPluto;
                    const string& strMd5 = ((CWorldCrossclient*)GetWorld())->GetDefMd5();
                    u->Encode(MSGID_CROSSSERVER_CHECK_MD5) << strMd5 << EndPluto;
                    pmb->PushPluto(u);
                }
                else
                {
                    LogInfo("connect_2_mb2", "connect %s:%d error:%d,%s", pmb->GetServerName().c_str(),
                        pmb->GetServerPort(), nConnErr, strerror(nConnErr));


                    RemoveFd(fd);
                    //int nRet = pmb->ConnectServer(m_epfd);
                    //if(nRet != 0)
                    //{
                    //    return nRet;
                    //}
                    //addFdAndMb(pmb->GetFd(), pmb);

                    //ERROR_PRINT2("reconncet");

                    return 0;
                }
            }
            else
            {
                return -2;
            }
        }

        if(event & EPOLLIN)
        {
            return this->HandleFdEvent(fd, event, pmb);
        }
        else
        {
            return 0;
        }
    }

    //todo,assert??
    //如果服务器的某一个进程退出之后,是否需要关闭所有服务器进程
    return -1;

}


