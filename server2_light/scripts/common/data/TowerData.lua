

require "lua_util"

local log_game_debug = lua_util.log_game_debug
local _readXml = lua_util._readXml

local TowerDataMgr = {}
TowerDataMgr.__index = TowerDataMgr

function TowerDataMgr:initData()

    self.towerData = _readXml('/data/xml/TowerReward.xml', 'id_i')
--    log_game_debug("TowerDataMgr:initData", "towerData=%s", mogo.cPickle(self.towerData))

    local tmp = _readXml('/data/xml/TowerSweepCdClearCost.xml', 'id_i')

    self.towerSweepCdClearCost = {}
    for _, v in pairs(tmp) do
        self.towerSweepCdClearCost[v['times']] = v['cost']
    end

--    log_game_debug("TowerDataMgr:initData", "towerSweepCdClearCost=%s", mogo.cPickle(self.towerSweepCdClearCost))

end

--根据试炼之塔的层数获取宝箱奖励
function TowerDataMgr:GetRewardByLevel(level)
    return self.towerData[level] or {}
end

--根据已清除cd的次数获取这次清除cd需要消耗的砖石数
function TowerDataMgr:GetSweepCdClearCost(times)
    return self.towerSweepCdClearCost[times]
end


gTowerDataMgr = TowerDataMgr
return gTowerDataMgr