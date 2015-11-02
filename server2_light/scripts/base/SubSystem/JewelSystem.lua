
-- 宝石系统
require "JewelData"
require "CommonXmlConfig"
require "public_config"
require "GlobalParams"
require "reason_def"

--local jewelData = g_jewel_mgr.jewelDataList
local log_game_info = lua_util.log_game_info
local log_game_debug = lua_util.log_game_debug
local log_game_error = lua_util.log_game_error
--[[
msgJewelSys = 
{
    MSG_JEWEL_NIFO                = 1,            -- 获取对应ID的宝石所有信息
    MSG_JEWEL_PROP                = 2,            -- 获取对应ID的宝石带来的属性加强信息
    MSG_JEWEL_SKILL               = 3,            -- 获取对应ID的宝石带来的被动技能信息             
    MSG_JEWEL_COMBINE             = 4,            -- 根据背包已有的低一级宝石合成对应类型和等级的宝石
    MSG_JEWEL_COMBINE_ANYWAY      = 5,            -- 根据背包已有的所有宝石外加钻石合成对应类型和等级的宝石
    MSG_JEWEL_COMBINE_MONEY       = 6,            -- 立即合成时检查需要的钻石数量
    MSG_JEWEL_INLAY               = 7,            -- 镶嵌对应ID宝石
    MSG_JEWEL_OUTLAY              = 8,            -- 卸下对应ID宝石
    MSG_JEWEL_SELL                = 9,            -- 根据对应ID宝石的出售价格出售
    MSG_JEWEL_ALL_COMBINE         = 10,           -- 计算所有可以合成的宝石信息
}
]]
local INSTANCE_GRIDINDEX        = public_config.ITEM_INSTANCE_GRIDINDEX  --背包索引
local INSTANCE_TYPEID           = public_config.ITEM_INSTANCE_TYPEID     --道具id
local INSTANCE_ID               = public_config.ITEM_INSTANCE_ID         --实例id
local INSTANCE_BINDTYPE         = public_config.ITEM_INSTANCE_BINDTYPE   --绑定类型
local INSTANCE_COUNT            = public_config.ITEM_INSTANCE_COUNT      --堆叠数量
local INSTANCE_SLOTS            = public_config.ITEM_INSTANCE_SLOTS      --宝石插槽
local INSTANCE_EXTINFO          = public_config.ITEM_INSTANCE_EXTINFO    --扩展信息

JewelSystem = {}
JewelSystem.__index = JewelSystem

local function CalcJewelPrice( lv )
	if not lv or lv < 1 then
		log_game_debug("CalcJewelPrice", "lv = %d", (lv or 0))
		return 0
	end
	if lv == 1 then
		return g_GlobalParamsMgr:GetParams('jewel_price', 20)
	end
	return g_GlobalParamsMgr:GetParams('jewel_level_per', 3) * CalcJewelPrice(lv - 1)
end

function JewelSystem:new( owner )
    local newObj = {}
	setmetatable(newObj, {__index = JewelSystem})
	newObj.ptr = {}
    setmetatable(newObj.ptr, {__mode = "v"})
    newObj.ptr.theOwner = owner
    return newObj
end
--[[
function JewelSystem:Req( msgId, ...)
    log_game_debug("JewelSystem:Req", "msgId = %d", msgId)
    local func = self.msgMapping[msgId]
    if func then
        return func(self, ...)
    else
        log_game_error("JewelSystem:Req", "msgId = %d", msgId)
    end
end
]]
-------------------------------------封装背包的接口begin-------------------------------------------
--从背包里获得所有宝石
function JewelSystem:GetAllJewels( )
	local inventorySystem = self.ptr.theOwner.inventorySystem
	return inventorySystem:GetAllItem(public_config.ITEM_TYPE_JEWEL)
end
--从背包里获取某件物品
function JewelSystem:GetItemByIndex( itemType, itemIndex )
	log_game_debug("JewelSystem:GetItemByIndex", "itemType = %d, itemIndex = %d", itemType, itemIndex)
	local inventorySystem = self.ptr.theOwner.inventorySystem
	local items = inventorySystem:GetAllItem(itemType)
	if not items then
		log_game_debug("JewelSystem:GetItemByIndex", "items is nil")
		return nil
	end
	for k, v in pairs(items) do
		if itemIndex == v[INSTANCE_GRIDINDEX] then
			return v
		end
	end
	return nil
end
--从背包删除宝石
function JewelSystem:DelJewels( typeId, num, reason )
	local avatar = self.ptr.theOwner
	return avatar:DelItem(typeId, num, reason)
end
function JewelSystem:AddJewels( typeId, num, reason )
	local avatar = self.ptr.theOwner
	return avatar:AddItem(typeId, num, reason)
end
--获取背包里的空格子
function JewelSystem:GetEmptyGrid( )
	local inventorySystem = self.ptr.theOwner.inventorySystem
	return inventorySystem:GetGridIndex(public_config.ITEM_TYPE_JEWEL)
end
--判断是否可以装进背包
function JewelSystem:CanIntoBag(typeId, num)
	local inventorySystem = self.ptr.theOwner.inventorySystem
	local isSpaceEnough   = inventorySystem:IsSpaceEnough(typeId, num)
	if  isSpaceEnough then
		return true
	else
		return false
	end
end
--todo
--更新一件背包物品
function JewelSystem:UpdateItemInBag( item, reason )
	--身上的装备
	local inventorySystem = self.ptr.theOwner.inventorySystem
	local itemId  = item[INSTANCE_ID]
	local gridIdx = item[INSTANCE_GRIDINDEX]
	local typeId  = item[INSTANCE_TYPEID]
	local retCode = inventorySystem:DelItemFromBody(itemId, gridIdx, typeId)
	if not retCode then
		log_game_error("JewelSystem:DelForEquip", "failed.")
		return false
	end
	inventorySystem:AddItemToBody( item )
	return true
end
-----------------------------------封装背包的接口end---------------------------------------------

--根据原型id获取宝石信息
function JewelSystem:GetJewInfo( protoId )
    return g_jewel_mgr:GetJewelInfoById(protoId)
end
--根据原型id获取宝石带来的属性加成效果
function JewelSystem:GetJewelProperty( protoId )
    log_game_debug("JewelSystem:GetJewelProperty", "can run.")
    local jewel = self:GetJewInfo(protoId)
    if not jewel then
    	return nil
    end
    return CommonXmlConfig:GetPassivePropertyEffect(jewel.propertyEffectId)
end
--待扩展用:根据原型id获取宝石带来的被动技能效果
function JewelSystem:GetJewSkill( protoId )
    log_game_debug("JewelSystem:GetJewSkill", "can run.")
    local jewel = self:GetJewInfo(protoId)
    if not jewel then
    	return nil
    end
    return CommonXmlConfig:GetPassiveSkillEffect(jewel.skillEfectId)
end
function JewelSystem:CheckCanCombine( jwSubtype, level )
	--从背包里获得所有宝石
	local jewels = self:GetAllJewels()
	local materials = {}
	local num = 0
	local function CheckTheJewels()
		for k, v in pairs(jewels) do 
			local jewel = self:GetJewInfo(v[INSTANCE_TYPEID])
			if jewel and jewel.subtype == jwSubtype and jewel.level == level - 1 then
				table.insert(materials, v)
				num = num + v[INSTANCE_COUNT]
				if num >= g_GlobalParamsMgr:GetParams('jewel_level_per', 3) then
					return materials, true
				end
			end
		end
		return nil, false
	end
	return CheckTheJewels()
end

function JewelSystem:Combine( jwSubtype, level )
	local jwInfo = g_jewel_mgr:GetJewelInfo(jwSubtype, level)
	if not jwInfo then
		return error_code.ERR_JEWEL_NOT_EXISTS
	end
	local owner = self.ptr.theOwner
	local vipLimit = g_vip_mgr:GetVipPrivileges(owner.VipLevel)
	if level > vipLimit['jewelSynthesisMaxLevel'] then
		return error_code.ERR_JEWEL_LEVEL_ALREADY_MAX
	end
	local materials, canCombine = self:CheckCanCombine(jwSubtype, level)
	if canCombine and materials[1][INSTANCE_GRIDINDEX] then 
		--todo:消耗和增加背包里的宝石
		if not self:CanIntoBag(jwInfo.id, 1) then
			return error_code.ERR_JEWEL_NO_EMPTY_GRID
		end
		local typeId   = materials[1][INSTANCE_TYPEID]
		local jewelNum = g_GlobalParamsMgr:GetParams('jewel_level_per', 3) 
		if self:DelJewels(typeId, jewelNum, reason_def.jewel_combine) == 0 then
			local err = self:AddJewels( jwInfo.id, 1, reason_def.jewel_combine )
			if err ~= 0 then
				log_game_error("JewelSystem:Combine", "add failed.")
			end
			--触发合成事件,数据中心统计
			owner:OnJewelCombine(jwInfo.id)
			return error_code.ERR_JEWEL_SUCCEED
		end
		return error_code.ERR_JEWEL_DEL_FAILED
	end
	return error_code.ERR_JEWEL_NOT_ENOUGH_MATERIAL
end

function JewelSystem:CombineInEqui(eqIndex, slotIndex)
	local equi = self:GetItemByIndex(public_config.ITEM_TYPE_AVATAR, eqIndex)
	if not equi then
		return error_code.ERR_JEWEL_EQUI_NOT_EXISTS
	end
	--前端：slotIndex是从0开始的
	local oldProID = equi[INSTANCE_SLOTS][slotIndex + 1]
	if not oldProID then 
		return error_code.ERR_JEWEL_NOT_EXISTS
	end
	local jwOld = self:GetJewInfo(oldProID)
	if not jwOld then
		return error_code.ERR_JEWEL_NOT_EXISTS
	end

	local owner    = self.ptr.theOwner
	local vipLimit = g_vip_mgr:GetVipPrivileges(owner.VipLevel)
	if not vipLimit then
		log_game_error('no vipLimit', '')
	end
	if not vipLimit['jewelSynthesisMaxLevel'] then
		log_game_error('jewelSynthesisMaxLevel not exists.','')
	end
	local jwOldLv = jwOld.level
	if jwOldLv >= vipLimit['jewelSynthesisMaxLevel'] then
		return error_code.ERR_BODY_LEVEL_ALREADY_MAX
	end
	--暂时只用子类型，大类型都为1
	local jwSubtype = jwOld.subtype
	local jwTypeId  = 0
	--从背包里获得所有宝石
	local function CheckTheJewels()
		local jewels = self:GetAllJewels()
		local num    = 0
		for k,v in pairs(jewels) do 
			local jewel = self:GetJewInfo(v[INSTANCE_TYPEID]) 
			if jewel and jewel.subtype == jwSubtype and jewel.level == jwOldLv then
				jwTypeId = v[INSTANCE_TYPEID]
				num = num + v[INSTANCE_COUNT]
				--还有一个材料在装备上
				--log_game_debug("JewelSystem:CombineInEqui", "num = %d", num)
				if num >= g_GlobalParamsMgr:GetParams('jewel_level_per', 3) - 1 then
					return true
				end
			end
		end
		--log_game_debug("JewelSystem:CombineInEqui", "finally num = %d", num)
		return false
	end
	if CheckTheJewels() then
		--还有一个材料在装备上
		local jewelNum = g_GlobalParamsMgr:GetParams('jewel_level_per', 3) - 1
		local err = self:DelJewels(jwTypeId, jewelNum, reason_def.jewel_combine)
		--log_game_debug('JewelSystem:CombineInEqui', 'delete jewel err = %d', err)
		if err ~= 0 then
			return error_code.ERR_JEWEL_DEL_FAILED
		end
		local jwNew = g_jewel_mgr:GetJewelInfo(jwSubtype, jwOldLv + 1)
		equi[INSTANCE_SLOTS][slotIndex + 1] = jwNew.id 
		--update equipment to client
		self:UpdateItemInBag(equi)

		--触发重算avatar属性
		owner:triggerEvent(event_config.EVENT_AVATAR_PROPERTIES_RECALCULATE)
		--触发合成事件,数据中心统计
		owner:OnJewelCombine(jwNew.id)
		return error_code.ERR_JEWEL_SUCCEED
	end
	--log_game_debug('JewelSystem:CombineInEqui', "check jewel failed.")
	return error_code.ERR_JEWEL_NOT_ENOUGH_MATERIAL
end

function JewelSystem:CheckCombineAnywayNeedMoney( jwSubtype, level )
	local materials = {}
	log_game_debug("CheckCombineAnywayNeedMoney", "jwSubtype[%d], level[%d]",jwSubtype, level)
	local function GetTheJewels()
		--从背包里获得所有宝石
		local jewels = self:GetAllJewels() or {}
		for k, v in pairs(jewels) do
			local jewel = self:GetJewInfo(v[INSTANCE_TYPEID]) 
			log_game_debug("CheckCombineAnywayNeedMoney", "v.typeId = %d", v[INSTANCE_TYPEID])
			if jewel and jewel.subtype == jwSubtype and jewel.level < level then
				table.insert(materials, v)
			end
		end
		local function sortFunc( arr1, arr2 )
			local jw1 = self:GetJewInfo(arr1[INSTANCE_TYPEID])
			local jw2 = self:GetJewInfo(arr2[INSTANCE_TYPEID])
			if jw1.level > jw2.level then
				return true
			elseif jw1.level == jw2.level then
				return arr1[INSTANCE_COUNT] < arr2[INSTANCE_COUNT] 
			end
		end
		table.sort( materials, sortFunc )
		--test
		for i, v in pairs(materials) do
			local jewel = self:GetJewInfo(v[INSTANCE_TYPEID])
			log_game_debug("CheckCombineAnywayNeedMoney", "i = %d, level = %d", i, jewel.level)
		end
	end
	GetTheJewels()
	log_game_debug("CheckCombineAnywayNeedMoney", "...level = %d", level)
	local needPrice = CalcJewelPrice(level)
	log_game_debug("CheckCombineAnywayNeedMoney", "...needPrice = %d", needPrice)

	for i, aJewel in pairs(materials) do
		local jw = self:GetJewInfo(aJewel[INSTANCE_TYPEID])
		needPrice = needPrice - aJewel[INSTANCE_COUNT] * CalcJewelPrice(jw.level)
		if needPrice <= 0 then
			break
		end
	end
	if needPrice < 0  then
		needPrice = 0
	end
	return needPrice
end

function JewelSystem:CombineAnyway( jwSubtype, level )
	local jwInfo = g_jewel_mgr:GetJewelInfo(jwSubtype, level)
	if not jwInfo then
		return error_code.ERR_JEWEL_NOT_EXISTS
	end

	local owner = self.ptr.theOwner
	if not self:CanIntoBag(jwInfo.id, 1) then
		return error_code.ERR_JEWEL_NO_EMPTY_GRID
	end
	local vipLimit = g_vip_mgr:GetVipPrivileges(owner.VipLevel)
	if level > vipLimit['jewelSynthesisMaxLevel'] then
		return error_code.ERR_BODY_LEVEL_ALREADY_MAX
	end
	--从背包里获得所有宝石
	local jewels = self:GetAllJewels()
	local materials = {}

	local function GetTheJewels()
		for k, v in pairs(jewels) do
			local jewel = self:GetJewInfo(v[INSTANCE_TYPEID]) 
			if jewel and jewel.subtype == jwSubtype and jewel.level < level then
				table.insert(materials, v)
			end
		end
		local function sortFunc( arr1, arr2 )
			local jw1 = self:GetJewInfo(arr1[INSTANCE_TYPEID])
			local jw2 = self:GetJewInfo(arr2[INSTANCE_TYPEID])
			if jw1.level > jw2.level then
				return true
			elseif jw1.level == jw2.level then
				return arr1[INSTANCE_COUNT] < arr2[INSTANCE_COUNT] 
			end
		end
		table.sort( materials, sortFunc )
	end

	GetTheJewels()

	
	--local leftPrice = 0
	
	local function GetCost( )
		local needPrice = CalcJewelPrice(level)
		local costs     = {}
		for i,aJewel in pairs(materials) do
			local jw  = self:GetJewInfo(aJewel[INSTANCE_TYPEID])
			local val = CalcJewelPrice(jw.level)
			local num = 0
			for i= 1, aJewel[INSTANCE_COUNT] do
				num = i
				needPrice = needPrice - val
				if needPrice <= 0 then
					break
				end
			end
			table.insert(costs, {aJewel[INSTANCE_TYPEID], num} )
			if needPrice <= 0 then
				needPrice = 0
				break
			end
		end
		return needPrice, costs
	end
	local price, jwCost = GetCost()

	if price > 0 and owner.diamond < price then
		return error_code.ERR_JEWEL_NOT_ENOUGH_DIAMOND
	end

	--消耗和增加背包里的宝石
	local costed = {}
	for _,c in pairs(jwCost) do
		if self:DelJewels(c[1], c[2], reason_def.jewel_combine) == 0 then
			table.insert(costed, {c[1], c[2]})
		else
			--roll back
			log_game_error("JewelSystem:Combine", "DelJewels failed.")
			for _,ced in pairs(costed) do
				local jwl = self:GetJewInfo(ced[1])
				--local err = self:AddJewels( jwl.subtype, jwl.level, owner.dbid, self:GetEmptyGrid(), ced[2] )
				self:AddJewels(ced[1], ced[2], reason_def.jewel_roll_back)
				if err ~= 0 then
					log_game_error("JewelSystem:Combine", "add failed.")
				end
			end
			return error_code.ERR_JEWEL_DEL_FAILED
		end
	end
	--add
	--self:AddJewels( jwSubtype, level, owner.dbid, self:GetEmptyGrid(), 1 )
	self:AddJewels( jwInfo.id, 1, reason_def.jewel_combine)
	if price > 0 then
		--owner.diamond = owner.diamond - price
		owner:AddDiamond(-price, reason_def.jewel_combine)
	end
	--触发合成事件,数据中心统计
	owner:OnJewelCombine(jwInfo.id)
	return error_code.ERR_JEWEL_SUCCEED
end

--指定了宝石镶嵌到指定装备上
function JewelSystem:Inlay( eqIndex, jwIndex )
	log_game_debug("JewelSystem:Inlay", "eqIndex[%d], jwIndex[%s]", eqIndex, jwIndex)
	local equiItem = self:GetItemByIndex(public_config.ITEM_TYPE_AVATAR, eqIndex)
	if not equiItem then
		log_game_debug("JewelSystem:Inlay", "equiItem is nil ")
		return error_code.ERR_JEWEL_EQUI_NOT_EXISTS
	end
	--local jewels = self:GetAllJewels()
	--前端：jwIndex是从0开始的
	local jwItem = self:GetItemByIndex(public_config.ITEM_TYPE_JEWEL, jwIndex + 1)
	if not jwItem then
		return error_code.ERR_JEWEL_NOT_EXISTS
	end
	--log_game_debug("JewelSystem:Inlay", "1 .... jwItem.typeId = %d", jwItem[INSTANCE_TYPEID]) 
	local jwInfo = self:GetJewInfo(jwItem[INSTANCE_TYPEID])

	local equiInfo = g_itemdata_mgr:GetItem(public_config.ITEM_TYPE_CFG_TBL, equiItem[INSTANCE_TYPEID])
	--log_game_debug("JewelSystem:Inlay", "2 .... equiItem.typeId = %d", equiItem[INSTANCE_TYPEID])
	if not equiInfo.jewelSlot then
		return error_code.ERR_JEWEL_SLOT_FULL_OR_NOT_MATCH
	end
	for i, aSlot in pairs(equiInfo.jewelSlot) do 
		if not equiItem[INSTANCE_SLOTS][i] and jwInfo.slotType[aSlot] then
			--消耗背包里的宝石
			if self:DelJewels(jwItem[INSTANCE_TYPEID], 1, reason_def.jewel_inlay) == 0 then
				--修改装备插槽上的值
				equiItem[INSTANCE_SLOTS][i] = jwInfo.id
				--todo
				--update data to client
				self:UpdateItemInBag(equiItem)
				--触发重算avatar属性
    			self.ptr.theOwner:triggerEvent(event_config.EVENT_AVATAR_PROPERTIES_RECALCULATE)
				return error_code.ERR_JEWEL_SUCCEED
			end
			return error_code.ERR_JEWEL_DEL_FAILED
		end
	end
	return error_code.ERR_JEWEL_SLOT_FULL_OR_NOT_MATCH
end

function JewelSystem:InlayIntoSlot( eqIndex, slotIndex, jwIndex )
	local equiItem = self:GetItemByIndex(public_config.ITEM_TYPE_AVATAR, eqIndex)
	if not equiItem then
		return error_code.ERR_JEWEL_EQUI_NOT_EXISTS
	end
	--local jewels = self:GetAllJewels()
	--前端：slotIndex是从0开始的
	local jwItem = self:GetItemByIndex(public_config.ITEM_TYPE_JEWEL, jwIndex + 1)
	if not jwItem then
		log_game_error("JewelSystem:InlayIntoSlot", "jwIndex's problem.")
		return error_code.ERR_JEWEL_NOT_EXISTS
	end
	local jwInfo = self:GetJewInfo(jwItem[INSTANCE_TYPEID])
	if not jwInfo then
		log_game_error("JewelSystem:InlayIntoSlot", "jwItem.typeId's problem")
		--宝石原型id非法
		return error_code.ERR_JEWEL_NOT_EXISTS
	end

	local equiInfo = g_itemdata_mgr:GetItem(public_config.ITEM_TYPE_CFG_TBL, equiItem[INSTANCE_TYPEID])
	--装备上第slotIndex + 1个插槽的类型
	local equiSlotType = equiInfo.jewelSlot[slotIndex + 1]

	if not equiSlotType then 
		return error_code.ERR_JEWEL_EQUI_SLOT_NOT_EXISTS
	end
	--检查新的宝石与指定的插槽是否匹配
	if not jwInfo.slotType[equiSlotType] then
		log_game_error("JewelSystem:InlayIntoSlot", "HaveSlot")
		return error_code.ERR_JEWEL_CAN_NOT_INLAY
	end

	--原来的已经被镶嵌的宝石原型id
	local oldPropId = equiItem[INSTANCE_SLOTS][slotIndex + 1] 
	--检查格子
	--if oldPropId and self:GetEmptyGrid() == 0 then
	if oldPropId and not self:CanIntoBag(oldPropId, 1) then
		return error_code.ERR_JEWEL_NO_EMPTY_GRID
	end

	local oldJwInfo = self:GetJewInfo(oldPropId) 
	--
	if oldJwInfo then
		--local err = self:AddJewels( oldJwInfo.subtype, oldJwInfo.level, self.ptr.theOwner.dbid, self:GetEmptyGrid(), 1 )
		local err = self:AddJewels(oldJwInfo.id, 1, reason_def.jewel_inlay)
		if err ~= 0 then
			log_game_error("JewelSystem:InlayIntoSlot", "self:AddJewels err = %d.", err)
			return error_code.ERR_JEWEL_CAN_NOT_OUTLAY
		end
	end
	--
	if self:DelJewels(jwItem[INSTANCE_TYPEID], 1, reason_def.jewel_inlay) ~= 0 then 
		log_game_error("JewelSystem:InlayIntoSlot", "self:DelJewels")
		return error_code.ERR_JEWEL_DEL_FAILED
	end
	equiItem[INSTANCE_SLOTS][slotIndex + 1] = jwInfo.id
	--todo
	--update data to client
	self:UpdateItemInBag(equiItem)
	--触发重算avatar属性
    self.ptr.theOwner:triggerEvent(event_config.EVENT_AVATAR_PROPERTIES_RECALCULATE)
	return error_code.ERR_JEWEL_SUCCEED
end

function JewelSystem:Outlay( eqIndex, slotIndex )
	local equiItem = self:GetItemByIndex(public_config.ITEM_TYPE_AVATAR, eqIndex)
	if not equiItem then
		return error_code.ERR_JEWEL_EQUI_NOT_EXISTS
	end

	local equiInfo = g_itemdata_mgr:GetItem(public_config.ITEM_TYPE_CFG_TBL, equiItem[INSTANCE_TYPEID])
	--装备上第slotIndex + 1个插槽的类型
	--local equiSlotType = equiInfo.jewelSlot[slotIndex + 1]

	if not equiItem[INSTANCE_SLOTS][slotIndex + 1] then  
		return error_code.ERR_JEWEL_SLOT_NO_JEWEL
	end
	--检查背包格子数
	if not self:CanIntoBag(equiItem[INSTANCE_SLOTS][slotIndex + 1], 1) then
		return error_code.ERR_JEWEL_NO_EMPTY_GRID
	end
	local theJwInfo = self:GetJewInfo(equiItem[INSTANCE_SLOTS][slotIndex + 1])
	if not theJwInfo then
		return error_code.ERR_JEWEL_NOT_EXISTS
	end
	--local err = self:AddJewels( theJwInfo.subtype, theJwInfo.level, self.ptr.theOwner.dbid, self:GetEmptyGrid(), 1 )
	local err = self:AddJewels(theJwInfo.id, 1, reason_def.jewel_outlay)
	if err ~= 0 then
		log_game_error("JewelSystem:Outlay", "self:AddJewels err = %d.", err)
		return error_code.ERR_JEWEL_CAN_NOT_OUTLAY
	end
	equiItem[INSTANCE_SLOTS][slotIndex + 1] = nil
	--todo
	--update data to client
	self:UpdateItemInBag(equiItem)
	--触发重算avatar属性
    self.ptr.theOwner:triggerEvent(event_config.EVENT_AVATAR_PROPERTIES_RECALCULATE)
	return error_code.ERR_JEWEL_SUCCEED
end
--[[宝石可以买卖
function JewelSystem:sell( jwIndex, num )
	--前端：slotIndex是从0开始的
	local jwl = self:GetItemByIndex(public_config.ITEM_TYPE_JEWEL, jwIndex + 1)
	if not jwl then
		return error_code.ERR_JEWEL_NOT_EXISTS
	end
	if num > jwl.count then
		return error_code.ERR_JEWEL_NUM_TOO_MUCH
	end
	jewel = self:GetJewInfo(jwl.typeId)
	if not jewel then return end
	if jewel.price <= 0 then
		return error_code.ERR_JEWEL_CAN_NOT_SELL
	end
	local gold = num * jewel.price
	if self.ptr.theOwner.gold + gold > g_GlobalParamsMgr:GetParams('max_gold_limit', 999999) then
		return error_code.ERR_GOLD_LIMIT
	end
	if 0 ~= self:DelJewels(jwl.typeId, num, reason_def.jewel_sell) then
		log_game_error("JewelSystem:InlayIntoSlot", "self:DelJewels")
		return error_code.ERR_JEWEL_DEL_FAILED
	end
	self.ptr.theOwner.gold = self.ptr.theOwner.gold + gold
	return error_code.ERR_JEWEL_SUCCEED
end
]]
function JewelSystem:CheckAllJewelCanComb(  )
	--todo:获取背包所有宝石信息
	--[[
	local items = {}
	local jewels = {}
	local jewel
	local protoId
	local function GetTheJewels()
		for k,v in pairs(items) do
			protoId = v.modelId
			jewel = self:GetJewInfo(protoId)
			if jewel then
				table.insert(jewels, jewel)
			end
		end
		local function sortFunc( arr1, arr2 )
			if arr1.level > arr2.level then
				return true
			else if arr1.level == arr2.level then
				return arr1.subtype > arr2.subtype
			end
			return false
		end
		table.sort( jewels, sortfunc )
	end
	GetTheJewels()

	local canComInfo = {}
	local l = 0
	local t = 0
	local n = 0
	for i,v in pairs(jewels) do
		if l ~= v.level or t ~= v.subtype then
			l = v.level
			t = v.subtype
			n = 0
		else 
			n = n + 1
			if n >= public_config.JEWEL_LEVEL_PER then
				canComInfo[t] = {[l] = 1} 
			end
		end
	end
	return canComInfo
	]]
end
 
return JewelSystem