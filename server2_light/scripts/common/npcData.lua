require "lua_util"

local log_game_debug = lua_util.log_game_debug
local log_game_info  = lua_util.log_game_info
local log_game_error = lua_util.log_game_error

local npcData = {}
npcData.__index = npcData

function npcData:initData()
    local cfgData = lua_util._readXml('/data/xml/NPCData.xml', 'id_i')
    self.cfgData = cfgData
end

function npcData:GetNPCDataById(id)
    if self.cfgData then
    	return self.cfgData[id]
    end
    return
end

g_npcData_mgr = npcData
return g_npcData_mgr


