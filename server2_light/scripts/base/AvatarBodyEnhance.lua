--author:hwj
--date:2013-4-23
--此为Avatar扩展类,只能由Avatar require使用
--避免Avatar.lua文件过长
--身体强化子系统begin -->
local log_game_debug = lua_util.log_game_debug
--test begin
--[[
function Avatar:AddGold( num )
    self.gold = self.gold + num
    return self.gold
end
]]
--[[ 道具信息字段
item = {
  typeId = , --(number)道具模板id
  avatarId = , --(number)分配给avatar的dbid
  count = , --(number)道具实际个数
  bagGridType = , --(number)背包类型
  gridIndex = , --(number)道具索引
  sourceKey = , --(number)装备来源key：1副本,2锻造,3任务
  sourceValue = , --(number)装备来源id：副本id,锻造id,任务id
  bindingType = , --(number)绑定类型
  leftCoolTime = , --(number)道具剩余冷却时间
  slots = , --(string)宝石插槽：针对装备
  extendInfo = , --(string)扩展信息
}
--]]
--[[
function Avatar:AddMaterial( typeId, num )
    self.IninventorySystem:Add
end
]]
--test end

function Avatar:BodyEnhaLevReq()
--    if id ~= self.dbid then
--        self.client.OnBodyEnhaLevResp({}, error_code.ERR_BODY_ENHANCE_PARA)
--        return
--    end
    --如果没有身体信息就创建一个初始的信息
    if self.body == nil then
        self.body = {}
    end 
    self.client.OnBodyEnhaLevResp(self.body, error_code.ERR_BODY_ENHANCE_SUCCEED)    
end

function Avatar:BodyEnhaUpgReq(position) 
    log_game_debug("Avatar:BodyEnhaUpgReq", "position = %d", position) 
    if self.bodyEnhanceSystem then        
        local err, lack = self.bodyEnhanceSystem:Req(msgBodyEnhance.MSG_UPGRADE, position)
        self.client.OnBodyEnhaUpgResp(err, lack)
        return
    end
    --self.client.OnBodyEnhaUpgResp(error_code.ERR_BODY_ENHANCE_OTHER) 
end

function Avatar:BodyEnhaInfoReq(position, level)
    if self.bodyEnhanceSystem == nil then
        self.client.OnBodyEnhaUpgCodiResp({}, error_code.ERR_BODY_ENHANCE_OTHER) 
    end       
    local aEnhanceInfo, err =  self.bodyEnhanceSystem:Req(msgBodyEnhance.MSG_GET_ENHANCE_NIFO, position, level)
    if err ~= error_code.ERR_BODY_ENHANCE_SUCCEED then
        self.client.OnBodyEnhaUpgCodiResp({}, err) 
        return
    end
    self.client.OnBodyEnhaInfoResp(aEnhanceInfo, error_code.ERR_BODY_ENHANCE_SUCCEED)
end

function Avatar:BodyEnhaPropReq(position, level)
    if self.bodyEnhanceSystem == nil then
        self.client.OnBodyEnhaPropResp({}, error_code.ERR_BODY_ENHANCE_OTHER) 
    end
    log_game_debug("Avatar:BodyEnhaPropReq", "position = %d", position)
    local prop, err = self.bodyEnhanceSystem:Req(msgBodyEnhance.MSG_GET_ENHANCE_PROP, position, level) 
    log_game_debug("Avatar:BodyEnhaPropReq", "err = %d", err)
    if err ~= error_code.ERR_BODY_ENHANCE_SUCCEED then
        self.client.OnBodyEnhaPropResp({}, err) 
        return
    end
    self.client.OnBodyEnhaPropResp(prop, error_code.ERR_BODY_ENHANCE_SUCCEED)
end
--身体强化子系统end -->
