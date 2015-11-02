---
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 12-6-2
-- Time: ����4:08
-- base���ܲ���.
--

require "public_config"
require "lua_util"
require "mgr_action"
require "MissionSystem"
require "action_config"
--local title_mgr = require "mgr_title"


local log_game_debug = lua_util.LogDebug
local log_game_info = lua_util.LogInfo


local BaseTestMgr = {}
BaseTestMgr.__index = BaseTestMgr
----------------------------------------------------------------------------------------------

--ģ��ͻ���
local sim_client_mt = {
    __index = function(t, f)
        --local s2 = s
        local function cf(...)
            print("call_client> ", f, ...)
        end
        return cf
    end
}
local sim_client = {}
setmetatable(sim_client, sim_client_mt)

local function generic_avatar_call_ne0(...)
    g_action_mgr.generic_avatar_call_ne0(g_action_mgr, ...)
end



--���ܲ��Դ���
function BaseTestMgr:spell_test()
    local function _make_entity(uid, side, rpt)
        local e = {
            [public_config.COMBAT_ATTRI2_MAX_HP] = 1000,
            [public_config.COMBAT_ATTRI2_WULI_ATT] = 100,
            [public_config.COMBAT_ATTRI2_FASHU_ATT] = 50,
            [public_config.COMBAT_ATTRI2_JUEJI_ATT] = 200,
            [public_config.COMBAT_ATTRI2_WULI_DEF] = 30,
            [public_config.COMBAT_ATTRI2_FASHU_DEF] = 40,
            [public_config.COMBAT_ATTRI2_JUEJI_DEF] = 50,
            [public_config.COMBAT_ATTRI2_HIT_P] = 0.2,
            [public_config.COMBAT_ATTRI2_DODGE_P] = 0.2,
            [public_config.COMBAT_ATTRI2_CRITICAL_P] = 0.3,
            [public_config.COMBAT_ATTRI2_RESILIENCE_P] = 0.15,
            [public_config.COMBAT_ATTRI2_POJI_P] = 0.11,
            [public_config.COMBAT_ATTRI2_GEDANG_P] = 0.20,
            [public_config.COMBAT_ATTRI2_BISHA_P] = 0.23,
            [public_config.COMBAT_ATTRI_HP] = 1000,
            [public_config.COMBAT_ATTRI_NUQI] = 0,
            [public_config.COMBAT_ATTRI_SPELL_ID] = 1,
            [public_config.COMBAT_ATTRI_SIDE] = side,
            [public_config.COMBAT_ATTRI_UID] = uid,
            --[public_config.COMBAT_ATTRI_ENTITY_ID] = uid,
            [public_config.COMBAT_ATTRI_POS_X] = 100,
            [public_config.COMBAT_ATTRI_POS_Y] = 200,
            [public_config.COMBAT_ATTRI_REPORT] = rpt,
        }
        return e
    end

    local rpt = {}
    local cc = _make_entity(1, 1, rpt)
    local tgt = _make_entity(2, 2, rpt)
    local ens = {cc, tgt}
    g_cast_mgr:cast_spell(cc, 2, ens)

    local rpt = cc[public_config.COMBAT_ATTRI_REPORT]
    cc[public_config.COMBAT_ATTRI_REPORT] = nil
    tgt[public_config.COMBAT_ATTRI_REPORT] = nil

    print('src:',mogo.cpickle(cc))
    print('tgt:',mogo.cpickle(tgt))
    print('rpt:',mogo.cpickle(rpt))

end

function BaseTestMgr:spell_monster_1v1()


end

--�������
function BaseTestMgr:quest_test()
    local a = {quest_accepted={},quest_completed='', quest_accepted_map={},
        level=5,exp = 0,
        money_cc=0,money_gc=0,money_tl=0,
        pkg_items={},pkg_items_size = 12,
        pkg_warehouse={}, pkg_items_size = 36,
        hasClient= function () end,
        getDbid=function () return 1 end,
        on_levelup = Avatar.on_levelup,
    }

    print(Avatar.quest_accept_req(a, 1001))
    print('quest_accepted:', mogo.cpickle(a.quest_accepted))
    print('quest_accepted:', mogo.cpickle(a.quest_accepted_map))

    Avatar.on_quest_event(a, 21, 101)
    Avatar.on_quest_event(a, 21, 102)
    Avatar.on_quest_event(a, 21, 102)
    Avatar.on_quest_event(a, 22, 201)
    Avatar.on_quest_event(a, 22, 202)
    Avatar.on_quest_event(a, 61, {1,3})
    Avatar.on_quest_event(a, 23, 1)
    Avatar.on_quest_event(a, 23, 1)
    Avatar.on_quest_event(a, 23, 3)
    Avatar.on_quest_event(a, 23, 3)
    Avatar.on_quest_event(a, 23, 3)
    Avatar.on_quest_event(a, 23, 3)
    Avatar.on_quest_event(a, 23, 4)
    Avatar.on_quest_event(a, 23, 4)
    print('quest_accepted:', mogo.cpickle(a.quest_accepted))
    print('quest_accepted:', mogo.cpickle(a.quest_accepted_map))

    print(Avatar.quest_commit_req(a, 1001))
    print('quest_accepted:', mogo.cpickle(a.quest_accepted))
    print('quest_accepted:', mogo.cpickle(a.quest_accepted_map))
    print('pkg_item', mogo.cpickle(a.pkg_items))

    print(Avatar.quest_abort_req(a, 1001))
    print('quest_accepted:', mogo.cpickle(a.quest_accepted))
    print('quest_accepted:', mogo.cpickle(a.quest_accepted_map))
end

function BaseTestMgr:item_test()
    local a = {money_cc=0,money_gc=0,money_tl=0,
        pkg_items={},pkg_items_size = 12,
        pkg_warehouse={}, pkg_items_size = 36,
        getDbid=function() return 1 end,
        hasClient = function() end,
    }

    --���Խ�����
    --g_item_mgr:pay_reward(a, 1,1)

    --������Ʒ
    g_item_mgr:add_item(a, 101, 1, 99)
    print(mogo.cpickle(a.pkg_items))
    g_item_mgr:add_item(a, 101, 11, 99)
    print(mogo.cpickle(a.pkg_items))
    g_item_mgr:add_item(a, 101, 11, 99)
    print(mogo.cpickle(a.pkg_items))

    --�Ƿ�ӵ����Ʒ
    print(g_item_mgr:has_item(a, 101))
    print(g_item_mgr:has_item(a, 101, 2))
    print(g_item_mgr:has_item(a, 101, 50))

    --ɾ����Ʒ
    g_item_mgr:remove_item(a, 1, 3, 99)
    print(mogo.cpickle(a.pkg_items))

    a.getDbid = nil
    a.hasClient = nil
    print(mogo.cpickle(a))
end

--���Գ����ȡ����
function BaseTestMgr:pexp_test()
    local a = {pets={},hasClient=function() return true end,
        getDbid = function() return 1 end, client=sim_client }
    Avatar._random_test_data(a)
    print(mogo.cpickle(a.pets))
    g_item_mgr:add_active_pets_exp(a, 1000, 98)
    print(mogo.cpickle(a.pets))
end

--װ��ǿ��
function BaseTestMgr:equip_qh()
    local equip = {[1]=201,[3]=5}
    local a = {pkg_items={[1]=equip},hasClient=function() return true end,
        getDbid = function() return 1 end, client=sim_client,
        pkg_items_size = 10, money_cc = 100000, xl_level2 = 20,vip=0, level = 5,
        equip_qh_cd1 = 0, equip_qh_cd2 = 0,
    }

    print('qh1', g_item_mgr:equip_strengthen_req(a, 1, 1), a.equip_qh_cd1, a.equip_qh_cd2, mogo.cpickle(equip))
    print('qh2', g_item_mgr:equip_strengthen_req(a, 1, 1), a.equip_qh_cd1, a.equip_qh_cd2, mogo.cpickle(equip))
    print('qh3', g_item_mgr:equip_strengthen_req(a, 1, 1), a.equip_qh_cd1, a.equip_qh_cd2, mogo.cpickle(equip))

    local attri = {}
    g_item_mgr:get_equip_combat_attri(a, equip, attri)
    print('attri:', mogo.cpickle(attri))
end

--��װ��
function BaseTestMgr:equip_load()
    local a = {pkg_items={[1]={[1]=101,[3]=5}},hasClient=function() return true end,
        getDbid = function() return 1 end, client=sim_client,
        pkg_items_size = 10, money_cc = 100000, xl_level2 = 20,
        level = 10, vocation = 3,
        pets = {[1]={[1]=101,[2]=10}}, pkg_loaded = {},
    }

    print('load', g_item_mgr:equip_load_req(a, 1, 1))
    print('items:',mogo.cpickle(a.pkg_items))
    print('loaded:',mogo.cpickle(a.pkg_loaded))
    print('pets:',mogo.cpickle(a.pets))

    print('unload', g_item_mgr:equip_unload_req(a, 1, 5))
    print('items:',mogo.cpickle(a.pkg_items))
    print('loaded:',mogo.cpickle(a.pkg_loaded))
    print('pets:',mogo.cpickle(a.pets))

    print(a.loaded_weapon, a.loaded_cloth)
end

--�ϳ�װ��
function BaseTestMgr:equip_compound()
    local a = {hasClient=function() return true end,
        getDbid = function() return 1 end, client=sim_client,
        pkg_items_size = 10, money_cc = 100000, xl_level2 = 20,
        level = 10, vocation = 3, money_gc = 1000,
        pets = {[1]={[1]=2}}, pkg_loaded = {},
        pkg_items={[1]={[1]=101,[3]=5}, [3]={[1]=301}, [4]={[1]=201,[3]=10},
            [5]={[1]=400,[2]=4},[6]={[1]=401,[2]=6},[7]={[1]=402,[2]=20},},
        pkg_warehouse = {[8]={[1]=400,[2]=4},[9]={[1]=401,[2]=6},[11]={[1]=402,[2]=20}},
    }

    print('items:',mogo.cpickle(a.pkg_items))
    print('warehouse:',mogo.cpickle(a.pkg_warehouse))

    --print('========>', g_item_mgr:equip_compound_req(a, 3, 1, 4, '5,6,7', '8,9,11'))
    print('========>', g_item_mgr:equip_gc_compound_req(a, 3, 1, 4, '5,6,7', '8,9,11'))
    print('items:',mogo.cpickle(a.pkg_items))
    print('warehouse:',mogo.cpickle(a.pkg_warehouse))
end

--�ϳɵ�ҩ
function BaseTestMgr:pill_compound()
    local a = {hasClient=function() return true end,
        getDbid = function() return 1 end, client=sim_client,
        pkg_items_size = 10, money_cc = 100000, xl_level2 = 20,
        level = 10, vocation = 3, money_gc = 1000,
        pets = {[1]={[1]=2}}, pkg_loaded = {},
        pkg_items={[1]={[1]=101,[3]=5}, [3]={[1]=3001}, [4]={[1]=201,[3]=10},
            [5]={[1]=4001,[2]=40},[6]={[1]=4002,[2]=60},[7]={[1]=402,[2]=20},},
        pkg_warehouse = {[8]={[1]=4003,[2]=40},[9]={[1]=401,[2]=6},[11]={[1]=402,[2]=20}},
    }

    print('items:',mogo.cpickle(a.pkg_items))
    print('warehouse:',mogo.cpickle(a.pkg_warehouse))

    --print('========>', g_item_mgr:equip_compound_req(a, 3, 1, 4, '5,6,7', '8,9,11'))
    print('========>', g_item_mgr:pill_compound_req(a, 3, '5,6,7', '8,9,11'))
    print('items:',mogo.cpickle(a.pkg_items))
    print('warehouse:',mogo.cpickle(a.pkg_warehouse))
end

--��Ƕ��ʯ
function BaseTestMgr:gem_load()
    local equip = {[1]=201,[3]=4,}
    local a = {hasClient=function() return true end,
        getDbid = function() return 1 end, client=sim_client,
        pkg_items_size = 10, money_cc = 100000, xl_level2 = 20,
        level = 10, vocation = 3, money_gc = 1000,
        pets = {[1]={[1]=2}}, pkg_loaded = {},
        pkg_items={[1]=equip, [2]={[1]=902,[2]=10}, [3]={[1]=902,[2]=10}},
    }

    print('items:',mogo.cpickle(a.pkg_items))

    print('========>', g_item_mgr:gem_load_req(a, 1, 1, 3, 7) )
    print('items:',mogo.cpickle(a.pkg_items))

    print('========>', g_item_mgr:gem_load_req(a, 1, 1, 3, 4) )
    print('items:',mogo.cpickle(a.pkg_items))

    --print("========>", g_item_mgr:gem_unload_req(a, 1, 1, 7) )
    --print('items:',mogo.cpickle(a.pkg_items))

    local attri = {}
    g_item_mgr:get_equip_combat_attri(a, equip, attri)
    print('attri:', mogo.cpickle(attri))
end

--��ʯ�ϳ�
function BaseTestMgr:gem_compound()
    local a = {hasClient=function() return true end,
        getDbid = function() return 1 end, client=sim_client,
        pkg_items_size = 10, money_cc = 100000, xl_level2 = 20,
        level = 10, vocation = 3, money_gc = 1000,
        pets = {[1]={[1]=2}}, pkg_loaded = {},
        pkg_items={[1]={[1]=903,[2]=14},[2]={[1]=903,[2]=14},[3]={[1]=903,[2]=14},},
        pkg_warehouse = {[2]={[1]=903,[2]=99}},
    }

    print('items:',mogo.cpickle(a.pkg_items))
    print('warehouse:',mogo.cpickle(a.pkg_warehouse))

    print('========>', Avatar.gem_compound_req(a, 903, 904, 15, '1,2,3', '2') )
    print('items222:',mogo.cpickle(a.pkg_items))
    print('warehouse222:',mogo.cpickle(a.pkg_warehouse))

end

--�̵깺����Ʒ
function BaseTestMgr:item_buy()
    local a = {hasClient=function() return true end,
        getDbid = function() return 1 end, client=sim_client,
        pkg_items_size = 2, money_cc = 100000, xl_level2 = 20,
        level = 10, vocation = 3, money_gc = 1000,
        pets = {[1]={[1]=2}}, pkg_loaded = {},
        pkg_items={[1]={[1]=903,[2]=14},[2]={[1]=2001,[2]=90}},
        pkg_warehouse = {[2]={[1]=903,[2]=99}},
        guild_dbid =0 ,guild_gx = 1111,
    }

    print('items:',mogo.cpickle(a.pkg_items))

    print('========>', Avatar.item_buy_req(a, 1050, 2001)  )
    print('items222:',mogo.cpickle(a.pkg_items))
end

--������Ʒ
function BaseTestMgr:item_drop()
    local a = {hasClient=function() return true end,
        getDbid = function() return 1 end, client=sim_client,
        pkg_items_size = 2, money_cc = 100000, xl_level2 = 20,
        level = 10, vocation = 3, money_gc = 1000,
        pets = {[1]={[1]=2}}, pkg_loaded = {},
        pkg_items={[1]={[1]=1001,[8]=2001},[2]={[1]=2001,[2]=90}},
        pkg_warehouse = {[2]={[1]=903,[2]=99}},
        guild_dbid =0 ,guild_gx = 1111,
    }

    print('items:',mogo.cpickle(a.pkg_items))

    print('========>', Avatar.item_drop_req(a, 1, 1001)  )
    print('items222:',mogo.cpickle(a.pkg_items))
end

--������Ʒ
function BaseTestMgr:item_sell()
    local a = {hasClient=function() return true end,
        getDbid = function() return 1 end, client=sim_client,
        pkg_items_size = 2, money_cc = 100000, xl_level2 = 20,
        level = 10, vocation = 3, money_gc = 1000,
        pets = {[1]={[1]=2}}, pkg_loaded = {},
        pkg_items={[1]={[1]=1001,[3]=11},[2]={[1]=2001,[2]=90}},
        pkg_warehouse = {[2]={[1]=903,[2]=99}},
        guild_dbid =0 ,guild_gx = 1111,pkg_sold={},
    }

    print('items:',a.money_cc,mogo.cpickle(a.pkg_items))

    print('========>', Avatar.item_sell_req(a, 1, 1001)  )
    print('items222:',a.money_cc,mogo.cpickle(a.pkg_items),mogo.cpickle(a.pkg_sold))

    print('========>', Avatar.item_redeem_req(a, 1, 1001) )
    print('items333:',a.money_cc,mogo.cpickle(a.pkg_items),mogo.cpickle(a.pkg_sold))
end

--������Ʒ
function BaseTestMgr:item_sort()
    local a = {hasClient=function() return true end,
        getDbid = function() return 1 end, client=sim_client,
        pkg_items_size = 2, money_cc = 100000, xl_level2 = 20,
        level = 10, vocation = 3, money_gc = 1000,
        pets = {[1]={[1]=2}}, pkg_loaded = {},
        pkg_items={[1]={[1]=1001,[3]=11},[2]={[1]=2001,[2]=90},[3]={[1]=1002},
            [4]={[1]=2001,[2]=50},[5]={[1]=2001,[2]=80}},
        pkg_warehouse = {[2]={[1]=903,[2]=99}},
        guild_dbid =0 ,guild_gx = 1111,pkg_sold={},
    }

    print('items:',mogo.cpickle(a.pkg_items))

    print('========>', Avatar.item_sort_req(a, 1, 1001)  )
    print('items222:',mogo.cpickle(a.pkg_items))
end

--�����̵깺����Ʒ
function BaseTestMgr:item_mystery_buy()
    local a = {hasClient=function() return true end,
        getDbid = function() return 1 end, client=sim_client,
        pkg_items_size = 12, money_cc = 100000, xl_level2 = 20,
        level = 9, vocation = 3, money_gc = 1000,
        pets = {[1]={[1]=2}}, pkg_loaded = {},
        pkg_items={[1]={[1]=903,[2]=14},[2]={[1]=2001,[2]=90}},
        pkg_warehouse = {[2]={[1]=903,[2]=99}},
        guild_dbid =10 ,guild_gx = 1111,
        pkg_mystery_shop={[2]=1207301,[1008]=0,[1003]=0,[1005]=0,[1007]=0,[1002]=0,[1004]=0,[1]=1000},
    }

    print('items:',mogo.cpickle(a.pkg_items))

    print('========>', Avatar.item_guild_buy_req(a, 1207301, 1008)  )
    print('mystery1:', mogo.cpickle(a.pkg_mystery_shop))
    print('items222:',mogo.cpickle(a.pkg_items))

    Avatar.item_guild_get_req(a)
    print('mystery2:', mogo.cpickle(a.pkg_mystery_shop))
    Avatar.item_guild_gc_refresh_req(a)
    print('mystery3:', mogo.cpickle(a.pkg_mystery_shop))

end

--�ƶ���Ʒ
function BaseTestMgr:item_move()
    local a = {hasClient=function() return true end,
        getDbid = function() return 1 end, client=sim_client,
        pkg_items_size = 12, money_cc = 100000, xl_level2 = 20,
        level = 9, vocation = 3, money_gc = 1000,
        pets = {[1]={[1]=2}}, pkg_loaded = {},
        pkg_items={[1]={[1]=903,[2]=14},[2]={[1]=2001,[2]=90}},
        pkg_warehouse = {[2]={[1]=903,[2]=99}}, pkg_warehouse_size = 12,
        guild_dbid =10 ,guild_gx = 1111,
    }

    print('items:',mogo.cpickle(a.pkg_items), mogo.cpickle(a.pkg_warehouse))

    print('========>', Avatar.item_move_req(a, 1, 1, 3, 1)  )
    print('items222:',mogo.cpickle(a.pkg_items), mogo.cpickle(a.pkg_warehouse))

end

--��Ƕ����
function BaseTestMgr:soul_load()
    local equip = {[1]=1001,[3]=4,}
    local a = {hasClient=function() return true end,
        getDbid = function() return 1 end, client=sim_client,
        pkg_items_size = 10, money_cc = 100000, xl_level2 = 20,
        level = 10, vocation = 3, money_gc = 1000,
        pets = {[1]={[1]=2}}, pkg_loaded = {},
        pkg_items={[1]=equip, [2]={[1]=902,[2]=10}, [3]={[1]=902,[2]=10}},
        pkg_soul={[3]={[1]=9005,[41]=21,[42]=10,[43]=22,[44]=11,[45]=23,[46]=12,[47]=24,[48]=13,},
            [13]={[1]=9001,[41]=21,[42]=10,[43]=22,[44]=11,[45]=23,[46]=12,[47]=24,[48]=13,},
            [4]={[1]=9002}},
    }

    print('items:',mogo.cpickle(a.pkg_items[1]), mogo.cpickle(a.pkg_soul))

    print('========>', g_item_mgr:soul_load_req(a, 1, 1, 13, 40) )
    print('items:',mogo.cpickle(a.pkg_items[1]), mogo.cpickle(a.pkg_soul))

    print('========>', g_item_mgr:soul_load_req(a, 1, 1, 3, 49) )
    print('items:',mogo.cpickle(a.pkg_items[1]), mogo.cpickle(a.pkg_soul))

    print('========>', g_item_mgr:soul_unload_req(a, 1, 1, 49) )
    print('items:',mogo.cpickle(a.pkg_items[1]), mogo.cpickle(a.pkg_soul))

end

--�������Լ���
function BaseTestMgr:soul_active()
    local equip = {[1]=1001}
    local a = {hasClient=function() return true end,
        getDbid = function() return 1 end, client=sim_client,
        pkg_items_size = 10, money_cc = 100000, xl_level2 = 20,
        level = 10, vocation = 3, money_gc = 143,
        pets = {[1]={[1]=2}}, pkg_loaded = {},
        pkg_items={[3]=equip},pkg_soul={}, soul_wash_count = 0,soul_chip=3,
    }

    local soul = g_item_mgr:soul_new_item(a, 9001)
    a.pkg_soul[13]= soul

    print('soul:',mogo.cpickle(soul))
    print('items:',mogo.cpickle(a.pkg_items))

    local soul_key = 40

    print('========>', g_item_mgr:soul_load_req(a, 1, 3, 13, soul_key) )
    print('items:',mogo.cpickle(a.pkg_items))

    print('========>', g_item_mgr:soul_active_req(a, 1, 3, soul_key, 1) )
    print('items:',mogo.cpickle(a.pkg_items))

    print('========>', g_item_mgr:soul_active_req(a, 1, 3, soul_key, 2) )
    print('items:',mogo.cpickle(a.pkg_items))

    print('========>', g_item_mgr:soul_active_req(a, 1, 3, soul_key, 3) )
    print('items:',mogo.cpickle(a.pkg_items))

    print('========>', g_item_mgr:soul_active_req(a, 1, 3, soul_key, 4) )
    print('items:',mogo.cpickle(a.pkg_items))

    print('wash========>', g_item_mgr:soul_wash_req(a, 1, 3, soul_key, 0) )
    print('items:',mogo.cpickle(a.pkg_items))

    print('wash========>', g_item_mgr:soul_wash_req(a, 1, 3, soul_key, 15) )
    print('items:',mogo.cpickle(a.pkg_items))

    print('wash========>', g_item_mgr:soul_wash_req(a, 1, 3, soul_key, 3) )
    print('items:',mogo.cpickle(a.pkg_items))

end

--���Ե����Ʒ
function BaseTestMgr:clickitem()
    local rpt = {}
    local a = {hasClient=function() return true end,
        getDbid = function() return 1 end, client=sim_client,
        pkg_items_size = 10, money_cc = 100000, xl_level2 = 20,
        level = 10, vocation = 3, money_gc = 143,
        pets = {[1]={[1]=2}}, pkg_loaded = {},
        pkg_items={},pkg_soul={}, soul_wash_count = 0,soul_chip=3,
        quest_accepted = {[2001]={}},
        on_quest_event = Avatar.on_quest_event,
        tmp_data = {[7]={
                         [11]={
                             [112]={
                                 [67]=1,      --monster_id,click_id
                                 [54]=100,    --x
                                 [55]=150,    --y
                             } },   --clickitems
                         [2] ={
                             [3] ={
                                 [54] = 100,   --x
                                 [55] = 200,   --y
                                 [60] = rpt,
                             }
                         }   ,   --entities
        }},
    }

    Avatar.combat_click_req(a, 112)
    print('rpt',mogo.cpickle(rpt))
end

--���Ը���ɨ��
function BaseTestMgr:ins_sweep()
    local rpt = {}
    local a = {hasClient=function() return true end,
        getDbid = function() return 1 end, client=sim_client,
        pkg_items_size = 10, money_cc = 100000, xl_level2 = 20,
        level = 10, vocation = 3, money_gc = 143,
        pets = {[1]={[1]=2}}, pkg_loaded = {},
        pkg_items={},pkg_soul={}, soul_wash_count = 0,soul_chip=3,
        quest_accepted = {[2001]={}},
        on_quest_event = Avatar.on_quest_event,exp = 0,
    }

    print('ins_sweep', g_ins_mgr:ins_sweep_req(a, 20001, 1))
end

--3v3���������а����
function BaseTestMgr:rank10_test()
    --local key_dbid = 1
    --local key_credit = 8
    local vs = mogo.createBase("Vs33Mgr")
    print('vs33',vs.rank10_count, vs.rank10_credit, vs.rank10_version)

    for i = 1, 20 do
        vs:_add_to_rank10({[1]=100+i,[8]=i}, i)
        print('vs33',vs.rank10_count, vs.rank10_credit, vs.rank10_version)
    end

    print('rank10')
    for k,v in pairs(vs.rank10) do
        print(k,mogo.cpickle(v) )
    end
end

--�ƺŲ���
function BaseTestMgr:title_test()
    local a = {
        title = '', title_inuse = 0, title_time = {},
        hasClient=function() return true end,
        getDbid = function() return 1 end, client=sim_client,
    }

    print('title_test---------------------------')
    print('del',title_mgr:del_title(a, 2))
    print('use',Avatar.title_use_req(a, 2))
    print('remove',Avatar.title_remove_req(a, 1))
    print('add',title_mgr:add_title(a, 1))
    print('add',title_mgr:add_title(a, 1))
    print('add',title_mgr:add_title(a, 111))
    print('use',title_mgr:title_use_req(a, 1))
    print('add4',title_mgr:add_title(a, 4))
    print('use4',title_mgr:title_use_req(a, 4))
    print('del',title_mgr:del_title(a, 2))
    print('use',title_mgr:title_use_req(a, 2))

    print('title', string.byte(a.title), mogo.cpickle(a.title_time))
    print('check', title_mgr:check_title_time(a))
    print('title', string.byte(a.title), mogo.cpickle(a.title_time))

end

--�ճ��������
function BaseTestMgr:daily_test()
    local a = {
        level = 41, quest_daily = {}, money_gc = 100, quest_accepted = {},
        quest_accepted_map = {}, money_cc = 0, exp = 1,
        hasClient=function() return true end,
        getDbid = function() return 1 end, client=sim_client,
    }

    --print('refresh', g_quest_mgr:daily_refresh(a))
    --print('refresh', g_quest_mgr:daily_refresh(a))
    --print('gc_refresh', g_quest_mgr:daily_gc_refresh(a))
    print('accept', Avatar.quest_accept_req(a,50012))
    print(mogo.cpickle(a.quest_daily), mogo.cpickle(a.quest_accepted), mogo.cpickle(a.quest_accepted_map))
    print('commit', Avatar.quest_commit_req(a, 50012))
    local tmp = a.quest_accepted[50012]
    if tmp then
        --tmp[1] = 3
    end
    print('commit2', g_quest_mgr:quest_commit_req(a, 50012))
    print('gccmt', Avatar.daily_gc_cmt_req(a, 50012))
    print(mogo.cpickle(a.quest_daily), mogo.cpickle(a.quest_accepted), mogo.cpickle(a.quest_accepted_map))
    print('abort', g_quest_mgr:quest_abort_req(a, 50012))
    print(mogo.cpickle(a.quest_daily), mogo.cpickle(a.quest_accepted), mogo.cpickle(a.quest_accepted_map))
    print('getback', Avatar.daily_get_back_req(a))
    print(mogo.cpickle(a.quest_daily))
end

function BaseTestMgr:missiontimes_test()
    local a = {
        hasClient= function () end,
        getDbid=function () return 1 end,
        client = sim_client,
        state = 0,
        VipLevel = 1,
        VipRealState = {},
        MissionTimes = {}
    }

    generic_avatar_call_ne0(a, action_config.MSG_ADD_FINISHED_MISSIONS, gMissionSystem, gMissionSystem:getC2BFuncByMsgId(action_config.MSG_ADD_FINISHED_MISSIONS), "", 10101, 1, "100")

end

function BaseTestMgr:missionuploadcombo()
    local a = {
        hasClient= function () end,
        getDbid=function () return 1 end,
        client = sim_client,
        state = 0,
        MissionTempData = {60, 10101, 1,},
        name = 'liangbohao',
        dbid = 0,
        VipLevel = 0,
        hpCount = 3,
    }
    generic_avatar_call_ne0(a, action_config.MSG_UPLOAD_COMBO, gMissionSystem, gMissionSystem:getFuncByMsgId(action_config.MSG_UPLOAD_COMBO), "", 10, 0, "")
end
--------------------------------------------------------------------------------------------------
--道具系统
--------------------------------------------------------------------------------------------------
function BaseTestMgr:get_avatar()
    local a = {
        hasClient = function () end,
        getDbid   = function () return 1 end,
        client    = sim_client,
        name      = "luna",
        dbid      = 1,
        generals  = {},
        equipeds  = {},
        jewels    = {},
        materials = {},
        vocation  = 1,
        VipLevel  = 0,
        gold      = 0,
        diamond   = 0,
        energy    = 180,
        level     = 1,
        chargeSum = 0,
    }
    a.inventorySystem = InventorySystem:new(a)
    return a
end
function BaseTestMgr:action_add_items()
    local a = self:get_avatar()
    --g_action_mgr:generic_avatar_call(a, a:getDbid(), g_action_mgr, 'test_add_items', 'log;typeId=%d;count=%d', 1293600, 1)
    -- g_action_mgr:generic_avatar_call(a, a:getDbid(), g_action_mgr, 'test_add_items', 'log;typeId=%d;count=%d', 1100016, 1)
    -- g_action_mgr:generic_avatar_call(a, a:getDbid(), g_action_mgr, 'test_add_items', 'log;typeId=%d;count=%d', 1293301, 1)
    -- g_action_mgr:generic_avatar_call(a, a:getDbid(), g_action_mgr, 'test_add_items', 'log;typeId=%d;count=%d', 1293301, 1)
    -- g_action_mgr:generic_avatar_call(a, a:getDbid(), g_action_mgr, 'test_add_items', 'log;typeId=%d;count=%d', 1100016, 1)
     g_action_mgr:generic_avatar_call(a, a:getDbid(), g_action_mgr, 'test_add_items', 'log;typeId=%d;count=%d', 1100036, 1)
    -- g_action_mgr:generic_avatar_call(a, a:getDbid(), g_action_mgr, 'test_add_items', 'log;typeId=%d;count=%d', 1100016, 1)
    -- g_action_mgr:generic_avatar_call(a, a:getDbid(), g_action_mgr, 'test_add_items', 'log;typeId=%d;count=%d', 1100036, 1)
    -- g_action_mgr:generic_avatar_call(a, a:getDbid(), g_action_mgr, 'test_add_items', 'log;typeId=%d;count=%d', 1293600, 1)
    -- g_action_mgr:generic_avatar_call(a, a:getDbid(), g_action_mgr, 'test_add_items', 'log;typeId=%d;count=%d', 1293301, 1)
    -- g_action_mgr:generic_avatar_call(a, a:getDbid(), g_action_mgr, 'test_add_items', 'log;typeId=%d;count=%d', 1100036, 1)
end
function BaseTestMgr:action_del_items()
    local a = self:get_avatar()
    for i = 0, 20 do
        g_action_mgr:generic_avatar_call(a, a:getDbid(), g_action_mgr, 'test_add_items', 'log;typeId=%d;count=%d', 1212600, i)
    end
    for i = 0, 20 do
        g_action_mgr:generic_avatar_call(a, a:getDbid(), g_action_mgr, 'test_del_items', 'log;typeId=%d;count=%d', 1212600, i)
    end
end
function  BaseTestMgr:action_init_role()
    local a = self:get_avatar()
    g_action_mgr:generic_avatar_call(a, a:getDbid(), g_action_mgr, 'test_init_role', 'log;vocation=%d;dbid=%q', a.vocation, a:getDbid())
end
function BaseTestMgr:action_tidy_inventory()
    local a = self:get_avatar()
    g_action_mgr:generic_avatar_call(a, a:getDbid(), g_action_mgr, 'test_tidy_inventory', 'log;vocation=%d;dbid=%q', a.vocation, a:getDbid())
end
function BaseTestMgr:action_use_item()
    local a = self:get_avatar()
    g_action_mgr:generic_avatar_call(a, a:getDbid(), g_action_mgr, 'test_use_item', 'log;vocation=%d;dbid=%q', a.vocation, a:getDbid())
end
function BaseTestMgr:action_replace_equipment()
    local a = self:get_avatar()
    g_action_mgr:generic_avatar_call(a, a:getDbid(), g_action_mgr, 'test_replace_equipment', 'log;vocation=%d;dbid=%q', a.vocation, a:getDbid())
end
function BaseTestMgr:action_decompose_equipment()
    local a = self:get_avatar()
    g_action_mgr:generic_avatar_call(a, a:getDbid(), g_action_mgr, 'test_decompose_equipment', 'log;vocation=%d;dbid=%q', a.vocation, a:getDbid())
end
function BaseTestMgr:action_sell_items()
    local a = self:get_avatar()
    g_action_mgr:generic_avatar_call(a, a:getDbid(), g_action_mgr, 'test_sell_items', 'log;vocation=%d;dbid=%q', a.vocation, a:getDbid())
end
function BaseTestMgr:action_lock_equipment()
    local a = self:get_avatar()
    g_action_mgr:generic_avatar_call(a, a:getDbid(), g_action_mgr, 'test_lock_equipemnt', 'log;vocation=%d;dbid=%q', a.vocation, a:getDbid())
end
function BaseTestMgr:action_charge_diamond()
    local a = self:get_avatar()
    local chrg      = {}
    chrg['rmb']     = 50
    chrg['diamond'] = 50
    for i = 1, 10000 do
        g_action_mgr:generic_avatar_call(a, a:getDbid(), g_action_mgr, 'test_charge_diamond', 'log;rmb=%d;diamond=%d', chrg.rmb, chrg.diamond)
    end
end
function BaseTestMgr:action_present_diamond()
    local a = self:get_avatar()
    local chrg      = {}
    chrg['diamond'] = 50
    for i = 1, 10000 do
        g_action_mgr:generic_avatar_call(a, a:getDbid(), g_action_mgr, 'test_present_diamond', 'log;diamond=%d', chrg.diamond)
    end
end
----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

g_base_test = BaseTestMgr
return g_base_test

