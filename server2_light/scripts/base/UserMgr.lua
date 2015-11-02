--todo优化项：20级以下的不作战斗数值装备等缓存，雇佣兵选择等

require "lua_util"
require "public_config"
require "avatar_level_data"
require "mercenary_config"
require "GlobalParams"
require "attri_cal"
require "arena_config"
require "global_data"
require "error_code"
require "channel_config"
--require "action_config"
--local channel_mgr = require "mgr_channel"


local log_game_debug   = lua_util.log_game_debug
local log_game_warning = lua_util.log_game_warning
local log_game_info    = lua_util.log_game_info
local log_game_error   = lua_util.log_game_error
--local generic_base_call = lua_util.generic_base_call
--local mailbox_call = lua_util.mailbox_call
--local mailbox_client_call = lua_util.mailbox_client_call
local globalbase_call = lua_util.globalbase_call

local PLAYER_BASE_MB_INDEX           = public_config.USER_MGR_PLAYER_BASE_MB_INDEX
local PLAYER_CELL_MB_INDEX           = public_config.USER_MGR_PLAYER_CELL_MB_INDEX
local PLAYER_DBID_INDEX              = public_config.USER_MGR_PLAYER_DBID_INDEX
local PLAYER_NAME_INDEX              = public_config.USER_MGR_PLAYER_NAME_INDEX
local PLAYER_LEVEL_INDEX             = public_config.USER_MGR_PLAYER_LEVEL_INDEX
local PLAYER_VOCATION_INDEX          = public_config.USER_MGR_PLAYER_VOCATION_INDEX
local PLAYER_GENDER_INDEX            = public_config.USER_MGR_PLAYER_GENDER_INDEX
local PLAYER_UNION_INDEX             = public_config.USER_MGR_PLAYER_UNION_INDEX
local PLAYER_FIGHT_INDEX             = public_config.USER_MGR_PLAYER_FIGHT_INDEX --todo:优化
local PLAYER_IS_ONLINE_INDEX         = public_config.USER_MGR_PLAYER_IS_ONLINE_INDEX
local PLAYER_FRIEND_NUM_INDEX        = public_config.USER_MGR_PLAYER_FRIEND_NUM_INDEX         --好友數量
local PLAYER_OFFLINETIME_INDEX       = public_config.USER_MGR_PLAYER_OFFLINETIME_INDEX
-->以下存盘字段begin
local PLAYER_ITEMS_INDEX             = public_config.USER_MGR_PLAYER_ITEMS_INDEX            --只缓存身上装备信息，但是会从数据load符文信息来算战斗力，计算完会delete
local PLAYER_BATTLE_PROPS_INDEX      = public_config.USER_MGR_PLAYER_BATTLE_PROPS
local PLAYER_SKILL_BAG_INDEX         = public_config.USER_MGR_PLAYER_SKILL_BAG
--<end
local PLAYER_LOADED_ITEMS_INDEX      = public_config.USER_MGR_PLAYER_LOADED_ITEMS    --todo:delete

--local PLAYER_BODY_INDEX = public_config.USER_MGR_PLAYER_BODY_INDEX --会从数据load身体信息来算战斗力，计算完会delete
local PLAYER_ARENIC_FIGHT_RANK_INDEX = public_config.USER_MGR_PLAYER_ARENIC_FIGHT_RANK_INDEX
local PLAYER_ARENIC_GRADE_INDEX      = public_config.USER_MGR_PLAYER_ARENIC_GRADE_INDEX
local PLAYER_GM_SETTING              = public_config.USER_MGR_PLAYER_GM_SETTING
local PLAYER_ACCOUNT                 = public_config.USER_MGR_PLAYER_ACCOUNT
--[[UserMgr临时数据]]
local PLAYER_SKILL_BAG_INDEX_TMP     = public_config.USER_MGR_PLAYER_SKILL_BAG_TMP
local PLAYER_ITEMS_INDEX_TMP         = public_config.USER_MGR_PLAYER_ITEMS_INDEX_TMP
local PLAYER_BODY_INDEX_TMP          = public_config.USER_MGR_PLAYER_BODY_INDEX_TMP
local PLAYER_RUNE_INDEX_TMP          = public_config.USER_MGR_PLAYER_RUNE_INDEX_TMP
--[[临时数据]]
--self.m_lFights的下标
local FIGHTS_DBID_INDEX              = public_config.USER_MGR_FIGHTS_DBID_INDEX
local FIGHTS_FIGHT_INDEX             = public_config.USER_MGR_FIGHTS_FIGHT_INDEX --存盘

--------------------在线管理器的好友数量记录-----------------------
--用于离线数据的存储
local userMgrIndex = {
    friendNum = 1,
}

local userMgrItem = {}
userMgrItem.__index = userMgrItem
function userMgrItem:new( friendNum )
    local newItem = {
        [userMgrIndex.friendNum] = friendNum,
    }
    setmetatable(newItem, {__index = userMgrItem})
    return newItem
end

--for test
theTab = {}
local function create_table(dbid)
    --[[
    --这个值会导致内存泄漏，不过这里是不需要销毁的所以允许这样子
    theTab[dbid] = {}
    local proxy = {}
    local meta = {}
    meta.__index = function (t, k)
        return theTab[dbid][k]
    end
    meta.__newindex = function (t, k, v)
        if k == 11 then --PLAYER_FRIEND_NUM_INDEX
            log_game_debug("attempt to change PLAYER_FRIEND_NUM_INDEX", "dbid %q %s", dbid, v)
        end
        theTab[dbid][k] = v
    end
    setmetatable(proxy, meta)
    return proxy
    ]]
    return {}
end

--------------------------------------------------------------------------------------
UserMgr = {}
--UserMgr.__index = UserMgr

setmetatable(UserMgr, {__index = BaseEntity} )
--启动相关
require "UserMgrStartUp"
--定时相关
require "UserMgrTimer"
--竞技场相关
require "UserMgrArena"
--世界boss相关
require "UserMgrWorldBoss"
--redis
require "UserMgrRedis"

require "UserMgrRankList"
--------------------------------------------------------------------------------------
--飞龙事件角色名获取
function UserMgr:EventListAvatarNameReq(mbStr, eList)
    local mb = mogo.UnpickleBaseMailbox(mbStr)
    if not mb then
        return
    end
    for _, event in pairs(eList) do
        local dbid = event[public_config.EVENT_DRAGON_DBID]
        local info = self.DbidToPlayers[dbid] or {}
        local name = info[PLAYER_NAME_INDEX] or ""
        event[public_config.EVENT_DRAGON_NAME] = name
    end
    mb.client.EventListAvatarNameResp(eList)
end
function UserMgr:DragonAttackPvpNameReq(mbStr, atkId, atkedId)
    local players   = self.DbidToPlayers
    local atkName   = players[atkId][PLAYER_NAME_INDEX]
    local atkedName = players[atkedId][PLAYER_NAME_INDEX]
    local atkInfo   = {}
    local atkedInfo = {}
    atkInfo[public_config.DRAGON_PVP_DBID]   = atkId
    atkInfo[public_config.DRAGON_PVP_NAME]   = players[atkId][PLAYER_NAME_INDEX]
    atkInfo[public_config.DRAGON_PVP_LEVEL]  = players[atkId][PLAYER_LEVEL_INDEX]
    atkedInfo[public_config.DRAGON_PVP_DBID] = atkedId
    atkedInfo[public_config.DRAGON_PVP_NAME] = players[atkedId][PLAYER_NAME_INDEX]
    globalbase_call("FlyDragonMgr", "DragonAttackPvpNameCallback", mbStr, atkInfo, atkedInfo)
end

function UserMgr:AddPlayer(dbid, account, gm_setting)
    local player = self.DbidToPlayers[dbid]

    if player then
        log_game_error('UserMgr:AddPlayer','dbid=%q,account=%s',dbid,account)
    else
        self.DbidToPlayers[dbid] = { [PLAYER_ACCOUNT] = account }
        self.DbidToPlayers[dbid][PLAYER_GM_SETTING] = gm_setting or 0
        --更新帐号索引dbid
        self:UpdateAc2Player(info.accountName,dbid)
    end
end

--------------------------------------------------------------------------------------
function UserMgr:PlayerOnLine(PlayerBaseMbStr, PlayerCellMbStr, PlayerDbid, PlayerName, PlayerLevel, PlayerVocation, PlayerGender, PlayerUnionDbid, PlayerFight, PlayerFriendNum)

    --    if not self.DbidToPlayers[PlayerDbid] then
    --        return
    --    end

    log_game_debug("UserMgr:PlayerOnLine", "PlayerBaseMbStr=%s;PlayerCellMbStr=%s;Playerdbid=%q;PlayerName=%s;PlayerLevel=%d;PlayerVocation=%d;PlayerGender=%d;PlayerUniondbid=%q;PlayerFight=%d",
                                            PlayerBaseMbStr, PlayerCellMbStr, PlayerDbid, PlayerName, PlayerLevel, PlayerVocation, PlayerGender, PlayerUnionDbid, PlayerFight)

    local bLogin = false  --是否登录的标记
    local PlayerInfo = self.DbidToPlayers[PlayerDbid]

    if not PlayerInfo then
        PlayerInfo = create_table(PlayerDbid)
    end

    local OldBaseMb = PlayerInfo[PLAYER_BASE_MB_INDEX]
    if PlayerBaseMbStr ~= '' and (OldBaseMb == nil or OldBaseMb == '') then
        self.OnlineCount = self.OnlineCount + 1
        bLogin = true
        log_game_debug("UserMgrOnlineCountAdd", "PlayerDbid=%q;PlayerName=%s;OnlineCount=%d", PlayerDbid, PlayerName, self.OnlineCount)
    end

    --新增离线玩家记录
    --globalbase_call("OfflineMgr", "NewCharacter", PlayerDbid)
    if not self.DbidToPlayers[PlayerDbid] then
        self.DbidToPlayers[PlayerDbid] = {}
    end
    self.DbidToPlayers[PlayerDbid][PLAYER_BASE_MB_INDEX]  = PlayerBaseMbStr
    self.DbidToPlayers[PlayerDbid][PLAYER_CELL_MB_INDEX]  = PlayerCellMbStr
    self.DbidToPlayers[PlayerDbid][PLAYER_DBID_INDEX]     = PlayerDbid
    self.DbidToPlayers[PlayerDbid][PLAYER_NAME_INDEX]     = PlayerName
    self.DbidToPlayers[PlayerDbid][PLAYER_LEVEL_INDEX]    = PlayerLevel
    self.DbidToPlayers[PlayerDbid][PLAYER_VOCATION_INDEX] = PlayerVocation
    self.DbidToPlayers[PlayerDbid][PLAYER_GENDER_INDEX]   = PlayerGender
    self.DbidToPlayers[PlayerDbid][PLAYER_UNION_INDEX]    = PlayerUnionDbid
    --
    --if not self.DbidToPlayers[PlayerDbid][PLAYER_ARENIC_FIGHT_RANK_INDEX] then
    self.DbidToPlayers[PlayerDbid][PLAYER_FIGHT_INDEX]     = PlayerFight
    --end

    self.DbidToPlayers[PlayerDbid][PLAYER_IS_ONLINE_INDEX] = public_config.USER_MGR_PLAYER_ONLINE
    if not self.DbidToPlayers[PlayerDbid][PLAYER_FRIEND_NUM_INDEX] then
        --如果redis上的数据被清掉了，使用角色身上的数据
        self.DbidToPlayers[PlayerDbid][PLAYER_FRIEND_NUM_INDEX] = PlayerFriendNum
    end
    self.DbidToPlayers[PlayerDbid][PLAYER_OFFLINETIME_INDEX] = os.time()
    --这种情况是刚刚创建角色
    if PlayerBaseMbStr == '' then
        self.DbidToPlayers[PlayerDbid][PLAYER_IS_ONLINE_INDEX] = public_config.USER_MGR_PLAYER_OFFLINE
    end
    if PlayerUnionDbid > 0 then
        local PlayerDbids = self.UnionDbidToPlayerDbid[PlayerUnionDbid]
        if PlayerDbids then
            table.insert(PlayerDbids, PlayerDbid)
        else
            PlayerDbids = {}
            table.insert(PlayerDbids, PlayerDbid)
        end
    end

    self.NameToDbid[PlayerName] = PlayerDbid

    self:__updateLevel(self.DbidToPlayers[PlayerDbid], PlayerDbid, PlayerLevel)
    --获取所有不在线时的消息
    if PlayerBaseMbStr and PlayerBaseMbStr ~= '' then
        local mb = mogo.UnpickleBaseMailbox(PlayerBaseMbStr)
        if mb then
            local fight_rank = self.DbidToPlayers[PlayerDbid][PLAYER_ARENIC_FIGHT_RANK_INDEX]
            local fight_max  = self.DbidToPlayers[PlayerDbid][PLAYER_FIGHT_INDEX]
            if fight_rank and fight_rank > 1 then
                fight_max = self.m_lFights[fight_rank][FIGHTS_FIGHT_INDEX]
            end
            local params = {
                ["fightMax"] = fight_max
            }
            --更新avatar的缓存数据
            mb.LoginUserMgr(params)
            
            if bLogin then
                mb.onEnterGame()
            end
        end
    end
    --    self:DestroyCellEntity()
end

function UserMgr:PlayerOffLine(PlayerDbid)

    local PlayerInfo = self.DbidToPlayers[PlayerDbid]
    if PlayerInfo then
        self.DbidToPlayers[PlayerDbid][PLAYER_BASE_MB_INDEX] = nil
        self.DbidToPlayers[PlayerDbid][PLAYER_CELL_MB_INDEX] = nil
        self.DbidToPlayers[PlayerDbid][PLAYER_IS_ONLINE_INDEX] = public_config.USER_MGR_PLAYER_OFFLINE
    end

    self.OnlineCount = math.max((self.OnlineCount - 1), 0)

    log_game_debug("UserMgrOnlineCountSub", "Playerdbid=%q;OnlineCount=%d", PlayerDbid, self.OnlineCount)
    log_game_debug("UserMgr:PlayerOffLine", "Playerdbid=%q;OnlineCount=%d", PlayerDbid, self.OnlineCount)

end

function UserMgr:QueryInfoByPlayerName(MsgId, MbStr, PlayerName)

    log_game_debug("UserMgr:QueryInfoByPlayerName", "MsgId=%d;MbStr=%s;PlayerName=%s", MsgId, MbStr, PlayerName)

    local mb = mogo.UnpickleBaseMailbox(MbStr)
    if mb then
        local PlayerDbid = self.NameToDbid[PlayerName]
        if PlayerDbid then
            local PlayerInfo = self.DbidToPlayers[PlayerDbid]
            if PlayerInfo then
                --查询者需要实现该方法
                mb.QueryInfoByPlayerNameResp(MsgId, PlayerName, PlayerInfo)
            else
                mb.QueryInfoByPlayerNameResp(MsgId, PlayerName, {})
            end
        else
            mb.QueryInfoByPlayerNameResp(MsgId, PlayerName, {})
        end
    end

end

function UserMgr:QueryInfoByPlayerDbid(MsgId, MbStr, PlayerDbid)

    log_game_debug("UserMgr:QueryInfoByPlayerDbid", "MsgId=%d;MbStr=%s;PlayerDbid=%s", MsgId, MbStr, PlayerDbid)

    local mb = mogo.UnpickleBaseMailbox(MbStr)
    if mb then
        local PlayerInfo = self.DbidToPlayers[PlayerDbid]
        if PlayerInfo then
            --查询者需要实现该方法
            mb.QueryInfoByPlayerDbidResp(MsgId, PlayerDbid, PlayerInfo)
        else
            mb.QueryInfoByPlayerDbidResp(MsgId, PlayerDbid, {})
        end
    end

end

function UserMgr:CampaignGetOnlineFriends(MbStr, PlayerDbid, friendDbids, CampaignId)

    log_game_debug("UserMgr:CampaignGetOnlineFriends", "MbStr=%s;PlayerDbid=%q;friendDbids=%s;CampaignId=%d", MbStr, PlayerDbid, mogo.cPickle(friendDbids), CampaignId)

    local result = {}
    for dbid, _ in pairs(friendDbids) do

        local PlayerInfo = self.DbidToPlayers[dbid]
        if PlayerInfo and PlayerInfo[PLAYER_IS_ONLINE_INDEX] == public_config.USER_MGR_PLAYER_ONLINE then
            table.insert(result, {
                                  [1] = dbid,
                                  [2] = PlayerInfo[PLAYER_NAME_INDEX],
                                  [3] = PlayerInfo[PLAYER_LEVEL_INDEX],
                                  [4] = PlayerInfo[PLAYER_FIGHT_INDEX],
                                  [5] = PlayerInfo[PLAYER_FIGHT_INDEX],
                                  [6] = PlayerInfo[PLAYER_VOCATION_INDEX],
                                 })
        end
    end

    log_game_debug("UserMgr:CampaignGetOnlineFriends", "MbStr=%s;PlayerDbid=%q;result=%s;CampaignId=%d", MbStr, PlayerDbid, mogo.cPickle(result), CampaignId)

    --得到最后结果
    local mb = mogo.UnpickleBaseMailbox(MbStr)
    if mb then
        mb.client.CampaignResp(action_config.MSG_CAMPAIGN_GET_ONLINE_FRIENDS, 0, result)
    end
end

function UserMgr:CampaignInvite(MbStr, PlayerDbid, PlayerName, CampaignId, InvitedPlayerDbid)
    log_game_debug("UserMgr:CampaignInvite", "MbStr=%s;PlayerDbid=%q;PlayerName=%s;CampaignId=%d;InvitedPlayerDbid=%q", MbStr, PlayerDbid, PlayerName, CampaignId, InvitedPlayerDbid)

    local PlayerInfo = self.DbidToPlayers[InvitedPlayerDbid]
    if not PlayerInfo then
        --被邀请的玩家不存在
        local mb = mogo.UnpickleBaseMailbox(MbStr)
        if mb then
            mb.client.CampaignResp(action_config.MSG_CAMPAIGN_INVITE, error_code.ERR_ACTIVITE_INVITE_NOT_EXIT, {})
        end
        return
    end

    if PlayerInfo[PLAYER_IS_ONLINE_INDEX] == public_config.USER_MGR_PLAYER_OFFLINE then
        --被邀请的玩家不在线
        local mb = mogo.UnpickleBaseMailbox(MbStr)
        if mb then
            mb.client.CampaignResp(action_config.MSG_CAMPAIGN_INVITE, error_code.ERR_ACTIVITE_INVITE_NOT_ONLINE, {})
        end
        return
    end

    --校验等级是否满足要求

    globalbase_call('ActivityMgr', 'CampaignInvite', MbStr, PlayerDbid, PlayerName, CampaignId, InvitedPlayerDbid, PlayerInfo[PLAYER_BASE_MB_INDEX])
end

--获取系统推荐的雇佣兵列表
--modify ///佣兵
function UserMgr:QueryMercenaryList(MbStr, selfDbid, FriendDbids)
    log_game_debug("UserMgr:QueryMercenaryList", "MbStr=%s" , MbStr)

    local selfInfo = self.DbidToPlayers[selfDbid]
    if not selfInfo then
        return
    end

    --    --如果除去玩家自己以外的总人数少于3，则把剩余人数全部作为推荐人数
    --    if (#self.LevelToDbid - 1) < 3 then
    --    end

    local result = {}
    for dbid, lastHireTime in pairs(FriendDbids) do
        if #result >= 2 then
            break
        end
        local now = os.time()
        if now - lastHireTime > 
            g_GlobalParamsMgr:GetParams('mercenary_friends_timesup', public_config.FRIEND_HIRE_TIMESUP) then
            
            local PlayerInfo = self.DbidToPlayers[dbid]
            if PlayerInfo then
                --获取3天内登录过的好友
                if PlayerInfo[PLAYER_LEVEL_INDEX] >= public_config.USER_MGR_DETAIL_DATA_CACHE_LEVEL and 
                    now - PlayerInfo[PLAYER_OFFLINETIME_INDEX] < 
                    g_GlobalParamsMgr:GetParams('mercenary_friends_offline_time', 3 * 24 * 3600) then
                    table.insert(result, {PlayerInfo[PLAYER_DBID_INDEX], 
                              PlayerInfo[PLAYER_NAME_INDEX], 
                              PlayerInfo[PLAYER_LEVEL_INDEX], 
                              PlayerInfo[PLAYER_VOCATION_INDEX], 
                              PlayerInfo[PLAYER_GENDER_INDEX], 
                              PlayerInfo[PLAYER_FIGHT_INDEX],
                              1}) --1:is friend
                end
            else
                log_game_error("UserMgr:QueryMercenaryList", "")
            end
        end 
    end

    local selfLevel = selfInfo[PLAYER_LEVEL_INDEX]
    if selfLevel >= public_config.USER_MGR_DETAIL_DATA_CACHE_LEVEL then
        local dbids = self.LevelToDbid[selfLevel] or {}

        for dbid, _ in pairs(dbids) do
            if #result == 3 then
                break
            end
            if not FriendDbids[dbid] and dbid ~= selfDbid then
                local PlayerInfo = self.DbidToPlayers[dbid]
                table.insert(result, {PlayerInfo[PLAYER_DBID_INDEX], 
                                      PlayerInfo[PLAYER_NAME_INDEX], 
                                      PlayerInfo[PLAYER_LEVEL_INDEX], 
                                      PlayerInfo[PLAYER_VOCATION_INDEX], 
                                      PlayerInfo[PLAYER_GENDER_INDEX], 
                                      PlayerInfo[PLAYER_FIGHT_INDEX],
                                      0}) --0:not my friend
            end
        end
    end

    local nowLevel = selfLevel
    if nowLevel < public_config.USER_MGR_DETAIL_DATA_CACHE_LEVEL then
        nowLevel = public_config.USER_MGR_DETAIL_DATA_CACHE_LEVEL - 1
    end

    while nowLevel < g_GlobalParamsMgr:GetParams('max_level', 60) and #result < 3 do
        nowLevel = nowLevel + 1
        local dbids = self.LevelToDbid[nowLevel]
        if dbids then
            for dbid, _ in pairs(dbids) do
                if #result == 3 then
                    break
                end
    
                if not FriendDbids[dbid] and dbid ~= selfDbid then
                    local PlayerInfo = self.DbidToPlayers[dbid]
--                print('insert:3',PlayerInfo[PLAYER_DBID_INDEX],PlayerInfo[PLAYER_NAME_INDEX],PlayerInfo[PLAYER_LEVEL_INDEX],PlayerInfo[PLAYER_VOCATION_INDEX], PlayerInfo[PLAYER_GENDER_INDEX], PlayerInfo[PLAYER_FIGHT_INDEX])
                    table.insert(result, {PlayerInfo[PLAYER_DBID_INDEX], 
                                          PlayerInfo[PLAYER_NAME_INDEX], 
                                          PlayerInfo[PLAYER_LEVEL_INDEX], 
                                          PlayerInfo[PLAYER_VOCATION_INDEX], 
                                          PlayerInfo[PLAYER_GENDER_INDEX], 
                                          PlayerInfo[PLAYER_FIGHT_INDEX],
                                          0}) --0:not my friend
                end
            end
        end
    end

    nowLevel = selfLevel

    while nowLevel > public_config.USER_MGR_DETAIL_DATA_CACHE_LEVEL and #result < 3 do
        nowLevel = nowLevel - 1

        local dbids = self.LevelToDbid[nowLevel]
        if dbids then
            for dbid, _ in pairs(dbids) do
                if #result == 3 then
                    break
                end

                if not FriendDbids[dbid] and dbid ~= selfDbid then
                    local PlayerInfo = self.DbidToPlayers[dbid]
--                print('insert4:',PlayerInfo[PLAYER_DBID_INDEX],PlayerInfo[PLAYER_NAME_INDEX],PlayerInfo[PLAYER_LEVEL_INDEX],PlayerInfo[PLAYER_VOCATION_INDEX], PlayerInfo[PLAYER_GENDER_INDEX], PlayerInfo[PLAYER_FIGHT_INDEX])
                    table.insert(result, {PlayerInfo[PLAYER_DBID_INDEX], 
                                          PlayerInfo[PLAYER_NAME_INDEX], 
                                          PlayerInfo[PLAYER_LEVEL_INDEX], 
                                          PlayerInfo[PLAYER_VOCATION_INDEX], 
                                          PlayerInfo[PLAYER_GENDER_INDEX], 
                                          PlayerInfo[PLAYER_FIGHT_INDEX],
                                          0}) --0:not my friend
                end
            end
        end
    end

    --得到最后结果
    local mb = mogo.UnpickleBaseMailbox(MbStr)
    if mb then
        mb.MercenaryInfoCallBack(result)
    end

end

-- rpc中转调用，这里是无论对方在线与否都离线消息处理
--如果CbId == 0不回调调用,如果PmsgId == 0不中转调用,
--Oper 0:不做离线处理，1：对方离线做离线处理， 2：无论对方在线与否都做离线处理
function UserMgr:RpcRelayCall( myDbid, CbId, PlayerDbid, PmsgId, ParamTab, Oper, OffType, OffItem)
    --log_game_debug("UserMgr:RelayCall", "CbId = %d, PmsgId = %d", CbId, PmsgId)
    --local mb = mogo.UnpickleBaseMailbox(MbStr)
    local myPlayerInfo = self.DbidToPlayers[myDbid]
    
    if not myPlayerInfo[PLAYER_BASE_MB_INDEX] then
        log_game_error('UserMgr:RelayCall', 'have no myPlayerInfo.')
        return
    end

    local mb = mogo.UnpickleBaseMailbox(myPlayerInfo[PLAYER_BASE_MB_INDEX])
    if not mb then
        log_game_error('UserMgr:RelayCall', 'have no mb.')
        return
    end

    local err = error_code.ERR_USER_MGR_SUCCEED
    local PlayerInfo = self.DbidToPlayers[PlayerDbid]
    --回调
    local function callback( errID )
        if CbId ~= 0 then
            --调用者需要实现该方法
            PlayerInfo = PlayerInfo or {}
            mb.RpcRelayCallback(CbId, PlayerDbid, PlayerInfo, errID)
        end
    end
    if not PlayerInfo then
        log_game_error('UserMgr:RelayCall', 'have no PlayerInfo.')
        callback(error_code.ERR_USER_MGR_PLAYER_NOT_EXISTS)
        return
    end
    -->为接受\删除好友请求特殊处理
    local function SpecialDeal( )
        --好友请求, 如果对方好友已满提示申请人
        if CbId == msgUserMgr.MSG_USER_FRIEND_ADD_REQ then
            local otherFriendNum = PlayerInfo[PLAYER_FRIEND_NUM_INDEX] or 0
            if otherFriendNum >= g_GlobalParamsMgr:GetParams('friend_limit', public_config.FRIEND_MAX_LIMIT) then
                callback(error_code.ERR_USER_MGR_PLAYER_FRIEND_FULL)
                --发现对方好友已满不通知对面
                return -1
            end
        --好友答应
        elseif CbId == msgUserMgr.MSG_USER_FRIEND_ACCEPT then
            local otherFriendNum = PlayerInfo[PLAYER_FRIEND_NUM_INDEX] or 0
            local myFriendNum = myPlayerInfo[PLAYER_FRIEND_NUM_INDEX] or 0
            if otherFriendNum >= g_GlobalParamsMgr:GetParams('friend_limit', public_config.FRIEND_MAX_LIMIT) then
                callback(error_code.ERR_USER_MGR_PLAYER_FRIEND_FULL)
                --发现对方好友已满不通知对面
                return -1
            elseif myFriendNum >= g_GlobalParamsMgr:GetParams('friend_limit', public_config.FRIEND_MAX_LIMIT) then
                callback(error_code.ERR_USER_MGR_MY_FRIEND_FULL)
                --发现对方好友已满不通知对面
                return -1
            else 
                --双方的好友数量同时+1
                self:PlayerFriendNumChange(PlayerDbid, otherFriendNum + 1)
                self:PlayerFriendNumChange(myDbid, myFriendNum + 1)
            end
        --好友删除
        elseif PmsgId == msgUserMgr.MSG_USER_FRIEND_DEL_REQ_BE then
            local otherFriendNum = PlayerInfo[PLAYER_FRIEND_NUM_INDEX] or 0
            local myFriendNum = myPlayerInfo[PLAYER_FRIEND_NUM_INDEX] or 0
            --双方的好友数量同时+1，预防一直不上线玩家的好友申请可以一直被加
            --self:PlayerFriendNumChange(PlayerDbid, otherFriendNum - 1) --用DeleteMyFriendNumBe代替
            --self:PlayerFriendNumChange(myDbid, myFriendNum - 1)
        else

        end
        return 0   
    end
    local ret = SpecialDeal()
    if ret ~= 0 then
        return
    end
    --<为接受\删除好友请求特殊处理

    if PmsgId ~= 0 then
        if PlayerInfo[PLAYER_IS_ONLINE_INDEX] == public_config.USER_MGR_PLAYER_ONLINE then
            log_game_debug("UserMgr:RelayCall", "the player is online.")
            local pmbStr = PlayerInfo[PLAYER_BASE_MB_INDEX]
            local pmb = mogo.UnpickleBaseMailbox(pmbStr)
            --被调用者需要实现该方法
            pmb.BeRpcRelayCall(PmsgId, ParamTab)
        else 
            err = error_code.ERR_USER_MGR_OFFLINE
            if 1 == Oper then
                --交给离线管理器处理
                globalbase_call("OfflineMgr", "Add", 
                    OffType, PlayerDbid, OffItem)
            end
        end
    end
    if 2 == Oper then
        --交给离线管理器处理
        globalbase_call("OfflineMgr", "Add", 
            OffType, PlayerDbid, OffItem)
    end
    callback(err)
end

--被动的减少自己的好友数量
function UserMgr:DeleteMyFriendNumBe(dbid)
    local theInfo = self.DbidToPlayers[dbid]
    if not theInfo then return end
    local myFriendNum = theInfo[PLAYER_FRIEND_NUM_INDEX] or 0
    self:PlayerFriendNumChange(dbid, myFriendNum - 1)
end

function UserMgr:QueryInfoByPlayerDbids(MsgId, MbStr, PlayerDbids, Format)

    log_game_debug("UserMgr:QueryInfoByPlayerDbids", "MsgId=%d;MbStr=%s;Format=%s", MsgId, MbStr, mogo.cPickle(Format))

    local result = {}
    for _, PlayerDbid in pairs(PlayerDbids) do
        local PlayerInfo = self.DbidToPlayers[PlayerDbid]
        log_game_debug("UserMgr:QueryInfoByPlayerDbids", "MsgId=%d;MbStr=%s;Playerdbid=%q;PlayerInfo=%s",
                                                          MsgId, MbStr, PlayerDbid, mogo.cPickle(PlayerInfo))
        local item = {}
        --local function FormatData()
        for _, k in pairs(Format) do
            --table.insert(item, PlayerInfo[k])
            item[k] = PlayerInfo[k]
        end
        --end
        --FormatData()
        table.insert(result, item)
    end
    local mb = mogo.UnpickleBaseMailbox(MbStr)
    if mb then
        mb.QueryInfoByPlayerDbidResp(MsgId, 0, result)
    end

end

function UserMgr:GuildQueryInfoByPlayerDbids(GuildDbid, MbStr, PlayerDbids, Format)

    log_game_debug("UserMgr:GuildQueryInfoByPlayerDbids", "Guilddbid=%q;MbStr=%s;Format=%s", GuildDbid, MbStr, mogo.cPickle(Format))

    local result = {}
    for _, PlayerDbid in pairs(PlayerDbids) do
        local PlayerInfo = self.DbidToPlayers[PlayerDbid]
        log_game_debug("UserMgr:QueryInfoByPlayerDbids", "MsgId=%d;MbStr=%s;Playerdbid=%q;PlayerInfo=%s",
                                                          GuildDbid, MbStr, PlayerDbid, mogo.cPickle(PlayerInfo))

        --设置该玩家的公会ID
        PlayerInfo[PLAYER_UNION_INDEX] = GuildDbid

        local item = {}
        --local function FormatData()
        for _, k in pairs(Format) do
            --table.insert(item, PlayerInfo[k])
            if k ~= public_config.USER_MGR_PLAYER_FIGHT_INDEX then
                item[k] = PlayerInfo[k]
            else
                --获取战斗力

                local fight_max = 0
                if self.DbidToPlayers[PlayerDbid] then
                    local fight_rank = self.DbidToPlayers[PlayerDbid][PLAYER_ARENIC_FIGHT_RANK_INDEX]
                    if fight_rank and fight_rank > 1 then
                        fight_max = self.m_lFights[fight_rank][FIGHTS_FIGHT_INDEX]
                    end
                end

                item[public_config.USER_MGR_PLAYER_FIGHT_INDEX] = fight_max
            end
        end
        --end
        --FormatData()
        table.insert(result, item)

    end
    local mb = mogo.UnpickleBaseMailbox(MbStr)
    if mb then
        mb.QueryInfoByPlayerDbidResp(GuildDbid, 0, result)
    end

end

function UserMgr:GetPlayerBattleProperties(myDbid, funcName, dbid, isPvp)
    if myDbid == dbid then
        if isPvp == 0 then
            log_game_error("UserMgr:GetPlayerBattleProperties", "logic was wrong dbid[%q]", dbid)
        end
        if not self:_GetRobotBattleProperties(myDbid, funcName, dbid, isPvp) then
            log_game_error("UserMgr:GetPlayerBattleProperties", "get robot data.")
        end
        return
    end
    local myInfo = self.DbidToPlayers[myDbid]
    if not myInfo then return end

    local theInfo = self.DbidToPlayers[dbid]
    if not theInfo then
        return
    end

    if not myInfo[PLAYER_BASE_MB_INDEX] or myInfo[PLAYER_BASE_MB_INDEX] == '' then
        return
    end

    local mb = mogo.UnpickleBaseMailbox(myInfo[PLAYER_BASE_MB_INDEX])
    --
    if mb then
        local attri = theInfo[PLAYER_BATTLE_PROPS_INDEX]
        --log_game_debug("UserMgr:GetPlayerBattleProperties", 'attri = '..mogo.cPickle(attri))
        local modes = theInfo[PLAYER_LOADED_ITEMS_INDEX]
        --log_game_debug("UserMgr:GetPlayerBattleProperties", 'modes = '..mogo.cPickle(modes))
        local skill = theInfo[PLAYER_SKILL_BAG_INDEX]
        --log_game_debug("UserMgr:GetPlayerBattleProperties", 'skill = '..mogo.cPickle(skill))
        local other_info = {}
        other_info.level = theInfo[PLAYER_LEVEL_INDEX]
        other_info.weapon_subtype = 0
        local items = theInfo[PLAYER_ITEMS_INDEX]
        if not attri or not modes or not skill or not items then
            log_game_error("UserMgr:GetPlayerBattleProperties", "dbid[%d], level [%d]", dbid, theInfo[PLAYER_LEVEL_INDEX])
            return
        end
        for _, v in pairs(items) do
            if v[public_config.USER_MGR_ITEMS_BODY_INDEX] == public_config.BODY_WEAPON then
                local weaponType = v[public_config.USER_MGR_ITEMS_TYPE_INDEX]
                local itInfo = g_itemdata_mgr:GetItem(public_config.ITEM_TYPE_CFG_TBL, weaponType)
                if itInfo then
                    other_info.weapon_subtype = itInfo.subtype
                end
                break
            end
        end
        other_info.vocation = theInfo[PLAYER_VOCATION_INDEX]
        other_info.name = theInfo[PLAYER_NAME_INDEX]
        other_info.dbid = theInfo[PLAYER_DBID_INDEX]
        mb[funcName](attri, modes, skill, other_info, isPvp)
    end
end

function UserMgr:_GetRobotBattleProperties(myDbid, funcName, dbid, flag)
    local myInfo = self.DbidToPlayers[myDbid]
    if not myInfo then return false end
    if not self.m_robots[dbid] then self.m_robots[dbid] = {} end
    local robot = self.m_robots[dbid][flag]
    if not robot then return false end
    if not myInfo[PLAYER_BASE_MB_INDEX] or myInfo[PLAYER_BASE_MB_INDEX] == '' then
        return false
    end

    local mb = mogo.UnpickleBaseMailbox(myInfo[PLAYER_BASE_MB_INDEX])
    --
    if mb then
        local attri = robot.battleProps
        --log_game_debug("UserMgr:_GetRobotBattleProperties", 'attri = '..mogo.cPickle(attri))
        local modes = robot.modes
        --log_game_debug("UserMgr:_GetRobotBattleProperties", 'modes = '..mogo.cPickle(modes))
        local skill = robot.skill
        --log_game_debug("UserMgr:_GetRobotBattleProperties", 'skill = '..mogo.cPickle(skill))
        local other_info = {}
        other_info.level = robot.level
        other_info.weapon_subtype = robot.weapon_subtype

        if not attri or not modes or not skill or not other_info.weapon_subtype then
            log_game_error("UserMgr:_GetRobotBattleProperties", "dbid[%d], level [%d]", dbid, other_info.level)
            return false
        end

        other_info.vocation = robot.vocation
        other_info.name = robot.name
        other_info.dbid = robot.dbid
        mb[funcName](attri, modes, skill, other_info, flag)
        return true
    end
    return false
end

function UserMgr:Chat(ChannelId, dbid, name, level, mbstr, to_dbid, msg)

    log_game_debug("UserMgr:Chat", "ChannelId=%d;dbid=%q;name=%s;level=%d;mbstr=%s;to_dbid=%q;msg=%s", ChannelId, dbid, name, level, mbstr, to_dbid, msg)

    if ChannelId == public_config.CHANNEL_ID_PERSONAL then
        local PlayerInfo = self.DbidToPlayers[to_dbid]
        if PlayerInfo then
            local PlayerBaseMbStr = PlayerInfo[PLAYER_BASE_MB_INDEX]
            if PlayerBaseMbStr and PlayerBaseMbStr ~= '' then
                local mb = mogo.UnpickleBaseMailbox(PlayerBaseMbStr)
                if mb then
                    log_game_debug("UserMgr:ChatResp", "ChannelId=%d;dbid=%q;name=%s;to_dbid=%q;msg=%s",
                                                              ChannelId, dbid, name, to_dbid, msg)
                    mb.client.ChatResp(ChannelId, dbid, name, level, msg)
                end
            else
                local mb = mogo.UnpickleBaseMailbox(mbstr)
                if mb then
                    mb.client.ShowTextID(CHANNEL.TIPS, error_code.CHAT_PERSON_NOT_ONLINE)
                end
            end
        else
            local mb = mogo.UnpickleBaseMailbox(mbstr)
            if mb then
                mb.client.ShowTextID(CHANNEL.TIPS, error_code.CHAT_PERSON_NOT_EXIT)
            end
        end
--    elseif ChannelId == public_config.CHANNEL_ID_WORLD then
--        --全服广播使用globaldata的机制
--        global_data:channel_req(ChannelId, name, msg)
--        for _, PlayerInfo in pairs(self.DbidToPlayers) do
--            local PlayerBaseMbStr = PlayerInfo[PLAYER_BASE_MB_INDEX]
--            if PlayerBaseMbStr and PlayerBaseMbStr ~= '' then
--                local mb = mogo.UnpickleBaseMailbox(PlayerBaseMbStr)
--                if mb then
--                    log_game_debug("UserMgr:ChatResp", "ChannelId=%d;dbid=%q;name=%s;to_dbid=%q;msg=%s",
--                                                        ChannelId, dbid, name, to_dbid, msg)
--                    mb.client.ChatResp(ChannelId, dbid, name, msg)
--                end
--            end
--        end
--    elseif ChannelId == public_config.CHANNEL_ID_UNION then
--        local PlayerInfo = self.DbidToPlayers[dbid]
--        if not PlayerInfo then
--            return
--        end
--
--        local UnionDbid = PlayerInfo[PLAYER_UNION_INDEX]
--        if UnionDbid <= 0 then
--            return
--        end
--
--        local PlayerDbids = self.UnionDbidToPlayerDbid[UnionDbid]
--        if not PlayerDbids then
--            return
--        end
--
--        for _, PlayerDbid in pairs(PlayerDbids) do
--            if PlayerDbid == dbid then
--                return
--            end
--
--            local ToPlayerInfo = self.DbidToPlayers[PlayerDbid]
--            if not ToPlayerInfo then
--                return
--            end
--
--            local PlayerBaseMbStr = ToPlayerInfo[PLAYER_BASE_MB_INDEX]
--            if not PlayerBaseMbStr then
--                return
--            end
--
--            local mb = mogo.UnpickleBaseMailbox(PlayerBaseMbStr)
--            if mb then
--                log_game_debug("UserMgr:ChatResp", "ChannelId=%d;dbid=%q;name=%s;to_dbid=%q;msg=%s",
--                                                    ChannelId, dbid, name, to_dbid, msg)
--                mb.client.ChatResp(ChannelId, dbid, name, msg)
--            end
--        end
    end

end

function UserMgr:Employ(PlayerCellMbStr, PlayerDbid)
    log_game_debug("UserMgr:Employ", "PlayerCellMbStr=%s;Playerdbid=%q", PlayerCellMbStr, PlayerDbid)
    if not self.DbidToPlayers[PlayerDbid] then
        return
    end

    local Employee = self.DbidToPlayers[PlayerDbid]
    --todo：计算玩家的二级属性
    local EmployeeBattleProps = {}

    local EmployerCellMb = mogo.UnpickleCellMailbox(PlayerCellMbStr)
    if not EmployerCellMb then
        return
    end

    --通知在雇佣者所在的位置创建被雇佣者
    EmployerCellMb.CreateEmployee(EmployeeBattleProps)
end
--广播指定玩家RPC Base
function UserMgr:BroacastRpcToOthers( Msg, mailInfo, dbids )
    log_game_debug("UserMgr:BroacastRpcToOthers", "dbids=%s", mogo.cPickle(dbids))
    for i,v in pairs(dbids) do
--        log_game_debug("UserMgr:BroacastRpcToOthers", "-------for-------")
        if self.DbidToPlayers[v] then
--            log_game_debug("UserMgr:BroacastRpcToOthers", "----------if-------")
            if self.DbidToPlayers[v][PLAYER_IS_ONLINE_INDEX] == public_config.USER_MGR_PLAYER_ONLINE then
                local mb = mogo.UnpickleBaseMailbox(self.DbidToPlayers[v][PLAYER_BASE_MB_INDEX])
                if mb then
--                    log_game_debug("UserMgr:BroacastRpcToOthers", "-----mb----")
                    mb.BeRpcRelayCall(Msg, mailInfo)
                end
            end    
        end 
    end
end
--广播其他所有玩家RPC Base
function UserMgr:BroacastRpc( Msg, Info )
--    log_game_debug('UserMgr:SystemMailNoticeAll', '1')
    for _,v in pairs(self.DbidToPlayers) do
        if v[PLAYER_IS_ONLINE_INDEX] == public_config.USER_MGR_PLAYER_ONLINE then
--            log_game_debug('UserMgr:SystemMailNoticeAll', '2')
            local mb = mogo.UnpickleBaseMailbox(v[PLAYER_BASE_MB_INDEX])
            if mb then
--                log_game_debug('UserMgr:SystemMailNoticeAll', '3')
                mb.BeRpcRelayCall(Msg, Info)
            end
        end
    end
end

--更新角色在usermgr上的等级引起的事件
function UserMgr:__updateLevel(myInfo, PlayerDbid, newLevel)
    if not myInfo then
        return
    end
    local lv = myInfo[PLAYER_LEVEL_INDEX]
    if lv == newLevel then return end

    if self.LevelToDbid[lv] and self.LevelToDbid[lv][PlayerDbid] then
        self.LevelToDbid[lv][PlayerDbid] = nil
    else
        for lv ,v in pairs(self.LevelToDbid) do
            if v[PlayerDbid] and lv ~= newLevel then
                v[PlayerDbid] = nil
                break
            end
        end    
    end
    myInfo[PLAYER_LEVEL_INDEX] = newLevel

    if not self.LevelToDbid[newLevel] then
        self.LevelToDbid[newLevel] = {}
    end
    self.LevelToDbid[newLevel][PlayerDbid] = true
end
--更新角色在usermgr上的战斗力相关引起的事件,todo:
function UserMgr:__updateFight( ... )
    -- body
end

--更新自己在线数据
function UserMgr:Update( dbid, data )
    log_game_debug('UserMgr:Update', '')
    local myInfo = self.DbidToPlayers[dbid]
    if not myInfo then
        return
    end
    if data[PLAYER_LEVEL_INDEX] and myInfo[PLAYER_LEVEL_INDEX] < data[PLAYER_LEVEL_INDEX] then
        self:__updateLevel(myInfo, dbid, data[PLAYER_LEVEL_INDEX])
    end
    
    if data[PLAYER_FIGHT_INDEX] then
        myInfo[PLAYER_FIGHT_INDEX] = data[PLAYER_FIGHT_INDEX]
        if data[PLAYER_BATTLE_PROPS_INDEX] and data[PLAYER_ITEMS_INDEX] and
            data[PLAYER_SKILL_BAG_INDEX] then
            --update data
            myInfo[PLAYER_BATTLE_PROPS_INDEX] = data[PLAYER_BATTLE_PROPS_INDEX]
            myInfo[PLAYER_ITEMS_INDEX] = data[PLAYER_ITEMS_INDEX]
            myInfo[PLAYER_SKILL_BAG_INDEX] = data[PLAYER_SKILL_BAG_INDEX]
            --更新外型
            self:__UpdateLoaded(dbid, myInfo[PLAYER_ITEMS_INDEX])

            local rank = myInfo[PLAYER_ARENIC_FIGHT_RANK_INDEX]
            if rank and rank > 0 then
                self:UpdateMyFights(rank, data[PLAYER_FIGHT_INDEX], dbid)
                --启动保存
                --log_game_debug("UserMgr:Update", "set save.")
                self.m_save[dbid] = 0
            elseif myInfo[PLAYER_LEVEL_INDEX] >= g_arena_config.OPEN_LV then
                self:InsertMyFights(data[PLAYER_FIGHT_INDEX], dbid)
                --启动保存
                --log_game_debug("UserMgr:Update", "set save.")
                self.m_save[dbid] = 0
            else
                log_game_warning("UserMgr:Update", "no need to update detail data.")
            end
        end

    end

    for k,v in pairs(data) do
        if myInfo[k] then
            if k ~= PLAYER_LEVEL_INDEX and
               k ~= PLAYER_BATTLE_PROPS_INDEX and 
               k ~= PLAYER_FIGHT_INDEX and
               k ~= PLAYER_ITEMS_INDEX and 
               k ~= PLAYER_SKILL_BAG_INDEX and
               k ~= PLAYER_FRIEND_NUM_INDEX then
                myInfo[k] = v
            end
        end
    end
end

function UserMgr:SwapFightPos(pos1, pos2, dbid1, dbid2)
    if not self.m_lFights[pos1] or not self.m_lFights[pos2] then
        log_game_error("UserMgr:SwapFightPos", "1")
        return
    end
    if not self.DbidToPlayers[dbid1] or not self.DbidToPlayers[dbid2] then
        log_game_error("UserMgr:SwapFightPos", "2")
        return
    end
    local tPos1 = self.DbidToPlayers[dbid1][PLAYER_ARENIC_FIGHT_RANK_INDEX]
    if not tPos1 or tPos1 ~= pos1 then
        log_game_error("UserMgr:SwapFightPos", "3")
        return
    end
    local tPos2 = self.DbidToPlayers[dbid2][PLAYER_ARENIC_FIGHT_RANK_INDEX]
    if not tPos2 or tPos2 ~= pos2 then
        log_game_error("UserMgr:SwapFightPos", "4")
        return
    end
    local tmp = self.m_lFights[pos1][FIGHTS_FIGHT_INDEX]
    self.m_lFights[pos1][FIGHTS_DBID_INDEX] = dbid2
    self.m_lFights[pos1][FIGHTS_FIGHT_INDEX] = self.m_lFights[pos2][FIGHTS_FIGHT_INDEX]
    self.m_lFights[pos2][FIGHTS_DBID_INDEX] = dbid1
    self.m_lFights[pos2][FIGHTS_FIGHT_INDEX] = tmp
    self.DbidToPlayers[dbid1][PLAYER_ARENIC_FIGHT_RANK_INDEX] = pos2
    self.DbidToPlayers[dbid2][PLAYER_ARENIC_FIGHT_RANK_INDEX] = pos1
end

function UserMgr:UpdateMyFights(myRank, myFight, myDbid)
    log_game_debug("UserMgr:UpdateMyFights", "myRank[%s], myFight[%s], myDbid[%s]", myRank, myFight, myDbid)
    if not self.m_lFights[myRank] then
        return
    end
    log_game_debug("UserMgr:UpdateMyFights",'...')
    self.m_lFights[myRank][FIGHTS_FIGHT_INDEX] = myFight
    local tPos = myRank-1
    while tPos > 0 do
        if self.m_lFights[tPos][FIGHTS_FIGHT_INDEX] < myFight then
            self:SwapFightPos(myRank, tPos, myDbid, self.m_lFights[tPos][FIGHTS_DBID_INDEX])
            myRank = tPos
            tPos = myRank - 1
        else
            break
        end
    end
end

function UserMgr:InsertMyFights(myFight, myDbid)
    log_game_debug("UserMgr:InsertMyFights", "myFight[%s], myDbid[%s]",myFight, myDbid)
    local m = 0
    for i,v in ipairs(self.m_lFights) do
        m = m + 1
        if v[FIGHTS_DBID_INDEX] == myDbid then
            log_game_error("UserMgr:InsertMyFights", "myFight[%s], myDbid[%s]",myFight, myDbid)
            return
        end
    end
    --local m = #self.m_lFights
    for i=m,1,-1 do
        local theFight = self.m_lFights[i][FIGHTS_FIGHT_INDEX]
        if theFight >= myFight then
            self.m_lFights[i+1] = 
            {
                [FIGHTS_DBID_INDEX] = myDbid,
                [FIGHTS_FIGHT_INDEX] = myFight,
            }
            self.DbidToPlayers[myDbid][PLAYER_ARENIC_FIGHT_RANK_INDEX] = i + 1
            return
        else
            local theDbid = self.m_lFights[i][FIGHTS_DBID_INDEX]
            self.DbidToPlayers[theDbid][PLAYER_ARENIC_FIGHT_RANK_INDEX] = i + 1
            self.m_lFights[i+1] = 
            {
                [FIGHTS_DBID_INDEX] = theDbid,
                [FIGHTS_FIGHT_INDEX] = theFight,
            }
        end
    end
    self.m_lFights[1] = 
    {
        [FIGHTS_DBID_INDEX] = myDbid,
        [FIGHTS_FIGHT_INDEX] = myFight,
    }
    self.DbidToPlayers[myDbid][PLAYER_ARENIC_FIGHT_RANK_INDEX] = 1
end

function UserMgr:__UpdateLoaded(PlayerDbid, items)
    --先初始化所有的为0
    local tbl = {
        [public_config.BODY_CHEST] = 0,
        [public_config.BODY_ARMGUARD] = 0,
        [public_config.BODY_LEG] = 0,
        [public_config.BODY_WEAPON] = 0,
    }
    for k,v in pairs(items) do
        --外观信息
        if v[public_config.USER_MGR_ITEMS_BODY_INDEX] == public_config.BODY_CHEST or 
           v[public_config.USER_MGR_ITEMS_BODY_INDEX] == public_config.BODY_ARMGUARD or
           v[public_config.USER_MGR_ITEMS_BODY_INDEX] == public_config.BODY_LEG or
           v[public_config.USER_MGR_ITEMS_BODY_INDEX] == public_config.BODY_WEAPON then
            tbl[v[public_config.USER_MGR_ITEMS_BODY_INDEX]] = v[public_config.USER_MGR_ITEMS_TYPE_INDEX]
        end
    end
    self.DbidToPlayers[PlayerDbid][PLAYER_LOADED_ITEMS_INDEX] = tbl
end
--一些以前的保留的脚本，但是没使用的移到UserMgrBackUp这里
require "UserMgrBackUp"
--------------------------------------------------------------------------------------

local function unpack(t, i) 
    local i = i or 1 
    if t[i] then
        return t [i], unpack(t, i + 1) 
    end 
end 

function UserMgr:GM_Dispacher(accountName, cmd,  params, var)

    local to_dbid = tonumber(var[1])
    log_game_debug("UserMgr:GmDispacher", "accountName=%s; func=%s; dbid=%q; table =%s ", accountName, cmd, to_dbid, t2s(self.DbidToPlayers[to_dbid]))
    
      local PlayerInfo = self.DbidToPlayers[to_dbid]
        if PlayerInfo then
             log_game_debug("UserMgr:GmDispacher1", "accountName=%s; func=%s; dbid=%q;", accountName, cmd, to_dbid)
            local PlayerBaseMbStr = PlayerInfo[PLAYER_BASE_MB_INDEX]
            if PlayerBaseMbStr then
                 log_game_debug("UserMgr:GmDispacher2", "accountName=%s; func=%s; dbid=%q;", accountName, cmd, to_dbid)
                local mb = mogo.UnpickleBaseMailbox(PlayerBaseMbStr)
                if mb then
                     log_game_debug("UserMgr:GmDispacher3", "accountName=%s; func=%s; dbid=%q;", accountName, cmd, to_dbid)
                    
                    if mb[cmd] then
                        log_game_debug("UserMgr:GmDispache4", "accountName=%s; func=%s; dbid=%q; ", accountName, cmd, to_dbid)                              
                    end
                    mb[cmd](unpack(params)) 
                end
            else
                --玩家不在线，则转到到OfflineManager
            end
        end   
end




function UserMgr:join_event(event_id)
--    log_game_debug("UserMgr:join_event", "")

    for i,v in pairs(self.DbidToPlayers) do
        local PlayerInfo = v
        if PlayerInfo then
            local PlayerBaseMbStr = PlayerInfo[PLAYER_BASE_MB_INDEX]
            if PlayerBaseMbStr then
--                 log_game_debug("UserMgr:join_event", "")
                local mb = mogo.UnpickleBaseMailbox(PlayerBaseMbStr)
                if mb then
                   mb.join_event(event_id) 
                   --mb.client.EventOpenResp(event_id)
                end
            else
                --玩家不在线，则转到到OfflineManager
            end
        end   
        
    end
end

function UserMgr:leave_event(event_id)
--    log_game_debug("UserMgr:leave_event", "")

    for i,v in pairs(self.DbidToPlayers) do
        local PlayerInfo = v
        if PlayerInfo then
            local PlayerBaseMbStr = PlayerInfo[PLAYER_BASE_MB_INDEX]
            if PlayerBaseMbStr then
--                 log_game_debug("UserMgr:leave_event", "")
                local mb = mogo.UnpickleBaseMailbox(PlayerBaseMbStr)
                if mb then
                  mb.leave_event(event_id)                   
                end
            else
                --玩家不在线，则转到到OfflineManager
            end
        end   
        
    end
end

--事件分派
function UserMgr:EventDispatch(dbid, sys_name, func_name, params)
    log_game_debug("UserMgr:EventDispatch", "dbid=%s", dbid)

    local theUser = self.DbidToPlayers[dbid]
    if not theUser then return end

    if theUser[PLAYER_IS_ONLINE_INDEX] == public_config.USER_MGR_PLAYER_ONLINE then
        local avatarMB = mogo.UnpickleBaseMailbox(theUser[PLAYER_BASE_MB_INDEX])
        if avatarMB then
            avatarMB.EventDispatch(sys_name, func_name, params)
        end
    end
end

function UserMgr:KickOut(name)
    log_game_debug('UserMgr:KickOut', 'name=%s', name)

    local PlayerDbid = self.NameToDbid[name]
    if PlayerDbid then
        local PlayerInfo = self.DbidToPlayers[PlayerDbid]
        if PlayerInfo then
            local PlayerBaseMbStr = PlayerInfo[PLAYER_BASE_MB_INDEX]
            if PlayerBaseMbStr and PlayerBaseMbStr ~= '' then
--                log_game_debug("UserMgr:leave_event", "")
                local mb = mogo.UnpickleBaseMailbox(PlayerBaseMbStr)
                if mb then
                    mb.KickedOut()
                end
            end
        end
    end
end

function UserMgr:GetOnlineCount()
--    log_game_debug("UserMgr:GetOnlineCount TEMP", "GetOnlineCount")
    globalbase_call("Collector", "SetOnlineCount", self.OnlineCount)

end

--检查名字是否存在
function UserMgr:CheckName(mbStr, name, param, cbFunc)
    local mm = mogo.UnpickleBaseMailbox(mbStr)
    if mm then
        if self.NameToDbid[name] then
            mm[cbFunc](param, 1)
        else
            mm[cbFunc](param, 0)
        end
    end
end

--通知客户端显示 (给所有在线玩家) 
--channelID  ,显示位置  定义在channel_config中     CHANNEL.DLG_WORLD
--textID   文本ID  客户端根据该ID显示相应的文字
-- args  参数list
function UserMgr:ShowTextID(channelID, textID, args) 

    global_data:ShowTextID(channelID, textID, args)  --给所有人发消息改为从 global_data

    --[[
    local bArgs = next(args)
    for _, PlayerInfo in pairs(self.DbidToPlayers) do
            local PlayerBaseMbStr = PlayerInfo[PLAYER_BASE_MB_INDEX]
            if PlayerBaseMbStr then
                local mb = mogo.UnpickleBaseMailbox(PlayerBaseMbStr)
                if mb then
                    if bArgs  then
                        mb.client.ShowTextIDWithArgs(channelID, textID, args)
                    else
                        mb.client.ShowTextID(channelID, textID)
                    end
                end
            end
        end
    ]]
end
function UserMgr:DragonShowText(atker, defier, rewds)
    local channelID = CHANNEL.WORLD
    local players   = self.DbidToPlayers
    local atkName   = players[atker][PLAYER_NAME_INDEX]
    local defName   = players[defier][PLAYER_NAME_INDEX]
    local args      = {}
    args[1] = atkName
    args[2] = defName
    args[3] = rewds[public_config.GOLD_ID]
    args[0] = rewds[public_config.EXP_ID]
    self:ShowTextID(channelID, public_config.WORLD_GOLD_ATK, args)
end
function UserMgr:GuildInvite(MbStr, PlayerDbid, ToDbid)

    local PlayerInfo = self.DbidToPlayers[ToDbid]
    if PlayerInfo then
        local PlayerBaseMbStr = PlayerInfo[PLAYER_BASE_MB_INDEX]
        if PlayerBaseMbStr and PlayerBaseMbStr ~= '' then
            globalbase_call("GuildMgr", "Invite", MbStr, PlayerDbid, ToDbid, PlayerBaseMbStr)
            return
        end
    end

    local mb = mogo.UnpickleBaseMailbox(MbStr)
    if mb then
        mb.client.GuildResp(action_config.MSG_INVITE, guild_config.ERROR_INVITE_NO_EXIT, {})
    end
end

function UserMgr:UpdatePlayerGuildDbid(PlayerDbid, GuildDbid)
    local PlayerInfo = self.DbidToPlayers[PlayerDbid]
    if PlayerInfo then
        log_game_debug("UserMgr:UpdatePlayerGuildDbid", "Playerdbid=%q;Guilddbid=%q", PlayerDbid, GuildDbid)
        PlayerInfo[PLAYER_UNION_INDEX] = GuildDbid
    end
end

function UserMgr:GetRecommedList(MbStr)

    local result = {}
    local i = 0
    local now = os.time()
    for PlayerDbid, PlayerInfo in pairs(self.DbidToPlayers) do
        if PlayerInfo[PLAYER_UNION_INDEX] == 0 and 
           PlayerInfo[PLAYER_LEVEL_INDEX] > g_GlobalParamsMgr:GetParams('guild_recommed_level', 20) and 
           PlayerInfo[PLAYER_OFFLINETIME_INDEX] >= (now - 24*3600) then
            table.insert(result, PlayerDbid)
            i = i + 1
        end
    end

    if i == 0 then
        local mb = mogo.UnpickleBaseMailbox(MbStr)
        if mb then
            mb.client.GuildResp(action_config.MSG_GET_RECOMMEND_LIST, guild_config.ERROR_GET_RECOMMEND_LIST_NO_PLAYERS, {})
        end
        return
    end

    log_game_debug("UserMgr:GetRecommedList", "MbStr=%s;result=%s", MbStr, mogo.cPickle(result))

    local ChoosedResult = lua_util.choose_n_norepeated(result, g_GlobalParamsMgr:GetParams('guild_recommed_list_count', 5))
    if ChoosedResult then
        local r = {}
        for dbid, _ in pairs(ChoosedResult) do

            --获取战斗力
            local fight_rank = self.DbidToPlayers[dbid][PLAYER_ARENIC_FIGHT_RANK_INDEX]
            local fight_max = 0
            if fight_rank and fight_rank > 1 then
                fight_max = self.m_lFights[fight_rank][FIGHTS_FIGHT_INDEX]
            end

            table.insert(r, {dbid, 
                             self.DbidToPlayers[dbid][PLAYER_NAME_INDEX], 
                             self.DbidToPlayers[dbid][PLAYER_LEVEL_INDEX], 
                             fight_max,})
        end

        local mb = mogo.UnpickleBaseMailbox(MbStr)
        if mb then
            mb.client.GuildResp(action_config.MSG_GET_RECOMMEND_LIST, 0, r)
        end
    end
end

--通知子系统数据过期
function UserMgr:DataDated(subSystem, fun_name, params)
    for i, v in ipairs(self.m_lFights) do
        local dbid = v[FIGHTS_DBID_INDEX]
        if dbid and self.DbidToPlayers[dbid] and
            self.DbidToPlayers[dbid][PLAYER_BASE_MB_INDEX] then
            local mb = mogo.UnpickleBaseMailbox(self.DbidToPlayers[dbid][PLAYER_BASE_MB_INDEX])
            mb.EventDispatch(subSystem, fun_name, params)
        else
            --log_game_debug("UserMgr:DataDated", "%s", dbid)
        end
    end
end

function UserMgr:ban_chat(user_names, is_ban, ban_date, reason)


    log_game_debug('UserMgr:ban_chat', 'name=%s, s_ban=%s, ban_date = %s', user_names,is_ban, ban_date )

    local names = lua_util.split_str(user_names, ',')
     for i,name in ipairs(names) do
        local PlayerDbid = self.NameToDbid[name]
        if PlayerDbid then
            local PlayerInfo = self.DbidToPlayers[PlayerDbid]
            if PlayerInfo then
                local PlayerBaseMbStr = PlayerInfo[PLAYER_BASE_MB_INDEX]
                if PlayerBaseMbStr then               
                    local mb = mogo.UnpickleBaseMailbox(PlayerBaseMbStr)
                    if mb then
                        mb.ban_chat(is_ban, ban_date,reason)                    
                    end
                else  --不在线
                    local var ={}
                    var.is_ban = is_ban
                    var.ban_date = ban_date
                    var.reason = reason
                    globalbase_call("EventMgr", "add_online_action_to_one", name , "On_ban_chat", var) 
                end
            end
        end

     end
    
end

--待踢的玩家昵称 (kick_all=1时，此参数为空) 若存在多个以逗号分隔
--kick_all    1=踢出所有玩家； 0=踢出单个玩家。踢出单个玩家时，需要在user_name获取需要踢出的用户昵称。
function UserMgr:kick_user(user_names, kick_all)    

    if kick_all == 1 then  --踢出所有
            for _, PlayerInfo in pairs(self.DbidToPlayers) do
                local PlayerBaseMbStr = PlayerInfo[PLAYER_BASE_MB_INDEX]
                if PlayerBaseMbStr   and PlayerBaseMbStr ~= '' then
                    local mb = mogo.UnpickleBaseMailbox(PlayerBaseMbStr)
                    if mb then
                        mb.KickedOut()    
                    end
                end
            end

    elseif  kick_all == 0 then --踢出user_names集合里面的玩家

            local names = lua_util.split_str(user_names, ',')
            for i,name in ipairs(names) do
                local PlayerDbid = self.NameToDbid[name]
                if PlayerDbid then
                    local PlayerInfo = self.DbidToPlayers[PlayerDbid]
                    if PlayerInfo then
                        local PlayerBaseMbStr = PlayerInfo[PLAYER_BASE_MB_INDEX]
                        if PlayerBaseMbStr    and PlayerBaseMbStr ~= '' then               
                            local mb = mogo.UnpickleBaseMailbox(PlayerBaseMbStr)
                            if mb then
                                mb.KickedOut()                    
                            end

                        end
                    end
                end
            end

    end   
    
end



function UserMgr:complain_reply(user_name,content,compain_id)   

    local PlayerDbid = self.NameToDbid[user_name]

    globalbase_call("MailMgr", "SendEx", "thanks", user_name, content, "GM", os.time(), {}, {PlayerDbid}, reason_def.gm)

end

--根据名字发邮件
function UserMgr:send_mail_by_names(user_names, mail_title, mail_content, items)   

    local to_dbids = {}
    local names = lua_util.split_str(user_names, ',')
    for i,name in ipairs(names) do
        local PlayerDbid = self.NameToDbid[name]
        if PlayerDbid then
            table.insert(to_dbids, PlayerDbid)
        end 
    end

    globalbase_call("MailMgr", "SendEx", mail_title, " ", mail_content, "System", os.time(), items or {}, to_dbids, reason_def.gm)

end

--发邮件给所有在线玩家
function UserMgr:send_mail_online(mail_title, mail_content, items)   

    for dbid, PlayerInfo in pairs(self.DbidToPlayers) do
            local PlayerBaseMbStr = PlayerInfo[PLAYER_BASE_MB_INDEX]
            if PlayerBaseMbStr   and PlayerBaseMbStr ~= '' then
                local mb = mogo.UnpickleBaseMailbox(PlayerBaseMbStr)
                if mb then
                   globalbase_call("MailMgr", "SendEx", mail_title, " ", mail_content, "System", os.time(), items or {}, {dbid}, reason_def.gm)
                end
            end
    end

    
end

function UserMgr:SanctuaryStart()
    for _, PlayerInfo in pairs(self.DbidToPlayers) do
        local PlayerBaseMbStr = PlayerInfo[PLAYER_BASE_MB_INDEX]
        if PlayerBaseMbStr   and PlayerBaseMbStr ~= '' and PlayerInfo[PLAYER_LEVEL_INDEX] >= 20 then
            local mb = mogo.UnpickleBaseMailbox(PlayerBaseMbStr)
            if mb then
               mb.SanctuaryNotice(1)
            end
        end
    end
end

function UserMgr:PlayerFriendNumChange(dbid, friendNum )
    log_game_debug("PlayerFriendNumChange", "friendNum = %d", friendNum)
    local playerInfo = self.DbidToPlayers[dbid]
    playerInfo[PLAYER_FRIEND_NUM_INDEX] = friendNum
    self.m_save[dbid] = PLAYER_FRIEND_NUM_INDEX
    --把该数据丢给离线管理器管理（该值需存盘）--modify by hwj:该值不存，改为读取玩家的好友数量外加被答应的数量之和
    --local friendNumItem = userMgrItem:new(friendNum)
    --globalbase_call("OfflineMgr", "RepOfflineItemByOffType", 
        --OfflineType.OFFLINE_RECORD_USER_MGR_FRIEND_NUM, playerInfo[PLAYER_DBID_INDEX], {friendNumItem})
end


function UserMgr:AddGiftBag( dbid, item_id, num)

    log_game_debug("UserMgr:AddGiftBag", "dbid=%s item_id=%s", dbid, item_id)
    local PlayerDbid = dbid
        if PlayerDbid then
            local PlayerInfo = self.DbidToPlayers[PlayerDbid]
            if PlayerInfo then
                local PlayerBaseMbStr = PlayerInfo[PLAYER_BASE_MB_INDEX]
                if PlayerBaseMbStr then               
                    local mb = mogo.UnpickleBaseMailbox(PlayerBaseMbStr)
                    if mb then
                        log_game_debug("UserMgr:AddGiftBag", "found player :%s", dbid)
                        mb.AddGiftBag(item_id, num)                    
                    end

                end
            end
        end
end

function UserMgr:GmSetting(dbid,gm_setting)
    if not self.DbidToPlayers[dbid] then
        log_game_error("UserMgr:GmSetting", "")
        return
    end
    self.DbidToPlayers[dbid][PLAYER_GM_SETTING] = gm_setting or 0
end

function UserMgr:run_func(role_name,func_name, var)

    log_game_debug("UserMgr:run_func", "role_name=%s, func_name=%s", role_name, func_name)

    local PlayerDbid = self.NameToDbid[role_name]
    if PlayerDbid then
        local PlayerInfo = self.DbidToPlayers[PlayerDbid]
        if PlayerInfo then
            local PlayerBaseMbStr = PlayerInfo[PLAYER_BASE_MB_INDEX]
            if PlayerBaseMbStr then               
                local mb = mogo.UnpickleBaseMailbox(PlayerBaseMbStr)
                if mb then
                    mb.run_func(func_name, var)                    
                end
            end
        end
    end
end

function UserMgr:NotifyCharge(account,avatar_dbid,ord_list,fd)
    log_game_debug('UserMgr:NotifyCharge',"")
    local avatars = self.AccountToDbid[account]
    if not avatars then 
        log_game_warning("UserMgr:NotifyCharge", "no acc.")
        --mogo.browserResponse(fd,error_code.ERR_BROWSER_RESP_NO)
        return 
    end
    local tpb = false
    for dbid,_ in pairs(avatars) do
        if avatar_dbid == 0 or avatar_dbid == dbid then
            local avatar = self.DbidToPlayers[dbid]
            if avatar and avatar[PLAYER_BASE_MB_INDEX] then
                local mb = mogo.UnpickleBaseMailbox(avatar[PLAYER_BASE_MB_INDEX])
                if mb then
                    mb.OnNotifyCharge(ord_list)
                end
            end
            tpb = true
        end
    end
    --
    if tpb then
        --mogo.browserResponse(fd,error_code.ERR_BROWSER_RESP_SUC)
    else
        --mogo.browserResponse(fd,error_code.ERR_BROWSER_RESP_NO)
    end
end
--[[
--检查角色或者帐号的合法性
function UserMgr:onChargeReq(fd,plat_id,ord_info)
    --拼接帐号
    local account = ord_info[5]
    if '0' ~= plat_id then
        account = '' .. plat_id .. '_' .. ord_info[5]
    end
    local avatars = self.AccountToDbid[account]
    if not avatars then 
        --用户不存在
        return mogo.browserResponse(fd,'-3')
    end
    local the_avatar = tonumber(ord_info[8] or '0')
    if the_avatar and the_avatar ~= 0 then
        local player = self.DbidToPlayers[the_avatar]
        if not player then
            --用户不存在
            return mogo.browserResponse(fd,'-3')
        end
    end
    globalbase_call("ChargeMgr", "onChargeReq", fd,plat_id,ord_info)
end
]]
return UserMgr