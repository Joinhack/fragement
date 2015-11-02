require "lua_util"
require "behaviors"

local _readXml = lua_util._readXml
local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local _splitStr = lua_util.split_str

local BehaviorMgr = {}
BehaviorMgr._index = BehaviorMgr

function BehaviorMgr:init_data()
    local tmp = _readXml("/data/xml/Behavior.xml", "id_i")     
    
    for k, v in pairs(tmp) do
        local tblParams = _splitStr(v['params'], ',')
        tmp[k].tblParams = tblParams
    end


    self.behaviorData = tmp
end


function BehaviorMgr:executeBehavior(behaviorId, avatar, spaceLoader)
--[[
    if avatar == nil then--or spaceLoader == nil 
        return false
    end
--]]
    local tmpBehaviorData = self.behaviorData[behaviorId]
    if tmpBehaviorData == nil then
        return false
    end

    local func = BehaviorFuncs[behaviorId] 
    if func == nil then
        return false
    end
    
    local rnt = func(avatar, spaceLoader, tmpBehaviorData.tblParams)
    if rnt == true and 
        tmpBehaviorData.trueNextId ~= nil and 
        tmpBehaviorData.trueNextId > 0 then
        rnt = self:executeBehavior(tmpBehaviorData.trueNextId, avatar, spaceLoader)
    elseif rnt == false and 
        tmpBehaviorData.falseNextId ~= nil and 
        tmpBehaviorData.falseNextId > 0 then
        rnt = self:executeBehavior(tmpBehaviorData.falseNextId, avatar, spaceLoader)
    end
    

    return rnt
end

return BehaviorMgr
