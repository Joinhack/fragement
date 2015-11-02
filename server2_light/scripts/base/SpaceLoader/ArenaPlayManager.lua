require "BasicPlayManager"
require "map_data"
require "lua_util"
require "arena_config"

local log_game_warning = lua_util.log_game_warning
local log_game_debug = lua_util.log_game_debug
local log_game_error = lua_util.log_game_error

ArenaPlayManager = BasicPlayManager.init()


function ArenaPlayManager:init(challenger_mb_str, challenger, pvpInfo)
    log_game_debug("ArenaPlayManager:init", "")
    local obj = {}
    setmetatable(obj, {__index = ArenaPlayManager})
    --obj.ptr = {}
    --setmetatable(obj.ptr,    {__mode = "v"})
    -->>>>  BasicPlayerManager的数据
    obj.StartTime = 0
    obj.Info = {}
    obj.Info[mission_config.SPECIAL_MAP_INFO_OWNER_DBID] = 0
    obj.Info[mission_config.SPECIAL_MAP_INFO_OWNER_NAME] = ''
    obj.Info[mission_config.SPECIAL_MAP_INFO_OWNER_MBSTR] = ''
    obj.Info[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT] = {}              --初始化已触发的刷怪点
    obj.Info[mission_config.SPECIAL_MAP_INFO_FINISHED_SPAWN_POINT] = {}             --初始化已经完成的刷怪点
    obj.Info[mission_config.SPECIAL_MAP_INFO_MISSION_ID] = 0
    obj.Info[mission_config.SPECIAL_MAP_INFO_DIFFICULT] = 0
    obj.Info[mission_config.SPECIAL_MAP_INFO_DROP] = {}                             --初始化已经掉落的物品信息
    --<<<<
    
    --pvp类型，1：弱敌，2：强敌，3：仇敌
    obj.pvpType = pvpInfo.pvpType or 0
    --pvp对象dbid
    obj.defier = pvpInfo.defier or 0
    --挑战者的战斗力
    obj.challenger_mb = mogo.UnpickleBaseMailbox(challenger_mb_str)
    --挑战者的dbid
    obj.challenger = challenger

    obj.arenicGrade = pvpInfo.arenicGrade or 0
    obj.level = pvpInfo.level or 0
    return obj
end

function ArenaPlayManager:DeathEvent(dbid)
	local win = -1
	if dbid == 0 then
		win = 1
	elseif dbid == self.challenger then
		win = 0
	elseif dbid == self.defier then
		win = 1
		--update his enemy
		local mm = globalBases['UserMgr']
		if mm and dbid ~= 0 then
			mm.UpdateDefierInfo(self.challenger, self.defier)
		end
	else
		log_game_debug("ArenaPlayManager:DeathEvent", "dbid = %q", dbid)
		return
	end
	local rewards = g_arena_config:GetChallengeReward(self.pvpType, self.arenicGrade, self.level, win)

	if rewards then
		local avatar_mb = self.challenger_mb
		if not avatar_mb then return end
		if 1 == win then
			avatar_mb.client.ShowRewardForms(rewards, 15, arena_text_id.REWARDS_TITLE_WIN, arena_text_id.REWARDS_TEXT_WIN, 1)
			if self.pvpType == 3 then
				avatar_mb.EventDispatch("arenaSystem", "BeatEnemy", {})
			end
		else
			avatar_mb.client.ShowRewardForms(rewards, 15, arena_text_id.REWARDS_TITLE_LOSS, arena_text_id.REWARDS_TEXT_LOSS, 0)
		end
		avatar_mb.EventDispatch('arenaSystem', 'GetRewards', {rewards})
	end
end
