require "lua_util"
local log_game_debug = lua_util.log_game_debug
local log_game_error = lua_util.log_game_error
local log_game_info = lua_util.log_game_info

local  arenic_data = {}
arenic_data.__index = arenic_data

function arenic_data:initData()
    self.cfgData = {}
    local arenicCfg = lua_util._readXml('/data/xml/ArenaLevel.xml', 'id_i')
    for _, v in pairs(arenicCfg) do
        v.id = nil
        table.insert(self.cfgData, v)
    end
    local function less(a, b)
        return a.credit < b.credit
    end
    table.sort( self.cfgData, less )

end

function arenic_data:GetPropEffect(grade)
    local id = grade + 1
    if self.cfgData then
        if self.cfgData[id] then
            return self.cfgData[id].propEffect
        else
            log_game_error("arenic_data:GetPropEffect", "grade = %d", id)
        end
    end
end

function arenic_data:GetCredit(grade)
    local id = grade + 1
    if self.cfgData then
         if self.cfgData[id] then
            return self.cfgData[id].credit
        else
            log_game_error("arenic_data:GetPropEffect", "grade = %d", id)
		 end
    end
end

g_arenic_level = arenic_data
return g_arenic_level
