
require "lua_util"
require "public_config"
require "GlobalParams"

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info


global_data = {}
global_data.__index = global_data


local _BASEDDATE_KEY_AVATAR_CHANNEL  = 1
local _BASEDDATE_KEY_ACTIVITY        = 2
local _BASEDDATE_KEY_ACTIVITY_FINISH = 3
local _BASEDDATE_KEY_SHOWTEXT_TO_WORLD = 4

function global_data.onBaseData(key, value)

    if type(value) == 'number' then
        log_game_debug("global_data.onBaseData", "key=%s;value=%d", key, value)
    end

--    log_game_debug("global_data.onBaseData", "key=%s", key)

    local self = global_data
    if tonumber(key) == _BASEDDATE_KEY_AVATAR_CHANNEL then
--        log_game_debug("global_data.onBaseData", "key=%s;value=%s", key, mogo.cPickle(value))
        self:on_channel_req(value)
    elseif tonumber(key) == _BASEDDATE_KEY_ACTIVITY then
        log_game_debug("global_data.onBaseData", "key=%s;value=%s", key, mogo.cPickle(value))
        self:on_activity_req(tonumber(key), value)
    elseif tonumber(key) == _BASEDDATE_KEY_ACTIVITY_FINISH then
        self:on_activity_finish_req(tonumber(key), value)
    elseif tonumber(key) == _BASEDDATE_KEY_SHOWTEXT_TO_WORLD then
        self:on_showtextid(value)        
    else
        global_data[key] = value
    end

end

function global_data.GetBaseData(key)
    return global_data[key]
end

--判断活动是否开启中
function global_data.GetActivityStartTime(ActivityId)
    local activities = global_data[_BASEDDATE_KEY_ACTIVITY] or {}
    return activities[ActivityId]
end

function global_data.GetServerTime(TimeType)
    if TimeType ==  public_config.SERVER_TIMESTAMP then
        return os.time()
    elseif TimeType == public_config.SERVER_PASSTIME then
        local ServerStartTime = global_data.GetBaseData(public_config.BASE_DATA_KEY_GAME_START_TIME) or os.time()
        return os.time() - ServerStartTime
    elseif TimeType == public_config.SERVER_SERVER_START_TIME then
        return g_GlobalParamsMgr:GetParams('server_start_time', os.time())
    elseif TimeType == public_config.SERVER_TIMEZONE then
        return mogo.getTimeZone()
    elseif TimeType == public_config.SERVER_TICK then
        return mogo.getTickCount()
    end
end


--  %a abbreviated weekday name (e.g., Wed)
--  %A full weekday name (e.g., Wednesday)
--  %b abbreviated month name (e.g., Sep)
--  %B full month name (e.g., September)
--  %c date and time (e.g., 09/16/98 23:48:10) 
--  %d day of the month (16) [01-31]
--  %F 年-月-日
--  %H hour, using a 24-hour clock (23) [00-23]
--  %I hour, using a 12-hour clock (11) [01-12]
--  %j 十进制表示的每年的第几天
--  %M minute (48) [00-59]
--  %m month (09) [01-12]
--  %p either "am" or "pm" (pm)
--  %S second (10) [00-61]
--  %w weekday (3) [0-6 = Sunday-Saturday]
--  %x date (e.g., 09/16/98)
--  %X time (e.g., 23:48:10)
--  %Y full year (1998)
--"*t" {year = 1998, month = 9, day = 16, yday = 259, wday = 4, hour = 23, min = 48, sec = 10, isdst = false}
--根据格式获得当前时间 其实就是os.date  format 是上述格式
function global_data.GetCurTimeByFormat(format)
    return os.date(format, global_data.GetServerTime(public_config.SERVER_TIMESTAMP))   
end

function global_data.GetTimeByFormat(time, format) --time 为时间戳
    return os.date(format, time)   
end

-- 获得昨天日期  格式2013-06-05  (字符串)
function global_data.GetYesterday()
    local tab = os.date("*t", global_data.GetServerTime(public_config.SERVER_TIMESTAMP))
    tab.day = tab.day - 1
    local yesterday = os.time(tab)
    return os.date("%F", yesterday)   
end


-- 获得服务器开启后第几天的日期 格式20130605 （开服为第一天）
function global_data.GetDayAfterSeverStart(day)
    local tab = os.date("*t", global_data.GetServerTime(public_config.SERVER_SERVER_START_TIME))
    tab.day = tab.day + day - 1    -- 开服为第一天，所以要减一
    local day_ = os.time(tab)
    local tab_ = os.date("*t", day_) 
    local format = string.format("%d%02d%02d",tab_.year, tab_.month, tab_.day)
    return tonumber(format)
end

-- 获得当天日期 格式20130605 
function global_data.GetCurDay()
    local tab = os.date("*t", global_data.GetServerTime(public_config.SERVER_TIMESTAMP))
    local format = string.format("%d%02d%02d",tab.year, tab.month, tab.day)
    return tonumber(format)
end


--是不是在同一周内(tab1,tab2 为时间table  用"*t"得到而来)
function global_data.IsInSameWeek(tab1, tab2)
    local week1 = tab1.wday - 1  --星期日为1 所以要减1 
    local week2 = tab2.wday - 1
    if week1 == 0 then week1 = 7 end 
    if week2 == 0 then week2 = 7 end 

    --为了不改变参数 这里临时复制下  
    --  os.date("*t", 0)   --> {day = 1, hour = 8, isdst = false, min = 0, month = 1, sec = 0, wday = 5, yday = 1, year = 1970} --[[table: 05C117C8]]
    
    local tmp1 = os.date("*t", 0)  
    local tmp2 = os.date("*t", 0)
    tmp1.day    = tab1.day 
    tmp1.hour   = tab1.hour
    tmp1.isdst  = tab1.isdst
    tmp1.month  = tab1.month
    tmp1.year   = tab1.year

    tmp2.day    = tab2.day 
    tmp2.hour   = tab2.hour
    tmp2.isdst  = tab2.isdst
    tmp2.month  = tab2.month
    tmp2.year   = tab2.year

    tmp1.day = tmp1.day - week1
    tmp2.day = tmp2.day - week2 


    local monday1 = os.time(tmp1) --tab1当周的星期一
    local monday2 = os.time(tmp2) --tab2 当周的星期一

    return monday1 == monday2

end

--初始化数据
function global_data:init_data()
    --本进程的玩家数据
    self._users = {__mode='v'}
end

--玩家上线注册
function global_data:register(avatar)
    self._users[avatar.dbid] = avatar
end

--玩家下线注销
function global_data:deregister(avatar)
    self._users[avatar.dbid] = nil
end

--向世界频道发送玩家消息
function global_data:channel_req(ch_id, dbid, name, to_dbid, msg, level)
    mogo.setBaseData(_BASEDDATE_KEY_AVATAR_CHANNEL, {ch_id, dbid, name, to_dbid, msg, level})
end

--活动开始向所有玩家发公告
function global_data:activity_req(ch_id, msg, activityId)
    mogo.setBaseData(_BASEDDATE_KEY_ACTIVITY, {ch_id, msg, activityId})
end

--
function global_data:activity_finish_req(activityId)
    mogo.setBaseData(_BASEDDATE_KEY_ACTIVITY_FINISH, {activityId})
end

--给世界上每个人发texteID 消息
function global_data:ShowTextID(channelID, textID, args)
    mogo.setBaseData(_BASEDDATE_KEY_SHOWTEXT_TO_WORLD, {channelID, textID, args})
end

----向世界频道发送系统消息
--function global_data:sys_info(sys_id, params_str)
--    mogo.setBaseData(_BASEDDATE_KEY_SYS_INFO, {sys_id, params_str})
--end

--触发了玩家聊天
function global_data:on_channel_req(basedata)
--    log_game_debug("global_data.on_channel_req", "basedata=%s", mogo.cPickle(basedata))
    local ChannelId = basedata[1]
    local from_dbid = basedata[2]
    local from_name = basedata[3]
    local to_dbid = basedata[4]
    local text = basedata[5]
    local level = basedata[6]
--    local item_data = ''

    for k,u in pairs(self._users) do
        local has_client_f = u.hasClient
        if has_client_f and has_client_f(u) then
--            log_game_debug("global_data.on_channel_req", "ChannelId=%d;from_name=%s;text=%s;name=%s", ChannelId, from_name, text, u.name)
            u.client.ChatResp(ChannelId, from_dbid, from_name, level, text)
--            u.client.channel_resp(ch_id, from_name, text, item_data)
        end
    end
end

function global_data:on_activity_req(key, basedata)
    local ChannelId = basedata[1]
    local msg = basedata[2]
    local activityId = basedata[3]

    for _, u in pairs(self._users) do
        local has_client_f = u.hasClient
        if has_client_f and has_client_f(u) then
            u.client.CampaignResp(action_config.MSG_CAMPAIGN_NOTIFY_TO_CLIENT_START, 0, {activityId,})
--            log_game_debug("global_data.on_activity_req", "basedata=%s;global_data=%s", mogo.cPickle(basedata), mogo.cPickle(global_data))
        end
    end

--    log_game_debug("global_data.on_activity_req", "basedata=%s;global_data=%s", mogo.cPickle(basedata), mogo.cPickle(global_data))

    local activities = global_data[key] or {}
    activities[activityId] = os.time()
    global_data[key] = activities

    --设置全局数据，标识活动开始
--    log_game_debug("global_data.on_activity_req", "basedata=%s;global_data=%s", mogo.cPickle(basedata), mogo.cPickle(global_data))

end

function global_data:on_activity_finish_req(key, basedata)
    local activityId = basedata[1]
    local activities = global_data[_BASEDDATE_KEY_ACTIVITY] or {}
    activities[activityId] = nil
    global_data[_BASEDDATE_KEY_ACTIVITY] = activities

    for _, u in pairs(self._users) do
        local has_client_f = u.hasClient
        if has_client_f and has_client_f(u) then
            u.client.CampaignResp(action_config.MSG_CAMPAIGN_NOTIFY_TO_CLIENT_FINISH, 0, {activityId,})
        end
    end

    --设置全局数据，标识活动结束
--    log_game_debug("global_data.on_activity_finish_req", "basedata=%s;global_data=%s", mogo.cPickle(basedata), mogo.cPickle(global_data))
end

--showtextid给所有人
function global_data:on_showtextid(basedata)
--    log_game_debug("global_data.on_channel_req", "basedata=%s", mogo.cPickle(basedata))
    local channelID = basedata[1]
    local textID = basedata[2]
    local args = basedata[3]

    local bArgs = next(args)
    for k,u in pairs(self._users) do
        local has_client_f = u.hasClient
        if has_client_f and has_client_f(u) then

            --log_game_debug("global_data.on_showtextid", "ChannelId=%s;textID=%s;args=%s", t2s(args)) 
            if bArgs  then
                u.client.ShowTextIDWithArgs(channelID, textID, args)
            else
                u.client.ShowTextID(channelID, textID)
            end
        end
    end
end

return global_data