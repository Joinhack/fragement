
require "lua_util"
require "error_code"
require "GlobalParams"

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error

local _splitStr = lua_util.split_str

local MonsterDataMgr = {}
MonsterDataMgr.__index = MonsterDataMgr

--读取配置数据
function MonsterDataMgr:initData()
    
	local monsterValueData = lua_util._readXml("/data/xml/MonsterValue.xml", "id_i")
	local avatarModelData = lua_util._readXml("/data/xml/AvatarModel.xml", "id_i")

    self.monsterValueData = monsterValueData
    self.monsterData = {}
    self.monsterRandomData = {}

    local tmp = lua_util._readXml("/data/xml/Monster.xml", "id_i")
    self.monsterData = tmp
    
    --test cfg error
    for k, v in pairs(monsterValueData) do
        if v.extraRandom and v.extraDrop then
            for itemId, chance in pairs(v.extraRandom) do
                if v.extraDrop[itemId] == nil then
                    log_game_error("MonsterDataMgr:initData", "extra error:raidId=%d difficulty=%d monsterType=%d", v.raidId, v.difficulty, v.monsterType)
                
                end
            end
        end
    end
	
	for k, v in pairs(tmp) do
		local subAvatarModelData = avatarModelData[v.model]
		if subAvatarModelData ~= nil then
			v.deadTime 		= subAvatarModelData.deadTime
			v.bornTime 		= subAvatarModelData.bornTime
			v.scaleRadius 	= subAvatarModelData.scaleRadius
			v.speed 		= subAvatarModelData.speed
			v.notTurn 		= subAvatarModelData.notTurn
		end
		
		for kV, vV in pairs(monsterValueData) do
			if ((v.monsterType <= 4 or v.monsterType >= 9)and vV.raidId == v.raidId and vV.difficulty == v.difficulty and vV.monsterType == v.monsterType) or 
                (v.monsterType >= 5 and v.monsterType <= 8 and vV.monsterType == v.monsterType) then
				v.raidId                = vV.raidId
				v.raidType              = vV.raidType
				v.difficulty            = vV.difficulty
				v.monsterType           = vV.monsterType
				v.hardType              = vV.hardType
				v.hpBase                = vV.hpBase
				v.attackBase            = vV.attackBase
				v.extraHitRate          = vV.extraHitRate
				v.extraCritRate         = vV.extraCritRate
				v.extraTrueStrikeRate   = vV.extraTrueStrikeRate
				v.extraAntiDefenceRate  = vV.extraAntiDefenceRate
				v.extraDefenceRate      = vV.extraDefenceRate
				v.missRate              = vV.missRate
				v.exp                   = vV.exp
				v.equ			        = vV.equ
				v.gold			        = vV.gold
				v.goldStack	  	        = vV.goldStack
				v.extraRandom		    = vV.extraRandom
				v.extraDrop             = vV.extraDrop
    	        v.level			        = vV.level	
                v.goldChance            = vV.goldChance
				break
			end
		end
		
        if v.extraRandom and v.extraDrop then 
		    v.extra = {}        
            for itemId, chance in pairs(v.extraRandom) do
                v.extra[itemId] = {chance=chance}
                local num = v.extraDrop[itemId]
                if num ~= nil then
                    v.extra[itemId] = {chance = chance, num = num}
                else
                    --容错
                    v.extraDrop[itemId] = 1
                    num = v.extraDrop[itemId]
                    v.extra[itemId] = {chance = chance, num = num}

                    log_game_error("MonsterDataMgr:initData", "extra error:raidId=%d difficulty=%d monsterType=%d", v.raidId, v.difficulty, v.monsterType)
                end
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
    
    self.SpawnPointLevel = {}
    local tmp = lua_util._readXml("/data/xml/SpawnPointLevel.xml", "id_i")
    self.SpawnPointLevel = tmp

end


--读取配置数据
function MonsterDataMgr:initDataOld()
    self.monsterData = {}
    local tmp = lua_util._readXml("/data/xml/Monster.xml", "id_i")
    self.monsterData = tmp
    
    
    for k, v in pairs(tmp) do
        v.extra = {}        
        if v.extraRandom and v.extraDrop then 
            for itemId, chance in pairs(v.extraRandom) do
                v.extra[itemId] = {chance=chance}
                local num = v.extraDrop[itemId]
                if num ~= nil then
                    v.extra[itemId] = {chance = chance, num = num}
                else
                end
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

    self.SpawnPointLevel = {}
    local tmp = lua_util._readXml("/data/xml/SpawnPointLevel.xml", "id_i")
    self.SpawnPointLevel = tmp

end

function MonsterDataMgr:initAIData()
    self.AIRoots = {}
    local tmp = lua_util._readXml("/data/xml/BT_AI.xml", "id_i")
    local btFileIds = nil

    btFileIds = tmp[1]['btFileIds']
    for k, v in pairs(btFileIds) do
        local t = "BT" .. v
        self.AIRoots[v] = require (t)
    end

    
end

function MonsterDataMgr:getAICfgById(id)
    if self.AIRoots then
        return self.AIRoots[id]
    end
end

--根据唯一id获取对应关卡的配置属性
function MonsterDataMgr:getCfgById(id, monsterDifficulty)
    if self.monsterData then
        if monsterDifficulty ~= nil and monsterDifficulty > 0 then
            return self:getRandomCfgById(id, monsterDifficulty)
        else
            return self.monsterData[id]
        end
    end
end

function MonsterDataMgr:getRandomCfgById(id, difficulty)
    print('MonsterDataMgr:getRandomCfgById', id,difficulty)
    --monsterRandomData
    local monsterData = self.monsterData[id]
    if monsterData == nil then
        if id == nil then
            log_game_error("MonsterDataMgr:getRandomCfgById idError", "id=nil, difficulty=%d", difficulty)
        else 
            log_game_error("MonsterDataMgr:getRandomCfgById idError", "id=%d, difficulty=%d", id, difficulty)
        end
        return nil
    end
    local monsterType = monsterData.monsterType
    local rid = id*10000+difficulty*10 + monsterType--这是random怪物属性唯一性标志：主角等级*100+怪物类型
    local cfgData = self.monsterRandomData[rid]
    if cfgData == nil then
        local v = {}
        local monsterValueData = self.monsterValueData
        local specialRaidId = g_GlobalParamsMgr:GetParams('random_map_raidid', 50000)
        for kV, vV in pairs(monsterValueData) do 
            if ((monsterType <= 4 or monsterType >= 9) and vV.difficulty == difficulty and vV.monsterType == monsterData.monsterType  and vV.raidId == specialRaidId) or 
                (monsterType >= 5 and monsterType <= 8 and vV.monsterType == monsterType) then
                                       
                lua_util.deep_copy(4, monsterData, v)   
                
                v.id                    = id
                v.rid                   = rid
				v.raidId                = vV.raidId
				v.raidType              = vV.raidType
				v.difficulty            = vV.difficulty
				v.monsterType           = vV.monsterType
				v.hardType              = vV.hardType
				v.hpBase                = vV.hpBase
				v.attackBase            = vV.attackBase
				v.extraHitRate          = vV.extraHitRate
				v.extraCritRate         = vV.extraCritRate
				v.extraTrueStrikeRate   = vV.extraTrueStrikeRate
				v.extraAntiDefenceRate  = vV.extraAntiDefenceRate
				v.extraDefenceRate      = vV.extraDefenceRate
				v.missRate              = vV.missRate
				v.exp                   = vV.exp
				v.equ		            = vV.equ
				v.gold			        = vV.gold
				v.goldStack	  	        = vV.goldStack
				v.extraRandom		    = vV.extraRandom
				v.extraDrop             = vV.extraDrop
    	        v.level			        = vV.level	
                v.goldChance            = vV.goldChance
            
                break
            end--if
        end--for

        if v.rid == nil then
            log_game_error("MonsterDataMgr:getRandomCfgById", "id=%d, difficulty=%d", id, difficulty)
            return
        end

        v.extra = nil

        if v.extraRandom and v.extraDrop then 
		    v.extra = {}        
            for itemId, chance in pairs(v.extraRandom) do
                v.extra[itemId] = {chance=chance}
                local num = v.extraDrop[itemId]
                if num ~= nil then
                    v.extra[itemId] = {chance = chance, num = num}
                else
                    --容错
                    v.extraDrop[itemId] = 1
                    num = v.extraDrop[itemId]
                    v.extra[itemId] = {chance = chance, num = num}

                    log_game_error("MonsterDataMgr:getRandomCfgById", "extra error:monsterId=%d  difficulty=%d monsterType=%d", v.id, v.difficulty, v.monsterType)
                end--if
            end--for
        end--if
        
        
        setmetatable(v,
            {__index =               
                function (table, key)
                    return 0         
                end                  
            }                        
        )

        self.monsterRandomData[rid] = v
        cfgData = v                      

    else
        
    end--if

    if cfgData == nil then
        log_game_error("MonsterDataMgr:getRandomCfgById", "id=%d, difficulty=%d", id, difficulty)
    end

    return cfgData
end

function MonsterDataMgr:getSpawnPointLevelCfgById(Id)
    if self.SpawnPointLevel then
        return self.SpawnPointLevel[Id]
    end
end

function MonsterDataMgr:getSpawnPointLevelCfgInfoById(dstTbl, Id)
    if type(dstTbl[1]) ~= 'table' then
        dstTbl[1] = {}
    end
    
    local cfg = self:getSpawnPointLevelCfgById(Id)
    if cfg == nil then
--        log_game_error("MonsterDataMgr:getSpawnPointLevelCfgInfoById SpawnPointLevel cfg is nil", "cfgId:%d", Id)
        return
    end

    --log_game_info('_splitStr', 'ids %s', cfg['monsterId'])

    local ids = cfg['monsterId']
    --log_game_info('_splitStr', 'num %s', cfg['monsterNumber'])
    local num = cfg['monsterNumber']

    local tblMonsterInfo = dstTbl[1]
    
    for k, monsterId in pairs(ids) do
        if tblMonsterInfo[monsterId] == nil then
            tblMonsterInfo[monsterId] = 0
        end
     
        tblMonsterInfo[monsterId] = tblMonsterInfo[monsterId] + num[k]
    end

    
end

function MonsterDataMgr:getRandom()
    return math.random(1, 10000) 
end

function MonsterDataMgr:getDrop(tblDstDropsItem, tblDstMoney, monsterId, vocation, monsterDifficuly)
    if monsterDifficuly == nil then
        monsterDifficuly = 0
    end

    local tmpCfgData = self:getCfgById(monsterId, monsterDifficuly)
    if tmpCfgData == nil then
        return false
    end
    
    local tblDstDrops = {}
    
    local equ_m = tmpCfgData.equ
    if equ_m and equ_m ~= 0 then
        for k,v in pairs(equ_m) do
            if self:getRandom() <= v then
                if tblDstDrops[k] == nil then
                    tblDstDrops[k] = 0
                end
                tblDstDrops[k] = tblDstDrops[k] + 1
            end 
        end 
    end

    local extra_tbl = tmpCfgData.extra
    if extra_tbl and extra_tbl ~= 0 then
        for itemId, tblValue in pairs(extra_tbl) do
            if self:getRandom() <= tblValue.chance then                
                if tblDstDropsItem[itemId] == nil then
                    tblDstDropsItem[itemId] = 0
                end
                tblDstDropsItem[itemId] = tblDstDropsItem[itemId] + tblValue.num
            end
        end
    end

    for dropId, num in pairs(tblDstDrops) do
        for i = 1, num do
            g_drop_mgr:GetAwards(tblDstDropsItem, dropId, vocation)
        end
    end
    

    if tmpCfgData.gold ~= 0 and tmpCfgData.goldStack ~= 0 and tmpCfgData.goldChance ~= 0 and math.random(0, 10000) < tmpCfgData.goldChance and #tmpCfgData.gold == 2 and tmpCfgData.goldStack > 0 then
        local awardGold = math.random(tmpCfgData.gold[1], tmpCfgData.gold[2])
        local averageGold = math.ceil(awardGold/tmpCfgData.goldStack)
        for i=1, tmpCfgData.goldStack do
            table.insert(tblDstMoney, averageGold)
        end
    end
    --test 
--[[
    for k,v in pairs(tblDstDropsItem) do
    end
    for k,v in pairs(tblDstMoney) do
    end
--]]
    return true
end

--获取所有可能出现的掉落物品ID
function MonsterDataMgr:getDropItemCfg(tblDstDropsItem, monsterId, vocation)
    local tmpCfgData = self:getCfgById(monsterId)
    if tmpCfgData == nil then
        return false         
    end                      

    local tblDstDrops = {}
    
    local equ_m = tmpCfgData.equ                    
    if equ_m and equ_m ~= 0 then                    
        for k,v in pairs(equ_m) do                  
            if tblDstDrops[k] == nil then       
                tblDstDrops[k] = 0              
            end                                 
            tblDstDrops[k] = tblDstDrops[k] + 1 
        end                                         
    end                                             

    local extra_tbl = tmpCfgData.extra
    if extra_tbl and extra_tbl ~= 0 then
        for itemId, tblValue in pairs(extra_tbl) do
            if tblDstDropsItem[itemId] == nil then
                tblDstDropsItem[itemId] = 0
            end
            tblDstDropsItem[itemId] = tblDstDropsItem[itemId] + tblValue.num
        end
    end
    for dropId, num in pairs(tblDstDrops) do                       
        for i = 1, num do                                          
            g_drop_mgr:GetAwardsItemCfg(tblDstDropsItem, dropId, vocation)
        end                                                        
    end
                               

    return true                        
end

g_monster_mgr = MonsterDataMgr
return g_monster_mgr

