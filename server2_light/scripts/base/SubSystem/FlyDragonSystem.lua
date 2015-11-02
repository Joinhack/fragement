require "PriceList"
require "public_config"
require "lua_util"
require "dragon_data"
require "error_code"
require "reason_def"
require "vip_privilege"
require "channel_config"

local log_game_debug    = lua_util.log_game_debug
local log_game_warning  = lua_util.log_game_warning
local log_game_error    = lua_util.log_game_error
local log_game_info     = lua_util.log_game_info
local globalbase_call   = lua_util.globalbase_call
----------------------------------------------------------------------------------------
local REDUCE_CONVOY_TIME_FIVEMIN  =  300           --护送时间减少5分钟(300s)
local NEED_AVATAR_COUNT_ON        =  4             --开始护送角色请求数量
local NEED_AVATAR_COUNT_OFF       =  5             --护送结束角色请求数量
local REWADS_HAS_GAINED           =  0             --奖励已经领取
local REWADS_CAN_GAIN             =  1             --奖励可以领取
local DRAGON_CONVOY_GOING         =  1             --正在护送
local DRAGON_CONVOY_END           =  0             --结束护送
local DRAGON_NO_CONVOY_TIMES      =  0             --没有剩余护送次数

----------------------------------------------------------------------------------------
FlyDragonSystem = {}
FlyDragonSystem.__index = FlyDragonSystem
function FlyDragonSystem:OnlineDragonInfoReq(avatar)
    if self:IsLevelLimit(avatar) then return end
    local dgnCst = avatar.DragonContest
    if not next(dgnCst) then
        self:InitDragonContest(avatar)
    end
    local delta = self:ConvoyTimeCheck(avatar)
    if delta <= 0 then
        local rsTime = dgnCst[public_config.AVATAR_DRAGON_STIME]
        if rsTime > 0 then
            self:DragonContestSettleReq(avatar) --上次没有结算
        else
            self:DragonInfosResp(avatar, {}) --已经结算过的
        end
        return
    end
    local mb_str = avatar.base_mbstr
    globalbase_call("FlyDragonMgr", "DragonAdversariesReq", mb_str, avatar.dbid)
end
----------------------------------------------------------------------------------------
--飞龙状态请求接口
----------------------------------------------------------------------------------------
function FlyDragonSystem:DragonStatusReq(avatar)
    if self:IsLevelLimit(avatar) then return end
    local dgnCst  = avatar.DragonContest
    if not next(dgnCst) then
        self:InitDragonContest(avatar)
    end
    local rewds   = dgnCst[public_config.AVATAR_DRAGON_REWDS] or {}
    local rwdMark = REWADS_HAS_GAINED
    if next(rewds) then
        rwdMark = REWADS_CAN_GAIN
    end
    local cvyMark = DRAGON_CONVOY_END
    local delta   = self:ConvoyTimeCheck(avatar)
    if delta > 0 then 
        cvyMark = DRAGON_CONVOY_GOING
    end
    local curRng    = dgnCst[public_config.AVATAR_DRAGON_CURRRING] or 0
    local remainRng = DRAGON_NO_CONVOY_TIMES
    if curRng < public_config.DRAGON_STATION_MAX then
        remainRng = public_config.DRAGON_STATION_MAX - curRng
    end
    if avatar:hasClient() then
        avatar.client.DragonStatusResp(rwdMark, cvyMark, remainRng)
        --log_game_debug("FlyDragonSystem:DragonStatusReq", "rwdMark=%d;cvyMark=%d;remainRng=%d", rwdMark, cvyMark, remainRng)
    end
end
----------------------------------------------------------------------------------------
--飞龙复仇请求
----------------------------------------------------------------------------------------
function FlyDragonSystem:DragonRevengeReq(avatar, dbid)
    local retCode  = error_code.ERR_DRAGON_OK
    if self:IsRevengeTimesLimit(avatar) then
        retCode = error_code.ERR_DRAGON_MAX_RVG
        self:DragonAttackResp(avatar, retCode)
        return
    end
    if not self:AttackAndRevengeCheck(avatar) then
        return
    end
    local mb_str = avatar.base_mbstr
    globalbase_call("FlyDragonMgr", "DragonRevengeCheckReq", mb_str, avatar.dbid, dbid)
end
function FlyDragonSystem:AttackAndRevengeCheck(avatar)
    local retCode  = error_code.ERR_DRAGON_OK
    if self:IsAtkTimesLimit(avatar) then
        retCode = error_code.ERR_DRAGON_MAX_ATK_TIMES
        self:DragonAttackResp(avatar, retCode)
        return false
    end
    local atkDelta = self:AtkCDTimeCheck(avatar)
    if atkDelta > 0 then
        retCode = error_code.ERR_DRAGON_ATK_CDLIMIT
        self:DragonAttackResp(avatar, retCode)
        return false
    end
    return true
end
----------------------------------------------------------------------------------------
--飞龙袭击请求
----------------------------------------------------------------------------------------
function FlyDragonSystem:DragonAttackReq(avatar, dbid)
    log_game_debug("FlyDragonSystem:DragonAttackReq", "dbid=%q;name=%s;adv_dbid=%d", avatar.dbid, avatar.name, dbid)
    if not self:AttackAndRevengeCheck(avatar) then
        return
    end
    local mb_str = avatar.base_mbstr
    globalbase_call("FlyDragonMgr", "DragonAttackReq", mb_str, avatar.dbid, dbid)
end
function FlyDragonSystem:ExploreDragonEventReq(avatar)
    local retCode = error_code.ERR_DRAGON_OK
    local delta = self:ConvoyTimeCheck(avatar)
    if delta > 0 then
        retCode = error_code.ERR_EXPORE_CVY_NOTEND
        self:ExploreDragonEventResp(avatar, retCode, 0)
        return
    end
    local dgnCst = avatar.DragonContest
    local curBuf = dgnCst[public_config.AVATAR_DRAGON_CURRBUF]
    if curBuf ~= public_config.DRAGON_START_BUFF_NO then
        self:ExploreDragonEventResp(avatar, retCode, curBuf)
        return
    end
    local curRng = dgnCst[public_config.AVATAR_DRAGON_CURRRING]
    local idx = g_dragon_mgr:GetStationEvent(curRng)
    if not idx then
        retCode = error_code.ERR_EXPORE_CANNOT_EXPLORE
        self:ExploreDragonEventResp(avatar, retCode, 0)
        return
    end
    dgnCst[public_config.AVATAR_DRAGON_CURRBUF] = idx 
    self:ExploreDragonEventResp(avatar, retCode, idx)
end
----------------------------------------------------------------------------------------
--开始飞龙护送请求
----------------------------------------------------------------------------------------
function FlyDragonSystem:StartDragonConvoyReq(avatar, pathMark)
    local dgnCst  = avatar.DragonContest
    local delta   = self:ConvoyTimeCheck(avatar)
    local retCode = error_code.ERR_DRAGON_OK
    if delta > 0 then
        retCode = error_code.ERR_DRAGON_NOEND
        self:DragonConvoyResp(avatar, retCode)
        return
    end
    local rewds  = dgnCst[public_config.AVATAR_DRAGON_REWDS]
    if next(rewds) then
        retCode = error_code.ERR_DRAGON_NOGET_REWAED
        self:DragonConvoyResp(avatar, retCode)
        return 
    end
    if self:IsConvoyTimesLimit(avatar) then
        retCode = error_code.ERR_DRAGON_CONVOY_TIMES_LIMIT
        self:DragonConvoyResp(avatar, retCode)
        return
    end
    local currRng = dgnCst[public_config.AVATAR_DRAGON_CURRRING]
    currRng = currRng + 1
    dgnCst[public_config.AVATAR_DRAGON_CURRRING] = currRng

    local quality = dgnCst[public_config.AVATAR_DRAGON_QUALITY]
    local mb_str  = avatar.base_mbstr
    local equips  = self:GetShowEquipeds(avatar)
    globalbase_call("FlyDragonMgr", "StartDragonConvoyReq", 
        mb_str, avatar.dbid, avatar.level, currRng, quality, equips)
    log_game_debug("FlyDragonSystem:StartDragonConvoyReq", "dbid=%q;name=%s;level=%d;currRng=%d;quality=%d", 
        avatar.dbid, avatar.name, avatar.level, currRng, quality)
    if quality == public_config.DRAGON_QUALITY_GOLD then
        globalbase_call("UserMgr", "ShowTextID", CHANNEL.WORLD, public_config.WORLD_GOLD_START, {avatar.name})
        avatar:OnDragonBest() 
    end
end
function FlyDragonSystem:GetShowEquipeds(avatar)
    local equipeds  = avatar.equipeds
    local equipsList = {}
    for _, item in pairs(equipeds) do
        local gridIndx = item[public_config.ITEM_INSTANCE_GRIDINDEX]
        if gridIndx == public_config.BODY_POS_CHEST or 
           gridIndx == (public_config.BODY_POS_WEAPON + 1) then
           local typeId = item[public_config.ITEM_INSTANCE_TYPEID]
           equipsList[gridIndx] = typeId
        end
    end
    return equipsList
end
function FlyDragonSystem:RemainConvoyTimesReq(avatar)
    local dgnCst = avatar.DragonContest
    local curRng = dgnCst[public_config.AVATAR_DRAGON_CURRRING]
    local remainTimes = public_config.DRAGON_STATION_MAX - curRng
    if avatar:hasClient() then
        avatar.client.RemainConvoyTimesResp(remainTimes)
    end
end
----------------------------------------------------------------------------------------
--购买金色飞龙请求
----------------------------------------------------------------------------------------
function FlyDragonSystem:BuyGoldDragonReq(avatar)
    local dgnCst  = avatar.DragonContest
    local quality = dgnCst[public_config.AVATAR_DRAGON_QUALITY]
    local retCode = error_code.ERR_DRAGON_OK
    if quality == public_config.DRAGON_QUALITY_GOLD then
        retCode = error_code.ERR_DRAGON_GOLDED
        self:FreshDragonQualityResp(avatar, retCode, quality)
        return
    end
    local reason  = reason_def.buyGoldDgn
    local pIdx    = g_dragon_mgr:GetGoldDragonIndex()
    retCode = self:CommonCostCheck(avatar, pIdx, reason)
    if retCode ~= error_code.ERR_DRAGON_OK then
          self:FreshDragonQualityResp(avatar, retCode, 0)
        return
    end
    quality = public_config.DRAGON_QUALITY_GOLD
    dgnCst[public_config.AVATAR_DRAGON_QUALITY] = quality
    self:FreshDragonQualityResp(avatar, retCode, quality)
    
end
----------------------------------------------------------------------------------------
--刷新飞龙品质请求
----------------------------------------------------------------------------------------
function FlyDragonSystem:FreshDragonQualityReq(avatar)
    local retCode = error_code.ERR_DRAGON_OK
    local dgnCst  = avatar.DragonContest
    local curQuality = dgnCst[public_config.AVATAR_DRAGON_QUALITY]
    if curQuality == public_config.DRAGON_QUALITY_GOLD then
        retCode = error_code.ERR_DRAGON_GOLDED
        self:FreshDragonQualityResp(avatar, retCode, curQuality)
        return
    end
    if not self:ItemCostEnoughCheck(avatar) then
        local reason = reason_def.frshDgnQt
        local pIdx   = g_dragon_mgr:GetUpQualityIndex()
        retCode  = self:CommonCostCheck(avatar, pIdx, reason)
        if retCode ~= error_code.ERR_DRAGON_OK then
            self:FreshDragonQualityResp(avatar, retCode, curQuality)
            return
        end
    end
    if not g_dragon_mgr:IsFreshSuccess(curQuality) then
        retCode = error_code.ERR_DRAGON_FRESH_FAIL
        self:FreshDragonQualityResp(avatar, retCode, curQuality)
        avatar:OnDragonLevelUp(false)
        return
    end
    local newQuality = self:GetNextGragonQuality(avatar)
    self:SetDragonQuality(avatar, newQuality)
    self:FreshDragonQualityResp(avatar, retCode, newQuality)
    avatar:OnDragonLevelUp(true)
end
----------------------------------------------------------------------------------------
--清除袭击cd请求，需要完善
----------------------------------------------------------------------------------------
function FlyDragonSystem:ClearAttackCDReq(avatar)
    local retCode  = error_code.ERR_DRAGON_OK
    local atkDelta = self:AtkCDTimeCheck(avatar)
    if atkDelta <= 0 then
        retCode = error_code.ERR_DRAGON_ATKCD_END
        self:ClearAtkCdResp(avatar, retCode)
        return
    end
    local pIdx = g_dragon_mgr:GetClearAttackCDIndex()  
    local reason = reason_def.clrAtkCd
    if not self:AttackCdCostCheck(avatar, pIdx, atkDelta, reason) then
        retCode = error_code.ERR_DRAGON_COST_LIMIT
        self:ClearAtkCdResp(avatar, retCode)
        return
    end
    local dgnCst   = avatar.DragonContest
    local cdLimit  = g_dragon_mgr:GetAttackCD()
    local currTime = dgnCst[public_config.AVATAR_DRAGON_ATKTIME]
    dgnCst[public_config.AVATAR_DRAGON_ATKTIME] = currTime - cdLimit
    self:ClearAtkCdResp(avatar, retCode)
end
----------------------------------------------------------------------------------------
--购买袭击次数请求
----------------------------------------------------------------------------------------
function FlyDragonSystem:BuyAtkTimesReq(avatar)
    local retCode  = error_code.ERR_DRAGON_OK
    if self:IsAtkBuyTimesLimit(avatar) then
        retCode = error_code.ERR_DRAGON_ATKBUY_LIMIT
        self:BuyAtkTimesResp(avatar, retCode)
        return
    end
    local pIdx     = g_dragon_mgr:GetAtkBuyTimesIndex()
    local reason   = reason_def.buyAtkTimes
    local buyTimes = self:GetRealAtkBuyTimes(avatar) + 1
    retCode = self:CommonCostCheck(avatar, pIdx, reason, buyTimes)
    if retCode ~= error_code.ERR_DRAGON_OK then
        self:BuyAtkTimesResp(avatar, retCode)
        return
    end
    self:SetReakAtkTimes(avatar)
    local dgnCst = avatar.DragonContest
    local atkIimes = dgnCst[public_config.AVATAR_DRAGON_ATKTIMES]
    dgnCst[public_config.AVATAR_DRAGON_ATKTIMES] = atkIimes - 1
    self:BuyAtkTimesResp(avatar, retCode)
end
----------------------------------------------------------------------------------------
--减少飞龙护送时间请求
----------------------------------------------------------------------------------------
function FlyDragonSystem:ReduceConvoyTimeReq(avatar)
    local retCode = error_code.ERR_DRAGON_OK
    local delta = self:ConvoyTimeCheck(avatar)
    if delta <= 0 then
        retCode = error_code.ERR_DRAGON_CONVOY_END
        self:DragonRelatedResp(avatar, retCode)
        return
    end
    --消耗计算:减少五分钟
    local pIdx = g_dragon_mgr:GetCutFiveMinIndex()
    local reason = reason_def.rdcCvyTime
    retCode = self:CommonCostCheck(avatar, pIdx, reason)
    if retCode ~= error_code.ERR_DRAGON_OK then
        self:DragonRelatedResp(avatar, retCode)
        return
    end
    local dgnCst = avatar.DragonContest
    local etime  = dgnCst[public_config.AVATAR_DRAGON_STIME] - REDUCE_CONVOY_TIME_FIVEMIN
    local mb_str = avatar.base_mbstr
    globalbase_call("FlyDragonMgr", "ReduceConvoyTimeReq", mb_str, avatar.dbid, etime)
    log_game_debug("FlyDragonSystem:ReduceConvoyTimeReq", "dbid=%q;name=%s;endtime=%d", avatar.dbid, avatar.name, etime)
end
----------------------------------------------------------------------------------------
--立即完成护送请求
----------------------------------------------------------------------------------------
function FlyDragonSystem:ImmediateCompleteConvoyReq(avatar)
    local retCode = error_code.ERR_DRAGON_OK
    local delta = self:ConvoyTimeCheck(avatar)
    if delta <= 0 then
        retCode = error_code.ERR_DRAGON_CONVOY_END
        self:DragonRelatedResp(avatar, retCode)
        return
    end
    local pIdx   = g_dragon_mgr:GetImmeCCIndex()
    local reason = reason_def.immeCplete
    if not self:ConvoyCdCostCheck(avatar, pIdx, delta, reason) then
        retCode = error_code.ERR_DRAGON_COST_LIMIT
        self:DragonRelatedResp(avatar, retCode)
        return
    end
    self:DragonContestSettleReq(avatar)
    log_game_debug("FlyDragonSystem:ImmediateCompleteConvoyReq", "dbid=%q;name=%s", avatar.dbid, avatar.name)
end
----------------------------------------------------------------------------------------
--购买护送次数请求
----------------------------------------------------------------------------------------
function FlyDragonSystem:BuyConvoyTimesReq(avatar)
    local retCode = error_code.ERR_DRAGON_OK
    if self:IsConvoyTimesLimit() then
        retCode = error_code.ERR_DRAGON_CONVOY_UNLIMIT
        self:DragonRelatedResp(avatar, retCode)
        return
    end
    if self:IsConvoyBuyTimesLimit() then
        retCode = error_code.ERR_DRAGON_BUYTIMES_LIMIT
        self:DragonRelatedResp(avatar, retCode)
        return 
    end
    local pIdx     = g_dragon_mgr:GetConvoyIndex()
    local reason   = reason_def.cvyBuyTimes
    local buyTimes = self:GetRealConvoyBuyTimes() + 1
    retCode = self:CommonCostCheck(avatar, pIdx, reason, buyTimes)
    if retCode ~= error_code.ERR_DRAGON_OK then
        self:DragonRelatedResp(avatar, retCode)
        return
    end
    self:SetRealConvoyTimes(avatar)
    local dgnCst = avatar.DragonContest
    local curRng = dgnCst[public_config.AVATAR_DRAGON_CURRRING]
    dgnCst[public_config.AVATAR_DRAGON_CURRRING] = curRng - 1
    self:DragonRelatedResp(avatar, retCode)
end
----------------------------------------------------------------------------------------
--飞龙结算请求中转接口
----------------------------------------------------------------------------------------
function FlyDragonSystem:DragonContestSettleReq(avatar)
    local mb_str = avatar.base_mbstr
    globalbase_call("FlyDragonMgr", "DragonContestSettleReq", mb_str, avatar.dbid)
end
----------------------------------------------------------------------------------------
--飞龙护送奖励接口
----------------------------------------------------------------------------------------
function FlyDragonSystem:DragonCvyRewardReq(avatar)
    local dgnCst  = avatar.DragonContest
    local rewds   = dgnCst[public_config.AVATAR_DRAGON_REWDS]
    local retCode = error_code.ERR_DRAGON_OK
    if not next(rewds) then
        retCode = error_code.ERR_DRAGON_HAS_GAINED
    end
    local gold = rewds[public_config.GOLD_ID] or 0
    local exp  = rewds[public_config.EXP_ID]  or 0
    avatar:AddGold(gold, reason_def.dragonConvoy)
    avatar:AddExp(exp, reason_def.dragonConvoy)

    dgnCst[public_config.AVATAR_DRAGON_REWDS] = {}
    if avatar:hasClient() then
        avatar.client.DragonCvyRewardResp(retCode)
    end
    local curRng = dgnCst[public_config.AVATAR_DRAGON_CURRRING]
    if curRng == public_config.DRAGON_STATION_MAX then
        local flips  = g_text_mgr:GetText(public_config.AVATAR_DRAGON_OVER)
        avatar:ShowText(CHANNEL.TIPS, flips)
    end
end

----------------------------------------------------------------------------------------
--刷新飞龙奖励接口
----------------------------------------------------------------------------------------
function FlyDragonSystem:FreshConvoyReward(avatar)
    local mb_str = avatar.base_mbstr
    globalbase_call("FlyDragonMgr", "FreshConvoyRewardReq", mb_str, avatar.dbid)
end
----------------------------------------------------------------------------------------
--所有飞龙事件请求接口
----------------------------------------------------------------------------------------
function FlyDragonSystem:AllDragonEventListReq(avatar)
    local mb_str = avatar.base_mbstr
    globalbase_call("FlyDragonMgr", "AllDragonEventListReq", mb_str, avatar.dbid)
end
----------------------------------------------------------------------------------------
--刷新对手请求
----------------------------------------------------------------------------------------
function FlyDragonSystem:FreshAdversaryReq(avatar)
    local delta    = self:ConvoyTimeCheck(avatar)
    if delta <= 0 then
        return
    end
    local pIdx     = g_dragon_mgr:GetFreshAdversaryIndex()
    local reason   = reason_def.frshAdvry
    local retCode  = self:CommonCostCheck(avatar, pIdx, reason)
    if retCode ~= error_code.ERR_DRAGON_OK  then
        self:DragonRelatedResp(avatar, retCode)
        return
    end
    local mb_str  = avatar.base_mbstr
    globalbase_call("FlyDragonMgr", "FreshDragonAdversariesReq", mb_str, avatar.dbid, avatar.level)
    avatar:DragonShowText(CHANNEL.TIPS, public_config.FRESH_DRAGON_OK)
end
----------------------------------------------------------------------------------------
--刷新附送奖励回调接口
----------------------------------------------------------------------------------------
function FlyDragonSystem:BaseFreshConvoyRewardResp(avatar, sucTimes, level, curRng)
    local rewds = self:GetConvoyRewards(avatar, sucTimes, level, curRng)
    local gold  = rewds[public_config.GOLD_ID] or 0
    local exp   = rewds[public_config.EXP_ID]  or 0
    if avatar:hasClient() then
        avatar.client.FreshConvoyRewardResp(exp, gold)
    end   
end
----------------------------------------------------------------------------------------
--飞龙护送回调请求接口
----------------------------------------------------------------------------------------
function FlyDragonSystem:BaseDragonContestSettleResp(avatar, sucTimes, level, curRng)
    local rewds = self:GetConvoyRewards(avatar, sucTimes, level, curRng)
    log_game_debug("FlyDragonSystem:BaseDragonContestSettleResp", "dbid=%q;name=%s;sucTimes=%d;level=%d;ring=%d;rewards=%s", 
        avatar.dbid, avatar.name, sucTimes, level, curRng, mogo.cPickle(rewds))
    self:OnceCompleteConvoyDragonReset(avatar, rewds)
    if level ~= 0 and curRng ~= 0 then
        local mb_str  = avatar.base_mbstr
        globalbase_call("FlyDragonMgr", "DragonConvoyCompleteResp", mb_str, avatar.dbid, rewds)
    end
    self:DragonTimerDeal(avatar, 0)   --处理timer(有可能是直接完成或是缩短时间)
    self:DragonInfosResp(avatar, {})  --返回给前端
end
----------------------------------------------------------------------------------------
--一次完成后飞龙数据重置
----------------------------------------------------------------------------------------
function FlyDragonSystem:OnceCompleteConvoyDragonReset(avatar, rewds)
    local dgnCst  = avatar.DragonContest
    dgnCst[public_config.AVATAR_DRAGON_REWDS]   = rewds   --保存奖励
    local genDgn  = public_config.DRAGON_QUALITY_GREEN
    dgnCst[public_config.AVATAR_DRAGON_QUALITY] = genDgn  --重置飞龙品质为绿色
    dgnCst[public_config.AVATAR_DRAGON_STIME]   = 0       --开始时间置为零
    dgnCst[public_config.AVATAR_DRAGON_CCRING]  = 0
    dgnCst[public_config.AVATAR_DRAGON_CURRBUF] = public_config.DRAGON_START_BUFF_NO
end
----------------------------------------------------------------------------------------
--零点清零接口，角色上线需要校验重置
----------------------------------------------------------------------------------------
function FlyDragonSystem:DragonContestStatusCheck(avatar)
    local dgnCst    = avatar.DragonContest
    local atkLimit  = g_dragon_mgr:GetDailyAttackTimes()
    local atkTimes  = dgnCst[public_config.AVATAR_DRAGON_ATKTIMES]
    local buffMark  = public_config.DRAGON_START_BUFF_NO
    if atkTimes > 0 then --校验角色袭击次数是否因购买而超过上限
        dgnCst[public_config.AVATAR_DRAGON_ATKTIMES] = 0
    end
    dgnCst[public_config.AVATAR_DRAGON_RSTIME]   = os.time()
    dgnCst[public_config.AVATAR_DRAGON_ATKTIME]  = 0         --袭击时间清零
    dgnCst[public_config.AVATAR_DRAGON_REVENGE]  = 0         --复仇次数回到上限
    dgnCst[public_config.AVATAR_DRAGON_CURRRING] = 0         --当前环数清零
    dgnCst[public_config.AVATAR_DRAGON_CURRBUF]  = buffMark  --每天清零
    log_game_debug("FlyDragonSystem:DragonContestStatusCheck", "dbid=%q;name=%s;resetTime=%d", avatar.dbid, avatar.name, os.time())
end
----------------------------------------------------------------------------------------
--护送奖励计算接口
----------------------------------------------------------------------------------------
function FlyDragonSystem:GetConvoyRewards(avatar, sucTimes, level, curRng)
    if level == 0 or curRng == 0 then
        return {}
    end
    local dgnCst  = avatar.DragonContest
    local quality = dgnCst[public_config.AVATAR_DRAGON_QUALITY]
    local idx     = dgnCst[public_config.AVATAR_DRAGON_CURRBUF] or 0
    local rewds   = self:SettleConvoyRewards(level, quality, curRng, sucTimes, idx)
    return rewds
end
----------------------------------------------------------------------------------------
--设置飞龙品质
----------------------------------------------------------------------------------------
function FlyDragonSystem:SetDragonQuality(avatar, quality)
    local dgnCst  = avatar.DragonContest
    dgnCst[public_config.AVATAR_DRAGON_QUALITY] = quality
end
----------------------------------------------------------------------------------------
--设置飞龙实时袭击购买次数
----------------------------------------------------------------------------------------
function FlyDragonSystem:SetReakAtkTimes(avatar)
    local key = public_config.DAILY_DRAGON_ATK_BUY_TIMES
    return avatar:SetVipState(key, 1)
end
----------------------------------------------------------------------------------------
--设置飞龙实时袭击购买次数
----------------------------------------------------------------------------------------
function FlyDragonSystem:GetRealAtkBuyTimes(avatar)
    local key    = public_config.DAILY_DRAGON_ATK_BUY_TIMES
    local rtimes = avatar:GetVipState(key)
    return rtimes
end
----------------------------------------------------------------------------------------
--设置飞龙实时护送次数
----------------------------------------------------------------------------------------
function FlyDragonSystem:SetRealConvoyTimes(avatar)
    local key = public_config.DAILY_DRAGON_CONVOY_BUY_TIMES
    return avatar:SetVipState(key, 1)
end
----------------------------------------------------------------------------------------
--获取飞龙实时护送购买次数
----------------------------------------------------------------------------------------
function FlyDragonSystem:GetRealConvoyBuyTimes(avatar)
    local key    = public_config.DAILY_DRAGON_CONVOY_BUY_TIMES
    local rtimes = avatar:GetVipState(key)
    return rtimes
end
----------------------------------------------------------------------------------------
--获取飞龙下一品质
----------------------------------------------------------------------------------------
function FlyDragonSystem:GetNextGragonQuality(avatar)
    local dgnCst  = avatar.DragonContest
    local quality = dgnCst[public_config.AVATAR_DRAGON_QUALITY]
    if quality == public_config.DRAGON_QUALITY_GREEN then
        return public_config.DRAGON_QUALITY_BLUE
    elseif quality == public_config.DRAGON_QUALITY_BLUE then
        return public_config.DRAGON_QUALITY_PURPLE
    elseif quality == public_config.DRAGON_QUALITY_PURPLE then
        return public_config.DRAGON_QUALITY_ORANGE
    elseif quality == public_config.DRAGON_QUALITY_ORANGE then
        return public_config.DRAGON_QUALITY_GOLD
    elseif quality == public_config.DRAGON_QUALITY_GOLD then
        return public_config.DRAGON_QUALITY_GOLD
    end
end
----------------------------------------------------------------------------------------
--获取角色基本信息
----------------------------------------------------------------------------------------
function FlyDragonSystem:GetAvatarBaseInfo(avatar)
    local dgnCst   = avatar.DragonContest
    if not next(dgnCst) then
        self:InitDragonContest(avatar)
    end
    local infoTbl  = {}
    local atkLimit = g_dragon_mgr:GetDailyAttackTimes()
    local rvgTimes = g_dragon_mgr:GetRevengeTimes()
    rvgTimes = rvgTimes - dgnCst[public_config.AVATAR_DRAGON_REVENGE]
    local atkTimes = atkLimit - dgnCst[public_config.AVATAR_DRAGON_ATKTIMES]
    local curRng   = dgnCst[public_config.AVATAR_DRAGON_CURRRING]
    local quality  = dgnCst[public_config.AVATAR_DRAGON_QUALITY]
    local rewds    = dgnCst[public_config.AVATAR_DRAGON_REWDS] or {}
    local atkDelta = self:AtkCDTimeCheck(avatar)
    local stDelta  = self:ConvoyTimeCheck(avatar) 
    if not next(rewds) then
        rewds = REWADS_HAS_GAINED
    else
        rewds = REWADS_CAN_GAIN
    end
    local bufMark = dgnCst[public_config.AVATAR_DRAGON_CURRBUF]
    if bufMark ~= public_config.DRAGON_START_BUFF_NO then
        bufMark = public_config.DRAGON_START_BUFF_OK
    end
    infoTbl[public_config.AVATAR_DRAGON_ATKTIMES] =  atkTimes --袭击别人的次数
    infoTbl[public_config.AVATAR_DRAGON_ATKTIME]  =  atkDelta --袭击别人时间戳，处理袭击cd
    infoTbl[public_config.AVATAR_DRAGON_CURRRING] =  curRng   --当前的环数
    infoTbl[public_config.AVATAR_DRAGON_REVENGE]  =  rvgTimes --复仇次数
    infoTbl[public_config.AVATAR_DRAGON_STIME]    =  stDelta  --开始时间戳,处理护送cd
    infoTbl[public_config.AVATAR_DRAGON_QUALITY]  =  quality  --飞龙品质
    infoTbl[public_config.AVATAR_DRAGON_REWDS]    =  rewds    --奖励领取标记
    infoTbl[public_config.AVATAR_DRAGON_EXPLRE]   =  bufMark  --探索标记
    return infoTbl
end
----------------------------------------------------------------------------------------
--袭击购买次数限制接口
----------------------------------------------------------------------------------------
function FlyDragonSystem:GetAtkBuyTimesLimit(avatar)
    local vipLimit = g_vip_mgr:GetVipPrivileges(avatar.VipLevel)
    local limit    = vipLimit.dailyDragonAttackBuyTimes
    if not limit then
        return 0
    end
    return limit
end
----------------------------------------------------------------------------------------
--护送购买次数限制接口
----------------------------------------------------------------------------------------
function FlyDragonSystem:GetConvoyBuyTimesLimit(avatar)
    local vipLimit = g_vip_mgr:GetVipPrivileges(avatar.VipLevel)
    local limit    = vipLimit.dailyDragonConvoyBuyTimes
    if not limit then
        return 0
    end
    return limit
end
----------------------------------------------------------------------------------------
--判断复仇次数是否限制
----------------------------------------------------------------------------------------
function FlyDragonSystem:IsRevengeTimesLimit(avatar)
    local dgnCst   = avatar.DragonContest
    local rvgTimes = dgnCst[public_config.AVATAR_DRAGON_REVENGE]
    local rvgLimit = g_dragon_mgr:GetRevengeTimes()
    if rvgTimes >= rvgLimit then
        return true
    end
    return false
end
----------------------------------------------------------------------------------------
--判断护送次数是否限制
----------------------------------------------------------------------------------------
function FlyDragonSystem:IsConvoyTimesLimit(avatar)
    local dgnCst = avatar.DragonContest
    local curRng = dgnCst[public_config.AVATAR_DRAGON_CURRRING]
    local maxRng = public_config.DRAGON_STATION_MAX
    if curRng >= maxRng then
        return true
    end
    return false
end
----------------------------------------------------------------------------------------
--判断护送购买次数是否限制
----------------------------------------------------------------------------------------
function FlyDragonSystem:IsConvoyBuyTimesLimit(avatar)
    local rtimes = self:GetRealConvoyBuyTimes(avatar)
    local vtimes = self:GetConvoyBuyTimesLimit(avatar)
    if rtimes >= vtimes then
        return true
    end
    return false
end
----------------------------------------------------------------------------------------
--判断袭击次数是否限制
----------------------------------------------------------------------------------------
function FlyDragonSystem:IsAtkTimesLimit(avatar)
    local dgnCst   = avatar.DragonContest
    local atkTimes = dgnCst[public_config.AVATAR_DRAGON_ATKTIMES]
    local atkLimit = g_dragon_mgr:GetDailyAttackTimes()
    if atkTimes >= atkLimit then
        return true
    end
    return false
end
----------------------------------------------------------------------------------------
--判断袭击购买次数是否限制
----------------------------------------------------------------------------------------
function FlyDragonSystem:IsAtkBuyTimesLimit(avatar)
    local rtimes = self:GetRealAtkBuyTimes(avatar)
    local vtimes = self:GetAtkBuyTimesLimit(avatar)
    if rtimes >= vtimes then
        return true
    end
    return false
end
-----------------------------------------------------------------------------------------
--袭击cd检查
-----------------------------------------------------------------------------------------
function FlyDragonSystem:AtkCDTimeCheck(avatar)
    local dgnCst   = avatar.DragonContest
    --local cdLimit  = g_dragon_mgr:GetAttackCD()
    local atkCd    = dgnCst[public_config.AVATAR_DRAGON_ATKTIME]
    local curTime = os.time()
    --atkCd = atkCd + cdLimit
    if atkCd > curTime then
        return atkCd - curTime
    end
    return 0
end
----------------------------------------------------------------------------------------
--消耗检查和扣除通用接口
----------------------------------------------------------------------------------------
function FlyDragonSystem:CommonCostCheck(avatar, pIdx, reason, times)
    local retCode = error_code.ERR_DRAGON_OK
    if not pIdx then
        retCode = error_code.ERR_DRAGON_CFG_ERR
        return retCode
    end
    local flag = g_priceList_mgr:PriceCheck(avatar, pIdx, times) 
    if not flag then
        retCode = error_code.ERR_DRAGON_COST_LIMIT
        return retCode
    end
    flag = g_priceList_mgr:DeductCost(avatar, pIdx, reason, times)
    if not flag then
        retCode = error_code.ERR_DRAGON_DEDUCT_WRONG
        return retCode
    end
    return retCode
end
function FlyDragonSystem:AttackCdCostCheck(avatar, pIdx, delta, reason)
    local mins = math.floor(delta/60)
    if mins <= 0 then
        mins = 1
    end
    return self:MinCdCostCheck(avatar, pIdx, mins, reason)
end
function FlyDragonSystem:MinCdCostCheck(avatar, pIdx, mins, reason)
    local flag = g_priceList_mgr:MinitesCostCheck(avatar, pIdx, mins, reason)
    if not flag then
        return false
    end
    flag = g_priceList_mgr:DeductMinitesCost(avatar, pIdx, mins, reason)
    if not flag then
        return false
    end
    return true
end
function FlyDragonSystem:ConvoyCdCostCheck(avatar, pIdx, delta, reason)
    local mins = math.floor(delta/60)
    if mins <= 0 then
        mins = 1
    end
    return self:MinCdCostCheck(avatar, pIdx, mins, reason)
end
----------------------------------------------------------------------------------------
--护送时间检查
----------------------------------------------------------------------------------------
function FlyDragonSystem:ConvoyTimeCheck(avatar)
    local dgnCst     = avatar.DragonContest
    local endTime    = dgnCst[public_config.AVATAR_DRAGON_STIME]
    local currTime   = os.time()
    if currTime < endTime then
        return endTime - currTime
    end
    return 0
end
----------------------------------------------------------------------------------------
--飞龙上线检查
----------------------------------------------------------------------------------------
function FlyDragonSystem:DragonOnlineCheck(avatar)
    if self:IsLevelLimit(avatar) then return end
    local dgnCst = avatar.DragonContest
    if not next(dgnCst) then
        self:InitDragonContest(avatar)
        return
    end
    local rsTime = dgnCst[public_config.AVATAR_DRAGON_RSTIME] or 0
    local cuTime = os.time()
    if not lua_util.is_same_day(rsTime, cuTime) then
        self:DragonContestStatusCheck(avatar)
    end
    local delta = self:ConvoyTimeCheck(avatar)
    if delta > 0 then
        self:DragonTimerDeal(avatar, delta)
    end
    local hasRing  = dgnCst[public_config.AVATAR_DRAGON_CURRRING]
    local cRing    = dgnCst[public_config.AVATAR_DRAGON_CCRING] or hasRing
    local dgnColor = dgnCst[public_config.AVATAR_DRAGON_QUALITY]
    local endTime  = dgnCst[public_config.AVATAR_DRAGON_STIME]
    local equipeds = self:GetShowEquipeds(avatar)
    globalbase_call("FlyDragonMgr", "RegisterInfoRecoveryReq", avatar.dbid, avatar.level, cRing, dgnColor, endTime, equipeds)
end
------------------------------------------------------------------------------------------
--校验等级是否受限
------------------------------------------------------------------------------------------
function FlyDragonSystem:IsLevelLimit(avatar)
    local lvNeed = g_dragon_mgr:GetLevelLimit()
    if avatar.level < lvNeed then
        log_game_debug("FlyDragonSystem:IsLevelLimit", "fly dragon level limit dbid=%q;name=%s;level=%d", 
            avatar.dbid, avatar.name, avatar.level)
        return true
    end
    return false
end
----------------------------------------------------------------------------------------
--飞龙护送完成结算接口
----------------------------------------------------------------------------------------
function FlyDragonSystem:SettleConvoyRewards(level, quality, currRng, atkeds, idx)
    local rewards    = g_dragon_mgr:GetRewards(level)                       --基本奖励(table)
    local percts     = g_dragon_mgr:GetAttackPercent()                      --袭击占比
    local awdAdd     = g_dragon_mgr:GetQualityRewardAdd(quality)            --品质加成系数
    local stnAdd     = g_dragon_mgr:GetAddFactor(currRng)                   --站点加成系数
    local buffs      = g_dragon_mgr:GetEventBuff(idx) or {}                 --上一站点buff加成 
    local rewds      = {}
    for tKey, bsCnt in pairs(rewards) do
        local kBuff  = buffs[tKey]  or 0
        local atkPt  = percts[tKey] or 0
        local resCnt = self:CaltReward(atkPt, awdAdd, stnAdd, atkeds, kBuff, bsCnt)
        rewds[tKey]  = resCnt
    end
    return rewds
end
----------------------------------------------------------------------------------------
--结算计算处理
----------------------------------------------------------------------------------------
function FlyDragonSystem:CaltReward(atkPer, awdAdd, stnAdd, atkeds, bufAdd, base)
    local resStn = (1 + stnAdd*0.0001)
    local resAwd = (1 + awdAdd*0.0001)
    local resBuf = (1 + bufAdd*0.0001)
    local resAtk = (1 - atkeds*atkPer*0.0001)
    local result = base*resStn*resAwd*resBuf*resAtk
    return result
end
----------------------------------------------------------------------------------------
--初始化飞龙数据
----------------------------------------------------------------------------------------
function FlyDragonSystem:InitDragonContest(avatar)
    local dgnCst = avatar.DragonContest
    local dgnClor = public_config.DRAGON_QUALITY_GREEN      --飞龙的品质
    --添加总的袭击次数

    dgnCst[public_config.AVATAR_DRAGON_ATKTIMES]     =  0         --袭击别人的次数
    dgnCst[public_config.AVATAR_DRAGON_ATKTIME]      =  0         --袭击别人时间戳，处理袭击cd
    dgnCst[public_config.AVATAR_DRAGON_CURRRING]     =  0         --当前的环数
    dgnCst[public_config.AVATAR_DRAGON_REVENGE]      =  0         --复仇次数
    dgnCst[public_config.AVATAR_DRAGON_STIME]        =  0         --开始时间戳,处理护送cd
    dgnCst[public_config.AVATAR_DRAGON_QUALITY]      =  dgnClor
    dgnCst[public_config.AVATAR_DRAGON_REWDS]        =  {}
    dgnCst[public_config.AVATAR_DRAGON_RSTIME]       =  os.time() --记录上次实际开始或完成时间
    dgnCst[public_config.AVATAR_DRAGON_CURRBUF]      =  public_config.DRAGON_START_BUFF_NO
    dgnCst[public_config.AVATAR_DRAGON_CCRING]       =  0         --当前护送的环数
end
----------------------------------------------------------------------------------------
--飞龙品质提升道具消耗处理
----------------------------------------------------------------------------------------
function FlyDragonSystem:ItemCostEnoughCheck(avatar)
    local inventory = avatar.inventorySystem
    local itemCost  = g_dragon_mgr:GetFreshQualityItemCost()
    if not itemCost then
        return false
    end
    for typeId, count in pairs(itemCost) do
        local flag = inventory:HasEnoughItems(typeId, count)
        if not flag then
            return false
        end
    end
    for typeId, count in pairs(itemCost) do
        avatar:DelItem(typeId, count, reason_def.frshDgnQt)
    end
    return true
end
----------------------------------------------------------------------------------------
--更新次数处理
----------------------------------------------------------------------------------------
function FlyDragonSystem:BaseUpdateRelateTimes(avatar, tKey)
    if tKey ~= public_config.AVATAR_DRAGON_ATKTIMES and tKey ~= public_config.AVATAR_DRAGON_REVENGE then
       return
    end
    local dgnCst = avatar.DragonContest
    local times  = dgnCst[tKey]
    if tKey == public_config.AVATAR_DRAGON_REVENGE then
        local rvgLimit = g_dragon_mgr:GetRevengeTimes()
        if times >= rvgLimit then
            return
        end
    end
    dgnCst[tKey] = times + 1
    if tKey == public_config.AVATAR_DRAGON_ATKTIMES  then
        local cdLimit = g_dragon_mgr:GetAttackCD()
        dgnCst[public_config.AVATAR_DRAGON_ATKTIME] = os.time() + cdLimit
    end
end
----------------------------------------------------------------------------------------
--袭击战斗回调
----------------------------------------------------------------------------------------
function FlyDragonSystem:DragonBattleCallback(avatar, isWin, rewards, defier, quality)
    if isWin == public_config.DRAGON_BATTLE_WIN then
        local gold = rewards[public_config.GOLD_ID] or 0
        avatar:AddGold(gold, reason_def.atkDragon)
        local exp  = rewards[public_config.EXP_ID] or 0
        avatar:AddExp(exp, reason_def.atkDragon)
        avatar:OnDragonAttackWin()
    end
    local dgnCst = avatar.DragonContest
    local cdLimit = g_dragon_mgr:GetAttackCD()
    dgnCst[public_config.AVATAR_DRAGON_ATKTIME]  = os.time() + cdLimit
    local mbStr = avatar.base_mbstr
    globalbase_call("FlyDragonMgr", "DragonBattleCallback", mbStr, avatar.dbid, defier, isWin, quality, rewards)
    log_game_debug("FlyDragonSystem:DragonBattleCallback", "dbid=%q;name=%s;defier=%q;isWin=%d;quality=%d;rewards=%s",
        avatar.dbid, avatar.name, defier, isWin, quality, mogo.cPickle(rewards))
end
----------------------------------------------------------------------------------------
--开始飞龙护送管理器回调
----------------------------------------------------------------------------------------
function FlyDragonSystem:BaseStartDragonConvoyResp(avatar, retCode, etime)
    local dgnCst  = avatar.DragonContest
    avatar:DragonShowText(CHANNEL.TIPS, public_config.START_DRAGON_OK)
    avatar:OnDragon()
    log_game_debug("FlyDragonSystem:BaseStartDragonConvoyResp", "dbid=%q;name=%s;end_time=%d;level=%d",
        avatar.dbid, avatar.name, etime, avatar.level)
    local curRng = dgnCst[public_config.AVATAR_DRAGON_CURRRING]
    dgnCst[public_config.AVATAR_DRAGON_CCRING] = curRng
    if self:ReduceConvoyTimeCheck(avatar, retCode, etime) then
        return  --进入结算不刷对手
    end
    local mb_str  = avatar.base_mbstr
    globalbase_call("FlyDragonMgr", "FreshDragonAdversariesReq", mb_str, avatar.dbid, avatar.level)  --刷对手
end
function FlyDragonSystem:ReduceConvoyTimeCheck(avatar, retCode, etime)
    if retCode ~= error_code.ERR_DRAGON_OK then
        self:DragonConvoyResp(avatar, retCode)
        return false
    end
    local dgnCst  = avatar.DragonContest
    dgnCst[public_config.AVATAR_DRAGON_STIME]  = etime
    local delta   = self:ConvoyTimeCheck(avatar)
    if delta > 0 then
        --记录定时器id，条件满足要执行delete
        self:DragonTimerDeal(avatar, delta)
    else
        self:DragonContestSettleReq(avatar)
        return true
    end
    return false
end
function FlyDragonSystem:BaseReduceConvoyTimeResp(avatar, retCode, etime)
    if not self:ReduceConvoyTimeCheck(avatar, retCode, etime) then
        local delta = self:ConvoyTimeCheck(avatar)
        self:DragonConvoyResp(avatar, retCode, delta)
    end
end
----------------------------------------------------------------------------------------
--飞龙定时器处理
----------------------------------------------------------------------------------------
function FlyDragonSystem:DragonTimerDeal(avatar, delta)
  local timerId = avatar.tmp_data[public_config.TMP_DATA_KEY_DRAGON_TIMERID]
  if timerId then
      if avatar:hasLocalTimer(timerId) then
          avatar:delLocalTimer(timerId)
      end
  end
  if delta <= 0 then
      return
  end
  timerId = avatar:addLocalTimer("DragonContestSettleReq", delta*1000, 1)
  avatar.tmp_data[public_config.TMP_DATA_KEY_DRAGON_TIMERID] = timerId
end

function FlyDragonSystem:FreshDragonQualityResp(avatar, retCode, quality)
    if avatar:hasClient() then
        avatar.client.FreshDragonQualityResp(retCode, quality)
    end
    log_game_debug("FlyDragonSystem:FreshDragonQualityResp", "dbid=%q;name=%s;retCode=%d;quality=%d", 
            avatar.dbid, avatar.name, retCode, quality)
end
function FlyDragonSystem:DragonRelatedResp(avatar, retCode)
    if avatar:hasClient() then
        avatar.client.DragonRelatedResp(retCode)
    end
end
function FlyDragonSystem:ClearAtkCdResp(avatar, retCode)
    if avatar:hasClient() then
        avatar.client.ClearAtkCdResp(retCode)
    end
end
function FlyDragonSystem:BuyAtkTimesResp(avatar, retCode)
    if avatar:hasClient() then
        avatar.client.BuyAtkTimesResp(retCode)
    end
end
function FlyDragonSystem:DragonConvoyResp(avatar, retCode, delta)
    if not delta then delta = 0 end
    if avatar:hasClient() then
        avatar.client.DragonConvoyResp(retCode, delta)
    end
end
function FlyDragonSystem:DragonAttackResp(avatar, retCode)
    if avatar:hasClient() then
        avatar.client.DragonAttackResp(retCode)
        --log_game_debug("FlyDragonSystem:DragonAttackResp", "retCode=%d", retCode)
    end
end
function FlyDragonSystem:DragonInfosResp(avatar, infoList)
    local allInfos = self:GetAvatarBaseInfo(avatar)
    allInfos[public_config.AVATAR_DRAGON_ADVES] = infoList
    if avatar:hasClient() then
        avatar.client.DragonInfoResp(allInfos)
        log_game_debug("FlyDragonSystem:DragonInfosResp", "dbid=%q;name=%s;info=%s", 
            avatar.dbid, avatar.name, mogo.cPickle(allInfos))
    end
end
function FlyDragonSystem:ExploreDragonEventResp(avatar, retCode, idx)
    if avatar:hasClient() then
        avatar.client.ExploreDragonEventResp(retCode, idx)
        --log_game_debug("FlyDragonSystem:ExploreDragonEventResp", "explore ok retCode=%d;idx=%d", retCode, idx)
    end
end
return FlyDragonSystem
