//#define _USE_RECV_BUFF

#include "epoll_server.h"
#include "world_cwmd.h"


class CPolicyServer : public CEpollServer
{

protected:
	inline int HandlePluto()
	{
		return 0;
	}


protected:
	int handle_message(int fd, CMailBox* mb);

};

namespace mogo{

class CWorldPolicy : public world
{

public:
	int from_RpcCall(CPluto&)
	{
		return 0;
	}

	//此方法无用
	inline int OpenMogoLib(lua_State* L)
	{
		return 0;
	}

	//此方法无用
	inline CEntityParent* getEntity(TENTITYID id)
	{
		return NULL;
	}

	inline int on_server_ready()
	{
		return 0;
	}

};

};

/*
const static char szPolicyText[] = "\
<?xml version=\"1.0\"?>\
<cross-domain-policy>\
<site-control permitted-cross-domain-policies=\"all\"/>\
<allow-access-from domain=\"*\" to-ports=\"*\" />\
</cross-domain-policy>\0";

*/

const static char szPolicyText[] = "\
<?xml version=\"1.0\" encoding=\"gb2312\" ?>\
<cross-domain-policy>\
<site-control permitted-cross-domain-policies=\"all\"/>\
<allow-access-from domain=\"*\" to-ports=\"*\" />\
</cross-domain-policy>\0";


int CPolicyServer::handle_message(int fd, CMailBox* mb)
{
	//uint16_t nLeft = mb->getRecvBuffLen();
	//char* szBuff = mb->getRecvBuff();

	enum{ POLICY_REQ_SIZE = 256, };
	char szBuff[POLICY_REQ_SIZE];

	int nLen = ::recv(fd, szBuff, POLICY_REQ_SIZE, 0);
	if(nLen > 0)
	{
		//printf("%d recved:'%s'，%d\n",fd, szBuff+nLeft, nLen);
		printf("fd:%d;size=%d;req=%s\n", fd, nLen, szBuff);
		
		if(strcmp(szBuff, "<policy-file-request/>") == 0)
		{
			int nSend = ::send(fd, szPolicyText, sizeof(szPolicyText), 0);
			::send(fd, "\0", 1, 0);
			printf("send=%d;text=%s\n", nSend, szPolicyText);
		}			
	}

	//无论结果都关闭连接
	close(fd);
	//shutdown(fd, SHUT_RDWR);
	return -1;
}


world* g_pTheWorld = new CWorldPolicy;

int main(int argc, char* argv[])
{
	CPolicyServer s;
	s.SetWorld(g_pTheWorld);
	g_pTheWorld->SetServer(&s);

	s.Service("", 5000);
}

