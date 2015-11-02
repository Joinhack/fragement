#include "world_other.h"
#include "pluto.h"
#include <string>
#include "other_def.h"
#include <curl/curl.h> 
#include <iostream>
//#include "http.h"
#include "cjson.h"

using std::string;

extern int IsMd5Ok(Method_Params& mp, const char* key);
extern int IsPlatMd5OK(Method_Params& mp, const char* key);
extern int DecodeUrl(string & url, OUT Method_Params& result);
extern void decode_value(map<string, string>& params);

extern tg_API_LIB g_api_lib;

#ifndef _WIN32
#include "db_task.h"
#endif

#include "threadpool.h"
extern threadpool* g_threadpool;
extern void* ThreadJob_SdkServerVerify(void* arg);
extern int GetUrl(const char* url, OUT string& result);
extern int GetUrl_new(const char* url, OUT string& result);
namespace mogo
{

	CWorldOther::CWorldOther() : m_baseBalance()
	{

	}

	CWorldOther::~CWorldOther()
	{
	}

	int CWorldOther::init(const char* pszEtcFile)
	{
		LogDebug("CWorldOther::init()", "a=%d", 1);

		int nWorldInit = world::init(pszEtcFile);
		if(nWorldInit != 0)
		{
			return nWorldInit;
		}

		try
		{
			GetDefParser().init(m_cfg->GetValue("init", "def_path").c_str());
			GetDefParser().ReadDbCfg(m_cfg);
		}
		catch(const CException& e)
		{
			LogDebug("CWorldOther::init().error", "%s", e.GetMsg().c_str());
			return -1;
		}

		////需要一个空的lua环境来保存LUA_TABLE类型的数据
		/*
		m_L = lua_open();
		if(m_L==NULL)
		{
		return -1;
		}
		luaL_newmetatable(m_L, "G_LUATABLES");
		lua_setglobal(m_L, "G_LUATABLES");
		*/
		//将所有的
		list<CMailBox*>& mbs = m_mbMgr.GetMailboxs();
		list<CMailBox*>::iterator iter = mbs.begin();
		for(; iter != mbs.end(); ++iter)
		{
			CMailBox* p = *iter;
			if(p->GetServerMbType() == SERVER_BASEAPP)
			{
				m_baseBalance.AddNewId(p->GetMailboxId());
			}
			//else if(p->GetServerMbType() == SERVER_CELLAPP)
			//{
			//  m_cellBalance.addNewId(p->GetMailboxId());
			//}
		}

		return 0;
	}

	int CWorldOther::FromRpcCall(CPluto& u, CDbOper& db)
	{
		//printf("CWorldOther::from_rpc_call\n");
		//print_hex_pluto(u);

		pluto_msgid_t msg_id = -1;
		T_VECTOR_OBJECT* p = NULL;

		//这一段要加锁(2012/02/15改为不加锁)
		{
			//CMutexGuard _g(m_rpcMutex);

			msg_id = u.GetMsgId();
			if(!CheckClientRpc(u))
			{
				LogWarning("from_rpc_call", "invalid rpcall error.unknown msgid:%d\n", msg_id);
				return -1;
			}

			p = m_rpc.Decode(u);
			if(p == NULL)
			{
				LogWarning("from_rpc_call", "rpc Decode error.unknown msgid:%d\n", msg_id);
				return -1;
			}

			if(u.GetDecodeErrIdx() > 0)
			{
				ClearTListObject(p);
				//PrintHexPluto(u);
				LogWarning("from_rpc_call", "rpc Decode error.msgid:%d;pluto err idx=%d\n", msg_id, u.GetDecodeErrIdx());
				return -2;
			}
		}

        //这一段不用加锁
        int nRet = -1;
        switch(msg_id)
        {
            case MSGID_LOG_INSERT:
            {
                nRet = InsertDB(p, db);
                break;
            }
            case MSGID_OTHER_HTTP_REQ:
            {
                nRet = ReqUrl(p);
                break;
            }
            case MSGID_ALLAPP_SHUTDOWN_SERVER:
            {
                nRet = ShutdownServer(p);
                break;
            }
            case MSGID_OTHER_ADD_GLOBALBASE:
            {
                nRet = RegisterGlobally(p);
                break;
            }
            case MSGID_OTHER_YUNYING_API:
            {
                nRet = SupportApi(p, u.GetMailbox(), db);
                break;
            }
            case MSGID_OTHER_CLIENT_RESPONSE:
            {
                nRet = Response2Browser(p);
				PrintHexPluto(u);
                break;
            }
            //case MSGID_OTHER_LOGIN_VERIFY:
            //{
            //    //todo:verify
            //    nRet = SdkServerVerify(p, u);
            //    break;
            //}
// 			case MSGID_OTHER_PLAT_API:
// 			{
// 				nRet = PlatApi(p, u.GetMailbox(), db);
// 				break;
// 			}
            default:
            {
                LogWarning("from_rpc_call", "rpc unkown msg_id = %d\n", msg_id, nRet);
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

	//     int CWorldOther::InsertDB(T_VECTOR_OBJECT* p, CDbOper& db)
	//     {
	//         if(p->size() != 3)
	//         {
	//             return -1;
	//         }
	// 
	//         CEntityMailbox& emb = VOBJECT_GET_EMB((*p)[0]);
	//         const char* sql = VOBJECT_GET_STR((*p)[1])
	//    	
	// 		string strErr;
	// 		int newId = db.TableInsert(sql, strErr);
	// 
	// 		if(newId == 0)
	// 		{
	// 			LogWarning("InsertDB_err", "newid=0;err=%s", strErr.c_str());	
	// 		}
	// 
	//         //通知db结果
	//         CEpollServer* s = this->GetServer();
	//         CMailBox* mb = s->GetServerMailbox(emb.m_nServerMailboxId);
	//         if(mb)
	//         {
	// 			printf("InsertDB_ok");
	// 		}
	// 
	//         return 0;
	//     }
	// 


	bool CWorldOther::InitMutex()
	{
#ifdef _WIN32
		return true;
#else
		return pthread_mutex_init(&m_entityMutex, NULL) == 0 && pthread_mutex_init(&m_rpcMutex, NULL)==0;
#endif
	}


	int CWorldOther::Response2Browser(int nFd, const string& response)
	{
		//CMailBox* mb = GetServerMailbox(emb.m_nServerMailboxId);
		CMailBox* mb = GetServer()->GetClientMailbox(nFd);
		if (mb)
		{
			CPluto* u = new CPluto;
			(*u).Encode(MSGID_LOG_INSERT) <<response.c_str() << EndPluto;  //这里是返回给浏览器 msg_id 用不到  就随便给个50以上的了
			mb->PushPluto(u);
			LogDebug("Response2Browser", "fd: %d,response:%s",nFd, response.c_str());
			
		}

		return 0;

	}

	// 	
	int CWorldOther::InsertDB(T_VECTOR_OBJECT* p, CDbOper& db)
	{
		if (p->size() != 1)
		{
			LogError("CWorldOther::InsertDB", "p->size()=%d", p->size());
			return -1;
		}

		const string& strSql = VOBJECT_GET_SSTR((*p)[0]);

		//LogDebug("CWorldOther::InsertDB", "strSql=%s", strSql.c_str());

		string strErr;
		int newId = db.TableInsert(strSql, strErr);

		if(newId == 0)
		{
			LogWarning("InsertDB_err", "newid=0;err=%s", strErr.c_str());
			//cout << strErr << endl;
			//return -2;
		}

		return 0;
	}


	int CWorldOther::ReqUrl(T_VECTOR_OBJECT* p)
	{
		if (p->size() != 1)
		{
			LogError("CWorldOther::ReqUrl", "p->size()=%d", p->size());
			return -1;
		}

		const string& url = VOBJECT_GET_SSTR((*p)[0]);

		reqUrl(url.c_str());

		return 0;
	}


    int CWorldOther::ShutdownServer(T_VECTOR_OBJECT* p)
    {
        LogDebug("CWorldOther::ShutdownServer", "");

        GetServer()->Shutdown();

        g_bShutdown = true;
        //回应cwmd,本进程已经退出

        SyncRpcCall(g_pluto_sendlist, SERVER_BASEAPPMGR, MSGID_BASEAPPMGR_ON_SERVER_SHUTDOWN, GetMailboxId());

        return 0;
    }

	int CWorldOther::RegisterGlobally(T_VECTOR_OBJECT* p)
	{
		//printf("rrrr,%d\n", p->size());
		if(p->size() != 2)
		{
			return -1;
		}

		const char* szName = VOBJECT_GET_STR((*p)[0]);
		CEntityMailbox& emb = VOBJECT_GET_EMB((*p)[1]);

		LogDebug("CWorldOther::RegisterGlobally", "szName=%s;m_nServerMailboxId=%d;m_nEntityType=%d;m_nEntityId=%d",
			szName, emb.m_nServerMailboxId, emb.m_nEntityType, emb.m_nEntityId);

		//printf("rrrr2222, %s, %d \n", szName, ref);

		bool bRet = false;
		map<string, CEntityMailbox*>::iterator iter = m_globalBases.lower_bound(szName);
		if(iter != m_globalBases.end() && iter->first.compare(szName) == 0)
		{
			//existed!
		}
		else
		{
			//add new
			bRet = true;
			CEntityMailbox* pe = new CEntityMailbox;
			pe->m_nServerMailboxId = emb.m_nServerMailboxId;
			pe->m_nEntityType = emb.m_nEntityType;
			pe->m_nEntityId = emb.m_nEntityId;
			m_globalBases.insert(iter, make_pair(szName, pe));
		}

		return 0;
	}

// 	int CWorldOther::SupportApi(T_VECTOR_OBJECT* p,CMailBox* pmb, CDbOper& db)
// 	{
// 
// 		if(p->size() != 1)
// 		{
// 			return -1;
// 		}
// 
// 		//const char* url = VOBJECT_GET_STR((*p)[0]);
// 		string& url = VOBJECT_GET_SSTR((*p)[0]);
// 
// 		LogDebug("CWorldOther::SupportApi", "url=%s", url.c_str());
// 
// 		int32_t client_fd =  pmb->GetFd();
// 		Method_Params mp;
// 		DecodeUrl(url, mp);
// 
// 
// 		if (1 ==  IsMd5Ok(mp,"aiyou123456")) //md5验证成功
// 		{
// 			decode_value(mp.params); //因为要算md5 所以params还是URL  这里需要decode
// 			RunApi(client_fd, mp, db);
// 
// 			//BaseCall("Collector", "API", client_fd, mp.method, mp.params_str);	
// 
// 		}
// 
// 		return 0;
// 	}

	int CWorldOther::SupportApi(T_VECTOR_OBJECT* p,CMailBox* pmb, CDbOper& db)
	{

		if(p->size() != 2)
		{
			LogDebug("CWorldOther::SupportApi", "params_size=%d ", p->size());
			return -1;
		}
		
		string& func_str = VOBJECT_GET_SSTR((*p)[0]);
		string& params_str = VOBJECT_GET_SSTR((*p)[1]);

		LogDebug("CWorldOther::SupportApi", "func =%s \n url=%s", func_str.c_str(), params_str.c_str());

		int32_t client_fd =  pmb->GetFd();

		RunApi(client_fd, func_str, params_str , db);	

		return 0;
	}


	//返回给浏览器
	int CWorldOther::Response2Browser(T_VECTOR_OBJECT* p)
	{
		if(p->size() != 2)
		{
			return -1;
		}

		int32_t nFd = VOBJECT_GET_I32((*p)[0]);
		string& response = VOBJECT_GET_SSTR((*p)[1]);

		g_worldOther.Response2Browser(nFd, response);

		return 0;
	}

	int CWorldOther::BaseCall(const char* mgrName, const char* pszFunc,int nFd, string &method, string& param)
	{

		map<string, CEntityMailbox*>::iterator iter = m_globalBases.find(mgrName);

		if(iter != m_globalBases.end())
		{	
			CEntityMailbox& em = *iter->second;
			const SEntityDef* pDef = GetDefParser().GetEntityDefByType(em.m_nEntityType);
			if(!pDef)
			{
				return -1;
			}

			uint16_t nFuncId = (uint16_t)pDef->m_baseMethodsMap.GetIntByStr(pszFunc);
			if ((uint16_t)-1 ==nFuncId)
			{
				LogDebug("CWorldOther::SupportApi", "error ,,,mgrName=%s, funcName= %s not found!!", mgrName, pszFunc);
				return -1;
			}

            SyncRpcCall(g_pluto_sendlist, em.m_nServerMailboxId, MSGID_BASEAPP_ENTITY_RPC, em , nFuncId, nFd, method, param);
			//existed!
		}
		else
		{
			LogDebug("CWorldOther::SupportApi", "error ,,,mgrName=%s, not found!!", mgrName);
		}

		return 0;
	}

	
// 	int CWorldOther::RunApi(int nFd,  Method_Params & mp, CDbOper& db)
// 	{
// 		tg_API_LIB::iterator itor = g_api_lib.find(mp.method);
// 		if (itor != g_api_lib.end())
// 		{
// 			api_func func = itor->second;
// 			func(nFd, mp, (void*)&db);						
// 		}
// 		else
// 		{
// 			BaseCall("Collector", "API", nFd, mp.method, mp.params_str);//c++层没有 就放到lua去处理
// 		}
// 
// 		return 0;
// 	}

	int CWorldOther::RunApi(int nFd,  string & method_str, string& params_str,  CDbOper& db)
	{

		if ("charge" == method_str) //先判断是否是充值
		{
			LogDebug("RunApi", "charge url = %s", params_str.c_str());
			BaseCall("ChargeMgr", "onChargeReq", nFd, method_str, params_str);
			return 0;
		}
		
		tg_API_LIB::iterator itor = g_api_lib.find(method_str);
		if (itor != g_api_lib.end())
		{
			map<string, string> dictParams;
			SplitStringToMap(params_str, '&', '=', dictParams);

			Method_Params mp;
			mp.method = method_str;
			mp.params = dictParams;

			api_func func = itor->second;
			func(nFd, mp, (void*)&db);						
		}
		else
		{
			BaseCall("Collector", "API", nFd, method_str, params_str);//c++层没有 就放到lua去处理
		}

		return 0;
	}
	
	int CWorldOther::SdkServerVerify(T_VECTOR_OBJECT* p, CPluto& u)
	{
#if 0
        //注释掉老代码
		if (p->size() != 4)
		{
			return -1;
		}
		string& url = VOBJECT_GET_SSTR((*p)[0]);
		int32_t nFd = VOBJECT_GET_I32((*p)[1]);
		string& strAccount = VOBJECT_GET_SSTR((*p)[2]);
		string& strPlatId = VOBJECT_GET_SSTR((*p)[3]);
		CMailBox* pmb = u.GetMailbox();
		if (NULL == pmb)
		{
			return -1;
		}

		CPluto* duplicate = new CPluto(u.GetBuff(), u.GetMaxLen());
		duplicate->SetMailbox(pmb);
		int ret = threadpool_add_job(g_threadpool, ThreadJob_SdkServerVerify, (void*)(duplicate));

		if (ret != 0)
		{
			//直接返回服务器繁忙，请稍后再试
			//printf("服务器繁忙，请稍后再试!\n");
			//std::cout << "服务器繁忙，请稍后再试!" << endl;
			LogWarning("CWorldOther::SdkServerVerify", "threadpool list is full.");
			CPluto* u2 = new CPluto;
			u2->Encode(MSGID_LOGINAPP_LOGIN_VERIFY_CALLBACK);
			(*u2)<< int32_t(-2) << nFd << strAccount << strPlatId << EndPluto;
			g_pluto_sendlist.PushPluto(u2);
			//不适合多线程发送
			//pmb->RpcCall(GetRpcUtil(), MSGID_LOGINAPP_LOGIN_VERIFY_CALLBACK, -2, nFd, strAccount, strPlatId);
		}

		return 0;
#endif

        if (p->size() != 4)
        {
            return -1;
        }
        string& url = VOBJECT_GET_SSTR((*p)[0]);
        int32_t nFd = VOBJECT_GET_I32((*p)[1]);
        string& strAccount = VOBJECT_GET_SSTR((*p)[2]);
        string& strPlatId = VOBJECT_GET_SSTR((*p)[3]);
        CMailBox* pmb = u.GetMailbox();

        pluto_msgid_t msg_id = u.GetMsgId();;

        string resp = "";
        int ret = GetUrl_new(url.c_str(), resp);
        if (ret != CURLE_OK)
        {
            LogWarning("CWorldOther::SdkServerVerify", "%s ret = %d", strAccount.c_str(), ret);
            //todo:faild.
            SyncRpcCall(g_pluto_sendlist, SERVER_LOGINAPP, MSGID_LOGINAPP_LOGIN_VERIFY_CALLBACK, ret, nFd, strAccount, strPlatId);            
            return 0;
        }
        Trim(resp);
        cJSON* json = cJSON_Parse(resp.c_str());
        cJSON* childJs = cJSON_GetObjectItem(json, "code");
        int rst = cJSON_GetObjectItem(json, "code")->valueint;

        if (rst == 1)
        {
            //succeed.
            if (strAccount.c_str() != cJSON_GetObjectItem(json, "msg")->valuestring)
            {
                ret = 0;
            }
            else
            {
                LogWarning("CWorldOther::SdkServerVerify", "strAccount[%s] msg[%s]", 
                    strAccount.c_str(), cJSON_GetObjectItem(json, "msg")->valuestring);
                ret = 1;
                //pmb->RpcCall(GetRpcUtil(), MSGID_LOGINAPP_LOGIN_VERIFY_CALLBACK, int32_t(1), nFd, strAccount, strPlatId);
            }
        }
        else
        {
            //failed.
            LogWarning("CWorldOther::SdkServerVerify", "strAccount[%s] rst[%d]", 
                strAccount.c_str(), rst);
            ret = -1;
            //pmb->RpcCall(GetRpcUtil(), MSGID_LOGINAPP_LOGIN_VERIFY_CALLBACK, -1, nFd, strAccount, strPlatId);
        }
        SyncRpcCall(g_pluto_sendlist, SERVER_LOGINAPP, MSGID_LOGINAPP_LOGIN_VERIFY_CALLBACK, ret, nFd, strAccount, strPlatId);
        return 0;


	}

}
