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
	//���û���ķ���
	CEpollServer::HandleMailboxReconnect();

	//����ɨ�������ļ�
	this->ReloadCrossClientCfg();

	return 0;
}

//����ɨ�������ļ�
int CCrossserverServer::ReloadCrossClientCfg()
{
	enum
	{ 
		FILE_INTERVAL = 10,				//���¶�ȡ�����ļ��ļ��ʱ��
	};

	time_t tNow = time(NULL);

	//���¶�ȡ�����ļ�
	if(tNow - m_tLastCrossFileTime >= FILE_INTERVAL)
	{
		m_tLastCrossFileTime = tNow;
		this->LoadCfg();
	}

	return 0;
}

//��ȡ�����ļ�
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

		m_setTrustedIp.clear();	//���
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
		//û�����ÿ������,ʲô������
		LogError("load_cfg", "err=no_cfg");
		return -9;
	}

	return 0;
}

//�㲥��Ϣ���ַ�
void CCrossserverServer::OnCrossClientBroadcast(CPluto& u)
{
    //printf("CCrossserverServer::OnCrossClientBroadcast\n");
    map<int, CMailBox*>::iterator iter1 = m_fds.begin();
    for(; iter1 != m_fds.end(); ++iter1)
    {
        CMailBox* mb = iter1->second;
        //printf("fd=%d;mbtype=%d;auth=%d;fdtype=%d\n", iter1->first, mb->GetServerMbType(), mb->GetAuthz(), mb->GetFdType());
        //���˷����������ķַ��ͻ���,�������ڲ���baseapp/cellapp/cwmd�Ƚ���,���������Ϣ����
        if(mb->GetAuthz() == MAILBOX_CLIENT_TRUSTED)
        {
            CPluto* u2 = new CPluto(u.GetBuff(), u.GetMaxLen());
            u2->ReplaceField<uint16_t>(6, MSGID_CROSSCLIENT_BROADCAST);
            mb->PushPluto(u2);
            //printf("add....\n");
        }        
    }
}


