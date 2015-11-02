#include "world_crossserver.h"
#include "crossserver.h"


namespace mogo
{


CWorldCrossserver::CWorldCrossserver() : m_baseBalance(), m_nCrossRpcSeq(0)
{
}

CWorldCrossserver::~CWorldCrossserver()
{
    ClearMap(m_InRpc);
    ClearMap(m_globalBases);
}

int CWorldCrossserver::init(const char* pszEtcFile)
{
	LogInfo("CWorldCrossserver::init()", "");

	int nWorldInit = world::init(pszEtcFile);
	if(nWorldInit != 0)
	{
		return nWorldInit;
	}

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
	}

    //计算def文件的md5
    {
        try
        {
            const string& strDefPath = GetCfgReader()->GetValue("init", "def_path");
            m_strDefMd5.assign(GetDefParser().CalcMd5OfAll(strDefPath.c_str()));
            LogInfo("CalcMd5OfAll", "md5=%s", m_strDefMd5.c_str());
        }
        catch(const CException& ex)
        {
            LogError("CWorldCrossserver::init.error", "Failed_to_calc_def_md5");
            return -10;
        }        
    }    

	return 0;
}

//根据需要创建的entity类型权重和各个baseapp的负载选择一个合适的baseapp的mailbox id
uint16_t CWorldCrossserver::ChooseABaseapp(const char* pszEntityType)
{
	uint16_t nServerId = m_baseBalance.GetLestWeightId();
	m_baseBalance.AddWeight(nServerId, 1);
	return nServerId;
}

//检查一个rpc调用是否合法
bool CWorldCrossserver::CSCheckClientRpc(CPluto& u)
{
	CMailBox* mb = u.GetMailbox();
	if(!mb)
	{
		//如果没有mb,是从本进程发来的包
		return true;
	}
	if(mb->IsDelete())
	{
		//已标记del的mb,其所有的包不再处理
		return false;
	}
	uint8_t authz = mb->GetAuthz();
	if(authz == MAILBOX_CLIENT_TRUSTED)
	{
		return true;
	}
	else if(authz == MAILBOX_CLIENT_UNAUTHZ)
	{
		//检查客户端地址是否可以信任
		//return CheckTrustedMailbox(mb);
        return u.GetMsgId() == MSGID_CROSSSERVER_CHECK_MD5;
	}
	else if(authz == MAILBOX_CLIENT_AUTHZ)
	{
		//return CheckTrustedMailbox(mb);
        return true;
	}
	else
	{
		return false;
	}
}

//bool CWorldCrossserver::CheckTrustedMailbox(CMailBox* pmb)
//{
//	if(((CCrossserverServer*)GetServer())->IsTrustedIp(pmb->GetServerName()))
//	{
//		//设置信任标记
//		pmb->SetAuthz(MAILBOX_CLIENT_TRUSTED);
//		LogInfo("check_trusted_mailbox", "ip=%s", pmb->GetServerName().c_str());
//		return true;
//	}
//	else
//	{
//		//断开连接
//		GetServer()->CloseFdFromServer(pmb->GetFd());
//		LogInfo("check_trusted_mailbox.err", "ip=%s", pmb->GetServerName().c_str());
//		return false;
//	}
//}

int CWorldCrossserver::FromRpcCall(CPluto& u)
{
    //printf("CWorldLogin::from_rpc_call\n");

	pluto_msgid_t msg_id = u.GetMsgId();
	if(!CSCheckClientRpc(u))
	{
		LogWarning("from_rpc_call", "invalid rpcall error.unknown msgid:%d\n", msg_id);
		return -1;
	}

	u.Decode();
    int nRet = ERR_RPC_UNKNOWN_MSGID;
    switch(msg_id)
    {
        //case MSGID_CROSSSERVER_ON_CROSS_REQ:
        //{
        //    nRet = OnCrossReq(u);
        //    break;
        //}
        case MSGID_CROSSSERVER_RPC:
        {
            nRet = OnCrossServerRpc(u);
            break;
        }
        case MSGID_CROSSSERVER_REGISTER_SERVER:
        {
            nRet = RegisterServer(u);
            break;
        }
        case MSGID_CROSSSERVER_CLIENT_RESP_PROXY:
        {
            nRet = OnCrossClientResp(u);
            break;
        }
        case MSGID_CROSSSERVER_CLIENT_BC_PROXY:
        {
            nRet = OnCrossClientBroadcast(u);
            break;
        }
        case MSGID_CROSSSERVER_CHECK_MD5:
        {
            nRet = CheckMd5(u);
            break;
        }
        default:
        {
            LogWarning("CWorldCrossserver::from_rpc_call", "unknown msgid:%d\n", msg_id);
            break;
        }
    }

	if(nRet != 0)
	{
		LogWarning("from_rpc_call", "rpc error.msg_id=%d;ret=%d\n", msg_id, nRet);
	}

    return 0;
}

//跨服请求
int CWorldCrossserver::OnCrossReq(CPluto& u)
{
	////由本进程来做平衡选择和id生成规则
	//uint16_t nBaseappId = ChooseABaseapp("Avatar");	
	//CMailBox* mb = GetServerMailbox(nBaseappId);
	//printf("CWorldCrossserver::cross_req,choose_base:%d,mb:%x\n", nBaseappId, mb);
	//if(mb)
	//{
	//	//生成新的id
	//	TENTITYID eid = GetNextEntityId();

	//	CPluto* u2 = new CPluto;
	//	u2->Encode(MSGID_BASEAPP_CREATE_BASE_FROM_CROSS);
	//	u2->FillField<TENTITYID>(eid);
	//	u2->FillBuff(u.getBuff()+u.getLen(), u.getMaxLen()-u.getLen());
	//	u2->EndPluto();
	//	mb->PushPluto(u2);
	//}

	return 0;
}

//来自原始服的跨服调用
int CWorldCrossserver::OnCrossServerRpc(CPluto& u)
{
    //printf("CWorldCrossserver::OnCrossServerRpc 111\n");

    CHECK_AND_GET_RPC_FIELD(u, uSrcServerId, uint16_t);
    CHECK_AND_GET_RPC_FIELD(u, etype, TENTITYTYPE);
    CHECK_AND_GET_RPC_FIELD(u, eid, TENTITYID);
    CHECK_AND_GET_RPC_FIELD(u, strGlobal, string);
    //CHECK_AND_GET_RPC_FIELD(u, strFuncId, uint16_t);

    uint32_t nSeq = GetNextRpcSeq(u, uSrcServerId, etype, eid);
    if(nSeq == 0)
    {
        return -1;
    }

    //printf("CWorldCrossserver::OnCrossServerRpc 222, %d - %d - %d - %s - seq =%d \n", uSrcServerId, etype, eid, strGlobal.c_str(), nSeq);

    map<string, CEntityMailbox*>::iterator iter1 = m_globalBases.find(strGlobal);
    if(iter1 == m_globalBases.end())
    {
        return -2;
    }

    CEntityMailbox* emb = iter1->second;
    CMailBox* mb = GetServerMailbox(emb->m_nServerMailboxId);
    if(mb)
    {
        CPluto* u2 = new CPluto;
        u2->Encode(MSGID_BASEAPP_ENTITY_RPC) << (*emb);
        u2->FillBuff(u.GetBuff()+u.GetLen(), 2);        //msg_id
        u2->FillField(nSeq);                            //填充流水号字段
        u2->FillBuff(u.GetBuff()+u.GetLen()+2, u.GetMaxLen()-u.GetLen()-2);//copy其他字段
        u2->endPluto();
        mb->PushPluto(u2);

        return 0;
    }

    return -2;
}

//获取一个流水号
uint32_t CWorldCrossserver::GetNextRpcSeq(CPluto& u, uint16_t sid, TENTITYTYPE etype, TENTITYID eid)
{
    CMailBox* mb = u.GetMailbox();
    if(mb == NULL)
    {
        return 0;
    }
    int fd = mb->GetFd();

    int nSeq;
    if(m_lsFreeRpcSeq.empty())
    {
        //没有空闲流水号了
        ++m_nCrossRpcSeq;
        nSeq = m_nCrossRpcSeq;
    }
    else
    {
        nSeq = m_lsFreeRpcSeq.front();
        m_lsFreeRpcSeq.pop_front();
    }

    _SCrossClientInfo* pInfo = new _SCrossClientInfo(fd, sid, etype, eid);
    m_InRpc.insert(make_pair(nSeq, pInfo));

    return nSeq;
}

//注册一个跨服服务提供者
int CWorldCrossserver::RegisterServer(CPluto& u)
{
    //globalbase名字
    CHECK_AND_GET_RPC_FIELD(u, strName, string);

    CEntityMailbox* emb = new CEntityMailbox;
    u >> *emb;
    if(u.GetDecodeErrIdx() > 0)
    {
        delete emb;
        return ERR_RPC_DECODE;
    }

    map<string, CEntityMailbox*>::iterator iter1 = m_globalBases.lower_bound(strName);
    if(iter1 != m_globalBases.end() && iter1->first == strName)
    {
        delete iter1->second;
        iter1->second = emb;
        LogInfo("CWorldCrossserver::RegisterServer", "s=%s;err=dup", strName.c_str());
    }
    else
    {
        m_globalBases.insert(iter1, make_pair(strName, emb));
        LogInfo("CWorldCrossserver::RegisterServer", "s=%s", strName.c_str());
    }

    return 0;
}

int CWorldCrossserver::OnCrossClientResp(CPluto& u)
{
    CHECK_AND_GET_RPC_FIELD(u, nSeq, uint32_t);

    //检查流水号对应的外系统连接是否还在
    map<uint32_t, _SCrossClientInfo*>::iterator iter1 = m_InRpc.find(nSeq);
    if(iter1 == m_InRpc.end())
    {
        LogWarning("CWorldCrossserver::OnCrossClientResp", "notfound_seq=%d", nSeq);
        return -1;
    }

    _SCrossClientInfo* pInfo = iter1 ->second;
    CMailBox* mb = GetServer()->GetClientMailbox(pInfo->fd);
    if(mb == NULL)
    {
        //外系统已经断开连接了
        LogWarning("CWorldCrossserver::OnCrossClientResp", "notfoundclient_seq=%d", nSeq);
        return -2;
    }

    CPluto* u2 = new CPluto;
    u2->Encode(MSGID_CROSSCLIENT_RESP) << pInfo->sid << pInfo->etype << pInfo->eid;
    //转发包内容
    u2->FillBuff(u.GetBuff()+u.GetLen(), u.GetMaxLen()-u.GetLen());
    u2->endPluto();
    mb->PushPluto(u2);

    //删除数据,即每个流水号只能被回调一次
    delete pInfo;
    m_InRpc.erase(iter1);
    m_lsFreeRpcSeq.push_back(nSeq); //流水号重用

    return 0;
}

//发给所有连接上的分服的广播消息
int CWorldCrossserver::OnCrossClientBroadcast(CPluto& u)
{
    ((CCrossserverServer*)GetServer())->OnCrossClientBroadcast(u);
    return 0;
}

//检查所有服的所有def文件的md5是否匹配
int CWorldCrossserver::CheckMd5(CPluto& u)
{
    CMailBox* pmb = u.GetMailbox();
    if(pmb == NULL)
    {
        return -1;
    }

    if(((CCrossserverServer*)GetServer())->IsTrustedIp(pmb->GetServerName()))
    {
        //来自受信任的客户端,校验md5是否匹配
        CHECK_AND_GET_RPC_FIELD(u, strMd5, string);

        if(m_strDefMd5 == strMd5)
        {
            //设置信任标记
            pmb->SetAuthz(MAILBOX_CLIENT_TRUSTED);
            LogInfo("CheckMd5", "ip=%s", pmb->GetServerName().c_str());

            return 0;
        }
        else
        {
            LogWarning("CheckMd5.err1", "md5_mismatch;self=%s;other=%s", m_strDefMd5.c_str(), strMd5.c_str());
            return -2;
        }
    }

    //来自不受信任的客户端,断开连接
    GetServer()->CloseFdFromServer(pmb->GetFd());
    LogInfo("CheckMd5.err2", "err_ip=%s", pmb->GetServerName().c_str());    
    return -3;
}


}

