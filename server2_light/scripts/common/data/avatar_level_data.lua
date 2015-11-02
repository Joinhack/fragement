
require "lua_util"
local log_game_debug = lua_util.log_game_debug
local AvatarLevelDataMgr = {}
AvatarLevelDataMgr.__index = AvatarLevelDataMgr

--读取配置数据
function AvatarLevelDataMgr:initData()
    self.data = lua_util._readXml("/data/xml/AvatarLevel.xml", "id_i")
end


function AvatarLevelDataMgr:getCfg()
    return self.data
end
--取得角色等级的属性效果id
function AvatarLevelDataMgr:GetLevelEffectId(level)
    --重新读取配置计算一级属性
    local cfgs = self.data 
    if not cfgs == nil then
        return nil
    end

    local tmpCfgData = cfgs[level]
    if tmpCfgData == nil then
        return nil
    end
    local effectId = tmpCfgData.effectId
    return effectId
end
--提供给体力系统
function AvatarLevelDataMgr:GetLevelProps(level)
    local cfgs = self.data 
    if cfgs == nil then
        return nil
    end
    local tmpCfgData = cfgs[level]
    if tmpCfgData == nil then
        return nil
    end
    return tmpCfgData
end

g_avatar_level_mgr = AvatarLevelDataMgr
return g_avatar_level_mgr

