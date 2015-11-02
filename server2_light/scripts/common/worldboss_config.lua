require "lua_util"

--以下是程序给的默认值，如果配置文件有相应的配置的话会覆盖这个默认值
local worldboss_config = 
{
	PLAYER_STATE_OUT      = 0,
	PLAYER_STATE_ENTERING = 1,
	PLAYER_STATE_IN_LIVE  = 2,
	PLAYER_STATE_IN_DEAD  = 3,

	BC_NUM = 3,

	STATE_UNSORT  = 0,
	STATE_SORTING = 1,
	STATE_SORTED  = 2,

	ENTER_TIME_PER_DAY = 6,

	STATE_NOT_OPEN = 0,
	STATE_OPEN = 1,
	STATE_START = 2,
	STATE_STOP = 3,

	LVS = {20, 25, 30, 35, 40, 45, 50, 55, public_config.LV_MAX,},
	SPACES = {40001,40002,40003,40004,40005,40006,40007,40008,40009,},

	PRE_OPEN_TIME = 600, --提前10分钟设置可进
	WorldBossTimeStart = {20,0},
	WorldBossTimeIntervel = 86400,
	WorldBossTime = 1800,

	SHOW_TOP_N = 5, --排行榜显示top几位
	WDAY_REFRESH = 2, --周一刷新, 1代表星期天
	HOUR_WEEK_REFRESH = 0, --周排名刷新时间（小时）
	--local HOUR_WEEK_RANK_REWARD
	SEC_PER_WEEK = 604800, --

	SAVE_PER_TIME = 300, --每次保存300个玩家数据
	SAVE_INTERVEL = 300, --300秒
	SYN_INTERVEL = 5, --广播时间间隔

	HP_ADD_MOD = 0, --世界boss血量增加
	HP_DEL_MOD = 1, --世界boss血量减少


	BossHpSynMode_timer = 1,
	BossHpSynMode_per   = 2,
	BossHpSynMode_mix   = 3,

	BossHpSynMode = 1, --默认是定时，这个可以通过配置文件修改
	BossBasicHp = 200000,
	HP_CHANGE = 1, --按百分比同步
	HP_LEFT   = 10, --还没用上，本来打算用来做剩余10%血量时频繁同步
	SYN_HP_TIME = 5000, --2秒同步一次

	-->刷小怪相关
	--[[
	SUMMON_MOD_ALL_DEAD  = 1,  --之前的怪物全部死光才刷
	SUMMON_MOD_NUM_LIMIT = 2,  --达到上限不触发召唤
	SUMMON_MOD_KILL_LEFT = 3,  --杀死之前剩下的小怪
	]]

	SUMMON_MOD = 1,
	SUMMON_LIMIT = 20,
	SUMMON_SPWAN_LIST = {},

	HP_SELF_DECREASE_VAL = 0,
	HP_SELF_DECREASE_PERCENT = 0,
	HP_SELF_DECREASE_INTERVAL = 300,

	--<刷小怪相关

	--活动开启时间列表时:分
	WB_TIMES = {[12]=30, [20]=30,}
}

setmetatable(worldboss_config, {__index = function(t,k) return nil end})
--worldboss_config.__index = worldboss_config


local WBConfig = {}
--WBConfig继承worldboss_config
setmetatable(WBConfig, {__index=worldboss_config})

function WBConfig:initData()

    local tmp = lua_util._readXml('/data/xml/SanctuaryDefenseConfig.xml', 'key')
    --setmetatable(self.wb_config, {__index = function(t, k) return nil end})

    local function less(a, b)
    	return a < b
    end 
    local result = {}
    for key, value in pairs(tmp) do
    	if value['value'] then
	    	local k, v = lua_util.format_key_value(key, value['value'])
	    	if k == 'SPACES' or k == 'LVS' then
	    		table.sort(v, less)
	    	end
	    	result[k] = v
	    	self[k] = v
    	end
    end

    --self.wb_config = result

    lua_util.log_game_debug("WBConfig:initData", "WBConfig=%s", mogo.cPickle(result))

end

--g_wb_config = worldboss_config
g_wb_config = WBConfig

return g_wb_config
