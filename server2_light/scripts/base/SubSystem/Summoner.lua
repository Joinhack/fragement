--author:hwj
--date:2013-8-6
--召唤器：用于世界boss召唤小怪，spawnpointId不要配置在场景里，这样子防止非法刷怪

local log_game_debug = lua_util.log_game_debug
local log_game_warning = lua_util.log_game_warning
local log_game_info = lua_util.log_game_info
local log_game_error = lua_util.log_game_error

Summoner = {}
--setmetatable(Summoner, {__index=Summoner})
Summoner.__index = Summoner


--[[参数说明
mod:
spawnTimeList: v:sec
funcName:  按时间顺序调用的owner的函数的名称funcName(timerId, count, spawnId, mod)
]]
function Summoner:new(owner, mod, spawnTimeList, funcName)
	local newObj = {}
	setmetatable(newObj, {__index=Summoner})
	newObj.ptr = {}
    setmetatable(newObj.ptr, {__mode = "v"})
	newObj.ptr.theOwner = owner

	newObj:init(mod, spawnTimeList, funcName)

	return newObj
end

function Summoner:init(mod, spawnTimeList, funcName)
	self.m_mode = mod
	self.m_spawnTimeList = spawnTimeList --v:sec
	self.m_funcName = funcName
	self.timerIds = {}
end

function Summoner:Start()
	log_game_debug("Summoner:Start", "self.m_funcName[%s], self.m_mode[%d], self.m_spawnTimeList[%s]", 
		self.m_funcName, self.m_mode, mogo.cPickle(self.m_spawnTimeList))
	local spawnId = 1
	local owner = self.ptr.theOwner
	for _, sec in pairs(self.m_spawnTimeList) do
		local id = owner:addLocalTimer(self.m_funcName, sec * 1000, 1, spawnId, self.m_mode)
		spawnId = spawnId + 1
		table.insert(self.timerIds, id)
	end
end

function Summoner:Stop()
	local theOwner = self.ptr.theOwner
	for i,v in ipairs(self.timerIds) do
		if theOwner:hasLocalTimer(v) then
			theOwner:delLocalTimer(v)
		end
		self.timerIds[i] = nil
	end
end

return Summoner