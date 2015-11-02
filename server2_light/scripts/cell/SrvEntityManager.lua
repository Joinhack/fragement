require "lua_util"
require "public_config"

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning


SrvEntityManager = {
    NameMapping = {
        [public_config.ENTITY_TYPE_MONSTER]     = 'Monster',
        [public_config.ENTITY_TYPE_MERCENARY]   = 'Mercenary'},
    BusyEid = { [public_config.ENTITY_TYPE_MONSTER] = {},   
		[public_config.ENTITY_TYPE_MERCENARY] = {}},
    IdleEid = { [public_config.ENTITY_TYPE_MONSTER] = {},   
		[public_config.ENTITY_TYPE_MERCENARY] = {}},
    ExpandCount = { [public_config.ENTITY_TYPE_MONSTER] = 0,
        [public_config.ENTITY_TYPE_MERCENARY] = 0}
}

setmetatable(SrvEntityManager, {__index = SrvEntityManager})
SrvEntityManager.__index = SrvEntityManager

function SrvEntityManager:initData(tblEntitySizePerType)

    --初始化时创建若干个实体
    if not tblEntitySizePerType then
        tblEntitySizePerType = { [public_config.ENTITY_TYPE_MONSTER]     = 1000,
                                [public_config.ENTITY_TYPE_MERCENARY]   = 1000}
    end
    
    self.tblEntitySizePerType = tblEntitySizePerType

    for k,v in pairs(self.NameMapping) do
        self:ExpandIdle(k, tblEntitySizePerType[k])
    end
end

function SrvEntityManager:ExpandIdle(entityType, size)
    local idleTbl = self.IdleEid[entityType]
    local busyTbl = self.BusyEid[entityType]
    if idleTbl == nil or busyTbl == nil then
        return nil                          
    end                                     

    for i=1, size do                                             
        local entity = mogo.createEntityNotInSpace(self.NameMapping[entityType], {})
	    self:AddIdleEid(entity)
	end
    
    self.ExpandCount[entityType] = self.ExpandCount[entityType] + 1
     
    log_game_debug("SrvEntityManager:ExpandIdle", "expand %s current: IdleMonster:%d  IdleMercenary:%d BusyMonster:%d BusyMercenary:%d expandMonsterCount:%d  expandMercenaryCount:%d", 
            self.NameMapping[entityType],
            #self.IdleEid[public_config.ENTITY_TYPE_MONSTER],
            #self.IdleEid[public_config.ENTITY_TYPE_MERCENARY],
            #self.BusyEid[public_config.ENTITY_TYPE_MONSTER],    
            #self.BusyEid[public_config.ENTITY_TYPE_MERCENARY],
            self.ExpandCount[public_config.ENTITY_TYPE_MONSTER],
            self.ExpandCount[public_config.ENTITY_TYPE_MERCENARY])
end

function SrvEntityManager:GetIdleEntity(entityType) 
    local idleTbl = self.IdleEid[entityType]
    local busyTbl = self.BusyEid[entityType]
    if idleTbl == nil or busyTbl == nil then
        return nil                          
    end                                     
                                            
    local idleTblSize = #idleTbl            
    if idleTblSize == 0 then                
        self:ExpandIdle(entityType, self.tblEntitySizePerType[entityType])
        return self:GetIdleEntity(entityType)
    else                                    
        local dstEid = idleTbl[1]           
        table.remove(idleTbl, 1)            
        table.insert(busyTbl, dstEid)
        local tarEntity =  mogo.getEntity(dstEid)
        if tarEntity then--如果找不到证明已经不存在此实体,不加入Busy
            table.insert(busyTbl, dstEid)
        end
        return tarEntity                       
    end                                     
end                                         

function SrvEntityManager:AddIdleEid(entity)     
    if not entity then                      
        return false                        
    end                                     
                                            
    local entityType = entity.c_etype       
                                            
    local busyTbl = self.BusyEid[entityType]
    local idleTbl = self.IdleEid[entityType]
    if not idleTbl then                     
        return false                        
    end                                     
                                            
    local eid = entity:getId()              
    table.insert(idleTbl, eid)              
                                            
    return true                             
                                            
end                                         

function SrvEntityManager:Busy2Idle(entity)      
    if entity == nil then                   
        return false                        
    end                                     
                                            
    local entityType = entity.c_etype       
                                            
    local idleTbl = self.IdleEid[entityType]
    local busyTbl = self.BusyEid[entityType]
    if idleTbl == nil or busyTbl == nil then
        return false                        
    end                                     
                                            
    local eid = entity:getId()              
    local dstIndex = 0                      
    for index, busyEid in pairs(busyTbl) do 
        if busyEid == eid then              
            dstIndex = index                
            break                           
        end                                 
    end                                     
                                            
    if dstIndex == 0 then                   
        return false                        
    end                                     
                                            
    table.remove(busyTbl, dstIndex)         
    table.insert(idleTbl, eid)              

    entity:delFromSpace()    
                                        
    return true                             
end                                         

function SrvEntityManager:StopAliveMonster(SpaceLoader)
    local tblAliveMonster = {}

    if lua_util.get_table_real_count(SpaceLoader.AliveMonster) <= 0 then
        return
    end

    for k,v in pairs(SpaceLoader.AliveMonster) do
        tblAliveMonster[k] = v        
    end

    for eid, v in pairs(tblAliveMonster) do
        local busyEntity = mogo.getEntity(eid)
        if busyEntity ~= nil then
            SpaceLoader:RemoveAliveMonster(eid)
            busyEntity:Stop()
            self:Busy2Idle(busyEntity)
        end
    end
end

function SrvEntityManager:StopBusyEntity(entityType)   
    local idleTbl = self.IdleEid[entityType]      
    local busyTbl = self.BusyEid[entityType]      
    if idleTbl == nil or busyTbl == nil then      
        return false                              
    end                                           
                                                  
    local tmpBusyTbl = {}                         
    for index, busyEid in pairs(busyTbl) do       
        tmpBusyTbl[index] = busyEid               
    end                                           
    for index, busyEid in pairs(tmpBusyTbl) do    
        local busyEntity = mogo.getEntity(busyEid)
        if busyEntity ~= nil then                 
            busyEntity:Stop()                     
            self:Busy2Idle(busyEntity)
        end                                       
    end                                           
                                                  
    self.BusyEid[entityType] = {}                 
end                                               




g_SrvEntityMgr = SrvEntityManager
return g_SrvEntityMgr
