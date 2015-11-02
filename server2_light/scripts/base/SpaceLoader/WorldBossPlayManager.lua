
require "BasicPlayManager"
require "map_data"
require "lua_util"

local log_game_warning = lua_util.log_game_warning
local log_game_debug = lua_util.log_game_debug
local log_game_error = lua_util.log_game_error

WorldBossPlayManager = BasicPlayManager.init()

function WorldBossPlayManager:init(owner)
    --log_game_debug("WorldBossPlayManager:init", "")
    local obj = {}
    setmetatable(obj, {__index = WorldBossPlayManager})
    obj.__index = obj
    -->>>>  BasicPlayerManager的数据
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
    --<<<<
    obj.PlayerInfo = {}
    obj.isOpen = 0
    obj.SpawnPoint = {} --初始化已触发的刷怪点

    obj.RankingList = {}
    --[[
    obj.Info = {}
    obj.Info[mission_config.SPECIAL_MAP_INFO_OWNER_DBID] = 0
    obj.Info[mission_config.SPECIAL_MAP_INFO_OWNER_NAME] = ''
    obj.Info[mission_config.SPECIAL_MAP_INFO_OWNER_MBSTR] = ''
    obj.Info[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT] = {}              --初始化已触发的刷怪点
    ]]

    --注册到WorldBossMgr
    local mgr = globalBases['WorldBossMgr']
    if mgr then
        mgr.Register(owner.map_id, mogo.pickleMailbox(owner), mogo.cPickle(owner.cell))
    end

    return obj
end
--设置场景玩家信息
function WorldBossPlayManager:SetMissionInfo(playerDbid, playerName, playerMbStr, missionId, difficult, SpaceLoader)
    log_game_debug("WorldBossPlayManager:SetMissionInfo", "dbid=%q;name=%s;mb=%s;missionId=%d;difficult=%d",
                                                       playerDbid, playerName, playerMbStr, missionId, difficult)
    --[[
    self.Info[mission_config.SPECIAL_MAP_INFO_OWNER_DBID] = playerDbid
    self.Info[mission_config.SPECIAL_MAP_INFO_OWNER_NAME] = playerName
    self.Info[mission_config.SPECIAL_MAP_INFO_OWNER_MBSTR] = playerMbStr
    self.Info[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT] = {}              --初始化已触发的刷怪点
    ]]
    if not self.PlayerInfo[playerDbid] then
        self.PlayerInfo[playerDbid] = {}
    --elseif self.PlayerInfo[playerDbid].isOnline then
        --log_game_error("WorldBossPlayManager:SetMissionInfo", "mutiple SetMissionInfo.")
    end
    local mb = mogo.UnpickleBaseMailbox(playerMbStr)
    self.PlayerInfo[playerDbid] = { name = playerName, mailBox = mb, isOnline = true }
    --cell上的信息一开始就设置好了，为了避免异步导致设置和刷怪先后顺序问题
    --SpaceLoader.cell.SetCellInfo(playerDbid, playerName, playerMbStr, missionId, difficult)
end

--获取正在场景中的，不包括掉线或者进入过但是离开了的
function WorldBossPlayManager:GetPlayerNumIn()
    local n = 0
    for _, v in pairs(self.PlayerInfo) do
        --if v.isOnline then
            n = n + 1
        --end
    end
    return n
end
--[[不用这个了
function WorldBossPlayManager:CheckEnter(mbStr, dbid, name, map_id)
    local srcMapId = g_map_mgr:GetSrcMapId(map_id)
    local MapCfg = g_map_mgr:getMapCfgData(srcMapId)
    local map_imap = lua_util.split_str(map_id, "_", tonumber)
    --配置检查
    if not MapCfg then
        log_game_error("WorldBossPlayManager:CheckEnter not config", "dbid=%q;name=%sscene=%d;line=%d", 
                                                                    dbid, name, map_imap[1], map_imap[2])
        lua_util.globalbase_call("MapMgr", "CheckEnterResp", -2, mbStr, map_imap[1], map_imap[2], dbid, name)
        return
    end

    --尚未开启
    if self.isOpen == 0 then
        log_game_error("WorldBossPlayManager:CheckEnter", "not open.")
        lua_util.globalbase_call("MapMgr", "CheckEnterResp", -4, mbStr, map_imap[1], map_imap[2], dbid, name)
        return
    end
    --人数检查
    if self:GetPlayerNumIn() >= MapCfg['maxPlayerNum'] then
        log_game_error("WorldBossPlayManager:CheckEnter", "full.")
        lua_util.globalbase_call("MapMgr", "CheckEnterResp", -3, mbStr, map_imap[1], map_imap[2], dbid, name)
        return
    end

    lua_util.globalbase_call("MapMgr", "CheckEnterResp", 0, mbStr, map_imap[1], map_imap[2], dbid, name)
end
]]
function WorldBossPlayManager:Reset(MapId)
    log_game_debug("WorldBossPlayManager:Reset", "MapId=%s, self.isOpen = %d", MapId, self.isOpen)

    self.StartTime = 0
    self.PlayerInfo = {}
    
    self.isOpen = 0 --重设开关
    self.SpawnPoint = {} --初始化已触发的刷怪点

    self.RankingList = {}
    lua_util.globalbase_call("MapMgr", "Reset", MapId)

end

--no use
function WorldBossPlayManager:Open(MapId)
    log_game_debug("WorldBossPlayManager:Open", 'self.isOpen = %d', self.isOpen)
    self.isOpen = 1
    --[[
    local mm = globalBases["MapMgr"]
    if mm then
        mm.AddToBusyPool(MapId)
    end
    ]]
end
--[[
--前端触发
function WorldBossPlayManager:Start(_StartTime, SpaceLoader)
    log_game_debug("WorldBossPlayManager:Start", "_StartTime=%d, self.isOpen = %d", _StartTime, self.isOpen)

    --副本已经处于开始状态，即玩家是断线重连，则应该不再处理
    --if self.StartTime > 0 then
        --return
    --end

    if self.isOpen == 2 then
        log_game_debug("WorldBossPlayManager:Start", "start cell.")
        SpaceLoader.cell.Start(_StartTime)
        return
    end

end
]]
--后端触发
function WorldBossPlayManager:StartByServer(_StartTime, SpaceLoader)
    log_game_debug("WorldBossPlayManager:StartByServer", "_StartTime=%d, self.isOpen = %d", _StartTime, self.isOpen)

    --副本已经处于开始状态，即玩家是断线重连，则应该不再处理
    --if self.StartTime > 0 then
        --return
    --end
    if self.isOpen == 2 then
        log_game_debug("WorldBossPlayManager:StartByServer", "")
        return
    end
    self.isOpen = 2
    --self.StartTime = _StartTime
    log_game_debug("WorldBossPlayManager:StartByServer", "start cell.")
    --SpaceLoader.cell.Start(_StartTime)

    --世界boss的触发是系统去触发的
    if self.SpawnPoint[public_config.SANCTUARY_BOSS_SPWAN_ID] then
        log_game_warning("WorldBossPlayManager:SpawnPointEvent ", "mutiple SpawnPointEvent.")
        return
    end
    --记录该刷怪点已经开始
    self.SpawnPoint[public_config.SANCTUARY_BOSS_SPWAN_ID] = true
    SpaceLoader.cell.SpawnPointEvent(mission_config.SPAWNPOINT_START, 0, 0, 0, public_config.SANCTUARY_BOSS_SPWAN_ID)
end

--no use
function WorldBossPlayManager:Stop(SpaceLoader)
    --self.isOpen = 0
    --self.StartTime = 0
    log_game_debug("WorldBossPlayManager:Stop", "self.isOpen = %d", self.isOpen)
    self.isOpen = 3
    self.RankingList = {}
    SpaceLoader.cell.Stop()
end

--刷世界boss
function WorldBossPlayManager:SpawnPointEvent(EventId, avatar_x, avatar_y, SpawnPointId, SpaceLoader)
    log_game_debug("WorldBossPlayManager:SpawnPointEvent", "EventId=%d;avatar_x=%d;avatar_y=%d;SpawnPointId=%d", 
                                                        EventId, avatar_x, avatar_y, SpawnPointId)
    --[[所有怪物的触发不走前端触发流程
    if self.isOpen ~= 2 then
        log_game_debug("WorldBossPlayManager:SpawnPointEvent", "is not start.")
        return
    end

    --世界boss的触发是系统去触发的
    if EventId == mission_config.SPAWNPOINT_START and self.SpawnPoint[SpawnPointId] then
        log_game_warning("WorldBossPlayManager:SpawnPointEvent ", "mutiple SpawnPointEvent.")
        return
    end
    --记录该刷怪点已经开始
    self.SpawnPoint[SpawnPointId] = true
    SpaceLoader.cell.SpawnPointEvent(EventId, avatar_x, avatar_y, SpawnPointId)
    ]]
end

function WorldBossPlayManager:GetMissionRewards(PlayerDbid, SpaceLoader)
    log_game_debug("WorldBossPlayManager:GetMissionRewards", "Playerdbid=%q", PlayerDbid)
    SpaceLoader.cell.GetMissionRewards(PlayerDbid)
end

function WorldBossPlayManager:onClientDeath(PlayerDbid, SpaceLoader)
    log_game_debug("WorldBossPlayManager:onClientDeath", "Playerdbid=%q", PlayerDbid)
    if self.PlayerInfo[PlayerDbid] then
        self.PlayerInfo[PlayerDbid].isOnline = false
    end
    SpaceLoader.cell.onClientDeath(PlayerDbid)
end

function WorldBossPlayManager:onMultiLogin(PlayerDbid, SpaceLoader)
    log_game_debug("WorldBossPlayManager:onMultiLogin", "")
    local theInfo = self.PlayerInfo[PlayerDbid]
    if theInfo then
        theInfo.isOnline = true
    else
        --这种情况是错误的，活动结束后玩家应该被踢回主城
        log_game_error("WorldBossPlayManager:onMultiLogin", "")
    end
end

--更新战斗中前3名贡献排名情况
function WorldBossPlayManager:UpdateWBRankList(rankList)
    log_game_debug("WorldBossPlayManager:UpdateWBRankList", "")
    self.RankingList = rankList
    --todo:通知前端
    for dbid, v in pairs(self.PlayerInfo) do
        if v.isOnline and v.mailBox then
            log_game_debug("WorldBossPlayManager:UpdateWBRankList", mogo.cPickle(v.mailBox))
            v.mailBox.client.OnRankingListUpdateResp(rankList)
        end
    end
end

function WorldBossPlayManager:Summon(spawnId, mod, SpaceLoader)
    if self.isOpen ~= 2 then
        log_game_debug("WorldBossPlayManager:Summon", "is not start.")
        return
    end
    SpaceLoader.cell.Summon(spawnId, mod)
end

function WorldBossPlayManager:KickAllPlayer(SpaceLoader)
    log_game_debug("WorldBossPlayManager:KickAllPlayer", "")
    self.isOpen = 3
    self.RankingList = {}
    --for test:活动结束马上开启世界boss的情况
    self.SpawnPoint = {} --初始化已触发的刷怪点
    SpaceLoader.cell.KickAllPlayer()
end

function WorldBossPlayManager:PlayerLeave(dbid)
    local theInfo = self.PlayerInfo[dbid]
    if not theInfo then return end

    local mm = globalBases['WorldBossMgr']
    if not mm then 
        log_game_error("WorldBossPlayManager:PlayerLeave", '')
        return 
    end
    mm.PlayerLeave(dbid)
    --[[
    if theInfo.isOnline then
        log_game_debug("WorldBossPlayManager:PlayerLeave", "dbid = %q", dbid)
        mm.PlayerLeave(theInfo.mailBox, SpaceLoader.map_id, dbid, level)
    else
        log_game_debug("WorldBossPlayManager:PlayerLeave", 'offline.')
        mm.PlayerLeave(theInfo.mailBox, SpaceLoader.map_id, dbid, level)
    end
    ]]
    self.PlayerInfo[dbid] = nil
end

return WorldBossPlayManager