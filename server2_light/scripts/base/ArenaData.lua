--
-- Created by IntelliJ IDEA.
-- User: jh
-- Date: 13-9-28
-- Time: 下午2:04
-- To change this template use File | Settings | File Templates.
--

local globalbase_call = lua_util.globalbase_call
local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error

--------------------------------------------------------------------------------------------------------------------
ArenaData = {}
ArenaData.__index = ArenaData
--------------------------------------------------------------------------------------------------------------------

--mogo.loadEntitiesOfType("ArenaData")的回调方法
--注意:这个方法不需要entity
function ArenaData.onEntitiesLoaded(count)
    log_game_info("ArenaData.onEntitiesLoaded", "count=%d", count)

    lua_util.globalbase_call('ArenaMgr', 'SetArenaDataCount', count)
end

function ArenaData:__ctor__()
    local eid = self:getId()
    --log_game_debug("ArenaData:__ctor__", "id=%d", eid)

    self:registerTimeSave('mysql') --注册定时存盘

    lua_util.globalbase_call('ArenaMgr', 'SetArenaData', eid)
end

function ArenaData:onDestroy()
	local function _dummy(a,b,c)
        log_game_error("ArenaData:writeToDB", "")
    end
    self:writeToDB(_dummy)
end
--------------------------------------------------------------------------------------------------------------------
return ArenaData

