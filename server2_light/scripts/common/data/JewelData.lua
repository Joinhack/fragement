require "lua_util"
require "public_config"

local JewelDataMgr = {}
JewelDataMgr.__index = JewelDataMgr

local JEWEL_MAX_LV = 9

--读取配置数据
function JewelDataMgr:initData()
    self.jewelDataList = lua_util._readXml("/data/xml/ItemJewel.xml", "id_i")
    --宝石暂时类型都是1，后面扩展需要重新组织一次jewelDataMap的数据
    --self.jewelDataMap = lua_util._readXmlBy2Key("/data/xml/ItemJewel.xml", "subtype_i", "level_i")
    self.jewelDataMap = {}
    for id, jewel in pairs(self.jewelDataList) do
        if jewel.level and jewel.subtype and 
            jewel.subtype > 0 and jewel.subtype <= JEWEL_MAX_LV then
            if not self.jewelDataMap[jewel.subtype] then
                self.jewelDataMap[jewel.subtype] = {}
            end
            self.jewelDataMap[jewel.subtype][jewel.level] = jewel
        else
            lua_util.log_game_error("JewelDataMgr:initData", "id = %d", id)
        end
    end
    --[[用上type字段
    self.jewelDataMap = {}
    for id, jewel in pairs(self.jewelDataList) do
        if not self.jewelDataMap[jewel.type] then
            self.jewelDataMap[jewel.type] = {}
        end
        if not self.jewelDataMap[jewel.type][jewel.subtype] then
            self.jewelDataMap[jewel.type][jewel.subtype] = {}
        end
        self.jewelDataMap[jewel.type][jewel.subtype][jewel.level] = jewel
    end
    ]]
    --self:TestData(self.jewelDataMap)
end

--根据唯一id获取对应宝石的配置属性
function JewelDataMgr:GetJewelInfoById(Id)
    if self.jewelDataList then
        return self.jewelDataList[Id]
    end
    return nil
end

--根据类型和级别获取对应宝石的配置属性
function JewelDataMgr:GetJewelInfo( type, level )
    if self.jewelDataMap and self.jewelDataMap[type] then
        return self.jewelDataMap[type][level]
    end
end

function JewelDataMgr:TestData( data )
    for key, val in pairs(data) do
        if type(val) == "table" then
--            print("table [".. tostring(key).. "] = {")
            self:TestData( val )
--            print("}")
        else 
--            print(key, val)
        end
    end
end

g_jewel_mgr = JewelDataMgr
return g_jewel_mgr
