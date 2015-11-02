
require "lua_util"
require "public_config"
require "mission_config"
require "mission_data"
require "map_data"
require "NormalPlayManager"
require "GlobalParams"
require "state_config"
require "reason_def"
require "channel_config"
require "cli_entity_config"
require "action_config"

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error

--local TIMER_ID_END     = 1    --副本(关卡)结束的定时器
--local TIMER_ID_SUCCESS = 2    --副本(关卡)成功后的定时器
--local TIMER_ID_MONSTER_DIE = 3--副本(关卡)成功后演示若干秒怪物死亡
--local TIMER_ID_DESTROY = 4    --副本开始破坏
--local TIMER_ID_START   = 5    --副本开始前倒数
--local TIMER_ID_PREPARE_START = 6 --副本准备时间倒计时

BasicPlayManager = NormalPlayManager.init()

function BasicPlayManager:init()
--    log_game_debug("BasicPlayManager:init", "")

    local obj = {}
    setmetatable(obj, {__index = BasicPlayManager})
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

    obj.CellInfo[mission_config.SPECAIL_MAP_INFO_DELAY_EVENT] = {}                       --延迟触发的事件
    obj.CellInfo[mission_config.SPECAIL_MAP_INFO_DELAY_TIMER_ID] = {}                     --延迟触发的事件定时器ID

    return obj
end

function BasicPlayManager:onTimer(SpaceLoader, timer_id, user_data)
    if user_data == public_config.TIMER_ID_END then
        self:Stop(SpaceLoader)
    elseif user_data == public_config.TIMER_ID_SUCCESS then
--        if self.PlayManager then
        self:AutoPickUpDrops(SpaceLoader)
--        end
    elseif user_data == public_config.TIMER_ID_MONSTER_DIE then
--        if self.PlayManager then
        self:MonsterAutoDie(SpaceLoader)
--        end
    elseif user_data == public_config.TIMER_ID_DELAY_ACTIVE then
        self:HandleDelayEvent(SpaceLoader)
    end
end

function BasicPlayManager:OnAvatarCtor(avatar)

    log_game_debug("BasicPlayManager:OnAvatarCtor", "dbid=%q;name=%s", avatar.dbid, avatar.name)
    --记录该场景玩家的dbid与id的key-value对应关系，记录玩家在当前场景的一些数据
    --格式:{玩家dbid = {玩家ID, 死亡次数, 喝药次数, 名字, 奖励}}
    self.PlayerInfo[avatar.dbid] = {[public_config.PLAYER_INFO_INDEX_EID]=avatar:getId(), 
                                    [public_config.PLAYER_INFO_INDEX_DEADTIMES]=0, 
                                    [public_config.PLAYER_INFO_INDEX_USE_DRUG_TIMES]=0,
                                    [public_config.PLAYER_INFO_INDEX_NAME]=avatar.name,
                                    [public_config.PLAYER_INFO_INDEX_REWARDS] = {[public_config.PLAYER_INFO_REWARDS_EXP] = 0,
                                                                                 [public_config.PLAYER_INFO_REWARDS_MONEY] = 0,
                                                                                 [public_config.PLAYER_INFO_REWARDS_ITEMS] = {}}
                                  }

end

function BasicPlayManager:OnAvatarDctor(avatar, SpaceLoader)

    log_game_debug("BasicPlayManager:OnAvatarDctor", "dbid=%q;name=%s", avatar.dbid, avatar.name)

    if self:IsSpaceLoaderSuccess() then
        --玩家离开副本时副本已经成功
        local BusyDrops = SpaceLoader.CliEntityManager:getEntityByType(cli_entity_config.CLI_ENTITY_TYPE_DROP)
        if BusyDrops then
            for _, BusyDrop in pairs(BusyDrops) do
                if BusyDrop and                                                             --掉落物存在
                   BusyDrop.belongAvatar == avatar:getId() and                              --掉落物属于该角色
                   avatar:GetLuaDistance(BusyDrop.enterX, BusyDrop.enterY) <= g_GlobalParamsMgr:GetParams('auto_pick_up_range', 500) then  --掉落物在玩家的5米之内
                   log_game_debug("BasicPlayManager:OnAvatarDctor", "dbid=%q;name=%s", avatar.dbid, avatar.name)
                   --如果该道具在玩家的5米之内，则让玩家拾取
                   avatar:ProcessPickDrop(BusyDrop.eid)
                end
            end
        end

        --发奖
--        self:SendReward(avatar.dbid)
    end

    --删除对应关系
    self:DeletePlayer(avatar.dbid)

    --复活
--    avatar.deathFlag = 0
    avatar.stateFlag = Bit.Reset(avatar.stateFlag, state_config.DEATH_STATE)
    --满血
    avatar.curHp = avatar.hp
    --清战斗buff

--    --清空怒气值
--    avatar:ClearAnger()
    

end

--回收
function BasicPlayManager:Recover(SpaceLoader)
    log_game_debug("BasicPlayManager:Recover", "")
    SpaceLoader:Stop()
    --副本重置
    SpaceLoader:Reset()
end

function BasicPlayManager:SetCellInfo(playerDbid, playerName, playerMbStr, missionId, difficult)

    log_game_debug("BasicPlayManager:SetCellInfo", "dbid=%q;name=%s;mb=%s;missionId=%d;difficult=%d", playerDbid, playerName, playerMbStr, missionId, difficult)

    self.CellInfo[mission_config.SPECIAL_MAP_INFO_OWNER_DBID] = playerDbid
    self.CellInfo[mission_config.SPECIAL_MAP_INFO_OWNER_NAME] = playerName
    self.CellInfo[mission_config.SPECIAL_MAP_INFO_OWNER_MBSTR] = playerMbStr
    self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID] = missionId
    self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT] = difficult
    self.CellInfo[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT] = {}               --初始化已触发的刷怪点
    self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_PROCESS] = {}                   --初始化副本进度
    self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID] = 0                       --副本结束的定时器ID
    self.CellInfo[mission_config.SPECIAL_MAP_INFO_SUCCESS_TIMER_ID] = 0
--    self.CellInfo[mission_config.SPECIAL_MAP_INFO_TOWER_DESTORY_TIMER_ID] = 0             --试炼之塔结束的定时器ID
    self.CellInfo[mission_config.SPECIAL_MAP_INFO_MONSTER_AUTO_DIE] = 0

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
                    self.Events[event] = {[mission_config.SPECIAL_MAP_EVENT_SPAWNPOINT_MONSTER_ALL_DEAD] = result }
                elseif EventCfg['type'] == mission_config.SPECIAL_MAP_EVENT_INIT then
                    self.Events[event] = {[mission_config.SPECIAL_MAP_EVENT_INIT] = true}
                end
            end
        end
    end

end

function BasicPlayManager:SpawnPointEvent(EventId, dbid, SpawnPointId, SpaceLoader)
    log_game_debug("BasicPlayManager:SpawnPointEvent", "EventId=%d;dbid=q;SpawnPointId=%d", EventId, dbid, SpawnPointId)

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
        log_game_warning("BasicPlayManager:SpawnPointEvent player death", "EventId=%d;dbid=q;SpawnPointId=%d", EventId, dbid, SpawnPointId)
        return
    end

--    print('BasicPlayManager:SpawnPointEvent :'..SpaceLoader.map_id)
    local spwanPoints = SpaceLoader.CliEntityManager:getEntityByType(cli_entity_config.CLI_ENTITY_TYPE_SPAWNPOINT)
    if spwanPoints then
        for _, spawnPointEntity in pairs(spwanPoints) do
            log_game_debug("BasicPlayManager:SpawnPointEvent", "spawnPointEntity.cfgId=%d", spawnPointEntity.cfgId)
            if spawnPointEntity.cfgId == SpawnPointId then
                if EventId == mission_config.SPAWNPOINT_START then
                    --SpwanPoints开始刷怪

                    --获取该标志，表示改副本是否随机副本
--                    local flag = g_mission_mgr:isRandomMission(self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID], self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT]) or false

                    local spawnPointRnt = SpawnPoint:Start({spawnPointData = spawnPointEntity,  
                                                    difficulty = self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT],
                                                    triggerType = public_config.SPAWNPOINT_TRIGGER_TYPE_STEP}, 
                                                    SpaceLoader)
                    if spawnPointRnt == nil then
                        return
                    end
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

function BasicPlayManager:AddRewards(playerDbid, item_id, count)

    log_game_debug("BasicPlayManager:AddRewards", "playerdbid=%q;item_id=%d;count=%d", playerDbid, item_id, count)

    if not self.PlayerInfo[playerDbid] then
        return
    end

    if count <= 0 then
        log_game_warning("BasicPlayManager:AddRewards", "playerdbid=%q;item_id=%d;count=%d", playerDbid, item_id, count)
        return
    end

    local oldCount = self.PlayerInfo[playerDbid][public_config.PLAYER_INFO_INDEX_REWARDS][public_config.PLAYER_INFO_REWARDS_ITEMS][item_id] or 0

    self.PlayerInfo[playerDbid][public_config.PLAYER_INFO_INDEX_REWARDS][public_config.PLAYER_INFO_REWARDS_ITEMS][item_id] = oldCount + count

    --拾取物品时直接发送到base
--    self:SendReward(playerDbid)

    local eid = self.PlayerInfo[playerDbid][public_config.PLAYER_INFO_INDEX_EID]
    local player = mogo.getEntity(eid)
    if not player then
        return
    end
    --加道具
    local result = {}
    result[item_id] = count
    player.base.MissionC2BReq(action_config.MSG_ADD_REWARD_ITEMS, 0, 0, mogo.cPickle(result))

--    self:NotifyRewardsToClient(playerDbid)

end

function BasicPlayManager:AddMoney(playerDbid, count)

    if not self.PlayerInfo[playerDbid] then
        return
    end

    if count <= 0 then
        log_game_warning("BasicPlayManager:AddMoney", "playerdbid=%q;count=%d", playerDbid, count)
        return
    end

    local oldCount = self.PlayerInfo[playerDbid][public_config.PLAYER_INFO_INDEX_REWARDS][public_config.PLAYER_INFO_REWARDS_MONEY] or 0
    self.PlayerInfo[playerDbid][public_config.PLAYER_INFO_INDEX_REWARDS][public_config.PLAYER_INFO_REWARDS_MONEY] = oldCount + count

    log_game_debug("BasicPlayManager:AddMoney", "playerdbid=%q;count=%d", playerDbid, count)

    --拾取物品时直接发送到base
--    self:SendReward(playerDbid)

    local eid = self.PlayerInfo[playerDbid][public_config.PLAYER_INFO_INDEX_EID]
    local player = mogo.getEntity(eid)
    if not player then
        return
    end

    player.base.AddGold(count, reason_def.mission)

--    self:NotifyRewardsToClient(playerDbid)

end

function BasicPlayManager:AddExp(playerDbid, count)

    if not self.PlayerInfo[playerDbid] then
        return
    end

    if count <= 0 then
        log_game_warning("BasicPlayManager:AddExp", "playerdbid=%q;count=%d", playerDbid, count)
        return
    end

    local oldCount = self.PlayerInfo[playerDbid][public_config.PLAYER_INFO_INDEX_REWARDS][public_config.PLAYER_INFO_REWARDS_EXP] or 0
    self.PlayerInfo[playerDbid][public_config.PLAYER_INFO_INDEX_REWARDS][public_config.PLAYER_INFO_REWARDS_EXP] = oldCount + count

    log_game_debug("BasicPlayManager:AddExp", "playerdbid=%q;count=%d", playerDbid, count)

--    self:NotifyRewardsToClient(playerDbid)

    local eid = self.PlayerInfo[playerDbid][public_config.PLAYER_INFO_INDEX_EID]
    local player = mogo.getEntity(eid)
    if not player then
        return
    end

    player.base.AddExp(count, reason_def.mission)

    --通知客户端飘经验
    self:NotifyAddExp(playerDbid, count)

--    --拾取物品时直接发送到base
--    self:SendReward(playerDbid)

end

function BasicPlayManager:GetMissionRewards(PlayerDbid)

    local Rewards = self.PlayerInfo[PlayerDbid][public_config.PLAYER_INFO_INDEX_REWARDS]
    if not Rewards then
        return
    end

    local player = mogo.getEntity(self.PlayerInfo[PlayerDbid][public_config.PLAYER_INFO_INDEX_EID])
    if not player then
        return
    end
--    if player.base and player:hasClient() then
        player.base.client.MissionResp(action_config.MSG_GET_MISSION_REWARDS, Rewards)
--    end
end

function BasicPlayManager:NotifyRewardsToClient(playerDbid)

    if not self.PlayerInfo[playerDbid] then
        return
    end

    --给客户端同步奖励池数据
    local player = mogo.getEntity(self.PlayerInfo[playerDbid][public_config.PLAYER_INFO_INDEX_EID])
    if not player then
        return
    end
--    if player.base and player:hasClient() then
        player.base.client.MissionResp(action_config.MSG_GET_MISSION_REWARDS, self.PlayerInfo[playerDbid][public_config.PLAYER_INFO_INDEX_REWARDS])
--    end
end

function BasicPlayManager:NotifyAddExp(playerDbid, count)
    if not self.PlayerInfo[playerDbid] then
        return
    end

    --给客户端同步奖励池数据
    local player = mogo.getEntity(self.PlayerInfo[playerDbid][public_config.PLAYER_INFO_INDEX_EID])
    if not player then
        return
    end
--    if player.base and player:hasClient() then
        player.base.client.MissionResp(action_config.MSG_NOTIFY_MISSION_EXP, {count})
--    end
end

function BasicPlayManager:HandleDelayEvent(SpaceLoader)
    if lua_util.get_table_real_count(self.CellInfo[mission_config.SPECAIL_MAP_INFO_DELAY_EVENT]) > 0 then
        local cfgId = table.remove(self.CellInfo[mission_config.SPECAIL_MAP_INFO_DELAY_EVENT], 1)

        if self.CellInfo[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT][cfgId] then
            log_game_error("BasicPlayManager:HandleDelayEvent allready", "map_id=%s;cfgId=%d", SpaceLoader.map_id, cfgId)
            return
        end

        local spwanPoints = SpaceLoader.CliEntityManager:getEntityByType(cli_entity_config.CLI_ENTITY_TYPE_SPAWNPOINT)
        if spwanPoints then

            log_game_debug("BasicPlayManager:HandleDelayEvent", "map_id=%s;spwanPoints=%s;cfgId=%d", SpaceLoader.map_id, mogo.cPickle(spwanPoints), cfgId)

            for _, spawnPointEntity in pairs(spwanPoints) do
                if spawnPointEntity.cfgId == cfgId then
                    --SpwanPoints开始刷怪

                    SpawnPoint:Start({spawnPointData = spawnPointEntity,
                        difficulty = self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT],
                        triggerType = public_config.SPAWNPOINT_TRIGGER_TYPE_STEP},
                        SpaceLoader)
                    --副本记录该刷怪点已经开始刷怪
                    self.CellInfo[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT][cfgId] = true
                    SpaceLoader:SyncCliEntityInfo()
                end
            end
        end
    end
end

function BasicPlayManager:OnSpawnPointMonsterDeath(SpaceLoader, SpawnPointId)

    if self.CellInfo[mission_config.SPECIAL_MAP_INFO_SUCCESS_TIMER_ID] and
       self.CellInfo[mission_config.SPECIAL_MAP_INFO_SUCCESS_TIMER_ID] > 0 then
        return
    end

    log_game_debug("BasicPlayManager:OnSpawnPointMonsterDeath", "SpawnPointId=%d",  SpawnPointId)

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
                if notifyToClient then
                    log_game_debug("BasicPlayManager:OnSpawnPointMonsterDeath notifyToClient", "map_id=%s;notifyToClient=%d", SpaceLoader.map_id, notifyToClient)
                    for _, info in pairs(self.PlayerInfo) do
                        local avatar = mogo.getEntity(info[public_config.PLAYER_INFO_INDEX_EID])
                        if avatar then
                            avatar.base.client.MissionResp(action_config.MSG_GET_NOTIFY_TO_CLENT_EVENT, {notifyToClient})
                            avatar.base.client.MissionResp(action_config.MSG_NOTIFY_TO_CLENT_SPAWNPOINT, {SpawnPointId})
                        else
                            log_game_error("BasicPlayManager:OnSpawnPointMonsterDeath notifyToClient", "map_id=%s;eid=%d", SpaceLoader.map_id, info[public_config.PLAYER_INFO_INDEX_EID])
                        end
                    end
                end

                local delayNotifyOtherSpawnPoint = EventCfg['delayNotifyOtherSpawnPoint']
                if delayNotifyOtherSpawnPoint then
                    for cfgId, seconds in pairs(delayNotifyOtherSpawnPoint) do
                        table.insert(self.CellInfo[mission_config.SPECAIL_MAP_INFO_DELAY_EVENT], cfgId)
                        table.insert(self.CellInfo[mission_config.SPECAIL_MAP_INFO_DELAY_TIMER_ID], SpaceLoader:addTimer(seconds, 0, public_config.TIMER_ID_DELAY_ACTIVE))

                        log_game_debug("BasicPlayManager:OnSpawnPointMonsterDeath delayNotifyOtherSpawnPoint", "cfgId=%d;seconds=%d;events=%s;timerIds=%s", cfgId, seconds, mogo.cPickle(self.CellInfo[mission_config.SPECAIL_MAP_INFO_DELAY_EVENT]), mogo.cPickle(self.CellInfo[mission_config.SPECAIL_MAP_INFO_DELAY_TIMER_ID]))
                    end
                end

                local notifyOtherSpawnPoint = EventCfg['notifyOtherSpawnPoint']
                if notifyOtherSpawnPoint then
                    for _, cfgId in pairs(notifyOtherSpawnPoint) do
                        local spwanPoints = SpaceLoader.CliEntityManager:getEntityByType(cli_entity_config.CLI_ENTITY_TYPE_SPAWNPOINT)
                        if spwanPoints then
                        log_game_debug("BasicPlayManager:OnSpawnPointMonsterDeath notifyOtherSpawnPoint", "map_id=%s;spwanPoints=%s", SpaceLoader.map_id, mogo.cPickle(spwanPoints))
                            for _, spawnPointEntity in pairs(spwanPoints) do
                                log_game_debug("BasicPlayManager:SpawnPointEvent", "spawnPointEntity.cfgId=%d;cfgId=%d", spawnPointEntity.cfgId, cfgId)
                                if spawnPointEntity.cfgId == cfgId then
--                                    log_game_debug("BasicPlayManager:SpawnPointEvent Start", "cfgId=%d", cfgId)
                                    --SpwanPoints开始刷怪

                                    --获取该标志，表示改副本是否随机副本
--                                    local flag = g_mission_mgr:isRandomMission(self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID], self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT]) or false

                                    SpawnPoint:Start({spawnPointData = spawnPointEntity, 
                                                difficulty = self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT],
                                                triggerType = public_config.SPAWNPOINT_TRIGGER_TYPE_STEP}, 
                                                SpaceLoader)
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
    log_game_debug("BasicPlayManager:OnSpawnPointMonsterDeath AddFinishedSpawnPoint", "SpawnPointId=%d",  SpawnPointId)
    SpaceLoader.base.AddFinishedSpawnPoint(SpawnPointId)

    if not self:IsSpaceLoaderSuccess() then
        return
    end

    if self.EndTime == 0 then
        self.EndTime = os.time()
    end

    local UsedTime = os.time() - self.StartTime
--    local Star = self:GetMissionStar(UsedTime)
    log_game_debug("BasicPlayManager:OnSpawnPointMonsterDeath success", "map_id=%s;UsedTime=%d", SpaceLoader.map_id, UsedTime)
    

    local src_map_id = g_map_mgr:GetSrcMapId(SpaceLoader.map_id)
    local map_cfg = g_map_mgr:getMapCfgData(src_map_id)

    for dbid, info in pairs(self.PlayerInfo) do
        log_game_debug("BasicPlayManager:OnSpawnPointMonsterDeath success", "id=%d", info[public_config.PLAYER_INFO_INDEX_EID])
        local avatar = mogo.getEntity(info[public_config.PLAYER_INFO_INDEX_EID])
        if avatar then
            log_game_debug("BasicPlayManager:OnSpawnPointMonsterDeath success", "dbid=%q;name=%s;missionId=%d;difficulty=%d", avatar.dbid, avatar.name, self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID], self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT])

            --普通副本弹出结算界面
            --通知客户端副本挑战成功，下发奖励表

--            local result = {}
--            table.insert(result, tostring(UsedTime))            --理想通关时间

--            local vipLimit = g_vip_mgr:GetVipPrivileges(avatar.VipLevel)
--            table.insert(result, tostring(vipLimit.hpMaxCount - avatar.hpCount))      --实际使用药瓶数量

            log_game_debug("SpaceLoader:OnSpawnPointMonsterDeath special success", "map_id=%s;result=%s;UsedTime=%d",  SpaceLoader.map_id, mogo.cPickle(self.PlayerInfo[avatar.dbid][public_config.PLAYER_INFO_INDEX_REWARDS]), UsedTime)
            avatar.base.MissionC2BReq(action_config.MSG_ADD_FINISHED_MISSIONS, 0, 0, tostring(UsedTime))

            --通知客户端通关时间和获得的星数
--            if avatar:hasClient() then
--            avatar.base.client.MissionResp(mission_config.MSG_NOTIFY_TO_CLIENT_RESULT_SUCCESS, {UsedTime, Star})
--            end
        end
    end

    self.CellInfo[mission_config.SPECIAL_MAP_INFO_MONSTER_AUTO_DIE] = SpaceLoader:addTimer(g_GlobalParamsMgr:GetParams('monster_auto_die', 1), 0, public_config.TIMER_ID_MONSTER_DIE)

--    if Monsters then
--        for _, entity in pairs(Monsters) do
--            --如果怪物当前没有死，则全部设置成死亡
--            if entity.curHp > 0 then
--                entity.addHp(-10*10000)
--            end
--        end
--    end

    --关卡成功后8秒钟，自动拾取，入背包
    self.CellInfo[mission_config.SPECIAL_MAP_INFO_SUCCESS_TIMER_ID] = SpaceLoader:addTimer(g_GlobalParamsMgr:GetParams('mission_countdown', 8), 0, public_config.TIMER_ID_SUCCESS)

end

--function BasicPlayManager:GetMissionStar(UsedTime)
--    local missionId = tostring(self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID])
--    local difficult = tostring(self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT])
--
--    local tbl = {}
--    table.insert(tbl, missionId)
--    table.insert(tbl, difficult)
--
--    local cfg = g_mission_mgr:getCfgById(table.concat(tbl, "_"))
--
--    if cfg and cfg['mission_time'] and self.StartTime > 0 then
----        local UsedTime = os.time() - self.StartTime
--        if UsedTime < cfg['mission_time'][1] then
--            return 3
--        elseif UsedTime >= cfg['mission_time'][1] and UsedTime <= cfg['mission_time'][2] then
--            return 2
--        else
--            return 1
--        end
--    end
--
--    log_game_error("BasicPlayManager:GetMissionStar", "StartTime=%d", self.StartTime)
--    return 1
--end

function BasicPlayManager:MonsterAutoDie(SpaceLoader)

    --关卡成功以后活着的怪物死亡
    --客户端怪物
    for dbid, info in pairs(self.PlayerInfo) do                                  
        local avatar = mogo.getEntity(info[public_config.PLAYER_INFO_INDEX_EID]) 
        if avatar then                              
    	    avatar.base.client.BossDieResp()
        end                                                                      
    end   
    --服务器怪物
    local tblAliveMonster = {}
    for k,v in pairs(SpaceLoader.AliveMonster) do
        tblAliveMonster[k] = v
    end
    for eid, v in pairs(tblAliveMonster) do
        local monsterEntity = mogo.getEntity(eid)
        if monsterEntity and monsterEntity.curHp > 0 and monsterEntity.factionFlag == 0 then
            log_game_debug("SpaceLoader:MonsterAutoDie", "map_id=%s", SpaceLoader.map_id)
--            print('monsterEntity die', monsterEntity:getId())
            --如果怪物当前没有死，则全部设置成死亡
            monsterEntity:addHp(-monsterEntity.curHp)
        end
    end

end

function BasicPlayManager:Start(SpaceLoader, StartTime)

    
    --佣兵
    --[[
    if SpaceLoader.MapType == public_config.MAP_TYPE_SPECIAL then
        for dbid, info in pairs(self.PlayerInfo) do
            local avatar = mogo.getEntity(info[public_config.PLAYER_INFO_INDEX_EID])
            if avatar then
                if avatar.mercenaryDbid > 0 then
                    avatar:addLocalTimer("CreateMercenaryReq", 2000, 1)
                end
            end
        end
    end
    --]]
    --开始计时
    local missionId = tostring(self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID])
    local difficult = tostring(self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT])

    local tbl = {}
    table.insert(tbl, missionId)
    table.insert(tbl, difficult)

    log_game_debug("BasicPlayManager:Start", "missionId=%s;difficult=%s;StartTime=%d",
                                              missionId, difficult, StartTime)

    if self.StartTime == 0 then
        self.StartTime = StartTime

        local cfg = g_mission_mgr:getCfgById(table.concat(tbl, "_"))

        --获取配置文件里的关卡通过时间，如果大于0，则设置副本结束时触发的定时器
        if cfg and cfg['passTime'] > 0 then
            log_game_debug("BasicPlayManager:Start", "passTime=%d", cfg['passTime'])
            local now = os.time()
            local endTime = self.StartTime + cfg['passTime']
            if endTime > now then
                self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID] = SpaceLoader:addTimer((endTime - now), 0, public_config.TIMER_ID_END)
                log_game_debug("BasicPlayManager:Start", "triggerTime=%d", (endTime - now))
            end
        end
    end

--累加关卡挑战次数和扣除精力值的逻辑放到关卡胜利后
--    if self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID] and self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT] then
--        --副本开始后增加每个玩家身上的挑战次数
--        for playerDbid, playerInfo in pairs(self.PlayerInfo) do
--
--            local avatar = mogo.getEntity(playerInfo[public_config.PLAYER_INFO_INDEX_EID])
--            if avatar then
--                log_game_debug("BasicPlayManager:Start AddMissionTimes", "missionId=%d;difficult=%d",
--                                                                          self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID],
--                                                                          self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT])
--
--                avatar.base.MissionReq(mission_config.MSG_ADD_MISSION_TIMES,
--                                       self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID],
--                                       self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT], '')
--            end
--        end
--    end

end

--function BasicPlayManager:DeletePlayer(dbid)
--    self.PlayerInfo[dbid] = nil
--end

function BasicPlayManager:onClientDeath(PlayerDbid, SpaceLoader)

    if not self:IsSpaceLoaderSuccess() then
        return
    end

    --自动拾取一定距离内的掉落物
    --把奖励池的物品放入背包或者邮件
    for dbid, info in pairs(self.PlayerInfo) do
        if dbid == PlayerDbid then
            local player = mogo.getEntity(info[public_config.PLAYER_INFO_INDEX_EID])
            if player then
                log_game_debug("SpaceLoader:onClientDeath", "dbid=%q;name=%s;eid=%d",
                                                             dbid, player.name, info[public_config.PLAYER_INFO_INDEX_EID])
                local BusyDrops = SpaceLoader.CliEntityManager:getEntityByType(cli_entity_config.CLI_ENTITY_TYPE_DROP)
                if BusyDrops then
                    for _, BusyDrop in pairs(BusyDrops) do
                        if BusyDrop and                                                             --掉落物存在
                           BusyDrop.belongAvatar == info[public_config.PLAYER_INFO_INDEX_EID] and   --掉落物属于该角色
                           player:GetLuaDistance(BusyDrop.enterX, BusyDrop.enterY) <= g_GlobalParamsMgr:GetParams('auto_pick_up_range', 1000) then  --掉落物在玩家的5米之内
                           --如果该道具在玩家的5米之内，则让玩家拾取
                           player:ProcessPickDrop(BusyDrop.eid)
                        end
                    end
                end

                --发奖
--                self:SendReward(dbid)

                --离开副本
                player.base.MissionReq(action_config.MSG_EXIT_MISSION, 0, 0, '')
                return
            end
        end
    end

end

function BasicPlayManager:IsSpaceLoaderSuccess()

    local missionId = tostring(self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID])
    local difficult = tostring(self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT])

    local tbl = {}
    table.insert(tbl, missionId)
    table.insert(tbl, difficult)

    local cfg = g_mission_mgr:getCfgById(table.concat(tbl, "_"))

    if not cfg or not cfg['target'] then
        return false
    end

    for _, v in pairs(cfg['target']) do
--        if not self.Progress[v] then
        if not self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_PROCESS][v] then
            return false
        end
    end

    return true

end

--发奖
function BasicPlayManager:SendReward(PlayerDbid)

    if not self.PlayerInfo[PlayerDbid] then
        return
    end

    local eid = self.PlayerInfo[PlayerDbid][public_config.PLAYER_INFO_INDEX_EID]
    local player = mogo.getEntity(eid)

    --入背包
    local Rewards = self.PlayerInfo[player.dbid][public_config.PLAYER_INFO_INDEX_REWARDS]

    log_game_debug("SpaceLoader:SendReward", "Playerdbid=%q", PlayerDbid)

    if Rewards then

        --加钱
        if Rewards[public_config.PLAYER_INFO_REWARDS_MONEY] > 0 then
            player.base.AddGold(Rewards[public_config.PLAYER_INFO_REWARDS_MONEY], reason_def.mission)
            self.PlayerInfo[player.dbid][public_config.PLAYER_INFO_INDEX_REWARDS][public_config.PLAYER_INFO_REWARDS_MONEY] = 0
        end

        --加经验
        if Rewards[public_config.PLAYER_INFO_REWARDS_EXP] > 0 then
            player.base.AddExp(Rewards[public_config.PLAYER_INFO_REWARDS_EXP], reason_def.mission)
            self.PlayerInfo[player.dbid][public_config.PLAYER_INFO_INDEX_REWARDS][public_config.PLAYER_INFO_REWARDS_EXP] = 0
        end

        --加道具
        player.base.MissionC2BReq(action_config.MSG_ADD_REWARD_ITEMS, 0, 0, mogo.cPickle(Rewards[public_config.PLAYER_INFO_REWARDS_ITEMS]))
        self.PlayerInfo[player.dbid][public_config.PLAYER_INFO_INDEX_REWARDS][public_config.PLAYER_INFO_REWARDS_ITEMS] = {}
    end

end

function BasicPlayManager:AutoPickUpDrops(SpaceLoader)

    --自动拾取一定距离内的掉落物
    --把奖励池的物品放入背包或者邮件
    for dbid, info in pairs(self.PlayerInfo) do
        local player = mogo.getEntity(info[public_config.PLAYER_INFO_INDEX_EID])
        if player then
            log_game_debug("BasicPlayManager:AutoPickUpDrops", "dbid=%q;name=%s;eid=%d",
                                                                dbid, player.name, info[public_config.PLAYER_INFO_INDEX_EID])
            local BusyDrops = SpaceLoader.CliEntityManager:getEntityByType(cli_entity_config.CLI_ENTITY_TYPE_DROP)
            if BusyDrops then
                for _, BusyDrop in pairs(BusyDrops) do
                    if BusyDrop and                                                             --掉落物存在
                       BusyDrop.belongAvatar == info[public_config.PLAYER_INFO_INDEX_EID] and   --掉落物属于该角色
                       player:GetLuaDistance(BusyDrop.enterX, BusyDrop.enterY) <= g_GlobalParamsMgr:GetParams('auto_pick_up_range', 500) then  --掉落物在玩家的5米之内
                        --如果该道具在玩家的5米之内，则让玩家拾取
                        player:ProcessPickDrop(BusyDrop.eid)
                    end
                end
            end

            --发奖
--            self:SendReward(dbid)
        end
    end

end

function BasicPlayManager:Stop(SpaceLoader)

    log_game_debug("BasicPlayManager:Stop", "map_id=%s", SpaceLoader.map_id)

    --自动拾取一定距离内的掉落物
    --把奖励池的物品放入背包或者邮件
    for dbid, info in pairs(self.PlayerInfo) do
        log_game_debug("BasicPlayManager:Stop", "dbid=%q;eid=%d", dbid, info[public_config.PLAYER_INFO_INDEX_EID])
        local player = mogo.getEntity(info[public_config.PLAYER_INFO_INDEX_EID])
        if player then

            --通知每个玩家退出副本
--            player.base.TeleportCell2Base("1|1|test_des")
            log_game_debug("BasicPlayManager:Stop", "")
            player.base.MissionC2BReq(action_config.MSG_EXIT_MAP, 0, 0, '')
        end
    end

    --设置所有出生点和怪物enable(0)
    g_SrvEntityMgr:StopAliveMonster(SpaceLoader)
    SpaceLoader:ProcessCliEntityTypeDel(cli_entity_config.CLI_ENTITY_TYPE_DUMMY) 
    SpaceLoader:ProcessCliEntityTypeDel(cli_entity_config.CLI_ENTITY_TYPE_DROP) 

    --当前场景玩家的列表
    self.PlayerInfo = {}

end

function BasicPlayManager:Reset(SpaceLoader)

    log_game_debug("BasicPlayManager:Reset", "map_id=%s", SpaceLoader.map_id)

    if self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID] and
       self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID] > 0 then
        SpaceLoader:delTimer(self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID])
    end

    if self.CellInfo[mission_config.SPECIAL_MAP_INFO_SUCCESS_TIMER_ID] and
       self.CellInfo[mission_config.SPECIAL_MAP_INFO_SUCCESS_TIMER_ID] > 0 then
        SpaceLoader:delTimer(self.CellInfo[mission_config.SPECIAL_MAP_INFO_SUCCESS_TIMER_ID])
    end

--    if self.CellInfo[mission_config.SPECIAL_MAP_INFO_TOWER_DESTORY_TIMER_ID] and self.CellInfo[mission_config.SPECIAL_MAP_INFO_TOWER_DESTORY_TIMER_ID] > 0 then
--        SpaceLoader:delTimer(self.CellInfo[mission_config.SPECIAL_MAP_INFO_TOWER_DESTORY_TIMER_ID])
--    end

    if self.CellInfo[mission_config.SPECIAL_MAP_INFO_MONSTER_AUTO_DIE] and self.CellInfo[mission_config.SPECIAL_MAP_INFO_MONSTER_AUTO_DIE] > 0 then
        SpaceLoader:delTimer(self.CellInfo[mission_config.SPECIAL_MAP_INFO_MONSTER_AUTO_DIE])
    end

    if self.CellInfo[mission_config.SPECAIL_MAP_INFO_DELAY_TIMER_ID] then
        for _, id in pairs(self.CellInfo[mission_config.SPECAIL_MAP_INFO_DELAY_TIMER_ID]) do
            SpaceLoader:delTimer(id)
        end
    end

    self.CellInfo = {}    --清空副本信息

--    self.CellInfo[mission_config.SPECIAL_MAP_INFO_OWNER_DBID] = 0
--    self.CellInfo[mission_config.SPECIAL_MAP_INFO_OWNER_NAME] = ''
--    self.CellInfo[mission_config.SPECIAL_MAP_INFO_OWNER_MBSTR] = ''
--    self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID] = 0
--    self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT] = 0
--    self.CellInfo[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT] = {}               --初始化已触发的刷怪点
--    self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_PROCESS] = {}                   --初始化副本进度
--    self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID] = 0                       --副本结束的定时器ID
--    self.CellInfo[mission_config.SPECIAL_MAP_INFO_SUCCESS_TIMER_ID] = 0
--    self.CellInfo[mission_config.SPECIAL_MAP_INFO_MONSTER_AUTO_DIE] = 0

    self.Events = {}

    self.StartTime = 0
    self.EndTime = 0

    SpaceLoader.base.Reset()

end

function BasicPlayManager:ExitMission(dbid)
    log_game_debug("BasicPlayManager:ExitMission", "dbid=%q", dbid)

    if self.PlayerInfo[dbid] and 
       self:IsSpaceLoaderSuccess() and 
       (os.time() - self.EndTime) < g_GlobalParamsMgr:GetParams('exit_time', 5) then
        --当副本胜利，并且胜利时间少于5秒则给出提示，不能让玩家通过该接口离开
        local eid = self.PlayerInfo[dbid][public_config.PLAYER_INFO_INDEX_EID]
        local player = mogo.getEntity(eid)
        player.base.client.ShowTextID(CHANNEL.TIPS, 818)
    elseif self.PlayerInfo[dbid] then
        local eid = self.PlayerInfo[dbid][public_config.PLAYER_INFO_INDEX_EID]
        local player = mogo.getEntity(eid)
        player.base.MissionC2BReq(action_config.MSG_EXIT_MAP, self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID], self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT], '')
    end
end

function BasicPlayManager:QuitMission(dbid)
    log_game_debug("BasicPlayManager:QuitMission", "dbid=%q", dbid)

    if self.PlayerInfo[dbid] and not self:IsSpaceLoaderSuccess() then
        local eid = self.PlayerInfo[dbid][public_config.PLAYER_INFO_INDEX_EID]
        local player = mogo.getEntity(eid)
        player.base.client.ShowTextID(CHANNEL.TIPS, 818)
    elseif self.PlayerInfo[dbid] then
        local eid = self.PlayerInfo[dbid][public_config.PLAYER_INFO_INDEX_EID]
        local player = mogo.getEntity(eid)
        player.base.MissionC2BReq(action_config.MSG_EXIT_MAP, self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID], self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT], '')
    end
end

function BasicPlayManager:AddFriendDegree(selfDbid, mercenaryDbid)
    log_game_debug("BasicPlayManager:AddFriendDegree", "selfdbid=%q;mercenarydbid=%q", selfDbid, mercenaryDbid)
    if not self:IsSpaceLoaderSuccess() then
        return
    end

    local eid = self.PlayerInfo[selfDbid][public_config.PLAYER_INFO_INDEX_EID]
    local player = mogo.getEntity(eid)
    player.base.MissionC2BReq(action_config.MSG_ADD_FRIEND_DEGREE_C2B, 0, 0, tostring(mercenaryDbid))
end

function BasicPlayManager:Revive(PlayerDbid)
    log_game_debug("BasicPlayManager:Revive", "Playerdbid=%q", PlayerDbid)

    if self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID] and self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT] then
        if not self.PlayerInfo[PlayerDbid] then
            return
        end

        local missionId = tostring(self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID])
        local difficult = tostring(self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT])

        local tbl = {}
        table.insert(tbl, missionId)
        table.insert(tbl, difficult)

        local cfg = g_mission_mgr:getCfgById(table.concat(tbl, "_"))
        if cfg and cfg['reviveTimes'] then
            local eid = self.PlayerInfo[PlayerDbid][public_config.PLAYER_INFO_INDEX_EID]
            local player = mogo.getEntity(eid)
            if player then

                if player.ReviveTimes >= cfg['reviveTimes'] then
                    --复活次数超过上限
                    player.base.client.MissionResp(action_config.MSG_REVIVE, {-3})
                    return
                else
                    --如果玩家处于死亡状态，则设置最大血量
                    player:addHp(player.hp)
                    player.base.MissionC2BReq(action_config.MSG_REVIVE_SUCCESS, 0, 0, '')
                end
            end
        end
    end
end

function BasicPlayManager:DeathEvent(dbid, SpaceLoader)

end

function BasicPlayManager:PrepareEntities(SpaceLoader, difficulty) 
    SpaceLoader:PrepareEntities(difficulty)
end

return BasicPlayManager

