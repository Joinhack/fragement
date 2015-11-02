#include "world_dbmgr.h"
#include "pluto.h"

#ifndef _WIN32
#include "db_task.h"
#endif


namespace mogo
{

    CWorldDbmgr::CWorldDbmgr() : m_baseBalance()
    {

    }

    CWorldDbmgr::~CWorldDbmgr()
    {
        ClearMap(m_avatars4LookupByAccount);

        {
            map<string, map<TDBID, SEntityLookup*>*>::iterator iter = m_entities4LookupByDbid.begin();
            for(; iter != m_entities4LookupByDbid.end(); ++iter)
            {
                ClearMap(*(iter->second));
            }
            ClearMap(m_entities4LookupByDbid);
        }

        {
            map<string, map<string, SEntityLookup*>*>::iterator iter = m_entities4LookupByName.begin();
            for(; iter != m_entities4LookupByName.end(); ++iter)
            {
                ClearMap(*(iter->second));
            }
            ClearMap(m_entities4LookupByName);
        }
    }

    int CWorldDbmgr::init(const char* pszEtcFile)
    {
        LogDebug("CWorldDbmgr::init()", "a=%d", 1);

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
            LogDebug("CWorldDbmgr::init().error", "%s", e.GetMsg().c_str());
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

    int CWorldDbmgr::FromRpcCall(CPluto& u, CDbOper& db)
    {
        //printf("CWorldDbmgr::from_rpc_call\n");
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
            case MSGID_DBMGR_INSERT_ENTITY:
            {
                nRet = InsertDB(p, db);
                break;
            }
            case MSGID_DBMGR_SELECT_ENTITY:
            {
                nRet = LookupEntityByDbId(p, db);
                break;
            }
            case MSGID_DBMGR_UPDATE_ENTITY:
            {
                nRet = UpdateEntity(p, db);
                break;
            }
            case MSGID_DBMGR_UPDATE_ENTITY_REDIS:
            {
                nRet = UpdateEntityToRedis(p, db);
                break;
            }
            case MSGID_DBMGR_SELECT_ACCOUNT:
            {
                nRet = SelectAccount(p, db);
                break;
            }
            case MSGID_DBMGR_RAW_MODIFY_NORESP:
            {
                nRet = QueryModifyNoResp(p, db);
                break;
            }
            case MSGID_DBMGR_CREATEBASE_FROM_NAME:
            {
                nRet = LookupEntityByName(p, db);
                break;
            }
            case MSGID_DBMGR_LOAD_ALL_AVATAR:
            {
                nRet = LoadAllAvatars(p, db);
                break;
            }
            case MSGID_DBMGR_LOAD_ENTITIES_OF_TYPE:
            {
                nRet = LoadEntitiesOfType(p, db);
                break;
            }
            case MSGID_DBMGR_SHUTDOWN_SERVER:
            {
                nRet = ShutdownServer(p);
                break;
            }
            case MSGID_DBMGR_REDIS_HASH_LOAD:
            {
                nRet = RedisHashLoad(p, db);
                break;
            }
            case MSGID_DBMGR_REDIS_HASH_SET:
            {
                nRet = RedisHashSet(p, db);
                break;
            }
            case MSGID_DBMGR_REDIS_HASH_DEL:
            {
                nRet = RedisHashDel(p, db);
                break;
            }
            case MSGID_DBMGR_DEL_ACCOUNT_CACHE:
            {
                nRet = DestroyAccountCache(p);
                break;
            }

            case MSGID_DBMGR_UPDATE_ITEMS:
            {
                nRet = UpdateArrayItemsToDb(p, db);
                break;
            }
            case MSGID_DBMGR_LOADING_ITEMS:
            {
                nRet = LoadingArrayItemsToInventory(p, db);
                break;
            }
            case MSGID_DBMGR_INCREMENTAL_UPDATE_ITEMS:
            {
                nRet = IncremantalUpdateItems(p, db);
                break;
            }

            case MSGID_DBMGR_TABLE_SELECT:
            {
                nRet = TableSelect(p, db);
                break;
            }
            case MSGID_DBMGR_UPDATE_BATCH:
            {
                nRet = TableUpdateBatch(p, db);
                break;
            }
            case MSGID_DBMGR_TABLE_INSERT:
            {
                nRet = TableInsert(p, db);
                break;
            }
            case MSGID_DBMGR_TABLE_EXCUTE:
            {
                nRet = TableExcute(p, db);
                break;
            }
            case MSGID_DBMGR_TABLE2_SELECT:
            {
                nRet = Table2Select(p, db);
                break;
            }
            case MSGID_DBMGR_TABLE2_INSERT:
            {
                nRet = Table2Insert(p, db);
                break;
            }
            case MSGID_DBMGR_TABLE2_EXCUTE:
            {
                nRet = Table2Excute(p, db);
                break;
            }
            default:
            {
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

    int CWorldDbmgr::InsertDB(T_VECTOR_OBJECT* p, CDbOper& db)
    {
        if(p->size() != 3)
        {
            return -1;
        }

        CEntityMailbox& emb = VOBJECT_GET_EMB((*p)[0]);
        int32_t ref = VOBJECT_GET_I32((*p)[1]);
        SEntityPropFromPluto* p2 = (SEntityPropFromPluto*)((*p)[2]->vv.p);

        const string& strEntityName = GetDefParser().GetTypeName(p2->etype);

        //string strSql;
        //db.make_insert_sql(strEntityName, p2->data, strSql);
        //cout << strSql << endl;

        //string strSql2;
        //db.make_create_sql(strEntityName, strSql2);
        //cout << strSql2 << endl;

        //LogWarning("insert to db", "emb ref strEntityName = %s", strEntityName.c_str());

        string strErr;
        TDBID newid = db.InsertEntity(strEntityName, p2->data, strErr);
        if(newid == 0)
        {
            LogWarning("InsertDB_err", "newid=0;err=%s", strErr.c_str());
            //cout << strErr << endl;
            //return -2;
        }

        //通知db结果
        CEpollServer* s = this->GetServer();
        CMailBox* mb = s->GetServerMailbox(emb.m_nServerMailboxId);
        if(mb)
        {
#ifdef _WIN32
            mb->RpcCall(GetRpcUtil(), MSGID_BASEAPP_INSERT_ENTITY_CALLBACK, emb, newid, ref, strErr.c_str());
#else
            CRpcUtil& rpc = GetRpcUtil();
            CPluto* u = new CPluto;
            rpc.Encode(*u, MSGID_BASEAPP_INSERT_ENTITY_CALLBACK, emb, newid, ref, strErr.c_str());
            u->SetMailbox(mb);

            LogDebug("CDbOper::InsertDB", "u.GenLen()=%d", u->GetLen());

            g_pluto_sendlist.PushPluto(u);
#endif
        }

        return 0;
    }



    int CWorldDbmgr::UpdateEntity(T_VECTOR_OBJECT* p, CDbOper& db)
    {
        if(p->size() != 3)
        {
            return -1;
        }

        CEntityMailbox& emb = VOBJECT_GET_EMB((*p)[0]);
        TDBID dbid = VOBJECT_GET_U64((*p)[1]);
        SEntityPropFromPluto* p2 = (SEntityPropFromPluto*)((*p)[2]->vv.p);

        const string& strEntityName = GetDefParser().GetTypeName(p2->etype);

        //string strSql;
        //db.make_update_sql(strEntityName, p2->data, dbid, strSql);

        //string strSql2;
        //db.make_create_sql(strEntityName, strSql2);
        //cout << strSql2 << endl;

        string strErr;
        int nRet = db.UpdateEntity(strEntityName, p2->data, dbid, strErr);
        if(nRet != 0)
        {
            if(nRet == -4)
            {
                LogWarning("UpdateEntity_err", "entity no change");
                return 0;
            }
            else
            {
                LogWarning("UpdateEntity_err", "%s", strErr.c_str());
            }

            //cout << strErr << endl;
            return -2;
        }

        //    //通知db结果
        //    CEpollServer* s = this->GetServer();
        //    CMailBox* mb = s->GetServerMailbox(emb.m_nServerMailboxId);
        //    if(mb)
        //    {
        //#ifdef _WIN32
        //        mb->RpcCall(GetRpcUtil(), MSGID_BASEAPP_INSERT_ENTITY_CALLBACK, emb, newid, ref);
        //#else
        //        CRpcUtil& rpc = GetRpcUtil();
        //        CPluto* u = new CPluto;
        //        rpc.Encode(*u, MSGID_BASEAPP_INSERT_ENTITY_CALLBACK, emb, newid, ref);
        //        u->SetMailbox(mb);
        //        g_pluto_sendlist.PushPluto(u);
        //#endif
        //    }

        return 0;
    }

    int CWorldDbmgr::UpdateEntityToRedis(T_VECTOR_OBJECT* p, CDbOper& db)
    {
        if(p->size() != 3)
        {
            return -1;
        }

        CEntityMailbox& emb = VOBJECT_GET_EMB((*p)[0]);
        TDBID dbid = VOBJECT_GET_U64((*p)[1]);
        SEntityPropFromPluto* p2 = (SEntityPropFromPluto*)((*p)[2]->vv.p);

        const string& strEntityName = GetDefParser().GetTypeName(p2->etype);

        string strErr;
        db.UpdateEntityToRedis(strEntityName, p2->data, dbid, strErr);

        return 0;
    }

    //根据dbid查找entity
    int CWorldDbmgr::LookupEntityByDbId(T_VECTOR_OBJECT* p, CDbOper& db)
    {
        if(p->size() != 4)
        {
            return -1;
        }

        uint8_t nServerId = VOBJECT_GET_U8((*p)[0]);
        const char* szEntityName = VOBJECT_GET_STR((*p)[1]);
        TDBID dbid = VOBJECT_GET_U64((*p)[2]);
        int32_t ref = VOBJECT_GET_I32((*p)[3]);

        CPluto* u = new CPluto;
        string strErr;
        if(db.LookupEntityByDbId(szEntityName, dbid, ref, *u, strErr) != 0)
        {
            delete u;
            //cout << strErr << endl;
            LogWarning("LookupEntityByDbId_err", "%s", strErr.c_str());
            return -2;
        }

        //通知db结果
        CEpollServer* s = this->GetServer();
        CMailBox* mb = s->GetServerMailbox(nServerId);
        if(mb)
        {
#ifdef _WIN32
            mb->RpcCall(*u);
#else
            u->SetMailbox(mb);

            LogDebug("CWorldDbmgr::LookupEntityByDbId", "u.GenLen()=%d", u->GetLen());

            g_pluto_sendlist.PushPluto(u);
#endif
        }
        else
        {
            LogWarning("CWorldDbmgr::LookupEntityByDbId", "u.GenLen()=%d", u->GetLen());
            delete u;
        }

        return 0;
    }

    int CWorldDbmgr::LookupEntityByName(T_VECTOR_OBJECT* p, CDbOper& db)
    {
        if(p->size() != 4)
        {
            return -1;
        }

        uint16_t nBaseappId = VOBJECT_GET_U16((*p)[0]);
        uint8_t nCreateFlag = VOBJECT_GET_U8((*p)[1]);
        const char* pszEntityName = VOBJECT_GET_STR((*p)[2]);
        const char* pszKey = VOBJECT_GET_STR((*p)[3]);

        const string& strKey(pszKey);
        //先查找该key相关的entity是否已经创建出来了
        SEntityLookup* pLookup = LookupEntityInfo(strKey, pszEntityName);
        if(pLookup != NULL)
        {
            //LogInfo("CWorldDbmgr::LookEntityByName", "entity exists;key=%s;eid=%d;baseapp=%d", \
            //        pszKey, pLookup->eid, pLookup->sid);

            CMailBox* mb = GetServerMailbox(pLookup->sid);
            if(mb)
            {
                CPluto* u = new CPluto;
                u->Encode(MSGID_BASEAPP_ENTITY_MULTILOGIN);
                (*u) << pLookup->eid << EndPluto;
                u->SetMailbox(mb);

                //LogDebug("CWorldDbmgr::LookupEntityByName", "u.GenLen()=%d", u->GetLen());

                g_pluto_sendlist.PushPluto(u);
            }

            return 0;
        }

        TENTITYID new_eid = MyGetNextEntityId();
        CPluto* u = new CPluto;
        string strErr;
        if(db.LookupEntityByName(nCreateFlag, pszEntityName, strKey, new_eid, *u, nBaseappId, strErr) != 0)
        {
            delete u;
            //cout << strErr << endl;
            LogWarning("LookEntityByName_err", "%s", strErr.c_str());
            return -2;
        }

        //add for lookup
        CreateNewEntityToLookup(strKey, pszEntityName, new_eid, nBaseappId);

        //通知db结果
        CEpollServer* s = this->GetServer();
        CMailBox* mb = s->GetServerMailbox(nBaseappId);
        if(mb)
        {
#ifdef _WIN32
            mb->RpcCall(*u);
#else
            u->SetMailbox(mb);

            LogDebug("CWorldDbmgr::LookupEntityByName", "u.GenLen()=%d", u->GetLen());

            g_pluto_sendlist.PushPluto(u);
#endif
        }
        else
        {
            LogWarning("CWorldDbmgr::LookupEntityByName", "u.GenLen()=%d", u->GetLen());
            delete u;
        }

        return 0;
    }

    int CWorldDbmgr::LoadAllAvatars(T_VECTOR_OBJECT* p, CDbOper& db)
    {
        if(p->size() != 2)
        {
            return -1;
        }

        const char* pszEntityType = VOBJECT_GET_STR((*p)[0]);
        const char* pszIndex = VOBJECT_GET_STR((*p)[1]);
        string strErr;
        int nRet = db.LoadAllAvatars(pszEntityType, pszIndex, strErr);
        if(nRet != 0)
        {
            //load数据失败,退出进程
            //todo,置全局退出标记
            LogCritical("dbmgr.LoadAllAvatar", "err=%d", nRet);
            exit(-1);
            return -1;
        }

        return 0;
    }

    int CWorldDbmgr::LoadEntitiesOfType(T_VECTOR_OBJECT* p, CDbOper& db)
    {
        if(p->size() != 2)
        {
            return -1;
        }

        const char* pszEntityType = VOBJECT_GET_STR((*p)[0]);
        uint16_t nBaseappId = VOBJECT_GET_U16((*p)[1]);
        string strErr;
        int nRet = db.LoadAllEntitiesOfType(pszEntityType, nBaseappId, strErr);
        if(nRet != 0)
        {
            //load数据失败,退出进程
            //todo,置全局退出标记
            LogCritical("dbmgr.LoadEntitiesOfType", "err=%d msg=%s pszEntityType=%s", nRet, strErr.c_str(), pszEntityType);
            exit(-1);
            return -1;
        }

        return 0;
    }

    int CWorldDbmgr::SelectAccount(T_VECTOR_OBJECT* p, CDbOper& db)
    {
#if __PLAT_PLUG_IN || __PLAT_PLUG_IN_NEW
		if(p->size() != 3)
#else
		if(p->size() != 4)
#endif
        {
            return -1;
        }

        uint16_t nServerId = VOBJECT_GET_U16((*p)[0]);
        int32_t nFd = VOBJECT_GET_I32((*p)[1]);
        const char* s1 = VOBJECT_GET_STR((*p)[2]);
#if __PLAT_PLUG_IN || __PLAT_PLUG_IN_NEW

#else
        const char* s2 = VOBJECT_GET_STR((*p)[3]);
#endif

        CPluto* u = new CPluto;
        string strErr;
#if __PLAT_PLUG_IN || __PLAT_PLUG_IN_NEW
		if(db.SelectAccount(nFd, s1, *u, strErr) != 0)
#else
        if(db.SelectAccount(nFd, s1, s2, *u, strErr) != 0)
#endif
        {
            delete u;
            //cout << strErr << endl;
            LogWarning("SelectAccount_err", "%s", strErr.c_str());
            return -2;
        }

        //通知db结果
        CEpollServer* s = this->GetServer();
        CMailBox* mb = s->GetServerMailbox(nServerId);
        if(mb)
        {
#ifdef _WIN32
            mb->RpcCall(*u);
#else
            u->SetMailbox(mb);

            LogDebug("CWorldDbmgr::SelectAccount", "u.GenLen()=%d", u->GetLen());

            g_pluto_sendlist.PushPluto(u);
#endif
        }
        else
        {
            delete u;
            LogWarning("SelectAccount_err", "no mb!");
            return -3;
        }

        return 0;
    }


    int CWorldDbmgr::QueryModifyNoResp(T_VECTOR_OBJECT* p, CDbOper& db)
    {
        if(p->size() != 1)
        {
            return -1;
        }

        const char* pszSql = VOBJECT_GET_STR((*p)[0]);
        db.QueryModifyNoResp(pszSql);

        return 0;
    }

    bool CWorldDbmgr::InitMutex()
    {
#ifdef _WIN32
        return true;
#else
        return pthread_mutex_init(&m_entityMutex, NULL) == 0 && pthread_mutex_init(&m_rpcMutex, NULL)==0;
#endif
    }

    //获取下一个entity id,本方法需要是一个同步方法
    TENTITYID CWorldDbmgr::MyGetNextEntityId()
    {
        CMutexGuard g(m_entityMutex);
        return GetNextEntityId();
    }

    //往查找结构中加入一个新的entity查找项
    void CWorldDbmgr::CreateNewEntityToLookup(TDBID dbid, const string& strEntity, TENTITYID eid, uint16_t sid)
    {
        CMutexGuard g(m_entityMutex);
        SEntityLookup* p = new SEntityLookup;
        p->eid = eid;
        p->sid = sid;

        //只有一次插入的机会,不用lower_bound来兼容查找和插入了
        map<string, map<TDBID, SEntityLookup*>*>::iterator iter = m_entities4LookupByDbid.find(strEntity);
        if(iter == m_entities4LookupByDbid.end())
        {
            map<TDBID, SEntityLookup*>* pp = new map<TDBID, SEntityLookup*>;
            pp->insert(make_pair(dbid, p));
            m_entities4LookupByDbid.insert(make_pair(strEntity, pp));
        }
        else
        {
            iter->second->insert(make_pair(dbid, p));
        }
    }

    void CWorldDbmgr::CreateNewEntityToLookup(const string& strKey, const string& strEntity, TENTITYID eid, uint16_t sid)
    {
        CMutexGuard g(m_entityMutex);
        SEntityLookup* p = new SEntityLookup;
        p->eid = eid;
        p->sid = sid;

        //只有一次插入的机会,不用lower_bound来兼容查找和插入了
        map<string, map<string, SEntityLookup*>*>::iterator iter = m_entities4LookupByName.find(strEntity);
        if(iter == m_entities4LookupByName.end())
        {
            map<string, SEntityLookup*>* pp = new map<string, SEntityLookup*>;
            pp->insert(make_pair(strKey, p));
            m_entities4LookupByName.insert(make_pair(strEntity, pp));
        }
        else
        {
            iter->second->insert(make_pair(strKey, p));
        }
    }

    //根据dbid查找entity信息
    SEntityLookup* CWorldDbmgr::LookupEntityInfo(TDBID dbid, const string& strEntity)
    {
        CMutexGuard g(m_entityMutex);

        map<string, map<TDBID, SEntityLookup*>*>::iterator iter = m_entities4LookupByDbid.find(strEntity);
        if(iter != m_entities4LookupByDbid.end())
        {
            map<TDBID, SEntityLookup*>& tmp = *(iter->second);
            map<TDBID, SEntityLookup*>::iterator iter = tmp.find(dbid);
            if(iter != tmp.end())
            {
                return iter->second;
            }
        }

        return NULL;
    }

    //根据唯一索引查找entity信息
    SEntityLookup* CWorldDbmgr::LookupEntityInfo(const string& strKey, const string& strEntity)
    {
        CMutexGuard g(m_entityMutex);

        map<string, map<string, SEntityLookup*>*>::iterator iter = m_entities4LookupByName.find(strEntity);
        if(iter != m_entities4LookupByName.end())
        {
            map<string, SEntityLookup*>& tmp = *(iter->second);
            map<string, SEntityLookup*>::iterator iter = tmp.find(strKey);
            if(iter != tmp.end())
            {
                return iter->second;
            }
        }

        return NULL;
    }

    //删除entity相关的信息
    void CWorldDbmgr::DeleteEntityInfo(TDBID dbid, const string& strEntity)
    {
        CMutexGuard g(m_entityMutex);
        map<string, map<TDBID, SEntityLookup*>*>::iterator iter = m_entities4LookupByDbid.find(strEntity);
        if(iter != m_entities4LookupByDbid.end())
        {
            //iter->second->erase(dbid);
            map<TDBID, SEntityLookup*>* p = iter->second;
            map<TDBID, SEntityLookup*>::iterator iter2 = p->find(dbid);
            if(iter2 != p->end())
            {
                delete iter2->second;
                p->erase(iter2);
            }
        }
    }

    void CWorldDbmgr::DeleteEntityInfo(const string& strKey, const string& strEntity)
    {
        CMutexGuard g(m_entityMutex);
        map<string, map<string, SEntityLookup*>*>::iterator iter = m_entities4LookupByName.find(strEntity);
        if(iter != m_entities4LookupByName.end())
        {
            //iter->second->erase(strKey);
            map<string, SEntityLookup*>* p = iter->second;
            map<string, SEntityLookup*>::iterator iter2 = p->find(strKey);
            if(iter2 != p->end())
            {
                delete iter2->second;
                p->erase(iter2);
            }
        }
    }

    //新增一个Avatar的查找项
    void CWorldDbmgr::CreateNewAvatarToLookup(const string& strAccount, TENTITYID eid, uint16_t sid)
    {
        CMutexGuard g(m_entityMutex);
        SEntityLookup* p = new SEntityLookup;
        p->eid = eid;
        p->sid = sid;
        m_avatars4LookupByAccount.insert(make_pair(strAccount, p));
    }

    //根据账户名查找一个Avatar
    SEntityLookup* CWorldDbmgr::LookupAvatarByAccount(const string& strAccount)
    {
        CMutexGuard g(m_entityMutex);
        map<string, SEntityLookup*>::iterator iter = m_avatars4LookupByAccount.find(strAccount);
        if(iter != m_avatars4LookupByAccount.end())
        {
            return iter->second;
        }
        else
        {
            return NULL;
        }
    }

    //获取下一个创建entity所在baseapp id
    uint16_t CWorldDbmgr::ChooseABaseApp()
    {
        uint16_t nServerId = m_baseBalance.GetLestWeightId();
        m_baseBalance.AddWeight(nServerId, 1);
        return nServerId;
    }

    int CWorldDbmgr::ShutdownServer(T_VECTOR_OBJECT* p)
    {
        GetServer()->Shutdown();
        g_bShutdown = true;
        return 0;
    }

    int CWorldDbmgr::RedisHashLoad(T_VECTOR_OBJECT* p, CDbOper& db)
    {
        if(p->size() != 3)
        {
            return -1;
        }

        const CEntityMailbox& emb = VOBJECT_GET_EMB((*p)[0]);
        const string& strAttri = VOBJECT_GET_SSTR((*p)[1]);
        const string& strKey = VOBJECT_GET_SSTR((*p)[2]);

        //查找该key的值
        string strValue;
        db.RedisHashLoad(strKey, strValue);

        //回调
        SyncRpcCall(g_pluto_sendlist, emb.m_nServerMailboxId, MSGID_BASEAPP_ON_REDIS_HASH_LOAD, emb, strAttri, strValue);        

        return 0;
    }

    int CWorldDbmgr::RedisHashSet(T_VECTOR_OBJECT* p, CDbOper& db)
    {
        if(p->size() != 3)
        {
            return -1;
        }

        const string& strKey = VOBJECT_GET_SSTR((*p)[0]);
        int32_t nSeq = VOBJECT_GET_I32((*p)[1]);
        const string& strValue = VOBJECT_GET_SSTR((*p)[2]);

        db.RedisHashSet(strKey, nSeq, strValue);

        return 0;
    }

    int CWorldDbmgr::RedisHashDel(T_VECTOR_OBJECT* p, CDbOper& db)
    {
        if(p->size() != 2)
        {
            return -1;
        }

        const string& strKey = VOBJECT_GET_SSTR((*p)[0]);
        int32_t nSeq = VOBJECT_GET_I32((*p)[1]);

        db.RedisHashDel(strKey, nSeq);

        return 0;
    }

    int CWorldDbmgr::DestroyAccountCache(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 2)
        {
            LogError("CWorldDbmgr::DestroyAccountCache", "p->size()=%d", p->size());
            return -1;
        }
        //const CEntityMailbox& emb = VOBJECT_GET_EMB((*p)[0]);
        const string& strKey = VOBJECT_GET_SSTR((*p)[0]);
        const string& strEntityType = VOBJECT_GET_SSTR((*p)[1]);
        //const int32_t ref = VOBJECT_GET_I32((*p)[3]);
        //先查找该key相关的entity是否已经创建出来了
        SEntityLookup* pLookup = LookupEntityInfo(strKey, strEntityType);
        if(pLookup != NULL)
        {
            //LogDebug("CWorldDbmgr::DestroyAccountCache", "entity exists;strKey=%s;eid=%d;baseapp=%d", strKey.c_str(), pLookup->eid, pLookup->sid);
            CMailBox* mb = GetServerMailbox(pLookup->sid);
            if(mb)
            {
                CPluto* u = new CPluto;
                u->Encode(MSGID_BASEAPP_DEL_ACCOUNT_CACHE_CALLBACK);
                (*u) << pLookup->eid << EndPluto;
                u->SetMailbox(mb);

                //LogDebug("CWorldDbmgr::LookupEntityByName", "u.GenLen()=%d", u->GetLen());
                DeleteEntityInfo(strKey, strEntityType);
                g_pluto_sendlist.PushPluto(u);
                return 0;
            }
        }
        LogError("CWorldDbmgr::DestroyAccountCache", "pLookup is not exists.strKey = %s, strEntityType = %s ",strKey.c_str(), strEntityType.c_str());
        return -1;

        //DeleteEntityInfo(strKey, strEntityType);
        //回调
        //RpcCall(emb.m_nServerMailboxId, MSGID_BASEAPP_DEL_ACCOUNT_CACHE_CALLBACK, emb);
        //return 0;
    }
    int CWorldDbmgr::UpdateArrayItemsToDb(T_VECTOR_OBJECT* p, CDbOper& db)
    {
        if( p->size() != 5 )
        {
            return -1;
        }
        const string & itemName = VOBJECT_GET_SSTR((*p)[0]);
        const TDBID dbid = VOBJECT_GET_U64((*p)[1]);
        const uint16_t nBaseappId = VOBJECT_GET_U16((*p)[2]);
        const int32_t ref = VOBJECT_GET_I32((*p)[3]);
        const string& itemsData = VOBJECT_GET_SSTR((*p)[4]);
        //uint32_t l = itemsData.size();

        //LogError("UpdateArrayItemsToDb", "[itemName = %s] [dbid = %d] [nBaseappId = %d] [ref = %d] [itemsData = %d]", 
        //        itemName.c_str(), dbid, nBaseappId, ref, itemsData.size());
        //cout<<itemsData.c_str()<<endl;
        //cout<<itemsData.size()<<endl;
        CPluto* u = new CPluto();
        u->FillBuff(itemsData.c_str(), itemsData.size());
        u->SetMaxLen(u->GetLen());
        string strErr;
        
        //cout<<"world update"<<endl;
        if( !db.UpdateArrayToDb(itemName, dbid, *u, nBaseappId, ref, strErr) )
        {
            LogError("UpdateArrayToDb failure", "[error = %s] [status = %d]", strErr.c_str(), -1);
            CPluto* u1 = new CPluto;
            u1->Encode(MSGID_BASEAPP_UPDATE_ITEMS_CALLBACK);
            *u1 << ref << (uint16_t)1 << strErr<< EndPluto;
            CMailBox* mb = GetServerMailbox(nBaseappId);
            if(mb)
            {
                //cout<<"send pluto"<<endl;
                u1->SetMailbox(mb);

                //LogDebug("CWorldDbmgr::UpdateArrayItemsToDb", "u1.GenLen()=%d", u1->GetLen());

                g_pluto_sendlist.PushPluto(u1);
            }
            else
            {
                delete u1;
                LogWarning("CWorldDbmgr::UpdateArrayItemsToDb", "");
            }
        }

        delete u;

        //cout<<"do success update"<<endl;
        return 0;

    }
    int CWorldDbmgr::LoadingArrayItemsToInventory(T_VECTOR_OBJECT* p, CDbOper& db)
    {
        if( p->size() != 4 )
        {
            return -1;
        }
        const string & itemName = VOBJECT_GET_SSTR((*p)[0]);
        //cout<<itemName.c_str()<<endl;
        const TDBID dbid = VOBJECT_GET_U64((*p)[1]);
        uint16_t nBaseappId = VOBJECT_GET_U16((*p)[2]);
        const int32_t ref = VOBJECT_GET_I32((*p)[3]);

        string strErr;
        if( !db.LoadingItemsToInventory(itemName, dbid, nBaseappId, ref, strErr) )
        {
            CPluto* u1 = new CPluto;
            u1->Encode(MSGID_BASEAPP_ITEMS_LOADING_CALLBACK);
            *u1 << ref <<(uint16_t)1 << itemName << strErr<< EndPluto;
            CMailBox* mb = GetServerMailbox(nBaseappId);
            if(mb)
            {
                //cout<<"send pluto"<<endl;
                u1->SetMailbox(mb);

                LogDebug("CWorldDbmgr::UpdateArrayItemsToDb", "u1.GenLen()=%d", u1->GetLen());

                g_pluto_sendlist.PushPluto(u1);
            }
            else
            {
                delete u1;
                LogWarning("CWorldDbmgr::UpdateArrayItemsToDb", "");
            }
        }
        return 0;
    }

    int CWorldDbmgr::TableSelect(T_VECTOR_OBJECT* p, CDbOper& db)
    {
        if (p->size() != 5)
        {
            LogError("CWorldDbmgr::TableSelect", "p->size()=%d", p->size());
            return -1;
        }

        uint16_t nBaseappId = VOBJECT_GET_U16((*p)[0]);
        uint32_t entityId = VOBJECT_GET_U32((*p)[1]);
        const string& strCallBackFunc = VOBJECT_GET_SSTR((*p)[2]);
        const string& strEntityType = VOBJECT_GET_SSTR((*p)[3]);
        const string& strSql = VOBJECT_GET_SSTR((*p)[4]);

        //LogDebug("CWorldDbmgr::TableSelect", "nBaseappId=%d;entityId=%d;strCallBackFunc=%s;strEntityType=%s;strSql=%s",
        //                                      nBaseappId, entityId, strCallBackFunc.c_str(), strEntityType.c_str(), strSql.c_str());

        db.TableSelect(nBaseappId, entityId, strCallBackFunc, strEntityType, strSql);

        return 0;
    }

	int CWorldDbmgr::TableUpdateBatch(T_VECTOR_OBJECT* p, CDbOper& db)
	{
		LogDebug("CWorldDbmgr::TableUpdateBatch", "");
		if( p->size() != 5 )
		{
			return -1;
		}
		const string & itemName = VOBJECT_GET_SSTR((*p)[0]);
		const string & uniqKey = VOBJECT_GET_SSTR((*p)[1]);
		const uint16_t nBaseappId = VOBJECT_GET_U16((*p)[2]);
		const int32_t ref = VOBJECT_GET_I32((*p)[3]);
		const string& itemsData = VOBJECT_GET_SSTR((*p)[4]);

		//cout<<itemsData.c_str()<<endl;
		//cout<<itemsData.size()<<endl;
		CPluto* u = new CPluto();
		u->FillBuff(itemsData.c_str(), itemsData.size());
		u->SetMaxLen(u->GetLen());
		string strErr;
		int ret = db.UpdateBatch(itemName, uniqKey, *u, nBaseappId, ref, strErr);
		//cout<<"world update"<<endl;
		if( 0 == ret)
		{
			delete u;
            return 0;
		}
		LogError("UpdateArrayToDb failure", "[error = %s] [ret = %d]", strErr.c_str(), ret);
		delete u;
		CPluto* u1 = new CPluto;
		u1->Encode(MSGID_BASEAPP_TABLE_UPDATE_BATCH_CB);
		*u1 << ref << (uint16_t)ret << EndPluto;
		CMailBox* mb = GetServerMailbox(nBaseappId);
		if(mb)
		{
			//cout<<"send pluto"<<endl;
			u1->SetMailbox(mb);

			//LogDebug("CWorldDbmgr::UpdateArrayItemsToDb", "u1.GenLen()=%d", u1->GetLen());

			g_pluto_sendlist.PushPluto(u1);
		}
        else
        {
            delete u1;
            LogWarning("CWorldDbmgr::UpdateArrayItemsToDb", "");
        }
		return -11;
	}

	int CWorldDbmgr::TableInsert(T_VECTOR_OBJECT* p, CDbOper& db)
	{
		if (p->size() != 3)
		{
			LogError("CWorldDbmgr::TableInsert", "p->size()=%d", p->size());
			return -1;
		}

		uint16_t nBaseappId = VOBJECT_GET_U16((*p)[0]);
		const string& strSql = VOBJECT_GET_SSTR((*p)[1]);
		uint32_t ref = VOBJECT_GET_U32((*p)[2]);

		//LogDebug("CWorldDbmgr::TableInsert", "nBaseappId=%d;ref=%d;strSql=%s",
		//	nBaseappId, ref,  strSql.c_str());

		string strErr;
		TDBID newId = db.TableInsert(strSql, strErr);

		if(newId == 0)
		{
			LogWarning("InsertDB_err", "newid=0;err=%s", strErr.c_str());
			//cout << strErr << endl;
			//return -2;
		}

		//通知db结果
		CEpollServer* s = this->GetServer();
		CMailBox* mb = s->GetServerMailbox(nBaseappId);
		if(mb)
		{
#ifdef _WIN32
			mb->RpcCall(GetRpcUtil(), MSGID_BASEAPP_TABLE_INSERT_CALLBACK, ref, newId );
#else
			CRpcUtil& rpc = GetRpcUtil();
			CPluto* u = new CPluto;
			rpc.Encode(*u, MSGID_BASEAPP_TABLE_INSERT_CALLBACK, ref, newId);
			u->SetMailbox(mb);

			LogDebug("CDbOper::InsertDB", "u.GenLen()=%d", u->GetLen());

			g_pluto_sendlist.PushPluto(u);
#endif
		}
		return 0;
	}

	int CWorldDbmgr::TableExcute(T_VECTOR_OBJECT* p, CDbOper& db)
	{
		if (p->size() != 3)
		{
			LogError("CWorldDbmgr::TableInsert", "p->size()=%d", p->size());
			return -1;
		}

		uint16_t nBaseappId = VOBJECT_GET_U16((*p)[0]);
		const string& strSql = VOBJECT_GET_SSTR((*p)[1]);
		uint32_t ref = VOBJECT_GET_U32((*p)[2]);

		//LogDebug("CWorldDbmgr::TableExcute", "nBaseappId=%d;ref=%d;strSql=%s",
		//	nBaseappId, ref,  strSql.c_str());

		string strErr;
		uint8_t ret = db.TableExcute(strSql, strErr);

		if(ret != 0)
		{
			LogWarning("ExcuteDB_err", "ret=%d;err=%s", ret, strErr.c_str());
		}
		//ref == 0 无返回
		if (ref == 0)
		{
			return 0;
		}
		
		//通知db结果
		CEpollServer* s = this->GetServer();
		CMailBox* mb = s->GetServerMailbox(nBaseappId);
		if(mb)
		{
#ifdef _WIN32
			mb->RpcCall(GetRpcUtil(), MSGID_BASEAPP_TABLE_EXCUTE_CALLBACK, ref, ret );
#else
			CRpcUtil& rpc = GetRpcUtil();
			CPluto* u = new CPluto;
			rpc.Encode(*u, MSGID_BASEAPP_TABLE_EXCUTE_CALLBACK, ref, ret);
			u->SetMailbox(mb);

			LogDebug("CDbOper::InsertDB", "u.GenLen()=%d", u->GetLen());

			g_pluto_sendlist.PushPluto(u);
#endif
		}
		return 0;
	}

    int CWorldDbmgr::IncremantalUpdateItems(T_VECTOR_OBJECT* p, CDbOper& db)
    {

        if ( p->size() != 5 )
        {
            LogError("CWorldDbmgr::IncremantalUpdateItems", "p->size()=%d", p->size());
            return -1;
        }

        const string & tblName = VOBJECT_GET_SSTR((*p)[0]);
        const string & optName = VOBJECT_GET_SSTR((*p)[1]);
        const uint16_t nBaseappId = VOBJECT_GET_U16((*p)[2]);
        const int32_t  ref = VOBJECT_GET_I32((*p)[3]);
        const string& itemsData = VOBJECT_GET_SSTR((*p)[4]);

        LogDebug("CWorldDbmgr::IncremantalUpdateItems", "tblName=%s;optName=%s;nBaseappId=%d;ref=%d",
            tblName.c_str(), optName.c_str(), nBaseappId, ref);

        CPluto* u = new CPluto();
        u->FillBuff(itemsData.c_str(), itemsData.size());
        u->SetMaxLen(u->GetLen());

        string strErr;
        uint8_t ret = -1;
        if ( optName.compare("update") == 0 )
        {

            ret = db.IncrementalUpdateItems(tblName, nBaseappId, *u, ref, strErr);
            if( ret != 0 )
            {
                CPluto* u1 = new CPluto;
                u1->Encode(MSGID_BASEAPP_UPDATE_ITEMS_CALLBACK);
                *u1 << ref << (uint16_t)1 << strErr<< EndPluto;
                CMailBox* mb = GetServerMailbox(nBaseappId);
                if(mb)
                {
                    u1->SetMailbox(mb);
                    //LogDebug("CWorldDbmgr::IncremantalUpdateItems", "u1.GenLen()=%d", u1->GetLen());
                    g_pluto_sendlist.PushPluto(u1);
                }
                else
                {
                    delete u1;
                    u1 = NULL;
                    LogWarning("CWorldDbmgr::IncremantalUpdateItems", "");
                }
            }
            delete u;
            u = NULL;
            return 0;
        }
        else if( optName.compare("insert") == 0 )
        {

            ret = db.IncremantalInsertItems(tblName, nBaseappId, *u, ref, strErr);
            if( ret != 0 )
            {
                CPluto* u1 = new CPluto;
                u1->Encode(MSGID_BASEAPP_INSERT_ITEMS_CALLBACK);
                *u1 << ref << (uint16_t)1 << strErr<< EndPluto;
                CMailBox* mb = GetServerMailbox(nBaseappId);
                if(mb)
                {
                    u1->SetMailbox(mb);
                    //LogDebug("CWorldDbmgr::IncremantalInsertItems", "u1.GenLen()=%d", u1->GetLen());
                    g_pluto_sendlist.PushPluto(u1);
                }
                else
                {
                    delete u1;
                    u1 = NULL;
                    LogWarning("CWorldDbmgr::IncremantalInsertItems", "");
                }
            }
            delete u;
            u = NULL;
            return 0;
        }
        
    }

    bool CWorldDbmgr::IsCanAcceptedClient(const string& strClientAddr)
    {
        return m_canAcceptedClients.find(strClientAddr) != m_canAcceptedClients.end();
    }

    int CWorldDbmgr::Table2Select(T_VECTOR_OBJECT* p, CDbOper& db)
    {
        if ( p->size() != 5 )
        {
            return -1;
        }

        uint16_t nBaseappId = VOBJECT_GET_U16((*p)[0]);
        TENTITYID eid = VOBJECT_GET_U32((*p)[1]);
        uint32_t nCbId = VOBJECT_GET_U32((*p)[2]);    
        const string& strEntity = VOBJECT_GET_SSTR((*p)[3]);
        const string& strSql = VOBJECT_GET_SSTR((*p)[4]);

        string strErr;
        int nRet = db.Table2Select(nBaseappId, eid, nCbId, strEntity, strSql, strErr);
        if(nRet != 0)
        {
            LogWarning("CWorldDbmgr::Table2Select.err", "ret=%d;err=%s", nRet, strErr.c_str());
        }

        return 0;
    }

    int CWorldDbmgr::Table2Insert(T_VECTOR_OBJECT* p, CDbOper& db)
    {
        if ( p->size() != 4 )
        {
            return -1;
        }

        uint16_t nBaseappId = VOBJECT_GET_U16((*p)[0]);
        TENTITYID eid = VOBJECT_GET_U32((*p)[1]);
        uint32_t nCbId = VOBJECT_GET_U32((*p)[2]);                      
        SEntityPropFromPluto* p2 = (SEntityPropFromPluto*)((*p)[3]->vv.p);

        const string& strEntityName = GetDefParser().GetTypeName(p2->etype);

        string strErr;
        uint64_t newid = db.InsertEntity(strEntityName, p2->data, strErr);
        if(newid == 0)
        {
            LogWarning("table_insert_err", "newid=0;err=%s", strErr.c_str());
            //cout << strErr << endl;
            //return -2;
        }

        //通知insert结果
        SyncRpcCall(g_pluto_sendlist, nBaseappId, MSGID_BASEAPP_TABLE2INSERT_RESP, eid, nCbId, newid, strErr);

        return 0;
    }

    int CWorldDbmgr::Table2Excute(T_VECTOR_OBJECT* p, CDbOper& db)
    {
        if ( p->size() != 4 )
        {
            return -1;
        }

        uint16_t nBaseappId = VOBJECT_GET_U16((*p)[0]);
        TENTITYID eid = VOBJECT_GET_U32((*p)[1]);
        uint32_t nCbId = VOBJECT_GET_U32((*p)[2]);               
        const string& strSql = VOBJECT_GET_SSTR((*p)[3]);

        string strErr;
        int8_t nRet = (int8_t)db.Table2Excute(strSql, strErr);

        SyncRpcCall(g_pluto_sendlist, nBaseappId, MSGID_BASEAPP_TABLE2EXCUTE_RESP, eid, nCbId, nRet, strErr);

        return 0;
    }
    

}

