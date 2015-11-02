require "lua_util"


local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_error = lua_util.log_game_error

local ItemEffect = {}

ItemEffect.__index = ItemEffect
--初始化道具配置效果配置表
function ItemEffect:initData()
    local ieffect = lua_util._readXml("/data/xml/ItemEffect.xml", "id_i")
    self.EData = ieffect
end
--根据效果tbl，通过随机值获取对应的奖励
function ItemEffect:GetReward(itb) 
    --log_game_debug("ItemEffect:GetReward", "----------start-------")
    local prob = {}
    if itb.random == nil then
        log_game_error("ItemEffect:GetReward", "random data error")
        return 
    end
    for k, v in pairs(itb.random) do
        table.insert(prob, v/100)
    end
    local rtn = lua_util.choice(prob)
    --log_game_debug("ItemEffect：GetReward", "------return number = %s------", tostring(rtn))
    if rtn == 1 then
        return itb.reward1
    elseif rtn == 2 then
        return itb.reward2
    elseif rtn == 3 then
        return itb.reward3
    end
end
--根据效果eId获取对应的配置项
function ItemEffect:GetEffect(eId)
    local itbl = self.EData[eId]
    if itbl == nil then
        log_game_error("ItemEffect:GetEffect", "effect id = %s error", tostring(eId))
        return
    end
    return itbl
end

item_effect_mgr = ItemEffect

return  item_effect_mgr

