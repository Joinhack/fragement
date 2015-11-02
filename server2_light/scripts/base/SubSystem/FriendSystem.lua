
-- 好友系统
require "OfflineMgr"
require "event_config"
require "friend_config"
require "client_text_id"
require "reason_def"

local log_game_info = lua_util.log_game_info
local log_game_debug = lua_util.log_game_debug
local log_game_error = lua_util.log_game_error

local _readXml = lua_util._readXml
local globalbase_call = lua_util.globalbase_call

-----------------好友信息--------------------
local blessDefault = 0
local degreeDefault = 0
local HireTimeDefault = 0
--好友信息的结构
local Friend = {}
Friend.__index = Friend
function Friend:new()
    local nextRefreshTime = lua_util.get_secs_until_next_hhmiss(0, 0, 0)
    local newItem = {
        [friendsInfoIndex.degreeIndex]        = degreeDefault,
        [friendsInfoIndex.nextHireTimeIndex]  = HireTimeDefault,
        [friendsInfoIndex.nextBlessTimeIndex] = blessDefault,
    }
     setmetatable(newItem, {__index = Friend})
    return newItem
end
-----------------留言-------------------------
local FriendNote = {}
FriendNote.__index = FriendNote
function FriendNote:new( fromId, name, note )
    local time = os.time()
    local timeout = os.time() + public_config.FRIEND_NOTE_TIMEOUT
    local newItem = {
        [noteIndex.fromId]   = fromId,
        [noteIndex.fromName] = name,
        [noteIndex.note]     = note,
        [noteIndex.time]     = time,
        [noteIndex.timeout]  = timeout,
    }
     setmetatable(newItem, {__index = FriendNote})
    return newItem
end
--------------------好友请求-----------------------
local FriendReq = {}
FriendReq.__index = FriendReq
function FriendReq:new( fromId, name, level, vocation)
    local timeout = os.time() + public_config.FRIEND_REQ_TIMEOUT
    local newItem = {
        [reqIndex.fromId]   = fromId,
        [reqIndex.fromName] = name,
        [reqIndex.level] = level,
        [reqIndex.vocation] = vocation,
        [reqIndex.timeout]  = timeout,
    }
     setmetatable(newItem, {__index = FriendReq})
    return newItem
end
--------------------好友答应-----------------------
local FriendResp = {}
FriendResp.__index = FriendResp
function FriendResp:new( fromId, name)
    --local timeout = os.time() + public_config.FRIEND_RESP_TIMEOUT
    local newItem = {
        [respIndex.fromId]   = fromId,
        [respIndex.fromName] = name,
        --[respIndex.timeout]  = timeout,
    }
     setmetatable(newItem, {__index = FriendResp})
    return newItem
end
--------------------好友删除-----------------------
local FriendBeDel = {}
FriendBeDel.__index = FriendBeDel
function FriendBeDel:new( fromId )
    local newItem = {
        [delIndex.fromId] = fromId,       
        --[fromNameIndex] = name,  
    }
     setmetatable(newItem, {__index = FriendBeDel})
    return newItem
end
--------------------好友祝福-----------------------
local FriendBeBless = {}
FriendBeBless.__index = FriendBeBless
function FriendBeBless:new( fromId )
    local newItem = {
        [FriendBeBlessIndex.fromId] = fromId,       
        [FriendBeBlessIndex.timeout] = os.time() + public_config.FRIEND_BLESS_TIMEOUT,   
    }
     setmetatable(newItem, {__index = FriendBeDel})
    return newItem
end
--------------------好友系统-----------------------

--local friendData = {}

FriendSystem = {}
FriendSystem.__index = FriendSystem

function FriendSystem:new( owner )
    local newObj = {}
	setmetatable(newObj, {__index = FriendSystem})
	newObj.ptr = {}
    setmetatable(newObj.ptr, {__mode = "v"})
    newObj.ptr.theOwner = owner
    --好友留言提示
    newObj.noteTips = {}
    --好友祝福提示
    newObj.blessTips = {}

    local msgMapping = {
        [msgFriendSys.MSG_FRIEND_LIST] = self.FriendList,
        [msgFriendSys.MSG_FRIEND_DEL] = self.DelFriend,
        [msgFriendSys.MSG_FRIEND_INFO] = self.QueryInfo,
        [msgFriendSys.MSG_FRIEND_QUERY] = self.FriendResearch, --
        [msgFriendSys.MSG_FRIEND_NOTE_W] = self.WriteNote,
        [msgFriendSys.MSG_FRIEND_NOTE_R] = self.ReadNote,
        --[msgFriendSys.MSG_FRIEND_REJECT] = self.Reject,
        [msgFriendSys.MSG_FRIEND_ACCEPT] = self.Accept,
        [msgFriendSys.MSG_FRIEND_REQ_ADD] = self.ReqAddFriend,
        [msgFriendSys.MSG_FRIEND_REQ_DEL] = self.DelReq,
        [msgFriendSys.MSG_FRIEND_LOGIN] = self.Login,
        [msgFriendSys.MSG_FRIEND_CHECK] = self.IsHasFriend,
        [msgFriendSys.MSG_FRIEND_REMOVE] = self.RemoveFriend,
        [msgFriendSys.MSG_FRIEND_INSERT] = self.InsertFriend,
        [msgFriendSys.MSG_FRIEND_ISFULL] = self.IsFulled,
        [msgFriendSys.MSG_FRIEND_REQ_LIST] = self.FriendReqList,
    }
    newObj.msgMapping = msgMapping
    return newObj
end
--todo:后面这个上限与VIP等级相关
function FriendSystem:GetEnergyLimit()
    return public_config.FRIEND_RECV_ENERGY_MAX
end

function FriendSystem:initData()
    --friendData = _readXml('/data/xml/friendData.xml', 'id_i')
end

function FriendSystem:Req( msgId, ...)
    local func = self.msgMapping[msgId]
    if func then
        return func(self, ...)
    else
        log_game_error("FriendSystem:Req", "msgId = %d", msgId)
    end
end

--查看好友信息
function FriendSystem:ReqFriendInfo(dbid)
   globalbase_call("UserMgr", "QueryInfoByPlayerDbid", 
        msgUserMgr.MSG_USER_FRIEND_QUERY_BY_DBID,
        self.ptr.theOwner.base_mbstr,
        dbid
        )     
end
--[[
function FriendSystem:ReqAddFriendCB( parm )
    log_game_debug('FriendSystem:ReqAddFriendCB', '%d', parm)
end
]]
--申请增加好友
function FriendSystem:ReqAddFriend( dbid )
    --globalbase_call('UserMgr', 'test', self.ptr.theOwner.dbid,'friendSystem', 'ReqAddFriendCB')
    --无论在线与否都加入离线管理器，在处理该请求后删除
--    log_game_debug("FriendSystem:ReqAddFriend","")
    local req = FriendReq:new(self.ptr.theOwner.dbid, self.ptr.theOwner.name, self.ptr.theOwner.level, self.ptr.theOwner.vocation)
    globalbase_call("UserMgr", "RpcRelayCall", 
        self.ptr.theOwner.dbid,
        msgUserMgr.MSG_USER_FRIEND_ADD_REQ,
        dbid,
        msgUserMgr.MSG_USER_FRIEND_ADD_REQ_BE,
        req,
        0, --无论怎么样都不做离线记录
        0, 
        req
        )
end

function FriendSystem:SendAddReq( dbid )
    local req = FriendReq:new(self.ptr.theOwner.dbid, self.ptr.theOwner.name, self.ptr.theOwner.level, self.ptr.theOwner.vocation)
    --作替换处理
--    log_game_debug("FriendSystem:SendAddReq","")
    globalbase_call("OfflineMgr", "Rep", 
        OfflineType.OFFLINE_RECORD_FRIEND_REQ,
        dbid,
        req,
        reqIndex.fromId, --offType, acceptId, keyIndex, val
        self.ptr.theOwner.dbid
        )
end

function FriendSystem:DelFriend( dbid )
    local beDel = FriendBeDel:new(self.ptr.theOwner.dbid)
    globalbase_call("UserMgr", "RpcRelayCall", 
        self.ptr.theOwner.dbid,
        0, --无需回调
        dbid,
        msgUserMgr.MSG_USER_FRIEND_DEL_REQ_BE,
        beDel,
        1, --对方不在线的时候做离线记录
        OfflineType.OFFLINE_RECORD_FRIEND_DEL_BE,
        beDel
        )
end

function FriendSystem:Login( allOffInfo )
--    log_game_debug("FriendSystem:Login","")
    --先处理好友被接受信息
    local accept = allOffInfo[OfflineType.OFFLINE_RECORD_FRIEND_ACCEPT_BE]
    if accept then
        log_game_debug("FriendSystem:Login","DealWithBeAccept")
        self:DealWithBeAccept(accept)
    end
    --处理好友删除信息
    local del = allOffInfo[OfflineType.OFFLINE_RECORD_FRIEND_DEL_BE]
    if del then
       self:DealWithBeDel(del)
    end
    local owner = self.ptr.theOwner
    --处理好友留言
    local note = allOffInfo[OfflineType.OFFLINE_RECORD_FRIEND_NOTE]
    if note then
        for k,v in pairs(note) do
            --[[
            noteIndex = {
                fromId   = 1,
                fromName = 2,
                note     = 3,
                time     = 4,
                timeout  = public_config.OFFLINE_ITEM_TIMEOUT_INDEX,
            }
            ]]
            if owner.friends[v[noteIndex.fromId]] and v[noteIndex.timeout] > os.time() then
                self.noteTips[v[noteIndex.fromId]] = 1
            end
        end
    end
    --处理好友祝福
    local bless = allOffInfo[OfflineType.MSG_RECORD_BLESS_BE]
    if bless then
        for k,v in pairs(bless) do
            --[[
            FriendBeBlessIndex = {
                fromId   = 1,
                timeout  = public_config.OFFLINE_ITEM_TIMEOUT_INDEX,
            }
            ]]
            if owner.friends[v[FriendBeBlessIndex.fromId]] and v[FriendBeBlessIndex.timeout] > os.time() then
                self.blessTips[v[FriendBeBlessIndex.fromId]] = 1
            end
        end
    end
    --[[
    do
        local friendList = {}
        for k,_ in pairs(owner.friends) do
            table.insert(friendList, k)
        end
        log_game_debug('FriendSystem:Login', '')
        --globalbase_call('UserMgr', 'FriendOnline', owner.dbid, friendList)
    end
    ]]
    --兼容旧的错误数据,之前没清
    if owner.friendsEnergy ~= 0 and owner.friendRefreshTime == 0 then
    	self:Refresh()
    end
    if owner.friendRefreshTime == 0 then
    	owner.friendRefreshTime = lua_util.get_secs_until_next_hhmiss(0, 0, 0)
    end
    if owner.friendRefreshTime < os.time() then
        self:Refresh()
    end
end

function FriendSystem:DealWithBeDel( FriendBeDels )
    for _, beDel in pairs(FriendBeDels) do
        local to_del_id = beDel[delIndex.fromId]
        self:RemoveFriend(to_del_id)
    end
    --删除所有的对方删除我为好友的记录
    globalbase_call("OfflineMgr", "DelTypeOf", 
        OfflineType.OFFLINE_RECORD_FRIEND_DEL_BE, self.ptr.theOwner.dbid)
end

function FriendSystem:DealWithBeAccept( FriendResps )
    for i, resp in pairs(FriendResps) do
        log_game_debug("FriendSystem:DealWithBeAccept", "%d", resp[respIndex.fromId])
        if self:InsertFriend(resp[respIndex.fromId]) == error_code.ERR_FRIEND_FULL then
            break
        end
    end
    --删除所有的对方删除我为好友的记录
    globalbase_call("OfflineMgr", "DelTypeOf", 
        OfflineType.OFFLINE_RECORD_FRIEND_ACCEPT_BE, self.ptr.theOwner.dbid)
end

function FriendSystem:WriteNote( dbid, context )
    --无论在线与否都加入离线管理器，在处理该请求后删除
    local noteItem = FriendNote:new(self.ptr.theOwner.dbid, self.ptr.theOwner.name, context)
    globalbase_call("UserMgr", "RpcRelayCall", 
        self.ptr.theOwner.dbid,
        msgUserMgr.MSG_USER_FRIEND_SEND_NOTE,
        dbid,
        msgUserMgr.MSG_USER_FRIEND_SEND_NOTE_BE,
        noteItem,
        2, --对方在线的时候也做离线记录
        OfflineType.OFFLINE_RECORD_FRIEND_NOTE,
        noteItem
        )
end

function FriendSystem:ReadNote( dbid, msgId )
    globalbase_call("OfflineMgr", "Get", 
        self.ptr.theOwner.base_mbstr,
        msgId,
        OfflineType.OFFLINE_RECORD_FRIEND_NOTE, --offType, acceptId, keyIndex, val
        self.ptr.theOwner.dbid, 
        noteIndex.fromId, 
        dbid,
        1 --非零:load完删除
        )
    self.noteTips[dbid] = nil
end
--[[
function FriendSystem:DelNote( dbid )

end
]]
--删除好友请求
function FriendSystem:DelReq( dbid, msgId )
    globalbase_call("OfflineMgr", "DelCb", 
        self.ptr.theOwner.base_mbstr,
        msgId,
        OfflineType.OFFLINE_RECORD_FRIEND_REQ, --offType, acceptId, keyIndex, val
        self.ptr.theOwner.dbid, 
        reqIndex.fromId, 
        dbid
        )
end

function FriendSystem:Accept( dbid )
    log_game_debug("FriendSystem:Accept","")
    local resp = FriendResp:new(self.ptr.theOwner.dbid, self.ptr.theOwner.name)
    globalbase_call("UserMgr", "RpcRelayCall", 
        self.ptr.theOwner.dbid,
        msgUserMgr.MSG_USER_FRIEND_ACCEPT,
        dbid,
        msgUserMgr.MSG_USER_FRIEND_ACCEPT_BE,
        resp,
        1, --对方不在线的时候做离线记录
        OfflineType.OFFLINE_RECORD_FRIEND_ACCEPT_BE,
        resp
        )
end

function FriendSystem:IsHasFriend( dbid )
    if self.ptr.theOwner.friends[dbid] then
        return true
    end
    return false
end

function FriendSystem:RemoveFriend( dbid )
    log_game_debug("FriendSystem:RemoveFriend","")
    local owner = self.ptr.theOwner
    if owner.friends[dbid] then
        owner.friends[dbid] = nil
        if self.noteTips[dbid] then self.noteTips[dbid] = nil end
        if self.blessTips[dbid] then self.blessTips[dbid] = nil end
        --删除来自该好友的祝福
        globalbase_call("OfflineMgr", "Del", 
            OfflineType.MSG_RECORD_BLESS_BE, 
            owner.dbid, 
            FriendBeBlessIndex.fromId,
            dbid
            )
        --删除来自该好友的留言
        globalbase_call("OfflineMgr", "Del", 
            OfflineType.OFFLINE_RECORD_FRIEND_NOTE, 
            owner.dbid, 
            noteIndex.fromId,
            dbid
          )
        local owner_id = self.ptr.theOwner.dbid
        --减少自己在全局管理器中的好友个数
        globalbase_call("UserMgr", "DeleteMyFriendNumBe", owner_id)
        self:FriendList()
        return true
    end

    --[[
    for i,v in pairs(self.ptr.theOwner.friends) do
        if v == dbid then
            --table.remove(self.ptr.theOwner.friends, i)
            self.ptr.theOwner.friends[dbid] = nil
            local function _dummy( a,b,c )
                log_game_debug("FriendSystem:RemoveFriend", "succeed")
            end
            self.ptr.theOwner:writeToDB(_dummy)
            --print("RemoveFriend=========================begin")
            --CommonXmlConfig:TestData(self.ptr.theOwner.friends)
            --print("RemoveFriend=========================end")
            return true
        end
    end
    CommonXmlConfig:TestData(self.ptr.theOwner.friends)
    ]]
    return false
end

function FriendSystem:InsertFriend( dbid )
    log_game_debug("FriendSystem:InsertFriend","")
    if self:IsHasFriend(dbid) then
        return error_code.ERR_FRIEND_ALREADY_HAS
    end
    if self:IsFulled() then
        return error_code.ERR_FRIEND_FULL
    end

    --table.insert(self.ptr.theOwner.friends, dbid)
    self.ptr.theOwner.friends[dbid] = Friend:new()
    local friendNum = lua_util.get_table_real_count(self.ptr.theOwner.friends)

    local function _dummy( a,b,c )
        log_game_error("FriendSystem:InsertFriend", "succeed")
    end
    self.ptr.theOwner:writeToDB(_dummy)

    self:FriendList() 
    --加好友成功{事件ID, 好友数量}
    self.ptr.theOwner:triggerEvent(event_config.EVENT_PLAYER_ADD_FRIEND_SCCESS, event_config.EVENT_PLAYER_ADD_FRIEND_SCCESS, friendNum)
   
    return error_code.ERR_FRIEND_SUCCEED
end

function FriendSystem:IsFulled( )
    local limit = g_GlobalParamsMgr:GetParams('friend_limit', public_config.FRIEND_MAX_LIMIT)
    if lua_util.get_table_real_count(self.ptr.theOwner.friends) >= limit then
        return true
    end
    return false
end

function FriendSystem:FriendList( )
    local format = {
            public_config.USER_MGR_PLAYER_DBID_INDEX,
            public_config.USER_MGR_PLAYER_NAME_INDEX,
            public_config.USER_MGR_PLAYER_LEVEL_INDEX,
            public_config.USER_MGR_PLAYER_VOCATION_INDEX,
            public_config.USER_MGR_PLAYER_GENDER_INDEX,
            public_config.USER_MGR_PLAYER_UNION_INDEX,
            public_config.USER_MGR_PLAYER_FIGHT_INDEX,
            public_config.USER_MGR_PLAYER_IS_ONLINE_INDEX,
        }
    local dbids = {}
    for k,_ in pairs(self.ptr.theOwner.friends) do
        table.insert(dbids, k)
--        print(k)
    end
    globalbase_call("UserMgr", "QueryInfoByPlayerDbids", 
        msgUserMgr.MSG_USER_FRIEND_QUERY_BY_ALL_DBID,
        self.ptr.theOwner.base_mbstr,
        dbids,
        format
        )
end
--下发所有好友信息
function FriendSystem:SendAllFriendInfoDown( PlayerInfo )
    local owner = self.ptr.theOwner
    local friends = owner.friends
--    print('friends:')
    for k,v in pairs(friends) do
--        print(k,v)
    end
    if PlayerInfo then
        if lua_util.get_table_real_count(PlayerInfo) < 1 then
            if owner:hasClient() then
                owner.client.OnFriendListResp({}, error_code.ERR_FRIEND_NOT_EXISTS)
            end
            return
        end
        local theInfos = {}
        for i,v in pairs(PlayerInfo) do
            local id = v[public_config.USER_MGR_PLAYER_DBID_INDEX]
            if not id then
                log_game_error("FriendSystem:SendAllFriendInfoDown", "%s", mogo.cPickle(PlayerInfo))
                return
            end
            if not friends[id] then
                log_game_error("FriendSystem:SendAllFriendInfoDown", "%s", mogo.cPickle(PlayerInfo))
                return
            end
            local degree = friends[id][friendsInfoIndex.degreeIndex]
            --[[
            0～9 1心
            10～24   2心
            25～44   3心
            45～69   4心
            70～99   5心
            ]]
            --[[
            if degree < 10 then 
                degree = 1
            elseif degree < 25 then
                degree = 2
            elseif degree <45 then 
                degree = 3
            elseif degree < 70 then
                degree = 4
            else
                degree = 5
            end
            ]]
            --是否有祝福我
            local IsBlessed = 0
            if self.blessTips[id] then
                IsBlessed = 1 --可领取祝福
            end
            local IsNoted = 0
            if self.noteTips[id] then
                IsNoted = 1 --有留言
            end
            --是否祝福过
            local Blessed = 0
            if friends[id][friendsInfoIndex.nextBlessTimeIndex] >= os.time() then
                Blessed = 1
            end
            --[[
            1 public int id { get; set; }
            2 public int vocation { get; set; }
            3 public string name { get; set; }
            4 public int level { get; set; }
            5 public int fight { get; set; }
            6 public int degree { get; set; }
            7 public int IsOnline { get; set; }
            //public int IsNote { get; set; } //由于服务器该存储在离线管理器，所以通过其他RPC下发
            8 public int IsBlessed { get; set; }
            ]]
            local info = {
                [1] = id,
                [2] = v[public_config.USER_MGR_PLAYER_VOCATION_INDEX],
                [3] = v[public_config.USER_MGR_PLAYER_NAME_INDEX],
                [4] = v[public_config.USER_MGR_PLAYER_LEVEL_INDEX],
                [5] = v[public_config.USER_MGR_PLAYER_FIGHT_INDEX],
                [6] = degree,
                [7] = v[public_config.USER_MGR_PLAYER_IS_ONLINE_INDEX],
                [8] = IsBlessed,
                [9] = IsNoted,
                [10]= Blessed,
            }
            table.insert(theInfos, info)
        end
        if owner:hasClient() then
            owner.client.OnFriendListResp(theInfos, error_code.ERR_FRIEND_SUCCEED)
        end
    else 
        if owner:hasClient() then
            owner.client.OnFriendListResp({}, error_code.ERR_FRIEND_NOT_EXISTS)
        end
    end 
end

function FriendSystem:FriendResearch( name )
    --log_game_debug('FriendSystem:FriendResearch','')
    globalbase_call("UserMgr", "QueryInfoByPlayerName", 
        msgUserMgr.MSG_USER_FRIEND_QUERY_BY_NAME,
        self.ptr.theOwner.base_mbstr,
        name
        )
end

function FriendSystem:FriendReqList( )
    globalbase_call("OfflineMgr", "GetTypeOf", 
        self.ptr.theOwner.base_mbstr,
        msgOfflineMgr.MSG_OFFLINE_FRIEND_REQ_GET,
        OfflineType.OFFLINE_RECORD_FRIEND_REQ, --offType, acceptId, keyIndex, val
        self.ptr.theOwner.dbid, 
        0 --零:不删除
        )
end

--祝福好友
function FriendSystem:BlessReq(dbid)
    --log_game_debug("FriendSystem:FriendBless","")
    local owner = self.ptr.theOwner
    if not owner then
        return
    end
    if not owner.friends[dbid] then
        owner:ShowTextID(CHANNEL.TIPS, g_text_id.FRIEND_BLESS_NOT_FRIEND)
        return
    end
    local theFriendInfo = owner.friends[dbid]
    if theFriendInfo[friendsInfoIndex.nextBlessTimeIndex] >= os.time() then
        owner:ShowTextID(CHANNEL.TIPS, g_text_id.FRIEND_BLESS_CDING)
        return
    end
    
    --local bless = FriendBeBless:new(owner.dbid)
    globalbase_call("UserMgr", "RpcRelayCall", 
        owner.dbid,
        msgUserMgr.MSG_USER_FRIEND_BLESS,
        dbid,
        msgUserMgr.MSG_USER_FRIEND_BLESS_BE,
        {owner.dbid}, --只发送祝福者dbid给前端
        0, --对方在线不在线都不做离线记录,离线处理在返回之后
        0,
        {}
        )
end
--祝福好友usermgr返回为了防止bless累加
function FriendSystem:BlessCallBack(dbid, err)
    --log_game_debug("FriendSystem:BlessCallBack","")
    local owner = self.ptr.theOwner
    if not owner then
        return
    end
    if error_code.ERR_USER_MGR_PLAYER_NOT_EXISTS == err then return end

    local bless = FriendBeBless:new(owner.dbid)
    globalbase_call("OfflineMgr", "Rep", 
        OfflineType.MSG_RECORD_BLESS_BE,
        dbid,
        bless,
        FriendBeBlessIndex.fromId, --offType, acceptId, keyIndex, val
        dbid
        )

    --local day = math.ceil( os.time() / 86400)
    --local canBlessTime = day * 86400
    local canBlessTime = lua_util.get_secs_until_next_hhmiss(0, 0, 0)
    owner.friends[dbid][friendsInfoIndex.nextBlessTimeIndex] = canBlessTime
    --触发体力赠送事件,数据中心统计
    owner:OnGiveEnergy(public_config.FRIEND_BE_BLESS_ENERGY)
    --add degree
    local theFriendInfo = owner.friends[dbid]
    if theFriendInfo[friendsInfoIndex.degreeIndex] < public_config.FRIEND_DEGREE_MAX then
        theFriendInfo[friendsInfoIndex.degreeIndex] = theFriendInfo[friendsInfoIndex.degreeIndex] + 
            public_config.FRIEND_BLESS_DEGREE
    end
    if theFriendInfo[friendsInfoIndex.degreeIndex] > public_config.FRIEND_DEGREE_MAX then
        theFriendInfo[friendsInfoIndex.degreeIndex] = public_config.FRIEND_DEGREE_MAX
    end
    --add energy
    self:AddBlessEnergy()
    --触发前端盖章
    owner.client.OnFriendBlessResp(dbid)
    owner:ShowTextID(CHANNEL.TIPS, g_text_id.FRINED_BLESS_SUC)
end

function FriendSystem:AddBlessEnergy()
    local owner = self.ptr.theOwner
    --检查主动祝福可以领取上限
    local energy_limit = public_config.FRIEND_BLESS_ENERGY_MAX
    if owner.friendsBleesEnergy >= energy_limit then
        return owner:ShowTextID(CHANNEL.TIPS,g_text_id.FRIEND_BLESS_LIMIT_1,energy_limit)
    end
    --检查体力上限
    local sum_limit = g_energy_mgr:GetEnergyLimit(owner.level)
    if owner.energy >= sum_limit then
        return owner:ShowTextID(CHANNEL.TIPS,g_text_id.FRIEND_BLESS_LIMIT_2,sum_limit)
    end
    --调整领取体力大小
    local theEnergy = owner.friendsBleesEnergy + public_config.FRIEND_BLESS_ENERGY
    if theEnergy >= energy_limit then
        theEnergy = energy_limit - owner.friendsBleesEnergy
    else
        theEnergy = public_config.FRIEND_BLESS_ENERGY
    end
    local tmp = owner.energy + theEnergy
    if tmp > sum_limit then
        theEnergy = sum_limit - owner.energy
    end
    --真正领取体力
    if owner:AddEnergy(theEnergy, reason_def.friend_bless_req) then
        owner.friendsBleesEnergy = owner.friendsBleesEnergy + theEnergy
        owner:ShowTextID(CHANNEL.TIPS,g_text_id.FRIEND_BLESS_ENERGY,theEnergy)
    else
        log_game_error("FriendSystem:RecvAllBless", "dbid = %q", owner.dbid)
    end
end

--{owner.dbid}, --只发送祝福者dbid给前端
function FriendSystem:BeBless(blessItem)
    --log_game_debug('FriendSystem:BeBless','1')
    local owner = self.ptr.theOwner
    if not owner then
        return
    end
    local theFriendInfo = owner.friends[blessItem[FriendBeBlessIndex.fromId]]
    if not theFriendInfo then
        log_game_error('FriendSystem:FriendBeBless', 'myDBID[%d], friendDBID[%d]', owner.dbid, blessItem[FriendBeBlessIndex.fromId])
        return
    end

    if theFriendInfo[friendsInfoIndex.degreeIndex] < public_config.FRIEND_DEGREE_MAX then
        theFriendInfo[friendsInfoIndex.degreeIndex] = theFriendInfo[friendsInfoIndex.degreeIndex] + 
            public_config.FRIEND_BLESS_DEGREE
    end
    if theFriendInfo[friendsInfoIndex.degreeIndex] > public_config.FRIEND_DEGREE_MAX then
        theFriendInfo[friendsInfoIndex.degreeIndex] = public_config.FRIEND_DEGREE_MAX
    end
    --log_game_debug('FriendSystem:BeBless','2')
    if owner:hasClient() then
        owner.client.OnFriendBeBlessResp(blessItem)
    end
    self.blessTips[blessItem[FriendBeBlessIndex.fromId]] = 1
end
--领取好友祝福体力
function FriendSystem:RecvBlessReq(dbid)
    --领取体力上限，暂定20，后面与vip系统相关
    local owner = self.ptr.theOwner
    if not owner then
        return
    end
    if owner.friendRefreshTime < os.time() then
        self:Refresh()
    end
    if self:GetFriendEnergy() >= self:GetEnergyLimit() then
        --if owner:hasClient() then
            --owner.client.OnFriendRecvBlessResp(0, dbid, error_code.ERR_FRIEND_BLESS_GET_FULL)
        --end
        self:ShowTextID(732)
        return
    end
    --OfflineMgr:Get( mbStr, msgId, offType, acceptId, fromIdIndex, dbid, remo )
    globalbase_call("OfflineMgr", "Get", 
        owner.base_mbstr,
        msgOfflineMgr.MSG_OFFLINE_FRIEND_BLESS_RECV,
        OfflineType.MSG_RECORD_BLESS_BE, 
        owner.dbid, 
        FriendBeBlessIndex.fromId,
        dbid,
        1 --非零:load完删除
        )
end

function FriendSystem:RecvBless( dbid, err )
    local owner = self.ptr.theOwner
    if not owner then
        return
    end
    if error_code.ERR_OFFLINE_SUCCEED ~= err then
        if owner:hasClient() then
            owner.client.OnFriendRecvBlessResp(0, dbid, error_code.ERR_FRIEND_BLESS_NOT_EXISTS)
        end
        return
    end
    local friend_give_energy_limit = self:GetEnergyLimit()
    local err = error_code.ERR_FRIEND_SUCCEED
    local tmpEnergy = public_config.FRIEND_BE_BLESS_ENERGY
    if (owner.friendsEnergy + public_config.FRIEND_BE_BLESS_ENERGY) > friend_give_energy_limit then
        tmpEnergy = friend_give_energy_limit - owner.friendsEnergy
        err = error_code.ERR_FRIEND_RECV_BLESS_FULL
    end
    if owner:AddEnergy(tmpEnergy, reason_def.friend_bless) then
        owner.friendsEnergy = owner.friendsEnergy + tmpEnergy
        self.blessTips[dbid] = nil
        --add degree
        local theFriendInfo = owner.friends[dbid]
        if theFriendInfo[friendsInfoIndex.degreeIndex] < public_config.FRIEND_DEGREE_MAX then
            theFriendInfo[friendsInfoIndex.degreeIndex] = theFriendInfo[friendsInfoIndex.degreeIndex] + 
                public_config.FRIEND_BLESS_DEGREE
        end
        if theFriendInfo[friendsInfoIndex.degreeIndex] > public_config.FRIEND_DEGREE_MAX then
            theFriendInfo[friendsInfoIndex.degreeIndex] = public_config.FRIEND_DEGREE_MAX
        end

        if owner:hasClient() then
            owner.client.OnFriendRecvBlessResp(tmpEnergy, dbid, err)
        end
    end
end

function FriendSystem:RecvAllBlessReq()
    --领取体力上限，暂定20，后面与vip系统相关
    local owner = self.ptr.theOwner
    if not owner then
        return
    end
    if owner.friendRefreshTime < os.time() then
        self:Refresh()
    end
    if owner.friendsEnergy >= self:GetEnergyLimit() then
        --if owner:hasClient() then
            --owner.client.OnFriendRecvAllBlessResp(0, {}, error_code.ERR_FRIEND_BLESS_GET_FULL)
        --end
        self:ShowTextID(732)
        return
    end
    --OfflineMgr:GetTypeOf( mbStr, msgId, offType, acceptId, remo )
    globalbase_call("OfflineMgr", "GetTypeOf", 
        owner.base_mbstr,
        msgOfflineMgr.MSG_OFFLINE_FRIEND_BLESS_RECV_ALL,
        OfflineType.MSG_RECORD_BLESS_BE, 
        owner.dbid, 
        0 --非零:load完删除
        )
end
--领取所有祝福
function FriendSystem:RecvAllBless( allBless, err )
    local owner = self.ptr.theOwner
    if not owner then
        return
    end
    --没有祝福
    local blessNum = lua_util.get_table_real_count(allBless)
    if blessNum == 0 then
        if owner:hasClient() then
            owner.client.OnFriendRecvAllBlessResp(0, {}, error_code.ERR_FRIEND_BLESS_NOT_EXISTS)
        end
        return
    end
    local energy_limit = self:GetEnergyLimit()
    if owner.friendsEnergy >= energy_limit then
        if owner:hasClient() then
            owner.client.OnFriendRecvAllBlessResp(0, {}, error_code.ERR_FRIEND_RECV_BLESS_FULL)
        end
        return
    end

    local sum_limit = g_energy_mgr:GetEnergyLimit(owner.level)
    if owner.energy >= sum_limit then
        return owner:AddEnergy(0, reason_def.friend_bless) 
    end

    local err = error_code.ERR_FRIEND_SUCCEED
    local theEnergy = 0
    local theDbids = {}
    for i,v in pairs(allBless) do
        --OfflineMgr:Del( offType, acceptId, fromIdIndex, dbid )
        globalbase_call("OfflineMgr", "Del", 
            OfflineType.MSG_RECORD_BLESS_BE, 
            owner.dbid, 
            FriendBeBlessIndex.fromId,
            v[FriendBeBlessIndex.fromId]
            )
        
        table.insert(theDbids, v[FriendBeBlessIndex.fromId])
        self.blessTips[v[FriendBeBlessIndex.fromId]] = nil
        theEnergy = theEnergy + public_config.FRIEND_BE_BLESS_ENERGY
        local tmpEnergy = owner.friendsEnergy + theEnergy
        if tmpEnergy >= energy_limit or owner.energy + theEnergy > sum_limit then
            theEnergy = energy_limit - owner.friendsEnergy
            if theEnergy > sum_limit - owner.energy then
                theEnergy = sum_limit - owner.energy
                break
            end
            err = error_code.ERR_FRIEND_RECV_BLESS_FULL
            break 
        end
    end

    if owner:AddEnergy(theEnergy, reason_def.friend_bless) then
        owner.friendsEnergy = owner.friendsEnergy + theEnergy
        if owner:hasClient() then
            owner.client.OnFriendRecvAllBlessResp(theEnergy, theDbids, err)
        end
    else
        log_game_error("FriendSystem:RecvAllBless", "dbid = %q", owner.dbid)
        --owner.client.OnFriendRecvAllBlessResp(theEnergy, theDbids, err)
    end
end


----------一下提供给其他后端系统调用
--增加好友友情值
function FriendSystem:AddDegree( dbid, num )
    local owner = self.ptr.theOwner
    if not owner then
        return false
    end
    local theFriendInfo = owner.friends[dbid] --blessItem[delIndex.fromId]
    if not theFriendInfo then
        log_game_error('FriendSystem:FriendBeBless', 'myDBID[%d], friendDBID[%d]', owner.dbid, dbid)
        return false
    end

    if theFriendInfo[friendsInfoIndex.degreeIndex] < public_config.FRIEND_DEGREE_MAX then
        theFriendInfo[friendsInfoIndex.degreeIndex] = theFriendInfo[friendsInfoIndex.degreeIndex] + num
    end
    if theFriendInfo[friendsInfoIndex.degreeIndex] > public_config.FRIEND_DEGREE_MAX then
        theFriendInfo[friendsInfoIndex.degreeIndex] = public_config.FRIEND_DEGREE_MAX
    end
    return true
end
--获取好友友情值
function FriendSystem:GetDegree(dbid)
    local owner = self.ptr.theOwner
    if not owner then
        return
    end
    local theFriendInfo = owner.friends[dbid]
    if not theFriendInfo then
        log_game_error('FriendSystem:FriendBeBless', 'myDBID[%d], friendDBID[%d]', owner.dbid, dbid)
        return
    end
    return theFriendInfo[friendsInfoIndex.degreeIndex]
end
--获取下一次可雇佣时间
function FriendSystem:GetNextHireTime(dbid)
    local owner = self.ptr.theOwner
    if not owner then
        return
    end
    local theFriendInfo = owner.friends[dbid]
    if not theFriendInfo then
        log_game_error('FriendSystem:GetNextHireTime', 'myDBID[%d], friendDBID[%d]', owner.dbid, dbid)
        return
    end
    return theFriendInfo[friendsInfoIndex.nextHireTimeIndex]
end
--增加
--[[
function FriendSystem:AddBlessEnergySingle()
    local owner = self.ptr.theOwner
    if not owner then
        return
    end
    local tmpEnergy = owner.friendsEnergy + public_config.FRIEND_BE_BLESS_ENERGY
    if tmpEnergy > self:GetEnergyLimit() then
        owner.energy = owner.energy + self:GetEnergyLimit() - owner.friendsEnergy
        owner.friendsEnergy = self:GetEnergyLimit()
        return
    end
    owner.friendsEnergy = owner.friendsEnergy + public_config.FRIEND_BE_BLESS_ENERGY
    owner.energy = owner.energy + public_config.FRIEND_BE_BLESS_ENERGY
end
]]
function FriendSystem:GetFriendEnergy()
    --return self.ptr.theOwner.friends[friendsInfoIndex.energyIndex]
    return self.ptr.theOwner.friendsEnergy
end

function FriendSystem:GetNextRefreshTime()
    --return self.ptr.theOwner.friends[friendsInfoIndex.nextRefreshTimeIndex]
    return self.ptr.theOwner.friendRefreshTime
end

function FriendSystem:Refresh()
    self.ptr.theOwner.friendsEnergy = 0
    --local nextTime = math.ceil(os.time() / 86400) * 86400
    self.ptr.theOwner.friendRefreshTime = lua_util.get_secs_until_next_hhmiss(0, 0, 0)
end
--显示浮动文字提示
function FriendSystem:ShowTextID(textId)
    local owner = self.ptr.theOwner
    if owner:hasClient() then
        owner.client.ShowTextID(CHANNEL.TIPS, textId)
    end
end

function FriendSystem:GetFriendNum()
    return lua_util.get_table_real_count(self.friends)
end

return FriendSystem
