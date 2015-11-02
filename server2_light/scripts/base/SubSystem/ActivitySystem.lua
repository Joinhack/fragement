
-- 活动系统

local log_game_info = lua_util.log_game_info
local log_game_debug = lua_util.log_game_debug
local _readXml = lua_util._readXml

local activityData = {}

ActivitySystem = {}
ActivitySystem.__index = ActivitySystem

function ActivitySystem:__ctor__( ... )
    self.activityData = _readXml('/data/xml/activityData.xml', 'id_i')
end

function ActivitySystem:new( owner )
    local newObj = {}
    setmetatable(newObj, {__index = ActivitySystem, __mode = "kv"})

    newObj.theOwner = owner 
    return newObj
end

function ActivitySystem:initData()
    self.missionData = _readXml('/data/xml/activityData.xml', 'id_i')
end

return ActivitySystem