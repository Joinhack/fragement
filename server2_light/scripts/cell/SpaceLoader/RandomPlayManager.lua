
require "BasicPlayManager"
require "mission_config"
require "lua_util"
require "state_config"
require "public_config"

local log_game_debug = lua_util.log_game_debug
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error

RandomPlayManager = BasicPlayManager.init()

function RandomPlayManager:init()
    --    log_game_debug("BasicPlayManager:init", "")

    local obj = {}
    setmetatable(obj, {__index = RandomPlayManager})
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
    --    obj.CellInfo[mission_config.SPECIAL_MAP_INFO_TOWER_DESTORY_TIMER_ID] = 0             --试炼之塔结束的定时器ID
    obj.CellInfo[mission_config.SPECIAL_MAP_INFO_MONSTER_AUTO_DIE] = 0
--    obj.CellInfo[mission_config.SPECIAL_MAP_INFO_AVATAR_LEVEL] = 0                       --副本玩家等级


    return obj
end

function RandomPlayManager:OnSpawnPointMonsterDeath(SpaceLoader, SpawnPointId)

    if self.CellInfo[mission_config.SPECIAL_MAP_INFO_SUCCESS_TIMER_ID] and
            self.CellInfo[mission_config.SPECIAL_MAP_INFO_SUCCESS_TIMER_ID] > 0 then
        return
    end

    log_game_debug("RandomPlayManager:OnSpawnPointMonsterDeath", "SpawnPointId=%d",  SpawnPointId)


    for event, eventResult in pairs(self.Events) do
        if eventResult[mission_config.SPECIAL_MAP_EVENT_SPAWNPOINT_MONSTER_ALL_DEAD] then
            eventResult[mission_config.SPECIAL_MAP_EVENT_SPAWNPOINT_MONSTER_ALL_DEAD][SpawnPointId] = true

            local flag = true
            for _, param in pairs(eventResult[mission_config.SPECIAL_MAP_EVENT_SPAWNPOINT_MONSTER_ALL_DEAD]) do
                if not param then
                    flag = false
                    break
                end
            end

            --触发该事件的条件已经达成，通知客户端触发事件
            if flag then
                self.Events[event] = nil
                local EventCfg = g_mission_mgr:getEventCfgById(event)
                local notifyToClient = EventCfg['notifyToClient']

                local level = 0

                if notifyToClient then
                    log_game_debug("RandomPlayManager:OnSpawnPointMonsterDeath notifyToClient", "map_id=%s;notifyToClient=%d", SpaceLoader.map_id, notifyToClient)
                    for _, info in pairs(self.PlayerInfo) do
                        local avatar = mogo.getEntity(info[public_config.PLAYER_INFO_INDEX_EID])
                        if avatar then
                            avatar.base.client.MissionResp(action_config.MSG_GET_NOTIFY_TO_CLENT_EVENT, {notifyToClient})
                            avatar.base.client.MissionResp(action_config.MSG_NOTIFY_TO_CLENT_SPAWNPOINT, {SpawnPointId})
                            level = avatar.level
                        else
                            log_game_error("RandomPlayManager:OnSpawnPointMonsterDeath notifyToClient", "map_id=%s;eid=%d", SpaceLoader.map_id, info[public_config.PLAYER_INFO_INDEX_EID])
                        end
                    end
                end

                local notifyOtherSpawnPoint = EventCfg['notifyOtherSpawnPoint']
                if notifyOtherSpawnPoint then
                    for _, cfgId in pairs(notifyOtherSpawnPoint) do
                        local spwanPoints = SpaceLoader.CliEntityManager:getEntityByType(cli_entity_config.CLI_ENTITY_TYPE_SPAWNPOINT)
                        if spwanPoints then
                            log_game_debug("RandomPlayManager:OnSpawnPointMonsterDeath notifyOtherSpawnPoint", "map_id=%s;spwanPoints=%s", SpaceLoader.map_id, mogo.cPickle(spwanPoints))
                            for _, spawnPointEntity in pairs(spwanPoints) do
                                log_game_debug("RandomPlayManager:SpawnPointEvent", "spawnPointEntity.cfgId=%d;cfgId=%d", spawnPointEntity.cfgId, cfgId)
                                if spawnPointEntity.cfgId == cfgId then

                                    SpawnPoint:Start({spawnPointData = spawnPointEntity, 
                                                difficulty = self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT], 
                                                triggerType = public_config.SPAWNPOINT_TRIGGER_TYPE_STEP}, 
                                                SpaceLoader, 
                                                level)
                                    --副本记录该刷怪点已经开始刷怪
                                    self.CellInfo[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT][cfgId] = true
                                    SpaceLoader:SyncCliEntityInfo()
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    --记录关卡进度
    self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_PROCESS][SpawnPointId] = true

    --通知base已经完成的spawnpoint
    log_game_debug("RandomPlayManager:OnSpawnPointMonsterDeath AddFinishedSpawnPoint", "SpawnPointId=%d",  SpawnPointId)
    SpaceLoader.base.AddFinishedSpawnPoint(SpawnPointId)

    if not self:IsSpaceLoaderSuccess() then
        return
    end

    if self.EndTime == 0 then
        self.EndTime = os.time()
    end

    local UsedTime = os.time() - self.StartTime
    log_game_debug("RandomPlayManager:OnSpawnPointMonsterDeath success", "map_id=%s;UsedTime=%d", SpaceLoader.map_id, UsedTime)

    for _, info in pairs(self.PlayerInfo) do
        log_game_debug("RandomPlayManager:OnSpawnPointMonsterDeath success", "id=%d", info[public_config.PLAYER_INFO_INDEX_EID])
        local avatar = mogo.getEntity(info[public_config.PLAYER_INFO_INDEX_EID])
        if avatar then
            log_game_debug("RandomPlayManager:OnSpawnPointMonsterDeath success", "dbid=%q;name=%s;missionId=%d;difficulty=%d",
                avatar.dbid, avatar.name,
                self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID],
                self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT])

            log_game_debug("SpaceLoader:OnSpawnPointMonsterDeath special success", "map_id=%s;result=%s;UsedTime=%d",
                SpaceLoader.map_id,
                mogo.cPickle(self.PlayerInfo[avatar.dbid][public_config.PLAYER_INFO_INDEX_REWARDS]),
                UsedTime)
            avatar.base.MissionC2BReq(action_config.MSG_ADD_FINISHED_MISSIONS, 0, 0, tostring(UsedTime))

        end
    end

    self.CellInfo[mission_config.SPECIAL_MAP_INFO_MONSTER_AUTO_DIE] = SpaceLoader:addTimer(g_GlobalParamsMgr:GetParams('monster_auto_die', 1), 0, public_config.TIMER_ID_MONSTER_DIE)

    --关卡成功后8秒钟，自动拾取，入背包
    self.CellInfo[mission_config.SPECIAL_MAP_INFO_SUCCESS_TIMER_ID] = SpaceLoader:addTimer(g_GlobalParamsMgr:GetParams('mission_countdown', 8), 0, public_config.TIMER_ID_SUCCESS)

end


function RandomPlayManager:SpawnPointEvent(EventId, dbid, SpawnPointId, SpaceLoader)
    log_game_debug("RandomPlayManager:SpawnPointEvent", "EventId=%d;dbid=q;SpawnPointId=%d", EventId, dbid, SpawnPointId)

    --如果客户端要求开始刷怪，但是服务器记录改点之前已经开始过，则跳过，该情况一般出现在客户端断线5分钟内重连
    if EventId == mission_config.SPAWNPOINT_START and
            self.CellInfo[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT][SpawnPointId] then
        return
    end

    local PlayerInfo = self.PlayerInfo[dbid]
    if not PlayerInfo then
        return
    end

    local eid = PlayerInfo[public_config.PLAYER_INFO_INDEX_EID]
    if not eid then
        return
    end

    local avatar = mogo.getEntity(eid)
    if not avatar then
        return
    end

    if Bit.Test(avatar.stateFlag, state_config.DEATH_STATE) or avatar.curHp <= 0 then
        log_game_warning("RandomPlayManager:SpawnPointEvent player death", "EventId=%d;dbid=q;SpawnPointId=%d", EventId, dbid, SpawnPointId)
        return
    end

    local spwanPoints = SpaceLoader.CliEntityManager:getEntityByType(cli_entity_config.CLI_ENTITY_TYPE_SPAWNPOINT)
    if spwanPoints then
        for _, spawnPointEntity in pairs(spwanPoints) do
            log_game_debug("RandomPlayManager:SpawnPointEvent", "spawnPointEntity.cfgId=%d", spawnPointEntity.cfgId)
            if spawnPointEntity.cfgId == SpawnPointId then
                if EventId == mission_config.SPAWNPOINT_START then
                    --SpwanPoints开始刷怪

                    --获取该标志，表示改副本是否随机副本
                    --                    local flag = g_mission_mgr:isRandomMission(self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID], self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT]) or false

                    SpawnPoint:Start({spawnPointData = spawnPointEntity,  
                                difficulty = self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT], 
                                triggerType = public_config.SPAWNPOINT_TRIGGER_TYPE_STEP}, 
                                SpaceLoader, 
                                avatar.level)
                    --副本记录该刷怪点已经开始刷怪
                    self.CellInfo[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT][SpawnPointId] = true
                    SpaceLoader:SyncCliEntityInfo()
                elseif EventId == mission_config.SPAWNPOINT_STOP then
                    SpawnPoint:Stop()
                end
                return
            end
        end
    end

end

return RandomPlayManager