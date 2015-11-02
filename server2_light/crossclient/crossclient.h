#ifndef __CROSSCLIENT_HEAD__
#define __CROSSCLIENT_HEAD__

#include "epoll_server.h"


enum { EXTERN_MAILBOX_ID = 0xffff };	//连往外系统的特殊mailbox_id


class CCrossclientServer : public CEpollServer
{
public:
    CCrossclientServer();
    ~CCrossclientServer();

protected:
	int ReloadCrossCfg();
	//读取配置文件
	int LoadCfg();

protected:
	CMailBox* NewExternMailbox(const string& strIp, uint16_t nPort);
	void DeleteExternMailbox(CMailBox* pmb);

public:
	//根据服务名获取外系统mailbox
	CMailBox* GetExternMailbox(const string& strServiceName);

protected:
	//重载的方法
	int HandleMailboxReconnect();
    int HandlePluto();
	int HandleTimeout();
    //重载这个方法
    int HandleMailboxEvent(int fd, uint32_t event, CMailBox* mb);

private:
	time_t m_tLastCrossFileTime;			//上次读取配置文件的时间
	time_t m_tLastCrossConnetTime;			//上次重新连接外系统的时间
	map<string, CMailBox*> m_externServers; //外部服务器

};


#endif

