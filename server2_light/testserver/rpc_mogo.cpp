/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：rpc_mogo
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.5
// 模块描述：rpc 打包，解包等
//----------------------------------------------------------------*/

#include "rpc_mogo.h"
#include "util.h"
#include "world.h"
#include "world_select.h"


namespace mogo
{

CRpcUtil::CRpcUtil() : m_strFuncNameNotfound("")
{   
    //printf("CRpcUtil::CRpcUtil()init inner methods for Util rpc: start!\n");
    this->InitInnerMethods();
    //printf("CRpcUtil::CRpcUtil()init inner methods for Util rpc: start!\n");
}

//初始化内嵌(非自定义)的方法
void CRpcUtil::InitInnerMethods()
{
    //client
    {
        _SEntityDefMethods* p = new _SEntityDefMethods;
        p->m_argsType.push_back(V_STR);             //baseapp addr
        p->m_argsType.push_back(V_UINT16);          //baseapp port
        p->m_argsType.push_back(V_STR);             //key
        m_methods.insert(make_pair(MSGID_CLIENT_NOTIFY_ATTACH_BASEAPP, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_UINT8);			//ret code
		m_methods.insert(make_pair(MSGID_CLIENT_LOGIN_RESP, p));
    }

    //all app
    {
        _SEntityDefMethods* p = new _SEntityDefMethods;
        p->m_argsType.push_back(V_UINT32);
        m_methods.insert(make_pair(MSGID_ALLAPP_ONTICK, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_UINT8);
		m_methods.insert(make_pair(MSGID_ALLAPP_SHUTDOWN_SERVER, p));
    }

    //client -> loginapp
    {
        _SEntityDefMethods* p = new _SEntityDefMethods;
        p->m_argsType.push_back(V_STR);         //account name
        p->m_argsType.push_back(V_STR);         //passwd
        m_methods.insert(make_pair(MSGID_LOGINAPP_LOGIN, p));

        p = new _SEntityDefMethods;
        p->m_argsType.push_back(V_INT32);       //client fd
        p->m_argsType.push_back(V_STR);         //account name
        p->m_argsType.push_back(V_UINT8);       //ret
        m_methods.insert(make_pair(MSGID_LOGINAPP_SELECT_ACCOUNT_CALLBACK, p));

        p = new _SEntityDefMethods;
        p->m_argsType.push_back(V_STR);         //account
        p->m_argsType.push_back(V_UINT16);      //server id
        p->m_argsType.push_back(V_STR);         //key
        m_methods.insert(make_pair(MSGID_LOGINAPP_NOTIFY_CLIENT_TO_ATTACH, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_UINT8);
		m_methods.insert(make_pair(MSGID_LOGINAPP_MODIFY_LOGIN_FLAG, p));
    }

    //mogod,baseappmgr
    {
        _SEntityDefMethods* p = new _SEntityDefMethods;
        p->m_argsType.push_back(V_ENTITYMB);   //mb
        p->m_argsType.push_back(V_STR);        //name
        p->m_argsType.push_back(V_INT32);      //ref
        m_methods.insert(make_pair(MSGID_BASEAPPMGR_REGISTERGLOBALLY, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_STR);			//entity name
		p->m_argsType.push_back(V_STR);			//param
		m_methods.insert(make_pair(MSGID_BASEAPPMGR_CREATEBASE_ANYWHERE, p));

        p = new _SEntityDefMethods;
        p->m_argsType.push_back(V_UINT8);       //create if not exists
        p->m_argsType.push_back(V_STR);         //entity name
        p->m_argsType.push_back(V_STR);         //unique index value
        m_methods.insert(make_pair(MSGID_BASEAPPMGR_CREATEBASE_FROM_NAME_ANYWHERE, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_UINT8);       //create if not exists
		p->m_argsType.push_back(V_STR);         //entity name
		p->m_argsType.push_back(V_STR);         //unique index value
		p->m_argsType.push_back(V_UINT16);		//baseapp id
		m_methods.insert(make_pair(MSGID_BASEAPPMGR_CREATEBASE_FROM_NAME, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_ENTITYMB);	//base mb
		p->m_argsType.push_back(V_UINT16);		//entity type id
		p->m_argsType.push_back(V_STR);			//other params
		p->m_argsType.push_back(V_BLOB);		//cell props
		m_methods.insert(make_pair(MSGID_BASEAPPMGR_CREATE_CELL_IN_NEW_SPACE, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_UINT8);		//dummy
		m_methods.insert(make_pair(MSGID_BASEAPPMGR_SHUTDOWN_SERVERS, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_UINT16);		//server id
		m_methods.insert(make_pair(MSGID_BASEAPPMGR_ON_SERVER_SHUTDOWN, p));
    }

    //baseapp
    {
        _SEntityDefMethods* p = new _SEntityDefMethods;
        p->m_argsType.push_back(V_ENTITYMB);   //mb
        p->m_argsType.push_back(V_UINT8);      //ret
        p->m_argsType.push_back(V_INT32);      //ref
        m_methods.insert(make_pair(MSGID_BASEAPP_REGISTERGLOBALLY_CALLBACK, p));

        p = new _SEntityDefMethods;
        p->m_argsType.push_back(V_STR);        //name
        p->m_argsType.push_back(V_ENTITYMB);   //mb
        m_methods.insert(make_pair(MSGID_BASEAPP_ADD_GLOBALBASE, p));

        p = new _SEntityDefMethods;
        p->m_argsType.push_back(V_STR);        //name
        m_methods.insert(make_pair(MSGID_BASEAPP_DEL_GLOBALBASE, p));

        p = new _SEntityDefMethods;
        p->m_argsType.push_back(V_ENTITYMB);    //mb
        p->m_argsType.push_back(V_UINT32);      //dbid
        p->m_argsType.push_back(V_INT32);       //ref
        p->m_argsType.push_back(V_STR);         //db err
        m_methods.insert(make_pair(MSGID_BASEAPP_INSERT_ENTITY_CALLBACK, p));

        p = new _SEntityDefMethods;
        p->m_argsType.push_back(V_UINT32);      //dbid
		p->m_argsType.push_back(V_INT32);		//callback
        p->m_argsType.push_back(V_ENTITY);      //entity
        m_methods.insert(make_pair(MSGID_BASEAPP_SELECT_ENTITY_CALLBACK, p));

        p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_UINT32);      //dbid
		p->m_argsType.push_back(V_UINT32);		//entity id
        p->m_argsType.push_back(V_UINT8);       //create flag
        p->m_argsType.push_back(V_STR);         //key
		p->m_argsType.push_back(V_UINT32);		//other entity id
        p->m_argsType.push_back(V_ENTITY);      //entity
        m_methods.insert(make_pair(MSGID_BASEAPP_LOOKUP_ENTITY_CALLBACK, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_UINT32);		//entity id
		m_methods.insert(make_pair(MSGID_BASEAPP_ENTITY_MULTILOGIN, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_UINT32);		//dbid
		p->m_argsType.push_back(V_UINT32);		//id
		p->m_argsType.push_back(V_ENTITY);		//entity
		m_methods.insert(make_pair(MSGID_BASEAPP_LOAD_ALL_AVATAR, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_UINT32);		//dbid
		p->m_argsType.push_back(V_UINT32);		//id
		p->m_argsType.push_back(V_ENTITY);		//entity
		m_methods.insert(make_pair(MSGID_BASEAPP_LOAD_ENTITIES_OF_TYPE, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_STR);			//entity name
		p->m_argsType.push_back(V_UINT32);		//entity count
		m_methods.insert(make_pair(MSGID_BASEAPP_LOAD_ENTITIES_END_MSG, p));

        p = new _SEntityDefMethods;
        p->m_argsType.push_back(V_STR);         //key
        m_methods.insert(make_pair(MSGID_BASEAPP_CLIENT_LOGIN, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_STR);			//lua code
		m_methods.insert(make_pair(MSGID_BASEAPP_LUA_DEBUG, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_ENTITYMB);	//cell mb
		m_methods.insert(make_pair(MSGID_BASEAPP_ON_GET_CELL, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_UINT32);		//entity id
		p->m_argsType.push_back(V_ENTITYMB);	//src base mb
		p->m_argsType.push_back(V_UINT32);		//x
		p->m_argsType.push_back(V_UINT32);		//y
		p->m_argsType.push_back(V_STR);			//mask string
		p->m_argsType.push_back(V_BLOB);		//props
		m_methods.insert(make_pair(MSGID_BASEAPP_CREATE_CELL_VIA_MYCELL, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_UINT32);		//entity id
		p->m_argsType.push_back(V_UINT8);		//err id
		m_methods.insert(make_pair(MSGID_BASEAPP_CREATE_CELL_FAILED, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_UINT32);		//eid
		m_methods.insert(make_pair(MSGID_BASEAPP_ON_LOSE_CELL, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_STR);			//entity name
		p->m_argsType.push_back(V_STR);			//param
		m_methods.insert(make_pair(MSGID_BASEAPP_CREATE_BASE_ANYWHERE, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_STR);			//key
		p->m_argsType.push_back(V_UINT8);		//value type
		p->m_argsType.push_back(V_STR);			//value
		m_methods.insert(make_pair(MSGID_BASEAPP_SET_BASE_DATA, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_STR);			//key
		m_methods.insert(make_pair(MSGID_BASEAPP_DEL_BASE_DATA, p));

		//p = new _SEntityDefMethods;
		//p->m_argsType.push_back(V_STR);			//gm cmd
		//m_methods.insert(make_pair(MSGID_BASEAPP_CLIENT_RPCALL, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_UINT32);			//eid
		p->m_argsType.push_back(V_UINT16);			//func id
		p->m_argsType.push_back(V_BLOB);			//params
		m_methods.insert(make_pair(MSGID_BASEAPP_CLIENT_RPC_VIA_BASE, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_ENTITYMB);		//entity mb
		p->m_argsType.push_back(V_STR);				//attri name
		p->m_argsType.push_back(V_STR);				//value
		m_methods.insert(make_pair(MSGID_BASEAPP_ON_REDIS_HASH_LOAD, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_UINT32);			//eid
		p->m_argsType.push_back(V_UINT16);			//msg id
		p->m_argsType.push_back(V_BLOB);			//params
		m_methods.insert(make_pair(MSGID_BASEAPP_CLIENT_MSG_VIA_BASE, p));

		p = new _SEntityDefMethods;
		m_methods.insert(make_pair(MSGID_BASEAPP_TIME_SAVE, p));

		p = new _SEntityDefMethods;
        p->m_argsType.push_back(V_UINT16);          //发到自己客户端的协议头
		p->m_argsType.push_back(V_UINT32);			//eid
        p->m_argsType.push_back(V_UINT8);           //face
		p->m_argsType.push_back(V_INT16);			//pos_x
		p->m_argsType.push_back(V_INT16);			//pos_y
		m_methods.insert(make_pair(MSGID_BASEAPP_AVATAR_POS_SYNC, p));
    }

	//cellapp
	{
		_SEntityDefMethods* p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_ENTITYMB);	//base mb
		p->m_argsType.push_back(V_UINT16);		//entity type id
		p->m_argsType.push_back(V_STR);			//other params
		p->m_argsType.push_back(V_BLOB);
		m_methods.insert(make_pair(MSGID_CELLAPP_CREATE_CELL_IN_NEW_SPACE, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_STR);			//lua code
		m_methods.insert(make_pair(MSGID_CELLAPP_LUA_DEBUG, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_UINT32);		//entity id
		p->m_argsType.push_back(V_ENTITYMB);	//src base mb
		p->m_argsType.push_back(V_UINT32);		//x
		p->m_argsType.push_back(V_UINT32);		//y
		p->m_argsType.push_back(V_STR);			//mask string
		p->m_argsType.push_back(V_BLOB);
		m_methods.insert(make_pair(MSGID_CELLAPP_CREATE_CELL_VIA_MYCELL, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_UINT16);		//baseapp id
		p->m_argsType.push_back(V_UINT32);		//eid
		m_methods.insert(make_pair(MSGID_CELLAPP_DESTROY_CELLENTITY, p));

		p = new _SEntityDefMethods;		
		p->m_argsType.push_back(V_UINT32);		//eid
		m_methods.insert(make_pair(MSGID_CELLAPP_PICKLE_CLIENT_ATTRIS, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_UINT32);		//eid
		m_methods.insert(make_pair(MSGID_CELLAPP_PICKLE_AOI_ENTITIES, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_UINT32);		//eid
		m_methods.insert(make_pair(MSGID_CELLAPP_LOSE_CLIENT, p));

		p = new _SEntityDefMethods;
		m_methods.insert(make_pair(MSGID_CELLAPP_ON_TIME_MOVE, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_UINT32);		//eid
		p->m_argsType.push_back(V_UINT8);
		m_methods.insert(make_pair(MSGID_CELLAPP_SET_VISIABLE, p));
	}

    //dbmgr
    {
        _SEntityDefMethods* p = new _SEntityDefMethods;
        p->m_argsType.push_back(V_ENTITYMB);      //mb
        p->m_argsType.push_back(V_INT32);         //ref
        p->m_argsType.push_back(V_ENTITY);        //entity props
        m_methods.insert(make_pair(MSGID_DBMGR_INSERT_ENTITY, p));

        p = new _SEntityDefMethods;
        p->m_argsType.push_back(V_ENTITYMB);        //mb
        p->m_argsType.push_back(V_UINT32);          //dbid
        p->m_argsType.push_back(V_ENTITY);          //entity props
        m_methods.insert(make_pair(MSGID_DBMGR_UPDATE_ENTITY, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_ENTITYMB);        //mb
		p->m_argsType.push_back(V_UINT32);          //dbid
		p->m_argsType.push_back(V_ENTITY);          //entity props
		m_methods.insert(make_pair(MSGID_DBMGR_UPDATE_ENTITY_REDIS, p));

        p = new _SEntityDefMethods;
        p->m_argsType.push_back(V_UINT16);          //server id
        p->m_argsType.push_back(V_STR);             //entity name
        p->m_argsType.push_back(V_UINT32);          //dbid
		p->m_argsType.push_back(V_INT32);			//callback
        m_methods.insert(make_pair(MSGID_DBMGR_SELECT_ENTITY, p));

        p = new _SEntityDefMethods;
        p->m_argsType.push_back(V_UINT16);          //mb id
        p->m_argsType.push_back(V_INT32);           //client fd
        p->m_argsType.push_back(V_STR);             //account name
        p->m_argsType.push_back(V_STR);             //passwd
        m_methods.insert(make_pair(MSGID_DBMGR_SELECT_ACCOUNT, p));

        p = new _SEntityDefMethods;
        p->m_argsType.push_back(V_STR);             //sql
        m_methods.insert(make_pair(MSGID_DBMGR_RAW_MODIFY_NORESP, p));

        p = new _SEntityDefMethods;
        p->m_argsType.push_back(V_UINT16);          //baseapp mb id
        p->m_argsType.push_back(V_UINT8);			//create flag
        p->m_argsType.push_back(V_STR);             //entity name
        p->m_argsType.push_back(V_STR);             //key
        m_methods.insert(make_pair(MSGID_DBMGR_CREATEBASE_FROM_NAME, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_STR);				//entity name
		p->m_argsType.push_back(V_STR);				//index name
		m_methods.insert(make_pair(MSGID_DBMGR_LOAD_ALL_AVATAR, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_STR);				//entity name
		p->m_argsType.push_back(V_UINT16);			//baseapp id
		m_methods.insert(make_pair(MSGID_DBMGR_LOAD_ENTITIES_OF_TYPE, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_UINT8);
		m_methods.insert(make_pair(MSGID_DBMGR_SHUTDOWN_SERVER, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_ENTITYMB);		//entity mb
		p->m_argsType.push_back(V_STR);				//attri name
		p->m_argsType.push_back(V_STR);				//hash key
		m_methods.insert(make_pair(MSGID_DBMGR_REDIS_HASH_LOAD, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_STR);				//key
		p->m_argsType.push_back(V_INT32);			//seq
		p->m_argsType.push_back(V_STR);				//value
		m_methods.insert(make_pair(MSGID_DBMGR_REDIS_HASH_SET, p));

		p = new _SEntityDefMethods;
		p->m_argsType.push_back(V_STR);				//key
		p->m_argsType.push_back(V_INT32);			//seq
		m_methods.insert(make_pair(MSGID_DBMGR_REDIS_HASH_DEL, p));
    }

}

CRpcUtil::~CRpcUtil()
{
    ClearMap(m_methods);
}

_SEntityDefMethods* CRpcUtil::GetDef(pluto_msgid_t msgid)
{
    map<pluto_msgid_t, _SEntityDefMethods*>::const_iterator iter = m_methods.find(msgid);
    if(iter != m_methods.end())
    {
        return iter->second;
    }
    else
    {
        return NULL;
    }
}

T_VECTOR_OBJECT* CRpcUtil::Decode(CPluto& u)
{
    //printf("CRpcUtil::Decode:start\n");
    //comment the statement for testing
    u.Decode();
    pluto_msgid_t msg_id = u.GetMsgId();

    map<pluto_msgid_t, _SEntityDefMethods*>::const_iterator iter = m_methods.find(msg_id);
    if(iter != m_methods.end())
    {   
        //printf("find methods !\n");
        list<VTYPE>& refs = iter->second->m_argsType;
        T_VECTOR_OBJECT* ll = new T_VECTOR_OBJECT;
        ll->reserve(refs.size());
        list<VTYPE>::const_iterator iter2 = refs.begin();
        for(; iter2 != refs.end(); ++iter2)
        {
            VOBJECT* v = new VOBJECT;
            u.FillVObject(*iter2, *v);
            ll->push_back(v);

			if(u.GetDecodeErrIdx() > 0)
			{
                printf("pluto error\n");
				break;
			}
        }
        return ll;
    }
	else
	{   
        //printf("find message failure!\n");
		switch(msg_id)
		{
		  case MSGID_BASEAPP_ENTITY_RPC:
			return DecodeBaseEntityRpc(u);
		  case MSGID_CELLAPP_ENTITY_RPC:
			return DecodeCellEntityRpc(u);
		  //case MSGID_BASEAPP_CLIENT_RPCALL:
		  //	return DecodeBaseClientRpc(u);
		  case MSGID_BASEAPP_ENTITY_ATTRI_SYNC:
			return DecodeEntityAttriSync(u);
		  case MSGID_CELLAPP_ENTITY_ATTRI_SYNC:
			return DecodeEntityAttriSync(u);
		  case MSGID_CELLAPP_CLIENT_MOVE_REQ:
			return DecodeClientMoveReq(u);
		}
	}
    //printf("CRpcUtil::Decode:end\n");
    return NULL;
}

//解析通用格式(可以配置在m_method里)的rpc调用
T_VECTOR_OBJECT* CRpcUtil::DecodeGeneralRpc(CPluto& u)
{
	return NULL;
}

//发到base的entity rpc调用
T_VECTOR_OBJECT* CRpcUtil::DecodeBaseEntityRpc(CPluto& u)
{
    //printf("decode base entity rpc function !\n");
	T_VECTOR_OBJECT* ll = new T_VECTOR_OBJECT; 

	VOBJECT* v = new VOBJECT;
	u.FillVObject(V_ENTITYMB, *v);
	ll->push_back(v);
	if(u.GetDecodeErrIdx() > 0)
	{
		return ll;
	}
	CEntityMailbox& mb = VOBJECT_GET_EMB(v);

	//取funcid
	v = new VOBJECT;
	u.FillVObject(V_UINT16, *v);
	ll->push_back(v);
	if(u.GetDecodeErrIdx() > 0)
	{
		return ll;
	}
	int32_t nFuncId = (int32_t)VOBJECT_GET_U16(v);

	const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByType(mb.m_nEntityType);
	if(pDef)
	{
		const string& strFunc = pDef->m_baseMethodsMap.GetStrByInt(nFuncId);
		map<string, _SEntityDefMethods*>::const_iterator iter11 = pDef->m_baseMethods.find(strFunc);
		if(iter11 != pDef->m_baseMethods.end())
		{
			_SEntityDefMethods* pMethods = iter11->second;
			list<VTYPE>& refs = pMethods->m_argsType;
			list<VTYPE>::const_iterator iter2 = refs.begin();
			for(; iter2 != refs.end(); ++iter2)
			{
				VOBJECT* v = new VOBJECT;
				u.FillVObject(*iter2, *v);
				ll->push_back(v);

				if(u.GetDecodeErrIdx() > 0)
				{
					break;
				}
			}
			return ll;
		}
	}

	ClearTListObject(ll);
	return NULL;
}

//发到cell的entity rpc调用
T_VECTOR_OBJECT* CRpcUtil::DecodeCellEntityRpc(CPluto& u)
{
	//特殊处理
	T_VECTOR_OBJECT* ll = new T_VECTOR_OBJECT; 

	VOBJECT* v = new VOBJECT;
	u.FillVObject(V_ENTITYMB, *v);
	ll->push_back(v);
	if(u.GetDecodeErrIdx() > 0)
	{
		return ll;
	}
	CEntityMailbox& mb = VOBJECT_GET_EMB(v);

	//取funcid
	v = new VOBJECT;
	u.FillVObject(V_UINT16, *v);
	ll->push_back(v);
	if(u.GetDecodeErrIdx() > 0)
	{
		return ll;
	}
	int32_t nFuncId = (int32_t)VOBJECT_GET_U16(v);

	const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByType(mb.m_nEntityType);
	if(pDef)
	{
		const string& strFunc = pDef->m_cellMethodsMap.GetStrByInt(nFuncId);
		map<string, _SEntityDefMethods*>::const_iterator iter11 = pDef->m_cellMethods.find(strFunc);
		if(iter11 != pDef->m_cellMethods.end())
		{
			_SEntityDefMethods* pMethods = iter11->second;
			list<VTYPE>& refs = pMethods->m_argsType;
			list<VTYPE>::const_iterator iter2 = refs.begin();
			for(; iter2 != refs.end(); ++iter2)
			{
				VOBJECT* v = new VOBJECT;
				u.FillVObject(*iter2, *v);
				ll->push_back(v);

				if(u.GetDecodeErrIdx() > 0)
				{
					break;
				}
			}
			return ll;
		}
	}

	ClearTListObject(ll);
	return NULL;
}
/*
//发到base的来自client的entity rpc调用
T_VECTOR_OBJECT* CRpcUtil::DecodeBaseClientRpc(CPluto& u)
{
	CMailBox* mb = u.GetMailbox();
	if(mb == NULL)
	{
		return NULL;
	}
	int fd = mb->GetFd();
	CWorldBase& the_world = GetWorldbase();
	CEntityBase* pBase = the_world.GetEntityByFd(fd);
	if(pBase == NULL)
	{
		return NULL;
	}
	const SEntityDef* pDef = the_world.GetDefParser().GetEntityDefByType(pBase->GetEntityType());
	if(pDef == NULL)
	{
		return NULL;
	}

	T_VECTOR_OBJECT* ll = new T_VECTOR_OBJECT; 

	VOBJECT* v = new VOBJECT;
	v->vt = V_ENTITY_POINTER;
	v->vv.p = pBase;
	ll->push_back(v);

	uint16_t nFuncId = 0;
	u >> nFuncId;
	if(u.GetDecodeErrIdx() > 0)
	{
		return ll;
	}

	const string& strFunc = pDef->m_baseMethodsMap.GetStrByInt(nFuncId);
	map<string, _SEntityDefMethods*>::const_iterator iter11 = pDef->m_baseMethods.find(strFunc);
	if(iter11 != pDef->m_baseMethods.end())
	{
		_SEntityDefMethods* pMethods = iter11->second;
		if(pMethods->m_bExposed)
		{
			v = new VOBJECT;
			v->vt = V_STR;
			v->vv.s = new string(strFunc);
			ll->push_back(v);

			list<VTYPE>& refs = pMethods->m_argsType;
			list<VTYPE>::const_iterator iter2 = refs.begin();
			for(; iter2 != refs.end(); ++iter2)
			{
				VOBJECT* v = new VOBJECT;
				u.FillVObject(*iter2, *v);
				ll->push_back(v);

				if(u.GetDecodeErrIdx() > 0)
				{
					return ll;
				}
			}
			return ll;			
		}
		//else 该方法不能由客户端调用
	}

	ClearTListObject(ll);
	return NULL;
}
*/
//来自客户端的移动请求
T_VECTOR_OBJECT* CRpcUtil::DecodeClientMoveReq(CPluto& u)
{
	T_VECTOR_OBJECT* ll = new T_VECTOR_OBJECT;

	u.Decode();

	//entity id
	{
		VOBJECT* v = new VOBJECT;
		u.FillVObject(V_UINT32, *v);

		if(u.GetDecodeErrIdx() > 0)
		{
			return ll;
		}

		ll->push_back(v);
	}

	//list of x,y
	int i = 0;
	while(!u.IsEnd())
	{
		VOBJECT* v = new VOBJECT;
		u.FillVObject(V_UINT16, *v);
		ll->push_back(v);

		v = new VOBJECT;
		u.FillVObject(V_UINT16, *v);
		ll->push_back(v);

		if(u.GetDecodeErrIdx() > 0)
		{
			return ll;
		}

		//增加一个判断,只接受某个值以下的坐标对,如果客户端发来的坐标对过多,则丢弃掉一些
		enum{ max_pos_pair_count = 10, };
		if(++i > max_pos_pair_count)
		{
			return ll;
		}
	}

	return ll;
}

//属性同步
T_VECTOR_OBJECT* CRpcUtil::DecodeEntityAttriSync(CPluto& u)
{
	uint32_t eid;
	uint16_t etype, nPropId;
	u >> eid >> etype >> nPropId;

	const SEntityDef* pDef = GetWorld()->GetDefParser().GetEntityDefByType(etype);
	if(pDef)
	{
		const string& strPropName = pDef->m_propertiesMap.GetStrByInt(nPropId);
		map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.find(strPropName);
		if(iter != pDef->m_properties.end())
		{
			if(u.GetDecodeErrIdx() == 0)
			{
				_SEntityDefProperties* pProp = iter->second;

				VOBJECT* v = new VOBJECT;
				u.FillVObject(pProp->m_nType, *v);

				if(u.GetDecodeErrIdx() == 0)
				{
					T_VECTOR_OBJECT* ll = new T_VECTOR_OBJECT; 

					VOBJECT* v2 = new VOBJECT;
					v2->vt = V_UINT32;
					v2->vv.u32 = eid;
					ll->push_back(v2);

					v2 = new VOBJECT;
					v2->vt = V_STR;
					v2->vv.s = new string(strPropName);
					ll->push_back(v2);

					ll->push_back(v);

					//如果带client标记,多添加一个值给world.from_rpc_call
					if(IsClientFlag(pProp->m_nFlags))
					{
						v2 = new VOBJECT;
						v2->vt = V_UINT16;
						v2->vv.u16 = nPropId;
						ll->push_back(v2);
					}

					return ll;
				}
				else
				{
					delete v;
					return NULL;
				}
			}
		}

	}

	return NULL;
}

//从pluto包解析出entity属性字段列表
bool CRpcUtil::UnpickleEntityDataFromPluto(CPluto& u, TDBID& dbid, map<string, VOBJECT*> data)
{
    //const SEntityDef* pDef = GetWorld()->getDefParser().getEntityDefByType();
    //if(pDef)
    //{
    //    TDBID dbid;
    //    u >> dbid;
    //    map<string, VOBJECT*> data;
    //    while(!u.isEnd())
    //    {
    //        uint16_t nPropId;
    //        u >> nPropId;
    //        const string& strPropName = pDef->m_propertiesMap.getStrByInt(nPropId);
    //        map<string, _SEntityDefProperties*>::const_iterator iter = pDef->m_properties.find(strPropName);
    //        if(iter == pDef->m_properties.end())
    //        {
    //            return false;
    //        }
    //        VOBJECT* v = new VOBJECT;
    //        u.FillVObject(iter->second->m_nType, *v);
    //        data.insert(make_pair(strPropName, v));
    //    }
    //}

    //return pDef != NULL;

    return false;
}

}



