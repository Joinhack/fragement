--主角技能映射怪物AI使用的技能ID
require "lua_util"
require "error_code"

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error

local _splitStr = lua_util.split_str

local SkillIdReflectMgr = {}
SkillIdReflectMgr.__index = SkillIdReflectMgr

--读取配置数据
function SkillIdReflectMgr:initData()
    self.reflectData = {}
    local tmp = lua_util._readXml("/data/xml/SkillIdReflect.xml", "id_i")
    
    for k, v in pairs(tmp) do
        if v.aiSlot < 1 or v.aiSlot > 7 then
            --error  
        else
            self.reflectData[v.avatarSkillId] = {mercenarySkillId = v.mercenarySkillId, aiSlot = v.aiSlot}       
        end
    end
end

function SkillIdReflectMgr:getCfgByAvatarSkillId(skillId)
    if self.reflectData then
        return self.reflectData[skillId]
    end
end

function SkillIdReflectMgr:reflectSkillTbl(tblAvatarSkill) 
    local tblMercenarySkill = {0,0,0,0,0,0,0}
    for skillId, v in pairs(tblAvatarSkill) do
        if v > 0 then
            local cfg = self.reflectData[skillId]
            if cfg and tblMercenarySkill[cfg.aiSlot] < cfg.mercenarySkillId then
                tblMercenarySkill[cfg.aiSlot] = cfg.mercenarySkillId
            end
        end
    end

    return tblMercenarySkill
end

g_skillIdReflect_mgr = SkillIdReflectMgr
return g_skillIdReflect_mgr

