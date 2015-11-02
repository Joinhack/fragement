---
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 12-8-24
-- Time: 上午11:41
-- 伙伴的战斗实体.
--

local public_config = require "public_config"
require "lua_util"
require "error_code"
require "CellEntity"


local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local math_sqrt = math.sqrt
local math_floor = math.floor


------------------------------------------------------------------------------------------------
Pet = {}
setmetatable(Pet, CellEntity)
------------------------------------------------------------------------------------------------

function Pet:__ctor__()
    CellEntity.__ctor__(self)
    self.c_etype = public_config.ENTITY_TYPE_PET
end

function Pet:think()
    local avatar = self.avatar_ref

    local x2 = avatar:getPosX()
    local y2 = avatar:getPosY()

    --if avatar.c_hp <= 0 then
    --    --玩家死了,瞬移过去
    --    self:setPos(x2, y2)
    --    return
    --end

    local x1 = self:getPosX()
    local y1 = self:getPosY()

    local dx = x2 - x1
    local dy = y2 - y1

    local speed = self.c_speed
    local d2 = dx*dx + dy*dy
    --小于一定范围就不走了
    if d2 <= 0.25*speed*speed then
        return
    end

    --local map_id = avatar.sp_ref.map_id
    --local x3, y3 = mogo.move_simple(x1, y1, x2, y2, speed, map_id)

    local sloop = math_sqrt(d2)
    local x3 = math_floor(x1 + (dx/sloop)*speed)
    local y3 = math_floor(y1 + (dy/sloop)*speed)

    if x3 then
        --修改新的坐标
        self:setPos(x3, y3)
    end

end


------------------------------------------------------------------------------------------------

return Pet


