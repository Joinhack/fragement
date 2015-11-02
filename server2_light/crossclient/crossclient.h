#ifndef __CROSSCLIENT_HEAD__
#define __CROSSCLIENT_HEAD__

#include "epoll_server.h"


enum { EXTERN_MAILBOX_ID = 0xffff };	//������ϵͳ������mailbox_id


class CCrossclientServer : public CEpollServer
{
public:
    CCrossclientServer();
    ~CCrossclientServer();

protected:
	int ReloadCrossCfg();
	//��ȡ�����ļ�
	int LoadCfg();

protected:
	CMailBox* NewExternMailbox(const string& strIp, uint16_t nPort);
	void DeleteExternMailbox(CMailBox* pmb);

public:
	//���ݷ�������ȡ��ϵͳmailbox
	CMailBox* GetExternMailbox(const string& strServiceName);

protected:
	//���صķ���
	int HandleMailboxReconnect();
    int HandlePluto();
	int HandleTimeout();
    //�����������
    int HandleMailboxEvent(int fd, uint32_t event, CMailBox* mb);

private:
	time_t m_tLastCrossFileTime;			//�ϴζ�ȡ�����ļ���ʱ��
	time_t m_tLastCrossConnetTime;			//�ϴ�����������ϵͳ��ʱ��
	map<string, CMailBox*> m_externServers; //�ⲿ������

};


#endif

