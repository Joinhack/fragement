--local p = {}
--setmetatable(p, {__index = _G})
--setfenv(1, p)

require "lua_util"
local log_game_info = lua_util.log_game_info

--随机数初始化，去除前面几个
math.randomseed(os.time())
local len = math.random(0, 100)
for _i = 1, len, 1 do
    math.random(0, 100)
end

local Mogo = require "BTNode"

local CmpType = {lt = 1,
                        le = 2,
                        eq = 3,
                        ge = 4,
                        gt = 5,
                    }
                    
local function Cmp(cmp, lv, rv)
        if cmp == CmpType.lt then
                do return lv < rv end
        elseif cmp == CmpType.le then
                do return lv <= rv end
        elseif cmp == CmpType.eq then
                do return lv == rv end
        elseif cmp == CmpType.ge then
                do return lv >= rv end
        elseif cmp == CmpType.gt then
                do return lv > rv end
        else
                do return false end
        end
end

---------------------------
local ISMoveEnd = Mogo.AI.ConditionNode:new()

function ISMoveEnd:new()
        local tmp = {}
        setmetatable(tmp, {__index = IsMoveEnd})
        tmp.__index = tmp
        return tmp
end

function ISMoveEnd:Proc(entity)

         --log_game_info('AI','ISMoveEnd')

        return true
end

-------------------------
local ISEscapeHP = Mogo.AI.ConditionNode:new()

function ISEscapeHP:new(escapeHP)
        local tmp = {}
        setmetatable(tmp, {__index = ISEscapeHP})
        tmp.__index = tmp
        tmp.escapeHP = escapeHP
        return tmp
end

function ISEscapeHP:Proc(entity)

         --log_game_info('AI','ISEscapeHP')

        return entity.HP <= self.escapeHP
end

------------------------
local ISIdle = Mogo.AI.ConditionNode:new()

function ISIdle:new()
        local tmp = {}
        setmetatable(tmp, {__index = ISIdle})
        tmp.__index = tmp
        return tmp
end

function ISIdle:Proc(entity)
        ---没有状态机了，是不是要去掉

         --log_game_info('AI','ISIdle')

        return true
end

------------------------
local ISThink = Mogo.AI.ConditionNode:new()

function ISThink:new()
        local tmp = {}
        setmetatable(tmp, {__index = ISThink})
        tmp.__index = tmp
        return tmp
end

function ISThink:Proc(entity)

         --log_game_info('AI','ISThink')

        return entity.blackBoard.aiState == Mogo.AI.AIState.THINK_STATE
end

--------------------------
local ISHited = Mogo.AI.ConditionNode:new()

function ISHited:new()
        local tmp = {}
        setmetatable(tmp, {__index = ISHited})
        tmp.__index = tmp
        return tmp
end

function ISHited:Proc(entity)

         --log_game_info('AI','ISHited')

        if entity.blackBoard.isHited == true then
--            --log_game_info('AI','ISHited true')
        else
 --           --log_game_info('AI','ISHited false')
        end
        return entity.blackBoard.isHited
end

--------------------------
local ISEscapeState = Mogo.AI.ConditionNode:new()

function ISEscapeState:new()
        local tmp = {}
        setmetatable(tmp, {__index = ISEscapeState})
        tmp.__index = tmp
        return tmp
end

function ISEscapeState:Proc(entity)

         --log_game_info('AI','ISEscapeState')

        return entity.blackBoard.aiState == Mogo.AI.AIState.ESCAPE_STATE
end

------------------------
local ISFightState = Mogo.AI.ConditionNode:new()

function ISFightState:new()
        local tmp = {}
        setmetatable(tmp, {__index = ISFightState})
        tmp.__index = tmp
        return tmp
end

function ISFightState:Proc(entity)

         --log_game_info('AI','ISFightState')

        return entity.blackBoard.aiState == Mogo.AI.AIState.FIGHT_STATE
end

-------------------------
local ISPatrolState = Mogo.AI.ConditionNode:new()

function ISPatrolState:new()
        local tmp = {}
        setmetatable(tmp, {__index = ISPatrolState})
        tmp.__index = tmp
        return tmp
end

function ISPatrolState:Proc(entity)

         --log_game_info('AI','ISPatrolState')

        return entity.blackBoard.aiState == Mogo.AI.AIState.PATROL_STATE
end

------------------------
local HasMovePoint = Mogo.AI.ConditionNode:new()

function HasMovePoint:new()
        local tmp = {}
        setmetatable(tmp, {__index = HasMovePoint})
        tmp.__index = tmp
        return tmp
end

function HasMovePoint:Proc(entity)

         --log_game_info('AI','HasMovePoint')

--       return entity.blackBoard.hasMovePoint
        return entity.blackBoard.movePoint ~= nil
end

-------------------------
local HasFightTarget = Mogo.AI.ConditionNode:new()

function HasFightTarget:new()
        local tmp = {}
        setmetatable(tmp, {__index = HasFightTarget})
        tmp.__index = tmp
        return tmp
end

function HasFightTarget:Proc(entity)

         --log_game_info('AI','HasFightTarget')

        if entity.blackBoard.enemyId ~= nil then
            --log_game_info('AI','HasFightTarget true')
        else
            --log_game_info('AI','HasFightTarget false')
        end
        return entity.blackBoard.enemyId ~= nil
end

------------------------
local InSkillRange = Mogo.AI.ConditionNode:new()

function InSkillRange:new(skillId)
        local tmp = {_skillId = skillId}
        setmetatable(tmp, {__index = InSkillRange})
        tmp.__index = tmp
        return tmp
end

function InSkillRange:Proc(entity)
        --计算自己和敌人的距离
        local rnt = entity:ProcInSkillRange(self._skillId)
        if rnt == true then
            --log_game_info('AI','InSkillRange true') 
        else
            --log_game_info('AI','InSkillRange false')
        end
        return rnt
end

--------------------------
local InSkillCoolDown = Mogo.AI.ConditionNode:new()

function InSkillCoolDown:new(skillId)
        local tmp = {_skillId = skillId}
        setmetatable(tmp, {__index = InSkillCoolDown})
        tmp.__index = tmp
        return tmp
end

function InSkillCoolDown:Proc(entity)
        --计算自己和敌人的距离
        local rnt = entity:ProcInSkillCoolDown(self._skillId)
        if rnt == true then
            --log_game_info('AI','InSkillCoolDown %d true', self._skillId) 
        else
            --log_game_info('AI','InSkillCoolDown %d false', self._skillId)
        end
        return rnt
end

--------------------------
local LastCastIs = Mogo.AI.ConditionNode:new()

function LastCastIs:new(skillId)
        local tmp = {_skillId = skillId}
        setmetatable(tmp, {__index = LastCastIs})
        tmp.__index = tmp
        return tmp
end

function LastCastIs:Proc(entity)
        --计算自己和敌人的距离
        local rnt = entity:ProcLastCastIs(self._skillId)
        if rnt == true then
            --log_game_info('AI','LastCastIs %d true', self._skillId) 
        else
            --log_game_info('AI','LastCastIs %d false', self._skillId)
        end
        return rnt
end

--------------------------

local ISRest = Mogo.AI.ConditionNode:new()

function ISRest:new()
        local tmp = {}
        setmetatable(tmp, {__index = ISRest})
        tmp.__index = tmp
        return tmp
end

function ISRest:Proc(entity)
        if entity.blackBoard.aiState == Mogo.AI.AIState.REST_STATE then
            --log_game_info('AI','ISRest true')
            return true
        else
            --log_game_info('AI','ISRest false')
            return false
        end
--        return entity.blackBoard.aiState == Mogo.AI.AIState.REST_STATE
end

-----------------------
local ISCD = Mogo.AI.ConditionNode:new()

function ISCD:new()
        local tmp = {}
        setmetatable(tmp, {__index = ISCD})
        tmp.__index = tmp
        return tmp
end

function ISCD:Proc(entity)
        if entity.blackBoard.aiState == Mogo.AI.AIState.CD_STATE then
            --log_game_info('AI','ISCD true')
            return true
        else
            --log_game_info('AI','ISCD false')
            return false
        end
 --       return entity.blackBoard.aiState == Mogo.AI.AIState.CD_STATE
end

-----------------------
local IsEventMoveEnd = Mogo.AI.ConditionNode:new()

function IsEventMoveEnd:new()
        local tmp = {}
        setmetatable(tmp, {__index = IsEventMoveEnd})
        tmp.__index = tmp
        return tmp
end

function IsEventMoveEnd:Proc(entity)
    if entity.blackBoard.aiEvent == Mogo.AI.AIEvent.MoveEnd then
        --log_game_info('AI','IsEventMoveEnd true')
        return true
    else
        --log_game_info('AI','IsEventMoveEnd false')
        return false
    end
end
-----------------------
local IsEventBorn = Mogo.AI.ConditionNode:new()

function IsEventBorn:new()
        local tmp = {}
        setmetatable(tmp, {__index = IsEventBorn})
        tmp.__index = tmp
        return tmp
end

function IsEventBorn:Proc(entity)
    if entity.blackBoard.aiEvent == Mogo.AI.AIEvent.Born then
        --log_game_info('AI','IsEventBorn true')
        return true
    else
        --log_game_info('AI','IsEventBorn false')
        return false
    end
end
-----------------------
local IsEventAvatarDie = Mogo.AI.ConditionNode:new()

function IsEventAvatarDie:new()
        local tmp = {}
        setmetatable(tmp, {__index = IsEventAvatarDie})
        tmp.__index = tmp
        return tmp
end

function IsEventAvatarDie:Proc(entity)
    if entity.blackBoard.aiEvent == Mogo.AI.AIEvent.AvatarDie then
        --log_game_info('AI','IsEventAvatarDie true')
        return true
    else
        --log_game_info('AI','IsEventAvatarDie false')
        return false
    end
end
-----------------------
local IsEventCDEnd = Mogo.AI.ConditionNode:new()

function IsEventCDEnd:new()
        local tmp = {}
        setmetatable(tmp, {__index = IsEventCDEnd})
        tmp.__index = tmp
        return tmp
end

function IsEventCDEnd:Proc(entity)
    if entity.blackBoard.aiEvent == Mogo.AI.AIEvent.CDEnd then
        --log_game_info('AI','IsEventCDEnd true')
        return true
    else
        --log_game_info('AI','IsEventCDEnd false')
        return false
    end
end
-----------------------
local IsEventRestEnd = Mogo.AI.ConditionNode:new()

function IsEventRestEnd:new()
        local tmp = {}
        setmetatable(tmp, {__index = IsEventRestEnd})
        tmp.__index = tmp
        return tmp
end

function IsEventRestEnd:Proc(entity)
    if entity.blackBoard.aiEvent == Mogo.AI.AIEvent.RestEnd then
        --log_game_info('AI','IsEventRestEnd true')
        return true
    else
        --log_game_info('AI','IsEventRestEnd false')
        return false
    end
end
-----------------------
local IsEventBeHit = Mogo.AI.ConditionNode:new()

function IsEventBeHit:new()
        local tmp = {}
        setmetatable(tmp, {__index = IsEventBeHit})
        tmp.__index = tmp
        return tmp
end

function IsEventBeHit:Proc(entity)
    if entity.blackBoard.aiEvent == Mogo.AI.AIEvent.BeHit then
        --log_game_info('AI','IsEventBeHit true')
        return true
    else
        --log_game_info('AI','IsEventBeHit false')
        return false
    end
end
-----------------------
local IsEventAvatarPosSync = Mogo.AI.ConditionNode:new()

function IsEventAvatarPosSync:new()
        local tmp = {}
        setmetatable(tmp, {__index = IsEventAvatarPosSync})
        tmp.__index = tmp
        return tmp
end

function IsEventAvatarPosSync:Proc(entity)
    if entity.blackBoard.aiEvent == Mogo.AI.AIEvent.AvatarPosSync then
        --log_game_info('AI','IsEventAvatarPosSync true')
        return true
    else
        --log_game_info('AI','IsEventAvatarPosSync false')
        return false
    end
end
-----------------------
local NoEnemys = Mogo.AI.ConditionNode:new()

function NoEnemys:new()
        local tmp = {}
        setmetatable(tmp, {__index = NoEnemys})
        tmp.__index = tmp
        return tmp
end

function NoEnemys:Proc(entity)

         --log_game_info('AI','NoEnemys')

        --此节点可不用，用比较敌人数量节点代替会更灵活
        return entity.blackBoard.noEnemy
end

----------------------
local CmpRate = Mogo.AI.ConditionNode:new()

function CmpRate:new(cmp, rate)
        local tmp = {_cmp = cmp, _rate = rate}
        setmetatable(tmp, {__index = CmpRate})
        tmp.__index = tmp
        return tmp
end

function CmpRate:Proc(entity)

         --log_game_info('AI','CmpRate')

        local rate = math.random(0, 100)
        local rst = Cmp(self._cmp, rate, self._rate)
        return rst
end

------------------------
local CmpSelfHP = Mogo.AI.ConditionNode:new()

function CmpSelfHP:new(cmp, percent)
        local tmp = {_cmp = cmp, _percent = percent}
        setmetatable(tmp, {__index = CmpSelfHP})
        tmp.__index = tmp
        return tmp
end

function CmpSelfHP:Proc(entity)

         --log_game_info('AI','CmpSelfHP')

        local percent = (entity.curHp / entity.hp) * 100
        local rst = Cmp(self._cmp, percent, self._percent)
        return rst
end

-------------------------
local CmpEnemyHP = Mogo.AI.ConditionNode:new()

function CmpEnemyHP:new(cmp, percent)
        local tmp = {_cmp = cmp, _percent = percent}
        setmetatable(tmp, {__index = CmpEnemyHP})
        tmp.__index = tmp
        return tmp
end

function CmpEnemyHP:Proc(entity)

         --log_game_info('AI','CmpEnemyHP')

        local enemyEntity = mogo.getEntity(entity.blackBoard.enemyId)
        if enemyEntity == nil then
            return false
        end
        local percent = enemyEntity.hp/enemyEntity.maxHp --根据enemyId计算敌人血量
        local rst = Cmp(self._cmp, percent, self._percent)
        return rst
end

--------------------------
local CmpTeammateNum = Mogo.AI.ConditionNode:new()

function CmpTeammateNum:new(cmp, num)
        local tmp = {_cmp = cmp, _num = num}
        setmetatable(tmp, {__index = CmpTeammateNum})
        tmp.__index = tmp
        return tmp
end

function CmpTeammateNum:Proc(entity)

         --log_game_info('AI','CmpTeammateNum')

        local num = entity:GetTeammateNum() --队友数量
        local rst = Cmp(self._cmp, num, self._num)
        return rst
end

---------------------------
local CmpEnemyNum = Mogo.AI.ConditionNode:new()

function CmpEnemyNum:new(cmp, num)
        local tmp = {_cmp = cmp, _num = num}
        setmetatable(tmp, {__index = CmpEnemyNum})
        tmp.__index = tmp
        return tmp
end

function CmpEnemyNum:Proc(entity)
        local num = entity:GetEnemyNum() --敌人数量
        local rst = Cmp(self._cmp, num, self._num)

        if rst == false then

--            --log_game_info('AI','CmpEnemyNum=false')

        else

--            --log_game_info('AI','CmpEnemyNum=true') 

        end
        return rst
end
---------------------------
local IsTargetCanBeAttack = Mogo.AI.ConditionNode:new()   

function IsTargetCanBeAttack:new()
        local tmp = {}
        setmetatable(tmp, {__index = IsTargetCanBeAttack})
        tmp.__index = tmp
        return tmp
end

function IsTargetCanBeAttack:Proc(entity)

         --log_game_info('AI','IsTargetCanBeAttack')

        local rnt = entity:ProcIsTargetCanBeAttack()
        return rnt
end

------------------------
local CmpSkillUseCount = Mogo.AI.ConditionNode:new()

function CmpSkillUseCount:new(skillId, cmp, useCount)
        local tmp = {_skillId = skillId, _cmp = cmp, _useCount = useCount}
        setmetatable(tmp, {__index = CmpSkillUseCount})
        tmp.__index = tmp
        return tmp
end

function CmpSkillUseCount:Proc(entity)

         --log_game_info('AI','CmpSkillUseCount')

        local tmpSkillUseCount = entity:GetSkillUseCount(self._skillId)
        local rst = Cmp(self._cmp, tmpSkillUseCount, self._useCount)
        return rst
end

--------------------------
local LastLookOnModeIs = Mogo.AI.ConditionNode:new()

function LastLookOnModeIs:new(lookOnMode)
        local tmp = {_lookOnMode = lookOnMode}
        setmetatable(tmp, {__index = LastLookOnModeIs})
        tmp.__index = tmp
        return tmp
end

function LastLookOnModeIs:Proc(entity)
        --计算自己和敌人的距离
        return false
end

--------------------------
local TowerDefenseMonsterAOI = Mogo.AI.ConditionNode:new()

function TowerDefenseMonsterAOI:new()
        local tmp = {}
        setmetatable(tmp, {__index = TowerDefenseMonsterAOI})
        tmp.__index = tmp
        return tmp
end

function TowerDefenseMonsterAOI:Proc(entity)
        local rnt = entity:ProcTowerDefenseMonsterAOI()
        return rnt
end


Mogo.AI.CmpType = CmpType
Mogo.AI.CmpEnemyHP = CmpEnemyHP
Mogo.AI.CmpEnemyNum = CmpEnemyNum
Mogo.AI.CmpRate = CmpRate
Mogo.AI.CmpSelfHP = CmpSelfHP
Mogo.AI.CmpTeammateNum = CmpTeammateNum
Mogo.AI.HasFightTarget = HasFightTarget
Mogo.AI.HasMovePoint = HasMovePoint
Mogo.AI.InSkillRange = InSkillRange
Mogo.AI.InSkillCoolDown = InSkillCoolDown
Mogo.AI.LastCastIs = LastCastIs
Mogo.AI.ISEscapeHP = ISEscapeHP
Mogo.AI.ISEscapeState = ISEscapeState
Mogo.AI.ISFightState = ISFightState
Mogo.AI.ISHited = ISHited
Mogo.AI.ISIdle = ISIdle
Mogo.AI.ISMoveEnd = ISMoveEnd
Mogo.AI.ISPatrolState = ISPatrolState
Mogo.AI.ISThink = ISThink
Mogo.AI.ISRest = ISRest
Mogo.AI.ISCD = ISCD
Mogo.AI.NoEnemys = NoEnemys
Mogo.AI.IsTargetCanBeAttack = IsTargetCanBeAttack
Mogo.AI.IsEventMoveEnd = IsEventMoveEnd
Mogo.AI.IsEventBorn = IsEventBorn
Mogo.AI.IsEventAvatarDie = IsEventAvatarDie
Mogo.AI.IsEventCDEnd = IsEventCDEnd
Mogo.AI.IsEventRestEnd = IsEventRestEnd
Mogo.AI.IsEventBeHit = IsEventBeHit
Mogo.AI.IsEventAvatarPosSync = IsEventAvatarPosSync
Mogo.AI.CmpSkillUseCount = CmpSkillUseCount
Mogo.AI.LastLookOnModeIs = LastLookOnModeIs
Mogo.AI.TowerDefenseMonsterAOI = TowerDefenseMonsterAOI
