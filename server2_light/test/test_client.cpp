#include <iostream>
#include <algorithm>
//#include <lua.hpp>

//#include "lua_mogo.h"
//#include "space.h"
#include "world_base.h"
//#include "lua_cell.h"
//
//#include "lua_base.h"
#include "pluto.h"
#include "net_util.h"

void send_str(int fd, const char* s)
{
    CPluto c1;
	c1.Encode(MSGID_BASEAPP_LUA_DEBUG);
	c1 << s << EndPluto;
    PrintHexPluto(c1);
    send(fd, c1.GetBuff(), c1.GetLen(), 0);
}

void send_shutdown(int fd)
{
    CPluto c1;
    c1.Encode(MSGID_BASEAPPMGR_SHUTDOWN_SERVERS);
    c1 << (uint8_t)1 << EndPluto;
    PrintHexPluto(c1);
    send(fd, c1.GetBuff(), c1.GetLen(), 0);
}

world* g_pTheWorld = new CWorldBase;

int main(int argc, char* argv[])
{

    if(argc < 3)
    {
        printf("Usage:%s etc_fn server_id log_fn\n", argv[0]);
        return -1;
    }

    const char* address = argv[1];
    unsigned int port = (unsigned int)atoi(argv[2]);


    cout << "test_client begin" << endl;

    int fd = MogoSocket();
    int nRet = MogoConnect(fd, address, port);

	//CPluto c1;
	//c1.Encode(MSGID_ALLAPP_SHUTDOWN_SERVER);
	//c1 << EndPluto;
	//PrintHexPluto(c1);
	//send(fd, c1.GetBuff(), c1.GetLen(), 0);
    
	/*
	CPluto c1;
    c1.encode(MSGID_BASEAPP_LUA_DEBUG);
    //c1 << "print(G_LUATABLES);for k,v in pairs(G_LUATABLES) do print(k,v) end";
    //c1 << "local e = mogo.get_entity(100663297);e:select_first_general_req(102);local function dummy(a,b,c) local d=0 end;e:writeToDB(dummy)";
    //c1 << "local e = mogo.get_entity(100663297);e.money_gold= 200;e:item_buy_req(101,2);local function dummy(a,b,c) local d=0 end;e:writeToDB(dummy)";
    //c1 << "local e = mogo.get_entity(100663297);e:equip_strengthen_req(1,1,0,0);local function dummy(a,b,c) local d=0 end;e:writeToDB(dummy)";
    //c1 << "local e = mogo.get_entity(100663297);e:equip_strengthen_req(1,1,1,1);print('qh_level:',e.item_equips[1][5])";
    //c1 << "local e = mogo.get_entity(100663297);e:table_get_req('item_equips');e:table_get_req('item_items');e:table_get_req('item_loaed');e:table_get_req('buildings');e:table_get_req('generals');";
    //c1 << "local e = mogo.get_entity(100663297);e.generals[1]={[1]=101};e.formation_skill[1]=1;e:formation_add_general_req(101,1,1)";
//    c1 << "for i=0, 20 do local e = mogo.get_entity(100663297+i);mogo.LogDebug('level', string.format('%s_%d_%d_%d', e.name,e.level, i, e:getId())) end";
    //c1 << "local e = mogo.get_entity(100663297);e.buildings[15]=20;print('skill_levelup:',g_skill_mgr:skill_levelup_req(e, 1))";
    //c1 << "local e = cw.get_entity(100663297);e.level=50;g_building_mgr:on_avatar_levelup(e)";
   // c1 << "local e = cw.get_entity(184549416);e:map_get_entities(101, 10, 20, 5)";
    //c1 << "local e = cw.get_entity(184549416);e.item_max_count=40;e.item_items={};local m=g_ins_mgr:accept_ins(e,1);local n=g_ins_mgr:attack_troops(e,1,1,1);print(m,n)";
    //c1 << "local e = cw.get_entity(184549416);cw.LogInfo('1111111','');e:gm_req('@vs 19 19');cw.LogInfo('2222222','')";
    //c1 << "local e = cw.createBase('Avatar');print(e:hasCell());local aaa = globalBases['SpaceLoader_1'];e:createCellEntity(aaa, 10, 20, '5,11');print(e:hasCell())";
    //c1 << "local e = cw.createBase('Avatar');e.level=23;e.ins_completed='ff';e:map_create_city_req(1, 40, 21)";
    //c1 << "local e = cw.get_entity(184549419);local s = g_combat_mgr:create_avatar_troops_info(e);local s2=cw.cpickle(s);print(#s2,s2)";
    //c1 << "local e = cw.get_entity(50331649);e:ins_chatan_troop_req(1)";
    //c1 << "local e = cw.get_entity(50331812);e:map_occupy_req(1)";
    //c1 << "for k,v in pairs(_G) do print(k,v) end";
    c1 << "local bd = cw.baseData;cw.setBaseData('int',111);cw.setBaseData('float',1.234);cw.setBaseData('str', 'abcd');cw.setBaseData('table', {[1]=1,a='bbb'})";
    //c1 << "local bd=cw.baseData;print(bd.int,bd.float,bd.str,bd.table,cw.cpickle(bd.table))";
    //c1 << "cw.setBaseData('int',nil);cw.setBaseData('str',nil)";
    //c1 << "print(cw.cpickle(globalBases['SpaceLoader_1']))";
    //c1 << "local e = cw.get_entity(184549418);print(e:hasCell())";
    //c1 << "local function f(...) end;for i=20001,30000 do local e = cw.createBase('Avatar');e.name=string.format('bot_%d',i);e:writeToDB(f) end";
    //c1 << "cw.loadAllAvatars()";
    //c1 << "cw.createBaseFromDBByNameAnywhere('Account', 's77')";
    c1 << endPluto;
	//*/

	/*
	CPluto c1;
    c1.encode(MSGID_BASEAPP_CLIENT_RPCALL);
    c1 << (int32_t) 0;
    c1 << (int8_t) 112 << "first_client_rpc";
    c1 << endPluto;
	//*/

    //print_hex_pluto(c1);

	//send(fd, c1.getBuff(), c1.getLen(), 0);

	/*
	send_str(fd, "local bd = cw.baseData;cw.setBaseData('int',111);cw.setBaseData('float',1.234);cw.setBaseData('str', 'abcd');cw.setBaseData('table', {[1]=1,a='bbb'})");
	send_str(fd, "local bd=cw.baseData;print(bd.int,bd.float,bd.str,bd.table,cw.cpickle(bd.table))");
	send_str(fd, "cw.setBaseData('int',nil);cw.setBaseData('str',nil)");
	send_str(fd, "cw.setBaseData('int','int');cw.setBaseData('str',123)");
	send_str(fd, "local bd=cw.baseData;print(bd.int,bd.float,bd.str,bd.table,cw.cpickle(bd.table))");
    //*/
	//"globalBases['ChargeMgr'].onChargeReq(1, '', 'order_id=14&uid=gongda&plat=0&callback_info=4294967298&amount=1')"
	//"globalBases['UserMgr'].Update(4294967298,{[5]=35})"
	send_str(fd, argv[3]);


    return 0;
}

