
-- 身体强化系统
require "CommonXmlConfig"
require "public_config"
require "error_code"
require "bodyEnhance_config"

local log_game_info = lua_util.log_game_info
local log_game_debug = lua_util.log_game_debug
local log_game_error = lua_util.log_game_error

local INSTANCE_GRIDINDEX        = public_config.ITEM_INSTANCE_GRIDINDEX  --背包索引
local INSTANCE_TYPEID           = public_config.ITEM_INSTANCE_TYPEID     --道具id
local INSTANCE_ID               = public_config.ITEM_INSTANCE_ID         --实例id
local INSTANCE_BINDTYPE         = public_config.ITEM_INSTANCE_BINDTYPE   --绑定类型
local INSTANCE_COUNT            = public_config.ITEM_INSTANCE_COUNT      --堆叠数量
local INSTANCE_SLOTS            = public_config.ITEM_INSTANCE_SLOTS      --宝石插槽
local INSTANCE_EXTINFO          = public_config.ITEM_INSTANCE_EXTINFO    --扩展信息

BodyEnhanceSystem = {}
BodyEnhanceSystem.__index = BodyEnhanceSystem

local bodyName2Index = 
{
    ["head"]       = 1,
    ["neck"]       = 2,
    ["shoulder"]   = 3,
    ["chest"]      = 4,
    ["waist"]      = 5,
    ["arm"]        = 6,
    ["leg"]        = 7,
    ["foot"]       = 8,
    ["finger"]     = 9,
    ["weapon"]     = 10,
}
local bodyIndex2Name = 
{
    [1]            = "head",
    [2]            = "neck",
    [3]            = "shoulder",
    [4]            = "chest",
    [5]            = "waist",
    [6]            = "arm",
    [7]            = "leg",
    [8]            = "foot",
    [9]            = "finger",
    [10]           = "weapon",
}
--判断一个二维数组是否存在array[key1][key2]
local function IsExist( array, key1, key2 )
    if array then
        if array[key1] then
            return array[key1][key2]
        end
    end
    return nil
end
--print table for test
local function TestData( data )
    for key, val in pairs(data) do
        if type(val) == "table" then
--            print("table [".. tostring(key).. "] = {")
            TestData( val )
--            print("}")
        else 
--            print(key, val)
        end
    end
end

function BodyEnhanceSystem:new( owner )
	local newObj = {}
	setmetatable(newObj, {__index = BodyEnhanceSystem})
	newObj.ptr = {}
    setmetatable(newObj.ptr, {__mode = "v"})
    newObj.ptr.theOwner = owner
    local msgMapping = {
        [msgBodyEnhance.MSG_GET_ENHANCE_NIFO] = self.GetEnhanceInfo,
        [msgBodyEnhance.MSG_GET_ENHANCE_PROP] = self.GetEnhanceProperty,
        [msgBodyEnhance.MSG_GET_ENHANCE_RATE] = self.GetEnhanceRate,
        [msgBodyEnhance.MSG_GET_UPGRADE_MATERIAL] = self.GetUpgradeMaterial,
        [msgBodyEnhance.MSG_GET_UPGRADE_GOLD] = self.GetUpgradeGold,
        [msgBodyEnhance.MSG_GET_UPGRADE_CHARACTER_LV] = self.GetUpgradeCharacterLevel,
        [msgBodyEnhance.MSG_CAN_UPGRADE] = self.CanUpgrade,
        [msgBodyEnhance.MSG_UPGRADE] = self.Upgrade,
    }

    newObj.msgMapping = msgMapping
    return newObj
end

function BodyEnhanceSystem:Req( msgId, ...)
    log_game_debug("BodyEnhanceSystem:Req", "msgId = %d", msgId)
    local func = self.msgMapping[msgId]
    if func then
        return func(self, ...)
    else
        log_game_error("BodyEnhanceSystem:Req", "msgId = %d", msgId)
    end
end

function BodyEnhanceSystem:client( )
    return self.ptr.theOwner.client
end

function BodyEnhanceSystem:GetEnhanceInfo( position, level )
    --[[
    print('+++++++++++++++++++++++++++++')
    if type(level) == 'table' then
        lua_util.print_table(level)
    end
    print('+++++++++++++++++++++++++++++')
    log_game_debug("BodyEnhanceSystem:GetEnhanceInfo", "%d", level)
    ]]
    local lv = 0
    if level then
        lv = level
    end
    if not bodyIndex2Name[position] or lv < 0 
        or lv > public_config.MAX_BODY_POS_LEVEL then
        return nil , error_code.ERR_BODY_ENHANCE_PARA
    end
    local info = g_body_mgr:GetBodyInfo(position, lv) 
    if not info then
        return nil, error_code.ERR_BODY_ENHANCE_CONFIG
    end
    return info, error_code.ERR_BODY_ENHANCE_SUCCEED 
end

function BodyEnhanceSystem:GetEnhanceProperty( position, level )
    log_game_debug("BodyEnhanceSystem:GetEnhanceProperty", "can run.")
    local aEnhanceInfo, err = self:GetEnhanceInfo(position, level)
    if err ~= error_code.ERR_BODY_ENHANCE_SUCCEED then
        log_game_error("BodyEnhanceSystem:GetEnhanceProperty", "err = %d", err)
        return nil, err
    end
    if aEnhanceInfo.propertyEffectId then
        local prop = CommonXmlConfig:GetPassivePropertyEffect(aEnhanceInfo.propertyEffectId)
        if prop then
            return prop, error_code.ERR_BODY_ENHANCE_SUCCEED
        end
        log_game_error("BodyEnhanceSystem:GetEnhanceProperty", 
            "prop is nil. aEnhanceInfo.propertyEffectId = %d", aEnhanceInfo.propertyEffectId)
    end
    return nil, error_code.ERR_BODY_ENHANCE_CONFIG
end

function BodyEnhanceSystem:GetEnhanceRate( position, level )
    local aEnhanceInfo, err = self:GetEnhanceInfo(position, level)
    if err ~= error_code.ERR_BODY_ENHANCE_SUCCEED then
        return nil, err
    end
    if aEnhanceInfo and aEnhanceInfo.enhanceRate then
        return aEnhanceInfo.enhanceRate, error_code.ERR_BODY_ENHANCE_SUCCEED
    end
    return nil, error_code.ERR_BODY_ENHANCE_CONFIG
end

----获取升级对应部位和等级所需的金币
function BodyEnhanceSystem:CanUpgrade( position, level, costs)
    if self.ptr.theOwner.body[position] and self.ptr.theOwner.body[position] ~= level -1 then
        return error_code.ERR_BODY_ENHANCE_POS_LEVEL, {}
    end
    log_game_debug("BodyEnhanceSystem:CanUpgrade", "level = %d", level)
    if level >= public_config.MAX_BODY_POS_LEVEL then
        return error_code.ERR_BODY_LEVEL_ALREADY_MAX, {}
    end
    local aEnhanceInfo, err = self:GetEnhanceInfo(position, level)
    if err ~= error_code.ERR_BODY_ENHANCE_SUCCEED then
        log_game_error("BodyEnhanceSystem:CanUpgrade", "err = %d", err)
        return err, {}
    end
    --缺少哪些材料
    local lack = {}

    if aEnhanceInfo then 
        --金币、等级是否够
        if aEnhanceInfo.gold then
            costs.gold = aEnhanceInfo.gold
            if self.ptr.theOwner.gold < aEnhanceInfo.gold then
                lack[public_config.GOLD_ID] = aEnhanceInfo.gold - self.ptr.theOwner.gold
                --return error_code.ERR_BODY_ENHANCE_GOLD_NOT_ENOUGH
            end
        end
        if aEnhanceInfo.characterLevel and self.ptr.theOwner.level < aEnhanceInfo.characterLevel then
            return error_code.ERR_BODY_ENHANCE_LEVEL, {}
        end
        if aEnhanceInfo.material then
            --todo:判断材料
            local myMaterial = self.ptr.theOwner.inventorySystem:GetAllItem(public_config.ITEM_TYPE_MATERIAL)
            local tmp_myMaterial = {}
            --deep copy something
            for _, item in pairs(myMaterial) do
                local it = g_itemdata_mgr:GetItem(public_config.ITEM_TYPE_CFG_TBL, item[INSTANCE_TYPEID]) 
                if not it then
                    log_game_error("BodyEnhanceSystem:CanUpgrade", "it[%d] not existed.", item[INSTANCE_TYPEID])
                    return
                end
                --特殊物品没有type字段
                if it.type and it.level then
                    if not tmp_myMaterial[it.type] then
                        tmp_myMaterial[it.type] = {}
                    end
                    if not tmp_myMaterial[it.type][it.subtype] then
                        tmp_myMaterial[it.type][it.subtype] = {}
                    end
                    if tmp_myMaterial[it.type][it.subtype][it.level] then 
                        tmp_myMaterial[it.type][it.subtype][it.level].count = tmp_myMaterial[it.type][it.subtype][it.level].count + item[INSTANCE_COUNT]
                    else
                        tmp_myMaterial[it.type][it.subtype][it.level] = { typeId = item[INSTANCE_TYPEID], count = item[INSTANCE_COUNT], level = it.level }
                    end
                end
            end

            local function IsHave( materials, id, count )
                if count < 1 then
                    return error_code.ERR_BODY_ENHANCE_SUCCEED, 0
                end
                --获取材料配置
                local materialInfo = g_itemdata_mgr:GetItem(public_config.ITEM_TYPE_CFG_TBL, id)
                if materialInfo == nil then
                    log_game_error("BodyEnhanceSystem:CanUpgrade", "item[%d] not existed", id)
                    return error_code.ERR_BODY_ENHANCE_CONFIG, 0
                end
                if not materials[materialInfo.type] or not materials[materialInfo.type][materialInfo.subtype] then
                    return error_code.ERR_BODY_ENHANCE_MATERIAL_NOT_ENOUGH, count
                end
                --同类型相同的所有材料
                local mm = materials[materialInfo.type][materialInfo.subtype]
                local lv = materialInfo.level
                --先扣除匹配材料
                if mm[lv] then
                    costs[id] = costs[id] or 0
                    if mm[lv].count >= count then
                        costs[id] = costs[id] + count
                        mm[lv].count = mm[lv].count - count
                        if mm[lv].count == 0 then mm[lv] = nil end
                        return error_code.ERR_BODY_ENHANCE_SUCCEED, 0
                    else
                        costs[id] = costs[id] + mm[lv].count
                        count = count - mm[lv].count
                        mm[lv] = nil
                    end
                end
                --sort
                --sort function
                local sort_tab = {}
                for l,_ in pairs(mm) do
                    local tmp = {}
                    tmp.level = l
                    table.insert(sort_tab, tmp)
                end
                local function less(a, b)
                    return a.level < b.level
                end
                table.sort(sort_tab, less)

                --不够再检查其它高级的材料
                for i, v in ipairs(sort_tab) do
                    if v.level == lv then
                        log_game_error("BodyEnhanceSystem:CanUpgrade", "not cost the same item.")
                    end
                    if v.level > lv then
                        local theData = mm[v.level]
                        if not theData then
                            log_game_error("BodyEnhanceSystem:CanUpgrade", "something is wrong.")
                        end
                        costs[theData.typeId] = costs[theData.typeId] or 0
                        if count <= theData.count then
                            costs[theData.typeId] = costs[theData.typeId] + count
                            theData.count = theData.count - count
                            if theData.count == 0 then mm[v.level] = nil end
                            return error_code.ERR_BODY_ENHANCE_SUCCEED, 0
                        else
                            costs[theData.typeId] = costs[theData.typeId] + theData.count
                            count = count - theData.count
                            --从临时材料集合中删除
                            mm[v.level] = nil
                        end
                    end
                end
                return error_code.ERR_BODY_ENHANCE_MATERIAL_NOT_ENOUGH, count
            end

            for materialId, num in pairs(aEnhanceInfo.material) do
                local err, lackNum = IsHave(tmp_myMaterial, materialId, num)
                if err == error_code.ERR_BODY_ENHANCE_MATERIAL_NOT_ENOUGH and lackNum > 0 then
                    lack[materialId] = lackNum
                end
            end
        end
        if lua_util.get_table_real_count(lack) > 0 then
            return error_code.ERR_BODY_ENHANCE_MATERIAL_NOT_ENOUGH, lack
        end
        return  error_code.ERR_BODY_ENHANCE_SUCCEED, {}
    end
    log_game_error("BodyEnhanceSystem:CanUpgrade", "err2 = %d", error_code.ERR_BODY_ENHANCE_CONFIG)
    return error_code.ERR_BODY_ENHANCE_CONFIG, {}
end
--获取升级对应部位和等级所需的材料
function BodyEnhanceSystem:GetUpgradeMaterial( position, level )
    local aEnhanceInfo, err = self:GetEnhanceInfo(position, level)
    if err ~= error_code.ERR_BODY_ENHANCE_SUCCEED then
        return nil, err
    end
    if aEnhanceInfo and aEnhanceInfo.material then
        return aEnhanceInfo.material, error_code.ERR_BODY_ENHANCE_SUCCEED
    end
    return nil, error_code.ERR_BODY_ENHANCE_CONFIG
end
--获取升级对应部位和等级所需的金币
function BodyEnhanceSystem:GetUpgradeGold( position, level )
    local aEnhanceInfo, err = self:GetEnhanceInfo(position, level)
    if err ~= error_code.ERR_BODY_ENHANCE_SUCCEED then
        return nil, err
    end
    if aEnhanceInfo and aEnhanceInfo.gold then
        return aEnhanceInfo.gold, error_code.ERR_BODY_ENHANCE_SUCCEED
    end
    return nil, error_code.ERR_BODY_ENHANCE_CONFIG
end
--获取升级对应部位和等级所需的角色等级
function BodyEnhanceSystem:GetUpgradeCharacterLevel( position, level )
    local aEnhanceInfo, err = self:GetEnhanceInfo(position, level)
    if err ~= error_code.ERR_BODY_ENHANCE_SUCCEED then
        return nil, err
    end
    if aEnhanceInfo and aEnhanceInfo.characterLevel then
        return aEnhanceInfo.characterLevel, error_code.ERR_BODY_ENHANCE_SUCCEED
    end
    return nil, error_code.ERR_BODY_ENHANCE_CONFIG
end
--升级对应的部位
function BodyEnhanceSystem:Upgrade( position )
    log_game_debug("BodyEnhanceSystem:Upgrade", "position = %d", position)
    local level = 0
    local owner = self.ptr.theOwner
	if bodyIndex2Name[position] ~= nil then
        if owner.body[position] then
            level = owner.body[position]
		end
	else
		log_game_error("BodyEnhanceSystem:Upgrade", "position = %s.", tostring(position))
		return error_code.ERR_BODY_ENHANCE_PARA, {}
	end
    level = level + 1 --期望升级的级数
    local costs = {}
    local err, lack = self:CanUpgrade(position, level, costs)
    if err == nil then
        log_game_error("BodyEnhanceSystem:Upgrade", "err is nil.")
    end

    if err ~= error_code.ERR_BODY_ENHANCE_SUCCEED then 
        --log_game_error("BodyEnhanceSystem:Upgrade", "err = %d", err)
        return err, lack
    end
    --[[
    local aEnhanceInfo, err1 = self:GetEnhanceInfo(position, level)
    --材料
    
    if aEnhanceInfo.material then
        local myMaterial = owner.inventorySystem:GetAllItem(public_config.ITEM_TYPE_MATERIAL)
        local function costMaterial( materials, materialId, num )
            if num < 1 then
                return true
            end
            for _,v in pairs(materials) do
                if v.typeId == materialId and 
                    owner.inventorySystem:DelForItems(materialId, num) == 0 then
                    log_game_debug("inventorySystem:DelForItems", "materialId = %d, num = %d", materialId, num)
                    return true
                end
            end
            return false
        end
        for materialId, num in pairs(aEnhanceInfo.material) do
            if not costMaterial(myMaterial, materialId, num) then
                log_game_error("BodyEnhanceSystem:Upgrade", "costMaterial fail.")
            end
        end
    end
    ]]

    --使用规定的接口改变关键数值
    --owner.gold = owner.gold - aEnhanceInfo.gold
    log_game_debug("BodyEnhanceSystem:Upgrade", mogo.cPickle(costs))
    if costs.gold then
        owner:AddGold(-costs.gold, reason_def.body_enhance)
        costs.gold = nil
    end
    --扣除材料
    for k,v in pairs(costs) do
        if 0 ~= owner:DelItem(k, v, reason_def.body_enhance) then
            log_game_error("BodyEnhanceSystem:Upgrade", "costMaterial fail.")
        end
    end

    local body = owner.body
    body[position] = level
    owner.body = body
    --触发重算avatar属性
    owner:triggerEvent(event_config.EVENT_AVATAR_PROPERTIES_RECALCULATE)
    log_game_debug("BodyEnhanceSystem:Upgrade", "self.ptr.theOwner.body[position] = %d", level)
    --数据中心数据采集
    owner:OnStrongEquip(position)
	return error_code.ERR_BODY_ENHANCE_SUCCEED, {}
end

return BodyEnhanceSystem
