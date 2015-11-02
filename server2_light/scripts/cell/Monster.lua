-- Create by Kevinhua
-- Modifed by Kevinhua
-- User: Administrator
-- Date: 13-3-19
-- Time: 15:55
-- 怪物.
--


local public_config = require "public_config"
require "lua_util"
require "error_code"
require "SpaceThing"
require "SkillSystem"
require "monster_data"
require "drop_data"
require "state_config"
require "SrvEntityManager"
--AI
local Mogo = require "BTNode"
require "DecoratorNodes"
require "ConditionNodes"
require "ActionNodes"
--local AIRoots = require "all_ai"

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error

local sectorAngle = lua_util.sectorAngle
local math_sqrt = math.sqrt
local math_floor = math.floor


------------------------------------------------------------------------------------------------
Monster = {}
setmetatable(Monster, SpaceThing)
SpaceThing.__index = SpaceThing
------------------------------------------------------------------------------------------------


function Monster:__ctor__()
    self.c_etype = public_config.ENTITY_TYPE_MONSTER

    self.skillSystem = SkillSystem:New(self)

end

function Monster:onEnterSpace()

    local sp = g_these_spaceloaders[self:getSpaceId()] 
    if sp then
        self.sp_ref = sp 
    end
    

end

function Monster:onDestroy()
    log_game_debug("Monster:onDestroy", "id=%d", self:getId())
    --注销技能系统
    self.skillSystem:Del()
end

function Monster:Start(cfgData)
    local tmpCfgData = cfgData
    if tmpCfgData == nil then
        return false
    end

    self:ProcessBattleProperties(tmpCfgData)
    self.curHp = self.battleProps.hp
    self.stateFlag = Bit.Reset(self.stateFlag, state_config.DEATH_STATE)
    self.borned = 0
    self.stateFlag = Bit.Set(self.stateFlag, state_config.NO_HIT_STATE)
	
   -- if tmpCfgData.showHitAct ~= nil and tmpCfgData.showHitAct > 0 then
	    self.stateFlag = Bit.Set(self.stateFlag, state_config.BATI_STATE)
   -- end
    self.sp_ref:InsertAliveMonster(self:getId())
	
    --register world boss
    if tmpCfgData.isClient == public_config.MONSTER_IS_CLIENT_BOSS and 
        self.spawnPointCfgId == public_config.SANCTUARY_BOSS_SPWAN_ID then
--        log_game_debug("Monster:Start", "RegisterBoss")
        self.sp_ref.PlayManager:RegisterBoss(self.sp_ref.map_id, mogo.pickleMailbox(self.sp_ref), self:getId())
        self.ctrlByBossHpMgr = 1
    end

    self.blackBoard = Mogo.AI.BlackBoard:new() 
    self.blackBoard:ChangeState(Mogo.AI.AIState.THINK_STATE)    
    
    self.factionFlag = tmpCfgData.faction
    
    local time = math.random(1, 1000)

    self:addLocalTimer("ProcessAppear", time, 1, {bornDelayTime = tmpCfgData.bornTime})
end

function Monster:ProcessAppear(timer_id, count, arg1, arg2)
    
    --出生动画时间
    
    if arg1.bornDelayTime == nil or arg1.bornDelayTime == 0 then
        arg1.bornDelayTime = 2000
   
    end
    
    self:addLocalTimer("RebornAnimationDelay", arg1.bornDelayTime+1000, 1)
    self:setVisiable(1)--出现
        

    return true
end




function Monster:Stop()
    if self.blackBoard.timeoutId ~= nil and self.blackBoard.timeoutId > 0 then
        self:delLocalTimer(self.blackBoard.timeoutId)
        self.blackBoard.timeoutId = 0
    end

    if self.blackBoard.thinkUpdateTimeoutId ~= nil and self.blackBoard.thinkUpdateTimeoutId > 0 then
        self:delLocalTimer(self.blackBoard.thinkUpdateTimeoutId)
        self.blackBoard.thinkUpdateTimeoutId = 0
    end
    
    if self.blackBoard.coordUpdateTimeoutId ~= nil and self.blackBoard.coordUpdateTimeoutId > 0 then
        self:delLocalTimer(self.blackBoard.coordUpdateTimeoutId)
        self.blackBoard.coordUpdateTimeoutId = 0
    end
    

    --Unregister world boss
    local tmpCfgData = g_monster_mgr:getCfgById(self.monsterId)
    if tmpCfgData == nil then
        log_game_error("Monster:Stop", 'Boss tmpCfgData == nil')
        return
    end
    if tmpCfgData.isClient == public_config.MONSTER_IS_CLIENT_BOSS and 
        self.spawnPointCfgId == public_config.SANCTUARY_BOSS_SPWAN_ID then
        log_game_debug("Monster:Stop","UnregisterBoss")
        --不需反注册，在活动结束时会全部一起反注册
        --self.sp_ref.PlayManager:UnregisterBoss(self.sp_ref.map_id, self:getId())
        self.ctrlByBossHpMgr = 0
    end

    
    self:ResetData()
end

function Monster:GetScaleRadius()
    return self.battleProps.scaleRadius
end

---------------------------------------属性begin----------------------------------------------

function Monster:ProcessBattleProperties(cfgProps)
    self.battleProps.exp = cfgProps.exp
    self.battleProps.model = cfgProps.model
    self.battleProps.speed = cfgProps.speed
    self.battleProps.scaleRadius = cfgProps.scaleRadius

    self.battleProps.hpBase = cfgProps.hpBase
    self.battleProps.hp = self.battleProps.hpBase
    self.battleProps.attackBase = cfgProps.attackBase
    self.battleProps.atk = cfgProps.attackBase
    self.battleProps.def = 0 

    self.battleProps.hitRate = cfgProps.extraHitRate * 0.0001
    self.battleProps.critRate = cfgProps.extraCritRate * 0.0001
    self.battleProps.trueStrikeRate = cfgProps.extraTrueStrikeRate * 0.0001
    self.battleProps.antiDefenseRate = cfgProps.extraAntiDefenceRate * 0.0001
    self.battleProps.defenceRate = cfgProps.extraDefenceRate * 0.0001
    self.battleProps.missRate = cfgProps.missRate * 0.0001

    self.level = cfgProps.level
    
    --怪物的技能表
    self.battleProps.skillBag = cfgProps.skillIds

    if self.battleProps.skillBag == 0 or #self.battleProps.skillBag <= 0 then
        self.battleProps.skillBag = {}
        log_game_debug("monster skillBag", "size<=0") 
    end
    --技能buff提供的属性加成
--    self.skillSystem.skillBuff:UpdateAttrEffectTo(self.battleProps)
    
    self:setSpeed(self.battleProps.speed/10)  --通知引擎
    self.speed = self.battleProps.speed/100
end

function Monster:addHp(value)
    value = math.ceil(value)
    
    if self.borned == 0 then
        return
    end
    local curHp = self.curHp
    if curHp <= 0 then
        if curHp + value > 0 then
            --复活
            curHp = curHp + value
            self.curHp = curHp
            self:TestDeath()
        end
    elseif curHp > 0 then
        if curHp + value <= 0 then
            --死亡
            curHp = 0
            self.curHp = curHp
            log_game_debug("Monster:addHp", "value=%d curHp =%d", value, self.curHp)
            self:TestDeath()
        else
            --扣血但没死(可能是加血)
            curHp = curHp + value
            self.curHp = curHp

            if value < 0 then
                self:Think(Mogo.AI.AIEvent.BeHit)
            end

        end
    end

end

function Monster:GetIdleDropEntity(gold, itemTypeId, memberAvatarEid)

    local selfX, selfY = self:getXY()
    local newDrop = self.sp_ref.CliEntityManager:entityFactory()
  		newDrop.eid = self:getNextEntityId()
		newDrop.enterX  = selfX              
		newDrop.enterY  = selfY              
		newDrop.gold    = gold                     
		newDrop.itemId  = itemTypeId                
		newDrop.belongAvatar=memberAvatarEid        	

    self.sp_ref.CliEntityManager:addEntity(cli_entity_config.CLI_ENTITY_TYPE_DROP, newDrop) 
    
    return newDrop
end

function Monster:ProcessDisappear()
    self:Stop()
    g_SrvEntityMgr:Busy2Idle(self)
end

function Monster:IsDeath()
    if self.curHp > 0 then
        return false
    else
        return true
    end
end

function Monster:TestDeath()
    local curHp = self.curHp
    if curHp > 0 then
        self.stateFlag = Bit.Reset(self.stateFlag, state_config.DEATH_STATE)

    else
        self.stateFlag = Bit.Set(self.stateFlag, state_config.DEATH_STATE)
        self.borned = 0
        self.stateFlag = Bit.Set(self.stateFlag, state_config.NO_HIT_STATE)
        self:ProcessDie()
    end
end

function Monster:ResetData()
    self.blackBoard = {testIdle = 1}
    self.battleProps = {} 
end

function Monster:ProcessDie()
    if self.curHp <= 0 then
        
        self:delLocalTimer(self.blackBoard.timeoutId)
        self.blackBoard.timeoutId = 0
        self:delLocalTimer(self.blackBoard.thinkUpdateTimeoutId)
        self.blackBoard.thinkUpdateTimeoutId = 0
        self:delLocalTimer(self.blackBoard.coordUpdateTimeoutId)
        self.blackBoard.coordUpdateTimeoutId = 0

        self:StopMove()
        self.sp_ref:RemoveAliveMonster(self:getId())


        local disappearDelayTime = 0
        local tmpCfgData = g_monster_mgr:getCfgById(self.monsterId)
        if tmpCfgData == nil or tmpCfgData.deadTime < 100 then--小于100毫秒
            disappearDelayTime = 5000
        else
            disappearDelayTime = tmpCfgData.deadTime
        end
        
        self.blackBoard.timeoutId = self:addLocalTimer("ProcessDisappear", disappearDelayTime, 1, {})--怪物延迟消失
        local selfX, selfY = self:getXY()

        --死亡,刷出道具
        local tblEntitiesAvatar = self.sp_ref:GetPlayInfo()
        for dbid, tblAvatar in pairs(tblEntitiesAvatar) do
            local memberAvatarEid = tblAvatar[public_config.PLAYER_INFO_INDEX_EID]
            local memberAvatar = mogo.getEntity(memberAvatarEid)  
            if memberAvatar then
                --memberAvatar:OnKillMonster(self.monsterId)  加rpc方法
                --通知经验增加
                self.sp_ref:AddExp(dbid, self.battleProps.exp)
                --游戏币掉落计算
                local tblSendEid = {}
                local tblDstDropsItem = {} 
                local tblDstMoney = {}     

                g_monster_mgr:getDrop(tblDstDropsItem, tblDstMoney, self.monsterId, memberAvatar.vocation)
                
                for itemId, itemNum in pairs(tblDstDropsItem) do
                    for i=1, itemNum do
                        local dropItem = self:GetIdleDropEntity(0, itemId, memberAvatarEid, spaceLoader, tblParam)
                        if dropItem ~= nil then
                            table.insert(tblSendEid, dropItem.eid)
                        end--if 
                    end
                end--for

                for key, moneyNum in pairs(tblDstMoney) do 
                    local dropGold = self:GetIdleDropEntity(moneyNum, 0, memberAvatarEid, spaceLoader,tblParam)
                    if dropGold ~= nil then
                        table.insert(tblSendEid, dropGold.eid)
                    end--if
                end--for

        		--send awards
		        local sendBuf = {}
        		self.sp_ref.CliEntityManager:pickleEntityBufByTblEid(sendBuf, tblSendEid, cli_entity_config.CLI_ENTITY_TYPE_DROP)
		        memberAvatar:CreateCliEntityResp(sendBuf)
            end--if
        end--for
        
        --通知SpawnPoint做怪物全灭测试
        self.sp_ref:TestSpawnPointMonsterDie(self.spawnPointCfgId)

    end
    
end

---------------------------------------更新begin------------------------------------------------

function Monster:onTimer()
end

function Monster:ProcSkillBuffStopTimer(timerID, activeCount, buffID)
    self.skillSystem.skillBuff:ProcSkillBuffStopTimer(timerID, activeCount, buffID)
end

function Monster:ProcSkillBuffTimer(timerID, activeCount, buffID, skillID)
    self.skillSystem.skillBuff:ProcSkillBuffTimer(timerID, activeCount, buffID, skillID)
end

function Monster:ProcSkillActionTimer(timerID, activeCount, param1, param2)
    self.skillSystem.skillAction:ProcSkillActionTimer(timerID, activeCount, param1, param2)
end

---------------------------------------非AI模块调用AI相关begin------------------------------------------------
function Monster:CanThink()
    
    --技能释放完毕没有？
    if self.borned == 0 then
        return false
    end

    if self.blackBoard.aiState == Mogo.AI.AIState.REST_STATE then
        return false
    end

    if mogo.getTickCount() - self.blackBoard.skillActTime - self.blackBoard.skillActTick < 0 then
        return false
    end
--[[
    local curTime = mogo.getTickCount()
    if self.blackBoard.thinkCDTimeOut > curTime then
        return false
    end

    self.blackBoard.thinkCDTimeOut = curTime + 1000
    --]]
    return true
end

function Monster:ThinkBefore()
--[[
    if self.blackBoard.enemyId ~= nil then
        local enemyEntity = mogo.getEntity(self.blackBoard.enemyId)
        local x2,y2 = enemyEntity:getXY()
        local x1,y1 = self:getXY()
        self:FaceToTarget(x1,y1,x2,y2)
    end
--]]
    self.blackBoard.enemyId = nil
    self.blackBoard.skillActTime = 0
    self.blackBoard.skillActTick = 0

    self.blackBoard.movePoint = nil
--[[
    if self.blackBoard.movePoint ~= nil then
        self:StopMove()
    end
--]]
end

function Monster:Think(event)
    if self:CanThink() == false then
        return
    end
    local tmpAIRoot = g_monster_mgr:getAICfgById(self.ai)
    if not tmpAIRoot then
        return 
    end
    self.blackBoard:ChangeEvent(event)

    self:ThinkBefore()
    tmpAIRoot:Proc(self) 
    self:ThinkAfter()
end

function Monster:ThinkAfter()
    self.blackBoard.isHited = false
end

function Monster:BeHit()
    self.blackBoard.isHited = true
end
---------------------------------------AI内部调用相关begin------------------------------------------------


function Monster:GetEnemyNum()
    local tblEntitiesAvatar = self.sp_ref:GetPlayInfo()
    local aliveNum = 0
    if tblEntitiesAvatar ~= nil then
--        local size = lua_util.get_table_real_count(tblEntitiesAvatar) 测试数量
        for dbid, tblAvatar in pairs(tblEntitiesAvatar) do
            local avatar = mogo.getEntity(tblAvatar[public_config.PLAYER_INFO_INDEX_EID])  
            if avatar and avatar.curHp > 0 then
--                for k,v in pairs(avatar.InSpawnPointCfgId) do
--                    if v == self.spawnPointCfgId then
                        aliveNum = aliveNum + 1
--                        break
--                    end
--                end
            end--if
        end--for
    end--if
    return aliveNum
end

function Monster:GetTeammateNum()
    return 0
end

function Monster:FaceToTarget(x1,y1,x2,y2)
    local face = sectorAngle(x1,y1,x2,y2)
    
    self:setFace(face)
end

function Monster:GetSkillUseCount(skillId)
    local rnt = self.blackBoard.skillUseCount[skillId]    	
    if rnt == nil then
	    return 0	
    else
    	return rnt
    end
end

function Monster:LetSpawnPointStart(spawnPointId)
    self.sp_ref:LetSpawnPointStart(spawnPointId)
end

---------------------------------------AI相关begin------------------------------------------------
function Monster:MoveToCompleteEvent()
    self.blackBoard.movePoint = nil
--    self:Think(Mogo.AI.AIEvent.MoveEnd)
end

function Monster:ProcessAITimerEvent(timer_id, count, arg1, arg2)
    if arg1 == 1 or arg1 == 2 or arg1 == 3 then
        local aiEvent = 0
        if arg1 == 1 then
            aiEvent = Mogo.AI.AIEvent.RestEnd
        elseif arg1 == 2 then
            aiEvent = Mogo.AI.AIEvent.CDEnd
        elseif arg1 == 3 then
            aiEvent = Mogo.AI.AIEvent.Born
        end
        self.blackBoard.timeoutId = 0
        self.blackBoard:ChangeState(Mogo.AI.AIState.THINK_STATE)
        self:Think(aiEvent)
    end
end

function Monster:ProcThink()

    
    ----log_game_info("AI", "ProcThink")
    
    self:Think(Mogo.AI.AIEvent.Self)
    return true
end

function Monster:ProcRest()
    --log_game_info("AI", "ProcRest")
    --用timeout解决(timeout一段时间后再次思考)
    if self.blackBoard.timeoutId ~= 0 then
        self:delLocalTimer(self.blackBoard.timeoutId)
        self.blackBoard.timeoutId = 0
    end

    self.blackBoard:ChangeState(Mogo.AI.AIState.THINK_STATE)
    self.blackBoard.timeoutId = self:addLocalTimer("ProcessAITimerEvent", self.blackBoard.waitSec, 1, 1)
    return true
end

function Monster:ProcAOI()
    local tblEntitiesAvatar = self.sp_ref:GetPlayInfo()
    if tblEntitiesAvatar ~= nil then
        for dbid, tblAvatar in pairs(tblEntitiesAvatar) do
            local avatar = mogo.getEntity(tblAvatar[public_config.PLAYER_INFO_INDEX_EID])  
            if avatar and avatar.curHp > 0 then
--                for k,v in pairs(avatar.InSpawnPointCfgId) do
--                    if v == self.spawnPointCfgId then
                        self.blackBoard.enemyId = tblAvatar[public_config.PLAYER_INFO_INDEX_EID]
--                        --log_game_info("AI", "ProcAOI true")
                        return true
--                    end
--                end
            end--if
        end--for
    end--if
--    --log_game_info("AI", "ProcAOI false") 
    return false
end


function Monster:ProcInSkillRange(skillId)
    
    if self.blackBoard.enemyId ~= nil then
        --计算自己和敌人的距离(未做)
        local rnt = self.skillSystem:IsInSkillRange(self.battleProps.skillBag[skillId], self.blackBoard.enemyId)
        return rnt
    end

    return false
end

function Monster:ProcInSkillCoolDown(skillId)

    local skillData = self.skillSystem:GetSkill(self.battleProps.skillBag[skillId])
    if skillData then
        local ret = self.skillSystem:TestSkill(SKILL_TEST_COLDDOWN, skillData)
        if ret == 0 then
            return true
        else
            return false
        end
    end
    return false
end

function Monster:ProcLastCastIs(skillId)
    if self.blackBoard.lastCastIndex == skillId then
        return true
    else
        return false
    end
end

function Monster:ProcChooseCastPoint(skillId)
        local enemyEntity = mogo.getEntity(self.blackBoard.enemyId)

        local skillRange = self.skillSystem:GetSkillRange(self.battleProps.skillBag[skillId])
        local tarX, tarY = self:getMovePointStraight(self.blackBoard.enemyId, skillRange*0.8)     

        if tarX == nil or tarY == nil then--这里不应该返回nil 否则证明已经到达了施法距离进来此函数是不对的
            local x,y = self:getXY()
            self.blackBoard.movePoint = {x, y}
            return false
        end

        self.blackBoard.movePoint = {tarX, tarY}

    return true
end

function Monster:ProcMoveTo()
    self:ApplyMoveTo()
    return true
end

function Monster:ProcSay(content)
    return true
end

function Monster:ProcCastSpell(skillId, reversal)--reversal暂时没用，前端有用
    --调用使用技能，参数为blackBoard上的spellId
        --log_game_info("AI", "ProcCostSpell me%d other%d", self:getId(), self.blackBoard.enemyId)
        self.blackBoard.movePoint = nil

        local enemyEntity = mogo.getEntity(self.blackBoard.enemyId)
        local x2,y2 = enemyEntity:getXY()
        local x1,y1 = self:getXY()
        self:FaceToTarget(x1,y1,x2,y2)

        self.blackBoard.lastCastIndex = skillId

        local skillData = self.skillSystem:GetSkill(self.battleProps.skillBag[skillId]) 
        if skillData == nil then
            return false --error
        end




        self.blackBoard.skillUseCount[skillId] = self.blackBoard.skillUseCount[skillId] + 1
        self.skillSystem:ExecuteSkill(self.battleProps.skillBag[skillId], {self.blackBoard.enemyId})

        self.blackBoard.skillActTime = self.skillSystem:GetTotalActionDuration(skillData)+1000
        self.blackBoard.skillActTick = mogo.getTickCount()
    return true
end

function Monster:ApplyMoveTo()
    local tarXY = self.blackBoard.movePoint
    if tarXY == nil then
        return true
    end
    
--    self.blackBoard.debugCount = self.blackBoard.debugCount + 1
     
    self:ProcessMove(tarXY[1], tarXY[2])
    return true 
end


function Monster:ProcIsTargetCanBeAttack()
    return true
end

function Monster:ProcEnterCD(sec)
    --log_game_info("AI", "ProcEnterCD")
    --用timeout解决(timeout一段时间后再次思考)
    if self.blackBoard.timeoutId ~= 0 then
        self:delLocalTimer(self.blackBoard.timeoutId)
        self.blackBoard.timeoutId = 0
    end

    self.blackBoard:ChangeState(Mogo.AI.AIState.CD_STATE)
    self.blackBoard.timeoutId = self:addLocalTimer("ProcessAITimerEvent", sec+self.blackBoard.skillActTime + 100, 1, 2)--100毫秒容错
    return true
end

function Monster:ProcEnterRest(sec)
    --log_game_info("AI", "ProcEnterRest")
    --用timeout解决(timeout一段时间后再次思考)
    if self.blackBoard.timeoutId ~= 0 then
        self:delLocalTimer(self.blackBoard.timeoutId)
        self.blackBoard.timeoutId = 0
    end

    self.blackBoard:ChangeState(Mogo.AI.AIState.REST_STATE)
    self.blackBoard.timeoutId = self:addLocalTimer("ProcessAITimerEvent", sec, 1, 1)--100毫秒容错
    return true
end

function Monster:RebornAnimationDelay(timer_id, count, arg1, arg2)
    self.borned = 1
    self.stateFlag = Bit.Reset(self.stateFlag, state_config.NO_HIT_STATE)
    
    if self.blackBoard.timeoutId ~= nil and self.blackBoard.timeoutId > 0 then
        log_game_error("Monster:RebornAnimationDelay","self.blackBoard.timeoutId not nil")
        self:delLocalTimer(self.blackBoard.timeoutId)
        self.blackBoard.timeoutId = 0
    end    

    if self.blackBoard.coordUpdateTimeoutId ~= nil and self.blackBoard.coordUpdateTimeoutId > 0 then
        log_game_error("Monster:RebornAnimationDelay","self.blackBoard.coordUpdateTimeoutId not nil") 
        self:delLocalTimer(self.blackBoard.coordUpdateTimeoutId) 
        self.blackBoard.coordUpdateTimeoutId = 0
    end

    if self.blackBoard.thinkUpdateTimeoutId ~= nil and self.blackBoard.thinkUpdateTimeoutId>0 then
        log_game_error("Monster:RebornAnimationDelay","self.blackBoard.thinkUpdateTimeoutId not nil")
        self:delLocalTimer(self.blackBoard.thinkUpdateTimeoutId)
        self.blackBoard.thinkUpdateTimeoutId = 0
    end

    self.blackBoard.coordUpdateTimeoutId = self:addLocalTimer("UpdateCoord", 100, 0) 
    self.blackBoard.thinkUpdateTimeoutId = self:addLocalTimer("UpdateThink", 1000, 0) 
end

function Monster:UpdateThink(timer_id, count, arg1, arg2)
    local testIdleFlag = self:TestIdle("Monster:UpdateThink self.blackBoard.testIdle not nil")
    if testIdleFlag == true then
        return
    end

    self:Think(Mogo.AI.AIEvent.AvatarPosSync)    
end

function Monster:UpdateCoord(timer_id, count, arg1, arg2)  
    local testIdleFlag = self:TestIdle("Monster:UpdateCoord self.blackBoard.testIdle not nil")
    if testIdleFlag == true then
        return
    end

    if self.blackBoard.movePoint == nil then
        return
    end
    local rnt = self:updateEntityMove(self.blackBoard.movePoint[1], self.blackBoard.movePoint[2])--, needSync
    if rnt == 0 then
        self:MoveToCompleteEvent()
    end
end


function Monster:ProcReinitLastCast()
    self.blackBoard.lastCastIndex = 0
end

function Monster:AvatarMove()
end

function Monster:ProcTowerDefenseMonsterAOI()
    --find crystal and mark it
    if self.blackBoard.towerDefennseCrystalEid == nil then
        local tblAliveMonster = self.sp_ref.AliveMonster
        if tblAliveMonster == nil then
            return false
        end
        for eid, v in pairs(tblAliveMonster) do
            local monsterEntity = mogo.getEntity(eid)
            if monsterEntity and monsterEntity.factionFlag ~= 0 and monsterEntity.curHp > 0 then
            
                --is Crystal not die
                self.blackBoard.towerDefennseCrystalEid = eid
            end--if
        end--for
    end--if

    --select crystal , if in skillrange then select it
    if self.blackBoard.towerDefennseCrystalEid ~= nil then
        local monsterEntity = mogo.getEntity(self.blackBoard.towerDefennseCrystalEid)
        if monsterEntity and monsterEntity.factionFlag ~= 0 then
            if monsterEntity.curHp > 0 then
                self.blackBoard.enemyId = self.blackBoard.towerDefennseCrystalEid
                local rnt = self.skillSystem:IsInSkillRange(self.battleProps.skillBag[1], self.blackBoard.towerDefennseCrystalEid)
                if rnt == true then
                    return true
                end 
            elseif monsterEntity.curHp <= 0 then
                --crystal was die stop
                return false
            end
        end
    end

    --select player becase crystal is not in skillrange
    local tblEntitiesAvatar = self.sp_ref:GetPlayInfo()
    if tblEntitiesAvatar ~= nil then
        for dbid, tblAvatar in pairs(tblEntitiesAvatar) do
            local avatar = mogo.getEntity(tblAvatar[public_config.PLAYER_INFO_INDEX_EID])  
            if avatar and avatar.curHp > 0 then
                local rnt = self.skillSystem:IsInSkillRange(self.battleProps.skillBag[1], avatar:getId())
                if rnt == true then
                    self.blackBoard.enemyId = tblAvatar[public_config.PLAYER_INFO_INDEX_EID]
                    return true
                end
            end--if
        end--for
    end--if

    return self.blackBoard.enemyId ~= nil
end
---------------------------------------AI end------------------------------------------------
function Monster:TestIdle(log)
    if self.blackBoard.testIdle ~= nil then
        log_game_error("Monster:TestIdle", log)        
        return true
    end
    return false
end
return Monster


