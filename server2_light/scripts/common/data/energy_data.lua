require "lua_util"
require "avatar_level_data"
require "PriceList"
require "vip_privilege"
require "error_code"
require "reason_def"

local log_game_error = lua_util.log_game_error
local log_game_info  = lua_util.log_game_info
local log_game_debug = lua_util.log_game_debug

local EnergyMgr = {}
EnergyMgr.__index = EnergyMgr

local ENERGY_PRICE_LIST_INDEX = public_config.PRICE_LIST_ENERGY_PRICE_LIST_INDEX
local ENERGY_GOLD             = public_config.PRICE_GOLD
local ENERGY_DIAMOND          = public_config.PRICE_DIAMOND
local DAILY_ENERGY_BUY_TIMES  = public_config.DAILY_ENERGY_BUY_TIMES
local ENERGY_VAL              = public_config.VARIABLE_PRICE
local ENERGY_FIXED            = public_config.FIXED_PRICE
--读取体力配置数据
function EnergyMgr:initData()
    local cfgData = lua_util._readXml('/data/xml/Energy.xml', 'id_i')
    if not cfgData then
        log_game_error("EnergyMgr:initData", "Energy.xml nil")
        return 
    end
    EnergyMgr.cfgData = cfgData
end
--获取体力配置数据
function EnergyMgr:GetData()
    if self.cfgData == nil then
        return 
    end
    return self.cfgData[1]
end
--获取角色信息
function EnergyMgr:GetLevelInfo(level)
    if level == 0 then
        level = 1
    end
    local baseProps = g_avatar_level_mgr:GetLevelProps(level)
    if baseProps == nil then
       return
    end
    return baseProps
end
function EnergyMgr:InitEnergy(avatar)
    local val = self:GetMaxEnergy(avatar.level)
    if val and val > 0 then
        avatar.energy = val
    else
		avatar.energy = 0
	end
    avatar.energyCd = os.time()
end
--获取角色最大体力值
function EnergyMgr:GetMaxEnergy(level)
   if level == 0 then
        level = 1
    end
   local baseProps = self:GetLevelInfo(level)
   if baseProps == nil then
       return 
   end
   return baseProps.maxEnergy
end
--获取角色升级体力值
function EnergyMgr:GetUpPoint(level)
  if level == 0 then
        level = 1
    end
   local baseProps = self:GetLevelInfo(level)
   if baseProps == nil then
       return 
   end
   return baseProps.levelUpAddPoints
end
--角色升级处理
function EnergyMgr:RewardLevelUp(avatar, level)
    local upPoints = self:GetUpPoint(level)
    local energyCount = avatar.energy + upPoints
    local energyLimit = self:GetEnergyLimit(avatar.level)
    if energyCount >= energyLimit then
        upPoints = energyLimit - avatar.energy
    end
    avatar:AddEnergy(upPoints, reason_def.level_up)
end
--获取角色体力上限
function EnergyMgr:GetEnergyLimit(level)
   if level == 0 then
        level = 1
    end
   local baseProps = self:GetLevelInfo(level)
   if baseProps == nil then
        return 
   end
   return baseProps.energyLimit
end
--增加角色体力值
function EnergyMgr:AddEnergy(avatar, points)
   local energyCount = avatar.energy + points
   local energyLimit = self:GetEnergyLimit(avatar.level)
   if energyCount > energyLimit then
        avatar.energy = energyCount
       return true
   end
   return false
end
--角色体力扣除值
function EnergyMgr:SubEnergy(avatar, points)
    if avatar.energy < points then
		return false
	end
    avatar:AddEnergy(-points, reason_def.enter_mission)
    return true
end
--获取固定恢复点
function EnergyMgr:GetRecoverPoints()
    local energyData = self:GetData()
    return energyData.recoverPoints or 1 --默认每次恢复1点
end
--获取恢复时间间隔
function EnergyMgr:GetRecoverInterval()
    local energyData = self:GetData()
    return energyData.recoverInterval or 12 --默认为12分钟
end
--获取每次购买体力点
function EnergyMgr:GetFixedPoints()
    local energyData = self:GetData()
    return energyData.fixedPoints or 20 --默认每次购买20点
end
--体力上线检查规则：
--如果体力大于自然恢复最大值，则不再恢复
--否则按时间差恢复，记录剩余恢复时间余留段
function EnergyMgr:EnergyCheck(avatar)
    local maxEnergy = self:GetMaxEnergy(avatar.level)
    local intervals = self:GetRecoverInterval()
    local lastTime  = avatar.energyCd
    local remainder = 0
    if lastTime == nil  or lastTime <= 0 then
       lastTime = os.time()
    end
    intervals = intervals*60
    if avatar.energy < maxEnergy then
        local delta  = os.time() - lastTime
        local lowInt = math.floor(delta/intervals)
        local fixPt  = self:GetRecoverPoints()
        lowInt = lowInt*fixPt
        remainder = math.fmod(delta, intervals)
        if lowInt > ( maxEnergy - avatar.energy ) then
            lowInt = maxEnergy - avatar.energy
        end
        avatar:AddEnergy(lowInt, reason_def.nature_up)
    end
    avatar.energyCd = os.time() - remainder
    return intervals, (intervals - remainder)
end
--体力恢复
--到达自然恢复上限则不再恢复
--否则，当前时间戳减掉上次恢复的剩余时间段
function EnergyMgr:RecoveryEnergy(avatar)
   local maxEnergy     = self:GetMaxEnergy(avatar.level)
   local recoverPoints = self:GetRecoverPoints() 
   local energyCount   = avatar.energy + recoverPoints
   if maxEnergy > avatar.energy then
      if energyCount >= maxEnergy then
          recoverPoints = maxEnergy - avatar.energy
      end
      avatar:AddEnergy(recoverPoints, reason_def.nature_up)
   end
   avatar.energyCd = os.time()
end
--执行消耗操作
function EnergyMgr:ExecuteCost(avatar, cost, count, cfgList, energyCount)
    if cfgList.currencyType == ENERGY_DIAMOND then
        if avatar.diamond < cost then
            avatar:ShowTextID(CHANNEL.TIPS, error_code.ENERGY_DIAMOND_UNENOUGH)
            return
        end
        avatar:AddDiamond(-cost, reason_def.energy_mgr)
    elseif cfgList.currencyType == ENERGY_GOLD then
        if avatar.gold < cost then
            avatar:ShowTextID(CHANNEL.TIPS, error_code.ENERGY_GOLD_UNENOUGH)
            return
        end
        avatar:AddGold(-cost, reason_def.energy_mgr)
    end
    avatar:SetVipState(DAILY_ENERGY_BUY_TIMES, count)
    local delta = energyCount - avatar.energy
    avatar:AddEnergy(delta, reason_def.energy_mgr)
    avatar:OnBuyEnergy(count)  --体力购买次数事件刷新 
    --avatar.energy = energyCount
    log_game_info("EnergyMgr:ExecuteCost", "dbid=%q;name=%s;cost=%d;count=%d", 
        avatar.dbid, avatar.name, cost, count)
    return
end
function EnergyMgr:CheckCondition(avatar, count, opt)
    local cfgList     = g_priceList_mgr:GetPriceData(ENERGY_PRICE_LIST_INDEX)
    local vipLimit    = g_vip_mgr:GetVipPrivileges(avatar.VipLevel)
    local cntLimit    = vipLimit.dailyEnergyBuyLimit
    local fixedPoints = self:GetFixedPoints()
    local buyCount    = 0
    local remain      = 1
    local energyCount = 0
    if opt == public_config.SINGLE_TIME then --单次购买
        buyCount = avatar:GetVipState(DAILY_ENERGY_BUY_TIMES) + count
    elseif opt == public_config.ALL_TIEMS then --全部购买
        buyCount = avatar:GetVipState(DAILY_ENERGY_BUY_TIMES)
        remain   = cntLimit - buyCount
        buyCount = buyCount + count
    end
    if buyCount > cntLimit or count <= 0 then  --体力购买次数上限
        avatar:ShowTextID(CHANNEL.TIPS, error_code.ENERGY_MAX_BUY_TIMES)
        return
    end
    buyCount = buyCount - count
    energyCount = avatar.energy + fixedPoints*remain
    local energyLimit = self:GetEnergyLimit(avatar.level)
    if remain > 0 and count ~= remain then --数量校验
        avatar:ShowTextID(CHANNEL.TIPS, error_code.ENERGY_COUNT)
        return
    end
    if energyLimit < energyCount then --体力点上限
        avatar:ShowTextID(CHANNEL.TIPS, error_code.ENERGY_LIMITED)
        return
    end
    local cost = self:GetCost(buyCount, cfgList, remain)
    log_game_debug("EnergyMgr:CheckCondition", "limit=%d;buyCount=%d;remain=%d", cntLimit, buyCount, remain)
    self:ExecuteCost(avatar, cost, remain, cfgList, energyCount)
end
--价格计算
function EnergyMgr:GetCost(buyCount, cfgList, remain)
    local cost = 0
    local priceList = cfgList.priceList
    if cfgList.type == ENERGY_VAL then
        local idx = buyCount + 1
        for i = 1, remain do   --计算总花费
            cost = cost + priceList[idx]
            idx = idx + 1
        end
    elseif cfgList.type == ENERGY_FIXED then
        cost = priceList[1]
    end
    return cost or 0
end
--单次购买体力
function EnergyMgr:BuyEnergy(avatar, count)
    self:CheckCondition(avatar, count, public_config.SINGLE_TIME)
end
--一次购买体力
function EnergyMgr:BuyAllEnergy(avatar, count)
    self:CheckCondition(avatar, count, public_config.ALL_TIEMS)
end



g_energy_mgr = EnergyMgr

return g_energy_mgr


