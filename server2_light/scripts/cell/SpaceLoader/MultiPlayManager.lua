
require "BasicPlayManager"
require "lua_util"

local log_game_debug = lua_util.log_game_debug

MultiPlayManager = BasicPlayManager.init()

function MultiPlayManager:init()
--    log_game_debug("MultiPlayManager:init", "")
    local obj = {}
    setmetatable(obj, {__index = MultiPlayManager})
    obj.__index = obj

    obj.PlayerInfo = {}
    obj.CellInfo = {}
    obj.Events = {}

    obj.StartTime = 0
    obj.EndTime = 0

    obj.CellInfo[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT] = {}               --初始化已触发的刷怪点
    obj.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_PROCESS] = {}                   --初始化副本进度
    obj.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID] = 0                       --副本结束的定时器ID

    return obj
end

function MultiPlayManager:SetCellInfo(playerDbid, playerName, playerMbStr, missionId, difficult)

    log_game_debug("MutiPlayManager:SetCellInfo", "dbid=%q;name=%s;mb=%s;missionId=%d;difficult=%d",
                                                    playerDbid, playerName, playerMbStr, missionId, difficult)

    self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID] = missionId
    self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT] = difficult
    self.CellInfo[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT] = {}               --初始化已触发的刷怪点
    self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_PROCESS] = {}                   --初始化副本进度
    self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID] = 0                       --副本结束的定时器ID

    --初始化副本事件表
    self.Events = {}

    local missionId = tostring(self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID])
    local difficult = tostring(self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT])

    local tbl = {}
    table.insert(tbl, missionId)
    table.insert(tbl, difficult)

    local cfg = g_mission_mgr:getCfgById(table.concat(tbl, "_"))

    if cfg and cfg['events'] then
        for _, event in pairs(cfg['events']) do
            local EventCfg = g_mission_mgr:getEventCfgById(event)
            if EventCfg then
                if EventCfg['param'] and EventCfg['type'] == mission_config.SPECIAL_MAP_EVENT_SPAWNPOINT_MONSTER_ALL_DEAD then
                    local params = lua_util.split_str(EventCfg['param'], ",", tonumber)
                    local result = {}
                    for _, param in pairs(params) do
                        result[param] = false
                    end
                    self.Events[event] = {[mission_config.SPECIAL_MAP_EVENT_SPAWNPOINT_MONSTER_ALL_DEAD] = result}
                end
            end
        end
    end

end

return MultiPlayManager
