
require "public_config"
require "mission_config"
require "mission_data"
require "map_data"
require "lua_util"
require "BasicPlayManager"
require "GlobalParams"
require "action_config"

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning

--local TIMER_ID_END     = 1    --副本(关卡)结束的定时器
--local TIMER_ID_SUCCESS = 2    --副本(关卡)成功后的定时器
--local TIMER_ID_MONSTER_DIE = 3--副本(关卡)成功后演示若干秒怪物死亡
--local TIMER_ID_DESTROY = 4    --副本开始破坏
--local TIMER_ID_START   = 5    --副本开始前倒数
--local TIMER_ID_PREPARE_START = 6 --副本准备时间倒计时

TowerPlayManager = BasicPlayManager.init()

function TowerPlayManager:init()
--    log_game_debug("TowerPlayManager:init", "")
    local obj = {}
    setmetatable(obj, {__index = TowerPlayManager})
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
    obj.CellInfo[mission_config.SPECIAL_MAP_INFO_TOWER_DESTORY_TIMER_ID] = 0             --试炼之塔结束的定时器ID

    return obj
end

function TowerPlayManager:OnSpawnPointMonsterDeath(SpaceLoader, SpawnPointId)

    log_game_debug("TowerPlayManager:OnSpawnPointMonsterDeath", "SpawnPointId=%d",  SpawnPointId)


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
                    log_game_debug("TowerPlayManager:OnSpawnPointMonsterDeath notifyToClient", "map_id=%s;notifyToClient=%d",
                                                                                                SpaceLoader.map_id, notifyToClient)
                    for dbid, info in pairs(self.PlayerInfo) do
                        local avatar = mogo.getEntity(info[public_config.PLAYER_INFO_INDEX_EID])
                        if avatar then
                            avatar.base.client.MissionResp(action_config.MSG_GET_NOTIFY_TO_CLENT_EVENT, {notifyToClient})
                        end
                    end
                end
        
                local notifyOtherSpawnPoint = EventCfg['notifyOtherSpawnPoint'] 
                if notifyOtherSpawnPoint then
                    for _, cfgId in pairs(notifyOtherSpawnPoint) do
                        local spwanPoints = SpaceLoader.CliEntityManager:getEntityByType(cli_entity_config.CLI_ENTITY_TYPE_SPAWNPOINT)
                        if spwanPoints then
                            log_game_debug("TowerPlayManager:OnSpawnPointMonsterDeath notifyOtherSpawnPoint", "map_id=%s;spwanPoints=%s", SpaceLoader.map_id, mogo.cPickle(spwanPoints))
                            for _, spawnPointEntity in pairs(spwanPoints) do
                                log_game_debug("TowerPlayManager:SpawnPointEvent", "spawnPointEntity.cfgId=%d;cfgId=%d", spawnPointEntity.cfgId, cfgId)
                                if spawnPointEntity.cfgId == cfgId then
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

    if not self:IsSpaceLoaderSuccess() then
        return
    end

    if self.EndTime == 0 then
        self.EndTime = os.time()
    end

    log_game_debug("TowerPlayManager:OnSpawnPointMonsterDeath success", "map_id=%s", SpaceLoader.map_id)

    local src_map_id = g_map_mgr:GetSrcMapId(SpaceLoader.map_id)
    local map_cfg = g_map_mgr:getMapCfgData(src_map_id)

    for dbid, info in pairs(self.PlayerInfo) do
        log_game_debug("TowerPlayManager:OnSpawnPointMonsterDeath success", "id=%d", info[public_config.PLAYER_INFO_INDEX_EID])
        local avatar = mogo.getEntity(info[public_config.PLAYER_INFO_INDEX_EID])
        if avatar then
            log_game_debug("TowerPlayManager:OnSpawnPointMonsterDeath success", "dbid=%q;name=%s;missionId=%d;difficulty=%d",
                                                                                 avatar.dbid, avatar.name, 
                                                                                 self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID], 
                                                                                 self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT])

            --试炼之塔副本成功后通知客户端创建传送门
            log_game_debug("TowerPlayManager:OnSpawnPointMonsterDeath slzt success", "map_id=%s", SpaceLoader.map_id)
            avatar.base.client.TowerResp(action_config.MSG_CLIENT_TOWER_SUCCESS, {self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT]})

            --副本成功后通知base，包括加宝箱奖励
            avatar.base.TowerC2BReq(action_config.MSG_CELL2BASE_TOWER_SUCCESS, self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT], 0, '')

        end
    end

    --关卡成功以后活着的怪物死亡
    local Monsters = SpaceLoader.EntitiesInfo[public_config.ENTITY_TYPE_MONSTER]
    if Monsters then
        for _, entity in pairs(Monsters) do
            --如果怪物当前没有死，则全部设置成死亡
            if entity.curHp > 0 then
                entity.addHp(-entity.curHp)
            end
        end
    end

    --关卡成功后8秒钟，自动拾取，入背包
    SpaceLoader:addTimer(g_GlobalParamsMgr:GetParams('mission_countdown', 8), 0, public_config.TIMER_ID_SUCCESS)

end

function TowerPlayManager:OnAvatarDctor(avatar, SpaceLoader)

    if self:IsSpaceLoaderSuccess() then
        --玩家离开副本时副本已经成功
        local BusyDrops = SpaceLoader.CliEntityManager:getEntityByType(cli_entity_config.CLI_ENTITY_TYPE_DROP)
        if BusyDrops then
            for _, BusyDrop in pairs(BusyDrops) do
                if BusyDrop and                                                             --掉落物存在
                   BusyDrop.belongAvatar == avatar:getId() and                              --掉落物属于该角色
                   avatar:GetLuaDistance(BusyDrop.enterX, BusyDrop.enterY) <= g_GlobalParamsMgr:GetParams('auto_pick_up_range', 500) then  --掉落物在玩家的5米之内
                   log_game_debug("TowerPlayManager:OnAvatarDctor", "dbid=%q;name=%s", avatar.dbid, avatar.name)
                   --如果该道具在玩家的5米之内，则让玩家拾取
                   avatar:ProcessPickDrop(BusyDrop.eid)
                end
            end
        end

        --发奖
        self:SendReward(avatar.dbid)

    else
        --玩家离开副本时副本还没成功
        log_game_debug("TowerPlayManager:OnAvatarDctor slzt fail", "map_id=%s", SpaceLoader.map_id)
        avatar.base.client.TowerResp(action_config.MSG_CLIENT_TOWER_FAIL, {self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT]})
        avatar.base.TowerC2BReq(action_config.MSG_TOWER_FAIL, self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT], 0, '')
    end

    --删除对应关系
    self:DeletePlayer(avatar.dbid)

    --复活
--    avatar.deathFlag = 0
    avatar.stateFlag = Bit.Reset(avatar.stateFlag, state_config.DEATH_STATE)
    --满血
    avatar.curHp = avatar.hp
    --清战斗buff
    

end

--发奖
function TowerPlayManager:SendReward(PlayerDbid)
    --副本内临时奖励池的奖励发到base的临时奖励池

    if not self.PlayerInfo[PlayerDbid] then
        log_game_warning("TowerPlayManager:SendReward", "Playerdbid=%q", PlayerDbid)
        return
    end

    local eid = self.PlayerInfo[PlayerDbid][public_config.PLAYER_INFO_INDEX_EID]
    local player = mogo.getEntity(eid)

    local Rewards = self.PlayerInfo[player.dbid][public_config.PLAYER_INFO_INDEX_REWARDS]
    if Rewards and Rewards ~= {} then
        local RewardStr = mogo.cPickle(Rewards)
        log_game_debug("TowerPlayManager:SendReward", "Playerdbid=%q;eid=%d;RewardStr=%s", PlayerDbid, eid, RewardStr)
        player.base.TowerC2BReq(action_config.MSG_CELL2BASE_SENT_REWARD, 0, 0, RewardStr)
        self.PlayerInfo[PlayerDbid] = {[public_config.PLAYER_INFO_INDEX_EID]=player:getId(), 
                                        [public_config.PLAYER_INFO_INDEX_DEADTIMES]=0, 
                                        [public_config.PLAYER_INFO_INDEX_USE_DRUG_TIMES]=0,
                                        [public_config.PLAYER_INFO_INDEX_NAME]=player.name,
                                        [public_config.PLAYER_INFO_INDEX_REWARDS] = {[public_config.PLAYER_INFO_REWARDS_EXP] = 0,
                                                                                     [public_config.PLAYER_INFO_REWARDS_MONEY] = 0,
                                                                                     [public_config.PLAYER_INFO_REWARDS_ITEMS] = {}}
                                      }
    end
end

function TowerPlayManager:AddMoney(playerDbid, count)

    if not self.PlayerInfo[playerDbid] then
        return
    end

    if count <= 0 then
        log_game_warning("TowerPlayManager:AddMoney", "playerDbid=%d;count=%d", playerDbid, count)
        return
    end

    log_game_debug("TowerPlayManager:AddMoney", "playerDbid=%d;count=%d", playerDbid, count)

    local eid = self.PlayerInfo[playerDbid][public_config.PLAYER_INFO_INDEX_EID]
    local player = mogo.getEntity(eid)
    if not player then
        return
    end

    player.base.AddGold(count, reason_def.tower)

    --放入临时奖励池
    local oldCount = self.PlayerInfo[playerDbid][public_config.PLAYER_INFO_INDEX_REWARDS][public_config.PLAYER_INFO_REWARDS_MONEY] or 0

    self.PlayerInfo[playerDbid][public_config.PLAYER_INFO_INDEX_REWARDS][public_config.PLAYER_INFO_REWARDS_MONEY] = oldCount + count

end

function TowerPlayManager:AddExp(playerDbid, count)

    if not self.PlayerInfo[playerDbid] then
        return
    end

    if count <= 0 then
        log_game_warning("TowerPlayManager:AddExp", "playerDbid=%d;count=%d", playerDbid, count)
        return
    end

    log_game_debug("TowerPlayManager:AddExp", "playerDbid=%d;count=%d", playerDbid, count)


    local eid = self.PlayerInfo[playerDbid][public_config.PLAYER_INFO_INDEX_EID]
    local player = mogo.getEntity(eid)
    if not player then
        return
    end

    player.base.AddExp(count, reason_def.tower)

    --通知客户端飘经验
    self:NotifyAddExp(playerDbid, count)

    --放入临时奖励池
    local oldCount = self.PlayerInfo[playerDbid][public_config.PLAYER_INFO_INDEX_REWARDS][public_config.PLAYER_INFO_REWARDS_EXP] or 0

    self.PlayerInfo[playerDbid][public_config.PLAYER_INFO_INDEX_REWARDS][public_config.PLAYER_INFO_REWARDS_EXP] = oldCount + count

end

--获得道具
function TowerPlayManager:AddRewards(playerDbid, item_id, count)

    log_game_debug("TowerPlayManager:AddRewards", "playerdbid=%q;item_id=%d;count=%d", playerDbid, item_id, count)

    if not self.PlayerInfo[playerDbid] then
        return
    end

    if count <= 0 then
        log_game_warning("TowerPlayManager:AddRewards", "playerdbid=%q;item_id=%d;count=%d", playerDbid, item_id, count)
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

    log_game_debug("TowerPlayManager:AddRewards", "playerdbid=%q;items=%s", playerDbid, mogo.cPickle(self.PlayerInfo[playerDbid][public_config.PLAYER_INFO_INDEX_REWARDS][public_config.PLAYER_INFO_REWARDS_ITEMS]))

--    self:NotifyRewardsToClient(playerDbid)

end

function TowerPlayManager:ExitMission(dbid)
    log_game_debug("TowerPlayManager:ExitMission", "dbid=%q", dbid)

    if  self.PlayerInfo[dbid] then
        local eid = self.PlayerInfo[dbid][public_config.PLAYER_INFO_INDEX_EID]
        local player = mogo.getEntity(eid)
        player.base.MissionC2BReq(action_config.MSG_EXIT_MAP, 0, 0, '')
    else
        log_game_warning("TowerPlayManager:ExitMission player not exit", "dbid=%q", dbid)
    end

end

function TowerPlayManager:QuitMission(dbid)
    log_game_debug("TowerPlayManager:QuitMission", "")

    local eid = self.PlayerInfo[dbid][public_config.PLAYER_INFO_INDEX_EID]
    local player = mogo.getEntity(eid)
    player.base.MissionC2BReq(action_config.MSG_EXIT_MAP, 0, 0, '')

end

function TowerPlayManager:Start(SpaceLoader, StartTime)
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

    --通知客户端陨石开始的倒计时，并开始倒数
    for _, info in pairs(self.PlayerInfo) do
        local eid = info[public_config.PLAYER_INFO_INDEX_EID]
        local avatar = mogo.getEntity(eid)
        if avatar then
            avatar.base.TowerC2BReq(action_config.MSG_CELL2BASE_SEND_TOWER_INFO, 0, 0, "")
--            mogo.EntityOwnclientRpc(avatar, "TowerResp", action_config.MSG_TOWER_NOTIFY_COUNT_DOWN, {g_GlobalParamsMgr:GetParams('tower_destroy_time', 200)})
        end
    end

    self.CellInfo[mission_config.SPECIAL_MAP_INFO_TOWER_DESTORY_TIMER_ID] = SpaceLoader:addTimer(g_GlobalParamsMgr:GetParams('tower_destroy_time', 200), 0, public_config.TIMER_ID_DESTROY)

end

function TowerPlayManager:SpaceDestroy()
    for _, info in pairs(self.PlayerInfo) do
        local eid = info[public_config.PLAYER_INFO_INDEX_EID]
        local avatar = mogo.getEntity(eid)
        if avatar then
            mogo.EntityOwnclientRpc(avatar, "TowerResp", action_config.MSG_TOWER_START_DESTROY, {})
        end
    end
end

function TowerPlayManager:Reset(SpaceLoader)

    log_game_debug("TowerPlayManager:Reset", "map_id=%s", SpaceLoader.map_id)

    if self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID] and
            self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID] > 0 then
        SpaceLoader:delTimer(self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID])
    end

    if self.CellInfo[mission_config.SPECIAL_MAP_INFO_SUCCESS_TIMER_ID] and
            self.CellInfo[mission_config.SPECIAL_MAP_INFO_SUCCESS_TIMER_ID] > 0 then
        SpaceLoader:delTimer(self.CellInfo[mission_config.SPECIAL_MAP_INFO_SUCCESS_TIMER_ID])
    end

    if self.CellInfo[mission_config.SPECIAL_MAP_INFO_TOWER_DESTORY_TIMER_ID] and
            self.CellInfo[mission_config.SPECIAL_MAP_INFO_TOWER_DESTORY_TIMER_ID] > 0 then
        SpaceLoader:delTimer(self.CellInfo[mission_config.SPECIAL_MAP_INFO_TOWER_DESTORY_TIMER_ID])
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
--    self.CellInfo[mission_config.SPECIAL_MAP_INFO_TOWER_DESTORY_TIMER_ID] = 0

    self.Events = {}

    self.StartTime = 0
    self.EndTime = 0

    SpaceLoader.base.Reset()

end


--function TowerPlayManager:Reset(SpaceLoader)
--
--    log_game_debug("TowerDefencePlayManager:Reset", "map_id=%s", SpaceLoader.map_id)
--
--    if self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID] and
--            self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID] > 0 then
--        SpaceLoader:delTimer(self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID])
--    end
--
--    if self.CellInfo[mission_config.SPECIAL_MAP_INFO_SUCCESS_TIMER_ID] and
--            self.CellInfo[mission_config.SPECIAL_MAP_INFO_SUCCESS_TIMER_ID] > 0 then
--        SpaceLoader:delTimer(self.CellInfo[mission_config.SPECIAL_MAP_INFO_SUCCESS_TIMER_ID])
--    end
--
--    if self.CellInfo[mission_config.SPECIAL_MAP_INFO_TOWER_DESTORY_TIMER_ID] and self.CellInfo[mission_config.SPECIAL_MAP_INFO_TOWER_DESTORY_TIMER_ID] > 0 then
--        SpaceLoader:delTimer(self.CellInfo[mission_config.SPECIAL_MAP_INFO_TOWER_DESTORY_TIMER_ID])
--    end
--
--    if self.CellInfo[mission_config.SPECIAL_MAP_INFO_MONSTER_AUTO_DIE] and self.CellInfo[mission_config.SPECIAL_MAP_INFO_MONSTER_AUTO_DIE] > 0 then
--        SpaceLoader:delTimer(self.CellInfo[mission_config.SPECIAL_MAP_INFO_MONSTER_AUTO_DIE])
--    end
--
--    self.CellInfo = {}    --清空副本信息
--
--    --    self.CellInfo[mission_config.SPECIAL_MAP_INFO_OWNER_DBID] = 0
--    --    self.CellInfo[mission_config.SPECIAL_MAP_INFO_OWNER_NAME] = ''
--    --    self.CellInfo[mission_config.SPECIAL_MAP_INFO_OWNER_MBSTR] = ''
--    --    self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID] = 0
--    --    self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT] = 0
--    --    self.CellInfo[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT] = {}               --初始化已触发的刷怪点
--    --    self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_PROCESS] = {}                   --初始化副本进度
--    --    self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID] = 0                       --副本结束的定时器ID
--    --    self.CellInfo[mission_config.SPECIAL_MAP_INFO_SUCCESS_TIMER_ID] = 0
--    --    self.CellInfo[mission_config.SPECIAL_MAP_INFO_MONSTER_AUTO_DIE] = 0
--
--    self.Events = {}
--
--    self.StartTime = 0
--    self.EndTime = 0
--
--    SpaceLoader.base.Reset()
--
--end

function TowerPlayManager:onTimer(SpaceLoader, timer_id, user_data)
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
    elseif user_data == public_config.TIMER_ID_DESTROY then
--        if self.PlayManager then
        self:SpaceDestroy(SpaceLoader)
--        end
--    elseif user_data == TIMER_ID_START then
--        if self.PlayManager then
--            self.PlayManager:Start(SpaceLoader)
--        end
--    elseif user_data == TIMER_ID_PREPARE_START then
--        if self.PlayManager then
--            self.PlayManager:PrepareStart(SpaceLoader)
--        end
    end
end

function TowerPlayManager:Revive(PlayerDbid, SpaceLoader)
    log_game_debug("TowerPlayManager:Revive", "Playerdbid=%q", PlayerDbid)

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

    if self.CellInfo[mission_config.SPECIAL_MAP_INFO_TOWER_DESTORY_TIMER_ID] and self.CellInfo[mission_config.SPECIAL_MAP_INFO_TOWER_DESTORY_TIMER_ID] > 0 then
        SpaceLoader:delTimer(self.CellInfo[mission_config.SPECIAL_MAP_INFO_TOWER_DESTORY_TIMER_ID])
    end

    --通知客户端陨石开始的倒计时，并开始倒数
    for _, info in pairs(self.PlayerInfo) do
        local eid = info[public_config.PLAYER_INFO_INDEX_EID]
        local avatar = mogo.getEntity(eid)
        if avatar then
            avatar.base.TowerC2BReq(action_config.MSG_CELL2BASE_SEND_TOWER_INFO, 0, 0, "")
        end
    end

    self.CellInfo[mission_config.SPECIAL_MAP_INFO_TOWER_DESTORY_TIMER_ID] = SpaceLoader:addTimer(g_GlobalParamsMgr:GetParams('tower_destroy_time', 200), 0, public_config.TIMER_ID_DESTROY)

end

return TowerPlayManager
