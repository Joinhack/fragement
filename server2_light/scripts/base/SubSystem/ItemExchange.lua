--兑换系统
require "lua_util"
require "Item_data"
require "error_code"
require "reason_def"

local log_game_error = lua_util.log_game_error
local log_game_info  = lua_util.log_game_info
local log_game_debug = lua_util.log_game_debug
--
local ITEM_CONFIGURE_PURP       = public_config.ITEM_TYPE_PURPLE_EXCHANGE--紫装兑换
--角色职业配置
local VOC_WARRIOR               = public_config.VOC_WARRIOR              --战士
local VOC_ASSASSIN              = public_config.VOC_ASSASSIN             --刺客
local VOC_ARCHER                = public_config.VOC_ARCHER               --箭手
local VOC_MAGE                  = public_config.VOC_MAGE                 --法师
local AVATAR_ALL_VOC            = public_config.AVATAR_ALL_VOC           --全职业
local MAX_OTHER_ITEM_ID         = public_config.MAX_OTHER_ITEM_ID        --特殊道具id上限
local AVATAR_USE_GOLD           = public_config.GOLD_ID                  --使用金币
local ExchangeSystem = {}
ExchangeSystem.__index = ExchangeSystem

--------------------------------------------------------------------
--紫装兑换接口
--------------------------------------------------------------------
function ExchangeSystem:PurpleExchange(avatar, id)
    log_game_info("ExchangeSystem:PurpleExchange", "dbid=%q;name=%s;id=%d", avatar.dbid, avatar.name, id)
    local itemData = self:GetPurpleCfg(avatar, id)
    if not itemData then
        avatar:ShowTextID(CHANNEL.TIPS, error_code.PURPLE_EXCHANGE_ID_NIL)
        return false
    end
    local costs  = itemData.cost or {}
    if not self:CheckCosts(avatar, costs) then
        return false
    end
    local typeId = self:GetPurpleReward(avatar, itemData)
    if not self:IsSpaceOk(avatar, typeId, 1) then
        avatar:ShowTextID(CHANNEL.TIPS, error_code.PURPLE_EXCHANGE_BAG_FULL)
        return false
    end
    self:ActionCosts(avatar, costs)
    avatar:AddItem(typeId, 1, reason_def.purple)
    avatar:ShowTextID(CHANNEL.TIPS, error_code.PURPLE_EXCHANGE_SUCCESS)
    return true
end
function ExchangeSystem:ActionCosts(avatar, costs)
    local validItems, specialItems = self:SplitItems(costs)
    for kId, vCount in pairs(validItems) do
        avatar:DelItem(kId, vCount, reason_def.purple)
    end
    local gold = specialItems[AVATAR_USE_GOLD] or 0
    if gold > 0 then
        avatar:AddGold(-gold, reason_def.purple)
    end
end
function ExchangeSystem:GetPurpleReward(avatar, itemData)
    local cfgRewards = itemData.reward
    local vocReward = cfgRewards[avatar.vocation]
    if not vocReward then
        vocReward = cfgRewards[AVATAR_ALL_VOC]
        if not vocReward then
            log_game_error("ExchangeSystem:GetPurpleReward", "dbid=%q;name=%s;vocation=%d", 
                avatar.dbid, avatar.name, avatar.vocation)
        end
    end
    return vocReward
end
function ExchangeSystem:GetPurpleCfg(avatar, id)
    local itemData = g_itemdata_mgr:GetItem(ITEM_CONFIGURE_PURP, id)
    if not itemData then
        log_game_error("ExchangeSystem:GetPurpleCfg", "dbid=%q;name=%s;id=%d", 
            avatar.dbid, avatar.name, id)
    end
    return itemData
end
function ExchangeSystem:CheckCosts(avatar, items)
    local validItems, specialItems = self:SplitItems(items)
    for kId, vCount in pairs(validItems) do
        if not self:IsCostOk(avatar, kId, vCount) then
            avatar:ShowTextID(CHANNEL.TIPS, error_code.PURPLE_EXCHANGE_LIMITED)
            return false
        end
    end
    local gold = specialItems[AVATAR_USE_GOLD] or 0
    if avatar.gold < gold then
        avatar:ShowTextID(CHANNEL.TIPS, error_code.PURPLE_EXCHANGE_GOLD_LIMIT)
        return false
    end
    return true
end
function ExchangeSystem:IsSpaceOk(avatar, typeId, count)
    local inventorySystem = avatar.inventorySystem
    return inventorySystem:IsSpaceEnough(typeId, count)
end
function ExchangeSystem:IsCostOk(avatar, id, count)
    local inventorySystem = avatar.inventorySystem
    return inventorySystem:HasEnoughItems(id, count)
end
function ExchangeSystem:SplitItems(items)
    local validItems   = {}
    local specialItems = {}
    for k, v in pairs(items) do
        if k > MAX_OTHER_ITEM_ID then
            validItems[k]   = v
        else
            specialItems[k] = v
        end
    end
    return validItems, specialItems
end
g_exchange_mgr = ExchangeSystem
return g_exchange_mgr
