require "lua_util"

local ChargeData = {}
ChargeData.__index = ChargeData

--读取配置数据
function ChargeData:initData()
	--时间是互斥的
    self.diamond_mine = lua_util._readXml('/data/xml/DiamondMine.xml', 'id_i')
    --check
    for _,v in pairs(self.diamond_mine) do
		if #v.cost ~= #v.reward or #v.cost ~= #v.vip_need then
			lua_util.log_game_error('ChargeData:initData', "DiamondMine.xml")
		end
    end
end

function ChargeData:GetMineCfg()
	local t = os.time()
	for id,v in pairs(self.diamond_mine) do
		if t > v.date_open and t < v.date_end then
			return v
		end
	end
	return nil
end

function ChargeData:MineCost(t)
	local cfg = self:GetMineCfg()
	if cfg then
		return cfg.cost[t]
	end
	return nil
end

function ChargeData:MineReward(t)
	local cfg = self:GetMineCfg()
	if cfg then
		return cfg.reward[t]
	end
	return nil
end

function ChargeData:MineVip(t)
	local cfg = self:GetMineCfg()
	if cfg then
		local vip = cfg.vip_need[t]
		if vip then 
			return vip
		else
			--这个是最大所需vip等级
			local m = #cfg.vip_need
			return cfg.vip_need[m]
		end
	end
	return nil
end

--是否领取完最大
function ChargeData:IfMax(t)
	local m = 0
	local cfg = self:GetMineCfg()
	if cfg then
		for k,v in pairs(cfg.cost) do
			if m < k then
				m = k
			end
		end
		return m < t
	end
	return true
end

--是否过期
function ChargeData:IfMineDated()
	local t = os.time()
	for id,v in pairs(self.diamond_mine) do
		if t > v.date_open and t < v.date_end then
			return false
		end
	end
	return true
end

g_charge_data = ChargeData
return g_charge_data