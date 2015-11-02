
require "BasicPlayManager"
require "map_data"
require "lua_util"
require "lua_map"
require "reason_def"
require "public_config"
require "channel_config"
require "action_config"
require "drop_data"
require "action_config"

local log_game_debug    = lua_util.log_game_debug
local log_game_info     = lua_util.log_game_info
local log_game_warning  = lua_util.log_game_warning
local _readXml          = lua_util._readXml
local confirm           = lua_util.confirm


local CLOSED_TICK       = public_config.OBLIVION_CLOSED_TIME


local TEXT_BOLIVION_VICTORY = 1006001   --胜利通关！地图将会在20秒后关闭...
local TEXT_BOLIVION_DEFEAT  = 1006002   --超时失败！地图将会在20秒后关闭...


local reward_attr_data  = {}


OblivionPlayManager     = BasicPlayManager.init()


function OblivionPlayManager:InitRewardData()
    reward_attr_data = _readXml('/data/xml/Reward_OblivionAttr.xml', 'id_i')
    if reward_attr_data then
        for k, reward_attr in pairs(reward_attr_data) do
            if not reward_attr.exp1 then reward_attr.exp1 = 0 end
            if not reward_attr.exp2 then reward_attr.exp2 = 0 end
            if not reward_attr.money1 then reward_attr.money1 = 0 end
            if not reward_attr.money2 then reward_attr.money2 = 0 end
            if not reward_attr.goldLimit then reward_attr.goldLimit = 0 end

            reward_attr.exp     = {[1] = reward_attr.exp1, [2] = reward_attr.exp2}
            reward_attr.money   = {[1] = reward_attr.money1, [2] = reward_attr.money2}
        end
    else
        reward_attr_data = {}
    end
    self:CheckData()
end

function OblivionPlayManager:CheckData()
    for i = 1, 100 do
        if not reward_attr_data[i] then
            reward_attr_data[i]         = {exp1 = 0, exp2 = 0, money1 = 0, money2 = 0}
            reward_attr_data[i].exp     = {[1] = 0, [2] = 0}
            reward_attr_data[i].money   = {[1] = 0, [2] = 0}
        end
    end
end

function OblivionPlayManager:init(space_loader, gate_id, map_id)
    log_game_debug("OblivionPlayManager:init", "")

    local newObj = {}
    newObj.ptr   = {}
    setmetatable(newObj, 		{__index = OblivionPlayManager})
    setmetatable(newObj.ptr,    {__mode = "v"})

    newObj.ptr.theSpaceLoader = space_loader

    newObj.gateID           = gate_id

    --湮灭之门模式（1恶魔，2邪神）
    newObj.gateMode         = public_config.OBLIVION_MAP_TO_GATE[map_id]
    confirm(newObj.gateMode == 1 or newObj.gateMode == 2, "非法的湮灭之门模式（限1恶魔，2邪神），当前模式：%s", newObj.gateMode)

    --玩家等级
    newObj.ownerLevel       = 1

    --是否已经刷过BOSS
    newObj.hasBoss          = false

    --刷出的BOSS_CfgID
    newObj.bossID           = nil

    --刷怪点ID
    newObj.spawnPointCfgID  = 0

    --击杀者Dbid
    newObj.killerDbid       = 0

    --怪物剩余血量的百分比，浮点数[0, 1]
    newObj.bossProgress     = 1

    --指向OblivionGateMgr的MailBox
    newObj.oblivionMB       = nil

    --副本内玩家的信息
    newObj.playerData       = lua_map:new()

    --攻击并产生伤害者的信息（包括已经离开副本的玩家）
    newObj.attackerData     = lua_map:new()

    --创建时间
    newObj.createTime       = os.time()

    --定时器ID
    newObj.timerID          = 0

    --玩家信息，接口层跳线（外部需要本类提供此数据接口）
    newObj.PlayerInfo = {}

    return newObj
end

function OblivionPlayManager:InitData(oblivion_mb_str, owner_level)
    self.ownerLevel    = owner_level
    self.oblivionMB    = mogo.UnpickleBaseMailbox(oblivion_mb_str)
    confirm(self.oblivionMB ~= nil, "未能设置base上OblivionGateMgr的MailBox")

    self.timerID = self.ptr.theSpaceLoader:addLocalTimer("OnLocalTimer", 60 * 1000, 0)
end

function OblivionPlayManager:SpawnBoss()
	local spaceLoader = self.ptr.theSpaceLoader
    local spwanPoints = spaceLoader.CliEntityManager:getEntityByType(cli_entity_config.CLI_ENTITY_TYPE_SPAWNPOINT)
    if spwanPoints then 
        for id, spawnPointEntity in pairs(spwanPoints) do
            local tabIDs = SpawnPoint:Start({spawnPointData = spawnPointEntity, 
                                        difficulty = self.ownerLevel,
                                        triggerType = public_config.SPAWNPOINT_TRIGGER_TYPE_STEP}, 
                                        spaceLoader)
            self.bossID  = tabIDs[1]
            self.spawnPointCfgID = spawnPointEntity.cfgId
            break
        end
    end

    confirm(self.spawnPointCfgID ~= 0, "未定义刷怪区，玩家等级[%s]", self.ownerLevel)
end

function OblivionPlayManager:Start(space_loader, start_time)
	if self.hasBoss == false then
		--主动刷怪
		self:SpawnBoss()
		self.hasBoss = true
	end
end

function OblivionPlayManager:Recover(space_loader)
    --只Stop不Reset重置
    --不做任何操作
    --space_loader:Stop()
end

function OblivionPlayManager:Stop(space_loader)
    for avatarDbid, _ in pairs(self.playerData) do
        self:ExitMission(avatarDbid)
    end
end

function OblivionPlayManager:Reset(space_loader)
    for avatarDbid, _ in pairs(self.playerData) do
        self:ExitMission(avatarDbid)
    end
    space_loader.base.Reset()
end

function OblivionPlayManager:Victory(avatar_obj)
    self.killerDbid = avatar_obj.dbid
    self:AvatarCall(nil, "ShowTextID", CHANNEL.DBG, TEXT_BOLIVION_VICTORY)

    --发放属性奖励给所有玩家
    self:SendAttrAwardAll()

    local spaceLoader = self.ptr.theSpaceLoader

    --设置所有怪物自动死亡
    self:MonsterAutoDie(spaceLoader)

    --设置所有怪物
    g_SrvEntityMgr:StopAliveMonster(spaceLoader)

    --关闭湮灭之门
    self.oblivionMB.MgrEventDispatch("", "EventCloseGate", {self.gateID, self.killerDbid, self.attackerData, self.bossID}, "", "", {})
    
    --关闭计时器
    if self.timerID ~= 0 then
        self.ptr.theSpaceLoader:delLocalTimer(self.timerID)
        self.timerID = 0
    end

    --延时重置
    spaceLoader:addLocalTimer("Stop", 20000, 1) --20s后
    spaceLoader:addLocalTimer("Reset", 30000, 1) --30s后
end

function OblivionPlayManager:Defeat()
    self:AvatarCall(nil, "ShowTextID", CHANNEL.DBG, TEXT_BOLIVION_DEFEAT)

    --发放属性奖励给所有玩家
    self:SendAttrAwardAll()

    local spaceLoader = self.ptr.theSpaceLoader

    --设置所有怪物自动死亡
    self:MonsterAutoDie(spaceLoader)

    --设置所有怪物
    g_SrvEntityMgr:StopAliveMonster(spaceLoader)

    --关闭湮灭之门
    self.oblivionMB.MgrEventDispatch("", "EventCloseGate", {self.gateID, 0, {}}, "", "", {})
    
    --关闭计时器
    if self.timerID ~= 0 then
        self.ptr.theSpaceLoader:delLocalTimer(self.timerID)
        self.timerID = 0
    end

    --延时重置
    spaceLoader:addLocalTimer("Stop", 20000, 1) --20s后
    spaceLoader:addLocalTimer("Reset", 30000, 1) --30s后    
end

function OblivionPlayManager:OnSpawnPointMonsterDeath(space_loader, spawn_point_cfg_id)
    if spawn_point_cfg_id ~= self.spawnPointCfgID then return end
    if self.killerDbid == 0 then return end

    --不在此处理胜利
    --self:Victory()
end

function OblivionPlayManager:DeathEvent(avatar_dbid)
    --发放属性奖励
    self:SendAttrAward(avatar_dbid, true)
end

---------------------------------------------------------

function OblivionPlayManager:GetAwardExp(avatar_level, damage)
    if not avatar_level or not damage then return 0 end
    return math.ceil(damage * reward_attr_data[avatar_level].exp[self.gateMode] / 10000)
end

function OblivionPlayManager:GetAwardMoney(avatar_level, damage)
    if not avatar_level or not damage then return 0 end
    return math.ceil(damage * reward_attr_data[avatar_level].money[self.gateMode] / 10000)
end

function OblivionPlayManager:GetPlayerData(avatar_dbid)
    if not self.playerData then return nil end
    return self.playerData:find(avatar_dbid)
end

function OblivionPlayManager:GetAvatarObj(avatar_dbid)
    local playerData = self:GetPlayerData(avatar_dbid)
    if not playerData then return nil end

    local avatarObj = mogo.getEntity(playerData.avatarEid)
    return avatarObj
end

--调用当前副本里的cell上所有玩家的对象接口
function OblivionPlayManager:AvatarCall(sub_system_name, member_func_name, ...)
    if not member_func_name or member_func_name == "" then return end

    for _, playerData in pairs(self.playerData) do
        local avatarObj = mogo.getEntity(playerData.avatarEid)
        if avatarObj then
            local theSelf = nil
            local theFunc = nil
            if not sub_system_name or sub_system_name == "" or  sub_system_name == "Avatar" then
                theSelf = avatarObj
                theFunc = avatarObj[member_func_name]
            elseif sub_system_name == "client" then
                theSelf = nil
                theFunc = avatarObj.base.client[member_func_name]
            else
                theSelf = avatarObj[sub_system_name]
                theFunc = theSelf[member_func_name]
            end

            if theFunc then
                if theSelf then
                    theFunc(theSelf, ...)
                else
                    theFunc(...)
                end
            end
        end
    end
end


---------------------------------------------------------

function OblivionPlayManager:OnAvatarCtor(avatar_obj)
    log_game_debug("OblivionPlayManager:OnAvatarCtor", "avatar_dbid=%q;name=%s", avatar_obj.dbid, avatar_obj.name)

    local player_data = 
    {
        avatarDbid      = avatar_obj.dbid,
        avatarEid       = avatar_obj:getId(),
        avatarLevel     = avatar_obj.level,
        totalDamage     = 0,
        addExp          = 0,
        addMoney        = 0,
    }

    self.playerData:insert(avatar_obj.dbid, player_data)


    self.PlayerInfo[avatar_obj.dbid] = {[public_config.PLAYER_INFO_INDEX_EID]=avatar_obj:getId(), 
                                    [public_config.PLAYER_INFO_INDEX_DEADTIMES]=0, 
                                    [public_config.PLAYER_INFO_INDEX_USE_DRUG_TIMES]=0,
                                    [public_config.PLAYER_INFO_INDEX_NAME]=avatar_obj.name,
                                    [public_config.PLAYER_INFO_INDEX_REWARDS] = {[public_config.PLAYER_INFO_REWARDS_EXP] = 0,
                                                                                 [public_config.PLAYER_INFO_REWARDS_MONEY] = 0,
                                                                                 [public_config.PLAYER_INFO_REWARDS_ITEMS] = {}},
                                    [public_config.PLAYER_INFO_INDEX_DAMEGE] = 0,
                                    [public_config.PLAYER_INFO_INDEX_BASEMB] = {}
                                  }
end

function OblivionPlayManager:OnAvatarDctor(avatar_obj)
    log_game_debug("OblivionPlayManager:OnAvatarDctor", "avatar_dbid=%q;name=%s", avatar_obj.dbid, avatar_obj.name)

    --发放属性奖励
    self:SendAttrAward(avatar_obj.dbid, false)

    self.playerData:erase(avatar_obj.dbid)

    self.PlayerInfo[avatar_obj.dbid] = nil

    self:SendPlayerCount()

    self.oblivionMB.MgrEventDispatch(mogo.cPickle(avatar_obj.base), "EventFinishPlay", {self.gateID, avatar_obj.dbid}, "", "", {})
end

function OblivionPlayManager:ExitMission(avatar_dbid)
    local avatarObj     = self:GetAvatarObj(avatar_dbid)
    if not avatarObj then return end

    if self.bossProgress > 0 and self.killerDbid == 0 then
        self.oblivionMB.MgrEventDispatch(mogo.cPickle(avatarObj.base), "EventSpreadGate", {self.gateID, avatar_dbid}, "", "", {})
    end

    self.oblivionMB.MgrEventDispatch(mogo.cPickle(avatarObj.base), "EventUpdateBossProgress", {self.gateID, self.bossProgress}, "", "", {})
    avatarObj.base.MissionC2BReq(action_config.MSG_EXIT_MAP, 0, 0, '')
end

function BasicPlayManager:QuitMission(avatar_dbid)
    self:ExitMission(avatar_dbid)
end

function OblivionPlayManager:AddDamage(avatar_obj, count)
    if count <= 0 then
        log_game_warning("OblivionPlayManager:AddDamage", "avatar_dbid=%q;count=%d", avatar_dbid, count)
        return
    end

    local avatar_dbid   = avatar_obj.dbid
    local playerData    = self:GetPlayerData(avatar_dbid)
    local avatarObj     = self:GetAvatarObj(avatar_dbid)
    if not playerData or not avatarObj then return end

    playerData.totalDamage = playerData.totalDamage + count
    self.attackerData:insert(avatar_dbid, avatar_obj.vocation)
end

function OblivionPlayManager:AddMoney(avatar_dbid, count)
    if count <= 0 then
        log_game_warning("OblivionPlayManager:AddMoney", "avatar_dbid=%q;count=%d", avatar_dbid, count)
        return
    end

    local playerData    = self:GetPlayerData(avatar_dbid)
    local avatarObj     = self:GetAvatarObj(avatar_dbid)
    if not playerData or not avatarObj then return end

    playerData.addMoney = playerData.addMoney + count

    log_game_debug("OblivionPlayManager:AddMoney", "avatar_dbid=%q;count=%d;result=%d", avatar_dbid, count, playerData.addMoney)
end

function OblivionPlayManager:AddExp(avatar_dbid, count)
    if count <= 0 then
        log_game_warning("OblivionPlayManager:AddExp", "avatar_dbid=%q;count=%d", avatar_dbid, count)
        return
    end

    local playerData = self:GetPlayerData(avatar_dbid)
    local avatarObj     = self:GetAvatarObj(avatar_dbid)
    if not playerData or not avatarObj then return end

    playerData.addExp = playerData.addExp + count

    log_game_debug("OblivionPlayManager:AddExp", "avatar_dbid=%q;count=%d;result=%d", avatar_dbid, count, playerData.addExp)
end

function OblivionPlayManager:MonsterHpChange(avatar_obj, boss_obj, damage)
    if avatar_obj.c_etype ~= public_config.ENTITY_TYPE_AVATAR then return end
    if boss_obj.spawnPointCfgId ~= self.spawnPointCfgID then return end
    if damage <= 0 then return end
    if boss_obj.battleProps and boss_obj.battleProps.hpBase then
        if damage > boss_obj.battleProps.hpBase then damage = boss_obj.battleProps.hpBase end
    end

    self:AddDamage(avatar_obj, damage)

    --local exp_count     = self:GetAwardExp(avatar_obj.level, damage)
    --local money_count   = self:GetAwardMoney(avatar_obj.level, damage)
    --if exp_count > 0 then self:AddExp(avatar_obj.dbid, exp_count) end
    --if money_count > 0 then self:AddMoney(avatar_obj.dbid, money_count) end

    if boss_obj:IsDeath() and self.bossProgress ~= 0 then
        self.bossProgress = 0
        self:Victory(avatar_obj)
    elseif self.bossProgress ~= 0 and boss_obj.battleProps.hp > 0 then
        self.bossProgress = boss_obj.curHp / boss_obj.battleProps.hp
    end
end

--发放奖励
function OblivionPlayManager:SendAttrAward(avatar_dbid, is_notify)
    local playerData    = self:GetPlayerData(avatar_dbid)
    local avatarObj     = self:GetAvatarObj(avatar_dbid)
    if not playerData or not avatarObj then return end

    local exp, money    = 0, 0
    local damage        = playerData.totalDamage
    if damage >= 0 then
        exp     = self:GetAwardExp(avatarObj.level, damage) + playerData.addExp
        money   = self:GetAwardMoney(avatarObj.level, damage) + playerData.addMoney
        if exp > 0 then
            avatarObj.base.AddExp(exp, reason_def.oblivion)
            playerData.addExp = 0
            log_game_debug("OblivionPlayManager:SendReward", "avatar_dbid=%q;exp=%d", avatar_dbid, exp)
        end
        if money > 0 then
            local moneyLimit = reward_attr_data[avatarObj.level].goldLimit
            if moneyLimit > 0 and money > moneyLimit then money = moneyLimit end
            avatarObj.base.AddGold(money, reason_def.oblivion)
            playerData.addMoney = 0
            log_game_debug("OblivionPlayManager:SendReward", "avatar_dbid=%q;money=%d", avatar_dbid, money)
        end
        playerData.totalDamage = -1
        if is_notify == true then avatarObj.base.client.OblivionAwardResp(damage, exp, money) end
    end
end

function OblivionPlayManager:SendAttrAwardAll()
    for avatarDbid, _ in pairs(self.playerData) do
        self:SendAttrAward(avatarDbid, true)
    end
end

function OblivionPlayManager:SendPlayerCount()
    self.oblivionMB.MgrEventDispatch("", "EventUpdatePlayerCount", {self.gateID, self.playerData:size()}, "", "", {})
end

function OblivionPlayManager:OnLocalTimer()
    self:SendPlayerCount()

    local elapseTime = os.time() - self.createTime
    if elapseTime <= CLOSED_TICK then return end

    self:Defeat()
end


---------------------------------------------------------

g_OblivionPlayManager = OblivionPlayManager
return g_OblivionPlayManager













