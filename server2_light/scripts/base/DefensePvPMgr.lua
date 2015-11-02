--PvP防御对抗活动


require "lua_util"
require "lua_map"
require "public_config"
require "channel_config"
require "GlobalParams"
require "global_data"
require "reason_def"


local log_game_debug 	= lua_util.log_game_debug
local log_game_warning 	= lua_util.log_game_warning
local log_game_info 	= lua_util.log_game_info
local log_game_error 	= lua_util.log_game_error
local _readXml          = lua_util._readXml
local globalbase_call	= lua_util.globalbase_call


DefensePvPMgr 	= {}
setmetatable(DefensePvPMgr, {__index = BaseEntity})


--忽略排队，满人数立即开启
local IGNORE_QUEUEING 	= 1

--守护PvP活动的玩家数量限制（单方阵营的玩家数）
local LIMIT_PLAYER 		= 3
local TIME_START 		= os.time{year=2000, month=1, day=1, hour=19, min=0, sec=0}
local TIME_STOP 		= os.time{year=2000, month=1, day=1, hour=19, min=30, sec=0}

--队列在10-20人之间的TICK
local TICK_QUE10_20 	= mogo.getTickCount()

--队列在20-40人之间的TICK
local TICK_QUE20_40 	= mogo.getTickCount()

--队列在10-20人之间的等待时间，单位：毫秒
local WAIT_QUE10_20 	= 30 * 1000

--队列在20-40人之间的等待时间，单位：毫秒
local WAIT_QUE20_40 	= 60 * 1000

--地图ID
local MAP_ID 			= 42000

--等级限制
local LIMIT_LEVEL		= 35

--最大GameID
local maxGameID         = 0

--计算积分的日期（用于记录更新玩家积分，每过一天清空一次积分，范围[1,31]，若为0则代表未登记日期）
local pointDay          = 0

--开启公告（关闭时为0，开启时为1，从0到1转变时发出公告）
local startPublish 		= 0

--准备公告（关闭时为0，开启时为1，从0到1转变时发出公告）
local preparePublish	= 0

--通过GM命令激活活动
local gmActive 			= false

--个人奖励
local reward_personal_data  = {}

--队伍奖励
local reward_team_data  = {}


--消息提示，对应ChineseData.xml表定义
local TEXT_NOT_ACTIVE    	= 1009001        	--不在活动时间内！
local TEXT_ALREADY_QUEUE 	= 1009002 			--你已经在队列里！
local TEXT_CANCEL_QUEUE  	= 1009003 			--你已成功离开队列！
local TEXT_NOT_IN_QUEUE  	= 1009004 			--你不在队列中，无法离开！
local TEXT_IN_GAME  	 	= 1009005 			--你已在游戏中，无法离开队列！
local TEXT_PUBLISH_START 	= 1009006 			--PvP已开启，请{0}级以上玩家迅速报告参加。
local TEXT_PUBLISH_PREPARE	= 1009007 			--PvP将在{0}分钟后开启，请{1}级以上玩家做好准备。


----------------------------------------------------------------------------------------

function DefensePvPMgr:InitRewardData()
	local totalRank = LIMIT_PLAYER * 2
	for i = 1, totalRank do
		reward_personal_data[i] = {}
	end

	--胜利方奖励
	reward_team_data[1] = {}

	--失败方奖励
	reward_team_data[2] = {}


    local personal_datas = _readXml('/data/xml/Reward_DefecsePvP_Personal.xml', 'id_i')
    if personal_datas then
        for _, reward_data in pairs(personal_datas) do
        	if reward_data.rank and reward_data.rank >=1 and reward_data.rank <= totalRank then
        		if reward_data.level and reward_data.level >= 1 then
        			local data = {}
        			data.exp = reward_data.exp or 0
        			data.gold = reward_data.gold or 0
        			data.reward = reward_data.reward or {}
        			reward_personal_data[reward_data.rank][reward_data.level] = data
        		end
        	end
        end
    end

    local team_datas = _readXml('/data/xml/Reward_DefecsePvP_Team.xml', 'id_i')
    if team_datas then
        for _, reward_data in pairs(team_datas) do
        	if reward_data.condition and (reward_data.condition == 1 or reward_data.condition == 2) then
        		if reward_data.level and reward_data.level >= 1 then
        			local data = {}
        			data.exp = reward_data.exp or 0
        			data.gold = reward_data.gold or 0
        			data.reward = reward_data.reward or {}
        			reward_team_data[reward_data.condition][reward_data.level] = data
        		end
        	end
        end
    end
end

function DefensePvPMgr:GetPersonalRewardExp(rank, level)
	if not reward_personal_data[rank] then return 0 end
	if not reward_personal_data[rank][level] then return 0 end
	return reward_personal_data[rank][level].exp
end

function DefensePvPMgr:GetPersonalRewardGold(rank, level)
	if not reward_personal_data[rank] then return 0 end
	if not reward_personal_data[rank][level] then return 0 end
	return reward_personal_data[rank][level].gold
end

function DefensePvPMgr:GetPersonalRewardItemTable(rank, level)
	if not reward_personal_data[rank] then return {} end
	if not reward_personal_data[rank][level] then return {} end
	return reward_personal_data[rank][level].reward
end

function DefensePvPMgr:GetTeamRewardExp(win_flag, level)
	if not reward_team_data[win_flag] then return 0 end
	if not reward_team_data[win_flag][level] then return 0 end
	return reward_team_data[win_flag][level].exp
end

function DefensePvPMgr:GetTeamRewardGold(win_flag, level)
	if not reward_team_data[win_flag] then return 0 end
	if not reward_team_data[win_flag][level] then return 0 end
	return reward_team_data[win_flag][level].gold
end

function DefensePvPMgr:GetTeamRewardItemTable(win_flag, level)
	if not reward_team_data[win_flag] then return {} end
	if not reward_team_data[win_flag][level] then return {} end
	return reward_team_data[win_flag][level].reward
end


----------------------------------------------------------------------------------------

function DefensePvPMgr:__ctor__()
	log_game_debug("DefensePvPMgr:__ctor__", "")

    --玩家ID->玩家信息
    self.mapPlayerInfo 		= lua_map:new()

    --玩家ID->玩家积分（内存永久信息）
    self.mapPlayerPoint		= lua_map:new()

	--游戏ID->{游戏ID,状态，玩家信息简表}，状态为1时代表正在创建地图，为2代表地图创建完毕
	self.mapGameInfo 		= lua_map:new()

    --排队队列
	self.queWaitting 		= {}

    --当前正在处理的MailBoxStr
    self.nowMailBoxStr 		= ""

    self:addLocalTimer("ProcTimer", 10000, 0)

	local function RegisterGloballyCB(ret)
		if ret == 1 then
			--注册成功
            self:OnRegistered()
		else
			--注册失败
            log_game_error("DefensePvPMgr:RegisterGlobally Error", '')
		end
	end
	self:RegisterGlobally("DefensePvPMgr", RegisterGloballyCB)
end

function DefensePvPMgr:OnRegistered()
	log_game_debug("DefensePvPMgr:OnRegistered", "")
    globalbase_call('GameMgr', 'OnMgrLoaded', 'DefensePvPMgr')
end

function DefensePvPMgr:InitData()
	LIMIT_PLAYER 	= g_GlobalParamsMgr:GetParams('defense_pvp_limit_player', LIMIT_PLAYER)
	TIME_START 		= g_GlobalParamsMgr:GetParams('defense_pvp_start_time', TIME_START)
	TIME_STOP 		= g_GlobalParamsMgr:GetParams('defense_pvp_stop_time', TIME_STOP)
	MAP_ID 			= g_GlobalParamsMgr:GetParams('defense_pvp_map_id', MAP_ID)
    LIMIT_LEVEL 	= g_GlobalParamsMgr:GetParams('defense_pvp_limit_level', LIMIT_LEVEL)
    IGNORE_QUEUEING = g_GlobalParamsMgr:GetParams('defense_pvp_ignore_queueing', IGNORE_QUEUEING)
    self:InitRewardData()
end

function DefensePvPMgr:GetNowMailBox()
    if not self.nowMailBoxStr or self.nowMailBoxStr == "" then return nil end
    return mogo.UnpickleBaseMailbox(self.nowMailBoxStr)
end

function DefensePvPMgr:GetNowMailBoxStr()
    return self.nowMailBoxStr
end

function DefensePvPMgr:MgrEventDispatch(mbStr, mgr_func_name, mgr_func_param_table, callback_sys_name, callback_func_name, callback_func_param_table)
    log_game_debug("DefensePvPMgr:MgrEventDispatch", "Execute!")

    if not mbStr then return end
    self.nowMailBoxStr = mbStr

    local a, b, c, d
	local theFunc = self[mgr_func_name]
    local theSize = lua_util.get_table_real_count(mgr_func_param_table)
    if theSize == 0 then 
        a, b, c, d = theFunc(self)
    elseif theSize == 1 then
        a, b, c, d = theFunc(self, mgr_func_param_table[1])
    elseif theSize == 2 then
        a, b, c, d = theFunc(self, mgr_func_param_table[1], mgr_func_param_table[2])
    elseif theSize == 3 then
        a, b, c, d = theFunc(self, mgr_func_param_table[1], mgr_func_param_table[2], mgr_func_param_table[3])
    elseif theSize == 4 then
        a, b, c, d = theFunc(self, mgr_func_param_table[1], mgr_func_param_table[2], mgr_func_param_table[3], mgr_func_param_table[4])
    elseif theSize == 5 then
        a, b, c, d = theFunc(self, mgr_func_param_table[1], mgr_func_param_table[2], mgr_func_param_table[3], mgr_func_param_table[4], mgr_func_param_table[5])
    elseif theSize == 6 then
        a, b, c, d = theFunc(self, mgr_func_param_table[1], mgr_func_param_table[2], mgr_func_param_table[3], mgr_func_param_table[4], mgr_func_param_table[5], mgr_func_param_table[6])
    else
        log_game_debug("DefensePvPMgr:MgrEventDispatch", "mgr_func_param_table too more params!")
        return
    end
    if not callback_func_name or callback_func_name == "" or not callback_func_param_table then return end

    log_game_debug("DefensePvPMgr:MgrEventDispatch", "Transmit!")

	local mb = self:GetNowMailBox()
    if not mb then
        log_game_debug("DefensePvPMgr:MgrEventDispatch", "Mailbox not found!")
    	return
    end

	local new_arg
	local org_arg = callback_func_param_table
    theSize = lua_util.get_table_real_count(org_arg)
    if theSize == 0 then
    	new_arg = {a, b, c, d}
    elseif theSize == 1 then
    	new_arg = {org_arg[1], a, b, c, d}
    elseif theSize == 2 then
    	new_arg = {org_arg[1], org_arg[2], a, b, c, d}
    elseif theSize == 3 then
    	new_arg = {org_arg[1], org_arg[2], org_arg[3], a, b, c, d}
    elseif theSize == 4 then
    	new_arg = {org_arg[1], org_arg[2], org_arg[3], org_arg[4], a, b, c, d}
    elseif theSize == 5 then
    	new_arg = {org_arg[1], org_arg[2], org_arg[3], org_arg[4], org_arg[5], a, b, c, d}
    elseif theSize == 6 then
    	new_arg = {org_arg[1], org_arg[2], org_arg[3], org_arg[4], org_arg[5], org_arg[6], a, b, c, d}
    else
        log_game_debug("DefensePvPMgr:MgrEventDispatch", "callback_func_param_table too more params!")
        return
    end

    log_game_debug("DefensePvPMgr:MgrEventDispatch", "Transmit Execute!")
    mb.EventDispatch(callback_sys_name, callback_func_name, new_arg)
end


------------------------------------------------------------------------

function DefensePvPMgr:EventGmOpen(open_flag)
    if open_flag == 1 then
    	gmActive = true
    else
    	gmActive = false
    end
end

function DefensePvPMgr:EventApply(avatar_dbid, avatar_name, avatar_level, avatar_fight)
	if self:IsActive() ~= true and gmActive ~= true then
		self:Send_ShowTextID(CHANNEL.TIPS, TEXT_NOT_ACTIVE)
		return
	end

	local playerInfo = 
	{
		avatarDbid      = avatar_dbid,      	--玩家dbid
        avatarName      = avatar_name,      	--玩家名称
        avatarLevel     = avatar_level,     	--玩家等级（创建时）
        avatarfight     = avatar_fight,     	--玩家战斗力
        faction 		= 0, 					--玩家阵营（0代表还没规划，1代表A阵营，2代表B阵营）
        gameID 			= 0, 					--游戏ID（0代表还没规划）
        avatarMB		= self:GetNowMailBox(),	--玩家的MailBox
	}
	if self.mapPlayerInfo:insert(avatar_dbid, playerInfo) == false then
		self.mapPlayerInfo[avatar_dbid].avatarMB = self:GetNowMailBox()
		local playerInfo = self.mapPlayerInfo[avatar_dbid]
		if not playerInfo then return end
		if playerInfo.faction == 0 or playerInfo.gameID == 0 then
			self:Send_ShowTextID(CHANNEL.TIPS, TEXT_ALREADY_QUEUE)
		else
			self:EventEnter(avatar_dbid)
		end
		return
	end
	table.insert(self.queWaitting, avatar_dbid)

	self:Send_DefensePvPApplyResp(#self.queWaitting)
	self:CheckStart()
end

function DefensePvPMgr:EventCancel(avatar_dbid, notify_flag)
	local playerInfo = self.mapPlayerInfo:find(avatar_dbid)
	if not playerInfo then
		if notify_flag == 1 then
			self:Send_ShowTextID(CHANNEL.TIPS, TEXT_NOT_IN_QUEUE)
		end
		return
	end
	if playerInfo.gameID ~= 0 then
		if notify_flag == 1 then
			self:Send_ShowTextID(CHANNEL.TIPS, TEXT_IN_GAME)
		end
		return
	end

	self.mapPlayerInfo:erase(avatar_dbid)
	self:ClearWaittingQueue()

	if notify_flag == 1 then
		self:Send_ShowTextID(CHANNEL.TIPS, TEXT_CANCEL_QUEUE)
	end
end

function DefensePvPMgr:EventEnter(avatar_dbid)
	local playerInfo = self.mapPlayerInfo[avatar_dbid]
	if not playerInfo then return end
	if playerInfo.faction == 0 or playerInfo.gameID == 0 then return end

    local gameInfo = self.mapGameInfo[playerInfo.gameID]
    if not gameInfo or gameInfo.state ~= 2 then return end

    local mm = globalBases['MapMgr']
    mm.SelectMapReq(self:GetNowMailBoxStr(), MAP_ID, playerInfo.gameID, playerInfo.avatarDbid, playerInfo.avatarName, {playerInfo.faction})

    local elapseTime = os.time() - gameInfo.createTime
    self:Send_DefensePvpEnterResp(gameInfo.players, elapseTime)
end

function DefensePvPMgr:EventCreateGameComplete(game_id)
    if not game_id then return end

    local gameInfo = self.mapGameInfo[game_id]
    if not gameInfo or gameInfo.state ~= 1 then return end
    self.mapGameInfo[game_id].state = 2
    self.mapGameInfo[game_id].createTime = os.time()

	self:SendGroup_Message(game_id, 0, "DefensePvPOpened", {})
end

function DefensePvPMgr:EventCloseGame(game_id, playersPoint, winnerFaction)
	self:CalculateAward(game_id, playersPoint, winnerFaction)

	for avatar_dbid, point in pairs(playersPoint) do
		if self.mapPlayerPoint[avatar_dbid] then
			self.mapPlayerPoint[avatar_dbid] = self.mapPlayerPoint[avatar_dbid] + point
		else
			self.mapPlayerPoint:insert(avatar_dbid, point)
		end
	end

	local players = self.mapGameInfo[game_id].players
	for avatar_dbid, v in pairs(players) do
		self.mapPlayerInfo:erase(avatar_dbid)
	end

	self.mapGameInfo:erase(game_id)
	self:ClearWaittingQueue()
end

function DefensePvPMgr:EventChat(avatar_dbid, msg)
	local playerInfo = self.mapPlayerInfo[avatar_dbid]
	if not playerInfo then return end
	if playerInfo.faction == 0 or playerInfo.gameID == 0 then return end

	self:SendGroup_Message(playerInfo.gameID, playerInfo.faction, "ChatResp", 
						   {public_config.CHANNEL_ID_DEFECSE_PVP, 0, playerInfo.avatarName, 0, msg})
end

function DefensePvPMgr:EventState(avatar_dbid)
	local remain = 0
	if self:IsActive() then
		local now_date = os.date("*t")
		local the_time = os.time{year=2000, month=1, day=1, hour=now_date.hour, min=now_date.min, sec=now_date.sec}
		remain = TIME_STOP - the_time
	elseif gmActive == true then
		remain = -1
	end
	local point = self.mapPlayerPoint[avatar_dbid]
	if not point then point = 0 end
	return remain, point
end


----------------------------------------------------------------------------------------

--判断活动是否开放
function DefensePvPMgr:IsActive()
	local now_date = os.date("*t")
	local the_time = os.time{year=2000, month=1, day=1, hour=now_date.hour, min=now_date.min, sec=now_date.sec}
	return (the_time >= TIME_START and the_time < TIME_STOP)
end

--清除队列
function DefensePvPMgr:ClearWaittingQueue()
	local mapPlayerInfo = self.mapPlayerInfo
	local queWaitting 	= self.queWaitting
	self.queWaitting 	= {}
	for i, avatar_dbid in pairs(queWaitting) do
		if mapPlayerInfo:find(avatar_dbid) then
			table.insert(self.queWaitting, avatar_dbid)
		end
	end
end

function DefensePvPMgr:CheckStart()
	if self:IsActive() ~= true and gmActive ~= true then return end

	self:ClearWaittingQueue()

	if IGNORE_QUEUEING == 1 then
		if #self.queWaitting == LIMIT_PLAYER * 2 then
			self:StartGame()
		end
		return
	end

	if #self.queWaitting < 10 then return end

	local tick = mogo.getTickCount()
	if #self.queWaitting < 20 then
		if tick - TICK_QUE10_20 > WAIT_QUE10_20 then
			self:StartGame()
			TICK_QUE10_20 = tick
		end
	elseif #self.queWaitting < 40 then
		if tick - TICK_QUE20_40 > WAIT_QUE20_40 then
			self:StartGame()
			TICK_QUE20_40 = tick
		end
	else
		self:StartGame()
	end
end

--开启游戏
function DefensePvPMgr:StartGame()
	maxGameID = maxGameID + 1
	if maxGameID == 0 then maxGameID = 1 end
	self.mapGameInfo:insert(maxGameID, {gameID = maxGameID, state = 1, players = lua_map:new()})

	local avatar_dbid
	local queWaitting = {}
	for i = 1, LIMIT_PLAYER * 2 do
		avatar_dbid = self.queWaitting[1]
		table.remove(self.queWaitting, 1)
		queWaitting[i] = avatar_dbid
	end

	--针对queWaitting排序
	local sortQueue = queWaitting
	queWaitting = {}
	for i = 1, LIMIT_PLAYER * 2 do
		local theIndex = 0
		local theDbid = 0
		for j, dbid in pairs(sortQueue) do
			if theDbid == 0 then
				theDbid = dbid
				theIndex = j
			else
				if self.mapPlayerInfo[theDbid].avatarLevel < self.mapPlayerInfo[dbid].avatarLevel then
					theDbid = dbid
					theIndex = j
				elseif self.mapPlayerInfo[theDbid].avatarLevel == self.mapPlayerInfo[dbid].avatarLevel then
					if self.mapPlayerInfo[theDbid].avatarfight < self.mapPlayerInfo[dbid].avatarfight then
						theDbid = dbid
						theIndex = j
					end
				end
			end
		end
		table.remove(sortQueue, theIndex)
		table.insert(queWaitting, theDbid)
	end

	local maxLevel = 1
	local faction = 1
	for i = 1, LIMIT_PLAYER * 2 do
		if (i % 2) == 0 then
			faction = faction + 1
			if faction == 3 then faction = 1 end
		end
		avatar_dbid = queWaitting[i]
		self.mapPlayerInfo[avatar_dbid].faction = faction
		self.mapPlayerInfo[avatar_dbid].gameID 	= maxGameID
		local playerInfo = self.mapPlayerInfo[avatar_dbid]
		local sampleInfo =
		{
			--注意：次序与网络有关，不可随意变更
			[1] = playerInfo.avatarDbid,
			[2] = playerInfo.avatarName,
	        [3] = faction,
		}
		if playerInfo.avatarLevel > maxLevel then maxLevel = playerInfo.avatarLevel end
		self.mapGameInfo[maxGameID].players:insert(avatar_dbid, sampleInfo)
	end
	self.mapGameInfo[maxGameID].gameID 	= maxGameID
	self.mapGameInfo[maxGameID].state 	= 1

    local mm = globalBases['MapMgr']
    mm.CreateDefensePvPMapInstance(maxGameID, MAP_ID, self.mapGameInfo[maxGameID].players, maxLevel)
end

function DefensePvPMgr:CheckPoint()
	local now_date = os.date("*t")
	local now_day = now_date["day"]
	if pointDay ~= now_day then
    	self.mapPlayerPoint = lua_map:new()
		pointDay = now_day
	end
end

function DefensePvPMgr:CheckPublish()
	if self:IsActive() then
		if startPublish == 0 then
			global_data:ShowTextID(CHANNEL.WORLD, TEXT_PUBLISH_START, {LIMIT_LEVEL})
		end
		startPublish = 1
	else
		startPublish = 0
	end

	local PREPARE_START = TIME_START - 10 * 60
	local PREPARE_END 	= TIME_START - 5 * 60
	local now_date = os.date("*t")
	local the_time = os.time{year=2000, month=1, day=1, hour=now_date.hour, min=now_date.min, sec=now_date.sec}
	if the_time >= PREPARE_START and the_time < PREPARE_END then
		if preparePublish == 0 then
			local remain = math.ceil((TIME_START - the_time) / 60)
			global_data:ShowTextID(CHANNEL.WORLD, TEXT_PUBLISH_PREPARE, {remain, LIMIT_LEVEL})
		end
		preparePublish = 1
	else
		preparePublish = 0
	end
end

--计算奖励
function DefensePvPMgr:CalculateAward(game_id, playersPoint, winnerFaction)
	local gameInfo = self.mapGameInfo[game_id]
	if not gameInfo then return end

	local players = gameInfo.players
	if not players then return end

	for avatar_dbid, sampleInfo in pairs(players) do
		local playerInfo = self.mapPlayerInfo[avatar_dbid]
		if playerInfo and playerInfo.avatarMB then
			local avatar_mb 		= playerInfo.avatarMB
			local avatar_level 		= playerInfo.avatarLevel or 0
			local avatar_faction 	= sampleInfo[3]
			local avatar_point 		= playersPoint[avatar_dbid] or 0
	        local avatar_rank 		= 1
	        for avatar_dbid_n, point in pairs(playersPoint) do
	            if avatar_point < point then
	                avatar_rank = avatar_rank + 1
	            end
	        end

	        local win_flag = 2 --失败为2
	        if winnerFaction == avatar_faction then
	        	--胜利
	            win_flag = 1
				avatar_mb.EventDispatch("client", "DefensePvpAward", {1, avatar_rank})
			else
				--失败
				avatar_mb.EventDispatch("client", "DefensePvpAward", {0, avatar_rank})
	        end


            local exp = self:GetPersonalRewardExp(avatar_rank, avatar_level) + self:GetTeamRewardExp(win_flag, avatar_level)
            if exp ~= 0 then
				avatar_mb.EventDispatch("", "AddExp", {exp, reason_def.defensePvP})
            end

            local gold = self:GetPersonalRewardGold(avatar_rank, avatar_level) + self:GetTeamRewardGold(win_flag, avatar_level)
            if gold ~= 0 then
				avatar_mb.EventDispatch("", "AddGold", {gold, reason_def.defensePvP})
            end

            local awardItems = nil
            local items 	 = self:GetPersonalRewardItemTable(avatar_rank, avatar_level)
    		for itemId, itemNum in pairs(items) do
    			awardItems = awardItems or {}
    			if awardItems[itemId] then
    				awardItems[itemId] = awardItems[itemId] + itemNum
    			else
    				awardItems[itemId] = itemNum
    			end
    		end

            items = self:GetTeamRewardItemTable(win_flag, avatar_level)
    		for itemId, itemNum in pairs(items) do
    			awardItems = awardItems or {}
    			if awardItems[itemId] then
    				awardItems[itemId] = awardItems[itemId] + itemNum
    			else
    				awardItems[itemId] = itemNum
    			end
    		end

    		if awardItems then
				avatar_mb.EventDispatch("defensePvPSystem", "AwardItems", {awardItems})
    		end
		end
	end
end

----------------------------------------------------------------------------------------

--定时器处理
function DefensePvPMgr:ProcTimer(timerID, activeCount)
	self:CheckPoint()
	self:CheckPublish()
	self:CheckStart()
end


----------------------------------------------------------------------------------------

--通知显示消息ID
function DefensePvPMgr:Send_ShowTextID(channelID, textID)
	local mb = self:GetNowMailBox()
    if mb then
        mb.EventDispatch("", "ShowTextID", {channelID, textID})
    end
end

--通知显示消息
function DefensePvPMgr:Send_ShowText(channelID, text, ...)
    local mb = self:GetNowMailBox()
    if mb then
        mb.EventDispatch("", "ShowText", {channelID, textID})
    end
end

--通知（当前玩家）守护PvP申请成功
function DefensePvPMgr:Send_DefensePvPApplyResp(queue_count)
	local mb = self:GetNowMailBox()
    if mb then
        mb.EventDispatch("client", "DefensePvPApplyResp", {queue_count})
    end
end

--通知（当前玩家）守护PvP申请成功
function DefensePvPMgr:Send_DefensePvpEnterResp(players, elapse_time)
	local mb = self:GetNowMailBox()
    if mb then
    	local pvpInfo = {}
		for avatar_dbid, sampleInfo in pairs(players) do
			table.insert(pvpInfo, sampleInfo)
		end
        mb.EventDispatch("client", "DefensePvpEnterResp", {elapse_time, pvpInfo})
    end
end

--发送群组消息
function DefensePvPMgr:SendGroup_Message(game_id, faction_id, msg_name, params)
	local gameInfo = self.mapGameInfo[game_id]
	if not gameInfo then return end

	for avatar_dbid, sampleInfo in pairs(gameInfo.players) do
		if faction_id == 0 or sampleInfo[3] == faction_id then
			local playerInfo = self.mapPlayerInfo[avatar_dbid]
			if playerInfo and playerInfo.avatarMB then
				playerInfo.avatarMB.EventDispatch("client", msg_name, params)
			end
		end
	end


--[[
	local faction
	if faction_id == 0 then
		faction = 1
	end

	for i = 1, LIMIT_PLAYER do
		local group = gameInfo.faction[faction]
		if group then
			for avatar_dbid, _ in pairs(group) do
				local playerInfo = self.mapPlayerInfo[avatar_dbid]
				if playerInfo and playerInfo.avatarMB then
					playerInfo.avatarMB.EventDispatch("client", msg_name, params)
				end
			end
		end
	end

	if faction_id == 0 then
		faction = 2
		for i = 1, LIMIT_PLAYER do
			local group = gameInfo.faction[faction]
			if group then
				for avatar_dbid, _ in pairs(group) do
					local playerInfo = self.mapPlayerInfo[avatar_dbid]
					if playerInfo and playerInfo.avatarMB then
						playerInfo.avatarMB.EventDispatch("client", msg_name, params)
					end
				end
			end
		end
	end
--]]
end


----------------------------------------------------------------------------------------

g_DefensePvPMgr = DefensePvPMgr
return g_DefensePvPMgr




