require "lua_util"
require "public_config"
require "reason_def"
require "error_code"
local log_game_debug = lua_util.log_game_debug
local log_game_info  = lua_util.log_game_info
local log_game_error = lua_util.log_game_error

local PriceList = {}
PriceList.__index = PriceList 
--管理物品价格列表
function PriceList:initData()
    local  cfgData = lua_util._readXml('/data/xml/PriceList.xml', 'id_i')
    if not cfgData then
    	log_game_error("PriceList:initData", "PriceList.xml Data Empty")
    	return 
    end
    self.cfgData = cfgData
    for _, v in pairs(self.cfgData) do
    	self:VerifyData(v)
    end
end

function PriceList:VerifyData(itemData)
    if not itemData.type then
    	log_game_error("PriceList:VerifyData", "price type error")
    	return
    end
    if not itemData.currencyType then
    	log_game_error("PriceList:VerifyData", "currencyType error")
    	return
    end
    if not itemData.priceList then
    	log_game_error("PriceList:VerifyData", "Price list error")
    	return
    end
end
--获取对应类型物品的价格定义
--id表示表中物品的索引值
function PriceList:GetPriceData(idx)
    if self.cfgData ~= nil then
        return self.cfgData[idx]
    end
end

function PriceList:NeedMoney(idx, times)
	local cfg = self.cfgData[idx]
	if not cfg then
		log_game_error("PriceList:NeedMoney", "%d, no data.", idx)
		return
	end
	local money = 
	{
		[public_config.GOLD_ID] = 0,
		[public_config.DIAMOND_ID] = 0,
	}
	if cfg.type == 1 then
		--todo:价格递增
	elseif cfg.type == 2 then
		--价格固定
		if cfg.currencyType == 1 then
			money[public_config.GOLD_ID] = cfg.priceList[1]
			money[public_config.DIAMOND_ID] = nil
		else
			money[public_config.DIAMOND_ID] = cfg.priceList[1]
			money[public_config.GOLD_ID] = nil
		end
	else
		log_game_error("PriceList:NeedMoney", "%d, type error.", idx)
		return
	end
	return money
end
--按次数计价
function PriceList:PriceCheck(avatar, idx, times)
	local pData = self:GetPriceData(idx)
    if not pData then
        log_game_error("PriceList:PriceCheck", "idx=%d price data nil", idx)
        return false
    end
    if not times then
    	times = 1
    end
    if pData.type == public_config.FIXED_PRICE then
    	times = 1
    end 
    local unitPrice = pData.priceList[times]
    if not unitPrice then
    	log_game_error("PriceList:PriceCheck", "idx=%d times=%d priceList error", idx, times)
		return false
	end
    if pData.currencyType == public_config.PRICE_GOLD then
        if avatar.gold < unitPrice then
            return false --金币不足
        end
    elseif pData.currencyType == public_config.PRICE_DIAMOND then
        if avatar.diamond < unitPrice then
            return false --钻石不足
        end
    end
    return true
end
function PriceList:DeductCost(avatar, idx, reason, times)
	local pData = self:GetPriceData(idx)
	if not times then
		times = 1
	end
	if pData.type == public_config.FIXED_PRICE then
    	times = 1
    end 
	local unitPrice = pData.priceList[times]
	if not unitPrice then
    	log_game_error("PriceList:DeductCost", "idx=%d times=%d priceList error", idx, times)
		return false
	end
	if pData.currencyType == public_config.PRICE_GOLD then
		if avatar.gold >= unitPrice then
			avatar:AddGold(-unitPrice, reason)
			return true
		end
	elseif pData.currencyType == public_config.PRICE_DIAMOND then
		if avatar.diamond >= unitPrice then
			avatar:AddDiamond(-unitPrice, reason)
			return true
		end
	end
	return false
end
--按分钟计价
function PriceList:MinitesCostCheck(avatar, idx, times, reason)
	local pData  = self:GetPriceData(idx)
	local uPrice = pData.priceList[1]
	if not uPrice then  
		log_game_error("PriceList:MinitesCostCheck", "idx=%d priceList error", idx)
		return false
	end
	if times <= 0 then
		log_game_error("PriceList:DeductMinitesCost", "times=%d error", times)
		return
	end
	local aPrice = uPrice*times 
	if pData.currencyType == public_config.PRICE_GOLD then
		if avatar.gold < aPrice then
			return false
		end
	elseif pData.currencyType == public_config.PRICE_DIAMOND then
		if avatar.diamond < aPrice then
			return false
		end
	end
	return true
end
function PriceList:DeductMinitesCost(avatar, idx, times, reason)
	local pData  = self:GetPriceData(idx)
	local uPrice = pData.priceList[1]
	if not uPrice then  
		log_game_error("PriceList:DeductMinitesCost", "idx=%d priceList error", idx)
		return false
	end
	if times <= 0 then
		log_game_error("PriceList:DeductMinitesCost", "times=%d error", times)
		return
	end
	local aPrice = uPrice*times 
	if pData.currencyType == public_config.PRICE_GOLD then
		if avatar.gold >= aPrice then
			avatar:AddGold(-aPrice, reason)
			return true
		end
	elseif pData.currencyType == public_config.PRICE_DIAMOND then
		if avatar.diamond >= aPrice then
			avatar:AddDiamond(-aPrice, reason)
			return true
		end
	end
	return false
end
g_priceList_mgr = PriceList 
return g_priceList_mgr


