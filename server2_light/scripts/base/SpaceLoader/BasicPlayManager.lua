
require "lua_util"
require "map_data"
require "mission_data"
require "mission_config"

require "NormalPlayManager"

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local _splitStr = lua_util.split_str


BasicPlayManager = NormalPlayManager.init()

function BasicPlayManager:init()
--    log_game_debug("BasicPlayManager:init", "")

    local obj = {}
    setmetatable(obj, {__index = BasicPlayManager})
    obj.__index = obj

    obj.StartTime = 0
    obj.Info = {}
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

function BasicPlayManager:Drop()
end

function BasicPlayManager:Start(_StartTime, SpaceLoader)
    log_game_debug("BasicPlayManager:Start", "_StartTime=%d", _StartTime)

    --副本已经处于开始状态，即玩家是断线重连，则应该不再处理
    if self.StartTime > 0 then
        return
    end

    self.StartTime = _StartTime

    SpaceLoader.cell.Start(_StartTime)

end

function BasicPlayManager:CheckEnter(mbStr, dbid, name, map_id)
    log_game_debug("BasicPlayManager:CheckEnter", "mbStr=%s;dbid=%q;name=%s;map_id=%s", mbStr, dbid, name, map_id)

    local mb = mogo.UnpickleBaseMailbox(mbStr)
    if mb then
        local map_imap = lua_util.split_str(map_id, "_", tonumber)

        if self.Info[mission_config.SPECIAL_MAP_INFO_OWNER_DBID] and self.Info[mission_config.SPECIAL_MAP_INFO_OWNER_DBID] == dbid and self.Info[mission_config.SPECIAL_MAP_INFO_OWNER_NAME] and self.Info[mission_config.SPECIAL_MAP_INFO_OWNER_NAME] == name then
            lua_util.globalbase_call("MapMgr", "CheckEnterResp", 0, mbStr, map_imap[1], map_imap[2], dbid, name)
        else
            lua_util.globalbase_call("MapMgr", "CheckEnterResp", -1, mbStr, map_imap[1], map_imap[2], dbid, name)
        end
    end

end

function BasicPlayManager:SetMissionInfo(playerDbid, playerName, playerMbStr, missionId, difficult, SpaceLoader)
    log_game_debug("BasicPlayManager:SetMissionInfo", "dbid=%q;name=%s;mb=%s;missionId=%d;difficult=%d", playerDbid, playerName, playerMbStr, missionId, difficult)

    self.Info[mission_config.SPECIAL_MAP_INFO_OWNER_DBID] = playerDbid
    self.Info[mission_config.SPECIAL_MAP_INFO_OWNER_NAME] = playerName
    self.Info[mission_config.SPECIAL_MAP_INFO_OWNER_MBSTR] = playerMbStr
    self.Info[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT] = {}              --初始化已触发的刷怪点
    self.Info[mission_config.SPECIAL_MAP_INFO_FINISHED_SPAWN_POINT] = {}             --初始化已经完成的刷怪点
    self.Info[mission_config.SPECIAL_MAP_INFO_MISSION_ID] = missionId
    self.Info[mission_config.SPECIAL_MAP_INFO_DIFFICULT] = difficult
    self.Info[mission_config.SPECIAL_MAP_INFO_DROP] = {}                             --初始化已经掉落的物品信息

    SpaceLoader.cell.SetCellInfo(playerDbid, playerName, playerMbStr, missionId, difficult)
end

function BasicPlayManager:Reset(MapId)
    log_game_debug("BasicPlayManager:Reset", "MapId=%s", MapId)

    self.StartTime = 0
    self.Info = {}
--    self.Info[mission_config.SPECIAL_MAP_INFO_OWNER_DBID] = 0
--    self.Info[mission_config.SPECIAL_MAP_INFO_OWNER_NAME] = ''
--    self.Info[mission_config.SPECIAL_MAP_INFO_OWNER_MBSTR] = ''
--    self.Info[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT] = {}              --初始化已触发的刷怪点
--    self.Info[mission_config.SPECIAL_MAP_INFO_FINISHED_SPAWN_POINT] = {}             --初始化已经完成的刷怪点
--    self.Info[mission_config.SPECIAL_MAP_INFO_MISSION_ID] = 0
--    self.Info[mission_config.SPECIAL_MAP_INFO_DIFFICULT] = 0
--    self.Info[mission_config.SPECIAL_MAP_INFO_DROP] = {}                             --初始化已经掉落的物品信息

    lua_util.globalbase_call("MapMgr", "Reset", MapId)

end

function BasicPlayManager:SpawnPointEvent(EventId, dbid, avatar_x, avatar_y, SpawnPointId, SpaceLoader)

    if self.StartTime <= 0 then
        log_game_warning("BasicPlayManager:SpawnPointEvent not Started", "EventId=%d;dbid=%q;avatar_x=%d;avatar_y=%d;SpawnPointId=%d",
                                                                                     EventId, dbid, avatar_x, avatar_y, SpawnPointId)
        return
    end

    local src_map_id = g_map_mgr:GetSrcMapId(SpaceLoader.map_id)

    log_game_debug("BasicPlayManager:SpawnPointEvent", "EventId=%d;dbid=%q;avatar_x=%d;avatar_y=%d;SpawnPointId=%d;src_map_id=%d",
                                                                EventId, dbid, avatar_x, avatar_y, SpawnPointId, src_map_id)

    local flag = true
    if src_map_id then
        local map_entity_cfg_data = g_map_mgr:GetMapEntityCfgData(src_map_id)

        if map_entity_cfg_data then
            for i, v in pairs(map_entity_cfg_data) do
                if v['type'] == 'SpawnPoint' and i == SpawnPointId then
--                    log_game_debug("BasicPlayManager:SpawnPointEvent", "SpawnPointId=%d", SpawnPointId)
                    if v['preSpawnPointId'] and v['preSpawnPointId'] ~= '' then
                        log_game_debug("BasicPlayManager:SpawnPointEvent", "SpawnPointId=%d;v['preSpawnPointId']=%s", SpawnPointId, v['preSpawnPointId'])
                        local preSpawnPointId = _splitStr(v['preSpawnPointId'], ',', tonumber)
                        for _, id in pairs(preSpawnPointId) do
                            if not self.Info[mission_config.SPECIAL_MAP_INFO_FINISHED_SPAWN_POINT][id] then
                                flag = false
                                log_game_warning("BasicPlayManager:SpawnPointEvent", "EventId=%d;SpawnPointId=%d;preSpawnPointId=%s;FinishedId=%s", 
                                                                                      EventId, SpawnPointId, 
                                                                                      mogo.cPickle(preSpawnPointId),
                                                                                      mogo.cPickle(self.Info[mission_config.SPECIAL_MAP_INFO_FINISHED_SPAWN_POINT])
                                                                                      )
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    if not flag then
        return
    end

    --如果客户端要求开始刷怪，但是服务器记录改点之前已经开始过，则跳过，该情况一般出现在客户端断线5分钟内重连
    if EventId == mission_config.SPAWNPOINT_START and 
       self.Info[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT] and
       self.Info[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT][SpawnPointId] then
        log_game_debug("BasicPlayManager:SpawnPointEvent fail", "")
        return
    end

    --记录该刷怪点已经开始
    self.Info[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT][SpawnPointId] = true

    SpaceLoader.cell.SpawnPointEvent(EventId, dbid, avatar_x, avatar_y, SpawnPointId)
end

function BasicPlayManager:GetMissionRewards(PlayerDbid, SpaceLoader)
    log_game_debug("BasicPlayManager:GetMissionRewards", "Playerdbid=%q", PlayerDbid)
    SpaceLoader.cell.GetMissionRewards(PlayerDbid)
end

function BasicPlayManager:onClientDeath(PlayerDbid, SpaceLoader)
    log_game_debug("BasicPlayManager:onClientDeath", "Playerdbid=%q", PlayerDbid)
    SpaceLoader.cell.onClientDeath(PlayerDbid)
end

function BasicPlayManager:ExitMission(dbid, SpaceLoader)
    SpaceLoader.cell.ExitMission(dbid)
end

function BasicPlayManager:QuitMission(dbid, SpaceLoader)
    SpaceLoader.cell.QuitMission(dbid)
end

function BasicPlayManager:AddFinishedSpawnPoint(SpawnPointId)
--    log_game_debug("BasicPlayManager:AddFinishedSpawnPoint", "SpawnPointId=%d", SpawnPointId)
    if self.Info[mission_config.SPECIAL_MAP_INFO_FINISHED_SPAWN_POINT] then
        self.Info[mission_config.SPECIAL_MAP_INFO_FINISHED_SPAWN_POINT][SpawnPointId] = true
    end
end

function BasicPlayManager:CreateClientDrop(Spaceloader, mbStr, DropId, x, y)
--    log_game_debug("BasicPlayManager:CreateClientDrop", "mbStr=%s;DropId=%d;x=%d;y=%d;mission=%d;difficulty=%d", mbStr, DropId, x, y, self.Info[mission_config.SPECIAL_MAP_INFO_MISSION_ID], self.Info[mission_config.SPECIAL_MAP_INFO_DIFFICULT])
    local MissionCfg = g_mission_mgr:getCfgById(self.Info[mission_config.SPECIAL_MAP_INFO_MISSION_ID] .. "_" .. self.Info[mission_config.SPECIAL_MAP_INFO_DIFFICULT])

    if MissionCfg and MissionCfg['drop'] then
        if self.Info[mission_config.SPECIAL_MAP_INFO_DROP] and MissionCfg['drop'][DropId] then
            local DropedCount =  self.Info[mission_config.SPECIAL_MAP_INFO_DROP][DropId] or 0
            if DropedCount < MissionCfg['drop'][DropId] then
                --开始创建掉落物
                self.Info[mission_config.SPECIAL_MAP_INFO_DROP][DropId] = DropedCount + 1
                Spaceloader.cell.ProcessWaguanDie(DropId, x, y)
            else
                log_game_warning("BasicPlayManager:CreateClientDrop","mbStr=%s;DropId=%d;x=%d;y=%d;DropedCount=%d;MissionCfg['drop']=%s", mbStr, DropId, x, y, DropedCount, mogo.cPickle(MissionCfg['drop']))
            end
        end
    end
end

return BasicPlayManager

