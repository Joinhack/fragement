-- 技能系统

require "SkillAction"
require "SkillBuff"
require "SkillBag"
require "SkillCalculate"
require "lua_util"
require "lua_map"
require "channel_config"


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
local _readXml                  = lua_util._readXml
local confirm                   = lua_util.confirm
local debug_show_text           = false
local skill_data                = {}
local hit_combo_time            = 10 * 1000     --连击有效计时，单位：毫秒
local faction                   = 1


--消息提示，对应ChineseData.xml表定义
local TEXT_SKILL_NOT_EXIST              = 1002001       --技能不存在
local TEXT_SKILL_COLDDOWN_LIMIT         = 1002002       --技能最少冷却保护
local TEXT_SKILL_COLDDOWNING            = 1002003       --此技能正在冷却中
local TEXT_SKILL_NEXT_COLDDOWN_BLOCK    = 1002004       --连续技禁手冷却中
local TEXT_SKILL_NEXT_COLDDOWNED        = 1002005       --连续技已冷却
local TEXT_SKILL_PUBLIC_COLDDOWNING     = 1002006       --技能公共冷却中
local TEXT_SKILL_NOT_LEARN              = 1002007       --此技能还没学到
local TEXT_SKILL_DEPEND                 = 1002008       --连续技依赖的前置技能未施放
local TEXT_SKILL_DEPEND_COUNT           = 1002009       --连续技依赖的前置技能施放次数不够
local TEXT_SKILL_DEPEND_BUFF            = 1002010       --此技能需要在指定Buff下施放
local TEXT_SKILL_INDEPEND_BUFF          = 1002011       --当前Buff下限制施放此技能
local TEXT_SKILL_CASTER_DEATH           = 1002012       --施法者已死亡
local TEXT_SKILL_TARGET_DEATH           = 1002013       --目标已死亡
local TEXT_SKILL_NEED_CHARGE            = 1002014       --需要蓄力
local TEXT_SKILL_OUT_OF_RANGE           = 1002015       --目标距离太远
local TEXT_SKILL_RANGE_OBJECT_ILLEGAL   = 1002016       --施法距离测试目标非法
local TEXT_SKILL_TICK_ILLEGAL           = 1002017       --非法的施法速度


--连击有效计时，单位：毫秒
local HIT_COMBO_TIME     = 10 * 1000


--技能测试模式
SKILL_TEST_COLDDOWN      = 1    --检查CD时间是否已完成
SKILL_TEST_HAS_LEARNED   = 2    --检查技能是否已习得
SKILL_TEST_DEPEND        = 3    --检查依赖和排他情况
SKILL_TEST_CASTER_DEATH  = 4    --检查施法者死亡状态
SKILL_TEST_CHARGE        = 5    --检查施蓄力状态
SKILL_TEST_RANGE         = 6    --检查目标距离


SkillSystem = {}
SkillSystem.__index = SkillSystem


function SkillSystem:InitData()
    skill_data = _readXml('/data/xml/SkillData.xml', 'id_i')
    if skill_data then
        for k, v in pairs(skill_data) do
            confirm(k >= 1 and k <= 65535, "技能索引ID越界[id=%d]", k);

            local skillData = v
            if not skillData.learnLimit then skillData.learnLimit = 0 end
            if not skillData.limitLevel then skillData.limitLevel = 0 end
            if not skillData.limitVocation then skillData.limitVocation = 0 end
            if not skillData.castRange then skillData.castRange = 0 end
            if not skillData.findTargetInAction then skillData.findTargetInAction = 0 end

            if not skillData.skillAction then skillData.skillAction = {} end

            skillData.cd            = self:InitDefaultList(skillData.cd, 4, {100, 100, 100, 100})
            skillData.dependSkill   = self:InitDefaultList(skillData.dependSkill, 3, {0, 0, 0})
            skillData.castTime      = self:InitDefaultList(skillData.castTime, 1, {0})
            skillData.dependBuff    = self:InitDefaultList(skillData.dependBuff, 0, {}, true)
            skillData.independBuff  = self:InitDefaultList(skillData.independBuff, 0, {}, true)
            skillData.learnBuff     = self:InitDefaultList(skillData.learnBuff, 0, {}, true)
        end
    else
        skill_data = {}
    end
    SkillAction:InitData()
    SkillBuff:InitData()
end

function SkillSystem:InitDefaultList(org_list, min_size, default_list, is_nonzero)
    if not org_list then return default_list end
    if is_nonzero == true and #org_list == 1 and org_list[1] == 0 then org_list = {} end
    if lua_util.get_table_real_count(org_list) < min_size then return default_list end
    return org_list
end

function SkillSystem:New(owner)
    log_game_debug("SkillSystem:New", "entity_id=%s", owner:getId())                      --输出调试，临时代码需要移除

    local newObj    = {}
    newObj.ptr      = {}
    setmetatable(newObj,        {__index = SkillSystem})
    setmetatable(newObj.ptr,    {__mode = "v"})

    newObj.ptr.theOwner         = owner

    --技能使用记录
    newObj.skillRecord          = {last_skill_id = 0, last_skill_count = 0, last_time_tick = 0}

    --蓄力技能启动记录
    newObj.skillChargeRecord    = {charge_tick = 0}

    --技能行为
    newObj.skillAction          = SkillAction:New(owner, newObj)

    --技能Buff
    newObj.skillBuff            = SkillBuff:New(owner, newObj)

    --技能背包
    newObj.skillBag             = SkillBag:New(owner, newObj)

    --当前连击计数器
    newObj.hitCombo             = {count = 0, last_tick = 0}

    --技能配置表 
    newObj.skillData            = skill_data

    --标记阵营（临时处理）
    newObj:MarkFaction()

    return newObj
end

function SkillSystem:OnLoad()
    self.skillBuff:OnLoad()
end

function SkillSystem:OnSave()
    self.skillBuff:OnSave()
end

--注销技能行为
function SkillSystem:Del()
    self.skillAction:Del()
    self.skillBuff:Del()
end

function SkillSystem:Reset()
    self.skillRecord          = {last_skill_id = 0, last_skill_count = 0, last_time_tick = 0}
    self.skillChargeRecord    = {charge_tick = 0}
    self.hitCombo             = {count = 0, last_tick = 0}
    self.skillBag:ResetCastTick()
end

function SkillSystem:MarkFaction()
    local theOwner = self.ptr.theOwner
    if theOwner.c_etype == public_config.ENTITY_TYPE_MERCENARY then
        theOwner.factionFlag = 0
        local avatar_id = theOwner:GetOwnerId()
        if avatar_id ~= nil then
            local theAvatar         = mogo.getEntity(avatar_id)

            if theAvatar then
                theOwner.factionFlag    = theAvatar.factionFlag 
            else
                theOwner.factionFlag = 0
            end

            return
        end
    elseif theOwner.c_etype == public_config.ENTITY_TYPE_AVATAR then
        theOwner.factionFlag    = faction
        --faction                 = faction + 1
        if faction == 255 then faction = 1 end
    else
        theOwner.factionFlag = 0
    end
end


------------------------------------------------------------------------

--调试显示接口
function SkillSystem:DebugShowText(...)
    if debug_show_text ~= true then return end
    local theOwner = self.ptr.theOwner
    if theOwner.c_etype == public_config.ENTITY_TYPE_AVATAR then
        theOwner:ShowText(...)
    end
end

--调试显示接口
function SkillSystem:DebugShowTextID(...)
    if debug_show_text ~= true then return end
    local theOwner = self.ptr.theOwner
    if theOwner.c_etype == public_config.ENTITY_TYPE_AVATAR then
        theOwner:ShowTextID(...)
    end
end

--获取技能对象，若不存在则返回nil
function SkillSystem:GetSkill(skillID)
    if not skill_data then return nil end
    return skill_data[skillID]
end

--获取连击次数
function SkillSystem:GetHitCombo()
    return self.hitCombo.count
end

--获取最高连击次数（当前副本出现过的最高记录）
function SkillSystem:GetMaxHitCombo()
    --return self.ptr.theOwner.maxHitComboCount or 0
    return 0
end

--获取技能所有动作执行的总时间，单位：毫秒
function SkillSystem:GetTotalActionDuration(skillData)
    local theAction = self.skillAction
    local duration  = 0
    for i, actionID in ipairs(skillData.skillAction) do
        duration = duration + theAction:GetDuration(actionID)
    end
    return duration
end

--获取技能施放距离，返回0代表无限远
function SkillSystem:GetSkillRange(skillID)
    local skillData = self:GetSkill(skillID)
    if not skillData then return 0 end

    return skillData.castRange
end

--判断目标是否在指定技能范围内
function SkillSystem:IsInSkillRange(skillID, targetID)
    local skillData = self:GetSkill(skillID)
    local theTarget = mogo.getEntity(targetID)
    if not skillData or not theTarget then return false end

    return (self:TestSkill(SKILL_TEST_RANGE, skillData, theTarget) == 0)
end

--判断目标是否在指定技能区域内（技能第一个行为指定的区域内）
function SkillSystem:IsInSkillArea(skillID, targetID)
    local skillData = self:GetSkill(skillID)
    local theTarget = mogo.getEntity(targetID)
    if not skillData or not theTarget then return false end

    local actionID = skillData.skillAction[1]
    if not actionID then return false end

    local theAction = self.skillAction
    return theAction:GetIsInArea(actionID, theTarget)
end

--技能测试
function SkillSystem:TestSkill(testMode, skillData, param1)
    --CD时间测试
    if testMode == SKILL_TEST_COLDDOWN then
        local lastSkillID   = self.skillRecord.last_skill_id
        local lastSkillData = self:GetSkill(lastSkillID)
        if not lastSkillData then
            self.skillRecord.last_skill_id = 0
        else
            local nowSkillID    = skillData.id
            local nowTick       = param1
            if not nowTick then nowTick = mogo.getTickCount() end
            if lastSkillID ~= 0 then
                --最少CD限制为100毫秒
                local elapsedTick = nowTick - self.skillRecord.last_time_tick
                if elapsedTick < 100 then return TEXT_SKILL_COLDDOWN_LIMIT end

                --自身技能CD
                local selfElapsedTick = nowTick - self.skillBag:GetCastTick(skillData)
                if selfElapsedTick < skillData.cd[1] then return TEXT_SKILL_COLDDOWNING end

                --连续技能判定
                if lastSkillData.dependSkill[3] == nowSkillID then
                    --连续技能禁手CD
                    if elapsedTick < lastSkillData.cd[2] then return TEXT_SKILL_NEXT_COLDDOWN_BLOCK end
                    --连续技能激活CD
                    if elapsedTick > lastSkillData.cd[2] + lastSkillData.cd[3] then return TEXT_SKILL_NEXT_COLDDOWNED end
                end

                --公共CD
                if elapsedTick < lastSkillData.cd[4] then return TEXT_SKILL_PUBLIC_COLDDOWNING end
            end
        end

        return 0

    --检查技能是否已习得
    elseif testMode == SKILL_TEST_HAS_LEARNED then
        if self.skillBag:Has() ~= true then
            return TEXT_SKILL_NOT_LEARN
        else
            return 0
        end

    --检查依赖和排他情况
    elseif testMode == SKILL_TEST_DEPEND then
        --依赖连续技能判定
        if skillData.dependSkill[1] > 0 then
            if self.skillRecord.last_skill_id ~= skillData.dependSkill[1] then return TEXT_SKILL_DEPEND end
            if self.skillRecord.last_skill_count < skillData.dependSkill[2] then return TEXT_SKILL_DEPEND_COUNT end
        end

        --Buff依赖判定
        for i, v in pairs(skillData.dependBuff) do
            if v ~= 0 then
                if self.skillBuff:Has(v) ~= true then return TEXT_SKILL_DEPEND_BUFF end
            end
        end

        --Buff排他判定
        for i, v in pairs(skillData.independBuff) do
            if v ~= 0 then
                if self.skillBuff:Has(v) ~= false then return TEXT_SKILL_INDEPEND_BUFF end
            end
        end

        return 0

    --检查施法者死亡状态
    elseif testMode == SKILL_TEST_CASTER_DEATH then
        local theOwner = self.ptr.theOwner
        if theOwner:IsDeath() then return TEXT_SKILL_CASTER_DEATH end

        return 0

    --检查施蓄力状态
    elseif testMode == SKILL_TEST_CHARGE then
        if skillData.castTime[1] == 1 then
            if self.skillChargeRecord.charge_tick == 0 then return TEXT_SKILL_NEED_CHARGE end
        end

        return 0

    --施法距离测试
    elseif testMode == SKILL_TEST_RANGE then
        local target = param1
        if not target or not target.getId or not target.GetScaleRadius then return TEXT_SKILL_RANGE_OBJECT_ILLEGAL end

        if skillData.castRange ~= 0 then
            local theOwner = self.ptr.theOwner
            local distance = math.floor(theOwner:getDistance(target:getId()))
            target:GetScaleRadius()
            theOwner:GetScaleRadius()
            local entity_r = target:GetScaleRadius() + theOwner:GetScaleRadius()
            if skillData.castRange + entity_r < distance then
                return TEXT_SKILL_OUT_OF_RANGE
            end
        end

        return 0
    end
end

--解析目标
function SkillSystem:ParseTagerts(targets)
    local serverTargets = lua_map:new()
    if targets and type(targets) == "table" then
        for k, v in pairs(targets) do
            if type(v) == "table" and type(v[1]) == "number" then
                local targetID  = v[1]
                local theTarget = mogo.getEntity(targetID)
                if theTarget then
                    if theTarget.c_etype == public_config.ENTITY_TYPE_AVATAR or
                        theTarget.c_etype == public_config.ENTITY_TYPE_MERCENARY or
                        theTarget.c_etype == public_config.ENTITY_TYPE_MONSTER then
                        serverTargets:insert(targetID, theTarget)
                    end
                end
            end
        end
    end
    return serverTargets
end

--标记时间
function SkillSystem:MarkTime(skillData, timeTick)
    local theRecord = self.skillRecord

    if theRecord.last_skill_id == skillData.id then
        theRecord.last_skill_count  = theRecord.last_skill_count + 1
    else
        theRecord.last_skill_id     = skillData.id
        theRecord.last_skill_count  = 1
    end

    self.skillBag:MarkCastTick(skillData, timeTick)
    theRecord.last_time_tick            = timeTick
    self.skillChargeRecord.charge_tick  = 0
end

--标记连击
function SkillSystem:MarkCombo(hitCombo)
    return
    --[[
    local theOwner = self.ptr.theOwner
    if theOwner.c_etype ~= public_config.ENTITY_TYPE_AVATAR then return end

    local theCombo  = self.hitCombo
    local theRecord = self.skillRecord
    if theCombo.last_tick + HIT_COMBO_TIME > theRecord.last_time_tick then
        theCombo.count     = theCombo.count + hitCombo
        theCombo.last_tick = theRecord.last_time_tick
        if theCombo.count > theOwner.maxHitComboCount then
            theOwner.maxHitComboCount = theCombo.count
        end
    else
        theCombo.count     = hitCombo
        theCombo.last_tick = theRecord.last_time_tick
    end
    --]]
end

--施放技能
function SkillSystem:CastSkill(skillData, targets)
    local theOwner  = self.ptr.theOwner
    local theAction = self.skillAction

    --搜索目标
    if skillData.findTargetInAction == 0 then
        if not targets or targets:size() == 0 then
            targets = SkillCalculate.FindTargets(theOwner, Faction.Enemy)
        end
    end
    
    local iCount    = 0
    local startTick = 0
    for i, actionID in ipairs(skillData.skillAction) do
        startTick = startTick + theAction:GetBeginDuration(actionID)
        theAction:Cast(skillData, iCount, actionID, startTick, targets)
        startTick = startTick + theAction:GetEndDuration(actionID)
        iCount = iCount + 1
    end

    local x, y = theOwner:getXY()
    theOwner:broadcastAOI(false, "CastSkillResp", theOwner:getId(), x, y, theOwner:getPackFace(), skillData.id)
end


------------------------------------------------------------------------

--客户端执行技能
function SkillSystem:OnClientUseSkill(skillID, targets, clientTick)
    log_game_debug("SkillSystem:OnClientUseSkill", "skillID=%s, clientTick=%s", skillID, clientTick)
    
    local theOwner  = self.ptr.theOwner
    local skillData = self:GetSkill(skillID)
    if not skillData then
        theOwner:ShowTextID(CHANNEL.DBG, TEXT_SKILL_NOT_EXIST)
        return
    end

    local ret

    --检查施法者死亡状态
    ret = self:TestSkill(SKILL_TEST_CASTER_DEATH, skillData)
    if ret ~= 0 then
        theOwner:ShowTextID(CHANNEL.DBG, ret)
        return
    end

    --检查技能是否已习得
--    ret = self:TestSkill(SKILL_TEST_HAS_LEARNED, skillData)
--    if ret ~= 0 then
--        theOwner:ShowTextID(CHANNEL.DBG, ret)
--        return
--    end

    --检查是否加速
    local S1E = mogo.getTickCount()
    ret = theOwner:VerifyTick(0, S1E, clientTick)
    if ret == false then
        theOwner:ShowTextID(CHANNEL.TIPS, TEXT_SKILL_TICK_ILLEGAL)
        return
    end

    --检查CD时间
    ret = self:TestSkill(SKILL_TEST_COLDDOWN, skillData, clientTick)
    if ret ~= 0 then
        self:DebugShowTextID(CHANNEL.DBG, ret)
        return
    end

    --检查依赖和排他情况
    ret = self:TestSkill(SKILL_TEST_DEPEND, skillData)
    if ret ~= 0 then
        self:DebugShowTextID(CHANNEL.DBG, ret)
        return
    end

    --检查蓄力情况
    ret = self:TestSkill(SKILL_TEST_CHARGE, skillData)
    if ret ~= 0 then
        self:DebugShowTextID(CHANNEL.DBG, ret)
        return
    end

    --解析目标
    targets = self:ParseTagerts(targets)

    --标记使用技能的时间
    self:MarkTime(skillData, clientTick)

    --施放技能
    self:CastSkill(skillData, targets)
end

--客户端佣兵执行技能
function SkillSystem:OnClientMercenaryExecuteSkill(skillID, targets, clientTick)
    log_game_debug("SkillSystem:OnClientMercenaryExecuteSkill", "skillID=%s, clientTick=%s", skillID, clientTick)
    
    local theOwner  = self.ptr.theOwner
    local skillData = self:GetSkill(skillID)
    if not skillData then
        log_game_debug("SkillSystem:OnClientMercenaryExecuteSkill", "Data Return=%s", TEXT_SKILL_NOT_EXIST)
        return
    end

    local ret

    --检查施法者死亡状态
    ret = self:TestSkill(SKILL_TEST_CASTER_DEATH, skillData)
    if ret ~= 0 then
        log_game_debug("SkillSystem:OnClientMercenaryExecuteSkill", "Death Return=%s", ret)
        return
    end

    --检查技能是否已习得
--    ret = self:TestSkill(SKILL_TEST_HAS_LEARNED, skillData)
--    if ret ~= 0 then
--        log_game_debug("SkillSystem:OnClientMercenaryExecuteSkill", "Learn Return=%s", ret)
--        return
--    end

    --检查CD时间
    --[[
    ret = self:TestSkill(SKILL_TEST_COLDDOWN, skillData, clientTick)
    if ret ~= 0 then
        log_game_debug("SkillSystem:OnClientMercenaryExecuteSkill", "CD Return=%s", ret)
        return
    end
    --]]

    --检查依赖和排他情况
    ret = self:TestSkill(SKILL_TEST_DEPEND, skillData)
    if ret ~= 0 then
        log_game_debug("SkillSystem:OnClientMercenaryExecuteSkill", "Depend Return=%s", ret)
        return
    end

    --检查蓄力情况
    ret = self:TestSkill(SKILL_TEST_CHARGE, skillData)
    if ret ~= 0 then
        log_game_debug("SkillSystem:OnClientMercenaryExecuteSkill", "Charge Return=%s", ret)
        return
    end

    --解析目标
    targets = self:ParseTagerts(targets)

    --标记使用技能的时间
    self:MarkTime(skillData, clientTick)

    --施放技能
    self:CastSkill(skillData, targets)
end

--服务器执行技能
function SkillSystem:OnServerExecuteSkill(skillID, targets)
    log_game_debug("SkillSystem:OnServerExecuteSkill", "skillID=%s", skillID)

    local theOwner  = self.ptr.theOwner
    local skillData = self:GetSkill(skillID)
    if not skillData then
        log_game_debug("SkillSystem:OnServerExecuteSkill", "Data Return=%s", TEXT_SKILL_NOT_EXIST)
        return
    end

    local ret

    --检查施法者死亡状态
    ret = self:TestSkill(SKILL_TEST_CASTER_DEATH, skillData)
    if ret ~= 0 then
        log_game_debug("SkillSystem:OnServerExecuteSkill", "Death Return=%s", ret)
        return
    end

    --检查CD时间
    ret = self:TestSkill(SKILL_TEST_COLDDOWN, skillData)
    if ret ~= 0 then
        log_game_debug("SkillSystem:OnServerExecuteSkill", "CD Return=%s", ret)
        return
    end

    --检查依赖和排他情况
    ret = self:TestSkill(SKILL_TEST_DEPEND, skillData)
    if ret ~= 0 then
        log_game_debug("SkillSystem:OnServerExecuteSkill", "Depend Return=%s", ret)
        return
    end

    --解析目标
    targets = self:ParseTagerts(targets)

    --标记使用技能的时间
    self:MarkTime(skillData, mogo.getTickCount())

    --施放技能
    self:CastSkill(skillData, targets)
end

--Buff执行技能
function SkillSystem:OnBuffExecuteSkill(skillID)
    log_game_debug("SkillSystem:OnBuffExecuteSkill", "skillID=%s", skillID)

    local theOwner  = self.ptr.theOwner
    local skillData = self:GetSkill(skillID)
    if not skillData then
        log_game_debug("SkillSystem:OnBuffExecuteSkill", "Return=%s", TEXT_SKILL_NOT_EXIST)
        return
    end

    --检查施法者死亡状态
    ret = self:TestSkill(SKILL_TEST_CASTER_DEATH, skillData)
    if ret ~= 0 then
        log_game_debug("SkillSystem:OnBuffExecuteSkill", "Return=%s", ret)
        return
    end

    --检查依赖和排他情况
    ret = self:TestSkill(SKILL_TEST_DEPEND, skillData)
    if ret ~= 0 then
        log_game_debug("SkillSystem:OnBuffExecuteSkill", "Return=%s", ret)
        return
    end

    local targets = lua_map:new()
    self:CastSkill(skillData, targets)
end

--执行定位技能（无目标技能）
function SkillSystem:OnExecutePosSkill(skillID, dir, posX, posY)
end


------------------------------------------------------------------------

--学习技能
function SkillSystem:Learn(skillID)
    local skillData = self:GetSkill(skillID)
    if not skillData then return false end

    --判断是否已习得此技能
    if self.skillBag:Has(skillID) == true then return false end

    --更新习得技能时的Buff
    if self:UpdateLearnBuff(skillData, true) == true then
        if self.skillBag:Add(skillID) == false then
            --回滚
            self:UpdateLearnBuff(skillData, false)
            return false
        end
    end

    return true
end

--忘却技能
function SkillSystem:Unlearn(skillID)
    local skillData = self:GetSkill(skillID)
    if not skillData then return false end

    --判断是否已习得此技能
    if self.skillBag:Has(skillID) == false then return false end

    --更新忘却技能时的Buff
    if self:UpdateLearnBuff(skillData, false) == true then
        if self.skillBag:Remove(skillID) == false then
            --回滚
            self:UpdateLearnBuff(skillData, true)
            return false
        end
    end

    return true
end

function SkillSystem:UpdateLearnBuff(skillData, bIsAdd)
    if bIsAdd == true then
        for k, BuffID in pairs(skillData.learnBuff) do
            if self.skillBuff:Add(BuffID) ~= 0 then
                --回滚
                for i = 1, k - 1 do
                    self.skillBuff:Remove(skillData.learnBuff[i])
                end
                return false
            end
        end
    else
        for k, BuffID in pairs(skillData.learnBuff) do
            if self.skillBuff:Remove(BuffID) ~= 0 then
                --回滚
                for i = 1, k - 1 do
                    self.skillBuff:Add(skillData.learnBuff[i])
                end
                return false
            end
        end
    end
    return true
end

function SkillSystem:AddBuff(buffID)
    return self.skillBuff:Add(buffID)
end

function SkillSystem:RemoveBuff(buffID)
    return self.skillBuff:Remove(buffID)
end


------------------------------------------------------------------------

function SkillSystem:ExecuteSkill(skillID, targetsID)
    --使用技能，由服务器调用（怪物，NPC或宠物）
    self:OnServerExecuteSkill(skillID, targetsID)
    --return self:_DoSkill(mogo.getTickCount(), skillID, targetsID)
end

function SkillSystem:ExecuteBuffSkill(skillID, targetsID)
    --使用技能，由服务器的技能Buff调用
    --return self:_DoSkill(0, skillID, targetsID)
end

function SkillSystem:ChargeSkillReq(clientTick)
    --畜力技能，开始畜力（玩家）

    local theOwner = self.ptr.theOwner

    log_game_debug("SkillSystem:ChargeSkillReq", "")                                      --输出调试，临时代码需要移除

    self.skillChargeRecord.charge_tick = clientTick

    --广播通知
    theOwner:broadcastAOI(true, "ChargeSkillResp", theOwner:getId(), 1)
end

function SkillSystem:CancelChargeSkillReq()
    --畜力技能，取消畜力（玩家）

    local theOwner = self.ptr.theOwner

    log_game_debug("SkillSystem:CancelChargeSkillReq", "")                                --输出调试，临时代码需要移除

    self.skillChargeRecord.charge_tick = 0

    --广播通知
    theOwner:broadcastAOI(true, "ChargeSkillResp", theOwner:getId(), 0)
end


------------------------------------------------------------------------


g_SkillSystem = SkillSystem
return g_SkillSystem





