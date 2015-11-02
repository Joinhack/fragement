require "lua_util"

local log_game_debug = lua_util.log_game_debug
local log_game_warning = lua_util.log_game_warning
local log_game_info = lua_util.log_game_info
local log_game_error = lua_util.log_game_error

local FumoData = {}
FumoData.__index = FumoData


--读取配置数据
function FumoData:initData()
    log_game_debug("FumoData:initData", "")

    local effect_data = lua_util._readXml("/data/xml/fumo_effect.xml", "id_i")
    local data_maker = lua_util._readXml("/data/xml/fumo_datamaker.xml", "id_i")



    self.data_maker = self:format_maker(data_maker)
    self.effect_data = effect_data
    
end


--读取配置数据
function FumoData:format_maker(data)

	local ret ={}
    
    for k,a_data in pairs(data) do
    	local prop_id = a_data.prop
    	local range_id = a_data.range
    	local tmp = {}
    	tmp.min = a_data.min
    	tmp.max = a_data.max
    	if not ret[prop_id] then
    		ret[prop_id] = {}
    	end
    	ret[prop_id][range_id] = tmp    	
    end
    return ret
    
end



function FumoData:get_effect_data(name)
	return self.effect_data
end

function FumoData:get_fumo_random(name)
	return self.data_maker
end


g_fumodata = FumoData
return g_fumodata