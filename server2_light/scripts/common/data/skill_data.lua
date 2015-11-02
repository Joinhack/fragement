require "lua_util"

local log_game_debug = lua_util.log_game_debug
local log_game_error = lua_util.log_game_error


SkillData = {}
SkillData.__index = SkillData

function SkillData:initData()
    skill_data = lua_util._readXml('/data/xml/SkillData.xml', 'id_i')
    if not skill_data then
    	log_game_error("SkillData:InitData", "skill data cfg error")
    	return
    end
    self.CfgSkillData = skill_data
end

function SkillData:GetSkillData(skillId)
	if self.CfgSkillData then
		return self.CfgSkillData[skillId]
	end
end
function SkillData:GetAllSkillData()
	if self.CfgSkillData then
		return self.CfgSkillData
	end
end
g_skillData_mgr = SkillData
return g_skillData_mgr