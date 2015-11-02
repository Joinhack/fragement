
require "lua_util"

local log_game_debug = lua_util.log_game_debug
local _readXml = lua_util._readXml

local ActivityData = {}
ActivityData.__index = ActivityData

function ActivityData:initData()
    self.activityTime = _readXml('/data/xml/ActivityTime.xml', 'weekDay_i')

    self.activities = _readXml('/data/xml/Activity.xml', 'id_i')

    self.activityReward = {}

--    local tmp = _readXml('/data/xml/ActivityReward.xml', 'id_i')
--    for _, v in pairs(tmp) do
    self.activityReward = _readXml('/data/xml/ActivityReward.xml', 'id_i')
--    end

--    log_game_debug("ActivityData:initData", "activityReward=%s",  mogo.cPickle(self.activityReward))
end

function ActivityData:getActivityTime(weekday)
    return self.activityTime[weekday] or {}
end

function ActivityData:getActivityLevel(ActivityId)
    local activity = self.activities[ActivityId] or {}
    return activity['level']
end

function ActivityData:getActivity(ActivityId)
    return self.activities[ActivityId]
end

--根据波数和玩家等级获取
function ActivityData:getTowerDefenceReward(wave, level)
    for _, v in pairs(self.activityReward) do
        if v['wave'] == wave and level >= v['level'][1] and level <= v['level'][2] then
            return v
        end
    end
    return {}
end

gActivityData = ActivityData
return gActivityData