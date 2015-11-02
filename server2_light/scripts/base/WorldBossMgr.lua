--author:hwj
--date:2013-6-14
--此为世界boss管理类

require "public_config"
require "lua_util"
require "error_code"
require "BossHpMgr"
require "worldboss_config"
require "channel_config"
require "vip_privilege"
require "client_text_id"
require "Summoner"

local log_game_info = lua_util.log_game_info
local log_game_debug = lua_util.log_game_debug
local log_game_error = lua_util.log_game_error
local log_game_warning = lua_util.log_game_warning

--local PRE_OPEN_TIME = g_wb_config.PRE_OPEN_TIME -- 600 --提前10分钟设置可进
--local WorldBossTimeStart = g_wb_config.WorldBossTimeStart --72000
--local WorldBossTimeIntervel = g_wb_config.WorldBossTimeIntervel --86400
--local WorldBossTime = g_wb_config.WorldBossTime --1800

--local SHOW_TOP_N = g_wb_config.SHOW_TOP_N --5 排行榜显示top几位
--local WDAY_REFRESH = g_wb_config.WDAY_REFRESH --2 周一刷新, 1代表星期天
--local HOUR_WEEK_REFRESH = g_wb_config.HOUR_WEEK_REFRESH --0 周排名刷新时间（小时）

--local SEC_PER_WEEK = g_wb_config.SEC_PER_WEEK --604800

--local SAVE_PER_TIME = g_wb_config.SAVE_PER_TIME --每次保存300个玩家数据
--local SAVE_INTERVEL = g_wb_config.SAVE_INTERVEL --300秒
--local SYN_INTERVEL = g_wb_config.SYN_INTERVEL --5

local m_timerType = 
{
	OPEN  = 1,
    START = 2,
	END   = 3,
    SYN   = 4,
    WEEK  = 5,
    SAVE  = 6,

    GM_OPEN = 7,
    GM_START = 8,
    GM_END = 9,
    GM_WEEK = 10,

    DAY = 11,
}
--[[
local m_lv = 
{
    lvmin = 20,
    lv1 = 25,
    lv2 = 30,
    lv3 = 35,
    lv4 = 40,
    lv5 = 45,
    lv6 = 50,
    lv7 = 55,
    lv8 = public_config.LV_MAX,
}
]]
--local m_lv = g_wb_config.LVS

local function lGetLv(level)
    if level >= public_config.LV_MAX then
        return #g_wb_config.LVS
    end
    for i,v in ipairs(g_wb_config.LVS) do
        if level < v then 
            return i - 1
        end
    end
end

local function lGetMapId(lv)
    return g_wb_config.SPACES[lv]
end
--vip进入活动次数对应规则
--[[
local m_vip2Time = 
{
    [0] = 1,
    [1] = 2,
    [2] = 3,
    [3] = 4,
    [4] = 5,
    [5] = 6,
    [6] = 7,
    [7] = 8,
    [8] = 9,
    [9] = 10,
}
]]
--伤害转贡献规则, 获得的贡献=伤害值×贡献系数/10000, 客户端显示时除以10000
local function lHarm2Contribution(harm, lv)
    local f = g_sanctuary_defense_mgr:GetFactors(lv)
    log_game_debug('lHarm2Contribution','f=%d,lv=%d',f.contributionFactor,lv)
    if not f then 
        log_game_error("lHarm2Contribution", "lv = %d", lv)
        return 0 
    end
    return harm * f.contributionFactor
end

WorldBossMgr = {}
--MapMgr.__index = MapMgr

setmetatable(WorldBossMgr, {__index = BaseEntity} )

--------------------------------------------------------------------------------------
--local function __dummy()
--end

--某个功能Mgr注册globalbase后的回调方法
local function basemgr_register_callback(mgr_name, eid)
    local mm_eid = eid
    local function __callback(ret)
        local gm = mogo.getEntity(mm_eid)
        if gm then
            if ret == 1 then
                --注册成功
                gm:on_registered()
            else
                --注册失败
                log_game_warning(mgr_name..".registerGlobally error", '')
                --destroy方法未实现,todo
                --gm.destroy()
            end
        end
    end
    return __callback
end

--某个功能Mgr写数据库的回调方法
local function on_basemgr_saved(mgr_name1)
    local mgr_name = mgr_name1
    local function __callback(entity, dbid, err)
        if dbid > 0 then
            log_game_info("create_"..mgr_name.."_success", '')
            entity:RegisterGlobally(mgr_name, basemgr_register_callback(mgr_name, entity:getId()))
        else
            --写数据库失败
            log_game_info("create_"..mgr_name.."_failed", err)
        end
    end
    return __callback
end
function WorldBossMgr:__ctor__()
    log_game_info('WorldBossMgr:__ctor__', '')

    --回调方法
    if self:getDbid() == 0 then
        --首次创建
        self:writeToDB(on_basemgr_saved('WorldBossMgr'))
    else
        self:RegisterGlobally("WorldBossMgr", basemgr_register_callback("WorldBossMgr", self:getId()))
    end
end

--注册globalbase成功后回调方法
function WorldBossMgr:on_registered()
	log_game_debug('WorldBossMgr:on_registered', '1')
    --todo:优化不用存储mb
    self.spaces = {}
    --self.boss = {}

    --self.idleSpaces = {} --空闲的sp
    --self.usedSpaces = {} --使用过的
    --self.lv2Spaces  = {} --正在使用中的，等级对应[lv][map_id] = num

    --[[
    self.bossInfo = {
        maxHp = 0,
    }
    ]]
    --周排名榜
    self.m_weekContribution = {}
    --天排名榜
    self.m_dayContribution = {}

	self.hasTimer = {
		--[0] = __dummy,
	}

    self.sortState = g_wb_config.STATE_UNSORT 
    --血量管理子系统
    --local mosterData = g_monster_mgr:getCfgById(101)
    self.bossHpMgr = BossHpMgr:new(self, g_wb_config.BossBasicHp, g_wb_config.BossHpSynMode, "HpSelfDecrease")
    --刷小怪管理子系统
    self.summoner = Summoner:new(self, g_wb_config.SUMMON_MOD, g_wb_config.SUMMON_SPWAN_LIST, "Summon")

    log_game_debug('WorldBossMgr:on_registered', '2')

	self:EnableWBActivity()
    --预load用户数据
    mogo.loadEntitiesOfType("WorldBossData")
    self:registerTimeSave('mysql') --注册定时存盘
end

function WorldBossMgr:SetDataCount(count)
    self.m_data_count = count

    if self.m_data_count == self.m_data_loaded then
        self:on_data_loaded()
    end
end

function WorldBossMgr:SetData(eid)
    self.m_data_loaded = self.m_data_loaded + 1

    local ad = mogo.getEntity(eid)
    self.m_wbData[ad.avatarDbid] = ad

    if self.m_data_count == self.m_data_loaded then
        self:on_data_loaded()
    end
end

function WorldBossMgr:on_data_loaded()
    for dbid, ad in pairs(self.m_wbData) do
        ad.state = g_wb_config.PLAYER_STATE_OUT
        ad.dayRank = 0
        ad.weekRank = 0
        if ad.weekContribution ~= 0 then
            table.insert(self.m_weekContribution, 
                { id = dbid, 
                  name = ad.name, 
                  contribution = ad.weekContribution })
        end
        if ad.dayContribution ~= 0 then
            table.insert(self.m_dayContribution, 
                { id = dbid, 
                  name = ad.name, 
                  contribution = ad.dayContribution })
        end
    end
    
    -->sort begin  
    --sort
    self:SortDayContribution()
    self:SortWeekContribution()

    for i,v in ipairs(self.m_dayContribution) do
        self.m_wbData[v.id].dayRank = i
    end
    for i,v in ipairs(self.m_weekContribution) do
        self.m_wbData[v.id].weekRank = i
    end

    self.sortState = g_wb_config.STATE_SORTED
    --<sort end
    lua_util.globalbase_call('GameMgr', 'OnMgrLoaded', 'WorldBossMgr')
end

function WorldBossMgr:Init()
    local time = os.time()

    if time >= self.nextDayReTime then
    	if self.nextDayReTime ~= 0 and self.dayRewarded == 0 then
    		--补发漏发奖励
    		self:SendDayRankReward()
    		--
    		self:ResetPerDay()
    	end
        --重置时间
        self.nextDayReTime = time + self:GetUtilNextDayReTime()
    else
    	if self.dayRewarded == 0 and self:IsLastDone() then
    		--补发漏发奖励
			self:SendDayRankReward()
    	end
    end
    if time >= self.nextWeekReTime then
        if self.nextWeekReTime ~= 0 then
            self:ResetPerWeek()
        end
        --重置时间
        self.nextWeekReTime = time + self:GetUtilNextWeekReTime()
    end
    lua_util.globalbase_call('GameMgr', 'OnInited', 'WorldBossMgr')
end

--周排名
function WorldBossMgr:SortWeekContribution()
    if not self.m_weekContribution then return end
    local function gt(a, b)
        return a.contribution > b.contribution
    end
    table.sort(self.m_weekContribution, gt)
end
--天排位
function WorldBossMgr:SortDayContribution()
    if not self.m_dayContribution then return end
    local function gt(a, b)
        return a.contribution > b.contribution
    end
    table.sort(self.m_dayContribution, gt)
end

--重新排位
function WorldBossMgr:ReSort()
    --清除上一次统计的排位
    log_game_info("WorldBossMgr:ReSort", "time[%q]",os.time())
    self.m_weekContribution = {}
    self.m_dayContribution = {}
    
    --更新周统计
    for dbid, ad in pairs(self.m_wbData) do
    	--计算所有人的天贡献harm
    	local ctri = math.ceil(ad.harm / 10)	
        local dayContri = ad.dayContribution + ctri
        local weekContri = ad.weekContribution + ctri
        if dayContri == 0 and weekContri == 0 then
            --todo:destroy data entity
        end
        if dayContri ~= 0 then
            table.insert(self.m_dayContribution, 
                {id = dbid, 
                name = ad.name, 
                contribution = dayContri })
        end
        if weekContri ~= 0 then
            table.insert(self.m_weekContribution, 
                {id = dbid, 
                name = ad.name, 
                contribution = weekContri })
        end
        ad.dayContribution = dayContri
        ad.weekContribution = weekContri
        ad.dayRank = 0
        ad.weekRank = 0
        ad.harm = 0
        ad.enterTimes = 0
    end
    --sort
    self:SortDayContribution()
    self:SortWeekContribution()

    for i,v in ipairs(self.m_dayContribution) do
        self.m_wbData[v.id].dayRank = i
        log_game_debug("WorldBossMgr:ReSort", "dbid = %q, day rank = %d", v.id, i)
    end

    for i,v in ipairs(self.m_weekContribution) do
        self.m_wbData[v.id].weekRank = i
        log_game_debug("WorldBossMgr:ReSort", "dbid = %q, week rank = %d", v.id, i)
    end

    self.sortState = g_wb_config.STATE_SORTED

    if self:IsLastInToday() then
    	--发放当天排名奖励
    	self:SendDayRankReward()
    end
    
	--初始化为未开启状态
	self.state = g_wb_config.STATE_NOT_OPEN
end

--开启入库定时器
function WorldBossMgr:Save()
    --
end

--注册spaceloader, 在创建sp的时候注册
function WorldBossMgr:Register(mapId, spBaseMbStr, spCellMbStr)
    log_game_info("WorldBossMgr:Register", "%s, %s, %s", mapId, spBaseMbStr, spCellMbStr)
	local baseMb = mogo.UnpickleBaseMailbox(spBaseMbStr)
    local cellMb = mogo.UnpickleCellMailbox(spCellMbStr)
    if self.spaces[mapId] then --or self.idleSpaces[mapId] 
        log_game_error("WorldBossMgr:Register", "mutiple register.")
        return
    end
    self.spaces[mapId] = baseMb
    --设置sp.cell的wbmgr
    cellMb.SetWorldBossMgr(mogo.pickleMailbox(self))
    --self.idleSpaces[mapId] = true

end

function WorldBossMgr:AlreadyStart(timer_id, count, mapId, arg2)
    log_game_debug("WorldBossMgr:AlreadyStart", "mapId[%s]", mapId)
    if self.spaces[mapId] then
        --刷boss
        self.spaces[mapId].StartByServer(os.time())
    else
        log_game_error("WorldBossMgr:AlreadyStart", "")
    end
end

--反注册boss,no use
function WorldBossMgr:UnregisterBoss(mapId, eid)
	log_game_info("WorldBossMgr:UnregisterBoss", "")
	
    if self.spaces[mapId] then
		self.spaces[mapId] = nil
    else
        log_game_error("WorldBossMgr:UnregisterBoss","mapId[%s] not exist.", tostring(mapId))
	end
    local num = self.bossHpMgr:Unregister(mapId, eid)
    if num > 0 then
        --log_game_error("WorldBossMgr:UnregisterBoss", "mapId[%s] still has avatar", tostring(mapId))
        --return
    end
    if lua_util.get_table_real_count(self.spaces) == 0 then
        log_game_debug("WorldBossMgr:UnregisterBoss", "UnregisterBoss done.")
    end
end
--mapId:spaceloader的mapid
function WorldBossMgr:RegisterBoss(mapId, spCellMbStr, eid)
    log_game_info("WorldBossMgr:AddTheBoss", "")
    if not self.spaces[mapId] then 
        log_game_error("WorldBossMgr:AddTheBoss", "mapId = %s is illegal.", mapId)
        return
    end

    self.bossHpMgr:Register(mapId, spCellMbStr, eid)
end
--设置一种定时器
function WorldBossMgr:SetTimer(startTime, intervel, tyTimer)
    local timerId= self:addTimer(startTime, intervel, tyTimer)
    if tyTimer == m_timerType.OPEN or
        tyTimer == m_timerType.START or
        tyTimer == m_timerType.END then
        if not self.hasTimer[tyTimer] then
            self.hasTimer[tyTimer] = {}
        end
        table.insert(self.hasTimer[tyTimer], timerId)
    else
        if self.hasTimer[tyTimer] then
            log_game_warning("WorldBossMgr:Init","addTimer self.hasTimer[%d]", tyTimer)
        else
            --加入定时器集合
            self.hasTimer[tyTimer] = timerId
            log_game_debug('WorldBossMgr:Init', 'addTimer %d', tyTimer)
        end
    end
end

--取消一种定时器
function WorldBossMgr:UnsetTimer(tyTimer)
    if not self.hasTimer[tyTimer] then return end
    if tyTimer == m_timerType.OPEN or
        tyTimer == m_timerType.START or
        tyTimer == m_timerType.END then
        for k,v in pairs(self.hasTimer[tyTimer]) do
            self:delTimer(v)
        end
    else
        self:delTimer(self.hasTimer[tyTimer])
    end
    self.hasTimer[tyTimer] = nil
end

--开放
function WorldBossMgr:Open()
	log_game_debug("WorldBossMgr:Open", 'open : %s', tostring(os.time()))

    if self.state ~= g_wb_config.STATE_NOT_OPEN then return end
	--test
    --[[
    for mapId, spBaseMb in pairs(self.spaces) do
        log_game_error("WorldBossMgr:Open", 'Open mapId[%s]', tostring(mapId))
	end
    ]]
	--self.lv2Spaces = {}
    self.state = g_wb_config.STATE_OPEN

    if self.hasTimer[m_timerType.GM_OPEN] then
        --注册定时开始器
        self.hasTimer[m_timerType.GM_OPEN] = nil
        log_game_debug("WorldBossMgr:GMOpen", "delete GM_OPEN : %s", tostring(os.time()))
    end
end
--开始
function WorldBossMgr:Start()
    log_game_debug("WorldBossMgr:Start",'')
    if self.state ~= g_wb_config.STATE_OPEN then
        --self:Open()
        log_game_error("WorldBossMgr:Start", "not open.")
        return
    end
    --设置已经开始状态
    self.state = g_wb_config.STATE_START
    --启动boss血量管理器
    self.bossHpMgr:Start()
    self.summoner:Start()

    local start = os.time()
    for mapId, spBaseMb in pairs(self.spaces) do
        --todo:通知刷boss
        --SpaceLoader.SpawnPointEvent(mission_config.SPAWNPOINT_START, self.ptr.theOwner.map_x, self.ptr.theOwner.map_y, SpawnPointId)
        spBaseMb.StartByServer(start)

    end

    if self.hasTimer[m_timerType.GM_START] then
        --注册定时开始器
        self.hasTimer[m_timerType.GM_START] = nil
        log_game_debug("WorldBossMgr:GMOpen", "delete GM_START")
    end
    if not self.hasTimer[m_timerType.SYN] then
        self:SetTimer(g_wb_config.SYN_INTERVEL, g_wb_config.SYN_INTERVEL, m_timerType.SYN)
    end
    local mm = globalBases['UserMgr']
    mm.SanctuaryStart()
end

function WorldBossMgr:IsLastInToday()
	local t = os.time()
	for k,v in pairs(self.nextStartTime) do
		if lua_util.is_same_day(t, v) then
			return false
		end
	end
	return true
end

--关闭
function WorldBossMgr:Stop()
	log_game_debug("WorldBossMgr:Stop", '%d',os.time())
    --for mapId, spBaseMb in pairs(self.spaces) do
        --todo:sp:stop
        --SpaceLoader.SpawnPointEvent(mission_config.SPAWNPOINT_STOP, self.ptr.theOwner.map_x, self.ptr.theOwner.map_y, SpawnPointId)

    --end
    if self.state == g_wb_config.STATE_STOP or self.state == g_wb_config.STATE_NOT_OPEN then
        log_game_error("WorldBossMgr:Stop", "")
        return
    end

    if self.state ~= g_wb_config.STATE_START then
        log_game_warning("WorldBossMgr:Stop", "already stop. boss die.")
        return
    end
    self.bossHpMgr:Stop()
    self.summoner:Stop()

    for mapId, spBaseMb in pairs(self.spaces) do
        --todo:
        spBaseMb.KickAllPlayer()

    end
    --重置当前使用的场景
    self.state = g_wb_config.STATE_STOP

    --正在排位中
    self:addLocalTimer("ReSort", 5000, 1) --5s后计算，避开高峰值
    --self:addLocalTimer("StopSpaceLoader", 600000, 1) --10min后计算，避开高峰值
    self.sortState = g_wb_config.STATE_SORTING

    --[[
    local time = os.time()
    local wdate = os.date("*t", time)
    wdate.hour = g_wb_config.WorldBossTimeStart[1]
    wdate.sec = 0
    wdate.min = g_wb_config.WorldBossTimeStart[2]
    local tt = os.time(wdate)

    local startTime = tt
    while startTime < time do
        startTime = startTime + g_wb_config.WorldBossTimeIntervel
    end

    startTime = startTime -  time
    local openTime = startTime
    if startTime < g_wb_config.PRE_OPEN_TIME then
        openTime = 1
        if startTime < 1 then
            startTime = 2
        end
    else
        openTime = startTime - g_wb_config.PRE_OPEN_TIME
    end
    ]]
    if self.hasTimer[m_timerType.GM_END] then
        --注册定时开始器
        self.hasTimer[m_timerType.GM_END] = nil
        log_game_debug("WorldBossMgr:Stop", "delete GM_END")
        self:EnableWBActivity()
    else
    	self:ResetSomething()
    end
    self:UnsetTimer(m_timerType.SYN)
    --reset
    self.spaces = {}

    log_game_debug("WorldBossMgr:Stop",'nextOpenTime=%s, nextStartTime=%s, nextEndTime=%s',
        mogo.cPickle(self.nextOpenTime),mogo.cPickle(self.nextStartTime),mogo.cPickle(self.nextEndTime))
end

function WorldBossMgr:IsLastDone()
	--下一次天重置时间点
	local t = os.time() + self:GetUtilNextDayReTime()
	for k,v in pairs(self.nextStartTime) do
		if t > v then
			return false
		end
	end
	return true
end

--重置数据
function WorldBossMgr:ResetPerDay()
	local t = os.time()
    log_game_debug("WorldBossMgr:ResetPerDay", "time = %d", t)
    --重置当上一次的统计
    for _, ad in pairs(self.m_wbData) do
        ad.buyTimes = 0
        ad.dayContribution = 0
        --设置状态
        --ad.state = g_wb_config.PLAYER_STATE_OUT
        ad.dayRank = 0
    end
    self.dayRewarded = 0
    self.nextDayReTime = t + self:GetUtilNextDayReTime()
    self.m_dayContribution = {}
end

--周重置
function WorldBossMgr:ResetPerWeek()
    log_game_debug("WorldBossMgr:ResetPerWeek", "time = %d", os.time())
    self:SendWeekRankReward()
    --重置当上一次的统计
    for _, ad in pairs(self.m_wbData) do
        --自动补发
        self:SendWeekContributionReward(ad)
        ad.weekContribution = 0
        ad.weekRank = 0
        ad.recvReward = {}
        ad.weekLevel = ad.level
    end
    self.nextWeekReTime = os.time() + self:GetUtilNextWeekReTime()
    self.m_weekContribution = {}
end

function WorldBossMgr:SendWeekContributionReward(ad)
    local cfg = g_sanctuary_defense_mgr:GetWeekContributionByLv(ad.weekLevel)
    if cfg then
        for _,cf in pairs(cfg) do
            --mail
            if not ad.recvReward[cf.id] and cf.contribution <= ad.weekContribution then
                local re = {}
                if cf.exp and cf.exp > 0 then
                    re[public_config.EXP_ID]  = cf.exp
                end
                if cf.gold and cf.gold > 0 then
                    re[public_config.GOLD_ID] = cf.gold
                end
                if next(re) then
                    lua_util.globalbase_call('MailMgr','SendIdEx',cf.mailTitle,ad.name,
                        cf.mailText,cf.mailFrom,os.time(),re,{ad.avatarDbid},{},reason_def.wb_contribution)
                end
                ad.recvReward[cf.id] = 1
            end
        end
    else
        log_game_error("WorldBossMgr:SendWeekContributionReward","%d",ad.weekLevel)
    end
end

local function is_in(t, i)
	if not t then return false end
    for _,v in pairs(t) do
        if i == v then return true end
    end
    return false
end

--定时器
function WorldBossMgr:onTimer( timer_id, user_data )
    if is_in(self.hasTimer[m_timerType.OPEN], timer_id) or timer_id == self.hasTimer[m_timerType.GM_OPEN] then
        self:Open()
    elseif is_in(self.hasTimer[m_timerType.START], timer_id) or timer_id == self.hasTimer[m_timerType.GM_START] then
        self:Start()
    elseif is_in(self.hasTimer[m_timerType.END], timer_id) or timer_id == self.hasTimer[m_timerType.GM_END] then
        self:Stop()
    elseif timer_id == self.hasTimer[m_timerType.WEEK] then
        self:ResetPerWeek()
    elseif timer_id == self.hasTimer[m_timerType.SYN] then
        self:BroadcastPlayerInfo()
    elseif timer_id == self.hasTimer[m_timerType.DAY] then
    	self:ResetPerDay()
    else
        log_game_warning("WorldBossMgr:onTimer","unknown timer = %d",timer_id)
    end
end

--获取玩家信息
function WorldBossMgr:GetPlayerInfo(dbid)
    return self.m_wbData[dbid]
end
--玩家申请进入的返回
function WorldBossMgr:OnEnter(mb, err)
    --log_game_debug("WorldBossMgr:OnEnter", tostring(err))
    --mb.client.ShowText(CHANNEL.TIPS, tostring(err))
    mb.client.EnterSanctuaryDefenseResp(err)
end
--进入世界boss活动
function WorldBossMgr:Enter(mbStr, dbid, name, level, viplevel)
    log_game_debug("WorldBossMgr:Enter", "name = %s", name)
    --是否开启
    local mb = mogo.UnpickleBaseMailbox(mbStr)
    if self.state == g_wb_config.STATE_NOT_OPEN or self.state == g_wb_config.STATE_STOP then
        self:OnEnter(mb, error_code.ERR_WB_ENTER_NOT_OPEN)
        mb.client.ShowTextID(CHANNEL.TIPS, g_text_id.WB_ENTER_NOT_OPEN)
        return
    end
    local lv = lGetLv(level)
    log_game_debug("WorldBossMgr:Enter", "lv = %d", lv)
    --等级不够
    if lv < 1 then
        self:OnEnter(mb, error_code.ERR_WB_ENTER_LV)
        mb.client.ShowTextID(CHANNEL.TIPS, g_text_id.WB_ENTER_LV)
        return
    end
    --check vip level 
    local vipCfg = g_vip_mgr:GetVipPrivileges(viplevel)
    if viplevel ~= 0 and not vipCfg then
        self:OnEnter(mb, error_code.ERR_WB_ENTER_VIP)
        return
    end
    local ad = self:GetPlayerInfo(dbid)
    if ad then
        --进入次数检查
        local canEnterTime = g_wb_config.ENTER_TIME_PER_DAY + ad.buyTimes
        if ad.enterTimes >= canEnterTime then
            self:OnEnter(mb, error_code.ERR_WB_ENTER_TIME)
            mb.client.ShowTextID(CHANNEL.TIPS, g_text_id.WB_ENTER_TIME)
            return
        end
        --状态检查
        if ad.state ~= g_wb_config.PLAYER_STATE_OUT then
            self:OnEnter(mb, error_code.ERR_WB_ENTER_STATE)
            mb.client.ShowTextID(CHANNEL.TIPS, g_text_id.WB_ENTER_STATE)
            return
        end
    end
--[[
    local scene_line
    --local needInit = 0
    --todo:find map_id
    --优先在已有的分线里找合适的分线

    if self.lv2Spaces[lv] then
        for mapId, num in pairs(self.lv2Spaces[lv]) do
            if num < public_config.NUM_PLAYER_PER_MAP then
                self.lv2Spaces[lv][mapId] = num + 1
                scene_line = lua_util.split_str(mapId, "_", tonumber)
                break
            end
        end
    else
        self.lv2Spaces[lv] = {}
    end

    if not scene_line then
        local b = 0
        for mapId,_ in pairs(self.usedSpaces) do
            for _lv, v in pairs(self.lv2Spaces) do
                if v[mapId] then
                    if lv == _lv and v[mapId] < public_config.NUM_PLAYER_PER_MAP then
                        self.lv2Spaces[_lv][mapId] = self.lv2Spaces[_lv][mapId] + 1
                        log_game_debug("WorldBossMgr:Enter 1", "use usedSpaces mapId = %s, num = %d", mapId, self.lv2Spaces[lv][mapId])
                        scene_line = lua_util.split_str(mapId, "_", tonumber)
                        b = 1
                    else
                        b = 2
                    end
                    break
                end
            end

            if b == 1 then
                --can use the using sp
                break
            elseif b == 0 then
                --no using
                self.lv2Spaces[lv][mapId] = 1
                log_game_debug("WorldBossMgr:Enter 2", "use usedSpaces mapId = %s, num = %d", mapId, self.lv2Spaces[lv][mapId])
                scene_line = lua_util.split_str(mapId, "_", tonumber)
                --needInit = mapId
                break
            else
                --can not use the using sp
                --continue
            end
        end
    end

    --self.idleSpaces[mapId]
    if not scene_line then
        for mapId, mb in pairs(self.idleSpaces) do
            if self.lv2Spaces[lv][mapId] then
                log_game_error("WorldBossMgr:Enter", "lv2Spaces use illegal mapId = %s", mapId)
                self.lv2Spaces[lv][mapId] = self.lv2Spaces[lv][mapId] + 1
            else
                self.lv2Spaces[lv][mapId] = 1
            end
            if self.usedSpaces[mapId] then
                log_game_error("WorldBossMgr:Enter", "usedSpaces use illegal mapId = %s", mapId)
            else
                self.usedSpaces[mapId] = mb
            end
            scene_line = lua_util.split_str(mapId, "_", tonumber)
            --needInit = mapId
            --把空闲的标识已经使用
            self.idleSpaces[mapId] = nil
            break
        end
    end

    if not scene_line then
        log_game_error("WorldBossMgr:Enter", "no scene_line enough.")
        self:OnEnter(mb, error_code.ERR_WB_ENTER_FULL)
        mb.client.ShowTextID(CHANNEL.TIPS, g_text_id.WB_ENTER_FULL)
        return
    end
]]
    local scene = lGetMapId(lv)
    if not scene then
        log_game_error("WorldBossMgr:Enter", "no scene_line enough.")
        self:OnEnter(mb, error_code.ERR_WB_ENTER_FULL)
        mb.client.ShowTextID(CHANNEL.TIPS, g_text_id.WB_ENTER_FULL)
        return
    end
    log_game_debug("WorldBossMgr:Enter", "%s, enter %d.", name, scene)
    --初始化玩家数据
    if not ad then
        ad = self:NewPlayerInfo(dbid, name, level)
    end
    --设置状态:正在进入
    ad.state = g_wb_config.PLAYER_STATE_ENTERING
    --进入切换场景
    local mm = globalBases['MapMgr'] 
    --mm.SelectMapReq(mbStr, scene_line[1], scene_line[2], dbid, name)
    mm.SelectMapReq(mbStr, scene, 0, dbid, name, {})

    log_game_debug("WorldBossMgr:Enter", mogo.cPickle(self.spaces))
    self:OnEnter(mb, error_code.ERR_WB_ENTER_SUCCESS)
    mb.client.ShowTextID(CHANNEL.TIPS, g_text_id.WB_ENTER_SUCCESS)
end

local function data_callback(ad, dbid, err)
    if dbid == 0 then
        log_game_warning("WorldBossMgr", "data_callback_err")
    end
end

--新增一个玩家的信息
function WorldBossMgr:NewPlayerInfo(dbid, name, level)
    if self.m_wbData[dbid] then
        log_game_error('WorldBossMgr:NewPlayerInfo', 'dbid = %q', dbid)
        return
    end

    local ad = mogo.createBase('WorldBossData', {
        avatarDbid=dbid,
        name = name,
        dayContribution = 0,
        weekContribution = 0,
        recvReward = {},
        enterTimes = 0,
        buyTimes = 0,
        })
    ad:writeToDB(data_callback)
    self.m_wbData[dbid] = ad
    --初始化不存库的信息
    ad.state = g_wb_config.PLAYER_STATE_OUT
    ad.dayRank = 0
    ad.weekRank = 0
    ad.level = level
    ad.weekLevel = level
    ad.harm = 0
    return ad
end

function WorldBossMgr:GetMissonId(lv)
    return lGetMapId(lv)
end
--[[
function WorldBossMgr:GetBossSpawnPoitId()
    return 99
end
]]
--成功进入活动场景后
function WorldBossMgr:EnterResp(dbid, name, level, imap_id, mbStr, errId)
    log_game_debug("WorldBossMgr:EnterResp", "imap_id = %s", imap_id)
    if not g_map_mgr:IsWBMap(imap_id) then
        return
    end
    local lv = lGetLv(level)
    local ad = self:GetPlayerInfo(dbid)
    if not ad then
        return
    end
    if errId == 0 then
        --进入次数累加
        ad.enterTimes = ad.enterTimes + 1
        --设置状态:正在进入
        ad.state = g_wb_config.PLAYER_STATE_IN_LIVE
        ad.level = level
        --设置场景信息
        log_game_debug("WorldBossMgr:EnterResp", "SetMissionInfo")
        --self.spaces[imap_id].SetMissionInfo(dbid, name, mbStr, self:GetMissonId(lv), lv)
        if self.spaces[imap_id] then
            self.spaces[imap_id].SetMissionInfo(dbid, name, mbStr, self:GetMissonId(lv), 1)
            --如果已经打开
            if self.state == g_wb_config.STATE_OPEN then
                --baseMb.Open()
            --如果已经开始
            elseif self.state == g_wb_config.STATE_START then
                --baseMb.Open()
                self:addLocalTimer("AlreadyStart", 2000, 1, imap_id) --2s后
                --baseMb.StartByServer(os.time())
            else
                log_game_error("WorldBossMgr:Register", "")
            end
        else
            log_game_error("WorldBossMgr:EnterResp", "")
        end
    else
        log_game_warning("WorldBossMgr:EnterResp", "enter failed.")
        --设置状态:out
        ad.state = g_wb_config.PLAYER_STATE_OUT
        --回滚正在被使用的map的人数
        --[[
        if self.lv2Spaces[lv][imap_id] then
            self.lv2Spaces[lv][imap_id] = self.lv2Spaces[lv][imap_id] - 1
            if self.lv2Spaces[lv][imap_id] < 0 then
                log_game_error("WorldBossMgr:EnterResp", 'num < 0')
                self.lv2Spaces[lv][imap_id] = 0 
            end
        else
            log_game_error("WorldBossMgr:EnterResp", 'not found imap_id = %s', imap_id)
        end
        ]]
    end
    --log_game_debug("WorldBossMgr:EnterResp", mogo.cPickle(self.lv2Spaces))
end

function WorldBossMgr:BossDie( killerMbStr )
	log_game_debug("WorldBossMgr:BossDie", "")
    self:Stop()
end

--sp.cell交互接口, 更新boss血量
function WorldBossMgr:UpdateBossHp(playerId, harm)
    --print("UpdateBossHp===================" .. tostring(playerId) .. tostring(harm))
    --log_game_debug("WorldBossMgr:UpdateBossHp", "playerId[%d], damage[%d]", playerId, harm)
    local ad = self:GetPlayerInfo(playerId)
    if not ad then
        log_game_error("WorldBossMgr:UpdateBossHp", "")
        return
    end
    local lv = ad.level
    --更新伤害与等级系数的统计
    ad.harm = ad.harm + harm--lHarm2Contribution(harm, lv)
    self.bossHpMgr:UpdateHp(playerId, harm, g_wb_config.HP_DEL_MOD)
end

--
function WorldBossMgr:SynByTimer(timerId, count, arg1, arg2)
    self.bossHpMgr:SynByTimer()
end

--[[直接在avatar上推出,即退出关卡
function WorldBossMgr:Exit(mbStr, dbid, name)
    log_game_debug("MissionSystem:ExitMission", "dbid=%q;name=%s", self.ptr.theOwner.dbid, self.ptr.theOwner.name)

    --通知玩家离开副本
    local mm = globalBases['MapMgr'] 
    if mm then
        mm.SelectMapReq(mbStr, g_GlobalParamsMgr:GetParams('init_scene', 10004), 0, dbid, name)
    end
end
]]

--周排名奖励发放
function WorldBossMgr:SendWeekRankReward()
    --发放周排名奖励
    local mail = globalBases["MailMgr"]
    if not mail then
        log_game_error("WorldBossMgr:SendWeekRankReward", "")
        return
    end
    --SendId(titleId, to, textId, fromId, time, attachment, dbids)
    local time = os.time()
    for rank, wInfo in ipairs(self.m_weekContribution) do
        local reward = g_sanctuary_defense_mgr:GetWeekRankReward(rank)
        if not reward then break end
        local attachment = {}
        if reward.exp and reward.exp > 0 then
            attachment[public_config.EXP_ID] = reward.exp
        end
        if reward.gold and reward.gold > 0 then
            attachment[public_config.GOLD_ID] = reward.gold
        end
        if reward.items then
            for k,v in pairs(reward.items) do
                attachment[k] = v
            end
        end

        log_game_debug("WorldBossMgr:SendWeekRankReward", "dbid = %q, reward = %s", wInfo.id,mogo.cPickle(reward))
        --mail.SendId(reward.mailTitle, wInfo.name, reward.mailText, 
            --reward.mailFrom, time, attachment, {wInfo.id}, {tostring(rank)})
        mail.SendIdEx(reward.mailTitle, wInfo.name, reward.mailText, 
            reward.mailFrom, time, attachment, {wInfo.id}, {tostring(rank)}, reason_def.wb_week_rank)
    end
end

--当次活动排名奖励
function WorldBossMgr:SendDayRankReward()
	if self.dayRewarded > 0 then return end
    local mail = globalBases["MailMgr"]
    if not mail then
        log_game_error("WorldBossMgr:SendDayRankReward", "")
        return
    end
    --SendId(titleId, to, textId, fromId, time, attachment, dbids)
    local time = os.time()
    for rank, dInfo in ipairs(self.m_dayContribution) do
        local reward = g_sanctuary_defense_mgr:GetDayRankReward(rank)
        if not reward then break end
        local attachment = {}
        if reward.exp and reward.exp > 0 then
            attachment[public_config.EXP_ID] = reward.exp
        end
        if reward.gold and reward.gold > 0 then
            attachment[public_config.GOLD_ID] = reward.gold
        end
        if reward.items then
            for k,v in pairs(reward.items) do
                attachment[k] = v
            end
        end
        --log_game_debug("WorldBossMgr:SendDayRankReward", "dbid = %q, reward = %s", dInfo.id,mogo.cPickle(reward))
        --mail.SendId(reward.mailTitle, dInfo.name, reward.mailText, 
            --reward.mailFrom, time, attachment, {dInfo.id}, {tostring(rank)})
        mail.SendIdEx(reward.mailTitle, dInfo.name, reward.mailText, 
            reward.mailFrom, time, attachment, {dInfo.id}, {tostring(rank)}, reason_def.wb_day_rank)
    end
    self.dayRewarded = 1
end

--周累积奖励发放
--[[
function WorldBossMgr:SendWeekContributionReward(dbid)
    --log_game_debug("WorldBossMgr:SendWeekContributionReward", "dbid = %q", dbid)
    local ad = self.m_wbData[dbid]
    if not ad then return end
    local lv = ad.recvReward
    --至今为止周贡献
    local contri = ad.weekContribution + math.ceil(ad.harm / 10)
    local rewards, lv_up = g_sanctuary_defense_mgr:GetWeekContributionReward(contri, lv)
    if not rewards or not lv_up or lv_up == lv then return end
    --log_game_debug("WorldBossMgr:SendWeekContributionReward", "rewards = %s, lv_up = %d", mogo.cPickle(rewards), lv_up)
    --改为统一由在线管理器去发送，（不在线直接用邮箱发放）
    local mm = globalBases['UserMgr']
    if not mm then
        log_game_error("WorldBossMgr:SendWeekContributionReward", "")
        return
    end
    --log_game_debug("WorldBossMgr:SendWeekContributionReward", "dbid = %q, lv_up = %d", dbid, lv_up)
    mm.SendSDRewards(rewards, dbid, ad.weekRank)
    --记录已领取至的级别
    ad.recvReward = lv_up
end
]]

--玩家离开世界boss场景
function WorldBossMgr:PlayerLeave(dbid)
    --log_game_debug("WorldBossMgr:PlayerLeave", "")
    local ad = self:GetPlayerInfo(dbid)
    if not ad then
        return
    end
    if ad.state == g_wb_config.PLAYER_STATE_OUT then
        return
    end
    --重置状态
    ad.state = g_wb_config.PLAYER_STATE_OUT

    --把伤害转成贡献值
    --ad.dayContribution = math.ceil(ad.harm / 10000)
    --log_game_debug("WorldBossMgr:PlayerLeave", "dbid[%q] day contribution [%q]", dbid, ad.dayContribution)
    --self:SendWeekContributionReward(dbid)
end

--领取奖励
function WorldBossMgr:GetWeekCtrbuRewardReq(mb_str,dbid,id)
    local ad = self.m_wbData[dbid]
    if not ad then return end
    local rew = g_sanctuary_defense_mgr:GetWeekContributionReward(id)
    if not rew then
        return lua_util.mailbox_client_call(mb_str,"ShowTextID",CHANNEL.TIPS,g_text_id.WB_CTRBU_REWARD_ID)
    end
    if rew.level[1] > ad.weekLevel or rew.level[2] < ad.weekLevel then
        return lua_util.mailbox_client_call(mb_str,"ShowTextID",CHANNEL.TIPS,g_text_id.WB_CTRBU_REWARD_LV)
    end
    if ad.recvReward[id] then
        return lua_util.mailbox_client_call(mb_str,"ShowTextID",CHANNEL.TIPS,g_text_id.WB_CTRBU_REWARD_ED)
    end
    if rew.contribution > ad.weekContribution then
        return lua_util.mailbox_client_call(mb_str,"ShowTextID",CHANNEL.TIPS,g_text_id.WB_CTRBU_REWARD_LE)
    end
    ad.recvReward[id] = 1
    local rewards = 
    {
        [public_config.EXP_ID]  = rew.exp,
        [public_config.GOLD_ID] = rew.gold,   
    }
    --领取奖励
    lua_util.mailbox_call(mb_str,"OnWorldBossWeekCtrbuRewardResp",id,rewards)
    local cfg = g_sanctuary_defense_mgr:GetWeekContributionByLv(ad.weekLevel)
    if not cfg then
        log_game_error("WorldBossMgr:GetWeekCtrbuRewardReq","%d",ad.weekLevel)
        return
    end
    local recved = {}
    for k,_ in pairs(ad.recvReward) do
        table.insert(recved,k)
    end
    --刷新数据
    lua_util.mailbox_client_call(mb_str,'SanctuaryDefenseMyInfoResp',ad.dayContribution,ad.weekContribution,ad.weekLevel,recved)
end

--广播玩家信息
function WorldBossMgr:BroadcastPlayerInfo()
    --log_game_debug("WorldBossMgr:BroadcastPlayerInfo", "")
    if self.state ~= g_wb_config.STATE_START then
        --log_game_error("WorldBossMgr:BroadcastPlayerInfo", "not start.")
        return
    end
    --整理排名
    local min = 1 --bc_info index
    local bc_info = {
                        --[1] = {name = '', contribution = 0} ,
                        --[2] = {name = '', contribution = 0} ,
                        --[3] = {name = '', contribution = 0} , 
                    }
    for i=1,g_wb_config.BC_NUM do
        bc_info[i] = {name = '', contribution = 0}
    end
    local function find_min(t)
        local n = 1
        for i=2, g_wb_config.BC_NUM do
            if t[i].contribution < t[n].contribution then
                n = i 
            end
        end
        return n
    end
    for dbid, ad in pairs(self.m_wbData) do
        if ad.harm > bc_info[min].contribution then
            bc_info[min].name = ad.name
            bc_info[min].contribution = ad.harm
            min = find_min(bc_info)
        end
    end
    local function gt(a, b)
        return a.contribution > b.contribution
    end
    table.sort(bc_info, gt)
    local b = true
    for i, v in ipairs(bc_info) do
        if v.contribution == 0 then
            bc_info[i] = nil
        else
            v.contribution = math.ceil(v.contribution / 10)
            b = false
        end
    end
    --log_game_debug("WorldBossMgr:BroadcastPlayerInfo bc_info", mogo.cPickle(bc_info))
    if b then
--        log_game_debug("WorldBossMgr:BroadcastPlayerInfo", "not broadcast ...") 
        return 
    end
    --log_game_debug("WorldBossMgr:BroadcastPlayerInfo spaces", mogo.cPickle(self.spaces))
    --[[
    for lv, mapids in pairs(self.lv2Spaces) do
        for map_id, num in pairs(mapids) do
            if num > 0 then
                log_game_debug("WorldBossMgr:BroadcastPlayerInfo", map_id)
                self.spaces[map_id].UpdateWBRankList(bc_info)
            end
        end
    end
    ]]
    for mapId, mb in pairs(self.spaces) do
        mb.UpdateWBRankList(bc_info)
    end
end

--获取排名相关信息
function WorldBossMgr:GetRankingList(mbStr, dbid)
    --log_game_debug("WorldBossMgr:GetRankingList", "dbid = %q", dbid)
    --if self.state == 0 then return end
    --g_wb_config.SHOW_TOP_N
    --log_game_debug("WorldBossMgr:GetRankingList", mogo.cPickle(self.m_weekContribution))
    --log_game_debug("WorldBossMgr:GetRankingList", mogo.cPickle(self.m_dayContribution))
    local w = {}
    local d = {}
    for i=1,g_wb_config.SHOW_TOP_N do
        if self.m_weekContribution[i] then
            w[i] = {}
            w[i].name = self.m_weekContribution[i]['name']
            w[i].contribution = self.m_weekContribution[i]['contribution']
        end
        if self.m_dayContribution[i] then
            d[i] = {}
            d[i].name = self.m_dayContribution[i]['name']
            d[i].contribution = self.m_dayContribution[i]['contribution']
        end
    end
    local wr = 0
    local dr = 0
    local ad = self.m_wbData[dbid]
    if ad then
        dr = ad.dayRank
        wr = ad.weekRank
    end

    local mb = mogo.UnpickleBaseMailbox(mbStr)
    if mb then
        --下发客户端数据
        --log_game_debug("WorldBossMgr:GetRankingList", "send data w = %s, d = %s", mogo.cPickle(w), mogo.cPickle(d))
        --log_game_debug("WorldBossMgr:GetRankingList", "send data wr = %d, dr = %d", wr, dr)

        mb.client.SanctuaryDefenseRankResp(w, d, wr, dr)
    end
end

--获取我的信息
--[[
function WorldBossMgr:GetMyInfo(mbStr, dbid)
    local lv = 0
    local myInfo = 
    {
        weekContribution = 0,
        dayContribution = 0,
        nextLvNeedContribution = 0,
    }
    local ad = self.m_wbData[dbid]
    if ad then
        myInfo.weekContribution = ad.weekContribution
        myInfo.dayContribution = ad.dayContribution
        lv = ad.recvReward
    end
    local cfg = g_sanctuary_defense_mgr:GetNeedWeekContribution(lv + 1)
    if cfg then
        myInfo.nextLvNeedContribution = cfg.contribution
    end
    local mb = mogo.UnpickleBaseMailbox(mbStr)
    if mb then
        --下发客户端数据
        --log_game_debug("WorldBossMgr:GetMyInfo", mogo.cPickle(myInfo))
        mb.client.SanctuaryDefenseMyInfoResp(myInfo)
    end
end
]]
function WorldBossMgr:GetMyInfo(mbStr,dbid,name,level)
    local ad = self.m_wbData[dbid]
    if not ad then
        ad = self:NewPlayerInfo(dbid, name, level)
    end
    --兼容旧的数据
    if ad.weekLevel < 21 then
        ad.weekLevel = level
    end
    local cfg = g_sanctuary_defense_mgr:GetWeekContributionByLv(ad.weekLevel)
    if not cfg then
        log_game_error("WorldBossMgr:GetMyInfo","%d",ad.weekLevel)
        return
    end
    local mb = mogo.UnpickleBaseMailbox(mbStr)
    if mb then
        --下发客户端数据
        --log_game_debug("WorldBossMgr:GetMyInfo", mogo.cPickle(myInfo))
        local recved = {}
        for k,_ in pairs(ad.recvReward) do
            table.insert(recved,k)
        end
        mb.client.SanctuaryDefenseMyInfoResp(ad.dayContribution,ad.weekContribution,ad.weekLevel,recved)
    end
end

local function _min(t)
    local min = t[1]
    for _,v in pairs(t) do
        if min > v then
            min = v
        end
    end
    return min
end

--下次开启时间
function WorldBossMgr:GetNextStartTime(mbStr, dbid)
    local openTime = 0
    local endTime = 0
    local time = os.time()
    local tt = _min(self.nextOpenTime)
    if tt > time then
        openTime = tt - time
    end
    tt = _min(self.nextEndTime)
    if tt > time then
        endTime = tt - time
    end
    local canEnterTime = g_wb_config.ENTER_TIME_PER_DAY
    local ad = self.m_wbData[dbid]
    if ad then
        canEnterTime = canEnterTime - ad.enterTimes
    end
    if canEnterTime < 0 then
        canEnterTime = 0
    end
    local mb = mogo.UnpickleBaseMailbox(mbStr)
    if mb then
        --下发客户端数据
        --log_game_debug("WorldBossMgr:GetNextStartTime", "openTime[%d], canEnterTime[%d] ", openTime, canEnterTime)
        if endTime <= openTime or endTime == 0 then
            log_game_debug("WorldBossMgr:GetNextStartTime", "openTime[%d], endTime[%d] ", openTime, endTime)
        end
        mb.client.SanctuaryDefenseTimeResp(openTime, canEnterTime, endTime)
    end
end

--购买进入次数
function WorldBossMgr:BuyEnterTimeReq(mbStr, dbid, viplevel)
    local mb = mogo.UnpickleBaseMailbox(mbStr)
    local ad = self.m_wbData[dbid]
     if not ad then
        log_game_warning("WorldBossMgr:BuyEnterTime", "no dbid[%d] m_wbData.", dbid)
        --mb.OnSanctuaryDefenseBuy(error_code.ERR_WB_BUY_NO_NEED, 0, 0)
        mb.client.ShowTextID(CHANNEL.TIPS, g_text_id.WB_BUY_NO_NEED)
        return
    end
    if ad.enterTimes < g_wb_config.ENTER_TIME_PER_DAY then
        log_game_warning("WorldBossMgr:BuyEnterTime", "dbid[%d] no need buy.", dbid)
        --mb.OnSanctuaryDefenseBuy(error_code.ERR_WB_BUY_NO_NEED, 0, 0)
        mb.client.ShowTextID(CHANNEL.TIPS, g_text_id.WB_BUY_NO_NEED)
        return
    end

    --vip info
    local vipCfg = g_vip_mgr:GetVipPrivileges(viplevel)
    if not vipCfg then
        log_game_error("WorldBossMgr:BuyEnterTime", "dbid[%d] viplevel is illegal.", dbid)
        return
    end
    local canBuyTimes = vipCfg.canBuyEnterSDTimes
    if not canBuyTimes then
        log_game_error("WorldBossMgr:BuyEnterTime", "no vipCfg.canBuyEnterSDTimes.")
        return
    end
    if ad.buyTimes >= canBuyTimes then
        mb.OnSanctuaryDefenseBuy(error_code.ERR_WB_BUY_FULL, 0, 0)
        mb.client.ShowTextID(CHANNEL.TIPS, g_text_id.WB_BUY_FULL)
        return
    end

    local nextTimes = ad.buyTimes + 1
    local price = g_sanctuary_defense_mgr:GetBuyEnterPrice(nextTimes)
    if not price then
        log_game_error("WorldBossMgr:BuyEnterTime", "no g_sanctuary_defense_mgr.price. nextTimes = %d", nextTimes)
        return
    end
    log_game_debug("WorldBossMgr:BuyEnterTime", "price.diamond[%d], price.gold[%d]", price.diamond, price.gold)
    mb.OnSanctuaryDefenseBuy(error_code.ERR_WB_BUY_CAN, price.diamond, price.gold)
end

function WorldBossMgr:AddBuyTime(mbStr, dbid, name, level, viplevel)
    local ad = self.m_wbData[dbid]
     if not ad then
        log_game_warning("WorldBossMgr:AddBuyTime", "no dbid[%d] m_wbData.", dbid)
        --mb.OnSanctuaryDefenseBuy(error_code.ERR_WB_BUY_NO_NEED, 0, 0)
        return
    end
    ad.buyTimes =  ad.buyTimes + 1
    self:Enter(mbStr, dbid, name, level, viplevel)
end

--可购买信息
function WorldBossMgr:CanBuyEnterInfo(mbStr, dbid, viplevel)
    --CanBuySanctuaryDefenseTimeResp
    local mb = mogo.UnpickleBaseMailbox(mbStr)
    local ad = self.m_wbData[dbid]
    if not ad then
        log_game_warning("WorldBossMgr:CanBuyEnterInfo", "no dbid[%d] m_wbData.", dbid)
        mb.client.CanBuySanctuaryDefenseTimeResp(error_code.ERR_WB_BUY_NO_NEED, 0, 0)
        return
    end
    if ad.enterTimes < g_wb_config.ENTER_TIME_PER_DAY then
        log_game_warning("WorldBossMgr:CanBuyEnterInfo", "dbid[%d] no need buy.", dbid)
        mb.client.CanBuySanctuaryDefenseTimeResp(error_code.ERR_WB_BUY_NO_NEED, 0, 0)
        return
    end

    --vip info
    local vipCfg = g_vip_mgr:GetVipPrivileges(viplevel)
    if not vipCfg then
        log_game_error("WorldBossMgr:CanBuyEnterInfo", "dbid[%d] viplevel is illegal.", dbid)
        return
    end
    local canBuyTimes = vipCfg.canBuyEnterSDTimes
    if not canBuyTimes then
        log_game_error("WorldBossMgr:CanBuyEnterInfo", "no vipCfg.canBuyEnterSDTimes.")
        return
    end
    if ad.buyTimes >= canBuyTimes then
        mb.client.CanBuySanctuaryDefenseTimeResp(error_code.ERR_WB_BUY_FULL, 0, 0)
        return
    end
    local nextTimes = ad.buyTimes + 1
    local price = g_sanctuary_defense_mgr:GetBuyEnterPrice(nextTimes)
    if not price then
        log_game_error("WorldBossMgr:CanBuyEnterInfo", "no g_sanctuary_defense_mgr.price. nextTimes = %d", nextTimes)
        return
    end
    log_game_debug("WorldBossMgr:CanBuyEnterInfo", "price.diamond[%d], price.gold[%d]", price.diamond, price.gold)
    mb.client.CanBuySanctuaryDefenseTimeResp(error_code.ERR_WB_BUY_CAN, price.diamond, price.gold)
end

--取消世界Boss活动
function WorldBossMgr:DisableWBActivity()
    if self.state ~= g_wb_config.STATE_NOT_OPEN and self.state ~= g_wb_config.STATE_STOP then 
        return 
    end

    for t, timerId in pairs(self.hasTimer) do
        if type(timerId) == 'table' then
            for _,v in pairs(timerId) do
                self:delTimer(v)
            end
        else
            self:delTimer(timerId)
        end
    end
    self.hasTimer = {}

    self.nextOpenTime = {}
    self.nextStartTime = {}
    self.nextEndTime = {}
end

--启动世界Boss活动
--[[
function WorldBossMgr:EnableWBActivity()
    if self.state ~= g_wb_config.STATE_NOT_OPEN and self.state ~= g_wb_config.STATE_STOP then 
        return 
    end
    log_game_debug("WorldBossMgr:EnableWBActivity", '')
    local time = os.time()
    local wdate = os.date("*t", time)
    
    wdate.hour = g_wb_config.WorldBossTimeStart[1]
    wdate.sec = 0
    wdate.min = g_wb_config.WorldBossTimeStart[2]
    local tt = os.time(wdate)

    local startTime = tt
    while startTime < time do
        startTime = startTime + g_wb_config.WorldBossTimeIntervel
    end
    startTime = startTime -  time
    local openTime = startTime
    if startTime < g_wb_config.PRE_OPEN_TIME then
        openTime = 1
        if startTime < 1 then
            startTime = 2
        end
    else
        openTime = startTime - g_wb_config.PRE_OPEN_TIME
    end
    if not self.hasTimer[m_timerType.OPEN] then
        --注册定时开始器
        self:SetTimer(openTime, g_wb_config.WorldBossTimeIntervel, m_timerType.OPEN)
        self.nextOpenTime = openTime + time
    end
    if not self.hasTimer[m_timerType.START] then
        --定时刷出世界boss
        self:SetTimer(startTime, g_wb_config.WorldBossTimeIntervel, m_timerType.START)
        self.nextStartTime = startTime + time
    end
    if not self.hasTimer[m_timerType.END] then
        --定时WorldBossTime + g_wb_config.PRE_OPEN_TIME秒后结束
        self:SetTimer( (g_wb_config.WorldBossTime + startTime), g_wb_config.WorldBossTimeIntervel, m_timerType.END)
    end

    local weekRfreshSec = self:GetUtilNextWeekReTime()
    if not self.hasTimer[m_timerType.WEEK] then
        self:SetTimer( weekRfreshSec, g_wb_config.SEC_PER_WEEK, m_timerType.WEEK)
    end
end
]]
function WorldBossMgr:EnableWBActivity()
    if self.state ~= g_wb_config.STATE_NOT_OPEN and self.state ~= g_wb_config.STATE_STOP then 
        return 
    end
    self.nextOpenTime = {}
    self.nextStartTime = {}
    self.nextEndTime = {}
    log_game_debug("WorldBossMgr:EnableWBActivity", '')
    local time = os.time()
    local wdate = os.date("*t", time)
    for hour,min in pairs(g_wb_config.WB_TIMES) do
        wdate.hour = hour
        wdate.sec = 0
        wdate.min = min
        local tt = os.time(wdate)

        local startTime = tt
        while startTime < time do
            startTime = startTime + 86400
        end
        startTime = startTime -  time
        local openTime = startTime
        if startTime < g_wb_config.PRE_OPEN_TIME then
            openTime = 1
            if startTime < 5 then
                startTime = 5
            end
        else
            openTime = startTime - g_wb_config.PRE_OPEN_TIME
        end
        
        --注册定时开始器
        self:SetTimer(openTime, 86400, m_timerType.OPEN)
        table.insert(self.nextOpenTime, openTime + time)


        --定时刷出世界boss
        self:SetTimer(startTime,86400, m_timerType.START)
        table.insert(self.nextStartTime, startTime + time)


        --定时WorldBossTime + g_wb_config.PRE_OPEN_TIME秒后结束
        local endTime = g_wb_config.WorldBossTime + startTime
        self:SetTimer( endTime, 86400, m_timerType.END)
        table.insert(self.nextEndTime, endTime + time)
    end
    if not self.hasTimer[m_timerType.DAY] then
    	local dayRefreshTime = self:GetUtilNextDayReTime()
    	self:SetTimer( dayRefreshTime, 86400, m_timerType.DAY)
    end
    local weekRfreshSec = self:GetUtilNextWeekReTime()
    if not self.hasTimer[m_timerType.WEEK] then
        self:SetTimer( weekRfreshSec, g_wb_config.SEC_PER_WEEK, m_timerType.WEEK)
    end
end

function WorldBossMgr:GetUtilNextDayReTime()
	return lua_util.get_left_secs_until_next_hhmiss(0,0,0)
end

function WorldBossMgr:GetUtilNextWeekReTime()
    return lua_util.get_secs_until_next_wdate(g_wb_config.WDAY_REFRESH,g_wb_config.HOUR_WEEK_REFRESH,0,0)
end

--GM 开启一次活动, starttime:多少秒后开启
function WorldBossMgr:GMOpen(openTime, startTime, endTime)
    log_game_debug("WorldBossMgr:GMOpen", "")
    if self.state ~= g_wb_config.STATE_NOT_OPEN and self.state ~= g_wb_config.STATE_STOP then 
        return 
    end
    if openTime > startTime or openTime > endTime or startTime > endTime then
        return
    end
    --先把原先的定时取消
    self:DisableWBActivity()
    log_game_debug("WorldBossMgr:GMOpen", "openTime[%d], startTime[%d], endTime[%d]", openTime, startTime, endTime)
    if not self.hasTimer[m_timerType.GM_OPEN] then
        --注册定时开始器
        log_game_debug("WorldBossMgr:GMOpen", "GM_OPEN : %s", tostring(os.time()))
        self:SetTimer(openTime, 0, m_timerType.GM_OPEN)
        table.insert(self.nextOpenTime, openTime + os.time())
    end
    if not self.hasTimer[m_timerType.GM_START] then
        --注册定时开始器
        log_game_debug("WorldBossMgr:GMOpen", "GM_START")
        self:SetTimer(startTime, 0, m_timerType.GM_START)
        table.insert(self.nextStartTime, startTime + os.time())
    end
    if not self.hasTimer[m_timerType.GM_END] then
        --注册定时开始器
        log_game_debug("WorldBossMgr:GMOpen", "GM_END")
        self:SetTimer(endTime, 0, m_timerType.GM_END)
        table.insert(self.nextEndTime, endTime + os.time())
    end
end

--
function WorldBossMgr:Summon(timerId, count, spawnId, mod)
    --[[
    for lv, v in pairs(self.lv2Spaces) do
        for mapId, num in pairs(v) do
            --有人才刷
            if num > 0 then
                local sp = self.spaces[mapId]
                sp.Summon(spawnId, mod)
            end
        end
    end
    ]]
    for _, mb in pairs(self.spaces) do
        mb.Summon(spawnId, mod)
    end
end

function WorldBossMgr:HpSelfDecrease(timerId, count, mod, val)
    if mod == decrease_type.ABS then 
        self.bossHpMgr:UpdateHp(0, val, g_wb_config.HP_DEL_MOD)
        --log_game_debug("WorldBossMgr:HpSelfDecrease", "self decrease hp by abs [%d]", val)
    else
        local hp = self.bossHpMgr.lastHp
        local dec = math.floor(hp * val / 10000)
        self.bossHpMgr:UpdateHp(0, dec, g_wb_config.HP_DEL_MOD)
        --log_game_debug("WorldBossMgr:HpSelfDecrease", "self decrease hp by per [%d:%d]", val, dec)
    end
end

function WorldBossMgr:CheckEnter(playerMbStr, map_id, line, dbid, name)
    if self.state == g_wb_config.STATE_NOT_OPEN or self.state == g_wb_config.STATE_STOP then
        log_game_error("WorldBossMgr:CheckEnter", "not open.")
        lua_util.globalbase_call("MapMgr", "CheckEnterResp", -1, playerMbStr, map_id, line, dbid, name)
        return
    end
    lua_util.globalbase_call("MapMgr", "CheckEnterResp", 0, playerMbStr, map_id, line, dbid, name)
end

function WorldBossMgr:SanctuaryLogin(mbStr)
    if self.state == g_wb_config.STATE_NOT_OPEN or self.state == g_wb_config.STATE_STOP then
        return
    end
    local mb = mogo.UnpickleBaseMailbox(mbStr)
    if mb then
        mb.SanctuaryNotice(1)
    end
end

function WorldBossMgr:ResetSomething()
    local t = os.time()
    for k,_ in pairs(self.nextOpenTime) do
    	while self.nextOpenTime[k] < t do
    		self.nextOpenTime[k] = 86400 + self.nextOpenTime[k]
    	end
    end
    for k,_ in pairs(self.nextStartTime) do
    	while self.nextStartTime[k] < t do
    		self.nextStartTime[k] = 86400 + self.nextStartTime[k]
    	end
    end

    for k,_ in pairs(self.nextEndTime) do
        while self.nextEndTime[k] < t + 600 do
            self.nextEndTime[k] = 86400 + self.nextEndTime[k]
        end
    end
end

--gm
function WorldBossMgr:add_week_score(mbStr,dbid,score)
    local ad = self.m_wbData[dbid]
    if not ad then return end
    ad.weekContribution = ad.weekContribution + score

    local cfg = g_sanctuary_defense_mgr:GetWeekContributionByLv(ad.weekLevel)
    if not cfg then
        log_game_error("WorldBossMgr:GetWeekCtrbuRewardReq","%d",ad.weekLevel)
        return
    end
    local recved = {}
    for k,_ in pairs(ad.recvReward) do
        table.insert(recved,k)
    end
    lua_util.mailbox_client_call(mbStr,'SanctuaryDefenseMyInfoResp',ad.dayContribution,ad.weekContribution,ad.weekLevel,recved)
end

return WorldBossMgr
