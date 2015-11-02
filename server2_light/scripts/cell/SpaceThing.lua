-- Create by Kevinhua
-- Modifed by Kevinhua
-- User: Administrator
-- Date: 13-3-19
-- Time: 15:55
-- 场景物体.
--


local public_config = require "public_config"
require "lua_util"
require "error_code"
require "CellEntity"
--AI

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning


------------------------------------------------------------------------------------------------
SpaceThing = {}
setmetatable(SpaceThing, CellEntity)
------------------------------------------------------------------------------------------------


function SpaceThing:__ctor__()
    self.c_etype = public_config.ENTITY_TYPE_SPACETHING
end

function SpaceThing:onEnterSpace()
    local sp = g_these_spaceloaders[self:getSpaceId()] 
    if sp then
        self.sp_ref = sp 
    end

end

function SpaceThing:Start()
end

function SpaceThing:Stop()
end

---------------------------------------属性begin----------------------------------------------

function SpaceThing:addHp(value)
    local curHp = self.curHp
    if curHp <= 0 then
        if curHp + value > 0 then
            --复活
            curHp = curHp + value
            self.curHp = curHp
            self:TestDeath()
        end
    elseif curHp > 0 then
        if curHp + value <= 0 then
            --死亡
            curHp = 0
            self.curHp = curHp
            self:TestDeath()
        else
            --扣血但没死(可能是加血)
            curHp = curHp + value
            self.curHp = curHp
        end
    end

end

function SpaceThing:setHp(value)
    if self.battleProps.hp then
        if value > self.battleProps.hp then
            self.curHp = self.battleProps.hp
        elseif value <= 0 then
            self.curHp = 0
        else
            log_game_debug("SpaceThing:setHp", "curHp = %d, value = %d", self.curHp, value)
            self.curHp = value  
        end
        self:TestDeath()
    else
        log_game_warning("SpaceThing:setHp", "self.battleProps.hp is nil.")
    end
end

function SpaceThing:IsDeath()
--    local result = mogo.stest(self.CellState, public_config.STATE_DEATH)
    if result == 0 then
        return false
    else
        return true
    end
--    return self.deathFlag == 1
end

function SpaceThing:TestDeath()
    local curHp = self.curHp
    if curHp > 0 then
--        mogo.sunset(self.CellState, public_config.STATE_DEATH)
--        self.deathFlag = 0
    else
--        mogo.sset(self.CellState, public_config.STATE_DEATH)
--        self.deathFlag = 1
        self:ProcessDie()
    end
end

function SpaceThing:ProcessDie()
    if self.curHp <= 0 then
    end
    
end

function SpaceThing:RecalculateBattleProperties()
end

return SpaceThing


