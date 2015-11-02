
require "BasicPlayManager"
require "map_data"
require "lua_util"
require "lua_map"
require "reason_def"
require "public_config"
require "channel_config"
require "action_config"
require "GlobalParams"
require "avatar_level_data"
require "mission_config"


local log_game_debug    = lua_util.log_game_debug
local log_game_info     = lua_util.log_game_info
local log_game_warning  = lua_util.log_game_warning
local _readXml          = lua_util._readXml
local confirm           = lua_util.confirm
local get_table_real_count = lua_util.get_table_real_count


DefensePvPManager     = BasicPlayManager.init()


--守护PvP活动的每局时间，单位：分钟
local PLAY_TIME 	= 10

--复活延时，单位：秒
local RELIVE_DELAY  = 5

--复活点
local RELIVE_POINT  = {{1520,1279}, {1520,11043}}

--个人奖励
local reward_personal_data  = {}

--队伍奖励
local reward_team_data  = {}


function DefensePvPManager:InitGlobalData()
	PLAY_TIME               = g_GlobalParamsMgr:GetParams('defense_pvp_play_time', PLAY_TIME)
    RELIVE_POINT            = g_GlobalParamsMgr:GetParams('defense_pvp_enter_point', RELIVE_POINT)
end

function DefensePvPManager:init(space_loader, game_id, map_id)
    log_game_debug("DefensePvPManager:init", "")

    local newObj = {}
    newObj.ptr   = {}
    setmetatable(newObj, 		{__index = DefensePvPManager})
    setmetatable(newObj.ptr,    {__mode = "v"})

    newObj.ptr.theSpaceLoader = space_loader

    newObj.gameID           = game_id

    --副本内玩家的信息
    newObj.playerData		= lua_map:new()

    --指向DefensePvPMgr的MailBox
    newObj.defensePvPMB     = nil

    --阵营信息
    newObj.factionData 		= {[1] = {point = 0, tower = 1}, [2] = {point = 0, tower = 1}}

    --玩家的最高等级
    newObj.maxLevel 		= 1

    --创建时间
    newObj.createTime       = os.time()

    --定时器ID
    newObj.timerID          = 0

    --玩家信息，接口层跳线（外部需要本类提供此数据接口）
    newObj.PlayerInfo = {}

    newObj.CellInfo = {}
    newObj.Events = {}

    newObj.StartTime = 0
    newObj.EndTime = 0

    newObj.CellInfo[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT] = {}               --初始化已触发的刷怪点
    newObj.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_PROCESS] = {}                   --初始化副本进度
    newObj.CellInfo[mission_config.SPECIAL_MAP_INFO_END_TIMER_ID] = 0                       --副本结束的定时器ID
    newObj.CellInfo[mission_config.SPECIAL_MAP_INFO_SUCCESS_TIMER_ID] = 0
    --    obj.CellInfo[mission_config.SPECIAL_MAP_INFO_TOWER_DESTORY_TIMER_ID] = 0             --试炼之塔结束的定时器ID
    newObj.CellInfo[mission_config.SPECIAL_MAP_INFO_MONSTER_AUTO_DIE] = 0

    newObj.CellInfo[mission_config.SPECAIL_MAP_INFO_DELAY_EVENT] = {}                       --延迟触发的事件
    newObj.CellInfo[mission_config.SPECAIL_MAP_INFO_DELAY_TIMER_ID] = {}                     --延迟触发的事件定时器ID

    return newObj
end

function DefensePvPManager:InitData(defense_pvp_mb_str, pvpInfo, maxLevel)
    self.defensePvPMB 	= mogo.UnpickleBaseMailbox(defense_pvp_mb_str)
	self.maxLevel 		= maxLevel

	for avatar_dbid, sampleInfo in pairs(pvpInfo) do
		self.playerData:insert(avatar_dbid, 
		{
			dbid 		= sampleInfo[1],
			name		= sampleInfo[2],
			faction 	= sampleInfo[3],
			point 		= 0,
			killed		= 0,
			attackFrom 	= {},
            reliveTick  = 0,
		})
	end

    self:SetInfo(maxLevel)
    --self:SetInfo(maxLevel)
    self:StartEventInit(self.ptr.theSpaceLoader)
    self.ptr.theSpaceLoader:PrepareEntities(1, maxLevel)
	--self.ptr.theSpaceLoader:PrepareEntities2(maxLevel, public_config.SPAWNPOINT_TRIGGER_TYPE_STEP)
    self.timerID = self.ptr.theSpaceLoader:addLocalTimer("OnLocalTimer", 5 * 1000, 0)
end

function DefensePvPManager:SetInfo(difficulty)
    self.CellInfo[mission_config.SPECIAL_MAP_INFO_MISSION_ID] = g_GlobalParamsMgr:GetParams("defense_pvp_mission", 42000)
    self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT] = difficulty

    local tbl = {}
    table.insert(tbl, g_GlobalParamsMgr:GetParams("defense_pvp_mission", 42000))
    table.insert(tbl, difficulty)

    local cfg = g_mission_mgr:getCfgById(table.concat(tbl, "_"))

    if cfg and cfg['events'] then
        for _, event in pairs(cfg['events']) do
            local EventCfg = g_mission_mgr:getEventCfgById(event)
            if EventCfg then
                if EventCfg['param'] and EventCfg['type'] == mission_config.SPECIAL_MAP_EVENT_SPAWNPOINT_MONSTER_ALL_DEAD then
                    local params = lua_util.split_str(EventCfg['param'], ",", tonumber)
                    local result = {}
                    for _, param in pairs(params) do
                        result[param] = false
                    end
                    self.Events[event] = {[mission_config.SPECIAL_MAP_EVENT_SPAWNPOINT_MONSTER_ALL_DEAD] = result }
                elseif EventCfg['type'] == mission_config.SPECIAL_MAP_EVENT_INIT then
                    self.Events[event] = {[mission_config.SPECIAL_MAP_EVENT_INIT] = true}
                end
            end
        end
    end
end

function DefensePvPManager:Start(space_loader, start_time)
	if false then return end
end

function DefensePvPManager:Recover(space_loader)
    --只Stop不Reset重置
    --不做任何操作
    --space_loader:Stop()
end

function DefensePvPManager:Stop(space_loader)
    for _, data in pairs(self.playerData) do
        if data.avatar then
            self:ExitMission(data.dbid)
        end
    end
end

function DefensePvPManager:Reset(space_loader)
    for _, data in pairs(self.playerData) do
        if data.avatar then
            self:ExitMission(data.dbid)
        end
    end
    space_loader.base.Reset()

    if self.CellInfo[mission_config.SPECAIL_MAP_INFO_DELAY_TIMER_ID] then
        for _, id in pairs(self.CellInfo[mission_config.SPECAIL_MAP_INFO_DELAY_TIMER_ID]) do
            space_loader:delTimer(id)
        end
        self.CellInfo[mission_config.SPECAIL_MAP_INFO_DELAY_TIMER_ID] = {}
    end
end

function DefensePvPManager:ExitMission(avatar_dbid)
    local data = self.playerData[avatar_dbid]
    if data and data.avatar then
        local avatarObj = data.avatar
        avatarObj.base.MissionC2BReq(action_config.MSG_EXIT_MAP, 0, 0, '')
    end
end

--调用当前副本里的cell上指定阵营玩家的对象接口（阵营若为0则代表副本内所有玩家）
function DefensePvPManager:AvatarCall(faction_id, sub_system_name, member_func_name, ...)
    if not member_func_name or member_func_name == "" then return end

    for _, playerData in pairs(self.playerData) do
        if faction_id == 0 or faction_id == playerData.faction then
        	local avatarObj = playerData.avatar
	        if avatarObj then
	            local theSelf = nil
	            local theFunc = nil
	            if not sub_system_name or sub_system_name == "" or  sub_system_name == "Avatar" then
	                theSelf = avatarObj
	                theFunc = avatarObj[member_func_name]
	            elseif sub_system_name == "client" then
	                theSelf = nil
	                theFunc = avatarObj.base.client[member_func_name]
	            else
	                theSelf = avatarObj[sub_system_name]
	                theFunc = theSelf[member_func_name]
	            end

	            if theFunc then
	                if theSelf then
	                    theFunc(theSelf, ...)
	                else
	                    theFunc(...)
	                end
	            end
	        end
        end
    end
end

function DefensePvPManager:CalculatePoint()
    local playerData = {}
    local factionData = {}
	local faction1_killed = 0
	local faction2_killed = 0
    local i = 1
	for avatar_dbid, data in pairs(self.playerData) do
		if data.faction == 1 then
			faction1_killed = faction1_killed + data.killed
			self.playerData[avatar_dbid].point = math.ceil(data.killed * 250 + (1 - self.factionData[2].tower) * 5000)
		else
			faction2_killed = faction2_killed + data.killed
			self.playerData[avatar_dbid].point = math.ceil(data.killed * 250 + (1 - self.factionData[1].tower) * 5000)
		end
		playerData[i] = {[1]=avatar_dbid, [2]=self.playerData[avatar_dbid].point}
        i = i + 1
	end

    self.factionData[1].point = math.ceil(faction1_killed * 250 + (1 - self.factionData[2].tower) * 5000)
    self.factionData[2].point = math.ceil(faction2_killed * 250 + (1 - self.factionData[1].tower) * 5000)

    factionData[1] = {self.factionData[1].point, self.factionData[1].tower}
    factionData[2] = {self.factionData[2].point, self.factionData[2].tower}

    self:AvatarCall(0, "client", "DefensePvpPointRefresh", playerData, factionData)
end

function DefensePvPManager:GameClose()
    local spaceLoader = self.ptr.theSpaceLoader

    --关闭计时器
    if self.timerID == 0 then return end
    if self.timerID ~= 0 then
        self.ptr.theSpaceLoader:delLocalTimer(self.timerID)
        self.timerID = 0
    end

    --计算积分
	self:CalculatePoint()
    local playersPoint = {}
    for avatar_dbid, data in pairs(self.playerData) do
        if data.point ~= 0 then
            playersPoint[avatar_dbid] = data.point
        end
    end
    local winnerFaction = 0
    if self.factionData[1].tower == 0 then
        winnerFaction = 2
    elseif self.factionData[2].tower == 0 then
        winnerFaction = 1
    else
        if self.factionData[1].point > self.factionData[2].point then
            winnerFaction = 1
        elseif self.factionData[1].point < self.factionData[2].point then
            winnerFaction = 2
        end
    end

    --设置所有怪物自动死亡
    self:MonsterAutoDie(spaceLoader)

    --设置所有怪物
    g_SrvEntityMgr:StopAliveMonster(spaceLoader)

    --关闭游戏
    self.defensePvPMB.MgrEventDispatch("", "EventCloseGame", {self.gameID, playersPoint, winnerFaction}, "", "", {})

    --关闭刷怪定时器（必须在所有怪物自动死亡后再删除，因为死亡会触发新的定时器）
    if self.CellInfo[mission_config.SPECAIL_MAP_INFO_DELAY_TIMER_ID] then
        for _, id in pairs(self.CellInfo[mission_config.SPECAIL_MAP_INFO_DELAY_TIMER_ID]) do
            spaceLoader:delTimer(id)
        end
        self.CellInfo[mission_config.SPECAIL_MAP_INFO_DELAY_TIMER_ID] = {}
    end

    --延时重置
    spaceLoader:addLocalTimer("Stop", 23000, 1) --20s后
    spaceLoader:addLocalTimer("Reset", 30000, 1) --30s后    
end


---------------------------------------------------------

function DefensePvPManager:OnLocalTimer()
	if os.time() - self.createTime > PLAY_TIME * 60 then
		--游戏结束
        self:GameClose()
		return
	end

    --计算积分
	self:CalculatePoint()

    --检查复活
    self:CheckRelive()
end


---------------------------------------------------------

function DefensePvPManager:OnAvatarCtor(avatar_obj)
    log_game_debug("DefensePvPManager:OnAvatarCtor", "avatar_dbid=%q;name=%s", avatar_obj.dbid, avatar_obj.name)

    self.playerData[avatar_obj.dbid].avatar = avatar_obj
    avatar_obj.factionFlag = self.playerData[avatar_obj.dbid].faction

    self.PlayerInfo[avatar_obj.dbid] = {[public_config.PLAYER_INFO_INDEX_EID]=avatar_obj:getId(), 
                                    [public_config.PLAYER_INFO_INDEX_DEADTIMES]=0, 
                                    [public_config.PLAYER_INFO_INDEX_USE_DRUG_TIMES]=0,
                                    [public_config.PLAYER_INFO_INDEX_NAME]=avatar_obj.name,
                                    [public_config.PLAYER_INFO_INDEX_REWARDS] = {[public_config.PLAYER_INFO_REWARDS_EXP] = 0,
                                                                                 [public_config.PLAYER_INFO_REWARDS_MONEY] = 0,
                                                                                 [public_config.PLAYER_INFO_REWARDS_ITEMS] = {}},
                                    [public_config.PLAYER_INFO_INDEX_DAMEGE] = 0,
                                    [public_config.PLAYER_INFO_INDEX_BASEMB] = {}
    }

    local count = get_table_real_count(self.PlayerInfo)
end

function DefensePvPManager:OnAvatarDctor(avatar_obj)
    log_game_debug("DefensePvPManager:OnAvatarDctor", "avatar_dbid=%q;name=%s", avatar_obj.dbid, avatar_obj.name)

    self.playerData[avatar_obj.dbid].avatar = nil
    avatar_obj.factionFlag = 1
end

function DefensePvPManager:DoDamageAction(attacker, defender, harm)
    if harm <= 0 then return end
    if defender.c_etype == public_config.ENTITY_TYPE_AVATAR then
    	self:AttackPlayer(attacker, defender, harm)
    elseif defender.c_etype == public_config.ENTITY_TYPE_MONSTER and defender.factionFlag ~= 0 then
    	self:AttackTower(attacker, defender, harm)
	else
    	return
    end
end

function DefensePvPManager:AttackPlayer(attacker, player, harm)
	if not self.playerData[player.dbid] then return end

	if player:IsDeath() then
		for attacker_dbid, _ in pairs(self.playerData[player.dbid].attackFrom) do
			if self.playerData[attacker_dbid] then
				self.playerData[attacker_dbid].killed = self.playerData[attacker_dbid].killed + 1
			end
		end
        self.playerData[player.dbid].attackFrom = {}
		self.playerData[player.dbid].reliveTick = mogo.getTickCount()
	else
		self.playerData[player.dbid].attackFrom[attacker.dbid] = 1
	end
end

function DefensePvPManager:AttackTower(attacker, tower, harm)
	local tower_faction = tower.factionFlag
	if tower:IsDeath() then
        self.factionData[tower_faction].tower = 0
		self:GameClose()
	else
        self.factionData[tower_faction].tower = tower.curHp / tower.battleProps.hp
	end
end

function DefensePvPManager:CheckRelive()
    local nowTick = mogo.getTickCount()
    for _, playerData in pairs(self.playerData) do
        local avatarObj = playerData.avatar
        if avatarObj then
            if avatarObj:IsDeath() then
                if nowTick - playerData.reliveTick > RELIVE_DELAY * 1000 then
                    avatarObj:setHp(avatarObj.hp)
                    local faction = avatarObj.factionFlag
                    avatarObj:TelportLocally(RELIVE_POINT[faction][1], RELIVE_POINT[faction][2])
                end
            end
        end
    end
end

function DefensePvPManager:StartEventInit(SpaceLoader)
    for event, eventResult in pairs(self.Events) do
        if eventResult[mission_config.SPECIAL_MAP_EVENT_INIT] then
            eventResult[mission_config.SPECIAL_MAP_EVENT_INIT] = false

            --触发该事件的条件已经达成，通知客户端触发事件
            self.Events[event] = nil
            local EventCfg = g_mission_mgr:getEventCfgById(event)

            local notifyOtherSpawnPoint = EventCfg['notifyOtherSpawnPoint']
            if notifyOtherSpawnPoint then
                for _, cfgId in pairs(notifyOtherSpawnPoint) do
                    local spwanPoints = SpaceLoader.CliEntityManager:getEntityByType(cli_entity_config.CLI_ENTITY_TYPE_SPAWNPOINT)
                    if spwanPoints then
                        --                            log_game_debug("TowerDefencePlayManager:Start notifyOtherSpawnPoint", "map_id=%s;spwanPoints=%s", SpaceLoader.map_id, mogo.cPickle(spwanPoints))
                        for _, spawnPointEntity in pairs(spwanPoints) do
                            --                                log_game_debug("TowerDefencePlayManager:SpawnPointEvent", "spawnPointEntity.cfgId=%d;cfgId=%d", spawnPointEntity.cfgId, cfgId)
                            if spawnPointEntity.cfgId == cfgId then
                                SpawnPoint:Start({spawnPointData = spawnPointEntity,
                                    difficulty = self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT],
                                    triggerType = public_config.SPAWNPOINT_TRIGGER_TYPE_STEP},
                                    SpaceLoader)
                                --副本记录该刷怪点已经开始刷怪
                                self.CellInfo[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT][cfgId] = true
                                SpaceLoader:SyncCliEntityInfo()
                            end
                        end
                    end
                end
            end
        end
    end
end

function DefensePvPManager:HandleDelayEvent(SpaceLoader)
    if lua_util.get_table_real_count(self.CellInfo[mission_config.SPECAIL_MAP_INFO_DELAY_EVENT]) > 0 then
        local cfgId = table.remove(self.CellInfo[mission_config.SPECAIL_MAP_INFO_DELAY_EVENT], 1)

        local spwanPoints = SpaceLoader.CliEntityManager:getEntityByType(cli_entity_config.CLI_ENTITY_TYPE_SPAWNPOINT)
        if spwanPoints then

            log_game_debug("BasicPlayManager:HandleDelayEvent", "map_id=%s;spwanPoints=%s;cfgId=%d", SpaceLoader.map_id, mogo.cPickle(spwanPoints), cfgId)

            for _, spawnPointEntity in pairs(spwanPoints) do
                if spawnPointEntity.cfgId == cfgId then
                    --SpwanPoints开始刷怪

                    SpawnPoint:Start({spawnPointData = spawnPointEntity,
                        difficulty = self.CellInfo[mission_config.SPECIAL_MAP_INFO_DIFFICULT],
                        triggerType = public_config.SPAWNPOINT_TRIGGER_TYPE_STEP},
                        SpaceLoader)
                    --副本记录该刷怪点已经开始刷怪
                    self.CellInfo[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT][cfgId] = true
                    SpaceLoader:SyncCliEntityInfo()
                end
            end
        end
    end
end


---------------------------------------------------------

g_DefensePvPManager = DefensePvPManager
return g_DefensePvPManager