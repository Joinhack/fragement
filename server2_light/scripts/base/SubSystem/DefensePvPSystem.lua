--PvP防御对抗活动子系统


require "lua_util"
require "lua_map"
require "public_config"
require "channel_config"
require "defense_pvp_config"
require "GlobalParams"
require "reason_def"


local log_game_debug 	= lua_util.log_game_debug
local log_game_warning 	= lua_util.log_game_warning
local log_game_info 	= lua_util.log_game_info
local log_game_error 	= lua_util.log_game_error
local _readXml          = lua_util._readXml
local globalbase_call   = lua_util.globalbase_call


DefensePvPSystem = {}
DefensePvPSystem.__index = DefensePvPSystem


--等级限制
local LIMIT_LEVEL = 35

--消息提示，对应ChineseData.xml表定义
local TEXT_LEVEL_LIMIT      = 1008001        --您的等级不足！
local TEXT_MAIL_TITLE       = 1008002        --PvP奖励
local TEXT_MAIL_TEXT        = 1008003        --您将获得一份奖励，请查收！
local TEXT_MAIL_FROM        = 1008004        --PvP系统
local TEXT_MAX_LEVEL_LIMIT  = 1008005        --您已超过最大等级限制！



function DefensePvPSystem:InitData()
    LIMIT_LEVEL = g_GlobalParamsMgr:GetParams('defense_pvp_limit_level', LIMIT_LEVEL)   --等级限制
end

function DefensePvPSystem:new(owner)
    local newObj    = {}
    newObj.ptr      = {}
    setmetatable(newObj,        {__index = DefensePvPSystem})
    setmetatable(newObj.ptr,    {__mode = "v"})

    newObj.ptr.theOwner = owner

    local msgMapping = {
        [DEFENSE_PVP_CONFIG.MSG_APPLY] 			= DefensePvPSystem.OnApply,		--申请进入
        [DEFENSE_PVP_CONFIG.MSG_ENTER]          = DefensePvPSystem.OnEnter,     --进入副本
        [DEFENSE_PVP_CONFIG.MSG_CANCEL]         = DefensePvPSystem.OnCancel,    --离开队列
        [DEFENSE_PVP_CONFIG.MSG_STATE] 		    = DefensePvPSystem.OnState,     --查询状态
	}
    newObj.msgMapping       = msgMapping

    return newObj
end

--注销
function DefensePvPSystem:Del()
    local theOwner = self.ptr.theOwner
    if theOwner.level < LIMIT_LEVEL then
        return
    end
    self:MgrPost("EventCancel", {theOwner.dbid, 0})
end

function DefensePvPSystem:OnDefensePvPReq(msg_id, ...)
    log_game_debug("DefensePvPSystem:OnDefensePvPReq", "msg_id=%d;dbid=%q;name=%s", msg_id, self.ptr.theOwner.dbid, self.ptr.theOwner.name)

    local func = self.msgMapping[msg_id]
    if func ~= nil then
        func(self, ...)
    end
end

--发送消息至Mgr管理器
function DefensePvPSystem:MgrPost(mgr_func_name, mgr_func_param_table)
    local theOwner = self.ptr.theOwner
    globalbase_call("DefensePvPMgr", "MgrEventDispatch", theOwner.base_mbstr, mgr_func_name, mgr_func_param_table,
                    "", "", {})
end

--发送消息至Mgr管理器并回调至Avatar实例
function DefensePvPSystem:MgrCallToAvatar(mgr_func_name, mgr_func_param_table, callback_func_name, callback_func_param_table)
    local theOwner = self.ptr.theOwner
    if not callback_func_param_table then callback_func_param_table = {} end
    globalbase_call("DefensePvPMgr", "MgrEventDispatch", theOwner.base_mbstr, mgr_func_name, mgr_func_param_table,
                    "", callback_func_name, callback_func_param_table)
end

--发送消息至Mgr管理器并回调至Client
function DefensePvPSystem:MgrCallToClient(mgr_func_name, mgr_func_param_table, callback_func_name, callback_func_param_table)
    local theOwner = self.ptr.theOwner
    if not callback_func_param_table then callback_func_param_table = {} end
    globalbase_call("DefensePvPMgr", "MgrEventDispatch", theOwner.base_mbstr, mgr_func_name, mgr_func_param_table,
                    "client", callback_func_name, callback_func_param_table)
end

--发送消息至Mgr管理器并回调至本子系统
function DefensePvPSystem:MgrCall(mgr_func_name, mgr_func_param_table, callback_func_name, callback_func_param_table)
    local theOwner = self.ptr.theOwner
    if not callback_func_param_table then callback_func_param_table = {} end
    globalbase_call("DefensePvPMgr", "MgrEventDispatch", theOwner.base_mbstr, mgr_func_name, mgr_func_param_table,
                    "defensePvPSystem", callback_func_name, callback_func_param_table)
end

--发送消息至Mgr管理器
function DefensePvPSystem:UserMgrCallToAvatar(dbid, callback_func_name, callback_func_param_table)
    local theOwner = self.ptr.theOwner
    if not dbid or not callback_func_name then return end
    if not callback_func_param_table then callback_func_param_table = {} end
    globalbase_call("UserMgr", "EventDispatch", dbid, "defensePvPSystem", callback_func_name, callback_func_param_table)
end


------------------------------------------------------------------------

function DefensePvPSystem:OnApply()
    log_game_debug("DefensePvPSystem:OnApply", "")

    local theOwner = self.ptr.theOwner
    if theOwner.level < LIMIT_LEVEL or theOwner.level > public_config.LV_MAX then
        theOwner:ShowTextID(CHANNEL.TIPS, TEXT_LEVEL_LIMIT)
        return
    end

    if theOwner.level > public_config.LV_MAX then
        theOwner:ShowTextID(CHANNEL.TIPS, TEXT_MAX_LEVEL_LIMIT)
        return
    end

    self:MgrPost("EventApply", {theOwner.dbid, theOwner.name, theOwner.level, theOwner.fightForce})
end

function DefensePvPSystem:OnEnter()
    log_game_debug("DefensePvPSystem:OnEnter", "")

    local theOwner = self.ptr.theOwner
    if theOwner.level < LIMIT_LEVEL then
        theOwner:ShowTextID(CHANNEL.TIPS, TEXT_LEVEL_LIMIT)
        return
    end

    self:MgrPost("EventEnter", {theOwner.dbid})
end

function DefensePvPSystem:OnCancel()
    log_game_debug("DefensePvPSystem:OnCancel", "")

    local theOwner = self.ptr.theOwner
    if theOwner.level < LIMIT_LEVEL then
        return
    end

    self:MgrPost("EventCancel", {theOwner.dbid, 1})
end

function DefensePvPSystem:OnState()
    log_game_debug("DefensePvPSystem:OnState", "")

    local theOwner = self.ptr.theOwner

    self:MgrCallToClient("EventState", {theOwner.dbid}, "DefensePvPStateResp")
end

function DefensePvPSystem:OnChat(msg)
    local theOwner = self.ptr.theOwner
    self:MgrPost("EventChat", {theOwner.dbid, msg})
end


------------------------------------------------------------------------

function DefensePvPSystem:AwardItems(items)
    local theOwner = self.ptr.theOwner

    local mailItems = nil
    for itemId, itemNum in pairs(items) do
        if theOwner:AddItem(itemId, itemNum, reason_def.defensePvP) == false then
            mailItems = mailItems or {}
            mailItems[itemId] = itemNum
        end
    end
    if mailItems then
        local mailMgr = globalBases["MailMgr"]
        if mailMgr then
            mailMgr.SendIdEx(TEXT_MAIL_TITLE, "", TEXT_MAIL_TEXT, TEXT_MAIL_FROM, os.time(), mailItems, {theOwner.dbid}, {}, reason_def.defensePvP)
        end
    end
end


------------------------------------------------------------------------

g_DefensePvPSystem = DefensePvPSystem
return g_DefensePvPSystem
















