-- Create by Kevinhua
-- Modifed by Kevinhua
-- User: Administrator
-- Date: 13-3-19
-- Time: 15:55
-- 助阵佣兵.
--


local public_config = require "public_config"
require "lua_util"
require "error_code"
require "SpaceThing"
require "SkillSystem"
require "monster_data"
require "state_config"
require "SrvEntityManager"

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error

local sectorAngle = lua_util.sectorAngle
local math_sqrt = math.sqrt
local math_floor = math.floor


------------------------------------------------------------------------------------------------
Mercenary = {}
setmetatable(Mercenary, SpaceThing)
SpaceThing.__index = SpaceThing
------------------------------------------------------------------------------------------------


function Mercenary:__ctor__()
    self.c_etype = public_config.ENTITY_TYPE_MERCENARY

    self.skillSystem = SkillSystem:New(self)

end

function Mercenary:onEnterSpace()

    local sp = g_these_spaceloaders[self:getSpaceId()] 
    if sp then
        self.sp_ref = sp 
    end
    

end

function Mercenary:onDestroy()
    log_game_debug("Mercenary:onDestroy", "id=%d", self:getId())

    --注销技能系统
    self.skillSystem:Del()
end

function Mercenary:StartMercenary()
    self.stateFlag = Bit.Reset(self.stateFlag, state_config.DEATH_STATE)
    self.borned = 0
    self.stateFlag = Bit.Set(self.stateFlag, state_config.NO_HIT_STATE)
    self.sp_ref:InsertAliveMonster(self:getId()) 

    self.blackBoard = Mogo.AI.BlackBoard:new()

    local avatarOwner = mogo.getEntity(self.ownerEid)
    if avatarOwner then
        self.factionFlag = avatarOwner.factionFlag
    else
        self.factionFlag = 0
    end

    local time = math.random(1, 1000)
    
    self:addLocalTimer("ProcessAppear", time, 1, {bornDelayTime = 0})
end

function Mercenary:Start(cfgData)
    local tmpCfgData = cfgData
    if tmpCfgData == nil then
        return false
    end
    
    log_game_debug('Mercenary:Start', 'monsterId:%d  hp:%d spaceId:%d', self.monsterId, self.battleProps.hp, self.sp_ref:getSpaceId())
-- 
-- self:ProcessBattleProperties(tmpCfgData)
   -- self.curHp = self.battleProps.hp
    self.stateFlag = Bit.Reset(self.stateFlag, state_config.DEATH_STATE)
    self.borned = 0
    self.stateFlag = Bit.Set(self.stateFlag, state_config.NO_HIT_STATE)
    if tmpCfgData.showHitAct ~= nil and tmpCfgData.showHitAct > 0 then
    	self.stateFlag = Bit.Set(self.stateFlag, state_config.BATI_STATE)
    end
    self.sp_ref:InsertAliveMonster(self:getId())

    self.blackBoard = Mogo.AI.BlackBoard:new()
    
    self.factionFlag = 0

    local time = math.random(1, 1000)

    self:addLocalTimer("ProcessAppear", time, 1, {bornDelayTime = tmpCfgData.bornTime})
end

function Mercenary:ProcessAppear(timer_id, count, arg1, arg2)
   
    self:addLocalTimer("RebornAnimationDelay", arg1.bornDelayTime+1000, 1)
    self:setVisiable(1)--出现
        

    return true
end




function Mercenary:Stop()
    if self.blackBoard.timeoutId ~= nil and self.blackBoard.timeoutId > 0 then            
        self:delLocalTimer(self.blackBoard.timeoutId)
    end                                              
    
    self:ResetData()
end

function Mercenary:GetScaleRadius()
    if not self.battleProps.scaleRadius then
        return 100
    else
        return self.battleProps.scaleRadius
    end
end

---------------------------------------属性begin----------------------------------------------

function Mercenary:ProcessBattleProperties(cfgProps)
    self.battleProps.exp = cfgProps.exp
    self.battleProps.model = cfgProps.model
    self.battleProps.speed = cfgProps.speed
    self.battleProps.scaleRadius = cfgProps.scaleRadius
    
    self.battleProps.hpBase = cfgProps.hpBase
    self.battleProps.hp = self.battleProps.hpBase
    self.battleProps.attackBase = cfgProps.attackBase
    self.battleProps.atk = cfgProps.attackBase
    self.battleProps.def = 0

    self.battleProps.hitRate = cfgProps.extraHitRate*0.0001            
    self.battleProps.critRate = cfgProps.extraCritRate*0.0001          
    self.battleProps.trueStrikeRate = cfgProps.extraTrueStrikeRate*0.0001
    self.battleProps.antiDefenseRate = cfgProps.extraAntiDefenceRate*0.0001
    self.battleProps.defenceRate = cfgProps.extraDefenceRate*0.0001   
    self.battleProps.missRate = cfgProps.missRate*0.0001
    self.battleProps.damageReduceRate = cfgProps.damageReduceRate*0.0001
    
    self.curHp = self.battleProps.hp   
 
    self.level = cfgProps.level 

    --怪物的技能表
    self.battleProps.skillBag = cfgProps.skillIds

    if #self.battleProps.skillBag <= 0 then
        log_game_debug("Mercenary skillBag", "size<=0") 
    end
    --技能buff提供的属性加成
--    self.skillSystem.skillBuff:UpdateAttrEffectTo(self.battleProps)
    
    self:setSpeed(self.battleProps.speed/10)  --通知引擎
    self.speed = self.battleProps.speed/100
end

function Mercenary:addHp(value)
    value = math.ceil(value)
    
    if self.borned == 0 then
        return
    end
    local curHp = self.curHp
    if curHp <= 0 then
        if value > 0 then
            --复活
            curHp = value
            self.curHp = curHp
            self:TestDeath()
        end
    elseif curHp > 0 then
        if curHp + value <= 0 then
            --死亡
            curHp = 0
            self.curHp = curHp
            log_game_debug("Mercenary:addHp", "value=%d curHp =%d", value, self.curHp)
            self:TestDeath()
        else
            --扣血但没死(可能是加血)
            curHp = curHp + value
            self.curHp = curHp

        end
    end

end



function Mercenary:GetIdleDropEntity(gold, itemTypeId, memberAvatarEid)

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

function Mercenary:ProcessDisappear()
    self:Stop()
    g_SrvEntityMgr:Busy2Idle(self)
end

function Mercenary:IsDeath()
    if self.curHp > 0 then
        return false
    else
        return true
    end
end

function Mercenary:TestDeath()
    local curHp = self.curHp
    if curHp > 0 then
        self.stateFlag = Bit.Reset(self.stateFlag, state_config.DEATH_STATE)
        self.borned = 1
        self.stateFlag = Bit.Reset(self.stateFlag, state_config.NO_HIT_STATE)
    else
        self.stateFlag = Bit.Set(self.stateFlag, state_config.DEATH_STATE)
        self.borned = 0
        self.stateFlag = Bit.Set(self.stateFlag, state_config.NO_HIT_STATE)
        self:ProcessDie()
        
    end
end

function Mercenary:ResetData()
    self.blackBoard = {}
    self.battleProps = {}
    self.skillBag = {}
end

function Mercenary:ProcessDie()
    if self.curHp > 0 then
        do return end
    end
    
    if self.isPVP > 0 then
        self.sp_ref:DeathEvent(self.avatarDbid)
    end

    
    if self.factionFlag > 0 then--替换
        --雇佣兵
        
        if self.blackBoard.timeoutId ~= nil and self.blackBoard.timeoutId > 0 then
            self:delLocalTimer(self.blackBoard.timeoutId)
        end
        self.blackBoard.timeoutId = self:addLocalTimer("ProcessReborn", 15000, 1, {})--延迟重生
    else
        --怪物
        self.sp_ref:RemoveAliveMonster(self:getId())

        local disappearDelayTime = 0
        local tmpCfgData = g_monster_mgr:getCfgById(self.monsterId, self.difficulty)
        if tmpCfgData == nil or tmpCfgData.deadTime < 100 then--小于100毫秒
            disappearDelayTime = 5000
        else
            disappearDelayTime = tmpCfgData.deadTime
        end
        
        if self.blackBoard.timeoutId ~= nil and self.blackBoard.timeoutId > 0 then
            self:delLocalTimer(self.blackBoard.timeoutId)
        end
        self.blackBoard.timeoutId = self:addLocalTimer("ProcessDisappear", disappearDelayTime, 1, {})--怪物延迟消失
        local selfX, selfY = self:getXY()
        

        local tblEntitiesAvatar = self.sp_ref:GetPlayInfo()
        for dbid, tblAvatar in pairs(tblEntitiesAvatar) do
            local memberAvatarEid = tblAvatar[public_config.PLAYER_INFO_INDEX_EID]
            local memberAvatar = mogo.getEntity(memberAvatarEid)  
            if memberAvatar then
                --memberAvatar:OnKillMonster(self.monsterId) rpc方法
                --通知经验增加
                self.sp_ref:AddExp(dbid, self.battleProps.exp)
                --游戏币掉落计算
                local tblSendEid = {}
                local tblDstDropsItem = {} 
                local tblDstMoney = {}
        
                g_monster_mgr:getDrop(tblDstDropsItem, tblDstMoney, self.monsterId, memberAvatar.vocation, self.difficulty)
                
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

function Mercenary:LetSpawnPointStart(spawnPointId)
    self.sp_ref:LetSpawnPointStart(spawnPointId)
end

---------------------------------------更新begin------------------------------------------------

function Mercenary:ProcSkillBuffStopTimer(timerID, activeCount, buffID)
    self.skillSystem.skillBuff:ProcSkillBuffStopTimer(timerID, activeCount, buffID)
end

function Mercenary:ProcSkillBuffTimer(timerID, activeCount, buffID, skillID)
    self.skillSystem.skillBuff:ProcSkillBuffTimer(timerID, activeCount, buffID, skillID)
end

function Mercenary:ProcSkillActionTimer(timerID, activeCount, param1, param2)
    self.skillSystem.skillAction:ProcSkillActionTimer(timerID, activeCount, param1, param2)
end

function Mercenary:GetOwnerId()
	if self.ownerEid then
		return self.ownerEid
	end
	
	return nil
end

function Mercenary:OwnerDie()
    self.curHp = 0
    self.stateFlag = Bit.Set(self.stateFlag, state_config.DEATH_STATE)
    self.borned = 0
    self.stateFlag = Bit.Set(self.stateFlag, state_config.NO_HIT_STATE)
end

function Mercenary:OwnerRevive()
    self:addHp(self.hp) 
end

function Mercenary:RebornAnimationDelay(timer_id, count, arg1, arg2)
    self.borned = 1
    self.stateFlag = Bit.Reset(self.stateFlag, state_config.NO_HIT_STATE)
end

function Mercenary:ProcessReborn()
    self.borned = 1
    self:addHp(self.hp)
end

function Mercenary:AvatarMove()
end

return Mercenary


