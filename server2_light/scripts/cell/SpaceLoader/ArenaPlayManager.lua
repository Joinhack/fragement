require "BasicPlayManager"
require "map_data"
require "lua_util"
require "public_config"
require "BasicPlayManager"

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning

--local TIMER_ID_END     = 1    --副本(关卡)结束的定时器
--local TIMER_ID_SUCCESS = 2    --副本(关卡)成功后的定时器
--local TIMER_ID_MONSTER_DIE = 3--副本(关卡)成功后演示若干秒怪物死亡

ArenaPlayManager = BasicPlayManager.init()

function ArenaPlayManager:init(SpaceLoader, params)
    log_game_debug("ArenaPlayManager:init", "")

    local newObj = {}
    newObj.ptr = {}
    setmetatable(newObj, {__index = ArenaPlayManager})
    setmetatable(newObj.ptr,    {__mode = "v"})
    -->>>>  BasicPlayerManager的数据
    newObj.PlayerInfo = {}
    newObj.CellInfo = {}
    newObj.Events = {}

    newObj.StartTime = 0
    newObj.EndTime = 0
    
    newObj.CellInfo[mission_config.SPECIAL_MAP_INFO_OWNER_DBID] = 0
    newObj.CellInfo[mission_config.SPECIAL_MAP_INFO_OWNER_NAME] = ''
    newObj.CellInfo[mission_config.SPECIAL_MAP_INFO_OWNER_MBSTR] = ''
    newObj.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID] = 0
    newObj.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT] = 0
    newObj.CellInfo[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT] = {}               --初始化已触发的刷怪点
    newObj.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_PROCESS] = {}                   --初始化副本进度
    newObj.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID] = 0                       --副本结束的定时器ID
    newObj.CellInfo[mission_config.SPECIAL_MAP_INFO_SUCCESS_TIMER_ID] = 0
    --<<<<
    
    newObj.ptr.theSpaceLoader = SpaceLoader

    newObj.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID] = 41000
    newObj.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT] = 1
    newObj.challenger_bufId = 0
    newObj.dead = -1
    newObj.pvpType = params.pvpType or 0
    --玩家信息，接口层跳线（外部需要本类提供此数据接口）
    
    
    return newObj
end

function ArenaPlayManager:Start(SpaceLoader, StartTime)
    --佣兵
    for dbid, info in pairs(self.PlayerInfo) do
    	local avatar = mogo.getEntity(info[public_config.PLAYER_INFO_INDEX_EID])
    	if avatar and avatar.pvpDbid > 0 then
            avatar:addLocalTimer("CreateMercenaryReq", 2000, 1, self.pvpType)
        end
    end
    --开始计时
    local missionId = tostring(self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID])
    local difficult = tostring(self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT])

    local tbl = {}
    table.insert(tbl, missionId)
    table.insert(tbl, difficult)

    log_game_debug("ArenaPlayManager:Start", "missionId=%s;difficult=%s;StartTime=%d",
                                              missionId, difficult, StartTime)

    if self.StartTime == 0 then
        self.StartTime = StartTime

        local cfg = g_mission_mgr:getCfgById(table.concat(tbl, "_"))

        --获取配置文件里的关卡通过时间，如果大于0，则设置副本结束时触发的定时器
        if cfg and cfg['passTime'] > 0 then
            log_game_debug("ArenaPlayManager:Start", "passTime=%d", cfg['passTime'])
            local now = os.time()
            local endTime = self.StartTime + cfg['passTime']
            if endTime > now then
                self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID] = SpaceLoader:addTimer((endTime - now), 0, public_config.TIMER_ID_END)
                log_game_debug("ArenaPlayManager:Start", "triggerTime=%d", (endTime - now))
            end
        end
    end
end

function ArenaPlayManager:DeathEvent(dbid, SpaceLoader)
	log_game_debug("ArenaPlayManager:DeathEvent", "%d", dbid)
	SpaceLoader.base.DeathEvent(dbid)
    --
    self.dead = dbid
    if self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID] then
        SpaceLoader:delTimer(self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID])
    end
    self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID] = SpaceLoader:addTimer(17, 0, public_config.TIMER_ID_END)
end


function ArenaPlayManager:ExitMission(dbid)
    log_game_debug("ArenaPlayManager:ExitMission", "")
    if self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID] then
        local SpaceLoader = self.ptr.theSpaceLoader
        SpaceLoader:delTimer(self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID])
        if self.dead == -1 then
            self.dead = dbid
            SpaceLoader.base.DeathEvent(dbid)
            --主动退出时也需要等奖励框显示完再退出
            return
        end
    end
    if self.PlayerInfo[dbid] then 
        local eid = self.PlayerInfo[dbid][public_config.PLAYER_INFO_INDEX_EID]
        local player = mogo.getEntity(eid)
        
        player.base.MissionC2BReq(action_config.MSG_EXIT_MAP, 0, 0, '')
    end
end

function ArenaPlayManager:QuitMission(dbid)
    log_game_debug("ArenaPlayManager:QuitMission", "")
    if self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID] then
        local SpaceLoader = self.ptr.theSpaceLoader
        SpaceLoader:delTimer(self.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID])
        if self.dead == -1 then
            self.dead = dbid
            SpaceLoader.base.DeathEvent(dbid)
        end
    end
    if self.PlayerInfo[dbid] then
        local eid = self.PlayerInfo[dbid][public_config.PLAYER_INFO_INDEX_EID]
        local player = mogo.getEntity(eid)
        player.base.MissionC2BReq(action_config.MSG_EXIT_MAP, 0, 0, '')
    end
end
