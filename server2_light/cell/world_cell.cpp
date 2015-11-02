/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：world_cell
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.14
// 模块描述：cell 服务器 逻辑相关
//----------------------------------------------------------------*/

#include "world_cell.h"
#include "lua_cell.h"
#include "world_select.h"
#include "lua_mogo_impl.h"
#include "lua_bitset.h"


const static char* s_entity_ctor_name = "__ctor__";       //构造函数
const static char* s_entity_dctor_name = "__dctor__";     //析构函数

const static char* s_entity_enter_space = "onEnterSpace";    //entity进入Space时调用的脚本方法
const static char* s_entity_leave_space = "onLeaveSpace";    //entity离开Space时调用的脚本方法

using namespace mogo;


namespace mogo
{


    CWorldCell::CWorldCell() : world(), m_nSpaceSeq(0), moveTimes(0)

#ifdef __TEST
        , movePackets(0), sumMoveCost(0)
#endif

#ifdef __AOI_PRUNING
        , m_nMaxObserverCount(0), m_nMaxFollowerCount(0)
#endif

    {

    }

    CWorldCell::~CWorldCell()
    {
        this->Clear();
    }

    void CWorldCell::Clear()
    {
        ClearMap(m_spaces);
        ClearMap(m_idleSpaces);
    }


    int CWorldCell::init(const char* pszEtcFile)
    {
        LogInfo("CWorldCell::init()", "");

        int nWorldInit = world::init(pszEtcFile);
        if(nWorldInit != 0)
        {
            return nWorldInit;
        }

        try
        {
            //m_defParser.init(m_cfg->GetValue("init", "def_path").c_str());
        }
        catch(const CException& e)
        {
            LogError("world::init().error", "%s", e.GetMsg().c_str());
            return -1;
        }

#ifdef __AOI_PRUNING
        this->m_nMaxObserverCount = atoi(m_cfg->GetOptValue("params", "max_observer_count", "15").c_str());
        this->m_nMaxFollowerCount = atoi(m_cfg->GetOptValue("params", "max_follower_count", "30").c_str());
#endif

        m_L = luaL_newstate();
        if(m_L==NULL)
        {
            return -1;
        }

        luaL_openlibs(m_L);   //装载lua标准库

        this->OpenMogoLib(m_L);   //装载cw 库
        g_lua_bitset.Init(m_L);
        ClearLuaStack(m_L);

        //lua脚本的顶层路径名
        string strLuaPath = m_cfg->GetValue("init", "lua_path");
        lua_pushstring(m_L, strLuaPath.c_str());
        lua_setglobal(m_L, "G_LUA_ROOTPATH");

        //读取初始化文件
        char szTmp[512];
        snprintf(szTmp, sizeof(szTmp), "package.path=package.path..';%s/cell/?.lua;%s/cell/?.luac'\0",
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


    int CWorldCell::OpenMogoLib(lua_State* L)
    {
        return LuaOpenMogoLibCCell(L);
    }

    CSpace* CWorldCell::CreateNewSpace()
    {
        //enum { MAX_X = 150, MAX_Y = 150, };
        TSPACEID nid = this->GetNextSpaceId();
        CSpace* s = new CSpace(nid);

        //新创建的space先进入空闲space池，不参与aoi计算
        m_idleSpaces.insert(make_pair(nid, s));

        //LogInfo("world::createNewSpace", "space_id=%d;space=%x", nid, s);

        return s;
    }

    CSpace* CWorldCell::GetSpace(TSPACEID id)
    {
        map<TSPACEID, CSpace*>::const_iterator iter = m_spaces.find(id);
        if(iter != m_spaces.end())
        {
            return iter->second;
        }
        else
        {
            map<TSPACEID, CSpace*>::const_iterator iter1 = m_idleSpaces.find(id);
            if(iter1 != m_idleSpaces.end())
            {
                return iter1->second;
            }
            else
            {
                return NULL;
            }
        }
    }

    bool CWorldCell::AddEntity(CEntityCell* p)
    {
        return m_enMgr.AddEntity(p);
    }

    bool CWorldCell::DelEntity(CEntityCell* p)
    {
        //删除一个对象时，在事件管理器里注册的管理器也删掉
        pstEventDispatcher->DeleteEntity(p->GetId());

        return m_enMgr.DelEntity(p);
    }

    CEntityParent* CWorldCell::GetEntity(TENTITYID id)
    {
        return (CEntityParent*)m_enMgr.GetEntity(id);
    }

    bool CWorldCell::ActiveSpace(TSPACEID id)
    {
        map<TSPACEID, CSpace*>::iterator iter = m_idleSpaces.find(id);
        if(iter != m_idleSpaces.end())
        {
            CSpace *s = iter->second;

            m_idleSpaces.erase(iter);

            pair<map<TSPACEID, CSpace*>::iterator, bool> ret = m_spaces.insert(make_pair(id, s));
            return ret.second;
        }
        else
        {
            return false;
        }
    }

    bool CWorldCell::InActiveSpace(TSPACEID id)
    {
        map<TSPACEID, CSpace*>::iterator iter = m_spaces.find(id);
        if(iter != m_spaces.end())
        {
            CSpace *sp = iter->second;

            sp->AllEntitiesMove();

            if(sp->IsAoiDirty())
            {
                //LogDebug("CWorldCell::OnTimeMove AoiEvent", "id=%d", iter2->first);
                sp->AoiEvent();
            }

            sp->AllEntitiesCheckLeaveAoi();

            m_spaces.erase(iter);

            pair<map<TSPACEID, CSpace*>::iterator, bool> ret = m_idleSpaces.insert(make_pair(id, sp));
            return ret.second;
        }
        else
        {
            return false;
        }
    }


    int CWorldCell::FromRpcCall(CPluto& u)
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
            LogWarning("from_rpc_call", "rpc decode error.msgid:%d;pluto err idx=%d\n",
                       msg_id, u.GetDecodeErrIdx());
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
            case MSGID_CELLAPP_ENTITY_RPC:
            {
                nRet = FromLuaCellRpcCall(p);
                break;
            }
            case MSGID_CELLAPP_CREATE_CELL_IN_NEW_SPACE:
            {
                nRet = CreateCellInNewSpace(p);
                break;
            }
            case MSGID_CELLAPP_LUA_DEBUG:
            {
                nRet = DebugLuaCode(p);
                break;
            }
            case MSGID_CELLAPP_CREATE_CELL_VIA_MYCELL:
            {
                nRet = CreateCellViaMycell(p);
                break;
            }
            case MSGID_CELLAPP_ENTITY_ATTRI_SYNC:
            {
                nRet = OnEntityAttriSync(p);
                break;
            }
            case MSGID_CELLAPP_DESTROY_CELLENTITY:
            {
                nRet = DestroyCellEntity(p);
                break;
            }
            case MSGID_ALLAPP_SHUTDOWN_SERVER:
            {
                nRet = ShutdownServer(p);
                break;
            }
            case MSGID_CELLAPP_PICKLE_CLIENT_ATTRIS:
            {
                nRet = PickleClientAttris(p);
                break;
            }
            case MSGID_CELLAPP_PICKLE_AOI_ENTITIES:
            {
                nRet = PickleAoiEntities(p);
                break;
            }
            case MSGID_CELLAPP_CLIENT_MOVE_REQ:
            {
                nRet = OnClientMoveReq(p);
                break;
            }
            case MSGID_CELLAPP_CLIENT_OTHERS_MOVE_REQ:
            {
                nRet = OnClientOthersMoveReq(p);
                break;
            }
            case MSGID_CELLAPP_LOSE_CLIENT:
            {
                nRet = OnLoseClient(p);
                break;
            }
            case MSGID_CELLAPP_ON_TIME_MOVE:
            {
                nRet = OnTimeMove(p);
                break;
            }
            case MSGID_CELLAPP_SET_VISIABLE:
            {
                nRet = SetCellVisiable(p);
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

    int CWorldCell::FromLuaCellRpcCall(T_VECTOR_OBJECT* p)
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
        const string& strFuncName = GetDefParser().GetCellMethodNameById(emb.m_nEntityType, nFuncId);

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
//        LogInfo("CWorldCell::FromLuaCellRpcCall Cost", "strFuncName=%s;cost=%d", strFuncName.c_str(), cost);
//#endif

        return 0;
    }

    //创建一个新的space,并在其中创建cell entity
    int CWorldCell::CreateCellInNewSpace(T_VECTOR_OBJECT* p, bool insertAOI)
    {
        //LogInfo("CreateCellInNewSpace", "");
        if(p->size() < 4)
        {
            return -1;
        }

        CEntityMailbox& emb = VOBJECT_GET_EMB((*p)[0]);
        uint16_t etype = VOBJECT_GET_U16((*p)[1]);

#ifdef __USE_MSGPACK
        charArrayDummy *d = (charArrayDummy*)VOBJECT_GET_BLOB((*p)[2]);
#else
        const string& strParams = VOBJECT_GET_SSTR((*p)[2]);
#endif

        charArrayDummy& szProps = *((charArrayDummy*)((*p)[3]->vv.p));

        //创建新space
        CDefParser& def = GetDefParser();
        CSpace* s = CreateNewSpace();

        //创建cell entity
        lua_State* L = GetLuaState();
        ClearLuaStack(L);
        lua_pushstring(L, def.GetTypeName(etype).c_str());  //entity type name
        lua_pushinteger(L, emb.m_nEntityId);                //entity id
        CEntityCell* e = _CreateEntity<CEntityCell>(L);     //cell和base的id是一样的

#ifdef __USE_MSGPACK
        if(d && LuaUnpickleFromBlob(L, d->m_s, d->m_l))
#else
        //data table
        if(!strParams.empty() && LuaUnpickleFromString(L, strParams))
#endif
        {
            lua_replace(L, 2);      //替换掉id
            //更新其他字段
            e->UpdateProps(L);
        }

        //更新base/cell共有的属性
        {
            map<string, VOBJECT*> cellProps;
            if(UnpickleCellProps(etype, szProps, cellProps))
            {
                e->UpdateProps(cellProps);
            }
            ClearMap(cellProps);
        }

        //加入到space中的特定位置
        this->AddEntity(e);

        if (insertAOI)
        {
            s->AddEntity(0, 0, e);//kevintest 需要把spaceloader实体加入AOI
        }
        else
        {
            e->SetSpaceID(s->GetId());//kevintest  调用create_avatar_req会调用MapActionMgr:create_cell通过找spaceloader的cell实体来获取对应cspace类实例。否则创建cell在mogo::CWorldCell::CreateCellViaMycell会失败return
        }
        //记录base的mailbox
        NewBaseMailbox(L, emb.m_nServerMailboxId, emb.m_nEntityType, emb.m_nEntityId);
        {
            CLuaCallback& cb = GetLuaTables();
            int nRef = cb.Ref(L);
            e->AddBaseMailbox(nRef, emb.m_nServerMailboxId);
        }

        //entity __ctor__
        EntityMethodCall(L, e, s_entity_ctor_name, 0, 0);
        ClearLuaStack(L);

        //通知base,cell创建完毕
        CMailBox* base = GetServerMailbox(emb.m_nServerMailboxId);
        //LogInfo("CreateCellInNewSpace22", "%d,%x", emb.m_nServerMailboxId, base);
        if(base)
        {
            emb.m_nServerMailboxId = GetMailboxId();
            base->RpcCall(GetRpcUtil(), MSGID_BASEAPP_ON_GET_CELL, emb);
        }

        return 0;
    }

    int CWorldCell::DebugLuaCode(T_VECTOR_OBJECT* p)
    {
        const char* pszLuaCode = VOBJECT_GET_STR((*p)[0]);
        LogInfo("CWorldCell::debug_lua_code", "%s", pszLuaCode);

        //luaL_dostring(m_L, "g_stdout = io.stdout");

        if(luaL_dostring(m_L, pszLuaCode) != 0)
        {
            LogInfo("CWorldCell::debug_lua_code", "dostring error:%s", lua_tostring(m_L, -1));
        }

        return 0;
    }

    //创建cell失败给base的消息
    void CWorldCell::CreateCellFailed(CEntityMailbox& emb, uint8_t err_id)
    {
        LogWarning("_create_cell_failed", "etype=%d;id=%d;err=%d", emb.m_nEntityType, emb.m_nEntityId, err_id);

        CMailBox* mb = GetServerMailbox(emb.m_nServerMailboxId);
        if(mb)
        {
            mb->RpcCall(GetRpcUtil(), MSGID_BASEAPP_CREATE_CELL_FAILED, emb.m_nEntityId, err_id);
        }
    }

    int CWorldCell::CreateCellViaMycell(T_VECTOR_OBJECT* p)
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
        charArrayDummy& szProps = *((charArrayDummy*)((*p)[5]->vv.p));

        //根据另外一个entity的id获得space
        CSpace* sp = NULL;
        CEntityCell* pCell = (CEntityCell*)GetEntity(myid);
        if(pCell)
        {
            TSPACEID spid = pCell->GetSpaceID();
            sp = GetSpace(spid);
        }

        if(sp == NULL)
        {
            //找不到创建entity的space
            CreateCellFailed(emb, 1);
            return 0;
        }

        //创建cell entity
        CDefParser& def = GetDefParser();
        lua_State* L = GetLuaState();
        ClearLuaStack(L);
        lua_pushstring(L, def.GetTypeName(emb.m_nEntityType).c_str());    //entity type name
        lua_pushinteger(L, emb.m_nEntityId);                              //entity id
        CEntityCell* e = _CreateEntity<CEntityCell>(L);                   //cell和base的id是一样的

        //更新base/cell共有的属性
        {
            map<string, VOBJECT*> cellProps;
            if(UnpickleCellProps(emb.m_nEntityType, szProps, cellProps))
            {
                e->UpdateProps(cellProps);
            }
            ClearMap(cellProps);
        }

		//LogDebug("CWorldCell::CreateCellViaMycell", "EntityType=%d;x=%d;y=%d", e->GetEntityType(), x, y);
		this->AddEntity(e);
		sp->AddEntity((position_t)x, (position_t)y, e);             //entity加入space

        //记录base的mailbox
        NewBaseMailbox(L, emb.m_nServerMailboxId, emb.m_nEntityType, emb.m_nEntityId);
        {
            CLuaCallback& cb = GetLuaTables();
            int nRef = cb.Ref(L);
            e->AddBaseMailbox(nRef, emb.m_nServerMailboxId);
        }

        //entity __ctor__
        EntityMethodCall(L, e, s_entity_ctor_name, 0, 0);
        ClearLuaStack(L);

        //entity onEnterSpace
        EntityMethodCall(L, e, s_entity_enter_space, 0, 0);
        ClearLuaStack(L);

        //通知base,cell创建完毕
        CMailBox* base = GetServerMailbox(emb.m_nServerMailboxId);
        if(base)
        {
            emb.m_nServerMailboxId = GetMailboxId();
            base->RpcCall(GetRpcUtil(), MSGID_BASEAPP_ON_GET_CELL, emb);
        }

        return 0;
    }

    int CWorldCell::OnEntityAttriSync(T_VECTOR_OBJECT* p)
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
            bool bUpdate;
            VOBJECT* vv = (*p)[2];
            VOBJECT* v = pe->UpdateAProp(strPropName, vv, bUpdate);
            //LogDebug("CWorldCell::OnEntityAttriSync", "p->size()=%d;strPropName=%s", p->size(), strPropName.c_str());
            if(bUpdate)
            {
                //更新成功,指针被替换了
                (*p)[2] = v;
                ((CEntityCell*)pe)->OnAttriModified(strPropName, vv);
            }
        }

        return 0;
    }

    bool CWorldCell::UnpickleCellProps(uint16_t etype, charArrayDummy& ad, map<string, VOBJECT*>& cellProps)
    {
        CPluto u(ad.m_s, ad.m_l);
        u.SetLen(0);    //指向0

        const SEntityDef* pDef = GetDefParser().GetEntityDefByType(etype);
        if(pDef)
        {
            while(!u.IsEnd())
            {
                uint16_t nPropId;
                u >> nPropId;
                if(u.GetDecodeErrIdx() > 0)
                {
                    return false;
                }

                const string& strPropName = pDef->m_propertiesMap.GetStrByInt(nPropId);
                map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.find(strPropName);
                if(iter == pDef->m_properties.end())
                {
                    return false;
                }
                VOBJECT* v = new VOBJECT;
                u.FillVObject(iter->second->m_nType, *v);
                if(u.GetDecodeErrIdx() > 0)
                {
                    delete v;
                    LogWarning("CWorldCell::UnpickleCellProps", "strPropName=%s", strPropName.c_str());
                    return false;
                }
                //LogDebug("CWorldCell::UnpickleCellProps", "strPropName=%s", strPropName.c_str());
                cellProps.insert(make_pair(strPropName, v));
            }
        }

        return pDef != NULL;
    }

    int CWorldCell::DestroyCellEntity(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 2)
        {
            return -1;
        }

        uint16_t nBaseappId = VOBJECT_GET_U16((*p)[0]);
        TENTITYID eid = VOBJECT_GET_U32((*p)[1]);
        CEntityCell* pe = (CEntityCell*)GetEntity(eid);
        if(pe)
        {
            //printf("destroy_cellentity,%d\n", eid);

            ClearLuaStack(m_L);

            EntityMethodCall(m_L, pe, s_entity_leave_space, 0, 0);
            ClearLuaStack(m_L);

            EntityMethodCall(m_L, pe, "onDestroy", 0, 0);

            //从场景中删除
            CSpace* sp = GetSpace(pe->GetSpaceID());
            if(sp)
            {
                sp->DelEntity(pe);
            }

            //从世界中删除
            this->DelEntity(pe);

            //把CEntityCell的数据全部打包出来，传给baseApp
            CPluto* u = new CPluto;
            u->Encode(MSGID_BASEAPP_ON_LOSE_CELL);

            (*u) << eid;

            pe->PickleCellToPluto(*u);

            (*u) << EndPluto;


            //从lua的entity集合中删除
            luaL_getmetatable(m_L, g_szUserDataEntity);
            lua_pushlightuserdata(m_L, pe);
            lua_pushnil(m_L);
            lua_rawset(m_L, -3);
            //lua_pop(m_L, 1);
            ClearLuaStack(m_L);

            CMailBox* mb = GetServerMailbox(nBaseappId);
            if (mb)
            {
                mb->PushPluto(u);
            }
            else
            {
                LogWarning("CWorldCell::DestroyCellEntity", "");
                delete u;
            }

			pe->ClearAllData();

            //test code,检查是否已经从lua中删除掉了
            //int nGcRet = lua_gc(m_L, LUA_GCCOLLECT, 0);
            //printf("lua_gc,ret=%d\n", nGcRet);

            ////通知base
            //RpcCall(nBaseappId, MSGID_BASEAPP_ON_LOSE_CELL, eid);
        }

        return 0;
    }

    int CWorldCell::PickleClientAttris(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 1)
        {
            return -1;
        }

        TENTITYID eid = VOBJECT_GET_U32((*p)[0]);
        CEntityCell* pe = (CEntityCell*)GetEntity(eid);
        if(pe)
        {
            int nBaseId = pe->GetBaseServerId();
            if(nBaseId <= 0)
            {
                return 0;
            }

            CMailBox* mb = GetServerMailbox((uint16_t)nBaseId);
            if(mb)
            {
                CPluto* u = new CPluto;
                (*u).Encode(MSGID_BASEAPP_CLIENT_MSG_VIA_BASE) << eid << (uint16_t)MSGID_CLIENT_ENTITY_CELL_ATTACHED;

                CPluto& uu = *u;
                uint32_t idx1 = uu.GetLen();
                uu << (uint16_t)0;                   //长度占位

                //输入数据
                pe->PickleClientToPluto(uu);

                uint32_t idx2 = uu.GetLen();
                uu.ReplaceField<uint16_t>(idx1, idx2 - idx1 - 2);
                uu << EndPluto;

                LogDebug("CWorldCell::PickleClientAttris", "uu.GenLen()=%d", uu.GetLen());
                mb->PushPluto(u);
            }
        }

        return 0;
    }

    int CWorldCell::PickleAoiEntities(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 1)
        {
            return -1;
        }

        TENTITYID eid = VOBJECT_GET_U32((*p)[0]);
        CEntityCell* pe = (CEntityCell*)GetEntity(eid);
        if(pe)
        {
            int nBaseId = pe->GetBaseServerId();
            if(nBaseId <= 0)
            {
                return 0;
            }

            CMailBox* mb = GetServerMailbox((uint16_t)nBaseId);
            if(mb)
            {
                CPluto* u = new CPluto;
                (*u).Encode(MSGID_BASEAPP_CLIENT_MSG_VIA_BASE) << eid << (uint16_t)MSGID_CLIENT_AOI_ENTITIES;

                pe->PickleAoiEntities(*u);

                LogDebug("CWorldCell::PickleAoiEntities", "id=%d", pe->GetId());

                mb->PushPluto(u);
            }
        }

        return 0;
    }

    int CWorldCell::OnClientMoveReq(T_VECTOR_OBJECT* p)
    {
        //printf("CWorldCell::on_client_move_req\n");
#ifdef __FACE
        if(p->size() < 4)
        {
            return -1;
        }
#else
        if(p->size() < 3)
        {
            return -1;
        }
#endif
        TENTITYID eid = VOBJECT_GET_U32((*p)[0]);
        CEntityCell* pCell = (CEntityCell*)GetEntity(eid);
        if(pCell)
        {
            //list<pair<int16_t, int16_t>*>* lsPosPairs = new list<pair<int16_t, int16_t>*>;
            //for(size_t i=1; i<p->size(); i+=2)
            //{
            //    int16_t x = VOBJECT_GET_I16((*p)[i]);
            //    int16_t y = VOBJECT_GET_I16((*p)[i+1]);
            //    lsPosPairs->push_back(new pair<int16_t, int16_t>(x,y));
            //}

            //pCell->OnClientMoveReq(lsPosPairs);
#ifdef __FACE
            uint8_t face = VOBJECT_GET_U8((*p)[1]);
            int16_t x = VOBJECT_GET_I16((*p)[2]);
            int16_t y = VOBJECT_GET_I16((*p)[3]);
#else
            int16_t x = VOBJECT_GET_I16((*p)[1]);
            int16_t y = VOBJECT_GET_I16((*p)[2]);
#endif

#ifdef __TEST
            //LogDebug("CWorldCell::OnClientMoveReq", "eid=%d;face=%d;x=%d;y=%d;old_x=%d;old_y=%d",
            //                                         eid, face, x, y, pCell->m_pos[0], pCell->m_pos[1]);
#endif

#ifdef __FACE
            pCell->OnClientMoveReq(face, x, y);
#else
            pCell->OnClientMoveReq(x, y);
#endif

        }

        return 0;
    }

    int CWorldCell::OnClientOthersMoveReq(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 5)
        {
            return -1;
        }

        //uint8_t type = VOBJECT_GET_U8((*p)[0]);

        TENTITYID eid = VOBJECT_GET_U32((*p)[0]);
        CEntityCell* pCell = (CEntityCell*)GetEntity(eid);
        if(pCell)
        {

            //uint8_t type = VOBJECT_GET_U8((*p)[1]);
            //uint8_t face = VOBJECT_GET_U8((*p)[2]);
            //int16_t x = VOBJECT_GET_I16((*p)[3]);
            //int16_t y = VOBJECT_GET_I16((*p)[4]);

            for(int i=1; i<(int)p->size(); ++i)
            {
                VOBJECT* _v = (*p)[i];
                PushVObjectToLua(m_L, *_v);
            }

            LogDebug("CWorldCell::OnClientOtherMoveReq", "");

            EntityMethodCall(m_L, pCell, "OthersMoveReq", (uint8_t)(p->size()-1), 0);
            ClearLuaStack(m_L);

        }

        return 0;
    }

    int CWorldCell::OnLoseClient(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 1)
        {
            return -1;
        }

        TENTITYID eid = VOBJECT_GET_U32((*p)[0]);
        CEntityCell* pe = (CEntityCell*)GetEntity(eid);
        if(pe)
        {
            pe->OnLoseClient();
        }

        return 0;
    }

    int CWorldCell::OnTimeMove(T_VECTOR_OBJECT* p)//每0.1秒进一次
    {   
            
        //LogDebug("CWorldCell::OnTimeMove", "m_spaces.size=%d", m_spaces.size());
        //CGetTimeOfDay time1;

        //int nMovedCount = 0;   //本次调用有多少entity移动了
        //map<TENTITYID, CEntityCell*>& entities = m_enMgr.Entities();
        //map<TENTITYID, CEntityCell*>::iterator iter = entities.begin();
        //for(; iter != entities.end(); ++iter)
        //{
        //    if(iter->second->OnMoveTick())
        //    {
        //        ++nMovedCount;
        //    }
        //}

        //int n1 = time1.GetLapsedTime();

        this->moveTimes++;

#ifdef __TEST
        time1.SetNowTime();
        this->movePackets++;
#endif

        if (this->moveTimes != 10)
        {
            return 0;
        }
        //LogDebug("CWorldCell::OnTimeMove", "m_spaces.size=%d", m_spaces.size());

        //触发进入aoi事件
        int nAoiEventCount = 0;
        map<TSPACEID, CSpace*>::iterator iter2 = m_spaces.begin();
        for(; iter2 != m_spaces.end(); ++iter2)
        {
            CSpace* sp = iter2->second;

            sp->AllEntitiesMove();
#ifdef __TEST
                //time1.SetNowTime();
#endif
                if(sp->IsAoiDirty())
                {
                    sp->AoiEvent();
                    ++nAoiEventCount;
                    sp->AllEntitiesCheckLeaveAoi();
                }

#ifdef __TEST
                //int cost = time1.GetLapsedTime();
                //LogDebug("CEntityCell::OnTimeMove", "cost=%d", cost);
#endif
        }

        this->moveTimes = 0;

#ifdef __TEST
        this->sumMoveCost += time1.GetLapsedTime();

        if ((this->movePackets % 100) == 0)
        {
            LogDebug("CWorldCell::OnTimeMove", "cost=%d;m_spaces.size=%d", this->sumMoveCost/100, m_spaces.size());
            this->sumMoveCost = 0;
        }
#endif

        //int n2 = time1.GetLapsedTime();

        ////触发离开aoi事件
        //int nAoiLeaveCheck = 0;
        //iter = entities.begin();
        //for(; iter != entities.end(); ++iter)
        //{
        //    if(iter->second->CheckLeaveAoi())
        //    {
        //        ++nAoiLeaveCheck;
        //    }
        //}

        //int n3 = time1.GetLapsedTime();

        //LogInfo("CWorldCell::on_time_move", "time=%d;moved=%d;aoi_event=%d;aoi_leave=%d;%d,%d,%d",
        //        time1.GetLapsedTime(), nMovedCount, nAoiEventCount, nAoiLeaveCheck,n1,n2,n3);

        return 0;
    }

    void CWorldCell::InitEntityCall()
    {
        world::InitEntityCall();

        //m_entityCalls.insert(make_pair("getSpaceId",  &CEntityParent::lGetSpaceId));
        ////m_entityCalls.insert(make_pair("teleport",    &CEntityParent::lTelePort));
        //m_entityCalls.insert(make_pair("setVisiable", &CEntityParent::lSetVisiable));


        m_entityCalls.insert(make_pair("getSpaceId",    &CEntityParent::lGetSpaceId));
        m_entityCalls.insert(make_pair("teleport",      &CEntityParent::lTelePort));
        m_entityCalls.insert(make_pair("setVisiable",   &CEntityParent::lSetVisiable));
        m_entityCalls.insert(make_pair("setSpeed",      &CEntityParent::lSetSpeed));
        m_entityCalls.insert(make_pair("getDistance",   &CEntityParent::lGetDistance));
        m_entityCalls.insert(make_pair("broadcastAOI",  &CEntityParent::lBroadcastAOI));
        m_entityCalls.insert(make_pair("getAOI",        &CEntityParent::lGetAOI));
        m_entityCalls.insert(make_pair("isInAOI",        &CEntityParent::lIsInAOI));
        m_entityCalls.insert(make_pair("ProcessMove", &CEntityParent::lProcessMove));
        m_entityCalls.insert(make_pair("ProcessPull", &CEntityParent::lProcessPull));
        m_entityCalls.insert(make_pair("StopMove", &CEntityParent::lStopMove));
        m_entityCalls.insert(make_pair("getXY", &CEntityParent::lGetXY));
        m_entityCalls.insert(make_pair("setXY", &CEntityParent::lSetXY));
        m_entityCalls.insert(make_pair("setFace", &CEntityParent::lSetFace));
        m_entityCalls.insert(make_pair("getFace", &CEntityParent::lGetFace));
        m_entityCalls.insert(make_pair("getPackFace", &CEntityParent::lGetPackFace));
        m_entityCalls.insert(make_pair("getMovePointStraight", &CEntityParent::lGetMovePointStraight));
        m_entityCalls.insert(make_pair("getNextEntityId", &CEntityParent::lGetNextEntityId));
        m_entityCalls.insert(make_pair("active", &CEntityParent::lActive));
        m_entityCalls.insert(make_pair("inActive", &CEntityParent::lInActive));
        m_entityCalls.insert(make_pair("addToSpace", &CEntityParent::lAddToSpace));
        m_entityCalls.insert(make_pair("delFromSpace", &CEntityParent::lDelFromSpace));
        m_entityCalls.insert(make_pair("updateEntityMove", &CEntityParent::lUpdateEntityMove));

    }

    int CWorldCell::SetCellVisiable(T_VECTOR_OBJECT* p)
    {
        if(p->size() != 2)
        {
            return -1;
        }

        TENTITYID eid = VOBJECT_GET_U32((*p)[0]);
        uint8_t n = VOBJECT_GET_U8((*p)[1]);
        CEntityCell* pe = (CEntityCell*)GetEntity(eid);
        if(pe)
        {
            pe->SetVisiable(n);
        }

        return 0;
    }

    bool CWorldCell::IsCanAcceptedClient(const string& strClientAddr)
    {
        return m_canAcceptedClients.find(strClientAddr) != m_canAcceptedClients.end();
    }

}

