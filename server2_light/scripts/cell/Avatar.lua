local public_config = require "public_config" 
require "lua_util"
require "error_code"
require "CellEntity"
require "SkillSystem"
require "mgr_map_cell"
require "avatar_level_data"
require "skillIdReflect_data"
require "mercenary_config"
require "PriceList"
require "vip_privilege"
require "state_config"
require "channel_config"
require "GlobalParams"
require "SrvEntityManager"
require "Item_data"
require "mission_config"

local log_game_debug    = lua_util.log_game_debug
local log_game_info     = lua_util.log_game_info
local log_game_warning  = lua_util.log_game_warning
local log_game_error    = lua_util.log_game_error
local _readXml          = lua_util._readXml
local myspeed           = public_config.BASE_SPEED_PER_SECOND

--定时器Id
local TIMER_ID_DEDUCTANGER      = 1             --扣除怒气值的定时器

local TEXT_MARK_CHEAT           = 1000011       --速度异常！数据库已记录！

Avatar = {}
setmetatable(Avatar, CellEntity)
-----------------------------------------------------------------------------------------------------

--构造函数
function Avatar:__ctor__()
    --log_game_debug("Avatar:__ctor__", "id=%d", self:getId())

    self.c_etype = public_config.ENTITY_TYPE_AVATAR

    --self:on_space_changed()
    --设置速度
    self:set_speed(myspeed)

    self.skillSystem = SkillSystem:New(self)
--    --最大连击次数
--    self.maxHitComboCount = 0
    
    self.skillSystem:OnLoad()

    self.tickRecord = {S0S = 0, S0E = 0, C0 = 0, QueryNo = 0, QueryTick = 0, CheatCount = 0}
    self.tickRecord.TimerID = self:addLocalTimer("ProcCheckClientWGTimer", 5000, 0)
end


--当cell对象进入Space时由引擎回调
function Avatar:onEnterSpace()

    --log_game_debug("Avatar:onEnterSpace", "self.dbid = %q", self.dbid)
    --初始化属性：要先读取完自身lv等DB属性，穿的装备以及身上附带的技能buff

    --向本场景管理器注册
    local sp = g_these_spaceloaders[self:getSpaceId()]
    if sp then
        self.sp_ref = sp
        self.factionFlag = self.sp_ref:NextFactionFlag()
        sp:OnAvatarCtor(self)

        local scene_line = lua_util.split_str(sp.map_id, "_", tonumber)

        local x, y = self:getXY()
--        log_game_debug("Avatar:onEnterSpace", "spaceId=%d;map_id=%s", self:getSpaceId(), sp.map_id)
        self.base.ChangeScene(scene_line[1], scene_line[2], x, y)

    end

end

--function Avatar:set_speed(speed)
--    self.c_speed = speed
--    self:setSpeed(math.floor(speed/2))  --通知引擎
--end

function Avatar:onLeaveSpace()
    --清楚竞技场buf
    if self.skillSystem.skillBuff:Has(public_config.ARENA_BUFF_ID) then
--        log_game_debug("Avatar:onLeaveSpace", "RemoveBuff")
        self.skillSystem:RemoveBuff(public_config.ARENA_BUFF_ID)
    end
    --向场景管理器注销
    self.FBProgress = 1
    self.sp_ref:OnAvatarDctor(self)

--    --玩家离开场景时清空怒气相关数据
--    self:ClearAngerInfo()
    log_game_debug("Avatar:onLeaveSpace", "dbid=%q;name=%s;id=%d", self.dbid, self.name, self:getId())

end

--destroy之前的回调方法
function Avatar:onDestroy()
    log_game_debug("Avatar:onDestroy", "dbid=%q;name=%s;id=%d", self.dbid, self.name, self:getId())

    self.skillSystem:OnSave()

    --注销技能系统
    self.skillSystem:Del()

    if self.tickRecord.TimerID then
        self:delLocalTimer(self.tickRecord.TimerID)
    end
end

--base通知cell二次登录
function Avatar:onMultiLogin()
    log_game_info("Avatar:onMultiLogin", "dbid=%q;name=%s;id=%d",
                                          self.dbid, self.name, self:getId())

    self.sp_ref:SyncCliEntityInfo()
                                          
    self.skillSystem:Reset()
end

--同场景传送,参数:x,y
function Avatar:TelportLocally(x, y)
    --先发传送成功的结果再跳转
--    self.base.on_teleport_suc_resp()
--    log_game_debug("Avatar:TelportLocally", "x=%d;y=%d", x, y)
    self:teleport(x, y)
end


function Avatar:EnterTeleportpointReq(tp_eid)
    log_game_debug("Avatar:EnterTeleportpointReq", "tp_eid=%d", tp_eid)
    gCellMapMgr:EnterTeleportpointReq(self, tp_eid)
end

--同cell内不同场景传送,参数:SpaceLoader id,x,y
function Avatar:TelportSameCell(spId, x, y)
    log_game_debug("Avatar:TelportSameCell", "spId=%d;x=%d;y=%d", spId, x, y)
    local sp = mogo.getEntity(spId)
    if sp then

        log_game_debug("Avatar:TelportSameCell before", "selfSpaceId=%d;targetSpaceId=%d", self:getSpaceId(), sp:getSpaceId())

--        --向旧的场景管理器注销
--        self.sp_ref:OnAvatarDctor(self)
        --先发传送成功的结果再跳转
--        self.base.onTeleportSucResp()

        self:teleport(sp:getSpaceId(), x, y)

        log_game_debug("Avatar:TelportSameCell after", "selfSpaceId=%d;targetSpaceId=%d", self:getSpaceId(), sp:getSpaceId())

--        self:on_space_changed()

--        local scene_line = lua_util.split_str(self.sp_ref.map_id, "_", tonumber)
--
--        self.base.ChangeScene(scene_line[1], scene_line[2], x, y)

    else
        self.base.on_teleport_fail_resp()
    end
end

--玩家隐身,从aoi管理器删除,但是不离开space
function Avatar:set_invisiable()
    self:setVisiable(0)
end

--现身
function Avatar:set_visiable()
    self:setVisiable(1)
end

--引擎回调方法，客户端控制的非Avatar的实体，宠物、雇佣兵等的移动
function Avatar:OthersMoveReq(type, x, y)
    log_game_debug("Avatar:OthersMoveReq", "type=%d;x=%d;y=%d", type, x, y)
end

--施放技能
function Avatar:UseSkillReq(clientTick, x, y, face, skillID, targetsID)
    if not self.skillSystem then
        log_game_error("Avatar:UseSkillReq", "skillSystem is nil")
        return
    end

    self:setXY(x, y)
    self:setFace(face*2)
    self.skillSystem:OnClientUseSkill(skillID, targetsID, clientTick)
end

--佣兵施放技能
function Avatar:MercenaryUseSkillReq(clientTick, mercenaryID, x, y, face, skillID, targetsID)
--    if not self.skillSystem then
--        log_game_error("Avatar:MercenaryUseSkillReq", "skillSystem is nil")
--        return
--    end

    local theMercenary = mogo.getEntity(mercenaryID)
    if theMercenary and theMercenary.c_etype == public_config.ENTITY_TYPE_MERCENARY then
        if not theMercenary.skillSystem then
            log_game_error("Avatar:MercenaryUseSkillReq", "skillSystem is nil")
            return
        end

        theMercenary:setXY(x, y)
        theMercenary:setFace(face*2)
        theMercenary.skillSystem:OnClientMercenaryExecuteSkill(skillID, targetsID, clientTick)

    end
end

--畜力技能，开始畜力(客户端回调)
function Avatar:ChargeSkillReq(clientTick)
    if not self.skillSystem then
        log_game_error("Avatar:ChargeSkillReq", "skillSystem is nil")
        return
    end

    self.skillSystem:ChargeSkillReq(clientTick)
end

--畜力技能，取消畜力(客户端回调)
function Avatar:CancelChargeSkillReq()
    if not self.skillSystem then
        log_game_error("Avatar:CancelChargeSkillReq", "skillSystem is nil")
        return
    end

    self.skillSystem:CancelChargeSkillReq()
end

function Avatar:MarkCheat(S1S, S1E, C1, force_flag)
    self.tickRecord.CheatCount = self.tickRecord.CheatCount + 1
    if self.tickRecord.CheatCount >= 3 or force_flag == true then
        self.cheatServerCount = self.cheatServerCount + 1
        local deltaC    = C1 - self.tickRecord.C0
        local deltaS    = S1E - self.tickRecord.S0S
        local delta     = deltaC - deltaS
        log_game_warning("Avatar:MarkCheat", "Cheat!dbid=%q;name=%s;(S0S=%q,S0E=%q,C0=%q,S1S=%q,S1E=%q,C1=%q,Delta=%q)", self:getDbid(), self.name,
                         self.tickRecord.S0S, self.tickRecord.S0E, self.tickRecord.C0, S1S, S1E, C1, delta)
        self:ShowTextID(CHANNEL.TIPS, TEXT_MARK_CHEAT)
        self.tickRecord.CheatCount = 0
    end
end

function Avatar:MarkTick(S1S, S1E, C1, force_flag)
    if self.tickRecord.S0S == 0 or force_flag == true then
        self.tickRecord.S0S = S1S
        self.tickRecord.S0E = S1E
        self.tickRecord.C0  = C1
    else
        local deltaS0 = self.tickRecord.S0E - self.tickRecord.S0S
        local deltaS1 = S1E - S1S
        if deltaS1 <= deltaS0 then
            self.tickRecord.S0S = S1S
            self.tickRecord.S0E = S1E
            self.tickRecord.C0  = C1
        end
    end
end

function Avatar:VerifyTick(S1S, S1E, C1)
    if self.tickRecord.S0S == 0 then return true end
    if S1S == 0 then S1S = self.tickRecord.S0S end

    local deltaC    = C1 - self.tickRecord.C0
    --local deltaS0   = self.tickRecord.S0E - self.tickRecord.S0S
    --local deltaS1   = S1E - S1S
    local deltaS    = S1E - self.tickRecord.S0S
    if deltaC > deltaS + 200 then
        return false
    end
    return true
end

function Avatar:QueryClientTickResp(queryNo, clientTick)
    if self.tickRecord.QueryNo == queryNo and clientTick and clientTick ~= 0 then
        if self.tickRecord.S0S == 0 then
            self.tickRecord.S0S = self.tickRecord.QueryTick
            self.tickRecord.S0E = mogo.getTickCount()
            self.tickRecord.C0  = clientTick
        else
            local S1S = self.tickRecord.QueryTick
            local S1E = mogo.getTickCount()
            local C1  = clientTick
            if self:VerifyTick(S1S, S1E, C1) then
                self:MarkTick(S1S, S1E, C1, false)
                self.tickRecord.CheatCount = 0
            else
                self:MarkCheat(S1S, S1E, C1)
                self:MarkTick(S1S, S1E, C1, true)
            end
        end
    end
    self.tickRecord.QueryNo = 0
end

function Avatar:ProcCheckClientWGTimer(timerID, activeCount)
    if self.tickRecord.QueryNo == 0 then
        self.tickRecord.QueryNo = activeCount
        self.tickRecord.QueryTick = mogo.getTickCount()
        self.base.client.QueryClientTickReq(activeCount)
    end
end

function Avatar:ProcSkillBuffStopTimer(timerID, activeCount, buffID)
    self.skillSystem.skillBuff:ProcSkillBuffStopTimer(timerID, activeCount, buffID)
end

function Avatar:ProcSkillBuffTimer(timerID, activeCount, buffID, skillID)
    self.skillSystem.skillBuff:ProcSkillBuffTimer(timerID, activeCount, buffID, skillID)
end

function Avatar:ProcSkillActionTimer(timerID, activeCount, param1, param2)
    self.skillSystem.skillAction:ProcSkillActionTimer(timerID, activeCount, param1, param2)
end

function Avatar:ShowText(channelID, text, ...)
    self.base.client.ShowText(channelID, string.format(text, ...))
end

function Avatar:ShowTextID(channelID, textID)
    self.base.client.ShowTextID(channelID, textID)
end

--------------------------------------------属性更新 begin----------------------------------------------


function Avatar:ProcessBattleProperties(baseProps)
    local battleProps = lua_util.deepcopy_1(baseProps)

    setmetatable(battleProps,      
        {__index =               
            function (table, key)
                --log_game_error("battleProps ASK", "%s", key)
                return 0         
            end                  
        }                        
    )
   
    --技能buff提供的属性加成
    self.skillSystem.skillBuff:UpdateAttrEffectTo(battleProps)

    self.battleProps        = battleProps
    self.battleProps.org    = baseProps

    self:SyncPropsToClient(self.battleProps)

    

    --初始化时去除玩家的死亡状态
--    self.CellState = mogo.sunset(self.CellState, public_config.STATE_DEATH)
--    self.deathFlag = 0 
end

function Avatar:RecalculateBattleProperties()
    if self.battleProps.org then
        local org_v = self.battleProps.org
        local new_v = lua_util.deepcopy_1(self.battleProps.org)
        setmetatable(new_v, {__index = function (table, key) return 0 end})
        self.skillSystem.skillBuff:UpdateAttrEffectTo(new_v)
        self.battleProps = new_v
        self.battleProps.org = org_v
        self:SyncPropsToClient(self.battleProps)
    end
end

--赋值后自动同步前端
function Avatar:SyncPropsToClient(baseProps)
    for k, v in pairs(baseProps) do
        if self[k] ~= nil then
            self[k] = v
        end
    end
    self.curHp = baseProps.hp 
    --self.hp = baseProps.hp
    --self.atk = baseProps.atk
    --self.def = baseProps.def
    --self.speedAddRate = baseProps.speedAddRate
    --self.hit = baseProps.hit
    --self.crit = baseProps.crit
    --self.trueStrike = baseProps.trueStrike
    --self.critExtraAttack = baseProps.critExtraAttack
    --self.antiDefense = baseProps.antiDefense
    --self.antiCrit = baseProps.antiCrit
    --self.antiTrueStrike = baseProps.antiTrueStrike
    ----self.damageReduce = baseProps.damageReduce
    --self.cdReduce = baseProps.cdReduce
    ----self.extraHitRate = baseProps.extraHitRate
    ----self.extraCritRate = baseProps.extraCritRate
    ----self.extraTrueStrikeRate = baseProps.extraTrueStrikeRate
    --self.pvpAddition = baseProps.pvpAddition
    --self.pvpAnti = baseProps.pvpAnti
    ----self.extraExpRate = baseProps.extraExpRate
    ----self.extraGoldRate = baseProps.extraGoldRate
    ----self.lifeStealRate = baseProps.lifeStealRate
    ----self.extraRecoverRate = baseProps.extraRecoverRate
    --self.earthDamage = baseProps.earthDamage
    --self.airDamage = baseProps.airDamage
    --self.waterDamage = baseProps.waterDamage
    --self.fireDamage = baseProps.fireDamage
    --self.earthDefense = baseProps.earthDefense
    --self.airDefense = baseProps.airDefense
    --self.waterDefense = baseProps.waterDefense
    --self.fireDefense = baseProps.fireDefense
    --self.allElementsDamage = baseProps.allElementsDamage
    --self.allElementsDefense = baseProps.allElementsDefense
end

function Avatar:RuneEffects(effectIds)
    for k, v in pairs(effectIds) do
        log_game_debug("rune effects", "%d", v)
    end
end

function Avatar:addHp(value)
    value = math.ceil(value)
    --lua_util.traceback()
    --value = -1
    local curHp = self.curHp
    if curHp <= 0 then
        if curHp + value > 0 then
            --复活
            curHp = curHp + value
			if curHp > self.hp then
				curHp = self.hp
			end
            self.curHp = curHp
            self:TestDeath()
        end
    elseif curHp > 0 then
        if curHp + value <= 0 then
            --死亡
            curHp = 0
            self.curHp = curHp
			log_game_debug("Avatar:addHp", "dbid=%q;name=%s;value=%d;curHp =%d", self.dbid, self.name, value, self.curHp)
            self:TestDeath()
    	elseif curHp + value > self.hp then
			--超上限
			self.curHp = self.hp
			log_game_debug("Avatar:addHp", "dbid=%q;name=%s;value=%d;curHp=%d", self.dbid, self.name, value, self.curHp)
        else
            --扣血但没死
            curHp = curHp + value
            self.curHp = curHp
			log_game_debug("Avatar:addHp", "dbid=%q;name=%s;value=%d;curHp=%d", self.dbid, self.name, value, self.curHp)
        end
    end
end

function Avatar:setHp(value)
    local curHp = self.curHp

    if value < 0 then
        value = 0
    end

    if curHp <= 0 and value > 0 then
        --复活
        self.curHp = value
        self:TestDeath()
    elseif curHp > 0 and value <= 0 then
        --死亡
        self.curHp = value
        self:TestDeath()
    else
        self.curHp = value
    end
end

function Avatar:IsDeath()
--    local result = mogo.stest(self.CellState, public_config.STATE_DEATH)
  --  if result == 0 then
    if self.curHp > 0 then
        return false
    else
        return true
    end
--    return self.deathFlag == 1
end

function Avatar:TestDeath()
    local curHp = self.curHp
    if curHp > 0 then
--        self.CellState = mogo.sunset(self.CellState, public_config.STATE_DEATH)
--        self.deathFlag = 0
        self.stateFlag = Bit.Reset(self.stateFlag, state_config.DEATH_STATE)

        self.base.UnsetStateToBase(state_config.DEATH_STATE)
        log_game_debug("TestDeath UnsetStateToBase", "dbid=%q;name=%s;stateFlag=%d", self.dbid, self.name, self.stateFlag)
    else
--        self.CellState = mogo.sset(self.CellState, public_config.STATE_DEATH)
--        self.deathFlag = 1
        self.stateFlag = Bit.Set(self.stateFlag, state_config.DEATH_STATE)
        self.base.SetStateToBase(state_config.DEATH_STATE)
        log_game_debug("TestDeath SetStateToBase", "dbid=%q;name=%s;stateFlag=%d", self.dbid, self.name, self.stateFlag)
        self:ProcessDie()
    end
end

function Avatar:ProcessDie()
    self.sp_ref:MonsterThink(Mogo.AI.AIEvent.AvatarDie)
    self.sp_ref:DeathEvent(self.dbid)
    self.skillSystem.skillBuff:OnDie()
end

function Avatar:ProcessRevive()
    self.sp_ref:MonsterThink(Mogo.AI.AIEvent.AvatarRevive)  
end

--------------------------------------------属性更新 end------------------------------------------------


--------------------------------------------拾取 begin------------------------------------------------
function Avatar:PickDropReq(dropEid)
--    if dropEid == nil then
--        log_game_debug("Avatar:PickDropReq", "dropEid=nil")
--    else
--        log_game_debug("Avatar:PickDropReq", "dropEid=%d", dropEid)
--    end
    self:ProcessPickDrop(dropEid)
end

function Avatar:ProcessPickDrop(dropEid)
    local rnt = 0
    local result = {}
    local dropEntity = self.sp_ref.CliEntityManager:getEntity(dropEid)
    if not dropEntity then
        self.base.client.PickDropResp(1, {})  
	    return
    end
    local dropBelongAvatarId = dropEntity.belongAvatar
    if dropBelongAvatarId ~= self:getId() then
        self.base.client.PickDropResp(2, {})  
    	return --该掉落物品不属于本人    
    end

    --距离判断(未做)
    
	local result = {}
	
	if dropEntity.gold > 0 then
    	result[1] = dropEntity.gold
	    self.sp_ref:AddMoney(self.dbid, dropEntity.gold)
    else
	    local dropItemTypeId = dropEntity.itemId
	    result[dropItemTypeId] = 1
	    self.sp_ref:AddRewards(self.dbid, dropItemTypeId, 1)
    end

    self.sp_ref.CliEntityManager:delEntity(dropEntity)

    self.base.client.PickDropResp(dropEid, result)
end

--------------------------------------------拾取 end------------------------------------------------
-----------------------------------------------------------------------------------------------------

function Avatar:AvatarMove()
    do return end
    --加入地图类型判断
    if self.sceneId == g_GlobalParamsMgr:GetParams('init_scene', 10004) then
        return
    end

    local nowTick = mogo.getTickCount()
    if nowTick < self.avatarMoveCDEndTime then
        return
    end

    if self.curHp <= 0 then
        return
    end

    self.avatarMoveCDEndTime = (nowTick + 500)
        

    self.sp_ref:MonsterThink(Mogo.AI.AIEvent.AvatarPosSync)
end

function Avatar:TestInSpawnPointCfgId(x, y)
    local tblRnt = {}
    local scene_line = lua_util.split_str(self.sp_ref.map_id, "_", tonumber)
    local map_entity_cfg_data = g_map_mgr:GetMapEntityCfgData(scene_line[1])
    if map_entity_cfg_data ~= nil then
        for i, v in pairs(map_entity_cfg_data) do
            if v['type'] == 'SpawnPoint' then 
                local disX = math.abs(x - v['homerangeX'])
                local disY = math.abs(y - v['homerangeY']) 
                if disX < v['homerangeLength']/2 and disY < v['homerangeWidth']/2 then
                    table.insert(tblRnt, i)
                end--if
            end
        end--for
    end--if


    return tblRnt
end

function Avatar:CreateCliEntityResp(sendBuf)
    self.base.client.CreateCliEntityResp(sendBuf)
end
-- function Avatar:SkillUpgradeReq(skillId, nextSkillId) --技能升级请求
--     local ret = g_skill_upgrade:SkillUpReq(self, skillId, nextSkillId)
--     if ret == 0 then return end
--     mogo.EntityOwnclientRpc(self, "SkillUpResp", ret)
-- end
-- function Avatar:SkillUpCallback(retCode, currSkills, nextSkills)
--     local ret = g_skill_upgrade:SkillCallback(self, retCode, currSkills, nextSkills)
--     mogo.EntityOwnclientRpc(self, "SkillUpResp", ret)
-- end
function Avatar:SyncEquipMode(idx, typeId)
    log_game_debug("Avatar:SyncEquipMode", "dbid=%q;name=%s;idx=%d;typeId=%d", self.dbid, self.name, idx, typeId)
    if idx == nil or typeId == nil then
        log_game_error("Avatar:SyncEquipMode", "parameter error:dbid=%q;name=%s;idx=%d;typeId=%d",
            self.dbid, self.name, idx, typeId)
        return
    end
    if idx == public_config.BODY_CHEST then  --胸甲
        if typeId ~= self.loadedCuirass then
            self.loadedCuirass = typeId
        end
    end
    if idx == public_config.BODY_ARMGUARD then  --护手
        if typeId ~= self.loadedArmguard then
            self.loadedArmguard = typeId
        end
    end
    if idx ==  public_config.BODY_LEG then --鞋子
        if typeId ~= self.loadedLeg then
            self.loadedLeg = typeId
        end
    end
    if idx == public_config.BODY_WEAPON then --武器
        if typeId ~= self.loadedWeapon then
            self.loadedWeapon = typeId
        end
    end
    if idx == public_config.BODY_SPEC_JEWEL then --宝石特效
        if typeId ~= self.loadedJewelId then
            self.loadedJewelId = typeId
        end
    end
    if idx == public_config.BODY_SPEC_EQUIP then --装备特效
        if typeId ~= self.loadedEquipId then
            self.loadedEquipId = typeId
        end
    end
    if idx == public_config.BODY_SPEC_STRGE then --强化特效
        if typeId ~= self.loadedStrengthenId then
            self.loadedStrengthenId = typeId
        end
    end
    if idx == public_config.BODY_WING then --翅膀
        if typeId ~= self.loadedWingId then
            self.loadedWingId = typeId
        end
    end
end

function Avatar:GetScaleRadius()
    return 0
end

function Avatar:UseHpBottleVerifyReq()
    local retCode = self:UseHpBottleVerify()
    self.base.UseHpBottleVerifyResp(retCode)
end

function Avatar:UseHpBottleVerify()
    local flag = Bit.Test(self.stateFlag, state_config.DEATH_STATE)
    if flag then
        return error_code.ERR_HP_AVATAR_DEATH
    end
    if self.curHp == self.hp then
        return error_code.ERR_HP_FULL
    end
    return error_code.ERR_HP_VERIFY_SUCCESS
end

function Avatar:set_prop(prop, value)
    if self[prop] ~= nil then
        if prop == "curHp" and value > self.hp then
            return
        end
        self[prop] = value
    end
end

function Avatar:AddBuffId(buffId)
    self.skillSystem.skillBuff:Add(buffId)
end

-- function Avatar:SyncMaxEnergy(maxEnergy)
--     self.maxEnergy = maxEnergy
--     log_game_debug("Avatar:SyncMaxEnergy", "maxEnergy = %s, self.maxEnergy = %s", tostring(maxEnergy), tostring(self.maxEnergy))
-- end

function Avatar:CliEntityActionReq(eid, actionId, tblParam)
    self.sp_ref:CliEntityActionReq(eid, actionId, self, tblParam)     
end

function Avatar:ResetHpCount()
    self.base.ResetHpCount()
end

function Avatar:GetIdleMercenaryEntity(tblData)
    local entityTypeName = 'Mercenary'
    local entityType = public_config.ENTITY_TYPE_MERCENARY
    local entity = SrvEntityManager:GetIdleEntity(entityType)
    if entity ~= nil then
            
            log_game_debug("Avatar:GetIdleMercenaryEntity", "battleProps=%s", mogo.cPickle(tblData.battleProps))
            entity:setXY(tblData.enterX, tblData.enterY)
            entity.spawnPointCfgId  = 0
            entity.vocation         = tblData.vocation      
            entity.loadedWeapon     = tblData.modes[public_config.BODY_WEAPON] 
            entity.loadedCuirass    = tblData.modes[public_config.BODY_CHEST]
            entity.loadedArmguard   = tblData.modes[public_config.BODY_ARMGUARD]
            entity.loadedLeg      = tblData.modes[public_config.BODY_LEG]
--            entity.loadedBodyEffect = 0
            entity.battleProps      = tblData.battleProps
            entity.curHp            = tblData.battleProps.hp    
            entity.ownerEid         = (tblData.isPVP and 0) or self:getId()
            entity.monsterId        = 0                    
            entity.notTurn          = 0                      
            entity.clientTrapId     = 0                 
            entity.skillBag         = tblData.skillBag
            entity.name             = tblData.name
            entity.factionFlag      = (tblData.isPVP and 0) or self.factionFlag
            entity.isPVP            = (tblData.isPVP and 1) or 0

            entity.level            = tblData.level
            entity.antiDefense      = tblData.battleProps.antiDefense 
            entity.antiDefenseRate  = tblData.battleProps.antiDefenseRate
            entity.atk              = tblData.battleProps.atk
            entity.attackBase       = tblData.battleProps.attackBase
            entity.baseHitRate      = tblData.battleProps.baseHitRate
            entity.crit             = tblData.battleProps.crit 
            entity.critExtraAttack  = tblData.battleProps.critExtraAttack 
            entity.critRate         = tblData.battleProps.critRate      
            entity.damageReduceRate = tblData.battleProps.damageReduceRate          
            entity.def              = tblData.battleProps.def   
            entity.hp               = tblData.battleProps.hp    
            entity.defenceRate      = tblData.battleProps.defenceRate      
            entity.hitRate          = tblData.battleProps.hitRate      
            entity.pvpAddition      = tblData.battleProps.pvpAddition          
            entity.pvpAdditionRate  = tblData.battleProps.pvpAdditionRate 
            entity.pvpAnti          = tblData.battleProps.pvpAnti          
            entity.pvpAntiRate      = tblData.battleProps.pvpAntiRate          
            entity.trueStrike       = tblData.battleProps.trueStrike          
            entity.trueStrikeRate   = tblData.battleProps.trueStrikeRate   
            entity.antiTrueStrikeRate   = tblData.battleProps.antiTrueStrikeRate
            entity.antiCritRate         = tblData.battleProps.antiCritRate
            entity.missRate             = tblData.battleProps.missRate

            
            entity.avatarDbid = tblData.avatarDbid --离线pvp或者雇佣兵带该值
            entity:addToSpace(self.sp_ref:getSpaceId(), tblData.enterX, tblData.enterY, 0) 
    else
        log_game_error("old mercenary entity is nil", "entity")
    end

    return entity
end

function Avatar:MercenaryBattleProperties(attri, modes, skill, other_info, isPvp)
    --容错    
    setmetatable(attri,               
        {__index =                
            function (table, key) 
                return 0          
            end                   
        }                         
    )                             

    attri.hp = attri.hpBase
    if not modes[public_config.BODY_WEAPON] then
        modes[public_config.BODY_WEAPON] = 0
    end
    if not modes[public_config.BODY_CHEST] then
        modes[public_config.BODY_CHEST] = 0
    end
    if not modes[public_config.BODY_ARMGUARD] then
        modes[public_config.BODY_ARMGUARD] = 0
    end
    if not modes[public_config.BODY_LEG] then
        modes[public_config.BODY_LEG] = 0
    end



    --过滤掉另外一种武器拥有的技能只保留现在武器的技能
    local curWeaponType = other_info.weapon_subtype
    for skillId, value in pairs(skill) do
	--test bug 为了容错 value可能是string原因未查明
	skill[skillId] = 1
	value = 1	

        local skillCfg = g_SkillSystem:GetSkill(skillId)      
        if skillCfg and skillCfg.weapon ~= curWeaponType then
            skill[skillId] = 0     
        end
    end 
    
--    modes[public_config.BODY_CHEST], modes[public_config.BODY_ARMGUARD],  modes[public_config.BODY_LEG])

    local selfX = 0
    local selfY = 0
    if isPvp > 0 then
        selfX = 3774
        selfY = 2304
    else
        selfX, selfY = self:getXY()
        selfX = selfX + 150
        selfY = selfY + 150
    end
    --[[pvp的情况
    我：2348,2240
    敌：2715,2440
    ]]
    local entity = self:GetIdleMercenaryEntity(
            {
                battleProps = attri,                                      
                enterX = selfX,  
                enterY = selfY,
                vocation = other_info.vocation,
                modes = modes,
                skillBag = g_skillIdReflect_mgr:reflectSkillTbl(skill),
                isPVP = (isPvp > 0),
                name = other_info.name,
                level = other_info.level,
                avatarDbid = other_info.dbid,
            }
        )
    if entity ~= nil then
        log_game_debug("OnAvatarCtor:Mercenary", "i=%d isNew", entity:getId(), isNew)  
        entity:StartMercenary()
    end
end

function Avatar:GetLuaDistance(x, y)
    local selfX, selfY = self:getXY()
    local h = y - selfY
    local w = x - selfX

    return math.sqrt(h^2 + w^2)
end

function Avatar:UpdateMercenaryCoord(mercenaryID, x, y, face, curHp)
--    log_game_debug("Avatar:UpdateMercenaryCoord", "mercenaryID=%d;x=%d;y=%d;face=%d;curHp=%d", mercenaryID, x, y, face, curHp)
    local theMercenary = mogo.getEntity(mercenaryID)
    if theMercenary ~= nil then
        if theMercenary.c_etype == public_config.ENTITY_TYPE_MERCENARY then
--            log_game_debug("Avatar:UpdateMercenaryCoord", "mercenaryID=%d;x=%d;y=%d;face=%d;curHp=%d", mercenaryID, x, y, face, curHp)
            theMercenary:setXY(x, y)
            theMercenary:setFace(face*2)
            if curHp < theMercenary.curHp then
                theMercenary:addHp((theMercenary.curHp - curHp)*-1)
            end
        end
    end
end

function Avatar:CreateMercenaryReq(timerId, count, isPvp, param2)
    isPvp = isPvp or 0
    self.base.CreateMercenaryReq(isPvp)
end

function Avatar:ReviveReq()
    local flag = Bit.Test(self.stateFlag, state_config.DEATH_STATE)
    if not flag then
        self.base.client.MissionResp(action_config.MSG_REVIVE, {-2})
    end

    if self.sp_ref then
        self.sp_ref:Revive(self.dbid)
    end
end

function Avatar:RemoveBuff(buff_id)
    if buff_id > 0 then
        self.skillSystem.skillBuff:Remove(buff_id)
    else
        self.skillSystem.skillBuff:Del()
    end
end

function Avatar:AddBuff(buff_id)
    self.skillSystem.skillBuff:Add(buff_id)
end


--function Avatar:AddAnger(anger)
--
--    log_game_debug("Avatar:AddAnger", "dbid=%q;name=%s;anger=%d;Anger=%d;AngerTimerId=%d", self.dbid, self.name, anger,  self.Anger, self.AngerTimerId)
--
--    if anger > 0 and self:IsAngerFull() then
--        return
--    end
--
--    self.Anger = math.max(0, math.min(g_GlobalParamsMgr:GetParams('anger_full', 200), self.Anger + anger))
--
--    if self.Anger == 0 then
--        self:ClearAnger()
--    end
--end

--function Avatar:IsAngerFull()
--    if self.AngerTimerId > 0 or self.Anger >= g_GlobalParamsMgr:GetParams('anger_full', 200) then
--        return true
--    else
--        return false
--    end
--end

--function Avatar:ClearAnger()
--    if self.AngerTimerId > 0 then
--        self:delTimer(self.AngerTimerId)
--    end
--    self.AngerTimerId = 0
--    self.Anger = 0
--end

--function Avatar:ClearAngerInfo()
--    self.harmInfo = {}
--    self.harmAngerTimesInfo = {}
--    self.harmedInfo = {}
--    self.harmedAngerTimesInfo = {}
--end

--function Avatar:onTimer(timer_id, user_data)
--    if user_data == TIMER_ID_DEDUCTANGER then
--        if self:IsAngerFull() then
--            self:AddAnger(-g_GlobalParamsMgr:GetParams('anger_decrease_value', 10))
--        end
--    end
--end

function Avatar:StartUseAnger()
    log_game_debug("Avatar:StartUseAnger", "dbid=%q;name=%s", self.dbid, self.name)
--    if self:IsAngerFull() and self.AngerTimerId == 0 then
--        self.AngerTimerId = self:addTimer(g_GlobalParamsMgr:GetParams('anger_decrease_rate', 1), g_GlobalParamsMgr:GetParams('anger_decrease_rate', 1), TIMER_ID_DEDUCTANGER)
--    end
end

function Avatar:LearnReq(skillId)
    log_game_debug("Avatar:LearnReq", "dbid=%q;name=%s;skillId=%d", self.dbid, self.name, skillId)
    self.skillSystem:Learn(skillId)
end
function Avatar:UnlearnReq(skillId)
    log_game_debug("Avatar:UnlearnReq", "dbid=%q;name=%s;skillId=%d", self.dbid, self.name, skillId)
    self.skillSystem:Unlearn(skillId)
end
return Avatar

