--author:hwj
--date:2013-8-21
--竞技场全局管理器,无数据存库,考虑扩展将来竞技场排位的情况，决定把玩家一些数据放在这里，所以需要存库
--玩家数据放在全局管理器好处是对将来的扩展性强，坏处是无论玩家在线与否都要有数据缓存，内存会占多点

require "arena_config"
require "timer_config"

local log_game_info = lua_util.log_game_info
local log_game_debug = lua_util.log_game_debug
local log_game_error = lua_util.log_game_error
local log_game_warning = lua_util.log_game_warning

--hasTimer中定时器的key
local timerType = {
SAVE  = 1, --销魂定时器
CLEAN = 2, --清理定时器
DAY = 3,
WEEK = 4,
}

ArenaMgr = {}
setmetatable(ArenaMgr, {__index = BaseEntity} )


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

function ArenaMgr:__ctor__()
    log_game_info('ArenaMgr:__ctor__', '')

    --self.m_arenicData = {}
    --self.m_Save = {}
    --回调方法
    if self:getDbid() == 0 then
        --首次创建
        self:writeToDB(on_basemgr_saved('ArenaMgr'))
    else
        self:RegisterGlobally("ArenaMgr", basemgr_register_callback("ArenaMgr", self:getId()))
    end
end

--注册globalbase成功后回调方法
function ArenaMgr:on_registered()
    self:registerTimeSave('mysql') --注册定时存盘
	--预load用户数据
    mogo.loadEntitiesOfType("ArenaData")
end

--设置arenadata的数目
function ArenaMgr:SetArenaDataCount(count)
    log_game_debug("ArenaMgr:SetArenaDataCount", "max=%d;loaded=%d", count, self.m_arena_loaded_count)
    self.m_arena_count = count

    if self.m_arena_count == self.m_arena_loaded_count then
        self:on_arenadata_loaded()
    end
end

--设置一个arenadata
function ArenaMgr:SetArenaData(eid)
    --log_game_debug("ArenaMgr:SetArenaData", "max=%d;loaded=%d", self.m_arena_count, self.m_arena_loaded_count+1)

    self.m_arena_loaded_count = self.m_arena_loaded_count + 1

    local ad = mogo.getEntity(eid)
    self.m_arenicData[ad.avatarDbid] = ad

    if self.m_arena_count == self.m_arena_loaded_count then
        self:on_arenadata_loaded()
    end
end

function ArenaMgr:GetNextDayReTime()
    return lua_util.get_left_secs_until_next_hhmiss(g_timer_config.ARENA_DAY_REFRESH_HOUR, g_timer_config.ARENA_DAY_REFRESH_MIN, 0)
end

function ArenaMgr:GetUtilNextWeekReTime()
    return lua_util.get_secs_until_next_wdate(g_timer_config.ARENA_WEEK_REFRESH_DAY,g_timer_config.ARENA_WEEK_REFRESH_HOUR,g_timer_config.ARENA_WEEK_REFRESH_MIN,0)
end

--所有的ArenaData都已经加载完毕
function ArenaMgr:on_arenadata_loaded()
    log_game_debug("ArenaMgr:on_arenadata_loaded", "")
    local timerId = 0
    --注册定时存储器
    --local timerId= self:addTimer(g_timer_config.ARENA_SAVE_INTERVAL, g_timer_config.ARENA_SAVE_INTERVAL, 1)
    --加入定时器集合(不需要定时存盘了)
    --self.m_timers[timerType.SAVE] = timerId
    --天刷新定时器
    local ss = lua_util.get_left_secs_until_next_hhmiss(g_timer_config.ARENA_DAY_REFRESH_HOUR, g_timer_config.ARENA_DAY_REFRESH_MIN, 0)
    log_game_debug("ArenaMgr:on_arenadata_loaded", "day timer start sec = %d", ss)
    timerId = self:addTimer(ss, g_timer_config.ARENA_DAY_REFRESH_INTERVAL, 2)
    self.m_timers[timerType.DAY] = timerId
    --周刷新定时器
    --[[
    local time = os.time()
    local wdate = os.date("*t", time)
    wdate.hour = g_timer_config.ARENA_WEEK_REFRESH_HOUR
    wdate.min = g_timer_config.ARENA_WEEK_REFRESH_MIN
    wdate.wday = g_timer_config.ARENA_WEEK_REFRESH_DAY
    local wt = os.time(wdate)
    while wt < time do
        wt = wt + g_timer_config.ARENA_WEEK_REFRESH_INTERVAL
    end
    local weekRfreshSec = wt - time
    ]]
    ss = self:GetUtilNextWeekReTime()
    log_game_debug("ArenaMgr:on_arenadata_loaded", "week timer start sec = %d", ss)
    timerId = self:addTimer(ss, g_timer_config.ARENA_WEEK_REFRESH_INTERVAL, 3)
    self.m_timers[timerType.WEEK] = timerId

	lua_util.globalbase_call('GameMgr', 'OnMgrLoaded', 'ArenaMgr')
end

--
function ArenaMgr:Init()
    local time = os.time()
    if time >= self.nextDayReTime then
        self:Day()
    end
    if time >= self.nextWeekReTime then
        self:Week()
    end
    lua_util.globalbase_call('GameMgr', 'OnInited', 'ArenaMgr')
end

--定时器
function ArenaMgr:onTimer( timer_id, user_data )
    --log_game_debug("ArenaMgr:onTimer","timer_id = %d, user_data = %d.", timer_id, user_data)
    if(timer_id == self.m_timers[timerType.SAVE]) then
        --log_game_debug("ArenaMgr:onTimer","Save.")
        self:Save()
    elseif (timer_id == self.m_timers[timerType.CLEAN]) then
        log_game_debug("ArenaMgr:onTimer","Clean.")
        self:Clean()
    elseif timer_id == self.m_timers[timerType.DAY] then
        log_game_debug("ArenaMgr:onTimer","DAY.")
        self:Day()
    elseif timer_id == self.m_timers[timerType.WEEK] then
        log_game_debug("ArenaMgr:onTimer","WEEK.")
        self:Week()
    else
        log_game_warning("ArenaMgr:onTimer","unknown timer = %d",timer_id)
    end
end


--定时定量入库,todo:根据处理时间的大小来动态变化处理入库数据的大小
function ArenaMgr:Save()
    --啥也不做,功能取消了
end

--销毁前操作
function ArenaMgr:onDestroy()
    log_game_info("ArenaMgr:onDestroy", "")
    self:Save()
end

--todo:清理无用的数据
function ArenaMgr:Clean()
    
end

function ArenaMgr:Day()
    local time = os.time()
    for id, ad in pairs(self.m_arenicData) do
        ad.dayScore = 0
        ad.dayReward = {}
        if ad.candidateEnemy ~= 0 then
            ad.enemy = ad.candidateEnemy
            ad.candidateEnemy = 0
        else
            if ad.enemy ~= 0 then
                ad.enemy = 0
            end
        end
        ad.enemyFight = 0
        ad.beatEnemy = 0
        ad.challengeTime = 0
        ad.dayLevel = ad.level
    end
    self.nextDayReTime = time + self:GetNextDayReTime()
    --通知在线玩家
    local mm = globalBases['UserMgr']
    if mm then
        mm.DataDated('arenaSystem', 'DataDated', {})
    end
end

function ArenaMgr:Week()
    local time = os.time()
    for id, ad in pairs(self.m_arenicData) do
        ad.weekScore = 0
        ad.weekReward = {}
        ad.weekLevel = ad.level
    end
    self.nextWeekReTime = time + self:GetUtilNextWeekReTime()
    local mm = globalBases['UserMgr']
    if mm then
        mm.RefreshRefFightReq()
    end
end

function ArenaMgr:RefreshRefFightResp(idToFight)
    for id, fight in pairs(idToFight) do
        local ad = self.m_arenicData[id]
        if ad then
            if ad.referenceFight < fight then
                ad.referenceFight = fight
            end
        end
    end
end

local function arenadata_callback(ad, dbid, err)
    if dbid == 0 then
        log_game_warning("arenadata_callback_err",'')
    end
end

--新增竞技场玩家
function ArenaMgr:AddNewPlayer(id, f, lv)
    local ad = self.m_arenicData[id]
    if ad then return ad end
    log_game_info("ArenaMgr:AddNewPlayer", "id[%q], f[%d], lv[%d]",id, f, lv)
    ad = mogo.createBase('ArenaData', {avatarDbid=id,referenceFight=f,level=lv,dayLevel=lv,weekLevel=lv,})
    ad:writeToDB(arenadata_callback)
    self.m_arenicData[id] = ad

    --刚刚进来的立即随机一个仇敌给他
    self:RandEnemy(id)

    return ad
end

function ArenaMgr:Login(mbStr, id, f, lv)
    if lv < g_arena_config.OPEN_LV then
        log_game_warning("ArenaMgr:Login", "dbid[%d] lv[%d]", id, lv)
        return
    end
    local ad = self:AddNewPlayer(id, f, lv)
    self:GetWeakFoes(id)
    self:GetStrongFoes(id)

    if ad.enemy == 0 then
        --随机一个当天的仇敌
        self:GetEnemy(mbStr, id)
    end
    self:GetPlayerInfo(mbStr, id)
end

function ArenaMgr:GetPlayerInfo(mbStr, id)
    local theInfo = self.m_arenicData[id]
    if not theInfo then
        return
    end
    local tmp = {
        [arenicDataKey.tmp_scoresOfDay] = theInfo.dayScore,
        [arenicDataKey.tmp_rewardOfDay] = theInfo.dayReward,
        [arenicDataKey.tmp_scoresOfWeek] = theInfo.weekScore,
        [arenicDataKey.tmp_rewardOfWeek] = theInfo.weekReward,
        [arenicDataKey.tmp_theEnemy] = theInfo.enemy,
        [arenicDataKey.tmp_challengeTimes] = theInfo.challengeTime,
        [arenicDataKey.tmp_beatEnemy] = theInfo.beatEnemy,
        [arenicDataKey.tmp_dayLevel] = theInfo.dayLevel,
        [arenicDataKey.tmp_weekLevel] = theInfo.weekLevel,
    }
    local mb = mogo.UnpickleBaseMailbox(mbStr)
    if mb then
        mb.EventDispatch("arenaSystem", "SetArenicData", {tmp})
        --mb.client.RefreshArenaDataResp(tmp)
    end
end

--获取弱对手
function ArenaMgr:GetWeakFoes(id)
    local myInfo = self.m_arenicData[id]
    if not myInfo then
        log_game_error("ArenaMgr:GetWeakFoes", "no data")
        return
    end
    if not self.m_arenicData[id] then
        log_game_error("ArenaMgr:GetWeakFoes", "no data")
        return
    end
    local mm = globalBases["UserMgr"]
    if mm then
        local myFight = myInfo.referenceFight
        mm.GetWeakFoes(id, myFight)
    end
end

--获取强对手
function ArenaMgr:GetStrongFoes(id)
    local myInfo = self.m_arenicData[id]
    if not myInfo then
        log_game_error("ArenaMgr:GetStrongFoes", "no data")
        return
    end
    if not self.m_arenicData[id] then
        log_game_error("ArenaMgr:GetStrongFoes", "no data")
        return
    end
    local mm = globalBases["UserMgr"]
    if mm then
        local myFight = myInfo.referenceFight
        mm.GetStrongFoes(id, myFight)
    end
end

--获取仇敌
function ArenaMgr:GetEnemy(mbStr, id)
    local myInfo = self.m_arenicData[id]
    if not myInfo then
        log_game_error("ArenaMgr:GetEnemy", "no data")
        return
    end
    --
    local mb = mogo.UnpickleBaseMailbox(mbStr)
    if not mb then
        return
    end

    local enemyId = myInfo.enemy
    if enemyId == 0 then
        --log_game_error("ArenaMgr:GetEnemy", "no enemy")
        log_game_debug("ArenaMgr:GetEnemy", "rand enemy.")
        self:RandEnemy(id)
        return
    end
    mb.EventDispatch("arenaSystem", "SetEnemy", {{enemyId}})
    --[[
    local param = g_arena_config.ENEMY_PICK_PARAM
    local myFight = self.m_arenicData[myPos].fight
    local fUp  = math.floor(myFight * param[1])
    local fLow = math.ceil(myFight* param[2])
    local mm = globalBases["UserMgr"]
    if mm then
        --mm.GetPlayerFightMax(fLow, fUp, id, 1, "arenaSystem", "SetEnemy")
        mm.GetPlayerFightMax(fLow, fUp, id, 1, mbStr, "UpdateEnemy")
    end
    ]]
end

function ArenaMgr:RandEnemy(id)
    local myInfo = self.m_arenicData[id]
    if not myInfo then
        log_game_error("ArenaMgr:GetEnemy", "no data")
        return
    end
    --
    local mbStr = mogo.pickleMailbox(self)
    if not mbStr then
        return
    end

    local enemyId = myInfo.enemy
    if enemyId ~= 0 then
        log_game_error("ArenaMgr:GetEnemy", "have enemy.")
        return
    end
    local param = g_arena_config.ENEMY_PICK_PARAM
    local myFight = myInfo.referenceFight--self.m_arenicData[myPos].fight
    local fUp  = math.floor(myFight * param[1]/ 100)
    local fLow = math.ceil(myFight* param[2]/ 100)
    local mm = globalBases["UserMgr"]
    if mm then
        --mm.GetPlayerFightMax(fLow, fUp, id, 1, "arenaSystem", "SetEnemy")
        mm.GetPlayerFightMax(fLow, fUp, id, 1, mbStr, "UpdateEnemy")
    end
end

function ArenaMgr:UpdateEnemy(id, enemys)
    local ad = self.m_arenicData[id]
    if ad == nil then
        return
    end
    local enemy1 = enemys[1]
    if enemy1 == nil then
        return
    end

    ad.enemy = enemy1
end

function ArenaMgr:UpdateCandidateEnemy(challenger_dbid, defier_dbid, challenger_fight)
    local challenger_info = self.m_arenicData[challenger_dbid]
    local defier_info = self.m_arenicData[defier_dbid]
    if not challenger_info or not defier_info then
        log_game_warning("ArenaMgr:UpdateCandidateEnemy", "")
        return
    end
    if defier_info.enemyFight < challenger_fight then
        defier_info.enemyFight = challenger_fight
        defier_info.candidateEnemy = challenger_dbid
    end
end

function ArenaMgr:AddScore(id, value)
    local theInfo = self.m_arenicData[id]
    if not theInfo then
        log_game_error("ArenaMgr:AddScore", "")
        return
    end

    theInfo.dayScore = theInfo.dayScore + value
    theInfo.weekScore = theInfo.weekScore + value
end

function ArenaMgr:AddChallengeTime(id, count, lv)
    local theInfo = self.m_arenicData[id]
    if not theInfo then
        log_game_error("ArenaMgr:AddChallengeTime", "")
        return
    end
    theInfo.level = lv
    theInfo.challengeTime = theInfo.challengeTime + count
end

function ArenaMgr:MarkBeatEnemy(dbid)
    local ad = self.m_arenicData[dbid]
    if not ad then
        log_game_error("ArenaMgr:MarkBeatEnemy", "")
        return
    end
    ad.beatEnemy = 1
end

function ArenaMgr:RecvDayRewards(dbid, mb, idx)
    local theInfo = self.m_arenicData[dbid]
    if not theInfo then
        log_game_error("ArenaMgr:RecvDayRewards", "")
        return
    end
    local mm = mogo.UnpickleBaseMailbox(mb)
    local dayReward = theInfo.dayReward
    if dayReward[idx] then
        mm.EventDispatch("arenaSystem", "RealGetArenaReward", {1, idx})
        return
    end
    dayReward[idx] = 1
    mm.EventDispatch("arenaSystem", "RealGetArenaReward", {0, idx})
end

function ArenaMgr:RecvWeekRewards(dbid, mb, idx)
    local theInfo = self.m_arenicData[dbid]
    if not theInfo then
        log_game_error("ArenaMgr:RecvWeekRewards", "")
        return
    end
    local mm = mogo.UnpickleBaseMailbox(mb)
    local weekReward = theInfo.weekReward
    if weekReward[idx] then
        mm.EventDispatch("arenaSystem", "RealGetArenaReward", {2, idx})
        return
    end
    weekReward[idx] = 1
    mm.EventDispatch("arenaSystem", "RealGetArenaReward", {0, idx})
end
