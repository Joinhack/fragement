
require "BasicPlayManager"
require "map_data"
require "lua_util"


local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning


DefensePvPManager = BasicPlayManager.init()

function DefensePvPManager:init(game_id)
--    log_game_debug("DefensePvPManager:init", "")

    local newObj = {}
    newObj.ptr   = {}
    setmetatable(newObj, 		{__index = DefensePvPManager})
    setmetatable(newObj.ptr,    {__mode = "v"})

    newObj.gameId = game_id

    newObj.StartTime = 0
    newObj.Info = {}
    newObj.Info[mission_config.SPECIAL_MAP_INFO_OWNER_DBID] = 0
    newObj.Info[mission_config.SPECIAL_MAP_INFO_OWNER_NAME] = ''
    newObj.Info[mission_config.SPECIAL_MAP_INFO_OWNER_MBSTR] = ''
    newObj.Info[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT] = {}              --初始化已触发的刷怪点
    newObj.Info[mission_config.SPECIAL_MAP_INFO_FINISHED_SPAWN_POINT] = {}             --初始化已经完成的刷怪点
    newObj.Info[mission_config.SPECIAL_MAP_INFO_MISSION_ID] = 0
    newObj.Info[mission_config.SPECIAL_MAP_INFO_DIFFICULT] = 0
    newObj.Info[mission_config.SPECIAL_MAP_INFO_DROP] = {}                             --初始化已经掉落的物品信息
    newObj.PlayerInfo = {}

    return newObj
end

function DefensePvPManager:ExitMission(avatar_dbid, space_loader)
    space_loader.cell.ExitMission(avatar_dbid)
end

function DefensePvPManager:SetMissionInfo(playerDbid, playerName, playerMbStr, missionId, difficult, SpaceLoader)
    log_game_debug("DefensePvPManager:SetMissionInfo", "dbid=%q;name=%s;mb=%s;missionId=%d;difficult=%d", playerDbid, playerName, playerMbStr, missionId, difficult)

--    self.Info[mission_config.SPECIAL_MAP_INFO_OWNER_DBID] = playerDbid
--    self.Info[mission_config.SPECIAL_MAP_INFO_OWNER_NAME] = playerName
--    self.Info[mission_config.SPECIAL_MAP_INFO_OWNER_MBSTR] = playerMbStr
--    self.Info[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT] = {}              --初始化已触发的刷怪点
--    self.Info[mission_config.SPECIAL_MAP_INFO_FINISHED_SPAWN_POINT] = {}             --初始化已经完成的刷怪点
--    self.Info[mission_config.SPECIAL_MAP_INFO_MISSION_ID] = missionId
--    self.Info[mission_config.SPECIAL_MAP_INFO_DIFFICULT] = difficult
--    self.Info[mission_config.SPECIAL_MAP_INFO_DROP] = {}                             --初始化已经掉落的物品信息
--
--    self.PlayerInfo[playerDbid] = {[1] = playerName, [2] = mogo.UnpickleBaseMailbox(playerMbStr)}
--
--    SpaceLoader.cell.SetCellInfo(playerDbid, playerName, playerMbStr, missionId, difficult)
end


----------------------------------------------------------------

return DefensePvPManager