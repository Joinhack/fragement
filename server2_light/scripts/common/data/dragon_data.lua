require "lua_util"
require "avatar_level_data"
-----------------------------------------------------------------------------------
local log_game_info   = lua_util.log_game_info
local log_game_debug  = lua_util.log_game_debug
local log_game_error  = lua_util.log_game_error
local globalbase_call = lua_util.globalbase_call
-----------------------------------------------------------------------------------
local DRAGON_BASE    = public_config.DRAGON_BASE
local DRAGON_QUALITY = public_config.DRAGON_QUALITY
local DRAGON_REWARDS = public_config.DRAGON_REWARDS
local DRAGON_STATION = public_config.DRAGON_STATION
local DRAGON_EVENTS  = public_config.DRAGON_EVENTS
-----------------------------------------------------------------------------------
local DragonData = {}
DragonData.__index = DragonData
-----------------------------------------------------------------------------------
--加载飞龙系统配置数据
-----------------------------------------------------------------------------------
function DragonData:initData()
	local DragonBase    = lua_util._readXml('/data/xml/DragonBase.xml',    'id_i')
    local DragonQuality = lua_util._readXml('/data/xml/DragonQuality.xml', 'id_i')
    local DragonRewards = lua_util._readXml('/data/xml/DragonRewards.xml', 'id_i')
    local DragonStation = lua_util._readXml('/data/xml/DragonStation.xml', 'id_i')
    local DragonEvents  = lua_util._readXml('/data/xml/DragonEvents.xml',  'id_i')
    if not DragonBase then
    	log_game_error("DragonData:initData", "DragonBase.xml configure error")
    	return
    end
    if not DragonQuality then
    	log_game_error("DragonData:initData", "DragonQuality.xml configure error")
    	return
    end
    if not DragonRewards then
    	log_game_error("DragonData:initData", "DragonRewards.xml configure error")
    	return
    end
    if not DragonStation then
    	log_game_error("DragonData:initData", "DragonStation.xml configure error")
    	return
    end
    if not DragonEvents then
    	log_game_error("DragonData:initData", "DragonEvents.xml configure error")
    	return
    end
    local DragonData = {}
    DragonData[DRAGON_BASE]    = DragonBase
    DragonData[DRAGON_QUALITY] = DragonQuality
    DragonData[DRAGON_REWARDS] = DragonRewards
    DragonData[DRAGON_STATION] = DragonStation
    DragonData[DRAGON_EVENTS]  = DragonEvents
    self.DragonData  = DragonData
    return
end
------------------------------------------------------------------------------------------
--获取配置数据项
------------------------------------------------------------------------------------------
function DragonData:GetDragonItem(type, idx)
	local typeData = self:GetDragonData(type)
	if typeData then
		local itmeData = typeData[idx]
		if not itmeData then
			log_game_error("DragonData:GetDragonItem", "type=%d index=%d error or data nil", type, idx)
			return 
		end
		return itmeData
	end
end
function DragonData:GetDragonData(type)
	local typeData = self.DragonData[type]
	if not typeData then
		log_game_error("DragonData:GetDragonData", "type=%d error or cfg nil", type)
		return
	end
	return typeData
end
------------------------------------------------------------------------------------------
--获取护送时间
------------------------------------------------------------------------------------------
function DragonData:GetConvoyTime(quality, curRng)
	if quality < 2 or curRng <= 0 then return 0 end
	local typeData = self:GetDragonData(DRAGON_QUALITY)
	if not typeData then
		log_game_error("DragonData:GetConvoyTime", "quality=%d error or cfg nil", quality)
		return 0
	end
	for _, dgn in pairs(typeData) do
		if dgn.quality == quality then
			local cmpTimes = dgn.convoyCompleteTime
			if not cmpTimes then
				log_game_error("DragonData:GetConvoyTime", "quality=%d [convoyCompleteTime] cfg nil", quality)
				return 0
			end
			local compTime = cmpTimes[curRng]
			if not compTime then
				log_game_error("DragonData:GetConvoyTime", "quality=%d;curRng=%d cfg nil", quality, curRng)
				return 0
			end
			return compTime
		end
	end
	log_game_error("DragonData:GetConvoyTime", "quality=%d error", quality)
	return 0
end
------------------------------------------------------------------------------------------
--获取每日护送次数
------------------------------------------------------------------------------------------
function DragonData:GetDailyConvoyTimes()
	local typeItem = self:GetDragonItem(DRAGON_BASE, 1)
	if not typeItem then
		return 0
	end
	local dyCvyTimes = typeItem.dailyConvoyTimes
	if not dyCvyTimes then
		log_game_error("DragonData:GetDailyConvoyTimes", "dailyConvoyTimes cfg nil")
		return 0
	end
	return dyCvyTimes
end
------------------------------------------------------------------------------------------
--获取每日袭击次数
------------------------------------------------------------------------------------------
function DragonData:GetDailyAttackTimes()
	local typeItem = self:GetDragonItem(DRAGON_BASE, 1)
	if not typeItem then
		return 0
	end
	local dyAtkTimes = typeItem.dailyAttackTimes
	if not dyAtkTimes then
		log_game_error("DragonData:GetDailyAttackTimes", "dailyAttackTimes cfg nil")
		return 0
	end 
	return dyAtkTimes
end
function DragonData:GetLevelLimit()
	local typeItem = self:GetDragonItem(DRAGON_BASE, 1)
	if not typeItem then
		return 0
	end
	local levelNeed = typeItem.levelNeed
	if not levelNeed then
		log_game_error("DragonData:GetLevelLimit", "levelNeed cfg nil")
		return 0
	end
	return levelNeed
end
------------------------------------------------------------------------------------------
--获取每日护送被袭击次数
------------------------------------------------------------------------------------------
function DragonData:GetConvoyAttackedTimes()
	local typeItem = self:GetDragonItem(DRAGON_BASE, 1)
	if not typeItem then
		return 0
	end
	local cvyAtkedTimes = typeItem.convoyAttackedTimes
	if not cvyAtkedTimes then
		log_game_error("DragonData:GetConvoyAttackedTimes", "convoyAttackedTimes cfg nil")
		return 0
	end
	return cvyAtkedTimes
end
------------------------------------------------------------------------------------------
--获取袭击cd
------------------------------------------------------------------------------------------
function DragonData:GetAttackCD()
	local typeItem = self:GetDragonItem(DRAGON_BASE, 1)
	if not typeItem then
		return 0
	end
	local atkCD = typeItem.attackCD
	if not atkCD then
		log_game_error("DragonData:GetAttackCD", "attackCD cfg nil")
		return 0
	end
	return atkCD 
end
------------------------------------------------------------------------------------------
--获取复仇次数
------------------------------------------------------------------------------------------
function DragonData:GetRevengeTimes()
	local typeItem = self:GetDragonItem(DRAGON_BASE, 1)
	if not typeItem then
		return 0
	end
	local rvgTimes = typeItem.revengeTimes
	if not rvgTimes then
		log_game_error("DragonData:GetRevengeTimes", "revengeTimes cfg nil")
		return 0
	end
	return rvgTimes 
end
------------------------------------------------------------------------------------------
--获取奖励
------------------------------------------------------------------------------------------
function DragonData:GetRewards(level)
	local typeData = self:GetDragonData(DRAGON_REWARDS)
	if not typeData then
		return {}
	end
	for _, v in pairs(typeData) do
		local levelRange = v.levelRange
		if not levelRange then
			log_game_error("DragonData:GetRewards", "levelRange cfg error")
			return {}
		end
		local minLevel = levelRange[1]
		local maxLevel = levelRange[2]
		if minLevel <= level and level <= maxLevel then
			local rewards = v.rewards 
			if not rewards then
				log_game_error("DragonData:GetRewards", "level=%d rewards cfg error", level)
				return {}
			end
			return rewards
		end 
	end
end
------------------------------------------------------------------------------------------
--获取站点加成百分比
------------------------------------------------------------------------------------------
function DragonData:GetAddFactor(stationId)
	local typeItem = self:GetDragonItem(DRAGON_STATION, stationId)
	if not typeItem then
		return 0
	end
	local addfactor = typeItem.addFactor 
	if not addfactor then
		log_game_error("DragonData:GetAddFactor", "id=%d addFactor nil", stationId)
		return 0
	end
	return addfactor
end
------------------------------------------------------------------------------------------
--获取站点随机事件
------------------------------------------------------------------------------------------
function DragonData:GetStationEvent(stationId)
	local typeItem = self:GetDragonItem(DRAGON_STATION, stationId)
	if not typeItem then
		return
	end
	local events = typeItem.event 
	if not events then
		log_game_error("DragonData:GetStationEvent", "id=%d event nil", stationId)
		return
	end
	local prop = {}
	for k, v in pairs(events) do
		prop[k] = v/100
	end
	local idx = lua_util.choice(prop)
	if not idx then
		idx = 1
	end
	return idx
end
------------------------------------------------------------------------------------------
--获取事件buff,返回值为table类型
------------------------------------------------------------------------------------------
function DragonData:GetEventBuff(idx)
	if idx <= 0 then return end
	local typeItem = self:GetDragonItem(DRAGON_EVENTS, idx)
	if not typeItem then
		return
	end
	local triggerBF = typeItem.triggerBuff
	if not triggerBF then
		log_game_error("DragonData:GetEventBuff", "id=%d triggerBuff nil", id)
		return
	end
	return triggerBF or {}
end
------------------------------------------------------------------------------------------
--获取事件战斗触发条件
------------------------------------------------------------------------------------------
function DragonData:GetFightCondition(idx)
	local typeItem = self:GetDragonItem(DRAGON_EVENTS, idx)
	if not typeItem then
		return 
	end
	return typeItem.ifDoFight
end
------------------------------------------------------------------------------------------
--获取加成buff数值
------------------------------------------------------------------------------------------
function DragonData:GetBuffbyStation(stationId)
  if stationId <= 0 then
    return {}
  end
	local idx = self:GetStationEvent(stationId)
	return self:GetEventBuff(idx)
end
------------------------------------------------------------------------------------------
--获取袭击占比
------------------------------------------------------------------------------------------
function DragonData:GetAttackPercent()
	local typeItem = self:GetDragonItem(DRAGON_BASE, 1)
	if not typeItem then
		return {}
	end
	local atkPercent = typeItem.attackPercent
	if not atkPercent then
		log_game_error("DragonData:GetAttackPercent", "attackPercent cfg nil")
		return {}
	end
	return atkPercent
end
function DragonData:GetLevelBase(level)
	local lvProps = g_avatar_level_mgr:GetLevelProps(level)
	if not lvProps then
		log_game_error("DragonData:GetLevelBase", "avatar level=%s error", tostring(level))
		return {}
	end
	local exp  = lvProps.expStandard
	local gold = lvProps.goldStandard
	return {exp, gold}
end
------------------------------------------------------------------------------------------
--获取飞龙品质数据
------------------------------------------------------------------------------------------
function DragonData:GetQualityItem(quality)
	local itemData = self.DragonData[DRAGON_QUALITY]
	if not itemData then
		log_game_error("DragonData:GetQualityItem", "quality=%d cfg nil or error", quality)
		return 
	end
	for _, v in pairs(itemData) do
		if v.quality == quality then
			return v
		end
	end
end
------------------------------------------------------------------------------------------
--获取飞龙品质加成
------------------------------------------------------------------------------------------
function DragonData:GetQualityRewardAdd(quality)
	local typeItem = self:GetQualityItem(quality)
	if not typeItem then
		return 0
	end
	local rwdAdd = typeItem.rewardAddition
	if not rwdAdd then
		return 0
	end
	return rwdAdd
end
------------------------------------------------------------------------------------------
--获取飞龙提升概率参数
------------------------------------------------------------------------------------------
function DragonData:GetUpQualityProp(quality)
	local typeItem = self:GetQualityItem(quality)
	if not typeItem then
		return 0
	end
	local props = typeItem.upgradeQualityProp
	if not props then
		return 0
	end
	return props
end
------------------------------------------------------------------------------------------
--判断是否刷新成功
------------------------------------------------------------------------------------------
function DragonData:IsFreshSuccess(quality)
	local props = self:GetUpQualityProp(quality)
	local rd    = math.random()
	props = props*0.0001
	return rd <= props
end

function DragonData:GetAttackUpLimit()
	local typeItem = self:GetDragonItem(DRAGON_BASE, 1)
	if not typeItem then
		return {}
	end
	local attackUpLimit = typeItem.attackUpLimit
	if not attackUpLimit then
		log_game_error("DragonData:GetAttackUpLimit", "attackUpLimit cfg nil")
		return {}
	end
	return attackUpLimit

end
------------------------------------------------------------------------------------------
--获取袭击次数购买定价索引
------------------------------------------------------------------------------------------
function DragonData:GetAtkBuyTimesIndex()
	local typeItem = self:GetDragonItem(DRAGON_BASE, 1)
	if not typeItem then
		return
	end
	local atkBuyTimesIdx = typeItem.attackTimesPrice
	if not atkBuyTimesIdx then
		log_game_error("DragonData:GetAtkBuyTimesIndex", "attackTimesPrice cfg nil")
		return
	end
	return atkBuyTimesIdx
end
------------------------------------------------------------------------------------------
--获取飞龙品质提升定价索引
------------------------------------------------------------------------------------------
function DragonData:GetUpQualityIndex()
	local typeItem = self:GetDragonItem(DRAGON_BASE, 1)
	if not typeItem then
		return
	end
	local upQIdx = typeItem.upgradeQualityCost
	if not upQIdx then
		log_game_error("DragonData:GetUpQualityIndex", "upgradeQualityCost cfg nil")
		return
	end
	return upQIdx
end
------------------------------------------------------------------------------------------
--直接购买金色飞龙定价索引
------------------------------------------------------------------------------------------
function DragonData:GetGoldDragonIndex()
	local typeItem = self:GetDragonItem(DRAGON_BASE, 1)
	if not typeItem then
		return
	end
	local goldDgnIdx = typeItem.goldDragonPrice
	if not goldDgnIdx then
		log_game_error("DragonData:GetGoldDragonIndex", "goldDragonPrice cfg nil")
		return
	end
	return goldDgnIdx
end
------------------------------------------------------------------------------------------
--清楚袭击cd定价索引
------------------------------------------------------------------------------------------
function DragonData:GetClearAttackCDIndex()
	local typeItem = self:GetDragonItem(DRAGON_BASE, 1)
	if not typeItem then
		return
	end
	local clrCDIdx = typeItem.clearAttackCDPrice
	if not clrCDIdx then
		log_game_error("DragonData:GetClearCDIndex", "clearAttackCDPrice cfg nil")
		return
	end
	return clrCDIdx
end
------------------------------------------------------------------------------------------
--缩短五分钟定价索引
------------------------------------------------------------------------------------------
function DragonData:GetCutFiveMinIndex()
	local typeItem = self:GetDragonItem(DRAGON_BASE, 1)
	if not typeItem then
		return
	end
	local cutFM = typeItem.cutCompleteTimeFiveMinPrice
	if not cutFM then
		log_game_error("DragonData:GetCutFiveMinIndex", "cutCompleteTimeFiveMinPrice cfg nil")
		return
	end
	return cutFM
end
------------------------------------------------------------------------------------------
--立即完成定价索引
------------------------------------------------------------------------------------------
function DragonData:GetImmeCCIndex()
	local typeItem = self:GetDragonItem(DRAGON_BASE, 1)
	if not typeItem then
		return
	end
	local imCC = typeItem.immediateCompleteConvoyPrice
	if not imCC then
		log_game_error("DragonData:GetImmeCCIndex", "immediateCompleteConvoyPrice cfg nil")
		return
	end
	return imCC
end
------------------------------------------------------------------------------------------
--立即完成定价索引
------------------------------------------------------------------------------------------
function DragonData:GetConvoyIndex()
	local typeItem = self:GetDragonItem(DRAGON_BASE, 1)
	if not typeItem then
		return
	end
	local cvyIdx = typeItem.convoyTimesPrice
	if not cvyIdx then
		log_game_error("DragonData:GetConvoyIndex", "convoyTimesPrice cfg nil")
		return
	end
	return cvyIdx
end
function DragonData:GetFreshAdversaryIndex()
	local typeItem = self:GetDragonItem(DRAGON_BASE, 1)
	if not typeItem then
		return
	end
	local fshAdryIdx = typeItem.freshAdversaryPrice
	if not fshAdryIdx then
		log_game_error("DragonData:GetFreshAdversaryIndex", "freshAdversaryPrice cfg nil")
		return
	end
	return fshAdryIdx
end
function DragonData:CaltAtkRewards(sLevel, level, quality, curRng)
    local rewards  = self:GetRewards(level)                       --基本奖励(table)
    local percts   = self:GetAttackPercent()                      --袭击占比系数
    local awdAdd   = self:GetQualityRewardAdd(quality)            --品质加成系数
    local stnAdd   = self:GetAddFactor(curRng)                    --站点加成系数
    local baseVals = self:GetLevelBase(sLevel)                    --获取等级基础经验和金币
    local upLimits = self:GetAttackUpLimit()                      --袭击上限控制因子
    local rewds    = {}
    for kType, val in pairs(rewards) do
    	local atkPct  = percts[kType] or 0
    	local upLimit = upLimits[kType]  --没有上限因子不计算
    	local baseVal = baseVals[kType]
    	local rest = val*(1 + stnAdd*0.0001)*(1 + awdAdd*0.0001)*atkPct*0.0001
    	if upLimit and baseVal then
    		upLimit = upLimit*baseVal
    		if rest > upLimit then
    			rest = upLimit
    		end
        end
    	rewds[kType] = math.floor(rest)
    end
    return rewds
end
function DragonData:GetFreshQualityItemCost()
	local typeItem = self:GetDragonItem(DRAGON_BASE, 1)
	if not typeItem then
		return
	end
	local itemCost = typeItem.upQualityitemCost
	if not itemCost then
		log_game_error("DragonData:GetFreshQualityItemCost", "upQualityitemCost cfg nil")
		return
	end
	return itemCost
end

------------------------------------------------------------------------------------------
g_dragon_mgr = DragonData

return g_dragon_mgr

