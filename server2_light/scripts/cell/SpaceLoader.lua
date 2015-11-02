

require "lua_util"
require "public_config"
require "error_code"
--require "mgr_map_cell"
require "mission_data"
require "event_config"
require "mission_config"
require "map_data"
require "tower_config"
require "monster_data"
require "state_config"

require "BasicPlayManager"
require "TowerPlayManager"
require "NormalPlayManager"
require "MultiPlayManager"
require "WorldBossPlayManager"
require "OblivionPlayManager"
require "ArenaPlayManager"
require "NewbiePlayManager"
require "TowerDefencePlayManager"
require "RandomPlayManager"
require "DragonPlayManager"
require "CliEntityManager"
require "DefensePvPManager"


local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error
local _splitStr = lua_util.split_str

--local TIMER_ID_END     = 1    --副本(关卡)结束的定时器
--local TIMER_ID_SUCCESS = 2    --副本(关卡)成功后的定时器
--local TIMER_ID_MONSTER_DIE = 3--副本(关卡)成功后演示若干秒怪物死亡
--local TIMER_ID_DESTROY = 4    --副本开始破坏
--local TIMER_ID_START   = 5    --副本开始前倒数
--local TIMER_ID_PREPARE_START = 6 --副本准备时间倒计时

SpaceLoader = {}
--SpaceLoader.__index = SpaceLoader

setmetatable(SpaceLoader, CellEntity)

----------------------------------------------------------------------------------------------------



function SpaceLoader:__ctor__()

    --实际上这步可有可无，因为引擎在创建space的时候，默认已经不把spaceloader放进去aoi管理器
    self:setVisiable(0)

    local SpaceId = self:getSpaceId()

    --把自己设为全局对象
    g_these_spaceloaders[SpaceId] = self

    --初始化自己的人数
    gSpaceLoadersPlayerCount[SpaceId] = 0

    self.cell_mbstr = mogo.pickleMailbox(self)

end

--加载本场景地图
function SpaceLoader:load_map()
    self.AliveMonster = {}

    self.CliEntityManager = CliEntityManager:new()
    --出生点初始化begin
    local src_map_id = g_map_mgr:GetSrcMapId(self.map_id)
    if src_map_id then
        local map_entity_cfg_data = g_map_mgr:GetMapEntityCfgData(src_map_id)
        if map_entity_cfg_data then
            for i, v in pairs(map_entity_cfg_data) do
                if v['type'] == 'SpawnPoint' then
                    local levelID = _splitStr(v['levelID'], ",", tonumber)

                    local tmpTblmonsterSpawntPoint = _splitStr(v['monsterSpawntPoint'], ',', tonumber)
                    local tmpTblmonsterDifficltCfg = {}

                    for _, v1 in pairs(levelID) do
                        local cfg = g_monster_mgr:getSpawnPointLevelCfgById(v1)
                        if cfg then
                            table.insert(tmpTblmonsterDifficltCfg, {
                                                                    ids = cfg['monsterId'],
                                                                    num = cfg['monsterNumber'],
                                                               })
                        end
                    end

                    local newSpawnPoint = self:GetIdleSpawnPointEntity(i, 
                                                                tmpTblmonsterSpawntPoint,
                                                                tmpTblmonsterDifficltCfg,
                                                                v['homerangeX'],
                                                                v['homerangeY'],
                                                                v['homerangeLength'],
                                                                v['homerangeWidth'],
                                                                v['triggerType'])--kevin v['triggerType']  0是踩点触发 1是一开始刷
                end
            end
        end
    end

end

function SpaceLoader:GetIdleSpawnPointEntity(cfgId, tmpTblmonsterSpawntPoint, tmpTblmonsterDifficltCfg, homerangeX, homerangeY, homerangeLength, homerangeWidth, triggerType)                   
     
    if triggerType == nil then--default
        triggerType = public_config.SPAWNPOINT_TRIGGER_TYPE_STEP
    end    

    local newSpawnPoint = self.CliEntityManager:entityFactory()               
                                                        
        newSpawnPoint.eid = self:getNextEntityId()                                            
        newSpawnPoint.enterX  = 0           
        newSpawnPoint.enterY  = 0                                 
        newSpawnPoint.cfgId   = cfgId
        newSpawnPoint.monsterSpawntPoint  = tmpTblmonsterSpawntPoint
        newSpawnPoint.monsterDifficltCfg  = tmpTblmonsterDifficltCfg
        newSpawnPoint.homerangeX  = homerangeX
        newSpawnPoint.homerangeY  = homerangeY
        newSpawnPoint.homerangeLength = homerangeLength
        newSpawnPoint.homerangeWidth  = homerangeWidth
        newSpawnPoint.triggerType = triggerType
                                 
                                                                                            
    self.CliEntityManager:addEntity(cli_entity_config.CLI_ENTITY_TYPE_SPAWNPOINT, newSpawnPoint) 
                                                                                            
    return newSpawnPoint                                                                          
end                                                                                         

function SpaceLoader:SetMapId(mbStr, sceneId, line, dbid, name, params)
    --初始化玩法逻辑

    local is_login_now = true

    if params['type'] then
        if params['type'] == public_config.MAP_TYPE_SLZT then
            self.PlayManager = TowerPlayManager.init()
        elseif params['type'] == public_config.MAP_TYPE_OBLIVION then
            self.PlayManager = OblivionPlayManager:init(self, line, sceneId)
            is_login_now     = false
        elseif params['type'] == public_config.MAP_TYPE_SPECIAL then
            self.PlayManager = BasicPlayManager.init()
        elseif params['type'] == public_config.MAP_TYPE_MUTI_PLAYER_NOT_TEAM then
            self.PlayManager = MultiPlayManager.init()
        elseif params['type'] == public_config.MAP_TYPE_WB then
            self.PlayManager = WorldBossPlayManager:init(self, sceneId)
        elseif params['type'] == public_config.MAP_TYPE_ARENA then
            self.PlayManager = ArenaPlayManager:init(self, params)
        elseif params['type'] == public_config.MAP_TYPE_NEWBIE then
            self.PlayManager = NewbiePlayManager.init()
        elseif params['type'] == public_config.MAP_TYPE_TOWER_DEFENCE then
            self.PlayManager = TowerDefencePlayManager:init(self)
        elseif params['type'] == public_config.MAP_TYPE_DRAGON then
            self.PlayManager = DragonPlayManager:init(self, params)
        elseif params['type'] == public_config.MAP_TYPE_RANDOM then
            self.PlayManager = RandomPlayManager.init()
        elseif params['type'] == public_config.MAP_TYPE_DEFENSE_PVP then
            self.PlayManager = DefensePvPManager:init(self, line, sceneId)
            is_login_now     = false
        elseif params['type'] == public_config.MAP_TYPE_MWSY then
            self.PlayManager = BasicPlayManager.init()
        else
            self.PlayManager = NormalPlayManager.init()
        end
        --设置它的地图类型
        self.MapType = params['type']
    else
        local src_map_id   = g_map_mgr:GetSrcMapId(sceneId)
        local cfg = g_map_mgr:getMapCfgData(src_map_id)
        if cfg then
            if cfg['type'] == public_config.MAP_TYPE_SLZT then
                self.PlayManager = TowerPlayManager.init()
            elseif cfg['type'] == public_config.MAP_TYPE_OBLIVION then
                self.PlayManager = OblivionPlayManager:init(self, line, sceneId)
                is_login_now     = false
            elseif cfg['type'] == public_config.MAP_TYPE_SPECIAL then
                self.PlayManager = BasicPlayManager.init()
            elseif cfg['type'] == public_config.MAP_TYPE_MUTI_PLAYER_NOT_TEAM then
                self.PlayManager = MultiPlayManager.init()
            elseif cfg['type'] == public_config.MAP_TYPE_WB then
                self.PlayManager = WorldBossPlayManager:init(self, sceneId)
            elseif cfg['type'] == public_config.MAP_TYPE_ARENA then
                self.PlayManager = ArenaPlayManager:init(self, params)
            elseif cfg['type'] == public_config.MAP_TYPE_NEWBIE then
                self.PlayManager = NewbiePlayManager.init()
            elseif cfg['type'] == public_config.MAP_TYPE_TOWER_DEFENCE then
                self.PlayManager = TowerDefencePlayManager:init(self)
            elseif cfg['type'] == public_config.MAP_TYPE_DRAGON then
                self.PlayManager = DragonPlayManager:init(self, params)
            elseif cfg['type'] == public_config.MAP_TYPE_RANDOM then
                self.PlayManager = RandomPlayManager.init()
            elseif cfg['type'] == public_config.MAP_TYPE_DEFENSE_PVP then
                self.PlayManager = DefensePvPManager:init(self, line, sceneId)
                is_login_now     = false
            elseif cfg['type'] == public_config.MAP_TYPE_MWSY then
                self.PlayManager = BasicPlayManager.init()
            else
                self.PlayManager = NormalPlayManager.init()
            end
            --设置它的地图类型
            self.MapType = cfg['type']
        end
    end

    if is_login_now == true then
        local mb = mogo.UnpickleBaseMailbox(mbStr)
        if mb then
            log_game_debug("SpaceLoader:SetMapId", "sceneId=%d;line=%d;dbid=%q;name=%s;params=%s", sceneId, line, dbid, name, mogo.cPickle(params))
            mb.SelectMapResp(sceneId, line, self.base, mogo.UnpickleCellMailbox(self.cell_mbstr), dbid, params)
        end
    end

    self:load_map()
end

function SpaceLoader:OnLocalTimer(timer_id, active_count, ...)
    if self.PlayManager then
        self.PlayManager:OnLocalTimer(timer_id, active_count, ...)
    end
end

function SpaceLoader:onTimer(timer_id, user_data)
--    mpins_mgr:onTimer(self)

--    if user_data == TIMER_ID_END then
--        log_game_info("SpaceLoader:onTimer", "Stop user_data=%d", user_data)
--        --self.PlayManager:Recover(self)
--        self:Stop()
--    elseif user_data == TIMER_ID_SUCCESS then
--        if self.PlayManager then
--            self.PlayManager:AutoPickUpDrops(self)
--        end
--    elseif user_data == TIMER_ID_MONSTER_DIE then
--        if self.PlayManager then
--            self.PlayManager:MonsterAutoDie(self)
--        end
--    elseif user_data == TIMER_ID_DESTROY then
--        if self.PlayManager then
--            self.PlayManager:SpaceDestroy(self)
--        end
--    elseif user_data == TIMER_ID_START then
--        if self.PlayManager then
--            self.PlayManager:Start(self)
--        end
--    elseif user_data == TIMER_ID_PREPARE_START then
--        if self.PlayManager then
--            self.PlayManager:PrepareStart(self)
--        end
--    else
        if self.PlayManager then
            self.PlayManager:onTimer(self, timer_id, user_data)
        end
--    end

end


--玩家进入场景
function SpaceLoader:OnAvatarCtor(avatar)

    --如果有玩家进入该场景时发现尚未激活，则激活该场景
    if self.IsActived == 0 then
        if self:active() then
            log_game_debug("SpaceLoader:OnAvatarCtor Active", "dbid=%q;name=%s", avatar.dbid, avatar.name)
            self.IsActived = 1
        end
    end

    if self.PlayManager then
        self.PlayManager:OnAvatarCtor(avatar, self)
    end

    --进副本时重置血瓶
    avatar:ResetHpCount()

    --玩家进入场景，则累加人数
    gSpaceLoadersPlayerCount[self:getSpaceId()] = gSpaceLoadersPlayerCount[self:getSpaceId()] + 1

    --通知副本管理器减少人数
    self.base.ChangeMapCount(public_config.CHANGE_MAP_COUNT_ADD, 1)

    --todo:PlayManager里人数超过时驳回

--    --玩家进入副本的时候重置血量
--    if avatar.hp then
--        avatar:addHp(avatar.hp)
--        avatar.base.UnsetStateToBase(state_config.DEATH_STATE)
--        log_game_debug("SpaceLoader:OnAvatarCtor addHp", "dbid=%q;name=%s;hp=%s;avatar.hp=%d;avatar.curHp=%d",
--                                                          avatar.dbid, avatar.name, avatar.battleProps.hp, avatar.hp, avatar.curHp)
--    else
--        log_game_error("SpaceLoader:OnAvatarCtor", "dbid=%q;name=%s;hp=%s",
--                                                    avatar.dbid, avatar.name, avatar.battleProps.hp)
--    end

    --进入场景的时候，把场景的basemb传给角色
    --add by winj,查找用于查找bug
    log_game_debug("SpaceLoader:OnAvatarCtor", "SetSpaceLoaderMb map_type[%d], self.base[%s]", self.MapType, mogo.cPickle(self.base))
--    avatar.base.SetSpaceLoaderMb(mogo.cPickle(self.base))

--    local scene_line = lua_util.split_str(self.map_id, "_", tonumber)
--
--    log_game_debug("SpaceLoader:OnAvatarCtor", "eid=%d;sceneId=%d;imap_id=%d",
--                                                  avatar:getId(), scene_line[1], scene_line[2])


end

--玩家离开场景
function SpaceLoader:OnAvatarDctor(avatar)

    log_game_debug("SpaceLoader:OnAvatarDctor", "eid=%d", avatar:getId())

    if avatar.mercenaryId and avatar.mercenaryId > 0 then
        local Mercenary = mogo.getEntity(avatar.mercenaryId)
        if Mercenary then
            log_game_debug("SpaceLoader:OnAvatarDctor", "eid=%d;Mercenary.OwnerId=%d", avatar:getId(), Mercenary.OwnerId)
            Mercenary.OwnerId = 0
            Mercenary:setVisiable(0)
        end
    end

    if self.PlayManager then
        self.PlayManager:OnAvatarDctor(avatar, self)
    end

    --玩家离开场景，则减少人数
    local SpaceId = self:getSpaceId()
    gSpaceLoadersPlayerCount[SpaceId] = gSpaceLoadersPlayerCount[SpaceId] - 1

    --通知副本管理器减少人数
    self.base.ChangeMapCount(public_config.CHANGE_MAP_COUNT_SUB, 1)

    --玩家离开场景的时候重置血量
    if avatar.hp then
        avatar:addHp(avatar.hp)
        avatar.base.UnsetStateToBase(state_config.DEATH_STATE)
--        log_game_debug("SpaceLoader:OnAvatarDctor addHp", "dbid=%q;name=%s;hp=%s;avatar.hp=%d;avatar.curHp=%d", avatar.dbid, avatar.name, avatar.battleProps.hp, avatar.hp, avatar.curHp)
    else
        log_game_error("SpaceLoader:OnAvatarDctor", "dbid=%q;name=%s;hp=%s", avatar.dbid, avatar.name, avatar.battleProps.hp)
    end

    --离开副本时重置血瓶
    avatar:ResetHpCount()

    log_game_debug("SpaceLoader:OnAvatarDctor", "self.MapType=%d;gSpaceLoadersPlayerCount[SpaceId]=%d", self.MapType, gSpaceLoadersPlayerCount[SpaceId])

    --世界boss地图在活动结束后统一停止、重置
    if public_config.MAP_TYPE_WB == self.MapType then
        --离开处理
        log_game_debug("SpaceLoader:OnAvatarDctor", "PlayerLeave[%q]", avatar.dbid)
        self.base.PlayerLeave(avatar.dbid)
    end

    if gSpaceLoadersPlayerCount[SpaceId] <= 0 then
        if self.PlayManager then
            --当副本内没有玩家时，则停止副本
            self.PlayManager:Recover(self)
        end

        if self:inActive() then
            log_game_debug("SpaceLoader:OnAvatarDctor inActive", "dbid=%q;name=%s", avatar.dbid, avatar.name)
            self.IsActived = 0
        end
    end
end

function SpaceLoader:InitData(params_tab)
    if self.PlayManager then
        self.PlayManager:InitData(params_tab[1], params_tab[2], params_tab[3], params_tab[4])
    end
end

function SpaceLoader:Start(StartTime)
--    log_game_debug("SpaceLoader:Start", "map_id=%s;SpaceId=%d", self.map_id, self:getSpaceId())
    if self.PlayManager then
        self.PlayManager:Start(self, StartTime)
    else
        log_game_error("SpaceLoader:Start", "map_id=%s;SpaceId=%d", self.map_id, self:getSpaceId())
    end
end

function SpaceLoader:onClientDeath(PlayerDbid)
--    log_game_debug("SpaceLoader:onClientDeath", "map_id=%s;Playerdbid=%q;SpaceId=%d", self.map_id, PlayerDbid, self:getSpaceId())
    if self.PlayManager then
        self.PlayManager:onClientDeath(PlayerDbid, self)
    else
        log_game_error("SpaceLoader:onClientDeath", "map_id=%s;Playerdbid=%q;SpaceId=%d", self.map_id, PlayerDbid, self:getSpaceId())
    end
end

function SpaceLoader:Stop()
--    log_game_debug("SpaceLoader:Stop", "map_id=%s;SpaceId=%d", self.map_id, self:getSpaceId())
    if self.PlayManager then
        self.PlayManager:Stop(self)
    else
        log_game_error("SpaceLoader:Stop", "map_id=%s;SpaceId=%d", self.map_id, self:getSpaceId())
    end
end

function SpaceLoader:Reset()
--    log_game_debug("SpaceLoader:Reset", "map_id=%s;SpaceId=%d", self.map_id, self:getSpaceId())
    if self.PlayManager then
        self.PlayManager:Reset(self)
        self.PlayManager = nil
        self.CliEntityManager = nil
        self.AliveMonster = nil
        self.MapType = 0
    else
        log_game_error("SpaceLoader:Reset", "map_id=%s;SpaceId=%d", self.map_id, self:getSpaceId())
    end
end

function SpaceLoader:NotifySpaceLoaderDeath(MonsterId)

    log_game_debug("SpaceLoader:NotifySpaceLoaderDeath", "map_id=%s;MonsterId=%d", self.map_id, MonsterId)

end

--function SpaceLoader:MonsterThink(tblSpawnPointCfgId, event)
function SpaceLoader:MonsterThink(event)
    --[[
    if #tblSpawnPointCfgId <= 0 then
        return
    end
    --]]
    if not self.AliveMonster then
        return
    end
    --服务器怪物
    for eid,v in pairs(self.AliveMonster) do
        local monsterEntity = mogo.getEntity(eid)
        if monsterEntity ~= nil and monsterEntity.c_etype == public_config.ENTITY_TYPE_MONSTER and monsterEntity.curHp > 0 then 
            monsterEntity:Think(event)
        elseif monsterEntity ~= nil and monsterEntity.factionFlag > 0 and 
            monsterEntity.c_etype == public_config.ENTITY_TYPE_MERCENARY then
            --是真雇佣兵,和主人一起死亡,和主人一起复活
            if event == Mogo.AI.AIEvent.AvatarDie then
                monsterEntity:OwnerDie()
            elseif event == Mogo.AI.AIEvent.AvatarRevive then
                monsterEntity:OwnerRevive()
            end
        end
        
    end
end

function SpaceLoader:TestSpawnPointMonsterDie(spawnPointCfgId)
    --服务器怪物
    log_game_debug("SpaceLoader:TestSpawnPointMonsterDie", "spawnPointCfgId=%d;self.AliveMonster=%s",
                                                            spawnPointCfgId, mogo.cPickle(self.AliveMonster))
    for eid, v in pairs(self.AliveMonster) do
        local monsterEntity = mogo.getEntity(eid)
        if monsterEntity ~= nil and monsterEntity.spawnPointCfgId == spawnPointCfgId and monsterEntity.curHp > 0 and monsterEntity.factionFlag == 0 then
            return false
        end
    end
    --客户端怪物
    local isAllCliDie = self.CliEntityManager:isEntityAllDie(cli_entity_config.CLI_ENTITY_TYPE_DUMMY, spawnPointCfgId)
    if isAllCliDie == false then
        return false
    end

    --通知出生点怪物死光
    self:OnSpawnPointMonsterDeath(spawnPointCfgId)
    return true
end

function SpaceLoader:OnSpawnPointMonsterDeath(SpawnPointId)

    log_game_debug("SpaceLoader:OnSpawnPointMonsterDeath", "map_id=%s;SpawnPointId=%d",
                                                           self.map_id, SpawnPointId)

    if self.PlayManager then
        self.PlayManager:OnSpawnPointMonsterDeath(self, SpawnPointId)
    end
end

function SpaceLoader:SetCellInfo(playerDbid, playerName, playerMbStr, missionId, difficult)

--    log_game_debug("SpaceLoader:SetCellInfo", "map_id=%s", self.map_id)

    if self.PlayManager then
        self.PlayManager:SetCellInfo(playerDbid, playerName, playerMbStr, missionId, difficult, self)
    end

    if self.PlayManager and self.PlayManager.PrepareEntities then
        self.PlayManager:PrepareEntities(self, difficult)
    end
end

function SpaceLoader:Restart(playerDbid, playerName, playerMbStr, missionId, difficult)

    log_game_debug("SpaceLoader:Restart", "map_id=%s;dbid=%q;name=%s;mb=%s;missionId=%d;difficult=%d", self.map_id, playerDbid, playerName, playerMbStr, missionId, difficult)

end

function SpaceLoader:SpawnPointEvent(EventId, dbid, avatar_x, avatar_y, SpawnPointId)

    log_game_debug("SpaceLoader:SpawnPointEvent", "map_id=%s;EventId=%d;dbid=%d;avatar_x=%d;avatar_y=%d;SpawnPointId=%d", self.map_id, EventId, dbid, avatar_x, avatar_y, SpawnPointId)

    if self.PlayManager then
        self.PlayManager:SpawnPointEvent(EventId, dbid, SpawnPointId, self)
    end
end

--玩家获得经验以后调用该接口，把物品放入奖励池
function SpaceLoader:AddExp(playerDbid, count)
    if self.PlayManager then
        self.PlayManager:AddExp(playerDbid, count)
    end
end


--玩家拾取金钱以后调用该接口，把物品放入奖励池
function SpaceLoader:AddMoney(playerDbid, count)
    if self.PlayManager then
        self.PlayManager:AddMoney(playerDbid, count)
    end
end

function SpaceLoader:MonsterHpChange(attacker, monster, hp_change)
    if self.PlayManager then
        self.PlayManager:MonsterHpChange(attacker, monster, hp_change)
    end
end

function SpaceLoader:DoDamageAction(attacker, defender, harm)
    if self.PlayManager then
        self.PlayManager:DoDamageAction(attacker, defender, harm)
    end
end

function SpaceLoader:AddDamage(attacker, harm)
    if self.PlayManager then
        self.PlayManager:AddDamage(attacker, harm)
    end
end

--玩家拾取道具以后调用该接口，把物品放入奖励池
function SpaceLoader:AddRewards(playerDbid, item_id, count)
    if self.PlayManager then
        self.PlayManager:AddRewards(playerDbid, item_id, count)
    end
end

function SpaceLoader:GetMissionRewards(PlayerDbid)
--    log_game_debug("SpaceLoader:GetMissionRewards", "map_id=%s;Playerdbid=%q", self.map_id, PlayerDbid)

    if self.PlayManager then
        self.PlayManager:GetMissionRewards(PlayerDbid)
    end

end


function SpaceLoader:GetPlayInfo()
--    log_game_debug("SpaceLoader:GetPlayInfo", "result=%s", mogo.cPickle(self.PlayManager.PlayerInfo))
    if self.PlayManager == nil then
        return nil
    end
    return self.PlayManager.PlayerInfo
end

function SpaceLoader:SyncCliEntityInfo()
    local sendBuf = {}
    local src_map_id = g_map_mgr:GetSrcMapId(self.map_id)
    --客户端实体
    self.CliEntityManager:pickleEntityBuf(sendBuf, cli_entity_config.CLI_ENTITY_TYPE_DUMMY)
    self.CliEntityManager:pickleEntityBuf(sendBuf, cli_entity_config.CLI_ENTITY_TYPE_DROP)

    local count = #sendBuf
    if count > 0 then
        local tblEntitiesAvatar = self.PlayManager.PlayerInfo
        for dbid, tblAvatar in pairs(tblEntitiesAvatar) do
            local avatar = mogo.getEntity(tblAvatar[public_config.PLAYER_INFO_INDEX_EID])
            if avatar then
                avatar:CreateCliEntityResp(sendBuf)
            end
        end
    end
end

function SpaceLoader:SyncCliEntityHpResp(cliEntityEid, hp)

    local sendBuf = {cliEntityEid, hp}

    local tblEntitiesAvatar = self.PlayManager.PlayerInfo                            
    for dbid, tblAvatar in pairs(tblEntitiesAvatar) do                               
        local avatar = mogo.getEntity(tblAvatar[public_config.PLAYER_INFO_INDEX_EID])
        if avatar then
            avatar:SyncCliEntityHpResp(sendBuf)
        end
    end
end

--设置boss血量管理中心mailbox
function SpaceLoader:SetWorldBossMgr(mbStr)
    if self.PlayManager then
        self.PlayManager:SetWorldBossMgr(mbStr)
    end
end

--更新boss血量给boss血量管理中心
function SpaceLoader:SynWorldBossHp(eid, bossCurHp)
    --self.PlayManager:SynWorldBossHp(bossCurHp)
    --log_game_debug("SpaceLoader:SynWorldBossHp", "eid[%d], bossCurHp[%d]", eid, bossCurHp)
    local boss = mogo.getEntity(eid)
    if boss ~= nil then
        --log_game_debug("SpaceLoader:SynWorldBossHp", "succeed.")
        boss:setHp(bossCurHp)
    end
end
--
function SpaceLoader:UpdateBossHp(attackerDbid, harm)
    if self.PlayManager then
        self.PlayManager:UpdateBossHp(attackerDbid, harm)
    end
end

function SpaceLoader:Summon(spawnId, mod)
    if self.PlayManager then
        self.PlayManager:Summon(spawnId, mod, self)
    end
end

function SpaceLoader:CliEntityActionReq(eid, actionId, avatar, tblParam)
    self.CliEntityManager:ProcessEntityAction(self, eid, actionId, avatar, tblParam)
end

function SpaceLoader:ProcessCliEntityTypeDel(cliEntityType)
    self.CliEntityManager:ProcessCliEntityTypeDel(cliEntityType)
end

function SpaceLoader:ExitMission(dbid)
    if self.PlayManager then
        self.PlayManager:ExitMission(dbid)
    end
end

function SpaceLoader:QuitMission(dbid)
    if self.PlayManager then
        self.PlayManager:QuitMission(dbid)
    end
end

function SpaceLoader:AddFriendDegree(selfDbid, mercenaryDbid)
    if self.PlayManager then
        self.PlayManager:AddFriendDegree(selfDbid, mercenaryDbid)
    end
end

function SpaceLoader:LetSpawnPointStart(spawnPointId)
    if self.CliEntityManager == nil then
        return
    end

    local dummyCount = self.CliEntityManager:GetDummyCount()
    if dummyCount >= 6 then
        return
    end

    local scene_line = lua_util.split_str(self.map_id, "_", tonumber)
    if  scene_line[1] == g_GlobalParamsMgr:GetParams('init_scene', 10004) then
        return
    end
 
    local spwanPoints = self.CliEntityManager:getEntityByType(cli_entity_config.CLI_ENTITY_TYPE_SPAWNPOINT)
    if spwanPoints then 
        for _, spawnPointEntity in pairs(spwanPoints) do
            if spawnPointEntity.cfgId == spawnPointId then
                --SpawnPoint:Start({spawnPointData = spawnPointEntity, isAlone=1, avgLv=1, difficulty = self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT]}, self)
                SpawnPoint:Start({spawnPointData = spawnPointEntity, 
                                difficulty = 1,
                                triggerType = public_config.SPAWNPOINT_TRIGGER_TYPE_STEP}, self)
                self:SyncCliEntityInfo() 
                break
            end
        end
    end
end

function SpaceLoader:KickAllPlayer()
    if self.PlayManager then
        self.PlayManager:KickAllPlayer(self)
    end
end

function SpaceLoader:InsertAliveMonster(eid)
    self.AliveMonster[eid] = 1
end

function SpaceLoader:RemoveAliveMonster(eid)
    self.AliveMonster[eid] = nil
end

function SpaceLoader:NextFactionFlag()
    if true then return 1 end
    
    local faction = self.factionCounter
    faction = faction + 1
    self.factionCounter = faction
    return faction
end

--avatar战斗死亡事件
function SpaceLoader:DeathEvent(dbid)
    if self.PlayManager then
        self.PlayManager:DeathEvent(dbid, self)
    end
end

function SpaceLoader:MonsterDeathEvent(killer_mb_str)
    if self.PlayManager then
        self.PlayManager:MonsterDeathEvent(killer_mb_str)
    end
end

function SpaceLoader:Revive(PlayerDbid)
    if self.PlayManager then
        self.PlayManager:Revive(PlayerDbid, self)
    end
end

--延时踢掉某个玩家
function SpaceLoader:DelayKick(timerId, count, dbid, arg2)
    if self.PlayManager.DelayKick then
        self.PlayManager:DelayKick(dbid)
    end 
end

function SpaceLoader:ProcessWaguanDie(monsterId, x, y)
    log_game_debug("SpaceLoader:ProcessWaguanDie", "monsterId=%d;x=%d;y=%d", monsterId, x, y)
    self.CliEntityManager:ProcessJugDie(self, monsterId, x, y)	
end

function SpaceLoader:PrepareEntities(difficulty, monsterDifficulty)
    
    local spwanPoints = self.CliEntityManager:getEntityByType(cli_entity_config.CLI_ENTITY_TYPE_SPAWNPOINT)
    if spwanPoints then
        for _, spawnPointEntity in pairs(spwanPoints) do
            local rntStartedMonsterIds = nil
            if monsterDifficulty == nil then
                rntStartedMonsterIds = SpawnPoint:Start({spawnPointData = spawnPointEntity,
                                        difficulty = difficulty, 
                                        triggerType = public_config.SPAWNPOINT_TRIGGER_TYPE_BEGIN},
                                        self)
            else 
                rntStartedMonsterIds = SpawnPoint:Start({spawnPointData = spawnPointEntity,
                                        difficulty = difficulty, 
                                        triggerType = public_config.SPAWNPOINT_TRIGGER_TYPE_BEGIN},
                                        self,
                                        monsterDifficulty)
            end
            if rntStartedMonsterIds ~= nil then
                --self.CellInfo[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT][spawnPointEntity.cfgId] = true
            end
        end
    end
    self:SyncCliEntityInfo()
end

function SpaceLoader:PrepareEntities2(difficulty, trigger_type)
    local spwanPoints = self.CliEntityManager:getEntityByType(cli_entity_config.CLI_ENTITY_TYPE_SPAWNPOINT)
    if spwanPoints then
        for _, spawnPointEntity in pairs(spwanPoints) do
            local rntStartedMonsterIds = SpawnPoint:Start({spawnPointData = spawnPointEntity,
                                    difficulty = difficulty, 
                                    triggerType = trigger_type},
                                    self)
            if rntStartedMonsterIds ~= nil then
                --self.CellInfo[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT][spawnPointEntity.cfgId] = true
            end
        end
    end
    self:SyncCliEntityInfo()
end

return SpaceLoader


