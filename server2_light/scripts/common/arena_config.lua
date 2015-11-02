local log_game_info = lua_util.log_game_info
local log_game_debug = lua_util.log_game_debug
local log_game_error = lua_util.log_game_error
local log_game_warning = lua_util.log_game_warning

arenicDataKey = 
{
    -->begin:arenaSystem m_systemData 的key
    tmp_scoresOfDay = 1,
    tmp_rewardOfDay  = 2,
    tmp_scoresOfWeek = 3,
    tmp_rewardOfWeek = 4,
    tmp_challengeTimes = 5,
    tmp_weakFoes = 6,
    --tmp_theWeakFoe = 7,
    tmp_strongFoes = 8,
    --tmp_theStrongFoe = 9,
    tmp_theEnemy = 10,
    tmp_beatEnemy = 11,
    tmp_weakFoesRange = 12,
    tmp_strongFoesRange = 13,
    tmp_dayLevel = 14,
    tmp_weekLevel = 15,
    --<end


    -->begin: avatar arenicData 的key
    avatar_cdEndTime = 1,
    avatar_buyTimes = 2,
    --avatar_bufAtk = 3,
    --avatar_bufHp = 4,
    avatar_weak = 5,
    avatar_strong = 6,
    avatar_inspire_buf = 7,
    avatar_weakRange = 8,
    avatar_strongRange = 9,
    avatar_DailyBuys = 10, --当天购买次数
    avatar_DailyBuyCd = 11, --下次清购买次数cd
    --<end
}

arena_text_id = 
{
	NO_MONEY = 25000,
	CLEAR_CD_NO_NEED = 25001,
	CLEAR_CD_SUC = 25002,
	BUY_ARENA_TIME_SUC = 25003,
	SCORS_REWARD_RECV_ED = 25004,
	SCORS_REWARD_RECV_SUC = 25005,

	ENEMY_BEATED = 25006,
	NO_ENEMY     = 25007,

	--挑战
	CHALLENGE_CDING = 25017,
	NO_ENTER_TIMES = 25018,
    NO_WEAK_FOE = 25019,
    NO_STRONG_FOE = 25020,
    MAP_CHANGE_FAILED = 25021,
    NEED_LEVEL = 25022,
    NO_DIAMOND = 25023,

    --
    SCORS_REWARD_RECV_LV = 25024,
    SCORS_REWARD_RECV_DAY = 25025,
    SCORS_REWARD_RECV_WEEK = 25026,

    --
    REWARDS_TITLE_WIN = 25030,
    REWARDS_TEXT_WIN = 25031,
    REWARDS_TITLE_LOSS = 25032,
    REWARDS_TEXT_LOSS = 25033,

    REFRESH_SUC = 25035,

    --复仇鼓舞
    INSPIRE_SUC = 25037, --鼓舞成功
    INSPIRE_ED  = 25038, --已经鼓舞过了

    VIP_BUY_FULL = 25039, --已达最大购买次数
}

--------------------------------- 配置 -----------------------------------------
--默认配置
local arena_config_default =
{
	--INIT_NUM = 1000,
	OPEN_LV = 20,
	CHALLENGE_CD = 300, 

	CHALLENGE_TIME_PER_DAY = 15,

	WEAK_FOE_PICK_PARAM = {90,50,50,10},
	STRONG_FOE_PICK_PARAM = {150,90,90,50,50,10},
	ENEMY_PICK_PARAM = {150,50},
	FOES_NUM_FOR_RAND = 15,

	BUF_ATK_PER = 10,
	BUF_HP_PER = 10,

	CLEAR_CD_PRICE_ID = 5,
	REFRESH_WEAK_PRICE_ID = 6,
	REFRESH_STRONG_PRICE_ID = 7,
	BUY_ARENA_TIME_PRICE_ID = 8,
	BUF_PRICE_ID = 9,
	INSPIRE_BUF_ID = 41,
	--BUF_PRICE_PER = {[2] = 200,},
	--REFRESH_WEAK_PRICE = {[2] = 200,},
	--REFRESH_STRONG_PRICE = {[2] = 200,},
}
setmetatable(arena_config_default, {__index = function(t,k) return nil end})

--xml配置，会覆盖掉默认配置
local arena_config = {}
setmetatable(arena_config, {__index=arena_config_default})

function arena_config:initData()
	local tmp = lua_util._readXml('/data/xml/ArenaConfig.xml', 'key')
    --setmetatable(self.wb_config, {__index = function(t, k) return nil end})

    local function less(a, b)
    	return a < b
    end 
    --local result = {}
    for key, value in pairs(tmp) do
    	if value['value'] then
	    	local k, v = lua_util.format_key_value(key, value['value'])
	    	--配置检查，或者特殊处理
	    	if k == 'WEAK_FOE_PICK_PARAM' then
	    		--弱对手选择配置检查
	    		if #v ~= 2 and #v ~= 4 then
	    			lua_util.log_game_error("arena_config:initData", "ArenaConfig.xml [WEAK_FOE_PICK_PARAM]")
	    			return false
	    		end
	    	elseif k == 'STRONG_FOE_PICK_PARAM' then
	    		if #v ~= 6 then
	    			lua_util.log_game_error("arena_config:initData", "ArenaConfig.xml [STRONG_FOE_PICK_PARAM]")
	    			return false
	    		end
	    	elseif k == 'ENEMY_PICK_PARAM' then
	    		if #v ~= 2 then
	    			lua_util.log_game_error("arena_config:initData", "ArenaConfig.xml [ENEMY_PICK_PARAM]")
	    			return false
	    		end
	    	end

	    	--result[k] = v
	    	self[k] = v
    	end
    end
    --lua_util.log_game_debug("arena_config:initData", "arena_config=%s", mogo.cPickle(result))


    self.m_scoreRewards = lua_util._readXml('/data/xml/ArenaScoreReward.xml', 'id_i')

    self.m_creditRewards4Challenge = lua_util._readXml('/data/xml/ArenaCreditReward4Challenge.xml', 'id_i')
    self.m_typeAndlevel2CreditRewards = {}
    for id,v in pairs(self.m_creditRewards4Challenge) do
    	local t = v.type
    	if not self.m_typeAndlevel2CreditRewards[t] then
    		self.m_typeAndlevel2CreditRewards[t] = {}
    	end

    	local l = v.level
    	if #l ~= 2 then
    		log_game_error("arena_config:initData", "ArenaCreditReward4Challenge.xml id (=%d)", id)
    		return
    	end
    	if l[1] > l[2] then
    		log_game_error("arena_config:initData", "ArenaCreditReward4Challenge.xml id (=%d)", id)
    		return
    	end    	
    	local tbl = 
    	{
	    	[1] = l[1],
	    	[2] = id,	
	    }
	    table.insert( self.m_typeAndlevel2CreditRewards[t], tbl )
	    v.level = nil
    	v.type = nil
    	v.id = nil
    end

    local function gt(a, b)
    	return a[1] > b[1]
    end
    for t, v in pairs(self.m_typeAndlevel2CreditRewards) do
    	table.sort( v, gt )
    end

    self.m_itemRewards4Challenge = lua_util._readXml('/data/xml/ArenaItemReward4Challenge.xml', 'id_i')
    self.m_level2itemRewards = {}
    for id, v in pairs(self.m_itemRewards4Challenge) do
    	local l = v.level
    	if #l ~= 2 then
    		log_game_error("arena_config:initData", "ArenaCreditReward4Challenge.xml id (=%d)", id)
    		return
    	end
    	if l[1] > l[2] then
    		log_game_error("arena_config:initData", "ArenaCreditReward4Challenge.xml id (=%d)", id)
    		return
    	end
    	local tbl = 
    	{
	    	[1] = l[1],
	    	[2] = id,	
	    }
    	table.insert( self.m_level2itemRewards, tbl )
    end
    table.sort(self.m_level2itemRewards, gt)
end

function arena_config:GetScoreRewardCfg(idx)
	return self.m_scoreRewards[idx]
end

function arena_config:GetAllScoreRewardCfg()
	return self.m_scoreRewards
end

function arena_config:GetScoreCfgByLv(ty, level)
	local t = {}
	for k,v in pairs(self.m_scoreRewards) do
		if level <= v.level[2] and level >= v.level[1] and v.type == ty then
			t[k] = v
		end
	end
	return t
end

function arena_config:GetScoreLvCfg(level)
	local t = {}
	for k,v in pairs(self.m_scoreRewards) do
		if level <= v.level[2] and level >= v.level[1] then
			t[k] = v
		end
	end
	return t
end

function arena_config:GetChallengeReward(pvpType, grade, level, win)
	local rr = {}
	local theCreditReward = self.m_typeAndlevel2CreditRewards[pvpType]
	if not theCreditReward then
		log_game_error("arena_config:GetChallengeReward", "pvpType (=%d)", pvpType)
		return
	end
	local id = 0
	for _,v in ipairs(theCreditReward) do
		if grade >= v[1] then
			id = v[2]
			break
		end
	end
	local credit = self.m_creditRewards4Challenge[id]
	if credit then
		if win == 1 then
			for k,v in pairs(credit.win) do
				rr[k] = v
			end
		else
			for k,v in pairs(credit.los) do
				rr[k] = v
			end
		end
	else
		log_game_debug("arena_config:GetChallengeReward", "no credit pvpType (=%d)", pvpType)
	end
	id = 0 
	for _,v in ipairs(self.m_level2itemRewards) do
		if level >= v[1] then
			id = v[2]
			break
		end
	end
	local items = self.m_itemRewards4Challenge[id]
	if items then
		if win == 1 then
			for k,v in pairs(items.itemsWin) do
				rr[k] = v
			end
		else
			for k,v in pairs(items.itemsLos) do
				rr[k] = v
			end
		end
	else
		log_game_debug("arena_config:GetChallengeReward", "no items level (=%d)", level)
	end
	return rr
end

g_arena_config = arena_config

return g_arena_config