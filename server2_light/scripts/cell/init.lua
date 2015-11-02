--cellapp的初始化脚本

local log_game_debug = mogo.logDebug
local log_game_info = mogo.logInfo
local original_print = print
local m_user = 
{
    anyone = 0, --0:所有的print信息都不打印，1：所有的print信息都打印，2：所有的老的print信息打印，新的按照用户设定来打印，3：所有的老的print信息不打印，新的按照用户设定来打印
    wenjie = 1,
    wenjie2 = 0,
    winj = 0,
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
    local all_path = {}
    table.insert(all_path, package.path)
    --table.insert(all_path, string.format("%s/?.lua", g_lua_rootpath) )
    --table.insert(all_path, string.format("%s/?.luac", g_lua_rootpath) )
    table.insert(all_path, string.format("%s/%s/?.lua", g_lua_rootpath, "common") )
    table.insert(all_path, string.format("%s/%s/?.luac", g_lua_rootpath, "common") )
    table.insert(all_path, string.format("%s/%s/?.lua", g_lua_rootpath, "common/data") )
    table.insert(all_path, string.format("%s/%s/?.luac", g_lua_rootpath, "common/data") )
    --table.insert(all_path, string.format("%s/%s/?.lua", g_lua_rootpath, "cell") )
    --table.insert(all_path, string.format("%s/%s/?.luac", g_lua_rootpath, "cell") )
    table.insert(all_path, string.format("%s/%s/?.lua", g_lua_rootpath, "cell/mgr") )
    table.insert(all_path, string.format("%s/%s/?.luac", g_lua_rootpath, "cell/mgr") )
    table.insert(all_path, string.format("%s/%s/?.lua", g_lua_rootpath, "cell/Skill") )
    table.insert(all_path, string.format("%s/%s/?.luac", g_lua_rootpath, "cell/Skill") )
    table.insert(all_path, string.format("%s/%s/?.lua", g_lua_rootpath, "ai") )
    table.insert(all_path, string.format("%s/%s/?.luac", g_lua_rootpath, "ai") )
    table.insert(all_path, string.format("%s/%s/?.lua", g_lua_rootpath, "cell/SpaceLoader") )
    table.insert(all_path, string.format("%s/%s/?.luac", g_lua_rootpath, "cell/SpaceLoader") )
    table.insert(all_path, string.format("%s/%s/?.lua", g_lua_rootpath, "lualibs") )
    package.path = table.concat(all_path, ";")
    log_game_info('package.path',package.path)
    log_game_info("add_all_lua_path", "end=======================================================")
end

--执行
add_all_lua_path()


--加载调试脚本
require "Debug"

--load所有需要的脚本
require "CellEntity"
require "SpaceThing"
--require "mgr_map_cell"
require "SpaceLoader"
require "Avatar"
require "NPC"
require "Monster"
require "SpawnPoint"
require "TeleportPointSrc"
require "Mercenary"
--require "TeleportPointDes"

require "mgr_map_cell"

require "mission_data"
require "drop_data"
require "monster_data"
require "avatar_level_data"
require "skillIdReflect_data"
require "map_data"
--require "SkillUpgradeSystem"
require "GlobalParams"
require "PriceList"

require "vip_privilege"
require "SanctuaryDefense_data"
require "SrvEntityManager"
require "lua_util"
require "guild_data"
require "OblivionPlayManager"
require "client_text_id"
require "ActivityData"

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

    --初始化全局变量
    g_these_spaceloaders = {}

    --初始化全局变量
    gSpaceLoadersPlayerCount = {}    --记录每一个Space的人数

    --空闲SpawnPoint的全局管理器
    gIdleSpawnPointPool = {}

    --繁忙SpawnPoint的全局管理器
    gBusySpawnPointPool = {}

    --空闲怪物的全局管理器
    gIdleMonsterPool = {}

    --繁忙怪物的全局管理器
    gBusyMonsterPool = {}

    --读取配置文件
--    gCellMapMgr:initData()
    g_GlobalParamsMgr:initData()
    g_map_mgr:initData()
    g_SkillSystem:InitData()
    g_mission_mgr:initData()
    g_drop_mgr:initData()
    g_monster_mgr:initData()
    g_monster_mgr:initAIData()
    g_avatar_level_mgr:initData()
    --g_level_pram_mgr:initData()
    --g_skill_upgrade:__ctor__()
    g_priceList_mgr:initData()
    g_vip_mgr:initData()    
    g_sanctuary_defense_mgr:initCellData()
    g_skillIdReflect_mgr:initData()
    gGuildDataMgr:initData()
    gGuildDataMgr:initGragonData()
    g_OblivionPlayManager:InitRewardData()
    g_DefensePvPManager:InitGlobalData()

    --读取活动数据表
    gActivityData:initData()
--    g_GlobalParamsMgr:initData()

end


--网络服务器准备好的回调方法,可以在这里加载游戏管理器
function onServerReady()

    --初始化时创建若干个刷怪点
	g_SrvEntityMgr:initData({[public_config.ENTITY_TYPE_MONSTER]     = 800,
                             [public_config.ENTITY_TYPE_MERCENARY]   = 500})
--    print('init over')
--[[
    local entity = g_SrvEntityMgr:GetIdleEntity(3)
    if entity then
        print('good')
    else
        print('create fail')
    end
--]]
end

function mogo_hotfix_code()
    print("Hot Patch Starting...")
    dofile "../scripts/hotfix_cell.lua"
    print("Hot Patch Complete!")
end


