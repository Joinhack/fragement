/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：entity_cell
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.5
// 模块描述：cell 进程， entity 封装
//----------------------------------------------------------------*/

#include "math.h"
#include "entity_cell.h"
#include "util.h"
#include "world_select.h"
#include "aoi.h"
#include "logger.h"
#include "defparser.h"


const static char* s_entity_enter_space = "onEnterSpace";    //entity进入Space时调用的脚本方法
const static char* s_entity_leave_space = "onLeaveSpace";    //entity离开Space时调用的脚本方法

namespace mogo
{

    /////////////////////////////////////////////////////////////////////////////////////////

    CEntityCell::CEntityCell(TENTITYTYPE etype, TENTITYID nid)
        : CEntityParent(etype, nid), m_spaceId(0), m_nBaseSvrId(0), 
        m_lsPosPairs(NULL), m_bMoved(false), m_bAfterMoveNotifyLua(false), m_bBroadcast(false)

#ifdef __TEST
        , movePackets(0), sumMoveCost(0)
#endif

#ifdef __SPEED_CHECK
        , m_nLastMoveTime(0)
#endif // __SPEED_CHECK


    {
        //cout << "CEntityCell::CEntityCell" << nid << endl;
        m_bIsBase = false;
        m_pos[0] = 0;
        m_pos[1] = 0;

#ifdef __FACE
        face = 0;             //朝向统一为0，待修改
#endif

        m_nSpeed = 60;        //先假定一个数值,待修改,todo

        //初始化时玩家的上一次移动时间为当前时间
        CGetTimeOfDay time1;
        this->lastMoveTime = time1.GetLapsedTime();

        //玩家的移动不良记录次数初始化为0
        this->badMoveTimes = 0;
    }

    void ClearPosPairList(list<std::pair<int16_t, int16_t>*>* ls)
    {
        if(ls)
        {
            ClearContainer(*ls);
            delete ls;
        }
    }

    CEntityCell::~CEntityCell()
    {
        ClearPosPairList(m_lsPosPairs);
    }

    //清除路点
    void CEntityCell::ClearPosPairs()
    {
        ClearPosPairList(m_lsPosPairs);
        m_lsPosPairs = NULL;
    }

    int CEntityCell::init(lua_State* L)
    {
        CEntityParent::init(L);

        //初始化在def定义的属性字段
        const SEntityDef* pDef = this->GetEntityDef();
        if(pDef)
        {
            map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.begin();
            for(; iter != pDef->m_properties.end(); ++iter)
            {
                const _SEntityDefProperties* pp = iter->second;
                if(IsCellFlag(pp->m_nFlags))
                {
                    VOBJECT* v = new VOBJECT;
                    v->vt = pp->m_nType;
                    FillVObjectDefaultValue(this, iter->first, *v, pp->m_defaultValue);
                    m_data.insert(make_pair(iter->first, v));
                }
            }
        }

        return 0;
    }

    int CEntityCell::lGetSpaceId(lua_State* L)
    {
        //LogDebug("CEntityCell::lGetSpaceId", "m_spaceId=%d", m_spaceId);
        lua_pushinteger(L, m_spaceId);
        return 1;
    }

    //记录base的mailbox
    void CEntityCell::AddBaseMailbox(int32_t n, uint16_t nBaseSrvId)
    {
        VOBJECT* v = new VOBJECT;
        v->vt = V_LUATABLE;
        v->vv.i32 = n;
        m_data.insert(make_pair("base", v) );

        m_nBaseSvrId = nBaseSrvId;
    }

    uint16_t CEntityCell::GetMailboxId()
    {
        return GetWorld()->GetMailboxId();
    }


    //将带client标记的属性打包至pluto,注意:CEntityBase有一个类似的同名方法
    void CEntityCell::PickleClientToPluto(CPluto& u)
    {
        //这个entity必须至少有一个client可见的cell属性
        const SEntityDef* pDef = this->GetEntityDef();
        //if(pDef && pDef->m_bHasCellClient)
        if(pDef)
        {
#ifdef __FACE
            u << m_id << face << m_pos[0] << m_pos[1];
#else
            u << m_id << m_pos[0] << m_pos[1];
#endif

            //打包这个entity的所有client可见的cell属性
            map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.begin();
            for(; iter != pDef->m_properties.end(); ++iter)
            {
                _SEntityDefProperties* p = iter->second;
                if(IsClientFlag(p->m_nFlags))
                {
                    const string& strEntityName = iter->first;
                    map<string, VOBJECT*>::const_iterator iter2 = m_data.find(strEntityName);
                    if(iter2 == m_data.end())
                    {
                        //todo warning...
                        continue;
                    }

                    uint16_t attr_id = (uint16_t)(pDef->m_propertiesMap.GetIntByStr(iter2->first));

                    //LogDebug("CEntityCell::PickleClientToPluto", "attr_id=%d;first=%s", attr_id, iter2->first.c_str());

                    u << attr_id;
                    u.FillPluto(*(iter2->second));
                }
            }
        }
    }

    //将带other_clients标记的属性打包至pluto
    void CEntityCell::PickleOtherClientToPluto(CPluto& u)
    {
        //这个entity必须至少有一个client可见的cell属性
        const SEntityDef* pDef = this->GetEntityDef();
        //if(pDef && pDef->m_bHasCellClient)
        if(pDef)
        {

#ifdef __FACE
            u << m_etype << m_id << face << m_pos[0] << m_pos[1];
#else
            u << m_etype << m_id << m_pos[0] << m_pos[1];
#endif

            //打包这个entity的所有client可见的cell属性
            map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.begin();
            for(; iter != pDef->m_properties.end(); ++iter)
            {
                _SEntityDefProperties* p = iter->second;
                if(IsOtherClientsFlag(p->m_nFlags))
                {
                    const string& strEntityName = iter->first;
                    map<string, VOBJECT*>::const_iterator iter2 = m_data.find(strEntityName);
                    if(iter2 == m_data.end())
                    {
                        //todo warning...
                        continue;
                    }

                    u << (uint16_t)(pDef->m_propertiesMap.GetIntByStr(iter2->first));
                    u.FillPluto(*(iter2->second));
                }
            }
        }
    }

    //将带cell标记的属性打包至pluto
    void CEntityCell::PickleCellToPluto(CPluto& u1)
    {
        CPluto u;
        const SEntityDef* pDef = this->GetEntityDef();
        if (pDef)
        {
            map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.begin();
            for(; iter != pDef->m_properties.end(); ++iter)
            {
                _SEntityDefProperties* p = iter->second;
                //只有设置了cell而且没设base，而且设置了CellShare为TRUE的属性才会打包
                if(IsCellFlag(p->m_nFlags) && !IsBaseFlag(p->m_nFlags) && p->m_bCellData)
                {
                    const string& strEntityName = iter->first;
                    map<string, VOBJECT*>::const_iterator iter2 = m_data.find(strEntityName);
                    if(iter2 == m_data.end())
                    {
                        //todo warning...
                        continue;
                    }

                    LogDebug("CEntityCell::PickleCellToPluto", "strPropName=%s", iter2->first.c_str());

                    u << (uint16_t)(pDef->m_propertiesMap.GetIntByStr(iter2->first));
                    u.FillPluto(*(iter2->second));
                }
            }
        }

        charArrayDummy ad;
        ad.m_l = u.GetLen();
        ad.m_s = (char*)u.GetBuff();
        u1 << ad;
        ad.m_l = 0;
    }

    CSpace* CEntityCell::GetMySpace()
    {
#ifdef _WIN32
        return NULL;
#else
        return GetWorldcell().GetSpace(m_spaceId);
#endif
    }

    //打包aoi内所有entities
    void CEntityCell::PickleAoiEntities(CPluto& u)
    {
        m_bHasClient = true;            //获得client

        LogDebug("CEntityCell::PickleAoiEntities", "md_id=%d", m_id);

        //在space范围内查找,不需要在world范围内查找
        CSpace* sp = GetMySpace();
        if(sp)
        {
            uint32_t idx1 = u.GetLen();
            u << (uint16_t)0;            //长度占位

            u << m_etype;                //类型

            u << m_id;                   //唯一ID

#ifdef __FACE
            u << face;                    //本entity的朝向
#endif

            u << m_pos[0] << m_pos[1];    //本entity的坐标

            uint32_t index1 = 0;
            uint32_t index2 = 0;

#ifdef __AOI_PRUNING
            set<TENTITYID>::iterator iter = m_observers.begin();
            for(; iter != m_observers.end(); ++iter)
#else
            set<TENTITYID>::iterator iter = m_entitiesIds.begin();
            for(; iter != m_entitiesIds.end(); ++iter)
#endif

            {
                index1 = u.GetLen();
                u << (uint16_t)0;

                CEntityCell* p2 = sp->GetEntity(*iter);
                if(p2)
                {
                    p2->PickleOtherClientToPluto(u);
                }

                index2 = u.GetLen();
                u.ReplaceField<uint16_t>(index1, index2 - index1 - 2);

            }

            uint32_t idx2 = u.GetLen();
            u.ReplaceField<uint16_t>(idx1, idx2-idx1-2);
            u << EndPluto;
        }
    }

    void CEntityCell::OnLoseClient()
    {
        m_bHasClient = false;    //cell失去client
        LogDebug("CEntityCell::OnLoseClient", "eid=%d", m_id);
    }

    //获取base的server_id
    int CEntityCell::GetBaseServerId()
    {
        if(m_nBaseSvrId == 0)
        {
            return -2;
        }

        return m_nBaseSvrId;

        //map<string, VOBJECT*>::const_iterator iter = m_data.find("base");
        //if(iter == m_data.end())
        //{
        //    return -2;
        //}

        //int nRef = iter->second->vv.i32;
        //world* the_world = GetWorld();
        //lua_State* L = the_world->GetLuaState();
        //int m = the_world->GetLuaTables().Getobj(L, nRef);

        //lua_rawGeti(L, -1, g_nMailBoxServerIdKey);

        //if(lua_isnumber(L, -1))
        //{
        //    int nServerId = (int)lua_tonumber(L, -1);
        //    lua_pop(L, m + 1);
        //    return nServerId;
        //}

        //lua_pop(L, m + 1);
        //return -3;
    }

    //同步带base标记的属性
    void CEntityCell::SyncBaseAndCellProp(int32_t nPropId, const VOBJECT& v)
    {
        int nCellId = GetBaseServerId();
        if(nCellId > 0)
        {
            CMailBox* mb = GetWorld()->GetServerMailbox(nCellId);
            if(mb)
            {
                CPluto* u =  new CPluto;
                (*u).Encode(MSGID_BASEAPP_ENTITY_ATTRI_SYNC) << m_id << m_etype << (uint16_t)nPropId;
                u->FillPluto(v);
                (*u) << EndPluto;

                LogDebug("CEntityCell::SyncBaseAndCellProp", "u->GetLen()=%d;", u->GetLen());

                mb->PushPluto(u);
            }
        }
    }

    void CEntityCell::SyncClientProp(int32_t nPropId, const VOBJECT& v)
    {
        if(!m_bHasClient)
        {
            return;
        }

        int nBaseId = GetBaseServerId();
        if(nBaseId < 0)
        {
            return;
        }

        CMailBox* mb = GetWorld()->GetServerMailbox(nBaseId);
        if(mb)
        {
            CPluto* u = new CPluto;
            (*u).Encode(MSGID_BASEAPP_CELL_ATTRI_SYNC) << (uint16_t)nPropId;
            u->FillPluto(v);
            (*u) << EndPluto;

            //LogDebug("CEntityCell::SyncClientProp", "u->GetLen()=%d;", u->GetLen());

            mb->PushPluto(u);
        }
    }

    int CEntityCell::lTelePort(lua_State* L)
    {
        //param 1 is userdata

        //停止行走
        this->ClearPosPairs();

        int n = lua_gettop(L);
        //LogDebug("CEntityCell::lTelePort", "n=%d", n);
        if(n > 3)
        {
            //同cell内不同场景teleport
            TSPACEID space_id = (TSPACEID)luaL_checkinteger(L, 2);
            position_t x = (position_t)luaL_checkinteger(L, 3);
            position_t y = (position_t)luaL_checkinteger(L, 4);

            //先离开当前场景
            CWorldCell& world = GetWorldcell();
            CSpace* sp1 = world.GetSpace(m_spaceId);
            if(sp1)
            {
                sp1->DelEntity(this);
            }

            EntityMethodCall(L, this, s_entity_leave_space, 0, 0);
            ClearLuaStack(L);

            //进入新的场景

            //LogDebug("CEntityCell::lTelePort", "space_id=%d", space_id);
            CSpace* sp2 = world.GetSpace(space_id);
            if(sp2)
            {
                //同步坐标给自己的客户端
#ifdef __FACE
                this->SendOtherEntityPos(NULL, m_id, face, x, y, 
                                         MSGID_CLIENT_ENTITY_POS_TELEPORT, MSGID_CLIENT_OTHER_ENTITY_TELEPORT);
#else
                this->SendOtherEntityPos(NULL, m_id, x, y, 0,
                    MSGID_CLIENT_ENTITY_POS_TELEPORT, MSGID_CLIENT_OTHER_ENTITY_TELEPORT);
#endif
                sp2->AddEntity(x, y, this);
            }

            EntityMethodCall(L, this, s_entity_enter_space, 0, 0);
            ClearLuaStack(L);
        }
        else
        {
            position_t x = (position_t)luaL_checkinteger(L, 2);
            position_t y = (position_t)luaL_checkinteger(L, 3);

            //本场景teleport,self:teleport(x,y)
            CSpace* sp = GetMySpace();
            if(sp)
            {
                //同步坐标给自己的客户端
#ifdef __FACE
                this->SendOtherEntityPos(NULL, m_id, face, x, y, 
                                         MSGID_CLIENT_ENTITY_POS_TELEPORT, MSGID_CLIENT_OTHER_ENTITY_TELEPORT);
#else
                this->SendOtherEntityPos(NULL, m_id, x, y, 0,
                    MSGID_CLIENT_ENTITY_POS_TELEPORT, MSGID_CLIENT_OTHER_ENTITY_TELEPORT);
#endif

                sp->TelePortLocally(this, x, y);

                CPluto* u = NULL;
                CEntityCell* p2 = NULL;
                CPluto* u2 = NULL;

#ifdef __AOI_PRUNING
                set<TENTITYID>::iterator iter = m_followers.begin();
                for(; iter != m_followers.end(); ++iter)
#else
                set<TENTITYID>::iterator iter = m_entitiesIds.begin();
                for(; iter != m_entitiesIds.end(); ++iter)
#endif

                {
                    CEntityCell* p2 = sp->GetEntity(*iter);
                    if(p2)
                    {
#ifdef __FACE
                        u2 = p2->SendOtherEntityPos(u, m_id, face, this->m_pos[0], this->m_pos[1],
                            MSGID_CLIENT_ENTITY_POS_TELEPORT, MSGID_CLIENT_OTHER_ENTITY_TELEPORT);
#else
                        u2 = p2->SendOtherEntityPos(u, m_id, this->m_pos[0], this->m_pos[1], 0,
                            MSGID_CLIENT_ENTITY_POS_TELEPORT, MSGID_CLIENT_OTHER_ENTITY_TELEPORT);
#endif
                        if(u2)
                        {
                            u = u2;
                        }
                    }
                }

            }
        }

        return 0;
    }

    int CEntityCell::lSetVisiable(lua_State* L)
    {
        //param 1 is userdata
        uint8_t nVisiable = (uint8_t)luaL_checkint(L, 2);
        //LogDebug("CEntityCell::lSetVisiable", "id=%d;nVisiable=%d", this->GetId(), nVisiable);
        SetVisiable(nVisiable);

        return 0;
    }

    int CEntityCell::lSetSpeed(lua_State* L)
    {
        //param 1 is userdata
        uint16_t nSpeed = (uint16_t)luaL_checkint(L, 2);

        //LogDebug("CEntityCell::lSetSpeed", "nSpeed=%d", nSpeed);

        this->m_nSpeed = nSpeed;

        return 0;
    }

    int CEntityCell::lBroadcastAOI(lua_State* L)
    {
        //param 1 is userdata
        if (lua_type(L, 2) != LUA_TBOOLEAN)
        {
            lua_pushfstring(L, "CEntityCell::lBroadcastAOI Arg1 need boolean type(now is %s)", lua_typename(L, lua_type(L, 2)));
            lua_error(L);
            return 0;
        }

        bool bIncludeSelf   = (lua_toboolean(L, 2) != 0);
        string strFunc      = luaL_checkstring(L, 3);
        lua_remove(L, 1);
        lua_remove(L, 1);
        lua_remove(L, 1);

        CEntityMailbox entity_mb;
        world* pWorld = GetWorld();

#ifdef __AOI_PRUNING
        for (auto iter = m_followers.begin(); iter != m_followers.end(); iter++)
#else
        for (auto iter = m_entitiesIds.begin(); iter != m_entitiesIds.end(); iter++)
#endif

        {
            CEntityCell* pEntity = dynamic_cast< CEntityCell* >(pWorld->GetEntity(*iter));
            if (pEntity && pEntity->HasClient())
            {
                entity_mb                       = pEntity->GetMyMailbox();
                entity_mb.m_nServerMailboxId    = pEntity->m_nBaseSvrId;
                pWorld->RpcCallToClientViaBase(strFunc.c_str(), entity_mb, L);
            }
        }
        if (bIncludeSelf && HasClient())
        {
            entity_mb                       = GetMyMailbox();
            entity_mb.m_nServerMailboxId    = m_nBaseSvrId;
            pWorld->RpcCallToClientViaBase(strFunc.c_str(), entity_mb, L);
        }

        ClearLuaStack(L);
        return 0;
    }

    int CEntityCell::lGetAOI(lua_State* L)
    {
        //param 1 is userdata
        double radius = luaL_checknumber(L, 2);

        lua_newtable(L);
        world* pWorld = GetWorld();

#ifdef __AOI_PRUNING
        for (auto iter = m_observers.begin(); iter != m_observers.end(); iter++)
#else
        for (auto iter = m_entitiesIds.begin(); iter != m_entitiesIds.end(); iter++)
#endif

        {
            CEntityCell* pEntity = dynamic_cast< CEntityCell* >(pWorld->GetEntity(*iter));
            if (pEntity)
            {
                if (radius > 0)
                {
                    float dis = Point2PointDistance(m_pos[0], m_pos[1], pEntity->m_pos[0], pEntity->m_pos[1]);
                    if (radius < dis) continue;
                }
                lua_pushnumber(L, *iter);
                luaL_getmetatable(L, g_szUserDataEntity);
                lua_pushlightuserdata(L, pEntity);
                lua_rawget(L, -2);
                lua_remove(L, -2);
                lua_settable(L, -3);
            }
        }
        return 1;
    }
	
	int CEntityCell::lIsInAOI(lua_State* L)
	{
		TENTITYID entity_id	= (TENTITYID)luaL_checkint(L, 2);
		bool bIsInAOI		= m_entitiesIds.find(entity_id) != m_entitiesIds.end();
        lua_pushboolean(L, (bIsInAOI ? 1 : 0));
		return 1;
	}

    int CEntityCell::lGetDistance(lua_State* L)
    {
        //param 1 is userdata
        TENTITYID entity_id = (TENTITYID)luaL_checkint(L, 2);
        if (m_id != entity_id)
        {
            CEntityCell* pEntity = dynamic_cast< CEntityCell* >(GetWorld()->GetEntity(entity_id));
            if (pEntity)
            {
                float dis = Point2PointDistance(m_pos[0], m_pos[1], pEntity->m_pos[0], pEntity->m_pos[1]);
                lua_pushnumber(L, dis);
            }
            else
            {
                lua_pushnumber(L, -1);
            }
        }
        else
        {
            lua_pushnumber(L, 0);
        }

        return 1;
    }

    int CEntityCell::lActive(lua_State* L)
    {
        CWorldCell& world = GetWorldcell();

        bool result = world.ActiveSpace(m_spaceId);
        if (result)
        {
            lua_pushboolean(L, 1);
        }
        else
        {
            lua_pushboolean(L, 0);
        }

        return 1;
    }

    int CEntityCell::lInActive(lua_State* L)
    {
        CWorldCell& world = GetWorldcell();

        bool result = world.InActiveSpace(m_spaceId);
        if (result)
        {
            lua_pushboolean(L, 1);
        }
        else
        {
            lua_pushboolean(L, 0);
        }

        return 1;
    }

    //把entity放进一个指定的space
    int CEntityCell::lAddToSpace(lua_State* L)
    {
        //param 1 is userdata

        int n = lua_gettop(L);
        if (n != 5)
        {
            lua_pushfstring(L, "CEntityCell::lAddToSpace;n=%d", n);
            lua_error(L);
            return 0;
        }

        TENTITYID nSpaceId = (TENTITYID)luaL_checkint(L, 2);

        CWorldCell& the_world = GetWorldcell();
        CSpace* sp = the_world.GetSpace(nSpaceId);
        if(sp == NULL)
        {
            lua_pushstring(L, "AddToSpace, space not exit");
            lua_error(L);
            return 0;
        }

        position_t x = (position_t)luaL_checkinteger(L, 3);
        position_t y = (position_t)luaL_checkinteger(L, 4);
        uint8_t visiable = (uint8_t)luaL_checkinteger(L, 5);

        lua_remove(L, 5);
        lua_remove(L, 4);
        lua_remove(L, 3);
        lua_remove(L, 2);  //移去visiable、space_id,x,y三个参数

        if (visiable == 0)
        {
            this->SetSpaceID(nSpaceId);
        }
        else
        {
            sp->AddEntity((position_t)x, (position_t)y, this);
        }

        EntityMethodCall(L, this, s_entity_enter_space, 0, 0);
        ClearLuaStack(L);

        lua_pushboolean(L, 1);

        return 1;
    }

    //把entity从一个指定的space拿出来
    int CEntityCell::lDelFromSpace(lua_State* L)
    {
        CWorldCell& world = GetWorldcell();

        CSpace* sp = world.GetSpace(m_spaceId);
        if(sp)
        {
            EntityMethodCall(L, this, s_entity_leave_space, 0, 0);
            ClearLuaStack(L);

            sp->DelEntity(this);
            lua_pushboolean(L, 1);
            return 1;
        }
        else
        {
            lua_pushstring(L, "DelFromSpace, space not exit");
            lua_error(L);
            return 0;
        }
    }

    //int CEntityCell::lGetEntities(lua_State* L)
    //{
    //    //param 1 is userdata
    //    float range = (float)luaL_checkint(L, 2);

    //    CSpace* sp = GetMySpace();
    //    if (sp)
    //    {
    //        set<TENTITYID>::iterator iter = m_entitiesIds.begin();
    //        for(; iter != m_entitiesIds.end(); ++iter)
    //        {
    //            CEntityCell* p = sp->GetEntity(*iter);
    //            float d = Point2PointDistance(m_pos[0], m_pos[1], p->m_pos[0], p->m_pos[1]);
    //            if (d <= range)
    //            {
    //            }
    //        }
    //    }

    //    return 0;
    //}

    void CEntityCell::SetVisiable(uint8_t nVisiable)
    {
        //停止行走
        this->ClearPosPairs();
        if(nVisiable==0)
        {
            //LogDebug("CEntityCell::SetVisiable", "id=%d;nVisiable=%d;m_pos[0]=%d;m_pos[1]=%d", 
            //                                      this->GetId(), nVisiable, m_pos[0], m_pos[1]);
            //设为隐藏,离开当前space,但还保留在cell里,space_id,x,y三个值都保留了
            CWorldCell& world = GetWorldcell();
            CSpace* sp1 = world.GetSpace(m_spaceId);
            if(sp1)
            {
                sp1->DelEntity(this);
            }
        }
        else
        {
            //LogDebug("CEntityCell::SetVisiable", "id=%d;nVisiable=%d", this->GetId(), nVisiable);
            //重新回到space
            CWorldCell& world = GetWorldcell();
            CSpace* sp1 = world.GetSpace(m_spaceId);
            if(sp1)
            {
                //同步坐标给自己的客户端
#ifdef __FACE
                this->SendOtherEntityPos(NULL, m_id, face, m_pos[0], m_pos[1], 
                    MSGID_CLIENT_ENTITY_POS_TELEPORT, MSGID_CLIENT_OTHER_ENTITY_TELEPORT);
#else
                this->SendOtherEntityPos(NULL, m_id, m_pos[0], m_pos[1], 0,
                    MSGID_CLIENT_ENTITY_POS_TELEPORT, MSGID_CLIENT_OTHER_ENTITY_TELEPORT);
#endif
                //LogDebug("CEntityCell::SetVisiable 1", "id=%d;nVisiable=%d;m_pos[0]=%d;m_pos[1]=%d",
                //                                        this->GetId(), nVisiable, m_pos[0], m_pos[1]);
                sp1->AddEntity(m_pos[0], m_pos[1], this);
            }
        }
    }

#ifdef __AOI_PRUNING
    bool CEntityCell::AddInFollowers(TENTITYID eid)
    {
        //uint16_t MaxFollowerCount = atoi(GetWorld()->GetCfgReader()->GetOptValue("params", "max_follower_count", "30").c_str());

        set<TENTITYID>::iterator iter = this->m_followers.find(eid);
        if ((this->m_followers.size() >= GetWorldcell().GetMaxFollowerCount()) || (iter != this->m_followers.end()))
        {
            return false;
        }
        this->m_followers.insert(iter, eid);
        return true;
    }

    bool CEntityCell::AddInObservers(TENTITYID eid)
    {
        set<TENTITYID>::iterator iter = this->m_observers.find(eid);

        //uint16_t MaxObserverCount = atoi(GetWorld()->GetCfgReader()->GetOptValue("params", "max_observer_count", "15").c_str());

        if ((this->m_observers.size() >= GetWorldcell().GetMaxObserverCount()) || (iter != this->m_observers.end()))
        {
            return false;
        }
        this->m_observers.insert(iter, eid);
        return true;
    }

    bool CEntityCell::IsObserversFull()
    {
        //uint16_t MaxObserverCount = atoi(GetWorld()->GetCfgReader()->GetOptValue("params", "max_observer_count", "15").c_str());

        return this->m_observers.size() >= GetWorldcell().GetMaxObserverCount();
    }

    bool CEntityCell::RemoveInFollower(TENTITYID eid)
    {
        set<TENTITYID>::iterator iter = this->m_followers.find(eid);
        if (iter != this->m_followers.end())
        {
            this->m_followers.erase(iter);
            return true;
        }
        return false;
    }
#endif


    //有新的entity进入aoi
    void CEntityCell::OnEnterAoi(CSpace* sp, TENTITYID eid)
    {
        //LogDebug("CEntityCell::OnEnterAoi", "eid=%d;m_id=%d", eid, this->m_id);
        CEntityCell* p2 = sp->GetEntity(eid);
        if(p2)
        {
            set<TENTITYID>::iterator iter = m_entitiesIds.lower_bound(eid);
            if(iter != m_entitiesIds.end() && *iter == eid)
            {
                //已经存在了
                //LogWarning("OnEnterAoi", "dup=%u", p2->GetId());
            }
            else
            {
                m_entitiesIds.insert(iter, eid);

#ifdef __AOI_PRUNING

                if (this->IsObserversFull())
                {
                    return;
                }

                if (!p2->AddInFollowers(m_id) || !this->AddInObservers(eid))
                {
                    //LogDebug("CEntityCell::OnEnterAoi False", "m_id=%d;eid=%d", m_id, eid);
                    return;
                }
#endif

                //enum {OBSERVER_SIZE = 15,};

                //if (m_entitiesIds.size() >= OBSERVER_SIZE)
                //{
                //    return;
                //}
                //else
                //{
                //    set<TENTITYID>::iterator iter1 = m_entitiesIds.find(eid);
                //    if (iter1 == m_entitiesIds.end())
                //    {
                //        m_entitiesIds.insert(iter1, eid);
                //    }
                //}

                //printf("OnEnterAoi, %u(%u,%u) ==> %u(%u,%u)\n", m_id, m_pos[0], m_pos[1],
                //    p2->GetId(), p2->m_pos[0], p2->m_pos[1]);
                //}
                //
                ////不管aoi消息是否重复,再发一次
                //{
                if(m_bHasClient)
                {
                    //如果有客户端,将新进入entity的other_CLIENTS属性发给客户端
                    int nBaseId = GetBaseServerId();
                    if(nBaseId > 0)
                    {
                        CMailBox* mb = GetWorld()->GetServerMailbox(nBaseId);
                        if(mb)
                        {
                            //新进入entity的属性
                            CPluto* u = new CPluto;
                            CPluto& uu = *u;
                            uu.Encode(MSGID_BASEAPP_CLIENT_MSG_VIA_BASE) << m_id << (uint16_t)MSGID_CLIENT_AOI_NEW_ENTITY;

                            uint32_t idx1 = uu.GetLen();
                            uu << (uint16_t)0;                                    //长度占位

                            p2->PickleOtherClientToPluto(uu);                //打包数据

                            uint32_t idx2 = uu.GetLen();
                            uu.ReplaceField<uint16_t>(idx1, idx2-idx1-2);        //替换为真正的长度
                            uu << EndPluto;

                            //LogDebug("CEntityCell::OnEnterAoi", "m_id=%d;eid=%d;u->GetLen()=%d;", m_id, eid, u->GetLen());

                            mb->PushPluto(u);


                            ////新进入entity的路点信息
                            //if(p2->GetLeftPosPairs())
                            //{
                            //    SendOtherClientMoveReq(NULL, p2->GetId(), *(p2->GetLeftPosPairs()) );
                            //}
                        }
                    }

                }
            }
        }

    }

    //如果有客户端则获取并返回base的mailbox
    CMailBox* CEntityCell::GetBaseMailboxIfClient()
    {
        if(!m_bHasClient)
        {
            return NULL;
        }

        int nBaseId = GetBaseServerId();
        if(nBaseId <= 0)
        {
            return NULL;
        }

        CMailBox* mb = GetWorld()->GetServerMailbox(nBaseId);
        return mb;
    }


    ////客户端移动请求
    //void CEntityCell::OnClientMoveReq(list<pair<int16_t, int16_t>*>* lsPosPairs)
    //{
    //    //保存路点坐标,在tick消息里处理
    //    ClearPosPairList(m_lsPosPairs);
    //    m_lsPosPairs = lsPosPairs;

    //    ////同步给aoi范围内其他玩家
    //    //CSpace* sp = GetMySpace();
    //    //if(sp)
    //    //{
    //    //    CPluto* u = NULL;
    //    //    set<TENTITYID>::iterator iter = m_entitiesIds.begin();
    //    //    for(; iter != m_entitiesIds.end(); ++iter)
    //    //    {
    //    //        CEntityCell* p2 = sp->GetEntity(*iter);
    //    //        if(p2)
    //    //        {
    //    //            CPluto* u2 = p2->SendOtherClientMoveReq(u, m_id, *lsPosPairs);
    //    //            if(u2 != NULL)
    //    //            {
    //    //                u = u2;
    //    //            }
    //    //        }
    //    //    }
    //    //}

    //}
#ifdef __FACE
    void CEntityCell::OnClientMoveReq(uint8_t _face, int16_t x, int16_t y)
#else
    void CEntityCell::OnClientMoveReq(int16_t x, int16_t y)
#endif
    {
        ////当前坐标
        //int16_t x1 = m_pos[0];
        //int16_t y1 = m_pos[1];

        //int16_t dx = x - m_pos[0];
        //int16_t dy = y - m_pos[1];

        //float df = (abs(dx) + abs(dy)) * 0.8;
        //float df = sqrt(dx*dx + dy*dy);

        //CWorldCell& world = GetWorldcell();

        //if (((time1.GetLapsedTime() - this->lastMoveTime) * this->m_nSpeed) * 2 < df)
        //{
        //    LogWarning("CEntityCell::OnClientMoveReq", "m_id=%d;x=%d;y=%d", m_id, x, y);

        //    //速度过快，记录不良移动次数，当次数超过一定限制时，服务器告诉客户端驳回    todo...
        //    //CMailBox* mb = GetBaseMailboxIfClient();
        //    //CPluto *u = new CPluto;

        //    //u->Encode(MSGID_BASEAPP_AVATAR_POS_SYNC) << m_id << x << y << EndPluto;

        //    //mb->PushPluto(u);

        //    return;


        //}


#ifdef __SPEED_CHECK

        
        struct timeval tv;
        if (gettimeofday(&tv, NULL) == 0)
        {
            uint32_t Now = tv.tv_usec / 1000;
            if (this->m_nLastMoveTime != 0 && Now > this->m_nLastMoveTime)
            {
                uint32_t TimeDis = Now - this->m_nLastMoveTime;

                float dis = Point2PointDistance(m_pos[0], m_pos[1], x, y);
                //LogDebug("CEntityCell::OnClientMoveReq", "m_id=%d;m_pos[0]=%d;m_pos[1]=%d;x=%d;y=%d;dis=%f;TimeDis=%d",
                //                                          m_id, m_pos[0], m_pos[1], x, y, dis, TimeDis);
                //m_nSpeed是以秒速度，计算的时候转换成毫秒速度
                if (!CheckSpeed(this->m_nSpeed * 1000, TimeDis, dis))
                {
                    //数度校验演不通过，则把客户端拉回原来的坐标点
                    CSpace* sp = GetMySpace();
                    if(sp)
                    {

                        //同步坐标给自己的客户端
                        this->SendOtherEntityPos(NULL, m_id, m_pos[0], m_pos[1], 0,
                            MSGID_CLIENT_ENTITY_POS_TELEPORT, MSGID_CLIENT_OTHER_ENTITY_TELEPORT);

                        sp->TelePortLocally(this, m_pos[0], m_pos[1]);

                        LogWarning("CEntityCell::OnClientMoveReq error", "m_id=%d;m_pos[0]=%d;m_pos[1]=%d;x=%d;y=%d;speed=%d;time_dif=%d;dis=%f",
                                                                          m_id, m_pos[0], m_pos[1], x, y, this->m_nSpeed, TimeDis, dis);
                    }

                    return;
                }
                else
                {
                    this->m_nLastMoveTime = Now;
                }
            }
            else
            {
                this->m_nLastMoveTime = Now;
            }
        }


#endif


        if (m_pos[0] != x || m_pos[1] != y)
        {
            m_bBroadcast = true;
        }

        m_pos[0] = x;
        m_pos[1] = y;

#ifdef __FACE
        face = _face;
#endif

        //this->BroadcastPos();


        return;
    }

    bool CEntityCell::BroadcastPos()
    {
        if (!m_bBroadcast)
        {
            return false;
        }

        m_bBroadcast = false;

        //同步坐标给aoi范围内其他玩家

        CSpace* sp = GetMySpace();
        if(sp)
        {
            CPluto* u = NULL;
            CEntityCell* p2 = NULL;
            CPluto* u2 = NULL;

#ifdef __AOI_PRUNING
            set<TENTITYID>::iterator iter = m_followers.begin();
            for(; iter != m_followers.end(); ++iter)
#else
            set<TENTITYID>::iterator iter = m_entitiesIds.begin();
            for(; iter != m_entitiesIds.end(); ++iter)
#endif

            {
                p2 = sp->GetEntity(*iter);
                if(p2)
                {

#ifdef __FACE
                    u2 = p2->SendOtherEntityPos(u, m_id, face, this->m_pos[0], this->m_pos[1], 
                        MSGID_CLIENT_ENTITY_POS_SYNC, MSGID_CLIENT_OTHER_ENTITY_POS_SYNC);
#else
                    u2 = p2->SendOtherEntityPos(u, m_id, this->m_pos[0], this->m_pos[1], 0,
                        MSGID_CLIENT_ENTITY_POS_SYNC, MSGID_CLIENT_OTHER_ENTITY_POS_SYNC);
#endif

                    if(u2)
                    {
                        u = u2;
                    }
                }
            }

            //刷新自己的坐标给aoi管理器
            sp->OnPosMove(this);
        }

        CMailBox* mb = GetBaseMailboxIfClient();
        if (mb)
        {
            CPluto *u = new CPluto;
#ifdef __FACE
            u->Encode(MSGID_BASEAPP_AVATAR_POS_SYNC) << (uint16_t)MSGID_CLIENT_ENTITY_POS_SYNC << m_id << face << this->m_pos[0] << this->m_pos[1] << (uint8_t)0 << EndPluto;
#else
            u->Encode(MSGID_BASEAPP_AVATAR_POS_SYNC) << (uint16_t)MSGID_CLIENT_ENTITY_POS_SYNC << m_id << this->m_pos[0] << this->m_pos[1] << (uint8_t)0 << EndPluto;
#endif

            mb->PushPluto(u);
        }

        CWorldCell& world = GetWorldcell();
        lua_State* L = world.GetLuaState();
        int nRet = EntityMethodCall(L, this, "AvatarMove", 0, 0);
        lua_pop(L, nRet);

        return true;

    }

    //将某个客户端的移动请求转发给aoi内其他玩家
    CPluto* CEntityCell::SendOtherClientMoveReq(CPluto* u, TENTITYID eid, list<std::pair<uint16_t, uint16_t>*>& lsPosPairs)
    {
        CMailBox* mb = GetBaseMailboxIfClient();
        if(mb == NULL)
        {
            return NULL;
        }

        if(u == NULL)
        {
            //第一个打包,其他的复制
            u = new CPluto;
            u->Encode(MSGID_BASEAPP_CLIENT_MSG_VIA_BASE) << m_id << (uint16_t)MSGID_CLIENT_OTHER_ENTITY_MOVE_REQ;

            CPluto& uu = *u;
            uint32_t idx1 = uu.GetLen();
            uu << (uint16_t)0;                //长度占位

            //输入数据
            uu << eid;
            list<pair<uint16_t, uint16_t>*>::const_iterator iter2 = lsPosPairs.begin();
            for(; iter2 != lsPosPairs.end(); ++iter2)
            {
                uu << (*iter2)->first << (*iter2)->second;
            }

            uint32_t idx2 = uu.GetLen();
            uu.ReplaceField<uint16_t>(idx1, idx2-idx1-2);
            uu << EndPluto;

            LogDebug("CEntityCell::SendOtherClientMoveReq 1", "u->GetLen()=%d;", u->GetLen());

            mb->PushPluto(u);

            return u;
        }
        else
        {
            CPluto* u2 = new CPluto(u->GetBuff(), u->GetLen());
            u2->ReplaceField<uint32_t>(8, m_id);

            LogDebug("CEntityCell::SendOtherClientMoveReq 2", "u->GetLen()=%d;", u->GetLen());

            mb->PushPluto(u2);

            return NULL;
        }

        return NULL;
    }

    inline void FormatPos(float x, int16_t& x2)
    {
        if(x < 0.0f)
        {
            x2 = 0;
        }
        else
        {
            x2 = (int16_t)x;
        }
    }

    float _move(int16_t x1, int16_t y1, int16_t x2, int16_t y2, float speed, int16_t& x3, int16_t& y3)
    {
        int32_t dx = (int32_t)x2 - (int32_t)x1;
        int32_t dy = (int32_t)y2 - (int32_t)y1;

        int32_t d = dx*dx + dy*dy;
        float speed_square = speed * speed;
        if(speed_square > d)
        {
            //速度大于间隔距离,还需要走下一个路点
            x3 = x2;
            y3 = y2;
            return speed - sqrt((float)d);
        }

        float sloop = sqrt((float)d);
        //FormatPos(x1 + (dx/sloop)*speed, x3);kevin modified
        //FormatPos(y1 + (dy/sloop)*speed, y3);kevin modified
        x3 = x1 + (dx/sloop)*speed;
        y3 = y1 + (dy/sloop)*speed;

        return 0.0f;
    }

    int CEntityCell::lGetXY(lua_State* L)
    {
        lua_pushinteger(L,  m_pos[0]);
        lua_pushinteger(L,  m_pos[1]);
        
        return 2;    
    }

    int CEntityCell::lSetXY(lua_State* L)
    {
        int n = lua_gettop(L); 
        if (n < 2)
        {
            return 0;
        }

        position_t newX = (position_t)luaL_checkint(L, 2);
        position_t newY = (position_t)luaL_checkint(L, 3);

        if(newX != m_pos[0] || newY != m_pos[1])
        {
            //前后两次的坐标不一致，则有移动，需要走aoi广播坐标
            this->m_bBroadcast = true;
        }

        m_pos[0] = newX;
        m_pos[1] = newY;

        return lGetXY(L);
    }

    int CEntityCell::lUpdateEntityMove(lua_State* L)
    {
        int n = lua_gettop(L);                            
        if (n < 2)                                        
        {                                                 
            return 0;                                     
        }                                                 
                                                  
        position_t tarX = (position_t)luaL_checkint(L, 2);
        position_t tarY = (position_t)luaL_checkint(L, 3); 
//        int needSync = (int)luaL_checkint(L, 4);

        int16_t x1 = m_pos[0];
        int16_t y1 = m_pos[1];

        int16_t x3;
        int16_t y3;

        float speed = (float)m_nSpeed;
        speed = _move(x1, y1, tarX, tarY, speed, x3, y3);
        
        m_pos[0] = x3;
        m_pos[1] = y3;
/*
        if (needSync == 1 || speed > 0)
        {

            CSpace* sp = GetMySpace();
            if(sp)
            {
                CPluto* u = NULL;
    
    #ifdef __AOI_PRUNING
                set<TENTITYID>::iterator iter = m_followers.begin();
                for(; iter != m_followers.end(); ++iter)
    #else
                set<TENTITYID>::iterator iter = m_entitiesIds.begin();
                for(; iter != m_entitiesIds.end(); ++iter)
    #endif
        
                {
                    CEntityCell* p2 = sp->GetEntity(*iter);
                    if(p2)
                    {
    #ifdef __FACE
                        CPluto* u2 = p2->SendOtherEntityPos(u, m_id, face, m_pos[0], m_pos[1],
                            //                                                        MSGID_CLIENT_ENTITY_POS_PULL, MSGID_CLIENT_OTHER_ENTITY_POS_PULL);
                            //                                                        MSGID_CLIENT_ENTITY_POS_TELEPORT, MSGID_CLIENT_OTHER_ENTITY_TELEPORT);
                            MSGID_CLIENT_ENTITY_POS_SYNC, MSGID_CLIENT_OTHER_ENTITY_POS_SYNC);
    #else
                        CPluto* u2 = p2->SendOtherEntityPos(u, m_id, m_pos[0], m_pos[1], 1,
                            //                                                        MSGID_CLIENT_ENTITY_POS_PULL, MSGID_CLIENT_OTHER_ENTITY_POS_PULL);
                            //                                                        MSGID_CLIENT_ENTITY_POS_TELEPORT, MSGID_CLIENT_OTHER_ENTITY_TELEPORT);
                            MSGID_CLIENT_ENTITY_POS_SYNC, MSGID_CLIENT_OTHER_ENTITY_POS_SYNC);
    #endif
    
    
                        if(u2 != NULL)
                        {
                            u = u2;
                        }
                    }
                }
            }
        }
*/
        if (speed > 0.0f)
        {
            //走完了
            lua_pushinteger(L,  0);                    
        }   
        else
        {
            //还没走到目标坐标
            lua_pushinteger(L,  1);
        }        

        return 1;

    }

    int CEntityCell::lGetFace(lua_State* L)
    {
        lua_pushinteger(L,  face * 2);
        return 1;
    }
	
    int CEntityCell::lGetPackFace(lua_State* L)
	{
        lua_pushinteger(L,  face);
        return 1;
	}

    int CEntityCell::lSetFace(lua_State* L)
    {
        int n = lua_gettop(L); 
        if (n < 1) return 0;

        int tmpFace = luaL_checkint(L, 2);

        face = tmpFace*0.5f;

        return 0;

        //face = 0;
        int needSync = 1;
        if (!needSync)
        {
             return 0;
        }
        //printf("实际同步face:%d\n", face);
        //同步坐标给AOI内其他玩家 kevinhua add20130425
        CSpace* sp = GetMySpace();
        if(sp)
        {
            CPluto* u = NULL;

#ifdef __AOI_PRUNING
            set<TENTITYID>::iterator iter = m_followers.begin();
            for(; iter != m_followers.end(); ++iter)
#else
            set<TENTITYID>::iterator iter = m_entitiesIds.begin();
            for(; iter != m_entitiesIds.end(); ++iter)
#endif

            {
                CEntityCell* p2 = sp->GetEntity(*iter);
                if(p2)
                {
                    //printf("monster m_id:%d %d %d %d\n", m_id, face, m_pos[0], m_pos[1]);
#ifdef __FACE
                    CPluto* u2 = p2->SendOtherEntityPos(u, m_id, face, m_pos[0], m_pos[1],
                        //                                                        MSGID_CLIENT_ENTITY_POS_PULL, MSGID_CLIENT_OTHER_ENTITY_POS_PULL);
                        //                                                        MSGID_CLIENT_ENTITY_POS_TELEPORT, MSGID_CLIENT_OTHER_ENTITY_TELEPORT);
                        MSGID_CLIENT_ENTITY_POS_SYNC, MSGID_CLIENT_OTHER_ENTITY_POS_SYNC);
#else
                    CPluto* u2 = p2->SendOtherEntityPos(u, m_id, m_pos[0], m_pos[1], 0,
                        //                                                        MSGID_CLIENT_ENTITY_POS_PULL, MSGID_CLIENT_OTHER_ENTITY_POS_PULL);
                        //                                                        MSGID_CLIENT_ENTITY_POS_TELEPORT, MSGID_CLIENT_OTHER_ENTITY_TELEPORT);
                        MSGID_CLIENT_ENTITY_POS_SYNC, MSGID_CLIENT_OTHER_ENTITY_POS_SYNC);
#endif


                    if(u2 != NULL)
                    {
                        u = u2;
                    }
                }
            }
        }
        return 0;
    }

	int CEntityCell::lGetMovePointStraight(lua_State* L)
	{
		position_t x1 = m_pos[0];
		position_t y1 = m_pos[1];

		CSpace* sp = GetMySpace();
		TENTITYID emenyId = (TENTITYID)luaL_checkint(L, 2); 
		int32_t spellDis = luaL_checkint(L, 3);
        //printf("spellDis:%d  %d\n", spellDis, (int)(spellDis*0.9));
        spellDis *= 0.9f;

		CEntityCell* emenyEntity = sp->GetEntity(emenyId);
		if(!emenyEntity)
        {
            //printf("no emenyEntity!!!!!!!!!!!!\n");
            lua_pushnil(L);
            lua_pushnil(L);
			return 2;
        }
		position_t x2 = emenyEntity->m_pos[0];
		position_t y2 = emenyEntity->m_pos[1];


		int32_t dx = (int32_t)x2 - (int32_t)x1;
        int32_t dy = (int32_t)y2 - (int32_t)y1;
		float d = dx*dx + dy*dy;
        
//		float sloop = sqrt((float)d);
        float sloop = Point2PointDistance(x1, y1, x2, y2);
		float moveLength = sloop;
        //printf("d=%d moveLength:%f\n", d, moveLength);


        if (spellDis >= moveLength) 
        {//可释放法术了
            lua_pushnil(L);
            lua_pushnil(L);
            return 2;
        }
                
        moveLength -= spellDis;

        position_t x3 = x1 + moveLength/sloop*dx;
        position_t y3 = y1 + moveLength/sloop*dy;
        float tmpDis = Point2PointDistance(x1, y1, x3, y3);
        if (tmpDis < 100.0f)
        {
            //printf("find4 fail %d\n", i++);	
            lua_pushnil(L);
            lua_pushnil(L);
            return 2;
        }
        else
        {
            //printf("find5 success  %d\n", i++);	
            lua_pushinteger(L,  x3);
            lua_pushinteger(L,  y3);
            return 2;
        }
    }

    int CEntityCell::lProcessMove(lua_State* L)
    {
        int n = lua_gettop(L);
        if (n < 2)
        {
            //printf("lProcessMove false 0\n");
            return 0;
        }

        position_t tarX = (position_t)luaL_checkint(L, 2);
        position_t tarY = (position_t)luaL_checkint(L, 3);

        if (tarX == m_pos[0] && tarY == m_pos[1])
        {
            //printf("lProcessMove false 1\n");
            return 0;
        }

        int16_t x1 = m_pos[0];
        int16_t y1 = m_pos[1];
        int16_t x2 = tarX;
        int16_t y2 = tarY;
        int16_t x3 = 0;
        int16_t y3 = 0;
        float speed = 0.0f;
        uint totalTimeusec = 0;
        while(speed <= 0.0f)
        {
            speed = (float)m_nSpeed;
            speed = _move(x1, y1, tarX, tarY, speed, x3, y3);
            x1 = x3;
            y1 = y3;
            totalTimeusec += 100;//1毫秒
        }
//            printf("speed %f  %d %d   %d %d \n", speed, x1, y1, tarX, tarY);

        struct timeval tv;    
        gettimeofday(&tv,NULL);    
        uint curTime = tv.tv_sec * 1000 + tv.tv_usec / 1000;   
        uint dstTime = curTime + totalTimeusec;
//        printf("targetTime:%d %u %u  %u\n",totalTimeusec, (tv.tv_sec * 1000 + tv.tv_usec / 1000) ,curTime, dstTime);
        

        //同步坐标给AOI内其他玩家 kevinhua add20130425
        CSpace* sp = GetMySpace();
        if(sp)
        {
            CPluto* u = NULL;

#ifdef __AOI_PRUNING
            set<TENTITYID>::iterator iter = m_followers.begin();
            for(; iter != m_followers.end(); ++iter)
#else
            set<TENTITYID>::iterator iter = m_entitiesIds.begin();
            for(; iter != m_entitiesIds.end(); ++iter)
#endif

            {
                CEntityCell* p2 = sp->GetEntity(*iter);
                if(p2)
                {
#ifdef __FACE
                    CPluto* u2 = p2->SendOtherEntityPos(u, m_id, face, tarX, tarY,
                        //                                                        MSGID_CLIENT_ENTITY_POS_PULL, MSGID_CLIENT_OTHER_ENTITY_POS_PULL);
                        //                                                        MSGID_CLIENT_ENTITY_POS_TELEPORT, MSGID_CLIENT_OTHER_ENTITY_TELEPORT);
                        MSGID_CLIENT_ENTITY_POS_SYNC, MSGID_CLIENT_OTHER_ENTITY_POS_SYNC);
#else
                    CPluto* u2 = p2->SendOtherEntityPos(u, m_id, tarX, tarY, dstTime,
                        //                                                        MSGID_CLIENT_ENTITY_POS_PULL, MSGID_CLIENT_OTHER_ENTITY_POS_PULL);
                        //                                                        MSGID_CLIENT_ENTITY_POS_TELEPORT, MSGID_CLIENT_OTHER_ENTITY_TELEPORT);
                        MSGID_CLIENT_ENTITY_POS_SYNC, MSGID_CLIENT_OTHER_ENTITY_POS_SYNC);
#endif


                    if(u2 != NULL)
                    {
                        u = u2;
                    }
                }
            }
        }
        return 0;
    }

    int CEntityCell::lProcessPull(lua_State* L)
    {
        int n = lua_gettop(L);
        if (n < 3)
        {
            //printf("lProcessMove false 0\n");
            return 0;
        }

        //停止行走
        this->ClearPosPairs();

        //LogDebug("CEntityCell::lTelePort", "n=%d", n);
        if(n > 3)
        {
            //同cell内不同场景pull
            TSPACEID space_id = (TSPACEID)luaL_checkinteger(L, 2);
            position_t x = (position_t)luaL_checkinteger(L, 3);
            position_t y = (position_t)luaL_checkinteger(L, 4);

            //先离开当前场景
            CWorldCell& world = GetWorldcell();
            CSpace* sp1 = world.GetSpace(m_spaceId);
            if(sp1)
            {
                sp1->DelEntity(this);
            }

            //进入新的场景

            //LogDebug("CEntityCell::lTelePort", "space_id=%d", space_id);
            CSpace* sp2 = world.GetSpace(space_id);
            if(sp2)
            {
                //同步坐标给自己的客户端
#ifdef __FACE
                this->SendOtherEntityPos(NULL, m_id, face, x, y,
                    MSGID_CLIENT_ENTITY_POS_PULL, MSGID_CLIENT_OTHER_ENTITY_POS_PULL);
#else
                this->SendOtherEntityPos(NULL, m_id, x, y, 0,
                    MSGID_CLIENT_ENTITY_POS_PULL, MSGID_CLIENT_OTHER_ENTITY_POS_PULL);
#endif
                sp2->AddEntity(x, y, this);
            }
        }
        else
        {
            position_t x = (position_t)luaL_checkinteger(L, 2);
            position_t y = (position_t)luaL_checkinteger(L, 3);

            //本场景pull,self:pull(x,y)
            CSpace* sp = GetMySpace();
            if(sp)
            {
                //同步坐标给自己的客户端
#ifdef __FACE
                this->SendOtherEntityPos(NULL, m_id, face, x, y, 
                    MSGID_CLIENT_ENTITY_POS_PULL, MSGID_CLIENT_OTHER_ENTITY_POS_PULL);
#else
                this->SendOtherEntityPos(NULL, m_id, x, y, 0,
                    MSGID_CLIENT_ENTITY_POS_PULL, MSGID_CLIENT_OTHER_ENTITY_POS_PULL);
#endif
                sp->TelePortLocally(this, x, y);
            }
        }

        return 0;
    }

    int CEntityCell::lStopMove(lua_State* L)
    {
        //停止行走
        if(m_lsPosPairs == NULL || m_lsPosPairs->empty()) 
        {
            return 0;
        }

        m_lsPosPairs->clear();

        SetAfterMoveNotifyLua(false);

        return 0;
    }

    //返回true表示移动了
    bool CEntityCell::OnMoveTick()
    {
        //怪物坐标更新不走这个方法
//        printf("OnMoveTick %d\n", m_id);
        if(m_lsPosPairs == NULL || m_lsPosPairs->empty())
        {
            return false;
        }

        //当前坐标
        int16_t x1 = m_pos[0];
        int16_t y1 = m_pos[1];
        //本次移动能走到的目标坐标
        int16_t x3;
        int16_t y3;
        //剩余速度值
        float speed = (float)m_nSpeed;

        while(!(m_lsPosPairs->empty()))
        {
            pair<int16_t, int16_t>* pNextPos = m_lsPosPairs->front();

            speed = _move(x1, y1, pNextPos->first, pNextPos->second, speed, x3, y3);
            if(speed > 0)
            {
                //当前路点已经走完,删除
                m_lsPosPairs->pop_front();
                delete pNextPos;

                //还需要走下一个路点
                x1 = x3;
                y1 = y3;
                

/*

                //同步坐标给AOI内其他玩家 kevinhua add20130425
                CSpace* sp = GetMySpace();
                if(sp)
                {
                    CPluto* u = NULL;
                    set<TENTITYID>::iterator iter = m_observersIds.begin();
                    for(; iter != m_observersIds.end(); ++iter)
                    {
                        CEntityCell* p2 = sp->GetEntity(*iter);
                        if(p2)
                        {
                            //printf("TELEPORT\n");
                            CPluto* u2 = p2->SendOtherEntityPos(u, m_id, face, x3, y3,
        //                                                        MSGID_CLIENT_ENTITY_POS_PULL, MSGID_CLIENT_OTHER_ENTITY_POS_PULL);
                                                                MSGID_CLIENT_ENTITY_POS_TELEPORT, MSGID_CLIENT_OTHER_ENTITY_TELEPORT);
        //                                                        MSGID_CLIENT_ENTITY_POS_SYNC, MSGID_CLIENT_OTHER_ENTITY_POS_SYNC);
                            if(u2 != NULL)
                            {
                                u = u2;
                            }
                        }
                    }
                }
*/
                continue;
            }
            else
            {
                //当前路点没有走完,不删除,下次接着走
                break;
            }
        }

        //设置新的坐标点
        m_pos[0] = x3;
        m_pos[1] = y3;
     //   printf("new pos, %d-%d\n", m_pos[0], m_pos[1]);


        //同步坐标给aoi范围内其他玩家
        CSpace* sp = GetMySpace();
        if(sp && sp->GetEntity(this->GetId()) == this)
        {
            //刷新自己的坐标给aoi管理器
            sp->OnPosMove(this);
        }

        if (m_lsPosPairs->empty())
        {
            //通知lua
            if (m_bAfterMoveNotifyLua)
            {
                SetAfterMoveNotifyLua(false);
                
                CWorldCell& world = GetWorldcell();
                lua_State* L = world.GetLuaState();
                int nRet = EntityMethodCall(L, this, "MoveToCompleteEvent", 0, 0);            
                lua_pop(L, nRet);
            }
        }


        m_bMoved = true;        //设置移动过了的标记
        return true;
    }

#ifdef __FACE
    //将entity的坐标同步给aoi范围内的玩家
    CPluto* CEntityCell::SendOtherEntityPos(CPluto* u, TENTITYID eid, uint8_t newFace, int16_t x, int16_t y,
        pluto_msgid_t selfCPlutoHead, pluto_msgid_t otherCPlutoHead)
#else
    //将entity的坐标同步给aoi范围内的玩家
    CPluto* CEntityCell::SendOtherEntityPos(CPluto* u, TENTITYID eid, int16_t x, int16_t y, uint32_t checkFlag,
        pluto_msgid_t selfCPlutoHead, pluto_msgid_t otherCPlutoHead)
#endif

    {
        CMailBox* mb = GetBaseMailboxIfClient();
        if(mb)
        {
            if(eid == m_id)
            {
                //发给自己的客户端,特殊处理,忽略传入的u(调用时传NULL)
                u = new CPluto;
#ifdef __FACE
                u->Encode(MSGID_BASEAPP_AVATAR_POS_SYNC) << (uint16_t)selfCPlutoHead << m_id << newFace << x << y << (uint8_t)1 << EndPluto;
#else
                u->Encode(MSGID_BASEAPP_AVATAR_POS_SYNC) << (uint16_t)selfCPlutoHead << m_id << x << y  <<(uint8_t)1 << EndPluto;
#endif
                //LogDebug("CEntityCell::SendOtherEntityPos 1", "u.GenLen()=%d;msg_id=%d;face=%d;x=%d;y=%d", 
                //                                               u->GetLen(), selfCPlutoHead, newFace, x, y);

                mb->PushPluto(u);

                return NULL;
            }

            if(u == NULL)
            {
                //第一个打包,其他的复制
                u = new CPluto;
#ifdef __FACE
                u->Encode(MSGID_BASEAPP_CLIENT_MSG_VIA_BASE) << m_id << (uint16_t)otherCPlutoHead
                        << (uint16_t)(sizeof(eid) + sizeof(newFace) + sizeof(x) + sizeof(y))        //可以预知长度
                        << eid << newFace << x << y                                    //输入数据
                        << EndPluto;
#else
                u->Encode(MSGID_BASEAPP_CLIENT_MSG_VIA_BASE) << m_id << (uint16_t)otherCPlutoHead
                    << (uint16_t)(sizeof(eid) + sizeof(x) + sizeof(y) + sizeof(checkFlag))        //可以预知长度
                    << eid << x << y << checkFlag                                  //输入数据
                    << EndPluto;
#endif

                //LogDebug("CEntityCell::SendOtherEntityPos 2", "u.GenLen()=%d;msg_id=%d;face=%d;x=%d;y=%d", 
                //                                               u->GetLen(), otherCPlutoHead, newFace, x, y);

                mb->PushPluto(u);

                return u;
            }
            else
            {
                CPluto* u2 = new CPluto(u->GetBuff(), u->GetLen());
                u2->ReplaceField<uint32_t>(8, m_id);

                //LogDebug("CEntityCell::SendOtherEntityPos 3", "u2.GenLen()=%d;msg_id=%d;face=%d;x=%d;y=%d", 
                //                                               u2->GetLen(), otherCPlutoHead, newFace, x, y);

                mb->PushPluto(u2);

                return NULL;
            }
        }

        return NULL;
    }

    //清除所有的关注者
    void CEntityCell::ClearAoiEntities()
    {
        CSpace* sp = GetMySpace();
        if(sp)
        {
            //通知关注者我离开了;如果不通知,当关注者没有移动时,无法检测到我的离开
            set<TENTITYID>::iterator iter = m_entitiesIds.begin();

#ifdef __AOI_PRUNING
            for (; iter != m_entitiesIds.end(); ++iter)
            {
                CEntityCell* p2 = sp->GetEntity(*iter);
                if(p2)
                {
                    p2->RemoveInFollower(m_id);
                }
            }

            iter = m_entitiesIds.begin();
#endif

            for(; iter != m_entitiesIds.end(); ++iter)
            {
                CEntityCell* p2 = sp->GetEntity(*iter);
                if(p2)
                {
                    p2->OnLeaveAoi(m_id, false);
                }
            }
        }

        //m_observersIds.clear();

        //清除所有的关注者
        m_entitiesIds.clear();

#ifdef __AOI_PRUNING
        m_followers.clear();
        m_observers.clear();
#endif

    }

    //检查关注者是否离开了aoi
    bool CEntityCell::CheckLeaveAoi()
    {
        if(!m_bMoved)
        {
            //不曾移动过
            return false;
        }

        m_bMoved = false;

        CSpace* sp = GetMySpace();
        if(sp == NULL)
        {
            return false;
        }

        bool bLeave = false;
        list<TENTITYID> left_ids;    //已经离开的关注者
        set<TENTITYID>::iterator iter = m_entitiesIds.begin();
        for(; iter != m_entitiesIds.end(); ++iter)
        {
            TENTITYID eid = *iter;
            CEntityCell* p2 = sp->GetEntity(eid);
            if(p2 == NULL)
            {
                //已经离开了本space
                this->OnLeaveAoi(eid, true);
                left_ids.push_back(eid);
                bLeave = true;
            }
            else
            {
                if(IsOutOfAoi(m_pos, p2->m_pos))
                {
                    //离开了aoi
                    this->OnLeaveAoi(eid, true);
                    p2->OnLeaveAoi(m_id, false);
                    left_ids.push_back(eid);
                    bLeave = true;
                }
            }
        }

        while(!left_ids.empty())
        {
            TENTITYID eid2 = left_ids.front();
            m_entitiesIds.erase(eid2);
            left_ids.pop_front();
        }

        return bLeave;
    }

    //有entity离开了aoi;bIsNest为true表示嵌套调用中,不能erase id
    void CEntityCell::OnLeaveAoi(TENTITYID eid, bool bIsNest)
    {
        bool bFound = false;
        if(bIsNest)
        {
            bFound = true;
        }
        else
        {
            set<TENTITYID>::iterator iter = m_entitiesIds.find(eid);
            if(iter != m_entitiesIds.end())
            {
                bFound = true;
                m_entitiesIds.erase(iter);
            }
        }

#ifdef __AOI_PRUNING

        CSpace *sp = this->GetMySpace();
        if (!sp)
        {
            return;
        }

        set<TENTITYID>::iterator iter2 = m_observers.find(eid);
        if(iter2 != m_observers.end())
        {
            //发送消息给客户端
            //printf("%u say: %u leave aoi\n", m_id, eid);
            //LogDebug("OnLeaveAoi", "watcher=%u;leave=%u", m_id, eid);

            CMailBox* mb = GetBaseMailboxIfClient();
            if(mb)
            {
                CPluto* u = new CPluto;
                u->Encode(MSGID_BASEAPP_CLIENT_MSG_VIA_BASE) << m_id << (uint16_t)MSGID_CLIENT_AOI_DEL_ENTITY
                    << (uint16_t)sizeof(eid) << eid << EndPluto;

                LogDebug("CEntityCell::OnLeaveAoi", "u.GenLen()=%d", u->GetLen());

                mb->PushPluto(u);
            }

            m_observers.erase(iter2);

            if (this->IsObserversFull())
            {
                return;
            }

            set<TENTITYID>::iterator iter3 = m_entitiesIds.begin();
            for (; iter3 != m_entitiesIds.end(); ++iter3)
            {
                CEntityCell* p2 = sp->GetEntity(*iter3);

                if (p2 && p2->AddInFollowers(m_id) && this->AddInObservers(*iter3))
                {

                    if(m_bHasClient)
                    {
                        //如果有客户端,将新进入entity的other_CLIENTS属性发给客户端
                        int nBaseId = GetBaseServerId();
                        if(nBaseId > 0)
                        {
                            CMailBox* mb = GetWorld()->GetServerMailbox(nBaseId);
                            if(mb)
                            {
                                //新进入entity的属性
                                CPluto* u = new CPluto;
                                CPluto& uu = *u;
                                uu.Encode(MSGID_BASEAPP_CLIENT_MSG_VIA_BASE) << m_id << (uint16_t)MSGID_CLIENT_AOI_NEW_ENTITY;

                                uint32_t idx1 = uu.GetLen();
                                uu << (uint16_t)0;                                    //长度占位

                                p2->PickleOtherClientToPluto(uu);                //打包数据

                                uint32_t idx2 = uu.GetLen();
                                uu.ReplaceField<uint16_t>(idx1, idx2-idx1-2);        //替换为真正的长度
                                uu << EndPluto;

                                LogDebug("CEntityCell::OnLeaveAoi Add", "m_id=%d;id=%d", m_id, *iter3);

                                mb->PushPluto(u);


                                ////新进入entity的路点信息
                                //if(p2->GetLeftPosPairs())
                                //{
                                //    SendOtherClientMoveReq(NULL, p2->GetId(), *(p2->GetLeftPosPairs()) );
                                //}
                            }
                        }

                    }
                    return;
                }
            }
        }
#else
        if(bFound)
        {
            //发送消息给客户端
            //printf("%u say: %u leave aoi\n", m_id, eid);
            //LogDebug("OnLeaveAoi", "watcher=%u;leave=%u", m_id, eid);

            CMailBox* mb = GetBaseMailboxIfClient();
            if(mb)
            {
                CPluto* u = new CPluto;
                u->Encode(MSGID_BASEAPP_CLIENT_MSG_VIA_BASE) << m_id << (uint16_t)MSGID_CLIENT_AOI_DEL_ENTITY
                    << (uint16_t)sizeof(eid) << eid << EndPluto;

                LogDebug("CEntityCell::OnLeaveAoi", "u.GenLen()=%d", u->GetLen());

                mb->PushPluto(u);
            }
        }
#endif

        /*
        set<TENTITYID>::iterator iter1 = m_observersIds.find(eid);
        if (iter1 != m_observersIds.end())
        {
            //当离开AOI的eid在关注者列表里面，则需要一同删除，并尝试新增一个进去
            m_observersIds.erase(iter1);

            enum {OBSERVER_SIZE = 15,};
            if (m_observersIds.size() >= OBSERVER_SIZE)
            {
                return;
            }

            CSpace *ptrCSpace = GetMySpace();
            if (!ptrCSpace)
            {
                return;
            }

            set<TENTITYID>::iterator iter = m_entitiesIds.begin();
            for (;iter != m_entitiesIds.end(); iter++)
            {
                TENTITYID eid = *iter;

                CEntityCell* p2 = ptrCSpace->GetEntity(eid);

                if (!p2)
                {
                    continue;
                }

                set<TENTITYID>::iterator iter2 = m_entitiesIds.find(eid);
                if (iter2 == m_entitiesIds.end())
                {
                    m_entitiesIds.insert(iter2, eid);
                    if(m_bHasClient)
                    {
                        //如果有客户端,将新进入entity的other_CLIENTS属性发给客户端
                        int nBaseId = GetBaseServerId();
                        if(nBaseId > 0)
                        {
                            CMailBox* mb = GetWorld()->GetServerMailbox(nBaseId);
                            if(mb)
                            {
                                //新进入entity的属性
                                CPluto* u = new CPluto;
                                CPluto& uu = *u;
                                uu.Encode(MSGID_BASEAPP_CLIENT_MSG_VIA_BASE) << m_id << (uint16_t)MSGID_CLIENT_AOI_NEW_ENTITY;

                                uint32_t idx1 = uu.GetLen();
                                uu << (uint16_t)0;                                    //长度占位

                                p2->PickleOtherClientToPluto(uu);                //打包数据

                                uint32_t idx2 = uu.GetLen();
                                uu.ReplaceField<uint16_t>(idx1, idx2-idx1-2);        //替换为真正的长度
                                uu << EndPluto;

                                LogDebug("CEntityCell::OnEnterAoi", "u->GetLen()=%d;", u->GetLen());

                                mb->PushPluto(u);


                                ////新进入entity的路点信息
                                //if(p2->GetLeftPosPairs())
                                //{
                                //    SendOtherClientMoveReq(NULL, p2->GetId(), *(p2->GetLeftPosPairs()) );
                                //}
                            }
                        }

                    }
                    return;
                }
            }
        }
        */
    }

    //当某个属性变更时,是否要同步给other_clients
    void CEntityCell::OnAttriModified(const string& strPropName, VOBJECT* v)
    {
        //该属性是否带other_clients标记
        uint16_t nPropId = 0;
        const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByType(m_etype);
        if(pDef)
        {
            map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.find(strPropName);
            if(iter != pDef->m_properties.end())
            {
                _SEntityDefProperties* pProp = iter->second;
                if(IsOtherClientsFlag(pProp->m_nFlags))
                {
                    nPropId = (uint16_t)pDef->m_propertiesMap.GetIntByStr(strPropName);
                }
            }
        }

        if(nPropId == 0)
        {
            return;
        }

        //同步属性给aoi范围内其他玩家
        CSpace* sp = GetMySpace();
        if(sp)
        {
            CPluto* u = NULL;

#ifdef __AOI_PRUNING
            set<TENTITYID>::iterator iter = m_followers.begin();
            for(; iter != m_followers.end(); ++iter)
#else
            set<TENTITYID>::iterator iter = m_entitiesIds.begin();
            for(; iter != m_entitiesIds.end(); ++iter)
#endif

            {
                CEntityCell* p2 = sp->GetEntity(*iter);
                if(p2)
                {
                    CPluto* u2 = p2->SyncOtherEntityAttri(u, m_id, nPropId, v);
                    if(u2 != NULL)
                    {
                        u = u2;
                    }
                }
            }
        }
    }

    //将其他entity的属性变化发给自己的客户端
    CPluto* CEntityCell::SyncOtherEntityAttri(CPluto* u, TENTITYID eid, uint16_t nPropId, VOBJECT* v)
    {
        CMailBox* mb = GetBaseMailboxIfClient();
        if(mb)
        {
            if(u == NULL)
            {
                //第一个打包,其他的复制
                u = new CPluto;
                u->Encode(MSGID_BASEAPP_CLIENT_MSG_VIA_BASE) << m_id << (uint16_t)MSGID_CLIENT_OTHER_ENTITY_ATTRI_SYNC;

                uint32_t idx = u->GetLen();
                (*u) << (uint16_t) 0;    //长度占位
                (*u) << eid << nPropId;
                u->FillPluto(*v);
                uint32_t idx2 = u->GetLen();
                u->ReplaceField<uint16_t>(idx, idx2-idx-2);        //替换为真实的长度
                (*u) << EndPluto;

                //LogDebug("CEntityCell::SyncOtherEntityAttri 1", "u.GenLen()=%d", u->GetLen());

                mb->PushPluto(u);

                return u;
            }
            else
            {
                CPluto* u2 = new CPluto(u->GetBuff(), u->GetLen());
                u2->ReplaceField<uint32_t>(8, m_id);

                //LogDebug("CEntityCell::SyncOtherEntityAttri 2", "u2.GenLen()=%d", u2->GetLen());

                mb->PushPluto(u2);

                return NULL;
            }
        }

        return NULL;
    }

    //将自己的属性变化发给自己的客户端(无base标记)
    void CEntityCell::SyncOwnEntityAttri(uint16_t nPropId, VOBJECT* v)
    {
        CMailBox* mb = GetBaseMailboxIfClient();
        if(mb)
        {
            //第一个打包,其他的复制
            CPluto* u = new CPluto;
            u->Encode(MSGID_BASEAPP_CLIENT_MSG_VIA_BASE) << m_id << (uint16_t)MSGID_CLIENT_AVATAR_ATTRI_SYNC;

            uint32_t idx = u->GetLen();
            (*u) << (uint16_t) 0;                                //长度占位
            (*u) << nPropId;
            u->FillPluto(*v);
            uint32_t idx2 = u->GetLen();
            u->ReplaceField<uint16_t>(idx, idx2-idx-2);          //替换为真实的长度
            (*u) << EndPluto;

            mb->PushPluto(u);

            return;
        }
    }

#ifdef __OPTIMIZE_PROP_SYN
    void CEntityCell::DoSyncClientProp()
    {
        if (this->m_clientPropIds.empty())
        {
            return;
        }

        TENTITYTYPE etype = this->GetEntityType();
        CDefParser& defparser = GetWorld()->GetDefParser();
        const string& etypename = defparser.GetTypeName(etype);
        const SEntityDef* pDef = defparser.GetEntityDefByName(etypename);
        if (pDef)
        {
            set<int32_t>::const_iterator iter = this->m_clientPropIds.begin();
            for (; iter != this->m_clientPropIds.end(); iter++)
            {
                const string& strPropName = pDef->m_propertiesMap.GetStrByInt(*iter);
                const _SEntityDefProperties* p = defparser.GetEntityPropDef(etypename, strPropName);
                if (p)
                {
                    if(IsClientFlag(p->m_nFlags))
                    {
                        map<string, VOBJECT*>::const_iterator iter1 = this->m_data.find(strPropName);
                        if (iter1 != this->m_data.end())
                        {
                            VOBJECT& obj = *(iter1->second);
                            this->SyncOwnEntityAttri(*iter, &obj);
                        }
                    }

                    if(IsOtherClientsFlag(p->m_nFlags))
                    {
                        map<string, VOBJECT*>::const_iterator iter2 = this->m_data.find(strPropName);
                        if (iter2 != this->m_data.end())
                        {
                            VOBJECT& obj = *(iter2->second);
                            this->OnAttriModified(strPropName, &obj);
                        }
                    }
                }
            }
        }

        this->m_clientPropIds.clear();
    }
#endif

    int CEntityCell::lGetNextEntityId(lua_State* L) 
    {
        world* pWorld = GetWorld();
        TENTITYID new_id = pWorld->GetNextEntityId();
        
        lua_pushinteger(L,  new_id); 
        return 1;
    }

    //调用所有clients的rpc方法
    void CEntityCell::AllclientsRpc(const char* pszFunc, lua_State* L)
    {
        //发给自己
        CPluto* u = this->ClientRpc(NULL, pszFunc, L);

        //发给aoi内其他玩家
        CSpace* sp = GetMySpace();
        if(sp)
        {
            set<TENTITYID>::iterator iter = m_entitiesIds.begin();
            for(; iter != m_entitiesIds.end(); ++iter)
            {
                CEntityCell* p2 = sp->GetEntity(*iter);
                if(p2)
                {			
                    u = p2->ClientRpc(u, pszFunc, L);
                }
            }
        }
    }

    void CEntityCell::OwnclientRpc(const char* pszFunc, lua_State* L)
    {
        //发给自己
        CPluto* u = this->ClientRpc(NULL, pszFunc, L);
    }

    //调用客户端rpc
    CPluto* CEntityCell::ClientRpc(CPluto* u, const char* pszFunc, lua_State* L)
    {
        CMailBox* mb = GetBaseMailboxIfClient();
        if(mb)
        {
            if(u)
            {
                CPluto* u2 = new CPluto(u->GetBuff(), u->GetLen());
                u2->ReplaceField<uint32_t>(8, m_id);
                mb->PushPluto(u2);

                return u;
            }
            else
            {
                CPluto* u2 = GetWorld()->RpcCallToClientViaBase(pszFunc, L, m_etype, m_id, mb->GetMailboxId());
                return u2;
            }
        }

        return NULL;
    }

}

