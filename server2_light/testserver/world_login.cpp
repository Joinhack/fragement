/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：world_login
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.11
// 模块描述：登录服务器逻辑
//----------------------------------------------------------------*/

#include "world_login.h"


namespace mogo
{

enum{
	ENUM_LOGIN_SUCCESS = 0,						 //认证成功
	ENUM_LOGIN_RET_ACCOUNT_PASSWD_NOMATCH = 1,   //帐号密码不匹配
	ENUM_LOGIN_NO_SERVICE = 2,				     //服务器未开放登陆
};

CWorldLogin::CWorldLogin() : m_bCanLogin(false)
{
}

CWorldLogin::~CWorldLogin()
{
}

int CWorldLogin::OnFdClosed(int fd)
{
	map<int, string>::iterator iter = m_fd2accounts.find(fd);
	if(iter != m_fd2accounts.end())
	{
		const string& strAccount = iter->second;
		m_accounts2fd.erase(strAccount);

		LogInfo("CWorldLogin::OnFdClosed", "fd=%d;account=%s", fd, strAccount.c_str());
		m_fd2accounts.erase(iter);
	}

	return 0;
}
//in parent class , this method has a pure virtual access limited
int CWorldLogin::FromRpcCall(CPluto& u)
{
    //printf("CWorldLogin::from_rpc_call\n");
    //printf("handle pluto in FromRpcCall()! : start!\n");
	pluto_msgid_t msg_id = u.GetMsgId();
    //printf("message id : %d\n", msg_id);
	if(!CheckClientRpc(u))
	{
		LogWarning("FromRpcCall", "invalid rpcall error.unknown msgid:%d\n", msg_id);
		return -1;
	}

	T_VECTOR_OBJECT* p = m_rpc.Decode(u);
	if(p == NULL)
	{
		LogWarning("FromRpcCall", "rpc decode error.unknown msgid:%d\n", msg_id);
		return -1;
	}

	if(u.GetDecodeErrIdx() > 0)
	{
		ClearTListObject(p);
		LogWarning("FromRpcCall", "rpc decode error.msgid:%d;pluto err idx=%d\n", msg_id, u.GetDecodeErrIdx());
		return -2;
	}
    printf("MSGID_LOGINAPP_MODIFY_LOGIN_FLAG:%d\n", MSGID_LOGINAPP_MODIFY_LOGIN_FLAG);
    int nRet = -1;
    switch(msg_id)
    {
        case MSGID_LOGINAPP_LOGIN:
        {
            AddClientFdToVObjectList(u.GetMailbox()->GetFd(), p);
            nRet = AccountLogin(p);
            break;
        }
        case MSGID_LOGINAPP_SELECT_ACCOUNT_CALLBACK:
        {
            nRet = SelectAccountCallback(p);
            break;
        }
        case MSGID_LOGINAPP_NOTIFY_CLIENT_TO_ATTACH:
        {
            nRet = NotifyClientToAttach(p);
            break;
        }
	    case MSGID_LOGINAPP_MODIFY_LOGIN_FLAG:  
		{
			nRet = ModifyLoginFlag(p);
			break;
		}
	    case MSGID_ALLAPP_SHUTDOWN_SERVER://103
		{
			nRet = ShutdownServer(p);
			break;
		}
        default:
        {
            LogWarning("CWorldLogin::from_rpc_call", "unknown msgid:%d\n", msg_id);
            break;
        }
    }

	if(nRet != 0)
	{
		LogWarning("from_rpc_call", "rpc error.msg_id=%d;ret=%d\n", msg_id, nRet);
	}

    ClearTListObject(p);
    //printf("handle pluto in FromRpcCall()! : end!\n");
    return 0;
}

// 登录请求，初步处理过后，转给dbMgr 验证
int CWorldLogin::AccountLogin(T_VECTOR_OBJECT* p)
{   
     //printf("handle in CWorldLogin::AccountLogin()! : start!\n");
    if(p->size() != 3)
    {
        return -1;
    }

	if(!m_bCanLogin)
	{
		printf("server no service\n");
        string& strAccount = VOBJECT_GET_SSTR((*p)[0]);
        string& strPasswd = VOBJECT_GET_SSTR((*p)[1]); 
		int32_t nFd = VOBJECT_GET_I32((*p)[2]);	
        Trim(strAccount);
        Trim(strPasswd);
        const char* pszAccount = strAccount.c_str();
        const char* pszPasswd = strPasswd.c_str();
        bool status = true;
        if(strcmp(pszAccount, pszPasswd))
        {  
            
            status = false;
        }
        //printf("strAccount cmp strPasswd : %d\n", strcmp(pszAccount, pszPasswd));

        string  constr = strAccount.append(pszPasswd);
          
		CMailBox* mb = GetServer()->GetClientMailbox(nFd);
		if(mb)
		{
			CPluto* u = new CPluto;
			(*u).Encode(MSGID_CLIENT_LOGIN_RESP) << (uint8_t)ENUM_LOGIN_NO_SERVICE << (int32_t)nFd << (bool)status << (string)constr << EndPluto;
			mb->PushPluto(u);
		}

		return 0;
	}

    string& strAccount = VOBJECT_GET_SSTR((*p)[0]);
    string& strPasswd = VOBJECT_GET_SSTR((*p)[1]); 
    int32_t nFd = VOBJECT_GET_I32((*p)[2]);

	//删除账户名/密码两边的空格,mysql中select * from table where s = '***'中不会区分***是否带空格
	Trim(strAccount);
	Trim(strPasswd);
	const char* pszAccount = strAccount.c_str();
	const char* pszPasswd = strPasswd.c_str();

    LogInfo("CWorldLogin::account_login", "client attempt to login;account=%s;passwd=%s;fd=%d\n", pszAccount, pszPasswd, nFd);

    if(m_fd2accounts.find(nFd) != m_fd2accounts.end())
    {
        //同一个连接上的重复认证,不给错误提示
		LogInfo("CWorldLogin::account_login", "login is in progress;account=%s;passwd=%s;fd=%d\n", pszAccount, pszPasswd, nFd);
        return 0;
    }

	map<string, int>::const_iterator iter = m_accounts2fd.find(pszAccount);
	if(iter != m_accounts2fd.end())
	{
		int fd2 = iter->second;
		if(nFd == fd2)
		{
			//同一个连接上的重复认证,不给错误提示
			LogInfo("CWorldLogin::account_login", "login is in progress(2);account=%s;passwd=%s;fd=%d\n", pszAccount, pszPasswd, nFd);
			return 0;
		}
		else
		{
			//不同连接上的同一个用户的认证,踢掉老的用户
			m_fd2accounts.erase(fd2);
			m_accounts2fd.erase(pszAccount);
			GetServer()->CloseFdFromServer(fd2);
			LogInfo("CWorldLogin::account_login", "multilogin,kick off old;account=%s;passwd=%s;fd=%d;old=%d\n", \
				pszAccount, pszPasswd, nFd, fd2);
		}
	}

    m_fd2accounts.insert(make_pair(nFd, pszAccount));
    m_accounts2fd.insert(make_pair(pszAccount, nFd));
    
    //printf("account :%s \npassword : %s\n", pszAccount, pszPasswd);

    /*
    CMailBox* mb = this->GetServerMailbox(SERVER_DBMGR);
    if(mb)
    {
        mb->RpcCall(GetRpcUtil(), MSGID_DBMGR_SELECT_ACCOUNT, GetMailboxId(), nFd, pszAccount, pszPasswd);
    }
    */
        
    CMailBox* mb = GetServer()->GetClientMailbox(nFd);
    if(mb)
    {
        CPluto* u = new CPluto;
        //printf("login success : %s\n", pszAccount);
        (*u).Encode(MSGID_CLIENT_LOGIN_RESP) << (uint8_t)ENUM_LOGIN_SUCCESS << EndPluto;
        mb->PushPluto(u);
    }
    //printf("handle in CWorldLogin::AccountLogin()! : end!\n");
    return 0;
}

// DbMgr 验证后的回调。 通过后通知baseapp 创建角色对象
int CWorldLogin::SelectAccountCallback(T_VECTOR_OBJECT* p)
{
    if(p->size() != 3)
    {
        return -1;
    }

    int32_t fd = VOBJECT_GET_I32((*p)[0]);
    const char* pszAccount = VOBJECT_GET_STR((*p)[1]);
    uint8_t nRet = VOBJECT_GET_U8((*p)[2]);

    //printf("select account call back vector objects: fd: %d account: %s ret: %d\n",fd, pszAccount, nRet );
    LogInfo("CWorldLogin::select_account_callback", "account=%s;fd=%d;ret=%d\n", pszAccount, fd, nRet);

	CMailBox* mb = GetServer()->GetClientMailbox(fd);
    CPluto* pu = new CPluto;
    if(nRet == 0)
    {
        m_fd2accounts.erase(fd);    //验证失败,删除对应关系
		m_accounts2fd.erase(pszAccount);

        //账号错误
        (*pu).Encode(MSGID_CLIENT_LOGIN_RESP) << (uint8_t)ENUM_LOGIN_RET_ACCOUNT_PASSWD_NOMATCH << EndPluto;
    }
    else
    {
        //账号校验通过
		if(mb)
		{
            //printf("set the client to authorize!\n");
			mb->SetAuthz(MAILBOX_CLIENT_AUTHZ);
		}
        uint32_t tp = 0x11111111;
        (*pu).Encode(MSGID_CLIENT_LOGIN_RESP) << (uint8_t)ENUM_LOGIN_SUCCESS << tp << EndPluto;

        /*
        //创建account
        CMailBox* mb2 = GetServerMailbox(SERVER_BASEAPPMGR);
        if(mb2)
        {
            //标记1表示如果数据库中不存在,也要创建一个entity
            mb2->RpcCall(GetRpcUtil(), MSGID_BASEAPPMGR_CREATEBASE_FROM_NAME_ANYWHERE, (uint8_t)1, "Account", pszAccount);
        }
        */
    }

	if(mb != NULL)
	{
		mb->PushPluto(pu);
        //printf("select account login call back success!\n");
	}

    return 0;
}

int CWorldLogin::NotifyClientToAttach(T_VECTOR_OBJECT* p)
{
    if(p->size() != 3)
    {
        return -1;
    }

    const char* pszAccount = VOBJECT_GET_STR((*p)[0]);
    uint16_t baseapp_id = VOBJECT_GET_U16((*p)[1]);
    const char* pszKey = VOBJECT_GET_STR((*p)[2]);

    map<string, int>::const_iterator iter = m_accounts2fd.find(pszAccount);
    if(iter == m_accounts2fd.end())
    {
        LogWarning("NotifyClientToAttach", "Account '%s' hasn't client", pszAccount);
        return -2;
    }

    LogDebug("NotifyClientToAttach", "account=%s;fd=%d", pszAccount, iter->second);
    CMailBox* mb = GetServer()->GetClientMailbox(iter->second);
    if(mb != NULL)
    {
        CMailBox* smb = GetServer()->GetServerMailbox(baseapp_id);
        if(smb == NULL)
        {
            LogWarning("NotifyClientToAttach", "error baseapp_id:%d", baseapp_id);
            return -3;
        }

        mb->RpcCall(GetRpcUtil(), MSGID_CLIENT_NOTIFY_ATTACH_BASEAPP, smb->GetServerName().c_str(), smb->GetServerPort(), pszKey);
    }

    return 0;
}

int CWorldLogin::ModifyLoginFlag(T_VECTOR_OBJECT* p)
{
    //printf("modify login flag !\n");
	if(p->size() != 1)
	{
		return -1;
	}

	uint8_t flag = VOBJECT_GET_U8((*p)[0]);
	if(flag == 1)
	{   
        //printf("open service success!\n");
		m_bCanLogin = true;
	}
	else
	{
        //printf("open service failure!\n");
		m_bCanLogin = false;
	}

	//记录日志
	LogInfo("CWorldLogin::ModifyLoginFlag", "input=%d;flag=%d", flag, m_bCanLogin);

	return 0;
}


}
