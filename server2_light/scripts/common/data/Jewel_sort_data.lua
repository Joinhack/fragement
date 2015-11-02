require "lua_util"

local log_game_debug = lua_util.log_game_debug
local log_game_error = lua_util.log_game_error

local JewelSortData = {}
JewelSortData.__index = JewelSortData

function JewelSortData:initData()
    local JewelSData = lua_util._readXml("/data/xml/JewelSort.xml", "id_i")
    if not JewelSData then
    	log_game_error("JewelSortData:initData", "JewelSort.xml error!")
    	return
    end
    self.CfgData = JewelSData
end

function JewelSortData:GetJewelInlaySort()
    if self.CfgData then
        return self.CfgData
    end
end
function JewelSortData:GetPriorityIdx(subType)
	if not self.CfgData then
		return 0
	end
	for _, item in pairs(self.CfgData) do
		local jewType = item.jewel or 0
		if jewType == subType then
			return item.id
		end
	end
	return 0
end
function JewelSortData:GetMinSortIdx()
	if not self.CfgData then
		return 0
	end
	local minIdx = 10000000
	for idx, _ in pairs(self.CfgData) do
		if minIdx > idx then
			minIdx = idx
		end
	end
	return minIdx
end
function JewelSortData:GetMaxSortIdx()
	if not self.CfgData then
		return 0
	end
	local maxIdx = -1
	for idx, _ in pairs(self.CfgData) do
		if maxIdx < idx then
			maxIdx = idx
		end
	end
	return maxIdx
end
g_JewelSort_mgr = JewelSortData
return g_JewelSort_mgr