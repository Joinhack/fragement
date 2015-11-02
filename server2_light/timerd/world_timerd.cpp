#include "world_timerd.h"


namespace mogo
{

    CTimerdWorld::CTimerdWorld()
    {
    }

    CTimerdWorld::~CTimerdWorld()
    {
    }

    int CTimerdWorld::FromRpcCall(CPluto& u)
    {
        pluto_msgid_t msg_id = u.GetMsgId();
        if(!CheckClientRpc(u))
        {
            LogWarning("from_rpc_call", "invalid rpcall error.unknown msgid:%d\n", msg_id);
            return -1;
        }

        T_VECTOR_OBJECT* p = m_rpc.Decode(u);
        if(p == NULL)
        {
            LogWarning("from_rpc_call", "rpc decode error.unknown msgid:%d\n", msg_id);
            return -1;
        }
        if(u.GetDecodeErrIdx() > 0)
        {
            ClearTListObject(p);
            LogWarning("from_rpc_call", "rpc decode error.msgid:%d;pluto err idx=%d\n", msg_id, u.GetDecodeErrIdx());
            return -2;
        }

        int nRet = -1;
        switch(msg_id)
        {
            case MSGID_ALLAPP_SHUTDOWN_SERVER:
            {
                nRet = ShutdownServer(p);
                break;
            }
            default:
            {
                LogWarning("from_rpc_call", "unknown msgid:%d\n", msg_id);
            }
        }

        if(nRet != 0)
        {
            LogWarning("from_rpc_call", "rpc error.msg_id=%d;ret=%d\n", msg_id, nRet);
        }

        ClearTListObject(p);

        return 0;
    }

    bool CTimerdWorld::IsCanAcceptedClient(const string& strClientAddr)
    {
        return m_canAcceptedClients.find(strClientAddr) != m_canAcceptedClients.end();
    }


}
