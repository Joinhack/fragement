
require "tower_config"
require "lua_util"
require "mission_config"
require "mission_data"
require "TowerData"
require "public_config"
require "map_data"
require "monster_data"
require "GlobalParams"
require "vip_privilege"
require "drop_data"
require "reason_def"
require "event_config"
require "action_config"
require "state_config"
require "MissionSystem"
require "client_text_id"

local _splitStr = lua_util.split_str
local log_game_debug = lua_util.log_game_debug
local log_game_warning = lua_util.log_game_warning
local log_game_info = lua_util.log_game_info
local log_game_error = lua_util.log_game_error
local globalbase_call = lua_util.globalbase_call

TowerSystem = {}
TowerSystem.__index = TowerSystem

--function TowerSystem:new(owner)
--
--    local newObj = {}
--    newObj.ptr = {}
--
--    setmetatable(newObj, {__index = TowerSystem})
--    setmetatable(newObj.ptr, {__mode = "kv"})
--
--    newObj.ptr.theOwner = owner
--
--    local msgMapping = {
--
--        --客户端到base的请求
--        [tower_config.MSG_GET_TOWER_INFO]         = TowerSystem.GetTowerInfo,                --客户请求获取试炼之塔的数据
--        [tower_config.MSG_ENTER_TOWER]            = TowerSystem.EnterTower,                  --进入指定层级的试炼之态
--        [tower_config.MSG_CLEAR_TOWER_SWEEP_CD]   = TowerSystem.ClearTowerSweepCd,           --清除副本扫荡的cd时间
--        [tower_config.MSG_TOWER_SWEEP]            = TowerSystem.TowerSweep,                  --普通扫荡
--        [tower_config.MSG_TOWER_VIP_SWEEP]        = TowerSystem.TowerVipSweep,               --VIP扫荡
--        [tower_config.MSG_TOWER_SWEEP_ALL]        = TowerSystem.SweepAll,                    --全部扫荡
--
--        [tower_config.MSG_CELL2BASE_SENT_REWARD]  = TowerSystem.SendReward,                   --cell通知base加临时奖励池道具
--        [tower_config.MSG_TOWER_FAIL]             = TowerSystem.TowerFail,                    --Cell通知副本失败
--        [tower_config.MSG_CELL2BASE_TOWER_SUCCESS]= TowerSystem.TowerSuccess,                 --cell通知base该层胜利
--
--    }
--    newObj.msgMapping = msgMapping
--
--    return newObj
--
--end

--function TowerSystem:TowerReq(msg_id, ...)
--    lua_util.log_game_debug("TowerSystem:TowerReq", "msg_id=%d;dbid=%q;name=%s", msg_id, self.ptr.theOwner.dbid, self.ptr.theOwner.name)
--
--    local func = self.msgMapping[msg_id]
--    if func ~= nil then
--        func(self, ...)
--    end
--end

TowerSystem.msgMapping = {

        --客户端到base的请求
        [action_config.MSG_GET_TOWER_INFO]         = "GetTowerInfo",                --客户请求获取试炼之塔的数据
        [action_config.MSG_ENTER_TOWER]            = "EnterTower",                  --进入指定层级的试炼之态
        [action_config.MSG_CLEAR_TOWER_SWEEP_CD]   = "ClearTowerSweepCd",           --清除副本扫荡的cd时间
        [action_config.MSG_TOWER_SWEEP]            = "TowerSweep",                  --普通扫荡
        [action_config.MSG_TOWER_VIP_SWEEP]        = "TowerVipSweep",               --VIP扫荡
        [action_config.MSG_TOWER_SWEEP_ALL]        = "SweepAll",                    --全部扫荡

    }

TowerSystem.msgC2BMapping = {

        [action_config.MSG_CELL2BASE_SENT_REWARD]  = "SendReward",                   --cell通知base加临时奖励池道具
        [action_config.MSG_TOWER_FAIL]             = "TowerFail",                    --Cell通知副本失败
        [action_config.MSG_CELL2BASE_TOWER_SUCCESS]= "TowerSuccess",                 --cell通知base该层胜利
        [action_config.MSG_CELL2BASE_SEND_TOWER_INFO]= "SendTowerInfo"               --cell通知base下发给客户端倒计时秒数和当前层数
}

function TowerSystem:getFuncByMsgId(msg_id)
    return self.msgMapping[msg_id]
end

function TowerSystem:getC2BFuncByMsgId(msg_id)
    return self.msgC2BMapping[msg_id]
end

function TowerSystem:GetTowerInfo(avatar)

--    local HighestFloor = avatar.TowerInfo[tower_config.TOWER_INFO_HIGHEST_FLOOR] or 0
    local HighestFloor = avatar.TowerHighestFloor
    local CurrentFloor = (avatar.TowerInfo[tower_config.TOWER_INFO_CURRENT_FLOOR] or 0) + 1
    local GotPackages  = avatar.TowerInfo[tower_config.TOWER_INFO_GOT_PACKAGES] or {}
    local LastSweepTime= avatar.TowerInfo[tower_config.TOWER_INFO_LAST_SWEEP_TIME] or 0
--    local VipSweepTimes= avatar.TowerInfo[tower_config.TOWER_INFO_VIP_SWEEP_TIMES] or 0
    local ClearSweepCdTimes = avatar.TowerInfo[tower_config.TOWER_INFO_CLEAR_SWEEP_CD_TIMES] or 0

    local result = {}
    table.insert(result, HighestFloor)           --历史最高层
    table.insert(result, CurrentFloor)           --当前层
    table.insert(result, GotPackages)            --已获取的宝箱列表

    local CountDownSeconds = (LastSweepTime + g_GlobalParamsMgr:GetParams('tower_sweep_cd_time', 2 * 3600)) - os.time()
    if CountDownSeconds > 0 then
        table.insert(result, CountDownSeconds)   --倒数秒数
    else
        table.insert(result, 0)
    end

    local FailTimes = avatar.TowerInfo[tower_config.TOWER_INFO_FAIL_TIMES] or 0

    table.insert(result, FailTimes)              --失败次数

    table.insert(result,  avatar.VipRealState[public_config.DAILY_TOWER_SWEEP_TIMES] or 0)          --已使用VIP扫荡的次数

    table.insert(result, ClearSweepCdTimes)      --每日清除普通扫荡cd的次数

    log_game_debug("TowerSystem:GetTowerInfo", "dbid=%q;name=%s;result=%s", avatar.dbid, avatar.name, mogo.cPickle(result))

    if avatar:hasClient() then
        avatar.client.TowerResp(action_config.MSG_GET_TOWER_INFO, result)
    end

    return 0
end

function TowerSystem:GotoTower(avatar, floor)
    local MissionId = self:GetMissionId(floor)

    --如果玩家不在试炼之态里面，则直接走普通进入关卡副本的流程
    avatar:MissionReq(action_config.MSG_ENTER_MISSION, self:GetMissionId(floor), floor, '')
    if avatar:hasClient() then
        avatar.client.TowerResp(action_config.MSG_ENTER_TOWER, {0})
    end

    avatar.state = mogo.sunset(avatar.state, state_config.STATE_TOWER_CURRENT_FLOOR_SUCCESS)

end

function TowerSystem:EnterTower(avatar)
    --进入 试炼之塔
    local CurrentFloor = avatar.TowerInfo[tower_config.TOWER_INFO_CURRENT_FLOOR] or 0
    local MissionId = self:GetMissionId(CurrentFloor)

    local tbl = {}
    table.insert(tbl, tostring(MissionId))
    table.insert(tbl, tostring(CurrentFloor+1))

    log_game_debug("TowerSystem:EnterTower", "dbid=%q;name=%s;MissionId=%d;CurrentFloor=%d;TowerInfo=%s", avatar.dbid, avatar.name, MissionId, CurrentFloor, mogo.cPickle(avatar.TowerInfo))

    local MissionCfg = g_mission_mgr:getCfgById(table.concat(tbl, '_'))

    if not MissionCfg then
        avatar.client.TowerResp(action_config.MSG_ENTER_TOWER, {tower_config.TOWER_ERROR_CODE_CFG})
        return 0
    end

    local failTime = avatar.TowerInfo[tower_config.TOWER_INFO_FAIL_TIMES] or 0

    if failTime >= g_GlobalParamsMgr:GetParams('tower_daily_fail_times', 3) then
        if avatar:hasClient() then
            avatar.client.TowerResp(action_config.MSG_ENTER_TOWER, {tower_config.TOWER_ERROR_CODE_FAIL_TIMES})
        end
        return 0
    end

--    if CurrentFloor < 0 and CurrentFloor > 0 then
--        self.ptr.theOwner.client.TowerResp(tower_config.MSG_ENTER_TOWER, {tower_config.TOWER_ERROR_CODE_SYSTEM_ERROR})
--        return
--    end

--    local scendId = self:GetMissionId(CurrentFloor + 1)
    local scendId = MissionCfg['scene']

    if scendId ~= avatar.sceneId then
        log_game_debug("TowerSystem:EnterTower different", "dbid=%q;name=%s;MissionId=%d;CurrentFloor=%d", avatar.dbid, avatar.name, MissionId, CurrentFloor)
        --如果玩家不在试炼之态里面，则直接走普通进入关卡副本的流程

        local result = gMissionSystem:CanEnterMission(avatar, self:GetMissionId(CurrentFloor), CurrentFloor+1)
        if result < 0 then
            if avatar:hasClient() then
                avatar.client.MissionResp(action_config.MSG_ENTER_MISSION, {result})
            end
            return 0
        end

        avatar:MissionReq(action_config.MSG_ENTER_MISSION, self:GetMissionId(CurrentFloor), CurrentFloor+1, '')

        if avatar:hasClient() then
            avatar.client.TowerResp(action_config.MSG_ENTER_TOWER, {0})
        end

        avatar.state = mogo.sunset(avatar.state, state_config.STATE_TOWER_CURRENT_FLOOR_SUCCESS)

        --成功进入试炼之塔时，记录时间戳，在试炼之塔内进入下一层时不记录
        avatar.TowerInfo[tower_config.TOWER_INFO_LAST_ENTER_TIME] = os.time()
    else
        --如果玩家已经在试炼之态里面，则要先判断是否可以进入下一层
        if mogo.stest(avatar.state, state_config.STATE_TOWER_CURRENT_FLOOR_SUCCESS) ~= 0 then
            log_game_debug("TowerSystem:EnterTower success", "dbid=%q;name=%s;MissionId=%d;CurrentFloor=%d", avatar.dbid, avatar.name, MissionId, CurrentFloor)

            local result = gMissionSystem:CanEnterMission(avatar, self:GetMissionId(CurrentFloor), CurrentFloor+1)
            if result < 0 then
                if avatar:hasClient() then
                    avatar.client.MissionResp(action_config.MSG_ENTER_MISSION, {result})
                end
                return 0
            end

            avatar:MissionReq(action_config.MSG_ENTER_MISSION, self:GetMissionId(CurrentFloor), CurrentFloor+1, '')

            if avatar:hasClient() then
                avatar.client.TowerResp(action_config.MSG_ENTER_TOWER, {0})
            end

            avatar.state = mogo.sunset(avatar.state, state_config.STATE_TOWER_CURRENT_FLOOR_SUCCESS)

--            --成功进入试炼之塔时，记录时间戳
--            avatar.TowerInfo[tower_config.TOWER_INFO_LAST_ENTER_TIME] = os.time()
        else
            log_game_debug("TowerSystem:EnterTower not success", "dbid=%q;name=%s;MissionId=%d;CurrentFloor=%d", avatar.dbid, avatar.name, MissionId, CurrentFloor)
            if avatar:hasClient() then
                avatar.client.TowerResp(action_config.MSG_ENTER_TOWER, {tower_config.TOWER_ERROR_CODE_CURRENT_NOT_SUCCESS})
            end
        end
    end

--        if MissionCfg['scene'] ~= self.ptr.theOwner.sceneId then
--            --如果玩家不在目标场景，则需要申请副本
--            self.ptr.theOwner:MissionReq(mission_config.MSG_ENTER_MISSION, self:GetMissionId(CurrentFloor), CurrentFloor+1, '')
--        else
--            --如果玩家已经在目标场景，只是层数不一样，则考虑重置数据，复用场景
--            local tbl = {}
--            table.insert(tbl, 'SpaceLoader')
--            table.insert(tbl, tostring(self.ptr.theOwner.sceneId))
--            table.insert(tbl, tostring(self.ptr.theOwner.imap_id))
--
--            local SpaceLoader = globalBases[table.concat(tbl, '_')]
--            if SpaceLoader then
--                SpaceLoader.Restart(self.ptr.theOwner.dbid, self.ptr.theOwner.name, mogo.pickleMailbox(self.ptr.theOwner), MissionId, CurrentFloor+1)
--            end
--
--            --重置客户端
--            self.ptr.theOwner.client.MissionResp(mission_config.MSG_CLIENT_RESET, {})
--        end
    return 0
end

--根据试炼之塔的层级获取关卡ID
function TowerSystem:GetMissionId(CurrentFloor)
    return 20001
end

--由0点定时器触发调用的函数
function TowerSystem:OnZeroPointTimer(avatar)
    log_game_info("TowerSystem:OnZeroPointTimer", "dbid=%q;name=%s", avatar.dbid, avatar.name)

    --0点清空失败次数
    avatar.TowerInfo[tower_config.TOWER_INFO_FAIL_TIMES] = 0

    --0点清空当前层数
    avatar.TowerInfo[tower_config.TOWER_INFO_CURRENT_FLOOR] = 0

    --清空已获得的宝箱列表
    avatar.TowerInfo[tower_config.TOWER_INFO_GOT_PACKAGES] = {}

    --清空每天已经使用的vip扫荡次数
    avatar.TowerInfo[tower_config.TOWER_INFO_VIP_SWEEP_TIMES] = 0

    --每天清空扫荡充值扫荡副本次数
    avatar.TowerInfo[tower_config.TOWER_INFO_CLEAR_SWEEP_CD_TIMES] = 0

    --给user_data的lua_table类型的字段整体赋值，令其为脏数据
--    local TowerInfo = mogo.deepcopy1(avatar.TowerInfo)
--    avatar.TowerInfo = TowerInfo
    return 0
end

--当client连接上base时调用
function TowerSystem:OnClientGetBase(avatar)

    log_game_debug("TowerSystem:OnClientGetBase", "dbid=%q;name=%s", avatar.dbid, avatar.name)

    local Today = lua_util.get_yyyymmdd(os.time())

    local LastFailTime = avatar.TowerInfo[tower_config.TOWER_INFO_LAST_FAIL_TIME] or 0

    if lua_util.get_yyyymmdd(LastFailTime) ~= Today then
        avatar.TowerInfo[tower_config.TOWER_INFO_FAIL_TIMES] = 0
        log_game_debug("TowerSystem:OnClientGetBase clear fail times", "dbid=%q;name=%s", avatar.dbid, avatar.name)
    end

    local LastVipSweepTime = avatar.TowerInfo[tower_config.TOWER_INFO_LAST_VIP_SWEEP_TIME] or 0

    if lua_util.get_yyyymmdd(LastVipSweepTime) ~= Today then
        avatar.TowerInfo[tower_config.TOWER_INFO_VIP_SWEEP_TIMES] = 0
        log_game_debug("TowerSystem:OnClientGetBase clear vip sweep times", "dbid=%q;name=%s", avatar.dbid, avatar.name)
    end

    local LastClearSweepCdTime = avatar.TowerInfo[tower_config.TOWER_INFO_LAST_CLEAR_SWEEP_CD_TIME] or 0
    if lua_util.get_yyyymmdd(LastClearSweepCdTime) ~= Today then
        avatar.TowerInfo[tower_config.TOWER_INFO_CLEAR_SWEEP_CD_TIMES] = 0
        log_game_debug("TowerSystem:OnClientGetBase clear sweep cd times", "dbid=%q;name=%s", avatar.dbid, avatar.name)
    end

    local LastSuccessTime = avatar.TowerInfo[tower_config.TOWER_INFO_LAST_SUCCESS_TIMES] or 0
    if lua_util.get_yyyymmdd(LastSuccessTime) ~= Today then
        avatar.TowerInfo[tower_config.TOWER_INFO_CURRENT_FLOOR] = 0
        avatar.TowerInfo[tower_config.TOWER_INFO_GOT_PACKAGES] = {}
    end

--    local TowerInfo = mogo.deepcopy1(self.ptr.theOwner.TowerInfo)
--    self.ptr.theOwner.TowerInfo = TowerInfo

    return 0

end

function TowerSystem:ClearTowerSweepCd(avatar)
    log_game_debug("TowerSystem:ClearTowerSweepCd", "dbid=%q;name=%s", avatar.dbid, avatar.name)

    local ClearSweepCdTimes = avatar.TowerInfo[tower_config.TOWER_INFO_CLEAR_SWEEP_CD_TIMES] or 0
    local Cost = gTowerDataMgr:GetSweepCdClearCost(ClearSweepCdTimes)

    if not Cost then
        avatar.client.TowerResp(action_config.MSG_CLEAR_TOWER_SWEEP_CD, {tower_config.TOWER_ERROR_CODE_NOT_ENOUGH_TO_CLEAR_SWEEP_CD})
        return 0
    end
    
    if not avatar:has_diamond(Cost) then
        avatar.client.TowerResp(action_config.MSG_CLEAR_TOWER_SWEEP_CD, {tower_config.TOWER_ERROR_CODE_NOT_ENOUGH_TO_CLEAR_SWEEP_CD})
        return 0
    end

    avatar:add_diamond(-Cost)
    avatar.TowerInfo[tower_config.TOWER_INFO_LAST_SWEEP_TIME] = 0

    avatar.TowerInfo[tower_config.TOWER_INFO_CLEAR_SWEEP_CD_TIMES] = ClearSweepCdTimes + 1
    avatar.TowerInfo[tower_config.TOWER_INFO_LAST_CLEAR_SWEEP_CD_TIME] = os.time()

--    local TowerInfo = mogo.deepcopy1(avatar.TowerInfo)
--    avatar.TowerInfo = TowerInfo

    self:GetTowerInfo(avatar)

    avatar.client.TowerResp(action_config.MSG_CLEAR_TOWER_SWEEP_CD, {0})

    return 0

end

function TowerSystem:TowerSweep(avatar)
    log_game_debug("TowerSystem:TowerSweep", "dbid=%q;name=%s", avatar.dbid, avatar.name)

    local now = os.time()

    if now < (avatar.TowerInfo[tower_config.TOWER_INFO_LAST_SWEEP_TIME] or 0) + g_GlobalParamsMgr:GetParams('tower_sweep_cd_time', 2 * 3600) then
        --2小时的普通扫荡cd时间没过，则给出提示
        avatar.client.TowerResp(action_config.MSG_TOWER_SWEEP, {tower_config.TOWER_ERROR_CODE_SWEEP_CD})
        return 0
    end

    local CurrentDifficult = avatar.TowerInfo[tower_config.TOWER_INFO_CURRENT_FLOOR] or 0
--    local HistoryHigestLevel = avatar.TowerInfo[tower_config.TOWER_INFO_HIGHEST_FLOOR] or 0
    local HistoryHigestLevel = avatar.TowerHighestFloor

    --实际上那个可以允许的扫荡层数
    local SweepLevel = math.min(g_GlobalParamsMgr:GetParams('tower_sweep_times', 10), HistoryHigestLevel - CurrentDifficult)

    if SweepLevel <= 0 then
        avatar.client.TowerResp(action_config.MSG_TOWER_SWEEP, {tower_config.TOWER_ERROR_CODE_SWEEP_LEVEL})
        return 0
    end

    local Exp = 0
    local Items = {}
    local Money = 0

    log_game_debug("TowerSystem:TowerSweep", "dbid=%q;name=%s;SweepLevel=%d", avatar.dbid, avatar.name, SweepLevel)

    local ItemsCanNotInBag = {}
    local flag1 = false

    for i=1, SweepLevel do
--        lua_util.log_game_debug("TowerSystem:TowerSweep", "dbid=%q;name=%s;SweepLevel=%d",
--                                                           avatar.dbid, avatar.name, SweepLevel)
        local TargetDifficult = CurrentDifficult + i

        local scendId = self:GetMissionId(TargetDifficult)

        local Reward = g_mission_mgr:getRewardInfo(scendId, TargetDifficult, avatar.vocation)
--        lua_util.log_game_debug("TowerSystem:TowerSweep", "dbid=%q;name=%s;Reward=%s", avatar.dbid, self.ptr.theOwner.name, mogo.cPickle(Reward))

        if Reward then
            --向客户端下发怪物列表
--            self.ptr.theOwner.client.TowerResp(tower_config.MSG_TOWER_SWEEP, Reward[1] or {})

            local ItemTbl = Reward[2] or {}

            for id, count in pairs(ItemTbl) do
                log_game_debug("TowerSystem:TowerSweep IsSpaceEnough", "dbid=%q;name=%s;id=%d;count=%d",
                                                                                 avatar.dbid, avatar.name, id, count)
                if avatar.inventorySystem:IsSpaceEnough(id, count) then
                    --背包位置足够
                    log_game_debug("TowerSystem:TowerSweep AddItems", "dbid=%q;name=%s;id=%d;count=%d",
                                                                                   avatar.dbid, avatar.name, id, count)
                    avatar.inventorySystem:AddItems(id, count)
                else
                    local ItemCount = ItemsCanNotInBag[id] or 0
                    ItemsCanNotInBag[id] = ItemCount + count
                    flag1 = true
                end

                local old = Items[id] or 0
                Items[id] = old + count
            end

            --金币奖励
            if Reward[3] and Reward[3] > 0 then
                Money = Money + Reward[3]
            end

            --经验奖励
            if Reward[4] and Reward[4] > 0 then
                Exp = Exp + Reward[4]
            end
        else
            avatar.client.TowerResp(action_config.MSG_TOWER_SWEEP, {tower_config.TOWER_ERROR_CODE_SWEEP_NO_REWARD})
        end

        log_game_debug("TowerSystem:TowerSweep", "dbid=%q;name=%s;CurrentDifficult=%d;TargetDifficult=%d", avatar.dbid, avatar.name, CurrentDifficult, TargetDifficult)
        self:GetPackage(avatar, TargetDifficult)

    end


    if flag1 then
        --                globalbase_call('MailMgr', 'SendEx', "试炼之塔扫荡奖励",                 --title
        --                    "试炼之塔扫荡奖励",                                                        --to
        --                    "试炼之塔扫荡奖励",                                                        --text
        --                    "试炼之塔扫荡奖励",                                                        --from
        --                    now,                                                                         --time
        --                    ItemsCanNotInBag,                                                            --道具
        --                    {[1]=avatar.dbid,},                                                          --收件者的dbid列表
        --                    reason_def.tower
        --                )

        log_game_debug("TowerSystem:TowerSweep send mail", "dbid=%q;name=%s;ItemsCanNotInBag=%s", avatar.dbid, avatar.name, mogo.cPickle(ItemsCanNotInBag))

        globalbase_call('MailMgr', 'SendIdEx', g_text_id.TOWER,                    --title
            avatar.name,                                                                 --to
            g_text_id.TOWER_NEW,                                                         --text
            g_text_id.TOWER,                                                             --from
            now,                                                                         --time
            ItemsCanNotInBag,                                                            --道具
            {[1]=avatar.dbid,},                                                          --收件者的dbid列表
            {},
            reason_def.tower
        )
    end

    --获取宝箱奖励
    self:GetPackageReward(avatar)

    avatar.TowerInfo[tower_config.TOWER_INFO_LAST_SWEEP_TIME] = now

    local CurrentFloor = avatar.TowerInfo[tower_config.TOWER_INFO_CURRENT_FLOOR] or 0
    avatar.TowerInfo[tower_config.TOWER_INFO_CURRENT_FLOOR] = CurrentFloor + SweepLevel

    avatar.TowerInfo[tower_config.TOWER_INFO_LAST_SUCCESS_TIMES] = now

    --更新上一次进入试炼之塔的时间戳
    avatar.TowerInfo[tower_config.TOWER_INFO_LAST_ENTER_TIME] = now

    --加前
    avatar:AddGold(Money, reason_def.tower)
    --加经验
    avatar:AddExp(Exp, reason_def.tower)

    --返回格式：
    --{1=经验,2=道具列表,3=钱, 4=已获取宝箱}
    local result = {[1]=Exp, [2]=Items, [3]=Money, [4]=avatar.TowerInfo[tower_config.TOWER_INFO_GOT_PACKAGES]}

    if avatar:hasClient() then
        avatar.client.TowerResp(action_config.MSG_CLIENT_REPORT, result)
    end

--    --弹出战报之后刷新UI界面
--    self:GetTowerInfo(avatar)

    log_game_debug("TowerSystem:TowerSweep", "dbid=%q;name=%s;result=%s", avatar.dbid, avatar.name, mogo.cPickle(result))

--    local TowerInfo = mogo.deepcopy1(avatar.TowerInfo)
--    avatar.TowerInfo = TowerInfo

    --试炼之塔扫荡后触发湮灭之门
    avatar.oblivionGateSystem:TriggerGate(2)

    --完成了试炼之塔一层以后触发
    avatar:OnFinishTower(avatar.TowerInfo[tower_config.TOWER_INFO_CURRENT_FLOOR] or 0)

    return 0
end

function TowerSystem:TowerVipSweep(avatar)

--    local VipLevel = g_vip_mgr:GetVipLevel(avatar.chargeSum)
--    if not VipLevel then
--        avatar.client.TowerResp(action_config.MSG_TOWER_VIP_SWEEP, {tower_config.TOWER_ERROR_CODE_NOT_VIP})
--        return
--    end

    local VipTbl = g_vip_mgr:GetVipPrivileges(avatar.VipLevel)
    if not VipTbl then
        avatar.client.TowerResp(action_config.MSG_TOWER_VIP_SWEEP, {tower_config.TOWER_ERROR_CODE_NOT_VIP})
        return 0
    end

    local UsedVipSweepTimes = avatar.VipRealState[public_config.DAILY_TOWER_SWEEP_TIMES] or 0
    log_game_debug("TowerSystem:TowerVipSweep", "dbid=%q;name=%s;chargeSum=%d;VipLevel=%d;VipTbl['dailyTowerSweepLimit']=%d;UsedVipSweepTimes=%d", avatar.dbid, avatar.name, avatar.chargeSum, avatar.VipLevel, VipTbl['dailyTowerSweepLimit'], UsedVipSweepTimes)

    if UsedVipSweepTimes >= (VipTbl['dailyTowerSweepLimit'] or 0) then
        avatar.client.TowerResp(action_config.MSG_TOWER_VIP_SWEEP, {tower_config.TOWER_ERROR_CODE_VIP_SWEEP_TIMES_UP})
        return 0
    end

    local CurrentDifficult = avatar.TowerInfo[tower_config.TOWER_INFO_CURRENT_FLOOR] or 0
    local HistoryHigestLevel = avatar.TowerHighestFloor
--    local HistoryHigestLevel = avatar.TowerInfo[tower_config.TOWER_INFO_HIGHEST_FLOOR] or 0

    --当前实际使用的次数为以下3个值的最小值
    --每次扫荡默认消耗次数，默认为10
    --当前层离最高层的剩余层数
    --今天剩余次数
    local RealUsedTimes = math.min( g_GlobalParamsMgr:GetParams('tower_vip_sweep_times', 10),
                                    HistoryHigestLevel - CurrentDifficult)

    if RealUsedTimes <= 0 then
        log_game_error("TowerSystem:TowerVipSweep", "dbid=%q;name=%s;RealUsedTimes=%d", avatar.dbid, avatar.name, RealUsedTimes)
        avatar.client.TowerResp(action_config.MSG_TOWER_VIP_SWEEP, {tower_config.TOWER_ERROR_CODE_VIP_SWEEP_DATA})
        return 0
    end

    local Exp = 0
    local Items = {}
    local Money = 0
    local now = os.time()
    local flag1 = false

    local ItemsCanNotInBag = {}

    for i=1, RealUsedTimes do
        local TargetDifficult = CurrentDifficult + i

        local scendId = self:GetMissionId(TargetDifficult)

        local Reward = g_mission_mgr:getRewardInfo(scendId, TargetDifficult, avatar.vocation)

        if Reward then
            --向客户端下发怪物列表
--            avatar.client.TowerResp(mission_config.MSG_TOWER_VIP_SWEEP, Reward[1] or {})

            local ItemTbl = Reward[2] or {}


            for id, count in pairs(ItemTbl) do
                if avatar.inventorySystem:IsSpaceEnough(id, count) then
                    --背包位置足够
                    avatar.inventorySystem:AddItems(id, count)
                else
                    local ItemCount = ItemsCanNotInBag[id] or 0
                    ItemsCanNotInBag[id] = ItemCount + count
                    flag1 = true
                end

                local old = Items[id] or 0
                Items[id] = old + count

            end

            --金币奖励
            if Reward[3] and Reward[3] > 0 then
                avatar:AddGold(Reward[3], reason_def.tower)
                Money = Money + Reward[3]
            end

            --经验奖励
            if Reward[4] and Reward[4] > 0 then
                avatar:AddExp(Reward[4], reason_def.tower)
                Exp = Exp + Reward[4]
            end
        else
            avatar.client.TowerResp(action_config.MSG_TOWER_VIP_SWEEP, {tower_config.TOWER_ERROR_CODE_VIP_SWEEP_NO_REWARD})
        end

        self:GetPackage(avatar, TargetDifficult)

    end


    if flag1 then
        --                globalbase_call('MailMgr', 'SendEx', "试炼之塔VIP扫荡奖励",                  --title
        --                    "试炼之塔VIP扫荡奖励",                  --to
        --                    "试炼之塔VIP扫荡奖励",                  --text
        --                    "试炼之塔VIP扫荡奖励",                  --from
        --                    now,                                     --time
        --                    ItemsCanNotInBag,            --道具
        --                    {[1]=avatar.dbid,}, --收件者的dbid列表
        --                    reason_def.tower
        --                )

        log_game_debug("TowerSystem:TowerVipSweep send mail", "dbid=%q;name=%s;ItemsCanNotInBag=%s", avatar.dbid, avatar.name, mogo.cPickle(ItemsCanNotInBag))

        globalbase_call('MailMgr', 'SendIdEx', g_text_id.TOWER,                    --title
            avatar.name,                                                                 --to
            g_text_id.TOWER_NEW,                                                         --text
            g_text_id.TOWER,                                                             --from
            now,                                                                         --time
            ItemsCanNotInBag,                                                            --道具
            {[1]=avatar.dbid,},                                                          --收件者的dbid列表
            {},
            reason_def.tower
        )
    end

    --获取宝箱奖励
    self:GetPackageReward(avatar)



    avatar.TowerInfo[tower_config.TOWER_INFO_LAST_VIP_SWEEP_TIME] = now

    local CurrentFloor = avatar.TowerInfo[tower_config.TOWER_INFO_CURRENT_FLOOR] or 0
    avatar.TowerInfo[tower_config.TOWER_INFO_CURRENT_FLOOR] = CurrentFloor + RealUsedTimes

    local CurrentVipSweepTimes = avatar.TowerInfo[tower_config.TOWER_INFO_VIP_SWEEP_TIMES] or 0
    avatar.TowerInfo[tower_config.TOWER_INFO_VIP_SWEEP_TIMES] = CurrentVipSweepTimes + RealUsedTimes

    UsedVipSweepTimes = UsedVipSweepTimes + 1

    avatar.VipRealState[public_config.DAILY_TOWER_SWEEP_TIMES] = UsedVipSweepTimes

    avatar.TowerInfo[tower_config.TOWER_INFO_LAST_SUCCESS_TIMES] = now

    --更新上一次进入试炼之塔的时间戳
    avatar.TowerInfo[tower_config.TOWER_INFO_LAST_ENTER_TIME] = now

    --返回格式：
    --{1=经验,2=道具列表,3=钱, 4=已获取宝箱}
    local result = {[1]=Exp, [2]=Items, [3]=Money, [4]=avatar.TowerInfo[tower_config.TOWER_INFO_GOT_PACKAGES]}

    if avatar:hasClient() then
        avatar.client.TowerResp(action_config.MSG_CLIENT_REPORT, result)
    end

--    --弹出战报之后刷新UI界面
--    self:GetTowerInfo(avatar)

--    local TowerInfo = mogo.deepcopy1(avatar.TowerInfo)
--    avatar.TowerInfo = TowerInfo


--    local VipRealState = mogo.deepcopy1(avatar.VipRealState)
--    avatar.VipRealState = VipRealState

    --试炼之塔扫荡后触发湮灭之门
    avatar.oblivionGateSystem:TriggerGate(2)

    --完成了试炼之塔一层以后触发
    avatar:OnFinishTower(avatar.TowerInfo[tower_config.TOWER_INFO_CURRENT_FLOOR] or 0)

    return 0

end

function TowerSystem:SweepAll(avatar)

    log_game_debug("TowerSystem:SweepAll", "dbid=%q;name=%s;chargeSum=%d", avatar.dbid, avatar.name, avatar.chargeSum)

--    local VipLevel = g_vip_mgr:GetVipLevel(avatar.chargeSum)
    if avatar.VipLevel < g_GlobalParamsMgr:GetParams('tower_all_sweep_vip_level', 5) then
        avatar.client.TowerResp(action_config.MSG_TOWER_SWEEP_ALL, {tower_config.TOWER_ERROR_CODE_SWEEP_ALL_LEVEL})
        return 0
    end

    local CurrentDifficult = avatar.TowerInfo[tower_config.TOWER_INFO_CURRENT_FLOOR] or 0
    local HistoryHigestLevel = avatar.TowerHighestFloor
--    local HistoryHigestLevel = avatar.TowerInfo[tower_config.TOWER_INFO_HIGHEST_FLOOR] or 0

    local RealUsedTimes = HistoryHigestLevel - CurrentDifficult

    if RealUsedTimes <= 0 then
        log_game_debug("TowerSystem:TowerVipSweep", "dbid=%q;name=%s;RealUsedTimes=%d", avatar.dbid, avatar.name, RealUsedTimes)
        avatar.client.TowerResp(action_config.MSG_TOWER_SWEEP_ALL, {tower_config.TOWER_ERROR_CODE_VIP_SWEEP_DATA})
        return 0
    end

    local Exp = 0
    local Items = {}
    local Money = 0
    local now = os.time()

    local ItemsCanNotInBag = {}
    local flag1 = false

    for i=1, RealUsedTimes do
        local TargetDifficult = CurrentDifficult + i

        local scendId = self:GetMissionId(TargetDifficult)

        local Reward = g_mission_mgr:getRewardInfo(scendId, TargetDifficult, avatar.vocation)

        if Reward then
            --向客户端下发怪物列表
--            self.ptr.theOwner.client.TowerResp(mission_config.MSG_TOWER_VIP_SWEEP, Reward[1] or {})

            local ItemTbl = Reward[2] or {}

            for id, count in pairs(ItemTbl) do
                if avatar.inventorySystem:IsSpaceEnough(id, count) then
                    --背包位置足够
                    avatar.inventorySystem:AddItems(id, count)
                else
                    local ItemCount = ItemsCanNotInBag[id] or 0
                    ItemsCanNotInBag[id] = ItemCount + count
                    flag1 = true
                end

                local old = Items[id] or 0
                Items[id] = old + count
            end

            --金币奖励
            if Reward[3] and Reward[3] > 0 then
                avatar:AddGold(Reward[3], reason_def.tower)
                Money = Money + Reward[3]
            end

            --经验奖励
            if Reward[4] and Reward[4] > 0 then
                avatar:AddExp(Reward[4], reason_def.tower)
                Exp = Exp + Reward[4]
            end

        end

        self:GetPackage(avatar, TargetDifficult)

    end

    if flag1 then
        --                globalbase_call('MailMgr', 'SendEx', "全部扫荡奖励",                  --title
        --                    "全部扫荡奖励",                                                         --to
        --                    "全部扫荡奖励",                                                         --text
        --                    "全部扫荡奖励",                                                         --from
        --                    now,                                                                      --time
        --                    ItemsCanNotInBag,                                                         --道具
        --                    {[1]=avatar.dbid,},                                                        --收件者的dbid列表
        --                    reason_def.tower
        --                )

        log_game_debug("TowerSystem:SweepAll send mail", "dbid=%q;name=%s;ItemsCanNotInBag=%s", avatar.dbid, avatar.name, mogo.cPickle(ItemsCanNotInBag))

        globalbase_call('MailMgr', 'SendIdEx', g_text_id.TOWER,                 --title
            avatar.name,                                                        --to
            g_text_id.TOWER_NEW,                                                        --text
            g_text_id.TOWER,                                                        --from
            now,                                                                         --time
            ItemsCanNotInBag,                                                            --道具
            {[1]=avatar.dbid,},                                                          --收件者的dbid列表
            {},
            reason_def.tower
        )
    end

    self:GetPackageReward(avatar)

    --返回格式：
    --{1=经验,2=道具列表,3=钱, 4=已获取宝箱}
    local result = {[1]=Exp, [2]=Items, [3]=Money, [4]=avatar.TowerInfo[tower_config.TOWER_INFO_GOT_PACKAGES]}

    avatar.TowerInfo[tower_config.TOWER_INFO_LAST_SWEEP_TIME] = now

    avatar.TowerInfo[tower_config.TOWER_INFO_CURRENT_FLOOR] = HistoryHigestLevel

    avatar.TowerInfo[tower_config.TOWER_INFO_LAST_SUCCESS_TIMES] = now

    --更新上一次进入试炼之塔的时间戳
    avatar.TowerInfo[tower_config.TOWER_INFO_LAST_ENTER_TIME] = now

    if avatar:hasClient() then
        avatar.client.TowerResp(action_config.MSG_CLIENT_REPORT, result)
    end

--    --弹出战报之后刷新UI界面
--    self:GetTowerInfo(avatar)

    --试炼之塔扫荡后触发湮灭之门
    avatar.oblivionGateSystem:TriggerGate(2)

    --完成了试炼之塔一层以后触发
    avatar:OnFinishTower(avatar.TowerInfo[tower_config.TOWER_INFO_CURRENT_FLOOR] or 0)

    return 0

end

--获取指定等级的宝箱
function TowerSystem:GetPackage(avatar, level)

    log_game_debug("TowerSystem:GetPackage", "name=%s;dbid=%q;level=%d", avatar.name, avatar.dbid, level)

    local Reward = gTowerDataMgr:GetRewardByLevel(level)

    if Reward and Reward['item'] then
        Reward = Reward['item']
        if not avatar.TowerInfo[tower_config.TOWER_INFO_GOT_PACKAGES] then
            avatar.TowerInfo[tower_config.TOWER_INFO_GOT_PACKAGES] = {}
        end
        if not avatar.TowerInfo[tower_config.TOWER_INFO_NOT_HAVE_GET_PACKAGE_REWARD] then
            avatar.TowerInfo[tower_config.TOWER_INFO_NOT_HAVE_GET_PACKAGE_REWARD] = {}
        end

        log_game_debug("TowerSystem:GetPackage", "name=%s;dbid=%q;level=%d;Reward=%s", avatar.name, avatar.dbid, level, mogo.cPickle(Reward))

        local flag = true
        for _, l in pairs(avatar.TowerInfo[tower_config.TOWER_INFO_GOT_PACKAGES]) do
            if l == level then
                flag = false
                break
            end
        end

        if flag then
            table.insert(avatar.TowerInfo[tower_config.TOWER_INFO_GOT_PACKAGES], level)
--            for item, count in pairs(Reward) do
--                local ItemCount = self.ptr.theOwner.TowerInfo[tower_config.TOWER_INFO_PACKAGES_POOL][item]
--                if ItemCount then
--                    self.ptr.theOwner.TowerInfo[tower_config.TOWER_INFO_PACKAGES_POOL][item] = ItemCount + count
--                else
--                    self.ptr.theOwner.TowerInfo[tower_config.TOWER_INFO_PACKAGES_POOL][item] = count
--                end
--            end
           local tempFlag = true
           for _, l in pairs(avatar.TowerInfo[tower_config.TOWER_INFO_NOT_HAVE_GET_PACKAGE_REWARD]) do
               if l == level then
                   tempFlag = false
                   break
               end
           end

           if tempFlag then
               table.insert(avatar.TowerInfo[tower_config.TOWER_INFO_NOT_HAVE_GET_PACKAGE_REWARD], level)
           end
        end

    end

    return 0

end

function TowerSystem:TowerSuccess(avatar, level)
    log_game_debug("TowerSystem:TowerSuccess", "name=%s;dbid=%q;level=%d", avatar.name, avatar.dbid, level)

    local CurrentFloor = avatar.TowerInfo[tower_config.TOWER_INFO_CURRENT_FLOOR] or 0
    if CurrentFloor < level then
        avatar.TowerInfo[tower_config.TOWER_INFO_CURRENT_FLOOR] = level
    end

--    local HighestFloor = avatar.TowerInfo[tower_config.TOWER_INFO_HIGHEST_FLOOR] or 0
    local HighestFloor = avatar.TowerHighestFloor
    if HighestFloor < level then
        avatar.TowerHighestFloor = level
        avatar.TowerInfo[tower_config.TOWER_INFO_HIGHEST_FLOOR] = level
    end

    avatar.TowerInfo[tower_config.TOWER_INFO_LAST_SUCCESS_TIMES] = os.time()

    self:GetPackage(avatar, level)

    log_game_debug("TowerSystem:TowerSuccess", "name=%s;dbid=%q;level=%d;result=%s", avatar.name, avatar.dbid, level, mogo.cPickle(avatar.TowerInfo))

    --设置当前副本已经成功
    avatar.state = mogo.sset(avatar.state, state_config.STATE_TOWER_CURRENT_FLOOR_SUCCESS)

--    local TowerInfo = mogo.deepcopy1(avatar.TowerInfo)
--    avatar.TowerInfo = TowerInfo
    avatar:triggerEvent(event_config.EVENT_FINISH_TOWER, event_config.EVENT_FINISH_TOWER, avatar.TowerInfo[tower_config.TOWER_INFO_CURRENT_FLOOR] or 0)

    --试炼之塔每一层胜利后通知湮灭之门
    avatar.oblivionGateSystem:TriggerGate(2)

    --完成了试炼之塔一层以后触发
    avatar:OnFinishTower(avatar.TowerInfo[tower_config.TOWER_INFO_CURRENT_FLOOR] or 0)

    return 0
end

function TowerSystem:SendReward(avatar, arg1, arg2, RewardStr)
    log_game_debug("TowerSystem:SendReward", "name=%s;dbid=%q;arg1=%d;arg2=%d;RewardStr=%s", avatar.name, avatar.dbid, arg1, arg2, RewardStr)

    local Reward = mogo.cUnpickle(RewardStr)
    if Reward then

        --把副本的临时奖励池道具移到玩家的临时奖励池
        if Reward[public_config.PLAYER_INFO_REWARDS_ITEMS] then
            if not avatar.TowerInfo[tower_config.TOWER_INFO_PACKAGES_POOL] then
                avatar.TowerInfo[tower_config.TOWER_INFO_PACKAGES_POOL] = {}
            end
            for id, count in pairs(Reward[public_config.PLAYER_INFO_REWARDS_ITEMS]) do
                local ItemCount = avatar.TowerInfo[tower_config.TOWER_INFO_PACKAGES_POOL][id]
                if ItemCount then
                    avatar.TowerInfo[tower_config.TOWER_INFO_PACKAGES_POOL][id] = ItemCount + count
                else
                    avatar.TowerInfo[tower_config.TOWER_INFO_PACKAGES_POOL][id] = count
                end
            end
        end

        if Reward[public_config.PLAYER_INFO_REWARDS_MONEY] > 0 then
            if not avatar.TowerInfo[tower_config.TOWER_INFO_PACKAGES_POOL_MONEY] then
                avatar.TowerInfo[tower_config.TOWER_INFO_PACKAGES_POOL_MONEY] = 0
            end
            local Money = avatar.TowerInfo[tower_config.TOWER_INFO_PACKAGES_POOL_MONEY] 
            avatar.TowerInfo[tower_config.TOWER_INFO_PACKAGES_POOL_MONEY] = Money + Reward[public_config.PLAYER_INFO_REWARDS_MONEY]
        end

        if Reward[public_config.PLAYER_INFO_REWARDS_EXP] > 0 then
            if not avatar.TowerInfo[tower_config.TOWER_INFO_PACKAGES_POOL_EXP] then
                avatar.TowerInfo[tower_config.TOWER_INFO_PACKAGES_POOL_EXP] = 0
            end
            local Exp = avatar.TowerInfo[tower_config.TOWER_INFO_PACKAGES_POOL_EXP] 
            avatar.TowerInfo[tower_config.TOWER_INFO_PACKAGES_POOL_EXP] = Exp + Reward[public_config.PLAYER_INFO_REWARDS_EXP]
        end

        log_game_debug("TowerSystem:SendReward", "name=%s;dbid=%q;RewardStr=%s;PoolStr=%s", avatar.name, avatar.dbid, RewardStr, mogo.cPickle(avatar.TowerInfo))

--        local TowerInfo = mogo.deepcopy1(self.ptr.theOwner.TowerInfo)
--        self.ptr.theOwner.TowerInfo = TowerInfo

    end

    return 0
end

--记录失败次数和上次失败时间
function TowerSystem:TowerFail(avatar, level)
    log_game_debug("TowerSystem:TowerFail", "name=%s;dbid=%q;level=%d", avatar.name, avatar.dbid, level)

    local failTimes = avatar.TowerInfo[tower_config.TOWER_INFO_FAIL_TIMES] or 0
    avatar.TowerInfo[tower_config.TOWER_INFO_FAIL_TIMES] = failTimes + 1

    avatar.TowerInfo[tower_config.TOWER_INFO_LAST_FAIL_TIME] = os.time()

--    local TowerInfo = mogo.deepcopy1(self.ptr.theOwner.TowerInfo)
--    self.ptr.theOwner.TowerInfo = TowerInfo

    return 0

end

function TowerSystem:GetPackageReward(avatar)

    --获取宝箱的奖励
    if avatar.TowerInfo[tower_config.TOWER_INFO_NOT_HAVE_GET_PACKAGE_REWARD] then
        local GotPackage = avatar.TowerInfo[tower_config.TOWER_INFO_GOT_PACKAGES] or {}
        local NotGetPackage = avatar.TowerInfo[tower_config.TOWER_INFO_NOT_HAVE_GET_PACKAGE_REWARD] or {}

        local ItemsCanNotInBag = {}
        local flag1 = false

        for _, level in pairs(GotPackage) do

            local flag = false
            local index = 0
            for k, v in pairs(NotGetPackage) do
                if v == level then
                    flag = true
                    index = k
                    break
                end
            end

            if flag then
                local Reward = gTowerDataMgr:GetRewardByLevel(level)

                if Reward and Reward['item'] then
                    Reward = Reward['item']


                    log_game_debug("TowerSystem:GetPackageReward GetPackage", "name=%s;dbid=%q;level=%d;Reward=%s", avatar.name, avatar.dbid, level, mogo.cPickle(Reward))

                    for id, count in pairs(Reward) do

                        if id == 1 then
                            avatar:AddExp(count, reason_def.tower_treasure)
                        elseif id == 2 then
                            avatar:AddGold(count, reason_def.tower_treasure)
                        elseif id == 3 then
                            avatar:AddDiamond(count, reason_def.tower_treasure)
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
                end
                avatar.TowerInfo[tower_config.TOWER_INFO_NOT_HAVE_GET_PACKAGE_REWARD][index] = nil
            end
        end


        if flag1 then
            --                        globalbase_call('MailMgr', 'SendEx', "试炼之塔宝箱",                  --title
            --                            "试炼之塔宝箱",                                                        --to
            --                            "试炼之塔宝箱",                                                        --text
            --                            "试炼之塔宝箱",                                                        --from
            --                            os.time(),                                                              --time
            --                            ItemsCanNotInBag,                                                        --道具
            --                            {[1]=avatar.dbid,},                                                      --收件者的dbid列表
            --                            reason_def.tower_treasure
            --                        )

            log_game_debug("TowerSystem:GetPackageReward send mail", "dbid=%q;name=%s;ItemsCanNotInBag=%s", avatar.dbid, avatar.name, mogo.cPickle(ItemsCanNotInBag))

            globalbase_call('MailMgr', 'SendIdEx', g_text_id.TOWER,                 --title
                avatar.name,                                                              --to
                g_text_id.TOWER_NEW,                                                      --text
                g_text_id.TOWER,                                                          --from
                os.time(),                                                                --time
                ItemsCanNotInBag,                                                         --道具
                {[1]=avatar.dbid,},                                                        --收件者的dbid列表
                {},
                reason_def.tower
            )
        end

    end

end

function TowerSystem:OnChangeScene(avatar, scene)


    if scene ~= g_GlobalParamsMgr:GetParams('init_scene', 10004) then
        local Items = avatar.TowerInfo[tower_config.TOWER_INFO_PACKAGES_POOL] or {}
        log_game_debug("TowerSystem:OnChangeScene", "name=%s;dbid=%q;Items=%s", avatar.name, avatar.dbid, mogo.cPickle(Items))
        return
    end

    local Items = avatar.TowerInfo[tower_config.TOWER_INFO_PACKAGES_POOL] or {}
    local Money = avatar.TowerInfo[tower_config.TOWER_INFO_PACKAGES_POOL_MONEY] or 0
    local Exp = avatar.TowerInfo[tower_config.TOWER_INFO_PACKAGES_POOL_EXP] or 0

    log_game_debug("TowerSystem:OnChangeScene", "name=%s;dbid=%q;level=%d;scene=%d;Items=%s;Money=%d;Exp=%d", avatar.name, avatar.dbid, avatar.level, scene, mogo.cPickle(Items), Money, Exp)

    local flag = false
    local now = os.time()

    --发战报
    if Items and Items ~= {} then

        local ItemsCanNotInBag = {}
        local flag1 = false

        --发道具
        for id, count in pairs(Items) do
            flag = true

            if id == 1 then
                avatar:AddExp(count, reason_def.tower_treasure)
            elseif id == 2 then
                avatar:AddGold(count, reason_def.tower_treasure)
            elseif id == 3 then
                avatar:AddDiamond(count, reason_def.tower_treasure)
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
--            globalbase_call('MailMgr', 'SendEx', "试炼之塔",                  --title
--                "试炼之塔",                                                         --to
--                "试炼之塔",                                                         --text
--                "试炼之塔",                                                         --from
--                os.time(),                                                           --time
--                ItemsCanNotInBag,                                                    --道具
--                {[1]=avatar.dbid,},                                                  --收件者的dbid列表
--                reason_def.tower
--            )

            log_game_debug("TowerSystem:OnChangeScene send mail", "dbid=%q;name=%s;ItemsCanNotInBag=%s", avatar.dbid, avatar.name, mogo.cPickle(ItemsCanNotInBag))

            globalbase_call('MailMgr', 'SendIdEx', g_text_id.TOWER,                   --title
                avatar.name,                                                                --to
                g_text_id.TOWER_NEW,                                                        --text
                g_text_id.TOWER,                                                            --from
                now,                                                                         --time
                ItemsCanNotInBag,                                                            --道具
                {[1]=avatar.dbid,},                                                          --收件者的dbid列表
                {},
                reason_def.tower
            )
        end

        avatar.TowerInfo[tower_config.TOWER_INFO_PACKAGES_POOL] = {}
    end

    if Money > 0 then
        flag = true
        avatar:AddGold(Money, reason_def.tower)
        avatar.TowerInfo[tower_config.TOWER_INFO_PACKAGES_POOL_MONEY] = 0
    end

    if Exp > 0 then
        flag = true
        avatar:AddExp(Exp, reason_def.tower)
        avatar.TowerInfo[tower_config.TOWER_INFO_PACKAGES_POOL_EXP] = 0
    end

    --获取宝箱的奖励
    self:GetPackageReward(avatar)

    if flag then
        --返回格式：
        --{1=经验,2=道具列表,3=钱, 4=已获取宝箱}
        local result = {[1]=Exp, [2]=Items, [3]=Money, [4]=avatar.TowerInfo[tower_config.TOWER_INFO_GOT_PACKAGES]}

        if avatar:hasClient() then
            avatar.client.TowerResp(action_config.MSG_CLIENT_REPORT, result)
        end

--        --弹出战报之后刷新UI界面
--        self:GetTowerInfo(avatar)

        log_game_debug("TowerSystem:OnChangeScene", "name=%s;dbid=%q;level=%d;result=%s", avatar.name, avatar.dbid, avatar.level, mogo.cPickle(result))
    else
        log_game_warning("TowerSystem:OnChangeScene no report", "name=%s;dbid=%q;level=%d", avatar.name, avatar.dbid, avatar.level)
    end

    if avatar.TowerInfo[tower_config.TOWER_INFO_LAST_ENTER_TIME] then
        local Today = lua_util.get_yyyymmdd(now)
        local Date = lua_util.get_yyyymmdd(avatar.TowerInfo[tower_config.TOWER_INFO_LAST_ENTER_TIME])

        if Today ~= Date then
            --玩家上一次进入是在当天的0点前，则清空一次数据
            self:ClearData(avatar)
        end
    end

--    local TowerInfo = mogo.deepcopy1(avatar.TowerInfo)
--    avatar.TowerInfo = TowerInfo

end

--清空当天的数据
function TowerSystem:ClearData(avatar)
    log_game_info("TowerSystem:ClearData", "dbid=%q;name=%s", avatar.dbid, avatar.name)

    --0点清空失败次数
    avatar.TowerInfo[tower_config.TOWER_INFO_FAIL_TIMES] = 0

    --0点清空当前层数
    avatar.TowerInfo[tower_config.TOWER_INFO_CURRENT_FLOOR] = 0

    --清空已获得的宝箱列表
    avatar.TowerInfo[tower_config.TOWER_INFO_GOT_PACKAGES] = {}

    --清空每天已经使用的vip扫荡次数
    avatar.TowerInfo[tower_config.TOWER_INFO_VIP_SWEEP_TIMES] = 0

    --每天清空扫荡充值扫荡副本次数
    avatar.TowerInfo[tower_config.TOWER_INFO_CLEAR_SWEEP_CD_TIMES] = 0

    --给user_data的lua_table类型的字段整体赋值，令其为脏数据
    --    local TowerInfo = mogo.deepcopy1(avatar.TowerInfo)
    --    avatar.TowerInfo = TowerInfo
    return 0
end

--获取当前层数
function TowerSystem:GetCurFloor(avatar)
      return (avatar.TowerInfo[tower_config.TOWER_INFO_CURRENT_FLOOR] or 0) 
end

function TowerSystem:SendTowerInfo(avatar)

    local CurrentFloor = avatar.TowerInfo[tower_config.TOWER_INFO_CURRENT_FLOOR] or 0
    log_game_debug("TowerSystem:SendTowerInfo", "name=%s;dbid=%q;level=%d;CurrentFloor=%d", avatar.name, avatar.dbid, avatar.level, CurrentFloor)

    if avatar:hasClient() then
        avatar.client.TowerResp(action_config.MSG_TOWER_NOTIFY_COUNT_DOWN, {g_GlobalParamsMgr:GetParams('tower_destroy_time', 200), CurrentFloor + 1})
    end

    return 0
end


gTowerSystem = TowerSystem
return gTowerSystem


