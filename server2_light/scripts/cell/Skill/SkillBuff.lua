
-- 技能Buff


require "lua_util"
require "lua_map"
require "public_config"


local function DebugOutput(head, pattern, ...)
    local log_to_console = false
    if log_to_console == true then
        print(string.format("[%s]%s", head, string.format(pattern, ...)))
    else
        lua_util.log_game_debug(head, pattern, ...)
    end
end


local log_game_info     = lua_util.log_game_info
local log_game_debug    = DebugOutput
local _readXml          = lua_util._readXml
local confirm           = lua_util.confirm
local skill_buff_data   = {}


local NOTIFY_EVENT_VIP_LEVEL  	  = 1			  --VIP等级通知事件


--消息提示，对应ChineseData.xml表定义
local TEXT_BUFF_UNKNOWN           = 1004001       --未知的Buff错误
local TEXT_BUFF_CANT_ADD          = 1004002       --不可添加Buff
local TEXT_BUFF_CANT_CREATE 	  = 1004003 	  --无法创建Buff


SkillBuff 				= {}
SkillBuff.__index 		= SkillBuff


function SkillBuff:InitData()
    skill_buff_data = _readXml('/data/xml/SkillBuff.xml', 'id_i')
    if skill_buff_data then
        for k, v in pairs(skill_buff_data) do
            confirm(k >= 1 and k <= 65535, "技能Buff索引ID越界[id=%d]", k);

            local buffData = v
            if not buffData.totalTime then buffData.totalTime = 0 end
            if not buffData.removeMode then buffData.removeMode = 0 end
            if not buffData.notifyEvent then buffData.notifyEvent = 0 end
            if not buffData.vipLevel then buffData.vipLevel = 0 end
            if not buffData.saveDB then buffData.saveDB = 0 end
            if not buffData.show then buffData.show = 0 end

            buffData.excludeBuff    = self:InitDefaultList(buffData.excludeBuff, 0, {}, true)
            buffData.replaceBuff    = self:InitDefaultList(buffData.replaceBuff, 0, {}, true)
            buffData.appendState    = self:InitDefaultList(buffData.appendState, 0, {}, true)

            self:CheckActiveSkillData(buffData)
            self:CheckAttrEffectData(buffData)
        end
    else
    	skill_buff_data = {}
    end
end

function SkillBuff:InitDefaultList(org_list, min_size, default_list, is_nonzero)
    if not org_list then return default_list end
    if is_nonzero == true and #org_list == 1 and org_list[1] == 0 then org_list = {} end
    if lua_util.get_table_real_count(org_list) < min_size then return default_list end
    return org_list
end

function SkillBuff:CheckActiveSkillData(buffData)
	local activeSkill 		= buffData.activeSkill
	buffData.activeSkill 	= lua_map:new()
	if not activeSkill then return end

	for tickKey, skillID in pairs(activeSkill) do
		if buffData.totalTime ~= 0 then
			if tickKey >= buffData.totalTime then break end
		end
		buffData.activeSkill:insert(tickKey, skillID)
	end
end

function SkillBuff:CheckAttrEffectData(buffData)
	local attrEffect 		= buffData.attrEffect
	buffData.attrEffect 	= lua_map:new()
	if not attrEffect then return end

	for k, value in pairs(attrEffect) do
		if value ~= 0 then
			buffData.attrEffect:insert(k, value)
		end
	end
end

function SkillBuff:New(owner, skillObj)
    local newObj    = {}
    newObj.ptr      = {}
    setmetatable(newObj,        {__index = SkillBuff})
    setmetatable(newObj.ptr,    {__mode = "v"})

    newObj.ptr.theOwner	= owner
    newObj.ptr.theSkill	= skillObj

    --技能Buff背包
    newObj.buffBag 		= lua_map:new()

    --属性影响
    newObj.attrEffect 	= lua_map:new()

    --状态影响
    newObj.stateEffect 	= lua_map:new()

    return newObj
end

function SkillBuff:Del()
	for buffID, _ in pairs(self.buffBag) do
		self:Remove(buffID)
	end
end

function SkillBuff:OnDie()
	for buffID, _ in pairs(self.buffBag) do
		local buffData = self:GetBuffData(buffID)
		if buffData.removeMode == 1 then
			self:Remove(buffID)
		end
	end
end

function SkillBuff:OnSave()
	local theOwner 	= self.ptr.theOwner
	local theBuff 	= {}
	for buffID, buffObj in pairs(self.buffBag) do
		local buffData = self:GetBuffData(buffID)
		if buffData.saveDB > 0 then
			theBuff[buffID] = {[1] = buffObj.startTime.createTime, [2] = self:GetElapseTick(buffObj)}
		end
	end
	theOwner.base.SkillBuffSyncToBase(theBuff)
end

function SkillBuff:OnLoad()
	local theOwner 	= self.ptr.theOwner
	if not theOwner.skillBuffSave then return end
	local theBuff 	= theOwner.skillBuffSave

	self:Del()
	for buffID, buffInfo in pairs(theBuff) do
		self:Add(buffID, buffInfo[1], buffInfo[2])
	end
	self:LoadBuffToClient()
end


------------------------------------------------------------------------

--获取技能Buff对象，若不存在则返回nil
function SkillBuff:GetBuffData(buffID)
    if not skill_buff_data then return nil end
    return skill_buff_data[buffID]
end

--判断身上是否存在指定的技能Buff，返回true/false
function SkillBuff:Has(buffID)
	return (self.buffBag:find(buffID) ~= nil)
end

--获取技能Buff对象已过时间
function SkillBuff:GetElapseTick(buffObj)
	local elapseTick = mogo.getTickCount() - buffObj.startTime.sysTick
	if elapseTick < 0 then elapseTick = 0 end
	elapseTick = elapseTick + buffObj.startTime.buffTick
	return elapseTick
end

--获取技能Buff剩余时间（返回负数代表无限期）
function SkillBuff:GetRemainTick(buffData, createTime, elapseTick)
	if buffData.totalTime == 0 then return -1 end

	local remainTick = buffData.totalTime - elapseTick
	if buffData.saveDB == 1 then
		--按绝对时间计算
		remainTick = buffData.totalTime - (os.time() - createTime) * 1000
	end
	if remainTick < 0 then remainTick = 0 end
	return remainTick
end

--把属性影响更新到表
function SkillBuff:UpdateAttrEffectTo(attrTable)
	for k, v in pairs(self.attrEffect) do
		if not attrTable[k] then
			attrTable[k] = v
		else
			attrTable[k] = attrTable[k] + v
		end
	end
	return attrTable
end

--获取单个属性影响值
function SkillBuff:GetAttrEffect(attrName)
	return self.attrEffect[attrName] or 0
end

--获取当前最大的虚拟VIP等级
function SkillBuff:GetMaxVipLevel()
	local maxVipLevel = 0
	for buffID, _ in pairs(self.buffBag) do
		local buffData = self:GetBuffData(buffID)
		if buffData.notifyEvent == NOTIFY_EVENT_VIP_LEVEL then
			if buffData.vipLevel > maxVipLevel then
				maxVipLevel = buffData.vipLevel
			end
		end
	end
	return maxVipLevel
end

--添加技能Buff，成功返回0
function SkillBuff:Add(buffID, createTime, elapseTick)
	createTime = createTime or os.time()
    elapseTick = elapseTick or 0
    log_game_debug("SkillBuff:Add", "buffID=%s, elapseTick=%s", buffID, elapseTick)

	local buffData = self:GetBuffData(buffID)
    if not buffData then return TEXT_BUFF_UNKNOWN end

    if self:CanAdd(buffData) ~= true then return TEXT_BUFF_CANT_ADD end

	local theOwner 	= self.ptr.theOwner
    local buffObj 	= self:Create(buffData, createTime, elapseTick)
    if not buffObj then return TEXT_BUFF_CANT_CREATE end

    --移除自身相同Buff
    self:Remove(buffID)

    --覆盖Buff
	for _, replaceBuffID in pairs(buffData.replaceBuff) do
    	self:Remove(replaceBuffID)
	end

    --加入属性效果
    self:UpdateAttrEffect(buffData, true)

    --加入相关状态，待处理
    self:UpdateStateEffect(buffData, true)

    --把对象加入Buff背包
    self.buffBag:insert(buffID, buffObj)

    --通知事件：开始
    self:NotifyEvent_Start(buffData)

    --视野广播
    local remainTick = self:GetRemainTick(buffData, createTime, elapseTick)
    if remainTick < 0 then remainTick = 0 end
    theOwner:broadcastAOI(true, "SkillBuffResp", theOwner:getId(), buffID, 1, remainTick)
    self:UpdateBuffToClient(buffData, true)

    log_game_debug("SkillBuff:Add", "OK! buffID=%s", buffID)

	return 0
end

--移除Buff
function SkillBuff:Remove(buffID)
    log_game_debug("SkillBuff:Remove", "buffID=%s", buffID)

	local buffObj = self.buffBag:find(buffID)
	if not buffObj then return end

	--删除停止定时器
	local theOwner = self.ptr.theOwner
	if buffObj.stopTimerID ~= 0 then
		theOwner:delLocalTimer(buffObj.stopTimerID)
		buffObj.stopTimerID = 0
	end

	--删除激活技能的定时器
	for _, timerID in pairs(buffObj.skillTimerIDs) do
		theOwner:delLocalTimer(timerID)
	end

	self:Destory(buffID)
end


------------------------------------------------------------------------

--判断是否可以添加技能Buff，返回true/false
function SkillBuff:CanAdd(buffData)
	--检查是否存在互斥Buff
	for _, buffID in pairs(buffData.excludeBuff) do
		if self:Has(buffID) == true then return false end
	end

	return true
end

--创建Buff对象
function SkillBuff:Create(buffData, createTime, elapseTick)
	local stopTick = self:GetRemainTick(buffData, createTime, elapseTick)
	if stopTick == 0 then return nil end

	local theOwner 	= self.ptr.theOwner
    local theSkill 	= self.ptr.theSkill
	local startTime = {createTime = createTime, sysTick = mogo.getTickCount(), buffTick = elapseTick}
	local buffObj 	= {startTime = startTime, stopTimerID = 0, skillTimerIDs = {}}

	--设置停止定时器
	if buffData.totalTime > 0 and stopTick > 0 then
    	local stopTimerID 	= theOwner:addLocalTimer("ProcSkillBuffStopTimer", stopTick, 1, buffData.id)
    	buffObj.stopTimerID = stopTimerID
	end

	--设置激活技能的定时器
	for startTick, skillID in pairs(buffData.activeSkill) do
		if startTick >= elapseTick then
			local skillTick = startTick - elapseTick
			if theSkill:GetSkill(skillID) then
	    		local skillTimerID 	= theOwner:addLocalTimer("ProcSkillBuffTimer", skillTick, 1, buffData.id, skillID)
	    		table.insert(buffObj.skillTimerIDs, skillTimerID)
			end
		end
	end

	return buffObj
end

--删除Buff
function SkillBuff:Destory(buffID)
  	local theOwner 	= self.ptr.theOwner

    log_game_debug("SkillBuff:Destory", "buffID=%s", buffID)

	--移除属性效果
    local buffData = self:GetBuffData(buffID)
    self:UpdateAttrEffect(buffData, false)

	--移除相关状态，待处理
    self:UpdateStateEffect(buffData, false)

    --移除Buff背包中的对象
    self.buffBag:erase(buffID)

    --通知事件：停止
    self:NotifyEvent_Stop(buffData)

    --视野广播
    theOwner:broadcastAOI(true, "SkillBuffResp", theOwner:getId(), buffID, 0, 0)
    self:UpdateBuffToClient(buffData, false)
end

function SkillBuff:NotifyEvent_Start(buffData)
	if buffData.notifyEvent == 1 then
  		local theOwner 		= self.ptr.theOwner
  		if theOwner.c_etype ~= public_config.ENTITY_TYPE_AVATAR then return end

		local maxVipLevel 	= self:GetMaxVipLevel()
		theOwner.base.VipBuffNoitfy(0, maxVipLevel)
	else
		return
	end
end

function SkillBuff:NotifyEvent_Stop(buffData)
	if buffData.notifyEvent == 1 then
  		local theOwner 		= self.ptr.theOwner
  		if theOwner.c_etype ~= public_config.ENTITY_TYPE_AVATAR then return end

		local maxVipLevel 	= self:GetMaxVipLevel()
		theOwner.base.VipBuffNoitfy(1, maxVipLevel)
	else
		return
	end
end

--加载Buff到客户端（玩家构造时）
function SkillBuff:LoadBuffToClient()
  	local theOwner = self.ptr.theOwner
  	theOwner.skillBuffClient = {}
  	local theBuff = theOwner.skillBuffClient
	for buffID, buffObj in pairs(self.buffBag) do
		local buffData = self:GetBuffData(buffID)
		if buffData.show > 0 then
			local remainTick = self:GetRemainTick(buffData, buffObj.startTime.createTime, self:GetElapseTick(buffObj))
			if remainTick < 0 then remainTick = 0 end
			theBuff[buffID] = remainTick
		end
	end
end

--更新Buff到客户端
function SkillBuff:UpdateBuffToClient(buffData, isAdd)
  	local theOwner = self.ptr.theOwner
  	if theOwner.c_etype ~= public_config.ENTITY_TYPE_AVATAR then return end

  	local buffID 	= buffData.id
  	local theBuff 	= theOwner.skillBuffClient
  	if isAdd == true then
  		local buffObj = self.buffBag:find(buffID)
		local remainTick = self:GetRemainTick(buffData, buffObj.startTime.createTime, self:GetElapseTick(buffObj))
		if remainTick < 0 then remainTick = 0 end
		theBuff[buffID] = remainTick
  	else
  		theBuff[buffID] = nil
  	end
end

--更新属性效果
function SkillBuff:UpdateAttrEffect(buffData, bIsAdd)
	local isChangeFlag = false
	for keyName, value in pairs(buffData.attrEffect) do
		isChangeFlag = true
		if bIsAdd == false then value = -value end
		if not self.attrEffect:find(keyName) then
			self.attrEffect:insert(keyName, value)
		else
			self.attrEffect[keyName] = self.attrEffect[keyName] + value
			if self.attrEffect[keyName] == 0 then
				self.attrEffect:erase(keyName)
			end
		end
	end

	if isChangeFlag == true then
		self.ptr.theOwner:RecalculateBattleProperties()
	end
end

--更新状态效果
function SkillBuff:UpdateStateEffect(buffData, bIsAdd)
	if #buffData.appendState == 0 then return end

	if bIsAdd == true then
		for _, stateID in pairs(buffData.appendState) do
			if self.stateEffect:find(stateID) then
				self.stateEffect[stateID] = self.stateEffect[stateID] + 1
			else
				self.stateEffect:insert(stateID, 1)
			end
		end
	else
		for _, stateID in pairs(buffData.appendState) do
			if self.stateEffect:find(stateID) then
				self.stateEffect[stateID] = self.stateEffect[stateID] - 1
				if self.stateEffect[stateID] == 0 then
					self.stateEffect:erase(stateID)
				end
			end
		end
	end

	--更新到属性
	local bitData 	= 0

	--针对死亡位进行or运算
	if Bit.Test(self.ptr.theOwner.stateFlag, 0) then
		bitData = 1
	end

	for stateID, _ in pairs(self.stateEffect) do
		bitData = Bit.Set(bitData, stateID)
	end

	self.ptr.theOwner.stateFlag = bitData
end


------------------------------------------------------------------------

--处理停止定时器
function SkillBuff:ProcSkillBuffStopTimer(timerID, activeCount, buffID)
    log_game_debug("SkillBuff:ProcSkillBuffStopTimer", "buffID=%s", buffID)

	self:Destory(buffID)
end

--处理激活技能的定时器
function SkillBuff:ProcSkillBuffTimer(timerID, activeCount, buffID, skillID)
    log_game_debug("SkillBuff:ProcSkillBuffTimer", "buffID=%s, skillID=%s", buffID, skillID)

    self.ptr.theSkill:OnBuffExecuteSkill(skillID)
end


--[[

------------------------------------------------------------------------

--把属性影响更新到表
function SkillBuff:UpdateAttrEffectTo(attrTable)
	for k, v in pairs(self.attrEffect) do
		if not attrTable[k] then
			attrTable[k] = v
		else
			attrTable[k] = attrTable[k] + v
		end
	end
end

--获取单个属性影响值
function SkillBuff:GetAttrEffect(attrName)
	return self.attrEffect[attrName] or 0
end


------------------------------------------------------------------------

--技能Buff时间回调函数
function SkillBuff:EventSkillBuffTimer(timerID, activeCount, buffID, totalTimes)
	if activeCount < totalTimes then
		self:EventSkillBuffActive(buffID)
	else
		self:EventSkillBuffComplete(buffID)
	end
end

--技能Buff激活回调
function SkillBuff:EventSkillBuffActive(buffID)
	--检查数据是否存在
	local buffData = skill_buff_data[buffID]
	if not buffData then return end

	local skillID = buffData.activeSkill[1]
	if skillID > 0 then
		self.ptr.theSkill:ExecuteBuffSkill(skillID, {self.ptr.theOwner:getId()})
	end
end

--技能Buff完成回调
function SkillBuff:EventSkillBuffComplete(buffID)
	--检查数据是否存在
	local buffData = skill_buff_data[buffID]
	if not buffData then return end

	local skillID = buffData.activeSkill[2]
	if skillID > 0 then
		self.ptr.theSkill:ExecuteBuffSkill(skillID, {self.ptr.theOwner:getId()})
	end

	self:Del(buffID, true)
end


------------------------------------------------------------------------

--广播技能Buff更新
function SkillBuff:Send_SkillBuffResp(buffID, isAdd)
	local theOwner 		= self.ptr.theOwner
	local buffData 		= skill_buff_data[buffID]
	local remainTick	= 0
	if isAdd == true then
		remainTick	= buffData.activeTime[1] or 0
		if remainTick > 0 then
			local buffObj = self.buffBag:find(buffID)
			if buffObj then
				local nowTick = mogo.getTickCount()
				if buffObj.stopTick > nowTick then
					remainTick = buffObj.stopTick - nowTick
				end
			end
		end
	end

	local opAdd = 0
	if isAdd == true then opAdd = 1 end
    theOwner:broadcastAOI(true, "SkillBuffResp", theOwner:getId(), buffID, opAdd, remainTick)
end

--广播全部技能Buff
function SkillBuff:Send_SkillAllBuffResp()
	local notify_data 	= {}
	local nowTick 		= mogo.getTickCount()
	for buffID, buffObj in pairs(self.buffBag) do
		local buffData 		= skill_buff_data[buffID]
		local remainTick	= buffData.activeTime[1] or 0
		if remainTick > 0 then
			if buffObj.stopTick > nowTick then
				remainTick = buffObj.stopTick - nowTick
			end
		end
		notify_data[buffID] = remainTick
	end
    self.ptr.theOwner:broadcastAOI(true, "SkillAllBuffResp", notify_data)
end


------------------------------------------------------------------------

function SkillBuff:_Add(buffID, elapseTick, bNotify)
	if self:CanAdd(buffID) == false then return 1 end

	local bNeedNotify 		= (bNotify or bNotify == true)
	local bNeedRefreshAll	= false

	local buffObj, ret = self:_CreateBuff(buffID, elapseTick)
	if not buffObj then return 2 end

	if self.buffBag:insert(buffID, buffObj) == false then
		--当前技能Buff已存在，覆盖它
		if self:Del(buffID, false) ~= true then
			self:_DestoryBuff(buffObj)
			return 3
		end
		if self.buffBag:insert(buffID, buffObj) == false then
			if bNotify and bNotify == true then 
				self:Send_SkillBuffResp(buffID, false);
			end
			self:_DestoryBuff(buffObj)
			return 4
		end
		bNeedRefreshAll = true
	end

	--覆盖指定Buff
	for i, v in pairs(skill_buff_data[buffID].replaceBuff) do
		if v ~= 0 then
			if self:Del(v, false) == true then bNeedRefreshAll = true end
		end
	end

	--计算属性并同步到客户端
	if bNeedRefreshAll == true then
		self:_UpdateAllAttrEffect()
		if bNotify and bNotify == true then self:Send_SkillAllBuffResp(buffID, true) end
	else
		self:_UpdateAttrEffect(buffID, true)
		if bNotify and bNotify == true then self:Send_SkillBuffResp(buffID, true) end
	end

	return 0
end

function SkillBuff:_CreateBuff(buffID, elapseTick)
	--检查数据是否存在
	local buffData = skill_buff_data[buffID]
	if not buffData then return nil, 1 end

	local timerID		= 0
	local startTick		= mogo.getTickCount()
	local interval		= 0
	local remainTimes	= 0
	local aliveTick	= buffData.activeTime[1] or 0
	if aliveTick > 0 then
		if aliveTick <= elapseTick then return nil, 2 end
		local totalTimes = buffData.activeTime[2] or 1
		totalTimes = totalTimes + 1
		if totalTimes <= 0 then return nil, 3 end
		interval = math.modf(aliveTick / totalTimes)
		if interval <= 0 then return nil, 4 end
		remainTimes = totalTimes - math.modf(elapseTick / interval)
		if remainTimes <= 0 then return nil, 5 end
		timerID = self.ptr.theOwner:addLocalTimer("EventSkillBuffTimer", interval, remainTimes, buffID, remainTimes)
	end

	local buffObj = {["buffID"] = buffID, ["timerID"] = timerID, ["startTick"] = startTick}
	if timerID ~= 0 then
		buffObj["stopTick"] = startTick + interval * remainTimes
	end
	return buffObj, 0
end

function SkillBuff:_DestoryBuff(buffObj)
	if buffObj.timerID and buffObj.timerID ~= 0 then
		self.ptr.theOwner:delLocalTimer(buffObj.timerID)
	end
end


--------------------------------------------------------------------------

]]










