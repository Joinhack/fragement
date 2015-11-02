
require "mission_config"
require "BasicPlayManager"
require "lua_util"
require "public_config"

local log_game_debug = lua_util.log_game_debug

TowerDefencePlayManager = BasicPlayManager.init()

function TowerDefencePlayManager:init()
    --    log_game_debug("TowerPlayManager:init", "")
    local obj = {}
    setmetatable(obj, {__index = TowerDefencePlayManager})
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
    obj.PlayerInfo = {}

    return obj
end

function TowerDefencePlayManager:Start()
end

function TowerDefencePlayManager:SpawnPointEvent()
end

function TowerDefencePlayManager:SetMissionInfo(playerDbid, playerName, playerMbStr, missionId, difficult, SpaceLoader)
    log_game_debug("TowerDefencePlayManager:SetMissionInfo", "dbid=%q;name=%s;mb=%s;missionId=%d;difficult=%d", playerDbid, playerName, playerMbStr, missionId, difficult)

    self.Info[mission_config.SPECIAL_MAP_INFO_OWNER_DBID] = playerDbid
    self.Info[mission_config.SPECIAL_MAP_INFO_OWNER_NAME] = playerName
    self.Info[mission_config.SPECIAL_MAP_INFO_OWNER_MBSTR] = playerMbStr
    self.Info[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT] = {}              --初始化已触发的刷怪点
    self.Info[mission_config.SPECIAL_MAP_INFO_FINISHED_SPAWN_POINT] = {}             --初始化已经完成的刷怪点
    self.Info[mission_config.SPECIAL_MAP_INFO_MISSION_ID] = missionId
    self.Info[mission_config.SPECIAL_MAP_INFO_DIFFICULT] = difficult
    self.Info[mission_config.SPECIAL_MAP_INFO_DROP] = {}                             --初始化已经掉落的物品信息

    self.PlayerInfo[playerDbid] = {[1] = playerName, [2] = mogo.UnpickleBaseMailbox(playerMbStr)}

    SpaceLoader.cell.SetCellInfo(playerDbid, playerName, playerMbStr, missionId, difficult)
end

function TowerDefencePlayManager:Chat(ChannelId, to_dbid, msg, name)
    log_game_debug("TowerDefencePlayManager:Chat", "ChannelId=%d;to_dbid=%q;msg=%s;name=%s", ChannelId, to_dbid, msg, name)

    if ChannelId == public_config.CHANNEL_ID_TOWER_DEFENCE then
        for _, v in pairs(self.PlayerInfo) do
            local mb = v[2]
            if mb then
                mb.client.ChatResp(ChannelId, 0, name, 0, msg)
            end
        end
    end
end

return TowerDefencePlayManager