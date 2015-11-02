require "lua_util"
require "t2s"

-- 契约技能等级升级消耗表 SkillLevelUpData
-- {[level]=cost...}
-- 印记技能等级升级消耗表 MarkLevelUpData
-- {[level]=cost...} 
-- 人物初始契约技能表SkillData
-- {skill...}
-- 人物初始元素刻印表MarkData
-- {mark...}
-- 技能槽数所需等级SkillSlotAndLevel
-- {[num]=level...}
-- 印记槽数所需等级MarkSlotAndLevel
-- {[num]=level..}
local log_game_debug = lua_util.log_game_debug

local spiritDataMgr = {}
spiritDataMgr.__index = spiritDataMgr

function spiritDataMgr:initData()
    self.spiritData = {}

    local SkillLevelUpData = lua_util._readXml("/data/xml/SpiritLevelData_Skill.xml", "id_i")
    local MarkLevelUpData = lua_util._readXml("/data/xml/SpiritLevelData_Mark.xml", "id_i")
    local SkillData = lua_util._readXml("/data/xml/SpiritSkillData.xml", "id_i")
    local MarkData = lua_util._readXml("/data/xml/SpiritMarkData.xml", "id_i")



    self.spiritData.SkillLevelUpData = SkillLevelUpData
    self.spiritData.MarkLevelUpData = MarkLevelUpData
    self.spiritData.SkillData = SkillData
    self.spiritData.MarkData = MarkData

	
    
    --log_game_debug("spiritDataMgr:initData", "SkillLevelUpData = %s",t2s(SkillLevelUpData)  ) 
    --log_game_debug("spiritDataMgr:initData", "MarkLevelUpData = %s",t2s(MarkLevelUpData)  ) 
   -- log_game_debug("spiritDataMgr:initData", "SkillData = %s",t2s(SkillData)  ) 
   -- log_game_debug("spiritDataMgr:initData", "MarkData = %s",t2s(MarkData)  ) 
   -- log_game_debug("spiritDataMgr:initData", "SkillSlotAndLevel = %s",t2s(SkillSlotAndLevel)  ) 
   -- log_game_debug("spiritDataMgr:initData", "MarkSlotAndLevel = %s",t2s(MarkSlotAndLevel)  ) 
	--log_game_debug("spiritDataMgr:initData", "Id2Point = %s",t2s(Id2Point)  ) 
end




function spiritDataMgr:GetPointFromId(id)
    if self.spiritData.SkillData[id] then
        return self.spiritData.SkillData[id].add_point
    end
    return nil
end

function spiritDataMgr:GetCostByLevel_Skill(level)
    if self.spiritData.SkillLevelUpData[level] then
        return self.spiritData.SkillLevelUpData[level].cost
    end
    return nil
end

function spiritDataMgr:GetCostByLevel_Mark(level)
    if self.spiritData.MarkLevelUpData[level] then
        return self.spiritData.MarkLevelUpData[level].cost
    end
    return nil
end



function spiritDataMgr:GetSlotNum_Skill(level)

	local data = self.spiritData.SkillLevelUpData[level]	
    if data then		
		return data.slot_num
    end
    return 0
end

function spiritDataMgr:GetSlotNum_Mark(level)

	local data = self.spiritData.SkillLevelUpData[level]
    if data then        
        return data.slot_num
    end
    return 0
end



g_spiritDataMgr = spiritDataMgr
return g_spiritDataMgr
