require "lua_util"
require "error_code"
require "public_config"
local log_game_debug = lua_util.log_game_debug
local log_game_info  = lua_util.log_game_info
local log_game_error = lua_util.log_game_error
local globalbase_call = lua_util.globalbase_call
-----------------------------------------------------------------------------------
RankListSystem = {}
RankListSystem.__index = RankListSystem
--marco define 
---------------------------------------------------------------------------------
local RANK_LIST_FIGHTFORCE      =  public_config.RANK_LIST_FIGHTFORCE      --角色战力榜
local RANK_LIST_UP_LEVEL        =  public_config.RANK_LIST_UP_LEVEL        --角色等级榜
local RANK_LIST_ARENIC_CREDIT   =  public_config.RANK_LIST_ARENIC_CREDIT   --竞技荣誉榜
local RANK_LIST_ARENIC_SCORE    =  public_config.RANK_LIST_ARENIC_SCORE    --竞技积分榜
local RANK_LIST_SANCTUARY       =  public_config.RANK_LIST_SANCTUARY       --圣域贡献榜
local RANK_LIST_TOWER_CHALLENGE =  public_config.RANK_LIST_TOWER_CHALLENGE --试炼挑战榜
local RANK_LIST_MISSION_SBRAND  =  public_config.RANK_LIST_MISSION_SBRAND  --S达人榜

local RET_SUCCESS               =  error_code.RANK_LIST_REQUIRE_SUCCESS
local RET_FAILURE               =  error_code.RANK_LIST_REQUIRE_FAILURE


----------------------------------------------------------------------------------
--初始化数据
----------------------------------------------------------------------------------
function RankListSystem:initData()
	local rankListData  = lua_util._readXml('/data/xml/RankList.xml', 'id_i')
	local fansData      = lua_util._readXml('/data/xml/FansReward.xml', 'id_i')
	if not rankListData then
		log_game_error("RankListSystem:initData", "RankList.xml configure error!")
		return
	end
	if not fansData then
		log_game_error("RankListSystem:initData", "FansReward.xml configure error!")
		return
	end
	self.RankListData   = rankListData
	self.FansRewardData = fansData
end
----------------------------------------------------------------------------------
--获取排行榜数据项
----------------------------------------------------------------------------------
function RankListSystem:GetRankItem(rankType)
	local rankData = self.RankListData[rankType]
	if not rankData then
		log_game_error("RankListSystem:GetRankItem", "rank type empty or error")
		return false
	end
	return rankData
end
--获取排名最大限制
function RankListSystem:GetRankLimit(rankType)
	local limit = self:GetRankItem(rankType)
	if not limit then
		log_game_error("RankListSystem:GetRankLimit", "rank limit error")
		return 0
	end
	return limit.rankCount
end
--检查是否有奖励
function RankListSystem:IsRewardType(typeIdx)
	local rankData = self:GetRankItem(typeIdx)
	if not rankData then
		return false
	end
	local ifReward = rankData.ifReward
	if not ifReward then
		return false
	end
	return true
end
----------------------------------------------------------------------------------
--获取粉丝奖励数据项
----------------------------------------------------------------------------------
function RankListSystem:RangeCheck(idx, rangeList)
	local minLimit = rangeList[1]
	local maxLimit = rangeList[2]
	if idx >= minLimit and idx <= maxLimit then
		return true
	end
	return false
end

function RankListSystem:GetReward(avatarLevel, rankLevel)
	local fansData = self.FansRewardData
	for _, item in pairs(fansData) do
		local levelRange = item.level
		if not levelRange then
			log_game_error("RankListSystem:GetReward", "fans level range cfg error")
			return {}
		end
		--检查角色的等级范围
		if self:RangeCheck(avatarLevel, levelRange) then
			local rankRang = item.rank
			if not rankRang then
				log_game_error("RankListSystem:GetReward", "fans rank range cfg error")
				return {}
			end
			--检查角色偶像排名范围
			if self:RangeCheck(rankLevel, rankRang) then
				local reward = item.reward
				if not reward then
					return {}
				end
				return reward
			end
		end
	end
end
----------------------------------------------------------------------------------




g_rankList_mgr = RankListSystem

return g_rankList_mgr