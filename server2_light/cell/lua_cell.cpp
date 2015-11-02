/*----------------------------------------------------------------
// Copyright (C) 2013 广州，爱游
//
// 模块名：lua_cell
// 创建者：Steven Yang
// 修改者列表：
// 创建日期：2013.1.14
// 模块描述：cell 上 lua 相关封装
//----------------------------------------------------------------*/

#include "lua_cell.h"
#include "entity_cell.h"
#include "space.h"
#include "my_stl.h"
#include "defparser.h"
#include "world_cell.h"
#include "world_select.h"
#include "lua_mogo_impl.h"


const static char* s_entity_ctor_name = "__ctor__";       //构造函数
const static char* s_entity_dctor_name = "__dctor__";     //析构函数

const static char* s_entity_enter_space = "onEnterSpace";    //entity进入Space时调用的脚本方法 kevinmodify
const static char* s_entity_leave_space = "onLeaveSpace";    //entity离开Space时调用的脚本方法

using namespace mogo;
//static int CreateSpace(lua_State* L)
//{
//    cout << "create_space begin " << endl;
//    CSpace** ppf = (CSpace**)lua_newuserdata(L, sizeof(CSpace*));
//    luaL_getmetatable(L, g_szUserDataEntity);
//    lua_pushvalue(L, -2);
//    int n = luaL_ref(L, -2);
//    lua_pop(L, 1);
//
//    //cout << "create_entity,checkudata" << luaL_checkudata(L, -1,s_szEntityName ) << endl;
//
//    CSpace* pf = new CSpace(0, 100, 60);
//    *ppf = pf;
//
//    luaL_getmetatable(L, s_szSpaceName);
//    lua_setmetatable(L, -2);
//
//    return 1;
//}
//
//static int space_gc(lua_State* L)
//{
//    CSpace** ppf = (CSpace**)luaL_checkudata(L, 1, s_szSpaceName);
//    delete *ppf;
//
//    return 0;
//}
//

static int CreateEntityInNewSpace(lua_State* L)
{
    TSPACEID nSpaceId = 0;
    uint32_t nx = 0, ny = 0;

    int n = lua_gettop(L);
    if( n > 1)
    {
        luaL_checkstring(L, 1);             //entity type name
        //luaL_checktype(L, 2, LUA_TTABLE);   //{space_id=1, position={x=1,y=2}}

        //lua_getfield(L, 2, "space_id");
        //nSpaceId = (TSPACEID)lua_tointeger(L, -1);
        //lua_pop(L, 1);

        //lua_getfield(L, 2, "position");
        //if(lua_istable(L, -1))
        //{
        //    lua_getfield(L, -1, "x");
        //    nx = (uint32_t)lua_tointeger(L, -1);
        //    lua_pop(L, 1);

        //    lua_getfield(L, -1, "y");
        //    ny = (uint32_t)lua_tointeger(L, -1);
        //    lua_pop(L, 1);
        //}
        //lua_pop(L, 1);
    }
    else
    {
        luaL_checkstring(L, 1);
    }

    CSpace* s = ((CWorldCell*)GetWorld())->CreateNewSpace();
    CEntityCell* e = _CreateEntity<CEntityCell>(L);

    if(!e)
    {
        lua_pushstring(L, "CreateEntityInNewSpace, can not create entity");
        lua_error(L);
        return 0;
    }

    ((CWorldCell*)GetWorld())->AddEntity(e);
    s->AddEntity(0, 0, e);

    //call __ctor__
    int n2 = EntityMethodCall(L, e, s_entity_ctor_name, 0, 0);
    //pop n,剩下在栈顶的是entity
    lua_pop(L, n2);
    return 1;
}

//
//int LuaOpenSpaceLib(lua_State* L)
//{
//    luaL_newmetatable(L, s_szSpaceName);
//
//    lua_pushstring(L, "__index");
//    lua_pushvalue(L, -2);
//    lua_rawset(L, -3);
//
//    lua_pushstring(L, "__gc");
//    lua_pushcfunction(L, space_gc);
//    lua_rawset(L, -3);
//
//    return 0;
//}

static int CreateCellEntityLocally(lua_State* L)
{
    //mogo.createEntity("Avatar", space_id, x, y, {other_data})

    const char* pszEntity = luaL_checkstring(L, 1);
    TSPACEID nSpaceId = (TSPACEID)luaL_checkinteger(L, 2);

    CWorldCell& the_world = GetWorldcell();
    CSpace* sp = the_world.GetSpace(nSpaceId);
    if(sp == NULL)
    {
        lua_pushstring(L, "CreateCellEntityLocally, space not exit");
        lua_error(L);
        return 0;
    }

    position_t x = (position_t)luaL_checkinteger(L, 3);
    position_t y = (position_t)luaL_checkinteger(L, 4);
    lua_remove(L, 4);
    lua_remove(L, 3);
    lua_remove(L, 2);  //移去space_id,x,y三个参数

    CEntityCell* p = _CreateEntity<CEntityCell>(L);
    if (!p)
    {
        lua_pushstring(L, "CreateCellEntityLocally, can not create entity");
        lua_error(L);
        return 0;
    }
    

    if(lua_gettop(L) > 1)
    {
        //附带了初始化参数,注意有一种情况是dbmgr指定了第2个参数是id,两者兼容
        p->UpdateProps(L);
    }

	the_world.AddEntity(p);
	sp->AddEntity((position_t)x, (position_t)y, p);

    //call __ctor__
    int n = EntityMethodCall(L, p, s_entity_ctor_name, 0, 0);
    //pop n,剩下在栈顶的是entity
    lua_pop(L, n);

    n = EntityMethodCall(L, p, s_entity_enter_space, 0, 0);//kevinmodify
    lua_pop(L, n); 
    
    return 1;
}

static int CreateCellEntityNotInSpace(lua_State* L)
{
    CEntityCell* p = _CreateEntity<CEntityCell>(L);
    if (!p)
    {
        lua_pushstring(L, "CreateCellEntityNotInSpace, can not create entity");
        lua_error(L);
        return 0;
    }

    if(lua_gettop(L) > 1)
    {
        //附带了初始化参数,注意有一种情况是dbmgr指定了第2个参数是id,两者兼容
        p->UpdateProps(L);
    }

    //call __ctor__
    int n = EntityMethodCall(L, p, s_entity_ctor_name, 0, 0);
    //pop n,剩下在栈顶的是entity
    lua_pop(L, n);

    CWorldCell& the_world = GetWorldcell();
    the_world.AddEntity(p);

    return 1;
}

static int DestroyCellEntityLocally(lua_State* L)
{
    CWorldCell& the_world = GetWorldcell();

    TENTITYID eid = (uint32_t)luaL_checkinteger(L, 1);
    CEntityCell* pe = (CEntityCell*)the_world.GetEntity(eid);
    if(pe)
    {
        //printf("destroy_cellentity,%d\n", eid);

        //ClearLuaStack(L);

        EntityMethodCall(L, pe, s_entity_leave_space, 0, 0);
        ClearLuaStack(L);

        EntityMethodCall(L, pe, "onDestroy", 0, 0);

        //从场景中删除
        CSpace* sp = the_world.GetSpace(pe->GetSpaceID());
        if(sp)
        {
            sp->DelEntity(pe);
        }

        //从世界中删除
        the_world.DelEntity(pe);

        //从lua的entity集合中删除
        luaL_getmetatable(L, g_szUserDataEntity);
        lua_pushlightuserdata(L, pe);
        lua_pushnil(L);
        lua_rawset(L, -3);
        //lua_pop(m_L, 1);
        ClearLuaStack(L);

        //test code,检查是否已经从lua中删除掉了
        //int nGcRet = lua_gc(m_L, LUA_GCCOLLECT, 0);
        //printf("lua_gc,ret=%d\n", nGcRet);

    }

    return 0;	
}

int LuaOpenMogoLibCCell(lua_State *L)
{
    LuaOpenEntityLib<CEntityCell>(L);
    //luaopen_spacelib(L);
    
    static const luaL_Reg mogoLib[] =
    {
        {"createEntity", CreateCellEntityLocally},
        {"destroyEntity", DestroyCellEntityLocally},
        {"createEntityNotInSpace", CreateCellEntityNotInSpace},
        //{"createEntityTest", create_entity<CEntityCell>},     //for test
        //{"createSpace", create_space},
        {"createEntityInNewSpace", CreateEntityInNewSpace}, //for test
        {"getEntity",         GetEntity},
        {"getPropId",        GetEntityPropId},
        {"cPickle",            LuaPickle},
        {"cUnpickle",          LuaUnpickle},
        {"readXmlToList",      XmlReadToList},
        {"readXmlToMap",       XmlReadToMap},
        {"readXml",            XmlReadToMapByKey},
        {"readSpace",          XmlReadSpace},
        {"logDebug",     LuaLogDebug},
        {"logInfo",      LuaLogInfo},
        {"logWarning",   LuaLogWarning},
        {"logError",     LuaLogError},
        {"stest",              bit_stest},
        {"sset",               bit_sset},
        {"sunset",             bit_sunset},
        {"pickleMailbox",     PickleMailbox},
        {"UnpickleBaseMailbox",     UnpickleBaseMailbox},
        {"UnpickleCellMailbox",     UnpickleCellMailbox},
        {"MakeBaseMailbox",  MakeBaseMailbox},
        {"MakeCellMailbox",  MakeCellMailbox},
        {"deepcopy1",          DeepCopyTable1},
        {"dist_p2p",           LuaPoint2PointDistance},
        {"dist_p2l",           LuaPoint2LineDistance},
        //{"AddEventListener", AddEventListener},
        //{"RemoveEventListener", RemoveEventListener},
        //{"TrigerEvent", TriggerEvent},
        {"load_bm",            LoadBlockMap },
        {"getTickCount", LuaGetTickCount},
        {"confirm", LuaConfirm},
        {"EntityAllclientsRpc",     EntityAllclientsRpc},
        {"EntityOwnclientRpc",      EntityOwnclientRpc},
        {NULL, NULL}

    };

#ifndef __LUA_5_2_1
    luaL_register(L, s_szMogoLibName, mogoLib);
    //luaL_register之后mogo位于栈顶

    lua_pushstring(L, "cellData");
    lua_newtable(L);
    lua_rawset(L, -3);
#else

    //以下三行代码替换上面注释的代码语句。lua版本5.2中采用以下格式注册c函数，
    //5.1版本中采用上面的方法注册c函数
    lua_newtable(L);
    luaL_setfuncs(L, mogoLib, 0);
    lua_pushstring(L, "cellData");
    lua_newtable(L);
    lua_rawset(L, -3);
    lua_setglobal(L, s_szMogoLibName);

#endif // !__LUA_5.2.1


    ClearLuaStack(L);
    return 0;
}


