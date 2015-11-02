-- 技能背包

require "lua_util"
require "lua_map"


local log_game_debug = lua_util.log_game_debug


SkillBag = {}
SkillBag.__index = SkillBag


function SkillBag:New(owner, skillObj)
    local newObj    = {}
    newObj.ptr      = {}
    setmetatable(newObj,        {__index = SkillBag})
    setmetatable(newObj.ptr,    {__mode = "v"})

    newObj.ptr.theOwner	= owner
    newObj.ptr.theSkill	= skillObj

    --技能背包,由角色技能背包属性值初始化
    newObj.skillBag 	    = owner.skillBag or {}

    --技能使用时间，用于技能CD计算
    newObj.skillCastTick    = lua_map:new()
    
    return newObj
end

function SkillBag:Add(skill_id)
	if self:Has(skill_id) == true then return false end
	self.skillBag[skill_id] = 1 
	self:Send_SkillBagResp()
	return true
end

function SkillBag:Remove(skill_id)
    --log_game_debug("SkillBag:Remove", "----del id = %s--", tostring(skill_id))
    self.skillBag[skill_id] = nil
	--table.remove(self.skillBag, skill_id)
	self:Send_SkillBagResp()
end

function SkillBag:Has(skill_id)
	return (self.skillBag[skill_id] == 1)
end


------------------------------------------------------------------------

--通知技能背包更新
function SkillBag:Send_SkillBagResp()
    local theOwner = self.ptr.theOwner
    if theOwner.c_etype ~= public_config.ENTITY_TYPE_AVATAR then return end
    --theOwner.base.client.SkillBagResp(self.skillBag)
    theOwner.base.SkillBagSyncToBase(self.skillBag)
end


--------------------------------------------------------------------------

--标记技能使用时间
function SkillBag:MarkCastTick(skillData, timeTick)
    if not timeTick then timeTick = mogo.getTickCount() end
    self.skillCastTick:replace(skillData.id, timeTick)
end

--获取指定技能最近一次标记的使用时间
function SkillBag:GetCastTick(skillData)
    local castTick = self.skillCastTick[skillData.id]
    if not castTick then return 0 end
    return castTick
end

--重置技能使用时间
function SkillBag:ResetCastTick()
    self.skillCastTick:clear()
end







