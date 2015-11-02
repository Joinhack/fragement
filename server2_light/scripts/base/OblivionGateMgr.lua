--湮灭之门


require "lua_util"
require "public_config"
require "channel_config"
require "reason_def"
require "GlobalParams"


local log_game_debug 	= lua_util.log_game_debug
local log_game_warning 	= lua_util.log_game_warning
local log_game_info 	= lua_util.log_game_info
local log_game_error 	= lua_util.log_game_error
local _readXml          = lua_util._readXml
local globalbase_call	= lua_util.globalbase_call


local CLOSED_TICK       = public_config.OBLIVION_CLOSED_TIME
local CLOSED_COUNT      = 5              --保留多少个已关闭的副本（超出此数量的副本不在客户端显示）


--消息提示，对应ChineseData.xml表定义
local TEXT_NOT_EXIST    = 1001101        --该湮灭之门副本不存在！
local TEXT_IS_CLOSED 	= 1001102        --该湮灭之门副本已关闭！
local TEXT_MAIL_TITLE   = 1001103        --湮灭之门通关奖励
local TEXT_MAIL_TEXT    = 1001104        --恭喜，由于您或您的好友在湮灭之门里获得胜利，您将获得一份奖励，请查收！
local TEXT_MAIL_FROM    = 1001105        --湮灭之门系统
local TEXT_IS_FULL      = 1001106        --人数已满，请稍候再试


local maxGateID         = 0             --最大GateID


local reward_drop_data  = {}


OblivionGateMgr 	= {}
setmetatable(OblivionGateMgr, {__index = BaseEntity})


function OblivionGateMgr:InitRewardData()
    CLOSED_TICK      = g_GlobalParamsMgr:GetParams('oblivion_gate_close_time', public_config.OBLIVION_CLOSED_TIME)
    reward_drop_data = _readXml('/data/xml/Reward_OblivionDrop.xml', 'id_i')
    if reward_drop_data then
        for k, reward_drop in pairs(reward_drop_data) do
            if not reward_drop.drop1 then reward_drop.drop1 = {} end
            if not reward_drop.drop2 then reward_drop.drop2 = {} end
            if not reward_drop.drop3 then reward_drop.drop3 = {} end
            if not reward_drop.drop4 then reward_drop.drop4 = {} end

            reward_drop.drop = {[1] = {}, [2] = {}, [3] = {}, [4] = {}}
            reward_drop.drop[1].order = {}
            for k, _ in pairs(reward_drop.drop1) do
                table.insert(reward_drop.drop[1].order, k)
            end
            reward_drop.drop[1].data = reward_drop.drop1

            reward_drop.drop[2].order = {}
            for k, _ in pairs(reward_drop.drop2) do
                table.insert(reward_drop.drop[2].order, k)
            end
            reward_drop.drop[2].data = reward_drop.drop2

            reward_drop.drop[3].order = {}
            for k, _ in pairs(reward_drop.drop3) do
                table.insert(reward_drop.drop[3].order, k)
            end
            reward_drop.drop[3].data = reward_drop.drop3

            reward_drop.drop[4].order = {}
            for k, _ in pairs(reward_drop.drop4) do
                table.insert(reward_drop.drop[4].order, k)
            end
            reward_drop.drop[4].data = reward_drop.drop4
        end
    else
        reward_drop_data = {}
    end

    self:CheckData()
end

function OblivionGateMgr:CheckData()
    for i = 1, 100 do
        if not reward_drop_data[i] then
            reward_drop_data[i] = {id=i, drop1 = {}, drop2 = {}, drop3 = {}, drop4 = {}}
            reward_drop_data[i].drop = 
            {
                [1] = {data={}, order={}}, [2] = {data={}, order={}},
                [3] = {data={}, order={}}, [4] = {data={}, order={}},
            }
        end
    end
end

function OblivionGateMgr:__ctor__()
	log_game_debug("OblivionGateMgr:__ctor__", "")

    --湮灭之门的信息表
    self.mapGateInfo      = lua_map:new()

    --玩家ID->湮灭之门ID列表映射（包括传播的副本）
    self.mapIdInfo        = lua_map:new()

    --当前正在处理的MailBoxStr
    self.nowMailBoxStr    = ""

	local function RegisterGloballyCB(ret)
		if ret == 1 then
			--注册成功
            self:OnRegistered()
		else
			--注册失败
            log_game_error("OblivionGateMgr:RegisterGlobally Error", '')
		end
	end
	self:RegisterGlobally("OblivionGateMgr", RegisterGloballyCB)
end

function OblivionGateMgr:OnRegistered()
	log_game_debug("OblivionGateMgr:OnRegistered", "")
    globalbase_call('GameMgr', 'OnMgrLoaded', 'OblivionGateMgr')
end

function OblivionGateMgr:GetNowMailBox()
    if not self.nowMailBoxStr or self.nowMailBoxStr == "" then return nil end
    return mogo.UnpickleBaseMailbox(self.nowMailBoxStr)
end

function OblivionGateMgr:GetNowMailBoxStr()
    return self.nowMailBoxStr
end

function OblivionGateMgr:MgrEventDispatch(mbStr, mgr_func_name, mgr_func_param_table, callback_sys_name, callback_func_name, callback_func_param_table)
    log_game_debug("OblivionGateMgr:MgrEventDispatch", "Execute!")

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
        log_game_debug("OblivionGateMgr:MgrEventDispatch", "mgr_func_param_table too more params!")
        return
    end
    if not callback_func_name or callback_func_name == "" or not callback_func_param_table then return end

    log_game_debug("OblivionGateMgr:MgrEventDispatch", "Transmit!")

	local mb = self:GetNowMailBox()
    if not mb then
        log_game_debug("OblivionGateMgr:MgrEventDispatch", "Mailbox not found!")
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
        log_game_debug("OblivionGateMgr:MgrEventDispatch", "callback_func_param_table too more params!")
        return
    end

    log_game_debug("OblivionGateMgr:MgrEventDispatch", "Transmit Execute!")
    mb.EventDispatch(callback_sys_name, callback_func_name, new_arg)
end


----------------------------------------------------------------------------------------

function OblivionGateMgr:GetRemainTime(gate_info)
    local elapseTime = os.time() - gate_info.createTime
    if elapseTime < CLOSED_TICK then return CLOSED_TICK - elapseTime end

    --已超时
    if gate_info.state ~= 4 then gate_info.state = 3 end

    return 0
end

function OblivionGateMgr:IsOpeningState(gate_info)
    return (gate_info.state == 0 or gate_info.state == 1 or gate_info.state == 2)
end

function OblivionGateMgr:GetAwardDrop(owner_level, avatar_vocation)
    local reward_drop = reward_drop_data[owner_level].drop
    if not reward_drop then return nil end

    local the_reward = reward_drop[avatar_vocation]
    if not the_reward then return nil end

    for _, dropID in pairs(the_reward.order) do
        local probability = the_reward.data[dropID] / 10000
        if math.random() <= probability then
            local theAwards = {}
            local retAwards = {}
            local bFlag     = false
            g_drop_mgr:GetAwards(theAwards, dropID)
            for itemId, itemNum in pairs(theAwards) do
                if itemId > 0 and itemNum > 0 then
                    retAwards[itemId] = itemNum
                    bFlag = true
                end
            end
            if bFlag == true then
                return retAwards
            else
                return nil
            end
        end
    end

    return nil
end

function OblivionGateMgr:InsertID(owner_dbid, gate_id)
    local mapIdInfo = self.mapIdInfo
    if not mapIdInfo[owner_dbid] then
        mapIdInfo[owner_dbid] = {}
    end
    mapIdInfo[owner_dbid][gate_id] = gate_id
end

function OblivionGateMgr:UpdateID(avatar_dbid)
    local tabIdInfo = self.mapIdInfo[avatar_dbid]
    if not tabIdInfo then return end

    local mapGates = self.mapGateInfo
    for gateID, _ in pairs(tabIdInfo) do
        if not mapGates:find(gateID) then
            tabIdInfo[gateID] = nil
        end
    end

    while self:GetCloseGateCount(tabIdInfo) > CLOSED_COUNT do
        local eraseGateID = 0
        for gateID, _ in pairs(tabIdInfo) do
            local gateInfoB = mapGates:find(gateID)
            if self:IsOpeningState(gateInfoB) == false then
                if eraseGateID == 0 then
                    eraseGateID = gateID
                else
                    local gateInfoA = mapGates:find(gateID)
                    if gateInfoA.createTime > gateInfoB.createTime then
                        eraseGateID = gateID
                    end
                end
            end
        end
        if eraseGateID == 0 then
            break
        else
            tabIdInfo[eraseGateID] = nil
        end
    end
end

function OblivionGateMgr:GetCloseGateCount(gate_id_table)
    local count    = 0
    local mapGates = self.mapGateInfo
    for gateID, _ in pairs(gate_id_table) do
        local gateInfo = mapGates:find(gateID)
        if gateInfo then
            if self:IsOpeningState(gateInfo) == false then count = count + 1 end
        end
    end
    return count
end


----------------------------------------------------------------------------------------

function OblivionGateMgr:EventCreateGate(map_id, owner_dbid, owner_name, owner_vocation, owner_level)
    local mapGates     = self.mapGateInfo
    local mapGateIDs   = self.mapIdInfo:find(owner_dbid) or {}
    for gateID, _ in pairs(mapGateIDs) do
        local gateInfo = mapGates:find(gateID)
        if gateInfo.ownerDbid == owner_dbid and self:IsOpeningState(gateInfo) then return nil end
    end

    maxGateID      = maxGateID + 1
	local gateID   = maxGateID
	local gateInfo = 
	{
        mapID             = map_id,           --地图ID
        gateID            = gateID,           --湮灭之门ID（等同于分线ID）
		createTime        = os.time(),        --创建时间
		state             = 0,                --0创建中，1待开启，2进行中，3超时关闭，4已完成
		ownerDbid         = owner_dbid,       --持有者dbid
        ownerName         = owner_name,       --持有者名称
		ownerVocation     = owner_vocation,   --持有者职业
        ownerLevel        = owner_level,      --玩家等级（创建时）
		bossProgress      = 1,                --BOSS剩余血量百分比，浮点数[0, 1]
        attackerList      = lua_map:new(),    --攻击者列表
        killerDbid        = 0,                --击杀者Dbid
        hasSpread         = false,            --是否已传播
        playerCount       = 0,                --当前正在副本里的玩家数量
	}
	if self.mapGateInfo:insert(gateID, gateInfo) == false then return nil end
    self:InsertID(owner_dbid, gateID)

    local mm = globalBases['MapMgr']
    mm.CreateOblivionMapInstance(self:GetNowMailBoxStr(), gateID, map_id, owner_dbid, owner_name, owner_level)
end

function OblivionGateMgr:EventCreateGateComplete(gate_id, error_no)
    if error_no ~= 0 then
        self.mapGateInfo:erase(gate_id)
        self:UpdateID(avatar_dbid)
        log_game_debug("OblivionGateMgr:EventCreateGateComplete", "False!(error_no=%s)", error_no)
        return
    end

    local gateInfo = self.mapGateInfo:find(gate_id)
    gateInfo.state = 1

    local mb = self:GetNowMailBox()
    mb.EventDispatch("oblivionGateSystem", "EventCreateGateComplete", {gate_id})
end

function OblivionGateMgr:EventCloseGate(gate_id, killer_dbid, attackerData, monster_id)
    local gateInfo = self.mapGateInfo:find(gate_id)
    if not gateInfo then return end
    if gateInfo.killerDbid ~= 0 or gateInfo.state == 4 then return end

    --没有击杀者，当超时处理，不发放奖励
    if killer_dbid == 0 then
        gateInfo.state = 3
        return
    end

    gateInfo.killerDbid = killer_dbid
    gateInfo.state      = 4

    --发放掉落奖励
    if monster_id then
        local mailMgr = globalBases["MailMgr"]
        if mailMgr then
            for dbid, vocation in pairs(attackerData) do
                local dropItems     = {}
                local dropMoneys    = {}
                g_monster_mgr:getDrop(dropItems, dropMoneys, monster_id, vocation)
                if dropItems then
                    mailMgr.SendIdEx(TEXT_MAIL_TITLE, "", TEXT_MAIL_TEXT, TEXT_MAIL_FROM, os.time(), dropItems, {dbid}, {}, reason_def.oblivion)
                end

--              local theAwards = self:GetAwardDrop(gateInfo.ownerLevel, vocation)
--              if theAwards then
--                  mailMgr.SendIdEx(TEXT_MAIL_TITLE, "", TEXT_MAIL_TEXT, TEXT_MAIL_FROM, os.time(), theAwards, {dbid}, {}, reason_def.oblivion)
--              end
            end
        end
    end
end

function OblivionGateMgr:EventSpreadGate(gate_id, avatar_dbid)
    local gateInfo = self.mapGateInfo:find(gate_id)
    if not gateInfo then return end
    if gateInfo.ownerDbid ~= avatar_dbid then return end

    --判定是否已传播过
    if gateInfo.hasSpread == false then
        local mb = self:GetNowMailBox()
        mb.EventDispatch("oblivionGateSystem", "SpreadGate", {gate_id})
        gateInfo.hasSpread = true
    end
end

function OblivionGateMgr:EventReceiveSpreadGate(avatar_dbid, gate_id)
    self:InsertID(avatar_dbid, gate_id)
end

function OblivionGateMgr:EventFinishPlay(gate_id, avatar_dbid)
    local mb = self:GetNowMailBox()
    mb.EventDispatch("", "OnFinishOblivionGate", {})
end

function OblivionGateMgr:EventUpdatePlayerCount(gate_id, player_count)
    local gateInfo = self.mapGateInfo:find(gate_id)
    if not gateInfo or not player_count then return end
    gateInfo.playerCount = player_count
end

function OblivionGateMgr:EventUpdateBossProgress(gate_id, boss_progress)
    local gateInfo = self.mapGateInfo:find(gate_id)
    if not gateInfo or not boss_progress then return end

    gateInfo.bossProgress = boss_progress
end

--进入副本
function OblivionGateMgr:EventEnterGate(gate_id, avatar_dbid)
	local gateInfo	= self.mapGateInfo:find(gate_id)
	if not gateInfo then
		self:Send_ShowTextID(CHANNEL.DLG, TEXT_NOT_EXIST)
		return 1
	end

    --判断是否超时
    if self:GetRemainTime(gateInfo) == 0 then
        self:Send_ShowTextID(CHANNEL.DLG, TEXT_IS_CLOSED)
        return 3
    end

    --判断是满人
    if gateInfo.playerCount >= 4 then
        self:Send_ShowTextID(CHANNEL.DLG, TEXT_IS_FULL)
        return 5
    end

    --判定状态
    if gateInfo.state == 0 then
        --创建中，还没创建完毕
        return 2
    elseif gateInfo.state == 1 then
        --首次进入
        gateInfo.attackerList:insert(avatar_dbid, 1)
        local mm = globalBases['MapMgr']
        mm.SelectMapReq(self:GetNowMailBoxStr(), gateInfo.mapID, gate_id, gateInfo.ownerDbid, gateInfo.ownerName, {})
        gateInfo.state = 2
        gateInfo.playerCount = gateInfo.playerCount + 1
        return 0
    elseif gateInfo.state == 2 then
        --其它玩家进入或者所有者再次进入
        gateInfo.attackerList:insert(avatar_dbid, 1)
        local mm = globalBases['MapMgr']
        mm.SelectMapReq(self:GetNowMailBoxStr(), gateInfo.mapID, gate_id, gateInfo.ownerDbid, gateInfo.ownerName, {})
        gateInfo.playerCount = gateInfo.playerCount + 1
        return 0
    elseif gateInfo.state == 3 then
        --超时已关闭
        self:Send_ShowTextID(CHANNEL.DLG, TEXT_IS_CLOSED)
        return 3
    elseif gateInfo.state == 4 then
        --已完成
        self:Send_ShowTextID(CHANNEL.DLG, TEXT_IS_CLOSED)
        return 4
    end
end

--请求获取湮灭之门列表
function OblivionGateMgr:EventGetListReq(avatar_dbid)
    self:UpdateID(avatar_dbid)
    
    local mapGates     = self.mapGateInfo
    local mapGateIDs   = self.mapIdInfo:find(avatar_dbid) or {}
	local toClientList = {}
    local toServerList = {}
    for gateID, _ in pairs(mapGateIDs) do
        local gateInfo = mapGates:find(gateID)
        if gateInfo then
            local remainTime = self:GetRemainTime(gateInfo)

            local state
            if gateInfo.state == 0 or gateInfo.state == 1 or gateInfo.state == 2 then
                state = 0
            elseif gateInfo.state == 3 then
                state = 2
            elseif gateInfo.state == 4 then
                state = 1
            end

            local has_enter = 0
            if gateInfo.attackerList:find(avatar_dbid) then has_enter = 1 end

            toClientList[gateID] = 
            {
                remainTime,
                state,
                gateInfo.ownerName,
                gateInfo.ownerVocation,
                gateInfo.ownerLevel,
                public_config.OBLIVION_MAP_TO_GATE[gateInfo.mapID],
                has_enter,
                gateInfo.bossProgress,
                gateInfo.killerDbid,
            }

            table.insert(toServerList, gateID)
        end
    end

    local mb = self:GetNowMailBox()
    mb.EventDispatch("oblivionGateSystem", "EventGetListComplete", {toServerList})

    return toClientList
end

--查询湮灭之门状态
function OblivionGateMgr:EventQueryStateReq(avatar_dbid, map_gates)
    local mapGates     = self.mapGateInfo
    local toClientList = {}
    local toServerList = {}
    local mapGateIDs   = self.mapIdInfo:find(avatar_dbid) or {}
    for gateID, _ in pairs(mapGateIDs) do
        local gateInfo = mapGates:find(gateID)
        if gateInfo then
            --判断是否超时，是否开启状态
            if self:GetRemainTime(gateInfo) > 0 then
                if self:IsOpeningState(gateInfo) then
                    return 1
                end
            end
        end
    end
    return 0
end

----------------------------------------------------------------------------------------

--通知显示消息ID
function OblivionGateMgr:Send_ShowTextID(channelID, textID)
	local mb = self:GetNowMailBox()
    if mb then
        mb.EventDispatch("", "ShowTextID", {channelID, textID})
    end
end

--通知显示消息
function OblivionGateMgr:Send_ShowText(channelID, text, ...)
    local mb = self:GetNowMailBox()
    if mb then
        mb.EventDispatch("", "ShowText", {channelID, textID})
    end
end


----------------------------------------------------------------------------------------

g_OblivionGateMgr = OblivionGateMgr
return g_OblivionGateMgr























