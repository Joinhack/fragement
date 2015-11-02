
require "lua_util"
require "public_config"

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info

TeleportPointSrc = {}
setmetatable(TeleportPointSrc, {__index = CellEntity} )

--构造函数
function TeleportPointSrc:__ctor__()
    log_game_debug("TeleportPointSrc.__ctor__", "id=%d;targetSceneId=%d;targetX=%d;targetY=%d",
                                                 self:getId(), self.targetSceneId, self.targetX, self.targetY)

    self.c_etype = public_config.ENTITY_TYPE_TELEPORTSRC
end

--当cell对象进入Space时由引擎回调
function TeleportPointSrc:onEnterSpace()
    log_game_debug("TeleportPointSrc:onEnterSpace", "spaceId=%d", self:getSpaceId())

end
