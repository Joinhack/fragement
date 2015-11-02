
require "lua_util"

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info

TeleportPointSrc = {}
setmetatable(TeleportPointSrc, {__index = BaseEntity} )


--构造函数
function TeleportPointSrc:__ctor__()
    log_game_debug("TeleportPointSrc:__ctor__", "id=%d;targetSceneId=%d;targetX=%d;targetY=%d",
                                                 self:getId(), self.targetSceneId, self.targetX, self.targetY)
end

function TeleportPointSrc:onGetCell()
    log_game_debug("TeleportPointSrc:onGetCell", string.format("id=%d", self:getId()))
end

