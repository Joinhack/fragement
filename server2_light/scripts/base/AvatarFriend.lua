--author:hwj
--date:2013-4-23
--此为Avatar扩展类,只能由Avatar require使用
--避免Avatar.lua文件过长

local log_game_debug = lua_util.log_game_debug
local PLAYER_DBID_INDEX = public_config.USER_MGR_PLAYER_DBID_INDEX
local PLAYER_NAME_INDEX = public_config.USER_MGR_PLAYER_NAME_INDEX
local PLAYER_LEVEL_INDEX = public_config.USER_MGR_PLAYER_LEVEL_INDEX
local PLAYER_VOCATION_INDEX = public_config.USER_MGR_PLAYER_VOCATION_INDEX
local PLAYER_GENDER_INDEX = public_config.USER_MGR_PLAYER_GENDER_INDEX
local PLAYER_UNION_INDEX = public_config.USER_MGR_PLAYER_UNION_INDEX
local PLAYER_FIGHT_INDEX = public_config.USER_MGR_PLAYER_FIGHT_INDEX
local PLAYER_IS_ONLINE_INDEX = public_config.USER_MGR_PLAYER_IS_ONLINE_INDEX

-->与UserMgr交互接口
function Avatar:FriendQueryInfoByPlayerNameResp( MsgId, PlayerName, PlayerInfo )
    log_game_debug('FriendQueryInfoByPlayerNameResp', '')
    if msgUserMgr.MSG_USER_FRIEND_QUERY_BY_NAME == MsgId then
        local err = error_code.ERR_FRIEND_SUCCEED
        if not PlayerInfo or lua_util.get_table_real_count(PlayerInfo) == 0 then
           PlayerInfo = {}
           err = error_code.ERR_FRIEND_NOT_EXISTS
        end
        local needInfo = {
            [1] = PlayerInfo[PLAYER_DBID_INDEX],
            [2] = PlayerInfo[PLAYER_VOCATION_INDEX],
            [3] = PlayerInfo[PLAYER_NAME_INDEX],
            [4] = PlayerInfo[PLAYER_LEVEL_INDEX],
            [5] = PlayerInfo[PLAYER_FIGHT_INDEX],
            [6] = PlayerInfo[PLAYER_IS_ONLINE_INDEX],
        }
        log_game_debug('FriendQueryInfoByPlayerNameResp', '%s', PlayerInfo[PLAYER_NAME_INDEX])
        self.client.OnFriendResearchReqResp(needInfo, err)
        return true
    else
        return false
    end
end

function Avatar:FriendQueryInfoByPlayerDbidResp( MsgId, PlayerDbid, PlayerInfo )
    --查看好友详细信息,这个如果好友在线可以查看更多好友信息，待扩展
    if     MsgId == msgUserMgr.MSG_USER_FRIEND_QUERY_BY_DBID then
        if PlayerInfo and lua_util.get_table_real_count(PlayerInfo) > 0 then
            
        else 
           --self.client.OnFriendAddResp(error_code.ERR_FRIEND_NOT_EXISTS)
        end
    --返回所有好友信息
    elseif MsgId == msgUserMgr.MSG_USER_FRIEND_QUERY_BY_ALL_DBID then
        self.friendSystem:SendAllFriendInfoDown(PlayerInfo)   
    else
        return false
    end
    return true 
end

--UserMgr回调
function Avatar:FriendRpcRelayCallback( MsgId, dbid, PlayerInfo, err)
    log_game_debug('Avatar:FriendRpcRelayCallback', 'MsgId = %d', MsgId)
    --申请增加好友
    if     MsgId == msgUserMgr.MSG_USER_FRIEND_ADD_REQ then
        --self.client.OnFriendAddReqResp(err)
        if err == error_code.ERR_FRIEND_SUCCEED or  err == error_code.ERR_USER_MGR_OFFLINE then
            self.friendSystem:ShowTextID(friendTipsId.TEXT_SEND_REQ_SUCCEED)
            self.friendSystem:SendAddReq(dbid)
        elseif err == error_code.ERR_USER_MGR_PLAYER_FRIEND_FULL then
            self.friendSystem:ShowTextID(friendTipsId.TEXT_THE_PLAYER_FRIEND_FULL)
        else
            self.friendSystem:ShowTextID(friendTipsId.TEXT_SEND_REQ_FAIL)
        end
    -->接受好友申请
    elseif MsgId == msgUserMgr.MSG_USER_FRIEND_ACCEPT then
        if err == error_code.ERR_OFFLINE_SUCCEED or err == error_code.ERR_USER_MGR_OFFLINE then
            self.friendSystem:Req(msgFriendSys.MSG_FRIEND_INSERT, dbid) 
            self.client.OnFriendAcceptResp(error_code.ERR_OFFLINE_SUCCEED)     
        else
            self.client.OnFriendAcceptResp(err)
        end
    --<接受好友申请
    --发送好友留言,这个放在offlineMgr内部处理
    elseif MsgId == msgUserMgr.MSG_USER_FRIEND_SEND_NOTE then 
        if err == error_code.ERR_FRIEND_SUCCEED or  err == error_code.ERR_USER_MGR_OFFLINE then
            self.friendSystem:ShowTextID(friendTipsId.TEXT_SEND_NOTE_SUCCEED)
            self.client.OnFriendSendNoteResp(error_code.ERR_FRIEND_SUCCEED)
        else
            self.friendSystem:ShowTextID(friendTipsId.TEXT_SEND_NOTE_FAIL)
            self.client.OnFriendSendNoteResp(err)
        end
    --好友祝福
    elseif MsgId == msgUserMgr.MSG_USER_FRIEND_BLESS then
        self.friendSystem:BlessCallBack(dbid, err)
    else
        return false
    end
    return true 
end
--OfflineMgr回调
function Avatar:FriendOfflineMgrCallback( MsgId, dbid, PlayerInfo, err)
    -->接受好友申请
    if     MsgId == msgOfflineMgr.MSG_OFFLINE_FRIEND_REQ_DEL then
        if err == error_code.ERR_OFFLINE_SUCCEED then
            self.friendSystem:Req(msgFriendSys.MSG_FRIEND_ACCEPT, dbid)
        else
            --接受的申请已过时或者不存在
            self.client.OnFriendAcceptResp(error_code.ERR_FRIEND_REQ_NOT_EXISTS)
        end
    --读取好友留言
    elseif MsgId == msgOfflineMgr.MSG_OFFLINE_FRIEND_NOTE_GET then
        --print('read note', 'get back=================')
        local notes = {}
        for k,v in pairs(PlayerInfo) do
            notes[k] = {
                id = v[noteIndex.fromId],
                content = v[noteIndex.note],
                time = v[noteIndex.time],
            }
        end
        lua_util.print_table(notes)
        self.client.OnFriendReadNoteResp(notes, err)
    --<接受好友申请
    -->返回所有好友的申请消息
    elseif MsgId == msgOfflineMgr.MSG_OFFLINE_FRIEND_REQ_GET then
        self.client.OnFriendReqListResp(PlayerInfo, err)
    --领取好友祝福
    elseif MsgId == msgOfflineMgr.MSG_OFFLINE_FRIEND_BLESS_RECV then
        self.friendSystem:RecvBless(dbid, err)
    --
    elseif MsgId == msgOfflineMgr.MSG_OFFLINE_FRIEND_BLESS_RECV_ALL then
        self.friendSystem:RecvAllBless(PlayerInfo, err)
    else
        return false
    end
    return true
end
--被动
function Avatar:FriendBeRpcRelayCall( MsgId, Item)
    --申请增加好友
    if     MsgId == msgUserMgr.MSG_USER_FRIEND_ADD_REQ_BE then
        if self:hasClient() then
            self.client.OnFriendRecvBeAddResp(Item)
        end
    --好友申请被接受
    elseif MsgId == msgUserMgr.MSG_USER_FRIEND_ACCEPT_BE then
        local bHas = self.friendSystem:Req(msgFriendSys.MSG_FRIEND_CHECK, Item[respIndex.fromId])
        if not bHas then
            self.friendSystem:Req(msgFriendSys.MSG_FRIEND_INSERT, Item[respIndex.fromId]) 
        end
    --对方删除我为好友
    elseif MsgId == msgUserMgr.MSG_USER_FRIEND_DEL_REQ_BE then
        self.friendSystem:Req(msgFriendSys.MSG_FRIEND_REMOVE, Item[delIndex.fromId])
    --发送好友留言,这个放在offlineMgr内部处理
    elseif MsgId == msgUserMgr.MSG_USER_FRIEND_SEND_NOTE_BE then 
        log_game_debug('FriendBeRpcRelayCall', '')
        self.friendSystem.noteTips[Item[noteIndex.fromId]] = 1
        local notes= {
            id = Item[noteIndex.fromId],
            content = Item[noteIndex.note],
            time = Item[noteIndex.time],
        }
        if self:hasClient() then
            self.client.OnFriendRecvNoteResp(notes)
        end
    --被祝福
    elseif MsgId == msgUserMgr.MSG_USER_FRIEND_BLESS_BE then
        log_game_debug('Avatar:FriendBeRpcRelayCall', '')
        self.friendSystem:BeBless(Item)
    else
    	return false
    end
    return true
end
--<与UserMgr交互接口

-->好友子系统begin
function Avatar:FriendAddReq( dbid )
    if dbid == self.dbid then
        self.friendSystem:ShowTextID(friendTipsId.TEXT_ADD_MYSELF)
        return
    end
    if self.friendSystem:Req(msgFriendSys.MSG_FRIEND_ISFULL) then
        --self.client.OnFriendAddReqResp(error_code.ERR_FRIEND_FULL)
        self.friendSystem:ShowTextID(friendTipsId.TEXT_FULL)
        return
    end
    if self.friendSystem:Req(msgFriendSys.MSG_FRIEND_CHECK, dbid) then
        --self.client.OnFriendAddReqResp(error_code.ERR_FRIEND_ALREADY_HAS)
        self.friendSystem:ShowTextID(friendTipsId.TEXT_ALREADY_HAVE)
        return
    end
    --调用好友系统AddFriend
    self.friendSystem:Req(msgFriendSys.MSG_FRIEND_REQ_ADD, dbid)
end

function Avatar:FriendDelReq( dbid )
    --删除自身该好友
    if self.friendSystem:Req(msgFriendSys.MSG_FRIEND_REMOVE, dbid) then
        self.friendSystem:Req(msgFriendSys.MSG_FRIEND_DEL, dbid)
        self.client.OnFriendDelResp(error_code.ERR_FRIEND_SUCCEED)
        return
    end
    self.client.OnFriendDelResp(error_code.ERR_FRIEND_NOT_EXISTS)
end

function Avatar:FriendListReq( )  
    self.friendSystem:Req(msgFriendSys.MSG_FRIEND_LIST)
end

function Avatar:FriendResearchReq( name )
    log_game_debug('FriendResearchReq', '%s', name)
    self.friendSystem:Req(msgFriendSys.MSG_FRIEND_QUERY, name)
end

function Avatar:FriendReqListReq( )
    self.friendSystem:Req(msgFriendSys.MSG_FRIEND_REQ_LIST)
end

function Avatar:FriendAcceptReq( dbid )
    log_game_debug("Avatar:FriendAcceptReq", "")
    if self.friendSystem:Req(msgFriendSys.MSG_FRIEND_ISFULL) then
        self.client.OnFriendAcceptResp(dbid, error_code.ERR_FRIEND_FULL)
         --no callback just del
        self.friendSystem:Req(msgFriendSys.MSG_FRIEND_REQ_DEL, dbid, 0)
        return
    end
    if self.friendSystem:Req(msgFriendSys.MSG_FRIEND_CHECK, dbid) then
        self.client.OnFriendAcceptResp(dbid, error_code.ERR_FRIEND_ALREADY_HAS)
        --no callback just del
        self.friendSystem:Req(msgFriendSys.MSG_FRIEND_REQ_DEL, dbid, 0)
        return
    end
    log_game_debug("Avatar:FriendAcceptReq", "")
    self.friendSystem:Req(msgFriendSys.MSG_FRIEND_REQ_DEL, dbid, msgOfflineMgr.MSG_OFFLINE_FRIEND_REQ_DEL)
end
function Avatar:FriendRejectReq( dbid )
    --no callback just del
    self.friendSystem:Req(msgFriendSys.MSG_FRIEND_REQ_DEL, dbid, 0)
end
function Avatar:FriendSendNoteReq( dbid, context )
    if self.friendSystem:Req(msgFriendSys.MSG_FRIEND_CHECK, dbid) then
        local len = lua_util.utfstrlen(context)
        if len > public_config.FRIEND_CONTEXT_LEN_LIMIT then
            self.friendSystem:ShowTextID(error_code.ERR_FRIEND_MSG_TOO_MUCH)
            return
        end
        self.friendSystem:Req(msgFriendSys.MSG_FRIEND_NOTE_W, dbid, context)
        return
    end
    self.friendSystem:ShowTextID(friendTipsId.TEXT_SEND_NOTE_NOT_FRIEND)
    self.client.OnFriendSendNoteResp(error_code.ERR_FRIEND_NOT_MY_FRIEND)
end

function Avatar:FriendReadNoteReq( dbid )
    self.friendSystem:Req(msgFriendSys.MSG_FRIEND_NOTE_R, dbid, msgOfflineMgr.MSG_OFFLINE_FRIEND_NOTE_GET)
end

function Avatar:FriendBlessReq( dbid )
    log_game_debug('Avatar:FriendBlessReq', '')
    self.friendSystem:BlessReq(dbid)
end

function Avatar:FriendRecvBlessReq( dbid )
    log_game_debug('Avatar:FriendRecvBlessReq', '')
    self.friendSystem:RecvBlessReq(dbid)
end

function Avatar:FriendRecvAllBlessReq()
    log_game_debug('Avatar:FriendRecvAllBlessReq', '')
    self.friendSystem:RecvAllBlessReq()
end

--<好友子系统end

--后端内部接口
function Avatar:AddFriendDegree( dbid, num )
    return self.friendSystem:AddDegree(dbid, num)
end

function Avatar:GetFriendDegree( dbid )
    return self.friendSystem:GetDegree(dbid)
end