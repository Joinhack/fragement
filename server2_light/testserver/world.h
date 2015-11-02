#ifndef __WORLD__BASE__HEAD__
#define __WORLD__BASE__HEAD__


//#include <lua.hpp>
#include "util.h"
#include "entity.h"
#include "rpc_mogo.h"
//#include "lua_mogo.h"
//#include "win_adaptor.h"
#include "timer.h"
#include "defparser.h"
//#include "path_founder.h"
#include "exception.h"
#include "epoll_server.h"
#include "mailbox.h"
//class CEpollServer;


namespace mogo
{


class CMailBoxManager
{
public:
    CMailBoxManager();
    ~CMailBoxManager();

public:
    bool init(CCfgReader& cfg);

public:
    inline list<CMailBox*>& GetMailboxs()
    {
        return m_mbs;
    }

private:
    list<CMailBox*> m_mbs;

};

extern string GetServerTypeNameById(uint16_t nServerType);

class world
{
public:
    world();
    virtual ~world();

public:
    virtual int init(const char* pszEtcFile);
    
public:
    virtual void Clear();
//    virtual int OpenMogoLib(lua_State* L) = 0;

public:
 //   virtual int OnScriptReady();
//    virtual int OnServerReady();
	virtual int OnFdClosed(int fd);

public:
    virtual CEntityParent* GetEntity(TENTITYID id) = 0;

public:
    
    uint16_t GetMailboxId();
/*
public:
    bool RpcCallFromLua(const char* pszFunc, CEntityMailbox& em, lua_State* L);
	bool RpcCall2CellFromLua(const char* pszFunc, CEntityMailbox& em, lua_State* L);
    bool RpcCall2ClientFromLua(const char* pszFunc, CClientMailbox& em, lua_State* L);
	bool RpcCallToClientViaBase(const char* pszFunc, CEntityMailbox& em, lua_State* L);
*/
public:
	template<typename T1>
	void RpcCall(uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1);

	template<typename T1, typename T2>
	void RpcCall(uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2);

	template<typename T1, typename T2, typename T3>
	void RpcCall(uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3);

	template<typename T1, typename T2, typename T3, typename T4>
	void RpcCall(uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4);

	template<typename T1, typename T2, typename T3, typename T4, typename T5>
	void RpcCall(uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5);

	template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6>
	void RpcCall(uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5, const T6& p6);

public:
	bool PushPlutoToMailbox(uint16_t nServerId, CPluto* u);

public:
    virtual int FromRpcCall(CPluto& u) = 0;

public:
   
     inline CRpcUtil& GetRpcUtil()
    {
        return m_rpc;
    }

public:
    inline void SetServer(CEpollServer* s)
    {
       this->the_server = s;
       InitNextEntityId();
    }

    inline CEpollServer* GetServer()
    {
       return the_server;
    }
    CMailBox* GetServerMailbox(uint16_t nServerId)
    {
 
       CEpollServer* s = GetServer();
       if(s)
       {
           return s->GetServerMailbox(nServerId);
       }

        return NULL;
 
    }
    


protected:
    int OnTimerdTick(T_VECTOR_OBJECT* p);
	virtual int ShutdownServer(T_VECTOR_OBJECT* p);

public:
  //  inline lua_State* GetLuaState()
   // {
  //      return m_L;
 //   }

    inline CTimerHeap& GetTimer()
    {
        return m_timer;
    }

    inline CDefParser& GetDefParser()
    {
        return m_defParser;
    }

    inline CMailBoxManager& GetMbMgr()
    {
        return m_mbMgr;
    }

public:
    //根据server_id获取服务器绑定端口
    uint16_t GetServerPort(uint16_t sid);

protected:
    void InitMailboxMgr();
    void InitTrustedClient();
    //检查一个rpc调用是否合法
    bool CheckClientRpc(CPluto& u);
    //将客户端的socket fd附加到pluto解包出来的数据结构上
    void AddClientFdToVObjectList(int fd, T_VECTOR_OBJECT* p);
	virtual void InitEntityCall();

public:
    //判断一个客户端连接的地址是否来自于可信任地址列表
    bool IsTrustedClient(const string& strClientAddr);
	//将一个entity id加入定时存盘列表
	void RegisterTimeSave(TENTITYID tid);

public:
	//初始化entity id
	void InitNextEntityId();
	//获得next entity id
	inline TENTITYID GetNextEntityId()
	{
		return ++m_nNextEntityId;
	}
/*
public:
	inline bool IsValidEntityCall(const string& s)
	{
		return m_entityCalls.find(s) != m_entityCalls.end();
	}

	inline map<string, ENTITY_MEMBER_METHOD>& GetEntityCalls()
	{
		return m_entityCalls;
	}

*/	 

protected:
   // lua_State* m_L;
    CCfgReader* m_cfg;
    set<string> m_trustedClients;
  //  CLuaCallback m_cb;
  //  CLuaCallback m_luatables;
    CRpcUtil m_rpc;
    CEpollServer* the_server;
    CTimerHeap m_timer;
    CDefParser m_defParser;
    CMailBoxManager m_mbMgr;
	TENTITYID m_nNextEntityId;
	list<TENTITYID> m_lsTimeSave;
	//map<string, ENTITY_MEMBER_METHOD> m_entityCalls;
	//CBlockMapMgr m_bmm;

};


//从VOBJECT*中读取字段
#define VOBJECT_GET_SSTR(p) *(p->vv.s)
#define VOBJECT_GET_STR(p) p->vv.s->c_str()
#define VOBJECT_GET_U8(p) p->vv.u8
#define VOBJECT_GET_U16(p) p->vv.u16
#define VOBJECT_GET_U32(p) p->vv.u32
//#define VOBJECT_GET_U64(p) p->vv.u64
#define VOBJECT_GET_I8(p) p->vv.i8
#define VOBJECT_GET_I16(p) p->vv.i16
#define VOBJECT_GET_I32(p) p->vv.i32
//#define VOBJECT_GET_I64(p) p->vv.i64
#define VOBJECT_GET_F32(p) p->vv.f32
#define VOBJECT_GET_F64(p) p->vv.f64
#define VOBJECT_GET_EMB(p) p->vv.emb


template<typename T1>
void world::RpcCall(uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1)
{
	if(nServerId == GetMailboxId())
	{
		//本进程
		CPluto* u = new CPluto;
		m_rpc.Encode(*u, msg_id, p1);
		GetServer()->AddLocalRpcPluto(u);
	}
	else
	{
		CMailBox* mb = GetServerMailbox(nServerId);
		if(mb)
		{
			mb->RpcCall(m_rpc, msg_id, p1);
		}
		else
		{
			LogWarning("world.rpc_call.error", "server_id=%d", nServerId);
		}
	}
}

template<typename T1, typename T2>
void world::RpcCall(uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2)
{
	if(nServerId == GetMailboxId())
	{
		//本进程
		CPluto* u = new CPluto;
		m_rpc.Encode(*u, msg_id, p1, p2);
		GetServer()->AddLocalRpcPluto(u);
	}
	else
	{
		CMailBox* mb = GetServerMailbox(nServerId);
		if(mb)
		{
			mb->RpcCall(m_rpc, msg_id, p1, p2);
		}
		else
		{
			LogWarning("world.rpc_call.error", "server_id=%d", nServerId);
		}
	}
}

template<typename T1, typename T2, typename T3>
void world::RpcCall(uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3)
{
	if(nServerId == GetMailboxId())
	{
		//本进程
		CPluto* u = new CPluto;
		m_rpc.Encode(*u, msg_id, p1, p2, p3);
		GetServer()->AddLocalRpcPluto(u);
	}
	else
	{
		CMailBox* mb = GetServerMailbox(nServerId);
		if(mb)
		{
			mb->RpcCall(m_rpc, msg_id, p1, p2, p3);
		}
		else
		{
			LogWarning("world.rpc_call.error", "server_id=%d", nServerId);
		}
	}
}

template<typename T1, typename T2, typename T3, typename T4>
void world::RpcCall(uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4)
{
	if(nServerId == GetMailboxId())
	{
		//本进程
		CPluto* u = new CPluto;
		m_rpc.Encode(*u, msg_id, p1, p2, p3, p4);
		GetServer()->AddLocalRpcPluto(u);
	}
	else
	{
		CMailBox* mb = GetServerMailbox(nServerId);
		if(mb)
		{
			mb->RpcCall(m_rpc, msg_id, p1, p2, p3, p4);
		}
		else
		{
			LogWarning("world.rpc_call.error", "server_id=%d", nServerId);
		}
	}
}

template<typename T1, typename T2, typename T3, typename T4, typename T5>
void world::RpcCall(uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5)
{
	if(nServerId == GetMailboxId())
	{
		//本进程
		CPluto* u = new CPluto;
		m_rpc.Encode(*u, msg_id, p1, p2, p3, p4, p5);
		GetServer()->AddLocalRpcPluto(u);
	}
	else
	{
		CMailBox* mb = GetServerMailbox(nServerId);
		if(mb)
		{
			mb->RpcCall(m_rpc, msg_id, p1, p2, p3, p4, p5);
		}
		else
		{
			LogWarning("world.rpc_call.error", "server_id=%d", nServerId);
		}
	}
}

template<typename T1, typename T2, typename T3, typename T4, typename T5, typename T6>
void world::RpcCall(uint16_t nServerId, pluto_msgid_t msg_id, const T1& p1, const T2& p2, const T3& p3, const T4& p4, const T5& p5, const T6& p6)
{
	if(nServerId == GetMailboxId())
	{
		//本进程
		CPluto* u = new CPluto;
		m_rpc.Encode(*u, msg_id, p1, p2, p3, p4, p5, p6);
		GetServer()->AddLocalRpcPluto(u);
	}
	else
	{
		CMailBox* mb = GetServerMailbox(nServerId);
		if(mb)
		{
			mb->RpcCall(m_rpc, msg_id, p1, p2, p3, p4, p5, p6);
		}
		else
		{
			LogWarning("world.rpc_call.error", "server_id=%d", nServerId);
		}
	}
}




}




#endif

