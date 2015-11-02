---
-- Created by kevinhua.
-- User: Administrator
-- Date: 13-3-26
-- Time: 15:27
-- 出生点.
--


local public_config = require "public_config"

require "lua_util"
require "error_code"
require "Monster"
require "cli_entity_config"
require "SrvEntityManager"

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error
local math_sqrt = math.sqrt
local math_floor = math.floor


------------------------------------------------------------------------------------------------
SpawnPoint = {}
setmetatable(SpawnPoint, {__index = SpawnPoint})
SpawnPoint.__index = SpawnPoint
------------------------------------------------------------------------------------------------

function SpawnPoint:GetIdleMonsterEntity(tblData, spaceLoader, selfData)
    local tmpCfgData = tblData.cfgData
    if tmpCfgData == nil then
        return nil
    end

--    local entityTypeName
    local entityType
    if tmpCfgData.isClient == public_config.MONSTER_IS_CLIENT_DUMMY then
        return nil
    else
--        entityTypeName = 'Monster'
        entityType = public_config.ENTITY_TYPE_MONSTER
    end
    
--    log_game_debug("SpawnPoint:GetIdleMonsterEntity", "tmpCfgData=%s", mogo.cPickle(tmpCfgData))


    local entity = SrvEntityManager:GetIdleEntity(entityType)

    if entity ~= nil then

            entity:setXY(tblData.enterX, tblData.enterY)
            entity.enterX = tblData.enterX
            entity.enterY = tblData.enterY
            entity.homerangeX = selfData.homerangeX
            entity.homerangeY = selfData.homerangeY
            entity.homerangeLength = selfData.homerangeLength
            entity.homerangeWidth = selfData.homerangeWidth
            entity.monsterId = tblData.monsterId
            entity.spawnPointCfgId = selfData.cfgId
            entity.model = tmpCfgData.model
            entity.clientTrapId = tmpCfgData.clientTrapId
            entity.ai = tmpCfgData.aiId
            entity.notTurn = tmpCfgData.notTurn
            entity.difficulty = tblData.difficulty


            entity:addToSpace(spaceLoader:getSpaceId(), tblData.enterX, tblData.enterY, 0)
    else
        log_game_error("old monster entity is nil", "")  

    end




    return entity
end



function SpawnPoint:GetIdleMercenaryEntity(tblData, spaceLoader, selfData)
    local tmpCfgData = tblData.cfgData
    if tmpCfgData == nil then
        return nil
    end

--    local entityTypeName = 'Mercenary'
    local entityType = public_config.ENTITY_TYPE_MERCENARY
    
    log_game_debug("SpawnPoint:GetIdleMercenaryEntity", "tmpCfgData=%s", mogo.cPickle(tmpCfgData))

    local entity = SrvEntityManager:GetIdleEntity(entityType) 
    
    if entity ~= nil then
        entity:setXY(tblData.enterX, tblData.enterY)
        entity.ownerEid = 0
        entity.monsterId = tblData.monsterId
        entity.spawnPointCfgId = selfData.cfgId
        entity.clientTrapId = tmpCfgData.clientTrapId
        entity.notTurn = tmpCfgData.notTurn
        entity.difficulty = tblData.difficulty
        entity:ProcessBattleProperties(tmpCfgData) 

        entity:addToSpace(spaceLoader:getSpaceId(), tblData.enterX, tblData.enterY, 0)
    else
        log_game_error("old mercenary entity is nil", "entityI")  
    end

--    log_game_debug('SpawnPoint:GetIdleMercenaryEntity Create a Old:' , 'entityTypeName:%s id:%d monsterId:%d spaceId:%d', entityTypeName, entity:getId(), tblData.monsterId, spaceLoader:getSpaceId())


    return entity
end

--副本刷新，里面包括怪物刷新
function SpawnPoint:Start(tblParam, spaceLoader, monsterDifficulty)--0:踩点 1:副本开始
    if monsterDifficulty == nil then
        monsterDifficulty = 0
    end 

    local triggerType = tblParam.triggerType
    if triggerType == nil then    
        triggerType = public_config.SPAWNPOINT_TRIGGER_TYPE_STEP--如果没填默认是踩点
    end

    if spaceLoader == nil then
        log_game_error('SpawnPoint:Start 0.1', 'spaceLoader == nil')
        return nil
    end

    if spaceLoader.map_id == nil then
        log_game_error('SpawnPoint:Start 0.2', 'spaceLoader.map_id == nil')
        return nil
    end

    local selfData = tblParam.spawnPointData

    local difficulty = tblParam.difficulty
    local a = selfData.triggerType
    local b = tblParam.triggerType
    if a - b ~= 0 then
        return nil
    end

    local rntStartedMonsterIds = {} --返回开始的怪物配置ID

    if type(tblParam) ~= 'table' then
        --error参数要table
        return nil
    end
	

    if selfData.monsterDifficltCfg[difficulty] == nil then 
        log_game_error('SpawnPoint:Start 1', 'difficult=%d;map_id=%s', difficulty, spaceLoader.map_id)
    end

    if selfData.monsterDifficltCfg[difficulty]['num'] == nil then
        log_game_error('SpawnPoint:Start 2', 'difficult=%d;map_id=%s', difficulty, spaceLoader.map_id)
    end

    local tmpTblMonsterNumber = selfData.monsterDifficltCfg[difficulty]['num']
    
    local tmpTblMonsterId = selfData.monsterDifficltCfg[difficulty]['ids']

    local tmpMonsterIdVector = {}
    for index=1, #tmpTblMonsterId do
        for index2=1, tmpTblMonsterNumber[index] do
            
            table.insert(tmpMonsterIdVector, tmpTblMonsterId[index])
        end
    end
    

    local tmpCurMonsterNumberCount = #tmpMonsterIdVector --制造monsterNumber只怪
    selfData.monsterNumber = tmpCurMonsterNumberCount

    
    --
    local coordSize = #selfData.monsterSpawntPoint
    local randomCoordIndexTbl = {}
    for coordIndex=1, coordSize, 2 do
        table.insert(randomCoordIndexTbl, coordIndex)
    end

    coordSize = #randomCoordIndexTbl
    for index=1, coordSize do
        local randomIndex = math.random(1, coordSize)
        local tmpValue = randomCoordIndexTbl[index]
        randomCoordIndexTbl[index] = randomCoordIndexTbl[randomIndex]
        randomCoordIndexTbl[randomIndex] = tmpValue
    end


--    log_game_debug("SpawnPoint:Start", "tblParam=%s;monsterDifficltCfg=%s;tmpMonsterIdVector=%s;tmpCurMonsterNumberCount=%d", mogo.cPickle(tblParam), mogo.cPickle(selfData.monsterDifficltCfg), mogo.cPickle(tmpMonsterIdVector), tmpCurMonsterNumberCount)
    
    if tmpCurMonsterNumberCount > coordSize then
        tmpCurMonsterNumberCount = coordSize --需要刷出的怪物数量不允许比坐标数还多
    end
    
    for i = 1, tmpCurMonsterNumberCount do   
        local tmpCfgData = g_monster_mgr:getCfgById(tmpMonsterIdVector[i], monsterDifficulty)

        if tmpCfgData ~= nil then
            if tmpCfgData.isClient == public_config.MONSTER_IS_CLIENT_MERCENARY then
                local entity = self:GetIdleMercenaryEntity(
                        {
                            cfgData = tmpCfgData,
                            enterX = selfData.monsterSpawntPoint[randomCoordIndexTbl[i]],
                            enterY = selfData.monsterSpawntPoint[randomCoordIndexTbl[i]+1],
                            monsterId = tmpMonsterIdVector[i],
                            difficulty = monsterDifficulty
                        },
                        spaceLoader,
                        selfData                
                    )

                if entity ~= nil then
--                    log_game_debug("SpawnPoint:Start Mercenary", "i=%d", i)
                    entity:Start(tmpCfgData)
        		    table.insert(rntStartedMonsterIds, tmpMonsterIdVector[i])
                end
            elseif tmpCfgData.isClient == public_config.MONSTER_IS_CLIENT_MONSTER or 
                tmpCfgData.isClient == public_config.MONSTER_IS_CLIENT_BOSS then 
                local entity = self:GetIdleMonsterEntity(
                        {
                            cfgData = tmpCfgData,
                            enterX = selfData.monsterSpawntPoint[randomCoordIndexTbl[i]],
                            enterY = selfData.monsterSpawntPoint[randomCoordIndexTbl[i]+1],
                            monsterId = tmpMonsterIdVector[i],
                            difficulty = monsterDifficulty
                        },
                        spaceLoader,
                        selfData
                    )
                
                if entity ~= nil then
--                    log_game_debug("SpawnPoint:Start monster", "i=%d", i)
                    entity:Start(tmpCfgData)
		            table.insert(rntStartedMonsterIds, tmpMonsterIdVector[i])
                end
            else
                --dummy
                local newDummy = spaceLoader.CliEntityManager:entityFactory()
                newDummy.eid = spaceLoader:getNextEntityId() 
                newDummy.enterX = selfData.monsterSpawntPoint[randomCoordIndexTbl[i]]
                newDummy.enterY = selfData.monsterSpawntPoint[randomCoordIndexTbl[i]+1]
                newDummy.monsterId = tmpMonsterIdVector[i]
                newDummy.difficulty = monsterDifficulty
                newDummy.exp = tmpCfgData.exp
                newDummy.spawnPointCfgId = selfData.cfgId 
                
                
                spaceLoader.CliEntityManager:addEntity(cli_entity_config.CLI_ENTITY_TYPE_DUMMY, newDummy)
		table.insert(rntStartedMonsterIds, tmpMonsterIdVector[i])
            end
        end
    end

    return rntStartedMonsterIds
end

------------------------------------------------------------------------------------------------

return SpawnPoint


