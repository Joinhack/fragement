
require "public_config"
require "mission_config"
require "mission_data"
require "map_data"
require "lua_util"
require "BasicPlayManager"

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning

--local TIMER_ID_END     = 1    --副本(关卡)结束的定时器
--local TIMER_ID_SUCCESS = 2    --副本(关卡)成功后的定时器

TowerPlayManager = BasicPlayManager.init()

function TowerPlayManager:init()
--    log_game_debug("TowerPlayManager:init", "")
    local obj = {}
    setmetatable(obj, {__index = TowerPlayManager})
    obj.__index = obj

    obj.StartTime = 0
    obj.Info = {}
--    obj.Info[mission_config.SPECIAL_MAP_INFO_OWNER_DBID] = 0
--    obj.Info[mission_config.SPECIAL_MAP_INFO_OWNER_NAME] = ''
--    obj.Info[mission_config.SPECIAL_MAP_INFO_OWNER_MBSTR] = ''
--    obj.Info[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT] = {}              --初始化已触发的刷怪点

    obj.Info[mission_config.SPECIAL_MAP_INFO_OWNER_DBID] = 0
    obj.Info[mission_config.SPECIAL_MAP_INFO_OWNER_NAME] = ''
    obj.Info[mission_config.SPECIAL_MAP_INFO_OWNER_MBSTR] = ''
    obj.Info[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT] = {}              --初始化已触发的刷怪点
    obj.Info[mission_config.SPECIAL_MAP_INFO_FINISHED_SPAWN_POINT] = {}             --初始化已经完成的刷怪点
    obj.Info[mission_config.SPECIAL_MAP_INFO_MISSION_ID] = 0
    obj.Info[mission_config.SPECIAL_MAP_INFO_DIFFICULT] = 0
    obj.Info[mission_config.SPECIAL_MAP_INFO_DROP] = {}                             --初始化已经掉落的物品信息

    return obj
end

function TowerPlayManager:NotifyRewardsToClient(playerDbid)

end




return TowerPlayManager