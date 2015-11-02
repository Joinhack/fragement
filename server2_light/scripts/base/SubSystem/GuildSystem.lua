
require "guild_config"
require "lua_util"
require "GlobalParams"
require "reason_def"
require "action_config"

local log_game_debug = lua_util.log_game_debug
local log_game_error = lua_util.log_game_error
local globalbase_call = lua_util.globalbase_call

GuildSystem = {}
GuildSystem.__index = GuildSystem

--function GuildSystem:new( owner )
--
--    local newObj = {}
--    newObj.ptr = {}
--
--    setmetatable(newObj, {__index = GuildSystem})
--    setmetatable(newObj.ptr, {__mode = "kv"})
--
--    newObj.ptr.theOwner = owner
--
--    local msgMapping = {
--
--        --客户端到base的请求
--        [guild_config.MSG_GET_GUILDS]               = GuildSystem.GetGuilds,                --分页获取服务器的公会
--        [guild_config.MSG_GET_GUILDS_COUNT]         = GuildSystem.GetGuildsCount,           --获取服务器的公会个数
--        [guild_config.MSG_CREATE_GUILD]             = GuildSystem.CreateGuild,              --创建公会
--        [guild_config.MSG_GET_GUILD_INFO]           = GuildSystem.GetGuildInfo,             --获取玩家的公会信息
--        [guild_config.MSG_SET_GUILD_ANNOUNCEMENT]   = GuildSystem.SetGuildAnnouncement,     --设置公会公告
--        [guild_config.MSG_GET_GUILD_ANNOUNCEMENT]   = GuildSystem.GetGuildAnnouncement,     --获取公会公告
--        [guild_config.MSG_APPLY_TO_JOIN]            = GuildSystem.ApplyToJoin,              --申请加入指定的公会
--        [guild_config.MSG_GET_GUILD_DETAILED_INFO]  = GuildSystem.GetGuildDetailedInfo,     --获取玩家的详细公会信息
--        [guild_config.MSG_GET_GUILD_MESSAGES_COUNT] = GuildSystem.GetGuildMessagesCount,    --获取指定公会消息数量
--        [guild_config.MSG_GET_GUILD_MESSAGES]       = GuildSystem.GetGuildMessages,         --分页获取指定公会消息
--        [guild_config.MSG_ANSWER_APPLY]             = GuildSystem.AnswerApply,              --接受\拒绝指定ID的申请
--        [guild_config.MSG_INVITE]                   = GuildSystem.Invite,                   --邀请制定玩家加入公会
--        [guild_config.MSG_ANSWER_INVITE]            = GuildSystem.AnswerInvite,             --回应公会长的邀请
--        [guild_config.MSG_QUIT]                     = GuildSystem.Quit,                     --退出公会
--        [guild_config.MSG_PROMOTE]                  = GuildSystem.Promote,                  --升职
--        [guild_config.MSG_DEMOTE]                   = GuildSystem.Demote,                   --降职
--        [guild_config.MSG_EXPEL]                    = GuildSystem.Expel,                    --开除
--        [guild_config.MSG_DEMISE]                   = GuildSystem.Demise,                   --转让
--        [guild_config.MSG_DISMISS]                  = GuildSystem.Dismiss,                  --解散
--        [guild_config.MSG_THAW]                     = GuildSystem.Thaw,                     --解冻
--        [guild_config.MSG_RECHARGE]                 = GuildSystem.Recharge,                 --注魔
--        [guild_config.MSG_GET_GUILD_MEMBERS]        = GuildSystem.GetGuildMembers,          --获取工会成员列表
--        [guild_config.MSG_GET_DRAGON]               = GuildSystem.GetDragon,                --敲龙晶
--        [guild_config.MSG_UPGRADE_GUILD_SKILL]      = GuildSystem.UpgradeGuildSkill,        --升级公会技能
--        [guild_config.MSG_GET_RECOMMEND_LIST]       = GuildSystem.GetRecommedList,          --获取推荐列表
--        [guild_config.MSG_GET_DRAGON_INFO]          = GuildSystem.GetDragonInfo,            --获取龙晶信息
--
--        [guild_config.MSG_UPGRADE_GUILD_SKILL_RESP] = GuildSystem.UpgradeGuildSkillResp,    --公会长升级技能成功后通知每一个成员
--        [guild_config.MSG_GET_DRAGON_RESP]          = GuildSystem.GetDragonResp,            --龙晶充魔的返回
--        [guild_config.MSG_RECHARGE_RESP]            = GuildSystem.RechargeResp,             --龙晶充魔的返回
--        [guild_config.MSG_SUBMIT_CREATE_GUILD_COST] = GuildSystem.SubmitCreateGuildCost,    --创建公会成功后扣除资源
--        [guild_config.MSG_SET_GUILD_ID]             = GuildSystem.SetGuildId,               --设置玩家的公会ID
--    }
--    newObj.msgMapping = msgMapping
--
--    return newObj
--end
--
----入口函数
--function GuildSystem:GuildReq(msg_id, ...)
--    log_game_debug("GuildSystem:GuildReq", "msg_id=%d;dbid=%q;name=%s", msg_id, self.ptr.theOwner.dbid, self.ptr.theOwner.name)
--
--    local func = self.msgMapping[msg_id]
--    if func ~= nil then
--        func(self, ...)
--    end
--
--end

GuildSystem.msgMapping = {

        [action_config.MSG_GET_GUILDS]               = "GetGuilds",                --分页获取服务器的公会
        [action_config.MSG_GET_GUILDS_COUNT]         = "GetGuildsCount",           --获取服务器的公会个数
        [action_config.MSG_CREATE_GUILD]             = "CreateGuild",              --创建公会
        [action_config.MSG_GET_GUILD_INFO]           = "GetGuildInfo",             --获取玩家的公会信息
        [action_config.MSG_SET_GUILD_ANNOUNCEMENT]   = "SetGuildAnnouncement",     --设置公会公告
        [action_config.MSG_GET_GUILD_ANNOUNCEMENT]   = "GetGuildAnnouncement",     --获取公会公告
        [action_config.MSG_APPLY_TO_JOIN]            = "ApplyToJoin",              --申请加入指定的公会
        [action_config.MSG_GET_GUILD_DETAILED_INFO]  = "GetGuildDetailedInfo",     --获取玩家的详细公会信息
        [action_config.MSG_GET_GUILD_MESSAGES_COUNT] = "GetGuildMessagesCount",    --获取指定公会消息数量
        [action_config.MSG_GET_GUILD_MESSAGES]       = "GetGuildMessages",         --分页获取指定公会消息
        [action_config.MSG_ANSWER_APPLY]             = "AnswerApply",              --接受\拒绝指定ID的申请
        [action_config.MSG_INVITE]                   = "Invite",                   --邀请制定玩家加入公会
        [action_config.MSG_ANSWER_INVITE]            = "AnswerInvite",             --回应公会长的邀请
        [action_config.MSG_QUIT]                     = "Quit",                     --退出公会
        [action_config.MSG_PROMOTE]                  = "Promote",                  --升职
        [action_config.MSG_DEMOTE]                   = "Demote",                   --降职
        [action_config.MSG_EXPEL]                    = "Expel",                    --开除
        [action_config.MSG_DEMISE]                   = "Demise",                   --转让
        [action_config.MSG_DISMISS]                  = "Dismiss",                  --解散
        [action_config.MSG_THAW]                     = "Thaw",                     --解冻
        [action_config.MSG_RECHARGE]                 = "Recharge",                 --注魔
        [action_config.MSG_GET_GUILD_MEMBERS]        = "GetGuildMembers",          --获取工会成员列表
        [action_config.MSG_GET_DRAGON]               = "GetDragon",                  --敲龙晶
        [action_config.MSG_UPGRADE_GUILD_SKILL]      = "UpgradeGuildSkill",        --升级公会技能
        [action_config.MSG_GET_RECOMMEND_LIST]       = "GetRecommedList",          --获取推荐列表
        [action_config.MSG_GET_DRAGON_INFO]          = "GetDragonInfo",            --获取龙晶信息

    }

GuildSystem.msgB2BMapping = {

        [action_config.MSG_UPGRADE_GUILD_SKILL_RESP] = "UpgradeGuildSkillResp",    --公会长升级技能成功后通知每一个成员
        [action_config.MSG_GET_DRAGON_RESP]          = "GetDragonResp",            --龙晶充魔的返回
        [action_config.MSG_RECHARGE_RESP]            = "RechargeResp",             --龙晶充魔的返回
        [action_config.MSG_SUBMIT_CREATE_GUILD_COST] = "SubmitCreateGuildCost",    --创建公会成功后扣除资源
        [action_config.MSG_SET_GUILD_ID]             = "SetGuildId",               --设置玩家的公会ID
}

function GuildSystem:getFuncByMsgId(msg_id)
    return self.msgMapping[msg_id]
end

function GuildSystem:getB2BFuncByMsgId(msg_id)
    return self.msgB2BMapping[msg_id]
end

--获取指定数量的公会信息
function GuildSystem:GetGuilds(avatar, StartIndex, Count)
    log_game_debug("GuildSystem:GetGuilds", "dbid=%q;name=%s;StartIndex=%d;Count=%d",
                                             avatar.dbid, avatar.name, StartIndex, Count)

    globalbase_call("GuildMgr", "GetGuilds", avatar.base_mbstr, StartIndex, Count)
    return 0
end

--获取工会数量
function GuildSystem:GetGuildsCount(avatar)

    globalbase_call("GuildMgr", "GetGuildsCount", avatar.base_mbstr)
    return 0
end

--创建公会
function GuildSystem:CreateGuild(avatar, arg1, arg2, name)

    log_game_debug("GuildSystem:CreateGuild", "dbid=%q;name=%s;GuildInfo=%s",
                                              avatar.dbid, avatar.name, mogo.cPickle(avatar.GuildInfo))

--    if avatar.GuildInfo and avatar.GuildInfo ~= {} then
--        local result = {}
--        table.insert(result, avatar.GuildInfo[guild_config.GUILD_INFO_NAME])
--        table.insert(result, avatar.GuildInfo[guild_config.GUILD_INFO_POST])
--        avatar.client.GuildResp(guild_config.MSG_CREATE_GUILD, result)
--
--    else

    if avatar.level < g_GlobalParamsMgr:GetParams('create_guild_min_level', 30) then
        avatar.client.GuildResp(action_config.MSG_CREATE_GUILD, guild_config.ERROR_CREATE_GUILD_LEVEL_TOO_LOW, {})
        return
    end

    if avatar.diamond < g_GlobalParamsMgr:GetParams('create_guild_diamond_cost', 200) then
        avatar.client.GuildResp(action_config.MSG_CREATE_GUILD, guild_config.ERROR_CREATE_GUILD_NOT_ENOUGH_DIAMOND, {})
        return
    end

    globalbase_call("GuildMgr", "CreateGuild", avatar.base_mbstr, name,
                                               avatar.dbid, avatar.name,
                                               avatar.level, 0)
--    end
    return 0
end

--设置公会信息(服务器内部调用)
function GuildSystem:SetGuildId(avatar, arg1, arg2, info)
    log_game_debug("GuildSystem:SetGuildId", "dbid=%q;name=%s;info=%s",
                                              avatar.dbid, avatar.name, info)

    avatar.GuildInfo = mogo.cUnpickle(info)
    return 0
end

function GuildSystem:SubmitCreateGuildCost(avatar)
    log_game_debug("GuildSystem:SubmitCreateGuildCost", "dbid=%q;name=%s;info=%s",
                                                         avatar.dbid, avatar.name)

    avatar:AddDiamond(-g_GlobalParamsMgr:GetParams('create_guild_diamond_cost', 200), reason_def.create_guild)
    return 0
end


--获取玩家身上的公会信息
function GuildSystem:GetGuildInfo(avatar)
    log_game_debug("GuildSystem:GetGuildInfo", "dbid=%q;name=%s", avatar.dbid, avatar.name)

    local result = {}
    if avatar.GuildInfo then
        table.insert(result, avatar.GuildInfo[guild_config.GUILD_INFO_NAME] or '')
        table.insert(result, avatar.GuildInfo[guild_config.GUILD_INFO_POST] or 0)
    end

    if result[1] == '' and result[2] == 0 then
        avatar.client.GuildResp(action_config.MSG_GET_GUILD_INFO, guild_config.ERROR_GET_GUILD_INFO_NO_GUILD, result)
    else
        avatar.client.GuildResp(action_config.MSG_GET_GUILD_INFO, 0, result)
    end

    return 0

end

--设置公会公告
function GuildSystem:SetGuildAnnouncement(avatar, arg1, arg2, announcement)
    log_game_debug("GuildSystem:SetGuildAnnouncement", "dbid=%q;name=%s;announcement=%s",
                                                        avatar.dbid, avatar.name, announcement)

    globalbase_call("GuildMgr", "SetGuildAnnouncement", avatar.base_mbstr, avatar.dbid, announcement)
    return 0
end

--获取公会公告
function GuildSystem:GetGuildAnnouncement(avatar)
    log_game_debug("GuildSystem:GetGuildAnnouncement", "dbid=%q;name=%s",
                                                        avatar.dbid, avatar.name)

    globalbase_call("GuildMgr", "GetGuildAnnouncement", avatar.base_mbstr, avatar.dbid)
    return 0
end

--获取玩家公会的详细信息
function GuildSystem:GetGuildDetailedInfo(avatar)
    log_game_debug("GuildSystem:GetGuildDetailedInfo", "dbid=%q;name=%s",
                                                        avatar.dbid, avatar.name)

    globalbase_call("GuildMgr", "GetGuildDetailedInfo", avatar.base_mbstr, avatar.dbid)
    return 0
end

--申请加入公会
function GuildSystem:ApplyToJoin(avatar, guildDbid)
    log_game_debug("GuildSystem:ApplyToJoin", "dbid=%q;name=%s;guilddbid=%q;level=%d",
                                               avatar.dbid, avatar.name, guildDbid, avatar.level)

    globalbase_call("GuildMgr", "ApplyToJoin", avatar.base_mbstr, 
                                               avatar.dbid, 
                                               avatar.name, 
                                               avatar.vocation, 
                                               guildDbid, 
                                               avatar.level, 0)
    return 0
end

--获取制定类型公会信息数量
function GuildSystem:GetGuildMessagesCount(avatar, type)
    log_game_debug("GuildSystem:GetGuildMessagesCount", "dbid=%q;name=%s;type=%d",
                                                         avatar.dbid, avatar.name, type)

    globalbase_call("GuildMgr", "GetGuildMessagesCount", avatar.base_mbstr, avatar.dbid, type)

    return 0

end

--获取指定类型指定数量的公会信息
function GuildSystem:GetGuildMessages(avatar, StartIndex, Count, type)

    log_game_debug("GuildSystem:GetGuildMessages", "dbid=%q;name=%s;StartIndex=%d;Count=%d;type=%s",
                                                    avatar.dbid, avatar.name, StartIndex, Count, type)

    globalbase_call("GuildMgr", "GetGuildMessages",avatar.base_mbstr, avatar.dbid, StartIndex, Count, tonumber(type))

    return 0

end

--回应申请公会的请求
function GuildSystem:AnswerApply(avatar, opt, MessageDbid)
    log_game_debug("GuildSystem:AnswerApply", "dbid=%q;name=%s;opt=%d;Messagedbid=%q",
                                               avatar.dbid, avatar.name, opt, MessageDbid)

    globalbase_call("GuildMgr", "AnswerApply", avatar.base_mbstr, avatar.dbid, opt, MessageDbid)
    return 0
end

--邀请好友加入公会
function GuildSystem:Invite(avatar, PlayerDbid)
    log_game_debug("GuildSystem:Invite", "dbid=%q;name=%s;Playerdbid=%q",
                                          avatar.dbid, avatar.name, PlayerDbid)

    globalbase_call("UserMgr", "GuildInvite", avatar.base_mbstr, avatar.dbid, PlayerDbid)
    return 0
end

function GuildSystem:AnswerInvite(avatar, InviteCode, opt)
    log_game_debug("GuildSystem:AnswerInvite", "dbid=%q;name=%s;InviteCode=%d;opt=%d",
                                                avatar.dbid, avatar.name, InviteCode, opt)

    globalbase_call("GuildMgr", "AnswerInvite", avatar.base_mbstr, avatar.dbid, InviteCode, opt)
    return 0
end

function GuildSystem:Quit(avatar)
    log_game_debug("GuildSystem:Quit", "dbid=%q;name=%s", avatar.dbid, avatar.name)

    globalbase_call("GuildMgr", "Quit", avatar.base_mbstr, avatar.dbid)
    return 0
end

function GuildSystem:Promote(avatar, PlayerDbid)
    log_game_debug("GuildSystem:Promote", "dbid=%q;name=%s;Playerdbid=%q", avatar.dbid, avatar.name, PlayerDbid)

    if PlayerDbid == avatar.dbid then
        avatar.client.GuildResp(action_config.MSG_PROMOTE, guild_config.ERROR_PROMOTE_NOT_MYSELF, {})
        return 0
    end

    globalbase_call("GuildMgr", "Promote", avatar.base_mbstr, avatar.dbid, PlayerDbid)
    return 0
end

function GuildSystem:Demote(avatar, PlayerDbid)
    log_game_debug("GuildSystem:Demote", "dbid=%q;name=%s;Playerdbid=%q", avatar.dbid, avatar.name, PlayerDbid)

    if PlayerDbid == avatar.dbid then
        avatar.client.GuildResp(action_config.MSG_DEMOTE, guild_config.ERROR_DEMOTE_NOT_MYSELF, {})
        return 0
    end

    globalbase_call("GuildMgr", "Demote", avatar.base_mbstr, avatar.dbid, PlayerDbid)
    return 0
end

function GuildSystem:Expel(avatar, PlayerDbid)
    log_game_debug("GuildSystem:Expel", "dbid=%q;name=%s;Playerdbid=%q", avatar.dbid, avatar.name, PlayerDbid)

    if PlayerDbid == avatar.dbid then
        avatar.client.GuildResp(action_config.MSG_EXPEL, guild_config.ERROR_EXPEL_NOT_MYSELF, {})
        return 0
    end

    globalbase_call("GuildMgr", "Expel", avatar.base_mbstr, avatar.dbid, PlayerDbid)
    return 0

end

function GuildSystem:Demise(avatar, PlayerDbid)
    log_game_debug("GuildSystem:Demise", "dbid=%q;name=%s;Playerdbid=%q", avatar.dbid, avatar.name, PlayerDbid)

    if PlayerDbid == avatar.dbid then
        avatar.client.GuildResp(action_config.MSG_DEMISE, guild_config.ERROR_DEMISE_NOT_MYSELF, {})
        return
    end

    globalbase_call("GuildMgr", "Demise", avatar.base_mbstr, avatar.dbid, PlayerDbid)
    return 0
end

function GuildSystem:Dismiss(avatar)
    log_game_debug("GuildSystem:Dismiss", "dbid=%q;name=%s", avatar.dbid, avatar.name)

    globalbase_call("GuildMgr", "Dismiss", avatar.base_mbstr, avatar.dbid)
    return 0
end

function GuildSystem:Thaw(avatar)
    log_game_debug("GuildSystem:Thaw", "dbid=%q;name=%s", avatar.dbid, avatar.name)

    if avatar.diamond < g_GlobalParamsMgr:GetParams('thaw_guild_diamond_cost', 10) then
        avatar.client.GuildResp(action_config.MSG_THAW, guild_config.ERROR_THAW_NOT_ENOUGH_DIAMOND, {})
        return 0
    end

    globalbase_call("GuildMgr", "Thaw", avatar.base_mbstr, avatar.dbid)
    return 0
end

function GuildSystem:GetGuildMembers(avatar, StartIndex, Count)
    log_game_debug("GuildSystem:GetGuildMembers", "dbid=%q;name=%s;StartIndex=%d;Count=%d", 
                                                   avatar.dbid, avatar.name, StartIndex, Count)

    globalbase_call("GuildMgr", "GetGuildMembers", avatar.base_mbstr, avatar.dbid, StartIndex, Count)
    return 0
end

function GuildSystem:Recharge(avatar, type, charge)
    log_game_debug("GuildSystem:Recharge", "dbid=%q;name=%s;type=%d;charge=%d", avatar.dbid, avatar.name, type, charge)

    if type == guild_config.GUILD_RECHARGE_TYPE_GOLD then
        if avatar.gold < charge then
            avatar.client.GuildResp(action_config.MSG_RECHARGE, guild_config.ERROR_RECHARGE_NOT_ENOUGH_GOLD, {})
            return 0
        end
        globalbase_call("GuildMgr", "Recharge", avatar.base_mbstr, 
                                                avatar.dbid, 
                                                avatar.name, 
                                                avatar.gold, 
                                                avatar.level, 
                                                type, 
                                                charge)
    elseif type == guild_config.GUILD_RECHARGE_TYPE_DIAMOND then
        if avatar.diamond < charge then
            avatar.client.GuildResp(action_config.MSG_RECHARGE, guild_config.ERROR_RECHARGE_NOT_ENOUGH_DIAMOND, {})
            return 0
        end
        globalbase_call("GuildMgr", "Recharge", avatar.base_mbstr, 
                                                avatar.dbid, 
                                                avatar.name, 
                                                avatar.diamond, 
                                                avatar.level, 
                                                type, 
                                                charge)
    else
        log_game_error("GuildSystem:Recharge", "dbid=%q;name=%s;type=%d;charge=%d", avatar.dbid, avatar.name, type, charge)
    end

    return 0
end

function GuildSystem:RechargeResp(avatar, Type, RealCost, Exp)
    log_game_debug("GuildSystem:Recharge", "dbid=%q;name=%s;Type=%d;RealCost=%d;Exp=%s", 
                                            avatar.dbid, avatar.name, Type, RealCost, Exp)

    local RealExp = tonumber(Exp)
    if Type == guild_config.GUILD_RECHARGE_TYPE_GOLD then
        avatar:AddGold(-RealCost, reason_def.guild_recharge)
    elseif Type == guild_config.GUILD_RECHARGE_TYPE_DIAMOND then
        avatar:AddDiamond(-RealCost, reason_def.guild_recharge)
    end

    avatar:AddExp(RealExp, reason_def.guild_recharge)

    return 0
end

function GuildSystem:GetDragon(avatar)
    log_game_debug("GuildSystem:GetDragon", "dbid=%q;name=%s", avatar.dbid, avatar.name)

    globalbase_call("GuildMgr", "GetDragon", avatar.base_mbstr, avatar.dbid, avatar.name, avatar.level)
    return 0
end

function GuildSystem:GetDragonResp(avatar, DiamondReward, GoldReward)
    log_game_debug("GuildSystem:GetDragonResp", "dbid=%q;name=%s;DiamondReward=%d;GoldReward=%d", 
                                            avatar.dbid, avatar.name, DiamondReward, GoldReward)

    avatar:AddGold(GoldReward, reason_def.guild_get_dragon)
    avatar:AddDiamond(DiamondReward, reason_def.guild_get_dragon)
    return 0
end

function GuildSystem:UpgradeGuildSkill(avatar, SkillType)
    log_game_debug("GuildSystem:UpgradeGuildSkill", "dbid=%q;name=%s;SkillType=%d", avatar.dbid, avatar.name, SkillType)

    if SkillType ~= guild_config.GUILD_SKILL_TYPE_ATTACK and SkillType ~= guild_config.GUILD_SKILL_TYPE_DEFENSE and SkillType ~= guild_config.GUILD_SKILL_TYPE_HP then
        avatar.client.GuildResp(action_config.MSG_UPGRADE_GUILD_SKILL, guild_config.ERROR_UPGRADE_GUILD_SKILL_NO_SUCH_TYPE, {})
        return 0
    end

    globalbase_call("GuildMgr", "UpgradeGuildSkill", avatar.base_mbstr, avatar.dbid, avatar.name, SkillType)
    return 0
end

function GuildSystem:UpgradeGuildSkillResp(avatar)
    log_game_debug("GuildSystem:UpgradeGuildSkillResp", "dbid=%q;name=%s", avatar.dbid, avatar.name)

    --重新计算二级属性，主要是加上公会技能的影响
    avatar:ProcessBaseProperties()
    return 0
end

function GuildSystem:GetRecommedList(avatar)
    globalbase_call("GuildMgr", "GetRecommedList", avatar.base_mbstr, avatar.dbid)
    return 0
end

function GuildSystem:GetDragonInfo(avatar)
    globalbase_call("GuildMgr", "GetDragonInfo", avatar.base_mbstr, avatar.dbid)
    return 0
end

gGuildSystem = GuildSystem
return gGuildSystem
