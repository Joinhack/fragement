--author:hwj
--date:2013-6-14
--此为世界boss hp管理类

require "public_config"
require "lua_util"
require "error_code"
require "worldboss_config"

local log_game_info = lua_util.log_game_info
local log_game_debug = lua_util.log_game_debug
local log_game_error = lua_util.log_game_error

--g_wb_config.SYN_HP_TIME = 5000 --2秒同步一次
decrease_type = {ABS = 1, PER = 2,}

BossHpSynMode = {
	timer = 1,
	per   = 2,
	mix   = 3,
}

BossHpMgr = {}
BossHpMgr.__index = BossHpMgr

--------------------------------------------------------------------------------------
--当mode == BossHpSynMode.timer 需要funcTimer
function BossHpMgr:new(owner, bossHp, mode, self_decrease_fun)
	local newObj = {}
	setmetatable(newObj, {__index = BossHpMgr})
	newObj.ptr = {}
    setmetatable(newObj.ptr, {__mode = "v"})
    newObj.ptr.theOwner = owner

    newObj.Info = {
    --cell = mailbox, boss = list
    } --地图信息

    --boss血量、血量广播方式
    newObj.bossMaxHp = bossHp
    newObj.bossHp = newObj.bossMaxHp
    newObj.lastHp = newObj.bossMaxHp
    newObj.mode = mode
    newObj.killerId = 0
    newObj.tmpHp = g_wb_config.HP_CHANGE * newObj.bossMaxHp / 100
    newObj.isStart = false
    newObj.localTimerId = 0
    
    newObj.hitTime = 0 --for test
    newObj.synTime = 0 --for test

    newObj.timer_ids = {} --血量自扣定时器
    newObj.self_decrease_fun = self_decrease_fun

    log_game_debug("BossHpMgr:new", "")
    --如果是定时模式则开启定时更新器
    --[[
    if not owner.SynByTimer then
    	log_game_debug("BossHpMgr:new", "owner.SynByTimer is nil.")
    --if mode == BossHpSynMode.timer then
    	function owner:SynByTimer()
    		newObj:SynByTimer()
    	end
    	--owner:addLocalTimer("SynByTimer", g_wb_config.SYN_HP_TIME, 0)
    end
	]]
    return newObj
end

--注册一个boss
function BossHpMgr:Register(map_id, cellMbStr, eid)
	log_game_debug("BossHpMgr:Register", 'map_id = %s, eid = %d', map_id, eid)
	if not self.Info[map_id] then
		self.Info[map_id] = {}
	end
	if not self.Info[map_id].cell then
		self.Info[map_id].cell = mogo.UnpickleCellMailbox(cellMbStr)
	end
	if not self.Info[map_id].boss then
		self.Info[map_id].boss = {}
	end
	for _,v in pairs(self.Info[map_id].boss) do
		if v == eid then return end
	end
	table.insert(self.Info[map_id].boss, eid)
	--如果已经开始马上同步一次血量
	if self.isStart then
		self.Info[map_id].cell.SynWorldBossHp(eid, self:GetCurrentHp())
	end
end

--销注一个boss
function BossHpMgr:Unregister(map_id, eid)
	log_game_debug("BossHpMgr:Unregister", 'map_id = %s, eid = %d', map_id, eid)
	if not self.Info[map_id] then return 0 end
	for k,v in pairs(self.Info[map_id].boss) do
		if v == eid then 
			table.remove(self.Info[map_id].boss, k)
			break
		end
	end
	return #self.Info[map_id].boss
end

function BossHpMgr:Start()
--	log_game_debug("BossHpMgr:Start", "")
	if self.isStart then return end
	self.isStart = true
	if self.mode == BossHpSynMode.timer then
		local owner = self.ptr.theOwner
		if not owner.SynByTimer then
	    	log_game_debug("BossHpMgr:Start", "owner.SynByTimer is nil.")
	    --if mode == BossHpSynMode.timer then
	    	--[[
	    	function owner:SynByTimer()
	    		self:SynByTimer()
	    	end
	    	]]
	    	--owner.SynByTimer = self.SynByTimer
	    	--owner:addLocalTimer("SynByTimer", g_wb_config.SYN_HP_TIME, 0)
	    end
	    if self.localTimerId == 0 then
	    	self.localTimerId = owner:addLocalTimer("SynByTimer", g_wb_config.SYN_HP_TIME, 0)
	    end
	end
	self:StartHpSelfDecrease()

	self:Reset()
end

function BossHpMgr:Stop()
	if not self.isStart then return end
	self.isStart = false
	if self.localTimerId ~= 0 then
		self.ptr.theOwner:delLocalTimer(self.localTimerId)
		self.localTimerId = 0
		--mgr:addLocalTimer("SynByTimer", g_wb_config.SYN_HP_TIME, 0)
	end
	--[[
	if lua_util.get_table_real_count(self.Info) > 0 then
		log_game_error("BossHpMgr:Stop", "")
	end
	]]
	self:StopHpSelfDecrease()

	self.Info = {}
end

function BossHpMgr:Reset()
    self.bossHp = self.bossMaxHp
    self.lastHp = self.bossMaxHp
    self.killerId = 0
end

function BossHpMgr:UpdateHp(playerId, hp, mod)
	if not self.isStart then
		return 
	end
	self.hitTime = self.hitTime + 1
	if mod == g_wb_config.HP_ADD_MOD then
		self.bossHp = self.bossHp + hp
		if self.bossHp > self.bossMaxHp then
			self.bossHp = self.bossMaxHp
		end
	else
		local t_hp = self.bossHp - hp
		if t_hp <= 0 then
			if playerId > 0 then
				self:BossDie(playerId)
				self.bossHp = 0
			end
		else
			self.bossHp = t_hp
		end
	end
	--log_game_debug("BossHpMgr:UpdateHp============", "hitTime[%d], playerId[%d], hp[%d], curHp[%d] ", self.hitTime, playerId, hp, self.bossHp)
	self:SynByPer()
end

--白分比更新
function BossHpMgr:SynByPer()
	--log_game_debug("BossHpMgr:SynByPer", "")
	if not self.isStart then
		return 
	end
	if self.mode == BossHpSynMode.per then
		if self.lastHp - self.bossHp > self.tmpHp or 
			self.bossHp - self.lastHp > self.tmpHp then
			self:SynWorldBossHp()
			self.lastHp = self.bossHp
		end
	end
end

--定时更新
function BossHpMgr:SynByTimer()
	if not self.isStart then
		return 
	end
	if self.mode == BossHpSynMode.timer then
		self:SynWorldBossHp()
	end
end

--同步boss血量
function BossHpMgr:SynWorldBossHp()
	--self.ptr.mgr.SynWorldBossHp(self.bossHp)
	--log_game_debug("BossHpMgr:SynWorldBossHp", "")
	for map_id, v in pairs(self.Info) do
		for _, eid in pairs(v.boss) do
			v.cell.SynWorldBossHp(eid, self.bossHp)
			--log_game_debug("BossHpMgr:SynWorldBossHp", "eid[%d], self.bossHp[%d]", eid, self.bossHp)
		end
	end
	self.synTime = self.synTime + 1
	--log_game_debug("BossHpMgr:SynWorldBossHp*********", "synTime[%d], curHp[%d]", self.synTime, self.bossHp)
end

function BossHpMgr:BossDie(playerId)
	self.killerId= playerId
	--
	self.ptr.theOwner:BossDie(playerId)
end

function BossHpMgr:GetCurrentHp()
	return self.bossHp
end
--变更血量同步方式
function BossHpMgr:ChangeMod(mod)
	
	if self.mod == BossHpSynMode.timer and self.localTimerId ~= 0 then
		self.ptr.theOwner:delLocalTimer(self.localTimerId)
		self.localTimerId = 0
		self.ptr.theOwner.SynByTimer = nil
		--mgr:addLocalTimer("SynByTimer", g_wb_config.SYN_HP_TIME, 0)
	end

	if mod == BossHpSynMode.timer then
		local owner = self.ptr.theOwner
		if not owner.SynByTimer then
	    	log_game_debug("BossHpMgr:Start", "owner.SynByTimer is nil.")
	    --if mode == BossHpSynMode.timer then
	    	--[[
	    	function owner:SynByTimer()
	    		self:SynByTimer()
	    	end
	    	]]
	    	--owner:addLocalTimer("SynByTimer", g_wb_config.SYN_HP_TIME, 0)
	    end
	    if self.localTimerId == 0 then
	    	self.localTimerId = owner:addLocalTimer("SynByTimer", g_wb_config.SYN_HP_TIME, 0)
	    end
	end

	self.mode = mod
end

function BossHpMgr:GetMod()
	return self.mode
end

function BossHpMgr:GetKiller()
	return self.killerId
end

function BossHpMgr:StartHpSelfDecrease()
	local hp_ctrl_val = g_wb_config.HP_SELF_DECREASE_VAL
	local bp_ctrl_per = g_wb_config.HP_SELF_DECREASE_PERCENT
	local interval = g_wb_config.HP_SELF_DECREASE_INTERVAL
	local owner = self.ptr.theOwner
	if hp_ctrl_val > 0 then
		local id = owner:addLocalTimer(self.self_decrease_fun, interval * 1000, 0, decrease_type.ABS, hp_ctrl_val)
		self.timer_ids[id] = true
	end
	if bp_ctrl_per > 0 then
		local id = owner:addLocalTimer(self.self_decrease_fun, interval * 1000, 0, decrease_type.PER, bp_ctrl_per)
		self.timer_ids[id] = true
	end
end

function BossHpMgr:StopHpSelfDecrease()
	local owner = self.ptr.theOwner
	for id,_ in pairs(self.timer_ids) do
		if owner:hasLocalTimer(id) then
			owner:delLocalTimer(id)
		end
		self.timer_ids[id] = nil
	end
end
--[[
function BossHpMgr:ResetBossHp()
	log_game_debug("BossHpMgr:ResetBossHp", "monsterId = %d", monsterId)
	local mosterData = g_monster_mgr:getCfgById(monsterId)
	self.bossMaxHp = mosterData.hpBase
	self.bossHp = mosterData.hpBase
	self.lastHp = mosterData.hpBase
end
]]