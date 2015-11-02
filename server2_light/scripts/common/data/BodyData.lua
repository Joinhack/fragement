require "lua_util"

local BodyDataMgr = {}
BodyDataMgr.__index = BodyDataMgr

--读取配置数据
function BodyDataMgr:initData()
    self.bodyData = lua_util._readXmlBy2Key('/data/xml/BodyEnhanceData.xml', 'pos', 'level')
end

--根据类型和级别获取对应身体的配置属性
function BodyDataMgr:GetBodyInfo( pos, level )
    if self.bodyData and self.bodyData[pos] then
        return self.bodyData[pos][level]
    end
    return nil
end

g_body_mgr = BodyDataMgr
return g_body_mgr