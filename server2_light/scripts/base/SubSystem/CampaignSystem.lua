
require "action_config"
require "ActivityData"
require "error_code"
require "global_data"
require "avatar_level_data"
require "reason_def"

local log_game_debug = lua_util.log_game_debug
local log_game_error = lua_util.log_game_error
local log_game_warning = lua_util.log_game_warning
local globalbase_call = lua_util.globalbase_call

CampaignSystem = {}
CampaignSystem.__index = CampaignSystem

CampaignSystem.msgMapping = {
    --客户端到base的请求
    [action_config.MSG_CAMPAIGN_GET_ONLINE_FRIENDS] = "GetOnlineFriends",       --获取在线好友，生成可邀请列表
    [action_config.MSG_CAMPAIGN_INVITE]             = "CampaignInvite",         --邀请指定玩家参加活动
    [action_config.MSG_CAMPAIGN_INVITED_RESP]       = "CampaignInvitedResp",   --被邀请方回应邀请
    [action_config.MSG_CAMPAIGN_JOIN]               = "CampaignJoin",           --参加指定ID的活动
    [action_config.MSG_CAMPAIGN_LEAVE]              = "CampaignLeave",          --离开匹配队列
    [action_config.MSG_CAMPAIGN_GET_LEFT_TIMES]     = "CampaignGetLeftTimes",  --获取指定活动的当天剩余次数
    [action_config.MSG_CAMPAIGN_GET_ACVIVITY_LEFT_TIME] = "CampaignGetActivityLeftTime",  --获取指定活动的剩余时间
}

CampaignSystem.msgC2BMapping = {
    --cell到base的请求
    [action_config.MSG_CAMPAIGN_REWARD_C2B]         = "CampaignRewardC2B",     --副本结算后把奖励从cell发到base
    [action_config.MSG_CAMPAIGN_ADD_TIMES]          = "CampaignAddTimes",      --累加次数
}

function CampaignSystem:getFuncByMsgId(msg_id)
    return self.msgMapping[msg_id]
end

function CampaignSystem:getC2BFuncByMsgId(msg_id)
    return self.msgC2BMapping[msg_id]
end

function CampaignSystem:GetOnlineFriends(avatar, CampaignId)
    --获取玩家所有好友的信息

    local level = gActivityData:getActivityLevel(CampaignId)
    if not level then
        if avatar:hasClient() then
            avatar.client.CampaignResp(action_config.MSG_CAMPAIGN_GET_ONLINE_FRIENDS, error_code.ERR_ACTIVITY_NOT_EXIT, {})
        end
        return 0
    end

    local friendDbids = {}
    for k, _ in pairs(avatar.friends) do
        friendDbids[k] = 1
    end

    log_game_debug("CampaignSystem:GetOnlineFriends", "dbid=%q;name=%s;level=%s;friendDbids=%s", avatar.dbid, avatar.name, mogo.cPickle(level), mogo.cPickle(friendDbids))

    if result ~= {} then
        globalbase_call('ActivityMgr', 'CampaignGetOnlineFriends', avatar.base_mbstr, avatar.dbid, friendDbids, CampaignId)
    else
        if avatar:hasClient() then
            avatar.client.CampaignResp(action_config.MSG_CAMPAIGN_GET_ONLINE_FRIENDS, 0, {})
        end
    end

    return 0
end

function CampaignSystem:CampaignInvite(avatar, CampaignId, arg2, PlayerDbidStr)
    log_game_debug("CampaignSystem:CampaignInvite", "dbid=%q;name=%s;CampaignId=%d;PlayerDbidStr=%s", avatar.dbid, avatar, CampaignId, PlayerDbidStr)

    local PlayerDbid = tonumber(PlayerDbidStr)

    if avatar.dbid == PlayerDbid then
        if avatar:hasClient() then
            avatar.client.CampaignResp(action_config.MSG_CAMPAIGN_INVITE, error_code.ERR_ACTIVITY_INVITE_SELF, {})
        end
        return 0
    end

    if not avatar.friends[PlayerDbid] then
        if avatar:hasClient() then
            avatar.client.CampaignResp(action_config.MSG_CAMPAIGN_INVITE, error_code.ERR_ACTIVITY_INVITE_NOT_FRIEND, {})
        end
        return 0
    end

    globalbase_call('UserMgr', 'CampaignInvite', avatar.base_mbstr, avatar.dbid, avatar.name, CampaignId, PlayerDbid)
end

function CampaignSystem:CampaignInvitedResp(avatar, CampaignId, Accept, PlayerDbidStr)
    log_game_debug("CampaignSystem:CampaignInvitedResp", "dbid=%q;name=%s;CampaignId=%d;Accept=%d;PlayerDbidStr=%s", avatar.dbid, avatar, CampaignId, Accept, PlayerDbidStr)

    local PlayerDbid = tonumber(PlayerDbidStr)

    globalbase_call('ActivityMgr', 'CampaignInvitedResp', avatar.base_mbstr, avatar.dbid, avatar.name, CampaignId, Accept, PlayerDbid)

    return 0
end

function CampaignSystem:CampaignJoin(avatar, CampaignId)
    log_game_debug("CampaignSystem:CampaignJoin", "dbid=%q;name=%s;level=%d;CampaignId=%d", avatar.dbid, avatar.name, avatar.level, CampaignId)

    local activity = gActivityData:getActivity(CampaignId)
    if not activity then
        --如果活动不存在，则开始返回错误
        if avatar:hasClient() then
            avatar.client.CampaignResp(action_config.MSG_CAMPAIGN_JOIN, error_code.ERR_ACTIVITY_JOIN_NOT_EXIT, {})
        end
    elseif activity['level'][1] > avatar.level or activity['level'][2] < avatar.level then
        if avatar:hasClient() then
            avatar.client.CampaignResp(action_config.MSG_CAMPAIGN_JOIN, error_code.ERR_ACTIVITY_JOIN_LEVEL_NOT_MATCH, {})
        end
    elseif activity['times'] <= (avatar.ActivityTimes[CampaignId] or 0) then
        if avatar:hasClient() then
            avatar.client.CampaignResp(action_config.MSG_CAMPAIGN_JOIN, error_code.ERR_ACTIVITY_JOIN_LEVEL_TIMES_OUT, {})
        end
    elseif not global_data.GetActivityStartTime(CampaignId) then
        --如果活动没开始，则开始返回错误
        if avatar:hasClient() then
            avatar.client.CampaignResp(action_config.MSG_CAMPAIGN_JOIN, error_code.ERR_ACTIVITY_JOIN_NOT_STARTED, {})
        end
    else
        globalbase_call('ActivityMgr', 'CampaignJoin', CampaignId, avatar.base_mbstr, avatar.dbid, avatar.name, avatar.level)
    end

    return 0
end

function CampaignSystem:CampaignLeave(avatar, CampaignId)
    log_game_debug("CampaignSystem:CampaignLeave", "dbid=%q;name=%s;level=%d;CampaignId=%d", avatar.dbid, avatar.name, avatar.level, CampaignId)

    globalbase_call('ActivityMgr', 'CampaignLeave', CampaignId, avatar.base_mbstr, avatar.dbid)
    return 0
end

function CampaignSystem:CampaignRewardC2B(avatar, wave, harm, result)
    log_game_debug("CampaignSystem:CampaignRewardC2B", "dbid=%q;name=%s;level=%d;wave=%d;harm=%d;result=%s", avatar.dbid, avatar.name, avatar.level, wave, harm, mogo.cPickle(result))

    local MvpReward = {}
    local NormalReward = result[3] or {}

    if result[6] == avatar.dbid then
        --如果玩家是Mvp，则需要把Mvp也一并加到里面
        local towerReward = gActivityData:getTowerDefenceReward(wave, avatar.level)
--        local levelProps = g_avatar_level_mgr:GetLevelProps(avatar.level)
--        local expStandard = levelProps['expStandard'] or 0
--        local goldStandard = levelProps['goldStandard'] or 0
--
--        local exp = (towerReward['exp2'] or 0) * expStandard
--        local gold = (towerReward['gold2'] or 0) * goldStandard
        local exp = math.floor((result[1] or 0) * g_GlobalParamsMgr:GetParams("tower_defence_extra_exp_rate", 1000) / 10000)
        local gold = math.floor((result[2] or 0) * g_GlobalParamsMgr:GetParams("tower_defence_extra_gold_rate", 1000) / 10000)
        local item = towerReward['items2'] or {}

        MvpReward = item

        for k, v in pairs(result) do
            if k == 1 then
                result[k] = result[k] + exp
            elseif k == 2 then
                result[k] = result[k] + gold
            elseif k == 3 then
                for k1, v1 in pairs(item) do
                    local count = (v[k1] or 0) + v1
                    result[k][k1] = count
                end
            end
        end

--        --单次兽人必须死副本结束时为MVP（输出最高）
--        function Avatar:OnOrcMvp()
        avatar:OnOrcMvp()

        log_game_debug("CampaignSystem:CampaignRewardC2B Mvp", "dbid=%q;name=%s;level=%d;wave=%d;VipLevel=%d;result=%s", avatar.dbid, avatar.name, avatar.level, wave, avatar.VipLevel, mogo.cPickle(result))
    end

    --下发结果
    if avatar:hasClient() then
        local r = {
            wave,                        --波数
            harm,                        --个人输出
            result[1] or 0,              --获得的经验
            result[2] or 0,              --获得的金币
            NormalReward,                --获得的普通奖励
            result[5] or 0,              --Mvp输出
            result[7] or '',             --Mvp名字
            MvpReward }

        log_game_debug("CampaignSystem:CampaignRewardC2B to client", "dbid=%q;name=%s;level=%d;wave=%d;VipLevel=%d;r=%s", avatar.dbid, avatar.name, avatar.level, result[4], avatar.VipLevel, mogo.cPickle(r))

        avatar.client.CampaignResp(action_config.MSG_CAMPAIGN_RESULT, result[4], r)                   --Mvp奖励
    end

    for k, v in pairs(result) do
        if k == 1 then
            avatar:AddExp(v, reason_def.tower_defence)
        elseif k == 2 then
            avatar:AddGold(v, reason_def.tower_defence)
        elseif k == 3 then
            local attach = {}
            for itemId, count in pairs(v) do
                if avatar.inventorySystem:IsSpaceEnough(itemId, count) then
                    --背包位置足够
                    avatar.inventorySystem:AddItems(itemId, count)
                else
                    attach[itemId] = count
                end
            end

            if next(attach) then

                log_game_debug("CampaignSystem:CampaignRewardC2B send mail", "dbid=%q;name=%s;attach=%s", avatar.dbid, avatar.name, mogo.cPickle(attach))

                globalbase_call('MailMgr', 'SendIdEx', g_text_id.MISSION_TREASURE_MAIL_REWARD_TITLE,  --title
                    avatar.name,                              --to
                    g_text_id.MISSION_TREASURE_MAIL_REWARD_TEXT, --text
                    g_text_id.MISSION_MAIL_REWARD_FROM, --from
                    os.time(),                              --time
                    attach,                                 --道具
                    {[1]=avatar.dbid,}, --收件者的dbid列表
                    {},
                    reason_def.tower_defence
                )
            end
        end
    end

    --结算的时候累加当天次数
    self:CampaignAddTimes(avatar, 1)

--    --单次兽人必须死副本结束时完成的波数 rush_count =波数
--    function Avatar:OnOrcCount(rush_count)
    avatar:OnOrcCount(wave)


--    --兽人必须死战斗副本胜利
--    function Avatar:OnOrcWin()

    if result[4] == 0 then
        avatar:OnOrcWin()
    end

    return 0
end

function CampaignSystem:OnClientGetBase(avatar)
    local now = os.time()

    local Today = lua_util.get_yyyymmdd(now)
    for k, v in pairs(avatar.LastActivityTime) do
        if lua_util.get_yyyymmdd(v) ~= Today then
            log_game_debug("CampaignSystem:OnClientGetBase clear activity times", "dbid=%q;name=%s;CampaignId=%d", avatar.dbid, avatar.name, k)
            avatar.LastActivityTime[k] = nil
            avatar.ActivityTimes[k] = nil
        end
    end
--    local LastActivityTime = avatar.LastActivityTime or 0
--
--    if lua_util.get_yyyymmdd(LastActivityTime) ~= Today then
--        avatar.ActivityTimes = {}
--        log_game_debug("CampaignSystem:OnClientGetBase clear activity times", "dbid=%q;name=%s", avatar.dbid, avatar.name)
--        avatar.LastActivityTime = os.time()
--    end
end

function CampaignSystem:CampaignAddTimes(avatar, CampaignId)
    log_game_debug("CampaignSystem:CampaignAddTimes", "dbid=%q;name=%s;CampaignId=%d", avatar.dbid, avatar.name, CampaignId)

    avatar.ActivityTimes[CampaignId] = (avatar.ActivityTimes[CampaignId] or 0) + 1
    avatar.LastActivityTime[CampaignId] = os.time()
end

function CampaignSystem:OnZeroPointTimer(avatar)
    log_game_debug("CampaignSystem:OnZeroPointTimer", "dbid=%q;name=%s", avatar.dbid, avatar.name)
    avatar.LastActivityTime = {}
    avatar.ActivityTimes = {}
end

function CampaignSystem:CampaignGetLeftTimes(avatar, CampaignId)
--    log_game_debug("CampaignSystem:CampaignGetLeftTimes", "dbid=%q;name=%s;CampaignId=%d", avatar.dbid, avatar.name, CampaignId)

    local activity = gActivityData:getActivity(CampaignId)
    if not activity then
        --如果活动不存在，则开始返回错误
        if avatar:hasClient() then
            avatar.client.CampaignResp(action_config.MSG_CAMPAIGN_GET_LEFT_TIMES, error_code.ERR_ACTIVITY_GET_LEFT_TIMES_NOT_EXIT, {})
        end
    else
        local times = math.max((activity['times'] - (avatar.ActivityTimes[CampaignId] or 0)), 0)
        if avatar:hasClient() then
            log_game_debug("CampaignSystem:CampaignGetLeftTimes", "dbid=%q;name=%s;CampaignId=%d;times=%d", avatar.dbid, avatar.name, CampaignId, times)
            avatar.client.CampaignResp(action_config.MSG_CAMPAIGN_GET_LEFT_TIMES, 0, {times,})
        end
    end

    return 0
end

function CampaignSystem:CampaignGetActivityLeftTime(avatar, CampaignId)
    local activity = gActivityData:getActivity(CampaignId)
    if not activity then
        --如果活动不存在，则开始返回错误
        if avatar:hasClient() then
            avatar.client.CampaignResp(action_config.MSG_CAMPAIGN_GET_ACVIVITY_LEFT_TIME, error_code.ERR_ACTIVITY_GET_ACTIVITY_LEFT_TIME_NOT_EXIT, {})
        end
    else
        local StartTime = global_data.GetActivityStartTime(CampaignId)
        if not StartTime then
            --如果活动没开始，则开始返回错误
            if avatar:hasClient() then
                avatar.client.CampaignResp(action_config.MSG_CAMPAIGN_GET_ACVIVITY_LEFT_TIME, error_code.ERR_ACTIVITY_GET_ACTIVITY_LEFT_TIME_NOT_STARTED, {})
            end
        else
            local EndTime = StartTime + activity['lastTime']
            local LeftTime = EndTime - os.time()
            --计算活动的结束时间
            if avatar:hasClient() then
                avatar.client.CampaignResp(action_config.MSG_CAMPAIGN_GET_ACVIVITY_LEFT_TIME, 0, {LeftTime,})
            end
        end
    end


    return 0
end

gCampaignSystem = CampaignSystem
return gCampaignSystem