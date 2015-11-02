#ifndef __CROSSSERVER_HEAD__
#define __CROSSSERVER_HEAD__

#include "epoll_server.h"


class CCrossserverServer : public CEpollServer
{
public:
    CCrossserverServer();
    ~CCrossserverServer();

public:
    //广播消息给分服
    void OnCrossClientBroadcast(CPluto& u);

protected:
    int HandlePluto();
	int HandleTimeout();
	int HandleMailboxReconnect();

protected:
	//重新扫描配置文件
	int ReloadCrossClientCfg();
	//读取配置文件
	int LoadCfg();

public:
	inline bool IsTrustedIp(const string& ip)
	{
		return m_setTrustedIp.find(ip) != m_setTrustedIp.end();
	}

protected:
	time_t m_tLastCrossFileTime;			//上次读取配置文件的时间
	set<string> m_setTrustedIp;				//可信任的服务器ip列表

};


#endif

