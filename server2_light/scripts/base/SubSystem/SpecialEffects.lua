require "lua_util"
require "reason_def"
require "error_code"
require "special_effects_data"
require "public_config"

local log_game_debug     = lua_util.log_game_debug
local log_game_error     = lua_util.log_game_error

SpecialEffectsSystem = {}
SpecialEffectsSystem.__index = SpecialEffectsSystem

local GROUP_JEWEL_INDEX = 1
local GROUP_EQUIP_INDEX = 2
local GROUP_STRGE_INDEX = 3
local SEPCIAL_ACTIVE_OK = 1

function SpecialEffectsSystem:ActiveSepciaclEffectsReq(avatar, id)
	log_game_debug("SpecialEffectsSystem:ActiveSepciaclEffectsReq", "dbid=%q;name=%s;id=%d", avatar.dbid, avatar.name, id)
	local specBag = avatar.specEffects[id]
	if specBag then
		self:ActiveSepciaclEffectsResp(avatar, id, error_code.ERR_SPECIAL_EFFECTS_HAS)
		return
	end
	local specData = g_spec_mgr:GetCfgData(id)
	if not specData then
		log_game_error("SpecialEffectsSystem:ActiveSepciaclEffectsReq", "dbid=%q;name=%s;id=%d not cfg item!", avatar.dbid, avatar.name, id)
		self:ActiveSepciaclEffectsResp(avatar, id, error_code.ERR_SPECIAL_EFFECTS_CFG)
		return
	end
	local grpId = specData.group or 0
	if GROUP_JEWEL_INDEX == grpId then
		if not self:IsInlayJewelScoreOk(avatar, specData) then
			self:ActiveSepciaclEffectsResp(avatar, id, error_code.ERR_SPECIAL_EFFECTS_JEWEL_LESS)
			return
		end
	elseif GROUP_EQUIP_INDEX == grpId then
		if not self:IsAdvancedEquipScoreOk(avatar, specData) then
			self:ActiveSepciaclEffectsResp(avatar, id, error_code.ERR_SPECIAL_EFFECTS_EQUIP_LESS)
			return
		end
	elseif GROUP_STRGE_INDEX == grpId then
		if not self:IsStrangeScoreOk(avatar, specData) then
			self:ActiveSepciaclEffectsResp(avatar, id, error_code.ERR_SPECIAL_EFFECTS_STRGE_LESS)
			return
		end
	else
		self:ActiveSepciaclEffectsResp(avatar, id, error_code.ERR_SPECIAL_EFFECTS_GROUPID)
		return
	end
	avatar.specEffects[id] = SEPCIAL_ACTIVE_OK
	self:ActiveSepciaclEffectsResp(avatar, id, error_code.ERR_SPECIAL_EFFECTS_OK)
	self:SyncSepcialEffectsResp(avatar)
	self:SyncSpecialEffectsMode(avatar)
end
function SpecialEffectsSystem:IsStrangeScoreOk(avatar, specData)
	local strangeBody = avatar.body
	local allScores = 0
	local scoreList = specData.scoreList or {}
	for _, level in pairs(strangeBody) do
		local score = scoreList[level] or 0
		allScores = allScores + score
	end
	local actScore = specData.activeScore or 0
	if allScores < actScore then
		return false
	end
	return true
end
function SpecialEffectsSystem:IsInlayJewelScoreOk(avatar, specData)
	local equipeds = avatar.equipeds
	local allScores = 0
	local scoreList = specData.scoreList or {}
	for _, item in pairs(equipeds) do
		local slots = item[public_config.ITEM_INSTANCE_SLOTS]
		for _, typeId in pairs(slots) do
			local itemData = self:GetItemData(avatar, typeId)
			if itemData then
				local lv = itemData.level
				local actScore = scoreList[lv] or 0
				allScores = allScores + actScore
			end
		end
	end
	local actScore = specData.activeScore or 0
	if allScores < actScore then
		return false
	end
	return true
end
function SpecialEffectsSystem:IsAdvancedEquipScoreOk(avatar, specData)
	local equipeds = avatar.equipeds
	local allScores = 0
	local scoreList = specData.scoreList or {}
	for _, item in pairs(equipeds) do
		local typeId = item[public_config.ITEM_INSTANCE_TYPEID]
		local itemData = self:GetItemData(avatar, typeId)
		if itemData then
			local quality = itemData.quality
			local actScore = scoreList[quality] or 0
			allScores = allScores + actScore
		end
	end
	local actScore = specData.activeScore or 0
	if allScores < actScore then
		return false
	end
	return true
end
function SpecialEffectsSystem:GetItemData(avatar, typeId)
	local invrySys = avatar.inventorySystem
	local itemData = invrySys:GetItemData(typeId)
	return itemData
end
function SpecialEffectsSystem:ActiveSepciaclEffectsResp(avatar, id, retCode)
	log_game_debug("SpecialEffectsSystem:ActiveSepciaclEffectsResp", "dbid=%q;name=%s;retCode=%d;specBag=%s", 
		avatar.dbid, avatar.name, retCode, mogo.cPickle(avatar.specEffects))
	if avatar:hasClient() then
		avatar.client.ActiveSepciaclEffectsResp(id, retCode)
	end
end
function SpecialEffectsSystem:SyncSepcialEffectsResp(avatar)
	if avatar:hasClient() then
		avatar.client.SyncSepcialEffectsResp(avatar.specEffects)
	end
end
function SpecialEffectsSystem:SyncSpecialEffectsMode(avatar)
	local specBag = avatar.specEffects or {}
	local maxLvs  = {}
	maxLvs[public_config.SPEC_JEWEL_IDNEX] = 0
	maxLvs[public_config.SPEC_EQUIP_IDNEX] = 0
	maxLvs[public_config.SPEC_STRGE_IDNEX] = 0
	local specIds = {}
	for sId, _ in pairs(specBag) do
		local cfgData = g_spec_mgr:GetCfgData(sId)
		local nLevel  = cfgData.level or 0
		local nGrpId  = cfgData.group or 0
		if maxLvs[nGrpId] then
			if maxLvs[nGrpId] < nLevel then
				maxLvs[nGrpId]  = nLevel
				specIds[nGrpId] = sId
			end
		end
	end
	for gId, sId in pairs(specIds) do
		if gId == public_config.SPEC_JEWEL_IDNEX then
			avatar.cell.SyncEquipMode(public_config.BODY_SPEC_JEWEL, sId)
		elseif gId == public_config.SPEC_EQUIP_IDNEX then
			avatar.cell.SyncEquipMode(public_config.BODY_SPEC_EQUIP, sId)
		elseif gId == public_config.SPEC_STRGE_IDNEX then
			avatar.cell.SyncEquipMode(public_config.BODY_SPEC_STRGE, sId)
		end
	end
end

return SpecialEffectsSystem
