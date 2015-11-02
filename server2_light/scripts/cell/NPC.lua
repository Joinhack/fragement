
require "lua_util"
require "SkillSystem"

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info

NPC = {}
setmetatable(NPC, CellEntity)


--构造函数
function NPC:__ctor__()
    log_game_debug("NPC.__ctor__", "id=%d", self:getId())

    self.c_etype = public_config.ENTITY_TYPE_NPC

    --不可加载技能系统，因为缺少状态等属性
    --self.skillSystem = SkillSystem:New(self)
end

--当cell对象进入Space时由引擎回调
function NPC:onEnterSpace()
    log_game_debug("NPC:onEnterSpace", "spaceId=%d", self:getSpaceId())

    local sp = g_these_spaceloaders[self:getSpaceId()]
    if sp then
        sp.Register(self)
    end
end
