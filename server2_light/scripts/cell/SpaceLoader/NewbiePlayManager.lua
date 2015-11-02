
require "BasicPlayManager"
require "mission_config"
require "lua_util"

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error

NewbiePlayManager = BasicPlayManager.init()

function NewbiePlayManager:init()
--    log_game_debug("BasicPlayManager:init", "")

    local obj = {}
    setmetatable(obj, {__index = NewbiePlayManager})
    obj.__index = obj

    obj.PlayerInfo = {}
    obj.CellInfo = {}
    obj.Events = {}

    obj.StartTime = 0
    obj.EndTime = 0

    obj.CellInfo[mission_config.SPECIAL_MAP_INFO_OWNER_DBID] = 0
    obj.CellInfo[mission_config.SPECIAL_MAP_INFO_OWNER_NAME] = ''
    obj.CellInfo[mission_config.SPECIAL_MAP_INFO_OWNER_MBSTR] = ''
    obj.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID] = 0
    obj.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT] = 0
    obj.CellInfo[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT] = {}               --初始化已触发的刷怪点
    obj.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_PROCESS] = {}                   --初始化副本进度
    obj.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID] = 0                       --副本结束的定时器ID
    obj.CellInfo[mission_config.SPECIAL_MAP_INFO_SUCCESS_TIMER_ID] = 0
    return obj
end

function NewbiePlayManager:DeathEvent(dbid, SpaceLoader)

    if not self.PlayerInfo[dbid] then
        log_game_error("NewbiePlayManager:DeathEvent", "dbid=%q", dbid)
        return
    end

    local eid = self.PlayerInfo[dbid][public_config.PLAYER_INFO_INDEX_EID]
    local player = mogo.getEntity(eid)
    if not player then
        log_game_error("NewbiePlayManager:DeathEvent", "dbid=%q", dbid)
        return
    end

    log_game_debug("NewbiePlayManager:DeathEvent", "dbid=%q;name=%s", dbid, player.name)
    --玩家在新收关死后离开副本
    player.base.MissionReq(action_config.MSG_EXIT_MISSION, 0, 0, '')

end
