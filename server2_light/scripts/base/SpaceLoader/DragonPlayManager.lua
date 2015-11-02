require "BasicPlayManager"
require "map_data"
require "lua_util"
require "dragon_data"
require "public_config"

local log_game_warning  = lua_util.log_game_warning
local log_game_debug    = lua_util.log_game_debug
local log_game_error    = lua_util.log_game_error

DragonPlayManager = BasicPlayManager.init()


function DragonPlayManager:init(atkerStr, attacker, pvpInfo)
    log_game_debug("DragonPlayManager:init", "ok")
    local obj = {}
    setmetatable(obj, {__index = DragonPlayManager})
    obj.__index = obj
    --setmetatable(obj.ptr,    {__mode = "v"})
    -->>>>  BasicPlayerManager的数据
    obj.StartTime = 0
    obj.Info = {}
    obj.Info[mission_config.SPECIAL_MAP_INFO_OWNER_DBID]           = 0
    obj.Info[mission_config.SPECIAL_MAP_INFO_OWNER_NAME]           = ''
    obj.Info[mission_config.SPECIAL_MAP_INFO_OWNER_MBSTR]          = ''
    obj.Info[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT]  = {}             --初始化已触发的刷怪点
    obj.Info[mission_config.SPECIAL_MAP_INFO_FINISHED_SPAWN_POINT] = {}             --初始化已经完成的刷怪点
    obj.Info[mission_config.SPECIAL_MAP_INFO_MISSION_ID]           = 0
    obj.Info[mission_config.SPECIAL_MAP_INFO_DIFFICULT]            = 0
    obj.Info[mission_config.SPECIAL_MAP_INFO_DROP]                 = {}             --初始化已经掉落的物品信息
    --<<<<
    obj.atkerMb     = mogo.UnpickleBaseMailbox(atkerStr)
    obj.attacker    = attacker
    obj.atkerLv     = pvpInfo.level
    local defInfo   = pvpInfo.defier
    obj.defier      = defInfo[public_config.DRAGON_PVP_DBID]
    obj.defierLv    = defInfo[public_config.DRAGON_PVP_LEVEL]
    obj.defierDgn   = defInfo[public_config.DRAGON_PVP_QUALITY] 
    obj.defierRng   = defInfo[public_config.DRAGON_PVP_CURRNG]
    return obj
end

function DragonPlayManager:DeathEvent(dbid)
    log_game_debug("DragonPlayManager:DeathEvent", "dbid=%q", dbid)
	local win  = -1
	local rewards = {}
	if dbid == self.attacker then
		win = public_config.DRAGON_BATTLE_LOSE
	elseif dbid == self.defier or dbid == 0 then
		win = public_config.DRAGON_BATTLE_WIN
		rewards = g_dragon_mgr:CaltAtkRewards(self.atkerLv, self.defierLv, self.defierDgn, self.defierRng)
	else
		return
	end
	local avatarMb = self.atkerMb
	if not avatarMb then return end
	if public_config.DRAGON_BATTLE_WIN == win then
		avatarMb.client.ShowRewardForms(rewards, 15, public_config.DRAGON_TITLE_WIN, public_config.DRAGON_TEXT_WIN, 1)
	else
		avatarMb.client.ShowRewardForms(rewards, 15, public_config.DRAGON_TITLE_LOSS, public_config.DRAGON_TEXT_LOSS, 0)
	end
	avatarMb.DragonBattleCallback(win, rewards, self.defier, self.defierDgn)
end
