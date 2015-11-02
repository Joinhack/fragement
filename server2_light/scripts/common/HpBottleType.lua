require "lua_util"

--log_game_debug = lua_util.log_game_debug
--log_game_info  = lua_util.log_game_info
--log_game_error = lua_util.log_game_error

local HpBottleType = {}
HpBottleType.__index = HpBottleType 

--血瓶类型初始化
function HpBottleType:initData()
    local cfgData = lua_util._readXml('/data/xml/HpTypes.xml', 'id_i')
    self.cfgData = cfgData
end
--根据血瓶的类型索引获取血瓶的数值
function HpBottleType:GetBottleData(idx)
    if self.cfgData ~= nil then
        return self.cfgData[idx]
    end
end

g_hpBottleType_mgr = HpBottleType
return g_hpBottleType_mgr
