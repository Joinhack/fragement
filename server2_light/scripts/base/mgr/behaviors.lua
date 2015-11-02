require "lua_util"

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning

BehaviorFuncs = {}

local BehaviorIds = {
    ADD_PROPERTY_ALWAYS = 1,
    LEARN_NEW_SKILL = 2,
}


BehaviorFuncs[BehaviorIds.ADD_PROPERTY_ALWAYS] = function (avatar, spaceLoader, tblParams)
    return false
end


BehaviorFuncs[BehaviorIds.LEARN_NEW_SKILL] = function (avatar, spaceLoader, tblParams)
    return false
end


return BehaviorFuncs
