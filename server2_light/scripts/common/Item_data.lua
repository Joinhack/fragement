
require "lua_util"
require "public_config"

local log_game_info = lua_util.log_game_info
local log_game_debug = lua_util.log_game_debug
local log_game_error = lua_util.log_game_error

local ItemDataMgr = {}
ItemDataMgr.__index = ItemDataMgr


function ItemDataMgr:initForAllItems()
    --解析装备（武器，穿戴等）
    local equipment = lua_util._readXml("/data/xml/ItemEquipment.xml", "id_i") 
    --解析宝石
    local jewel = lua_util._readXml("/data/xml/ItemJewel.xml", "id_i")
    --解析普通道具（礼包或材料等）
    local comItems = lua_util._readXml("/data/xml/ItemCom.xml", "id_i")
    local tbl = {}
    local it = {}
    --合并一起，方便循环遍历
    table.insert(it, equipment)
    table.insert(it, jewel)
    table.insert(it, comItems)
    --将三种道具解析到一个table中
    for _, v in pairs(it) do
        for tk, tv in pairs(v) do
            if tv.itemType ~= nil then
                tbl[tk] = tv
            end
            --log_game_debug("ItemDataMgr:initForAllItems", "tk = %s", tk)
        end
    end
    return tbl
end

function ItemDataMgr:initForEquipValues()
    --装备属性表
    local ev = lua_util._readXml("/data/xml/ItemEquipValues.xml", "id_i") 

    local tbl = {}
    --构建装备属性值索引表
    for k, v in pairs(ev) do
        --构建新key值
        local t = v.quality .. v.vocation .. v.type .. v.level
        local it = {}
        for tk, tv in pairs(v) do
            --剔除无用数据项
            if tk ~= "id"  and tk ~= "vocation" and tk ~= "type" 
                and tk ~= "level" and tk ~= "quality" then
                it[tk] = tv
            end
        end
        tbl[t] = it
        --log_game_debug("ItemDataMgr:initForEquipValues", "t = %s", t)
    end
    --log_game_debug("ItemDataMgr:initForEquipValues", "end")
    return tbl
end
function ItemDataMgr:initForJewelValues()
    local propEffects = lua_util._readXml('/data/xml/PropertyEffect.xml', 'id_i') 
    return self:DataFilter(propEffects)
end

--读取道具表数据，解析为list
function ItemDataMgr:initData()
    --log_game_info("ItemDataMgr:initData", "%s", "parse item data")
    self.ItemDataMgr = {}
    --道具配置
    self.ItemDataMgr[public_config.ITEM_TYPE_CFG_TBL]         = self:initForAllItems()
    --装备数值属性配置
    self.ItemDataMgr[public_config.ITEM_TYPE_EQUIPMENTATTRI]  = self:initForEquipValues()
    --宝石数值属性配置
    self.ItemDataMgr[public_config.ITEM_TYPE_JEWELATTRI]      = self:initForJewelValues()
    --装备分解数值配置
    self.ItemDataMgr[public_config.ITEM_TYPE_DEEQUIPMENT]     = self:initForDeEquip()
    --装备套装属性配置
    self.ItemDataMgr[public_config.ITEM_TYPE_SUITEQUIPMENT]   = self:initForSuitEquipment()
    --紫装兑换属性配置
    self.ItemDataMgr[public_config.ITEM_TYPE_PURPLE_EXCHANGE] = self:initPurpleExchange()
    return
end
--装备分解配置初始化
function ItemDataMgr:initForDeEquip()
    --log_game_info("ItemDataMgr:initForDeEquip", "deequip parsing start")
    local deEquip = lua_util._readXml('/data/xml/ItemDeEquipValues.xml', 'id_i')
    --根据配置表构建新的内存存放形式
    local tbl = {}
    for k, v in pairs(deEquip) do
        local t = v.level
        --校验等级区间段是否配置正确和容错处理
        local min = -1
        local max = -1
        if t[1] == nil then
            log_game_error("ItemDataMgr:initForDeEquip", "configure data error")
            return 
        end
        if t[2] == nil then
            min = t[1]
            max = t[1]
        else
            if t[1] >= t[2] then
                min = t[2]
                max = t[1]
            else
                min = t[1]
                max = t[2]
            end
        end
        --等级数据必须大于零
        if min < 1 or max < 1 then
            log_game_error("ItemDataMgr:initForDeEquip", "level interval error")
            return 
        end
        local it = {}
        for tk, tv in pairs(v) do
            --剔除无用数据项
            if tk ~= "id" and tk ~= "level" 
                and tk ~= "quality" then
                it[tk] = tv
            end
        end
        for i = min, max do
            local key = i .. v.quality
            tbl[key] = it
        end
    end
    return tbl
end
--装备套装属性配置表初始化
function ItemDataMgr:initForSuitEquipment()
    local suitEquip = lua_util._readXml('/data/xml/ItemSuitEquipments.xml', 'id_i')
    if not suitEquip then
        log_game_error("ItemDataMgr:initForSuitEquipment", "ItemSuitEquipments.xml error")
        return {}
    end
    return suitEquip
end
--紫装兑换数据解析
function ItemDataMgr:initPurpleExchange()
    local purples = lua_util._readXml('/data/xml/ItemExchange.xml', 'id_i')
    return self:DataFilter(purples)
end
--配置数据过滤多余的id
function ItemDataMgr:DataFilter(datas)
    local tbl = {}
    for k, v in pairs(datas) do
        local oneData = {}
        for tk, tv in pairs(v) do
            if tk ~= "id" then
                oneData[tk] = tv
            end
        end
        tbl[k] = oneData
    end
    return tbl
end
--取得属性值(需要道具类型值，道具的模板id或是属性值key), 返回属性值table
--没有该项道具，返回1
function ItemDataMgr:GetItem(itemType, itemkey)
    local item = self.ItemDataMgr[itemType] or {}
    if item[itemkey] ~= nil then
        return item[itemkey]
    end    
end

g_itemdata_mgr = ItemDataMgr
return g_itemdata_mgr

