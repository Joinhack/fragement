require "lua_util"
-----------------------------------------------------------------------------------
local log_game_info    = lua_util.log_game_info
local log_game_debug   = lua_util.log_game_debug
local log_game_error   = lua_util.log_game_error
local globalbase_call  = lua_util.globalbase_call

local SpecialEffectsData = {}
SpecialEffectsData.__index = SpecialEffectsData

function SpecialEffectsData:initData()
	local specData = lua_util._readXml('/data/xml/EquipSpecialEffects.xml', 'id_i')
	if not specData then
		log_game_error("SpecialEffectsData:initData", "EquipSpecialEffects.xml error!")
		return
	end
	self.cfgData = specData
end
function SpecialEffectsData:GetCfgData(id)
	if self.cfgData then
		return self.cfgData[id]
	end
end
g_spec_mgr = SpecialEffectsData
return g_spec_mgr