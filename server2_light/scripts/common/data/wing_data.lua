require "lua_util"
-----------------------------------------------------------------------------------
local log_game_info    = lua_util.log_game_info
local log_game_debug   = lua_util.log_game_debug
local log_game_error   = lua_util.log_game_error
local globalbase_call  = lua_util.globalbase_call
-----------------------------------------------------------------------------------
local WING_BASE_INDEX  = public_config.WING_BASE_INDEX
local WING_LEVEL_INDEX = public_config.WING_LEVEL_INDEX
-----------------------------------------------------------------------------------
local WingData = {}
WingData.__index = WingData
-----------------------------------------------------------------------------------
--加载飞龙系统配置数据
-----------------------------------------------------------------------------------
function WingData:initData()
	local wingData = lua_util._readXml('/data/xml/Wing.xml', 'id_i')
    local wingLevelData = lua_util._readXml('/data/xml/WingLevel.xml', 'id_i')
    if not wingData then
    	log_game_error("WingData:initData", "Wing.xml configure error")
    	return
    end
    if not wingLevelData then
    	log_game_error("WingData:initData", "WingLevel.xml configure error")
    	return
    end
    local cfgData = {}
    cfgData[WING_BASE_INDEX]  = wingData
    cfgData[WING_LEVEL_INDEX] = wingLevelData
    self.cfgData = cfgData
end
function WingData:GetWingCfg(id)
	local wingData = self.cfgData[WING_BASE_INDEX]
	local wData = wingData[id]
	if not wData then
		log_game_error("WingData:GetWingCfg", "id = %d wing cfg nil !", id)
	end
	return wData
end
function WingData:GetWingLevelCfg(id, level)
    local wingData = self.cfgData[WING_LEVEL_INDEX]
    for _, item in pairs(wingData) do
        local wId = item.wingId or 0
        local wlv = item.level  or 0
        if wId == id and level == wlv then
            return item
        end
    end
    log_game_error("WingData:GetWingLevelCfg", "id=%d;level=%d wing level cfg nil !", id, level)
    return
end
-----------------------------------------------------------------------------------
g_wing_mgr = WingData
return g_wing_mgr