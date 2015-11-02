require "lua_util"
require "skill_data"
require "reason_def"
local log_game_debug = lua_util.log_game_debug
local log_game_error = lua_util.log_game_error

SkillUpgradeSystem = {}
SkillUpgradeSystem.__index =SkillUpgradeSystem
local ret_code = 
{
    SUCCESS                    = 0,
    NEXT_SKILL_NOT_EXIST       = 1,
    NEXT_SKILL_ERROR           = 2,
    MONEY_OR_PVP_UNENOUGH      = 3,
    CURRENCY_SKILL_NOT_LEARNED = 4,
    NEXT_SKILL_HAS_LENRNED     = 5,
    CURRENCY_SKILL_ERROR       = 6,
}
function SkillUpgradeSystem:SkillUpReq(avatar, skillId, nextSkillId)
	local retCode = self:ActionSkillUp(avatar, skillId, nextSkillId)
	self:SkillUpResp(avatar, retCode)
end
function SkillUpgradeSystem:ActionSkillUp(avatar, skillId, nextSkillId)
    log_game_debug("SkillUpgradeSystem:SkillUpReq", "dbid=%q;name=%s;skillId=%d;nextSkillId=%d", 
		avatar.dbid, avatar.name, skillId, nextSkillId)
    if skillId == 0 and nextSkillId > 0 then
        return self:ZeroLevelLearn(avatar, nextSkillId)
    end
    return self:UpgradeLearn(avatar, skillId, nextSkillId)
end
function SkillUpgradeSystem:SkillUpResp(avatar, retCode)
	if avatar:hasClient() then
		avatar.client.SkillUpResp(retCode)
	end
end
function SkillUpgradeSystem:UpgradeLearn(avatar, skillId, nextSkillId)
    local retCode     = 0
    local currSkills  = {}
    local nextSkills  = {}
    retCode, currSkills = self:GetRelatedSkills(avatar, skillId, false)
    if retCode ~= ret_code.SUCCESS then
        return retCode
    end
    retCode, nextSkills = self:GetRelatedSkills(avatar, nextSkillId, true)
    if retCode ~= ret_code.SUCCESS then
        return retCode
    end
    retCode = self:SkillCheck(avatar, currSkills, false)
    if retCode ~= ret_code.SUCCESS then
        return retCode
    end
    retCode = self:SkillCheck(avatar, nextSkills, true)
    if retCode ~= ret_code.SUCCESS then
        return retCode
    end
    return self:ActionCostAndSkills(avatar, nextSkillId, currSkills, nextSkills)
end
function SkillUpgradeSystem:ZeroLevelLearn(avatar, nextSkillId)
    local skillData = self:GetSkillData(avatar, nextSkillId)
    if not skillData then
        return ret_code.NEXT_SKILL_NOT_EXIST
    end
    if skillData.level ~= 1 then
        log_game_error("SkillUpgradeSystem:ZeroLevelUpgrade", "dbid=%q;name=%s;level=%d",
            avatar.dbid, avatar.name, skillData.level)
        return ret_code.NEXT_SKILL_ERROR
    end
    local retCode, nextSkills = self:GetRelatedSkills(avatar, nextSkillId, true)
    if retCode ~= ret_code.SUCCESS then
       return retCode
    end
    retCode = self:SkillCheck(avatar, nextSkills, true)
    if retCode ~= ret_code.SUCCESS then
        return retCode
    end
    return self:ActionCostAndSkills(avatar, nextSkillId, {}, nextSkills)
end
function SkillUpgradeSystem:ActionCostAndSkills(avatar, nextSkillId, currSkills, nextSkills)
	if not self:ReduceMoneyAndPvp(avatar, nextSkillId, currSkills, nextSkills) then
    	return ret_code.MONEY_OR_PVP_UNENOUGH
    end
    self:UnlearnSkills(avatar, currSkills)
    self:LearnSkills(avatar, nextSkills)
    return ret_code.SUCCESS	
end

--做金币扣减和pvp值扣减
function SkillUpgradeSystem:ReduceMoneyAndPvp(avatar, skillId, currSkills, nextSkills)
    local skillData = self:GetSkillData(avatar, skillId)
    local gold      = skillData.moneyCost or 0
    local pvpCost   = skillData.pvpCreditCost or 0
    return self:SkillUpDeductCheck(avatar, gold, pvpCost, skillId, currSkills, nextSkills)
end
--钻石同步处理
function SkillUpgradeSystem:SkillUpDeductCheck(avatar, gold, pvpCost, skillId, currSkills, nextSkills)
    log_game_debug("SkillUpgradeSystem:SkillUpDeductCheck", "dbid=%q;name=%s;gold=%d;pvpCost=%d;skillId=%d;currSkills=%s;nextSkills=%s",
        avatar.dbid, avatar.name, gold, pvpCost, skillId, mogo.cPickle(currSkills), mogo.cPickle(nextSkills))
    if avatar.gold >= gold and avatar.pvpCredit >= pvpCost then
        avatar:AddGold(-gold, reason_def.skill_up)
        if not avatar.pvpCredit then
            avatar.pvpCredit = 0
        end
        if pvpCost > 0 then
            log_game_info("SkillUpgradeSystem:SkillUpDeductCheck", "dbid=%q;name=%s;pvpCredit=%d;pvpCost=%d",
                avatar.dbid, avatar.name, avatar.pvpCredit, avatar.pvpCost)
            avatar.pvpCredit = avatar.pvpCredit - pvpCost
        end
        avatar:OnSkillLevelUp(skillId)
        return true
    end
    return false
end
function SkillUpgradeSystem:SkillCheck(avatar, skills, isNextSkill)
    for _, skillId in pairs(skills) do
        if isNextSkill and self:Has(avatar, skillId) then
            return ret_code.NEXT_SKILL_HAS_LENRNED
        end
        if not isNextSkill and not self:Has(avatar, skillId) then
            return ret_code.CURRENCY_SKILL_NOT_LEARNED
        end
    end
    return ret_code.SUCCESS
end

function SkillUpgradeSystem:GetRelatedSkills(avatar, skillId, isNextSkill)
   local skillData = self:GetSkillData(avatar, skillId)
   if not skillData then
       if isNextSkill then
           log_game_error("SkillUpgradeSystem:GetRelatedSkills", "next skill nil! dbid=%q;name=%s;skillId=%d", 
               avatar.dbid, avatar.name, skillId)
           return ret_code.NEXT_SKILL_NOT_EXIST, {}
       else
           log_game_error("SkillUpgradeSystem:GetRelatedSkills", "skill nil! dbid=%q;name=%s;skillId=%d", 
               avatar.dbid, avatar.name,  skillId)
           return ret_code.CURRENCY_SKILL_ERROR, {}
       end
   end
   local relatedSkills = self:RelatedSkillId(avatar, skillId)
   table.insert(relatedSkills, skillId)
   return ret_code.SUCCESS, relatedSkills
end
function SkillUpgradeSystem:RelatedSkillId(avatar, skillId)
   local skillCfg = g_skillData_mgr:GetAllSkillData()
   local sks = self:GetSkillData(avatar, skillId)
   local skillTable = {}
   for k, v in pairs(skillCfg) do
       if v.posi and sks.posi and v.level and sks.level and
          v.id ~= sks.id and 
          v.limitVocation == sks.limitVocation and
          v.posi == sks.posi and
          v.level == sks.level then
           table.insert(skillTable, v.id)
       end
   end
   return skillTable
end
function SkillUpgradeSystem:GetSkillData(avatar, skillId)
	local skillData = g_skillData_mgr:GetSkillData(skillId)
    if not skillData then
        log_game_error("SkillUpgradeSystem:GetSkillData", "dbid=%q;name=%s;skillId=%d",
            avatar.dbid, avatar.name, skillId)
    end
    return skillData
end
function SkillUpgradeSystem:Has(avatar, skill_id)
	return (avatar.skillBag[skill_id] == 1)
end

function SkillUpgradeSystem:UnlearnSkills(avatar, skills)
    for _, skillId in pairs(skills) do
        avatar.cell.UnlearnReq(skillId)
    end
end
function SkillUpgradeSystem:LearnSkills(avatar, skills)
    for _, skillId in pairs(skills) do
        avatar.cell.LearnReq(skillId)
    end
end

return SkillUpgradeSystem