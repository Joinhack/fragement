require "lua_util"

local RouletteData = {}
RouletteData.__index = RouletteData

--读取配置数据
function RouletteData:initData()
	--时间是互斥的
    self.roulette = lua_util._readXml('/data/xml/Roulette.xml', 'id_i')
    --check
    self.roulette_reward = {}
    self.all_rewards = lua_util._readXml('/data/xml/RouletteReward.xml', 'id_i')
    for _,v in pairs(self.all_rewards) do
    	local roul_id = v.roulette
    	if not self.roulette_reward[roul_id] then
    		self.roulette_reward[roul_id] = {}
    	end
    	table.insert(self.roulette_reward[roul_id],v)
    end

end

function RouletteData:GetRouletteCfg(roule_id)
	return self.roulette[roule_id]
end

function RouletteData:GetRouletteRewards(roule_id)
	return self.roulette_reward[roule_id]
end

function RouletteData:GetRewardCfg(rew_id)
	return self.all_rewards[rew_id]
end

g_roulette_data = RouletteData
return g_roulette_data