local globalbase_call = lua_util.globalbase_call
local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error

--------------------------------------------------------------------------------------------------------------------
WorldBossData = {}
WorldBossData.__index = WorldBossData
--------------------------------------------------------------------------------------------------------------------

--mogo.loadEntitiesOfType("WorldBossData")的回调方法
--注意:这个方法不需要entity
function WorldBossData.onEntitiesLoaded(count)
    log_game_info("WorldBossData.onEntitiesLoaded", "count=%d", count)

    lua_util.globalbase_call('WorldBossMgr', 'SetDataCount', count)
end

function WorldBossData:__ctor__()
    local eid = self:getId()
    --log_game_debug("WorldBossData:__ctor__", "id=%d", eid)

    self:registerTimeSave('mysql') --注册定时存盘

    lua_util.globalbase_call('WorldBossMgr', 'SetData', eid)
end

function WorldBossData:onDestroy()
	local function _dummy(a,b,c)
        log_game_error("WorldBossData:writeToDB", "")
    end
    self:writeToDB(_dummy)
end

--------------------------------------------------------------------------------------------------------------------
return WorldBossData