
require "lua_util"
require "ActivityData"
require "channel_config"
require "global_data"
require "GlobalParams"

local log_game_debug = lua_util.log_game_debug
local log_game_warning = lua_util.log_game_warning
local log_game_info = lua_util.log_game_info
local log_game_error = lua_util.log_game_error
local globalbase_call = lua_util.globalbase_call
local get_table_real_count = lua_util.get_table_real_count

local ZERO_TIMER = 0

local TEMPDATA_INDEX_TOWER_DEFENCE = 1         --塔防副本用到的临时数据key
local TEMPDATA_INDEX_TOWER_DEFENCE_ORDER = 1   --塔防副本的匹配顺序
local TEMPDATA_INDEX_TOWER_DEFENCE_MATCH_TIMER_ID = 2 --塔防副本的匹配定时器ID
local TEMPDATA_INDEX_TOWER_DEFENCE_LAST_MATCH_TIME = 3  --上一次塔防副本匹配的时间戳
local TEMPDATA_INDEX_TOWER_DEFENCE_END_TIMER_ID = 4  --塔防副本借宿的定时器ID

ActivityMgr = {}

setmetatable( ActivityMgr, {__index = BaseEntity} )

function ActivityMgr:__ctor__()
    log_game_debug("ActivityMgr:__ctor__", "")

    local function RegisterGloballyCB(ret)
        if 1 == ret then
            --注册成功
            self:OnRegistered()
        else
            --注册失败
            log_game_error("ActivityMgr:RegisterGlobally error", '')
        end
    end

    self:RegisterGlobally("ActivityMgr", RegisterGloballyCB)
end

function ActivityMgr:OnRegistered()

    --开始设置活动定时器
    self:AddActivityTimer()

    --设定每天0点触发的定时器
    self:addTimer(lua_util.get_left_secs_until_next_hhmiss(0, 0, 0) + math.random(0, 10), 24*60*60, ZERO_TIMER)

    --记录塔防副本里面的匹配顺序
    self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE] = {}
    self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_ORDER] = 0

    globalbase_call('GameMgr', 'OnMgrLoaded', 'ActivityMgr')
end

function ActivityMgr:AddActivityTimer()
    --首先获取当天的活动时间表
    local now = os.time()
    local weekday = tonumber(os.date("%w", now))

    if weekday == 0 then
        --如果weekday是0，则表示今天是星期天
        weekday = 7
    end

    local activitySchedule = gActivityData:getActivityTime(weekday)
    local now_hour = tonumber(os.date("%H", now))
    local now_minute = tonumber(os.date("%M", now))
    local now_second = tonumber(os.date("%S", now))

    --建立当天各个活动的定时器
    if activitySchedule and activitySchedule['activityTime'] then
        local activityTime = activitySchedule['activityTime']
        local activities = lua_util.split_str(activityTime, ';')
        for _, activity in pairs(activities) do
            local t = lua_util.split_str(activity, '@')
            local hour_minute = lua_util.split_str(t[1], ':', tonumber)
            local hour = hour_minute[1]
            local minute = hour_minute[2]
            if hour > now_hour or (hour == now_hour and minute > now_minute) then
                --开服的时间在活动时间前
                local delaytime = (hour - now_hour) * 3600 + (minute - now_minute) * 60 + (0 - now_second)
                local a_table = lua_util.split_str(t[2], ',', tonumber)
                for _, a in pairs(a_table) do
                    log_game_debug('ActivityMgr AddTimer', "hour=%d;minute=%d;delaytime=%d;now_second=%d;a=%d", hour, minute, delaytime, now_second, a)
                    self:addTimer(delaytime, 0, a)
                end
            else
--                --开服的时间在活动时间内，则需要把活动激活起来
--                --计算活动的结束时间，如果当前时刻在活动的结束时间前，则激活该活动
--                local lastTimeHour = math.floor(activity['lastTime'] / 3600)
--                local lastTimeMinute = math.floor(math.max(activity['lastTime'] - lastTimeHour * 3600, 0) / 60)
--                local end_hour = hour + lastTimeHour
--                local end_minute = minute + lastTimeMinute
--                if hour > now_hour or (hour == end_hour and minute > end_minute) then
--                    local a_table = lua_util.split_str(t[2], ',', tonumber)
--                    for _, a in pairs(a_table) do
--                        --立即打开活动
--                        global_data:activity_req(CHANNEL.WORLD, activity['notice'], activity['id'])
--                        --设置活动结束时间的timer
--                        local delaytime = (end_hour - now_hour) * 3600 + (end_minute - now_minute) * 60 + (0 - now_second)
--                        self:addTimer(delaytime, 0, a + 1000)
--
--                        --如果活动是塔防副本，则需要开始每隔一段时间触发一次匹配的定时器
--                        if a == 1 then
--                            self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_MATCH_TIMER_ID] = self:addTimer(activity['param1'], activity['param1'], a + 2000)
--                            --记录活动的开始时间
--                            self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_START_TIME] = os.time()
--                        end
--                    end
--                end
            end
        end
    end
end

function ActivityMgr:onTimer(timer_id, user_data)
    log_game_debug('ActivityMgr:onTimer', "timer_id=%d;user_data=%d", timer_id, user_data)

    if user_data == ZERO_TIMER then
        --每天0点触发一次，设置当天的所有活动的触发时间
        self:AddActivityTimer()
    else
        self:StartActivity(user_data)
--        local activity = gActivityData:getActivity(user_data)
--
--        if activity then
--            --首先向全服发送世界公告
--            if activity['notice'] then
--                global_data:activity_req(CHANNEL.WORLD, activity['notice'], activity['id'])
--                log_game_debug('ActivityMgr:onTimer start', "user_data=%d", user_data)
--            end
--
--            --然后设置活动的结束timer
--            if activity['lastTime'] then
--                --每个活动的ID加1000表示该活动的结束timerId
--
--                --删除老的定时器ID
--                if self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_END_TIMER_ID] then
--                    self:delTimer(self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_END_TIMER_ID])
--                    self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_END_TIMER_ID] = nil
--                end
--
--                self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_END_TIMER_ID] = self:addTimer(activity['lastTime'], 0, user_data + 1000)
--
--                log_game_debug('ActivityMgr:onTimer lastTime', "lastTime=%d;user_data=%d", activity['lastTime'], user_data)
--            end
--
--            --如果活动是塔防副本，则需要开始每隔一段时间触发一次匹配的定时器
--            if user_data == 1 then
--
--                if self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_MATCH_TIMER_ID] then
--                    self:delTimer(self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_MATCH_TIMER_ID])
--                    self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_MATCH_TIMER_ID] = nil
--                end
--
--                self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_MATCH_TIMER_ID] = self:addTimer(activity['param1'], activity['param1'], user_data + 2000)
--
--
--                --记录活动的开始时间
--                self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_LAST_MATCH_TIME] = os.time()
--
--                log_game_debug("ActivityMgr:onTimer", "param1=%d;user_data=%d", activity['param1'], user_data)
--            end
--
--        end

        local activity = gActivityData:getActivity(user_data - 1000)
        if activity then
            --进到这里，则表示该活动应该结束了，通知各个base进程结束

            self:StopActivity(user_data - 1000)
            log_game_debug('ActivityMgr:onTimer StopActivity', "user_data=%d", user_data)

--            global_data:activity_finish_req(user_data - 1000)
--            log_game_debug('ActivityMgr:onTimer finish', "user_data=%d", user_data)
--
--            if user_data - 1000 == 1 and self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_MATCH_TIMER_ID] then
--                --如果结束的活动是塔防副本，则需要把匹配用的定时器也一并去掉
--                self:delTimer(self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_MATCH_TIMER_ID])
--                self.TowerDefenceWaitingList = {}
--                self.TowerDefenceWaitingMapList = {}
--                self.TowerDefenceId = 0
--                self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE] = {}
--            end
        end

        local activity = gActivityData:getActivity(user_data - 2000)
        if activity then
            if user_data - 2000 == 1 then
                --系统开始匹配的定时器触发了
                log_game_debug('ActivityMgr:onTimer matchTimer', "user_data=%d", user_data)
                self:TowerDefenceMatch()
                --记录当前触发过匹配的次数
                self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_LAST_MATCH_TIME] = os.time()
            end
        end
    end
end

function ActivityMgr:CampaignGetOnlineFriends(MbStr, PlayerDbid, friendDbids, CampaignId)
    log_game_debug('ActivityMgr:CampaignGetOnlineFriends', "MbStr=%s;PlayerDbid=%q;friendDbids=%s;CampaignId=%d", MbStr, PlayerDbid, mogo.cPickle(friendDbids))

    --排除掉已经邀请过的玩家
    if self.InviteList[CampaignId] and self.InviteList[CampaignId][PlayerDbid] then
        for dbid, _ in pairs(friendDbids) do
            if self.InviteList[CampaignId][PlayerDbid][dbid] then
                friendDbids[dbid] = nil
            end
        end
    end

    globalbase_call('UserMgr', 'CampaignGetOnlineFriends', MbStr, PlayerDbid, friendDbids, CampaignId)
end

function ActivityMgr:CampaignInvite(MbStr, PlayerDbid, PlayerName, CampaignId, InvitedPlayerDbid, InvitedPlayerMbStr)
    log_game_debug('ActivityMgr:CampaignInvite', "MbStr=%s;CampaignId=%d;PlayerDbid%q;PlayerName=%s;InvitedPlayerDbid=%q;InvitedPlayerMbStr=%s", MbStr, CampaignId, PlayerDbid, PlayerName, InvitedPlayerDbid, InvitedPlayerMbStr)

    if not self.InviteList[CampaignId] then
        local mb = mogo.UnpickleBaseMailbox(MbStr)
        if mb then
            mb.client.CampaignResp(action_config.MSG_CAMPAIGN_INVITE, error_code.ERR_ACTIVITE_INVITE_AC_NOT_EXIT, {})
        end
        return
    end

    if self.InviteList[CampaignId][PlayerDbid] then
        if self.InviteList[CampaignId][PlayerDbid][InvitedPlayerDbid] then
            local mb = mogo.UnpickleBaseMailbox(MbStr)
            if mb then
                mb.client.CampaignResp(action_config.MSG_CAMPAIGN_INVITE, error_code.ERR_ACTIVITE_INVITE_ALLREADY_INVITED, {})
            end
            return
        end
    end

    local InvitedInfo = self.InviteList[CampaignId][PlayerDbid] or {}
    InvitedInfo[InvitedPlayerDbid] = os.time()
    self.InviteList[CampaignId][PlayerDbid] = InvitedInfo

    --通知邀请方成功发出邀请
    local mb = mogo.UnpickleBaseMailbox(MbStr)
    if mb then
        mb.client.CampaignResp(action_config.MSG_CAMPAIGN_INVITE, 0, {})
    end

    local InvitedPlayerMb = mogo.UnpickleBaseMailbox(InvitedPlayerMbStr)
    if InvitedPlayerMb then
        InvitedPlayerMb.client.CampaignResp(action_config.MSG_CAMPAIGN_INVITED, 0, {CampaignId, PlayerName, PlayerDbid,})
    end
end

function ActivityMgr:CampaignInvitedResp(MbStr, selfDbid, selfName, CampaignId, Accept, PlayerDbid)
    log_game_debug("ActivityMgr:CampaignInvitedResp", "MbStr=%d;selfDbid=%q;selfName=%s;CampaignId=%d;Accept=%d; PlayerDbid=%q", MbStr, selfDbid, selfName, CampaignId, Accept, PlayerDbid)

    if not self.InviteList[CampaignId] then
        local mb = mogo.UnpickleBaseMailbox(MbStr)
        if mb then
            mb.client.CampaignResp(action_config.MSG_CAMPAIGN_INVITED_RESP, error_code.ERR_ACTIVITE_INVITED_RESP_NOT_EXIT, {})
        end
        return
    end

    if not self.InviteList[CampaignId][PlayerDbid] then
        local mb = mogo.UnpickleBaseMailbox(MbStr)
        if mb then
            mb.client.CampaignResp(action_config.MSG_CAMPAIGN_INVITED_RESP, error_code.ERR_ACTIVITE_INVITED_RESP_NOT_EXIT, {})
        end
        return
    end

    if not self.InviteList[CampaignId][PlayerDbid][selfDbid] then
        local mb = mogo.UnpickleBaseMailbox(MbStr)
        if mb then
            mb.client.CampaignResp(action_config.MSG_CAMPAIGN_INVITED_RESP, error_code.ERR_ACTIVITE_INVITED_RESP_NOT_EXIT, {})
        end
        return
    end

    --接下来要具体活动逻辑决定
end

function ActivityMgr:CampaignJoin(CampaignId, MbStr, PlayerDbid, PlayerName, PlayerLevel)
    log_game_debug("ActivityMgr:CampaignJoin", "CampaignId=%d;MbStr=%s;PlayerDbid=%q;PlayerName=%s;PlayerLevel=%d", CampaignId, MbStr, PlayerDbid, PlayerName, PlayerLevel)

    if CampaignId == 1 and gActivityData:getActivity(CampaignId) then

        local activity = gActivityData:getActivity(CampaignId)
        --倒数时间等于下一次触发的时间减去当前时间
        local LastTime = self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_LAST_MATCH_TIME] or 0

        local now = os.time()
        local CountDown = math.max(0, (LastTime + activity['param1']) - now)

        for _, v in pairs(self.TowerDefenceWaitingList) do
            if v[2] == PlayerDbid then
                local mb = mogo.UnpickleBaseMailbox(MbStr)
                if mb then
                    log_game_debug("ActivityMgr:CampaignJoin TowerDefenceWaitingList", "CampaignId=%d;MbStr=%s;PlayerDbid=%q;PlayerName=%s;PlayerLevel=%d;LastTime=%d;CountDown=%d;now=%d", CampaignId, MbStr, PlayerDbid, PlayerName, PlayerLevel, LastTime, CountDown, now)
                    mb.client.CampaignResp(action_config.MSG_CAMPAIGN_JOIN, error_code.ERR_ACTIVITY_JOIN_ALREADY, {CountDown,})
                end
                return
            end
        end

        for _, v in pairs(self.TowerDefenceWaitingMapList) do
            for _, v1 in pairs(v) do
                if v1[2] == PlayerDbid then
                    local mb = mogo.UnpickleBaseMailbox(MbStr)
                    if mb then
                        log_game_debug("ActivityMgr:CampaignJoin TowerDefenceWaitingMapList", "CampaignId=%d;MbStr=%s;PlayerDbid=%q;PlayerName=%s;PlayerLevel=%d;LastTime=%d;CountDown=%d;now=%d", CampaignId, MbStr, PlayerDbid, PlayerName, PlayerLevel, LastTime, CountDown, now)
                        mb.client.CampaignResp(action_config.MSG_CAMPAIGN_JOIN, error_code.ERR_ACTIVITY_JOIN_ALREADY, {CountDown,})
                    end
                    return
                end
            end
        end

        --玩家参加的是塔防副本
        local result = {MbStr, PlayerDbid, PlayerName, PlayerLevel, }
        table.insert(self.TowerDefenceWaitingList, result)
        table.sort(self.TowerDefenceWaitingList, function (a, b) return a[4] > b[4] end)
--        local len = get_table_real_count(self.TowerDefenceWaitingList)
--        local index = BinarySearch(self.TowerDefenceWaitingList, len, PlayerLevel, function (x) return x[4] end)
--        table.insert(self.TowerDefenceWaitingList, index, result)

        local mb = mogo.UnpickleBaseMailbox(MbStr)
        if mb then
            log_game_debug("ActivityMgr:CampaignJoin", "CampaignId=%d;MbStr=%s;PlayerDbid=%q;PlayerName=%s;PlayerLevel=%d;LastTime=%d;CountDown=%d;now=%d", CampaignId, MbStr, PlayerDbid, PlayerName, PlayerLevel, LastTime, CountDown, now)
            mb.client.CampaignResp(action_config.MSG_CAMPAIGN_JOIN, 0, {CountDown,})
        end
    end
end

--塔防副本的匹配函数
function ActivityMgr:TowerDefenceMatch()
    local len = get_table_real_count(self.TowerDefenceWaitingList)
    if len < g_GlobalParamsMgr:GetParams("tower_defence_player_count", 4) then
        for _, v in pairs(self.TowerDefenceWaitingList) do
            local mb = mogo.UnpickleBaseMailbox(v[1])
            if mb then
                mb.client.CampaignResp(action_config.MSG_CAMPAIGN_MATCH, error_code.ERR_ACTIVITY_TOWER_DEFENCE_MATCH_FAIL, {})
            end
        end

        log_game_debug("ActivityMgr:TowerDefenceMatch not enough", "TowerDefenceWaitingList=%s", mogo.cPickle(self.TowerDefenceWaitingList))

        return
    end

    --从高级玩家向高级玩家匹配
    while get_table_real_count(self.TowerDefenceWaitingList) >= g_GlobalParamsMgr:GetParams("tower_defence_player_count", 4) do

        local result = {}
        for i=1, g_GlobalParamsMgr:GetParams("tower_defence_player_count", 4) do
            table.insert(result, table.remove(self.TowerDefenceWaitingList, 1))
        end
        --            table.insert(result, table.remove(self.TowerDefenceWaitingList, 1))
        --            local player1 = table.remove(self.TowerDefenceWaitingList, 1)
        --            local player2 = table.remove(self.TowerDefenceWaitingList, 1)
        --            local player3 = table.remove(self.TowerDefenceWaitingList, 1)
        --            local player4 = table.remove(self.TowerDefenceWaitingList, 1)

        local TowerDefenceId = self:GenTowerDefenceId()
        self.TowerDefenceWaitingMapList[TowerDefenceId] = result
        --            self.TowerDefenceWaitingMapList[TowerDefenceId] = {player1, player2, player3, player4, }
    end

--    if self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_ORDER] == 0 then
--        --从高级玩家向高级玩家匹配
--        while get_table_real_count(self.TowerDefenceWaitingList) >= g_GlobalParamsMgr:GetParams("tower_defence_player_count", 4) do
--
--            local result = {}
--            for i=1, g_GlobalParamsMgr:GetParams("tower_defence_player_count", 4) do
--                table.insert(result, table.remove(self.TowerDefenceWaitingList, 1))
--            end
----            table.insert(result, table.remove(self.TowerDefenceWaitingList, 1))
----            local player1 = table.remove(self.TowerDefenceWaitingList, 1)
----            local player2 = table.remove(self.TowerDefenceWaitingList, 1)
----            local player3 = table.remove(self.TowerDefenceWaitingList, 1)
----            local player4 = table.remove(self.TowerDefenceWaitingList, 1)
--
--            local TowerDefenceId = self:GenTowerDefenceId()
--            self.TowerDefenceWaitingMapList[TowerDefenceId] = result
----            self.TowerDefenceWaitingMapList[TowerDefenceId] = {player1, player2, player3, player4, }
--        end
--        self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_ORDER] = 1
--    elseif self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_ORDER] == 1 then
--    --从低级玩家向低级玩家匹配
--        while get_table_real_count(self.TowerDefenceWaitingList) >= g_GlobalParamsMgr:GetParams("tower_defence_player_count", 4) do
--
--            local result = {}
--            local len = get_table_real_count(self.TowerDefenceWaitingList)
--
--            for i=1, g_GlobalParamsMgr:GetParams("tower_defence_player_count", 4) do
--                table.insert(result, table.remove(self.TowerDefenceWaitingList, len))
--                len = get_table_real_count(self.TowerDefenceWaitingList)
--            end
--
----            local player1 = table.remove(self.TowerDefenceWaitingList, len)
----            local player2 = table.remove(self.TowerDefenceWaitingList, len - 1)
----            local player3 = table.remove(self.TowerDefenceWaitingList, len - 2)
----            local player4 = table.remove(self.TowerDefenceWaitingList, len - 3)
--
--            local TowerDefenceId = self:GenTowerDefenceId()
--            self.TowerDefenceWaitingMapList[TowerDefenceId] = result
----            self.TowerDefenceWaitingMapList[TowerDefenceId] = {player1, player2, player3, player4,}
--        end
--        self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_ORDER] = 0
--    end

    for TowerDefenceId, _ in pairs(self.TowerDefenceWaitingMapList) do
        globalbase_call('MapMgr', 'CreateTowerDefenceMapInstance', g_GlobalParamsMgr:GetParams("tower_defence_scene_id", 30002), TowerDefenceId)
    end

    for _, v in pairs(self.TowerDefenceWaitingList) do
        local mb = mogo.UnpickleBaseMailbox(v[1])
        if mb then
            mb.client.CampaignResp(action_config.MSG_CAMPAIGN_MATCH, error_code.ERR_ACTIVITY_TOWER_DEFENCE_MATCH_FAIL, {})
        end
    end

    return
end

function ActivityMgr:SelectMapResp(map_id, imap_id, spBaseMb, spCellMb, dbid, params)
    log_game_debug("ActivityMgr:SelectMapResp", "map_id=%d;imap_id=%d;spBaseMb=%s;spCellMb=%s;dbid=%d;params=%s", map_id, imap_id, mogo.cPickle(spBaseMb), mogo.cPickle(spCellMb), dbid, mogo.cPickle(params))

    --成功申请副本，则直接把玩家拉进副本
    if self.TowerDefenceWaitingMapList[imap_id] then
        local players = self.TowerDefenceWaitingMapList[imap_id]
        for _, player in pairs(players) do
            local mb = mogo.UnpickleBaseMailbox(player[1])
            if mb then
                --所有人拉进去副本
                mb.SelectMapResp(map_id, imap_id, spBaseMb, spCellMb, dbid, params)
            end
        end

        self.TowerDefenceWaitingMapList[imap_id] = nil
    else
        --如果回来的时候
        globalbase_call('MapMgr', 'Reset', map_id .. '_' .. imap_id)
    end
end

function ActivityMgr:GenTowerDefenceId()
    self.TowerDefenceId = self.TowerDefenceId + 1
    return self.TowerDefenceId
end

--每次副本结算时都调用一下，重置副本流水号
function ActivityMgr:ResetDefenceId()
    self.TowerDefenceId = 0
end

--离开所有活动
function ActivityMgr:CampaignLeaveAll(MbStr, PlayerDbid)

    log_game_debug("ActivityMgr:CampaignLeaveAll", "dbid=%q", PlayerDbid)

    for index, v in pairs(self.TowerDefenceWaitingList) do
        if v[2] == PlayerDbid then
            local player = table.remove(self.TowerDefenceWaitingList, index)
            local mb = mogo.UnpickleBaseMailbox(player[1])
            if mb then
                mb.client.CampaignResp(action_config.MSG_CAMPAIGN_LEAVE, 0, {})
            end
            return
        end
    end

    for index, v in pairs(self.TowerDefenceWaitingMapList) do
        for index1, v1 in pairs(v) do
            if v1[2] == PlayerDbid then
                local player = table.remove(v, index1)
                local mb = mogo.UnpickleBaseMailbox(player[1])
                if mb then
                    mb.client.CampaignResp(action_config.MSG_CAMPAIGN_LEAVE, 0, {})
                end

                --所有人对退出了，就删除该队列
                if v == {} then
                    self.TowerDefenceWaitingMapList[index] = nil
                end
                return
            end
        end
    end
end

function ActivityMgr:CampaignLeave(CampaignId, MbStr, PlayerDbid)

    log_game_debug("ActivityMgr:CampaignLeave", "dbid=%q", PlayerDbid)

    if CampaignId == 1 then
        for index, v in pairs(self.TowerDefenceWaitingList) do
            if v[2] == PlayerDbid then
                local player = table.remove(self.TowerDefenceWaitingList, index)
                local mb = mogo.UnpickleBaseMailbox(player[1])
                if mb then
                    mb.client.CampaignResp(action_config.MSG_CAMPAIGN_LEAVE, 0, {})
                end
                return
            end
        end

        for index, v in pairs(self.TowerDefenceWaitingMapList) do
            for index1, v1 in pairs(v) do
                if v1[2] == PlayerDbid then
                    local player = table.remove(v, index1)
                    local mb = mogo.UnpickleBaseMailbox(player[1])
                    if mb then
                        mb.client.CampaignResp(action_config.MSG_CAMPAIGN_LEAVE, 0, {})
                    end

                    --所有人对退出了，就删除该队列
                    if v == {} then
                        self.TowerDefenceWaitingMapList[index] = nil
                    end
                    return
                end
            end
        end

        local mb = mogo.UnpickleBaseMailbox(MbStr)
        if mb then
            mb.client.CampaignResp(action_config.MSG_CAMPAIGN_LEAVE, 0, {})
        end
    end
end

function ActivityMgr:StartActivity(user_data)
--
--    --先把上一次活动关了
--    self:StopActivity()
--
--    local activity = gActivityData:getActivity(id)
--
--    if activity then
--        if id == 1 then
--            --首先向全服发送世界公告
--            if activity['notice'] then
--                global_data:activity_req(CHANNEL.WORLD, activity['notice'], activity['id'])
--            end
--            --记录活动的开始时间
--            self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_LAST_MATCH_TIME] = os.time()
--            self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_MATCH_TIMER_ID] = self:addTimer(activity['param1'], activity['param1'], id + 2000)
--
--            --然后设置活动的结束timer
--            if activity['lastTime'] then
--                --每个活动的ID加1000表示该活动的结束timerId
--                self:addTimer(activity['lastTime'], 0, id + 1000)
--                log_game_debug('ActivityMgr:onTimer lastTime', "lastTime=%d;user_data=%d", activity['lastTime'], id)
--            end
--        end
--    end

    local activity = gActivityData:getActivity(user_data)

    if activity then
        --首先向全服发送世界公告
        if activity['notice'] then
            global_data:activity_req(CHANNEL.WORLD, activity['notice'], activity['id'])
            log_game_debug('ActivityMgr:StartActivity start', "user_data=%d", user_data)
        end

        if user_data == 1 then

            --然后设置活动的结束timer
            if activity['lastTime'] then
                --每个活动的ID加1000表示该活动的结束timerId

                --删除老的定时器ID
                if self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_END_TIMER_ID] then
                    self:delTimer(self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_END_TIMER_ID])
                    self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_END_TIMER_ID] = nil
                end

                self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_END_TIMER_ID] = self:addTimer(activity['lastTime'], 0, user_data + 1000)

                log_game_debug('ActivityMgr:StartActivity lastTime', "lastTime=%d;user_data=%d", activity['lastTime'], user_data)
            end

            --如果活动是塔防副本，则需要开始每隔一段时间触发一次匹配的定时器

            if self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_MATCH_TIMER_ID] then
                self:delTimer(self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_MATCH_TIMER_ID])
                self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_MATCH_TIMER_ID] = nil
            end

            self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_MATCH_TIMER_ID] = self:addTimer(activity['param1'], activity['param1'], user_data + 2000)


            --记录活动的开始时间
            self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_LAST_MATCH_TIME] = os.time()

            log_game_debug("ActivityMgr:StartActivity", "param1=%d;user_data=%d", activity['param1'], user_data)

        end

    end

end

function ActivityMgr:StopActivity(id)
    log_game_debug('ActivityMgr:StopActivity', "id=%d", id)

    local activity = gActivityData:getActivity(id)
    if activity then
        if id == 1 then
            --进到这里，则表示该活动应该结束了，通知各个base进程结束
            global_data:activity_finish_req(id)

            --删除匹配定时器
            if self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_MATCH_TIMER_ID] then
                --如果结束的活动是塔防副本，则需要把匹配用的定时器也一并去掉
                self:delTimer(self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_MATCH_TIMER_ID])
            end

            --删除结束定时器
            if self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_END_TIMER_ID] then
                self:delTimer(self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE][TEMPDATA_INDEX_TOWER_DEFENCE_END_TIMER_ID])
            end

            self.TowerDefenceWaitingList = {}
            self.TowerDefenceWaitingMapList = {}
            self.TempData[TEMPDATA_INDEX_TOWER_DEFENCE] = {}
            self:ResetDefenceId()
        end
    end
end