--author:hwj
--date:2014-01-20
--此为Avatar扩展类,充值相关接口,只能由Avatar require使用
--避免Avatar.lua文件过长

require "charge_data"
local globalbase_call   = lua_util.globalbase_call
local log_game_debug    = lua_util.log_game_debug
local log_game_info     = lua_util.log_game_info
local log_game_warning  = lua_util.log_game_warning
local log_game_error    = lua_util.log_game_error
--[[
chargeSum
VipLevel
diamond_mine_info
]]
local txt_id = {
	diamond_mine_dated   = 25580,
	diamond_mine_max     = 25581,
	diamond_mine_cost    = 25582,
	diamond_mine_vip     = 25583,
}

------------------------------------------------------充值相关事件触发接口 begin------------------------------------------------------
--充值成功事件
function Avatar:ChargeSucEvent()
	log_game_info("Avatar:ChargeSucEvent", "dbid=%q,name=%s",self.dbid,self.name)
	--请使用pcall接口来执行相关的触发事件，以免出异常影响到其他事件
	local function func(dbid)
		log_game_debug("lua_util.pcall","Avatar:ChargeSucEvent,%q",dbid)
		return true
	end
	local ret = lua_util.pcall(func, false, self.dbid)
	if not ret then
		log_game_debug("Avatar:ChargeSucEvent", "func dbid=%q",self.dbid)
	end
end

--充值带来的vip等级变更事件
function Avatar:VipLevelChangeEvent()
	log_game_info("Avatar:VipLevelChange", "dbid=%q,name=%s",self.dbid,self.name)
	--请使用pcall接口来执行相关的触发事件，以免出异常影响到其他事件

end

------------------------------------------------------充值相关事件触发接口 end------------------------------------------------------

--钻石充值
function Avatar:ChargeDiamond(rmb, diamond)
    if rmb < 0 or diamond < 0 then
    	log_game_error("Avatar:ChargeDiamond","rmb=%d;diamond=%d",rmb, diamond)
        return false
    end
    local tpSum = self.chargeSum + rmb
    self:AddDiamond(diamond, reason_def.charge)
    self.chargeSum = tpSum

    --local ss = string.format("charge rmb=%s successfully.",rmb)
	--self:ShowText(CHANNEL.DLG,ss)
	if self:hasClient() then
		--触发前端事件
		self.client.OnChargeDiamondResp(diamond)
	end

    self:ChargeSucEvent()
    --vip 等级变更
    local lv = g_vip_mgr:GetVipLevel(tpSum)
    if not lv then
    	log_game_error("Avatar:ChargeDiamond", "vip lv is nil.")
        return false
    end
    log_game_info("Avatar:ChargeDiamond", "chargeSum=%d;vip=%d;rmb=%d;diamond=%d", tpSum, lv, rmb, diamond)
    if self.VipLevel < lv then
        self.VipLevel = lv
        self:VipLevelChangeEvent()
    end
    return true
end

--充值赠送钻石
function Avatar:PresentDiamond(diamond)
    if diamond < 0 then
        return false
    end
    self:AddDiamond(diamond, reason_def.present)
    return true
end

--检查是否有充值
function Avatar:CheckChargeReq()
	local mm = globalBases['ChargeMgr']
	if mm then
		mm.CheckChargeReq(self.base_mbstr,self.accountName,self.dbid)
	end
end

--领取钻石
function Avatar:WithdrawReq(ord_dbid)
	local mm = globalBases['ChargeMgr']
	if mm then
		mm.WithdrawReq(self.base_mbstr,self.accountName,self.dbid,ord_dbid)
	end
end

--领取钻石回调
function Avatar:OnWithdrawResp(rmb,diamond)
    log_game_debug("Avatar:OnWithdrawResp","rmb=%d,diamond = %d",rmb,diamond)
    --self:AddDiamond(diamond,reason_def.charge)
    --todo:触发vip升级，任务，活动等
    self:ChargeDiamond(rmb, diamond)
end
--{avatar_dbid=rec['avatar_dbid'],ord_dbid=newid,create_time=rec['create_time'],diamond=self:Rmb2Diamon(rec.amount),}
function Avatar:OnNotifyCharge(ord_list)
	log_game_debug("Avatar:NotifyCharge","%s",mogo.cPickle(ord_list))
	if self:hasClient() then
		local ords = {}
		for _,v in pairs(ord_list) do
			if v.avatar_dbid == self.dbid then
				--自动领取
				self:WithdrawReq(v.ord_dbid)
			else
				table.insert(ords,v)
			end
		end
		if next(ords) then
			self.client.OnNotifyChargeResp(ords)
		end
	end
end


------------------------------------------------------充值返利 begin----------------------------------------------------
--精灵宝钻
function Avatar:DiamondMineReq()
	local my_info = self.diamond_mine_info
	if g_charge_data:IfMineDated() then
		return self:ShowTextID(CHANNEL.TIPS,txt_id.diamond_mine_dated)
	end
	local ts = my_info.times or 0
	ts = ts + 1
	if g_charge_data:IfMax(ts) then
		return self:ShowTextID(CHANNEL.TIPS,txt_id.diamond_mine_max)
	end
	local cost = g_charge_data:MineCost(ts)
	if cost > self.diamond then
		return self:ShowTextID(CHANNEL.TIPS,txt_id.diamond_mine_cost)
	end
	local vip = g_charge_data:MineVip(ts)
	if vip > self.VipLevel then
		return self:ShowTextID(CHANNEL.TIPS,txt_id.diamond_mine_vip,vip)
	end
	local reward = g_charge_data:MineReward(ts)
	if reward then
		my_info.times = ts
		local sum_cost = my_info.costs or 0
		my_info.costs = sum_cost + cost
		self:AddDiamond(-cost, reason_def.diamond_mine)
		log_game_info("Avatar:DiamondMineReq","cost[%d]",cost)
		local sum_get = my_info.gets or 0
		my_info.gets = sum_get + reward
		self:AddDiamond(reward, reason_def.diamond_mine)
		log_game_info("Avatar:DiamondMineReq","reward[%d]",reward)
		--刷新数据
		self:DiamondMineInfoReq()
	end
end
--精灵宝钻返回
function Avatar:DiamondMineInfoReq()
	if self:hasClient() then
		local my_info = self.diamond_mine_info
		local info = {
			times   = my_info.times or 0,
			sumCost = my_info.costs or 0,
			sumGet  = my_info.gets  or 0,
		}
		local ts = info.times + 1
		info.cost = g_charge_data:MineCost(ts) or 0
		info.get = g_charge_data:MineReward(ts) or 0
		info.vip = g_charge_data:MineVip(ts) or false
		if not info.vip then
			log_game_error('Avatar:DiamondMineInfoReq','something wrong about DiamondMine.xml')
			info.vip = 100 --次数超过最大次数，预防前端出错
		end
		self.client.DiamondMineInfoResp(info)
	end
end
------------------------------------------------------充值返利 end------------------------------------------------------