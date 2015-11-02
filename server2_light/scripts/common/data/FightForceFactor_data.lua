
require "lua_util"
local log_game_debug      = lua_util.log_game_debug
local log_game_error      = lua_util.log_game_error

local FightForceFactorMgr = {}
FightForceFactorMgr.__index = FightForceFactorMgr

local  FIGHT_FORCE_INDEX  = 1
--读取配置数据
function FightForceFactorMgr:initData()
	local fffData = lua_util._readXml("/data/xml/FightForceFactor.xml", "id_i")
    if not fffData then
        log_game_error("FightForceFactorMgr:initData", "FightForceFactor.xml lose or error")
        return
    end
    if not fffData[FIGHT_FORCE_INDEX] then
    	log_game_error("FightForceFactorMgr:initData", "FightForceFactor.xml data error")
    	return
    end
    self.data = fffData
end

function FightForceFactorMgr:GetCfg()
	local cfgData = self.data[FIGHT_FORCE_INDEX]
	cfgData["id"] = nil
    return cfgData
end

g_fightForce_mgr = FightForceFactorMgr
return g_fightForce_mgr