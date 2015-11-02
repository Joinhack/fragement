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
#include <string.h>
#include <curl/curl.h> 

namespace mogo
{
	enum
	{
		ENUM_LOGIN_CHECK_SUCCESS            = 0,  //ENTITY_DEF检查成功
		ENUM_LOGIN_CHECK_ENTITY_DEF_NOMATCH = 1,  //ENTITY_DEF检查不成功
		ENUM_LOGIN_CHECK_NO_SERVICE         = 2,  //服务器未开放登陆
	};
    
	enum
    {
        ENUM_LOGIN_SUCCESS = 0,                      //认证成功
        ENUM_LOGIN_RET_ACCOUNT_PASSWD_NOMATCH = 1,   //帐号密码不匹配
        ENUM_LOGIN_NO_SERVICE = 2,                   //服务器未开放登陆
        ENUM_LOGIN_FORBIDDEN_LOGIN = 3,              //被禁止登陆
        ENUM_LOGIN_TOO_MUCH   = 4,                   //服务器人数超过最大数量，不可登录
		ENUM_LOGIN_TIME_ILLEGAL = 5,                 //本次登录超时 
		ENUM_LOGIN_SIGN_ILLEGAL = 6,                 //签名非法
		ENUM_LOGIN_SERVER_BUSY = 7,                  //sdk服务器验证超时
		ENUM_LOGIN_SDK_VERIFY_FAILED = 8,            //sdk服务器验证失败
		ENUM_LOGIN_ACCOUNT_ILLEGAL = 9,              //sdk验证成功但是帐号不一样
    };

    CWorldLogin::CWorldLogin() : m_bCanLogin(false), m_onlineCount(0)
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

    int CWorldLogin::FromRpcCall(CPluto& u)
    {
        //printf("CWorldLogin::from_rpc_call\n");

        pluto_msgid_t msg_id = u.GetMsgId();
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

        int nRet = -1;
        switch(msg_id)
        {
            case MSGID_LOGINAPP_CHECK:
            {
                AddClientFdToVObjectList(u.GetMailbox()->GetFd(), p);
                //版本校验
                nRet = VersionCheck(p);
                break;
            }
            case MSGID_LOGINAPP_LOGIN:
            {
                AddClientFdToVObjectList(u.GetMailbox()->GetFd(), p);
                nRet = AccountLogin(p);
                break;
            }
            case MSGID_LOGINAPP_WEBLOGIN:
            {
                AddClientFdToVObjectList(u.GetMailbox()->GetFd(), p);
                nRet = AccountWebLogin(p);
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
            case MSGID_LOGINAPP_NOTIFY_CLIENT_MULTILOGIN:
            {
                nRet = NotifyClientMultiLogin(p);
                break;
            }
            case MSGID_LOGINAPP_MODIFY_LOGIN_FLAG:
            {
                nRet = ModifyLoginFlag(p);
                break;
            }
            case MSGID_LOGINAPP_FORBIDLOGIN:
            {
                nRet = ForbidLogin(p);
                break;
            }
            case MSGID_LOGINAPP_FORBID_IP_UNTIL_TIME:
            {
                nRet = ForbidLoginByIp(p);
                break;
            }

            case MSGID_LOGINAPP_FORBID_ACCOUNT_UNTIL_TIME:
            {
                nRet = ForbidLoginByAccount(p);
                break;
            }

            case MSGID_ALLAPP_SHUTDOWN_SERVER:
            {
                nRet = ShutdownServer(p);
                break;
            }
            case MSGID_LOGINAPP_MODIFY_ONLINE_COUNT:
            {
                nRet = ModifyOnlineCount(p);
                break;
            }
#if __PLAT_PLUG_IN_NEW
			case MSGID_LOGINAPP_LOGIN_VERIFY_CALLBACK:
			{

				nRet = SdkServerCheckResp(p);
				break;
			}
#endif
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

        return 0;
    }

    int CWorldLogin::VersionCheck(T_VECTOR_OBJECT* p)
    {
        if (p->size() != 2)
        {
            return -1;
        }
        int32_t nFd = VOBJECT_GET_I32((*p)[1]);
        CMailBox* mb = GetServer()->GetClientMailbox(nFd);
        if (!mb)
        {
            return -2;
        }
        CPluto* u = new CPluto;
        (*u).Encode(MSGID_CLIENT_CHECK_RESP);

        #ifndef __TEST_LOGIN
        if (!m_bCanLogin)
        {
            (*u) << (uint8_t)ENUM_LOGIN_CHECK_NO_SERVICE << EndPluto;
            LogDebug("CWorldLogin::VersionCheck no service", "u.GenLen()=%d", u->GetLen());
            mb->PushPluto(u);
            return 0;
        }
        #endif

        //string& version = VOBJECT_GET_SSTR((*p)[0]);
        string& md5Str = VOBJECT_GET_SSTR((*p)[0]);
        //Trim(version);
        Trim(md5Str);
        const string& md5 = m_defParser.GetEntityDefMd5();

        if (md5.compare(md5Str) != 0)
        {
            (*u) << (uint8_t)ENUM_LOGIN_CHECK_ENTITY_DEF_NOMATCH << EndPluto;
            LogDebug("CWorldLogin::VersionCheck no match", "u.GenLen()=%d", u->GetLen());
            mb->PushPluto(u);
            return 0;
        }

        (*u) << (uint8_t)ENUM_LOGIN_CHECK_SUCCESS << EndPluto;

        mb->PushPluto(u);
        return 0;
    }

    int CWorldLogin::ForbidLogin(T_VECTOR_OBJECT* p)
    {
        if (p->size() != 2)
        {
            return -1;
        }

        string& strAccount = VOBJECT_GET_SSTR((*p)[0]);
        uint32_t forbidTime     = VOBJECT_GET_U32((*p)[1]);

		uint32_t endTime = 0;
		if (forbidTime == 0)
			endTime = 0;
		else
		{
			struct timeval tv;
			gettimeofday(&tv, NULL);			
			endTime = (uint32_t)tv.tv_sec + forbidTime;
		}

		return ForbidLogin(m_forbiddenLogin, strAccount, endTime);		 //禁账号登录

    }

	

		int CWorldLogin::ForbidLoginByAccount(T_VECTOR_OBJECT* p)
		{
			if (p->size() != 2)
			{
				return -1;
			}

			string& strAccount = VOBJECT_GET_SSTR((*p)[0]);
			uint32_t endTime     = VOBJECT_GET_U32((*p)[1]);

			return ForbidLogin(m_forbiddenLogin, strAccount, endTime);		 //禁账号登录

		}


	int CWorldLogin::ForbidLoginByIp(T_VECTOR_OBJECT* p)
	{
		if (p->size() != 2)
		{
			return -1;
		}
		string& strIp = VOBJECT_GET_SSTR((*p)[0]);
		uint32_t endTime     = VOBJECT_GET_U32((*p)[1]);
				
		return ForbidLogin(m_forbiddenIP, strIp, endTime);		 //禁IP登录
	
	}


	//endTime =0 则表示解封
	int CWorldLogin::ForbidLogin(map<string, uint32_t>& records, const string & key, uint32_t endTime)
	{		
		if (endTime == 0)
		{
			//如果是0，则表示解禁登录
			map<string, uint32_t>::iterator iter = records.find(key);
			if(iter != m_forbiddenIP.end())
			{
				m_forbiddenIP.erase(iter);
				return 0;
			}
			else
			{
				return 0;
			}
		}
		else
		{
			//如果不是0，则表示禁止登录
			map<string, uint32_t>::iterator iter = records.find(key);

			if(iter != records.end())
			{
				iter->second = endTime;
				return 0;
			}
			else
			{
				records.insert(make_pair(key, endTime));
				return 0;
			}
		}
	}
	
	// 登录请求，初步处理过后，转给dbMgr 验证
#ifdef __PLAT_PLUG_IN_NEW
	int CWorldLogin::AccountLogin(T_VECTOR_OBJECT* p)
    {
        //这种情况下直接禁止登陆
        return -1;
    }
#else
    //内网开发模式下的登陆
	int CWorldLogin::AccountLogin(T_VECTOR_OBJECT* p)
    {
        return _AccountLoginImpl(p, true);
    }
#endif

    //到平台认证后的登陆
    int CWorldLogin::AccountWebLogin(T_VECTOR_OBJECT* p)
    {
        return _AccountLoginImpl(p, false);
    }

    //真正实现登陆流程的方法
    int CWorldLogin::_AccountLoginImpl(T_VECTOR_OBJECT* p, bool bLoginFirst)
	{
		if(p->size() != 3)
		{
			return -1;
		}

		if(!m_bCanLogin)
		{
			//服务器不可登陆
			int32_t nFd = VOBJECT_GET_I32((*p)[2]);
			CMailBox* mb = GetServer()->GetClientMailbox(nFd);
			if(mb)
			{
				CPluto* u = new CPluto;
				(*u).Encode(MSGID_CLIENT_LOGIN_RESP) << (uint8_t)ENUM_LOGIN_NO_SERVICE << EndPluto;

				//LogDebug("CWorldLogin::AccountLogin 1", "u.GenLen()=%d", u->GetLen());

				mb->PushPluto(u);
			}

			return 0;
		}

		if (this->m_cfg)
		{
			uint16_t MaxOnlineCount = atoi(this->m_cfg->GetOptValue("params", "max_online_count", "3000").c_str());

			//LogDebug("CWorldLogin::AccountLogin", "MaxOnlineCount=%d", MaxOnlineCount);

			if (this->m_onlineCount >= MaxOnlineCount)
			{
				//人数超过最大数量，服务器不可登陆
				int32_t nFd = VOBJECT_GET_I32((*p)[2]);
				CMailBox* mb = GetServer()->GetClientMailbox(nFd);
				if(mb)
				{
					CPluto* u = new CPluto;
					(*u).Encode(MSGID_CLIENT_LOGIN_RESP) << (uint8_t)ENUM_LOGIN_TOO_MUCH << EndPluto;

					mb->PushPluto(u);
				}

				return 0;
			}
		}

        string& strAccount = VOBJECT_GET_SSTR((*p)[0]);
		string& strPasswd = VOBJECT_GET_SSTR((*p)[1]);
		int32_t nFd = VOBJECT_GET_I32((*p)[2]);

		//删除账户名/密码两边的空格,mysql中select * from table where s = '***'中不会区分***是否带空格
		Trim(strAccount);
		Trim(strPasswd);
		const char* pszAccount = strAccount.c_str();
		const char* pszPasswd = strPasswd.c_str();
		CMailBox* mb = GetServer()->GetClientMailbox(nFd);
		LogInfo("CWorldLogin::account_login", "client attempt to login;account=%s;passwd=%s;fd=%d", pszAccount, pszPasswd, nFd);

		struct timeval tv;
		if (gettimeofday(&tv, NULL) == 0)
		{
			int32_t nFd = VOBJECT_GET_I32((*p)[2]);
			CMailBox* mb = GetServer()->GetClientMailbox(nFd);
			if(mb)
			{
				map<string, uint32_t>::const_iterator iter1 = m_forbiddenLogin.find(strAccount);
				if (iter1 != m_forbiddenLogin.end() && iter1->second > (uint32_t)tv.tv_sec)
				{
					LogWarning("CWorldLogin::AccountLogin", "client login forbidden;account=%s;fd=%d;time=%d",
						pszAccount, nFd, iter1->second);

					CPluto* u = new CPluto;
					(*u).Encode(MSGID_CLIENT_LOGIN_RESP) << (uint8_t)ENUM_LOGIN_FORBIDDEN_LOGIN << EndPluto;

					mb->PushPluto(u);
					return 0;
				}

				string strIp = mb->GetServerName();
				map<string, uint32_t>::const_iterator iter2 = m_forbiddenIP.find(strIp);
				if (iter2 != m_forbiddenIP.end() && iter2->second > (uint32_t)tv.tv_sec)
				{
					LogWarning("CWorldLogin::AccountLogin", "client login ip(%s) forbidden;account=%s;fd=%d;time=%d",
						strIp.c_str(), pszAccount, nFd, iter2->second);

					CPluto* u = new CPluto;
					(*u).Encode(MSGID_CLIENT_LOGIN_RESP) << (uint8_t)ENUM_LOGIN_FORBIDDEN_LOGIN << EndPluto;

					mb->PushPluto(u);
					return 0;
				}
			}		
		}
		else
		{
			LogWarning("CWorldLogin::AccountLogin", "tv errno=%d;errstr=%s", errno, strerror(errno));
		}

        if(m_fd2accounts.find(nFd) != m_fd2accounts.end())
        {
            //同一个连接上的重复认证,不给错误提示
            LogInfo("CWorldLogin::account_login", "login is in progress;account=%s;fd=%d", pszAccount, nFd);
            return 0;
        }

        map<string, int>::const_iterator iter = m_accounts2fd.find(pszAccount);
        if(iter != m_accounts2fd.end())
        {
            int fd2 = iter->second;
            if(nFd == fd2)
            {
                //同一个连接上的重复认证,不给错误提示
                LogInfo("CWorldLogin::account_login", "login is in progress(2);account=%s;fd=%d", pszAccount, nFd);
                return 0;
            }
            else
            {
                map<string, time_t>::iterator iter2 = m_accountsInVerify.find(strAccount);
                if(iter2 == m_accountsInVerify.end())
                {
                    //第一次发生冲突,踢掉新的连接,保留老连接等待认证完成
                    //同时记录冲突发生的时间,以防再次冲突
                    LogInfo("CWorldLogin::account_login", "multilogin,kick off new;account=%s;fd=%d;old=%d", \
                        pszAccount, nFd, fd2);
                    GetServer()->CloseFdFromServer(nFd);
                    m_accountsInVerify.insert(make_pair(strAccount, time(NULL)));
                    return 0;
                }
                else
                {
                    //如果两次认证间隔时间小于3秒,则保留老连接(不修改冲突时间);否则踢掉老连接
                    int nTimeDelta = time(NULL) - iter2->second;
                    if(nTimeDelta < 3)
                    {
                        LogInfo("CWorldLogin::account_login", "multilogin,delta<3,kick off new;account=%s;fd=%d;old=%d", \
                            pszAccount, nFd, fd2);
                        GetServer()->CloseFdFromServer(nFd);
                        return 0;
                    }
                    else
                    {
                        LogInfo("CWorldLogin::account_login", "multilogin,kick off old;account=%s;fd=%d;old=%d", \
                            pszAccount, nFd, fd2);
                        m_fd2accounts.erase(fd2);
                        m_accounts2fd.erase(pszAccount);
                        GetServer()->CloseFdFromServer(fd2);
                        m_accountsInVerify.erase(iter2);        //删掉冲突记录
                        //继续下面的流程,开启一个新的认证
                    }
                }
            }
        }

        m_fd2accounts.insert(make_pair(nFd, pszAccount));
        m_accounts2fd.insert(make_pair(pszAccount, nFd));

        if(bLoginFirst)
        {
            //开发模式,要先校验一下
            CMailBox* mb2 = this->GetServerMailbox(SERVER_DBMGR);
            if(mb2)
            {
                mb2->RpcCall(GetRpcUtil(), MSGID_DBMGR_SELECT_ACCOUNT, GetMailboxId(), nFd, pszAccount, pszPasswd);
            }
        }
        else
        {
            CMailBox* mb2 = this->GetServerMailbox(SERVER_BASEAPPMGR);
            if(mb2)
            {
                //平台认证后的登陆直接进了
                //标记1表示如果数据库中不存在,也要创建一个entity
                mb2->RpcCall(GetRpcUtil(), MSGID_BASEAPPMGR_CREATEBASE_FROM_NAME_ANYWHERE, (uint8_t)1, "Account", pszAccount);                
            }
        }

        return 0;
    }


#if __PLAT_PLUG_IN || __PLAT_PLUG_IN_NEW
	int CWorldLogin::AccountRealLogin(const char* pszAccount, const int32_t nFd)
#else
	int CWorldLogin::AccountRealLogin(const char* pszAccount, const char* pszPasswd, const int32_t nFd)
#endif
	{
		if(m_fd2accounts.find(nFd) != m_fd2accounts.end())
		{
			//同一个连接上的重复认证,不给错误提示
			LogInfo("CWorldLogin::account_login", "login is in progress;account=%s;fd=%d", pszAccount, nFd);
			return 0;
		}

		map<string, int>::const_iterator iter = m_accounts2fd.find(pszAccount);
		if(iter != m_accounts2fd.end())
		{
			int fd2 = iter->second;
			if(nFd == fd2)
			{
				//同一个连接上的重复认证,不给错误提示
				LogInfo("CWorldLogin::account_login", "login is in progress(2);account=%s;fd=%d", pszAccount, nFd);
				return 0;
			}
			else
			{
				//不同连接上的同一个用户的认证,踢掉老的用户
				m_fd2accounts.erase(fd2);
				m_accounts2fd.erase(pszAccount);
				GetServer()->CloseFdFromServer(fd2);
				LogInfo("CWorldLogin::account_login", "multilogin,kick off old;account=%s;fd=%d;old=%d", \
					pszAccount, nFd, fd2);
			}
		}

		m_fd2accounts.insert(make_pair(nFd, pszAccount));
		m_accounts2fd.insert(make_pair(pszAccount, nFd));

		CMailBox* mb = this->GetServerMailbox(SERVER_DBMGR);
		if(mb)
		{
#if __PLAT_PLUG_IN || __PLAT_PLUG_IN_NEW
			mb->RpcCall(GetRpcUtil(), MSGID_DBMGR_SELECT_ACCOUNT, GetMailboxId(), nFd, pszAccount);
#else
			mb->RpcCall(GetRpcUtil(), MSGID_DBMGR_SELECT_ACCOUNT, GetMailboxId(), nFd, pszAccount, pszPasswd);
#endif	
		}

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

        LogInfo("CWorldLogin::select_account_callback", "account=%s;fd=%d;ret=%d", pszAccount, fd, nRet);

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
                mb->SetAuthz(MAILBOX_CLIENT_AUTHZ);
            }
            (*pu).Encode(MSGID_CLIENT_LOGIN_RESP) << (uint8_t)ENUM_LOGIN_SUCCESS << EndPluto;

            //创建account
            CMailBox* mb2 = GetServerMailbox(SERVER_BASEAPPMGR);
            if(mb2)
            {
                //标记1表示如果数据库中不存在,也要创建一个entity
                mb2->RpcCall(GetRpcUtil(), MSGID_BASEAPPMGR_CREATEBASE_FROM_NAME_ANYWHERE, (uint8_t)1, "Account", pszAccount);
            }
        }

        if(mb != NULL)
        {
            LogDebug("CWorldLogin::SelectAccountCallback", "u.GenLen()=%d", pu->GetLen());

            mb->PushPluto(pu);
        }
        else
        {
            delete pu;
            LogDebug("CWorldLogin::SelectAccountCallback", "");
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

        LogDebug("NotifyClientToAttach", "account=%s;fd=%d %s", pszAccount, iter->second, pszKey);
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

    int CWorldLogin::NotifyClientMultiLogin(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 1)
        {
            return -1;
        }

        const char* pszAccount = VOBJECT_GET_STR((*p)[0]);

        map<string, int>::const_iterator iter = m_accounts2fd.find(pszAccount);
        if(iter == m_accounts2fd.end())
        {
            LogWarning("NotifyClientMultiLogin", "Account '%s' hasn't client", pszAccount);
            return -2;
        }

        CMailBox* mb = GetServer()->GetClientMailbox(iter->second);
        if(mb != NULL)
        {
            LogDebug("NotifyClientMultiLogin", "account=%s;fd=%d", pszAccount, iter->second);

            CPluto* u = new CPluto;
            (*u).Encode(MSGID_CLIENT_NOTIFY_MULTILOGIN);
            (*u) << EndPluto;
            mb->PushPluto(u);
        }

        return 0;
    }

    int CWorldLogin::ModifyLoginFlag(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 1)
        {
            return -1;
        }

        uint8_t flag = VOBJECT_GET_U8((*p)[0]);
        if(flag == 1)
        {
            m_bCanLogin = true;
        }
        else
        {
            m_bCanLogin = false;
        }

        //记录日志
        LogInfo("CWorldLogin::ModifyLoginFlag", "input=%d;flag=%d", flag, m_bCanLogin);

        return 0;
    }

    bool CWorldLogin::CheckClientRpc(CPluto& u)
     {
        CMailBox* mb = u.GetMailbox();
        if(!mb)
        {
            //如果没有mb,是从本进程发来的包
            return true;
        }
        uint8_t authz = mb->GetAuthz();
        if(authz == MAILBOX_CLIENT_TRUSTED)
        {
            return true;
        }
        else if(authz == MAILBOX_CLIENT_UNAUTHZ)
        {
            pluto_msgid_t msg_id = u.GetMsgId();
            return msg_id == MSGID_LOGINAPP_LOGIN || msg_id == MSGID_LOGINAPP_CHECK || msg_id == MSGID_LOGINAPP_LOGIN_VERIFY_CALLBACK;
        }
        else
        {
            return false;
        }
        return false;
    }

    int CWorldLogin::ModifyOnlineCount(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 2)
        {
            return -1;
        }

        uint8_t flag = VOBJECT_GET_U8((*p)[0]);
        uint8_t modifyCount = VOBJECT_GET_U8((*p)[1]);

        if (flag == 0)
        {
            this->m_onlineCount += modifyCount;
        }
        else if (flag == 1)
        {
            int32_t tmp = this->m_onlineCount - modifyCount;

            if (tmp < 0)
            {
                this->m_onlineCount = 0;
            } 
            else
            {
                this->m_onlineCount = tmp;
            }
        }

        LogDebug("CWorldLogin::ModifyOnlineCount", "flag=%d;modifyCount=%d;m_onlineCount=%d", flag, modifyCount, this->m_onlineCount);

        return 0;
    }

#if __PLAT_PLUG_IN  || __PLAT_PLUG_IN_NEW
	int CWorldLogin::AccountVerify(string& strSuid, string& strSign, string& timestamp)
	{
		//suid&timestamp&serverkey
		//char* a[12];
		//snprintf(a, sizeof(a), "%d", timestamp);

		string s = strSuid + "&";
		s += timestamp + "&";
		s += "5a9513158a0254f81951236449190bfb";
		LogDebug("CWorldLogin::AccountVerify", "s : %s", s.c_str());
		m_md5.reset();
		m_md5.update(s);
		string sig = m_md5.toString();
#ifdef _WIN32
		if(stricmp(sig.c_str(), strSign.c_str()) != 0)
#else
		if (strcasecmp(sig.c_str(), strSign.c_str()) != 0)
#endif
		{
			return -1;
		}
		return 0;
	}

	string CWorldLogin::GetGameAccount(const string& strSuid, const string& strPlatId)
	{
		string strAccount = strSuid + "_";
		strAccount = strAccount + strPlatId;
		return strAccount;
	}
#endif


#if __PLAT_PLUG_IN_NEW
	int CWorldLogin::SdkServerCheckReq(const string& strToken, const int32_t nFd, const string& strSuid, const string& strPlatId)
	{
		if(m_fd2accounts.find(nFd) != m_fd2accounts.end())
		{
			//同一个连接上的重复认证,不给错误提示
			LogInfo("CWorldLogin::account_login", "login is in progress;account=%s;fd=%d", strSuid.c_str(), nFd);
			return 0;
		}
		//string url = "https://api.4399sy.com/service/verify?verifyToken=03bf9b7d6cd652b08fd214d2a020828f";
		static string strUrl = "https://api.4399sy.com/service/verify?verifyToken=";
		string url = strUrl + strToken;
		//创建account
		static CMailBox* mb = GetServerMailbox(SERVER_LOG);
		if(mb)
		{
			//标记1表示如果数据库中不存在,也要创建一个entity
			//for (int i=0 ; i < 50; i++)
			//{
				mb->RpcCall(GetRpcUtil(), MSGID_OTHER_LOGIN_VERIFY, url, nFd, strSuid, strPlatId);
			//}	
		}
		return 0;
	}

	int CWorldLogin::SdkServerCheckResp(T_VECTOR_OBJECT* p)
	{
		if (p->size() != 4)
		{
			return -1;
		}
		int32_t rst = VOBJECT_GET_I32((*p)[0]);
		int32_t nFd = VOBJECT_GET_I32((*p)[1]);
		string& strSuid = VOBJECT_GET_SSTR((*p)[2]);
		string& strPlatId = VOBJECT_GET_SSTR((*p)[3]);

		string strAccount = GetGameAccount(strSuid, strPlatId);

		if(m_fd2accounts.find(nFd) != m_fd2accounts.end())
		{
			//同一个连接上的重复认证,不给错误提示
			LogInfo("CWorldLogin::SdkServerCheckResp", "login is in progress;account=%s;fd=%d", strAccount.c_str(), nFd);
			return 0;
		}

		CMailBox* mb = GetServer()->GetClientMailbox(nFd);
		if (!mb)
		{
			LogWarning("CWorldLogin::SdkServerCheckResp", "%s mb is null.", strAccount.c_str());
			return 0;
		}	

		CPluto* u = NULL;
		if (rst == CURLE_OPERATION_TIMEDOUT)
		{
			u = new CPluto;
			u->Encode(MSGID_CLIENT_LOGIN_RESP);
			(*u) << ENUM_LOGIN_SERVER_BUSY << EndPluto;
		}
		else if (-1 == rst)
		{
			u = new CPluto;
			u->Encode(MSGID_CLIENT_LOGIN_RESP);
			(*u) << ENUM_LOGIN_SDK_VERIFY_FAILED << EndPluto;
		}
		else if (1 == rst)
		{
			LogWarning("CWorldLogin::SdkServerCheckResp", "%s account is illegal.", strAccount.c_str());
			u = new CPluto;
			u->Encode(MSGID_CLIENT_LOGIN_RESP);
			(*u) << ENUM_LOGIN_ACCOUNT_ILLEGAL << EndPluto;
		}
		else if (-2 == rst)
		{
			u = new CPluto;
			u->Encode(MSGID_CLIENT_LOGIN_RESP);
			(*u) << ENUM_LOGIN_SERVER_BUSY << EndPluto;
		}
		else
		{
			return AccountRealLogin(strAccount.c_str(), nFd);
			//LogWarning("CWorldLogin::SdkServerCheckResp", "%s", strAccount.c_str());
		}
		LogWarning("CWorldLogin::SdkServerCheckResp", "%s", strAccount.c_str());
		mb->PushPluto(u);
		return 0;
	}
#endif

}
