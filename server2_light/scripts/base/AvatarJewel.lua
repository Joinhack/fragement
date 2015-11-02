--author:hwj
--date:2013-4-23
--此为Avatar扩展类,只能由Avatar require使用
--避免Avatar.lua文件过长

local log_game_debug = lua_util.log_game_debug
-->宝石子系统begin
--[[
function Avatar:JewelAddReq( jwSubtype, jwLevel )
	local jewels = self.jewelSystem:Add(jwSubtype, jwLevel)
	self.client.JewelAddResp(jewels)	
end

function Avatar:JewelAddEquiReq( propID )
	self.jewelSystem:AddEqui(propID)
end
]]
function Avatar:JewelCombineReq( jwSubtype, jwLevel )
	local err = self.jewelSystem:Combine(jwSubtype, jwLevel)
	self.client.JewelCombineResp(jwSubtype, jwLevel, err)	
end  

function Avatar:JewelCombineInEquiReq( eqIndex, slotIndex )
	local err = self.jewelSystem:CombineInEqui(eqIndex, slotIndex)
	self.client.JewelCombineInEquiResp(err)
end

function Avatar:JewelCombineAnywayMoneyReq( jwSubtype, jwLevel )
	local diamond = self.jewelSystem:CheckCombineAnywayNeedMoney(jwSubtype, jwLevel)
	self.client.JewelCombineAnywayMoneyResp(diamond)	
end 

function Avatar:JewelCombineAnywayReq( jwSubtype, jwLevel )
	local err = self.jewelSystem:CombineAnyway(jwSubtype, jwLevel)
	self.client.JewelCombineAnywayResp(err)	
end 

function Avatar:JewelInlayIntoSlotReq( eqIndex, slotIndex, jwIndex )
	local err = self.jewelSystem:InlayIntoSlot(eqIndex, slotIndex, jwIndex)
	self.client.JewelInlayIntoSlotResp(err)
end    

function Avatar:JewelInlayReq( eqIndex, jwIndex )
	local err = self.jewelSystem:Inlay(eqIndex, jwIndex)
	self.client.JewelInlayResp(err)	
end  

function Avatar:JewelOutlayReq( eqIndex, slotIndex )
	local err = self.jewelSystem:Outlay(eqIndex, slotIndex)
	self.client.JewelOutlayResp(err)		
end

--[[
function Avatar:JewelSell( jwIndex, num )
	local err = self.jewelSystem:Sell(jwIndex)
	self.client.JewelSellResp(err)	
end
]]
--<宝石子系统end