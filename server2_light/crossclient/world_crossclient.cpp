#include "world_crossclient.h"
#include "crossclient.h"


namespace mogo
{


CWorldCrossclient::CWorldCrossclient() : m_nBcBaseappId(0)
{
}

CWorldCrossclient::~CWorldCrossclient()
{
}

int CWorldCrossclient::init(const char* pszEtcFile)
{
    LogInfo("CWorldCrossclient::init()", "");

    int nWorldInit = world::init(pszEtcFile);
    if(nWorldInit != 0)
    {
        return nWorldInit;
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
            LogError("CWorldCrossclient::init.error", "Failed_to_calc_def_md5");
            return -10;
        }        
    }    

    return 0;
}

bool CWorldCrossclient::CcCheckClientRpc(CPluto& u)
{
    CMailBox* mb = u.GetMailbox();
    if(mb && mb->GetMailboxId() == EXTERN_MAILBOX_ID)
    {
        //如果消息来自跨服连接
        return true;
    }

    return CheckClientRpc(u);
}

int CWorldCrossclient::FromRpcCall(CPluto& u)
{
    //printf("CWorldLogin::from_rpc_call\n");

	pluto_msgid_t msg_id = u.GetMsgId();    
	if(!CcCheckClientRpc(u))
	{
		LogWarning("from_rpc_call", "invalid rpcall error.unknown msgid:%d\n", msg_id);
		return -1;
	}

	u.Decode();
    int nRet = ERR_RPC_UNKNOWN_MSGID;
    switch(msg_id)
    {
		//case MSGID_CROSSCLIENT_CROSS_REQ:
		//{
		//	nRet = CrossReq(u);
		//	break;
		//}
        case MSGID_CROSSCLIENT_SERVER_RPC_PROXY:
        {
            nRet = OnCrossServerRpc(u);
            break;
        }
        case MSGID_CROSSCLIENT_RESP:
        {
            nRet = OnCrossClientResp(u);
            break;
        }
        case MSGID_CROSSCLIENT_BROADCAST:
        {
            nRet = OnCrossClientBroadcast(u);
            break;
        }
		default:
        {
            LogWarning("CWorldCrossclient::from_rpc_call", "unknown msgid:%d\n", msg_id);
            break;
        }
    }

	if(nRet != 0)
	{
		LogWarning("from_rpc_call", "rpc error.msg_id=%d;ret=%d\n", msg_id, nRet);
	}

    return 0;
}




//int CWorldCrossclient::CrossReq(CPluto& u)
//{
//	printf("CWorldCrossclient::cross_req\n");
//
//	CHECK_AND_GET_RPC_FIELD(u, strService, string);
//
//
//	CMailBox* pmb = ((CCrossclientServer*)GetServer())->GetExternMailbox(strService);
//	if(pmb == NULL)
//	{
//		//外系统当前不可用,返回失败消息
//		//todo
//		printf("CWorldCrossclient::cross_req, extern error\n");
//		return 0;
//	}
//
//	//发消息给外系统
//	CPluto* u2 = new CPluto;
//	u2->Encode(MSGID_CROSSSERVER_ON_CROSS_REQ);
//	u2->FillBuff(u.getBuff()+u.getLen(), u.getMaxLen()-u.getLen());
//	u2->EndPluto();
//	pmb->PushPluto(u2);
//
//	return 0;
//}


//转发跨服调用
int CWorldCrossclient::OnCrossServerRpc(CPluto& u)
{
    //跨服服务名
    CHECK_AND_GET_RPC_FIELD(u, strService, string);

    //检查对应的跨服服务器是否已连接
    CMailBox* pmb = ((CCrossclientServer*)GetServer())->GetExternMailbox(strService);
    if(pmb == NULL)
    {
    	//外系统当前不可用,记录日志;返回错误消息也无用
    	LogWarning("CWorldCrossclient::OnCrossServerRpc", "extern error,%s\n", strService.c_str());
    	return 0;
    }

    CPluto* u2 = new CPluto;
    u2->Encode(MSGID_CROSSSERVER_RPC);
    //转发包内容
    u2->FillBuff(u.GetBuff()+u.GetLen(), u.GetMaxLen()-u.GetLen());
    u2->endPluto();
    pmb->PushPluto(u2);

    return 0;
}

//来自跨服的回调
int CWorldCrossclient::OnCrossClientResp(CPluto& u)
{
    //printf("CWorldCrossclient::onCrossClientResp\n");

    CHECK_AND_GET_RPC_FIELD(u, sid, uint16_t);

    CMailBox* mb = GetServerMailbox(sid);
    //printf("CWorldCrossclient::onCrossClientResp 222, sid=%d;mb=%x\n", sid, mb);
    if(mb)
    {
        //发回给发起调用的那个entity
        CPluto* u2 = new CPluto;
        u2->Encode(MSGID_BASEAPP_ENTITY_RPC) << sid;
        u2->FillBuff(u.GetBuff()+u.GetLen(), u.GetMaxLen()-u.GetLen());
        u2->endPluto();

        mb->PushPluto(u2);
    }

    return 0;
}

//来自跨服的广播
int CWorldCrossclient::OnCrossClientBroadcast(CPluto& u)
{
    //printf("CWorldCrossclient::OnCrossClientBroadcast \n");

    if(m_nBcBaseappId == 0)
    {
        //挑一个baseapp来处理,挑完之后不会再变了
        vector<CMailBox*>& mbs = GetServer()->GetAllServerMbs();
        vector<CMailBox*>::iterator iter1 = mbs.begin();
        for(; iter1 != mbs.end(); ++iter1)
        {
            CMailBox* mb2 = *iter1;
            if(mb2 && mb2->GetServerMbType() == SERVER_BASEAPP)
            {
                m_nBcBaseappId = mb2->GetMailboxId();
                break;
            }
        }
    }

    CMailBox* mb = GetServerMailbox(m_nBcBaseappId);
    if(mb)
    {
        CPluto* u2 = new CPluto(u.GetBuff(), u.GetMaxLen());
        u2->ReplaceField<uint16_t>(6, MSGID_BASEAPP_CROSSCLIENT_BROADCAST);
        mb->PushPluto(u2);
    }

    return 0;
}

}
