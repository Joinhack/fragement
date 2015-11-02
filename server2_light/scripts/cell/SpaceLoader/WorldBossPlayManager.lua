--author:hwj
--date:2013-6-28
--此为世界boss场景数据管理类
--todo:优化把mogo.getEntity(eid) 替换为使用场景保存的base mailbox
require "lua_util"
require "public_config"
require "mission_config"
require "mission_data"
require "map_data"
require "BasicPlayManager"
require "GlobalParams"
require "state_config"
require "reason_def"
require "action_config"

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error

--local TIMER_ID_END     = 1    --副本(关卡)结束的定时器
--local TIMER_ID_SUCCESS = 2    --副本(关卡)成功后的定时器
--local TIMER_ID_MONSTER_DIE = 3--副本(关卡)成功后演示若干秒怪物死亡

WorldBossPlayManager = BasicPlayManager.init()

function WorldBossPlayManager:init(owner, sceneId)
--    log_game_debug("WorldBossPlayManager:init", "")

    local obj = {}
    setmetatable(obj, {__index = WorldBossPlayManager})
    obj.ptr = {}
    setmetatable(obj.ptr, {__mode = "v"})
    -->>>>  BasicPlayerManager的数据
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
    --<<<<
    
    obj.ptr.sp_ref = owner
    obj.isStart = true
    
    obj.m_localTimerIds = {}
    --new
    obj.BaseWBMgrMb = {} 
    obj.boss = {} 
    obj.isSetMission = false

    obj.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID] = sceneId
    obj.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT] = 1
    
    obj.CellInfo[mission_config.SPECIAL_MAP_INFO_MONSTER_AUTO_DIE] = 0

    return obj
end

function WorldBossPlayManager:OnAvatarCtor(avatar)

    log_game_debug("WorldBossPlayManager:OnAvatarCtor", "dbid=%q;name=%s", avatar.dbid, avatar.name)
    --记录该场景玩家的dbid与id的key-value对应关系，记录玩家在当前场景的一些数据
    --格式:{玩家dbid = {玩家ID, 死亡次数, 喝药次数, 名字, 奖励}}
    self.PlayerInfo[avatar.dbid] = {[public_config.PLAYER_INFO_INDEX_EID]=avatar:getId(), 
                                    [public_config.PLAYER_INFO_INDEX_DEADTIMES]=0, 
                                    [public_config.PLAYER_INFO_INDEX_USE_DRUG_TIMES]=0,
                                    [public_config.PLAYER_INFO_INDEX_NAME]=avatar.name,
                                    [public_config.PLAYER_INFO_INDEX_REWARDS] = {[public_config.PLAYER_INFO_REWARDS_EXP] = 0,
                                                                                 [public_config.PLAYER_INFO_REWARDS_MONEY] = 0,
                                                                                 [public_config.PLAYER_INFO_REWARDS_ITEMS] = {}},
                                    [public_config.PLAYER_INFO_INDEX_DAMEGE] = 0,
                                    [public_config.PLAYER_INFO_INDEX_BASEMB] = {}
                                  }
    --清楚自己的一些记录
    self:DelLocalKickTimer(avatar.dbid, self.ptr.sp_ref)

    --世界boss使用到
    self.ptr.sp_ref.base.ChangeMapCount(public_config.CHANGE_MAP_COUNT_ADD, 1)

end

function WorldBossPlayManager:OnAvatarDctor(avatar, SpaceLoader)

    log_game_debug("WorldBossPlayManager:OnAvatarDctor", "dbid=%q;name=%s", avatar.dbid, avatar.name)

    --圣域守卫战需要
    --SpaceLoader.base.ChangeMapCount(public_config.CHANGE_MAP_COUNT_SUB, 1)

    --if self:IsSpaceLoaderSuccess() then
        --玩家离开副本时副本已经成功
        local BusyDrops = SpaceLoader.CliEntityManager:getEntityByType(cli_entity_config.CLI_ENTITY_TYPE_DROP)
        if BusyDrops then
            for _, BusyDrop in pairs(BusyDrops) do
                if BusyDrop and                                                             --掉落物存在
                   BusyDrop.belongAvatar == avatar:getId() and                              --掉落物属于该角色
                   avatar:GetLuaDistance(BusyDrop.enterX, BusyDrop.enterY) <= g_GlobalParamsMgr:GetParams('auto_pick_up_range', 500) then  --掉落物在玩家的5米之内
                   log_game_debug("WorldBossPlayManager:OnAvatarDctor", "dbid=%q;name=%s", avatar.dbid, avatar.name)
                   --如果该道具在玩家的5米之内，则让玩家拾取
                   avatar:ProcessPickDrop(BusyDrop.eid)
                end
            end
        end
        self:ProcessPickDrop(avatar.dbid, SpaceLoader)
        --发奖
        --self:SendReward(avatar.dbid)
    --end

    --删除对应关系
    self:DeletePlayer(avatar.dbid)

    --复活
--    avatar.deathFlag = 0
    avatar.stateFlag = Bit.Reset(avatar.stateFlag, state_config.DEATH_STATE)
    --满血
    avatar.curHp = avatar.hp
    --清战斗buff

    --
    self:DelLocalKickTimer(avatar.dbid, SpaceLoader)
end

--回收
function WorldBossPlayManager:Recover(SpaceLoader)
    log_game_debug("WorldBossPlayManager:Recover", "")
    if self.isStart then return end
    SpaceLoader:Stop()
    --副本重置
    --SpaceLoader:Reset()
end

function WorldBossPlayManager:DeletePlayer(dbid)

    log_game_debug("WorldBossPlayManager:DeletePlayer", "dbid=%q", dbid)

    self.PlayerInfo[dbid] = nil
end

function WorldBossPlayManager:SetCellInfo(playerDbid, playerName, playerMbStr, missionId, difficult, SpaceLoader)

    log_game_debug("WorldBossPlayManager:SetCellInfo", "dbid=%q;name=%s;mb=%s;missionId=%d;difficult=%d",
                                                    playerDbid, playerName, playerMbStr, missionId, difficult)

    if not self.PlayerInfo[playerDbid] then
        log_game_error("WorldBossPlayManager:SetCellInfo", "")
        --return
    end
    self.PlayerInfo[playerDbid][public_config.PLAYER_INFO_INDEX_BASEMB] = mogo.UnpickleBaseMailbox(playerMbStr)
    if self.isSetMission then
        log_game_debug("WorldBossPlayManager:SetCellInfo", "have set SetCellInfo.")
        return
    end

    log_game_debug("WorldBossPlayManager:SetCellInfo", "start to set SetCellInfo.")
    --BasicPlayManager:SetCellInfo(playerDbid, playerName, playerMbStr, missionId, difficult)

    --self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID] = missionId
    --self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT] = difficult

    --初始化副本事件表
    self.Events = {}

    local missionId = tostring(self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID])
    local difficult = tostring(self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT])
    self.isSetMission = true
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
    --[[
    if self.isStart then
        self:SpawnPointEvent(mission_config.SPAWNPOINT_START, public_config.SANCTUARY_BOSS_SPWAN_ID, SpaceLoader)
    end
    ]]
end
--改为由base上的worldbossmgr统一触发
function WorldBossPlayManager:SpawnPointEvent(EventId, dbid, SpawnPointId, SpaceLoader)

    log_game_debug("WorldBossPlayManager:SpawnPointEvent", "EventId=%d;SpawnPointId=%d", EventId, SpawnPointId)
    if not self.isSetMission then
        --log_game_error("WorldBossPlayManager:SpawnPointEvent", "not set mission.")
        --return
    end
    if EventId == mission_config.SPAWNPOINT_START and not self.isStart then return end
    --如果客户端要求开始刷怪，但是服务器记录改点之前已经开始过，则跳过，该情况一般出现在客户端断线5分钟内重连
    if EventId == mission_config.SPAWNPOINT_START and
        self.CellInfo[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT][SpawnPointId] then
        log_game_debug("WorldBossPlayManager:SpawnPointEvent", "had started.")
        return
    end

    local spwanPoints = SpaceLoader.CliEntityManager:getEntityByType(cli_entity_config.CLI_ENTITY_TYPE_SPAWNPOINT)
    if spwanPoints then
        for _, spawnPointEntity in pairs(spwanPoints) do
            log_game_debug("WorldBossPlayManager:SpawnPointEvent", "spawnPointEntity.cfgId=%d", spawnPointEntity.cfgId)
            if spawnPointEntity.cfgId == SpawnPointId then
                if EventId == mission_config.SPAWNPOINT_START then
                    --如果或者没开始不刷
                    if not self.isStart then 
                        log_game_debug("WorldBossPlayManager:SpawnPointEvent", "")
                        return 
                    end
                    --SpwanPoints开始刷怪
                    SpawnPoint:Start({spawnPointData = spawnPointEntity, 
                                difficulty = self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT],
                                triggerType = public_config.SPAWNPOINT_TRIGGER_TYPE_STEP}, 
                                SpaceLoader)
                    --副本记录该刷怪点已经开始刷怪
                    self.CellInfo[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT][SpawnPointId] = true
                    SpaceLoader:SyncCliEntityInfo()
                elseif EventId == mission_config.SPAWNPOINT_STOP then
                    SpawnPoint:Stop()
                end
            end
        end
    end

end

--todo:暂时没有这个需求
function WorldBossPlayManager:OnSpawnPointMonsterDeath(SpaceLoader, SpawnPointId)
    log_game_debug("WorldBossPlayManager:OnSpawnPointMonsterDeath", "SpawnPointId=%d",  SpawnPointId)
end

function WorldBossPlayManager:Start(SpaceLoader, StartTime)
    log_game_debug("WorldBossPlayManager:Start", '')

    if self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID] 
        and self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID] > 0 then
        log_game_error("WorldBossPlayManager:Start", "Still have TIMER_ID_END = [%d]", self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID])
        return
    end
    --self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID] = SpaceLoader:addTimer(3600, 0, TIMER_ID_END)

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
end

--掉线后不立即退出
function WorldBossPlayManager:onClientDeath(PlayerDbid)
    log_game_debug("WorldBossPlayManager:onClientDeath", "Playerdbid = %q", PlayerDbid)

    --self:ProcessPickDrop(PlayerDbid, SpaceLoader)
    self:SendReward(PlayerDbid, 0, false)
    --self:AddLocalKickTimer(dbid, SpaceLoader)
end

function WorldBossPlayManager:IsSpaceLoaderSuccess()
    return true
end

function WorldBossPlayManager:ProcessPickDrop(PlayerDbid, SpaceLoader)
    local thePlayerData = self.PlayerInfo[PlayerDbid]
    if not thePlayerData then
        log_game_error("WorldBossPlayManager:ProcessPickDrop", "")
        return
    end
    local eid = thePlayerData[public_config.PLAYER_INFO_INDEX_EID]
    local player = mogo.getEntity(eid)
    if not player then 
        log_game_debug("WorldBossPlayManager:ProcessPickDrop", "player[%d] is detroyed.", PlayerDbid)
        return 
    end
    --自动拾取一定距离内的掉落物
    local BusyDrops = SpaceLoader.CliEntityManager:getEntityByType(cli_entity_config.CLI_ENTITY_TYPE_DROP)
    if BusyDrops then
        for _, BusyDrop in pairs(BusyDrops) do
            if BusyDrop and                                                             --掉落物存在
               BusyDrop.belongAvatar == thePlayerData[public_config.PLAYER_INFO_INDEX_EID] and   --掉落物属于该角色
               player:GetLuaDistance(BusyDrop.enterX, BusyDrop.enterY) <= g_GlobalParamsMgr:GetParams('auto_pick_up_range', 1000) then  --掉落物在玩家的5米之内
               --如果该道具在玩家的5米之内，则让玩家拾取
               player:ProcessPickDrop(BusyDrop.eid)
            end
        end
    end
end

--发奖
function WorldBossPlayManager:SendReward(PlayerDbid, win, bShow)
    log_game_debug("WorldBossPlayManager:SendReward", "Playerdbid=%q", PlayerDbid)
    --发送伤害奖励,通过base usermgr
    local thePlayerData = self.PlayerInfo[PlayerDbid]
    if not thePlayerData then
        log_game_error("WorldBossPlayManager:SendReward", "")
        return
    end
    --发送伤害奖励,通过base usermgr
    log_game_debug("WorldBossPlayManager:SendReward", 'send.damage = %d', thePlayerData[public_config.PLAYER_INFO_INDEX_DAMEGE])
    --self.ptr.theOwner.base.SendWBReward(PlayerDbid, thePlayerData[public_config.PLAYER_INFO_INDEX_DAMEGE])

    --有可能entity已经destroy了，todo:
    local eid = thePlayerData[public_config.PLAYER_INFO_INDEX_EID]
    local player = mogo.getEntity(eid)
    if not player then 
        log_game_debug("WorldBossPlayManager:SendReward", "player[%d] is detroyed.", PlayerDbid)
        return 
    end
    local rewards_for_show = {}
    --发放wb奖励, 伤害奖励
    local demage = thePlayerData[public_config.PLAYER_INFO_INDEX_DAMEGE]
    if demage and demage > 0 then
        local fa = g_sanctuary_defense_mgr:GetFactors(player.level)
        local wb_exp = math.ceil(fa.expFactor * demage / 10000)
        local wb_gold = math.ceil(fa.goldFactor * demage / 10000)
        if wb_gold > 0 then
            --增加上限
            if wb_gold > fa.goldLimit then
                wb_gold = fa.goldLimit
            end
            player.base.AddGold(wb_gold, reason_def.wb_fight)
            rewards_for_show[public_config.GOLD_ID] = wb_gold
        end
        if wb_exp > 0 then
            player.base.AddExp(wb_exp, reason_def.wb_fight)
            rewards_for_show[public_config.EXP_ID] = wb_exp
        end
        thePlayerData[public_config.PLAYER_INFO_INDEX_DAMEGE] = 0
    end

    --发放奖励池里的奖励（打小怪或者关卡奖励）
    local Rewards = thePlayerData[public_config.PLAYER_INFO_INDEX_REWARDS]

    log_game_debug("WorldBossPlayManager:SendReward", "Playerdbid=%q 2", PlayerDbid)

    if Rewards then
        --加钱
        if Rewards[public_config.PLAYER_INFO_REWARDS_MONEY] > 0 then
            --player.base.add_gold(Rewards[public_config.PLAYER_INFO_REWARDS_MONEY])
            player.base.AddGold(Rewards[public_config.PLAYER_INFO_REWARDS_MONEY], reason_def.world_boss)
            --player.base.ShowText(CHANNEL.TIPS, "AddGold:"..Rewards[public_config.PLAYER_INFO_REWARDS_MONEY])
            thePlayerData[public_config.PLAYER_INFO_INDEX_REWARDS][public_config.PLAYER_INFO_REWARDS_MONEY] = 0
            if rewards_for_show[public_config.GOLD_ID] then
                rewards_for_show[public_config.GOLD_ID] = rewards_for_show[public_config.GOLD_ID] + Rewards[public_config.PLAYER_INFO_REWARDS_MONEY]
            else
                rewards_for_show[public_config.GOLD_ID] = Rewards[public_config.PLAYER_INFO_REWARDS_MONEY]
            end 
        end

        --加经验
        if Rewards[public_config.PLAYER_INFO_REWARDS_EXP] > 0 then
            --player.base.AddExp(Rewards[public_config.PLAYER_INFO_REWARDS_EXP], public_config.EXP_SOURCE_MISSION)
            player.base.AddExp(Rewards[public_config.PLAYER_INFO_REWARDS_EXP], reason_def.world_boss)
            --player.base.ShowText(CHANNEL.TIPS, "AddExp:"..Rewards[public_config.PLAYER_INFO_REWARDS_EXP])
            thePlayerData[public_config.PLAYER_INFO_INDEX_REWARDS][public_config.PLAYER_INFO_REWARDS_EXP] = 0
            if rewards_for_show[public_config.EXP_ID] then
                rewards_for_show[public_config.EXP_ID] = rewards_for_show[public_config.EXP_ID] + Rewards[public_config.PLAYER_INFO_REWARDS_EXP]
            else
                rewards_for_show[public_config.EXP_ID] = Rewards[public_config.PLAYER_INFO_REWARDS_EXP]
            end
        end

        --加道具
        local b = false
        for k,v in pairs(Rewards[public_config.PLAYER_INFO_REWARDS_ITEMS]) do
            rewards_for_show[k] = v
        end
        if b then
            player.base.MissionC2BReq(action_config.MSG_ADD_REWARD_ITEMS, 0, 0, mogo.cPickle(Rewards[public_config.PLAYER_INFO_REWARDS_ITEMS]))
            thePlayerData[public_config.PLAYER_INFO_INDEX_REWARDS][public_config.PLAYER_INFO_REWARDS_ITEMS] = {}
        end
    end
    if bShow then
        if win == 0 then
            player.base.client.ShowRewardForms(rewards_for_show, 15, g_text_id.WB_FIGHT_FAIL_TITLE, g_text_id.WB_FIGHT_FAIL_TEXT, 0)
        else
            player.base.client.ShowRewardForms(rewards_for_show, 15, g_text_id.WB_FIGHT_SUC_TITLE, g_text_id.WB_FIGHT_SUC_TEXT, 1)
        end
    end
end

function WorldBossPlayManager:AddLocalKickTimer(dbid, SpaceLoader)
    log_game_debug("WorldBossPlayManager:AddLocalKickTimer", "")
    if self.m_localTimerIds[dbid] then
        log_game_error("WorldBossPlayManager:AddLocalKickTimer", "already haved.")
        return
    end
    self.m_localTimerIds[dbid] = SpaceLoader:addLocalTimer("DelayKick", 17000, 1, dbid) --17s后
end

function WorldBossPlayManager:DelLocalKickTimer(dbid, SpaceLoader)
    log_game_debug("WorldBossPlayManager:DelLocalKickTimer", "")
    local tid = self.m_localTimerIds[dbid]
    if not tid then
        --log_game_error("WorldBossPlayManager:DelLocalKickTimer", "hasnt.")
        return
    end
    if SpaceLoader:hasLocalTimer(tid) then
        SpaceLoader:delLocalTimer(tid)
    end
    if self.m_localTimerIds[dbid] then
        self.m_localTimerIds[dbid] = nil
    end
end

function WorldBossPlayManager:DelayKick(dbid)
    local thePlayerData = self.PlayerInfo[dbid]
    if not thePlayerData then
        log_game_warning("WorldBossPlayManager:DelayKick", "hasnt PlayerInfo[%d].", dbid)
        return
    end
    local eid = thePlayerData[public_config.PLAYER_INFO_INDEX_EID]
    local player = mogo.getEntity(eid)
    if not player then 
        log_game_warning("WorldBossPlayManager:DelayKick", "player[%d] is detroyed.", PlayerDbid)
        return 
    end
    player.base.MissionReq(action_config.MSG_GO_TO_INIT_MAP, 0, 0, "")
end

--活动结束由worldbossmgr调用
function WorldBossPlayManager:KickAllPlayer(SpaceLoader)
    log_game_debug("WorldBossPlayManager:KickAllPlayer", "")
    --标识活动时间结束
    if not self.isStart then
        log_game_error("WorldBossPlayManager:KickAllPlayer", "")
        return
    end
    self.isStart = false

    --如果有人先踢掉所有的玩家,然后在最后一个离开后回收
    for dbid, info in pairs(self.PlayerInfo) do
        log_game_debug("WorldBossPlayManager:KickAllPlayer", "dbid=%q;eid=%d", dbid, info[public_config.PLAYER_INFO_INDEX_EID])
        local player = mogo.getEntity(info[public_config.PLAYER_INFO_INDEX_EID])
        if player then
            --todo:通知每个玩家奖励获得 
            --player.base.TownPortal()
            self:SendReward(dbid, 1, true)
            self:AddLocalKickTimer(dbid, SpaceLoader)
            --活动时间到退出
            --player.base.MissionReq(mission_config.MSG_QUIT_MISSION, 0, 0, '')
            --player.base.MissionReq(mission_config.MSG_EXIT_MAP, 0, 0, '')
        end
    end
    self.CellInfo[mission_config.SPECIAL_MAP_INFO_MONSTER_AUTO_DIE] = 
        SpaceLoader:addTimer(g_GlobalParamsMgr:GetParams('monster_auto_die', 1), 0, public_config.TIMER_ID_MONSTER_DIE)
    --关卡成功后8秒钟，自动拾取，入背包
    --self.CellInfo[mission_config.SPECIAL_MAP_INFO_SUCCESS_TIMER_ID] = 
        --SpaceLoader:addTimer(g_GlobalParamsMgr:GetParams('mission_countdown', 8), 0, TIMER_ID_SUCCESS)
end

--掉落不自动捡,这个是关卡胜利TIMER_ID_SUCCESS对应的定时操作
function WorldBossPlayManager:AutoPickUpDrops(SpaceLoader)
    log_game_debug("WorldBossPlayManager:AutoPickUpDrops", "")
end

--TIMER_ID_MONSTER_DIE对应的定时操作
function WorldBossPlayManager:MonsterAutoDie(SpaceLoader)
    log_game_debug("WorldBossPlayManager:MonsterAutoDie", "")
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
            --如果怪物当前没有死，则全部设置成死亡
            monsterEntity:addHp(-monsterEntity.curHp)
        end
    end
    self.CellInfo[mission_config.SPECIAL_MAP_INFO_MONSTER_AUTO_DIE] = 0
    --如果没人了立即回收
    if lua_util.get_table_real_count(self.PlayerInfo) == 0 then
        self:Recover(SpaceLoader)
        return
    end
end

--todo:如果活动没结束先不关闭场景
function WorldBossPlayManager:Stop(SpaceLoader)
    log_game_debug("WorldBossPlayManager:Stop", "map_id=%s", SpaceLoader.map_id)
    if self.isStart then return end
    --todo:delete all timer
    if self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID] and
       self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID] > 0 then
        SpaceLoader:delTimer(self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID])
    end

    if self.CellInfo[mission_config.SPECIAL_MAP_INFO_MONSTER_AUTO_DIE] and
       self.CellInfo[mission_config.SPECIAL_MAP_INFO_MONSTER_AUTO_DIE] > 0 then
        SpaceLoader:delTimer(self.CellInfo[mission_config.SPECIAL_MAP_INFO_MONSTER_AUTO_DIE])
        --
        self:MonsterAutoDie(SpaceLoader)
    end

    --自动拾取一定距离内的掉落物
    --把奖励池的物品放入背包或者邮件
    for dbid, info in pairs(self.PlayerInfo) do
        log_game_debug("WorldBossPlayManager:Stop", "dbid=%q;eid=%d", dbid, info[public_config.PLAYER_INFO_INDEX_EID])
        local player = mogo.getEntity(info[public_config.PLAYER_INFO_INDEX_EID])
        if player then
            --这种情况只能是副本的定时到了，强制退出这个玩家,此时活动已经结束
            if not self.isStart then
                log_game_error("WorldBossPlayManager:Stop", "not start, but stop.")
            end
            self:SendReward(dbid, 0, false)
            player.base.MissionReq(action_config.MSG_GO_TO_INIT_MAP, 0, 0, "")
            --player.base.MissionReq(action_config.MSG_EXIT_MISSION, 0, 0, '')
            --player.base.MissionReq(mission_config.MSG_EXIT_MAP, 0, 0, '')
        end
    end

    --设置所有怪物
    g_SrvEntityMgr:StopAliveMonster(SpaceLoader)
    
    --延时重置,改由管理器统一去回收
    SpaceLoader:addLocalTimer("Reset", 30000, 1) --30s后
end

function WorldBossPlayManager:Reset(SpaceLoader)
    if self.isStart then return end --没开始不重置
    
    log_game_debug("WorldBossPlayManager:Reset", "map_id=%s", SpaceLoader.map_id)
    
    --当前场景玩家的列表,不清空
    --self.PlayerInfo = {} 

    self.CellInfo = {}    --清空副本信息

    self.Events = {}
    
    --
    self.isSetMission = false
    self.StartTime = 0

    self.boss = {} 

    self.CellInfo[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT] = {}               --初始化已触发的刷怪点
    self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_PROCESS] = {}                   --初始化副本进度
    self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID] = 0                       --副本结束的定时器ID
    self.CellInfo[mission_config.SPECIAL_MAP_INFO_SUCCESS_TIMER_ID] = 0                   --
    self.CellInfo[mission_config.SPECIAL_MAP_INFO_MONSTER_AUTO_DIE] = 0  

    self.ptr = nil

    SpaceLoader.base.Reset()
end

--活动结束前的退出
function WorldBossPlayManager:ExitMission(dbid)
    log_game_debug("WorldBossPlayManager:ExitMission", "")
    if self.PlayerInfo[dbid] then
        self:SendReward(dbid, 0, false)
        self:DelayKick(dbid)
        --[[改成立即退出
        self:SendReward(dbid, 0, true)
        self:AddLocalKickTimer(dbid, self.ptr.sp_ref)]]
    end
end

--活动结束后的退出
function WorldBossPlayManager:QuitMission(dbid)
    log_game_debug("WorldBossPlayManager:QuitMission", "")

    if self.PlayerInfo[dbid] and not self:IsSpaceLoaderSuccess() then
        local eid = self.PlayerInfo[dbid][public_config.PLAYER_INFO_INDEX_EID]
        local player = mogo.getEntity(eid)
        --player.base.client.ShowTextID(CHANNEL.TIPS, 818)
        mogo.EntityOwnclientRpc(player, "ShowTextID", CHANNEL.TIPS, 818)
    elseif self.PlayerInfo[dbid] then
        local eid = self.PlayerInfo[dbid][public_config.PLAYER_INFO_INDEX_EID]
        local player = mogo.getEntity(eid)
        player.base.MissionC2BReq(action_config.MSG_EXIT_MAP, 0, 0, '')
    end
end


--[[
*******************************************************************
--winj test
]]
----更新boss血量给boss血量管理中心
function WorldBossPlayManager:UpdateBossHp(dbid, damage)
    --log_game_debug("WorldBossPlayManager:UpdateBossHp", 'dbid(attacker): %s, damage:%s', tostring(dbid), tostring(damage) )
    local theInfo = self.PlayerInfo[dbid]
    if not theInfo then
        log_game_error("WorldBossPlayManager:UpdateBossHp", "")
        return
    end
    theInfo[public_config.PLAYER_INFO_INDEX_DAMEGE] = theInfo[public_config.PLAYER_INFO_INDEX_DAMEGE] + damage
    self.BaseWBMgrMb.UpdateBossHp(dbid, damage)

end
--[[
function WorldBossPlayManager:SynWorldBossHp(eid, hp)
    for k,v in pairs(self.boss) do
        if k == eid and self.boss[eid] then
            local boss = mogo.getEntity(eid)
            log_game_debug('SynWorldBossHp', 'eid[%d] hp [%d]', eid, hp)
            boss.setHp(hp)
        end
    end
end
]]
function WorldBossPlayManager:SetWorldBossMgr(wbMgrMbStr)
    log_game_debug("WorldBossPlayManager:SetWorldBossMgr", wbMgrMbStr)
    self.BaseWBMgrMb = mogo.UnpickleBaseMailbox(wbMgrMbStr)
end

function WorldBossPlayManager:RegisterBoss(mapId, cellStr, eid)
    log_game_debug("WorldBossPlayManager:RegisterBoss", "")
    self.BaseWBMgrMb.RegisterBoss(mapId, cellStr, eid)
    self.boss[eid] = true
end

function WorldBossPlayManager:UnregisterBoss(mapId, eid)
    log_game_debug("WorldBossPlayManager:UnregisterBoss","mapId[%s] UnregisterBoss", mapId)
    self.BaseWBMgrMb.UnregisterBoss(mapId, eid)
    self.boss[eid] = nil
end
--[[
function WorldBossPlayManager:PlayerLeave(mapId, dbid, level)
    log_game_debug("WorldBossPlayManager:PlayerLeave", "")
    self.BaseWBMgrMb.PlayerLeave(mapId, dbid, level)
end
]]
function WorldBossPlayManager:Summon(spawnId, mod, SpaceLoader)
    log_game_debug("WorldBossPlayManager:Summon", "")
    --todo:等待spawnpoint重构后再改
    if public_config.SUMMON_MOD_ALL_DEAD == mod then

    elseif public_config.SUMMON_MOD_NUM_LIMIT == mod then

    elseif public_config.SUMMON_MOD_KILL_LEFT == mod then

    end
    if lua_util.get_table_real_count(self.PlayerInfo) > 0 then
        self:SpawnPointEvent(mission_config.SPAWNPOINT_START, spawnId, SpaceLoader)
    end
end

function WorldBossPlayManager:DeathEvent(dbid, SpaceLoader)
    log_game_debug("WorldBossPlayManager:DeathEvent", "%d", dbid)
    local theInfo = self.PlayerInfo[dbid]
    if not theInfo then
        return
    end
    self:SendReward(dbid, 0, true)
    self:AddLocalKickTimer(dbid, SpaceLoader)
end

function WorldBossPlayManager:MonsterDeathEvent(killer_mb_str)
    self.BaseWBMgrMb.BossDie(killer_mb_str)
end

--[[
*******************************************************************
]]
return WorldBossPlayManager

