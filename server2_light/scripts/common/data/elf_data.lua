
require "lua_util"
require "error_code"
require "GlobalParams"

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error

local _splitStr = lua_util.split_str

local ElfDataMgr = {
        


}

ElfDataMgr.__index = ElfDataMgr

--读取配置数据
function ElfDataMgr:initData()
	
    self.elfNodeData = lua_util._readXml("/data/xml/ElfNode.xml", "id_i")
	self.elfAreaLimitData = lua_util._readXml("/data/xml/ElfAreaLimit.xml", "id_i")
    self.elfSkillData = lua_util._readXml("/data/xml/ElfSkill.xml", "id_i")
    self.elfSkillUpgradeData = lua_util._readXml("/data/xml/ElfSkillUpgrade.xml", "id_i")
    
    for k, v in pairs(self.elfAreaLimitData) do
        self.elfAreaLimitData[k].lastNodeAreaProgress = 0
    end        


    local tmpData = self.elfNodeData

	for k, v in pairs(tmpData) do
       
        tmpData[k].id = k 
        tmpData[k].areaProgress = v.consume
             
        for k2,v2 in pairs(tmpData) do
            if k > k2 and math.floor(k/10000) == math.floor(k2/10000) then
                tmpData[k].areaProgress = tmpData[k].areaProgress + v2.consume 
            end
        end
        setmetatable(v,
            {__index =               
                function (table, key)
                    return 0         
                end                  
            }                        
        )                      
		
	end
    
    --得出每个领域最大进度
    for k, v in pairs(tmpData) do
        local areaId = math.floor(k/10000)
        if v.areaProgress > self.elfAreaLimitData[areaId].lastNodeAreaProgress then
            self.elfAreaLimitData[areaId].lastNodeAreaProgress = v.areaProgress
        end
    end

    tmpData = self.elfAreaLimitData
    local areaMaxNum = 0
    for k, v in pairs(tmpData) do
        if v.areaId > areaMaxNum then
            areaMaxNum = v.areaId
        end
    end

    self.elfAreaMaxCount = areaMaxNum

    for k, v in pairs(self.elfSkillData) do

        setmetatable(v,
            {__index =               
                function (table, key)
                    return 0         
                end                  
            }                        
        )                      
    end
    
    for k, v in pairs(self.elfSkillUpgradeData) do
        self.elfSkillUpgradeData[k].id = k    

        for k2, v2 in pairs(self.elfSkillUpgradeData) do        
            if v2.preSkillId ~= nil and v2.preSkillId > 0 and k == v2.preSkillId then
                self.elfSkillUpgradeData[k].nextSkillId = k2
                break
            end
        end

        setmetatable(v,
            {__index =               
                function (table, key)
                    return 0         
                end                  
            }                        
        )                      
    end
end

function ElfDataMgr:getElfAreaMaxCount()
    return self.elfAreaMaxCount
end

function ElfDataMgr:CanActivationArea(areaId, avatarlevel)
    local v = self.elfAreaLimitData[areaId]
    if v == nil then
        return false
    end

    if avatarlevel ~= nil and avatarlevel >= v.limitLevel then
        return true
    else
        return false
    end
end

function ElfDataMgr:getAwardList(dstTable, areaId, startProgress, endProgress)
    if dstTable == nil then
        return 0
    end

    local awardTable = dstTable

    local tmpData = self.elfNodeData
    for k, v in pairs(tmpData) do
        if math.floor(k/10000) == areaId and 
            v.areaProgress > startProgress and 
            v.areaProgress <= endProgress then
            table.insert(awardTable, v)
        end
    end  

    return #awardTable
end

function ElfDataMgr:getSkillUpgradeCfg(skillId)
    return self.elfSkillUpgradeData[skillId]
end

function ElfDataMgr:getSkillUpgradeCfgByPreSkillId(preskillId)
    for k2, v2 in pairs(self.elfSkillUpgradeData) do        
        if v2.preSkillId == preskillId then
            return v2
        end
    end
end

function ElfDataMgr:getRandomNewElfSkillCfg(elfLearnedSkillId)
    local tblCanLearnSkill = {}

    
    local canLearnSkillCount = 0
    for i=1, #elfLearnedSkillId do
        if elfLearnedSkillId[i][2] == 0 then
            --可学
            canLearnSkillCount = canLearnSkillCount + 1
            table.insert(tblCanLearnSkill, elfLearnedSkillId[i][1])
        else 
            --已学
            table.insert(tblCanLearnSkill, 0)
        end
    end
    
    if canLearnSkillCount <= 0 then
        return false
    end         

    for i=1, #tblCanLearnSkill do
    end

    local sumWeight = 0
    for i=1, #tblCanLearnSkill do
        if tblCanLearnSkill[i] > 0 then
            sumWeight = sumWeight + self.elfSkillData[i].weight
        end
    end 


    local targetIndex = 0
    local ranV = math.random(0, sumWeight)
    local curSumWeight = 0
    for i=1, #tblCanLearnSkill do
        if tblCanLearnSkill[i] > 0 then
            curSumWeight = curSumWeight + self.elfSkillData[i].weight
            if ranV <= curSumWeight then
                targetIndex = i
                break
            end
        end
    end
    
    return true, tblCanLearnSkill[targetIndex], targetIndex
end


g_elf_mgr = ElfDataMgr
return g_elf_mgr

