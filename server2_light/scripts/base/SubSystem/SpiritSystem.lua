

require "spiritData"
require "event_config"
require "role_data"
require "t2s"

-- 精灵系统、技能契约、元素刻印

local log_game_info = lua_util.log_game_info
local log_game_debug = lua_util.log_game_debug
local _readXml = lua_util._readXml

SpiritSystem = {}
SpiritSystem.__index = SpiritSystem


local spirit_error_code = 
{ 
	spirit_error_code_successful = 0, --成功
	spirit_error_code_max_than_self_level = 1, --超过自身等级
	spirit_error_code_not_enough_point = 2, --点数不够
	spirit_error_code_not_found_consume = 3,	--没有找到该等级升级所需的消耗
	spirit_error_code_not_players = 4, --该技能不是玩家的
	spirit_error_code_not_open = 5, --技能未开启
	spirit_error_code_activeskill_exists = 6, --已经装备了主动技能，不能再装备主动技能了
	spirit_error_code_beyond_index = 7,--拖拽的槽位未开启或者槽位号超出范围
	spirit_error_code_already_selected = 8,--拖动的对象已经存在于槽中
}


function SpiritSystem:new( owner )
    local newObj = {}
    setmetatable(newObj, {__index = SpiritSystem, __mode = "kv"})

    newObj.theOwner = owner

    local msgMapping = {
		
		    }
    newObj.msgMapping = msgMapping
    return newObj
end



--配置文件初始化
function SpiritSystem:formatInitData(initdata)		
		local result = {}
		if initdata then
			for k,v in pairs(initdata) do						
 				result[v] = 0			
			end
		end			
	return result
end

--创建人物的时候数据初始化
function SpiritSystem:InitSpiritDataOnCreateRole()	

	local role_data = g_roleDataMgr:GetRoleDataByVocation(self.theOwner.vocation)

	self.theOwner.SpiritSkillLevel = role_data.spirit_skill_level
	self.theOwner.SpiritMarkLevel = role_data.spirit_mark_level
	self.theOwner.SpiritSkillPoint = role_data.spirit_skill_point
	self.theOwner.SpiritMarkPoint = role_data.spirit_mark_point
	
	self.theOwner.SpiritSkill = self:formatInitData(role_data.spirit_skill)	
	self.theOwner.SpiritMark = self:formatInitData(role_data.spirit_mark)	
	
	self.theOwner.SelectedSpiritSkill = {}
	self.theOwner.SelectedSpiritMark = {}
	
	self:FreshOpenSkill() --这里创建人物的时候刷新下槽位,有可能默认开启
	self:FreshOpenMark()
	

--	log_game_debug("SpiritSystem:InitOnCreateRole", "level = %d\n%d ;point = %d\n%d ,skills = %s \n marks = %s, selected=%s\n%s",
--					self.theOwner.SpiritSkillLevel ,
--					self.theOwner.SpiritMarkLevel,
--					self.theOwner.SpiritSkillPoint ,
--					self.theOwner.SpiritMarkPoint, 
--					t2s(self.theOwner.SpiritSkill), 
--					t2s(self.theOwner.SpiritMark), 
--					t2s(self.theOwner.SelectedSpiritSkill), 
--					t2s(self.theOwner.SelectedSpiritMark))
end

--暂时屏蔽
function SpiritSystem:IsSkillActive(skillId)	
	return false	
end


----加怒气值 value正值为加，负值为减
--function SpiritSystem:AddAnger(value)
--
--		local add_v = self.theOwner.Anger + value
--		if add_v > 100 then
--			self.theOwner.Anger = 100    --超过上限
--		elseif add_v < 0 then
--			self.theOwner.Anger = 0		--低于0
--		else
--			self.theOwner.Anger = add_v
--		end
--end

----重置怒气（目前是为0）
--function SpiritSystem:ResetAnger(value)
--	self.theOwner.Anger = 0
--end


--刷新所有
function SpiritSystem:UpdateProps()	
    local ppt = {}
    setmetatable(ppt, {__index =
        function (table, key)
            return 0
        end
        }
    )
    return ppt
end




--升级契约技能等级
function SpiritSystem:LevelUpSkill()	

	local skillLevel = self.theOwner.SpiritSkillLevel	
	if skillLevel >= self.theOwner.level then  --超过自身等级
		log_game_debug("SpiritSystem:LevelUpSkill", "LevelUpSkill failled , skilllevel(%d) >= player_level(%d)",skillLevel,self.theOwner.level  ) 	
		return spirit_error_code.spirit_error_code_max_than_self_level
	end

	local cost = g_spiritDataMgr:GetCostByLevel_Skill(skillLevel)
	if cost then
		if self.theOwner.SpiritSkillPoint < cost then --点数不够
			log_game_debug("SpiritSystem:LevelUpSkill", "LevelUpSkill failled  cur curPoint(%d) <needPoint(%d) ",self.theOwner.SpiritSkillPoint, cost )
			return spirit_error_code.spirit_error_code_not_enough_point
		end
		self.theOwner.SpiritSkillLevel = self.theOwner.SpiritSkillLevel + 1		 --加等级
		self.theOwner.SpiritSkillPoint = self.theOwner.SpiritSkillPoint - tonumber(cost)	 --扣点数

		--self:triggerEvent(event_config.EVENT_SPIRIT_LEVELUP_SKILL, self.theOwner.SpiritSkillLevel -1, self.theOwner.SpiritSkillLevel)

		--EVENT_SPIRIT_LEVELUP_SKILL		   = 6, --契约技能升级{升级前等级，升级后等级}
		--EVENT_SPIRIT_LEVELUP_MARK		   = 7, --元素刻印升级{升级前等级，升级后等级}
		log_game_debug("SpiritSystem:LevelUpSkill", "Success! curLevel=%d, curPoint=%d cost=%d ) ",self.theOwner.SpiritSkillLevel,self.theOwner.SpiritSkillPoint, cost )
		self:FreshOpenSkill()
		return spirit_error_code.spirit_error_code_successful
	end
	--没有找到该等级升级所需的消耗
	log_game_debug("SpiritSystem:LevelUpSkill", "LevelUpSkill failled  cur skillLevel = %d cost not found",skillLevel ) 	

	return spirit_error_code.spirit_error_code_not_found_consume
end



--增加ID为skillId的契约技能
function SpiritSystem:AddSpiritSkill(skillId)
 	
 	log_game_debug("SpiritSystem:LevelUpSkill", "addskillID=%d \n skills = %s",skillId, t2s(self.theOwner.SpiritSkill)  ) 

	if not self:IsSelfSkill(skillId) then
		log_game_debug("SpiritSystem:AddSpiritSkill", "skillId=%d ,not player's skill ", skillId)  
		return false
	end	

	if self:IsSkillOpen(skillId) then 
		local add_point = g_spiritDataMgr:GetPointFromId(skillId)
		if 	add_point then		
				
			self.theOwner.SpiritSkillPoint = self.theOwner.SpiritSkillPoint + tonumber(add_point) --已经开启，则加契约之力			
			log_game_debug("SpiritSystem:AddSpiritSkill", "SkillId=%d exists, add Point=%d  curPoint=%d ", skillId, add_point, self.theOwner.SpiritSkillPoint ) 
			
			return true	
		end
			log_game_debug("SpiritSystem:AddSpiritSkill", "Config Error! SkillId=%d Point NotFound!", skillId ) 
			return false
	else
		self.theOwner.SpiritSkill[skillId]	= 1	--技能开启(解锁)
		log_game_debug("SpiritSystem:SpiritPropRefreshResp", "1" ) 
		self.theOwner.client.SpiritPropRefreshResp(1, self.theOwner.SpiritSkill)--1:SpiritSkill 2：SpiritMark 3：SelectedSpiritSkill 4：SelectedSpiritMark
	
		log_game_debug("SpiritSystem:AddSpiritSkill", "addskillID=%d opened! \n skills = %s",skillId, t2s(self.theOwner.SpiritSkill)  ) 
		return true
	end
end

--技能是否解锁
function SpiritSystem:IsSkillOpen(skillId)
	local skills = self.theOwner.SpiritSkill

	if skills[skillId] == nil then
		return false
	else
		return skills[skillId] == 1
	end
end

--是否是自己的技能
function SpiritSystem:IsSelfSkill(skillId)
	local skills = self.theOwner.SpiritSkill
	return skills[skillId] ~= nil
end



function SpiritSystem:ClientCastSkill(skillId, castIndex) 

	if not self:IsSelfSkill(skillId) then
		log_game_debug("SpiritSystem:CastSkill", "skillId=%d ,not player's skill ", skillId) --该技能不是玩家的
		return spirit_error_code.spirit_error_code_not_players
	end	

	if 	not self:IsSkillOpen(skillId)  then
		log_game_debug("SpiritSystem:CastSkill", "skillID=%d  not open", skillId) 	--技能未开启
		return spirit_error_code.spirit_error_code_not_open 
	end
	
	if 	self:IsSkillSelected(skillId)  then
		log_game_debug("SpiritSystem:CastSkill", "skillID=%d  alread exist", skillId) 	--拖动的对象已经存在于槽中
		return spirit_error_code.spirit_error_code_already_selected 
	end

	if self:GetActiveSkillNum() >0 and self:IsSkillActive(skillId) then
		log_game_debug("SpiritSystem:CastSkill", "skillID=%d  No more ActiveSkill", skillId) 	--已经装备了主动技能，不能再装备主动技能了
		return spirit_error_code.spirit_error_code_activeskill_exists 
	end

	local selectedSkills = self.theOwner.SelectedSpiritSkill

	if selectedSkills[castIndex] == nil then									--拖拽的槽位未开启或者槽位号超出范围
			log_game_debug("SpiritSystem:CastSkill", "castIndex = %d  not open or the index beyond range", castIndex) 
			return spirit_error_code.spirit_error_code_beyond_index 
	end
	local oldSkill = self.theOwner.SelectedSpiritSkill[castIndex] 
	if oldSkill == skillId then --
		return spirit_error_code.spirit_error_code_successful	
	end
	
	self.theOwner.SelectedSpiritSkill[castIndex] = skillId 	 --设置槽位里面的技能为拖拽的技能
	log_game_debug("SpiritSystem:SpiritPropRefreshResp", "3" ) 
	self.theOwner.client.SpiritPropRefreshResp(3, self.theOwner.SelectedSpiritSkill)--1:SpiritSkill 2：SpiritMark 3：SelectedSpiritSkill 4：SelectedSpiritMark
	
	if oldSkill > 0 then
		log_game_debug("SpiritSystem:CastSkill", "UnLearn=%d", oldSkill)
		--self.theOwner.skillSystem:Unlearn(oldSkill) --如果之前槽位有技能则取消之前的技能    todo : 等待技能接口
	end
	
	log_game_debug("SpiritSystem:CastSkill", "Learn=%d", skillId) 
	--self.theOwner.cell.Learn(skillId)	  todo : 等待接口
	
	return spirit_error_code.spirit_error_code_successful	
		
end



--刷新 看有没有打开的技能
function SpiritSystem:FreshOpenSkill()
	local slotNum = g_spiritDataMgr:GetSlotNum_Skill(self.theOwner.SpiritSkillLevel)		
	log_game_debug("SpiritSystem:FreshOpenSkill", "Data: skillLevel=%d, slotNum = %d", self.theOwner.SpiritSkillLevel,slotNum) 
	for i=1, slotNum do
		if self.theOwner.SelectedSpiritSkill[i] == nil then
			self.theOwner.SelectedSpiritSkill[i] = 0  --槽位开启 里面没有技能则值为0，如有技能则为技能ID(与客户端约定好)
			if self.theOwner.client then -- 这里因为刷新的时候有可能是创建账号的时候就刷新 那么这个时候client 是nil 所以做个判断	
			log_game_debug("SpiritSystem:SpiritPropRefreshResp", "3" ) 
				self.theOwner.client.SpiritPropRefreshResp(3, self.theOwner.SelectedSpiritSkill)--1:SpiritSkill 2：SpiritMark 3：SelectedSpiritSkill 4：SelectedSpiritMark
			end
			log_game_debug("SpiritSystem:FreshOpenSkill", "SlotIndex = %d  Opened!", i) 
		end
	end	
	log_game_debug("SpiritSystem:FreshOpenSkill", "slot = %s", t2s(self.theOwner.SelectedSpiritSkill)) 
end


--刷新 槽中主动技能的个数
function SpiritSystem:GetActiveSkillNum()	
	local num = 0;
		for k,v in pairs(self.theOwner.SelectedSpiritSkill) do	
			if self:IsSkillActive(v) then
				num = num + 1	
			end
		end
	
	return num
end

--得到人物已经开启的
function SpiritSystem:GetOpenSkills()	
	
	local openSkills = {}		
		for k,v in pairs(self.theOwner.SpiritSkill) do	
			if v==1 then
				table.insert(openSkills, k)
			end
		end
	
	return openSkills
end


--得到人物已经未解锁的
function SpiritSystem:GetCloseSkills()	
	local closeSkills = {}		
		for k,v in pairs(self.theOwner.SpiritSkill) do	
			if not v==1 then
				table.insert(closeSkills, k)
			end
		end
	
	return closeSkills
end


--技能是否已经被拖进槽
function SpiritSystem:IsSkillSelected(id)	

		for k,v in pairs(self.theOwner.SelectedSpiritSkill) do	
			if v == Id then
				return true	
			end
		end	
	return false
end























--升级元素印记等级
function SpiritSystem:LevelUpMark()	

	local markLevel = self.theOwner.SpiritMarkLevel	
	if markLevel >= self.theOwner.level then  --超过自身等级
		log_game_debug("SpiritSystem:LevelUpMark", "LevelUpMark failled , marklevel(%d) >= player_level(%d)",markLevel,self.theOwner.level  ) 	
		return spirit_error_code.spirit_error_code_max_than_self_level
	end

	local cost = g_spiritDataMgr:GetCostByLevel_Mark(markLevel)
	if cost then
		if self.theOwner.SpiritMarkPoint < cost then --点数不够
			log_game_debug("SpiritSystem:LevelUpMark", "LevelUpMark failled  cur curPoint(%d) <needPoint(%d) ",self.theOwner.SpiritMarkPoint, cost )
			return spirit_error_code.spirit_error_code_not_enough_point
		end
		self.theOwner.SpiritMarkLevel = self.theOwner.SpiritMarkLevel + 1		 --加等级
		self.theOwner.SpiritMarkPoint = self.theOwner.SpiritMarkPoint - tonumber(cost)	 --扣点数

		--self:triggerEvent(event_config.EVENT_SPIRIT_LEVELUP_MARK, self.theOwner.SpiritMarkLevel -1, self.theOwner.SpiritMarkLevel)
		--EVENT_SPIRIT_LEVELUP_SKILL		   = 6, --契约技能升级{升级前等级，升级后等级}
		--EVENT_SPIRIT_LEVELUP_MARK		   = 7, --元素刻印升级{升级前等级，升级后等级}

		log_game_debug("SpiritSystem:LevelUpMark", "Success! curLevel=%d, curPoint=%d cost=%d ) ",self.theOwner.SpiritMarkLevel,self.theOwner.SpiritMarkPoint, cost )
		self:FreshOpenMark()
		return spirit_error_code.spirit_error_code_successful
	end
	--没有找到该等级升级所需的消耗
	log_game_debug("SpiritSystem:LevelUpMark", "LevelUpMark failled  cur markLevel = %d cost not found",markLevel ) 	

	return spirit_error_code.spirit_error_code_not_found_consume
end



--增加ID为markId的元素印记
function SpiritSystem:AddSpiritMark(markId)
 	
 	log_game_debug("SpiritSystem:AddSpiritMark", "addmarkID=%d \n marks = %s",markId, t2s(self.theOwner.SpiritMark)  ) 

	if not self:IsSelfMark(markId) then
		log_game_debug("SpiritSystem:AddSpiritMark", "markId=%d ,not player's mark ", markId)  
		return false
	end	

	if self:IsMarkOpen(markId) then 
		local add_point = g_spiritDataMgr:GetPointFromId(markId)
		if 	add_point then		
				
			self.theOwner.SpiritMarkPoint = self.theOwner.SpiritMarkPoint + tonumber(add_point) --已经开启，则加契约之力			
			log_game_debug("SpiritSystem:AddSpiritMark", "MarkId=%d exists, add Point=%d curPoint=%d", markId, add_point, self.theOwner.SpiritMarkPoint) 
			
			return true	
		end
			log_game_debug("SpiritSystem:AddSpiritMark", "Config Error! MarkId=%d Point NotFound!", markId ) 
			return false
	else
		self.theOwner.SpiritMark[markId]	= 1		--印记开启(解锁)	
		log_game_debug("SpiritSystem:SpiritPropRefreshResp", "2" ) 
		self.theOwner.client.SpiritPropRefreshResp(2, self.theOwner.SpiritMark)--1:SpiritSkill 2：SpiritMark 3：SelectedSpiritSkill 4：SelectedSpiritMark
	
		log_game_debug("SpiritSystem:AddSpiritMark", "addmarkID=%d opened! \n marks = %s",markId, t2s(self.theOwner.SpiritMark)  ) 
		return true
	end
end

--印记是否解锁
function SpiritSystem:IsMarkOpen(markId)
	local marks = self.theOwner.SpiritMark

	if marks[markId] == nil then
		return false
	else
		return marks[markId] == 1
	end
end

--是否是自己的印记
function SpiritSystem:IsSelfMark(markId)
	local marks = self.theOwner.SpiritMark
	return marks[markId] ~= nil
end



function SpiritSystem:ClientCastMark(markId, castIndex) 

	if not self:IsSelfMark(markId) then
		log_game_debug("SpiritSystem:CastMark", "markId=%d ,not player's mark ", markId) --该印记不是玩家的
		return spirit_error_code.spirit_error_code_not_players
	end	

	if 	not self:IsMarkOpen(markId)  then
		log_game_debug("SpiritSystem:CastMark", "markID=%d  not open", markId) 	--印记未开启
		return spirit_error_code.spirit_error_code_not_open
	end
	
	if 	self:IsMarkSelected(markId)  then
		log_game_debug("SpiritSystem:CastSkill", "markID=%d  alread exist", markId) 	--拖动的对象已经存在于槽中
		return spirit_error_code.spirit_error_code_already_selected 
	end

	--[[  印记不需要主动还是被动
	if self:GetActiveMarkNum() >0 and self:IsMarkActive(markId) then
		log_game_debug("SpiritSystem:CastMark", "markID=%d  No more ActiveMark", markId) 	--已经装备了主动印记，不能再装备主动印记了
		return
	end
	--]]

	local selectedMarks = self.theOwner.SelectedSpiritMark

	if selectedMarks[castIndex] == nil then									--拖拽的槽位未开启或者槽位号超出范围
			log_game_debug("SpiritSystem:CastMark", "castIndex = %d  not open or the index beyond range", castIndex) 
		return spirit_error_code.spirit_error_code_beyond_index
	end

	local oldMark = self.theOwner.SelectedSpiritMark[castIndex] 
	
	if oldMark == markId then --
		return spirit_error_code.spirit_error_code_successful	
	end
	
	self.theOwner.SelectedSpiritMark[castIndex] = markId 	 --设置槽位里面的印记为拖拽的印记
	log_game_debug("SpiritSystem:SpiritPropRefreshResp", "4" ) 
	self.theOwner.client.SpiritPropRefreshResp(4, self.theOwner.SelectedSpiritMark)--1:SpiritSkill 2：SpiritMark 3：SelectedSpiritSkill 4：SelectedSpiritMark
	
	if oldMark > 0 then
		log_game_debug("SpiritSystem:CastMark", "UnLearn=%d", oldMark) 
		--self.theOwner.skillSystem:Unlearn(oldMark) --如果之前槽位有技能则取消之前的技能    todo : 等待技能接口
	end
	
	log_game_debug("SpiritSystem:CastMark", "Learn=%d", markId) 
	--self.theOwner.skillSystem:Learn(markId)  todo : 等待技能接口
	
	return spirit_error_code.spirit_error_code_successful	
end



--刷新 看有没有打开的印记
function SpiritSystem:FreshOpenMark()
	local slotNum = g_spiritDataMgr:GetSlotNum_Mark(self.theOwner.SpiritMarkLevel)		
--	log_game_debug("SpiritSystem:FreshOpenMark", "Data: markLevel=%d, slotNum = %d", self.theOwner.SpiritMarkLevel,slotNum) 
	for i=1, slotNum do
		if self.theOwner.SelectedSpiritMark[i] == nil then
			self.theOwner.SelectedSpiritMark[i] = 0  --槽位开启 里面没有印记则值为0，如有印记则为印记ID(与客户端约定好)
			if self.theOwner.client then -- 这里因为刷新的时候有可能是创建账号的时候就刷新 那么这个时候client 是nil 所以做个判断
			log_game_debug("SpiritSystem:SpiritPropRefreshResp", "4" ) 	
				self.theOwner.client.SpiritPropRefreshResp(4, self.theOwner.SelectedSpiritMark)--1:SpiritSkill 2：SpiritMark 3：SelectedSpiritSkill 4：SelectedSpiritMark
			end
			
--			log_game_debug("SpiritSystem:FreshOpenMark", "SlotIndex = %d  Opened!", i) 
		end
	end	
--	log_game_debug("SpiritSystem:FreshOpenMark", "slot = %s", t2s(self.theOwner.SelectedSpiritMark)) 
end



--得到人物已经开启的印记
function SpiritSystem:GetOpenMarks()	
	
	local openMarks = {}		
		for k,v in pairs(self.theOwner.SpiritMark) do	
			if v==1 then
				table.insert(openMarks, k)
			end
		end
	
	return openMarks
end


--得到人物未解锁的印记
function SpiritSystem:GetCloseMarks()	
	
	local closeMarks = {}		
		for k,v in pairs(self.theOwner.SpiritMark) do	
			if not v==1 then
				table.insert(closeMarks, k)
			end
		end
	
	return closeMarks
end



--印记是否已经被拖进槽
function SpiritSystem:IsMarkSelected(id)	

		for k,v in pairs(self.theOwner.SelectedSpiritMark) do	
			if v == id then
				return true	
			end
		end	
	return false
end






return SpiritSystem
