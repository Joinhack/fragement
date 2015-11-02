
require "public_config"
require "lua_util"
require "mission_data"
require "mission_config"
require "GlobalParams"
require "vip_privilege"
require "reason_def"
require "action_config"
require "PriceList"
require "state_config"
require "error_code"
require "channel_config"
require "map_data"
require "Item_data"
require "global_data"

local log_game_debug = lua_util.log_game_debug
local log_game_error = lua_util.log_game_error
local log_game_warning = lua_util.log_game_warning
local log_game_info = lua_util.log_game_info
local globalbase_call = lua_util.globalbase_call
local get_table_real_count = lua_util.get_table_real_count
local choose_1 = lua_util.choose_1
local split_str = lua_util.split_str

-- 关卡系统

MissionSystem = {}
MissionSystem.__index = MissionSystem

--function MissionSystem:new( owner )
--
--    local newObj = {}
--    newObj.ptr = {}
--
--    setmetatable(newObj, {__index = MissionSystem})
--    setmetatable(newObj.ptr, {__mode = "kv"})
--
--    newObj.ptr.theOwner = owner
--
--    local msgMapping = {
--
--        --客户端到base的请求
--        [mission_config.MSG_ENTER_MISSION]                 = MissionSystem.EnterMission,                --客户请求进入关卡
--        [mission_config.MSG_START_MISSION]                 = MissionSystem.StartMission,                --客户端请求开始关卡
--        [mission_config.MSG_RESET_MISSION_TIMES]           = MissionSystem.ResetMissionTimes,           --客户端请求重置关卡挑战次数
--        [mission_config.MSG_EXIT_MISSION]                  = MissionSystem.ExitMission,                 --胜利前退出关卡副本
--        [mission_config.MSG_GET_STARS_MISSION]             = MissionSystem.GetStarsMission,             --客户端获取所有副本的星数
--        [mission_config.MSG_GET_MISSION_TIMES]             = MissionSystem.GetMissionTimes,             --客户端获取已挑战次数
--        [mission_config.MSG_GET_FINISHED_MISSIONS]         = MissionSystem.GetFinishedMissions,         --客户端获取已完成的关卡数据
--        [mission_config.MSG_SPAWNPOINT_START]              = MissionSystem.SpawnPointStart,             --客户端通知服务器指定刷怪点开始刷怪
--        [mission_config.MSG_SPWANPOINT_STOP]               = MissionSystem.SpawnPointStop,              --客户端通知服务器指定刷怪点停止刷怪
--        [mission_config.MSG_GET_MISSION_REWARDS]           = MissionSystem.GetMissionRewards,           --客户端获取副本的奖励池数据
--        [mission_config.MSG_CLIENT_MISSION_INFO]           = MissionSystem.ClientMissionInfo,           --客户端设置关卡状态
--        [mission_config.MSG_SWEEP_MISSION]                 = MissionSystem.SweepMission,                --扫荡制定难度的关卡
--        [mission_config.MSG_QUIT_MISSION]                  = MissionSystem.QuitMission,                 --胜利后退出管卡副本
--        [mission_config.MSG_ADD_FRIEND_DEGREE]             = MissionSystem.AddFriendDegree,             --副本胜利后加好友度
--        [mission_config.MSG_UPLOAD_COMBO]                  = MissionSystem.UploadCombo,                 --客户端上传连击数
--        [mission_config.MSG_GET_MISSION_TRESURE_REWARDS]   = MissionSystem.GetMissionTreasureRewards,   --客户端获取已经拿到的关卡副本奖励
--        [mission_config.MSG_REVIVE]                        = MissionSystem.Revive,                      --复活
--        [mission_config.MSG_GET_REVIVE_TIMES]              = MissionSystem.GetReviveTimes,              --获取已复活次数
--
--        --cell到base的请求
--        [mission_config.MSG_REVIVE_SUCCESS]        = MissionSystem.ReviveSuccess,
--        [mission_config.MSG_ADD_FRIEND_DEGREE_C2B] = MissionSystem.AddFriendDegreeB2C,
--        [mission_config.MSG_EXIT_MAP]              = MissionSystem.ExitMap,
----        [mission_config.MSG_ADD_MISSION_TIMES]     = MissionSystem.AddMissionTimes,
--        [mission_config.MSG_ADD_FINISHED_MISSIONS] = MissionSystem.AddFinishedMissions,
--        [mission_config.MSG_ADD_REWARD_ITEMS]      = MissionSystem.AddRewardItems,
--    }
--    newObj.msgMapping = msgMapping
--    newObj.Combos     = {}               --初始化连击数
--
--    return newObj
--end

MissionSystem.msgMapping = {

        --客户端到base的请求
        [action_config.MSG_ENTER_MISSION]                 = "EnterMission",                --客户请求进入关卡
        [action_config.MSG_START_MISSION]                 = "StartMission",                --客户端请求开始关卡
        [action_config.MSG_RESET_MISSION_TIMES]           = "ResetMissionTimes",           --客户端请求重置关卡挑战次数
        [action_config.MSG_EXIT_MISSION]                  = "ExitMission",                 --胜利前退出关卡副本
        [action_config.MSG_GET_STARS_MISSION]             = "GetStarsMission",             --客户端获取所有副本的星数
        [action_config.MSG_GET_MISSION_TIMES]             = "GetMissionTimes",             --客户端获取已挑战次数
        [action_config.MSG_GET_FINISHED_MISSIONS]         = "GetFinishedMissions",         --客户端获取已完成的关卡数据
        [action_config.MSG_SPAWNPOINT_START]              = "SpawnPointStart",             --客户端通知服务器指定刷怪点开始刷怪
        [action_config.MSG_SPWANPOINT_STOP]               = "SpawnPointStop",              --客户端通知服务器指定刷怪点停止刷怪
        [action_config.MSG_GET_MISSION_REWARDS]           = "GetMissionRewards",           --客户端获取副本的奖励池数据
        [action_config.MSG_CLIENT_MISSION_INFO]           = "ClientMissionInfo",           --客户端设置关卡状态
        [action_config.MSG_SWEEP_MISSION]                 = "SweepMission",                --扫荡制定难度的关卡
        [action_config.MSG_QUIT_MISSION]                  = "QuitMission",                 --胜利后退出管卡副本
        [action_config.MSG_ADD_FRIEND_DEGREE]             = "AddFriendDegree",             --副本胜利后加好友度
        [action_config.MSG_UPLOAD_COMBO]                  = "UploadCombo",                 --客户端上传连击数
        [action_config.MSG_GET_MISSION_TREASURE_REWARDS]  = "GetMissionTreasureRewards", --客户端获取已经拿到的关卡副本奖励
        [action_config.MSG_REVIVE]                        = "Revive",                        --复活
        [action_config.MSG_GET_REVIVE_TIMES]              = "GetReviveTimes",              --获取已复活次数
--        [action_config.MSG_RESET_MISSION_TIMES]           = "ResetMissionTimes",            --重置关卡每天次数
        [action_config.MSG_GET_MISSION_SWEEP_LIST]        = "GetMissionSweepList",         --获取副本的怪物和奖励
        [action_config.MSG_GET_RESET_TIMES]               = "GetResetTimes",                --客户端获取关卡总的已重置次数
--        [action_config.MSG_GET_RESET_TIMES_BY_MISSION]    = "GetResetTimesByMission",       --客户端获取指定关卡难度的已重置次数
        [action_config.MSG_GET_MISSION_DROPS]             = "GetMissionDrops",             --客户端获取指定关卡可能出现掉落道具id集合
        [action_config.MSG_GO_TO_INIT_MAP]                = "GoToInitMap",                  --回到王城
        [action_config.MSG_GET_SWEEP_TIMES]               = "GetSweepTimes",                --获取可扫荡次数
        [action_config.MSG_GET_MISSION_TREASURE]          = "GetMissionTreasure",          --获取指定id的关卡副本宝箱奖励
        [action_config.MSG_CREATE_CLIENT_DROP]            = "CreateClientDrop",            --客户端拾取掉落以后通知服务器加钱
        [action_config.MSG_UPLOAD_COMBO_AND_BOTTLE]       = "UploadComboAndBottle",        --单机副本结束时，客户端上传连击数和使用药瓶数量
        [action_config.MSG_GET_MISSION_RECORD]            = "GetMissionRecord",             --获取关卡的最优记录
        [action_config.MSG_GET_ACQUIRED_MISSION_BOSS_TREASURE]     = "GetAcquiredMissionBossTreasure",      --获取玩家已经拿到的boss宝箱奖励
        [action_config.MSG_GET_MISSION_BOSS_TREASURE]     = "GetMissionBossTreasure",
        [action_config.MSG_MWSY_MISSION_GET_INFO]         = "GetMwsyInfo",             --获取迷雾深渊的相关信息
        [action_config.MSG_MWSY_MISSION_ENTER]            = "EnterMwsy",               --进入迷雾深渊副本

    }

MissionSystem.msgC2BMapping = {
        --cell到base的请求
        [action_config.MSG_REVIVE_SUCCESS]        = "ReviveSuccess",
        [action_config.MSG_ADD_FRIEND_DEGREE_C2B] = "AddFriendDegreeB2C",
        [action_config.MSG_EXIT_MAP]              = "ExitMap",
--        [mission_config.MSG_ADD_MISSION_TIMES]     = MissionSystem.AddMissionTimes,
        [action_config.MSG_ADD_FINISHED_MISSIONS] = "AddFinishedMissions",
        [action_config.MSG_ADD_REWARD_ITEMS]      = "AddRewardItems",
    }

function MissionSystem:getFuncByMsgId(msg_id)
    return self.msgMapping[msg_id]
end

function MissionSystem:getC2BFuncByMsgId(msg_id)
    return self.msgC2BMapping[msg_id]
end

--function MissionSystem:tostring()
--    local l = {}
--    for k, v in pairs(self) do
--        l[#l + 1] = v
--    end
--
--    return "{" .. table.concat(l, ", ") .. "}"
--end

---- 关卡完成， 给玩家增加奖励
--function MissionSystem:Complete( missionID )
--    local sp = globalBases['SpaceLoader_' .. avatar.sceneId .. "_" .. avatar.imap_id]
--end

function MissionSystem:SubEnergy(avatar, MissionId, difficulty)

end

function MissionSystem:GmAddFinishedMissions(avatar, MissionId, difficulty, Star)

    if avatar.MissionStars[MissionId] then
        avatar.MissionStars[MissionId][difficulty] = Star
    else
        avatar.MissionStars[MissionId] = {}
        avatar.MissionStars[MissionId][difficulty] = Star
    end

--    local missionInfo = avatar.FinishedMissions[MissionId]
--    if missionInfo then
--        for _, diff in pairs(avatar.FinishedMissions[MissionId]) do
--            if diff == difficulty then
--                log_game_debug("MissionSystem:GmAddFinishedMissions", "dbid=%q;name=%s;MissionId=%d;difficulty=%d;Star=%d;MissionStars=%s;FinishedMissions=%s",
--                                                                       avatar.dbid, avatar.name, MissionId, difficulty, Star, mogo.cPickle(avatar.MissionStars), mogo.cPickle(avatar.FinishedMissions))
--
--                return
--            end
--        end
--        table.insert(avatar.FinishedMissions[MissionId], difficulty)
--    else
--        avatar.FinishedMissions[MissionId] = {[1]=difficulty}
--    end
--
--    log_game_debug("MissionSystem:GmAddFinishedMissions", "dbid=%q;name=%s;MissionId=%d;difficulty=%d;Star=%d;MissionStars=%s;FinishedMissions=%s",
--                                                           avatar.dbid, avatar.name, MissionId, difficulty, Star, mogo.cPickle(avatar.MissionStars), mogo.cPickle(avatar.FinishedMissions))

end

function MissionSystem:GetMissionTreasure(avatar, treasureId)
    log_game_debug("MissionSystem:GetMissionTreasure", "dbid=%q;name=%s;GetMissionTreasure=%d",
                                                        avatar.dbid, avatar.name, treasureId)
    local MissionReward = g_mission_mgr:getMissionReward()

    if not MissionReward or not MissionReward[treasureId] then
        if avatar:hasClient() then
            avatar.client.MissionResp(action_config.MSG_GET_MISSION_TREASURE, {1})
        end
        return 0
    end

    if avatar.MissionTreasureRewards[treasureId] then
        if avatar:hasClient() then
            avatar.client.MissionResp(action_config.MSG_GET_MISSION_TREASURE, {2})
        end
        return 0
    end

    local v = MissionReward[treasureId]
    --没记录，表示奖励没有拿到
    local condition = v['condition']
    if condition then
        local flag = true
        for _, c in pairs(condition) do

            local MissionId = c[1]
            local Difficulty = c[2]
            local MinStar = c[3]

            if not avatar.MissionStars[MissionId] then
                flag = false
            elseif not avatar.MissionStars[MissionId][Difficulty] then
                flag = false
            elseif avatar.MissionStars[MissionId][Difficulty] < MinStar then
                flag = false
            end
        end

        if flag then
            --玩家已经达到了该宝箱奖励的条件，发奖
            avatar.MissionTreasureRewards[treasureId] = 1
--                avatar.MissionTreasureRewards = mogo.deepcopy1(avatar.MissionTreasureRewards)

            local Rewards = v['rewards']
            if Rewards then
                local attach = {}
                for itemId, count in pairs(Rewards) do
                    if itemId == public_config.EXP_ID then
                        avatar:AddExp(count, reason_def.mission_treasure)
                    elseif itemId == public_config.GOLD_ID then
                        avatar:AddGold(count, reason_def.mission_treasure)
                    elseif itemId == public_config.DIAMOND_ID then
                        avatar:AddDiamond(count, reason_def.mission_treasure)
                    else
                        if avatar.inventorySystem:IsSpaceEnough(itemId, count) then
                            --背包位置足够
                            avatar.inventorySystem:AddItems(itemId, count)
                        else
                            attach[itemId] = count
                        --[[
                        lua_util.globalbase_call('MailMgr', 'SendEx', "关卡宝箱奖励",                  --title
                                                                      "关卡宝箱奖励",                  --to
                                                                      "关卡宝箱奖励",                  --text
                                                                      "关卡宝箱奖励",                  --from
                                                                       os.time(),                --time
                                                                       {[itemId]=count,},            --道具
                                                                       {[1]=avatar.dbid,}, --收件者的dbid列表
                                                                       reason_def.mission_treasure
                                                )
                        ]]
                        end
                    end
                end
                if next(attach) then
                    log_game_debug("MissionSystem:GetMissionTreasure send mail", "dbid=%q;name=%s;attach=%s", avatar.dbid, avatar.name, mogo.cPickle(attach))
                    globalbase_call('MailMgr', 'SendIdEx', g_text_id.MISSION_TREASURE_MAIL_REWARD_TITLE,  --title
                                                                  avatar.name,                              --to
                                                                  g_text_id.MISSION_TREASURE_MAIL_REWARD_TEXT, --text
                                                                  g_text_id.MISSION_MAIL_REWARD_FROM, --from
                                                                  os.time(),                              --time
                                                                  attach,                                 --道具
                                                                  {[1]=avatar.dbid,}, --收件者的dbid列表
                                                                  {},
                                                                  reason_def.mission_treasure
                                                                )
                end
            end
            if avatar:hasClient() then
                avatar.client.MissionResp(action_config.MSG_GET_MISSION_TREASURE, {0})
            end
            return 0
        else
            if avatar:hasClient() then
                avatar.client.MissionResp(action_config.MSG_GET_MISSION_TREASURE, {3})
            end
            return 0
        end

    end
end

function MissionSystem:CreateClientDrop(avatar, DropId, arg, argStr)
--    log_game_debug("MissionSystem:CreateClientDrop", "dbid=%q;name=%s;DropId=%d;argStr=%s",  avatar.dbid, avatar.name, DropId, argStr)

    if avatar.SpaceLoaderMb then
        local xy = lua_util.split_str(argStr, "_", tonumber)
        avatar.SpaceLoaderMb.CreateClientDrop(avatar.base_mbstr, DropId, xy[1], xy[2])
    else
        log_game_error("MissionSystem:CreateClientDrop", "dbid=%q;name=%s;DropId=%d;argStr=%s", avatar.dbid, avatar.name, DropId, argStr)
    end

    return 0
end

--生成关卡的翻牌数据
function MissionSystem:GenMissionRandomReward(mission, difficulty, vocation)
--    --获取能获得的奖励个数
--    local times = g_mission_mgr:getMissionRandomRewardTimes(star)
--    if times <= 0 then
--        return {}
--    else
--        if times == 1 then
--            return {g_mission_mgr:getMissionRandomRewardItem1(mission, difficulty),}
--        elseif times == 2 then
--            local item1 = g_mission_mgr:getMissionRandomRewardItem1(mission, difficulty)
--            local item2 = g_mission_mgr:getMissionRandomRewardItem2(mission, difficulty)
--
--            return {item1, item2,}
--        else
--
--            local item1 = g_mission_mgr:getMissionRandomRewardItem1(mission, difficulty)
--            local item2 = g_mission_mgr:getMissionRandomRewardItem2(mission, difficulty)
--
--            local item = g_mission_mgr:getMissionRandomRewardItem(mission, difficulty, vocation)
--
--            return {item1, item2, item,}
--        end
--    end
    return g_mission_mgr:getMissionRandomReward(mission, difficulty, vocation)
end

function MissionSystem:FinishMission(avatar, missionId, difficulty)

    log_game_debug("MissionSystem:FinishMission", "dbid=%q;name=%s;missionId=%d;difficulty=%d", avatar.dbid, avatar.name, missionId, difficulty)

    if avatar.MissionStars[missionId] then
        if not avatar.MissionStars[missionId][difficulty] or avatar.MissionStars[missionId][difficulty] < mission_config.MISSION_VALUATION_S then
            avatar.MissionStars[missionId][difficulty] = mission_config.MISSION_VALUATION_S
        end
    else
        avatar.MissionStars[missionId] = {}
        avatar.MissionStars[missionId][difficulty] = mission_config.MISSION_VALUATION_S
    end

    --计算总的s数
    avatar.MissionSSum = self:GetMissionSSum(avatar)

    --        --计算宝箱获取
    --        self:MissionTreasureReward(avatar)

    --关卡胜利后累加挑战次数和精力值
    self:AddMissionTimes(avatar, missionId, difficulty)

    --任务触发器
    avatar.taskSystem:UpdateTaskProgress(public_config.TASK_ASK_TYPE_MISSION_COMPLITE, {missionId = missionId, difficulty = difficulty})

    --剧情副本胜利后触发湮灭之门
    avatar.oblivionGateSystem:TriggerGate(1)

    --完成副本调用
    avatar:OnFinishFB(missionId, difficulty)

    avatar.LastFinishedMissionTime = os.time()


    if avatar:hasClient() then
        avatar.client.MissionResp(action_config.MSG_GET_FINISHED_MISSIONS, avatar.MissionStars)
    end
end

function MissionSystem:UploadComboAndBottle(avatar, Combo, Bottle, ReviveTimes, ClientResult)
    if mogo.stest(avatar.state, state_config.STATE_CONSOLE) == 0 then
        --玩家不再单机副本状态
        log_game_error("MissionSystem:UploadComboAndBottle", "dbid=%d;name=%s;Combo=%d;Bottle=%d;ReviveTimes=%d;ClientResult=%s", avatar.dbid, avatar.name, Combo, Bottle, ReviveTimes, ClientResult)
        return 0
    else

        local Result = avatar.tmp_data[public_config.TMP_DATA_KEY_CONSOLE_MISSION_REWARD] or {}
        local StartTime = avatar.tmp_data[public_config.TMP_DATA_KEY_CONSOLE_MISSION_STARTTIME] or 0
        local missionId = avatar.tmp_data[public_config.TMP_DATA_KEY_CONSOLE_MISSION_ID] or 0
        local difficulty = avatar.tmp_data[public_config.TMP_DATA_KEY_CONSOLE_MISSION_DIFFICULT] or 0
        local MissionCfg = g_mission_mgr:getCfgById(tostring(missionId) .. "_" .. tostring(difficulty))
        local now = os.time()

        if StartTime <= 0 or missionId == 0 or difficulty == 0 or not MissionCfg then
            log_game_error("MissionSystem:UploadComboAndBottle", "dbid=%q;name=%s", avatar.dbid, avatar.name)
        else
            if MissionCfg['reviveTimes'] < ReviveTimes then
                log_game_error("MissionSystem:UploadComboAndBottle ReviveTimes", "dbid=%q;name=%s;ReviveTimes=%d;MissionCfg['reviveTimes']=%d;ClientResult=%s;Result=%s", avatar.dbid, avatar.name, ReviveTimes, MissionCfg['reviveTimes'], ClientResult, mogo.cPickle(Result))
                return 0
            end

            if Bottle > 0 then
                --如果客户端使用了血瓶，则判断该副本是否允许使用血瓶
                if not MissionCfg['can_use_hpBottle'] or MissionCfg['can_use_hpBottle'] == 0 then
                    log_game_error("MissionSystem:UploadComboAndBottle Bottle 1", "dbid=%q;name=%s;Bottle=%d;ClientResult=%s;Result=%s", avatar.dbid, avatar.name, Bottle, ClientResult, mogo.cPickle(Result))
                    return 0
                end

                if Bottle > avatar.hpCount then
                    log_game_error("MissionSystem:UploadComboAndBottle Bottle 2", "dbid=%q;name=%s;Bottle=%d;hpCount=%d;ClientResult=%s;Result=%s", avatar.dbid, avatar.name, Bottle, avatar.hpCount, ClientResult, mogo.cPickle(Result))
                    return 0
                end
            end

            local ClientResultTable = mogo.cUnpickle(ClientResult)
            if not ClientResultTable then
                log_game_error("MissionSystem:UploadComboAndBottle ClientResultTable", "dbid=%q;name=%s;Bottle=%d;hpCount=%d;ClientResult=%s;Result=%s", avatar.dbid, avatar.name, Bottle, avatar.hpCount, ClientResult, mogo.cPickle(Result))
                return 0
            end

            if ClientResultTable[1] then
                for k, v in pairs(ClientResultTable[1]) do
                    if not Result[1][k] or Result[1][k] < v then
                        log_game_error("MissionSystem:UploadComboAndBottle ClientResultError 1", "dbid=%q;name=%s;ClientResult=%s;Result=%s", avatar.dbid, avatar.name, ClientResult, mogo.cPickle(Result))
                        return 0
                    end
                end
            end

            if ClientResultTable[2] and ClientResultTable[2] > Result[2] then
                log_game_error("MissionSystem:UploadComboAndBottle ClientResultError 2", "dbid=%q;name=%s;ClientResult=%s;Result=%s", avatar.dbid, avatar.name, ClientResult, mogo.cPickle(Result))
                return 0
            end

            if ClientResultTable[3] and ClientResultTable[3] > Result[3] then
                log_game_error("MissionSystem:UploadComboAndBottle ClientResultError 3", "dbid=%q;name=%s;ClientResult=%s;Result=%s", avatar.dbid, avatar.name, ClientResult, mogo.cPickle(Result))
                return 0
            end

            log_game_debug("MissionSystem:UploadComboAndBottle", "dbid=%d;name=%s;Combo=%d;Bottle=%d;ReviveTimes=%d;ClientResult=%s", avatar.dbid, avatar.name, Combo, Bottle, ReviveTimes, ClientResult)

            local UseTime = now - StartTime
            if UseTime < (MissionCfg['shortestTime'] or 0) then
                log_game_error("MissionSystem:UploadComboAndBottle UseTime", "dbid=%q;name=%s;UseTime=%d", avatar.dbid, avatar.name, UseTime)
            else

                local attach = {}
                for id, count in pairs(ClientResultTable[1]) do
                    if avatar.inventorySystem:IsSpaceEnough(id, count) then
                        --背包位置足够
                        avatar:AddItem(id, count, reason_def.fuben_drop)
                    else
                        attach[id] = count
                    end
                end
                --    if lua_util.get_table_real_count(attach) > 0 then
                if next(attach) then

                    log_game_debug("MissionSystem:UploadComboAndBottle send mail", "dbid=%q;name=%s;attach=%s", avatar.dbid, avatar.name, mogo.cPickle(attach))

                    globalbase_call('MailMgr', 'SendIdEx', g_text_id.MISSION_MAIL_REWARD_TITLE,  --title
                        avatar.name,                            --to
                        g_text_id.MISSION_MAIL_REWARD_TEXT,     --text
                        g_text_id.MISSION_MAIL_REWARD_FROM,     --from
                        now,                              --time
                        attach,                                 --道具
                        {[1]=avatar.dbid,}, --收件者的dbid列表
                        {},
                        reason_def.mission_treasure
                    )
                end

                --金币奖励
                if ClientResultTable[2] and ClientResultTable[2] > 0 then
                    avatar:AddGold(ClientResultTable[2], reason_def.mission)
                end

                --经验奖励
                if ClientResultTable[3] and ClientResultTable[3] > 0 then
                    avatar:AddExp(ClientResultTable[3], reason_def.mission)
                end

                --把客户端的复活次数设成avatar的复活次数
                avatar.ReviveTimes = ReviveTimes

                if avatar.ReviveTimes >= 1 then
                    --如果复活次数多余1，则扣除道具
                    avatar:DelItem(g_GlobalParamsMgr:GetParams('revive_item', 10004), avatar.ReviveTimes, reason_def.revive)
                end

                local _Point = 0
                local _Star = 0
                _Star, _Point = self:GetMissionStar(avatar, missionId, difficulty, UseTime, Bottle, Combo)

                --生成翻牌数据
                --每次生成5张牌，然后根据评价的次数决定获得几张
                local RandomReward = self:GenMissionRandomReward(missionId, difficulty, avatar.vocation)
                local times = g_mission_mgr:getMissionRandomRewardTimes(_Star)
                local playerRandomReward = {}
                for i=1, times do
                    table.insert(playerRandomReward, RandomReward[i])
                end

                avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_RANDOM_REWARD] = playerRandomReward

--                for _, v in pairs(playerRandomReward) do
--                    for itemId, _ in pairs(v) do
--                        local itemCfg = g_itemdata_mgr:GetItem(public_config.ITEM_TYPE_CFG_TBL, itemId)
--                        if itemCfg and itemCfg['quality'] then
--                            if itemCfg['quality'] == public_config.ITEM_QUALITY_PURPLE then
--                                global_data:ShowTextID(CHANNEL.WORLD, mission_config.RANDOM_REWARD_MSG_PURPLE, {avatar.name, ['item_id'] = itemId})  --给所有人发消息改为从 global_data
--                            elseif itemCfg['quality'] == public_config.ITEM_QUALITY_ORANGE then
--                                global_data:ShowTextID(CHANNEL.WORLD, mission_config.RANDOM_REWARD_MSG_ORANGE, {avatar.name, ['item_id'] = itemId})  --给所有人发消息改为从 global_data
--                            end
--                        end
--                    end
--                end

                if avatar:hasClient() then
                    local result = ClientResultTable
                    table.insert(result, UseTime)
                    table.insert(result, _Star)
                    table.insert(result, _Point)
                    table.insert(result, RandomReward)
                    log_game_debug("MissionSystem:UploadComboAndBottle to client", "missionId=%d;difficulty=%d;dbid=%q;name=%s;level=%d;UseTime=%d;_Star=%d;_Point=%d;fightForce=%d;Combo=%d;", missionId, difficulty, avatar.dbid, avatar.name, avatar.level, UseTime, _Star, _Point, avatar.fightForce, Combo)

                    log_game_info("MissionSystem:Statistics", " %d %d %q %s %d %d %d %d", missionId, difficulty, avatar.dbid, avatar.name, UseTime, _Point, avatar.fightForce, Combo)

                    avatar.client.MissionResp(action_config.MSG_UPLOAD_COMBO_AND_BOTTLE, result)
                end

--                --玩家的cell部分现身
--                avatar.cell.set_visiable()

                globalbase_call("MissionMgr", "UpdateMissionRecord", missionId, difficulty, avatar.dbid, avatar.name, avatar.vocation, UseTime, Combo, _Point)

                if avatar.MissionStars[missionId] then
                    if not avatar.MissionStars[missionId][difficulty] or avatar.MissionStars[missionId][difficulty] < _Star then
                        avatar.MissionStars[missionId][difficulty] = _Star
                    end
                else
                    avatar.MissionStars[missionId] = {}
                    avatar.MissionStars[missionId][difficulty] = _Star
                end

                --计算总的s数
                avatar.MissionSSum = self:GetMissionSSum(avatar)

                --        --计算宝箱获取
                --        self:MissionTreasureReward(avatar)

                --关卡胜利后累加挑战次数和精力值
                self:AddMissionTimes(avatar, missionId, difficulty)

                --任务触发器
                avatar.taskSystem:UpdateTaskProgress(public_config.TASK_ASK_TYPE_MISSION_COMPLITE, {missionId = missionId, difficulty = difficulty})

                --剧情副本胜利后触发湮灭之门
                avatar.oblivionGateSystem:TriggerGate(1)

                --完成副本调用
                avatar:OnFinishFB(missionId, difficulty)

                avatar.LastFinishedMissionTime = now

                --离开副本时扣除体力
                local tbl = {}
                table.insert(tbl, tostring(missionId))
                table.insert(tbl, tostring(difficulty))
                local MissionCfg = g_mission_mgr:getCfgById(table.concat(tbl, '_'))
                if MissionCfg and MissionCfg['energy'] then
                    avatar:DeductEnergy(MissionCfg['energy'])
                    log_game_debug("MissionSystem:UploadComboAndBottle DeductEnergy", "dbid=%q;name=%s;missionId=%d;difficulty=%d;MissionCfg['energy']=%d;energy=%d",
                        avatar.dbid, avatar.name, missionId, difficulty,
                        MissionCfg['energy'], avatar.energy)
                end

                avatar.tmp_data[public_config.TMP_DATA_KEY_CONSOLE_MISSION_REWARD] = nil
                avatar.tmp_data[public_config.TMP_DATA_KEY_CONSOLE_MISSION_STARTTIME] = nil
                avatar.tmp_data[public_config.TMP_DATA_KEY_CONSOLE_MISSION_ID] = nil
                avatar.tmp_data[public_config.TMP_DATA_KEY_CONSOLE_MISSION_DIFFICULT] = nil

                return 0

            end
        end

    end
end

--GZ2814(王强) 12-17 11:47:02
--扣体力按50000
--算评分按10106
--发奖励按50000

function MissionSystem:UploadCombo(avatar, Combos)

--    --重置玩家当前关卡的通关时间和卡id、难度
--    avatar.MissionTempData = {0, MissionId, Difficult, MissionIdRandom, MissionDifficultyRandom,}

    local MissionTempData = avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_DATA] or {}
    local UseTime = MissionTempData[1] or 0
    local mission = MissionTempData[2] or 0
    local difficulty = MissionTempData[3] or 0
    local MissionIdRandom = MissionTempData[4]
    local MissionDifficultyRandom = MissionTempData[5]

    if UseTime == 0 or mission == 0 or difficulty == 0 then
        log_game_error("MissionSystem:UploadCombo", "dbid=%q;name=%s;Combos=%d", avatar.dbid, avatar.name, Combos)
    else
        --开始结算

        log_game_debug("MissionSystem:UploadCombo", "dbid=%q;name=%s;Combos=%d;UseTime=%d;mission=%d;difficulty=%d", avatar.dbid, avatar.name, Combos, UseTime, mission, difficulty)

        --把临时数据清理掉
        avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_DATA] = nil
--        avatar.MissionTempData = {}

        local vipLimit = g_vip_mgr:GetVipPrivileges(avatar.VipLevel)

        local _Point = 0
        local _Star = 0

        if not vipLimit then
            log_game_error("MissionSystem:UploadCombo", "dbid=%q;name=%s;VipLevel=%d", avatar.dbid, avatar.name, avatar.VipLevel)
        else
            local HpCount = vipLimit.hpMaxCount - avatar.hpCount
            if avatar.tmp_data[public_config.TMP_DATA_KEY_IS_RANDOM_MISSION] then
                _Star, _Point = self:GetMissionStar(avatar, MissionIdRandom, MissionDifficultyRandom, UseTime, HpCount, Combos)
            else
                _Star, _Point = self:GetMissionStar(avatar, mission, difficulty, UseTime, HpCount, Combos)
            end
        end

        --生成翻牌数据
        --每次生成5张牌，然后根据评价的次数决定获得几张
        local RandomReward = {}
        if avatar.tmp_data[public_config.TMP_DATA_KEY_IS_RANDOM_MISSION] then
            RandomReward = self:GenMissionRandomReward(mission, avatar.level, avatar.vocation)
        else
            RandomReward = self:GenMissionRandomReward(mission, difficulty, avatar.vocation)
        end
        local times = g_mission_mgr:getMissionRandomRewardTimes(_Star)
        local playerRandomReward = {}
        for i=1, times do
            table.insert(playerRandomReward, RandomReward[i])
        end

--        for _, v in pairs(playerRandomReward) do
--            for itemId, _ in pairs(v) do
--                local itemCfg = g_itemdata_mgr:GetItem(public_config.ITEM_TYPE_CFG_TBL, itemId)
--                if itemCfg and itemCfg['quality'] then
--                    if itemCfg['quality'] == public_config.ITEM_QUALITY_PURPLE then
--                        global_data:ShowTextID(CHANNEL.WORLD, mission_config.RANDOM_REWARD_MSG_PURPLE, {avatar.name, ['item_id'] = itemId})  --给所有人发消息改为从 global_data
--                    elseif itemCfg['quality'] == public_config.ITEM_QUALITY_ORANGE then
--                        global_data:ShowTextID(CHANNEL.WORLD, mission_config.RANDOM_REWARD_MSG_ORANGE, {avatar.name, ['item_id'] = itemId})  --给所有人发消息改为从 global_data
--                    end
--                end
--            end
--        end

        avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_RANDOM_REWARD] = playerRandomReward

        if avatar:hasClient() then
            local result = {UseTime, _Star, _Point, RandomReward}
            log_game_debug("MissionSystem:UploadCombo to client", "missionId=%d;difficulty=%d;dbid=%q;name=%s;UseTime=%d;_Star=%d;_Point=%d;fightForce=%d;Combos=%d;result=%s", mission, difficulty, avatar.dbid, avatar.name, UseTime, _Star, _Point, avatar.fightForce, Combos, mogo.cPickle(result))
            log_game_info("MissionSystem:Statistics", " %d %d %q %s %d %d %d %d", mission, difficulty, avatar.dbid, avatar.name, UseTime, _Point, avatar.fightForce, Combos)
            avatar.client.MissionResp(action_config.MSG_NOTIFY_TO_CLIENT_RESULT_SUCCESS, result)
        end

        globalbase_call("MissionMgr", "UpdateMissionRecord", mission, difficulty, avatar.dbid, avatar.name, avatar.vocation, UseTime, Combos, _Point)

        if avatar.tmp_data[public_config.TMP_DATA_KEY_IS_RANDOM_MISSION] then
            avatar.tmp_data[public_config.TMP_DATA_KEY_IS_RANDOM_MISSION] = nil
        else

            if avatar.tmp_data[public_config.TMP_DATA_KEY_IS_MWSY] then
                --如果玩家是在迷雾深渊副本，则标记该玩家已经打完了该副本，进度加1
                avatar.tmp_data[public_config.TMP_DATA_KEY_IS_MWSY] = nil

                if avatar.MwsyInfo[mission_config.MWSY_MISSION_DIFFICULTY] >= mission_config.MWSY_MISSION_DIFFICULTY_DY then
                    avatar.MwsyInfo[mission_config.MWSY_MISSION_IS_FINISH] = 1
                else
                    avatar.MwsyInfo[mission_config.MWSY_MISSION_DIFFICULTY] = avatar.MwsyInfo[mission_config.MWSY_MISSION_DIFFICULTY] + 1
                end

            else
                if avatar.MissionStars[mission] then
                    if not avatar.MissionStars[mission][difficulty] or avatar.MissionStars[mission][difficulty] < _Star then
                        avatar.MissionStars[mission][difficulty] = _Star
                    end
                else
                    avatar.MissionStars[mission] = {}
                    avatar.MissionStars[mission][difficulty] = _Star
                end

                --计算总的s数
                avatar.MissionSSum = self:GetMissionSSum(avatar)
            end

        end

        --关卡胜利后累加挑战次数和精力值
        self:AddMissionTimes(avatar, mission, difficulty)

    end

    return 0
end

--进入迷雾深渊
function MissionSystem:EnterMissionMwsy(avatar, missionId, difficulty)

    local result = self:CanEnterMission(avatar, missionId, difficulty)

    if result < 0 then
        log_game_error("MissionSystem:EnterMission", "missionId=%d;difficulty=%d;dbid=%q;name=%s;result=%d",  missionId, difficulty, avatar.dbid, avatar.name, result)

        if avatar:hasClient() then
            avatar.client.MissionResp(action_config.MSG_ENTER_MISSION, {result})
        end
        return result
    else
        --可以进入副本关卡
        --申请副本
        self:GotoMission(avatar, missionId, difficulty)
    end

    return 0
end


--获取一个关卡，初始化临时奖励池
function MissionSystem:EnterMission(avatar, missionId, difficulty)

    local result = self:CanEnterMission(avatar, missionId, difficulty)

    --判断是否迷雾深渊，如果是，则需要返回错误码，不应该从该接口进入迷雾深渊
    if g_mission_mgr:IsMwsyMissionDifficulty(missionId, difficulty) then
        result = -6
    end

    if result < 0 then
        log_game_error("MissionSystem:EnterMission", "missionId=%d;difficulty=%d;dbid=%q;name=%s;result=%d",  missionId, difficulty, avatar.dbid, avatar.name, result)

        if avatar:hasClient() then
            avatar.client.MissionResp(action_config.MSG_ENTER_MISSION, {result})
        end
        return result
--    elseif mogo.stest(avatar.state, public_config.STATE_IN_TELEPORT) ~= 0 then
--        result = -6
--        log_game_error("MissionSystem:EnterMission", "dbid=%q;name=%s;missionId=%d;difficulty=%d;result=%d",
--                                                      avatar.dbid, avatar.name, missionId, difficulty, result)
--        avatar.client.MissionResp(mission_config.MSG_ENTER_MISSION, {result})
--        return result
    else
        --可以进入副本关卡
        --申请副本
        self:GotoMission(avatar, missionId, difficulty)
--        local tbl = {}
--        table.insert(tbl, tostring(missionId))
--        table.insert(tbl, tostring(difficulty))
--        local MissionCfg = g_mission_mgr:getCfgById(table.concat(tbl, '_'))
--        if MissionCfg and MissionCfg['scene'] then
--            globalbase_call("MapMgr", "SelectMapReq", avatar.base_mbstr,
--                                     MissionCfg['scene'], 0, avatar.dbid, avatar.name)
--
--            avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_ID] = missionId
--            avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_DIFFICULT] = difficulty
----            avatar.state = mogo.sset(avatar.state, public_config.STATE_IN_TELEPORT)
--
--            --记录玩家在王城的坐标点
--            if g_GlobalParamsMgr:GetParams('init_scene', 10004) == avatar.sceneId then
--                avatar.tmp_data[public_config.TMP_DATE_KEY_KINDOM_X] = avatar.map_x
--                avatar.tmp_data[public_config.TMP_DATE_KEY_KINDOM_Y] = avatar.map_y
--            end
--
--            if avatar:hasClient() then
--                avatar.client.MissionResp(action_config.MSG_ENTER_MISSION, {0})
--            end
    end

    return 0
end

--获取目前玩家满足条件的所有场景
function MissionSystem:GetAllMissionScene(avatar)
    local result = {}
    local allMissions = g_mission_mgr:getAllMissions()
    for k, v in pairs(allMissions) do
        if avatar.level >= v['level'] then
            result[v['scene']] = true
        end
    end
    return result
end

function MissionSystem:GotoMission(avatar, missionId, difficulty)
    local tbl = {}
    table.insert(tbl, tostring(missionId))
    table.insert(tbl, tostring(difficulty))
    local MissionCfg = g_mission_mgr:getCfgById(table.concat(tbl, '_'))

    if MissionCfg and MissionCfg['scene'] and mogo.stest(avatar.state, state_config.STATE_SCENE_CHANGING) == 0 then

        avatar.baseflag = mogo.sunset(avatar.baseflag, public_config.AVATAR_BASE_STATE_NEWBIE)

        if MissionCfg['isConsole'] and MissionCfg['isConsole'] == 1 then
            if mogo.stest(avatar.state, state_config.STATE_CONSOLE) == 0 then
                --如果玩家选择进入的是一个单机副本，则玩家需要隐身

                if avatar:HasCell() then
                    --玩家的cell部分隐身
                    avatar.cell.set_invisiable()
                    --设置玩家进入单机副本状态
                    avatar.state = mogo.sset(avatar.state, state_config.STATE_CONSOLE)

                    --进副本前重置血瓶
                    avatar:ResetHpCount()
                else
                    log_game_warning("MissionSystem:GotoMission isConsole no cell", "dbid=%q;name=%s;missionId=%d;difficulty=%d", avatar.dbid, avatar.name, missionId, difficulty)
                end

                --通知客户端切换成功，客户端自行通过配置表读取需要加载的场景
                if avatar:hasClient() then
                    avatar.client.MissionResp(action_config.MSG_ENTER_MISSION, {0})
                end

                --生成奖励池，发送给客户端
                --开始记录时间？
                --获取该次副本的奖励
                local Reward = g_mission_mgr:getRewardInfo(missionId, difficulty, avatar.vocation, 1)
                local ItemTbl = Reward[2] or {}
                --金币奖励
                local Money = Reward[3] or 0
                --经验奖励
                local Exp = Reward[4] or 0

                local Result = {[1] = ItemTbl, [2] = Money, [3] = Exp }

                avatar.tmp_data[public_config.TMP_DATA_KEY_CONSOLE_MISSION_REWARD] = Result
                avatar.tmp_data[public_config.TMP_DATA_KEY_CONSOLE_MISSION_STARTTIME] = os.time()
                avatar.tmp_data[public_config.TMP_DATA_KEY_CONSOLE_MISSION_ID] = missionId
                avatar.tmp_data[public_config.TMP_DATA_KEY_CONSOLE_MISSION_DIFFICULT] = difficulty

                log_game_debug("MissionSystem:GotoMission isConsole", "dbid=%d;name=%s;missionId=%d;difficulty=%d;Result=%s", avatar.dbid, avatar.name, missionId, difficulty, mogo.cPickle(Result))

                if avatar:hasClient() then
                    avatar.client.MissionResp(action_config.MSG_NOTIFY_TO_CLIENT_MISSION_REWARD, Result)
                end

                return
            else
                log_game_error("MissionSystem:GotoMission isConsole", "dbid=%d;name=%s;missionId=%d;difficulty=%d", avatar.dbid, avatar.name, missionId, difficulty)
                return
            end
        else
            --如果该关卡是非单机关卡，则需要传送至一个新的space
            local cfg = g_map_mgr:getMapCfgData(MissionCfg['scene'])
            if cfg['type'] == public_config.MAP_TYPE_RANDOM then
                --如果玩家进入的随机副本，则需要获取一个随机场景ID

                --获取所有可选的场景
                local randomScenes = g_map_mgr:GetRandomSceneIds()

                --获取玩家满足条件的场景
                local nowScenes = self:GetAllMissionScene(avatar)

                --获取可选的场景ID
                local result = {}
                for i, _ in pairs(randomScenes) do
                    if nowScenes[i] then
                        table.insert(result, i)
--                        log_game_debug("MissionSystem:GotoMission random", "dbid=%d;name=%s;i=%d", avatar.dbid, avatar.name, i)
                    end
                end

                if result == {} then
                    if avatar:hasClient() then
                        avatar.client.MissionResp(action_config.MSG_ENTER_MISSION, {-8})
                    end
                    return
                end

                local sceneId = choose_1(result)

                log_game_debug("MissionSystem:GotoMission random", "dbid=%d;name=%s;missionId=%d;difficulty=%d;sceneId=%d;oldSceneId=%d", avatar.dbid, avatar.name, missionId, difficulty, sceneId, MissionCfg['scene'])

                globalbase_call("MapMgr", "SelectMapReq", avatar.base_mbstr, sceneId, 0, avatar.dbid, avatar.name, {['type'] = public_config.MAP_TYPE_RANDOM})

                avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_ID_RANDOM] = sceneId
                avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_DIFFICULT_RANDOM] = 1

            else
                globalbase_call("MapMgr", "SelectMapReq", avatar.base_mbstr, MissionCfg['scene'], 0, avatar.dbid, avatar.name, {})

            end

            avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_ID] = missionId
            avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_DIFFICULT] = difficulty

            --记录玩家在王城的坐标点
            if g_GlobalParamsMgr:GetParams('init_scene', 10004) == avatar.sceneId then
                avatar.tmp_data[public_config.TMP_DATE_KEY_KINDOM_X] = avatar.map_x
                avatar.tmp_data[public_config.TMP_DATE_KEY_KINDOM_Y] = avatar.map_y
            end

            avatar.state = mogo.sset(avatar.state, state_config.STATE_SCENE_CHANGING)

            if avatar:hasClient() then
                avatar.client.MissionResp(action_config.MSG_ENTER_MISSION, {0})
            end

            log_game_debug("MissionSystem:GotoMission", "missionId=%d;difficult=%d;dbid=%q;name=%s;tmp_data=%s", missionId, difficulty, avatar.dbid, avatar.name, mogo.cPickle(avatar.tmp_data))
        end
    end
end

--副本胜利前退出
function MissionSystem:ExitMission(avatar, ...)

    log_game_debug("MissionSystem:ExitMission", "dbid=%q;name=%s;sceneId=%d;line=%d", avatar.dbid, avatar.name, avatar.sceneId, avatar.imap_id)

    if avatar:HasCell() then
        --玩家的cell部分隐身

        if mogo.stest(avatar.state, state_config.STATE_CONSOLE) ~= 0 then
            avatar.state = mogo.sunset(avatar.state, state_config.STATE_CONSOLE)

            --玩家从单机副本出来，需要随机一个坐标点
            local locations = g_GlobalParamsMgr:GetParams('init_scene_random_enter_point', {})
            local index = math.random(1, lua_util.get_table_real_count(locations))
            avatar.cell.TelportLocally( locations[index][1], locations[index][2])

            --玩家处于单机副本中
            avatar.cell.set_visiable()
            --离开副本时重置血瓶
            avatar:ResetHpCount()
            --重置复活次数
            avatar.ReviveTimes = 0

            --获取随机奖励
            self:GetMissionRandomReward(avatar)

            --通知客户端加载场景
            avatar.client.MissionResp(action_config.MSG_NOTIFY_TO_CLIENT_TO_LOAD_INIT_MAP, {avatar.sceneId, avatar.imap_id})
        else
            local SpaceLoader = avatar.SpaceLoaderMb
            if SpaceLoader then
                SpaceLoader.ExitMission(avatar.dbid)
            else
                log_game_error("MissionSystem:ExitMission", "dbid=%q;name=%s;sceneId=%d;line=%d", avatar.dbid, avatar.name, avatar.sceneId, avatar.imap_id)
            end
        end
    end

--    --通知玩家离开副本


    return 0
end

function MissionSystem:ExitMap(avatar, missionId, difficulty)

--    if mogo.stest(avatar.state, state_config.STATE_CONSOLE) ~= 0 then
--        avatar.state = mogo.sunset(avatar.state, state_config.STATE_CONSOLE)
--        --玩家处于单机副本中
--        avatar.cell.set_visiable()
--        --通知客户端加载场景
--        avatar.client.MissionResp(action_config.MSG_NOTIFY_TO_CLIENT_TO_LOAD_INIT_MAP, {avatar.sceneId, avatar.imap_id})
--    else
    if mogo.stest(avatar.state, state_config.STATE_SCENE_CHANGING) == 0 then

--        --离开副本时扣除体力
--        local tbl = {}
--        table.insert(tbl, tostring(missionId))
--        table.insert(tbl, tostring(difficulty))
--        local MissionCfg = g_mission_mgr:getCfgById(table.concat(tbl, '_'))
--        if MissionCfg and MissionCfg['energy'] then
--            avatar:DeductEnergy(MissionCfg['energy'])
--            log_game_debug("MissionSystem:ExitMap DeductEnergy", "dbid=%q;name=%s;missionId=%d;difficulty=%d;MissionCfg['energy']=%d;energy=%d",
--                avatar.dbid, avatar.name, missionId, difficulty,
--                MissionCfg['energy'], avatar.energy)
--        end

        globalbase_call("MapMgr", "SelectMapReq", avatar.base_mbstr, g_GlobalParamsMgr:GetParams('init_scene', 10004), 0, avatar.dbid, avatar.name, {})
        avatar.state = mogo.sset(avatar.state, state_config.STATE_SCENE_CHANGING)
    else
        log_game_warning("MissionSystem:ExitMap", "dbid=%q;name=%s", avatar.dbid, avatar.name)
    end
--    end

    return 0
end

function MissionSystem:GoToInitMap(avatar, ...)
    --无论上什么情况都适用的离开副本接口
    if mogo.stest(avatar.state,  state_config.STATE_SCENE_CHANGING) == 0 then
        if mogo.stest(avatar.state, state_config.STATE_CONSOLE) ~= 0 then
            avatar.state = mogo.sunset(avatar.state, state_config.STATE_CONSOLE)

            --玩家从单机副本出来，需要随机一个坐标点
            local locations = g_GlobalParamsMgr:GetParams('init_scene_random_enter_point', {})
            local index = math.random(1, lua_util.get_table_real_count(locations))
            avatar.cell.TelportLocally( locations[index][1], locations[index][2])

            --玩家处于单机副本中
            avatar.cell.set_visiable()
            --离开副本时重置血瓶
            avatar:ResetHpCount()
            --重置复活次数
            avatar.ReviveTimes = 0

            --获取随机奖励
            self:GetMissionRandomReward(avatar)


            --通知客户端加载场景
            avatar.client.MissionResp(action_config.MSG_NOTIFY_TO_CLIENT_TO_LOAD_INIT_MAP, {avatar.sceneId, avatar.imap_id})
        else
            globalbase_call("MapMgr", "SelectMapReq", avatar.base_mbstr, g_GlobalParamsMgr:GetParams('init_scene', 10004), 0, avatar.dbid, avatar.name, {})
            avatar.state = mogo.sset(avatar.state, state_config.STATE_SCENE_CHANGING)
        end
    else
        log_game_warning("MissionSystem:GoToInitMap", "dbid=%q;name=%s", avatar.dbid, avatar.name)
    end
    return 0
end

--副本胜利后退出
function MissionSystem:QuitMission(avatar, ...)
    log_game_debug("MissionSystem:QuitMission", "dbid=%q;name=%s", avatar.dbid, avatar.name)
--
--    local tbl = {}
--    table.insert(tbl, 'SpaceLoader')
--    table.insert(tbl, tostring(avatar.sceneId))
--    table.insert(tbl, tostring(avatar.imap_id))
--

    if avatar:HasCell() then
        if mogo.stest(avatar.state, state_config.STATE_CONSOLE) ~= 0 then
            avatar.state = mogo.sunset(avatar.state, state_config.STATE_CONSOLE)

            --玩家从单机副本出来，需要随机一个坐标点
            local locations = g_GlobalParamsMgr:GetParams('init_scene_random_enter_point', {})
            local index = math.random(1, lua_util.get_table_real_count(locations))
            avatar.cell.TelportLocally( locations[index][1], locations[index][2])

            --玩家处于单机副本中
            avatar.cell.set_visiable()
            --离开副本时重置血瓶
            avatar:ResetHpCount()
            --重置复活次数
            avatar.ReviveTimes = 0

            --获取随机奖励
            self:GetMissionRandomReward(avatar)

            --通知客户端加载场景
            avatar.client.MissionResp(action_config.MSG_NOTIFY_TO_CLIENT_TO_LOAD_INIT_MAP, {avatar.sceneId, avatar.imap_id})
        else
            local SpaceLoader = avatar.SpaceLoaderMb
            if SpaceLoader then
                SpaceLoader.QuitMission(avatar.dbid)
            else
                log_game_error("MissionSystem:QuitMission", "dbid=%q;name=%s;sceneId=%d;line=%d", avatar.dbid, avatar.name, avatar.sceneId, avatar.imap_id)
            end
        end
    end

    return 0
end

function MissionSystem:StartMission(avatar, mercenaryIndex)

    log_game_debug("MissionSystem:StartMission", "dbid=%q;name=%s;mercenaryIndex=%d", avatar.dbid, avatar.name, mercenaryIndex)

    --mercenary select begin
    avatar.mercenaryDbid = 0   
    if mercenaryIndex > 0 then
        local mercenaryInfo = avatar.mercenaryInfoList[mercenaryIndex]
        if mercenaryInfo then
            avatar.mercenaryDbid = mercenaryInfo[1]
        end
    end
    --mercenary select end

    local SpaceLoader = avatar.SpaceLoaderMb
    if SpaceLoader then
        SpaceLoader.Start(os.time())
    end

--    lua_util.globalbase_call("MapMgr", "Start", avatar.sceneId, avatar.imap_id, avatar.dbid)

--    log_game_debug("MissionSystem:StartMission", "dbid=%q;name=%s;missionInfo=%s", 
--                                                           avatar.dbid, avatar.name, avatar.ClientMissionInfo)
    if avatar.ClientMissionInfo ~= '' and avatar:hasClient() then
        avatar.client.MissionResp(action_config.MSG_CLIENT_MISSION_INFO, {avatar.ClientMissionInfo})
    end

    return 0
end

function MissionSystem:AddFriendDegree(avatar)
    local SpaceLoader = avatar.SpaceLoaderMb
    if SpaceLoader and avatar.mercenaryDbid > 0 then
        SpaceLoader.AddFriendDegree(avatar.dbid, avatar.mercenaryDbid)
    end

    return 0
end

function MissionSystem:OnChangeScene(avatar, scene, line)
--    log_game_debug("MissionSystem:OnChangeScene", "scene = %d, line = %d", scene, line)

    local MissionId = avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_ID]
    local Difficult = avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_DIFFICULT]

    local MissionIdRandom = avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_ID_RANDOM]
    local MissionDifficultyRandom = avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_DIFFICULT_RANDOM]

    if MissionId and Difficult and not MissionIdRandom and not MissionDifficultyRandom then
        --正常服务器副本

        local SpaceLoader = avatar.SpaceLoaderMb
        if SpaceLoader then
            SpaceLoader.SetMissionInfo(avatar.dbid, avatar.name, avatar.base_mbstr, MissionId, Difficult)
        end

        avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_ID] = nil
        avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_DIFFICULT] = nil

        --当玩家进入一个关卡，而且该关卡此前没有评价，则先设成未通过
        local MissionStars = avatar.MissionStars[MissionId] or {}
        if not MissionStars[Difficult] then
            MissionStars[Difficult] = mission_config.MISSION_VALUATION_NOT_PASS
            avatar.MissionStars[MissionId] = MissionStars
        end
        log_game_debug("MissionSystem:OnChangeScene init", "MissionId=%d;Difficult=%d", MissionId, Difficult)

        --重置玩家当前关卡的通关时间和卡id、难度
        avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_DATA] = {0, MissionId, Difficult,}
--        avatar.MissionTempData = {0, MissionId, Difficult,}

    end

    if MissionIdRandom and MissionDifficultyRandom then
        --随机副本

        if avatar:hasClient() then
            avatar.client.MissionResp(action_config.MSG_NOTIFY_TO_CLIENT_MISSION_INFO, {MissionIdRandom, MissionDifficultyRandom})
        end

        local SpaceLoader = avatar.SpaceLoaderMb
        if SpaceLoader then
            SpaceLoader.SetMissionInfo(avatar.dbid, avatar.name, avatar.base_mbstr, MissionIdRandom, MissionDifficultyRandom)
        end

        avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_ID_RANDOM] = nil
        avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_DIFFICULT_RANDOM] = nil

        --重置玩家当前关卡的通关时间和卡id、难度
        avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_DATA] = {0, MissionId, Difficult, MissionIdRandom, MissionDifficultyRandom,}

--        avatar.MissionTempData = {0, MissionId, Difficult, MissionIdRandom, MissionDifficultyRandom,}

        --记录当前属于随机副本
        avatar.tmp_data[public_config.TMP_DATA_KEY_IS_RANDOM_MISSION] = 1
    end

    if scene == g_GlobalParamsMgr:GetParams('init_scene', 10004) then
        avatar.ReviveTimes = 0
        avatar.ClientMissionInfo = ''
        avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_DATA] = nil
        avatar.tmp_data[public_config.TMP_DATA_KEY_IS_MWSY] = nil
--        avatar.MissionTempData = {}
        avatar.tmp_data[public_config.TMP_DATA_KEY_IS_RANDOM_MISSION] = nil

        log_game_debug("MissionSystem:OnChangeScene init_scene", "dbid=%q;name=%s", avatar.dbid, avatar.name)

        --获取随机奖励
        self:GetMissionRandomReward(avatar)

--        --玩家回到王城以后把奖励加给他
--        if avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_RANDOM_REWARD] then
--            log_game_debug("MissionSystem:OnChangeScene init_scene", "dbid=%q;name=%s;randomReward=%s", avatar.dbid, avatar.name, mogo.cPickle(avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_RANDOM_REWARD]))
--
--            local attach = {}
--            local times = 0
--            for _, v in pairs(avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_RANDOM_REWARD]) do
--                times = times + 1
--                for itemId, count in pairs(v) do
--                    if itemId == public_config.EXP_ID then
--                        avatar:AddExp(count, reason_def.mission_random_reward)
--                    elseif itemId == public_config.GOLD_ID then
--                        avatar:AddGold(count, reason_def.mission_random_reward)
--                    elseif itemId == public_config.DIAMOND_ID then
--                        avatar:AddDiamond(count, reason_def.mission_random_reward)
--                    else
--                        if avatar.inventorySystem:IsSpaceEnough(itemId, count) then
--                            --背包位置足够
--                            avatar.inventorySystem:AddItems(itemId, count)
--                        else
--                            if not attach[itemId] then
--                                attach[itemId] = count
--                            else
--                                attach[itemId] = attach[itemId] + count
--                            end
--                        end
--                    end
--                end
--            end
--            if next(attach) then
--
--                local now = os.time()
--                globalbase_call('MailMgr', 'SendIdEx', g_text_id.MISSION_MAIL_RANDOM_REWARD_TITLE,  --title
--                    avatar.name,                              --to
--                    g_text_id.MISSION_MAIL_RANDOM_REWARD_TEXT, --text
--                    g_text_id.MISSION_MAIL_RANDOM_REWARD_FROM, --from
--                    now,                              --time
--                    attach,                                 --道具
--                    {[1]=avatar.dbid,}, --收件者的dbid列表
--                    {os.date("%m", now), os.date("%d", now)},
--                    reason_def.mission_random_reward
--                )
--            end
--
--            --记录翻拍次数
--            avatar:OnRollCard(times)
--
--            avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_RANDOM_REWARD] = nil
--        end
    end

--    --如果玩家进入的是剧情副本，则扣体力
--    local cfg = g_map_mgr:getMapCfgData(scene)
--        if cfg and cfg['type'] == public_config.MAP_TYPE_SPECIAL then
--            --扣除体力值
--            local MissionCfg = g_mission_mgr:getCfgById(tostring(MissionId) .. "_" .. tostring(Difficult))
--            if MissionCfg and MissionCfg['energy'] then
--                avatar:DeductEnergy(MissionCfg['energy'])
--                log_game_debug("MissionSystem:OnChangeScene DeductEnergy", "dbid=%q;name=%s;MissionId=%d;Difficult=%d;MissionCfg['energy']=%d;energy=%d", 
--                                                                            avatar.dbid, avatar.name, MissionId, Difficult,
--                                                                            MissionCfg['energy'], avatar.energy)
--            end
--        end
--    end
    return 0
end

function MissionSystem:GetMissionRandomReward(avatar)
    --玩家回到王城以后把奖励加给他
    if avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_RANDOM_REWARD] then
        local attach = {}
        local times = 0
        for _, v in pairs(avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_RANDOM_REWARD]) do
            times = times + 1
            for itemId, count in pairs(v) do
                if itemId == public_config.EXP_ID then
                    avatar:AddExp(count, reason_def.mission_random_reward)
                elseif itemId == public_config.GOLD_ID then
                    avatar:AddGold(count, reason_def.mission_random_reward)
                elseif itemId == public_config.DIAMOND_ID then
                    avatar:AddDiamond(count, reason_def.mission_random_reward)
                else
                    if avatar.inventorySystem:IsSpaceEnough(itemId, count) then
                        --背包位置足够
                        avatar.inventorySystem:AddItems(itemId, count)
                    else
                        if not attach[itemId] then
                            attach[itemId] = count
                        else
                            attach[itemId] = attach[itemId] + count
                        end
                    end
                end

                --拿到紫装或者橙装后发公告
                local itemCfg = g_itemdata_mgr:GetItem(public_config.ITEM_TYPE_CFG_TBL, itemId)
                if itemCfg and itemCfg['quality'] then
                    if itemCfg['quality'] == public_config.ITEM_QUALITY_PURPLE then
                        global_data:ShowTextID(CHANNEL.WORLD, mission_config.RANDOM_REWARD_MSG_PURPLE, {avatar.name, ['item_id'] = itemId})  --给所有人发消息改为从 global_data
                    elseif itemCfg['quality'] == public_config.ITEM_QUALITY_ORANGE then
                        global_data:ShowTextID(CHANNEL.WORLD, mission_config.RANDOM_REWARD_MSG_ORANGE, {avatar.name, ['item_id'] = itemId})  --给所有人发消息改为从 global_data
                    end
                end
            end
        end
        if next(attach) then
            local now = os.time()

            log_game_debug("MissionSystem:GetMissionRandomReward send mail", "dbid=%q;name=%s;attach=%s", avatar.dbid, avatar.name, mogo.cPickle(attach))

            globalbase_call('MailMgr', 'SendIdEx', g_text_id.MISSION_MAIL_OFFLINE_RANDOM_REWARD_TITLE,  --title
                avatar.name,                              --to
                g_text_id.MISSION_MAIL_OFFLINE_RANDOM_REWARD_TEXT, --text
                g_text_id.MISSION_MAIL_OFFLINE_RANDOM_REWARD_FROM, --from
                now,                              --time
                attach,                                 --道具
                {[1]=avatar.dbid,}, --收件者的dbid列表
                {os.date("%m", now), os.date("%d", now)},
                reason_def.mission_random_reward
            )
        end

        --记录翻牌次数
        avatar:OnRollCard(times)

        avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_RANDOM_REWARD] = nil
    end
end

function MissionSystem:onDestroy(avatar)
    --获取随机奖励
    self:GetMissionRandomReward(avatar)
--    --玩家回到王城以后把奖励加给他
--    if avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_RANDOM_REWARD] then
--        local attach = {}
--        local times = 0
--        for _, v in pairs(avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_RANDOM_REWARD]) do
--            times = times + 1
--            for itemId, count in pairs(v) do
--                if itemId == public_config.EXP_ID then
--                    avatar:AddExp(count, reason_def.mission_random_reward)
--                elseif itemId == public_config.GOLD_ID then
--                    avatar:AddGold(count, reason_def.mission_random_reward)
--                elseif itemId == public_config.DIAMOND_ID then
--                    avatar:AddDiamond(count, reason_def.mission_random_reward)
--                else
--                    if avatar.inventorySystem:IsSpaceEnough(itemId, count) then
--                        --背包位置足够
--                        avatar.inventorySystem:AddItems(itemId, count)
--                    else
--                        if not attach[itemId] then
--                            attach[itemId] = count
--                        else
--                            attach[itemId] = attach[itemId] + count
--                        end
--                    end
--                end
--            end
--        end
--        if next(attach) then
--            local now = os.time()
--            globalbase_call('MailMgr', 'SendIdEx', g_text_id.MISSION_MAIL_OFFLINE_RANDOM_REWARD_TITLE,  --title
--                avatar.name,                              --to
--                g_text_id.MISSION_MAIL_OFFLINE_RANDOM_REWARD_TEXT, --text
--                g_text_id.MISSION_MAIL_OFFLINE_RANDOM_REWARD_FROM, --from
--                os.time(),                              --time
--                attach,                                 --道具
--                {[1]=avatar.dbid,}, --收件者的dbid列表
--                {os.date("%m", now), os.date("%d", now)},
--                reason_def.mission_random_reward
--            )
--        end
--
--        --记录翻牌次数
--        avatar:OnRollCard(times)
--
--        avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_RANDOM_REWARD] = nil
--    end
end



--判断是否可进入关卡的函数
function MissionSystem:CanEnterMission(avatar, mission, difficulty)
    local MissionCfg = g_mission_mgr:getCfgById(tostring(mission) .. "_" .. tostring(difficulty))
    if MissionCfg then

        if mogo.stest(avatar.state, state_config.STATE_MISSION_ALL_ALLOW) ~= 0 then
            return 0
        end

        --判断是否已经达到最小进入等级
        if MissionCfg['level'] and MissionCfg['level'] > avatar.level then
            return -2
        end

        --判断是否完成前置关卡
        if MissionCfg['preMissions'] then
            --遍历前置关卡条件，如果玩家没有前置关卡，则返回错误码
            for i, v in pairs(MissionCfg['preMissions']) do
                if not avatar.MissionStars[i] then
                    return -3
                elseif not avatar.MissionStars[i][v] or avatar.MissionStars[i][v] <= mission_config.MISSION_VALUATION_NOT_PASS then
                    return -3
                end
            end
        end

        --判断是否已达到每天挑战上限
        if avatar.MissionTimes[mission] and avatar.MissionTimes[mission][difficulty] then
            if avatar.MissionTimes[mission][difficulty] >= MissionCfg['dayTimes'] then
--                local vipLimit = g_vip_mgr:GetVipPrivileges(avatar.VipLevel)
--
--                if (not vipLimit) or ((avatar.VipRealState[public_config.DAILY_MISSION_TIMES] or 0) >= vipLimit.missionDayTimes) then
                return -4
--                end

            end
        end

        --判断体力是否足够
        if MissionCfg['energy'] and avatar.energy < MissionCfg['energy'] then
            return -5
        end

--        --判断战斗力是否足够
--        if MissionCfg['minimumFight'] and avatar.fightForce < MissionCfg['minimumFight'] then
--            return -7
--        end

        --判断任务条件是否达成

        return 0
    else
        return -1
    end
end

function MissionSystem:AddMissionTimes(avatar, mission, difficulty)

--    log_game_debug("MissionSystem:AddMissionTimes", "dbid=%q;name=%s;mission=%d;difficulty=%d", avatar.dbid, avatar.name, mission, difficulty)

    local MissionCfg = g_mission_mgr:getCfgById(tostring(mission) .. "_" .. tostring(difficulty))
    if MissionCfg then
        local missionInfo = avatar.MissionTimes[mission]
        if missionInfo then
            local oldTimes = avatar.MissionTimes[mission][difficulty]
            if oldTimes then --and oldTimes < MissionCfg['dayTimes'] then
                avatar.MissionTimes[mission][difficulty] = oldTimes + 1
--            elseif oldTimes and oldTimes >= MissionCfg['dayTimes'] then
--                avatar.VipRealState[public_config.DAILY_MISSION_TIMES] = (avatar.VipRealState[public_config.DAILY_MISSION_TIMES] or 0) + 1
            else
                avatar.MissionTimes[mission][difficulty] = 1
            end
        else
            avatar.MissionTimes[mission] = {}
            avatar.MissionTimes[mission][difficulty] = 1
        end

        --副本的每日次数开始累计时，判断是否需要触发迷雾深渊
        self:TriggerMwsy(avatar)
    end

--    log_game_debug("MissionSystem:AddMissionTimes", "dbid=%q;name=%s;MissionTimes=%s", avatar.dbid, avatar.name, mogo.cPickle(avatar.MissionTimes))

--    --修改了lua_table中的一个值，需要整体赋值才能设置为脏数据存盘
--    local MissionTimes = mogo.deepcopy1(avatar.MissionTimes)
--    avatar.MissionTimes = MissionTimes

    return 0
end

function MissionSystem:GetMissionStar(avatar, mission, difficulty, UsedTime, HpCount, Combos)

    log_game_debug("MissionSystem:GetMissionStar", "dbid=%q;name=%s;mission=%d;difficulty=%d;UsedTime=%d;HpCount=%d;Combos=%d", avatar.dbid, avatar.name, mission, difficulty, UsedTime, HpCount, Combos)

    local idealPassTime         = 0
--    local idealCombo            = 0
--    local idealReviveTimes      = 0
--    local idealUseHpBottleTimes = 0
    local RevivieTimes          = avatar.ReviveTimes

    local MissionEvaluate = g_mission_mgr:getMissionEvaluate(mission, difficulty)

    local star = 0
    local point = 0

    if MissionEvaluate then

--        if avatar.vocation == public_config.VOC_WARRIOR then
--            idealCombo = tonumber(MissionEvaluate['ideal_combo_warrior'] or 0)
--        end
--
--        if avatar.vocation == public_config.VOC_ASSASSIN then
--            idealCombo = tonumber(MissionEvaluate['ideal_combo_assassin'] or 0)
--        end
--
--        if avatar.vocation == public_config.VOC_ARCHER then
--            idealCombo = tonumber(MissionEvaluate['ideal_combo_archer'] or 0)
--        end
--
--        if avatar.vocation == public_config.VOC_MAGE then
--            idealCombo = tonumber(MissionEvaluate['ideal_combo_mage'] or 0)
--        end

        idealPassTime = tonumber(MissionEvaluate['ideal_passTime'] or 0)
--        idealReviveTimes = tonumber(MissionEvaluate['ideal_reviveTime'] or 0)
--        idealUseHpBottleTimes = tonumber(MissionEvaluate['use_hpBottleTime'] or 0)

    --[[
     [实际通关时间/理想通关时间*时间权重+实际最高连击/理想最高连击*连击权重+（理想复活次数-实际复活次数）*复活权重+（理想喝药次数-实际喝药次数）*喝药权重]*基准分数

      *实际最高连击/理想最高连击最大值取1
      *小于0则记作0


                  暂定总分=10000，时间权重=5，连击权重=3，复活权重=1，喝药权重=1，基准分数=1000

                  需要为每一关每个难度设定SAB的区间

当实际通关时间<理想通关时间： 
[时间权重+实际最高连击/理想最高连击*连击权重+（理想复活次数-实际复活次数）*复活权重+（理想喝药次数-实际喝药次数）*喝药权重]*基准分数

当实际通关时间>=理想通关时间： 
[理想通关时间/实际通关时间*时间权重+实际最高连击/理想最高连击*连击权重+（理想复活次数-实际复活次数）*复活权重+（理想喝药次数-实际喝药次数）*喝药权重]*基准分数

    ]]

        --        point = (math.min(1, (idealPassTime / UsedTime)) * g_GlobalParamsMgr:GetParams('mission_point_time_rank', 5) +
        --                 math.min(1, (Combos / idealCombo)) * g_GlobalParamsMgr:GetParams('mission_point_combo_rank', 3) +
        --                 math.max(0, (idealReviveTimes - RevivieTimes)) * g_GlobalParamsMgr:GetParams('mission_point_revive_times_rank', 1) +
        --                 math.max(0, (idealUseHpBottleTimes - HpCount)) * g_GlobalParamsMgr:GetParams('mission_point_bottle_times_rank', 1)) *
        --                 g_GlobalParamsMgr:GetParams('mission_basic_point', 1000)
        --
        --        point = math.max(0, math.floor(point))


    --[[

    thresHold_i                    9500
    baseDenominator_i              11875
    firstDenominator_i             1000
    firstNumerator_i               988
    secondDenominator_i            1000
    secondNumerator_i              2493750
    maxHold_i                      95000
    reviveCutRate_i                1000
    useHpCutRate_i                 1000

    a=通关副本标准时间（读取配置）
    b=实际时间（玩家通关副本的实际时间）
    x=a/b*10000
    记录玩家通关副本的嗑药次数和复活次数

    y为评分
    x<thresHold_i
    y=x/baseDenominator_i*10000
    thresHold_i<=x<maxHold_i
    y=x*10000/(firstNumerator_i/firstDenominator_i*x+secondNumerator_i/secondDenominator_i)
    x>maxHold_i
    y=10000

    最终评分为
    y*(1-嗑药次数*useHpCutRate_i/10000)*（1-复活次数*reviveCutRate_i/10000）

    -- ]]

        local x = (idealPassTime / UsedTime) * 10000
        local y = 0

        if x < g_GlobalParamsMgr:GetParams('thresHold', 9500) then
            y = (x / g_GlobalParamsMgr:GetParams('baseDenominator', 11875)) * 10000

            log_game_debug("MissionSystem:GetMissionStar 1", "dbid=%q;name=%s;x=%d;y=%d", avatar.dbid, avatar.name, x, y)

        elseif x >= g_GlobalParamsMgr:GetParams('thresHold', 9500) and x < g_GlobalParamsMgr:GetParams('maxHold', 95000) then
            local x1 = x * 10000
            local y1 = g_GlobalParamsMgr:GetParams('firstNumerator', 988) / g_GlobalParamsMgr:GetParams('firstDenominator', 1000) * x
            local y2 = g_GlobalParamsMgr:GetParams('secondNumerator', 2493750) / g_GlobalParamsMgr:GetParams('secondDenominator', 1000)
            y =  x1 / (y1 + y2)

            log_game_debug("MissionSystem:GetMissionStar 2", "dbid=%q;name=%s;x=%d;y=%d", avatar.dbid, avatar.name, x, y)

        elseif x > g_GlobalParamsMgr:GetParams('maxHold', 95000) then
            y = 10000

            log_game_debug("MissionSystem:GetMissionStar 3", "dbid=%q;name=%s;x=%d;y=%d", avatar.dbid, avatar.name, x, y)

        end

        point = y * (1 - (HpCount *  g_GlobalParamsMgr:GetParams('useHpCutRate', 1000) / 10000))
                  * (1 - (RevivieTimes *  g_GlobalParamsMgr:GetParams('reviveCutRate', 1000) / 10000))

        --分数向下取整
        point = math.floor(point)

        --拿到区间
        local rank = MissionEvaluate['rank'] or {}

        if point >= tonumber(rank[2] or 0) then
            star = mission_config.MISSION_VALUATION_S
        elseif point >= tonumber(rank[1] or 0) then
            star = mission_config.MISSION_VALUATION_A
        else
            star = mission_config.MISSION_VALUATION_B
        end

        log_game_debug("MissionSystem:GetMissionStar", "dbid=%q;name=%s;mission=%d;difficulty=%d;UsedTime=%d;HpCount=%d;Combos=%d;RevivieTimes=%d;idealPassTime=%d;star=%d;point=%d;rank=%s",
                                                        avatar.dbid, avatar.name, 
                                                        mission, difficulty, 
                                                        UsedTime, HpCount, Combos, RevivieTimes,
                                                        idealPassTime, star, point, mogo.cPickle(rank))

    else
        log_game_error("MissionSystem:GetMissionStar", "dbid=%q;name=%s;mission=%d;difficulty=%d;UsedTime=%d;HpCount=%d", avatar.dbid, avatar.name, mission, difficulty, UsedTime, HpCount)
    end

    return star, point
end

function MissionSystem:AddFinishedMissions(avatar, arg1, arg2, UsedTime)

    log_game_debug("MissionSystem:AddFinishedMissions", "dbid=%q;name=%s;UsedTime=%s", avatar.dbid, avatar.name, UsedTime)

--    if avatar.tmp_data[public_config.TMP_DATA_KEY_IS_RANDOM_MISSION] then
--        mission = avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_ID_RANDOM_REAL]
--        difficulty = avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_DIFFICULTY_RANDOM_REAL]
--        log_game_debug("MissionSystem:AddFinishedMissions Random Mission", "dbid=%q;name=%s;mission=%d;difficulty=%d;UsedTime=%s", avatar.dbid, avatar.name, mission, difficulty, UsedTime)
--    end

    local MissionTempData = avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_DATA] or {}

    local mission = MissionTempData[2]
    local difficulty = MissionTempData[3]

    local _UsedTime = tonumber(UsedTime)

    --记录副本通关时间

    MissionTempData[1] = _UsedTime

    avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_DATA] = MissionTempData

    --剧情副本胜利后触发湮灭之门
    avatar.oblivionGateSystem:TriggerGate(1)

    --任务触发器
    avatar.taskSystem:UpdateTaskProgress(public_config.TASK_ASK_TYPE_MISSION_COMPLITE, {missionId = mission, difficulty = difficulty})

    --完成副本调用
    avatar:OnFinishFB(mission, difficulty)

    avatar.LastFinishedMissionTime = os.time()

    --离开副本时扣除体力
    local tbl = {}
    table.insert(tbl, tostring(mission))
    table.insert(tbl, tostring(difficulty))
    local MissionCfg = g_mission_mgr:getCfgById(table.concat(tbl, '_'))
    if MissionCfg and MissionCfg['energy'] then
        avatar:DeductEnergy(MissionCfg['energy'])
        log_game_debug("MissionSystem:AddFinishedMissions DeductEnergy", "dbid=%q;name=%s;missionId=%d;difficulty=%d;MissionCfg['energy']=%d;energy=%d", avatar.dbid, avatar.name, mission, difficulty, MissionCfg['energy'], avatar.energy)
    end

    if avatar:hasClient() then
        avatar.client.MissionResp(action_config.MSG_NOTIFY_TO_CLIENT_TO_UPLOAD_COMBO, {})
    end

    return 0

end

function MissionSystem:ResetMissionTimes(avatar, mission, difficulty)

    log_game_debug("MissionSystem:ResetMissionTimes", "dbid=%q;name=%s;mission=%d;difficulty=%d", avatar.dbid, avatar.name, mission, difficulty)

    local missionInfo = avatar.MissionTimes[mission]

    --玩家没玩过该难度的副本关卡
    if not missionInfo or not missionInfo[difficulty] then
        avatar.client.MissionResp(action_config.MSG_RESET_MISSION_TIMES, {-1})
        return 0
    else
        local VipTbl = g_vip_mgr:GetVipPrivileges(avatar.VipLevel)
        if not VipTbl then
            avatar.client.MissionResp(action_config.MSG_RESET_MISSION_TIMES, {-2})
            return 0
        end
        if not VipTbl['dailyHardModResetLimit'] then
            avatar.client.MissionResp(action_config.MSG_RESET_MISSION_TIMES, {-3})
            return 0
        end
        if avatar.MissionResetSubTimes >= VipTbl['dailyHardModResetLimit'] then
            avatar.client.MissionResp(action_config.MSG_RESET_MISSION_TIMES, {-4})
            return 0
        end

--        local times = avatar.MissionResetTimes[mission] or {}
--        local resetedTimes = times[difficulty] or 0

        local cfgData = g_priceList_mgr:GetPriceData(public_config.PRICE_LIST_MISSION_RESET_INDEX)

        if not cfgData or not cfgData.priceList then
            avatar.client.MissionResp(action_config.MSG_RESET_MISSION_TIMES, {-5})
            return 0
        end

        local diamondCost = cfgData.priceList[avatar.MissionResetSubTimes + 1]
        if not diamondCost then
            avatar.client.MissionResp(action_config.MSG_RESET_MISSION_TIMES, {-5})
            return 0
        end

        if diamondCost > avatar.diamond then
            avatar.client.MissionResp(action_config.MSG_RESET_MISSION_TIMES, {-6})
            return 0
        end

        --扣钱
        avatar:AddDiamond(-diamondCost, reason_def.mission_reset)

--        --累加已重置副本次数
--        resetedTimes = resetedTimes + 1
--        times[difficulty] = resetedTimes
--        avatar.MissionResetTimes[mission] = times

        --总次数累加1
        avatar.MissionResetSubTimes = avatar.MissionResetSubTimes + 1

        --记录时间
        avatar.LastResetMissionTime = os.time()

        --重置每天次数
        avatar.MissionTimes[mission][difficulty] = 0
        avatar.client.MissionResp(action_config.MSG_RESET_MISSION_TIMES, {0})
        return 0
    end
--    --修改了lua_table中的一个值，需要整体赋值才能设置为脏数据存盘
--    local MissionTimes = mogo.deepcopy1(avatar.MissionTimes)
--    avatar.MissionTimes = MissionTimes

end

function MissionSystem:GetResetTimes(avatar)
    log_game_debug("MissionSystem:GetResetTimes", "dbid=%q;name=%s;MissionResetSubTimes=%d", avatar.dbid, avatar.name, avatar.MissionResetSubTimes)

    if avatar:hasClient() then
        avatar.client.MissionResp(action_config.MSG_GET_RESET_TIMES, {avatar.MissionResetSubTimes})
    end

    return 0
end

--function MissionSystem:GetResetTimesByMission(avatar, mission, difficulty)
--    log_game_debug("MissionSystem:GetResetTimesByMission", "dbid=%q;name=%s;mission=%d;difficulty=%d", 
--                                                            avatar.dbid, avatar.name, mission, difficulty)
--
--    local times = avatar.MissionResetTimes[mission] or {}
--    local resetedTimes = times[difficulty] or 0
--
--    if avatar:hasClient() then
--        avatar.client.MissionResp(action_config.MSG_GET_RESET_TIMES_BY_MISSION, {resetedTimes})
--    end
--
--    return 0
--end

--function MissionSystem:MissionReq(msg_id, ...)
--    log_game_debug("MissionSystem:MissionReq", "msg_id=%d;dbid=%q;name=%s", 
--                                                         msg_id, avatar.dbid, avatar.name)
--
--    local func = self.msgMapping[msg_id]
--    if func ~= nil then
--        func(self, ...)
--    end
--
--
--end

function MissionSystem:GetStarsMission(avatar)

    log_game_debug("MissionSystem:GetStarsMission", "dbid=%q;name=%s", avatar.dbid, avatar.name)

    if avatar:hasClient() then
        avatar.client.MissionResp(action_config.MSG_GET_STARS_MISSION, avatar.MissionStars)
    end

    return 0
end

function MissionSystem:GetMissionTimes(avatar)

    log_game_debug("MissionSystem:GetMissionTimes", "dbid=%q;name=%s;MissionTimes=%s", avatar.dbid, avatar.name, mogo.cPickle(avatar.MissionTimes))

    avatar.client.MissionResp(action_config.MSG_GET_MISSION_TIMES, avatar.MissionTimes)

    return 0
end

function MissionSystem:GetFinishedMissions(avatar)

    log_game_debug("MissionSystem:GetFinishedMissions", "dbid=%q;name=%s;MissionStars=%s", 
                                                         avatar.dbid, avatar.name, mogo.cPickle(avatar.MissionStars))

    if avatar:hasClient() then
        avatar.client.MissionResp(action_config.MSG_GET_FINISHED_MISSIONS, avatar.MissionStars)
    end

    return 0
end

function MissionSystem:SpawnPointStart(avatar, SpawnPointId)
--    log_game_debug("MissionSystem:SpawnPointStart", "dbid=%q;name=%s;SpawnPointId=%d", avatar.dbid, avatar.name, SpawnPointId)

--    local tbl = {}
--    table.insert(tbl, 'SpaceLoader')
--    table.insert(tbl, tostring(avatar.sceneId))
--    table.insert(tbl, tostring(avatar.imap_id))

    if mogo.stest(avatar.state, state_config.DEATH_STATE) > 0 then
        log_game_warning(" MissionSystem:SpawnPointStart player death", "dbid=%q;name=%s;state=%s", avatar.dbid, avatar.name, avatar.state)
    else
        local SpaceLoader = avatar.SpaceLoaderMb
        if SpaceLoader then
            SpaceLoader.SpawnPointEvent(mission_config.SPAWNPOINT_START, avatar.dbid, avatar.map_x, avatar.map_y, SpawnPointId)
        end
    end

    return 0
end

function MissionSystem:SpawnPointStop(avatar, SpawnPointId)
    log_game_debug("MissionSystem:SpawnPointStop", "dbid=%q;name=%s;SpawnPointId=%d", 
                                                             avatar.dbid, avatar.name, SpawnPointId)

--    local tbl = {}
--    table.insert(tbl, 'SpaceLoader')
--    table.insert(tbl, tostring(avatar.sceneId))
--    table.insert(tbl, tostring(avatar.imap_id))

    local SpaceLoader = avatar.SpaceLoaderMb
    if SpaceLoader then
        SpaceLoader.SpawnPointEvent(mission_config.SPAWNPOINT_STOP, avatar.map_x, avatar.map_y, SpawnPointId)
    end

    return 0
end

function MissionSystem:GetMissionRewards(avatar)
    log_game_debug("MissionSystem:GetMissionRewards", "dbid=%q;name=%s", avatar.dbid, avatar.name)

    local SpaceLoader = avatar.SpaceLoaderMb
    if SpaceLoader then
        SpaceLoader.GetMissionRewards(avatar.dbid)
    end

    return 0
end

function MissionSystem:ClientMissionInfo(avatar, arg1, arg2, ClientInfo)
--    log_game_debug("MissionSystem:ClientMissionInfo", "name=%s;dbid=%q;ClientInfo=%s",
--                                                                avatar.name, avatar.dbid, ClientInfo)
    avatar.ClientMissionInfo = ClientInfo

--    avatar.client.MissionResp(mission_config.MSG_CLIENT_MISSION_INFO, {avatar.ClientMissionInfo})

    return 0
end

function MissionSystem:onGetCell(avatar)
    if avatar:hasClient() then
        log_game_debug("MissionSystem:onGetCell", "name=%s;dbid=%q;client=%s", avatar.name, avatar.dbid, mogo.cPickle(avatar.client))
    else
        log_game_debug("MissionSystem:onGetCell", "name=%s;dbid=%q", avatar.name, avatar.dbid)
    end

    return 0
end

function MissionSystem:onClientDeath(avatar)
    log_game_debug("MissionSystem:onClientDeath", "name=%s;dbid=%q", avatar.name, avatar.dbid)

    --客户端断线后通知关卡副本
--    local tbl = {}
--    table.insert(tbl, 'SpaceLoader')
--    table.insert(tbl, tostring(avatar.sceneId))
--    table.insert(tbl, tostring(avatar.imap_id))

    local SpaceLoader = avatar.SpaceLoaderMb
    if SpaceLoader then
        SpaceLoader.onClientDeath(avatar.dbid)
    else
        log_game_error("MissionSystem:onClientDeath", "dbid=%q;name=%s", avatar.dbid, avatar.name)
    end

    --服务器短线时把东西发给玩家
    self:GetMissionRandomReward(avatar)

    return 0
end

function MissionSystem:AddRewardItems(avatar, arg1, arg2, ItemList)
    log_game_debug("MissionSystem:AddRewardItems", "name=%s;dbid=%q;ItemList=%s",
                                                             avatar.name, avatar.dbid, ItemList)

    local ItemTable = mogo.cUnpickle(ItemList)
--    if ItemList and ItemList ~= '' then
--        local ItemTable = lua_util.split_str_2_dict(ItemList)
--    end
    local attach = {}
    for id, count in pairs(ItemTable) do
        if avatar.inventorySystem:IsSpaceEnough(id, count) then
            --背包位置足够
            avatar:AddItem(id, count, reason_def.fuben_drop)
        else
            attach[id] = count
            --[[
            lua_util.globalbase_call('MailMgr', 'SendEx', "关卡奖励",                  --title
                                                          "关卡奖励",                  --to
                                                          "关卡奖励",                  --text
                                                          "关卡奖励",                  --from
                                                          os.time(),                --time
                                                          {[id]=count,},            --道具
                                                          {[1]=avatar.dbid,}, --收件者的dbid列表
                                                          reason_def.mission_treasure
                                                        )
            ]]
        end
    end
--    if lua_util.get_table_real_count(attach) > 0 then
    if next(attach) then
        log_game_debug("MissionSystem:AddRewardItems send mail", "dbid=%q;name=%s;attach=%s", avatar.dbid, avatar.name, mogo.cPickle(attach))
        globalbase_call('MailMgr', 'SendIdEx', g_text_id.MISSION_MAIL_REWARD_TITLE,  --title
                                                      avatar.name,                            --to
                                                      g_text_id.MISSION_MAIL_REWARD_TEXT,     --text
                                                      g_text_id.MISSION_MAIL_REWARD_FROM,     --from
                                                      os.time(),                              --time
                                                      attach,                                 --道具
                                                      {[1]=avatar.dbid,}, --收件者的dbid列表
                                                      {},
                                                      reason_def.mission_treasure
                                                    )
    end
    return 0
end

function MissionSystem:GetMissionDrops(avatar, mission)
    log_game_debug("MissionSystem:GetMissionDrops", "name=%s;dbid=%q;mission=%d", avatar.name, avatar.dbid, mission)

    local tblRewardItemCfg = g_mission_mgr:getRewardItemCfg(mission, avatar.vocation)
    if avatar:hasClient() then
        avatar.client.MissionResp(action_config.MSG_GET_MISSION_DROPS, tblRewardItemCfg)
    end
    return 0
end

function MissionSystem:AddFriendDegreeB2C(avatar, arg1, arg2, mercenaryDbid)
    log_game_debug("MissionSystem:AddFriendDegreeB2C", "name=%s;dbid=%q;mercenaryDbid=%s",
                                                        avatar.name, avatar.dbid, mercenaryDbid)
    avatar:AddFriendDegree(tonumber(mercenaryDbid), g_GlobalParamsMgr:GetParams('mission_success_degree', 100))

    return 0
end

function MissionSystem:OnZeroPointTimer(avatar)
    log_game_debug("MissionSystem:OnZeroPointTimer", "name=%s;dbid=%q;MissionTimes=%s;MissionResetSubTimes=%d;MwsyInfo=%s", avatar.name, avatar.dbid, mogo.cPickle(avatar.MissionTimes), avatar.MissionResetSubTimes, mogo.cPickle(self.MwsyInfo))

    avatar.MissionTimes = {}
    avatar.MissionResetSubTimes = 0

    avatar.MwsyInfo = {}

    return 0
end

function MissionSystem:GetSweepTimes(avatar)

    local VipTbl = g_vip_mgr:GetVipPrivileges(avatar.VipLevel)
    if not VipTbl then
        if avatar:hasClient() then
            avatar.client.MissionResp(action_config.MSG_GET_SWEEP_TIMES, {0})
        end
        return 0
    end

    local UsedVipSweepTimes = avatar.VipRealState[public_config.DAILY_RAID_SWEEP_TIMES] or 0
    local times = (VipTbl['dailyRaidSweepLimit'] or 0) - UsedVipSweepTimes
    if avatar:hasClient() then
        avatar.client.MissionResp(action_config.MSG_GET_SWEEP_TIMES, {math.max(times, 0)})
    end
    return 0
end

function MissionSystem:SweepMission(avatar, mission, difficulty)
    log_game_debug("MissionSystem:SweepMission", "name=%s;dbid=%q;mission=%d;difficulty=%d;VipLevel=%d", avatar.name, avatar.dbid, mission, difficulty, avatar.VipLevel)

--    local VipLevel = g_vip_mgr:GetVipLevel(avatar.chargeSum)
--    if not VipLevel then
--        avatar.client.MissionResp(action_config.MSG_SWEEP_MISSION, {1})
--        return
--    end

    local VipTbl = g_vip_mgr:GetVipPrivileges(avatar.VipLevel)
    if not VipTbl then
        avatar.client.MissionResp(action_config.MSG_SWEEP_MISSION, {2})
        return 0
    end

    local UsedVipSweepTimes = avatar.VipRealState[public_config.DAILY_RAID_SWEEP_TIMES] or 0
    if UsedVipSweepTimes >= (VipTbl['dailyRaidSweepLimit'] or 0) then
        avatar.client.MissionResp(action_config.MSG_SWEEP_MISSION, {3})
        return 0
    end

    --判断体力值是否足够
    local MissionCfg = g_mission_mgr:getCfgById(tostring(mission) .. "_" .. tostring(difficulty))
    if MissionCfg and MissionCfg['energy'] then
        if avatar.energy < MissionCfg['energy'] then
            avatar.client.MissionResp(action_config.MSG_SWEEP_MISSION, {4})
            return 0
        end
    end

    --判断副本的进入次数
    if MissionCfg and avatar.MissionTimes[mission] and avatar.MissionTimes[mission][difficulty] then
        if avatar.MissionTimes[mission][difficulty] >= MissionCfg['dayTimes'] then
            avatar:ShowTextID(CHANNEL.TIPS, error_code.SWEEP_MISSION_DAILY_TIMES)
            return 0
        end
    end

    --之前没打过该难度的副本，不能扫荡
    if not avatar.MissionStars[mission] or 
       not avatar.MissionStars[mission][difficulty] or 
       avatar.MissionStars[mission][difficulty] <= mission_config.MISSION_VALUATION_NOT_PASS then
        avatar.client.MissionResp(action_config.MSG_SWEEP_MISSION, {5})
        return 0
    end

    --判断进入次数

    --扣除体力值
    if MissionCfg and MissionCfg['energy'] then
        avatar:DeductEnergy(MissionCfg['energy'])
    end

    --每日已扫荡次数加1
    UsedVipSweepTimes = UsedVipSweepTimes + 1
    avatar.VipRealState[public_config.DAILY_RAID_SWEEP_TIMES] = UsedVipSweepTimes

--    local VipRealState = mogo.deepcopy1(avatar.VipRealState)
--    avatar.VipRealState = VipRealState

    --剧情副本胜利后触发湮灭之门
    avatar.oblivionGateSystem:TriggerGate(1)

    --记录时间戳
    avatar.LastFinishedMissionTime = os.time()

    --完成副本调用
    avatar:OnFinishFB(mission, difficulty)

    --副本扫荡增加挑战次数
    self:AddMissionTimes(avatar, mission, difficulty)

    --计算副本奖励

--    local Reward = g_mission_mgr:getRewardInfo(mission, difficulty, avatar.vocation)

    local Reward =  avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_SWEEP_REWARD] or g_mission_mgr:getRewardInfo(mission, difficulty, avatar.vocation)

    if Reward then
        --向客户端下发怪物列表
        local MonsterTbl = Reward[1] or {}

        local ItemTbl = Reward[2] or {}
        local attach = {}
        for id, count in pairs(ItemTbl) do
            if avatar.inventorySystem:IsSpaceEnough(id, count) then
                --背包位置足够
                avatar.inventorySystem:AddItems(id, count)
            else
                attach[id] = count
            end

--            local itemCfg = g_itemdata_mgr:GetItem(public_config.ITEM_TYPE_CFG_TBL, id)
--            if itemCfg and itemCfg['quality'] then
--                if itemCfg['quality'] == public_config.ITEM_QUALITY_PURPLE then
--                    global_data:ShowTextID(CHANNEL.WORLD, mission_config.RANDOM_REWARD_MSG_PURPLE, {avatar.name, ['item_id'] = id})  --给所有人发消息改为从 global_data
--                    log_game_debug("MissionSystem:SweepMission world msg", "dbid=%q;name=%s;itemId=%q", avatar.dbid, avatar.name, id)
--                elseif itemCfg['quality'] == public_config.ITEM_QUALITY_ORANGE then
--                    global_data:ShowTextID(CHANNEL.WORLD, mission_config.RANDOM_REWARD_MSG_ORANGE, {avatar.name, ['item_id'] = id})  --给所有人发消息改为从 global_data
--                    log_game_debug("MissionSystem:SweepMission world msg", "dbid=%q;name=%s;itemId=%q", avatar.dbid, avatar.name, id)
--                end
--            end
        end
--        if lua_util.get_table_real_count(attach) > 0 then
        if next(attach) then
            log_game_debug("MissionSystem:SweepMission send mail", "dbid=%q;name=%s;attach=%s", avatar.dbid, avatar.name, mogo.cPickle(attach))
            globalbase_call('MailMgr', 'SendIdEx', g_text_id.MISSION_SWEEP_MAIL_REWARD_TITLE,  --title
                                                          avatar.name,                              --to
                                                          g_text_id.MISSION_SWEEP_MAIL_REWARD_TEXT, --text
                                                          g_text_id.MISSION_MAIL_REWARD_FROM, --from
                                                          os.time(),                              --time
                                                          attach,                                 --道具
                                                          {[1]=avatar.dbid,}, --收件者的dbid列表
                                                          {},
                                                          reason_def.mission_treasure
                                                        )
        end
        if avatar:hasClient() then
            avatar.client.MissionResp(action_config.MSG_SWEEP_MISSION, {0})
        end

        --金币奖励
        if Reward[3] and Reward[3] > 0 then
            avatar:AddGold(Reward[3], reason_def.mission)
        end

        --经验奖励
        if Reward[4] and Reward[4] > 0 then
            avatar:AddExp(Reward[4], reason_def.mission)
        end

        --成功领取以后，把临时奖励删掉
        avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_SWEEP_REWARD] = nil

        --获取翻牌奖励
        self:GetMissionRandomReward(avatar)

        log_game_debug("MissionSystem:SweepMission", "name=%s;dbid=%q;mission=%d;difficulty=%d;Reward=%s", avatar.name, avatar.dbid, mission, difficulty, mogo.cPickle(Reward))
    else
        log_game_error("MissionSystem:SweepMission", "name=%s;dbid=%q;mission=%d;difficulty=%d", avatar.name, avatar.dbid, mission, difficulty)
    end

    return 0
end

function MissionSystem:GetMissionSweepList(avatar, mission, difficulty)
    log_game_debug("MissionSystem:GetMissionSweepList", "name=%s;dbid=%q;mission=%d;difficulty=%d", avatar.name, avatar.dbid, mission, difficulty)

    local VipTbl = g_vip_mgr:GetVipPrivileges(avatar.VipLevel)
    if not VipTbl then
        avatar.client.MissionResp(action_config.MSG_SWEEP_MISSION, {2})
        return 0
    end

    local UsedVipSweepTimes = avatar.VipRealState[public_config.DAILY_RAID_SWEEP_TIMES] or 0
    if UsedVipSweepTimes >= (VipTbl['dailyRaidSweepLimit'] or 0) then
        avatar.client.MissionResp(action_config.MSG_SWEEP_MISSION, {3})
        return 0
    end

    --判断体力值是否足够
    local MissionCfg = g_mission_mgr:getCfgById(tostring(mission) .. "_" .. tostring(difficulty))
    if MissionCfg and MissionCfg['energy'] then
        if avatar.energy < MissionCfg['energy'] then
            avatar.client.MissionResp(action_config.MSG_SWEEP_MISSION, {4})
            return 0
        end
    end

    --判断副本的进入次数
    if MissionCfg and avatar.MissionTimes[mission] and avatar.MissionTimes[mission][difficulty] then
        if avatar.MissionTimes[mission][difficulty] >= MissionCfg['dayTimes'] then
            avatar:ShowTextID(CHANNEL.TIPS, error_code.SWEEP_MISSION_DAILY_TIMES)
            return 0
        end
    end

    --之前没打过该难度的副本，不能扫荡
    if not avatar.MissionStars[mission] or 
       not avatar.MissionStars[mission][difficulty] or 
       avatar.MissionStars[mission][difficulty] <= mission_config.MISSION_VALUATION_NOT_PASS then
        avatar.client.MissionResp(action_config.MSG_SWEEP_MISSION, {5})
        return 0
    end

    if avatar:hasClient() then
        local Reward = g_mission_mgr:getRewardInfo(mission, difficulty, avatar.vocation)
        if Reward then
            --向客户端下发怪物列表
            local MonsterTbl = Reward[1] or {}
            local ItemTbl = Reward[2] or {}

            --获取玩家的副本评分，用于算出玩家的
            local star = avatar.MissionStars[mission][difficulty]

            --生成翻牌数据
            --每次生成5张牌，然后根据评价的次数决定获得几张
            local RandomReward = {}
            RandomReward = self:GenMissionRandomReward(mission, difficulty, avatar.vocation)
            local times = g_mission_mgr:getMissionRandomRewardTimes(star)
            local playerRandomReward = {}
            for i=1, times do
                table.insert(playerRandomReward, RandomReward[i])
            end

--            for _, v in pairs(playerRandomReward) do
--                for itemId, count in pairs(v) do
--                    if itemId == public_config.EXP_ID then
--                        Reward[4] = (Reward[4] or 0) + count
--                    elseif itemId == public_config.GOLD_ID then
--                        Reward[3] = (Reward[3] or 0) + count
--                    elseif itemId == public_config.DIAMOND_ID then
--                        --                        avatar:AddDiamond(count, reason_def.mission_random_reward)
--                    else
--                        ItemTbl[itemId] = (ItemTbl[itemId] or 0) + count
--                        Reward[2] = ItemTbl
--                    end
--                end
--            end

            avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_SWEEP_REWARD] = Reward
            avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_RANDOM_REWARD] = playerRandomReward

            log_game_debug("MissionSystem:GetMissionSweepList", "name=%s;dbid=%q;mission=%d;difficulty=%d;Reward=%s", avatar.name, avatar.dbid, mission, difficulty, mogo.cPickle(Reward))
            avatar.client.MissionResp(action_config.MSG_GET_MISSION_SWEEP_LIST, {MonsterTbl, ItemTbl,})
        end
    end

    return 0
end

function MissionSystem:OnClientGetBase(avatar)

    log_game_debug("MissionSystem:OnClientGetBase", "dbid=%q;name=%s", avatar.dbid, avatar.name)

    local now = os.time()

    local Today = lua_util.get_yyyymmdd(now)
    local LastFailTime = avatar.LastFinishedMissionTime or 0
 
    if lua_util.get_yyyymmdd(LastFailTime) ~= Today then
--        avatar.LastFinishedMissionTime = os.time()
        avatar.MissionTimes = {}
        avatar.MissionResetSubTimes = 0
        log_game_debug("MissionSystem:OnClientGetBase clear mission times", "dbid=%q;name=%s", avatar.dbid, avatar.name)
    end

--    --获取下一个8点的时间戳
--    local next8time = lua_util.get_left_secs_until_next_hhmiss(8, 0, 0) + now
--    --获取上一个8点的时间戳
--    local last8time = next8time - 24*3600
    local LastResetMissionTime = avatar.LastResetMissionTime or 0
    if lua_util.get_yyyymmdd(LastResetMissionTime) ~= Today then
        avatar.MissionResetSubTimes = 0
--        avatar.MissionResetTimes = {}
        log_game_debug("MissionSystem:OnClientGetBase clear mission reset times", "dbid=%q;name=%s", avatar.dbid, avatar.name)
    end

    --计算总共获得s评分的关卡个数
    local count = 0
    for _, v in pairs(avatar.MissionStars) do
        for _, star in pairs(v) do
            if star >= mission_config.MISSION_VALUATION_S then
                count = count + 1
            end
        end
    end

    avatar.MissionSSum = self:GetMissionSSum(avatar)

    --计算是否清空迷雾深渊数据
    local LastMWSYMissionTime = avatar.MwsyInfo[mission_config.MWSY_MISSION_LAST_TIME] or 0
    if Today ~= lua_util.get_yyyymmdd(LastMWSYMissionTime) then
        log_game_debug("MissionSystem:OnClientGetBase clear mwsy", "dbid=%q;name=%s;LastMWSYMissionTime=%d", avatar.dbid, avatar.name, LastMWSYMissionTime)
        avatar.MwsyInfo = {}
    end

    return 0
end

function MissionSystem:GetMissionSubTimes(avatar)
    local SubTimes = 0
    for _, v in pairs(avatar.MissionTimes) do
        for _, times in pairs(v) do
            SubTimes = times + SubTimes
        end
    end
    return SubTimes
end

function MissionSystem:TriggerMwsyByTask(avatar, completeTaskId)

    if avatar.level > g_GlobalParamsMgr:GetParams('mwsyTriggerLevel', 20) then
        return
    elseif avatar.MwsyInfo[mission_config.MWSY_MISSION_IS_FINISH] then
        return
    else
--        local flag = false
        local Tasks = g_GlobalParamsMgr:GetParams('mwsyTriggerTasks', {})
        for _, TaskId in pairs(Tasks) do
            if TaskId == completeTaskId then
                --玩家完成了指定的任务
                --成功触发了迷雾深渊
--                if avatar.MwsyInfo[mission_config.MWSY_MISSION_IS_FINISH] then
--                    return
--                end

                avatar.MwsyInfo[mission_config.MWSY_MISSION_DIFFICULTY] = mission_config.MWSY_MISSION_DIFFICULTY_JD
                avatar.MwsyInfo[mission_config.MWSY_MISSION_IS_FINISH] = 0
                avatar.MwsyInfo[mission_config.MWSY_MISSION_LAST_TIME] = os.time()

                if avatar:hasClient() then
                    avatar.client.MissionResp(action_config.MSG_MWSY_MISSION_NOTIFY_CLIENT, {avatar.MwsyInfo[mission_config.MWSY_MISSION_DIFFICULTY],})
                end
            end
        end
    end
end

--在该方法里面触发迷雾深渊
function MissionSystem:TriggerMwsy(avatar)

    if avatar.level <=  g_GlobalParamsMgr:GetParams('mwsyTriggerLevel', 20) then
        return
    elseif avatar.MwsyInfo[mission_config.MWSY_MISSION_IS_FINISH] then
        return
    end

    local SubTimes = self:GetMissionSubTimes(avatar)
    local Rate = 0

    local mwsyRate = g_GlobalParamsMgr:GetParams('mwsyRate', {})
    local mwsyMinTimes = g_GlobalParamsMgr:GetParams('mwsyMinTimes', 1)
    local mwsyMaxTimes = g_GlobalParamsMgr:GetParams('mwsyMaxTimes', 1)

    if SubTimes <= mwsyMinTimes then
        Rate = mwsyRate[mwsyMinTimes] / 10000
    elseif SubTimes >= mwsyMaxTimes then
        Rate = mwsyRate[mwsyMaxTimes] / 10000
    else
        Rate = mwsyRate[SubTimes] / 10000
    end

    log_game_debug("MissionSystem:TriggerMwsy", "dbid=%q;name=%s;SubTimes=%d;mwsyRate=%s;mwsyMinTimes=%d;mwsyMaxTimes=%d;Rate=%q", avatar.dbid, avatar.name, SubTimes, mogo.cPickle(mwsyRate), mwsyMinTimes, mwsyMaxTimes, Rate)

    if lua_util.prob(Rate) then
        --成功触发了迷雾深渊
        avatar.MwsyInfo[mission_config.MWSY_MISSION_DIFFICULTY] = mission_config.MWSY_MISSION_DIFFICULTY_JD
        avatar.MwsyInfo[mission_config.MWSY_MISSION_IS_FINISH] = 0
        avatar.MwsyInfo[mission_config.MWSY_MISSION_LAST_TIME] = os.time()

        if avatar:hasClient() then
            avatar.client.MissionResp(action_config.MSG_MWSY_MISSION_NOTIFY_CLIENT, {avatar.MwsyInfo[mission_config.MWSY_MISSION_DIFFICULTY],})
        end
    end

    return 0
end

function MissionSystem:trigger_mwsy(avatar)
    --成功触发了迷雾深渊
    avatar.MwsyInfo[mission_config.MWSY_MISSION_DIFFICULTY] = mission_config.MWSY_MISSION_DIFFICULTY_JD
    avatar.MwsyInfo[mission_config.MWSY_MISSION_IS_FINISH] = 0
    avatar.MwsyInfo[mission_config.MWSY_MISSION_LAST_TIME] = os.time()

    if avatar:hasClient() then
        avatar.client.MissionResp(action_config.MSG_MWSY_MISSION_NOTIFY_CLIENT, {avatar.MwsyInfo[mission_config.MWSY_MISSION_DIFFICULTY],})
    end
end

--获取迷雾深渊的信息
function MissionSystem:GetMwsyInfo(avatar)
    if avatar:hasClient() then
        log_game_debug("MissionSystem:GetMwsyInfo", "dbid=%q;name=%s;MwsyInfo=%s", avatar.dbid, avatar.name, mogo.cPickle(avatar.MwsyInfo))
        avatar.client.MissionResp(action_config.MSG_MWSY_MISSION_GET_INFO, {avatar.MwsyInfo[mission_config.MWSY_MISSION_DIFFICULTY], avatar.MwsyInfo[mission_config.MWSY_MISSION_IS_FINISH]})
    end

    return 0
end

function MissionSystem:EnterMwsy(avatar)

    log_game_debug("MissionSystem:EnterMwsy", "dbid=%q;name=%s;MwsyInfo=%s", avatar.dbid, avatar.name, mogo.cPickle(avatar.MwsyInfo))

    if avatar.MwsyInfo[mission_config.MWSY_MISSION_IS_FINISH] == 0 and avatar.MwsyInfo[mission_config.MWSY_MISSION_DIFFICULTY] > 0 and avatar.MwsyInfo[mission_config.MWSY_MISSION_DIFFICULTY] <= mission_config.MWSY_MISSION_DIFFICULTY_DY then

        local cfg = g_mission_mgr:GetMwsytMissionDifficulty(avatar.level, avatar.MwsyInfo[mission_config.MWSY_MISSION_DIFFICULTY])
        local mission = cfg[1]
        local difficulty = cfg[2]

        log_game_debug("MissionSystem:EnterMwsy", "dbid=%q;name=%s;MwsyInfo=%s;mission=%d;difficulty=%d", avatar.dbid, avatar.name, mogo.cPickle(avatar.MwsyInfo), mission, difficulty)

        self:EnterMissionMwsy(avatar, mission, difficulty)

        --记录玩家是在迷雾深渊
        avatar.tmp_data[public_config.TMP_DATA_KEY_IS_MWSY] = 1
    end

    return 0
end

function MissionSystem:GetMissionSSum(avatar)
    --计算总共获得s评分的关卡个数
    local count = 0
    for _, v in pairs(avatar.MissionStars) do
        for _, star in pairs(v) do
            if star >= mission_config.MISSION_VALUATION_S then
                count = count + 1
            end
        end
    end

    return count
end

function MissionSystem:GetMissionTreasureRewards(avatar)

    log_game_debug("MissionSystem:GetMissionTreasureRewards", "dbid=%q;name=%s;MissionTreasureRewards=%s", avatar.dbid, avatar.name, mogo.cPickle(avatar.MissionTreasureRewards))

    if avatar:hasClient() then
        local result = {}
        for id, _ in pairs(avatar.MissionTreasureRewards) do
            table.insert(result, id)
        end
        avatar.client.MissionResp(action_config.MSG_GET_MISSION_TREASURE_REWARDS, result)
    end

    return 0
end

function MissionSystem:Revive(avatar)

    log_game_debug("MissionSystem:Revive", "dbid=%q;name=%s", avatar.dbid, avatar.name)

    if avatar.sceneId ~= g_GlobalParamsMgr:GetParams("tower_defence_scene_id", 30002) then
        --如果玩家不再塔防副本
        --判断是否有复活道具
        if avatar.inventorySystem:GetItemCountsInBag(g_GlobalParamsMgr:GetParams('revive_item', 10004)) == 0 then
            if avatar:hasClient() then
                avatar.client.MissionResp(action_config.MSG_REVIVE, {-1})
            end
            return 0
        end
    else
        --如果玩家在塔防副本
        --
        local price = 0
        local cfg = g_priceList_mgr:GetPriceData(public_config.PRICE_LIST_TOWER_DEFENCE_REVIVE_INDEX)
        if cfg then
            local priceList = cfg['priceList'] or {}
            price = priceList[avatar.ReviveTimes + 1] or 0
            if avatar.diamond < price then
                if avatar:hasClient() then
                    avatar.client.MissionResp(action_config.MSG_REVIVE, {-4})
                end
                return 0
            end
        end

    end

    if avatar:HasCell() then
        avatar.cell.ReviveReq()
    end

    return 0
end

function MissionSystem:ReviveSuccess(avatar)
    log_game_debug("MissionSystem:ReviveSuccess", "dbid=%q;name=%s", avatar.dbid, avatar.name)

     if avatar.sceneId ~=  g_GlobalParamsMgr:GetParams("tower_defence_scene_id", 30002) then
         if avatar.inventorySystem:GetItemCountsInBag(g_GlobalParamsMgr:GetParams('revive_item', 10004)) == 0 then
             if avatar:hasClient() then
                 avatar.client.MissionResp(action_config.MSG_REVIVE, {-1})
             end
             return 0
         end

         avatar.ReviveTimes = avatar.ReviveTimes + 1
         avatar:DelItem(g_GlobalParamsMgr:GetParams('revive_item', 10004), 1, reason_def.revive)
     else
         --如果玩家在塔防副本
         --
         local price = 0
         local cfg = g_priceList_mgr:GetPriceData(public_config.PRICE_LIST_TOWER_DEFENCE_REVIVE_INDEX)
         if cfg then
             local priceList = cfg['priceList'] or {}
             price = priceList[avatar.ReviveTimes + 1] or 0
             if avatar.diamond < price then
                 if avatar:hasClient() then
                     avatar.client.MissionResp(action_config.MSG_REVIVE, {-4})
                 end
                 return 0
             end
         end

         avatar:AddDiamond(-price, reason_def.revive)
         avatar.ReviveTimes = avatar.ReviveTimes + 1
     end

    if avatar:hasClient() then
        log_game_debug("MissionSystem:ReviveSuccess result", "dbid=%q;name=%s", avatar.dbid, avatar.name)
        avatar.client.MissionResp(action_config.MSG_REVIVE, {0})
    end

    return 0
end

function MissionSystem:GetReviveTimes(avatar)
    log_game_debug("MissionSystem:GetReviveTimes", "dbid=%q;name=%s;ReviveTimes=%d", avatar.dbid, avatar.name, avatar.ReviveTimes)

    if avatar:hasClient() then
        avatar.client.MissionResp(action_config.MSG_GET_REVIVE_TIMES, {avatar.ReviveTimes})
    end

    return 0
end

function MissionSystem:GetMissionRecord(avatar, mission, difficulty)
    log_game_debug("MissionSystem:GetMissionRecord", "dbid=%q;name=%s;mission=%d;difficulty=%d", avatar.dbid, avatar.name, mission, difficulty)

    globalbase_call("MissionMgr", "GetMissionRecord", avatar.base_mbstr, mission, difficulty)

    return 0
end

function MissionSystem:GetAcquiredMissionBossTreasure(avatar)
    log_game_debug("MissionSystem:GetAcquiredMissionBossTreasure", "dbid=%q;name=%s", avatar.dbid, avatar.name)

    local result = {}
    for k, _ in pairs(avatar.MissionBossTreasure) do
        table.insert(result, k)
    end

    if avatar:hasClient() then
        avatar.client.MissionResp(action_config.MSG_GET_ACQUIRED_MISSION_BOSS_TREASURE, result)
    end

    return 0
end



function MissionSystem:GetMissionBossTreasure(avatar, treasureId)
--    log_game_debug("MissionSystem:GetMissionBossTreasure", "dbid=%q;name=%s;treasureId=%d", avatar.dbid, avatar.name, treasureId)

    local treasure = g_mission_mgr:getBossTreasure(treasureId)
    if treasure then
        log_game_debug("MissionSystem:GetMissionBossTreasure", "dbid=%q;name=%s;treasureId=%d;mission=%d;difficulty=%d;MissionStars=%s", avatar.dbid, avatar.name, treasureId, treasure['mission'], treasure['difficulty'], mogo.cPickle(avatar.MissionStars))
        if not avatar.MissionStars[treasure['mission']] then
            if avatar:hasClient() then
                avatar.client.MissionResp(action_config.MSG_GET_MISSION_BOSS_TREASURE, {-1})
            end
        elseif not avatar.MissionStars[treasure['mission']][treasure['difficulty']] then
            if avatar:hasClient() then
                avatar.client.MissionResp(action_config.MSG_GET_MISSION_BOSS_TREASURE, {-1})
            end
        elseif avatar.MissionStars[treasure['mission']][treasure['difficulty']] < mission_config.MISSION_VALUATION_S then
--            log_game_error("MissionSystem:GetMissionBossTreasure", "dbid=%q;name=%s;treasureId=%d;mission=%d;difficulty=%d;star=%d", avatar.dbid, avatar.name, treasureId, treasure['mission'], treasure['difficulty'], avatar.MissionStars[treasure['mission']][treasure['difficulty']])
            if avatar:hasClient() then
                avatar.client.MissionResp(action_config.MSG_GET_MISSION_BOSS_TREASURE, {-1})
            end
        elseif avatar.MissionBossTreasure[treasureId] then
            if avatar:hasClient() then
                avatar.client.MissionResp(action_config.MSG_GET_MISSION_BOSS_TREASURE, {-2})
            end
        else

            local Reward = treasure['reward']
            local ItemsCanNotInBag = {}
            local flag1 = false

            for id, count in pairs(Reward) do

                if id == 1 then
                    avatar:AddExp(count, reason_def.missionBoss)
                elseif id == 2 then
                    avatar:AddGold(count, reason_def.missionBoss)
                elseif id == 3 then
                    avatar:AddDiamond(count, reason_def.missionBoss)
                else
                    if avatar.inventorySystem:IsSpaceEnough(id, count) then
                        --背包位置足够
                        avatar.inventorySystem:AddItems(id, count)
                    else
                        local ItemCount = ItemsCanNotInBag[id] or 0
                        ItemsCanNotInBag[id] = ItemCount + count
                        flag1 = true
                    end
                end
            end

            if flag1 then

                log_game_debug("MissionSystem:GetMissionBossTreasure send mail", "dbid=%q;name=%s;ItemsCanNotInBag=%s", avatar.dbid, avatar.name, mogo.cPickle(ItemsCanNotInBag))

                globalbase_call('MailMgr', 'SendIdEx', g_text_id.MISSION_MAIL_BOSS_TREASURE,   --title
                    avatar.name,                                                             --to
                    g_text_id.MISSION_MAIL_BOSS_TREASURE,                                    --text
                    g_text_id.MISSION_MAIL_BOSS_TREASURE,                                    --from
                    os.time(),                                                               --time
                    ItemsCanNotInBag,                                                        --道具
                    {[1]=avatar.dbid,},                                                      --收件者的dbid列表
                    {},
                    reason_def.missionBoss
                )
            end

            avatar.MissionBossTreasure[treasureId] = 1

            log_game_debug("MissionSystem:GetMissionBossTreasure success", "dbid=%q;name=%s;treasureId=%d", avatar.dbid, avatar.name, treasureId)

            if avatar:hasClient() then
                avatar.client.MissionResp(action_config.MSG_GET_MISSION_BOSS_TREASURE, {0})
            end
        end
    end

    return 0
end


gMissionSystem = MissionSystem
return gMissionSystem


