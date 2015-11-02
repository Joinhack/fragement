/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：world
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.11
// 模块描述：消息转发， mailbox 列表维护， 部分消息触发等
//----------------------------------------------------------------*/

#include "my_stl.h"
#include "util.h"
#include "entity.h"
#include "world.h"
#include "defparser.h"
//#include "lua_mogo.h"
#include "timer.h"


#ifndef _WIN32
    #include "epoll_server.h"
#endif


namespace mogo
{


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////


CMailBoxManager::CMailBoxManager()
{

}

CMailBoxManager::~CMailBoxManager()
{
    ClearContainer(m_mbs);
}

bool CMailBoxManager::init(CCfgReader& cfg)
{
    int nServerCount = atoi(cfg.GetValue("server_all", "server_count").c_str()) + 1;
    for(int i = 1; i < nServerCount; ++i)
    {
        char szServer[16];
        memset(szServer, 0, sizeof(szServer));
        snprintf(szServer, sizeof(szServer), "server_%d", i);
         
        const string& strServerType = cfg.GetOptValue(szServer, "type", "");
        if(strServerType.empty())
        {
            LogWarning("init_cfg", "warning:missed section:%s", szServer);
            continue;
        }
   
        //server type define in the file  pluto.h
        int nServerType;
        if(strServerType.compare("cwmd") == 0)
        {
            nServerType = SERVER_BASEAPPMGR;//2
        }
        else if(strServerType.compare("baseapp") == 0)
        {
            nServerType = SERVER_BASEAPP;//6
        }
		else if(strServerType.compare("cellapp") == 0)
		{
			nServerType = SERVER_CELLAPP;//7
		}
        else if(strServerType.compare("dbmgr") == 0)
        {
            nServerType = SERVER_DBMGR;//3
        }
        else if(strServerType.compare("timerd") == 0)
        {
            nServerType = SERVER_TIMERD;//4
        }
        else if(strServerType.compare("loginapp") == 0)
        {
            nServerType = SERVER_LOGINAPP;//1
        }
        else
        {
            ThrowException(-1, "unknown server type:%s", strServerType.c_str());
        }

		if(nServerType != SERVER_BASEAPP && nServerType != SERVER_CELLAPP)
		{
			//baseapp和cellapp可以配置多个,其他类型的服务器id必须和服务器类型编号一致
			if(nServerType != i)
			{
				ThrowException(-1, "%s, server_id error,need=%d,set=%d", strServerType.c_str(), nServerType, i);
			}
		}
		else
		{
			//baseapp/cellapp的编号必须大于最小编号 SERVER_MULTI_MIN_ID == 11 
			if(i < SERVER_MULTI_MIN_ID)
			{
				ThrowException(-1, "%s, server_id=%d < min=%d", strServerType.c_str(), i, SERVER_MULTI_MIN_ID);
			}
		}

        CMailBox* mb = new CMailBox(i, FD_TYPE_MAILBOX, cfg.GetValue(szServer, "ip").c_str(), \
            atoi(cfg.GetValue(szServer, "port").c_str()));
        mb->SetServerMbType(nServerType);
        m_mbs.push_back(mb);

    }
    //printf("CMailBoxManager init success!\n");
    return true;
}

string GetServerTypeNameById(uint16_t nServerType)
{
	switch(nServerType)
	{
	case SERVER_BASEAPP:
		return "baseapp";
	case SERVER_CELLAPP:
		return "cellapp";
	case SERVER_LOGINAPP:
		return "loginapp";
	case SERVER_BASEAPPMGR:
		return "cwmd";
	case SERVER_DBMGR:
		return "dbmgr";
	case SERVER_TIMERD:
		return "timerd";
	}

	return "";
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

world::world(): m_cfg(NULL), m_rpc(), \
                the_server(NULL), m_timer(), m_defParser(), m_mbMgr(), m_nNextEntityId(0)
{
}

world::~world()
{
    delete m_cfg;
    this->Clear();
}

void world::Clear()
{
}

void world::InitMailboxMgr()
{
    m_mbMgr.init(*m_cfg);
    LogInfo("world::InitMailboxMgr", "init_id=%d", 1);
}

//初始化entity id
void world::InitNextEntityId()
{
	uint16_t nServerId = the_server->GetMailboxId();
	m_nNextEntityId = nServerId << 24;
	LogInfo("world::initNextEntityId", "init_id=%d", m_nNextEntityId);
}

//根据server_id获取服务器绑定端口
uint16_t world::GetServerPort(uint16_t sid)
{
    list<CMailBox*>& mbs = m_mbMgr.GetMailboxs();
    list<CMailBox*>::iterator iter = mbs.begin();
    for(; iter != mbs.end(); ++iter)
    {
        CMailBox* pmb = *iter;
        if(pmb->GetMailboxId() == sid)
        {
            return pmb->GetServerPort();
        }
    }

    return 0;
}

void world::InitTrustedClient()
{
    const string& strTrusted = m_cfg->GetValue("clients", "trusted");
    list<string> l = SplitString(strTrusted, ',');
    for(list<string>::const_iterator iter = l.begin(); iter != l.end(); ++iter)
    {
        m_trustedClients.insert(*iter);
    }

    m_defParser.init(m_cfg->GetValue("init", "def_path").c_str());
}


//将客户端的socket fd附加到pluto解包出来的数据结构上
void world::AddClientFdToVObjectList(int fd, T_VECTOR_OBJECT* p)
{
    //printf("handle pluto in world::AddClientFdToVObjectList()! : start!\n");
    VOBJECT* v = new VOBJECT;
    v->vt = V_INT32;
    v->vv.i32 = (int32_t)fd;
    p->push_back(v);
    //printf("handle pluto in world::AddClientFdToVObjectList()! : end!\n");
}

int world::init(const char* pszEtcFile)
{
    LogDebug("world::init()", "a=%d", 1);
    //intance CCfgReader with configure file 
    m_cfg = new CCfgReader(pszEtcFile);
    
    try
    {
        InitMailboxMgr();
        //InitTrustedClient();
    }
    catch(const CException& e)
    {
        LogDebug("world::init().error", "%s", e.GetMsg().c_str());
        return -1;
    }

	InitEntityCall();

    return 0;
}
/*
int world::OnScriptReady()
{
    static const char* szScriptReady = "onScriptReady";
    lua_getglobal(m_L, szScriptReady);
    int nRet = lua_pcall(m_L, 0, 0, 0);
    if (nRet != 0)
    {
        if (nRet == LUA_ERRRUN)
        {
            LogError("world::on_script_ready error", lua_tostring(m_L, -1));
        }

        return -4;
    }

    ClearLuaStack(m_L);
    return 0;
}

int world::OnServerReady()
{
    static const char* szServerReady = "onServerReady";
    lua_getglobal(m_L, szServerReady);
    int nRet = lua_pcall(m_L, 0, 0, 0);
    if (nRet != 0)
    {
        if (nRet == LUA_ERRRUN)
        {
            LogError("world::on_server_ready error", lua_tostring(m_L, -1));
        }

        return -5;
    }

    ClearLuaStack(m_L);
    return 0;
}
*/
int world::OnFdClosed(int fd)
{
	return 0;
}
uint16_t world::GetMailboxId()
{
 
    return GetServer()->GetMailboxId();

}

/*
//服务器脚本发起的到其他服务器进程的rpc调用
bool world::RpcCallFromLua(const char* pszFunc, CEntityMailbox& em, lua_State* L)
{
    pluto_msgid_t msg_id = MSGID_BASEAPP_ENTITY_RPC;

    const SEntityDef* pDef = GetDefParser().GetEntityDefByType(em.m_nEntityType);
    if(pDef == NULL)
    {
        return false;
    }

    map<string, _SEntityDefMethods*>::const_iterator iter11 = \
        pDef->m_baseMethods.find(pszFunc);
    if(iter11 == pDef->m_baseMethods.end())
    {
        return false;
    }

    const _SEntityDefMethods* pMethods = iter11->second;
    const list<VTYPE>& args = pMethods->m_argsType;
    int nArgCount = lua_gettop(L);
    if(nArgCount != (int)args.size())
    {
        return false;
    }

    uint16_t nFuncId = (uint16_t)pDef->m_baseMethodsMap.GetIntByStr(pszFunc);

    CPluto* pu = new CPluto;
    CPluto& u = *pu;
    u.Encode(msg_id) << em << nFuncId;
    int idx = 0;
    list<VTYPE>::const_iterator iter = args.begin();
    for(; iter != args.end(); ++iter)
    {
        ++idx;
        VTYPE vt = *iter;
        u.FillPlutoFromLua(vt, L, idx);
    }
    u << EndPluto;

	PushPlutoToMailbox(em.m_nServerMailboxId, &u);

    return true;
}

//服务器脚本发起的到cell服务器进程的rpc调用
bool world::RpcCall2CellFromLua(const char* pszFunc, CEntityMailbox& em, lua_State* L)
{
	pluto_msgid_t msg_id = MSGID_CELLAPP_ENTITY_RPC;

	const SEntityDef* pDef = GetDefParser().GetEntityDefByType(em.m_nEntityType);
	if(pDef == NULL)
	{
		return false;
	}

	map<string, _SEntityDefMethods*>::const_iterator iter11 = \
		pDef->m_cellMethods.find(pszFunc);
	if(iter11 == pDef->m_cellMethods.end())
	{
		return false;
	}

	const _SEntityDefMethods* pMethods = iter11->second;
	const list<VTYPE>& args = pMethods->m_argsType;
	int nArgCount = lua_gettop(L);
	if(nArgCount != (int)args.size())
	{
		return false;
	}

	uint16_t nFuncId = (uint16_t)pDef->m_cellMethodsMap.GetIntByStr(pszFunc);

	CPluto* pu = new CPluto;
	CPluto& u = *pu;
	u.Encode(msg_id) << em << nFuncId;
	int idx = 0;
	list<VTYPE>::const_iterator iter = args.begin();
	for(; iter != args.end(); ++iter)
	{
		++idx;
		VTYPE vt = *iter;
		u.FillPlutoFromLua(vt, L, idx);
	}
	u << EndPluto;

	PushPlutoToMailbox(em.m_nServerMailboxId, &u);

	return true;
}


//服务器脚本发起的到客户端rpc调用
bool world::RpcCall2ClientFromLua(const char* pszFunc, CClientMailbox& em, lua_State* L)
{
    pluto_msgid_t msg_id = MSGID_CLIENT_RPC_RESP;

    const SEntityDef* pDef = GetDefParser().GetEntityDefByType(em.m_nEntityType);
    if(pDef == NULL)
    {
        return false;
    }

    map<string, _SEntityDefMethods*>::const_iterator iter11 = \
        pDef->m_clientMethods.find(pszFunc);
    if(iter11 == pDef->m_clientMethods.end())
    {
        return false;
    }

    const _SEntityDefMethods* pMethods = iter11->second;
    const list<VTYPE>& args = pMethods->m_argsType;
    int nArgCount = lua_gettop(L);
    if(nArgCount != (int)args.size())
    {
        return false;
    }

    uint16_t nFuncId = (uint16_t)pDef->m_clientMethodsMap.GetIntByStr(pszFunc);

    CPluto* pu = new CPluto;
    CPluto& u = *pu;
    u.Encode(msg_id) << nFuncId;
    int idx = 0;
    list<VTYPE>::const_iterator iter = args.begin();
    for(; iter != args.end(); ++iter)
    {
        ++idx;
        VTYPE vt = *iter;
        u.FillPlutoFromLua(vt, L, idx);
    }
    u << EndPluto;

    CMailBox* mb = GetServer()->GetClientMailbox(em.m_fd);
    if(mb)
    {
        mb->PushPluto(&u);
    }

    return true;
}

//通过base转发的client rpc调用
bool world::RpcCallToClientViaBase(const char* pszFunc, CEntityMailbox& em, lua_State* L)
{
	const static pluto_msgid_t msg_id = MSGID_BASEAPP_CLIENT_RPC_VIA_BASE;

	const SEntityDef* pDef = GetDefParser().GetEntityDefByType(em.m_nEntityType);
	if(pDef == NULL)
	{
		return false;
	}

	map<string, _SEntityDefMethods*>::const_iterator iter11 = \
		pDef->m_clientMethods.find(pszFunc);
	if(iter11 == pDef->m_clientMethods.end())
	{
		return false;
	}

	const _SEntityDefMethods* pMethods = iter11->second;
	const list<VTYPE>& args = pMethods->m_argsType;
	int nArgCount = lua_gettop(L);
	if(nArgCount != (int)args.size())
	{
		return false;
	}

	uint16_t nFuncId = (uint16_t)pDef->m_clientMethodsMap.GetIntByStr(pszFunc);

	CPluto* u = new CPluto;
	u->Encode(msg_id) << em.m_nEntityId << nFuncId;

	uint32_t idx1 = u->GetLen();		//记录
	u->FillField<uint16_t>(0);			//长度占位
	
	//打包rpc的所有参数为一个string
	int idx = 0;
	list<VTYPE>::const_iterator iter = args.begin();
	for(; iter != args.end(); ++iter)
	{
		++idx;
		VTYPE vt = *iter;
		u->FillPlutoFromLua(vt, L, idx);
	}

	uint32_t idx2 = u->GetLen();
	u->ReplaceField<uint16_t>(idx1, idx2 - idx1 - 2);
	u->endPluto();
	
	PushPlutoToMailbox(em.m_nServerMailboxId, u);

	return true;
}
*/


int world::OnTimerdTick(T_VECTOR_OBJECT* p)
{
    if(p->size() != 1)
    {
        return -1;
    }

    //uint32_t unTick = VOBJECT_GET_U32((*p)[0]);
   // m_timer.OnTick(m_L, *this, unTick);

    return 0;
}

//判断一个客户端连接的地址是否来自于可信任地址列表
bool world::IsTrustedClient(const string& strClientAddr)
{
    return m_trustedClients.find(strClientAddr) != m_trustedClients.end();
}

//检查一个rpc调用是否合法
bool world::CheckClientRpc(CPluto& u)
{
    CMailBox* mb = u.GetMailbox();
	if(!mb)
	{
		//如果没有mb,是从本进程发来的包
		return true;
	}
    uint8_t authz = mb->GetAuthz();
    //printf("authz status: %d\n", authz);
    pluto_msgid_t msg_id = u.GetMsgId();
    if(authz == MAILBOX_CLIENT_TRUSTED)
    {
        printf("authz status: %d MAILBOX_CLIENT_TRUSTED:%d\n", authz,MAILBOX_CLIENT_TRUSTED);
        return true;
    }
    else if(authz == MAILBOX_CLIENT_AUTHZ)
    {
        
        //pluto_msgid_t msg_id = u.GetMsgId();
        printf("authz status: %d MAILBOX_CLIENT_AUTHZ:%d msg_id: %d\n", authz,MAILBOX_CLIENT_AUTHZ, msg_id);
        return msg_id == MSGID_BASEAPP_CLIENT_RPCALL || msg_id == MSGID_BASEAPP_CLIENT_MOVE_REQ;
    }
    else if(authz == MAILBOX_CLIENT_UNAUTHZ)
    {
                
        printf("authz status: %d MAILBOX_CLIENT_UNAUTHZ:%d msg_id: %d\n", authz, MAILBOX_CLIENT_UNAUTHZ, msg_id);
        return msg_id == MSGID_LOGINAPP_LOGIN || msg_id == MSGID_BASEAPP_CLIENT_LOGIN || \
               msg_id == MSGID_LOGINAPP_MODIFY_LOGIN_FLAG || msg_id == MSGID_LOGINAPP_SELECT_ACCOUNT_CALLBACK;
    
    }
    else
    {
        //printf("authz status: %d error: %d\n", authz, -1);
        return false;
    }
}


// 关闭服务器
// 向BaseappMgr 发送 关闭消息
int world::ShutdownServer(T_VECTOR_OBJECT* p)
{
	LogInfo("world::shutdown_server", "");

	//回应cwmd,本进程已经退出
	RpcCall(SERVER_BASEAPPMGR, MSGID_BASEAPPMGR_ON_SERVER_SHUTDOWN, GetMailboxId());
	//设置服务器退出标记
	GetServer()->Shutdown();

	return 0;
}

// 将一个entity id加入定时存盘列表
void world::RegisterTimeSave(TENTITYID tid)
{
	m_lsTimeSave.push_back(tid);
}

void world::InitEntityCall()
{
    /*
	m_entityCalls.insert(make_pair("getId",            &CEntityParent::lGetId));
	m_entityCalls.insert(make_pair("getDbid",          &CEntityParent::lGetDbid));
	m_entityCalls.insert(make_pair("getEntityType",    &CEntityParent::lGetEntityType));
	m_entityCalls.insert(make_pair("addTimer",         &CEntityParent::lAddTimer));
	m_entityCalls.insert(make_pair("writeToDB",        &CEntityParent::lWriteToDB));
	m_entityCalls.insert(make_pair("hasClient",        &CEntityParent::lHasClient));
	m_entityCalls.insert(make_pair("registerTimeSave", &CEntityParent::lRegisterTimeSave));
    */
}

// 将指定的 pluto 发给 对应的服务器mailbox
bool world::PushPlutoToMailbox(uint16_t nServerId, CPluto* u)
{
	if(GetMailboxId() == nServerId)
	{
		//本服务器
		GetServer()->AddLocalRpcPluto(u);
	}
	else
	{
		CMailBox* mb = GetServerMailbox(nServerId);
		if(mb)
		{
			mb->PushPluto(u);
		}
	}

	return true;
}

}

