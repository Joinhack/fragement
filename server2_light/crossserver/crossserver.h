#ifndef __CROSSSERVER_HEAD__
#define __CROSSSERVER_HEAD__

#include "epoll_server.h"


class CCrossserverServer : public CEpollServer
{
public:
    CCrossserverServer();
    ~CCrossserverServer();

public:
    //�㲥��Ϣ���ַ�
    void OnCrossClientBroadcast(CPluto& u);

protected:
    int HandlePluto();
	int HandleTimeout();
	int HandleMailboxReconnect();

protected:
	//����ɨ�������ļ�
	int ReloadCrossClientCfg();
	//��ȡ�����ļ�
	int LoadCfg();

public:
	inline bool IsTrustedIp(const string& ip)
	{
		return m_setTrustedIp.find(ip) != m_setTrustedIp.end();
	}

protected:
	time_t m_tLastCrossFileTime;			//�ϴζ�ȡ�����ļ���ʱ��
	set<string> m_setTrustedIp;				//�����εķ�����ip�б�

};


#endif

