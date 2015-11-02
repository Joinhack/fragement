require "lua_util"
local log_game_debug = lua_util.log_game_debug

local SDDataMgr = {}
SDDataMgr.__index = SDDataMgr

local reward_type = 
{
	day_rank = 1,
	week_rank = 2,
	week_contribution = 3,
}
--读取配置数据(cell)
function SDDataMgr:initCellData()
	self.lv2factors = {}
	local tmp_factor = lua_util._readXml("/data/xml/SanctuaryDefenseLevelToFactor.xml", "id_i")
	for id, factors in pairs(tmp_factor) do
		self.lv2factors[factors.level] = factors
		--节约缓存
		factors.level = nil
		factors.id = nil
		if factors.id then factors.id = nil end
	end
end
--读取配置数据
function SDDataMgr:initData()
	self.dayRankReward = {}
	self.weekRankReward = {}
	self.weekContributionReward = {}
	self.lv2factors = {}
	local tmp_reward = lua_util._readXml("/data/xml/Reward_SanctuaryDefense.xml", "id_i")
	for id, reward in pairs(tmp_reward) do
		if reward.type == reward_type.day_rank then
			local rk = reward.rank
			if not rk or self.dayRankReward[rk] then
				lua_util.log_game_error("SDDataMgr:initData", "type[1] rank[%s]", tostring(rk) )
			end

			if reward.contribution then reward.contribution = nil end
			if reward.id then
				--lua_util.log_game_debug("SDDataMgr:initData", "have id.")
				reward.id = nil
			end
			reward.type = nil

			self.dayRankReward[reward.rank] = reward
			reward.rank = nil
		elseif reward.type == reward_type.week_rank then
			local rk = reward.rank
			if not rk or self.weekRankReward[rk] then
				lua_util.log_game_error("SDDataMgr:initData", "type[2] rank[%s]", tostring(rk) )
			end

			if reward.contribution then reward.contribution = nil end
			if reward.id then reward.id = nil end
			reward.type = nil

			self.weekRankReward[reward.rank] = reward
			reward.rank = nil
		elseif reward.type == reward_type.week_contribution then
			local cn = reward.contribution
			if not cn then
				lua_util.log_game_error("SDDataMgr:initData", "type[3] " )
				return
			end
			self.weekContributionReward[reward.id] = reward
			reward.type = nil
			if reward.rank then reward.rank = nil end
			--if reward.id then reward.id = nil end

			--table.insert(self.weekContributionReward, reward)
		else
			lua_util.log_game_error("SDDataMgr:initData", "illegal type[%d]", reward.type)
		end
	end
	local function less(a, b)
		return a.contribution < b.contribution
	end
	--table.sort(self.weekContributionReward, less)

	local tmp_factor = lua_util._readXml("/data/xml/SanctuaryDefenseLevelToFactor.xml", "id_i")
	for id, factors in pairs(tmp_factor) do
		self.lv2factors[factors.level] = factors
		--节约缓存
		factors.level = nil
		factors.id = nil
		if factors.id then factors.id = nil end
	end

	self.buyTimesPrice = lua_util._readXml("/data/xml/SanctuaryDefenseEnterTimesPrice.xml", "count_i")
end

function SDDataMgr:GetDayRankReward(rank)
	return self.dayRankReward[rank]
end

function SDDataMgr:GetWeekRankReward(rank)
	return self.weekRankReward[rank]
end
--[[
function SDDataMgr:GetWeekContributionReward(weekContri, lv)
	log_game_debug("SDDataMgr:GetWeekContributionReward", "weekContri = %s, lv = %s", tostring(weekContri), tostring(lv) )
	local tm = {}
	local max = #self.weekContributionReward
	log_game_debug("SDDataMgr:GetWeekContributionReward", "max = %d", max)
	if lv >= max then return end
	local lv_up = lv
	for i=(lv + 1), max do
		local v = self.weekContributionReward[i]
		if v and v.contribution <= weekContri then
			table.insert(tm, v)
			lv_up = i
		else
			--因为带顺序的表
			break
		end
	end
	return tm, lv_up
end
]]
function SDDataMgr:GetWeekContributionReward(id)
	return self.weekContributionReward[id]
end

--获取该级奖励需要的贡献
function SDDataMgr:GetWeekContributionByLv(lv)
	local ret = {}
	for _,v in pairs(self.weekContributionReward) do
		if v.level[1] <= lv and v.level[2] >= lv then
			table.insert(ret,v)
		end
	end
	return ret
end

--(cell) and base
function SDDataMgr:GetFactors(level)
	return self.lv2factors[level]
end

function SDDataMgr:GetBuyEnterPrice(times)
	return self.buyTimesPrice[times]
end

g_sanctuary_defense_mgr = SDDataMgr
return g_sanctuary_defense_mgr