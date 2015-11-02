
require "lua_util"

local DropDataMgr = {}
DropDataMgr.__index = DropDataMgr

--读取配置数据
function DropDataMgr:initData()
    self.dropData = {}
    
    local tmp = lua_util._readXml("/data/xml/Drop.xml", "id_i")
    
    self.dropData = tmp
    
    for k,v in pairs(self.dropData) do
        v.dropGroup = {
            v.dropGroup0, v.dropGroup1, v.dropGroup2, v.dropGroup3
        }
    end

end


--根据唯一id获取对应关卡的配置属性
function DropDataMgr:getCfgById(Id)
    if self.dropData then
        return self.dropData[Id]
    end
end

function DropDataMgr:GetAwards(dstAwards, groupId, vocation)
    local dropCfgData = self:getCfgById(groupId)
    if dropCfgData == nil then
        return nil
    end
    local tblDataCopy = dropCfgData.dropGroup[vocation]

    local weightSum = 0             
    for k,v in pairs(tblDataCopy) do
        weightSum = weightSum + v   
    end                               

    if weightSum <= 0 then
        return nil        
    end                   

    local ran = math.random(1, weightSum)

    for k,v in pairs(tblDataCopy) do 
        ran = ran - v                
        if ran <= 0 then             
            if dstAwards[k] == nil then 
                dstAwards[k] = 0        
            end                      
            dstAwards[k] = dstAwards[k] + 1
            break                    
        end                          
    end

    return dstAwards
end

function DropDataMgr:GetAwardsItemCfg(dstAwards, groupId, vocation)
    local dropCfgData = self:getCfgById(groupId)
    if dropCfgData == nil then
        return nil
    end
    local tblDataCopy = dropCfgData.dropGroup[vocation]
    for k,v in pairs(tblDataCopy) do
        if dstAwards[k] == nil then
            dstAwards[k] = 0
        end
        dstAwards[k] = dstAwards[k] + 1
    end
end

g_drop_mgr = DropDataMgr
return g_drop_mgr

