---
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 13-3-1
-- Time: 上午10:01
-- 频道管理器.
--

require "lua_util"
require "public_config"
require "error_code"


local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning


local _CHANNEL_WORLD      = public_config.CHANNEL_WORLD       --世界频道
local _CHANNEL_GUILD      = public_config.CHANNEL_GUILD       --帮派频道
local _CHANNEL_PRIVATE    = public_config.CHANNEL_PRIVATE     --私聊频道

--频道发言的cd时间
local _CD_TIME = { [_CHANNEL_WORLD] = 1, [_CHANNEL_PRIVATE] = 1, [_CHANNEL_GUILD] = 1,
}


local ChannelMgr = {}
ChannelMgr.__index = ChannelMgr

----------------------------------------------------------------------------------------

--玩家请求在频道里发言
local _DEFAULT_ITEM_DATA = {}
function ChannelMgr:channel_req(avatar, ch_id, to_name, text, item_list)
    --是否合法的频道
    local cd = _CD_TIME[ch_id]
    if cd == nil then
        return error_code.ERR_CHANNEL_ERR_CH_ID
    end

    --检查cd时间
    local last_time = avatar.channel_cd[ch_id]
    local now_time = os.time()
    if last_time ~= nil then
        if last_time + cd > now_time then
            return error_code.ERR_CHANNEL_CD
        end
    end

    --字符长度判断,不能超过60个字
    local _len = lua_util.utfstrlen(text)
    if _len == 0 then
        return error_code.ERR_CHANNEL_TEXT_EMPTY
    end
    if _len > 60 then
        return error_code.ERR_CHANNEL_TEXT_TOO_LONG
    end

    --敏感字过滤(收发的消息都由客户端处理)

    if ch_id == _CHANNEL_PRIVATE then
        --不要自己和自己私聊吧
        if to_name == avatar.name then
            return error_code.ERR_CHANNEL_PRIVATE_SELF
        end
    end

    --记录发言时间
    avatar.channel_cd[ch_id] = now_time

    --获取道具展示信息
    local item_data
    if #item_list > 0 then
        item_data = avatar:channel_get_items(item_list)
    else
        item_data = _DEFAULT_ITEM_DATA
    end

    if ch_id == _CHANNEL_GUILD then
        --帮派频道
        if avatar.guild_dbid == 0 then
            return error_code.ERR_CHANNEL_NOTIN_GUILD
        end

        avatar.guild_mb.channel_req(avatar.channel_str, text, item_data)

        return 0
    end

    --其他频道发到UserMgr转发
    local mgr = globalBases['UserMgr']
    if mgr then
        mgr.channel_req(ch_id, avatar.channel_str, to_name, text, item_data)
    end

    return 0
end

local _ITEM_KEY_ID = public_config.ITEM_KEY_ID
function ChannelMgr:make_item_seq_data(item_data, mgr)
    local item_data11 = {}  --发给客户端的数据结构,包括道具id和seq
    local item_data22 = {}  --发给UserMgr的数据,包括seq和道具完整数据
    for k, v in pairs(item_data) do
        local seq = mgr:get_item_seq()
        item_data11[k] = {v[_ITEM_KEY_ID], seq }
        item_data22[seq] = mogo.cpickle(v)
    end
    return item_data11, item_data22
end

function ChannelMgr:get_item_seq(mgr, min_seq, max_seq)
    local seq = mgr.item_seq
    if seq < min_seq then
        seq = min_seq
    elseif seq >= max_seq then
        seq = min_seq
    else
        seq = seq + 1
    end

    mgr.item_seq = seq
    return seq
end

----------------------------------------------------------------------------------------

g_channel_mgr = ChannelMgr
return g_channel_mgr


