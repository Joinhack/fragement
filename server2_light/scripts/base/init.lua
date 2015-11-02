--baseapp的初始化脚本

local log_game_debug = mogo.logDebug
local log_game_info = mogo.logInfo
local log_game_error = mogo.logError

local original_print = print
local m_user = 
{
    anyone = 0, --0:所有的print信息都不打印，1：所有的print信息都打印，2：所有的老的print信息打印，新的按照用户设定来打印，3：所有的老的print信息不打印，新的按照用户设定来打印
    wenjie = 1,
    wenjie2 = 0,
    winj = 1,
}
local function _print(usr,...)
    if not usr then return end

    if m_user.anyone == 1 then
        if ... then 
            original_print(...)
        else
            original_print(usr)
        end
    elseif m_user.anyone == 2 then
        if ... then 
            if m_user[usr] == 1 then
                original_print(...)
            end
        else
            original_print(usr)
        end
    elseif m_user.anyone == 3 then
        if ... then 
            if m_user[usr] == 1 then
                original_print(...)
            end
        end    
    elseif m_user.anyone == 0 then
        return
    else

    end
end

print = _print

--print重构单元测试
--[[
print("wenjie","wenjie,hello world.......")
print("winj","winj,hello world.......")
print("wenjie2","wenjie2 hello world.......")
print("anyone hello world.......")
]]

--添加所有的lua脚本路径
local function add_all_lua_path()
    log_game_info("add_all_lua_path", "begin=====================================================")
    log_game_info('package.path',package.path)
    local g_lua_rootpath = G_LUA_ROOTPATH
    log_game_info('G_LUA_ROOTPATH', G_LUA_ROOTPATH)
    local all_path = {}
    table.insert(all_path, package.path)
    --table.insert(all_path, string.format("%s/?.lua", g_lua_rootpath) )
    --table.insert(all_path, string.format("%s/?.luac", g_lua_rootpath) )
    table.insert(all_path, string.format("%s/%s/?.lua", g_lua_rootpath, "common") )
    table.insert(all_path, string.format("%s/%s/?.luac", g_lua_rootpath, "common") )
    table.insert(all_path, string.format("%s/%s/?.lua", g_lua_rootpath, "common/data") )
    table.insert(all_path, string.format("%s/%s/?.luac", g_lua_rootpath, "common/data") )
    --table.insert(all_path, string.format("%s/%s/?.lua", g_lua_rootpath, "base") )
    --table.insert(all_path, string.format("%s/%s/?.luac", g_lua_rootpath, "base") )
    table.insert(all_path, string.format("%s/%s/?.lua", g_lua_rootpath, "base/mgr") )
    table.insert(all_path, string.format("%s/%s/?.luac", g_lua_rootpath, "base/mgr") )
    table.insert(all_path, string.format("%s/%s/?.lua", g_lua_rootpath, "test") )
    table.insert(all_path, string.format("%s/%s/?.luac", g_lua_rootpath, "test") )

    table.insert(all_path, string.format("%s/%s/?.lua", g_lua_rootpath, "base/SubSystem") )
    table.insert(all_path, string.format("%s/%s/?.luac", g_lua_rootpath, "base/SubSystem") )

    table.insert(all_path, string.format("%s/%s/?.lua", g_lua_rootpath, "base/SubSystem/GM") )
    table.insert(all_path, string.format("%s/%s/?.luac", g_lua_rootpath, "base/SubSystem/GM") )

    table.insert(all_path, string.format("%s/%s/?.lua", g_lua_rootpath, "base/SpaceLoader") )
    table.insert(all_path, string.format("%s/%s/?.luac", g_lua_rootpath, "base/SpaceLoader") )
    table.insert(all_path, string.format("%s/%s/?.lua", g_lua_rootpath, "lualibs") )
    table.insert(all_path, string.format("%s/%s/?.luac", g_lua_rootpath, "lualibs") )


    package.path = table.concat(all_path, ";")
    log_game_info('package.path',package.path)
    log_game_info("add_all_lua_path", "end=======================================================")

end

--执行
add_all_lua_path()

--load所有需要的脚本
--require "profiler"
require "Debug"

require "BaseEntity"

require "Avatar"
require "Account"
require "GameMgr"
require "UserMgr"
require "MapMgr"
require "SpaceLoader"
require "EventMgr"
require "Collector"
require "global_data"
require "NPCSystem"
require "TeleportPointSrc"
require "WorldBossMgr"
require "WorldBossData"
require "NameMgr"
require "Guild"
require "GuildMgr"
require "ArenaMgr"
require "ArenaData"
require "MissionMgr"
require "FlyDragonMgr"
require "MissionRecord"
--require "TeleportPointDes"
require "ChargeMgr"
require "CommonXmlConfig"

--子系统
--require "FriendSystem"
--require "BodyEnhanceSystem"

require "InventorySystem"

require "TaskSystem"
require "MarketSystem"
require "HotSalesSystem"

--读取数据的模块
require "avatar_level_data"
require "map_data"
require "mission_data"
require "runeData"
require "spiritData"
require "BodyData"
require "TowerData"
require "JewelData"
require "Item_data"

require "GM"

require "MailMgr"

require "eventData"
--require "lib"
require "_task"
require "_achievement"
require "_father"
require "_day_task"

require "OblivionGateMgr"
require "OblivionGateSystem"
require "DefensePvPMgr"
require "DefensePvPSystem"
require "LevelGiftSystem"
require "role_data"
require "npcData"
require "NPCSystem"

require "message_code"
require "OfflineDataType"

require "monster_data"
require "drop_data"
require "GlobalParams"
require "vip_privilege"
require "item_effect"
require "energy_data"
require "PriceList"
require "jewel_cube"


require "SanctuaryDefense_data"
require "ServerChineseData"
require "client_text_id"

require "worldboss_config"
require "arena_config"
require "guild_data"
require "arenic_level"
require "HpBottleType"
require "mgr_action"
require "GlobalDataMgr"
require "FormularPara"

----单元测试模块
--require "base_test"

require "banned_char"

require "global_data"
require "EventDispatcher"
require "RankListData"
require "ActivityMgr"
require "ActivityData"
require "dragon_data"
require "FumoData"
require "gm_setting_state"
require "mgr_compensate"
require "FightForceFactor_data"
require "elf_data"
require "wing_data"
require "special_effects_data"
require "Jewel_sort_data"
require "charge_data"
require "skill_data"
require "RouletteMgr"
require "roulette_data"

local stopword_mgr = require "mgr_stopword"
local behavior_mgr = require "mgr_behavior" 

--对随机数作一些处理
local function init_random()
    local sd = os.time()    --取当前时间作为随机数种子
    math.randomseed(sd)
    local i = 1
    local test_count = sd % 10 + 10
    --丢弃掉前面的一些随机数
    for i=1,test_count,1 do
        math.random(1,10)
    end
end

--脚本层准备好的回调方法,可以在这里加载数据,不能在这里创建entity
function onScriptReady()
    --对随机数作一些处理
    init_random()

    g_GlobalParamsMgr:initData()
    CommonXmlConfig:Read()
    g_map_mgr:initData()
    TaskSystem:initData()
    g_mission_mgr:initData()
    g_runeDataMgr:initData()
	GMSystem:Init()
	g_spiritDataMgr:initData()
    g_avatar_level_mgr:initData()
    --g_level_pram_mgr:initData()
    g_body_mgr:initData()
    g_itemdata_mgr:initData()
    g_jewel_mgr:initData()
    gTowerDataMgr:initData()
    MarketSystem:initData()
    HotSalesSystem:initData()
    LevelGiftSystem:initData()
    g_roleDataMgr:initData()

    g_eventData:initData()
    --g_libDataMgr:initData()
    g_father:initData()
    Achievement:initData()    
    EventTask:initData() 
    DayTask:initData() 

    g_npcData_mgr:initData()
    NPCSystem:__ctor__()
    g_monster_mgr:initData()
    g_drop_mgr:initData()
    g_vip_mgr:initData()
    item_effect_mgr:initData()
    g_energy_mgr:initData()
    g_priceList_mgr:initData()
    g_sanctuary_defense_mgr:initData()
    g_text_mgr:initData()
    g_jewelCube_mgr:initData()
    g_wb_config:initData()
    gGuildDataMgr:initData()
    gGuildDataMgr:initGragonData()
    gGuildDataMgr:initGuildSkill()
    g_OblivionGateMgr:InitRewardData()
    g_OblivionGateSystem:InitData()
    g_DefensePvPSystem:InitData()
    g_DefensePvPMgr:InitData()
    g_arenic_level:initData()
    g_arena_config:initData()
    g_hpBottleType_mgr:initData()
    g_action_mgr:init_data()
    g_banned_char:initData()
    g_formular_mgr:initData()

    --初始化全局数据模块
    global_data:init_data()

    --初始化事件管理器
    gEventDispatcher:init()
    g_rankList_mgr:initData()

    --读取活动数据表
    gActivityData:initData()
    g_dragon_mgr:initData()

    stopword_mgr:initData()
    g_fumodata:initData()
    g_fightForce_mgr:initData()
    --精灵系统
    g_elf_mgr:initData()
    --通用行为
    behavior_mgr:init_data()


    g_wing_mgr:initData()
    g_spec_mgr:initData()
    g_JewelSort_mgr:initData()
    g_charge_data:initData()
    g_skillData_mgr:initData()
    g_roulette_data:initData()
--    --单元测试代码
--    g_base_test:missiontimes_test()
--    g_base_test:missionuploadcombo()

--    FriendSystem:initData()

end


--网络服务器准备好的回调方法,可以在这里加载游戏管理器
function onServerReady()
    log_game_info("init.onServerReady", "")

    --生成并注册游戏管理器
    --回调方法
    local function _game_mgr_register_callback(eid)
        local gm_eid = eid
        local function __callback(ret)
            local gm = mogo.getEntity(gm_eid)
            if gm then
                if ret == 1 then
                    --注册成功
                    gm:on_registered()
                else
                    log_game_error("init.onServerReady", "===========error===========")
                    --注册失败
                    --print("register error.")
                    --destroy方法未实现,todo
                    mogo.DestroyBaseEntity(eid)
                    --gm.destroy()
                end
            end
        end
        return __callback
    end

    local game_mgr = mogo.createBase("GameMgr")

    game_mgr:RegisterGlobally("GameMgr", _game_mgr_register_callback(game_mgr:getId()))
    ----test code
    --local game_mgr2 = mogo.createBase("GameMgr")
    --game_mgr2:registerGlobally("GameMgr", _game_mgr_register_callback(game_mgr2:getId()))
end

function mogo_hotfix_code()
    print("Hot Patch Starting...")
    dofile "../scripts/hotfix_base.lua"
    print("Hot Patch Complete!")
end




