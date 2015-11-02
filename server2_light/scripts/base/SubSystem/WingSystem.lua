require "lua_util"
require "wing_data"
require "reason_def"
require "error_code"
require "Item_data"
require "event_config"

local log_game_debug     = lua_util.log_game_debug
local log_game_error     = lua_util.log_game_error
local WING_INIT_LEVEL    = public_config.WING_INIT_LEVEL
local WING_INIT_EXP      = public_config.WING_INIT_EXP
local WING_MAGIC_ACTIVED = public_config.WING_MAGIC_ACTIVED
local WING_MAGIC_NOACTED = public_config.WING_MAGIC_NOACTED
local WING_LIMIT_VOC     = public_config.WING_LIMIT_VOC
local WING_LIMIT_VIP     = public_config.WING_LIMIT_VIP
local WING_BODY_INDEX    = public_config.WING_BODY_INDEX
local WING_DATA_INDEX    = public_config.WING_DATA_INDEX

WingSystem = {}
WingSystem.__index = WingSystem

----------------------------------------------------------------------------
function WingSystem:SplitCosts(costs)
	local specItems = {}
	local items     = {}
	for id, count in pairs(costs) do
		if id < public_config.MAX_OTHER_ITEM_ID then
			specItems[id] = count
		else
			items[id] = count
		end
	end
	return specItems, items
end
----------------------------------------------------------------------------
--培养普通翅膀
function WingSystem:TrainWingReq(avatar, id)
	local wingBag = self:GetWingBag(avatar)
	if not wingBag or not wingBag[id] then
		self:TrainOrdinaryWingResp(avatar, error_code.WING_NOT_EXIST)
		return
	end
	wingBag = wingBag[id]
	local level  = wingBag[public_config.WING_DATA_LEVEL]
	local lvData = g_wing_mgr:GetWingLevelCfg(id, level)
	if not lvData then
		self:TrainOrdinaryWingResp(avatar, error_code.WING_CFG_ERROR)
		return
	end
	local upNeedExp = lvData.nextLevelExp or 0
	if upNeedExp <= 0 then
		self:TrainOrdinaryWingResp(avatar, error_code.WING_HAS_CEIL)
		return
	end
	if not self:TrainCostCheck(avatar, lvData) then
		self:TrainOrdinaryWingResp(avatar, error_code.WING_NO_DIAORITEMS)
		return
	end
	local expRate  = self:GetTrainExpRate(avatar, lvData)
	local lvExpAdd = lvData.levelExpAdd or 0
	local hasUp    = false
	local hasExp   = wingBag[public_config.WING_DATA_EXP]
	hasExp = hasExp + expRate*lvExpAdd
	if hasExp >= upNeedExp then
		level = level + 1
		local tpData = g_wing_mgr:GetWingLevelCfg(id, level)
		if tpData then
			if tpData.nextLevelExp == 0 then
				hasExp = upNeedExp
			else
				hasExp = hasExp - upNeedExp
			end
			hasUp = true
		end
	end
	wingBag[public_config.WING_DATA_EXP]   = hasExp
	wingBag[public_config.WING_DATA_LEVEL] = level
	self:TrainOrdinaryWingResp(avatar, error_code.WING_TRAIN_OK)
	self:WingBagSyncClientResp(avatar)
	if hasUp then
		avatar:triggerEvent(event_config.EVENT_AVATAR_PROPERTIES_RECALCULATE)
		self:MagicWingActiveDeal(avatar)
	end
end
function WingSystem:GetTrainExpRate(avatar, lvData)
	local tWeight = lvData.trainWeight
	if not tWeight then
		return 0
	end
	local idx, prop = lua_util.getrandomseed(tWeight)
	local tValue = lvData.trainValue
	if not tValue then
		log_game_error("WingSystem:GetTrainExpRate", "dbid=%q;name=%s", avatar.dbid, avatar.name)
		return 0
	end
	return tValue[idx] or 0
end
function WingSystem:TrainCostCheck(avatar, lvData)
	local items = lvData.trainCost or {}
	if self:HasEnoughItems(avatar, items) then
		for typeId, cnt in pairs(items) do
			avatar:DelItem(typeId, cnt, reason_def.trainWing)
		end
		return true
	end
	local dia = lvData.trainDiamondCost or 0
	if avatar.diamond >= dia then
		avatar:AddDiamond(-dia, reason_def.trainWing)
		return true
	end
	return false
end
function WingSystem:HasEnoughItems(avatar, items)
	local invrySys = avatar.inventorySystem
	for typeId, cnt in pairs(items) do
		if not invrySys:HasEnoughItems(typeId, cnt) then
			return false
		end
	end
	return true
end
function WingSystem:TrainOrdinaryWingResp(avatar, retCode)
	if avatar:hasClient() then
        log_game_debug("WingSystem:TrainOrdinaryWingResp", "dbid=%q;name=%s;retCode=%d", avatar.dbid, avatar.name, retCode)
		avatar.client.TrainOrdinaryWingResp(retCode)
	end
end
function WingSystem:MagicWingActiveDeal(avatar)
	local wingBag = self:GetWingBag(avatar)
	for wId, _ in pairs(wingBag) do
		local wData = g_wing_mgr:GetWingCfg(wId)
		local wType = wData.type or 0
		if wType == public_config.WING_MAGIC_TYPE then
			self:MagicWingActiveReq(avatar, wId)
		end
	end
end
----------------------------------------------------------------------------
--幻化翅膀属性激活
function WingSystem:MagicWingActiveReq(avatar, id)
	local wingBag = self:GetWingBag(avatar)
	if not wingBag or not wingBag[id] then
		self:MagicWingActiveResp(avatar, error_code.WING_ACTIVE_NOWING)
		return
	end
	if self:IsActivedWing(avatar, id) then
		self:MagicWingActiveResp(avatar, error_code.WING_ACTIVE_ACTIVED)
		return
	end
	local wData = g_wing_mgr:GetWingCfg(id)
	if not wData then
		self:MagicWingActiveResp(avatar, error_code.WING_ACTIVE_CFG)
		return
	end
	if not self:ActiveMagicWingCheck(avatar, wData) then
		return
	end
	local activeCosts = wData.activeCost
	if not self:ActiveCostsCheck(avatar, activeCosts) then
		return
	end
	self:CostsAction(avatar, activeCosts, reason_def.activeWing)
	wingBag[id][public_config.WING_DATA_ACT] = WING_MAGIC_ACTIVED
	self:MagicWingActiveResp(avatar, error_code.WING_ACTIVE_SUCCESS)
	self:WingBagSyncClientResp(avatar)
	avatar:triggerEvent(event_config.EVENT_AVATAR_PROPERTIES_RECALCULATE)
end
----------------------------------------------------------------------------
--幻化翅膀激活条件检查
function WingSystem:ActiveMagicWingCheck(avatar, wData)
	local wType = wData.type
	if wType ~= public_config.WING_MAGIC_TYPE then
		self:MagicWingActiveResp(avatar, error_code.WING_ACTIVE_TYPE)
		return false
	end
	local limits = wData.limit
	if not self:ActiveLimitCheck(avatar, limits) then
		return false
	end
	local unlocks = wData.unlock
	if not self:ActiveConditionCheck(avatar, unlocks) then
		return false
	end
	return true
end
function WingSystem:ActiveConditionCheck(avatar, unlocks) 
	if not unlocks then return true end
	local wingBag = self:GetWingBag(avatar)
	for wId, needLevel in pairs(unlocks) do
		local rData = wingBag[wId]
		if not rData or rData[public_config.WING_DATA_LEVEL] < needLevel then
			self:MagicWingActiveResp(avatar, error_code.WING_ACTIVE_LESS)
			return false
		end
	end
	return true
end

function WingSystem:ActiveLimitCheck(avatar, limits)
	if not limits then return true end
	local vVoc   = limits[WING_LIMIT_VOC] or 0
	if vVoc ~= public_config.AVATAR_ALL_VOC and vVoc ~= avatar.vocation then
		self:MagicWingActiveResp(avatar, error_code.WING_ACTIVE_VOC)
		return false
	end
	local vLimit = limits[WING_LIMIT_VIP] or 0
	if vLimit > avatar.VipLevel then
		self:MagicWingActiveResp(avatar, error_code.WING_ACTIVE_VIP)
		return false
	end
	return true
end
function WingSystem:ActiveCostsCheck(avatar, activeCosts)
	if not activeCosts then return true end
	local specItems, items = self:SplitCosts(activeCosts)
	local gold = specItems[public_config.GOLD_ID] or 0
	if avatar.gold < gold then
		self:MagicWingActiveResp(avatar, error_code.WING_ACTIVE_GOLD)
		return false
	end
	local dia = specItems[public_config.DIAMOND_ID] or 0
	if avatar.diamond < dia then
		self:MagicWingActiveResp(avatar, error_code.WING_ACTIVE_DIA)
		return false
	end
	local invrySys = avatar.inventorySystem 
	for typeId, cnt in pairs(items) do
		if not invrySys:HasEnoughItems(typeId, cnt) then
			self:MagicWingActiveResp(avatar, error_code.WING_ACTIVE_ITEM)
			return false
		end
	end
	return true
end
function WingSystem:CostsAction(avatar, costs, reason)
	if not costs then return true end
	local specItems, items = self:SplitCosts(costs)
	local gold = specItems[public_config.GOLD_ID]
	if gold then
		if gold < avatar.gold then
			avatar:AddGold(-gold, reason)
		end
	end
	local dia = specItems[public_config.DIAMOND_ID]
	if dia then
		if dia < avatar.diamond then
			avatar:AddDiamond(-dia, reason)
		end
	end
--	local invrySys = avatar.inventorySystem
	for typeId, cnt in pairs(items) do
		avatar:DelItem(typeId, cnt, reason)
	end
	return true
end
function WingSystem:MagicWingActiveResp(avatar, retCode)
	if avatar:hasClient() then
        log_game_debug("WingSystem:UnlockMagicWingResp", "dbid=%q;name=%s;retCode=%d", avatar.dbid, avatar.name, retCode)
		avatar.client.MagicWingActiveResp(retCode)
	end
end
----------------------------------------------------------------------------
--翅膀属性处理
function WingSystem:DealWingBagProps(wingBag)
    local propertIds = {}
    local wingData = wingBag[WING_DATA_INDEX] or {}
    for wId, item in pairs(wingData) do
        local wLevel = item[public_config.WING_DATA_LEVEL]
        local lvData = g_wing_mgr:GetWingLevelCfg(wId, wLevel)
        local propId = lvData.propertEffectId
        local mark   = item[public_config.WING_DATA_ACT]
        if mark == WING_MAGIC_ACTIVED then
            if propId then
                local hasCnt = propertIds[propId] or 0
                propertIds[propId] = hasCnt + 1
            end
        end
    end
    return propertIds
end
----------------------------------------------------------------------------
--翅膀属性同步前端
function WingSystem:WingBagSyncClientResp(avatar)
	if avatar:hasClient() then
		avatar.client.WingBagSyncClientResp(avatar.wingBag)
	end
end
----------------------------------------------------------------------------
function WingSystem:WingExchangeReq(avatar, id)
	local wingBag = self:GetWingBag(avatar)
	if not wingBag or not wingBag[id] then
		self:WingExchangeResp(avatar, error_code.WING_EXCHANGE_NO)
		return
	end
	local preId = avatar.wingBag[WING_BODY_INDEX]
	if preId == id then
		self:WingExchangeResp(avatar, error_code.WING_EXCHANGE_DONE)
		return
	end
	avatar.wingBag[WING_BODY_INDEX] = id
	self:WingExchangeResp(avatar, error_code.WING_EXCHANGE_OK)
	self:WingBagSyncClientResp(avatar)
	self:SyncWingShowMode(avatar)
end
function WingSystem:IsActivedWing(avatar, id)
	local wingBag = self:GetWingBag(avatar)
	local mark = wingBag[id][public_config.WING_DATA_ACT]
	if mark == WING_MAGIC_ACTIVED then
		return true
	end
	return false
end
function WingSystem:WingExchangeResp(avatar, retCode)
	log_game_debug("WingSystem:WingExchangeResp", "dbid=%q;name=%s;retCode=%d", avatar.dbid, avatar.name, retCode)
	if avatar:hasClient() then
		avatar.client.WingExchangeResp(retCode)
	end
end
function WingSystem:GetWingBag(avatar)
	local wingBag = avatar.wingBag[WING_DATA_INDEX]
	if not wingBag then
		log_game_debug("WingSystem:GetWingBag", "dbid=%q;name=%s wing bag not init!", avatar.dbid, avatar.name)
		return
	end
	return wingBag
end
----------------------------------------------------------------------------
function WingSystem:SyncWingShowMode(avatar)
	local wingId = avatar.wingBag[public_config.WING_BODY_INDEX]
	if wingId > 0 then
		avatar.cell.SyncEquipMode(public_config.BODY_WING, wingId)
	end
end
----------------------------------------------------------------------------
function WingSystem:SyncWingBagReq(avatar)
	self:WingBagSyncClientResp(avatar)
end
----------------------------------------------------------------------------
WingSystem = WingSystem
return WingSystem