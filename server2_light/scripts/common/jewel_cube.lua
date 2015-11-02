require "lua_util"
require "public_config"

local log_game_debug = lua_util.log_game_debug
local log_game_error = lua_util.log_game_error

local JewelCube = {}

JewelCube.__index = JewelCube

function JewelCube:initData()
    self.jewelCube  = lua_util._readXml("/data/xml/JewelCube.xml", "id_i")
    --log_game_debug("jewelCube:initData", "jewelCube = %s", mogo.cPickle(self.jewelCube))
    for k, v in pairs(self.jewelCube) do
        v.allVoc = v.allVoc or {}
        for tk, tv in pairs(v.allVoc) do
            v.warrior = v.warrior or {}
            table.insert(v.warrior, tv)

            v.assassin = v.assassin or {}
            table.insert(v.assassin, tv)

            v.archer = v.archer or {}
            table.insert(v.archer, tv)

            v.mage = v.mage or {}
            table.insert(v.mage, tv)
        end
        v.allVoc = nil
    end
    --log_game_debug("jewelCube:initData", "jewelCube = %s", mogo.cPickle(self.jewelCube))
end

function JewelCube:GetJewelRewards(idx)
    if self.jewelCube  then
        return self.jewelCube[idx]
    end
end

function JewelCube:GetVocationReward(idx, vocation)
    --log_game_debug("JewelCube:GetVocationReward", "idx = %d, vocation = %d", idx, vocation)
    local rewards = self:GetJewelRewards(idx)
    if rewards == nil then
        return nil, nil
    end
    --log_game_debug("JewelCube:GetVocationReward", "%s", mogo.cPickle(rewards))
    local rewds = {}
    if vocation == public_config.VOC_WARRIOR then
        rewds = rewards.warrior
    elseif vocation == public_config.VOC_ASSASSIN then
        rewds = rewards.assassin
    elseif vocation == public_config.VOC_ARCHER then
        rewds = rewards.archer
    elseif vocation == public_config.VOC_MAGE then
        rewds = rewards.mage
    end
    --log_game_debug("JewelCube:GetVocationReward", "%s", mogo.cPickle(rewds))
    local allWeight = 0
    for i = 3, #rewds, 3 do
        if rewds[i] == nil then
            log_game_error("JewelCube:GetVocationRewards", "jewelCube configure error")
            return
        end
        allWeight = allWeight + rewds[i]
    end
    math.randomseed(os.time())
    local rData = math.random(1, allWeight)
    --log_game_debug("JewelCube:GetVocationReward", "rData = %d, allWeight = %d", rData, allWeight)
    tpWeight = 0
    for i = 3, #rewds, 3 do
        tpWeight = tpWeight + rewds[i]
        if tpWeight >= rData then
            return rewds[i - 2], rewds[i - 1]
        end
    end
end

g_jewelCube_mgr = JewelCube

return g_jewelCube_mgr
