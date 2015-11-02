require "lua_util"
require "Item_data"
require "public_config"
require "role_data"
require "reason_def"
require "vip_privilege"
require "energy_data"
require "wing_data"
require "Jewel_sort_data"
require "event_config"
require "channel_config"
require "WingSystem"

local log_game_debug  = lua_util.log_game_debug
local log_game_info   = lua_util.log_game_info
local log_game_error  = lua_util.log_game_error
local globalbase_call = lua_util.globalbase_call
--道具系统
InventorySystem = {}
InventorySystem.__index = InventorySystem

function InventorySystem:new(owner)
    local newObj = {}
    newObj.ptr = {}
    setmetatable(newObj, {__index = InventorySystem})
    setmetatable(newObj.ptr, {__mode = "kv"})
    newObj.ptr.theOwner = owner
    newObj.uid = os.time()
    return newObj
end
--背包类型定义
local BAG_TYPE_EQUIPMENT        = 1
local BAG_TYPE_JEWELS           = 2
local BAG_TYPE_MATERIALS        = 3
local BAG_TYPE_BODY             = 5
--背包空间大小限定
local BAG_GRID_COUNT_EQUIPMENT  = 40
local BAG_GRID_COUNT_JEWELs     = 40
local BAG_GRID_COUNT_MATERIALS  = 40
local BAG_GRID_COUNT_BODY       = 11
--道具配置数据索引
local ITEM_CONFIGURE_DATA       = public_config.ITEM_TYPE_CFG_TBL        --道具
local ITEM_CONFIGURE_ATTR       = public_config.ITEM_TYPE_EQUIPMENTATTRI --基础属性
local ITEM_CONFIGURE_DEEQ       = public_config.ITEM_TYPE_DEEQUIPMENT    --分解属性
local ITEM_TYPE_SUITEQUIPMENT   = public_config.ITEM_TYPE_SUITEQUIPMENT  --套装属性
--配置表中道具类型编号
local ITEM_GRID_TYPE_EQUIPMENT  = public_config.ITEM_GRID_EQUIPMENT      --装备
local ITEM_GRID_TYPE_MATERIAL   = public_config.ITEM_GRID_MATERIAL       --材料
local ITEM_GRID_TYPE_JEWEL      = public_config.ITEM_GRID_JEWEL          --宝石
local ITEM_GRID_TYPE_COMMON     = public_config.ITEM_GRID_COMMON         --普通
--角色职业配置
local AVATAR_ALL_VOC            = public_config.AVATAR_ALL_VOC           --全职业
--角色身体部位
local BODY_POS_HEAD             = public_config.BODY_POS_HEAD            --头盔
local BODY_POS_NECK             = public_config.BODY_POS_NECK            --项链 
local BODY_POS_SHOULDER         = public_config.BODY_POS_SHOULDER        --肩甲
local BODY_POS_CHEST            = public_config.BODY_POS_CHEST           --胸甲
local BODY_POS_WAIST            = public_config.BODY_POS_WAIST           --护腰
local BODY_POS_ARM              = public_config.BODY_POS_ARM             --手套
local BODY_POS_LEG              = public_config.BODY_POS_LEG             --腿甲
local BODY_POS_FOOT             = public_config.BODY_POS_FOOT            --战靴
local BODY_POS_FINGER           = public_config.BODY_POS_FINGER          --戒指
local BODY_POS_WEAPON           = public_config.BODY_POS_WEAPON          --武器
--道具使用物品id索引
local AVATAR_USE_EXP            = public_config.EXP_ID                   --经验
local AVATAR_USE_GOLD           = public_config.GOLD_ID                  --金币
local AVATAR_USE_DIAMOND        = public_config.DIAMOND_ID               --钻石
local AVATAR_USE_VIP            = public_config.VIP_ID                   --vip卡
local AVATAR_USE_CUBE           = public_config.CUBE_ID                  --宝箱
local AVATAR_USE_ENERGY         = public_config.ENERGY_ID                --体力
local AVATAR_USE_BUFF           = public_config.BUFF_ID                  --buff
local AVATAR_USE_GUILD          = public_config.GUILD_CARD_ID            --公会卡
local AVATAR_USE_ARENA_CREDIT   = public_config.ARENA_CREDIT             --竞技场荣誉
local AVATAR_USE_ARENA_SCORE    = public_config.ARENA_SCORE              --竞技场积分
local AVATAR_USE_WING           = public_config.WING_ID                  --翅膀
local AVATAR_USE_RUNE           = public_config.RUNE_ID                  --符文
--道具品质定义
local ITEM_QUALITY_WHITE        = public_config.ITEM_QUALITY_WHITE       --白色
local ITEM_QUALITY_GREEN        = public_config.ITEM_QUALITY_GREEN       --绿色
local ITEM_QUALITY_BLUE         = public_config.ITEM_QUALITY_BLUE        --蓝色
local ITEM_QUALITY_PURPLE       = public_config.ITEM_QUALITY_PURPLE      --粉色
local ITEM_QUALITY_ORANGE       = public_config.ITEM_QUALITY_ORANGE      --橙色
local ITEM_QUALITY_GOLD         = public_config.ITEM_QUALITY_GOLD        --暗金
--刷新数据类型
local ITEM_OPTION_DELETE        = public_config.ITEM_OPTION_DELETE       --删除
local ITEM_OPTION_UPDATE        = public_config.ITEM_OPTION_UPDATE       --更新
local ITEM_OPTION_ADD           = public_config.ITEM_OPTION_ADD          --新增
--特殊道具最大编号
local MAX_OTHER_ITEM_ID         = public_config.MAX_OTHER_ITEM_ID        
--道具实例属性索引
local INSTANCE_GRIDINDEX        = public_config.ITEM_INSTANCE_GRIDINDEX  --背包索引
local INSTANCE_TYPEID           = public_config.ITEM_INSTANCE_TYPEID     --道具id
local INSTANCE_ID               = public_config.ITEM_INSTANCE_ID         --实例id
local INSTANCE_BINDTYPE         = public_config.ITEM_INSTANCE_BINDTYPE   --绑定类型
local INSTANCE_COUNT            = public_config.ITEM_INSTANCE_COUNT      --堆叠数量
local INSTANCE_SLOTS            = public_config.ITEM_INSTANCE_SLOTS      --宝石插槽
local INSTANCE_EXTINFO          = public_config.ITEM_INSTANCE_EXTINFO    --扩展信息

local ITEM_ACTIVE_TYPE          = public_config.ITEM_ACTIVE_TYPE         --激活道具标识
local ITEM_ACTIVE_SUBTYPE       = public_config.ITEM_ACTIVE_SUBTYPE      --激活子类型标识

local ITEM_ACTIVED_OK           = public_config.ITEM_ACTIVED_OK          --已激活
local ITEM_ACTIVED_NO           = public_config.ITEM_ACTIVED_NO          --没有激活
local ITEM_EXTINFO_ACTIVE       = public_config.ITEM_EXTINFO_ACTIVE      --道具激活标识

local ITEM_EXTINFO_LOCKED       = public_config.ITEM_EXTINFO_LOCKED      --装备是否加锁
local ITEM_LOCKED_OK            = public_config.ITEM_LOCKED_OK           --已锁
local ITEM_LOCKED_NO            = public_config.ITEM_LOCKED_NO           --解锁

local JEWEL_SLOT_TYPE           = public_config.JEWEL_SLOT_TYPE          -- 通用宝石插槽
--生成道具系统的实例id
function InventorySystem:GetUId()
    local uid = self.uid
    local currTime = os.time()
    if uid <= currTime then
        uid = currTime + 1
        self.uid = uid
    else
        uid = uid + 1
        self.uid = uid
    end
    return uid
end
--获取指定类型的背包数据
function InventorySystem:GetItemsByType(bagType)
    local avatar = self.ptr.theOwner
    if bagType == BAG_TYPE_EQUIPMENT then
        return avatar.generals
    elseif bagType == BAG_TYPE_JEWELS then
        return avatar.jewels
    elseif bagType == BAG_TYPE_MATERIALS then
        return avatar.materials
    elseif bagType == BAG_TYPE_BODY then
        return avatar.equipeds
    end
    return {}
end
--获取背包空间总容量
function InventorySystem:GetGridCounts(bagType)
    if bagType == BAG_TYPE_EQUIPMENT then
        return BAG_GRID_COUNT_EQUIPMENT
    elseif bagType == BAG_TYPE_JEWELS then
        return BAG_GRID_COUNT_JEWELs
    elseif bagType == BAG_TYPE_MATERIALS then
        return BAG_GRID_COUNT_MATERIALS
    elseif bagType == BAG_TYPE_BODY then
        return BAG_GRID_COUNT_BODY
    end
    return 0
end
--获取未使用的格式数量
function InventorySystem:GetEmptyGridCounts(bagType)
    local maxNums  = self:GetGridCounts(bagType)
    local bagDatas = self:GetItemsByType(bagType)
    local usedNums = self:GetTableItemsCount(bagDatas)
    return maxNums - usedNums
end
--获取table中项的个数
function InventorySystem:GetTableItemsCount(items)
    local count = 0	
	for _, v in pairs(items) do
		count = count + 1
	end
    return count
end
--获取已使用的格子数量
function InventorySystem:GetUsedGridCounts(bagType)
    local items = self:GetItemsByType(bagType)
	return self:GetTableItemsCount(items)
end
--判断背包格子是否已满
function InventorySystem:IsFull(bagType)
    local items = self:GetItemsByType(bagType)
    local remainCount = self:GetEmptyGridCounts(bagType)
    if remainCount == 0 then
        return true
    end
    return false
end
--获取背包中最小空格子索引
function InventorySystem:GetGridIndex(bagType)
    local avatar = self.ptr.theOwner
    local bagDatas = self:GetItemsByType(bagType)
    local count = self:GetGridCounts(bagType)
    local mark = {}
    for k, v in pairs(bagDatas) do
        local idx = v[INSTANCE_GRIDINDEX]
        mark[idx] = 1
    end
    local i = 1
    for k, v in ipairs(mark) do
        i = i + 1
    end
    if i > count then
        log_game_error("InventorySystem:GetGridIndex", "gridIndex over !dbid=%q;name=%s,bagType=%d", 
            avatar.dbid, avatar.name, bagType)
        return 0
    end
    return i
end
--构建一个新的道具
function InventorySystem:NewItem()
    local item = {}
    item[INSTANCE_ID]          = self:GetUId() --道具的实例id
    item[INSTANCE_TYPEID]      = 0             --道具的配置id
    item[INSTANCE_GRIDINDEX]   = 0             --道具的格子索引
    item[INSTANCE_BINDTYPE]    = 0             --道具绑定类型
    item[INSTANCE_COUNT]       = 0             --道具的数量
    item[INSTANCE_SLOTS]       = {}            --道具的宝石插槽
    item[INSTANCE_EXTINFO]     = {}            --道具的扩展信息
    return item
end
--获取道具的配置数据
function InventorySystem:GetItemData(typeId)
    local avatar = self.ptr.theOwner
    local itemCfg = g_itemdata_mgr:GetItem(ITEM_CONFIGURE_DATA, typeId)
    if not itemCfg then
        log_game_error("InventorySystem:GetItemData", "configure nil! dbid=%q;name=%s;typeId=%d", 
            avatar.dbid, avatar.name, typeId)
        return
    end
    return itemCfg
end
--判断道具是否为可堆叠类型(为配置数据)
function InventorySystem:IsStackType(item)
    if not item.maxStack or item.maxStack == -1 then
        return false
    end
    return true
end
--检查同类型指定道具个数是否空间足够
function InventorySystem:IsSpaceEnough(typeId, count)
    local itemData = self:GetItemData(typeId)
    local avatar = self.ptr.theOwner
    if not itemData then
        log_game_error("InventorySystem:IsSpaceEnough", "typeId not exist! dbid=%q;name=%s;typeId=%d;count=%d", 
        avatar.dbid, avatar.name, typeId, count)
        return false
    end
    local bagType = self:GetBagType(itemData)
    local canStack = self:IsStackType(itemData)
    local emptyGridCount = self:GetEmptyGridCounts(bagType)
    if emptyGridCount > count then
        return true
    end
    local tpCount = 0
    local maxStack = itemData.maxStack or 1
    if canStack then --计算已有道具格子加满余留空间
        local bagDatas = self:GetItemsByType(bagType)
        for _, v in pairs(bagDatas) do
            if v[INSTANCE_TYPEID] == typeId then 
                tpCount = tpCount + (maxStack - v[INSTANCE_COUNT] )
            end
        end
    end
    if tpCount >= count then  --已有道具堆叠属于空间
        return true
    end
    tpCount = tpCount + maxStack*emptyGridCount
    if tpCount >= count then  --叠加空格子可加入的数量
        return true
    end
    log_game_error("InventorySystem:IsSpaceEnough", "space unenough! dbid=%q;name=%s;has_space=%d;need_space=%d", 
        avatar.dbid, avatar.name, tpCount, count)
    return false
end
--获取所有道具背包剩余格子数量
function InventorySystem:GetAllRemainCount()
    local bagCountTable = {}
    bagCountTable[BAG_TYPE_EQUIPMENT] = self:GetEmptyGridCounts(BAG_TYPE_EQUIPMENT)
    bagCountTable[BAG_TYPE_JEWELS]    = self:GetEmptyGridCounts(BAG_TYPE_JEWELS)
    bagCountTable[BAG_TYPE_MATERIALS] = self:GetEmptyGridCounts(BAG_TYPE_MATERIALS)
    return bagCountTable
end
--检查多个不同的道具是否有足够的空间
function InventorySystem:SpaceForItems(items)
    local bagGridCount = self:GetAllRemainCount()
    for kId, vCount in pairs(items) do
--        print(kId, vCount)
        local itemData = self:GetItemData(kId)
        if not itemData then
            return false
        end
        local bagType = self:GetBagType(itemData)
        local canStack = self:IsStackType(itemData)
        if canStack then
            local bagDatas = self:GetItemsByType(bagType)
            local tpCount  = 0
            local maxStack = itemData.maxStack or 1
            for k, v in pairs(bagDatas) do
                if v[INSTANCE_TYPEID] == kId then 
                    tpCount = tpCount + (maxStack - v[INSTANCE_COUNT])
                end
            end
            if tpCount < vCount then
                local need = math.ceil((vCount - tpCount)/maxStack)
                if bagGridCount[bagType] >= need then
                    bagGridCount[bagType] = bagGridCount[bagType] - need
                else
                    return false
                end
            end
        else
            if bagGridCount[bagType] >= vCount then
                bagGridCount[bagType] = bagGridCount[bagType] - vCount
            else
                return false
            end
        end
    end
    return true
end
--将配置表中指定的类型编号转化为背包类型
function InventorySystem:GetBagType(item)
    if item.itemType == ITEM_GRID_TYPE_EQUIPMENT then
        return BAG_TYPE_EQUIPMENT
    elseif item.itemType == ITEM_GRID_TYPE_MATERIAL then
        return BAG_TYPE_MATERIALS
    elseif item.itemType == ITEM_GRID_TYPE_JEWEL then
        return BAG_TYPE_JEWELS
    elseif item.itemType == ITEM_GRID_TYPE_COMMON then
        return BAG_TYPE_EQUIPMENT
    end
    return 
end
--------------------------------------------------------------------------
--增加道具逻辑
--------------------------------------------------------------------------
--增加一个新道具到背包
function InventorySystem:AddItems(typeId, count)
    --处理特殊添加
    if typeId < MAX_OTHER_ITEM_ID then
        return self:AddSpecItems(typeId, count)
    end
    local mItem = self:NewItem()
    mItem[INSTANCE_TYPEID] = typeId
    mItem[INSTANCE_COUNT]  = count
    local itemData = self:GetItemData(typeId)
    if not itemData then
        return false
    end
    local bagType  = self:GetBagType(itemData)
    local maxStack = itemData.maxStack or 1
    if self:IsStackType(itemData) then
        --log_game_debug("InventorySystem:AddItems", "count=%d", count)
        return self:AddStackableItems(mItem, bagType, maxStack)
    else
        --log_game_debug("InventorySystem:AddItems", "count=%d", count)
        return self:AddNotStackableItems(mItem, bagType)
    end
end
function InventorySystem:AddSpecItems(typeId, count)
    local item = {}
    item[typeId] = count
    local retCode = self:CheckSpecItems(item, {})
    if retCode == error_code.ERR_USEITEM_SUCCESS then
        self:ActionSpecItems(item, {})
        return true
    end
    return false
end
local function less(a, b)
    if a[INSTANCE_TYPEID] == b[INSTANCE_TYPEID] then  
        return a[INSTANCE_COUNT] < b[INSTANCE_COUNT]
    else
        return a[INSTANCE_TYPEID] > a[INSTANCE_TYPEID]
    end
end
local function great(a, b)
    if a[INSTANCE_TYPEID] == b[INSTANCE_TYPEID] then
        if a[INSTANCE_COUNT] == b[INSTANCE_COUNT] then
            return a[INSTANCE_GRIDINDEX] < b[INSTANCE_GRIDINDEX] 
        else
            return a[INSTANCE_COUNT] > b[INSTANCE_COUNT]
        end
    else
        return a[INSTANCE_TYPEID] > b[INSTANCE_TYPEID]
    end
end
--可堆叠的道具
function InventorySystem:AddStackableItems(sItem, bagType, maxStack)
    local remainCount = self:GetEmptyGridCounts(bagType)
    local isSpaceEnough = self:IsSpaceEnough(sItem[INSTANCE_TYPEID], sItem[INSTANCE_COUNT])
    if  not isSpaceEnough then
        return false
    end
    local tpCount = sItem[INSTANCE_COUNT]
    local bagDatas = self:GetItemsByType(bagType)
    table.sort(bagDatas, less)
    for k, v in pairs(bagDatas) do
        if tpCount > 0 and v[INSTANCE_TYPEID] == sItem[INSTANCE_TYPEID] then
            local need = maxStack - v[INSTANCE_COUNT]
            if need > 0 then
                if tpCount >= need then
                    v[INSTANCE_COUNT] = maxStack
                    tpCount = tpCount - need
                    self:UpdateClient(bagType, ITEM_OPTION_ADD, v)
                else
                    v[INSTANCE_COUNT] = v[INSTANCE_COUNT] + tpCount
                    tpCount = 0
                    self:UpdateClient(bagType, ITEM_OPTION_ADD, v)
                    return true
                end
            end
        end
    end
    if tpCount > 0 then
        local need = math.ceil(tpCount/maxStack)
        for i = 1, need do
            local item = mogo.deepcopy1(sItem)
            item[INSTANCE_ID]        = self:GetUId()  
            item[INSTANCE_SLOTS]     = {}   
            item[INSTANCE_EXTINFO]   = {} 
            item[INSTANCE_GRIDINDEX] = self:GetGridIndex(bagType)
            if tpCount > maxStack then
                item[INSTANCE_COUNT] = maxStack
                tpCount = tpCount - maxStack
            else
                item[INSTANCE_COUNT] = tpCount
                tpCount = 0
            end
            table.insert(bagDatas, item)
            self:UpdateClient(bagType, ITEM_OPTION_ADD, item)
        end
    end
    return true
end
--不可堆叠的道具
function InventorySystem:AddNotStackableItems(sItem,  bagType)
    local avatar = self.ptr.theOwner
    local remainCount = self:GetEmptyGridCounts(bagType)
    if remainCount < sItem[INSTANCE_COUNT] then
        log_game_error("InventorySystem:AddNotStackableItems", "bag full! dbid=%q;name=%s;typeId=%d", 
            avatar.dbid, avatar.name, sItem[INSTANCE_TYPEID])
        return false
    end
    local bagDatas = self:GetItemsByType(bagType)
    for i = 1, sItem[INSTANCE_COUNT] do
        local item = mogo.deepcopy1(sItem)
        item[INSTANCE_ID]        = self:GetUId()  
        item[INSTANCE_SLOTS]     = {}   
        item[INSTANCE_EXTINFO]   = {} 
        item[INSTANCE_GRIDINDEX] = self:GetGridIndex(bagType)
        item[INSTANCE_COUNT]     = 1
        table.insert(bagDatas, item)
        self:UpdateClient(bagType, ITEM_OPTION_ADD, item)
    end
    return true
end
--判断是否有足量的指定道具
function InventorySystem:HasEnoughItems(typeId, count)
    local itemData = self:GetItemData(typeId)
    if not itemData then
        return false
    end
    local bagType = self:GetBagType(itemData)
    local bagDatas = self:GetItemsByType(bagType)
    local tpCount = 0
    for k, v in pairs(bagDatas) do
        if v[INSTANCE_TYPEID] == typeId then
            tpCount = tpCount + v[INSTANCE_COUNT]
            if tpCount >= count then
                return true
            end
        end
    end
    local avatar = self.ptr.theOwner
    log_game_debug("InventorySystem:HasEnoughItems", "dbid=%q;name=%s;typeId=%d;has_count=%d;count=%d", 
        avatar.dbid, avatar.name, typeId, tpCount, count)
    return false
end
--已sfdjsafldjal有的道具实体添加到角色身上(内部使用)
function InventorySystem:AddItemToBody(item)
    local  bagDatas = self:GetItemsByType(BAG_TYPE_BODY)
    table.insert(bagDatas, item)
    self:UpdateClient(BAG_TYPE_BODY, ITEM_OPTION_UPDATE, item)
end
--已有道具实体添加到背包中(内部使用)
function InventorySystem:AddItemToBag(item)
    local itemData = self:GetItemData(item[INSTANCE_TYPEID])
    local bagType  = self:GetBagType(itemData)
    local bagDatas = self:GetItemsByType(bagType)
    table.insert(bagDatas, item)
    self:UpdateClient(bagType, ITEM_OPTION_UPDATE, item)
    return true
end
---------------------------------------------------------------------------
---道具删除逻辑
---------------------------------------------------------------------------
--将背包数据索引连续化
function InventorySystem:ReassignItems(bagDatas, bagType)
    local avatar = self.ptr.theOwner
    local newDatas = {}
    for k, v in pairs(bagDatas) do
        table.insert(newDatas, v)
    end
    if bagType == BAG_TYPE_EQUIPMENT then
        avatar.generals = newDatas
    elseif bagType == BAG_TYPE_JEWELS then
        avatar.jewels = newDatas
    elseif bagType == BAG_TYPE_MATERIALS then
        avatar.materials = newDatas
    end
end
--删除道具实际操作
function InventorySystem:RemoveItems(bagDatas, bagType, typeId, count)
    local tpCount = count
    local isNeed  = false
    table.sort(bagDatas, less)
    for k, v in pairs(bagDatas) do
        if tpCount > 0 and v[INSTANCE_TYPEID] == typeId then
            if tpCount >= v[INSTANCE_COUNT] then
                tpCount = tpCount - v[INSTANCE_COUNT]
                v[INSTANCE_COUNT] = 0   
                bagDatas[k] = nil
                self:UpdateClient(bagType, ITEM_OPTION_DELETE, v)
                isNeed = true
            else
                v[INSTANCE_COUNT] = v[INSTANCE_COUNT] - tpCount
                self:UpdateClient(bagType, ITEM_OPTION_UPDATE, v)
                tpCount = 0
            end
        end
    end
    if isNeed then
        self:ReassignItems(bagDatas, bagType)
    end
end
--删除背包中指定数量的道具和条件判断
function InventorySystem:DelItems(typeId, count)
    --处理特殊道具
    if typeId < MAX_OTHER_ITEM_ID then
        return self:AddSpecItems(typeId, -count)
    end
    local itemData = self:GetItemData(typeId)
    if not itemData then
        return false
    end
    local bagType = self:GetBagType(itemData)
    local bagDatas = self:GetItemsByType(bagType)
    local hasEnoughItems = self:HasEnoughItems(typeId, count)
    if  not hasEnoughItems then
        local avatar = self.ptr.theOwner
        log_game_error("InventorySystem:DelItems", "item not enough! dbid=%q;name=%s;typeId=%d;count=%d",
        avatar.dbid, avatar.name, typeId, count)
        return false
    end
    self:RemoveItems(bagDatas, bagType, typeId, count)
    --log_game_debug("InventorySystem:DelItems", "count=%d", count)
    return true
end
--从角色身上脱下道具
function InventorySystem:DelItemFromBody(id, idx, typeId)
    local  bagDatas = self:GetItemsByType(BAG_TYPE_BODY)
    for k, v in pairs(bagDatas) do
        if v[INSTANCE_ID] == id and v[INSTANCE_GRIDINDEX] == idx  
           and v[INSTANCE_TYPEID] == typeId then 
            table.remove(bagDatas, k)
            self:UpdateClient(BAG_TYPE_BODY, ITEM_OPTION_DELETE, v)
            return true
        end
    end
    return false
end
--删除指定格子的道具
function InventorySystem:DelItemFromBag(id, idx, typeId, count)
    local itemData = self:GetItemData(typeId)
    if not itemData then
        return false
    end
    local cnt = count or 1
    local bagType  = self:GetBagType(itemData)
    local bagDatas = self:GetItemsByType(bagType)
    for k, v in pairs(bagDatas) do
        if v[INSTANCE_ID] == id and v[INSTANCE_GRIDINDEX] == idx 
           and v[INSTANCE_TYPEID] == typeId then
            if cnt == v[INSTANCE_COUNT] then 
                table.remove(bagDatas, k)
                self:UpdateClient(bagType, ITEM_OPTION_DELETE, v)
                return true
            end
            if cnt < v[INSTANCE_COUNT] then 
                v[INSTANCE_COUNT] = v[INSTANCE_COUNT] - cnt
                self:UpdateClient(bagType, ITEM_OPTION_UPDATE, v)
                return true
            end
        end
    end
    return false
end
--清空背包数据
function InventorySystem:DelBagItems(bagType)
    local avatar = self.ptr.theOwner
    if bagType == BAG_TYPE_EQUIPMENT then
        self:FlushClientItems(bagType, avatar.generals)
        avatar.generals = {}
    elseif bagType == BAG_TYPE_JEWELS then
        self:FlushClientItems(bagType, avatar.jewels)
        avatar.jewels = {}
    elseif bagType == BAG_TYPE_MATERIALS then
        self:FlushClientItems(bagType, avatar.materials)
        avatar.materials = {}
    elseif bagType == BAG_TYPE_BODY then
        self:FlushClientItems(bagType, avatar.equipeds)
        avatar.equipeds = {}
    end 
end
function InventorySystem:FlushClientItems(bagType, items)
    for k, v in pairs(items) do
        self:UpdateClient(bagType, ITEM_OPTION_DELETE, v)
    end
end
----------------------------------------------------------------
--整理背包逻辑
----------------------------------------------------------------
function InventorySystem:TidyBag(bagType)
    local bagDatas = self:GetItemsByType(bagType)
    table.sort(bagDatas, great)
    local len = self:GetTableItemsCount(bagDatas)
    local i = 1
    local j = 2    
    local t = {}
    while j <= len do  
        --线性数据横向累加，整理道具的个数问题
        if bagDatas[i][INSTANCE_TYPEID] == bagDatas[j][INSTANCE_TYPEID]  then
            local itemData = self:GetItemData(bagDatas[i][INSTANCE_TYPEID])       
            if self:IsStackType(itemData) then 
                --可堆叠道具
                local maxStack = itemData.maxStack
                --i的个数未达最大堆叠，将后面相同道具加到前面
                if bagDatas[i][INSTANCE_COUNT] < maxStack then
                    local remain = maxStack - bagDatas[i][INSTANCE_COUNT]  
                    if bagDatas[j][INSTANCE_COUNT] < remain then
                        bagDatas[i][INSTANCE_COUNT] = bagDatas[i][INSTANCE_COUNT] + bagDatas[j][INSTANCE_COUNT]
                        t[i] = 0
                        bagDatas[j][INSTANCE_COUNT] = 0
                        t[j] = 1
                        j = j + 1
                    elseif bagDatas[j][INSTANCE_COUNT] == remain then
                        bagDatas[i][INSTANCE_COUNT] = bagDatas[i][INSTANCE_COUNT] + remain
                        t[i] = 0
                        bagDatas[j][INSTANCE_COUNT] = 0
                        t[j] = 1
                        i = i + 1
                        j = j + 1
                    else
                        bagDatas[i][INSTANCE_COUNT] = maxStack
                        t[i] = 0
                        bagDatas[j][INSTANCE_COUNT] = bagDatas[j][INSTANCE_COUNT] - remain
                        t[j] = 0
                        i = i + 1
                        if j - i == 0 then
                            j = j + 1
                        end
                    end
                elseif bagDatas[i][INSTANCE_COUNT] == maxStack then
                    i = i + 1
                    if j - i == 0 then
                        j = j + 1
                    end
                end
            else
                i = i + 1
                j = j + 1
            end          
        else
            i = j
            j = j + 1
        end
    end
    local isDirty = false
    for k, v in pairs(t) do
        if v == 1 then
            isDirty = true
            bagDatas[k] = nil
        end       
    end
    t = {}   
    i = 1
    for k, v in pairs(bagDatas) do
        if v[INSTANCE_GRIDINDEX] ~= i then
            isDirty = true
            v[INSTANCE_GRIDINDEX] = i
        end
        i = i + 1
    end
    self:ReassignItems(bagDatas, bagType)
    return isDirty
end
function InventorySystem:TidyInventory()
    local avatar = self.ptr.theOwner
    if self:TidyBag(BAG_TYPE_EQUIPMENT) then
        self:UpdateBagToClient(BAG_TYPE_EQUIPMENT, avatar.generals)
    end
    if self:TidyBag(BAG_TYPE_JEWELS) then
        self:UpdateBagToClient(BAG_TYPE_JEWELS, avatar.jewels)
    end
    if self:TidyBag(BAG_TYPE_MATERIALS) then
        self:UpdateBagToClient(BAG_TYPE_MATERIALS, avatar.materials)
    end
end
--gm
function InventorySystem:PrintItems()
    local tbl = {}
    tbl[BAG_TYPE_EQUIPMENT] =  self:GetItemsByType(BAG_TYPE_EQUIPMENT)
    tbl[BAG_TYPE_JEWELS]    =  self:GetItemsByType(BAG_TYPE_JEWELS)
    tbl[BAG_TYPE_MATERIALS] =  self:GetItemsByType(BAG_TYPE_MATERIALS)
    tbl[BAG_TYPE_BODY]      =  self:GetItemsByType(BAG_TYPE_BODY)
    for k, v in pairs(tbl) do
        log_game_info("items:","type= %d;count=%d", k, #v)
        for tk, tv in pairs(v) do
            log_game_info("IS:PT","id=%d;idx=%d;typeId=%d;count=%d;slots=%s;info=%s",
                tv[INSTANCE_ID], tv[INSTANCE_GRIDINDEX], tv[INSTANCE_TYPEID], tv[INSTANCE_COUNT],
                mogo.cPickle(tv[INSTANCE_SLOTS]), mogo.cPickle(tvtv[INSTANCE_EXTINFO]))
        end
    end
    return tbl
end
--获取指定类型的背包数据
function InventorySystem:GetAllItem(bagType)
    local bagDatas = self:GetItemsByType(bagType)
    return bagDatas or {}
end
--根据索引和背包类型获取指定位置道具
function InventorySystem:GetItemByIdx(idx, bagType)
    local bagDatas = self:GetItemsByType(bagType)
    for k, v in pairs(bagDatas) do
        if v[INSTANCE_GRIDINDEX] == idx then
            return v, k
        end
    end
end
----------------------------------------------------------------
--角色初始化逻辑
----------------------------------------------------------------
function InventorySystem:CreateRoleInitItems(vocation, dbid)
    local roleDatas = g_roleDataMgr:GetRoleDataByVocation(vocation)
    if not roleDatas then
        log_game_error("InventorySystem:CreateRoleInitItems", "role data null! dbid=%q;vocation=%d", dbid, vocation)
        return false
    end
    local generals = roleDatas.items
    local bodys = roleDatas.bodyEquip

    if generals then
        if not self:InitGeneralItems(generals) then
            log_game_error("InventorySystem:CreateRoleInitItems", "init general items! dbid=%q;vocation=%d", dbid, vocation)
            return false
        end
    end
    if bodys then
        if not self:InitBodyItems(bodys, dbid) then
            log_game_error("InventorySystem:CreateRoleInitItems", "init bodys items! dbid=%q;vocation=%d", dbid, vocation)
            return false
        end
    end
    return self:UpdateAvatar(dbid)
end
--角色道具初始化回调
function InventorySystem:UpdateAvatar(dbid)
    local function _dummy(a,b,c)
        log_game_debug("account:writeToDB", "succeed")
    end

    local avatar = self.ptr.theOwner
    local account = mogo.getEntity(avatar.accountId)

    if not account then
        return false
    end

    local errNo = account:UpdateAvatarsInfo(avatar, dbid)
    if(errNo ~= 0) then
        log_game_debug("Account:UpdateAvatarsInfo","errNo = %d", errNo)
        return false
    end
    account:writeToDB(_dummy)
    if account:hasClient() then
        account.client.OnCreateCharacterResp(error_code.ERR_SUCCESSFUL, dbid)
    end
    return true 
end
--初始化普通道具
function InventorySystem:InitGeneralItems(items)
    if not self:SpaceForItems(items) then
        return false
    end
    for kId, vCount in pairs(items) do
        self:AddItems(kId, vCount)
    end
    return true
end
--初始化角色穿戴的装备
function InventorySystem:InitBodyItems(items, dbid)
    local avatar = self.ptr.theOwner
    for kId, vCount in pairs(items) do
        local itemData = self:GetItemData(kId)
        if not itemData then
            return false
        end
        if itemData.vocation ~= avatar.vocation 
            and itemData.vocation ~= AVATAR_ALL_VOC then
            log_game_error("InventorySystem:InitBodyItems", "vocation error! dbid=%q;vocation=%d", dbid, avatar.vocation)
            return false
        end
        for i = 1, vCount do
          if not self:AddToBody(kId, itemData.type, dbid) then
              log_game_error("InventorySystem:InitBodyItems", "init error! dbid=%q;vocation=%d", dbid, avatar.vocation)
              return false
          end
        end
    end
    return true
end
--添加道具到角色身上
function InventorySystem:AddToBody(typeId, posi, dbid)
    local avatar   = self.ptr.theOwner
    local newItem  = self:NewItem()
    newItem[INSTANCE_TYPEID] = typeId     
    newItem[INSTANCE_COUNT]  = 1
    newItem[INSTANCE_ID]     = self:GetUId()
    if posi == BODY_POS_FINGER then
        local finger = self:GetItemByIdx(posi, BAG_TYPE_BODY)
        if not finger then
            newItem[INSTANCE_GRIDINDEX] = posi
        else
            finger = self:GetItemByIdx(posi + 1, BAG_TYPE_BODY)
            if not finger then
                newItem[INSTANCE_GRIDINDEX] = posi + 1
            else
                --戒指配置多了
                log_game_error("InventorySystem:AddToBody", "ring more error! dbid=%q;vocation=%d", dbid, avatar.vocation)
                self:DelBagItems(BAG_TYPE_BODY)
                return false
            end
        end
    elseif posi == BODY_POS_WEAPON then
        local weapon = self:GetItemByIdx(posi + 1, BAG_TYPE_BODY)
        if not weapon then
            newItem[INSTANCE_GRIDINDEX] = posi + 1
        else
            --武器配置多了
            log_game_error("InventorySystem:AddToBody", "weapon more error! dbid=%q;vocation=%d", dbid, avatar.vocation)
            self:DelBagItems(BAG_TYPE_BODY)
            return false
        end
    else
        local others = self:GetItemByIdx(posi, BAG_TYPE_BODY)
        if not others then
            newItem[INSTANCE_GRIDINDEX] = posi
        else
            --同类型装备配置多了
            log_game_error("InventorySystem:AddToBody", "others more error! dbid=%q;vocation=%d", dbid, avatar.vocation)
            self:DelBagItems(BAG_TYPE_BODY)
            return false
        end
    end
    local bagDatas = self:GetItemsByType(BAG_TYPE_BODY)
    table.insert(bagDatas, newItem)
    return true
end
--------------------------------------------------------------
--使用道具逻辑
--------------------------------------------------------------
function InventorySystem:UseItem(id, idx, count)
    local avatar = self.ptr.theOwner
    local item = self:GetItemByIdx(idx, BAG_TYPE_EQUIPMENT)
    if not item then
        log_game_error("InventorySystem:UseItem", "item nil! dbid=%q;name=%s;idx=%d", 
            avatar.dbid, avatar.name, idx)
        return -1, error_code.ERR_USEITEM_IDX_ERROR
    end
    local itemData = self:GetItemData(item[INSTANCE_TYPEID]) 
    if not itemData then
        return -1, error_code.ERR_USEITEM_CFG_ERROR
    end
    local effectId = itemData.effectId
    if not effectId then
        log_game_error("InventorySystem:UseItem", "effectId nil! dbid=%q;name=%s;typeId=%d", 
            avatar.dbid, avatar.name, item[INSTANCE_TYPEID])
        return item[INSTANCE_TYPEID], error_code.ERR_USEITEM_FORBID_USE
    end
    return item[INSTANCE_TYPEID], self:ConditionCheck(item, itemData, count)
end
--使用条件检查
function InventorySystem:ConditionCheck(item, itemData, count)
    if not self:CheckCoolTime(itemData) then
        return error_code.ERR_USEITEM_COLD_LIMIT
    end
    if not self:CheckUseVocation(itemData) then
        return error_code.ERR_USEITEM_VOCATION_LIMIT
    end
    if not self:CheckUseLevel(itemData) then
        return error_code.ERR_USEITEM_USELEVEL_LIMIT
    end
    if not self:CheckVipLevel(itemData) then
        return error_code.ERR_USEITEM_VIP_LEVEL_LIMIT
    end
    return self:YieldItemEffect(itemData, item, count)
end
--检查冷却时间(参数为道具的配置数据)
function InventorySystem:CheckCoolTime(itemData)
    local avatar = self.ptr.theOwner
    if itemData.cdTypes and itemData.cdTypes ~= -1 then
        local lastTime = avatar:GetCdTime(itemData.cdTypes)
        if lastTime then
            local currTime = os.time()
            local interval = currTime - lastTime
            if interval < itemData.cdTime then
                return false
            end
        end
    end
    return true
end
--校验vip等级是否受限
function InventorySystem:CheckVipLevel(itemData)
    local avatar = self.ptr.theOwner
    if itemData.vipLevel and itemData.vipLevel ~= -1 then
        if avatar.VipLevel < itemData.vipLevel then
            return false
        end
    end
    return true
end
--使用职业限制校验
function InventorySystem:CheckUseVocation(itemData)
    local avatar = self.ptr.theOwner
    if itemData.useVocation and itemData.useVocation ~= -1 then 
        if avatar.vocation ~= itemData.useVocation 
            and itemData.useVocation ~= AVATAR_ALL_VOC then
            return false
        end
    end
    return true
end
--使用等级限制
function InventorySystem:CheckUseLevel(itemData)
    local avatar = self.ptr.theOwner
    if itemData.useLevel and itemData.useLevel ~= -1 then 
        if avatar.level < itemData.useLevel then
            return false
        end
    end
    return true
end
--产生道具效果
function InventorySystem:YieldItemEffect(itemData, item, count)
    local avatar = self.ptr.theOwner
    local effectId = itemData.effectId
    local effectData = item_effect_mgr:GetEffect(effectId)
    if not effectData then
        log_game_error("InventorySystem:YieldItemEffect", "effect nil !dbid=%q;name=%s;effectId=%d", 
            avatar.dbid, avatar.name, effectId)
        return error_code.ERR_USEITEM_CFG_ERROR
    end
    local reward = item_effect_mgr:GetReward(effectData)
    if not reward then
        log_game_error("InventorySystem:YieldItemEffect", "reward nil !dbid=%q;name=%s;effectId=%d", 
            avatar.dbid, avatar.name, effectId)
        return error_code.ERR_USEITEM_CFG_ERROR
    end
    local costs = effectData.costId  or {}
    --将使用的道具添加到消耗表中
    local validItems, specialItems = self:SplitItems(reward)
    if not self:CheckCosts(costs) then
        return error_code.ERR_USERITEM_COST_UNENOUGH, costs
    end
    --特殊宝箱处理
    if specialItems[AVATAR_USE_CUBE] then
        self:CheckSpecCube(validItems, specialItems)
    end
    if not self:SpaceForItems(validItems) then
        return error_code.ERR_USEITEM_SPACE_UNENOUGH
    end
    local retCode = self:CheckSpecItems(specialItems, effectData)
    if retCode == error_code.ERR_USEITEM_SUCCESS then
        local id        = item[INSTANCE_ID]
        local gridIndex = item[INSTANCE_GRIDINDEX]
        local typeId    = item[INSTANCE_TYPEID]
        self:DelItemFromBag(id, gridIndex, typeId, count)
        --扣除使用的道具对象
        log_game_info("InventorySystem:YieldItemEffect", "delete:dbid=%q;name=%s;typeId=%d;count=%d",
            avatar.dbid, avatar.name, typeId, count)
        self:ActionItemsCost(costs)
        self:ActionSpecItems(specialItems, effectData)
        self:ActionItemsReward(validItems)
        if itemData.cdTypes and itemData.cdTypes ~= -1 then
            avatar:SetCdTime(itemData.cdTypes)
        end
    end
    return retCode
end
--分离奖励中的实体道具和特殊道具
function InventorySystem:SplitItems(items)
    local validItems   = {}
    local specialItems = {}
    for k, v in pairs(items) do
        --local itemData = self:GetItemData(k)
        if k > MAX_OTHER_ITEM_ID then
            validItems[k]   = v
        else
            specialItems[k] = v
        end
    end
    return validItems, specialItems
end
--检查道具的消耗数量背包是否满足
function InventorySystem:CheckCosts(items)
    local avatar = self.ptr.theOwner
    local validItems, specialItems = self:SplitItems(items)
    for kId, vCount in pairs(validItems) do
        local hasEnoughItem = self:HasEnoughItems(kId, vCount)
        if not hasEnoughItem then
            return false
        end
    end
    local gold = specialItems[AVATAR_USE_GOLD] or 0
    if avatar.gold < gold then
        return false
    end
    local diamond = specialItems[AVATAR_USE_DIAMOND] or 0
    if avatar.diamond < diamond then
        return false
    end
    return true
end
--获取特殊道具的奖励并添加到有效道具表中
function InventorySystem:CheckSpecCube(validItems, specialItems)
    local vocation = self.ptr.theOwner.vocation
    local specDataId =  specialItems[AVATAR_USE_CUBE]
    if specDataId then
        local typeId, count = g_jewelCube_mgr:GetVocationReward(specDataId, vocation)
        if validItems[typeId] then
            validItems[typeId] = validItems[typeId] + count
        end
        validItems[typeId] = count
    end
    return validItems
end
--执行消耗
function InventorySystem:ActionItemsCost(items)
    local avatar = self.ptr.theOwner
    --扣除消耗的道具，金币或钻石
    local validItems, specialItems = self:SplitItems(items)
    for k, v in pairs(validItems) do
        avatar:DelItem(k, v, reason_def.use_item)
    end
    local gold = specialItems[AVATAR_USE_GOLD]
    if gold then 
        avatar:AddGold(-gold, reason_def.use_item)
    end
    local diamond = specialItems[AVATAR_USE_DIAMOND]
    if diamond then
        avatar:AddDiamond(-diamond, reason_def.use_item)
    end
end
--添加奖励道具到背包
function InventorySystem:ActionItemsReward(items)
    local avatar = self.ptr.theOwner
    --增加使用道具获得的道具
    for k, v in pairs(items) do
        avatar:AddItem(k, v, reason_def.use_item)
        --for test
        --self:AddItems(k, v)
    end
end
-----------------------------------------------------------------
--检查特殊道具
-----------------------------------------------------------------
function InventorySystem:CheckSpecItems(items, effectData)
    if items[AVATAR_USE_VIP] then
        local level = items[AVATAR_USE_VIP]
        if not self:CheckVipCards(level) then
            return error_code.ERR_USEITEM_VIP_UNEFFECT
        end
    end
    if items[AVATAR_USE_BUFF] then
        local ids = items[AVATAR_USE_BUFF]
        if not self:CheckBuffIds(ids, effectData) then
            return error_code.ERR_USEITEM_BUFF_CFG_ERROR
        end
    end
    if items[AVATAR_USE_ENERGY] then
        local energy = items[AVATAR_USE_ENERGY]
        if not self:CheckEnergy(energy) then
            return error_code.ERR_USEITEM_ENERGY_LIMIT
        end
    end
    if items[AVATAR_USE_EXP] then
        local exp = items[AVATAR_USE_EXP]
        if not self:CheckExperience(exp) then
            return error_code.ERR_USEITEM_EXP_LIMIT
        end
    end
    if items[AVATAR_USE_GOLD] then
        local gold = items[AVATAR_USE_GOLD]
        if not self:CheckGolds(gold) then
            return error_code.ERR_USEITEM_GOLD_LIMIT
        end
    end
    if items[AVATAR_USE_DIAMOND] then
        local diamond = items[AVATAR_USE_DIAMOND]
        if not self:CheckDiamonds(diamond) then
            return error_code.ERR_USEITEM_DIAMOND_LIMIT
        end
    end
    if items[AVATAR_USE_ARENA_CREDIT] then
        local credit = items[AVATAR_USE_ARENA_CREDIT]
        if not self:CheckArenaCredit(credit) then
            return error_code.ERR_USEITEM_CREDIT_LIMIT
        end
    end
    if items[AVATAR_USE_WING] then
        local wingId = items[AVATAR_USE_WING]
        if not self:CheckWing(wingId) then
            return error_code.ERR_USEITEM_WING_LIMIT
        end
    end
    if items[AVATAR_USE_RUNE] then
        local runeId = items[AVATAR_USE_RUNE]
        if not self:CheckRune(runeId) then
            return error_code.ERR_USEITEM_RUNE_LIMIT
        end
    end
    return error_code.ERR_USEITEM_SUCCESS
end
function InventorySystem:CheckVipCards(level)
    local avatar = self.ptr.theOwner
    local vLevel = avatar.VipLevel
    if vLevel >= level then --vip效果等级小于当前等级不可使用
        return false
    end
    return true
end
function InventorySystem:CheckBuffIds(ids, effectData)
    local avatar  = self.ptr.theOwner
    local buffIds = effectData.buffId
    if #buffIds ~= ids then
        return false
    end
    return true
end
function InventorySystem:CheckEnergy(energy)
    local avatar = self.ptr.theOwner
	if energy < 0 then
	    if avatar.energy < -energy then
			return false
		end
	end
    local limit = g_energy_mgr:GetEnergyLimit(avatar.level)
    if avatar.energy < limit then
        return true
    end
    return false
end
function InventorySystem:CheckExperience(exp)
    local avatar = self.ptr.theOwner
    local _exp   = avatar.exp + exp
    if _exp >= 0 then
        return true
    end
    return false
end
function InventorySystem:CheckGolds(gold)
    local avatar = self.ptr.theOwner
    local _gold = avatar.gold + gold
    if _gold >= 0 then
        return true
    end
    return false
end
function InventorySystem:CheckDiamonds(diamond)
    local avatar   = self.ptr.theOwner
    local _diamond =avatar.diamond + diamond
    if _diamond >= 0 then
        return true
    end
    return false
end
function InventorySystem:CheckArenaCredit(credit)
    local avatar = self.ptr.theOwner
    local _credit = avatar.arenicCredit + credit
    if _credit >= 0 then
        return true
    end
    return false
end
function InventorySystem:CheckWing(wingId)
    local avatar  = self.ptr.theOwner
    local wingBag = avatar.wingBag[public_config.WING_DATA_INDEX]
    if wingBag[wingId] then
        return false
    end
    return true
end
function InventorySystem:CheckRune(runeId)
    local avatar  = self.ptr.theOwner
    local runeSys = avatar.runeSystem
    if not runeSys:GetRuneBagSpaceIdx() then
        return false
    end
    return true
end
-------------------------------------------------------------------
--作用特殊道具效果
------------------------------------------------------------------
function InventorySystem:ActionSpecItems(items, effectData)
    if items[AVATAR_USE_BUFF] then
        self:ActionBuffEffect(effectData.buffId)
    end
    if items[AVATAR_USE_ENERGY] then
        local val = items[AVATAR_USE_ENERGY]
        self:ActionEnergy(val)
    end
    if items[AVATAR_USE_EXP] then
        local val = items[AVATAR_USE_EXP]
        self:ActionExp(val)
    end
    if items[AVATAR_USE_GOLD] then
        local val = items[AVATAR_USE_GOLD]
        self:ActionGold(val)
    end
    if items[AVATAR_USE_DIAMOND] then
        local val = items[AVATAR_USE_DIAMOND]
        self:ActionDiamond(val)
    end
    if items[AVATAR_USE_ARENA_CREDIT] then
        local val = items[AVATAR_USE_ARENA_CREDIT]
        self:ActionArenaCredit(val)
    end
    if items[AVATAR_USE_WING] then
        local wingId = items[AVATAR_USE_WING]
        self:ActionWing(wingId)
    end
    if items[AVATAR_USE_RUNE] then
        local runeId = items[AVATAR_USE_RUNE]
        self:ActionRune(runeId)
    end
end
function InventorySystem:ActionBuffEffect(val)
    local avatar = self.ptr.theOwner
    for _, bId in pairs(val) do
        avatar.cell.AddBuffId(bId)
    end
    log_game_info("InventorySystem:GenBuffEffect", "dbid=%q;name=%s;buffids=%s",
        avatar.dbid, avatar.name, mogo.cPickle(val))
    return true
end
function InventorySystem:ActionArenaCredit(val)
    local avatar = self.ptr.theOwner
    avatar:AddCredit(val)
end
function InventorySystem:ActionExp(val)
    local avatar = self.ptr.theOwner
    avatar:AddExp(val, 1)
end
function InventorySystem:ActionGold(val)
    local avatar = self.ptr.theOwner
    avatar:AddGold(val, reason_def.use_item)
end
function InventorySystem:ActionDiamond(val)
    local avatar  = self.ptr.theOwner
    avatar:AddDiamond(val, reason_def.use_item)
end
function InventorySystem:ActionEnergy(val)
    local avatar = self.ptr.theOwner
    avatar:AddEnergy(val, reason_def.use_item)
end
function InventorySystem:ActionWing(wingId)
    local wData  = g_wing_mgr:GetWingCfg(wingId)
    local wType  = wData.type
    local isMark = public_config.WING_MAGIC_ACTIVED --普通道具处于激活状态
    local nWing  = {}
    nWing[public_config.WING_DATA_LEVEL] = public_config.WING_INIT_LEVEL
    nWing[public_config.WING_DATA_EXP]   = public_config.WING_INIT_EXP
    if wType == public_config.WING_MAGIC_TYPE then
        isMark = public_config.WING_MAGIC_NOACTED --幻化翅膀需要激活
    end
    nWing[public_config.WING_DATA_ACT] = isMark
    local avatar  = self.ptr.theOwner
    local wingBag = avatar.wingBag[public_config.WING_DATA_INDEX]
    wingBag[wingId] = nWing
    if isMark == public_config.WING_MAGIC_ACTIVED then
        avatar:triggerEvent(event_config.EVENT_AVATAR_PROPERTIES_RECALCULATE)
        WingSystem:WingBagSyncClientResp(avatar)
    end
    WingSystem:MagicWingActiveDeal(avatar)
end
function InventorySystem:ActionRune(runeId)
    local avatar = self.ptr.theOwner
    local runeSys = avatar.runeSystem
    local idx = runeSys:GetRuneBagSpaceIdx()
    runeSys:AddRune(runeId, idx)
end
--------------------------------------------------------------------
--出售道具逻辑
----------------------------------------------------------------------
function InventorySystem:SellItems(id, idx, typeId, count)
    local itemData = self:GetItemData(typeId)
    if not itemData then
        return error_code.ITEM_SELL_ITEM_NOT_EXISTED
    end
    if not self:PriceCheck(itemData) then
        return error_code.ITEM_SELL_FORBID_SELL
    end
    local bagType = self:GetBagType(itemData)
    local item, index = self:GetItemByIdx(idx, bagType)
    if not item then
        return error_code.ITEM_SELL_ITEM_NOT_EXISTED
    end
    if not self:SellConditionCheck(item, id, idx, typeId) then
        return error_code.ITEM_SELL_DATA_UNMATCH
    end
    local bagDatas = self:GetItemsByType(bagType)
    local retCode = self:ActionSell(bagDatas, item, index, count, bagType)
    if retCode == error_code.ITEM_SELL_SUCCESS then
        local avatar = self.ptr.theOwner
        local gold   = count*itemData.price
        avatar:AddGold(gold, reason_def.sell_item)
    end
    return retCode
end
function InventorySystem:PriceCheck(itemData)
    if not itemData.price or itemData.price == -1 then
        return false
    end
    return true 
end
function InventorySystem:SellConditionCheck(item, id, idx, typeId)
    if item[INSTANCE_ID] ~= id then 
        return false
    end
    if item[INSTANCE_GRIDINDEX] ~= idx then 
        return false
    end
    if item[INSTANCE_TYPEID] ~= typeId then 
        return false
    end
    return true
end
function InventorySystem:ActionSell(bagDatas, item, index, count, bagType)
    local avatar = self.ptr.theOwner
    if item[INSTANCE_COUNT] < count then 
        return error_code.ITEM_SELL_COUNT_ERROR
    end
    if item[INSTANCE_COUNT] > count then
        item[INSTANCE_COUNT] = item[INSTANCE_COUNT] - count
        self:UpdateClient(bagType, ITEM_OPTION_UPDATE, item)
    elseif item[INSTANCE_COUNT] == count then
        item[INSTANCE_COUNT] = 0
        table.remove(bagDatas, index)
        self:UpdateClient(bagType, ITEM_OPTION_DELETE, item)
    end
    log_game_debug("InventorySystem:ActionSell", "dbid=%q;name=%s;typeId=%d;count=%d;gridIndex=%d;reason=%d", 
        avatar.dbid, avatar.name, item[INSTANCE_TYPEID], count, index, reason_def.sell_item)
    return error_code.ITEM_SELL_SUCCESS
end
----------------------------------------------------------------------
--换装接口
----------------------------------------------------------------------
--装备类型为戒指，特殊规则。
--如果两个位置都是空的，按照顺序放到第一个戒指位里
--如果一个空一个不空，放到空的那个里
--如果两个都不空，替掉分值低的那个
--若两个戒指分值是一样的，按照顺序替换第一个戒指位
----------------------------------------------------------------------
function InventorySystem:ReplaceEquipment(id, idx)
    local unequiped = self:CheckIdx(idx)
    if not unequiped then
        return -1, error_code.CHG_EQUIP_EQUIPMENT_NOT_EXISTED
    end
    if not self:CheckId(unequiped, id) then
        return -1, error_code.CHG_EQUIP_DATA_UNMATCH
    end
    local itemData = self:GetItemData(unequiped[INSTANCE_TYPEID])
    if not itemData then 
        return -1, error_code.CHG_EQUIP_EQUIPMENT_NOT_EXISTED_IN_CFG_TBL --需修短
    end
    if not self:CheckNeedLevel(itemData) then
        return -1, error_code.CHG_EQUIP_LEVEL_NOT_ENOUGH
    end
    if not self:CheckVocation(itemData) then
        return -1, error_code.CHG_EQUIP_VOCATION_UNMATCH
    end
    return self:ActionEquipment(itemData, unequiped)
end
function InventorySystem:CheckIdx(idx)
    local avatar = self.ptr.theOwner
    local item = self:GetItemByIdx(idx, BAG_TYPE_EQUIPMENT)
    if not item then
        log_game_error("InventorySystem:CheckIdx", "nil! dbid=%q;name=%s;idx=%d", avatar.dbid, avatar.name, idx)
        return
    end
    if item[INSTANCE_GRIDINDEX] ~= idx then 
        log_game_error("InventorySystem:CheckIdx", "unmatch! dbid=%q;name=%s;idx=%d", avatar.dbid, avatar.name, idx)
        return
    end
    return item
end
function InventorySystem:CheckId(item, id)
    local avatar = self.ptr.theOwner
    if item[INSTANCE_ID] ~= id then 
        log_game_error("InventorySystem:CheckId", "dbid=%q;name=%s;req_id=%d;id=%d", 
            avatar.dbid, avatar.id, item[INSTANCE_ID], id)
        return false
    end
    return true
end
function InventorySystem:CheckNeedLevel(itemData)
    local avatar = self.ptr.theOwner
    if itemData.levelNeed > avatar.level then
        return false
    end
    return true
end
function InventorySystem:CheckVocation(itemData)
    local avatar = self.ptr.theOwner
    if itemData.vocation ~= AVATAR_ALL_VOC 
        and itemData.vocation ~= avatar.vocation then
        log_game_error("InventorySystem:CheckVocation", "dbid=%q;name=%s;vocation=%d", 
            avatar.dbid, avatar.name, avatar.vocation)
        return false
    end
    return true
end
function InventorySystem:ActionEquipment(itemData, unequiped)
    local posi = itemData.type
    if posi == BODY_POS_FINGER then
        return self:ActionRing(posi, unequiped)
    elseif posi == BODY_POS_WEAPON then
        return self:ActionWeapon(posi + 1, unequiped)
    else
        return self:ActionOthers(posi, unequiped)
    end
end
function InventorySystem:ActionRing(posi, unequiped)
    local leftRing = self:GetItemByIdx(posi, BAG_TYPE_BODY)
    if not leftRing then
        return self:WearEquipment(posi, unequiped)
    end
    local rightRing = self:GetItemByIdx(posi + 1, BAG_TYPE_BODY)
    if not rightRing then
        return self:WearEquipment(posi + 1, unequiped)
    end
    local leftScores = self:GetAttriScores(leftRing[INSTANCE_TYPEID])
    local rightSocres = self:GetAttriScores(rightRing[INSTANCE_TYPEID])
    if not leftScores or not rightSocres then
        return -1, error_code.CHG_EQUIP_EQUIPMENT_NOT_EXISTED_IN_CFG_TBL
    end
    if leftScores <= rightSocres then
        return self:ExchangeEquipment(leftRing, unequiped)
    else
        return self:ExchangeEquipment(rightRing, unequiped)
    end
end
function InventorySystem:ActionWeapon(posi, unequiped)
    local weapon = self:GetItemByIdx(posi, BAG_TYPE_BODY)
    if not weapon then
        return self:WearEquipment(posi, unequiped)
    else
        return self:ExchangeEquipment(weapon, unequiped)
    end
end
function InventorySystem:ActionOthers(posi, unequiped)
    local others = self:GetItemByIdx(posi, BAG_TYPE_BODY)
    if not others then
        return self:WearEquipment(posi, unequiped)
    else
        return self:ExchangeEquipment(others, unequiped)
    end
end
function InventorySystem:WearEquipment(posi, unequiped)
    local bagDatas  = self:GetItemsByType(BAG_TYPE_BODY)
    local id        = unequiped[INSTANCE_ID]
    local gridIndex = unequiped[INSTANCE_GRIDINDEX]
    local typeId    = unequiped[INSTANCE_TYPEID]
    self:DelItemFromBag(id, gridIndex, typeId)
    unequiped[INSTANCE_GRIDINDEX] = posi
    self:AddItemToBody(unequiped)
    self:SyncVisibleMode(unequiped)
    return typeId, error_code.CHG_EQUIP_SUCCESS
end
function InventorySystem:ExchangeEquipment(equiped, unequiped)
    local id      = unequiped[INSTANCE_ID]
    local gdIndex = unequiped[INSTANCE_GRIDINDEX]
    local typeId  = unequiped[INSTANCE_TYPEID]
    self:DelItemFromBag(id, gdIndex, typeId)
    id            = equiped[INSTANCE_ID]
    gdIndex       = equiped[INSTANCE_GRIDINDEX]
    typeId        = equiped[INSTANCE_TYPEID]
    self:DelItemFromBody(id, gdIndex, typeId)
    equiped[INSTANCE_GRIDINDEX]   = unequiped[INSTANCE_GRIDINDEX]
    unequiped[INSTANCE_GRIDINDEX] = gdIndex
    self:AutoInlayJewels(equiped, unequiped)
    self:AddItemToBag(equiped)
    self:AddItemToBody(unequiped)
    self:SyncVisibleMode(unequiped)
    return unequiped[INSTANCE_TYPEID], error_code.CHG_EQUIP_SUCCESS
end
function InventorySystem:GetAttriScores(typeId)
    local itemData = self:GetItemData(typeId)
    if not itemData then
        return false
    end
    if itemData.quality == ITEM_QUALITY_GOLD then
        return self:GetGoldScores(itemData) 
    else
        return self:GetGeneralScores(itemData)
    end
end
function InventorySystem:GetCfgAttri(attkey, attri)
    local avatar = self.ptr.theOwner
    local tpAttri = g_itemdata_mgr:GetItem(ITEM_CONFIGURE_ATTR, attkey)
    if not tpAttri then
        log_game_error("InventorySystem:GetCfgAttri", "dbid=%q;name=%s;key=%s", avatar.dbid, avatar.name, attkey)
        return
    end
    return tpAttri
end
function InventorySystem:GetGoldScores(itemData)
    local avatar   = self.ptr.theOwner
    return self:GetSocres(itemData, avatar.level)
end
function InventorySystem:GetGeneralScores(itemData)
    local scores = self:GetSocres(itemData, itemData.levelNeed)
    return scores
end
function InventorySystem:GetSocres(itemData, level)
    local attkey   = -1
    local attri    = -1
    attkey = itemData.quality .. AVATAR_ALL_VOC .. itemData.type .. level
    attri = self:GetCfgAttri(attkey)
    if not attri then
        attkey = itemData.quality .. itemData.vocation .. itemData.type .. level
        attri = self:GetCfgAttri(attkey)
        if not attri then
            return false
        end
    end
    return attri.scores
end
function InventorySystem:AutoInlayJewels(equiped, unequiped)
    local eSlots = equiped[INSTANCE_SLOTS]
    local nSlots = unequiped[INSTANCE_SLOTS]
    local aSlots = {} --抽取宝石
    self:RemoveJewel(eSlots, aSlots)
    self:RemoveJewel(nSlots, aSlots)
    local uTypeId   = unequiped[INSTANCE_TYPEID]
    local uItemData = self:GetItemData(uTypeId)
    local jewelSlot = uItemData.jewelSlot or {} --获取装备的宝石插槽类型
    local newSlots  = {}
    local avatar = self.ptr.theOwner
    log_game_debug("InventorySystem:AutoInlayJewels", "remove from equip!dbid=%q;name=%s;eSlots=%s;nSlots=%s;aSlots=%s", 
        avatar.dbid, avatar.name, mogo.cPickle(eSlots), mogo.cPickle(nSlots), mogo.cPickle(aSlots)) 
    for idx, slotType in pairs(jewelSlot) do --镶嵌宝石
        local jewelId = 0
        if slotType == JEWEL_SLOT_TYPE then
            jewelId = self:GetComJewelId(aSlots, slotType)
        else
            jewelId = self:GetProperJewel(aSlots, slotType)
        end
        if jewelId and aSlots[jewelId] then
            if aSlots[jewelId] > 1 then
                aSlots[jewelId] = aSlots[jewelId] - 1
            else
                aSlots[jewelId] = nil
            end
        end
        newSlots[idx] = jewelId
        log_game_debug("InventorySystem:AutoInlayJewels", "inlay jewel!dbid=%q;name=%s;newSlots=%s;aSlots=%s", 
            avatar.dbid, avatar.name, mogo.cPickle(newSlots), mogo.cPickle(aSlots))
    end
    equiped[INSTANCE_SLOTS]   = {}
    unequiped[INSTANCE_SLOTS] = newSlots
    for jewelId, count in pairs(aSlots) do
        if not self:IsSpaceEnough(jewelId, count) then
            self:SendRemainJewel(aSlots) --发送邮件
            avatar:ShowTextID(CHANNEL.DLG, public_config.JWEl_AUTO_MSG_MAIL)
            return error_code.ERR_JEWEl_INLAY_MAIL
        end
    end
    --加入背包
    for jewelId, count in pairs(aSlots) do
        log_game_debug("InventorySystem:AutoInlayJewels", "add to inventory!dbid=%q;name=%s;aSlots=%s", 
            avatar.dbid, avatar.name, mogo.cPickle(aSlots))
        avatar:AddItem(jewelId, count, reason_def.autoInlay)
    end
    if next(aSlots) then
        avatar:ShowTextID(CHANNEL.DLG, public_config.JWEl_AUTO_MSG_BAG)
        return error_code.ERR_JEWEl_INLAY_BAG
    end
    if next(newSlots) then
        local eTypeId = equiped[INSTANCE_TYPEID]
        local sParas  = {}
        sParas['item_id1'] = eTypeId
        sParas['item_id2'] = uTypeId
        if avatar:hasClient() then
            avatar.client.ShowTextIDWithArgs(CHANNEL.DLG, public_config.JWEl_AUTO_MSG_OK, sParas)
        end
        return error_code.ERR_JEWEl_INLAY_OK
    end
end
function InventorySystem:SendRemainJewel(allSlots)
    local avatar = self.ptr.theOwner
    log_game_debug("InventorySystem:SendRemainJewel", "dbid=%q;name=%s;allSlots=%s", 
            avatar.dbid, avatar.name, mogo.cPickle(allSlots))
    local titleId = public_config.JEWL_AUTO_MAIL_TITLE
    local textId  = public_config.JEWL_AUTO_MAIL_TEXT
    local fromId  = public_config.JEWL_AUTO_MAIL_SENDER
    local prefix  = g_text_mgr:GetText(public_config.JEWEL_AUTO_INLAY_PREFIX)
    local to      = string.format("%s[%s]", prefix, avatar.name)
    globalbase_call("MailMgr", "SendIdEx", titleId, to, textId, fromId, os.time(), allSlots, {avatar.dbid}, {}, reason_def.autoInlay)
end
function InventorySystem:RemoveJewel(slots, aSlots)
    for _, typeId in pairs(slots) do
        if aSlots[typeId] then
            aSlots[typeId] = aSlots[typeId] + 1
        else
            aSlots[typeId] = 1
        end
    end
end
--查找非通用宝石(按照同类型等级)
function InventorySystem:GetProperJewel(allSlots, slotType)
    local maxLevel = 0
    local properId = 0
    for jewelId, count in pairs(allSlots) do
        local jewelData = self:GetItemData(jewelId)
        local jewSTypes = jewelData.slotType or {}
        if jewSTypes[slotType] then
            local jewelLevel = jewelData.level or 0
            if maxLevel < jewelLevel then
                maxLevel = jewelLevel
                properId = jewelId
            end
        end
    end
    if properId > 0 then
        return properId
    end
end
--查找通用宝石孔(按照宝石排序表索取最高等级)
function InventorySystem:GetComJewelId(allSlots, slotType)
    local jewSorts = g_JewelSort_mgr:GetJewelInlaySort()
    local avatar = self.ptr.theOwner
    if not jewSorts then
        log_game_error("InventorySystem:GetComJewelId", "dbid=%q;name=%s;jewel type sort error", avatar.dbid, avatar.name)
        return
    end
    local maxLevels = {}
    for idx, item in pairs(jewSorts) do
        maxLevels[idx] = 0
    end
    local maxIds = {}
    for jewelId, count in pairs(allSlots) do
        local jewelData = self:GetItemData(jewelId)
        local jewSTypes = jewelData.slotType or {}
        if jewSTypes[slotType] then
            local jewelLv   = jewelData.level or 0
            --获取宝石优先级
            local subType   = jewelData.subtype or 0
            local priority  = g_JewelSort_mgr:GetPriorityIdx(subType)
            --所有宝石的优先级计算
            if maxLevels[priority] and maxLevels[priority] < jewelLv then
                maxLevels[priority] = jewelLv
                maxIds[priority] = jewelId
            end
        end
    end
    --log_game_debug("InventorySystem:GetComJewelId", "dbid=%q;name=%s;maxLevels=%s;maxIds=%s", 
    --    avatar.dbid, avatar.name, mogo.cPickle(maxLevels), mogo.cPickle(maxIds))
    local minIdx = g_JewelSort_mgr:GetMinSortIdx()
    local maxIdx = g_JewelSort_mgr:GetMaxSortIdx()
    --log_game_debug("InventorySystem:GetComJewelId", "dbid=%q;name=%s;minIdx=%d;maxIdx=%d",
    --    avatar.dbid, avatar.name, minIdx, maxIdx)
    for idx = minIdx, maxIdx do
        if maxIds[idx] and maxIds[idx] > 0 then
            return maxIds[idx]
        end
    end
end
---------------------------------------------------------------------
--分解装备接口
---------------------------------------------------------------------
function InventorySystem:DecomposeEquipment(id, idx)
    local avatar = self.ptr.theOwner
    local item   = self:GetItemByIdx(idx, BAG_TYPE_EQUIPMENT)
    if not item then
        log_game_error("InventorySystem:DecomposeEquipment", "dbid=%q;name=%s", avatar.dbid, avatar.name)
        return -1, error_code.DEP_EQUIP_EQUIP_NOT_IN_INVRY
    end
    if not self:CheckId(item, id) then
        return -1, error_code.DEP_EQUIP_DATA_UNMATCH
    end
    local itemData = self:GetItemData(item[INSTANCE_TYPEID])  
    if not itemData then
        return -1, error_code.DEP_EQUIP_EQUIP_NOT_IN_CFG_TBL
    end
    local deps    = self:GetDepsCfgData(itemData)
    local results, hasJewel = self:GetDepsRes(item, deps)
    if not self:SpaceForItems(results) then
        log_game_error("InventorySystem:DecomposeEquipment", "space limited!dbid=%q;name=%s", avatar.dbid, avatar.name)        
        return -1, error_code.DEP_EQUIP_SPACE_LIMITED
    end
    local id      = item[INSTANCE_ID]
    local gdIndex = item[INSTANCE_GRIDINDEX]
    local typeId  = item[INSTANCE_TYPEID]
    self:DelItemFromBag(id, gdIndex, typeId)
    self:ActionDepsRes(results)
    self:ActionDepsGold(deps)
    avatar:OnBreakEquip(typeId) --商城事件刷新
    return idx, error_code.DEP_EQUIP_SUCCESS, hasJewel
end
--获取分解配置数据
function InventorySystem:GetDepsCfgData(itemData)
    local avatar = self.ptr.theOwner
    local key    = itemData.levelNeed .. itemData.quality
    local deps   = g_itemdata_mgr:GetItem(ITEM_CONFIGURE_DEEQ, key)
    if not deps then
        log_game_error("InventorySystem:GetDepsData", "cfg nil! dbid=%q;name=%s", avatar.dbid, avatar.name)
        return
    end
    return deps
end
--获取随机结果
function InventorySystem:GetDepsRes(item, deps)
    local results = {}
    setmetatable(results, {__index = 
        function (table, key)
            return 0
        end
    })
    local hasJewel = self:GetInlayJewels(item, results)
    local rProp =  self:GetRandProp(deps)
    self:GetRandRes(rProp, deps, results)
    return results, hasJewel
end
--摘除装备上镶嵌的宝石
function InventorySystem:GetInlayJewels(item, results)
    local slots    = item[INSTANCE_SLOTS] or {}
    local hasJewel = false 
    for _, vId in pairs(slots) do
        results[vId] = results[vId] + 1
        hasJewel = true
    end
    return hasJewel
end
--获取随机概率值
function InventorySystem:GetRandProp(deps)
    local prop = {}
    if deps.chance1 then
        table.insert(prop, deps.chance1*0.0001)
    end
    if deps.chance2 then
        table.insert(prop, deps.chance2*0.0001)
    end
    if deps.chance3 then
        table.insert(prop, deps.chance3*0.0001)
    end
    return lua_util.choice(prop)
end
--获取分解随机数据
function InventorySystem:GetRandRes(pb, deps, results)
    local tp = {}
    if pb == 1 then
        tp = deps.reward1
    elseif pb == 2 then
        tp = deps.reward2
    elseif pb == 3 then
        tp = deps.reward3
    end
    for k, v in pairs(tp) do
        results[k] = results[k] + v
    end
end
function InventorySystem:ActionDepsRes(items)
    local avatar = self.ptr.theOwner
    for k, v in pairs(items) do
        avatar:AddItem(k, v, reason_def.decompose)
    end
end
function InventorySystem:ActionDepsGold(deps)
    local gold = 0
    local rangeGold = deps.gold or {0, 0}
    math.randomseed(os.time())
    local left  = rangeGold[1]
    local right = rangeGold[2] or left
    gold = math.random(left, right)
    if gold > 0 then
        local avatar = self.ptr.theOwner
        avatar:AddGold(gold, reason_def.decompose)
    end
end
-------------------------------------------------------------------
--卸装接口
-------------------------------------------------------------------
-- function InventorySystem:RemoveEquipment(id, idx)
--     --todo
-- end
-------------------------------------------------------------------
--装备加锁
-------------------------------------------------------------------
function InventorySystem:LockEquipment(id, idx)
    local avatar = self.ptr.theOwner
    local item = self:GetItemByIdx(idx, BAG_TYPE_EQUIPMENT)
    if not item then
        log_game_error("InventorySystem:LockEquipment", "dbid=%q;name=%s;idx=%d", 
            avatar.dbid, avatar.name, idx)
        return error_code.ERR_ITEM_LOCK_NO
    end
    local extInfo = item[INSTANCE_EXTINFO]
    if not extInfo[ITEM_EXTINFO_LOCKED] then
        extInfo[ITEM_EXTINFO_LOCKED] = ITEM_LOCKED_OK
    elseif extInfo[ITEM_EXTINFO_LOCKED] == ITEM_LOCKED_OK then
        extInfo[ITEM_EXTINFO_LOCKED] = ITEM_LOCKED_NO
    elseif extInfo[ITEM_EXTINFO_LOCKED] == ITEM_LOCKED_NO then
        extInfo[ITEM_EXTINFO_LOCKED] = ITEM_LOCKED_OK
    end
    return error_code.ERR_ITEM_LOCK_OK
end

--获取指定背包中指定道具个数
function InventorySystem:GetItemCountsInSpeciBag(bagType, typeId)
    local bagDatas = self:GetItemsByType(bagType)
    local cnt = 0
    for k, v in pairs(bagDatas) do
        if v[INSTANCE_TYPEID] == typeId then 
            cnt = cnt + v[INSTANCE_COUNT]
        end
    end
    return cnt
end
--获取背包中指定道具个数
function InventorySystem:GetItemCountsInBag(typeId)
    local itemData = self:GetItemData(typeId)
    if not itemData then
        return 0
    end
    local bagType = self:GetBagType(itemData)
    return self:GetItemCountsInSpeciBag(bagType, typeId)
end
--获取背包道具个数
function InventorySystem:GetItemsFromSpeciBag(bagType)
    local  bagDatas = self:GetItemsByType(bagType)
    return self:GetTableItemsCount(bagDatas) 
end
-------------------------------------------------------------------
--单条数据刷新接口
-------------------------------------------------------------------
function InventorySystem:UpdateClient(bagType, optType, item)
    local avatar = self.ptr.theOwner
    local formatItem = 1
    if optType == ITEM_OPTION_ADD or optType == ITEM_OPTION_UPDATE then
        formatItem = self:FormatToClient(bagType, item)
    end
    if optType == ITEM_OPTION_DELETE then
        formatItem = self:DeleteFromClient(bagType, item)
    end
    avatar:UpdateItem(optType, formatItem)
    return true
end
--道具删除格式化lua table参数
function InventorySystem:DeleteFromClient(bagType, item)
    local del = {}
    table.insert(del, bagType)
    table.insert(del, item[INSTANCE_GRIDINDEX] - 1) 
    return del
end
--道具新增及更新格式lua table参数
function InventorySystem:FormatToClient(bagType, item)
    local tpItem = {}
    table.insert(tpItem, item[INSTANCE_ID])    
    table.insert(tpItem, item[INSTANCE_TYPEID])
    table.insert(tpItem, bagType)
    table.insert(tpItem, item[INSTANCE_GRIDINDEX] - 1)
    table.insert(tpItem, item[INSTANCE_COUNT])
    table.insert(tpItem, item[INSTANCE_BINDTYPE]) 
    table.insert(tpItem, item[INSTANCE_SLOTS]) 
    table.insert(tpItem, 0) --source key
    table.insert(tpItem, 0) --source value
    table.insert(tpItem, 0) 
    table.insert(tpItem, item[INSTANCE_EXTINFO])
    return tpItem
end
-------------------------------------------------------------------
--同步角色外观属性
-------------------------------------------------------------------
--同步有外形的角色已穿戴的装备
function InventorySystem:SyncVisibleMode(item)
    local avatar = self.ptr.theOwner
    local idx    = item[INSTANCE_GRIDINDEX]
    local typeId = item[INSTANCE_TYPEID]
    if idx == public_config.BODY_CHEST           --胸甲槽位
        or idx == public_config.BODY_ARMGUARD    --护手槽位
        or idx == public_config.BODY_LEG         --腿的槽位
        or idx == public_config.BODY_WEAPON then --武器槽位
        avatar.cell.SyncEquipMode(idx, typeId)
    end
end
--创建角色同步其他玩家可见外观
function InventorySystem:SyncVisibleProps()
    local position = {}
    position[public_config.BODY_CHEST]    = 1
    position[public_config.BODY_ARMGUARD] = 1
    position[public_config.BODY_LEG]      = 1
    position[public_config.BODY_WEAPON]   = 1
    local item = 1
    local avatar = self.ptr.theOwner
    for k, v in pairs(position) do
        item = self:GetItemByIdx(k, BAG_TYPE_BODY)
        if not item then
            avatar.cell.SyncEquipMode(k, 0)
        else
            avatar.cell.SyncEquipMode(k, item[INSTANCE_TYPEID])
        end
    end
end
-------------------------------------------------------------------
--批量数据刷新接口
-------------------------------------------------------------------
function InventorySystem:UpdateBagToClient(bagType, bagDatas)
    local tp = {}
    for k, v in pairs(bagDatas) do
        table.insert(tp, self:FormatToClient(bagType, v))
    end
    if next(tp) == nil then return end
    local avatar = self.ptr.theOwner
    avatar:UpdateArrayItem(tp)
end
--玩家登陆后刷新背包数据给前端
function InventorySystem:UpdateArrayToClient()
    local allBags = self:GetAllBags()
    for k, v in pairs(allBags) do
        self:UpdateBagToClient(k, v)
    end
end
function InventorySystem:GetAllBags()
    local allBags = {}
    allBags[BAG_TYPE_BODY]      = self:GetItemsByType(BAG_TYPE_BODY)
    allBags[BAG_TYPE_EQUIPMENT] = self:GetItemsByType(BAG_TYPE_EQUIPMENT)
    allBags[BAG_TYPE_JEWELS]    = self:GetItemsByType(BAG_TYPE_JEWELS)
    allBags[BAG_TYPE_MATERIALS] = self:GetItemsByType(BAG_TYPE_MATERIALS)
    return allBags
end
function InventorySystem:ActivedSuitEquipmentReq(typeId)
    local retCode = error_code.ERR_ITEM_ACTIVE_CFG
    local itemData = self:GetItemData(typeId)
    if not itemData then
        self:ActivedSuitEquipmentResp(retCode, 0, 0)
        return
    end
    local suitId = itemData.suitId
    if not suitId then
        local avatar = self.ptr.theOwner
        log_game_error("InventorySystem:ActivedSuitEquipmentReq", 
            "suitId nil dbid=%q;name=%s;typeId=%d", avatar.dbid, avatar.name, typeId)
        self:ActivedSuitEquipmentResp(retCode, 0, 0)
        return
    end
    self:ActionSuitActive(suitId, typeId)
end
function InventorySystem:ActionSuitActive(suitId, typeId)
    if not self:IsRightSuitId(suitId, typeId) then
        return
    end
    local costs = self:ActiveSuitCostsCheck(suitId)
    if not costs then
        return
    end
    local retCode = error_code.ERR_ITEM_ACTIVE_OK
    local bagType = BAG_TYPE_BODY
    --local itemData = self:GetItemData(typeId)
    local flag = self:MarkSuitItem(bagType, typeId)
    if  not flag then
        bagType = BAG_TYPE_EQUIPMENT
        flag = self:MarkSuitItem(bagType, typeId)
        if not flag then
            retCode = error_code.ERR_ITEM_ACTIVE_NO
            self:ActivedSuitEquipmentResp(retCode, 0, 0)
            return
        end
    end
    local avatar  = self.ptr.theOwner
    for costId, count in pairs(costs) do
        avatar:DelItem(costId, count, reason_def.activeEquip)
    end
    self:ActivedSuitEquipmentResp(retCode, typeId, bagType)
end
function InventorySystem:ActiveSuitCostsCheck(suitId)
    local suitData = self:GetSuitCfgData(suitId)
    local costs    = suitData.costs or {}
    for typeId, count in pairs(costs) do
        if not self:hasEnoughItems(typeId, count) then
            local retCode = error_code.ERR_ITEM_ACTIVE_UNCOSTS
            self:ActivedSuitEquipmentResp(retCode, 0, 0)
            return
        end
    end
    return costs
end
function InventorySystem:IsRightSuitId(suitId, typeId)
    local retCode = error_code.ERR_ITEM_ACTIVE_CFG
    local suitData = self:GetSuitCfgData(suitId)
    if not suitData then
        self:ActivedSuitEquipmentResp(retCode, 0, 0)
        return
    end
    local suits = self:GetVocationSuits(suitData)
    for _, tpSuitId in pairs(suits) do
        if tpSuitId == typeId then
            return true
        end
    end
    retCode = error_code.ERR_ITEM_ACTIVE_WRONG
    self:ActivedSuitEquipmentResp(retCode, 0, 0)
    return false
end
function InventorySystem:MarkSuitItem(bagType, typeId)
    local bagDatas = self:GetItemsByType(bagType)
    local avatar = self.ptr.theOwner
    for _, item in pairs(bagDatas) do
        if item[INSTANCE_TYPEID] == typeId then
            local extInfo = item[INSTANCE_EXTINFO]
            local mark = extInfo[ITEM_EXTINFO_ACTIVE] or ITEM_ACTIVED_NO
            if mark == ITEM_ACTIVED_NO then
                extInfo[ITEM_EXTINFO_ACTIVE] = ITEM_ACTIVED_OK
                self:UpdateClient(bagType, ITEM_OPTION_UPDATE, item)
                if bagType == BAG_TYPE_BODY then --激活已穿戴的装备，属性重新计算
                    avatar:triggerEvent(event_config.EVENT_AVATAR_PROPERTIES_RECALCULATE)
                end
                return true
            end
        end
    end
    return false
end
function InventorySystem:GetVocationSuits(suitData)
    local vocType = self.ptr.theOwner.vocation
    if public_config.VOC_WARRIOR == vocType then         -- 战士
        return suitData.vocation1 or {}
    elseif public_config.VOC_ASSASSIN == vocType then    -- 刺客
        return suitData.vocation2 or {}
    elseif public_config.VOC_ARCHER == vocType then      -- 弓箭手
        return suitData.vocation3 or {}
    elseif public_config.VOC_MAGE == vocType then        -- 法师
        return suitData.vocation4 or {}
    end
end
function InventorySystem:GetSuitCfgData(suitId)
    local suitData = g_itemdata_mgr:GetItem(ITEM_TYPE_SUITEQUIPMENT, suitId)
    if not suitData then
        local avatar = self.ptr.theOwner
        log_game_error("InventorySystem:GetSuitCfgData", 
            "suit configure nil! dbid=%q;name=%s;suitId=%d", avatar.dbid, avatar.name, suitId)
    end
    return suitData
end
function InventorySystem:ActivedSuitEquipmentResp(retCode, typeId, bagType)
    local avatar = self.ptr.theOwner
    if avatar:hasClient() then
        avatar.client.ActivedSuitEquipmentResp(retCode, typeId, bagType)
    end
end
-------------------------------------------------------------------
return InventorySystem
