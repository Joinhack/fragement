require "lua_util"
require "public_config"
require "cli_entity_config"

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error

CliEntityManager = {
    msgMapping = {
    }
}
setmetatable(CliEntityManager, {__index = CliEntityManager})
CliEntityManager.__index = CliEntityManager

function CliEntityManager:new()

    local obj = {}
    setmetatable(obj, {__index = CliEntityManager})
    obj.__index = obj
    
    obj:init()

    return obj
end

function CliEntityManager:init()
    self.entityVec = {
        [cli_entity_config.CLI_ENTITY_TYPE_DUMMY] = {},
        [cli_entity_config.CLI_ENTITY_TYPE_JUG] = {},
	    [cli_entity_config.CLI_ENTITY_TYPE_DROP] = {},
        [cli_entity_config.CLI_ENTITY_TYPE_SPAWNPOINT] = {}
    }
    
    self.msgMapping[cli_entity_config.MSG_DIE] = CliEntityManager.onActionDie
    self.msgMapping[cli_entity_config.MSG_HITAVATAR] = CliEntityManager.onActionHitAvatar
end

function CliEntityManager:entityFactory()
    local obj = {}                       
    setmetatable(obj,               
    {__index =                           
        function (table, key)            
            return 0                     
        end                              
    }                                    
    )                                      
    return obj                           
end                                      

function CliEntityManager:addEntity(entityType, entity)
    if not self.entityVec[entityType] then
        return false
    end

    if not entity.eid then
        return false
    end

    self.entityVec[entityType][entity.eid] = entity
    entity.entityType = entityType

    return true
end

function CliEntityManager:delEntity(entity)
    self.entityVec[entity.entityType][entity.eid] = nil
end

function CliEntityManager:getEntity(eid)
    local entity = nil
    entity = self.entityVec[cli_entity_config.CLI_ENTITY_TYPE_DUMMY][eid]
    if entity then
        return entity
    end

    entity = self.entityVec[cli_entity_config.CLI_ENTITY_TYPE_JUG][eid]
    if entity then
        return entity
    end

    entity = self.entityVec[cli_entity_config.CLI_ENTITY_TYPE_DROP][eid]
    if entity then
	    return entity
    end

    return nil
end

function CliEntityManager:getEntityByType(cliEntityType)
    return self.entityVec[cliEntityType]
end

function CliEntityManager:pickleEntityBufByTblEid(dstTbl, tblSendEid, cliEntityType)
    if cliEntityType == nil then
    	return false
    end

    local entities = self.entityVec[cliEntityType]
    if not entities then
	    return false
    end
	
    for k,v in pairs(tblSendEid) do
    	if entities[v] then
            local entity = entities[v]
            if entity.entityType == cli_entity_config.CLI_ENTITY_TYPE_DUMMY then
                table.insert(dstTbl, {entity.entityType, entity.eid, entity.enterX, entity.enterY, entity.monsterId, entity.difficulty, entity.spawnPointCfgId})
            elseif entity.entityType == cli_entity_config.CLI_ENTITY_TYPE_DROP then
                table.insert(dstTbl, {entity.entityType, entity.eid, entity.enterX, entity.enterY, entity.gold, entity.itemId, entity.belongAvatar})
            end 
    	end
    end
end

function CliEntityManager:pickleEntityBuf(dstTbl, cliEntityType)
    if cliEntityType then
        local entities = self.entityVec[cliEntityType]
        if entities then
            for k2,v2 in pairs(entities) do
                local entity = v2
                if entity then
                    if entity.entityType == cli_entity_config.CLI_ENTITY_TYPE_DUMMY then
                        table.insert(dstTbl, {entity.entityType, entity.eid, entity.enterX, entity.enterY, entity.monsterId, entity.difficulty, entity.spawnPointCfgId})
                    elseif entity.entityType == cli_entity_config.CLI_ENTITY_TYPE_DROP then
                        table.insert(dstTbl, {entity.entityType, entity.eid, entity.enterX, entity.enterY, entity.gold, entity.itemId, entity.belongAvatar})
                    end 
                end
            end
        end
    end
end

function CliEntityManager:ProcessCliEntityTypeDel(cliEntityType)
    if cliEntityType == nil then
        for k, v in pairs(self.entityVec) do
            self.entityVec[k] = {}
        end
    else
        local tmpEntityVec = {}
        for k, v in pairs(self.entityVec[cliEntityType]) do
            tmpEntityVec[k] = v
        end

        local entities = tmpEntityVec
        if entities then
            for k2,v2 in pairs(entities) do
                local entity = v2
                if entity then
                    self:delEntity(entity)
                end
            end
        end
    end
end

function CliEntityManager:isEntityAllDie(cliEntityType, spawnPointCfgId)

    local entities = self.entityVec[cliEntityType]
    if entities then
        for k2,v2 in pairs(entities) do
            local entity = v2
            if entity and 
                (entity.isDeath == nil or entity.isDeath ~= 1) and
                entity.spawnPointCfgId == spawnPointCfgId then
                return false
            end
        end
    end
    return true
end

function CliEntityManager:ProcessEntityAction(spaceLoader, eid, actionId, avatar, tblParam)
    local entity = nil
    if actionId ~= cli_entity_config.MSG_HITAVATAR then
	entity = self:getEntity(eid)
	if entity == nil then
            return false
        end
    end

    local func = self.msgMapping[actionId]
    if func then
        func(self, spaceLoader, entity, avatar, tblParam)
    else
        return false
    end

    return true
end



function CliEntityManager:onActionDie(spaceLoader, entity, avatar, tblParam)
    if entity.entityType == cli_entity_config.CLI_ENTITY_TYPE_DUMMY then
        entity.isDeath = 1    	
    	
        local tblEntitiesAvatar = spaceLoader:GetPlayInfo()
        for dbid, tblAvatar in pairs(tblEntitiesAvatar) do
            local memberAvatarEid = tblAvatar[public_config.PLAYER_INFO_INDEX_EID]
            local memberAvatar = mogo.getEntity(memberAvatarEid)
            if memberAvatar then
                spaceLoader:AddExp(dbid, entity.exp)


        		local tblSendEid = {}
                local tblDstDropsItem = {}
                local tblDstMoney = {}

                g_monster_mgr:getDrop(tblDstDropsItem, tblDstMoney, entity.monsterId, memberAvatar.vocation, entity.difficulty)

                for itemId, itemNum in pairs(tblDstDropsItem) do
                    for i=1, itemNum do
                        local dropItem = self:GetIdleDropEntity(0, itemId, memberAvatarEid, spaceLoader, tblParam)
                        if dropItem ~= nil then
                            table.insert(tblSendEid, dropItem.eid)
                        end--if 
                    end
                end--for

                for key, moneyNum in pairs(tblDstMoney) do
                    local dropGold = self:GetIdleDropEntity(moneyNum, 0, memberAvatarEid, spaceLoader,tblParam)
                    if dropGold ~= nil then
                        table.insert(tblSendEid, dropGold.eid)
                    end--if
                end--for
                
        		--send awards
	    	    local sendBuf = {}
    	      	self:pickleEntityBufByTblEid(sendBuf, tblSendEid, cli_entity_config.CLI_ENTITY_TYPE_DROP)
	    	    memberAvatar:CreateCliEntityResp(sendBuf)			
            end
        end
        
        self:delEntity(entity)
        spaceLoader:TestSpawnPointMonsterDie(entity.spawnPointCfgId)
    end
end

function CliEntityManager:ProcessJugDie(spaceLoader, monsterId, x, y)

        local tblEntitiesAvatar = spaceLoader:GetPlayInfo()
        for dbid, tblAvatar in pairs(tblEntitiesAvatar) do
            local memberAvatarEid = tblAvatar[public_config.PLAYER_INFO_INDEX_EID]
            local memberAvatar = mogo.getEntity(memberAvatarEid)
            if memberAvatar then

      		local tblSendEid = {}
                local tblDstDropsItem = {}
                local tblDstMoney = {}

                g_monster_mgr:getDrop(tblDstDropsItem, tblDstMoney, monsterId, memberAvatar.vocation)

                for itemId, itemNum in pairs(tblDstDropsItem) do
                    local dropItem = self:GetIdleDropEntity(0, itemId, memberAvatarEid, spaceLoader, {x, y})

                    if dropItem ~= nil then
                        table.insert(tblSendEid, dropItem.eid)
                    end--if 
                end--for

                for key, moneyNum in pairs(tblDstMoney) do
                    local dropGold = self:GetIdleDropEntity(moneyNum, 0, memberAvatarEid, spaceLoader, {x, y})

                    if dropGold ~= nil then
                        table.insert(tblSendEid, dropGold.eid)
                    end--if
                end--for

        	--send awards
	    	local sendBuf = {}
  	      	self:pickleEntityBufByTblEid(sendBuf, tblSendEid, cli_entity_config.CLI_ENTITY_TYPE_DROP)
	    	memberAvatar:CreateCliEntityResp(sendBuf)			
            end
        end
end

function CliEntityManager:onActionHitAvatar(spaceLoader, entity, avatar, tblParam)
    local scene_line = lua_util.split_str(avatar.sp_ref.map_id, "_", tonumber) 
    if tblParam == nil or tblParam[1] == nil or tblParam[1] < 0 or scene_line[1] == g_GlobalParamsMgr:GetParams('init_scene', 10004) then
        return
    end
    if avatar.curHp > tblParam[1] then
    	avatar:addHp((avatar.curHp - tblParam[1])*-1) 
    end    

end

function CliEntityManager:GetIdleDropEntity(gold, itemTypeId, memberAvatarEid, spaceLoader, tblParam)
    if gold == nil or itemTypeId == nil then
        return
    end

    if gold <= 0 and itemTypeId <= 0 then 
        log_game_error(                                                    
                "CliEntityManager:GetIdleDropEntity",                            
                "parameter error:itemTypeId=%d",
                itemTypeId
               )                                                   
        return nil 
    end
    
    local newDrop = self:entityFactory()
		newDrop.eid = spaceLoader:getNextEntityId()
		newDrop.enterX 	= tblParam[1]
	        newDrop.enterY 	= tblParam[2]
		newDrop.gold    = gold
		newDrop.itemId	= itemTypeId            
		newDrop.belongAvatar=memberAvatarEid

    self:addEntity(cli_entity_config.CLI_ENTITY_TYPE_DROP, newDrop)    

    return newDrop
end

function CliEntityManager:GetDummyCount()
    local count = 0
    for k,v in pairs(self.entityVec[cli_entity_config.CLI_ENTITY_TYPE_DUMMY]) do
        count = count + 1
    end

    return count
end
