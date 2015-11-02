
require "BasicPlayManager"
require "map_data"
require "lua_util"

local log_game_warning = lua_util.log_game_warning
local log_game_debug = lua_util.log_game_debug

MultiPlayManager = BasicPlayManager.init()

function MultiPlayManager:init()
--    log_game_debug("MultiPlayManager:init", "")
    local obj = {}
    setmetatable(obj, {__index = MultiPlayManager})
    obj.__index = obj

    obj.StartTime = 0
    obj.PlayerInfo = {}

    obj.Info = {}
    obj.Info[mission_config.SPECIAL_MAP_INFO_OWNER_DBID] = 0
    obj.Info[mission_config.SPECIAL_MAP_INFO_OWNER_NAME] = ''
    obj.Info[mission_config.SPECIAL_MAP_INFO_OWNER_MBSTR] = ''
    obj.Info[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT] = {}              --初始化已触发的刷怪点

    return obj
end

function MultiPlayManager:CheckEnter(mbStr, dbid, name, map_id)
    local srcMapId = g_map_mgr:GetSrcMapId(map_id)
    local MapCfg = g_map_mgr:getMapCfgData(srcMapId)
    local map_imap = lua_util.split_str(map_id, "_", tonumber)

    if not MapCfg then
        log_game_warning("MultiPlayManager:CheckEnter not config", "dbid=%q;name=%sscene=%d;line=%d", 
                                                                    dbid, name, map_imap[1], map_imap[2])
        lua_util.globalbase_call("MapMgr", "CheckEnterResp", -2, mbStr, map_imap[1], map_imap[2], dbid, name)
        return
    end

    if lua_util.get_table_real_count(self.PlayerInfo) >= MapCfg['maxPlayerNum'] then
        lua_util.globalbase_call("MapMgr", "CheckEnterResp", -3, mbStr, map_imap[1], map_imap[2], dbid, name)
        return
    end

    lua_util.globalbase_call("MapMgr", "CheckEnterResp", 0, mbStr, map_imap[1], map_imap[2], dbid, name)
end

function MultiPlayManager:SetMissionInfo(playerDbid, playerName, playerMbStr, missionId, difficult, SpaceLoader)
    log_game_debug("MultiPlayManager:SetMissionInfo", "dbid=%q;name=%s;mb=%s;missionId=%d;difficult=%d",
                                                       playerDbid, playerName, playerMbStr, missionId, difficult)

    self.PlayerInfo[playerDbid] = {playerName, playerMbStr}
    self.Info[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT] = {}              --初始化已触发的刷怪点

    SpaceLoader.cell.SetCellInfo(playerDbid, playerName, playerMbStr, missionId, difficult)
end

function MultiPlayManager:Reset(MapId)
    log_game_debug("MultiPlayManager:Reset", "MapId=%s", MapId)

    self.StartTime = 0
    self.PlayerInfo = {}

    self.Info[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT] = {}              --初始化已触发的刷怪点

    lua_util.globalbase_call("MapMgr", "Reset", MapId)

end


return MultiPlayManager