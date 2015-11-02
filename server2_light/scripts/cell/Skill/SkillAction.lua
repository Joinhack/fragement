-- 技能行为

require "SkillCalculate"
require "lua_util"
require "lua_map"
require "channel_config"
require "public_config"
require "state_config"
require "action_config"
require "GlobalParams"
require "monster_data"


local function DebugOutput(head, pattern, ...)
    local log_to_console = false
    if log_to_console == true then
        print(string.format("[%s]%s", head, string.format(pattern, ...)))
    else
        --lua_util.log_game_debug(head, pattern, ...)
    end
end


local log_game_info             = lua_util.log_game_info
local log_game_debug            = DebugOutput
local confirm                   = lua_util.confirm
local _readXml                  = lua_util._readXml
local debug_show_text           = false
local skill_action_data         = {}


--消息提示，对应ChineseData.xml表定义
local TEXT_ACTION_UNKNOWN           = 1003001       --未知的技能行为错误
local TEXT_ACTION_NOT_EXIST         = 1003002       --技能行为不存在
local TEXT_ACTION_CASTER_DEATH      = 1003003       --执行者已死亡
local TEXT_ACTION_NOT_EXECUTE       = 1003004       --技能行为无需执行
local TEXT_ACTION_NO_TARGETS        = 1003005       --没找到有效的目标
local TEXT_ACTION_NOT_IN_AREA       = 1003006       --目标不在范围内
local TEXT_ACTION_FIND_NO_TARGETS   = 1003007       --找不到目标
local TEXT_ACTION_NO_HIT_STATE      = 1003008       --不可攻击状态
local TEXT_ACTION_NOT_IN_AOI        = 1003009       --不在AOI范围内


--技能行为测试模式
ACTION_TEST_NEED_EXECUTE      = 1             --检查技能行为是否需要执行实现
ACTION_TEST_CASTER_DEATH      = 2             --检查施法者死亡状态
ACTION_TEST_TARGET_DEATH      = 3             --检查目标死亡状态
ACTION_TEST_TARGET_IN_AREA    = 4             --检查目标是否在目标范围内
ACTION_TEST_CAN_HIT_STATE     = 5             --检查是否可攻击状态
ACTION_TEST_IN_AOI            = 6             --检查是否在AOI内

--目标范围
local TARGET_RANGE =
{
    SECTOR          = 0,    --扇形范围
    ROUND           = 1,    --圆形范围
    SINGLE          = 2,    --单体范围
    LINE            = 3,    --直线范围
    FACE            = 4,    --面向（前方）范围
    FRONT_ROUND     = 5,    --前方一段距离的圆形范围
    WORLD_RECT      = 6,    --世界矩形坐标
}


SkillAction = {}
SkillAction.__index = SkillAction


function SkillAction:InitData()
    skill_action_data = _readXml('/data/xml/SkillAction.xml', 'id_i')
    if skill_action_data then
        for k, v in pairs(skill_action_data) do
            confirm(k >= 1 and k <= 65535, "技能行为索引ID越界[id=%d]", k);

            local actionData = v
            if not actionData.maxTargetCount then actionData.maxTargetCount = 0 end
            if not actionData.damageFlag then actionData.damageFlag = 0 end
            if not actionData.damageMul then actionData.damageMul = 0.0 end
            if not actionData.damageAdd then actionData.damageAdd = 0 end
            if not actionData.targetRangeType then actionData.targetRangeType = 1 end
            if not actionData.castPosType then actionData.castPosType = 0 end
            if not actionData.actionBeginDuration then actionData.actionBeginDuration = 0 end
            if not actionData.actionEndDuration then actionData.actionEndDuration = 0 end
            if not actionData.extraSpeed then actionData.extraSpeed = 0 end
            if not actionData.extraSl then actionData.extraSl = 0 end
            if not actionData.spawnPoint then actionData.spawnPoint = 0 end
            if not actionData.triggerEvent then actionData.triggerEvent = 0 end
            if not actionData.hitXoffset then actionData.hitXoffset = 0 end
            if not actionData.hitYoffset then actionData.hitYoffset = 0 end
            actionData.hitXoffset = actionData.hitXoffset * 100
            actionData.hitYoffset = actionData.hitYoffset * 100

            actionData.extraDistance        = (actionData.extraSpeed / 10) * actionData.extraSl
            actionData.casterHeal           = self:InitDefaultList(actionData.casterHeal, 2, {0, 0})
            actionData.targetHeal           = self:InitDefaultList(actionData.targetHeal, 2, {0, 0})
            actionData.targetRangeParam     = self:InitDefaultList(actionData.targetRangeParam, 0, {})
            actionData.casterAddBuff        = self:InitDefaultList(actionData.casterAddBuff, 0, {}, true)
            actionData.casterDelBuff        = self:InitDefaultList(actionData.casterDelBuff, 0, {}, true)
            actionData.targetAddBuff        = self:InitDefaultList(actionData.targetAddBuff, 0, {}, true)
            actionData.targetDelBuff        = self:InitDefaultList(actionData.targetDelBuff, 0, {}, true)
            actionData.randTeleport         = self:InitDefaultList(actionData.randTeleport, 0, {}, true)

            self:CheckTargetRangeData(actionData)
            self:CheckRandTeleportData(actionData)
            self:CheckExecute(actionData)
        end
    else
    	skill_action_data = {}
    end
end

function SkillAction:InitDefaultList(org_list, min_size, default_list, is_nonzero)
    if not org_list then return default_list end
    if is_nonzero == true and #org_list == 1 and org_list[1] == 0 then org_list = {} end
    if lua_util.get_table_real_count(org_list) < min_size then return default_list end
    return org_list
end

function SkillAction:CheckTargetRangeData(actionData)
    if actionData.targetRangeType == TARGET_RANGE.SECTOR then
        if #actionData.targetRangeParam < 2 then
            actionData.targetRangeParam = {500, 0}
        end
    elseif actionData.targetRangeType == TARGET_RANGE.ROUND then
        if #actionData.targetRangeParam < 1 then
            actionData.targetRangeParam = {500}
        end
    elseif actionData.targetRangeType == TARGET_RANGE.SINGLE then
        --无参数
    elseif actionData.targetRangeType == TARGET_RANGE.LINE then
        if #actionData.targetRangeParam < 2 then
            actionData.targetRangeParam = {1000, 300}
        end
    elseif actionData.targetRangeType == TARGET_RANGE.FACE then
        --无参数
    elseif actionData.targetRangeType == TARGET_RANGE.FRONT_ROUND then
        if #actionData.targetRangeParam < 2 then
            actionData.targetRangeParam = {500, 300}
        end
    elseif actionData.targetRangeType == TARGET_RANGE.WORLD_RECT then
        if #actionData.targetRangeParam < 4 then
            actionData.targetRangeParam = {0, 0, 100 * 10000, 100 * 10000}
        end
        if actionData.targetRangeParam[1] > actionData.targetRangeParam[3] then
            local tmp = actionData.targetRangeParam[1]
            actionData.targetRangeParam[1] = actionData.targetRangeParam[3]
            actionData.targetRangeParam[3] = tmp
        end
        if actionData.targetRangeParam[2] > actionData.targetRangeParam[4] then
            local tmp = actionData.targetRangeParam[2]
            actionData.targetRangeParam[2] = actionData.targetRangeParam[4]
            actionData.targetRangeParam[4] = tmp
        end
    end
end

function SkillAction:CheckRandTeleportData(actionData)
    local randTeleport      = actionData.randTeleport
    actionData.randTeleport = {}

    local x = 0
    for i, value in ipairs(randTeleport) do
        if (i % 2) ~= 0 then
            x = value
        else
            actionData.randTeleport[i / 2]   = {}
            actionData.randTeleport[i / 2].x = x
            actionData.randTeleport[i / 2].y = value
        end
    end
end

function SkillAction:CheckExecute(actionData)
    if #actionData.casterAddBuff > 0 or #actionData.casterDelBuff > 0 or
       #actionData.targetAddBuff > 0 or #actionData.targetDelBuff > 0
    then
        actionData.hasActiveBuff = true
    else
        actionData.hasActiveBuff = false
    end

    if actionData.casterHeal[1] ~= 0 or actionData.casterHeal[2] ~= 0 or
       actionData.targetHeal[1] ~= 0 or actionData.targetHeal[2] ~= 0
    then
       actionData.hasHeal = true
    else
       actionData.hasHeal = false
    end

    if #actionData.randTeleport > 0 or actionData.extraDistance > 0 then
       actionData.hasShift = true
    else
       actionData.hasShift = false
    end

    if actionData.hasActiveBuff == true or actionData.hasHeal == true or
       actionData.hasShift == true or actionData.damageFlag > 0 or
       actionData.spawnPoint ~= 0 or actionData.triggerEvent ~= 0
    then
        actionData.isNeedExecute = true
    else
        actionData.isNeedExecute = false
    end
end

function SkillAction:New(owner, skillObj)
    local newObj    = {}
    newObj.ptr      = {}
    setmetatable(newObj,        {__index = SkillAction})
    setmetatable(newObj.ptr,    {__mode = "v"})

    newObj.ptr.theOwner	= owner
    newObj.ptr.theSkill	= skillObj

    --定时器参数表
    newObj.timerParamTab	= {}

    newObj.theParams = {castPos = {x = 0, y = 0, face = 0}, targetPos = {x = 0, y = 0, face = 0}, actionSeq = 0}

    return newObj
end

function SkillAction:Del()
	self:RemoveAll()
end

--移除所有定时器及参数
function SkillAction:RemoveAll()
	for k, v in pairs(self.timerParamTab) do
		self.ptr.theOwner:delLocalTimer(k)
	end
	self.timerParamTab = {}
end


------------------------------------------------------------------------

--获取技能动作对象，若不存在则返回nil
function SkillAction:GetActionData(actionID)
    if not skill_action_data then return nil end
    return skill_action_data[actionID]
end

--获取技能动作的周期
function SkillAction:GetDuration(actionID)
	local actionData = self:GetActionData(actionID)
	if not actionData then return 0 end
	return actionData.actionBeginDuration + actionData.actionEndDuration
end

--获取技能动作的出招周期
function SkillAction:GetBeginDuration(actionID)
    local actionData = self:GetActionData(actionID)
    if not actionData then return 0 end
    return actionData.actionBeginDuration
end

--获取技能动作的收招周期
function SkillAction:GetEndDuration(actionID)
    local actionData = self:GetActionData(actionID)
    if not actionData then return 0 end
    return actionData.actionEndDuration
end

--判断目标是否在行为指定的区域内容
function SkillAction:GetIsInArea(actionID, target)
    local actionData = self:GetActionData(actionID)
    if not actionData then return false end

    return (self:TestAction(ACTION_TEST_TARGET_IN_AREA, actionData, target) == 0)
end

--转接口
function SkillAction:ShowText(...)
    local theOwner = self.ptr.theOwner
    if theOwner.c_etype == public_config.ENTITY_TYPE_AVATAR then
        theOwner:ShowText(...)
    end
end

--转接口
function SkillAction:ShowTextID(...)
    local theOwner = self.ptr.theOwner
    if theOwner.c_etype == public_config.ENTITY_TYPE_AVATAR then
        theOwner:ShowTextID(...)
    end
end

--调试显示接口
function SkillAction:DebugShowText(...)
    if debug_show_text ~= true then return end
    local theOwner = self.ptr.theOwner
    if theOwner.c_etype == public_config.ENTITY_TYPE_AVATAR then
        theOwner:ShowText(...)
    end
end

--调试显示接口
function SkillAction:DebugShowTextID(...)
    if debug_show_text ~= true then return end
    local theOwner = self.ptr.theOwner
    if theOwner.c_etype == public_config.ENTITY_TYPE_AVATAR then
        theOwner:ShowTextID(...)
    end
end

--技能行为测试
function SkillAction:TestAction(testMode, param1, param2)
    local theOwner = self.ptr.theOwner

    --检查技能行为是否需要执行实现
    if testMode == ACTION_TEST_NEED_EXECUTE then
        local actionData = param1
        if actionData.isNeedExecute == true then return 0 end

        return TEXT_ACTION_NOT_EXECUTE

    --检查施法者死亡状态
    elseif testMode == ACTION_TEST_CASTER_DEATH then
        if theOwner:IsDeath() then return TEXT_ACTION_CASTER_DEATH end

        return 0

    elseif testMode == ACTION_TEST_IN_AOI then
        local target = param1
        if theOwner:isInAOI(target:getId()) == false then return TEXT_ACTION_NOT_IN_AOI end

        return 0

    --检查目标死亡状态
    elseif testMode == ACTION_TEST_TARGET_DEATH then
        local target = param1
        if not target or not target.IsDeath or target:IsDeath() then return TEXT_ACTION_CASTER_DEATH end

        return 0

    --检查是否可攻击状态
    elseif testMode == ACTION_TEST_CAN_HIT_STATE then
        local target = param1
        if not target or not target.stateFlag or Bit.Test(target.stateFlag, state_config.NO_HIT_STATE) then return TEXT_ACTION_NO_HIT_STATE end

        return 0
    
    --检查目标是否在施法区域内
    elseif testMode == ACTION_TEST_TARGET_IN_AREA then
        local actionData = param1
        local target     = param2
        if not target then return TEXT_ACTION_NOT_IN_AREA end

        --local entityA_r = theOwner:GetScaleRadius()
        local entityB_r = target:GetScaleRadius()
        --local entity_r = entityA_r + entityB_r
        local p1     = actionData.targetRangeParam[1] or 0
        local p2     = actionData.targetRangeParam[2] or 0
        local p3     = actionData.targetRangeParam[3] or 0
        local p4     = actionData.targetRangeParam[4] or 0
        local x2, y2 = target:getXY()
        local x1, y1, face1
        if actionData.castPosType == 1 then
            x1, y1  = theOwner:getXY()
            face1   = theOwner:getFace()
        elseif actionData.castPosType == 2 then
            x1      = self.theParams.targetPos.x
            y1      = self.theParams.targetPos.y
            face1   = self.theParams.targetPos.face
        else
            x1      = self.theParams.castPos.x
            y1      = self.theParams.castPos.y
            face1   = self.theParams.castPos.face
        end
        x1, y1 = SkillCalculate.Offset(x1, y1, face1, actionData.hitYoffset, actionData.hitXoffset)

        if actionData.targetRangeType == TARGET_RANGE.SECTOR then
            if SkillCalculate.TestInSector(x1, y1, face1, x2, y2, p1 + entityB_r, p2) ~= true then return TEXT_ACTION_NOT_IN_AREA end
        elseif actionData.targetRangeType == TARGET_RANGE.ROUND then
            if SkillCalculate.GetDistance(x1, y1, x2, y2) > p1 + entityB_r then return TEXT_ACTION_NOT_IN_AREA end
        elseif actionData.targetRangeType == TARGET_RANGE.LINE then
            if SkillCalculate.TestInRectangle(x1, y1, face1, x2, y2, p1 + entityB_r, p2 + 2 * entityB_r) ~= true then return TEXT_ACTION_NOT_IN_AREA end
        elseif actionData.targetRangeType == TARGET_RANGE.FACE then
            if SkillCalculate.TestInSector(x1, y1, face1, x2, y2, p1 + entityB_r, 180) ~= true then return TEXT_ACTION_NOT_IN_AREA end
        elseif actionData.targetRangeType == TARGET_RANGE.FRONT_ROUND then
            local x0, y0 = SkillCalculate.GetFrontPosition(x1, y1, face1, p1)
            if SkillCalculate.GetDistance(x0, y0, x2, y2) > p2 + entityB_r then return TEXT_ACTION_NOT_IN_AREA end
        elseif actionData.targetRangeType == TARGET_RANGE.WORLD_RECT then
            if SkillCalculate.TestInWorldRectangle(x2, y2, p1, p2, p3, p4) ~= true then return TEXT_ACTION_NOT_IN_AREA end
        end

        return 0
    end

    return TEXT_ACTION_UNKNOWN
end

--施放技能动作
function SkillAction:Cast(skillData, actionSeq, actionID, startTick, targets)
    log_game_debug("SkillAction:Cast", "skillID=%s, actionID=%s, actionSeq=%s", skillData.id, actionID, actionSeq)

    local theOwner      = self.ptr.theOwner
    local actionData    = self:GetActionData(actionID)
    if not actionData then
        self:ShowTextID(CHANNEL.DBG, TEXT_ACTION_NOT_EXIST)
        return
    end

    --检查行为是否需要执行
    local ret = self:TestAction(ACTION_TEST_NEED_EXECUTE, actionData)
    if ret ~= 0 then
        log_game_debug("SkillAction:Cast", "Not Execute! skillID=%s, actionID=%s, actionSeq=%s", skillData.id, actionID, actionSeq)
        return
    end

    local timerID = theOwner:addLocalTimer("ProcSkillActionTimer", startTick, 1)
    local skillPosX, skillPosY  = theOwner:getXY()
    local skillFace             = theOwner:getFace()
	self.timerParamTab[timerID] = {skillData = skillData, actionSeq = actionSeq, actionData = actionData, targets = targets,
                                   skillPosX = skillPosX, skillPosY = skillPosY, skillFace = skillFace}
    if targets:size() ~= 0 then
        local the_target_id, the_target         = targets:begin()
        local target_x, target_y                = the_target:getXY()
        local target_face                       = the_target:getFace()
        self.timerParamTab[timerID].targetPos   = {x = target_x, y = target_y, face = target_face}
    end
end

--根据条件剔除目标
function SkillAction:EliminateTarget(skillData, actionData, targets)
    local theOwner = self.ptr.theOwner
    local theSkill = self.ptr.theSkill

    local ret   = 0
    local count = 0
    for k, v in pairs(targets) do
        repeat
            --判断是否已达目标数量上限
            if actionData.maxTargetCount > 0 then
                if count >= actionData.maxTargetCount then
                    targets:erase(k)
                    break
                end
            end

            --是否在AOI范围内（若不存在则可能是一个空target，所以需要优先判断并移除）
            ret = self:TestAction(ACTION_TEST_IN_AOI, v)
            if ret ~= 0 then
                log_game_debug("SkillAction:EliminateTarget", "ACTION_TEST_IN_AOI=%s", ret)
                targets:erase(k)
                break
            end

            --死亡状态判断
            ret = self:TestAction(ACTION_TEST_TARGET_DEATH, v)
            if ret ~= 0 then
                log_game_debug("SkillAction:EliminateTarget", "ACTION_TEST_TARGET_DEATH=%s", ret)
                targets:erase(k)
                break
            end

            --是否可攻击状态判断
            ret = self:TestAction(ACTION_TEST_CAN_HIT_STATE, v)
            if ret ~= 0 then
                log_game_debug("SkillAction:EliminateTarget", "ACTION_TEST_CAN_HIT_STATE=%s", ret)
                targets:erase(k)
                break
            end

            --敌我阵营判断
            ret = SkillCalculate.GetFaction(theOwner, v)
            if ret ~= Faction.Enemy then
                log_game_debug("SkillAction:EliminateTarget", "Not enemy : %s", ret)
                targets:erase(k)
                break
            end

            --目标距离判断（计算伤害时不执行此判定）
            --ret = theSkill:TestSkill(SKILL_TEST_RANGE, skillData, v)
            --if ret ~= 0 then
            --    log_game_debug("SkillAction:EliminateTarget", "SKILL_TEST_RANGE=%s", ret)
            --    targets:erase(k)
            --    break
            --end

            --施法区域判断
            ret = self:TestAction(ACTION_TEST_TARGET_IN_AREA, actionData, v)
            if ret ~= 0 then
--[[
                local x2, y2 = v:getXY()
                local x1, y1, face1
                if actionData.castPosType == 0 then
                    x1      = self.theParams.castPos.x
                    y1      = self.theParams.castPos.y
                    face1   = self.theParams.castPos.face
                elseif actionData.castPosType == 1 then
                    x1, y1  = theOwner:getXY()
                    face1   = theOwner:getFace()
                elseif actionData.castPosType == 2 then
                    x1      = self.theParams.target.x
                    y1      = self.theParams.target.y
                    face1   = self.theParams.target.face
                end
                local r         = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
                local entity_r  = v:GetScaleRadius() + theOwner:GetScaleRadius()
                log_game_debug("SkillAction:EliminateTarget", "ACTION_TEST_TARGET_IN_AREA=%s, actionID=%s, x1=%s, y1=%s, face1=%s, x2=%s, y2=%s, r=%s, entity_r=%s", 
                               ret, actionData.id, x1, y1, face1, x2, y2, r, entity_r)
--]]
                targets:erase(k)
                break
            end

            count = count + 1
        until true
    end
    return ret
end

------------------------------------------------------------------------

function SkillAction:ProcSkillActionTimer(timerID, activeCount)
    log_game_debug("SkillAction:ProcSkillActionTimer", "timerID=%s, activeCount=%s", timerID, activeCount)

	local actionParams = self.timerParamTab[timerID]
	if not actionParams then
        log_game_debug("SkillAction:ProcSkillActionTimer", "No params! (timerID=%s)", timerID)
		return
	end

	local theOwner     = self.ptr.theOwner
	local skillData    = actionParams.skillData
    local actionData   = actionParams.actionData

	--检查施法者死亡状态
    local ret = self:TestAction(ACTION_TEST_CASTER_DEATH)
    if ret ~= 0 then
        log_game_debug("SkillAction:ProcSkillActionTimer", "Caster Death!")
        self:ShowTextID(CHANNEL.DBG, ret)
        self:RemoveAll()
        return
    end

    --处理位移
    self:DoShiftAction(skillData, actionData)

    --召唤怪物
    self:DoSpawnAction(skillData, actionData)

    --寻找有效目标
    local targets = actionParams.targets:clone()
    if skillData.findTargetInAction ~= 0 then
        if not targets or targets:size() == 0 then
            targets = SkillCalculate.FindTargets(theOwner, Faction.Enemy)
            if targets:size() == 0 then
                log_game_debug("SkillAction:ProcSkillActionTimer", "Find no targets!")
                self:DebugShowTextID(CHANNEL.DBG, TEXT_ACTION_FIND_NO_TARGETS)
                --return
            end
        end
    end

    --构建相关参数
    local castPos = {x = actionParams.skillPosX, y = actionParams.skillPosY, face = actionParams.skillFace}
    if actionParams.targetPos then
        self.theParams = {castPos = castPos, targetPos = actionParams.targetPos, actionSeq = actionParams.actionSeq}
    else
        local targetPos = {x = 0, y = 0, face = 0}
        if targets:size() ~= 0 then
            local the_target_id, the_target = targets:begin()
            local target_x, target_y        = the_target:getXY()
            local target_face               = the_target:getFace()
            targetPos                       = {x = target_x, y = target_y, face = target_face}
        end
        self.theParams = {castPos = castPos, targetPos = targetPos, actionSeq = actionParams.actionSeq}
    end
    self.timerParamTab[timerID] = nil

    if targets:size() ~= 0 then
        --根据条件剔除目标
        local ret = self:EliminateTarget(skillData, actionData, targets)

        --判断是否存在有效目标
        if targets:size() == 0 then
            log_game_debug("SkillAction:ProcSkillActionTimer", "No targets!")
            self:DebugShowTextID(CHANNEL.DBG, ret)
            --self:DebugShowTextID(CHANNEL.DBG, TEXT_ACTION_NO_TARGETS)
            --return
        end
    end

    --处理伤害
    self:DoDamageAction(skillData, actionData, targets)

    --处理加血
    self:DoHealAction(skillData, actionData, targets)

    --处理Buff
    self:DoBuffAction(skillData, actionData, targets)

    --处理机关事件
    self:DoTriggerEvent(skillData, actionData, targets)
end

function SkillAction:DoShiftAction(skillData, actionData)
    log_game_debug("SkillAction:DoShiftAction", "skillID=%s, activeID=%s", skillData.id, actionData.id)

    if actionData.hasShift ~= true then return end

    local theOwner = self.ptr.theOwner

    --带位移的技能
    if actionData.extraDistance > 0 then
        if theOwner.c_etype == public_config.ENTITY_TYPE_MONSTER then
            local x, y  = theOwner:getXY()
            x, y        = SkillCalculate.GetFrontPosition(x, y, theOwner:getFace(), actionData.extraDistance)
            theOwner:setXY(x, y)
            log_game_debug("SkillAction:DoShiftAction setXY", "skillID=%s, activeID=%s", skillData.id, actionData.id)
        end
    end

    --带随机瞬移的技能
    if #actionData.randTeleport > 0 then
        if theOwner.c_etype == public_config.ENTITY_TYPE_MONSTER then
            local n  = math.random(1, #actionData.randTeleport)
            local x  = actionData.randTeleport[n].x
            local y  = actionData.randTeleport[n].y
            theOwner:teleport(x, y)
            log_game_debug("SkillAction:DoShiftAction teleport", "skillID=%s, activeID=%s", skillData.id, actionData.id)
        end
    end
end

function SkillAction:DoSpawnAction(skillData, actionData)
    log_game_debug("SkillAction:DoSpawnAction", "skillID=%s, activeID=%s", skillData.id, actionData.id)

    if actionData.spawnPoint == 0 then return end

    local theOwner = self.ptr.theOwner

    if theOwner.c_etype == public_config.ENTITY_TYPE_MONSTER or
       theOwner.c_etype == public_config.ENTITY_TYPE_MERCENARY then
        theOwner:LetSpawnPointStart(actionData.spawnPoint)
        log_game_debug("SkillAction:DoSpawnAction LetSpawnPointStart", "skillID=%s, activeID=%s", skillData.id, actionData.id)
    end
end

function SkillAction:DoTriggerEvent(skillData, actionData, targets)
    log_game_debug("SkillAction:DoTriggerEvent", "skillID=%s, activeID=%s", skillData.id, actionData.id)

    if actionData.triggerEvent == 0 then return end

    local theOwner = self.ptr.theOwner
    for defenderID, defender in pairs(targets) do
        if defender.c_etype == public_config.ENTITY_TYPE_AVATAR then
            defender.base.client.MissionResp(action_config.MSG_GET_NOTIFY_TO_CLENT_EVENT, {actionData.triggerEvent})
        end
    end

    log_game_debug("SkillAction:DoTriggerEvent Done", "skillID=%s, activeID=%s", skillData.id, actionData.id)
end

function SkillAction:DoDamageAction(skillData, actionData, targets)
    log_game_debug("SkillAction:DoDamageAction", "skillID=%s, activeID=%s, targets.size=%s", skillData.id, actionData.id, targets:size())

    if actionData.damageFlag == 0 or targets:size() == 0 then return end

    local attacker      = self.ptr.theOwner
    local tabHarms      = {}
    local hitCombo      = 0
    for defenderID, defender in pairs(targets) do
        local harmType, harm = 0, 0
        if actionData.damageFlag == 1 then
            harmType, harm = SkillCalculate.GetDamage(attacker, defender, actionData.damageMul, actionData.damageAdd)
            if harmType ~= 1 then hitCombo = hitCombo + 1 end
            if harm ~= 0 then 
                defender:addHp(-harm)
                defender.sp_ref:DoDamageAction(attacker, defender, harm)

                if defender.c_etype == public_config.ENTITY_TYPE_MONSTER then
                    attacker.sp_ref:MonsterHpChange(attacker, defender, harm)
                    if defender:IsDeath() then
                        if attacker.c_etype == public_config.ENTITY_TYPE_AVATAR then
                            local cfg = g_monster_mgr:getCfgById(defender.monsterId)
                            if cfg and cfg.spreadSkillBuff and cfg.spreadSkillBuff ~= 0 then
                                attacker.skillSystem:AddBuff(cfg.spreadSkillBuff)
                            end
                        end
                    end
                end

                --如果攻击者是玩家，则把每次输出累加到Space中
                if attacker.c_etype == public_config.ENTITY_TYPE_AVATAR then
                    attacker.sp_ref:AddDamage(attacker, harm)
                end

--                --计算怒气值
--                self:CastAnger(attacker, defender, harm)

                if defender.ctrlByBossHpMgr == 1 then
                    --log_game_debug('SkillAction:DoDamageAction', "attacker.c_etype = %s, defender.c_etype = %s", attacker.c_etype, defender.c_etype)
                    --log_game_debug("SkillAction:DoDamageAction", "defender.dbid[%s], attacker.dbid[%s]", tostring(defender.dbid), tostring(attacker.dbid))
                    attacker.sp_ref:UpdateBossHp(attacker.dbid, harm)
                    --log_game_debug('SkillAction:DoDamageAction', "3333333")
                    if defender:IsDeath() then
                        local mb_str = mogo.cPickle(attacker.base)
                        attacker.sp_ref:MonsterDeathEvent(mb_str)
                    end
                end
            end
        end
        tabHarms[defenderID] = {harmType, harm}
    end
    attacker.skillSystem:MarkCombo(hitCombo)
    local nowHitCombo = attacker.skillSystem:GetHitCombo()
    attacker:broadcastAOI(true, "SkillHarmResp", attacker:getId(), skillData.id, self.theParams.actionSeq, nowHitCombo, tabHarms);
end

function SkillAction:DoBuffAction(skillData, actionData, targets)
    log_game_debug("SkillAction:DoBuffAction", "skillID=%s, activeID=%s, targets.size=%s", skillData.id, actionData.id, targets:size())

    if actionData.hasActiveBuff ~= true then return end

    if #actionData.casterAddBuff > 0 or #actionData.casterDelBuff > 0 then
        local attacker = self.ptr.theOwner
        for k, buffID in pairs(actionData.casterAddBuff) do
            attacker.skillSystem.skillBuff:Add(buffID)
        end

        for k, buffID in pairs(actionData.casterDelBuff) do
            attacker.skillSystem.skillBuff:Remove(buffID)
        end
    end
 
    if #actionData.targetAddBuff > 0 then
        for id, defender in pairs(targets) do
            for k, buffID in pairs(actionData.targetAddBuff) do
                defender.skillSystem.skillBuff:Add(buffID)
            end
        end
    end

    if #actionData.targetDelBuff > 0 then
        for id, defender in pairs(targets) do
            for k, buffID in pairs(actionData.targetDelBuff) do
                defender.skillSystem.skillBuff:Remove(buffID)
            end
        end
    end
end

--处理加血
function SkillAction:DoHealAction(skillData, actionData, targets)
    log_game_debug("SkillAction:DoHealAction", "skillID=%s, activeID=%s, targets.size=%s", skillData.id, actionData.id, targets:size())

    if actionData.hasHeal ~= true then return end

    --给自身加血
    if actionData.casterHeal[1] ~= 0 or actionData.casterHeal[2] ~= 0 then
        local theOwner  = self.ptr.theOwner
        local addHP     = SkillCalculate.GetAttr(theOwner, "hp")
        addHP = addHP * actionData.casterHeal[1] / 100 + actionData.casterHeal[2]
        if addHP > 0 then
            theOwner:addHp(addHP)
        end
    end

    --给目标加血
    if actionData.targetHeal[1] ~= 0 or actionData.targetHeal[2] ~= 0 then
        for k, targetObj in pairs(targets) do
            local addHP     = SkillCalculate.GetAttr(targetObj, "hp")
            addHP = addHP * actionData.targetHeal[1] / 100 + actionData.targetHeal[2]
            if addHP > 0 then
                targetObj:addHp(addHP)
            end
        end
    end
end

----计算怒气值
--function SkillAction:CastAnger(attacker, defender, harm)
--
--    --计算怒气值
--    --                PVE时，
--    --                对敌人每造成10%生命上限的伤害，增加2点怒气（1%）
--    --                自身每受到1%生命上限的伤害，增加2点怒气（1%）
--    --                PVP时，
--    --                对敌人每造成1%血量上限的伤害，增加1点怒气（0.5%）
--    --                自身每受到1%血量上限的伤害，增加2点怒气（1%）
--
--    local theHp = SkillCalculate.GetAttr(defender, "hp")
--    local defenderId = defender:getId()
--    local attacherId = attacker:getId()
--
----    log_game_info("SkillAction:CastAnger", "attackerid=%d;defenderid=%d;attacker.c_etype=%d;defender.c_etype=%d;harm=%d", attacherId, defenderId, attacker.c_etype, defender.c_etype, harm)
--
--    if (defender.c_etype == public_config.ENTITY_TYPE_MONSTER or defender.c_etype == public_config.ENTITY_TYPE_MERCENARY) and attacker.c_etype == public_config.ENTITY_TYPE_AVATAR then
--
--        --累加对怪造成的伤害
--        attacker.harmInfo[defenderId] = (attacker.harmInfo[defenderId] or 0) + harm
--
----        log_game_info("SkillAction:CastAnger 1", "attackerid=%d;defenderid=%d;attacker.c_etype=%d;defender.c_etype=%d;harm=%d;theHp=%d", attacherId, defenderId, attacker.c_etype, defender.c_etype, harm, theHp)
--
--        --PVE时，玩家攻击
--        if not attacker:IsAngerFull() then
--            --攻击者怒气值未满
--
--            local times = math.floor((attacker.harmInfo[defenderId] / (theHp * g_GlobalParamsMgr:GetParams('anger_pve_hit_rate', 0.1))))
--
--            times = times - (attacker.harmAngerTimesInfo[defenderId] or 0)
--
--            if times > 0 then
--                attacker:AddAnger(times * g_GlobalParamsMgr:GetParams('anger_pve_hit_value', 2))
--                attacker.harmAngerTimesInfo[defenderId] = (attacker.harmAngerTimesInfo[defenderId] or 0) + times
--            end
--
--        end
--
--    elseif defender.c_etype == public_config.ENTITY_TYPE_AVATAR and (attacker.c_etype == public_config.ENTITY_TYPE_MONSTER or attacker.c_etype == public_config.ENTITY_TYPE_MERCENARY) then
--
----        log_game_info("SkillAction:CastAnger 2", "attackerid=%d;defenderid=%d;attacker.c_etype=%d;defender.c_etype=%d;harm=%d;theHp=%d", attacherId, defenderId, attacker.c_etype, defender.c_etype, harm, theHp)
--
--        --累加被怪造成的伤害
--        defender.harmedInfo[attacherId] = (defender.harmedInfo[attacherId] or 0) + harm
--
--        --PVE时，玩家受击
--        if not defender:IsAngerFull() then
--            --受击者怒气值未满
--
--            local times = math.floor((defender.harmedInfo[attacherId] / (theHp * g_GlobalParamsMgr:GetParams('anger_pve_hited_rate', 0.01))))
--
--            times = times - (defender.harmedAngerTimesInfo[attacherId] or 0)
--
--            if times > 0 then
--                defender:AddAnger(times * g_GlobalParamsMgr:GetParams('anger_pve_hited_value', 2))
--                defender.harmedAngerTimesInfo[attacherId] = (defender.harmedAngerTimesInfo[attacherId] or 0) + times
--            end
--        end
--
--    elseif defender.c_etype == public_config.ENTITY_TYPE_AVATAR and attacker.c_etype == public_config.ENTITY_TYPE_AVATAR then
--
--        --双方都累加伤害
--        attacker.harmInfo[defenderId] = (attacker.harmInfo[defenderId] or 0) + harm
--        defender.harmedInfo[attacherId] = (defender.harmedInfo[attacherId] or 0) + harm
--
----        log_game_info("SkillAction:CastAnger 3", "attackerid=%d;defenderid=%d;attacker.c_etype=%d;defender.c_etype=%d;harm=%d;theHp=%d", attacherId, defenderId, attacker.c_etype, defender.c_etype, harm, theHp)
--
--        --PVP
--        if not attacker:IsAngerFull() then
--            --攻击者怒气值未满
--
--            local times = math.floor((attacker.harmInfo[defenderId] / (theHp * g_GlobalParamsMgr:GetParams('anger_pvp_hit_rate', 0.01))))
--
--            times = times - (attacker.harmAngerTimesInfo[defenderId] or 0)
--
--            if times > 0 then
--                attacker:AddAnger(times * g_GlobalParamsMgr:GetParams('anger_pvp_hit_value', 1))
--                attacker.harmAngerTimesInfo[defenderId] = (attacker.harmAngerTimesInfo[defenderId] or 0) + times
--            end
--        end
--
--        if not defender:IsAngerFull() then
--            --受击者怒气值未满
--            local times = math.floor((defender.harmedInfo[attacherId] / (theHp * g_GlobalParamsMgr:GetParams('anger_pvp_hited_rate', 0.01))))
--
--            times = times - (defender.harmedAngerTimesInfo[attacherId] or 0)
--
--            if times > 0 then
--                defender:AddAnger(times * g_GlobalParamsMgr:GetParams('anger_pvp_hited_value', 1))
--                defender.harmedAngerTimesInfo[attacherId] = (defender.harmedAngerTimesInfo[attacherId] or 0) + times
--            end
--        end
--    end
--end
