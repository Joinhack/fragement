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

    //����def�ļ���md5
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
        //�����Ϣ���Կ������
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
//		//��ϵͳ��ǰ������,����ʧ����Ϣ
//		//todo
//		printf("CWorldCrossclient::cross_req, extern error\n");
//		return 0;
//	}
//
//	//����Ϣ����ϵͳ
//	CPluto* u2 = new CPluto;
//	u2->Encode(MSGID_CROSSSERVER_ON_CROSS_REQ);
//	u2->FillBuff(u.getBuff()+u.getLen(), u.getMaxLen()-u.getLen());
//	u2->EndPluto();
//	pmb->PushPluto(u2);
//
//	return 0;
//}


//ת���������
int CWorldCrossclient::OnCrossServerRpc(CPluto& u)
{
    //���������
    CHECK_AND_GET_RPC_FIELD(u, strService, string);

    //����Ӧ�Ŀ���������Ƿ�������
    CMailBox* pmb = ((CCrossclientServer*)GetServer())->GetExternMailbox(strService);
    if(pmb == NULL)
    {
    	//��ϵͳ��ǰ������,��¼��־;���ش�����ϢҲ����
    	LogWarning("CWorldCrossclient::OnCrossServerRpc", "extern error,%s\n", strService.c_str());
    	return 0;
    }

    CPluto* u2 = new CPluto;
    u2->Encode(MSGID_CROSSSERVER_RPC);
    //ת��������
    u2->FillBuff(u.GetBuff()+u.GetLen(), u.GetMaxLen()-u.GetLen());
    u2->endPluto();
    pmb->PushPluto(u2);

    return 0;
}

//���Կ���Ļص�
int CWorldCrossclient::OnCrossClientResp(CPluto& u)
{
    //printf("CWorldCrossclient::onCrossClientResp\n");

    CHECK_AND_GET_RPC_FIELD(u, sid, uint16_t);

    CMailBox* mb = GetServerMailbox(sid);
    //printf("CWorldCrossclient::onCrossClientResp 222, sid=%d;mb=%x\n", sid, mb);
    if(mb)
    {
        //���ظ�������õ��Ǹ�entity
        CPluto* u2 = new CPluto;
        u2->Encode(MSGID_BASEAPP_ENTITY_RPC) << sid;
        u2->FillBuff(u.GetBuff()+u.GetLen(), u.GetMaxLen()-u.GetLen());
        u2->endPluto();

        mb->PushPluto(u2);
    }

    return 0;
}

//���Կ���Ĺ㲥
int CWorldCrossclient::OnCrossClientBroadcast(CPluto& u)
{
    //printf("CWorldCrossclient::OnCrossClientBroadcast \n");

    if(m_nBcBaseappId == 0)
    {
        //��һ��baseapp������,����֮�󲻻��ٱ���
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
