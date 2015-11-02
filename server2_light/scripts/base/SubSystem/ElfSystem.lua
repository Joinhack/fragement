
require "public_config"
require "error_code"
require "lua_util"
require "reason_def"
-- 任务系统

local log_game_info = lua_util.log_game_info
local log_game_debug = lua_util.log_game_debug
local log_game_error    = lua_util.log_game_error

local _readXml = lua_util._readXml

local ElfSystemFlag = {
    ELFSYSTEM_MSG_HANDLE_SUCCESS = 1,
    HAS_NOT_ENOUGH_TEARS = 2,
    AVATAR_NIL = 3,
    CONSUME_TEARS_FAILED = 4,
    AREAID_FIND_NOT_FOUND = 5,
    CHECK_LEVEL_LIMIT_FAILED = 6,
    SKILLPOINT_NOT_ENOUGH = 7,
    NO_ELFSKILL_CAN_LEARN = 8,
    SKILLBAG_NIL = 9,
    SKILL_LEARNED = 10,
    SKILL_UPGRADE_CFG_NOT_FOUND = 11,
    HAS_NOT_ENOUGH_ITEM_TO_UPGRADE = 12,
    CONSUME_UPGRADE_FAILED = 13,
    PRESKILLID_NOT_LEARN = 14,
    PRICE_CFG_NIL = 15,
    DIAMOND_NOT_ENOUGH = 16,
    LEARNED_HAS_NOT_SKILL = 17,
    NOT_LEARNED_ANY_SKILL = 18,
}


ElfSystem = {}
ElfSystem.__index = ElfSystem


function ElfSystem:SendError(errorId)
    if self.ptr.theOwner == nil or self.ptr.theOwner.client == nil then
    	return
    end
    
    if errorId > ElfSystemFlag.ELFSYSTEM_MSG_HANDLE_SUCCESS then
        log_game_error("ElfSystem:SendError", "dbid=%q; id=%d; name=%s; errorId=%d", self.ptr.theOwner.dbid, self.ptr.theOwner:getId(), self.ptr.theOwner.name, errorId) 
    end
    self.ptr.theOwner.client.ElfSysMsgResp(errorId)
end

function ElfSystem:UpdateElfLearnedSkillId()
    if self.ptr.theOwner == nil then
        return
    end
    if self.ptr.theOwner.client == nil then
        return
    end
    

    self.ptr.theOwner.client.UpdateElfLearnedSkillInfo(self.ptr.theOwner.ElfLearnedSkillId, self.ptr.theOwner.ElfEquipSkillId )
end

function ElfSystem:UpdateElfSkillPoint()
    if self.ptr.theOwner == nil then
        return
    end
    if self.ptr.theOwner.client == nil then
        return
    end
    


    self.ptr.theOwner.client.UpdateElfSkillPoint(self.ptr.theOwner.ElfSkillPoint)
end

function ElfSystem:InitElfAreaTearProg()
    if self.ptr.theOwner == nil then 
        return
    end

    local elfAreaMaxCount = g_elf_mgr:getElfAreaMaxCount()
    
    
    self.ptr.theOwner.elfAreaTearProg = {}

    for i=1, elfAreaMaxCount do
        table.insert(self.ptr.theOwner.elfAreaTearProg, 0) 
    end
end

function ElfSystem:InitElfLearnedSkillId()
    if self.ptr.theOwner == nil then 
        return
    end
   
    self.ptr.theOwner.ElfEquipSkillId = 0
    
    self.ptr.theOwner.ElfLearnedSkillId = {} 

    local elfSkillData = g_elf_mgr.elfSkillData

    for slotIndex, v in pairs(elfSkillData) do
        table.insert(self.ptr.theOwner.ElfLearnedSkillId, {v.skillId, 0})
    end
end

function ElfSystem:InitResetElfSysData()
    if self.ptr.theOwner == nil then 
        return
    end
    
    self.ptr.theOwner.ResetElfSysDataFlag = 0 
    self.ptr.theOwner.ElfSysConsumeItemsRecord = {}
end

function ElfSystem:GMApplyUseTear(areaId, useNum)
    
    if areaId < 0 or areaId > g_elf_mgr:getElfAreaMaxCount() then
        self:SendError(ElfSystemFlag.AREAID_FIND_NOT_FOUND)
        return false
    end

    local avatar = self.ptr.theOwner
    if avatar == nil then
        self:SendError(ElfSystemFlag.AVATAR_NIL)
        return false
    end
--[[
    for k,v in pairs(avatar.skillBag) do
    end
--]]
    if g_elf_mgr:CanActivationArea(areaId, avatar.level) == false then
        self:SendError(ElfSystemFlag.CHECK_LEVEL_LIMIT_FAILED)
        return false
    end

    --初始化    
    if avatar.elfAreaTearProg[areaId] == nil then
        avatar.elfAreaTearProg[areaId] = 0
    end
 
    if (useNum + avatar.elfAreaTearProg[areaId]) > g_elf_mgr.elfAreaLimitData[areaId].lastNodeAreaProgress then
        useNum = g_elf_mgr.elfAreaLimitData[areaId].lastNodeAreaProgress - avatar.elfAreaTearProg[areaId]
        if useNum <= 0 then
            self:SendError(ElfSystemFlag.CONSUME_TEARS_FAILED)
            return false
        end
    end

    --不处理道具扣除
    local startProgress = avatar.elfAreaTearProg[areaId]
    local endProgress = startProgress + useNum
    
    avatar.elfAreaTearProg[areaId] = endProgress
    avatar:triggerEvent(event_config.EVENT_AVATAR_PROPERTIES_RECALCULATE) --触发属性刷新 
    local nodeList = {}
    local nodeCount = g_elf_mgr:getAwardList(nodeList, areaId, startProgress, endProgress)
    if nodeCount > 0 then
        for i=1, nodeCount do
            local tmpNode = nodeList[i]
            if tmpNode then
                if tmpNode.AwardSkillPoint ~= nil and tmpNode.AwardSkillPoint ~= 0 then
                    avatar.ElfSkillPoint = avatar.ElfSkillPoint + tmpNode.AwardSkillPoint
                    self:UpdateElfSkillPoint()
--                    avatar:SkillUpgradeReq(tmpNode.AwardSkillPoint[1], tmpNode.AwardSkillId[2])
                end
            end
        end
    end

    avatar.client.ElfAreaTearProgResp(avatar.elfAreaTearProg)
    self:SendError(ElfSystemFlag.ELFSYSTEM_MSG_HANDLE_SUCCESS)
    return true 
end

function ElfSystem:ApplyUseTear(areaId, useNum)
    if areaId < 0 or areaId > g_elf_mgr:getElfAreaMaxCount() then
        self:SendError(ElfSystemFlag.AREAID_FIND_NOT_FOUND)
        return false
    end

    local avatar = self.ptr.theOwner
    if avatar == nil then
        self:SendError(ElfSystemFlag.AVATAR_NIL)
        return false
    end
--[[
    for k,v in pairs(avatar.skillBag) do
    end
--]]
    if g_elf_mgr:CanActivationArea(areaId, avatar.level) == false then
        self:SendError(ElfSystemFlag.CHECK_LEVEL_LIMIT_FAILED)
        return false
    end

    --初始化    
    if avatar.elfAreaTearProg[areaId] == nil then
        avatar.elfAreaTearProg[areaId] = 0
    end
 
    if (useNum + avatar.elfAreaTearProg[areaId]) > g_elf_mgr.elfAreaLimitData[areaId].lastNodeAreaProgress then
        useNum = g_elf_mgr.elfAreaLimitData[areaId].lastNodeAreaProgress - avatar.elfAreaTearProg[areaId]
        if useNum <= 0 then
            self:SendError(ElfSystemFlag.CONSUME_TEARS_FAILED)
            return false
        end
    end
    

    local itemId = g_GlobalParamsMgr:GetParams('goddessTearItemTypeId', 1100076)
    local hasEnoughFlag = avatar.inventorySystem:HasEnoughItems(itemId, useNum)
    if not hasEnoughFlag then
        self:SendError(ElfSystemFlag.HAS_NOT_ENOUGH_TEARS)
        return false
    end
    

    local consumeSuccessFlag = avatar:DelItem(itemId, useNum, reason_def.elfUseTear)
    if 0 ~= consumeSuccessFlag then
        self:SendError(ElfSystemFlag.CONSUME_TEARS_FAILED)
        return false
    end
    --增加消耗道具记录
    self:AddConsumeItemsRecord(itemId, useNum)

    --初始化    
    if avatar.elfAreaTearProg[areaId] == nil then
        avatar.elfAreaTearProg[areaId] = 0
    end

    local startProgress = avatar.elfAreaTearProg[areaId]
    local endProgress = startProgress + useNum
    
    avatar.elfAreaTearProg[areaId] = endProgress
    avatar:triggerEvent(event_config.EVENT_AVATAR_PROPERTIES_RECALCULATE) --触发属性刷新 
    local nodeList = {}
    local nodeCount = g_elf_mgr:getAwardList(nodeList, areaId, startProgress, endProgress)
    if nodeCount > 0 then
        for i=1, nodeCount do
            local tmpNode = nodeList[i]
            if tmpNode then
                if tmpNode.AwardSkillPoint ~= nil and tmpNode.AwardSkillPoint ~= 0 then
                    avatar.ElfSkillPoint = avatar.ElfSkillPoint + tmpNode.AwardSkillPoint
                    self:UpdateElfSkillPoint()
--                    avatar:SkillUpgradeReq(tmpNode.AwardSkillPoint[1], tmpNode.AwardSkillId[2])
                end
            end
        end
    end

    avatar.client.ElfAreaTearProgResp(avatar.elfAreaTearProg)
    self:SendError(ElfSystemFlag.ELFSYSTEM_MSG_HANDLE_SUCCESS)
    return true 
end

function ElfSystem:ElfEquipSkill(skillId)

    local avatar = self.ptr.theOwner
    if avatar == nil then
        self:SendError(ElfSystemFlag.AVATAR_NIL)
        return false
    end
--[[
    local skillBagHas = false
    for skillId, v in pairs(avatar.skillBag) do
        if skillId == skillId then
            skillBagHas = true
            break
        end
    end

    if skillBagHas == false then
        self:SendError(ElfSystemFlag.SKILLBAG_HAS_NOT_SKILL)
        return false
    end
--]]
    local elfLearnedSkillId = avatar.ElfLearnedSkillId
    for i=1, #elfLearnedSkillId do
        if skillId == elfLearnedSkillId[i][1] and elfLearnedSkillId[i][2] >= 1 then
            avatar.ElfEquipSkillId = skillId
            self:UpdateElfLearnedSkillId()
            self:SendError(ElfSystemFlag.ELFSYSTEM_MSG_HANDLE_SUCCESS)
            return true
        end
    end 

    self:SendError(ElfSystemFlag.LEARNED_HAS_NOT_SKILL)
    return false
end

function ElfSystem:RandomLearnElfSkill()
    
    local avatar = self.ptr.theOwner
    if avatar == nil then
        self:SendError(ElfSystemFlag.AVATAR_NIL)
        return false
    end
    

    local curElfSkillPoint = avatar.ElfSkillPoint
    if 0 == curElfSkillPoint then
        self:SendError(ElfSystemFlag.SKILLPOINT_NOT_ENOUGH) 
        return false
    end

    local rntFlag, tmpLearnSkillId, tmpSkillIndex = g_elf_mgr:getRandomNewElfSkillCfg(avatar.ElfLearnedSkillId)
    if rntFlag == true then
--[[
        local tmpAvatarSkillBag = avatar.skillBag
        if tmpAvatarSkillBag ~= nil then
            for skillId, v in pairs(tmpAvatarSkillBag) do
                if skillId == tmpLearnSkillId then
                     self:SendError(ElfSystemFlag.SKILL_LEARNED) 
                    return false
                end
            end
        else
            self:SendError(ElfSystemFlag.SKILLBAG_NIL)
            return false
        end  
        --向cell发起学习技能
        avatar:SkillUpgradeReq(0, tmpLearnSkillId)
--]]
    else
        self:SendError(ElfSystemFlag.NO_ELFSKILL_CAN_LEARN) 
        return false
    end
    --扣除技能点
    avatar.ElfSkillPoint = curElfSkillPoint - 1

    self:UpdateElfSkillPoint()

    avatar.ElfLearnedSkillId[tmpSkillIndex] = {tmpLearnSkillId, 1}

    --人生一次学技能自动装备上
    if avatar.ElfEquipSkillId == 0 then
        avatar.ElfEquipSkillId = tmpLearnSkillId
    end


    self:UpdateElfLearnedSkillId()


    self:SendError(ElfSystemFlag.ELFSYSTEM_MSG_HANDLE_SUCCESS)
    return true
end

function ElfSystem:ElfSkillUpgrade(newSkillId)
    --找玩家
    local avatar = self.ptr.theOwner
    if avatar == nil then
        self:SendError(ElfSystemFlag.AVATAR_NIL)
        return false
    end

    --找配置
    local skillUpgradeCfg = g_elf_mgr:getSkillUpgradeCfgByPreSkillId(newSkillId)    
    if skillUpgradeCfg == nil then
        self:SendError(ElfSystemFlag.SKILL_UPGRADE_CFG_NOT_FOUND)
        return false
    end

    --已学精灵技能中是否有这个技能的依赖技能
    local elfLearnedSkillId = avatar.ElfLearnedSkillId
    local canUpgradeFlag = false
    local tmpSkillIndex = 0
    for i=1, #elfLearnedSkillId do
        if elfLearnedSkillId[i][1] == skillUpgradeCfg.preSkillId and elfLearnedSkillId[i][2] >= 1 then
            tmpSkillIndex = i
            canUpgradeFlag = true
            break
        end
    end
    
    if canUpgradeFlag == false then
        self:SendError(ElfSystemFlag.PRESKILLID_NOT_LEARN)
        return false
    end

    --是否有足够道具可扣除
    for itemId, useNum in pairs(skillUpgradeCfg['consume']) do
        local hasEnoughFlag = avatar.inventorySystem:HasEnoughItems(itemId, useNum)
        if not hasEnoughFlag then
            self:SendError(ElfSystemFlag.HAS_NOT_ENOUGH_ITEM_TO_UPGRADE)
            return false
        end
    end

    --扣除道具
    for itemId, useNum in pairs(skillUpgradeCfg['consume']) do
        local consumeSuccessFlag = avatar:DelItem(itemId, useNum, reason_def.elfUpgradeSkill)
        if 0 ~= consumeSuccessFlag then
            self:SendError(ElfSystemFlag.CONSUME_UPGRADE_FAILED)
            return false
        end
        --增加消耗道具记录
        self:AddConsumeItemsRecord(itemId, useNum)
    end

    --向cell发起升级技能
--    avatar:SkillUpgradeReq(0, newSkillId)  
    
    avatar.ElfLearnedSkillId[tmpSkillIndex] = {skillUpgradeCfg.id, 1}

    --如果装备了上一个技能，那么现在要装备升级后的技能
    if avatar.ElfEquipSkillId == newSkillId then
        avatar.ElfEquipSkillId = skillUpgradeCfg.id
    end

    self:UpdateElfLearnedSkillId()

    self:SendError(ElfSystemFlag.ELFSYSTEM_MSG_HANDLE_SUCCESS)
    return true 
end

function ElfSystem:ResetElfSkill()

    --找玩家
    local avatar = self.ptr.theOwner
    if avatar == nil then
        self:SendError(ElfSystemFlag.AVATAR_NIL)
        return false
    end

    local hasLearnedSkill = false
    local elfLearnedSkillId = avatar.ElfLearnedSkillId
    for i=1, #elfLearnedSkillId do
        if elfLearnedSkillId[i][2] > 0 then
            hasLearnedSkill = true
            break
        end
    end
    
    if not hasLearnedSkill then
        self:SendError(ElfSystemFlag.NOT_LEARNED_ANY_SKILL)
        return false            
    end
    

    local price = g_priceList_mgr:NeedMoney(22) 
    if not price then
        self:SendError(ElfSystemFlag.PRICE_CFG_NIL)
        return false
    end

    local needConsumeDiamond = 0
    for k,v in pairs(price) do
        if k == public_config.DIAMOND_ID then
            needConsumeDiamond = v
            break
        end
    end
    
    if needConsumeDiamond == nil or needConsumeDiamond <= 0 then
        self:SendError(ElfSystemFlag.PRICE_CFG_NIL) 
        return false
    end


    --扣钻石
    if avatar.diamond < needConsumeDiamond then
        self:SendError(ElfSystemFlag.DIAMOND_NOT_ENOUGH)
        return false
    end

    avatar:AddDiamond(-needConsumeDiamond, reason_def.reset_elf_skill) 

    --遗忘技能，返还技能点
    local elfSkillPointBack = 0
    for i=1, #elfLearnedSkillId do
        if elfLearnedSkillId[i][2] > 0 then
            elfSkillPointBack = elfSkillPointBack + 1
        end
        elfLearnedSkillId[i][2] = 0
    end

    avatar.ElfSkillPoint = avatar.ElfSkillPoint + elfSkillPointBack

    avatar.ElfEquipSkillId = 0
   
    self:UpdateElfSkillPoint() 
    self:UpdateElfLearnedSkillId()

    self:SendError(ElfSystemFlag.ELFSYSTEM_MSG_HANDLE_SUCCESS)
    
--[[
    local elfLearnedSkillId = avatar.ElfLearnedSkillId
    local elfSkillPoint = 0 
    for i=1, #elfLearnedSkillId do
        for skillId, v in pairs(avatar.skillBag) do
            if elfLearnedSkillId[i] == skillId then
                elfSkillPoint = elfSkillPoint + 1
                avatar:SkillUpgradeReq(elfLearnedSkillId[i], 0)            
                break
            end
        end
    end

    --清空主角已学精灵技能，返还技能点
    self:InitElfLearnedSkillId()    
    avatar.ElfSkillPoint = avatar.ElfSkillPoint + elfSkillPoint
    avatar.ElfEquipSkillId = 0

    self:SendError(ElfSystemFlag.ELFSYSTEM_MSG_HANDLE_SUCCESS)
--]]
    return true
end

function ElfSystem:CheckResetElfSysData()
    
    --找玩家
    local avatar = self.ptr.theOwner
    if avatar == nil then
        self:SendError(ElfSystemFlag.AVATAR_NIL)
        return
    end

    --预防有记录为空的情况
    if avatar.ResetElfSysDataFlag == nil then
        avatar.ResetElfSysDataFlag = 0
    end

    if avatar.ResetElfSysDataFlag == 0 then
        return
    end
    --返还道具
    local tmpElfSysConsumeItemsRecord = avatar.ElfSysConsumeItemsRecord
    for itemId, consumedNum in pairs(tmpElfSysConsumeItemsRecord) do
        if consumedNum > 0 then
            avatar:AddItem(itemId, consumedNum, reason_def.elf_all_reset)   
        end
    end

    self:InitResetElfSysData()
    self:InitElfAreaTearProg()
    self:InitElfLearnedSkillId()
end

function ElfSystem:AddConsumeItemsRecord(itemId, num)
    --找玩家
    local avatar = self.ptr.theOwner
    if avatar == nil then
        self:SendError(ElfSystemFlag.AVATAR_NIL)
        return false
    end
    
    local tmpElfSysConsumeItemsRecord = avatar.ElfSysConsumeItemsRecord
    if tmpElfSysConsumeItemsRecord[itemId] == nil then
        avatar.ElfSysConsumeItemsRecord[itemId] = num
    else
        avatar.ElfSysConsumeItemsRecord[itemId] = tmpElfSysConsumeItemsRecord[itemId] + num
    end
end

function ElfSystem:new( owner )
    local newObj = { }
    setmetatable(newObj, {__index = ElfSystem})
    newObj.ptr = {}
    setmetatable(newObj.ptr, {__mode = "v"})


    newObj.ptr.theOwner = owner
    
 
    return newObj
end


return ElfSystem
