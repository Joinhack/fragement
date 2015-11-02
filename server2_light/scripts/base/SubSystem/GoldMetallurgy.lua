require "lua_util"
require "PriceList"
require "vip_privilege"
require "error_code"
require "reason_def"

local log_game_debug = lua_util.log_game_debug
local GoldMetallurgy = {}
GoldMetallurgy.__index = GoldMetallurgy

local GOLDMETALLURGY_COST_INDEX   = public_config.PRICE_LIST_GOLDMETALLURGY_COST_INDEX   --炼金消耗
local GOLDMETALLURGY_GAIN_INDEX   = public_config.PRICE_LIST_GOLDMETALLURGY_GAIN_INDEX   --炼金产出
local DAILY_GOLD_METALLURGY_TIMES = public_config.DAILY_GOLD_METALLURGY_TIMES --炼金次数
local META_GOLD                   = public_config.PRICE_GOLD                  --金币
local META_DIAMOND                = public_config.PRICE_DIAMOND               --钻石
local META_VAL                    = public_config.VARIABLE_PRICE              --可变价格
local META_FIXED                  = public_config.FIXED_PRICE                 --固定价格
--炼金系统完成钻石兑换金币,times为购买次数
--1为单次购买，否则为全部购买
function GoldMetallurgy:ExchangeGold(avatar, times)
    log_game_debug("GoldMetallurgy:ExchangeGold", "dbid=%q;name=%s;times=%d", avatar.dbid, avatar.name, times)
    if times <= 0 or not self:CheckTimes(avatar, times) then
        avatar:ShowTextID(CHANNEL.TIPS, error_code.GOLD_META_TIMES_LIMIT)
        self:ClientResp(avatar, 1) --失败
        return false
    end
    local diamonds = self:GetDiamondCosts(avatar, times)
    if avatar.diamond < diamonds then
        avatar:ShowTextID(CHANNEL.TIPS, error_code.GOLD_META_DIMAOND_UNENOUGH)
        self:ClientResp(avatar, 1) --失败
        return false
    end
    local golds = self:GetGoldGains(avatar, times)
    self:SubDiamond(avatar, diamonds)
    self:AddGold(avatar, golds)
    avatar:SetVipState(DAILY_GOLD_METALLURGY_TIMES, times)
    avatar:ShowTextID(CHANNEL.TIPS, error_code.GOLD_META_SUCCESS)
    avatar:OnLianjin()
    self:ClientResp(avatar, 0) --成功
    return true
end
function GoldMetallurgy:ClientResp(avatar, retCode)
    avatar.client.GoldMetallurgyResp(retCode)
end
--获取兑换金币总额
function GoldMetallurgy:GetGoldGains(avatar, times)
    local gains = 0
    local dailyTimes = self:GetDailyReal(avatar)
    local tpTimes = dailyTimes
    for k = 1, times do
        tpTimes = tpTimes + 1
        gains = gains + self:GetGainPrice(tpTimes)
    end
    return gains
end
--计算钻石消耗总额
function GoldMetallurgy:GetDiamondCosts(avatar, times)
    local cost = 0
    local dailyTimes = self:GetDailyReal(avatar)
    local tpTimes = dailyTimes
    for k = 1, times do
        tpTimes = tpTimes + 1
        cost = cost + self:GetCostPrice(tpTimes)
    end
    return cost
end
--检查次数是否足够
function GoldMetallurgy:CheckTimes(avatar, times)
    local dailyTimes = self:GetDailyReal(avatar)
    local vipLimit   = self:GetDailyLimit(avatar)
    local tpTimes = dailyTimes + times
    if tpTimes > vipLimit then
        return false
    end
    return true
end
--扣除钻石
function GoldMetallurgy:SubDiamond(avatar, count)
    avatar:AddDiamond(-count, reason_def.gold_meta)
end
--增加金币
function GoldMetallurgy:AddGold(avatar, count)
    avatar:AddGold(count, reason_def.gold_meta)
end
--获取每日上线
function GoldMetallurgy:GetDailyLimit(avatar)
    local vipLimit = g_vip_mgr:GetVipPrivileges(avatar.VipLevel)
    local cntLimit = vipLimit.dailyGoldMetallurgyLimit
    return cntLimit or 0
end
--获取每日已使用次数
function GoldMetallurgy:GetDailyReal(avatar)
    local buyCount = avatar:GetVipState(DAILY_GOLD_METALLURGY_TIMES)
    return buyCount
end
--设置每日已使用次数
function GoldMetallurgy:SetDailyReal(avatar, count)
    local dailyCount = avatar:SetVipState(DAILY_GOLD_METALLURGY_TIMES, count)
    return dailyCount
end
--获取第times次的钻石消耗
function GoldMetallurgy:GetCostPrice(times)
    local cfgList = g_priceList_mgr:GetPriceData(GOLDMETALLURGY_COST_INDEX)
    return self:GetPrice(cfgList, times)
end
--获取第times次的金币
function GoldMetallurgy:GetGainPrice(times)
    local cfgList = g_priceList_mgr:GetPriceData(GOLDMETALLURGY_GAIN_INDEX)
    return self:GetPrice(cfgList, times)
end
--得到第times次单价
function GoldMetallurgy:GetPrice(cfgList, times)
    local priceList = cfgList.priceList
    if cfgList.type == META_VAL and times >= 1 then
        return priceList[times] or 0
    end
    if cfgList.type ==META_FIXED then
        return priceList[1] or 0
    end
    return 0
end

g_goldmeta_mgr = GoldMetallurgy
return g_goldmeta_mgr
