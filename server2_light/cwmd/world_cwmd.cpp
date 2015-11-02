#include "world_cwmd.h"


namespace mogo
{

    CWorldMgrD::CWorldMgrD() : m_baseBalance(), m_cellBalance(), m_bShutdown(false)
    {

    }

    CWorldMgrD::~CWorldMgrD()
    {
        ClearMap(m_globalBases);
    }

    //读取日志输出路径
    string CWorldMgrD::GetLogPath(const char* pszEtcFile)
    {
        //专门读一次配置文件
        CCfgReader cfg(pszEtcFile);
        return cfg.GetValue("init", "log_path");
    }

    int CWorldMgrD::init(const char* pszEtcFile)
    {
        LogInfo("CWorldMgrD::init()", "");

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
            else if(p->GetServerMbType() == SERVER_CELLAPP)
            {
                m_cellBalance.AddNewId(p->GetMailboxId());
            }
        }

        return 0;
    }

    int CWorldMgrD::FromRpcCall(CPluto& u)
    {
        //PrintHexPluto(u);

        pluto_msgid_t msg_id = u.GetMsgId();

#ifndef __TEST_LOGIN

        if(!CheckClientRpc(u))
        {
            LogWarning("from_rpc_call", "invalid rpcall error.unknown msgid:%d\n", msg_id);
            return -1;
        }

#endif // !__TEST_LOGIN

        T_VECTOR_OBJECT* p = m_rpc.Decode(u);
        if(p == NULL)
        {
            LogWarning("from_rpc_call", "rpc Decode error.unknown msgid:%d\n", msg_id);
            return -1;
        }

        if(u.GetDecodeErrIdx() > 0)
        {
            ClearTListObject(p);
            LogWarning("from_rpc_call", "rpc Decode error.msgid:%d;pluto err idx=%d\n", msg_id, u.GetDecodeErrIdx());
            return -2;
        }

        int nRet = -1;
        switch(msg_id)
        {
            case MSGID_BASEAPPMGR_REGISTERGLOBALLY:
            {
                LogInfo("CWorldMgrD::FromRpcCall() MSGID_BASEAPPMGR_REGISTERGLOBALLY", "");
                nRet = RegisterGlobally(p);
                break;
            }
            case MSGID_BASEAPPMGR_CREATEBASE_FROM_NAME_ANYWHERE:
            {
                nRet = CreateBaseFromDbByName(p);
                break;
            }
            case MSGID_BASEAPPMGR_CREATEBASE_FROM_NAME:
            {
                nRet = CreateBaseFromDbByName(p);
                break;
            }
            case MSGID_BASEAPPMGR_CREATE_CELL_IN_NEW_SPACE:
            {
                nRet = CreateCellInNewSpace(p);
                break;
            }
            case MSGID_BASEAPPMGR_CREATEBASE_ANYWHERE:
            {
                nRet = CreateBaseAnywhere(p);
                break;
            }
            case MSGID_BASEAPPMGR_SHUTDOWN_SERVERS:
            {
                nRet = ShutdownAllServers(p, u);
                break;
            }
            case MSGID_BASEAPPMGR_ON_SERVER_SHUTDOWN:
            {
                nRet = OnServerShutdown(p);
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

    int CWorldMgrD::RegisterGlobally(T_VECTOR_OBJECT* p)
    {

        //printf("rrrr,%d\n", p->size());
        if(p->size() != 3)
        {
            return -1;
        }

        CEntityMailbox& emb = VOBJECT_GET_EMB((*p)[0]);
        const char* szName = VOBJECT_GET_STR((*p)[1]);
        int32_t ref = VOBJECT_GET_I32((*p)[2]);

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

        //如果注册成功,同步给所有的baseapp
        CEpollServer* s = this->GetServer();
        if(bRet)
        {
            vector<CMailBox*>& mbs = s->GetAllServerMbs();
            vector<CMailBox*>::iterator iter = mbs.begin();
            for(; iter != mbs.end(); ++iter)
            {
                CMailBox* basemb = *iter;
                if(basemb && basemb->GetServerMbType() == SERVER_BASEAPP)
                {
                    basemb->RpcCall(GetRpcUtil(),MSGID_BASEAPP_ADD_GLOBALBASE, szName, emb);
                }
                if (basemb && basemb->GetServerMbType() == SERVER_LOG)
                {
                    LogDebug("mogo::CWorldMgrD::RegisterGlobally", "szName=%s;", szName);
                    //通知logapp，哪一个base进程拥有哪一个globalbase
                    basemb->RpcCall(GetRpcUtil(), MSGID_OTHER_ADD_GLOBALBASE, szName, emb);
                }
            }
        }

        //通知注册结果
        CMailBox* mb = s->GetServerMailbox(emb.m_nServerMailboxId);
        if(mb)
        {
            mb->RpcCall(GetRpcUtil(), MSGID_BASEAPP_REGISTERGLOBALLY_CALLBACK, emb, (uint8_t)bRet, ref);
        }

        return 0;
    }

    int CWorldMgrD::CreateBaseFromDbByName(T_VECTOR_OBJECT* p)
    {
        if(p->size() < 3)
        {
            return -1;
        }

        uint8_t createFlag = VOBJECT_GET_U8((*p)[0]);
        const char* pszEntityType = VOBJECT_GET_STR((*p)[1]);
        const char* pszKey = VOBJECT_GET_STR((*p)[2]);

        uint16_t nBaseappId;
        if(p->size() > 3)
        {
            //指定了baseapp
            nBaseappId = VOBJECT_GET_U16((*p)[3]);
        }
        else
        {
            //未指定baseapp,选择一个
            nBaseappId = ChooseABaseApp(pszEntityType);
        }

#ifdef __TEST_LOGIN
        CEpollServer* s = this->GetServer();
        CMailBox* mb = s->GetServerMailbox(nBaseappId);

        if (mb)
        {
            TENTITYID nOtherEntityId = 0;

            CPluto* u = new CPluto;
            (*u).Encode(MSGID_BASEAPP_LOOKUP_ENTITY_CALLBACK);
            (*u) << (uint64_t)0 << this->GetNextEntityId()<< createFlag << pszKey << nOtherEntityId;
            (*u) << this->GetDefParser().GetTypeId(pszEntityType);

            TDBID dbid2 = 0;

            (*u).ReplaceField(PLUTO_FILED_BEGIN_POS, dbid2);
            (*u) << EndPluto;

            u->SetMailbox(mb);

            LogDebug("CWorldMgrD::CreateBaseFromDbByName", "u.GenLen()=%d", u.GetLen());

            mb->PushPluto(u);
        }

#else
        CMailBox* mb = GetServerMailbox(SERVER_DBMGR);
        if(mb)
        {
            mb->RpcCall(GetRpcUtil(), MSGID_DBMGR_CREATEBASE_FROM_NAME, nBaseappId, createFlag, pszEntityType, pszKey);
        }
#endif
        return 0;
    }

    int CWorldMgrD::CreateBaseAnywhere(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 2)
        {
            return -1;
        }

        const char* pszEntityType = VOBJECT_GET_STR((*p)[0]);
#ifdef __USE_MSGPACK
        charArrayDummy* d = (charArrayDummy*)VOBJECT_GET_BLOB((*p)[1]);
        uint16_t nBaseappId = ChooseABaseApp(pszEntityType);
        RpcCall(nBaseappId, MSGID_BASEAPP_CREATE_BASE_ANYWHERE, pszEntityType, *d);
#else
        const char* pszParam = VOBJECT_GET_STR((*p)[1]);
        uint16_t nBaseappId = ChooseABaseApp(pszEntityType);
        LogDebug("CWorldMgrD::CreateBaseAnywhere", "pszEntityType=%s;pszParam=%s", pszEntityType, pszParam);
        RpcCall(nBaseappId, MSGID_BASEAPP_CREATE_BASE_ANYWHERE, pszEntityType, pszParam);
#endif
        return 0;
    }

    int CWorldMgrD::CreateCellInNewSpace(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 4)
        {
            return -1;
        }

        CEntityMailbox& emb = VOBJECT_GET_EMB((*p)[0]);
        uint16_t etype = VOBJECT_GET_U16((*p)[1]);
#ifdef __USE_MSGPACK
        charArrayDummy *d = (charArrayDummy*)VOBJECT_GET_BLOB((*p)[2]);
#else
        const char* pszParams = VOBJECT_GET_STR((*p)[2]);
#endif
        charArrayDummy& props = *((charArrayDummy*)((*p)[3]->vv.p));

        uint16_t nCellappId = ChooseACellApp(etype);
        CMailBox* mb = GetServerMailbox(nCellappId);
        if(mb)
        {
#ifdef __USE_MSGPACK
            mb->RpcCall(GetRpcUtil(), MSGID_CELLAPP_CREATE_CELL_IN_NEW_SPACE, emb, etype, *d, props);
#else
            mb->RpcCall(GetRpcUtil(), MSGID_CELLAPP_CREATE_CELL_IN_NEW_SPACE, emb, etype, pszParams, props);
#endif
        }

        return 0;
    }

    //根据需要创建的entity类型权重和各个baseapp的负载选择一个合适的baseapp的mailbox id
    uint16_t CWorldMgrD::ChooseABaseApp(const char* pszEntityType)
    {
        uint16_t nServerId = m_baseBalance.GetLestWeightId();
        m_baseBalance.AddWeight(nServerId, 1);
        return nServerId;
    }

    //根据需要创建的entity类型权重和各个cellapp的负载选择一个合适的cellapp的mailbox id
    uint16_t CWorldMgrD::ChooseACellApp(const char* pszEntityType)
    {
        uint16_t nServerId = m_cellBalance.GetLestWeightId();
        m_cellBalance.AddWeight(nServerId, 1);
        return nServerId;
    }

    uint16_t CWorldMgrD::ChooseACellApp(uint16_t etype)
    {
        uint16_t nServerId = m_cellBalance.GetLestWeightId();
        m_cellBalance.AddWeight(nServerId, 1);
        return nServerId;
    }

    //停止所有服务器
    int CWorldMgrD::ShutdownAllServers(T_VECTOR_OBJECT* p, CPluto& u)
    {
        if(m_bShutdown)
        {
            return 0;
        }

        m_bShutdown = true;         //设置正在停止之中标记

        //步骤1:通知loginapp/baseapp/cellapp退出
        vector<CMailBox*>& mbs = GetServer()->GetAllServerMbs();
        vector<CMailBox*>::iterator iter = mbs.begin();
        for(; iter != mbs.end(); ++iter)
        {
            CMailBox* basemb = *iter;
            if(basemb && basemb->GetServerMbType() != SERVER_DBMGR)
            {
                LogDebug("CWorldMgrD::ShutdownAllServers", "basemb->GetServerMbType()=%d;basemb->GetServerName()=%s;basemb->GetServerPort()=%d", 
                                                            basemb->GetServerMbType(), basemb->GetServerName().c_str(), basemb->GetServerPort());
                basemb->RpcCall(GetRpcUtil(), MSGID_ALLAPP_SHUTDOWN_SERVER, (uint8_t)1);
            }
        }

        //步骤2:确认其他服务器退出之后,再通知dbmgr退出
        //在另外一个方法里实现

        CMailBox* mb = u.GetMailbox();
        if(mb != NULL)
        {
            mb->RpcCall(GetRpcUtil(), MSGID_BASEAPPMGR_SHUTDOWN_SERVERS_CALLBACK, (uint8_t)1);
        }

        return 0;
    }

    //其他服务器进程退出后的回调方法
    int CWorldMgrD::OnServerShutdown(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 1)
        {
            return -1;
        }

        //标记这个进程已经退出
        uint16_t nServerId = VOBJECT_GET_U16((*p)[0]);
        m_setShutdown.set(nServerId);

        LogDebug("CWorldMgrD::OnServerShutdown", "nServerId=%d", nServerId);

        //检查是否除dbmgr之外的进程都已经退出
        bool bQuitAll = true;
        vector<CMailBox*>& mbs = GetServer()->GetAllServerMbs();
        vector<CMailBox*>::iterator iter = mbs.begin();
        for(; iter != mbs.end(); ++iter)
        {
            CMailBox* basemb = *iter;
            if(basemb && basemb->GetServerMbType() != SERVER_DBMGR)
            {
                if(!m_setShutdown.test(basemb->GetMailboxId()))
                {
                    bQuitAll = false;
                    break;
                }
            }
        }

        if(bQuitAll)
        {
            //通知dbmgr退出
            RpcCall(SERVER_DBMGR, MSGID_DBMGR_SHUTDOWN_SERVER, (uint8_t)1);

            //cwmd退出
            GetServer()->Shutdown();
        }

        return 0;
    }

    bool CWorldMgrD::IsCanAcceptedClient(const string& strClientAddr)
    {
        return m_canAcceptedClients.find(strClientAddr) != m_canAcceptedClients.end();
    }
}
