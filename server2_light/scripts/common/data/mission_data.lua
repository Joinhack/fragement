
require "lua_util"
require "mission_config"
require "map_data"
require "monster_data"
require "drop_data"
require "GlobalParams"

local _splitStr = lua_util.split_str
local log_game_debug = lua_util.log_game_debug
local choose_prob = lua_util.choose_prob

local MissionDataMgr = {}
MissionDataMgr.__index = MissionDataMgr

--读取配置数据
function MissionDataMgr:initData()
    self.missionData = {}
    local tmp = lua_util._readXml("/data/xml/Mission.xml", "id_i")
    for _, v in pairs(tmp) do
        local tbl = {}
        table.insert(tbl, tostring(v['mission']))
        table.insert(tbl, tostring(v['difficulty']))
        self.missionData[table.concat(tbl, "_")] = v
    end

    --初始化随机副本池
    self.randomMission = {}
    for k, v in pairs(self.missionData) do
        if v['isRandom'] and v['isRandom'] == 1 then
            self.randomMission[k] = true
        end
    end

    self.missionEvaluate = {}
    tmp = lua_util._readXml("/data/xml/MissionEvaluate.xml", "id_i")
    for k, v in pairs(tmp) do
        local tbl = {}
        table.insert(tbl, tostring(v['mission']))
        table.insert(tbl, tostring(v['difficulty']))
        self.missionEvaluate[table.concat(tbl, "_")] = v
    end

    self.missionEvent = lua_util._readXml("/data/xml/MissionEvent.xml", "id_i")

    self.missionReward = {}
    tmp = lua_util._readXml("/data/xml/MissionReward.xml", "id_i")
    for k, v in pairs(tmp) do
        local result = {}
        local conditions = _splitStr(v['condition'], ";")
        if conditions then
            for _, v1 in pairs(conditions) do
                table.insert(result, _splitStr(v1, ",", tonumber))
            end
        end

        self.missionReward[k] = {["condition"]=result, ["rewards"]=v['rewards'],}
    end

    self.missionRandomRewardTimes = lua_util._readXml("/data/xml/MissionRandomRewardTimes.xml", "evaluate_i")

    self.missionRandomReward = {}
    tmp = lua_util._readXml("/data/xml/MissionRandomReward.xml", "id_i")
    for _, v in pairs(tmp) do
        if self.missionRandomReward[v['mission']] then
            self.missionRandomReward[v['mission']][v['difficulty']] = v
        else
            self.missionRandomReward[v['mission']] = {}
            self.missionRandomReward[v['mission']][v['difficulty']] = v
        end
    end

    self.missionBossTreasure = lua_util._readXml("/data/xml/MissionBossTreasure.xml", "id_i")

    self.mwsyData = {}
    tmp = lua_util._readXml("/data/xml/Mwsy.xml", "id_i")
    for _, v in pairs(tmp) do
        v[1] = _splitStr(v['difficulty1'], ":", tonumber)
        v[2] = _splitStr(v['difficulty2'], ":", tonumber)
        v[3] = _splitStr(v['difficulty3'], ":", tonumber)
    end
    self.mwsyData = tmp

--    self.missionResetCost = {}
--    tmp = lua_util._readXml("/data/xml/MissionResetCost.xml", "id_i")
--    for k, v in pairs(tmp) do
--        local tbl = {}
--        table.insert(tbl, tostring(v['difficulty']))
--        table.insert(tbl, tostring(v['times']))
--        self.missionResetCost[table.concat(tbl, "_")] = v['cost']
--    end
--
--    log_game_debug("MissionDataMgr:initData", "mwsyData=%s", mogo.cPickle(self.mwsyData))
end

function MissionDataMgr:IsMwsyMissionDifficulty(mission, difficulty)
    for _, v in pairs(self.mwsyData) do
        for i=1, 3 do
            if mission == v[i][1] and difficulty == v[i][2] then
                return true
            end
        end
    end
    return false
end

--指定玩家的等级和难度，获取迷雾深渊用到的关卡id和难度
function MissionDataMgr:GetMwsytMissionDifficulty(level, difficulty)
    for _, v in pairs(self.mwsyData) do
        if level >= v['level'][1] and level <= v['level'][2] then
            return v[difficulty]
        end
    end
end

function MissionDataMgr:getBossTreasure(id)
    return self.missionBossTreasure[id]
end

function MissionDataMgr:getAllMissions()
    return self.missionData
end

--function MissionDataMgr:getMissionResetCost(difficulty, times)
--    local key = difficulty .. "_" .. times
--    if self.missionResetCost then
--        return self.missionResetCost[key]
--    end
--end

function MissionDataMgr:getMissionRandomRewardTimes(star)
    local times = self.missionRandomRewardTimes[star] or {}
    return times['times'] or 0
end

--function MissionDataMgr:getMissionRandomRewardItem1(mission, difficulty)
--    local reward = self.missionRandomReward[mission] or {}
--    local items =  reward[difficulty] or {}
--    return items['item1'] or {}
--end

--function MissionDataMgr:getMissionRandomRewardItem2(mission, difficulty)
--    local reward = self.missionRandomReward[mission] or {}
--    local items =  reward[difficulty] or {}
--    return items['item2'] or {}
--end

--function MissionDataMgr:getMissionRandomRewardItem(mission, difficulty, vocation)
--    local reward = self.missionRandomReward[mission] or {}
--    local items =  reward[difficulty] or {}
--    local Random = mogo.deepcopy1(items['random'] or {})
--    for k, v in pairs(Random) do
--        Random[k] = v / 10000
--    end
--    local k = choose_prob(Random)
--    if k == 1 then
--        return items['item3'] or {}
--    elseif k == 2 then
--        return items['item4'] or {}
--    elseif k == 3 then
--        local DropId = items['dropId']
--        local result = {}
--        g_drop_mgr:GetAwards(result, DropId, vocation)
--        return result
--    else
--        return {}
--    end
--end

function MissionDataMgr:getMissionRandomReward(mission, difficulty, vocation)

    local result = {}

    local reward = self.missionRandomReward[mission] or {}
    local items =  reward[difficulty]

    if items then
        local Random = mogo.deepcopy1(items['random'] or {})
        if Random ~= {} then
            for i=1, g_GlobalParamsMgr:GetParams('mission_random_reward_num', 5) do
                --先算所有权值的总数
                local sum = 0
                for _, v in pairs(Random) do
                    sum = sum + v
                end

                --算出每一个值占得概率
                for k, v in pairs(Random) do
                    Random[k] = v / sum
                end

--                log_game_debug("MissionDataMgr:getMissionRandomReward", "mission=%d;difficulty=%d;Random=%s", mission, difficulty, mogo.cPickle(Random))

                local k = choose_prob(Random)

                --记录自己抽中了哪一项
                table.insert(result, k)
                --把抽中的那一项去掉
                Random[k] = nil
            end
        end
    end


    local rewardItems = {}

    for _, v in pairs(result) do
        if vocation == public_config.VOC_WARRIOR then
            table.insert(rewardItems, {[items['item1'][v]] = items['num'][v]})
        elseif vocation == public_config.VOC_ASSASSIN then
            table.insert(rewardItems, {[items['item2'][v]] = items['num'][v]})
        elseif vocation == public_config.VOC_ARCHER then
            table.insert(rewardItems, {[items['item3'][v]] = items['num'][v]})
        elseif vocation == public_config.VOC_MAGE then
            table.insert(rewardItems, {[items['item4'][v]] = items['num'][v]})
        end
    end

--    log_game_debug("MissionDataMgr:getMissionRandomReward", "mission=%d;difficulty=%d;result=%s;rewardItems=%s", mission, difficulty, mogo.cPickle(result), mogo.cPickle(rewardItems))

    return rewardItems
end

function MissionDataMgr:getDropByMapId(mission, difficulty)
    local key = mission .. "_" .. difficulty
    if self.missionData then
        return (self.missionData[key] or {})['drop']
    end
end

function MissionDataMgr:getMissionEvaluate(mission, difficulty)
    local key = mission .. "_" .. difficulty
    if self.missionEvaluate then
        return self.missionEvaluate[key]
    end
end

--function MissionDataMgr:isRandomMission(mission, difficulty)
--    local key = mission .. "_" .. difficulty
--    return self.randomMission[key]
--end

function MissionDataMgr:getMissionReward()
    return self.missionReward
end

--根据唯一id获取对应关卡的配置属性
function MissionDataMgr:getCfgById(Id)
    if self.missionData then
        return self.missionData[Id]
    end
end

function MissionDataMgr:getEventCfgById(Id)
    if self.missionEvent then
        return self.missionEvent[Id]
    end
end

--获取副本内所有刷怪点的id
function MissionDataMgr:getAllSpawnPointIds(mission, difficult)
    local tmpMissionCfg = self:getCfgById(tostring(mission) .. "_" .. tostring(difficult))
    if not tmpMissionCfg then
        return {}
    else
        local result = {}
        local events = tmpMissionCfg['events'] or {}
        for _, eventId in pairs(events) do
            local eventCfg = self:getEventCfgById(eventId)
            if eventCfg then
                local notifyOtherSpawnPoint = eventCfg['notifyOtherSpawnPoint']
                if notifyOtherSpawnPoint then
                    for _, spawnPointId in pairs(notifyOtherSpawnPoint) do
                        if spawnPointId ~= 99 then
                            result[spawnPointId] = 1
                        end
                    end
                end
            end
        end
        return result
    end
end

function MissionDataMgr:getRewardInfo(mission, difficult, vocation, includeJug)

    local tmpMissionCfg = self:getCfgById(tostring(mission) .. "_" .. tostring(difficult))

    if vocation == nil or tmpMissionCfg == nil then
        return
    end
    
    local src_map_id = tmpMissionCfg['scene']

--找map 找SpawnPointLevel 找monster 找drop
    local tblDst = {{}, {}, 0, 0}--怪物表：monsterId<=>num 奖励表：itemId<=>num 金钱累计：0 经验累计：0

    if src_map_id ~= nil then
        local map_entity_cfg_data = g_map_mgr:GetMapEntityCfgData(src_map_id)
        if map_entity_cfg_data ~= nil then
            for i, v in pairs(map_entity_cfg_data) do
                if v['type'] == 'SpawnPoint' then
                    local levelID = _splitStr(v['levelID'], ",", tonumber)
                    local tarDifficultSpawnPointLevel = levelID[difficult]
                    if tarDifficultSpawnPointLevel ~= nil then
                        g_monster_mgr:getSpawnPointLevelCfgInfoById(tblDst, tarDifficultSpawnPointLevel)
                    end
                end
            end
        end
    end

    --过滤门等trap
    for monsterId, num in pairs(tblDst[1]) do
        local tmpMonsterCfgData = g_monster_mgr:getCfgById(monsterId)
        if tmpMonsterCfgData ~= nil and tmpMonsterCfgData.monsterType > 4 then
            tblDst[1][monsterId] = nil
        end
    end

    if includeJug ~= nil and tmpMissionCfg['drop'] ~= nil then
	for monsterId, num in pairs(tmpMissionCfg['drop']) do 
	    if tblDst[1][monsterId] == nil then
		tblDst[1][monsterId] = 0
	    end
	    tblDst[1][monsterId] = tblDst[1][monsterId] + num
	end	
    end

    for monsterId, num in pairs(tblDst[1]) do
        local tmpMonsterCfgData = g_monster_mgr:getCfgById(monsterId)
        if tmpMonsterCfgData then
            --经验累加
            tblDst[4] = tblDst[4] + num * tmpMonsterCfgData.exp
            --道具获得（包括金钱）
            for index = 1, num do--逐个怪逐数量
                local tblDstMoney = {}
                g_monster_mgr:getDrop(tblDst[2], tblDstMoney, monsterId, vocation)
                    
                if #tblDstMoney > 0 then
                    for k,moneyNum in pairs(tblDstMoney) do
                        tblDst[3] = tblDst[3] + moneyNum
                    end--for
                end--if
            end--for
        end
    end

    tblDst[2][0] = nil--金钱次数没用了删掉
--    log_game_info('getMapMonsterInfo', '%s', mogo.cPickle(tblDst))
    return tblDst
end

--获取某副本可能刷出的道具
function MissionDataMgr:getRewardItemCfg(src_map_id, vocation)
    --
    
    local tmpMissionCfg = self:getCfgById(tostring(src_map_id) .. "_1")    


    if vocation == nil or tmpMissionCfg == nil then
        return
    end

    src_map_id = tmpMissionCfg['scene']

    local map_entity_cfg_data = nil
    if src_map_id ~= nil then
        map_entity_cfg_data = g_map_mgr:GetMapEntityCfgData(src_map_id)
        if map_entity_cfg_data == nil then
            return
        end
    end

    local difficultyCount = 0
    for i, v in pairs(map_entity_cfg_data) do
        if v['type'] == 'SpawnPoint' then
            local levelID = _splitStr(v['levelID'], ",", tonumber)
            difficultyCount = #levelID
            break
        end
    end

    if difficultyCount == nil or difficultyCount <= 0 then
        return
    end

    local tblDstDifficult = {}
    for i=1, difficultyCount do 
        table.insert(tblDstDifficult, {})
    end

    for difficult=1, difficultyCount do
        local tblDst = {{}, {}}--怪物表：monsterId<=>num 奖励表：itemId<=>num 

        for i, v in pairs(map_entity_cfg_data) do
           if v['type'] == 'SpawnPoint' then
               local levelID = _splitStr(v['levelID'], ",", tonumber)
               local tarDifficultSpawnPointLevel = levelID[difficult]
               if tarDifficultSpawnPointLevel ~= nil then
                   g_monster_mgr:getSpawnPointLevelCfgInfoById(tblDst, tarDifficultSpawnPointLevel)
               end
           end
        end

        for monsterId, num in pairs(tblDst[1]) do
            g_monster_mgr:getDropItemCfg(tblDst[2], monsterId, vocation)
        end

        for itemId, num in pairs(tblDst[2]) do
            table.insert(tblDstDifficult[difficult], itemId)
        end
    end--for
    
    

    return tblDstDifficult
end

function MissionDataMgr:GetMonsterEntityTotleCount(mission, difficult)
    local monsterEntityTotleCount = 0 

    local tmpMissionCfg = self:getCfgById(tostring(mission) .. "_" .. tostring(difficult))

    if tmpMissionCfg == nil then
        return monsterEntityTotleCount
    end

    local src_map_id = tmpMissionCfg['scene']

    local tblDst = {{}, {}, 0, 0}--怪物表：monsterId<=>num 奖励表：itemId<=>num 金钱累计：0 经验累计：0 

    if src_map_id ~= nil then
        local map_entity_cfg_data = g_map_mgr:GetMapEntityCfgData(src_map_id)
        if map_entity_cfg_data ~= nil then    
            for i, v in pairs(map_entity_cfg_data) do   
                if v['type'] == 'SpawnPoint' then
                    local levelID = _splitStr(v['levelID'], ",", tonumber)
                    local tarDifficultSpawnPointLevel = levelID[difficult]
                    if tarDifficultSpawnPointLevel ~= nil then
                        g_monster_mgr:getSpawnPointLevelCfgInfoById(tblDst, tarDifficultSpawnPointLevel)
                    end
                end
            end
        end
    end


    --过滤门等trap:monsterType <= 4
    for monsterId, num in pairs(tblDst[1]) do
        local tmpMonsterCfgData = g_monster_mgr:getCfgById(monsterId)
        if tmpMonsterCfgData and tmpMonsterCfgData.monsterType <= 4 and tmpMonsterCfgData.isClient ~= public_config.MONSTER_IS_CLIENT_DUMMY then
            monsterEntityTotleCount = monsterEntityTotleCount + num
        end
    end

    return monsterEntityTotleCount
end

g_mission_mgr = MissionDataMgr
return g_mission_mgr

