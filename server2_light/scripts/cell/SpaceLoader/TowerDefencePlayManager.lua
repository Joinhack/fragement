
require "BasicPlayManager"
require "mission_config"
require "lua_util"
require "GlobalParams"
require "public_config"
require "mission_data"
require "ActivityData"
require "avatar_level_data"

--local TIMER_ID_END     = 1    --副本(关卡)结束的定时器
--local TIMER_ID_SUCCESS = 2    --副本(关卡)成功后的定时器
--local TIMER_ID_MONSTER_DIE = 3--副本(关卡)成功后演示若干秒怪物死亡
--local TIMER_ID_DESTROY = 4    --副本开始破坏
--local TIMER_ID_START   = 5    --副本开始前倒数
--local TIMER_ID_PREPARE_START = 6 --副本准备时间倒计时
--local TIMER_ID_ACITVITY_SETTLE=7 --副本结算时间

local get_table_real_count = lua_util.get_table_real_count
local log_game_debug = lua_util.log_game_debug
local log_game_error = lua_util.log_game_error

--副本状态
local STATUS_INIT       = 0    --初始状态
local STATUS_READY      = 1    --准备阶段
local STATUS_PLAYING    = 2    --进行中状态
local STATUS_SETTLED    = 3    --已结算状态

TowerDefencePlayManager = BasicPlayManager.init()

function TowerDefencePlayManager:init(Spaceloader)
    --    log_game_debug("BasicPlayManager:init", "")

    local obj = {}
    setmetatable(obj, {__index = TowerDefencePlayManager})
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
    obj.CellInfo[mission_config.SPECIAL_MAP_INFO_AVATAR_DAMAGE] = {}                     --初始化伤害列表
    obj.CellInfo[mission_config.SPECAIL_MAP_INFO_DELAY_EVENT] = {}                       --延迟触发的事件
    obj.CellInfo[mission_config.SPECAIL_MAP_INFO_DELAY_TIMER_ID] = {}                     --延迟触发的事件定时器ID


    --副本开始时进行一分钟的倒数
    obj.PrepareStartTimerId = Spaceloader:addTimer(60, 0, public_config.TIMER_ID_PREPARE_START)
    obj.StartTimerId = 0
    --开始时设置初始状态
    obj.status = STATUS_INIT

    --结算的定时器ID
    obj.SettleTimerId = 0

    --记录当前怪物波数
    obj.MonsterWave = 1

    --记录玩家打过的怪物波数
    obj.FinishedMonsterWave = 0

    --记录副本内所有刷怪点的id
    obj.AllSpawnPoints = {}

    return obj
end

function TowerDefencePlayManager:OnAvatarCtor(avatar, SpaceLoader)

    log_game_debug("TowerDefencePlayManager:OnAvatarCtor", "dbid=%q;name=%s", avatar.dbid, avatar.name)
    --记录该场景玩家的dbid与id的key-value对应关系，记录玩家在当前场景的一些数据
    --格式:{玩家dbid = {玩家ID, 死亡次数, 喝药次数, 名字, 奖励}}
    self.PlayerInfo[avatar.dbid] = {
                                    [public_config.PLAYER_INFO_INDEX_EID]=avatar:getId(),
                                    [public_config.PLAYER_INFO_INDEX_DEADTIMES]=0,
                                    [public_config.PLAYER_INFO_INDEX_USE_DRUG_TIMES]=0,
                                    [public_config.PLAYER_INFO_INDEX_NAME]=avatar.name,
                                    [public_config.PLAYER_INFO_INDEX_REWARDS] = {[public_config.PLAYER_INFO_REWARDS_EXP] = 0,
                                    [public_config.PLAYER_INFO_REWARDS_MONEY] = 0,
                                    [public_config.PLAYER_INFO_REWARDS_ITEMS] = {}}
                                    }

    --初始化玩家的伤害
    self.CellInfo[mission_config.SPECIAL_MAP_INFO_AVATAR_DAMAGE][avatar.dbid] = {avatar.name, 0 }

    local count = get_table_real_count(self.PlayerInfo)

    if count == 1 then
        --当第一个人进来的时候就开始设置副本信息
        self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID] = g_GlobalParamsMgr:GetParams("tower_defence_mission", 30002)
        self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT] = g_GlobalParamsMgr:GetParams("tower_defence_difficulty", 1)


        self.AllSpawnPoints = g_mission_mgr:getAllSpawnPointIds(self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID], self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT])

        log_game_debug("TowerDefencePlayManager:OnAvatarCtor", "dbid=%q;name=%s;AllSpawnPoints=%s", avatar.dbid, avatar.name, mogo.cPickle(self.AllSpawnPoints))

        local tbl = {}
        table.insert(tbl, g_GlobalParamsMgr:GetParams("tower_defence_mission", 30002))
        table.insert(tbl, g_GlobalParamsMgr:GetParams("tower_defence_difficulty", 1))

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

    if count >= g_GlobalParamsMgr:GetParams("tower_defence_player_count", 4) then
        --副本需要的人都进去了，就开始副本
        if self.PrepareStartTimerId > 0 then
            SpaceLoader:delTimer(self.PrepareStartTimerId)
            self.PrepareStartTimerId = 0
        end
        self:PrepareStart(SpaceLoader)
    end

    SpaceLoader.base.SetMissionInfo(avatar.dbid, avatar.name, mogo.cPickle(avatar.base), g_GlobalParamsMgr:GetParams("tower_defence_mission", 30002), g_GlobalParamsMgr:GetParams("tower_defence_difficulty", 1))

end

--副本进入准备阶段，5秒钟
function TowerDefencePlayManager:PrepareStart(SpaceLoader)

    --给副本内的每个人下发倒计时5秒
    for _, info in pairs(self.PlayerInfo) do
        local player = mogo.getEntity(info[public_config.PLAYER_INFO_INDEX_EID])
        if player then
            log_game_debug("TowerDefencePlayManager:PrepareStart CountDown", "dbid=%q;name=%s", player.dbid, player.name)
            mogo.EntityOwnclientRpc(player, "CampaignResp", action_config.MSG_CAMPAIGN_COUNT_DOWN, 0, {5,})
        end
    end

    --副本进入准备状态
    self.status = STATUS_READY

    --5秒钟后开始副本
    self.StartTimerId = SpaceLoader:addTimer(5, 0, public_config.TIMER_ID_START)
end


function TowerDefencePlayManager:SetCellInfo(playerDbid, playerName, playerMbStr, missionId, difficult)
end

function TowerDefencePlayManager:HandleDelayEvent(SpaceLoader)

--    if #self.CellInfo[public_config.SPECAIL_MAP_INFO_DELAY_EVENT] > 0 then
--        local cfgId = table.remove(self.CellInfo[public_config.SPECAIL_MAP_INFO_DELAY_EVENT], 1)
--        local spwanPoints = SpaceLoader.CliEntityManager:getEntityByType(cli_entity_config.CLI_ENTITY_TYPE_SPAWNPOINT)
--        if spwanPoints then
--            log_game_debug("TowerDefencePlayManager:HandleDelayEvent", "map_id=%s;spwanPoints=%s", SpaceLoader.map_id, mogo.cPickle(spwanPoints))
--            for _, spawnPointEntity in pairs(spwanPoints) do
--                if spawnPointEntity.cfgId == cfgId then
--                    --SpwanPoints开始刷怪
--                    SpawnPoint:Start({spawnPointData = spawnPointEntity,
--                                difficulty = g_GlobalParamsMgr:GetParams("tower_defence_difficulty", 1),
--                                triggerType = public_config.SPAWNPOINT_TRIGGER_TYPE_STEP},
--                                SpaceLoader)
--                    --副本记录该刷怪点已经开始刷怪
--                    self.CellInfo[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT][cfgId] = true
----                    SpaceLoader:SyncCliEntityInfo()
--                end
--            end
--        end
--    end

end

function TowerDefencePlayManager:OnSpawnPointMonsterDeath(SpaceLoader, SpawnPointId)

    if self.CellInfo[mission_config.SPECIAL_MAP_INFO_SUCCESS_TIMER_ID] and self.CellInfo[mission_config.SPECIAL_MAP_INFO_SUCCESS_TIMER_ID] > 0 then
        return
    end

--    log_game_debug("TowerDefencePlayManager:OnSpawnPointMonsterDeath", "SpawnPointId=%d",  SpawnPointId)

    local flag1 = false

    for event, eventResult in pairs(self.Events) do
        if eventResult[mission_config.SPECIAL_MAP_EVENT_SPAWNPOINT_MONSTER_ALL_DEAD] and not eventResult[mission_config.SPECIAL_MAP_EVENT_SPAWNPOINT_MONSTER_ALL_DEAD][SpawnPointId] then
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

                self.FinishedMonsterWave = self.FinishedMonsterWave + 1
                log_game_debug("TowerDefencePlayManager:OnSpawnPointMonsterDeath", "FinishedMonsterWave=%d", self.FinishedMonsterWave)

                self.Events[event] = nil
                local EventCfg = g_mission_mgr:getEventCfgById(event)
                local notifyToClient = EventCfg['notifyToClient']
                if notifyToClient then
--                    log_game_debug("TowerDefencePlayManager:OnSpawnPointMonsterDeath notifyToClient", "map_id=%s;notifyToClient=%d", SpaceLoader.map_id, notifyToClient)
                    for _, info in pairs(self.PlayerInfo) do
                        local avatar = mogo.getEntity(info[public_config.PLAYER_INFO_INDEX_EID])
                        if avatar then
                            avatar.base.client.MissionResp(action_config.MSG_GET_NOTIFY_TO_CLENT_EVENT, {notifyToClient})
                            avatar.base.client.MissionResp(action_config.MSG_NOTIFY_TO_CLENT_SPAWNPOINT, {SpawnPointId})
                        else
                            log_game_error("TowerDefencePlayManager:OnSpawnPointMonsterDeath notifyToClient", "map_id=%s;eid=%d", SpaceLoader.map_id, info[public_config.PLAYER_INFO_INDEX_EID])
                        end
                    end
                end

--                local delayNotifyOtherSpawnPoint = EventCfg['delayNotifyOtherSpawnPoint']
--                if delayNotifyOtherSpawnPoint then
--                    for cfgId, seconds in pairs(delayNotifyOtherSpawnPoint) do
--                        table.insert(self.CellInfo[public_config.SPECAIL_MAP_INFO_DELAY_EVENT], cfgId)
--                        table.insert(self.CellInfo[mission_config.SPECAIL_MAP_INFO_DELAY_TIMER_ID], SpaceLoader:addTimer(seconds, 0, public_config.TIMER_ID_DELAY_ACTIVE))
--                    end
--                end

                local notifyOtherSpawnPoint = EventCfg['notifyOtherSpawnPoint']
                if notifyOtherSpawnPoint then
                    for _, cfgId in pairs(notifyOtherSpawnPoint) do
                        local spwanPoints = SpaceLoader.CliEntityManager:getEntityByType(cli_entity_config.CLI_ENTITY_TYPE_SPAWNPOINT)
                        if spwanPoints then
--                            log_game_debug("TowerDefencePlayManager:OnSpawnPointMonsterDeath notifyOtherSpawnPoint", "map_id=%s;spwanPoints=%s", SpaceLoader.map_id, mogo.cPickle(spwanPoints))
                            for _, spawnPointEntity in pairs(spwanPoints) do
--                                log_game_debug("TowerDefencePlayManager:SpawnPointEvent", "spawnPointEntity.cfgId=%d;cfgId=%d", spawnPointEntity.cfgId, cfgId)
                                if spawnPointEntity.cfgId == cfgId then
                                    --SpwanPoints开始刷怪
                                    SpawnPoint:Start({spawnPointData = spawnPointEntity, 
                                                    difficulty = g_GlobalParamsMgr:GetParams("tower_defence_difficulty", 1), 
                                                    triggerType = public_config.SPAWNPOINT_TRIGGER_TYPE_STEP}, 
                                                    SpaceLoader)
                                    --副本记录该刷怪点已经开始刷怪
                                    self.CellInfo[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT][cfgId] = true
                                    SpaceLoader:SyncCliEntityInfo()

                                    flag1 = true
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if flag1 then

        --波数加1
        self.MonsterWave = self.MonsterWave + 1

--        log_game_debug("TowerDefencePlayManager:OnSpawnPointMonsterDeath", "MonsterWave=%d", self.MonsterWave)

        --给副本内的每个人下发怪物波数
        for _, info in pairs(self.PlayerInfo) do
            local player = mogo.getEntity(info[public_config.PLAYER_INFO_INDEX_EID])
            if player then
                --下发第几波的通知
                mogo.EntityOwnclientRpc(player, "CampaignResp", action_config.MSG_CAMPAIGN_NOTIFY_WAVE_COUNT, 0, {self.MonsterWave,})
            end
        end
    end

    --记录关卡进度
    self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_PROCESS][SpawnPointId] = true

    --通知base已经完成的spawnpoint
--    log_game_debug("TowerDefencePlayManager:OnSpawnPointMonsterDeath AddFinishedSpawnPoint", "SpawnPointId=%d",  SpawnPointId)
    SpaceLoader.base.AddFinishedSpawnPoint(SpawnPointId)


    --记录刷怪点的死亡情况，如果指定的点都死了，就开始结算
    self.AllSpawnPoints[SpawnPointId] = nil
    if get_table_real_count(self.AllSpawnPoints) == 0 then
        --玩家副本结束，开始结算
        if self.SettleTimerId > 0 then
            SpaceLoader:delTimer(self.SettleTimerId)
            self:Settle()
        end
        return
    end

    if not self:IsSpaceLoaderSuccess() then
        return
    end

    --当塔防副本的关卡目标达到时，意味着水晶已经被打烂，副本失败

    if self.EndTime == 0 then
        self.EndTime = os.time()
    end

--    local UsedTime = os.time() - self.StartTime
--    log_game_debug("TowerDefencePlayManager:OnSpawnPointMonsterDeath fail", "map_id=%s;UsedTime=%d", SpaceLoader.map_id, UsedTime)

--    for _, info in pairs(self.PlayerInfo) do
--        log_game_debug("TowerDefencePlayManager:OnSpawnPointMonsterDeath fail", "id=%d", info[public_config.PLAYER_INFO_INDEX_EID])
--
--        local avatar = mogo.getEntity(info[public_config.PLAYER_INFO_INDEX_EID])
--        if avatar then
--            --副本水晶被打烂，通知每个客户端副本已经失败
--            mogo.EntityOwnclientRpc(avatar, "CampaignResp", action_config.MSG_CAMPAIGN_RESULT, 1, {})
--        end
--    end

    --玩家副本结束，开始结算
    if self.SettleTimerId > 0 then
        SpaceLoader:delTimer(self.SettleTimerId)
        self:Settle()
    end

--    --回收副本
--    self:Recover(SpaceLoader)
end

function TowerDefencePlayManager:Start(SpaceLoader)
    if get_table_real_count(self.PlayerInfo) <= 0 then
        --如果开始倒计时结束后副本内的玩家个数为0，则回收该副本
        self:Recover(SpaceLoader)
    else
        if self.StartTime ~= 0 then
            return
        end

        self.StartTime = os.time()

        self.status = STATUS_PLAYING

        self.SettleTimerId = SpaceLoader:addTimer(g_GlobalParamsMgr:GetParams("tower_defence_time", 6*60), 0, public_config.TIMER_ID_ACITVITY_SETTLE)

        local tbl = {}
        table.insert(tbl, self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID])
        table.insert(tbl, self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT])

        local cfg = g_mission_mgr:getCfgById(table.concat(tbl, "_"))
        if cfg  and cfg['passTime'] > 0 then
            log_game_debug("BasicPlayManager:Start", "passTime=%d", cfg['passTime'])
            local now = os.time()
            local endTime = self.StartTime + cfg['passTime']
            if endTime > now then
                self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID] = SpaceLoader:addTimer((endTime - now), 0, public_config.TIMER_ID_END)
--                log_game_debug("TowerDefencePlayManager:Start", "triggerTime=%d", (endTime - now))

                --给副本内的每个人下发倒计时
                for _, info in pairs(self.PlayerInfo) do
                    --        log_game_debug("TowerDefencePlayManager:Stop", "dbid=%q;eid=%d", dbid, info[public_config.PLAYER_INFO_INDEX_EID])
                    local player = mogo.getEntity(info[public_config.PLAYER_INFO_INDEX_EID])
                    if player then
                        log_game_debug("TowerDefencePlayManager:Start CountDown", "dbid=%q;name=%s", player.dbid, player.name)
                        --下发倒计时
                        mogo.EntityOwnclientRpc(player, "CampaignResp", action_config.MSG_CAMPAIGN_MISSION_COUNT_DOWN, 0, {g_GlobalParamsMgr:GetParams("tower_defence_time", 6*60),})

                        --下发第几波的通知
                        mogo.EntityOwnclientRpc(player, "CampaignResp", action_config.MSG_CAMPAIGN_NOTIFY_WAVE_COUNT, 0, {self.MonsterWave,})
                    end
                end
            end
        end

        for event, eventResult in pairs(self.Events) do
            if eventResult[mission_config.SPECIAL_MAP_EVENT_INIT] then
                eventResult[mission_config.SPECIAL_MAP_EVENT_INIT] = false

                --触发该事件的条件已经达成，通知客户端触发事件
                self.Events[event] = nil
                local EventCfg = g_mission_mgr:getEventCfgById(event)

                local notifyOtherSpawnPoint = EventCfg['notifyOtherSpawnPoint']
                if notifyOtherSpawnPoint then
                    for _, cfgId in pairs(notifyOtherSpawnPoint) do
                        local spwanPoints = SpaceLoader.CliEntityManager:getEntityByType(cli_entity_config.CLI_ENTITY_TYPE_SPAWNPOINT)
                        if spwanPoints then
--                            log_game_debug("TowerDefencePlayManager:Start notifyOtherSpawnPoint", "map_id=%s;spwanPoints=%s", SpaceLoader.map_id, mogo.cPickle(spwanPoints))
                            for _, spawnPointEntity in pairs(spwanPoints) do
--                                log_game_debug("TowerDefencePlayManager:SpawnPointEvent", "spawnPointEntity.cfgId=%d;cfgId=%d", spawnPointEntity.cfgId, cfgId)
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
end

function TowerDefencePlayManager:ExitMission(dbid)
    log_game_debug("TowerDefencePlayManager:ExitMission", "dbid=%q", dbid)


    self:QuitMission(dbid)

--    local info = self.PlayerInfo[dbid]
--
--    if not info then
--        log_game_error("TowerDefencePlayManager:ExitMission not exit", "dbid=%q", dbid)
--        return
--    end
--
--    local flag = false
--    if not self:IsSpaceLoaderSuccess() then
--        --如果副本的胜利条件还没达到，也就是水晶还没被打烂，则任务玩家胜利
--        flag = true
--    end
--
--    local wave =  get_table_real_count(self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_PROCESS])
--
--    local player = mogo.getEntity(info[public_config.PLAYER_INFO_INDEX_EID])
--    if player then
--        log_game_debug("TowerDefencePlayManager:ExitMission", "dbid=%q;name=%s", player.dbid, player.name)
--        player.base.MissionC2BReq(action_config.MSG_EXIT_MAP, 0, 0, '')
--
--        --玩家退出时结算当前波数
--        local towerReward = gActivityData:getTowerDefenceReward(wave, player.level)
--        local levelProps = g_avatar_level_mgr:GetLevelProps(player.level)
--        local expStandard = levelProps['expStandard'] or 0
--        local goldStandard = levelProps['goldStandard'] or 0
--
--        local harm = self.CellInfo[mission_config.SPECIAL_MAP_INFO_AVATAR_DAMAGE][player.dbid] or 0
--
--        if flag then
--            player.base.CampaignC2BReq(action_config.MSG_CAMPAIGN_REWARD_C2B, wave, harm,
--                {
--                    [1] = (towerReward['exp'] or 0) * expStandard,
--                    [2] = (towerReward['gold'] or 0) * goldStandard,
--                    [3] = towerReward['items'] or {},
--                    [4] = 0,
--                })
--        else
--            player.base.CampaignC2BReq(action_config.MSG_CAMPAIGN_REWARD_C2B, wave, harm,
--                {
--                    [1] = (towerReward['exp'] or 0) * expStandard,
--                    [2] = (towerReward['gold'] or 0) * goldStandard,
--                    [3] = towerReward['items'] or {},
--                    [4] = 1,
--                })
--        end
--    end
end

function TowerDefencePlayManager:QuitMission(dbid)
    log_game_debug("TowerDefencePlayManager:QuitMission", "dbid=%q", dbid)

    local info = self.PlayerInfo[dbid]

    if not info then
        log_game_error("TowerDefencePlayManager:QuitMission not exit", "dbid=%q", dbid)
        return
    end

--    local flag = false
--    if not self:IsSpaceLoaderSuccess() then
--        --如果副本的胜利条件还没达到，也就是水晶还没被打烂，则任务玩家胜利
--        flag = true
--    end

--    local wave =  get_table_real_count(self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_PROCESS])
    local wave =  self.FinishedMonsterWave

    local player = mogo.getEntity(info[public_config.PLAYER_INFO_INDEX_EID])
    if player then
        log_game_debug("TowerDefencePlayManager:QuitMission", "dbid=%q;name=%s", player.dbid, player.name)
        player.base.MissionC2BReq(action_config.MSG_EXIT_MAP, 0, 0, '')

        if self.status ==  STATUS_PLAYING then
            --如果玩家退出时副本还在进行中，则需要结算
            --玩家退出时结算当前波数
            local towerReward = gActivityData:getTowerDefenceReward(wave, player.level)
            local levelProps = g_avatar_level_mgr:GetLevelProps(player.level)
            local expStandard = levelProps['expStandard'] or 0
            local goldStandard = levelProps['goldStandard'] or 0

            local harm = self.CellInfo[mission_config.SPECIAL_MAP_INFO_AVATAR_DAMAGE][player.dbid] or {}

    --        if flag then
            player.base.CampaignC2BReq(action_config.MSG_CAMPAIGN_REWARD_C2B, wave, harm[2],
                {
--                    [1] = (towerReward['exp'] or 0) * expStandard,
--                    [2] = (towerReward['gold'] or 0) * goldStandard,
                    [1] = math.min((towerReward['exp'] or 0), (g_GlobalParamsMgr:GetParams("tower_defence_exp_upperlimit", 10) * expStandard)),
                    [2] = math.min((towerReward['gold'] or 0), (g_GlobalParamsMgr:GetParams("tower_defence_gold_upperlimit", 10) * goldStandard)),
                    [3] = towerReward['items'] or {},
                    [4] = 2,
                    [5] = 0,
                    [6] = 0,
                    [7] = '',
                })
        end

    end
end

function TowerDefencePlayManager:AddDamage(avatar, harm)
    log_game_debug("TowerDefencePlayManager:AddDamage", "dbid=%q;name=%s;harm=%d", avatar.dbid, avatar.name, harm)
    local name_harm = self.CellInfo[mission_config.SPECIAL_MAP_INFO_AVATAR_DAMAGE][avatar.dbid]
    if name_harm then
--        log_game_debug("TowerDefencePlayManager:AddDamage", "dbid=%q;name=%s;name_harm=%s", avatar.dbid, avatar.name, mogo.cPickle(name_harm))
        self.CellInfo[mission_config.SPECIAL_MAP_INFO_AVATAR_DAMAGE][avatar.dbid] = {name_harm[1], name_harm[2] + harm}
    end
end

function TowerDefencePlayManager:onTimer(SpaceLoader, timer_id, user_data)
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
    elseif user_data == public_config.TIMER_ID_START then
--        if self.PlayManager then
        self:Start(SpaceLoader)
--        end
    elseif user_data == public_config.TIMER_ID_PREPARE_START then
--        if self.PlayManager then
        self:PrepareStart(SpaceLoader)
--        end
    elseif user_data == public_config.TIMER_ID_ACITVITY_SETTLE then
        --结算时间到了就结算发奖励
        self:Settle()
--    elseif user_data == public_config.TIMER_ID_DELAY_ACTIVE then
--        self:HandleDelayEvent(SpaceLoader)
    end
end

function TowerDefencePlayManager:Settle()

    if self.status == STATUS_SETTLED then
        log_game_error("TowerDefencePlayManager:Settle", "")
        return
    end

    self.status = STATUS_SETTLED

    local flag = false
    if not self:IsSpaceLoaderSuccess() then
        --如果副本的胜利条件还没达到，也就是水晶还没被打烂，则任务玩家胜利
        flag = true
    end

--    local wave =  get_table_real_count(self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_PROCESS])
    local wave =  self.FinishedMonsterWave

    local MaxHarm = 0
    local MaxHarmDbid = 0
    local MaxName = ''
    for dbid, v in pairs(self.CellInfo[mission_config.SPECIAL_MAP_INFO_AVATAR_DAMAGE]) do
        if v[2] > MaxHarm then
            MaxHarmDbid = dbid
            MaxName = v[1]
            MaxHarm = v[2]
        end
    end

    local MaxHarmName = self.PlayerInfo[MaxHarmDbid]

    for _, info in pairs(self.PlayerInfo) do
        --        log_game_debug("TowerDefencePlayManager:Stop", "dbid=%q;eid=%d", dbid, info[public_config.PLAYER_INFO_INDEX_EID])
        local player = mogo.getEntity(info[public_config.PLAYER_INFO_INDEX_EID])
        if player then

            log_game_debug("TowerDefencePlayManager:Settle", "dbid=%q;name=%s;flag=%s;wave=%d;MaxHarmDbid=%d;MaxName=%s;MaxHarm=%d", player.dbid, player.name, flag, wave, MaxHarmDbid, MaxName, MaxHarm)

--            player.base.MissionC2BReq(action_config.MSG_EXIT_MAP, 0, 0, '')
            local towerReward = gActivityData:getTowerDefenceReward(wave, player.level)
            local levelProps = g_avatar_level_mgr:GetLevelProps(player.level)
            local expStandard = levelProps['expStandard'] or 0
            local goldStandard = levelProps['goldStandard'] or 0

            local harm = self.CellInfo[mission_config.SPECIAL_MAP_INFO_AVATAR_DAMAGE][player.dbid] or {}

            if flag then
                player.base.CampaignC2BReq(action_config.MSG_CAMPAIGN_REWARD_C2B, wave, harm[2],
                    {
--                        [1] = (towerReward['exp'] or 0) * expStandard,
--                        [2] = (towerReward['gold'] or 0) * goldStandard,
                        [1] = math.min((towerReward['exp'] or 0), (g_GlobalParamsMgr:GetParams("tower_defence_exp_upperlimit", 10) * expStandard)),
                        [2] = math.min((towerReward['gold'] or 0), (g_GlobalParamsMgr:GetParams("tower_defence_gold_upperlimit", 10) * goldStandard)),
                        [3] = towerReward['items'] or {},
                        [4] = 0,
                        [5] = MaxHarm,
                        [6] = MaxHarmDbid,
                        [7] = MaxName,
                    })
            else
                player.base.CampaignC2BReq(action_config.MSG_CAMPAIGN_REWARD_C2B, wave, harm[2],
                    {
--                        [1] = (towerReward['exp'] or 0) * expStandard,
--                        [2] = (towerReward['gold'] or 0) * goldStandard,
                        [1] = math.min((towerReward['exp'] or 0), (g_GlobalParamsMgr:GetParams("tower_defence_exp_upperlimit", 10) * expStandard)),
                        [2] = math.min((towerReward['gold'] or 0), (g_GlobalParamsMgr:GetParams("tower_defence_gold_upperlimit", 10) * goldStandard)),
                        [3] = towerReward['items'] or {},
                        [4] = 1,
                        [5] = MaxHarm,
                        [6] = MaxHarmDbid,
                        [7] = MaxName,
                    })
            end
        end
    end
end

function TowerDefencePlayManager:Reset(SpaceLoader)

    log_game_debug("TowerDefencePlayManager:Reset", "map_id=%s", SpaceLoader.map_id)

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

return TowerDefencePlayManager