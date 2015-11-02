---
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 12-8-24
-- Time: 上午11:40
-- 所有cell上entity的基类.
--

require "public_config"
require "lua_util"
require "error_code"


local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local math = math
local _ENTITY_TYPE_AVATAR = public_config.ENTITY_TYPE_AVATAR
local _ENTITY_TYPE_PET = public_config.ENTITY_TYPE_PET
local entity_allclients_rpc = mogo.entity_allclients_rpc
local entity_ownclient_rpc = mogo.entity_ownclient_rpc


------------------------------------------------------------------------------------------------
CellEntity = {}
CellEntity.__index = CellEntity
------------------------------------------------------------------------------------------------

function CellEntity:__ctor__()
    log_game_debug("CellEntity:__ctor__", "id=%d", self:getId())
    self:on_space_changed()
end

--设置速度
function CellEntity:set_speed(speed)
    self.c_speed = speed
    self:setSpeed(math.floor(speed/2))  --通知引擎
end

--进入space时由引擎回调
function CellEntity:onEnterSpace()
--    log_game_debug("CellEntity:onEnterSpace", "id=%d", self:getId())
end

--离开space时由引擎回调
function CellEntity:onLeaveSpace()
--    log_game_debug("CellEntity:onLeaveSpace", "id=%d", self:getId())
end

--space发生变更
function CellEntity:on_space_changed()
    --向本场景管理器注册
    local sp = g_these_spaceloaders[self:getSpaceId()]
    if sp then
        self.sp_ref = sp
    end
end

--cast_spell广播
function CellEntity:bc_cast_spell(target_id, spell_id)
    entity_allclients_rpc(self, 'mpins_cast_spell_resp', self:getId(), target_id, spell_id)
end

--onhit通知给对应的客户端
function CellEntity:bc_on_hit(tgt_entity, hit_ret, dmg)
    local tgt_eid = tgt_entity:getId()   --受击者id

    --如果施法者是玩家或者宠物,要把受击信息发给对应的玩家
    local myetype = self.c_etype
    if myetype == _ENTITY_TYPE_AVATAR then
        entity_ownclient_rpc(self, "mpins_on_hit_resp", tgt_eid, hit_ret, dmg)
    elseif myetype == _ENTITY_TYPE_PET then
        entity_ownclient_rpc(self.avatar_ref, "mpins_on_hit_resp", tgt_eid, hit_ret, dmg)
    end

    --如果受击者是玩家或者宠物,要把受击信息发给对应的玩家
    local tgtetype = tgt_entity.c_etype
    if tgtetype == _ENTITY_TYPE_AVATAR then
        entity_ownclient_rpc(tgt_entity, "mpins_on_hit_resp", tgt_eid, hit_ret, dmg)
    elseif tgtetype == _ENTITY_TYPE_PET then
        entity_ownclient_rpc(tgt_entity.avatar_ref, "mpins_on_hit_resp", tgt_eid, hit_ret, dmg)
    end
end

function CellEntity:onDestroy()
    log_game_debug("CellEntity:onDestroy", self:getId())
end

function CellEntity:RecalculateBattleProperties()
end

------------------------------------------------------------------------------------------------

return CellEntity
