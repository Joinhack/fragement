/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：world_base
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.5
// 模块描述：base服务器游戏世界逻辑相关
//----------------------------------------------------------------*/

#include <stdlib.h>

#ifndef _WIN32
#include <sys/time.h>
#include <openssl/md5.h>
#include <openssl/rc4.h>
#include <mysql.h>
#endif
#include "world_base.h"
#include "lua_base.h"
#include "type_mogo.h"
#include "lua_bitset.h"


extern CEntityBase* CreateEntityFromDbData(lua_State* L, TDBID dbid, SEntityPropFromPluto* pProps);
extern int CreateBaseWithData(lua_State* L, map<string, VOBJECT*>& new_data);
extern int CreateEntityInBase(lua_State* L);

namespace mogo
{


    CWorldBase::CWorldBase() : world()
    {

    }

    CWorldBase::~CWorldBase()
    {
        ClearMap(m_clientLoginKeys);

#ifdef __RELOGIN
        ClearMap(m_clientReLoginKeys);
#endif
    }

    void CWorldBase::Clear()
    {

    }



    int CWorldBase::init(const char* pszEtcFile)
    {
        LogInfo("CWorldBase::init()", "");

        int nWorldInit = world::init(pszEtcFile);
        if(nWorldInit != 0)
        {
            return nWorldInit;
        }

        try
        {
            //m_defParser.init(m_cfg->GetValue("init", "def_path").c_str());
            //测试这两个字段是否配置
            m_cfg->GetValue("init", "lua_path");
            m_cfg->GetValue("init", "rpt_path");
        }
        catch(const CException& e)
        {
            LogError("world::init().error", "%s", e.GetMsg().c_str());
            return -1;
        }


        m_L = luaL_newstate();

        if(m_L==NULL)
        {
            return -1;
        }

        luaL_openlibs(m_L);   //装载lua标准库


        this->OpenMogoLib(m_L);   //装载mogo库
        g_lua_bitset.Init(m_L);
        ClearLuaStack(m_L);

        //lua脚本的顶层路径名
        string strLuaPath = m_cfg->GetValue("init", "lua_path");
        lua_pushstring(m_L, strLuaPath.c_str());
        lua_setglobal(m_L, "G_LUA_ROOTPATH");

        //战报输出路径
        string strRptPath = m_cfg->GetValue("init", "rpt_path");
        lua_pushstring(m_L, strRptPath.c_str());
        lua_setglobal(m_L, "G_RPT_PATH");

        //读取初始化文件
        char szTmp[512];
        snprintf(szTmp, sizeof(szTmp), "package.path=package.path..';%s/base/?.lua;%s/base/?.luac'\0",
                 strLuaPath.c_str(), strLuaPath.c_str());
        if(luaL_dostring(m_L, szTmp) != 0)
        {
            return -2;
        }

        //读取base目录下的init.lua方法
        if(luaL_dostring(m_L, "require 'init'") != 0)
        {
            LogError("world::init()", "dostring error:%s", lua_tostring(m_L, -1));
            return -3;
        }

        //load所有的lua文件,由init.lua来负责完成

        //call lua init function
        int nRet = OnScriptReady();
        if(nRet != 0)
        {
            return nRet;
        }

        ClearLuaStack(m_L);

        //int nGcRet = lua_gc(m_L, LUA_GCCOLLECT, 0);
        //LogInfo("lua_gc", "ret=%d", nGcRet);

        return 0;
    }


    int CWorldBase::OpenMogoLib(lua_State* L)
    {
        return LuaOpenMogoLibCBase(L);
    }

    bool CWorldBase::AddEntity(CEntityBase* p)
    {
        return m_enMgr.AddEntity(p);
    }

    bool CWorldBase::DelEntity(CEntityBase* p)
    {
        //删除一个对象时，在事件管理器里注册的管理器也删掉
        pstEventDispatcher->DeleteEntity(p->GetId());

#ifdef __RELOGIN
        //删除一个对象，把重登陆的key也删掉
        this->ClearClientReLoginKeys(p->GetId());
#endif

        return m_enMgr.DelEntity(p);
    }

    //int CWorldBase::iter_entities(lua_State* L)
    //{
    //    typedef map<TENTITYID, CEntityBase*>::const_iterator itertype;
    //    const map<TENTITYID, CEntityBase*>& ens = m_enMgr.entities();
    //    itertype* piter = (itertype*)lua_touserdata(L, lua_upvalueindex(1));
    //    itertype iter = *piter;
    //
    //    if(iter != ens.end())
    //    {
    //        lua_pushinteger(L, iter->first);
    //        ++iter;
    //        return 1;
    //    }
    //
    //    return 0;
    //}

    CEntityParent* CWorldBase::GetEntity(TENTITYID id)
    {
        return (CEntityParent*)m_enMgr.GetEntity(id);
    }

#ifdef _WIN32
    void CWorldBase::_MakeKey(const string& strAccount, string& key, time_t& t2)
    {
        //根据 帐户名/时间/随机数 生成一个md5码作为key
        //todo,这里先做一个临时的
        time_t t = time(NULL);
        struct tm* tm1 = localtime(&t);
        char szKey[64];
        memset(szKey, 0, sizeof(szKey));
        snprintf(szKey, sizeof(szKey), "%s_%04d-%02d-%02d %02d:%02d:%02d", strAccount.c_str(), tm1->tm_year+1900, tm1->tm_mon+1, \
                 tm1->tm_mday, tm1->tm_hour, tm1->tm_min, tm1->tm_sec);
        key.assign(szKey);
        t2 = t;
    }
#else

    int __enc(char* buff, int len, char* buff2, int* len2)
    {
        enum { SIZE16 = 16,};
        char passwd[SIZE16]="cellayykeyenc";

        RC4_KEY key;
        RC4_set_key(&key, SIZE16, (unsigned char*)passwd);

        RC4(&key, len, (unsigned char*)buff, (unsigned char*)buff2);
        *len2 = len;

        return 0;
    }

    void CWorldBase::_MakeKey(const string& strAccount, string& key, time_t& t2)
    {
        //根据帐号名/时间/随机数生成一个原始字符串
        time_t t = time(NULL);
        struct tm* tm1 = localtime(&t);
        char szKey[64];
        memset(szKey, 0, sizeof(szKey));
        int nRam = (int)random() && 0xffff;
        snprintf(szKey, sizeof(szKey), "%s%d%d%d%d%d%d%d", strAccount.c_str(), tm1->tm_year+1900, tm1->tm_mon+1, \
                 tm1->tm_mday, tm1->tm_hour, tm1->tm_min, tm1->tm_sec, nRam);

        //printf("key1:%s\n", szKey);

        //加密字符串
        char szOut[1024];
        int nOut = 0;
        __enc(szKey, strlen(szKey), szOut, &nOut);

        //md5
        enum { SIZE16 = 16,};
        unsigned char szMd5[SIZE16];
        MD5((unsigned char*)szOut, nOut, szMd5);

        memset(szKey, 0, sizeof(szKey));
        for(int i=0; i<SIZE16; ++i)
        {
            //printf("%0X", szMd5[i]);
            //    sprintf(szKey+2*i, "%0X", szMd5[i]);
            char_to_sz(szMd5[i], szKey+2*i);
        }
        //printf("\n");
        //printf("key2:%s\n", szKey);
        key.assign(szKey);
        t2 = t;
    }
#endif

    const string& CWorldBase::MakeClientLoginKey(const string& strAccount, TENTITYID eid)
    {
        _SClientLoginKey* p = new _SClientLoginKey;
        this->_MakeKey(strAccount, p->m_key, p->m_time);
        p->m_eid = eid;
        m_clientLoginKeys.insert(make_pair(p->m_key, p));
        return p->m_key;
    }

#ifdef __RELOGIN
    const string& CWorldBase::MakeClientReLoginKey(const string& strAccount, TENTITYID eid)
    {
		//strAccount传入的其实是空字符串,把eid转为eid来做
		char szTmp[32];
		memset(szTmp, 0, sizeof(szTmp));
		snprintf(szTmp, sizeof(szTmp), "%d", eid);

        _SClientReLoginKey* p = new _SClientReLoginKey;
        this->_MakeKey(szTmp, p->m_key, p->m_time);
        p->m_eid = eid;
        p->m_offtime = 0;

		map<string, _SClientReLoginKey*>::iterator iter = m_clientReLoginKeys.lower_bound(p->m_key);
		if(iter != m_clientReLoginKeys.end() && iter->first == p->m_key)
		{
			//有重复的key
			delete iter->second;
			iter->second = p;
		}
		else
		{
			m_clientReLoginKeys.insert(iter, make_pair(p->m_key, p));
		}

        return p->m_key;
    }

    _SClientReLoginKey* CWorldBase::GetClientReLoginKey(const string& key)
    {
        map<string, _SClientReLoginKey*>::const_iterator iter = m_clientReLoginKeys.find(key);
        if(iter == m_clientReLoginKeys.end())
        {
            return NULL;
        }
        else
        {
            return iter->second;
        }
    }


#endif

    int CWorldBase::FromRpcCall(CPluto& u)
    {
        pluto_msgid_t msg_id = u.GetMsgId();
        if(!CheckClientRpc(u))
        {
            LogWarning("from_rpc_call", "invalid rpcall error.unknown msgid:%d\n", msg_id);
            return -1;
        }

        if(msg_id == MSGID_BASEAPP_CLIENT_MOVE_REQ)
        {
            //转发给cell的客户端移动方法
            return OnClientMoveReq(u);
        }
        else if(msg_id == MSGID_BASEAPP_CLIENT_RPC2CELL_VIA_BASE)
        {
            //通过base转发的到cell的rpc调用
            return FromClientRpc2CellViaBase(u);
        }

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
            case MSGID_ALLAPP_ONTICK:
            {
                nRet = OnTimerdTick(p);
                break;
            }
            case MSGID_BASEAPP_REGISTERGLOBALLY_CALLBACK:
            {
                nRet = RegisterGloballyCallback(p);
                break;
            }
            case MSGID_BASEAPP_ADD_GLOBALBASE:
            {
                nRet = AddGlobalBase(p);
                break;
            }
            case MSGID_BASEAPP_INSERT_ENTITY_CALLBACK:
            {
                nRet = InsertEntityCallback(p);
                break;
            }
            case MSGID_BASEAPP_SELECT_ENTITY_CALLBACK:
            {
                nRet = SelectEntityCallback(p);
                break;
            }
            case MSGID_BASEAPP_LOOKUP_ENTITY_CALLBACK:
            {
                nRet = LookupEntityCallback(p);
                break;
            }
            case MSGID_BASEAPP_ENTITY_MULTILOGIN:
            {
                nRet = EntityMultilogin(p);
                break;
            }
            case MSGID_BASEAPP_LOAD_ALL_AVATAR:
            {
                nRet = LoadAllAvatar(p);
                break;
            }
            case MSGID_BASEAPP_LOAD_ENTITIES_OF_TYPE:
            {
                nRet = LoadEntitiesOfType(p);
                break;
            }
            case MSGID_BASEAPP_LOAD_ENTITIES_END_MSG:
            {
                nRet = LoadEntitiesEnd(p);
                break;
            }
            case MSGID_BASEAPP_ENTITY_RPC:
            {
                nRet = FromLuaRpcCall(p);
                break;
            }
            case MSGID_BASEAPP_CLIENT_RPCALL:
            {
                nRet = FromClientRpcCall(p);
                break;
            }
            case MSGID_BASEAPP_CLIENT_LOGIN:
            {
                int fd = u.GetMailbox()->GetFd();
                AddClientFdToVObjectList(fd, p);
                nRet = ClientLogin(p);
                if(nRet != 0)
                {
                    GetServer()->CloseFdFromServer(fd);
                }
                break;
            }
#ifndef _WIN32
            case MSGID_BASEAPP_CLIENT_RELOGIN:
            {
                int fd = u.GetMailbox()->GetFd();
                AddClientFdToVObjectList(fd, p);
                nRet = ClientReLogin(p);
                if(nRet != 0)
                {
                    GetServer()->AddToNeedToDisconnectFd(fd);
                }
                break;
            }
#endif
            case MSGID_BASEAPP_LUA_DEBUG:
            {
                nRet = DebugLuaCode(p);
                break;
            }
            case MSGID_BASEAPP_ON_GET_CELL:
            {
                nRet = OnGetCell(p);
                //LogInfo("base_ongetcell", "%d", nRet);
                break;
            }
            case MSGID_BASEAPP_CREATE_CELL_VIA_MYCELL:
            {
                nRet = CreateCellViaMyCell(p);
                break;
            }
            case MSGID_BASEAPP_CREATE_CELL_FAILED:
            {
                nRet = OnCreateCellFailed(p);
                break;
            }
            case MSGID_BASEAPP_ENTITY_ATTRI_SYNC:
            {
                nRet = OnEntityAttriSync(p);
                break;
            }
            case MSGID_BASEAPP_ON_LOSE_CELL:
            {
                nRet = OnLoseCell(p);
                break;
            }
            case MSGID_BASEAPP_CREATE_BASE_ANYWHERE:
            {
                nRet = CreateBaseFromCWMD(p);
                break;
            }
            case MSGID_BASEAPP_SET_BASE_DATA:
            {
                nRet = SetBaseData(p);
                break;
            }
            case MSGID_BASEAPP_DEL_BASE_DATA:
            {
                nRet = DelBaseData(p);
                break;
            }
            case MSGID_ALLAPP_SHUTDOWN_SERVER:
            {
                nRet = ShutdownServer(p);
                break;
            }
            case MSGID_BASEAPP_CLIENT_RPC_VIA_BASE:
            {
                nRet = ClientRpcViaBase(p);
                break;
            }
            case MSGID_BASEAPP_CLIENT_MSG_VIA_BASE:
            {
                nRet = ClientMsgViaBase(p);
                break;
            }
            case MSGID_BASEAPP_ON_REDIS_HASH_LOAD:
            {
                nRet = OnRedisHashLoad(p);
                break;
            }
            case MSGID_BASEAPP_TIME_SAVE:
            {
                nRet = TimeSave(p);
                break;
            }
            case MSGID_BASEAPP_AVATAR_POS_SYNC:
            {
                nRet = OnAvatarPosSync(p);
                break;
            }
            case MSGID_BASEAPP_DEL_ACCOUNT_CACHE_CALLBACK:
            {
                nRet = NotifyDbDestroyAccountCacheCallBack(p);
                break;
            }

            case MSGID_BASEAPP_ITEMS_LOADING_CALLBACK:
            {
                nRet = LoadingAvatarItemsCallback(p);
                break;
            }
            case MSGID_BASEAPP_UPDATE_ITEMS_CALLBACK:
            {
                nRet = UpdateItemsCallback(p);
                break;
            }
            case MSGID_BASEAPP_INSERT_ITEMS_CALLBACK:
            {
                nRet = IncrementalInsertCallback(p);
                break;
            }

            case MSGID_BASEAPP_TABLE_SELECT_CALLBACK:
            {
                nRet = TableSelectCallback(u);
                break;
            }
            case MSGID_BASEAPP_BROADCAST_CLIENT_PRC:
            {
                nRet = BroadClientRpc(p);
                break;
            }
            case MSGID_BASEAPP_TABLE_UPDATE_BATCH_CB:
            {
                nRet = TableUpdateCallback(p);
                break;
            }
            case MSGID_BASEAPP_TABLE_INSERT_CALLBACK:
            {
                nRet = TableInsertCallback(p);
                break;
            }
            case MSGID_BASEAPP_TABLE_EXCUTE_CALLBACK:
            {
                nRet = TableExcuteCallback(p);
                break;
            }
            case MSGID_BASEAPP_TABLE2EXCUTE_RESP:
            {
                nRet = Table2ExcuteResp(p);
                break;
            }
            case MSGID_BASEAPP_TABLE2SELECT_RESP:
            {
                nRet = Table2SelectResp(u);
                break;
            }
            case MSGID_BASEAPP_TABLE2INSERT_RESP:
            {
                nRet = Table2InsertResp(p);
                break;
            }
            case MSGID_BASEAPP_CROSSCLIENT_BROADCAST:
            {
                nRet = OnCrossClientBroadcast(p);
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

    int CWorldBase::RegisterGloballyCallback(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 3)
        {
            return -1;
        }

        CEntityMailbox& emb = VOBJECT_GET_EMB((*p)[0]);
        uint8_t nRegRet = VOBJECT_GET_U8((*p)[1]);
        int ref = (int)VOBJECT_GET_I32((*p)[2]);

        CLuaCallback& cb = GetCallback();
        int n = cb.GetObj(m_L, ref);
        lua_pushinteger(m_L, nRegRet);
        int nRet = lua_pcall(m_L, 1, 0, 0);
        if (nRet != 0)
        {
            if (nRet == LUA_ERRRUN)
            {
                LogDebug("EntityMethodCall", "call 0error:%s", \
                         lua_tostring(m_L, -1));
            }
        }

        cb.Unref(m_L, ref);
        ClearLuaStack(m_L);

        return 0;
    }

    int CWorldBase::AddGlobalBase(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 2)
        {
            return -1;
        }

        const char* szName = VOBJECT_GET_STR((*p)[0]);
        CEntityMailbox& emb = VOBJECT_GET_EMB((*p)[1]);


        //LogInfo("CWorldBase::AddGlobalBase", "name=%s;server_id=%d;entity_id=%d", \
        //        szName, emb.m_nServerMailboxId, emb.m_nEntityId);

        //先用table,以后再改为userdata;table的话可以在lua里修改id,sid等几个值
        NewBaseMailbox(m_L, emb.m_nServerMailboxId, emb.m_nEntityType, emb.m_nEntityId);

        lua_getglobal(m_L, g_szGlobalBases);
        lua_pushstring(m_L, szName);
        lua_pushvalue(m_L, -3);
        lua_rawset(m_L, -3);



        ClearLuaStack(m_L);

        return 0;
    }

    int CWorldBase::InsertEntityCallback(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 4)
        {
            return -1;
        }

        ClearLuaStack(m_L);

        CEntityMailbox& emb = VOBJECT_GET_EMB((*p)[0]);
        TDBID newid = VOBJECT_GET_U64((*p)[1]);
        int ref = (int)VOBJECT_GET_I32((*p)[2]);
        const char* pszDbErr = VOBJECT_GET_STR((*p)[3]);

        LogDebug("CWorldBase::InsertEntityCallback", "eid=%d;newid=%d;ref=%d;pszDbErr=%s",
                                                      emb.m_nEntityId, newid, ref, pszDbErr);

        CEntityParent* pEntity = GetEntity(emb.m_nEntityId);
        if(pEntity)
        {
            pEntity->SetDbid(newid);
        }

        CLuaCallback& cb = GetCallback();
        int n = cb.GetObj(m_L, ref);

        //根据指针获得lua userdata
        luaL_getmetatable(m_L, g_szUserDataEntity);
        lua_pushlightuserdata(m_L, pEntity);
        lua_rawget(m_L, -2);
        lua_remove(m_L, -2);

        lua_pushinteger(m_L, (lua_Integer)newid);
        lua_pushstring(m_L, pszDbErr);
        int nRet = lua_pcall(m_L, 3, 0, 0);
        if (nRet != 0)
        {
            if (nRet == LUA_ERRRUN)
            {
                LogDebug("InsertEntityCallback", "call error:%s", \
                         lua_tostring(m_L, -1));
            }
        }

        cb.Unref(m_L, ref);
        ClearLuaStack(m_L);

        return 0;
    }

    int CWorldBase::SelectEntityCallback(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 3)
        {
            return -1;
        }

        TDBID dbid = VOBJECT_GET_U64((*p)[0]);
        int32_t ref = VOBJECT_GET_I32((*p)[1]);
        SEntityPropFromPluto* p2 = (SEntityPropFromPluto*)((*p)[2]->vv.p);

        ClearLuaStack(m_L);
        //printf("top:%d\n", lua_gettop(m_L));

        //需要传入entity的类型名
        const char* pszEntityType = GetDefParser().GetTypeName(p2->etype).c_str();

        LogInfo("SelectEntityCallback", "entity type=%d;type2=%s;dbid=%lld",p2->etype, pszEntityType, dbid);

        lua_pushstring(m_L, pszEntityType);
        CEntityBase* pEntity = CreateEntityFromDbData(m_L, dbid, p2);

        ClearLuaStack(m_L);

        CLuaCallback& cb = GetCallback();
        int n = cb.GetObj(m_L, ref);

        //根据指针获得lua userdata
        luaL_getmetatable(m_L, g_szUserDataEntity);
        lua_pushlightuserdata(m_L, pEntity);
        lua_rawget(m_L, -2);
        lua_remove(m_L, -2);

        int nRet = lua_pcall(m_L, 1, 0, 0);
        if (nRet != 0)
        {
            if (nRet == LUA_ERRRUN)
            {
                LogDebug("SelectEntityCallback", "call error:%s", \
                         lua_tostring(m_L, -1));
            }
        }

        cb.Unref(m_L, ref);
        ClearLuaStack(m_L);

        return 0;
    }

    int CWorldBase::LookupEntityCallback(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 6)
        {
            return -1;
        }

        TDBID dbid = VOBJECT_GET_U64((*p)[0]);
        uint32_t eid = VOBJECT_GET_U32((*p)[1]);
        uint8_t nCreateFlag = VOBJECT_GET_U8((*p)[2]);
        const char* pszKey = VOBJECT_GET_STR((*p)[3]);
        uint32_t avatar_id = VOBJECT_GET_U32((*p)[4]);
        SEntityPropFromPluto* p2 = (SEntityPropFromPluto*)((*p)[5]->vv.p);

        //TENTITYTYPE eType = p2->etype;
        //map<string, VOBJECT*> &pMap = p2->data;
        //uint32_t nums = pMap.size();


        //map<string, VOBJECT*>::iterator iter;
        //for( iter = pMap.begin(); iter != pMap.end(); iter++ )
        //{
        //    //LogDebug("CWorldBase::LookupEntityCallback", "name=%s", (iter->first).c_str());

        //    VOBJECT *vtp = iter->second;
        //    //LogDebug("CWorldBase::LookupEntityCallback", "type=%d", vtp->vt);
        //    //printf("[type][%d] ",vtp->vt);

        //    if( vtp->vt == V_STR )
        //    {
        //        //LogDebug("CWorldBase::LookupEntityCallback", "value=%s", vtp->vv);
        //        //printf("[value][%s]\n", vtp->vv);
        //    }
        //    else if( vtp->vt >= 3 && vtp->vt <= 11)
        //    {
        //        //LogDebug("CWorldBase::LookupEntityCallback", "value=%d", vtp->vv);
        //        //pintf("[value][%d]\n", vtp->vv);
        //    }
        //}



        //数据库中没有记录
        bool bCreateNew = false;
        if(dbid == 0)
        {
            if(nCreateFlag == 0)
            {
                //没有设置创建标记 TODO
                LogWarning("LookupEntityCallback", "not_set_create_flag");
                return -2;
            }
            else
            {
                //设置了创建标记
                bCreateNew = true;
            }
        }

        ClearLuaStack(m_L);
        //printf("top:%d\n", lua_gettop(m_L));

        //需要传入entity的类型名
        CDefParser& defparser = GetDefParser();
        const char* pszEntityType = defparser.GetTypeName(p2->etype).c_str();

        LogInfo("SelectEntityCallback", "entity type=%d;type2=%s;dbid=%lld",p2->etype, pszEntityType, dbid);
        lua_pushstring(m_L, pszEntityType);
        lua_pushinteger(m_L, eid);

        if(bCreateNew)
        {
            map<string, VOBJECT*> new_data;
            {
                VOBJECT* v = new VOBJECT;
                v->vt = V_STR;
                v->vv.s = new string;
                v->vv.s->assign(pszKey);
                new_data.insert(make_pair(defparser.GetEntityDefByType(p2->etype)->m_strUniqueIndex, v));
            }
            CreateBaseWithData(m_L, new_data);
            ClearMap(new_data);
        }
        else
        {
            //特殊写的代码
            if(avatar_id > 0)
            {
                VOBJECT* v = new VOBJECT;
                v->vt = V_UINT32;
                v->vv.u32 = avatar_id;
                p2->data.insert(make_pair("avatar_id", v));
            }

            //从数据库获得了数据
            CEntityBase* pEntity = CreateEntityFromDbData(m_L, dbid, p2);
        }

        return 0;
    }

    //虽然这个方法的名字是LoadAllAvatar,其实是指发起操作的目的是load all
    //每一个pluto包里其实只包含了一个avatar的数据
    int CWorldBase::LoadAllAvatar(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 3)
        {
            return -1;
        }

        TDBID dbid = VOBJECT_GET_U64((*p)[0]);
        uint32_t eid = VOBJECT_GET_U32((*p)[1]);
        SEntityPropFromPluto* p2 = (SEntityPropFromPluto*)((*p)[2]->vv.p);

        ClearLuaStack(m_L);

        //需要传入entity的类型名
        CDefParser& defparser = GetDefParser();
        const char* pszEntityType = defparser.GetTypeName(p2->etype).c_str();

        lua_pushstring(m_L, pszEntityType);
        lua_pushinteger(m_L, eid);

        //从数据库获得了数据
        CEntityBase* pEntity = CreateEntityFromDbData(m_L, dbid, p2);

        return 0;
    }

    int CWorldBase::LoadEntitiesOfType(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 3)
        {
            return -1;
        }

        TDBID dbid = VOBJECT_GET_U64((*p)[0]);
        uint32_t eid = VOBJECT_GET_U32((*p)[1]);
        SEntityPropFromPluto* p2 = (SEntityPropFromPluto*)((*p)[2]->vv.p);

        ClearLuaStack(m_L);

        //需要传入entity的类型名
        CDefParser& defparser = GetDefParser();
        const char* pszEntityType = defparser.GetTypeName(p2->etype).c_str();

        lua_pushstring(m_L, pszEntityType);
        lua_pushinteger(m_L, eid);

        //从数据库获得了数据
        CEntityBase* pEntity = CreateEntityFromDbData(m_L, dbid, p2);

        return 0;
    }

    int CWorldBase::LoadEntitiesEnd(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 2)
        {
            return -1;
        }

        const string& strEntity = VOBJECT_GET_SSTR((*p)[0]);
        uint32_t count = VOBJECT_GET_U32((*p)[1]);

        ClearLuaStack(m_L);
        lua_pushinteger(m_L, count);
        const static char szCallback[] = "onEntitiesLoaded";
        ScriptMethodCall(m_L, strEntity.c_str(), szCallback, 1, 0);

        return 0;
    }

    int CWorldBase::EntityMultilogin(T_VECTOR_OBJECT* p)
    {
        uint32_t eid = VOBJECT_GET_U32((*p)[0]);
        CEntityBase* pBase = (CEntityBase*)GetEntity(eid);
        if(pBase == NULL)
        {
            return -1;
        }

        ClearLuaStack(m_L);
        EntityMethodCall(m_L, pBase, "onMultiLogin", 0, 0);
        ClearLuaStack(m_L);

        return 0;
    }

    int CWorldBase::ClientLogin(T_VECTOR_OBJECT* p)
    {
        const char* pszKey = VOBJECT_GET_STR((*p)[0]);
        int32_t fd = VOBJECT_GET_I32((*p)[1]);

        map<string, _SClientLoginKey*>::iterator iter = m_clientLoginKeys.find(pszKey);
        if(iter == m_clientLoginKeys.end())
        {
            LogWarning("CWorldBase::ClientLogin", "error login key,fd=%d", fd);
            return -1;
        }

        _SClientLoginKey* pl = iter->second;
        TENTITYID eid = pl->m_eid;
        time_t tOld = pl->m_time;

        //验证通过之后删除
        delete pl;
        m_clientLoginKeys.erase(iter);        

        //检查时间有无过期
        time_t tNow = time(NULL);
        //enum { loginkey_timeout = 60, };    //key有效时间60秒
        enum { loginkey_timeout = 600, };    //key有效时间60秒
        //LogDebug("baseapp_loginkey", "t1=%d;t2=%d;dt=%d", tOld, tNow, tNow-tOld);
        if(tNow - tOld > loginkey_timeout)
        {
            LogWarning("CWorldBase::ClientLogin", "loginkey_expired;fd=%d;eid=%d", fd, eid);
            return -3;
        }

        CEntityBase* pBase = (CEntityBase*)GetEntity(eid);
        if(pBase == NULL)
        {
            LogWarning("CWorldBase::ClientLogin", "entity not exsits or expired;fd=%d;eid=%d", fd, eid);
            return -2;
        }

        //加入map
        m_fd2Entity.insert(make_pair(fd, pBase->GetId()));

        CMailBox* mb = GetServer()->GetClientMailbox(fd);
        if(mb)
        {
            //验证通过
            mb->SetAuthz(MAILBOX_CLIENT_AUTHZ);
        }

        pBase->GiveClient(m_L, fd);
        ClearLuaStack(m_L);

        //通知登录服务器增加人数
        CMailBox* mb2 = this->GetServerMailbox(SERVER_LOGINAPP);
        if(mb2)
        {
            mb2->RpcCall(this->GetRpcUtil(), MSGID_LOGINAPP_MODIFY_ONLINE_COUNT, (uint8_t)0, (uint8_t)1);
        }

        return 0;
    }

#ifdef __RELOGIN
    int CWorldBase::ClientReLogin(T_VECTOR_OBJECT* p)
    {
        const char* pszKey = VOBJECT_GET_STR((*p)[0]);
        int32_t fd = VOBJECT_GET_I32((*p)[1]);

        map<string, _SClientReLoginKey*>::iterator iter = m_clientReLoginKeys.find(pszKey);
        if(iter == m_clientReLoginKeys.end())
        {

            CPluto* u2 = new CPluto;
            u2->Encode(MSGID_CLIENT_RELOGIN_KEY_NOT_EXIT) << EndPluto;
            CMailBox* mb = GetServer()->GetClientMailbox(fd);
            mb->PushPluto(u2);

            LogWarning("CWorldBase::ClientReLogin", "error login key,fd=%d", fd);
            return -1;
        }

        _SClientReLoginKey* pl = iter->second;
        TENTITYID eid = pl->m_eid;
        time_t tOld = pl->m_time;
        time_t tOfflinetime = pl->m_offtime;

        //验证通过之后删除
        m_clientReLoginKeys.erase(iter);
        delete pl;

        //检查时间有无过期
        time_t tNow = time(NULL);
        enum { reloginkey_timeout = 600, };    //key有效时间60秒
        //LogDebug("baseapp_loginkey", "t1=%d;t2=%d;dt=%d", tOld, tNow, tNow-tOld);
        if(tOfflinetime != 0 && tNow - tOfflinetime > reloginkey_timeout)
        {

            CPluto* u2 = new CPluto;
            u2->Encode(MSGID_CLIENT_RELOGIN_KEY_NOT_EXIT) << EndPluto;
            CMailBox* mb = GetServer()->GetClientMailbox(fd);
            mb->PushPluto(u2);

            LogWarning("CWorldBase::ClientReLogin", "loginkey_expired;fd=%d;eid=%d;tOfflinetime=%d;tNow=%d", 
                                                     fd, eid, tOfflinetime, tNow);
            return -3;
        }

        CEntityBase* pBase = (CEntityBase*)GetEntity(eid);
        if(pBase == NULL)
        {
            CPluto* u2 = new CPluto;
            u2->Encode(MSGID_CLIENT_RELOGIN_KEY_NOT_EXIT) << EndPluto;
            CMailBox* mb = GetServer()->GetClientMailbox(fd);
            mb->PushPluto(u2);

            LogWarning("CWorldBase::ClientReLogin", "entity not exsits or expired;fd=%d;eid=%d", fd, eid);
            return -2;
        }

        //加入map
        m_fd2Entity.insert(make_pair(fd, pBase->GetId()));

        CMailBox* mb = GetServer()->GetClientMailbox(fd);
        if(mb)
        {
            //验证通过
            mb->SetAuthz(MAILBOX_CLIENT_AUTHZ);
        }

        pBase->GiveClient(m_L, fd);
        ClearLuaStack(m_L);

        //通知登录服务器增加人数
        CMailBox* mb2 = this->GetServerMailbox(SERVER_LOGINAPP);
        if(mb2)
        {
            mb2->RpcCall(this->GetRpcUtil(), MSGID_LOGINAPP_MODIFY_ONLINE_COUNT, (uint8_t)0, (uint8_t)1);
        }

        return 0;
    }
#endif

    int CWorldBase::OnGetCell(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 1)
        {
            return -1;
        }

        CEntityMailbox& emb = VOBJECT_GET_EMB((*p)[0]);
        CEntityBase* pBase = (CEntityBase*)GetEntity(emb.m_nEntityId);
        if(pBase == NULL)
        {
            return -1;
        }

        //记录cell的mailbox
        NewCellMailbox(m_L, emb.m_nServerMailboxId, emb.m_nEntityType, emb.m_nEntityId);
        {
            CLuaCallback& cb = GetLuaTables();
            int nRef = cb.Ref(m_L);
            pBase->AddCellMailbox(nRef, emb.m_nServerMailboxId);
        }

        //call script
        EntityMethodCall(m_L, pBase, "onGetCell", 0, 0);
        ClearLuaStack(m_L);

        //如果有client,通知cell打包client字段
        pBase->NotifyCellSyncClientAttris();

        return 0;
    }

    int CWorldBase::OnLoseCell(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 2)
        {
            return -1;
        }

        TENTITYID eid = VOBJECT_GET_U32((*p)[0]);
        charArrayDummy& props = *((charArrayDummy*)((*p)[1]->vv.p));

        CEntityBase* pBase = (CEntityBase*)GetEntity(eid);
        if (pBase)
        {
            pBase->RemoveCellMailbox();

            //call script
            ClearLuaStack(m_L);

            CPluto u(props.m_s, props.m_l);
            u.SetLen(0);    //指向0

            //LogDebug("CWorldBase::OnLoseCell", "eid=%d;props.m_l=%d", eid, props.m_l);

            pBase->UnpickleCellDataFromPluto(u);



            EntityMethodCall(m_L, pBase, "onLoseCell", 0, 0);
            ClearLuaStack(m_L);
        }

        return 0;
    }

    void CWorldBase::UpdateClientInfo(int fd, TENTITYID eid)
    {
        map<int, TENTITYID>::iterator iter = m_fd2Entity.lower_bound(fd);
        if(iter != m_fd2Entity.end() && fd == iter->first)
        {
            iter->second = eid;
        }
        else
        {
            m_fd2Entity.insert(iter, make_pair(fd, eid));
        }
    }

    int CWorldBase::DebugLuaCode(T_VECTOR_OBJECT* p)
    {
        const char* pszLuaCode = VOBJECT_GET_STR((*p)[0]);
        LogInfo("CWorldBase::DebugLuaCode", "%s", pszLuaCode);

        //luaL_dostring(m_L, "g_stdout = io.stdout");

        if(luaL_dostring(m_L, pszLuaCode) != 0)
        {
            LogInfo("CWorldBase::DebugLuaCode", "dostring error:%s", lua_tostring(m_L, -1));
        }

        return 0;
    }

    //客户端断开连接处理
    int CWorldBase::OnFdClosed(int fd)
    {
        map<int, TENTITYID>::iterator iter = m_fd2Entity.find(fd);
        if(iter == m_fd2Entity.end())
        {
            LogWarning("CWorldBase::OnFdClosed no fd", "fd=%d", fd);

            //通知登录服务器减人数
            CMailBox* mb = this->GetServerMailbox(SERVER_LOGINAPP);
            if(mb)
            {
                mb->RpcCall(this->GetRpcUtil(), MSGID_LOGINAPP_MODIFY_ONLINE_COUNT, (uint8_t)1, (uint8_t)1);
            }

            return -1;
        }

        TENTITYID eid = iter->second;
        m_fd2Entity.erase(iter);

        CEntityBase* pBase = (CEntityBase*)GetEntity(eid);
        if(pBase == NULL)
        {
            LogWarning("CWorldBase::OnFdClosed no entity", "fd=%d;eid=%d", fd, eid);

            //通知登录服务器减人数
            CMailBox* mb = this->GetServerMailbox(SERVER_LOGINAPP);
            if(mb)
            {
                mb->RpcCall(this->GetRpcUtil(), MSGID_LOGINAPP_MODIFY_ONLINE_COUNT, (uint8_t)1, (uint8_t)1);
            }

            return -2;
        }

        //删除client mailbox
        pBase->RemoveClient();

        ClearLuaStack(m_L);
        EntityMethodCall(m_L, pBase, "onClientDeath", 0, 0);
        ClearLuaStack(m_L);

#ifdef __RELOGIN
        //断开连接时记录时间
        LogDebug("CWorldBase::OnFdClosed", "fd=%d;m_id=%d", fd, pBase->GetId());
        _SClientReLoginKey *p = GetClientReLoginKey(pBase->GetClientReLoginKey());
        if(p)
        {
            p->m_offtime = time(NULL);
        }
#endif

        //通知登录服务器减人数
        CMailBox* mb = this->GetServerMailbox(SERVER_LOGINAPP);
        if(mb)
        {
            mb->RpcCall(this->GetRpcUtil(), MSGID_LOGINAPP_MODIFY_ONLINE_COUNT, (uint8_t)1, (uint8_t)1);
        }

        return 0;
    }

    //获取一个fd上关联的entity
    CEntityBase* CWorldBase::GetEntityByFd(int fd)
    {
        map<int, TENTITYID>::iterator iter = m_fd2Entity.find(fd);
        if(iter != m_fd2Entity.end())
        {
            return (CEntityBase*)GetEntity(iter->second);
        }

        return NULL;
    }

    //顶掉一个连接
    void CWorldBase::KickOffFd(int fd)
    {
        m_fd2Entity.erase(fd);
        GetServer()->KickOffFd(fd);
    }

    int CWorldBase::FromLuaRpcCall(T_VECTOR_OBJECT* p)
    {
        if(p->size() < 2)
        {
            return -1;
        }

        VOBJECT* pemb = (*p)[0];
        if(pemb->vt != V_ENTITYMB)
        {
            return -2;
        }

        CEntityMailbox& emb = pemb->vv.emb;
        CEntityParent* pe = GetEntity(emb.m_nEntityId);
        if(pe == NULL)
        {
            return -3;
        }

        int32_t nFuncId = (int32_t)VOBJECT_GET_U16((*p)[1]);
        const string& strFuncName = GetDefParser().GetMethodNameById(emb.m_nEntityType, nFuncId);

        for(int i=2; i<(int)p->size(); ++i)
        {
            VOBJECT* _v = (*p)[i];
            PushVObjectToLua(m_L, *_v);
        }

//#ifdef __TEST
//
//        time1.SetNowTime();
//#endif

        int n = EntityMethodCall(m_L, pe, strFuncName.c_str(), (uint8_t)(p->size()-2), 0);
        lua_pop(m_L, n);

//#ifdef __TEST
//
//        int cost = time1.GetLapsedTime();
//
//        LogInfo("CWorldBase::FromLuaRpcCall Cost", "strFuncName=%s;cost=%d", strFuncName.c_str(), cost);
//#endif

        return 0;
    }

    int CWorldBase::FromClientRpcCall(T_VECTOR_OBJECT* p)
    {
        if(p->size() < 2)
        {
            return -1;
        }

        VOBJECT* p0 = (*p)[0];
        if(p0->vt != V_ENTITY_POINTER)
        {
            return -2;
        }
        CEntityBase* pBase = (CEntityBase*)p0->vv.p;
        const char* pszFuncName = VOBJECT_GET_STR((*p)[1]);
        for(int i=2; i<(int)p->size(); ++i)
        {
            VOBJECT* _v = (*p)[i];
            PushVObjectToLua(m_L, *_v);
        }

//#ifdef __TEST
//
//        time1.SetNowTime();
//#endif

        int n = EntityMethodCall(m_L, pBase, pszFuncName, (uint8_t)(p->size()-2), 0);
        lua_pop(m_L, n);

//#ifdef __TEST
//
//        int cost = time1.GetLapsedTime();
//
//        LogInfo("CWorldBase::FromClientRpcCall Cost", "pszFuncName=%s;cost=%d", pszFuncName, cost);
//#endif

        return 0;
    }

    int CWorldBase::FromClientRpc2CellViaBase(CPluto& u)
    {
        CMailBox* mb = u.GetMailbox();
        if(mb == NULL)
        {
            return -1;
        }
        int fd = mb->GetFd();
        CEntityBase* pBase = GetEntityByFd(fd);
        if(pBase == NULL)
        {
            return -2;
        }
        const SEntityDef* pDef = GetDefParser().GetEntityDefByType(pBase->GetEntityType());
        if(pDef == NULL)
        {
            return -3;
        }

        u.Decode();
        uint16_t nFuncId = 0;
        u >> nFuncId;
        if(u.GetDecodeErrIdx() > 0)
        {
            return -4;
        }

        const string& strFunc = pDef->m_cellMethodsMap.GetStrByInt(nFuncId);
        map<string, _SEntityDefMethods*>::const_iterator iter11 = pDef->m_cellMethods.find(strFunc);
        if(iter11 != pDef->m_cellMethods.end())
        {
            _SEntityDefMethods* pMethods = iter11->second;
            if(pMethods->m_bExposed)
            {
                int nCellSvrId = pBase->GetCellServerId();
                if(nCellSvrId > 0)
                {
                    CMailBox* cmb = GetServerMailbox(nCellSvrId);
                    if(cmb)
                    {
                        CPluto* u2 = new CPluto;
                        u2->Encode(MSGID_CELLAPP_ENTITY_RPC) << pBase->GetMyMailbox() << nFuncId;
                        u2->FillBuff(u.GetBuff()+u.GetLen(), u.GetMaxLen()-u.GetLen()) << EndPluto;
                        cmb->PushPluto(u2);

                        return 0;
                    }
                }
            }
            //else 该方法不能由客户端调用
        }

        return -5;
    }

    int CWorldBase::CreateCellViaMyCell(T_VECTOR_OBJECT* p)
    {
        if(p->size() < 6)
        {
            return -1;
        }

        TENTITYID myid = VOBJECT_GET_U32((*p)[0]);
        CEntityMailbox& emb = VOBJECT_GET_EMB((*p)[1]);
        int16_t x = VOBJECT_GET_I16((*p)[2]);
        int16_t y = VOBJECT_GET_I16((*p)[3]);
        const char* szMask = VOBJECT_GET_STR((*p)[4]);
        charArrayDummy& props = *((charArrayDummy*)((*p)[5]->vv.p));

        //获取自己的cell mb
        CEntityBase* pBase = (CEntityBase*)GetEntity(myid);
        if(pBase)
        {
            int nCellSvrId = pBase->GetCellServerId();
            if(nCellSvrId > 0)
            {
                CMailBox* mb = GetServerMailbox(nCellSvrId);
                if(mb)
                {
                    mb->RpcCall(GetRpcUtil(), MSGID_CELLAPP_CREATE_CELL_VIA_MYCELL, myid, emb, x, y, szMask, props);
                    return 0;
                }
            }
        }

        //如果不能rpc,记录警告日志
        LogWarning("CWorldBase::CreateCellViaMycell", "cant find base.cell;id=%d", myid);

        return 0;
    }

    int CWorldBase::OnCreateCellFailed(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 2)
        {
            return -1;
        }

        TENTITYID eid = (TENTITYID)VOBJECT_GET_U32((*p)[0]);
        uint8_t err_id = VOBJECT_GET_U8((*p)[1]);

        CEntityBase* pBase = (CEntityBase*)GetEntity(eid);
        if(pBase != NULL)
        {
            pBase->SetCellState(E_HASNT_CELL);

            //call script
            lua_pushinteger(m_L, err_id);
            EntityMethodCall(m_L, pBase, "onCreateCellFailed", 1, 0);
            ClearLuaStack(m_L);
        }

        return 0;
    }

    int CWorldBase::OnEntityAttriSync(T_VECTOR_OBJECT* p)
    {
        if(p->size() < 3)
        {
            return -1;
        }

        TENTITYID eid = VOBJECT_GET_U32((*p)[0]);
        CEntityParent* pe = GetEntity(eid);
        if(pe)
        {
            const string& strPropName = VOBJECT_GET_SSTR((*p)[1]);
            bool bUpate;
            VOBJECT* v = pe->UpdateAProp(strPropName, (*p)[2], bUpate);
            if(bUpate)
            {
                (*p)[2] = v;
                if(p->size() > 3)
                {
                    uint16_t nPropId = VOBJECT_GET_U16((*p)[3]);
                    pe->SyncClientProp(nPropId, *v);
                }
            }
        }

        return 0;
    }

    //createBaseAnywhere在目标baseapp的操作
    int CWorldBase::CreateBaseFromCWMD(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 2 )
        {
            return -1;
        }

        ClearLuaStack(m_L);

        const char* pszEntity = VOBJECT_GET_STR((*p)[0]);
        lua_pushstring(m_L, pszEntity);

#ifdef __USE_MSGPACK
        charArrayDummy *d = (charArrayDummy *)VOBJECT_GET_BLOB((*p)[1]);
        if (d)
        {
            LuaUnpickleFromBlob(m_L, d->m_s, d->m_l);
        }
#else
        const string& strParam = VOBJECT_GET_SSTR((*p)[1]);

        if(!strParam.empty())
        {
            LuaUnpickleFromString(m_L, strParam);
        }

#endif

        CreateEntityInBase(m_L);    //创建的entity在栈顶,不要了
        ClearLuaStack(m_L);


        return 0;
    }


    ////获取一个账号关联的fd
    //int CWorldBase::GetAccountSocketFd(const string& strAccount)
    //{
    //    map<string, int>::const_iterator iter = m_accounts2fd.find(strAccount);
    //    if(iter == m_accounts2fd.end())
    //    {
    //        return -1;
    //    }
    //    else
    //    {
    //        return iter->second;
    //    }
    //}

    int CWorldBase::SetBaseData(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 3 )
        {
            return -1;
        }

        const char* pszKey = VOBJECT_GET_STR((*p)[0]);
        uint8_t nValueType = VOBJECT_GET_U8((*p)[1]);

#ifdef __USE_MSGPACK
        charArrayDummy* d = (charArrayDummy*)VOBJECT_GET_BLOB((*p)[2]);
#else
        const string& strValue = VOBJECT_GET_SSTR((*p)[2]);
#endif

        lua_getglobal(m_L, s_szMogoLibName);
        lua_pushstring(m_L, "baseData");
        lua_rawget(m_L, -2);

        lua_pushstring(m_L, pszKey);

        if(nValueType == V_UINT8)
        {
#ifdef __USE_MSGPACK
            lua_pushlstring(m_L, d->m_s, d->m_l);
#else
            lua_pushstring(m_L, strValue.c_str());
#endif
            lua_Number _num = lua_tonumber(m_L, -1);
            lua_pushnumber(m_L, _num);
            lua_replace(m_L, -2);

        }
        else if(nValueType == V_STR)
        {
#ifdef __USE_MSGPACK
            lua_pushlstring(m_L, d->m_s, d->m_l);
#else
            lua_pushstring(m_L, strValue.c_str());
#endif
        }
        else if(nValueType == V_LUATABLE)
        {
#ifdef __USE_MSGPACK
            LuaUnpickleFromBlob(m_L, d->m_s, d->m_l);
#else
            LuaUnpickleFromString(m_L, strValue);
#endif
        }

        //复制一份key/value用来做cw.baseData的rawset,原始的一份用来回调脚本
        lua_pushvalue(m_L, -2);
        lua_pushvalue(m_L, -2);
        lua_rawset(m_L, -5);

#ifdef __USE_MSGPACK
        LogInfo("SetBaseData", "key=%s;d->m_s=%s;d->m_l=%d;type=%d", pszKey, d->m_s, d->m_l, nValueType);
#else
        LogInfo("SetBaseData", "key=%s;value=%s;type=%d", pszKey, strValue.c_str(), nValueType);
#endif

        //回调init脚本的onBaseData方法
        ScriptMethodCall(m_L, "global_data", "onBaseData", 2, 0);

        ClearLuaStack(m_L);

        return 0;
    }

    int CWorldBase::DelBaseData(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 1 )
        {
            return -1;
        }

        const char* pszKey = VOBJECT_GET_STR((*p)[0]);

        lua_getglobal(m_L, s_szMogoLibName);
        lua_pushstring(m_L, "baseData");
        lua_rawget(m_L, -2);

        lua_pushstring(m_L, pszKey);
        lua_pushnil(m_L);

        //复制一份key/value用来做cw.baseData的rawset,原始的一份用来回调脚本
        lua_pushvalue(m_L, -2);
        lua_pushvalue(m_L, -2);
        lua_rawset(m_L, -5);

        LogInfo("DelBaseData", "key=%s", pszKey);

        //回调init脚本的onBaseData方法
        ScriptMethodCall(m_L, "global_data", "onBaseData", 2, 0);

        ClearLuaStack(m_L);

        return 0;
    }

    //重载基类的停止服务器方法
    int CWorldBase::ShutdownServer(T_VECTOR_OBJECT* p)
    {
        LogInfo("CWorldBase::ShutdownServer", "");

        //所有entity存盘
        map<TENTITYID, CEntityBase*>& entities = m_enMgr.Entities();
        while(!entities.empty())
        {
            map<TENTITYID, CEntityBase*>::iterator iter = entities.begin();
            CEntityBase* pBase = iter->second;
            if(pBase->GetDbid() > 0)
            {
                //printf("ShutdownServer,etype=%d;dbid=%d\n", pBase->GetEntityType(), pBase->GetDBID());
                pBase->lWriteToDB(m_L);
            }

            EntityMethodCall(m_L, pBase, "onDestroy", 0, 0);

            //从lua的entity集合中删除
            luaL_getmetatable(m_L, g_szUserDataEntity);
            lua_pushlightuserdata(m_L, pBase);
            lua_pushnil(m_L);
            lua_rawset(m_L, -3);
            ClearLuaStack(m_L);

#ifdef _DEBUG_FINAL_GC
			pBase->ClearAllData();
			this->DelEntity(pBase);
#else			
			entities.erase(iter);
#endif            
        }

        //只标记退出,先不发消息给cwmd
        //world::ShutdownServer(p);
        //设置服务器退出标记
        GetServer()->Shutdown();

        return 0;
    }

    int CWorldBase::ClientRpcViaBase(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 3 )
        {
            return -1;
        }

        TENTITYID eid = VOBJECT_GET_U32((*p)[0]);
        uint16_t nFuncId = VOBJECT_GET_U16((*p)[1]);
        charArrayDummy* ad = (charArrayDummy*)((*p)[2]->vv.p);

        CEntityBase* pBase = (CEntityBase*)GetEntity(eid);
        if(pBase)
        {
            CMailBox* mb = GetServer()->GetClientMailbox(pBase->GetClientFd());
            if(mb)
            {
                pluto_msgid_t msg_id = MSGID_CLIENT_RPC_RESP;
                CPluto* u = new CPluto;
                (*u).Encode(msg_id) << nFuncId;
                (*u).FillBuff(ad->m_s, ad->m_l) << EndPluto;

                mb->PushPluto(u);
            }
        }

        return 0;
    }

    int CWorldBase::ClientMsgViaBase(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 3 )
        {
            return -1;
        }

        uint32_t eid = VOBJECT_GET_U32((*p)[0]);
        uint16_t nMsgId = VOBJECT_GET_U16((*p)[1]);
        charArrayDummy* ad = (charArrayDummy*)((*p)[2]->vv.p);

        CEntityBase* pBase = (CEntityBase*)GetEntity(eid);
        if(pBase)
        {
            CMailBox* mb = GetServer()->GetClientMailbox(pBase->GetClientFd());
            if(mb)
            {
                CPluto* u = new CPluto;
                (*u).Encode(nMsgId);
                (*u).FillBuff(ad->m_s, ad->m_l) << EndPluto;

                mb->PushPluto(u);
            }
        }

        return 0;
    }

    int CWorldBase::OnRedisHashLoad(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 3 )
        {
            return -1;
        }

        const CEntityMailbox& emb = VOBJECT_GET_EMB((*p)[0]);
        const string& strAttri = VOBJECT_GET_SSTR((*p)[1]);
        const string& strValue = VOBJECT_GET_SSTR((*p)[2]);

        //先不用到CRedisHash那边处理load的状态了,现在只load一次

        CEntityParent* e = GetEntity(emb.m_nEntityId);
        e->OnLoadRedis(strAttri, strValue);

        lua_pushstring(m_L, strAttri.c_str());
        lua_pushstring(m_L, strValue.c_str());
        EntityMethodCall(m_L, e, "onRedisReply", 2, 0);
        ClearLuaStack(m_L);

        return 0;
    }

    //定时存盘功能
    int CWorldBase::TimeSave(T_VECTOR_OBJECT* p)
    {
#ifndef _WIN32
        bool flag = false;

        struct timeval tv1;
        if (gettimeofday(&tv1, NULL) == 0)
        {
            flag = true;
        }
        else
        {
            LogWarning("CWorldBase::TimeSave", "tv1 errno=%d;errstr=%s", errno, strerror(errno));
        }
#endif

        int nAll = (int)m_lsTimeSave.size();   //entity总数
        int nSaved = 0;                           //存盘数
        int nDiscard = 0;                      //丢弃数

        list<TENTITYID> saved;
        while(!m_lsTimeSave.empty())
        {
            TENTITYID eid = m_lsTimeSave.front();
            CEntityParent* p = GetEntity(eid);
            if(p)
            {
                if(p->WriteToRedis())
                {
                    ++nSaved;
                }
                saved.push_back(eid);

#ifndef _WIN32
                if (flag)
                {
                    struct timeval tv2;
                    if (gettimeofday(&tv2, NULL) == 0)
                    {
                        if(((tv2.tv_sec-tv1.tv_sec)*1000000+tv2.tv_usec-tv1.tv_usec) > 100000)
                        {
                            //超过0.1秒则本次存盘退出
                            break;
                        }
                    }
                    else
                    {
                        LogWarning("CWorldBase::TimeSave", "tv2 errno=%d;errstr=%s", errno, strerror(errno));
                    }
                }

#endif
            }
            else
            {
                //找不到entity,丢弃
                ++nDiscard;
            }
            m_lsTimeSave.pop_front();
        }

        float cost = 0.0;

#ifndef _WIN32
        if (flag)
        {
            struct timeval tv3;
            if (gettimeofday(&tv3, NULL) == 0)
            {
                cost = ((tv3.tv_sec-tv1.tv_sec)*1000000+tv3.tv_usec-tv1.tv_usec)/1000000.0;
            }
            else
            {
                LogWarning("CWorldBase::TimeSave", "tv3 errno=%d;errstr=%s", errno, strerror(errno));
            }
        }
#endif


        //LogInfo("CWorldBase::TimeSave", "all=%d;handle=%d;saved=%d;discard=%d;cost=%.6f", nAll, (int)saved.size(), nSaved, nDiscard, cost);


        m_lsTimeSave.splice(m_lsTimeSave.end(), saved);

        return 0;
    }

    //处理和转发客户端的移动请求
    int CWorldBase::OnClientMoveReq(CPluto& u)
    {
        CMailBox* mb = u.GetMailbox();
        if(mb == NULL)
        {
            return -1;
        }
        int fd = mb->GetFd();
        CEntityBase* p = GetEntityByFd(fd);
        if(p == NULL)
        {
            return -2;
        }

        int nCellId = p->GetCellServerId();
        if(nCellId > 0)
        {
            CMailBox* mb = GetServerMailbox(nCellId);
            if(mb)
            {
                CPluto* u2 = new CPluto;
                (*u2).Encode(MSGID_CELLAPP_CLIENT_MOVE_REQ) << p->GetId();

                u.Decode();
                int nCopyLen = (int)(u.GetMaxLen() - u.GetLen());
                if(nCopyLen > 0)
                {
                    u2->FillBuff(u.GetBuff() + u.GetLen(), nCopyLen);
                    (*u2) << EndPluto;
                    mb->PushPluto(u2);

                    return 0;
                }
                else
                {
                    delete u2;
                }
            }
        }

        return -3;
    }

    //处理和转发客户端对雇佣兵的移动请求
    int CWorldBase::OnClientOthersMoveReq(CPluto& u)
    {
        CMailBox* mb = u.GetMailbox();
        if(mb == NULL)
        {
            return -1;
        }
        int fd = mb->GetFd();
        CEntityBase* p = GetEntityByFd(fd);
        if(p == NULL)
        {
            return -2;
        }

        int nCellId = p->GetCellServerId();
        if(nCellId > 0)
        {
            CMailBox* mb = GetServerMailbox(nCellId);
            if(mb)
            {
                CPluto* u2 = new CPluto;
                (*u2).Encode(MSGID_CELLAPP_CLIENT_OTHERS_MOVE_REQ) << p->GetId();

                u.Decode();
                int nCopyLen = (int)(u.GetMaxLen() - u.GetLen());
                if(nCopyLen > 0)
                {
                    u2->FillBuff(u.GetBuff() + u.GetLen(), nCopyLen);
                    (*u2) << EndPluto;
                    mb->PushPluto(u2);

                    return 0;
                }
                else
                {
                    delete u2;
                }
            }
        }

        return -3;
    }

    void CWorldBase::InitEntityCall()
    {
        world::InitEntityCall();

        m_entityCalls.insert(make_pair("RegisterGlobally",      &CEntityParent::lRegisterGlobally));
        m_entityCalls.insert(make_pair("RegisterCrossServer",   &CEntityParent::lRegisterCrossServer));
        m_entityCalls.insert(make_pair("GiveClientTo",          &CEntityParent::lGiveClientTo));
        m_entityCalls.insert(make_pair("NotifyClientToAttach",  &CEntityParent::lNotifyClientToAttach));
        m_entityCalls.insert(make_pair("CreateInNewSpace",      &CEntityParent::lCreateInNewSpace));
        m_entityCalls.insert(make_pair("CreateCellEntity",      &CEntityParent::lCreateCellEntity));
        m_entityCalls.insert(make_pair("HasCell",               &CEntityParent::lHasCell));
        m_entityCalls.insert(make_pair("DestroyCellEntity",     &CEntityParent::lDestroyCellEntity));
        m_entityCalls.insert(make_pair("SetCellVisiable",       &CEntityParent::lSetCellVisiable));
        m_entityCalls.insert(make_pair("NotifyDbDestroyAccountCache",       &CEntityParent::lNotifyDbDestroyAccountCache));
        m_entityCalls.insert(make_pair("TableInsertSql", &CEntityParent::lTableInsertSql));
        m_entityCalls.insert(make_pair("TableExcuteSql", &CEntityParent::lTableExcuteSql));
        m_entityCalls.insert(make_pair("TableSelectSql", &CEntityParent::lTableSelectSql));
        m_entityCalls.insert(make_pair("TblInsert", &CEntityParent::lTable2Insert));
        m_entityCalls.insert(make_pair("TblExcute", &CEntityParent::lTable2Excute));
        m_entityCalls.insert(make_pair("TblSelect", &CEntityParent::lTable2Select));
        m_entityCalls.insert(make_pair("CKickedOut", &CEntityParent::lKickedOut));
        m_entityCalls.insert(make_pair("hasClient",        &CEntityParent::lHasClient));
        m_entityCalls.insert(make_pair("GetIPAddr", &CEntityParent::lGetIPAddr));
        m_entityCalls.insert(make_pair("NotifyClientMultiLogin", &CEntityParent::lNotifyClientMultiLogin));

        //m_entityCalls.insert(make_pair("Collector", &CEntityParent::lCollector));

    }

    int CWorldBase::OnAvatarPosSync(T_VECTOR_OBJECT* p)
    {
#ifdef __FACE
        if(p->size() != 6 )
        {
            return -1;
        }
#else
        if(p->size() != 5 )
        {
            return -1;
        }
#endif

        pluto_msgid_t msg_id = VOBJECT_GET_U16((*p)[0]);
        TENTITYID eid = VOBJECT_GET_U32((*p)[1]);
#ifdef __FACE
        uint8_t face = VOBJECT_GET_U8((*p)[2]);
        int16_t x = VOBJECT_GET_I16((*p)[3]);
        int16_t y = VOBJECT_GET_I16((*p)[4]);
        uint8_t notifyToClient = VOBJECT_GET_U8((*p)[5]);
#else
        int16_t x = VOBJECT_GET_I16((*p)[2]);
        int16_t y = VOBJECT_GET_I16((*p)[3]);
        uint8_t notifyToClient = VOBJECT_GET_U8((*p)[4]);
#endif

        CEntityBase* pBase = (CEntityBase*)GetEntity(eid);
        if(pBase)
        {
            //LogDebug("CWorldBase::OnAvatarPosSync", "eid=%d;msg_id=%d;face=%d;x=%d;y=%d", eid, msg_id, face, x, y);

            //x,y字段设置到entity里
            pBase->SetMapXY(x, y);

            if (notifyToClient == 1)
            {
                //同步给客户端
                CMailBox* mb = GetServer()->GetClientMailbox(pBase->GetClientFd());
                if(mb)
                {
                    CPluto* u = new CPluto;
#ifdef __FACE
                    (*u).Encode(msg_id) << face << x << y << EndPluto;
#else
                    (*u).Encode(msg_id) << x << y << EndPluto;
#endif
                    mb->PushPluto(u);
                }
            }

        }

        return 0;
    }
    int CWorldBase::NotifyDbDestroyAccountCacheCallBack(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 1)
        {
            return -1;
        }
        TENTITYID eid = VOBJECT_GET_U32((*p)[0]);
        CEntityBase* pe = (CEntityBase*)GetEntity(eid);
        if(pe)
        {
            //printf("destroy_cellentity,%d\n", eid);

            ClearLuaStack(m_L);
            EntityMethodCall(m_L, pe, "onDestroy", 0, 0);

            //从世界中删除
            this->DelEntity(pe);

            //从lua的entity集合中删除
            luaL_getmetatable(m_L, g_szUserDataEntity);
            lua_pushlightuserdata(m_L, pe);
            lua_pushnil(m_L);
            lua_rawset(m_L, -3);
            //lua_pop(m_L, 1);
            ClearLuaStack(m_L);

            //test code,检查是否已经从lua中删除掉了
            //int nGcRet = lua_gc(m_L, LUA_GCCOLLECT, 0);
            //printf("lua_gc,ret=%d\n", nGcRet);

        }
        return 0;
        /*
        if(p->size() != 2 )
        {
        	return -1;
        }
        const CEntityMailbox& emb = VOBJECT_GET_EMB((*p)[0]);

        int32_t ref = VOBJECT_GET_I32((*p)[1]);

        ClearLuaStack(m_L);
        //printf("top:%d\n", lua_gettop(m_L));

        CLuaCallback& cb = GetCallback();
        int n = cb.GetObj(m_L, ref);

        CEntityBase* pBase = (CEntityBase*)GetEntity(emb.m_nEntityId);
        //根据指针获得lua userdata
        if (NULL == pBase)
        {
        	cb.Unref(m_L, ref);
        	ClearLuaStack(m_L);
        	return -1;
        }
        luaL_getmetatable(m_L, g_szUserDataEntity);
        lua_pushlightuserdata(m_L, pBase);
        lua_rawget(m_L, -2);
        lua_remove(m_L, -2);

        int nRet = lua_pcall(m_L, 1, 0, 0);
        if (nRet != 0)
        {
        	if (nRet == LUA_ERRRUN)
        	{
        		LogDebug("SelectEntityCallback", "call error:%s", \
        			lua_tostring(m_L, -1));
        	}
        }

        cb.Unref(m_L, ref);
        ClearLuaStack(m_L);

        return 0;
        */
    }

    int CWorldBase::UpdateItemsCallback(T_VECTOR_OBJECT* p)
    {
        //cout<<"updating array items start"<<endl;
        if(p->size() != 3)
        {
            return -1;
        }
        int32_t ref = VOBJECT_GET_I32((*p)[0]);
        uint16_t nRet = VOBJECT_GET_U16((*p)[1]);
        const string str = VOBJECT_GET_STR((*p)[2]);

        ClearLuaStack(m_L);
        CLuaCallback& cb = GetCallback();
        int n = cb.GetObj(m_L, ref);
        lua_pushnumber(m_L, nRet);
        lua_pushstring(m_L, str.c_str());
        //lua_pcall(m_L, 2, 0, 0);
        int ret = lua_pcall(m_L, 2, 0, 0);
        if (  ret != 0 )
        {
            if ( ret == LUA_ERRRUN )
            {
                LogDebug("update array items Callback", "call error:%s", lua_tostring(m_L, -1));
            }
        }
        cb.Unref(m_L, ref);
        ClearLuaStack(m_L);
        //cout<<"updating: ref ="<<ref <<" status = "<<nRet<<" content ="<<str.c_str()<<endl;
        //cout<<"updating array items end"<<endl;
        return 0;
    }

    int CWorldBase::LoadingAvatarItemsCallback(T_VECTOR_OBJECT* p)
    {
        //cout<<"loading array items start"<<endl;
        if(p->size() != 4)
        {
            return -1;
        }
        int32_t ref = VOBJECT_GET_I32((*p)[0]);
        uint16_t nRet = VOBJECT_GET_U16((*p)[1]);
        const string itemName = VOBJECT_GET_SSTR((*p)[2]);
        const string itemsData = VOBJECT_GET_SSTR((*p)[3]);
        //cout<<"ref = "<<ref<<endl;
        ClearLuaStack(m_L);
        CLuaCallback& cb = GetCallback();
        int n = cb.GetObj(m_L, ref);
        lua_pushnumber(m_L, nRet);
        //cout<<"curr top = "<<lua_gettop(m_L)<<endl;
        if( nRet == 0 )
        {
            CPluto* u = new CPluto();
            u->FillBuff(itemsData.c_str(), itemsData.size());
            //cout<<u->GetLen()<<endl;
            u->SetMaxLen(u->GetLen());
            //PrintHexPluto(*u);
            u->SetLen(0);

            const SEntityDef* pDef = GetDefParser().GetEntityDefByName(itemName);
            if(pDef == NULL)
            {
                delete u;
                LogError("entitydef not existed", "[name =%s]", itemName.c_str());

                cb.Unref(m_L, ref);

                return 0;
            }
            lua_newtable(m_L);
            int i = 1;
            while(u->GetLen() < u->GetMaxLen())
            {
                //ostringstream oss;
                lua_newtable(m_L);
                VOBJECT* vId = new VOBJECT();
                u->FillVObject(V_INT64, *vId);
                if(u->GetDecodeErrIdx() > 0)
                {
                    LogError("parse pluto error", "[type = %d][name = %s], [status = %d]", V_INT64, "id", -1);
                    delete vId;
                    vId = NULL;
                    delete u;
                    u = NULL;

                    cb.Unref(m_L, ref);

                    return 0;
                }
                lua_pushstring(m_L, "id");
                PushVObjectToLua(m_L, *vId);
                lua_settable(m_L, -3);

                map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.begin();
                for(; iter != pDef->m_properties.end(); ++iter)
                {
                    const _SEntityDefProperties* pProp = iter->second;
                    //LogDebug("Parse Pluto Start", "name = %s, type =%d", pProp->m_name.c_str(), pProp->m_nType);
                    VOBJECT *v = new VOBJECT();
                    if( IsBaseFlag(pProp->m_nFlags) && pProp->m_bSaveDb )
                    {
                        u->FillVObject(pProp->m_nType, *v);
                        if(u->GetDecodeErrIdx() > 0)
                        {
                            LogError("pluto parse error", "[type = %d][name = %s], [status = %d]", pProp->m_nType, pProp->m_name.c_str(), -1);
                            delete u;
                            u = NULL;
                            delete v;
                            v = NULL;

                            cb.Unref(m_L, ref);

                            return 0;
                        }
                        lua_pushstring(m_L, pProp->m_name.c_str());
                        PushVObjectToLua(m_L, *v);
                        lua_settable(m_L, -3);
                       
                    }
                    delete v;
                    v = NULL;
                    
                }
                lua_rawseti(m_L, -2, i++);
                //lua_pushstring(m_L, "next");
                //cout<<"lua top = "<<lua_gettop(m_L)<<endl;
            }
            delete u;
            u = NULL;
        }
        else if( nRet == 1 )
        {
            lua_newtable(m_L);
            lua_pushstring(m_L, "status");
            lua_pushstring(m_L, itemsData.c_str());
            lua_settable(m_L, -3);
        }
        
        int ret = lua_pcall(m_L, 2, 0, 0);
        if (  ret != 0)
        {
            if ( ret == LUA_ERRRUN )
            {
                LogDebug("Loading array items Callback", "call error:%s", lua_tostring(m_L, -1));
            }
        }
        cb.Unref(m_L, ref);
        ClearLuaStack(m_L);
        //cout<<"loading AvatarItemsCallback"<<endl;
        //cout<<"updating array items end"<<endl;
        return 0;
    }

    int CWorldBase::TableSelectCallback(CPluto& u)
    {
        u.Decode();

        uint32_t eid;
        u >> eid;

        LogDebug("CWorldBase::TableSelectCallback", "eid=%d", eid);

        CEntityBase* pBase = (CEntityBase*)GetEntity(eid);
        if(pBase == NULL)
        {
            return 0;
        }

        string strCallBackFunc;
        string strEntity;
        uint16_t nFieldNum;
        u >> strCallBackFunc >> strEntity >> nFieldNum;

        LogDebug("CWorldBase::TableSelectCallback", "strCallBackFunc=%s;strEntity=%s;nFieldNum=%d", strCallBackFunc.c_str(), strEntity.c_str(), nFieldNum);

        CDefParser& def = GetDefParser();
        const SEntityDef* pDef = def.GetEntityDefByName(strEntity);

        if (pDef)
        {
            vector<string> vtFields;
            vtFields.reserve(nFieldNum);
            vector<_SEntityDefProperties*> vtProps;
            vtProps.reserve(nFieldNum);

            string strField;

            for(uint16_t i = 0; i < nFieldNum; ++i)
            {
                u >> strField;

                //LogDebug("CWorldBase::TableSelectCallback 1", "strField=%s", strField.c_str());

                map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.find(strField);
                if(iter == pDef->m_properties.end())
                {
                    if(strField.compare("id") == 0 || strField.compare("timestamp") == 0)
                    {
                        vtFields.push_back(strField);
                        vtProps.push_back((_SEntityDefProperties*)NULL);
                    }
                    else
                    {
                        return -1;
                    }
                }
                else
                {
                    vtFields.push_back(strField);
                    vtProps.push_back(iter->second);
                }
            }

            //lua params
            lua_State* L = GetLuaState();
            ClearLuaStack(L);

            //lua_pushinteger(L, nCbId);
            lua_newtable(L);        //结果的table
            //lua_pushinteger(L, 1);  //随便push一个值,后面要pop掉的

            string strTmp = "";     //一个用来占位的变量
            //string strId = "id";
            bool ifHaveDbid = false;
            int raw = 1;
            while(!u.IsEnd())
            {
                lua_newtable(L);   //每一条记录

                for(uint16_t i = 0; i < nFieldNum; ++i)
                {
                    string strValue;
                    charArrayDummy* cValue = NULL;

                    //u >> strValue;

                    VOBJECT v;

                    const string& strFieldName = vtFields[i];
                    _SEntityDefProperties* pp = vtProps[i];

                    if(pp)
                    {
                        v.vt = pp->m_nType;
                        if (pp->m_nType == V_BLOB)
                        {
                            cValue = new charArrayDummy;
                            u >> (*cValue);
                        }
                        else
                        {
                            u >> strValue;
                        }
                    }
                    else
                    {
                        u >> strValue;
                        v.vt = V_UINT8;  //随便给个类型,防止析构时出错
                        if(strFieldName.compare("id") == 0)
                        {
                            TDBID dbid = (TDBID)atoll(strValue.c_str());
                            //lua_pop(L, 1);      //pop掉多余值
                            //lua_newtable(L);
                            //lua_pushinteger(L, dbid);
                            //lua_pushvalue(L, -2);
                            //lua_rawset(L, -4);
                            lua_pushnumber(L, dbid);
                            lua_pushvalue(L, -2);
                            lua_rawset(L, -4);
                            //lua_rawseti(L, -3, dbid);
                            //sql中是否带有id字段
                            ifHaveDbid = true;
                            //LogDebug("CWorldBase::TableSelectCallback 1", "size=%d", lua_gettop(L));
                            //LogDebug("CWorldBase::TableSelectCallback 2====", "dbid=%lld;strValue.c_str()=%s", dbid, strValue.c_str());
                        }
                        //else
                        //{
                        //	//id,timestamp两个特殊字段
                        //	v.vt = V_UINT32;
                        //	v.vv.u32 = (uint32_t)atoll(strValue.c_str());
                        //}

                        continue;
                    }

                    if (pp && pp->m_nType != V_BLOB)
                    {
                        if(strValue.empty())
                        {
                            FillVObjectDefaultValue(NULL, strTmp, v, pp->m_defaultValue);
                        }
                        else
                        {
                            FillVObjectDefaultValue(NULL, strTmp, v, strValue);
                        }
                    }
                    else if (pp)
                    {
                        //u >> *cValue;
                        v.vv.p = cValue;
                        //LogDebug("CWorldBase::TableSelectCallback 2", "cValue->m_s=%s;cValue->m_l=%d", cValue->m_s, cValue->m_l);
                    }

                    lua_pushstring(L, strFieldName.c_str());
                    //LogDebug("CWorldBase::TableSelectCallback", "strFieldName=%s", strFieldName.c_str());
                    PushVObjectToLua(L, v);
                    lua_rawset(L, -3);

                    if(u.IsEnd())
                    {
                        break;
                    }
                }

                if (!ifHaveDbid)
                {
                    //LogDebug("=========", "size=%d", lua_gettop(L));
                    lua_rawseti(L, -2, raw);
                    raw ++;
                    //LogDebug("=========", "size=%d", lua_gettop(L));
                }
                else
                {
                    lua_pop(L, 1);
                }

                //lua_pop(L, 1);

                

            }

            //lua_pop(L, 1);      //pop掉多余值

            LogDebug("CWorldBase::TableSelectCallback end", "size=%d", lua_gettop(L));

            EntityMethodCall(L, pBase, strCallBackFunc.c_str(), 1, 0);
            ClearLuaStack(L);
        }

        return 0;
    }
	int CWorldBase::TableInsertCallback(T_VECTOR_OBJECT* p)
	{
		if(p->size() != 2)
		{
			return -1;
		}
		int32_t ref = VOBJECT_GET_I32((*p)[0]);
		TDBID newId = VOBJECT_GET_U64((*p)[1]);

		ClearLuaStack(m_L);
		CLuaCallback& cb = GetCallback();
		int n = cb.GetObj(m_L, ref);
		lua_pushnumber(m_L, newId);
		//lua_pcall(m_L, 2, 0, 0);
		int ret = lua_pcall(m_L, 1, 0, 0);
		if ( ret != 0 )
		{
			if ( ret == LUA_ERRRUN )
			{
				LogDebug("CWorldBase::TableInsertCallback", "call error:%s", lua_tostring(m_L, -1));
			}
		}
		cb.Unref(m_L, ref);
		ClearLuaStack(m_L);
		//cout<<"updating: ref ="<<ref <<" status = "<<nRet<<" content ="<<str.c_str()<<endl;
		//cout<<"updating array items end"<<endl;
		return 0;
	}
    int CWorldBase::BroadClientRpc(T_VECTOR_OBJECT* p)
    {
        TENTITYTYPE iType = VOBJECT_GET_U16((*p)[0]);
        const char* pszFuncName = VOBJECT_GET_STR((*p)[1]);

        for(int i=2; i<(int)p->size(); ++i)
        {
            VOBJECT* _v = (*p)[i];
            PushVObjectToLua(m_L, *_v);
        }

        map<TENTITYID, CEntityBase*>& entities = m_enMgr.Entities();
        map<TENTITYID, CEntityBase*>::iterator iter = entities.begin();
        for(; iter != entities.end(); ++iter)
        {
            TENTITYTYPE _iType = iter->second->GetEntityType();
            CDefParser& def = GetDefParser();
            if (iType == _iType && iter->second->HasClient())
            {
                //RpcCallToClientViaBase(pszFuncName, iter->second->GetMyMailbox(), m_L);
                int n = EntityMethodCall(m_L, iter->second, pszFuncName, (uint8_t)(p->size()-2), 0);
                lua_pop(m_L, n);
            }
        }

        return 0;
    }
	
	int CWorldBase::TableUpdateCallback(T_VECTOR_OBJECT* p)
	{
		//cout<<"updating array items start"<<endl;
		if(p->size() != 2)
		{
			return -1;
		}
		int32_t ref = VOBJECT_GET_I32((*p)[0]);
		uint16_t nRet = VOBJECT_GET_U16((*p)[1]);

		ClearLuaStack(m_L);
		CLuaCallback& cb = GetCallback();
		int n = cb.GetObj(m_L, ref);
		lua_pushnumber(m_L, nRet);
		//lua_pcall(m_L, 2, 0, 0);
		int ret = lua_pcall(m_L, 1, 0, 0);
		if ( ret != 0 )
		{
			if ( ret == LUA_ERRRUN )
			{
				LogDebug("CWorldBase::TableUpdateCallback", "call error:%s", lua_tostring(m_L, -1));
			}
		}
		cb.Unref(m_L, ref);
		ClearLuaStack(m_L);
		//cout<<"updating: ref ="<<ref <<" status = "<<nRet<<" content ="<<str.c_str()<<endl;
		//cout<<"updating array items end"<<endl;
		return 0;
	}

	int CWorldBase::TableExcuteCallback(T_VECTOR_OBJECT* p)
	{
		if(p->size() != 2)
		{
			return -1;
		}
		int32_t ref = VOBJECT_GET_I32((*p)[0]);
		uint8_t ret = VOBJECT_GET_U32((*p)[1]);

		ClearLuaStack(m_L);
		CLuaCallback& cb = GetCallback();
		int n = cb.GetObj(m_L, ref);
		lua_pushnumber(m_L, ret);
		//lua_pcall(m_L, 2, 0, 0);
		int err = lua_pcall(m_L, 1, 0, 0);
		if ( err != 0 )
		{
			if ( err == LUA_ERRRUN )
			{
				LogDebug("CWorldBase::TableExcuteCallback", "call error:%s", lua_tostring(m_L, -1));
			}
		}
		cb.Unref(m_L, ref);
		ClearLuaStack(m_L);

		return 0;
	}
    int CWorldBase::IncrementalInsertCallback(T_VECTOR_OBJECT* p)
    {
        if( p->size() != 4 )
        {
            return -1;
        }
        int32_t ref = VOBJECT_GET_I32((*p)[0]);
        uint16_t nRet = VOBJECT_GET_U16((*p)[1]);
        const string tblName = VOBJECT_GET_SSTR((*p)[2]);
        const string itemsData = VOBJECT_GET_SSTR((*p)[3]);

        ClearLuaStack(m_L);
        CLuaCallback& cb = GetCallback();
        int n = cb.GetObj(m_L, ref);
        lua_pushnumber(m_L, nRet);

        const SEntityDef* pDef = GetDefParser().GetEntityDefByName(tblName);
        if(pDef == NULL)
        {
            LogError("entitydef not existed", "[name =%s]", tblName.c_str());
            return 0;
        }
        
        if( nRet == 0 )
        {
            CPluto* u = new CPluto();
            u->FillBuff(itemsData.c_str(), itemsData.size());
            u->SetMaxLen(u->GetLen());
            //PrintHexPluto(*u);
            u->SetLen(0);
            lua_newtable(m_L);
            int i = 1;
            while(u->GetLen() < u->GetMaxLen())
            {
                lua_newtable(m_L);
                vector<VOBJECT*> vec;
                VOBJECT* vId = new VOBJECT();
                u->FillVObject(V_INT64, *vId);
                if(u->GetDecodeErrIdx() > 0)
                {
                    LogError("parse pluto error", "[type = %d][name = %s], [status = %d]", V_INT64, "id", -1);
                    delete vId;
                    vId = NULL;
                    delete u;
                    u = NULL;

                    cb.Unref(m_L, ref);

                    return 0;
                }
                lua_pushstring(m_L, "nId");
                PushVObjectToLua(m_L, *vId);
                lua_settable(m_L, -3);
                
                u->FillVObject(V_INT64, *vId);
                if(u->GetDecodeErrIdx() > 0)
                {
                    LogError("parse pluto error", "[type = %d][name = %s], [status = %d]", V_INT64, "id", -1);
                    delete vId;
                    vId = NULL;
                    delete u;
                    u = NULL;

                    cb.Unref(m_L, ref);

                    return 0;
                }
                lua_pushstring(m_L, "oId");
                PushVObjectToLua(m_L, *vId);
                lua_settable(m_L, -3);
                delete vId;
             
                map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.begin();
                for(; iter != pDef->m_properties.end(); ++iter)
                {
                    VOBJECT *v = new VOBJECT();
                    const _SEntityDefProperties* pProp = iter->second;
                    if( pProp->m_name.compare("bagGridType") == 0 || pProp->m_name.compare("gridIndex") == 0 )
                    {
                        u->FillVObject(pProp->m_nType, *v);
                        if( u->GetDecodeErrIdx() > 0 )
                        {
                            LogError("parse pluto error", "[type = %d][name = %s], [status = %d]", pProp->m_nType, pProp->m_name.c_str(), -1);
                            delete u;
                            u = NULL;
                            delete v;
                            v = NULL;

                            cb.Unref(m_L, ref);

                            return 0;
                        }
                        lua_pushstring(m_L, pProp->m_name.c_str());
                        PushVObjectToLua(m_L, *v);
                        lua_settable(m_L, -3);
                    }
                    delete v;
                    v = NULL;
                    
                }
                lua_rawseti(m_L, -2, i++);
            }
            delete u;
            u = NULL;
        }
        else if( nRet == 1 )
        {
            lua_newtable(m_L);
            lua_pushstring(m_L, "status");
            lua_pushstring(m_L, itemsData.c_str());
            lua_settable(m_L, -3);
        }
        
        int ret = lua_pcall(m_L, 2, 0, 0);
        if (  ret != 0 )
        {
            if ( ret == LUA_ERRRUN )
            {
                LogDebug("insert items Callback", "call error:%s", lua_tostring(m_L, -1));
            }
        }
        cb.Unref(m_L, ref);
        ClearLuaStack(m_L);
        return 0;

    }

    int CWorldBase::OnCrossClientBroadcast(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 2)
        {
            return -1;
        }
        uint16_t nMsgId = VOBJECT_GET_U16((*p)[0]);
        string strMsg = VOBJECT_GET_SSTR((*p)[1]);

        ClearLuaStack(m_L);
        lua_pushinteger(m_L, nMsgId);
        lua_pushstring(m_L, strMsg.c_str());

        const static char szScriptName[] = "cross_client";
        const static char szCallback[] = "onCrossClientBroadcast";
        ScriptMethodCall(m_L, szScriptName, szCallback, 2, 0);

        ClearLuaStack(m_L);

        return 0;
    }

    int CWorldBase::Table2ExcuteResp(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 4)
        {
            return -1;
        }

        TENTITYID eid = VOBJECT_GET_U32((*p)[0]);
        uint32_t nCbId = VOBJECT_GET_U32((*p)[1]);               
        int nRet = VOBJECT_GET_I8((*p)[2]);               
        const string& strErr = VOBJECT_GET_SSTR((*p)[3]);

        CEntityBase* pBase = (CEntityBase*)GetEntity(eid);
        if(pBase)
        {
            ClearLuaStack(m_L);
            lua_pushinteger(m_L, nCbId);
            lua_pushinteger(m_L, nRet);
            lua_pushstring(m_L, strErr.c_str());
            EntityMethodCall(m_L, pBase, "onTblExcuteResp", 3, 0);
            ClearLuaStack(m_L);
        }

        return 0;
    }

    int CWorldBase::Table2SelectResp(CPluto& u)
    {
        u.Decode();     //把内部指针调回去

        uint32_t eid;
        u >> eid;

        CEntityBase* pBase = (CEntityBase*)GetEntity(eid);
        if(pBase == NULL)
        {
            return 0;
        }

        uint32_t nCbId;
        string strEntity;
        uint16_t nFieldNum;
        u >> nCbId >> strEntity >> nFieldNum;

        CDefParser& def = GetDefParser();
        const SEntityDef* pDef = def.GetEntityDefByName(strEntity);
        if(pDef)
        {		
            vector<string> vtFields;
            vtFields.reserve(nFieldNum);
            vector<_SEntityDefProperties*> vtProps;
            vtProps.reserve(nFieldNum);

            for(uint16_t i = 0; i < nFieldNum; ++i)
            {
                string strField;
                u >> strField;

                map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.find(strField);
                if(iter == pDef->m_properties.end())
                {
                    if(strField.compare("id") == 0 || strField.compare("timestamp") == 0)
                    {
                        vtFields.push_back(strField);
                        vtProps.push_back((_SEntityDefProperties*)NULL);					
                    }
                    else
                    {
                        return -1;
                    }				
                }
                else
                {
                    vtFields.push_back(strField);
                    vtProps.push_back(iter->second);	
                }			
            }

            //lua params
            lua_State* L = GetLuaState();
            ClearLuaStack(L);

            lua_pushinteger(L, nCbId);
            lua_newtable(L);
            lua_pushinteger(L, 1);	//随便push一个值,后面要pop掉的

            string strTmp = "";		//一个用来占位的变量
            string strId = "id";
            while(!u.IsEnd())
            {		
                for(uint16_t i = 0; i < nFieldNum; ++i)
                {				
                    //这里有bug,如果是blob类型,这样取值是有问题的
                    string strValue;
                    u >> strValue;

                    VOBJECT v;

                    const string& strFieldName = vtFields[i];
                    _SEntityDefProperties* pp = vtProps[i];
                    if(pp)
                    {
                        v.vt = pp->m_nType;
                    }
                    else
                    {
                        v.vt = V_UINT8;  //随便给个类型,防止析构时出错
                        if(strFieldName == strId)
                        {
                            uint64_t dbid = (uint64_t)atoll(strValue.c_str());
                            lua_pop(L, 1);		//pop掉多余值
                            lua_newtable(L);
                            lua_pushinteger(L, dbid);
                            lua_pushvalue(L, -2);
                            lua_rawset(L, -4);
                        }
                        //else
                        //{
                        //	//id,timestamp两个特殊字段
                        //	v.vt = V_UINT32;
                        //	v.vv.u32 = (uint32_t)atoll(strValue.c_str());
                        //}

                        continue;
                    }				

                    if(strValue.empty())
                    {
                        FillVObjectDefaultValue(NULL, strTmp, v, pp->m_defaultValue);
                    }
                    else
                    {
                        FillVObjectDefaultValue(NULL, strTmp, v, strValue);
                    }

                    lua_pushstring(L, strFieldName.c_str());
                    PushVObjectToLua(L, v);
                    lua_rawset(L, -3);

                    if(u.IsEnd())
                    {
                        break;
                    }
                }
            }

            lua_pop(L, 1);		//pop掉多余值

            EntityMethodCall(L, pBase, "onTblSelectResp", 2, 0);
            ClearLuaStack(L);
        }	

        return 0;
    }

    int CWorldBase::Table2InsertResp(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 4)
        {
            return -1;
        }

        TENTITYID eid = VOBJECT_GET_U32((*p)[0]);
        uint32_t nCbId = VOBJECT_GET_U32((*p)[1]);               
        uint64_t new_dbid = VOBJECT_GET_U64((*p)[2]);               
        const string& strErr = VOBJECT_GET_SSTR((*p)[3]);

        CEntityBase* pBase = (CEntityBase*)GetEntity(eid);
        if(pBase)
        {
            ClearLuaStack(m_L);
            lua_pushinteger(m_L, nCbId);
            lua_pushnumber(m_L, new_dbid);
            lua_pushstring(m_L, strErr.c_str());
            EntityMethodCall(m_L, pBase, "onTblInsertResp", 3, 0);
            ClearLuaStack(m_L);
        }

        return 0;
    }


}

  
