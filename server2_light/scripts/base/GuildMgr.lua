
require "lua_util"
require "guild_config"
require "OfflineDataType"
require "message_code"
require "guild_data"
require "GlobalParams"
require "public_config"
require "action_config"
require "channel_config"
require "error_code"

local log_game_debug = lua_util.log_game_debug
local log_game_warning = lua_util.log_game_warning
local log_game_info = lua_util.log_game_info
local log_game_error = lua_util.log_game_error
local globalbase_call = lua_util.globalbase_call

local TIMER_ID_SAVE  = 1        --5分钟存盘定时器的ID
local TIMER_ID_CLEAR = 2        --5分钟清理冻结状态公会定时器的ID
local TIMER_ID_ZERO  = 3        --0点定时器，每天0点计算哪些公会该进入冻结状态

GuildMgr = {}

setmetatable( GuildMgr, {__index = BaseEntity} )

function GuildMgr:__ctor__()

    log_game_debug("GuildMgr:__ctor__", "")

    local function RegisterGloballyCB(ret)
        log_game_debug("RegisterGloballyCB", "")
        if 1 == ret then
             --注册成功
             self:OnRegistered()
        else
            --注册失败
            log_game_error("GuildMgr:RegisterGlobally error", '')
        end
    end

    self:RegisterGlobally("GuildMgr", RegisterGloballyCB)
end

function GuildMgr:OnRegistered()

    self.guilds = {}

    self.guildDbids = {}

    self.DirtyGuildIds = {}

    self.guildMessages = {}

    log_game_debug("GuildMgr:OnRegistered", "")

    self:addTimer(5*60, 5*60, TIMER_ID_SAVE)
    self:addTimer(5*60 + 5*60, 5*60, TIMER_ID_CLEAR)
    self:addTimer(lua_util.get_left_secs_until_next_hhmiss(0, 0, 0) + math.random(0, 10), 24*60*60, TIMER_ID_ZERO)

    --在本进程内加载所有公会实体
    mogo.loadEntitiesOfType("Guild")

--    self:TableSelectSql("onGuildSelectCountResp", "Guild", "SELECT COUNT(*) AS `id` FROM `tbl_Guild`")

--    globalbase_call('GameMgr', 'OnMgrLoaded', 'GuildMgr')
end

function GuildMgr:OnAllGuildsLoaded()
    log_game_info("GuildMgr:OnAllGuildsLoaded", "")
end

function GuildMgr:OnGuildsLoaded(count)
    --记录所有公会的总数量
    log_game_info("GuildMgr:OnGuildsLoaded", "count=%d", count)
    self.AllGuildsCount = count

    if self.AllLoadedGuildsCount == self.AllGuildsCount then

--    for dbid, info in pairs(rst) do
--        self.guilds[dbid] = info
--        table.insert(guildDbids, dbid)

        globalbase_call('GameMgr', 'OnMgrLoaded', 'GuildMgr')
    end
end

function GuildMgr:RegisterToGuild(guild)
    local LoadedCount = self.AllLoadedGuildsCount + 1
    self.AllLoadedGuildsCount = LoadedCount

    local guildDbid = guild:getDbid()
    self.guilds[guildDbid] = guild

    self.guildNames[guild.name] = 1

    for _, PlayerDbid in pairs(guild.members) do
        self.PlayerDbid2GuildDbid[PlayerDbid] = guildDbid
    end

    if self.AllLoadedGuildsCount == self.AllGuildsCount then
        globalbase_call('GameMgr', 'OnMgrLoaded', 'GuildMgr')
    end
end

function GuildMgr:onTimer(timer_id, user_data)
    if user_data == TIMER_ID_SAVE then
--        log_game_debug("GuildMgr:onTimer", "save db")
        self:SaveDirtyGuilds()
    elseif user_data == TIMER_ID_CLEAR then
--        log_game_debug("GuildMgr:onTimer", "clear deleted guilds")
        self:ClearDeletedGuilds()
    elseif user_data == TIMER_ID_ZERO then
         log_game_debug("GuildMgr:onTimer", "zero point")
        self:ProcessFreezeGuilds()
    end
end

--每天0点处理哪些公会应该被冻结
--公会创建7天以后，如果连续2天日登陆少于5人时，将进入冻结状态。
function GuildMgr:ProcessFreezeGuilds()
    local now = os.time()
    for guildId, guild in pairs(self.guilds) do
        if now- guild.buildtime >= g_GlobalParamsMgr:GetParams('start_process_freeze_time', 7 * 24 * 3600) then
            local i = 0
            for _, onlinetime in pairs(guild.members_online_time) do
                if now - onlinetime <= g_GlobalParamsMgr:GetParams('process_freeze_time', 2 * 24 * 3600) then
                    i = i + 1
                end
            end
            if i < g_GlobalParamsMgr:GetParams('start_freeze_member_count', 5) then
                guild.status = guild_config.GUILD_STATUS_FREEZE
                guild.timestamp = now
                self.DirtyGuildIds[guildId] = true
            end
        end

        --每天0点清理龙晶值
        guild.dragon_clear_time = now
        guild.player_recharge_times = {}
        guild.player_recharge_number_of_times = {}
        guild.player_get_dragon_times = {}
        self.DirtyGuildIds[guildId] = true

        log_game_debug("GuildMgr:ProcessFreezeGuilds", "zero point guildId=%d", guildId)
    end
end

function GuildMgr:ClearTimeOutMessage()
--        local Messages = self.guildMessages[info.guildId] or {}
--        table.insert(Messages, {dbid, info.type, info.extend, info.timestamp,})

    for guildId, Messages in pairs(self.guildMessages) do
        if Messages and Messages ~= {} then
            for i, Message in pairs(Messages) do
                if Message[4] >= 72 * 3600 then
                    local sql = string.format("'DELETE FROM `tbl_GuildMessage` WHERE `id`=%d", Message[1])

                    local function ExcCallBack(ret)
                        if ret ~= 0 then
                            log_game_error("GuildMgr:ClearTimeOutMessage", "ret = %d", ret)
                        else
                            self.guildMessages[guildId][i] = nil
                            log_game_debug("GuildMgr:ClearTimeOutMessage", "Message=%s;sql=%s", mogo.cPickle(Message), sql)
                        end
                    end

                    log_game_debug("GuildMgr:ClearTimeOutMessage", "Message=%s;sql=%s", mogo.cPickle(Message), sql)

                    self:TableExcuteSql(sql, ExcCallBack)

                end
            end
        end
    end
end

function GuildMgr:ClearDeletedGuilds()
    for guildId, guild in pairs(self.guilds) do
        if guild.status == guild_config.GUILD_STATUS_FREEZE and guild.timestamp + 72 * 3600 <= os.time() then

            local function ExcCallBack(ret)
                if ret ~= 0 then
                    log_game_error("GuildMgr:ClearDeletedGuilds", "ret = %d", ret)
                else
                    for _, playerDbid in pairs(guild.members) do
                        self.PlayerDbid2GuildDbid[playerDbid] = nil
                        globalbase_call("UserMgr", "UpdatePlayerGuildDbid", playerDbid, 0)
                    end
                    self.guilds[guildId] = nil
                    log_game_debug("GuildMgr:ClearDeletedGuilds", "guildId=%d;guild=%s", guildId, mogo.cPickle(guild))
                end
            end

--            local sql = 'DELETE FROM tbl_Guild WHERE id=' .. guildId
            local sql = string.format("'DELETE FROM `tbl_Guild` WHERE `id`=%d", guildId)

            self:TableExcuteSql(sql, ExcCallBack)

            local function ExcCallBack1(ret)
                if ret ~= 0 then
                    log_game_error("GuildMgr:ClearDeletedGuildMessages", "ret = %d", ret)
                else
                    self.guildMessages[guildId] = nil
                    log_game_debug("GuildMgr:ClearDeletedGuildMessages", "guildId=%d;guild=%s", guildId, mogo.cPickle(guild))
                end
            end

            local sql1 = 'DELETE FROM `tbl_GuildMessage` WHERE `guildId`=' .. guildId

            self:TableExcuteSql(sql1, ExcCallBack1)

            log_game_debug("GuildMgr:ClearDeletedGuilds", "sql=%s;sql1=%s", sql, sql1)

        end
    end
end

function GuildMgr:SaveDirtyGuilds()

    for guildId, _ in pairs(self.DirtyGuildIds) do
        local guild = self.guilds[guildId]
        if guild then

            local function ExcCallBack(ret)
                if ret ~= 0 then
                    log_game_error("GuildMgr:SaveDirtyGuilds", "ret = %d", ret)
                else
                    log_game_debug("GuildMgr:SaveDirtyGuilds", "guild=%s", mogo.cPickle(guild))
                end
            end

--    local sql = "INSERT INTO tbl_Guild(sm_name, sm_level, sm_members, sm_contribute, sm_announcement, sm_money) VALUES( \"" 
--        .. GuildName .. "\", " .. 1
--        ..", \"" .. mogo.cPickle({[guild_config.GUILD_POST_PRESIDENT] = PlayerDbid}) .. "\", \"" .. mogo.cPickle({[PlayerDbid] = 0}) .. "\", \"\", " .. 0 .. " ) "

--            local sql = 'UPDATE tbl_Guild SET sm_name=' .. guild.name .. 
--                                           ', sm_level=' .. guild.level .. 
--                                           ', sm_members=' .. mogo.cPickle(guild.members) .. 
--                                           ', sm_announcement=' .. guild.announcement .. 
--                                           ', sm_money=' .. guild.money .. 
--                                           ', sm_timestamp=' .. guild.timestamp .. 
--                                           ' WHERE id=' .. guild

            local sql = string.format("UPDATE `tbl_Guild` SET `sm_name`='%s', `sm_level`=%d, `sm_members`='%s', `sm_announcement`='%s', `sm_money`=%d, `sm_timestamp`=%d, `sm_members_online_time`='%s', `sm_status`=%d, `sm_dragon_value`=%d, `sm_dragon_clear_time`=%d, `sm_player_recharge_times`='%s', `sm_player_recharge_number_of_times`='%s', `sm_player_get_dragon_times`='%s', `sm_skill`='%s', `sm_builder_dbid`=%d, `sm_president_dbid`=%d, `sm_vice_president1_dbid`=%d, `sm_vice_president2_dbid`=%d, `sm_vice_president3_dbid`=%d WHERE `id`=%d", 
                                       guild.name, 
                                       guild.level, 
                                       mogo.cPickle(guild.members), 
                                       guild.announcement, 
                                       guild.money, 
                                       guild.timestamp, 
                                       mogo.cPickle(guild.members_online_time), 
                                       guild.status, 
                                       guild.dragon_value,
                                       guild.dragon_clear_time,
                                       mogo.cPickle(guild.player_recharge_times), 
                                       mogo.cPickle(guild.player_recharge_number_of_times), 
                                       mogo.cPickle(guild.player_get_dragon_times), 
                                       mogo.cPickle(guild.skill), 
                                       guild.builder_dbid, 
                                       guild.president_dbid, 
                                       guild.vice_president1_dbid, 
                                       guild.vice_president2_dbid, 
                                       guild.vice_president3_dbid, 
                                       guildId)

            self:TableExcuteSql(sql,ExcCallBack)
        end
    end

    self.DirtyGuildIds = {}

end

function GuildMgr:Init()
    log_game_debug("GuildMgr:Init", "self.guilds=%s", mogo.cPickle(self.guilds))

    --开始加载玩家的信息

    local flag = true

    for guildDbid, info in pairs(self.guilds) do
        for position, playerDbid in pairs(info.members) do
            flag = false
            globalbase_call('UserMgr', 'GuildQueryInfoByPlayerDbids', guildDbid,    --公会dbid
                                                                 mogo.pickleMailbox(self), {playerDbid,},
                                                                {public_config.USER_MGR_PLAYER_DBID_INDEX,
                                                                 public_config.USER_MGR_PLAYER_NAME_INDEX,
                                                                 public_config.USER_MGR_PLAYER_LEVEL_INDEX,
                                                                 public_config.USER_MGR_PLAYER_FIGHT_INDEX,
                                                                 public_config.USER_MGR_PLAYER_OFFLINETIME_INDEX,})
            self.PlayerInfo[playerDbid] = {}
        end
    end

    if flag then
        globalbase_call('GameMgr', 'OnInited', 'GuildMgr')
    end
end

function GuildMgr:QueryInfoByPlayerDbidResp(guildDbid, PlayerDbid, PlayerInfo)
    log_game_debug('UserMgr:QueryInfoByPlayerDbidResp', 'guilddbid=%q;Playerdbid=%q;PlayerInfo=%s', 
                                                         guildDbid, PlayerDbid, mogo.cPickle(PlayerInfo))

    for _, info in pairs(PlayerInfo) do
        self.PlayerInfo[info[public_config.USER_MGR_PLAYER_DBID_INDEX]] = {
                                                                           '',
                                                                           info[public_config.USER_MGR_PLAYER_NAME_INDEX],
                                                                           info[public_config.USER_MGR_PLAYER_LEVEL_INDEX],
                                                                           info[public_config.USER_MGR_PLAYER_FIGHT_INDEX],
--                                                                           guildDbid,    --玩家的公会dbid
                                                                          }

        local guild = self.guilds[guildDbid]
        if guild then
            guild.members_online_time[guildDbid] = info[public_config.USER_MGR_PLAYER_OFFLINETIME_INDEX]
        end

    end

    local flag = true
    for _, info in pairs(self.PlayerInfo) do
        if info == {} then
            flag = false
        end
    end

    --所有参与了公会的玩家数据都加载回来了再通知游戏管理器启动完毕
    if flag then
        log_game_debug('UserMgr:QueryInfoByPlayerDbidResp', 'PlayerInfo=%s', mogo.cPickle(self.PlayerInfo))
        globalbase_call('GameMgr', 'OnInited', 'GuildMgr')
    end
end

function GuildMgr:GetGuildsCount(MbStr)
    local mb = mogo.UnpickleBaseMailbox(MbStr)
    if mb then
        local i = 0
        for _, guild in pairs(self.guilds) do
            if guild.status == guild_config.GUILD_STATUS_NORMAL then
                i = i + 1
            end
        end
        mb.client.GuildResp(action_config.MSG_GET_GUILDS_COUNT, 0, {i})
    end
end

--分页获取公会的信息
function GuildMgr:GetGuilds(MbStr, StartIndex, Count)
    log_game_debug("GuildMgr:GetGuilds", "MbStr=%s;StartIndex=%d;Count=%d", MbStr, StartIndex, Count)
    local mb = mogo.UnpickleBaseMailbox(MbStr)
    if mb then
        local result = {}
        for i=StartIndex, StartIndex + Count, 1 do
            local guildDbid = self.guildDbids[i]

            if not guildDbid then
                break
            end

            local info = self.guilds[guildDbid]

            if info and info.status == guild_config.GUILD_STATUS_NORMAL then
                local MemberCount = lua_util.get_table_real_count(info.members)
                table.insert(result, {guildDbid, info.name, info.level, MemberCount})
            end
        end

        --所有公会的总数量
        local i = 0
        for _, guild in pairs(self.guilds) do
            if guild.status == guild_config.GUILD_STATUS_NORMAL then
                i = i + 1
            end
        end

        mb.client.GuildResp(action_config.MSG_GET_GUILDS, 0, {i, result})
    end
end

function GuildMgr:CreateGuild(MbStr, GuildName, PlayerDbid, PlayerName, PlayerLevel, PlayerFight)
    log_game_debug("GuildMgr:CreateGuild", "MbStr=%s;GuildName=%s;Playerdbid=%q;PlayerName=%s;PlayerLevel=%d;PlayerFight=%d",
                                            MbStr, GuildName, PlayerDbid, PlayerName, PlayerLevel, PlayerFight)

    if self.guildNames[GuildName] then
        --公会名字已经被占用
        local mb = mogo.UnpickleBaseMailbox(MbStr)
        if mb then
            mb.client.GuildResp(action_config.MSG_CREATE_GUILD, guild_config.ERROR_CREATE_GUILD_NAME_ALREADY_USED, {})
        end
        return
    end

    if self.PlayerDbid2GuildDbid[PlayerDbid] then
        --找到玩家所属的公会信
        local mb = mogo.UnpickleBaseMailbox(MbStr)
        if mb then
            mb.client.GuildResp(action_config.MSG_CREATE_GUILD, guild_config.ERROR_CREATE_GUILD_ALREADY_IN_GUILD, {})
        end
        return
    end

    --先占着该名字，防止在公会存盘成功前该名字被重复使用
    self.guildNames[GuildName] = 1
    local guild = mogo.createBase('Guild')

    guild:OnCreated(MbStr, GuildName, PlayerDbid, PlayerName, PlayerLevel, PlayerFight)



--    local now = os.time()
--
--    --创建公会
--    --INSERT INTO `tbl_Guild`(`sm_name`, `sm_level`,`sm_members`, `sm_contribute`, `sm_announcement`, `sm_money`, `sm_buildtime`, `sm_timestamp`, `sm_members_online_time`, `sm_status`, `sm_dragon_value`, `sm_dragon_clear_time`, `sm_player_recharge_times`, `sm_player_recharge_number_of_times`, `sm_player_get_dragon_times`, `sm_skill`) VALUES( 'MaiFeo', 1, '{1=23}', '{23=0}', '', 0, 1377695309, 0, '{23=1377695309}', 0, 0, 1377695309, '{}', '{}', '{}', '{}')
--    local sql = string.format("INSERT INTO `tbl_Guild`(`sm_name`, `sm_level`, `sm_members`, `sm_contribute`, `sm_announcement`, `sm_money`, `sm_buildtime`, `sm_timestamp`, `sm_members_online_time`, `sm_status`, `sm_dragon_value`, `sm_dragon_clear_time`, `sm_player_recharge_times`, `sm_player_recharge_number_of_times`, `sm_player_get_dragon_times`, `sm_skill`, `sm_builder_dbid`, `sm_president_dbid`, `sm_vice_president1_dbid`, `sm_vice_president2_dbid`, `sm_vice_president3_dbid`) VALUES ( '%s', %d, '%s', '%s', '%s', %d, %d, %d, '%s', %d, %d, %d, '%s', '%s', '%s', '%s', %d, %d, %d, %d, %d)",
--                               GuildName,
--                               1,
--                               mogo.cPickle({[guild_config.GUILD_POST_PRESIDENT] = PlayerDbid}),
--                               mogo.cPickle({[PlayerDbid] = 0}),
--                               '""',
--                               0,
--                               now,
--                               0,
--                               mogo.cPickle({[PlayerDbid] = now}),
--                               guild_config.GUILD_STATUS_NORMAL,
--                               0,
--                               now,
--                               mogo.cPickle({}),
--                               mogo.cPickle({}),
--                               mogo.cPickle({}),
--                               mogo.cPickle({}),
--                               PlayerDbid,
--                               PlayerDbid,
--                               0,
--                               0,
--                               0)
--
--
----    local sql = "INSERT INTO tbl_Guild(sm_name, sm_level, sm_members, sm_contribute, sm_announcement, sm_money, sm_timestamp) VALUES( \""
----        .. GuildName .. "\", " .. 1
----        ..", \"" .. mogo.cPickle({[guild_config.GUILD_POST_PRESIDENT] = PlayerDbid}) .. "\", \"" .. mogo.cPickle({[PlayerDbid] = 0}) .. "\", \"\", " .. 0 .. "\", \"\", " .. 0 .. " ) "
--
--    log_game_debug("GuildMgr:CreateGuild", "sql=%s", sql)
--
--    local function OnCreateGuild(guildId)
--        if 0 == guildId then
--            log_game_error("GuildMgr:CreateGuild", "SaveCB failed.")
--            return
--        end
--
--        log_game_debug("GuildMgr:CreateGuild", "guildId=%d", guildId)
--
--        self.PlayerInfo[PlayerDbid] = {MbStr, PlayerName, PlayerLevel, PlayerFight,}
--
--        self.guilds[guildId] = {
--                                ['name'] = GuildName,
--                                ['level'] = 1,
--                                ['members'] = {[guild_config.GUILD_POST_PRESIDENT] = PlayerDbid},
--                                ['contribute'] = {[PlayerDbid] = 0},
--                                ['announcement'] = '',
--                                ['money'] = 0,
--                                ['buildtime'] = now,
--                                ['timestamp'] = 0,
--                                ['members_online_time'] = {[PlayerDbid] = now},
--                                ['status'] = guild_config.GUILD_STATUS_NORMAL,
--                                ['dragon_value'] = 0,
--                                ['dragon_clear_time'] = now,
--                                ['player_recharge_times'] = {},
--                                ['player_recharge_number_of_times'] = {},
--                                ['player_get_dragon_times'] = {},
--                                ['skill'] = {},
--                                ['builder_dbid'] = PlayerDbid,
--                                ['president_dbid'] = PlayerDbid,
--                                ['vice_president1_dbid'] = 0,
--                                ['vice_president2_dbid'] = 0,
--                                ['vice_president3_dbid'] = 0,
--                                }
--
----        --设置玩家的公会dbid
----        table.insert(self.PlayerInfo[PlayerDbid], guildId)
--
--        table.insert(self.guildDbids, guildId)
--
--        self.PlayerDbid2GuildDbid[PlayerDbid] = guildId
--        globalbase_call("UserMgr", "UpdatePlayerGuildDbid", PlayerDbid, guildId)
--
--        local mb = mogo.UnpickleBaseMailbox(MbStr)
--        if mb then
--            mb.GuildB2BReq(action_config.MSG_SET_GUILD_ID, 0, 0, mogo.cPickle({guildId, GuildName, guild_config.GUILD_POST_PRESIDENT,}))
--            mb.GuildB2BReq(action_config.MSG_SUBMIT_CREATE_GUILD_COST, 0, 0, '')
--
--            --通知客户端成功建立公会
--            mb.client.GuildResp(action_config.MSG_CREATE_GUILD, 0, {GuildName, 1, guild_config.GUILD_POST_PRESIDENT,})
--        end
--	end
--
--    self:TableInsertSql(sql, OnCreateGuild)
end

--注册注册玩家的mb等信息
function GuildMgr:Register(dbid, MbStr, name, PlayerLevel, PlayerFight)
    log_game_debug("GuildMgr:Register", "dbid=%q;MbStr=%s;name=%s;PlayerLevel=%d;PlayerFight=%d",
                                         dbid, MbStr, name, PlayerLevel, PlayerFight)

    local now = os.time()

    self.PlayerInfo[dbid] = {MbStr, name, PlayerLevel, PlayerFight, now,}

    local guildDbid = self.PlayerDbid2GuildDbid[dbid]
    if guildDbid then
        --找到玩家所属的公会信息
        local guild = self.guilds[guildDbid]
        if guild then
            for position, playerDbid in pairs(guild.members) do
                if playerDbid == dbid then
                    local mb = mogo.UnpickleBaseMailbox(MbStr)
                    if mb then
                        mb.GuildB2BReq(action_config.MSG_SET_GUILD_ID, 0, 0, mogo.cPickle({
                                                                                        [guild_config.GUILD_INFO_DBID] = guildDbid, 
                                                                                        [guild_config.GUILD_INFO_NAME] = guild.name, 
                                                                                        [guild_config.GUILD_INFO_POST] = position,
                                                                                       }))

                    --刷新玩家的登录时间
                    guild.members_online_time[dbid] = now

                    self.PlayerDbid2GuildDbid[dbid] = guildDbid
                    globalbase_call("UserMgr", "UpdatePlayerGuildDbid", dbid, guildDbid)

                    --如果日登陆超过8人，则冻结状态取消。
                    if guild.status == guild_config.GUILD_STATUS_FREEZE then
                        local i = 0
                        for _, onlinetime in pairs(guild.members_online_time) do
                            if now - onlinetime <= 24 * 3600 then
                                i = i + 1
                            end
                        end

                        if i >= g_GlobalParamsMgr:GetParams('clear_freeze_member_count', 8) then
                            guild.status = guild_config.GUILD_STATUS_NORMAL
                            guild.timestamp = 0
                        end
                    end

                    self.DirtyGuildIds[guildDbid] = true

                    end
                    return
                end
            end
        end
    end

end

function GuildMgr:DisRegister(dbid)
    --玩家下线时，注销掉mb
    if self.PlayerInfo[dbid] then
        self.PlayerInfo[dbid][1] = ''
    end
end

function GuildMgr:SetGuildAnnouncement(MbStr, PlayerDbid, announcement)

    local mb = mogo.UnpickleBaseMailbox(MbStr)

    if not self.PlayerInfo[PlayerDbid] or not self.PlayerDbid2GuildDbid[PlayerDbid] then
        --玩家没有公会
        if mb then
            mb.client.GuildResp(action_config.MSG_SET_GUILD_ANNOUNCEMENT, guild_config.ERROR_SET_ANNOUNCEMENT_NO_GUILD, {})
        end
        return
    end

    local GuildId = self:PresidentGetGuildId(PlayerDbid)

    if GuildId then
        --找到了对应玩家是公会长的公会
        local info = self.guilds[GuildId]

        if not info then
            if mb then
                mb.client.GuildResp(action_config.MSG_SET_GUILD_ANNOUNCEMENT, guild_config.ERROR_SET_ANNOUNCEMENT_NO_GUILD, {})
            end
        end

        self.guilds[GuildId].announcement = announcement
        if mb then
            mb.client.GuildResp(action_config.MSG_SET_GUILD_ANNOUNCEMENT, 0, {})
        end

        self.DirtyGuildIds[GuildId] = true

        --UPDATE数据库
        return
    end

    if mb then
        --找不到对应的公会或者玩家不是公会长
        mb.client.GuildResp(action_config.MSG_SET_GUILD_ANNOUNCEMENT, guild_config.ERROR_SET_ANNOUNCEMENT_NO_RIGHT, {})
    end
end

function GuildMgr:GetGuildAnnouncement(MbStr, PlayerDbid)

    local mb = mogo.UnpickleBaseMailbox(MbStr)

    if not self.PlayerInfo[PlayerDbid] or not self.PlayerDbid2GuildDbid[PlayerDbid] then
        --玩家没有公会
        if mb then
            mb.client.GuildResp(action_config.MSG_GET_GUILD_ANNOUNCEMENT, guild_config.ERROR_GET_ANNOUNCEMENT_NO_GUILD, {})
        end
        return
    end

    local info = self.guilds[self.PlayerDbid2GuildDbid[PlayerDbid]]
    if info then
        if mb then
            mb.client.GuildResp(action_config.MSG_GET_GUILD_ANNOUNCEMENT, 0, {info.announcement})
        end
    else
        if mb then
            --找不到对应的公会
            mb.client.GuildResp(action_config.MSG_GET_GUILD_ANNOUNCEMENT, guild_config.ERROR_GET_ANNOUNCEMENT_NO_GUILD, {})
        end
    end

end

function GuildMgr:GetGuildDetailedInfo(MbStr, PlayerDbid)
    log_game_debug("GuildMgr:GetGuildDetailedInfo", "MbStr=%s;Playerdbid=%q", MbStr, PlayerDbid)

    local mb = mogo.UnpickleBaseMailbox(MbStr)

    if not self.PlayerInfo[PlayerDbid] or not self.PlayerDbid2GuildDbid[PlayerDbid] then
        --玩家没有公会
        if mb then
            mb.client.GuildResp(action_config.MSG_GET_GUILD_DETAILED_INFO, guild_config.ERROR_GET_GUILD_DETAILED_INFO_NO_GUILD, {})
        end
        return
    end

    local guildId = self.PlayerDbid2GuildDbid[PlayerDbid]
    local info = self.guilds[guildId]
    if info then
        if mb then
            local result = {
                             info.announcement,                                                --公会公告
                             info.money,                                                       --公会资金
                             info.level,                                                       --公会等级
                             lua_util.get_table_real_count(info.members),                      --公会人数
                             self:GetPositionName(guildId, guild_config.GUILD_POST_PRESIDENT), --公会长名字
                             info.dragon_value,                                                --公会的龙晶值
                             {
                             [guild_config.GUILD_SKILL_TYPE_ATTACK] = info.skill[guild_config.GUILD_SKILL_TYPE_ATTACK] or 0, 
                             [guild_config.GUILD_SKILL_TYPE_DEFENSE] = info.skill[guild_config.GUILD_SKILL_TYPE_DEFENSE] or 0, 
                             [guild_config.GUILD_SKILL_TYPE_HP] = info.skill[guild_config.GUILD_SKILL_TYPE_HP] or 0, 
                             },                                                                --公会技能
                            }
            log_game_debug("GuildMgr:GetGuildDetailedInfo", "MbStr=%s;Playerdbid=%q;result=%s", MbStr, PlayerDbid, mogo.cPickle(result))
            mb.client.GuildResp(action_config.MSG_GET_GUILD_DETAILED_INFO, 0, result)
        end
    else
        if mb then
            --找不到对应的公会
            mb.client.GuildResp(action_config.MSG_GET_GUILD_DETAILED_INFO, guild_config.ERROR_GET_GUILD_DETAILED_INFO_NO_GUILD, {})
        end
    end

end

function GuildMgr:ApplyToJoin(MbStr, PlayerDbid, PlayerName, PlyaerVocation, guildDbid, PlayerLevel, PlayerFight)

    log_game_debug("GuildMgr:ApplyToJoin", "MbStr=%s;Playerdbid=%q;PlayerName=%s;PlyaerVocation=%d;guilddbid=%q;PlayerLevel=%d;PlayerFight=%d", 
                                            MbStr, PlayerDbid, PlayerName, PlyaerVocation, guildDbid, PlayerLevel, PlayerFight)

    local mb = mogo.UnpickleBaseMailbox(MbStr)

    if not self.PlayerInfo[PlayerDbid] and self.PlayerDbid2GuildDbid[PlayerDbid] --[[and self.PlayerDbid2GuildDbid[PlayerDbid] > 0]] then
        --玩家已经有公会，不能再申请加入
        if mb then
            mb.client.GuildResp(action_config.MSG_APPLY_TO_JOIN, guild_config.ERROR_APPLY_TO_JOIN_ALREADY_IN_GUILD, {})
        end
        return
    end

    local guild = self.guilds[guildDbid]

    if not guild then
        --工会不存在
        if mb then
            mb.client.GuildResp(action_config.MSG_APPLY_TO_JOIN, guild_config.ERROR_APPLY_TO_JOIN_GUILD_NOT_EXIT, {})
        end
        return
    end

    --table.insert(Messages, 1, {guildMessageId, guild_config.GUILD_MESSAGE_TYPE_JOIN_IN, {PlayerDbid, PlayerName, PlyaerVocation, PlayerLevel, PlayerFight,}, now})
    local Messages = self.guildMessages[guildDbid] or {}
    for _, info in pairs(Messages) do
        if info[2] == guild_config.GUILD_MESSAGE_TYPE_JOIN_IN and info[3][1] == PlayerDbid then
            if mb then
                mb.client.GuildResp(action_config.MSG_APPLY_TO_JOIN, guild_config.ERROR_APPLY_TO_JOIN_ALREADY_APPLY, {})
            end
            return
        end
    end

    if lua_util.get_table_real_count(guild.members) >= gGuildDataMgr:getMemberCountByLevel(guild.level) then
        --公会人数超过最大值
        if mb then
            mb.client.GuildResp(action_config.MSG_APPLY_TO_JOIN, guild_config.ERROR_APPLY_TO_JOIN_TOO_MUCH_MEMBERS, {})
        end
        return
    end

    if guild.status == guild_config.GUILD_STATUS_FREEZE then
        --处于冻结状态得的公会不能申请加入
        if mb then
            mb.client.GuildResp(action_config.MSG_APPLY_TO_JOIN, guild_config.ERROR_APPLY_TO_JOIN_STATUS_FREEZE, {})
        end
        return
    end

----测试用代码------------------
--
--    local i = self:GetIdleNormalPoistion(guildDbid)
--    guild.members[i] = PlayerDbid
--
--    self.DirtyGuildIds[guildDbid] = true
--
--    self.PlayerDbid2GuildDbid[PlayerDbid] = guildDbid
--
--    --通知申请人已经成功加入公会
--    if mb then
--        
--        mb.client.GuildResp(guild_config.MSG_APPLY_TO_JOIN_RESULT, 0, {guild_config.GUILD_ANSWER_APPLY_JOIN_IN_YES, guild.name,})
--        return
--    end
--
----测试用代码------------------

    local now = os.time()

    --创建申请信息
--    local sql = "INSERT INTO tbl_GuildMessage(sm_guildId, sm_type, sm_extend, sm_timestamp) VALUES( \"" 
--        .. guildDbid .. "\", " .. guild_config.GUILD_MESSAGE_TYPE_JOIN_IN
--        ..", \"" .. mogo.cPickle({PlayerDbid, PlayerName,}) .. "\", " .. now .. " ) "

    local sql = string.format("INSERT INTO `tbl_GuildMessage`(`sm_guildId`, `sm_type`, `sm_extend`, `sm_timestamp`) VALUES( %d, %d, '%s', %d )", 
                               guildDbid, 
                               guild_config.GUILD_MESSAGE_TYPE_JOIN_IN, 
                               mogo.cPickle({PlayerDbid, PlayerName, PlyaerVocation, PlayerLevel, PlayerFight,}), 
                               now )

    log_game_debug("GuildMgr:CreateGuildMessage", "sql=%s", sql)

    local function OnCreateGuildMessage(guildMessageId)
        if 0 == guildMessageId then
            log_game_error("GuildMgr:OnCreateGuildMessage", "SaveCB failed.")
            return
        end

        log_game_debug("GuildMgr:CreateGuildMessage", "guildMessageId=%d", guildMessageId)

        --新增内存数据
        local Messages = self.guildMessages[guildDbid] or {}
        table.insert(Messages, 1, {guildMessageId, guild_config.GUILD_MESSAGE_TYPE_JOIN_IN, {PlayerDbid, PlayerName, PlyaerVocation, PlayerLevel, PlayerFight,}, now})

--        --按时间戳反序排列
--        table.sort(Messages, function (a, b) return a[4] > b[4] end)

        self.guildMessages[guildDbid] = Messages

        local mb = mogo.UnpickleBaseMailbox(MbStr)
        if mb then
            --通知申请者的客户端成功发出请求
            mb.client.GuildResp(action_config.MSG_APPLY_TO_JOIN, 0, {})
        end

        if not self.PlayerInfo[PlayerDbid] then
            self.PlayerInfo[PlayerDbid] = {MbStr, PlayerName, PlayerLevel, PlayerFight, os.time(),}
        end

--        local members = self.guilds[guildDbid].members
--        local presidentDbid = members[guild_config.GUILD_POST_PRESIDENT]               --公会长
--        local vicepresidentDbid1 = members[guild_config.GUILD_POST_VICE_PRESIDENT1]     --副公会长
--        local vicepresidentDbid2 = members[guild_config.GUILD_POST_VICE_PRESIDENT2]     --副公会长
--        local vicepresidentDbid3 = members[guild_config.GUILD_POST_VICE_PRESIDENT3]     --副公会长

        local guild = self.guilds[guildDbid]
        local presidentDbid = guild.president_dbid
        local vicepresidentDbid1 = guild.vice_president1_dbid
        local vicepresidentDbid2 = guild.vice_president2_dbid
        local vicepresidentDbid3 = guild.vice_president3_dbid

        --通知公会长和副公会长有人申请加入了
        if presidentDbid > 0 then
            local presidentInfo = self.PlayerInfo[presidentDbid]
            if presidentInfo and presidentInfo[1] then
                local mb1 = mogo.UnpickleBaseMailbox(presidentInfo[1])
                if mb1 then
                    log_game_debug("GuildMgr:CreateGuildMessage", "guildMessageId=%d", guildMessageId)
                    mb1.client.GuildResp(action_config.MSG_APPLY_TO_JOIN_NOTIFY, 0, {PlayerName,})
                end
            end
        end

        if vicepresidentDbid1 > 0 then
            local vicepresidentInfo = self.PlayerInfo[vicepresidentDbid1]
            if vicepresidentInfo and vicepresidentInfo[1] then
                local mb2 = mogo.UnpickleBaseMailbox(vicepresidentInfo[1])
                if mb2 then
                    mb2.client.GuildResp(action_config.MSG_APPLY_TO_JOIN_NOTIFY, 0, {PlayerName,})
                end
            end
        end

        if vicepresidentDbid2 > 0 then
            local vicepresidentInfo = self.PlayerInfo[vicepresidentDbid2]
            if vicepresidentInfo and vicepresidentInfo[1] then
                local mb3 = mogo.UnpickleBaseMailbox(vicepresidentInfo[1])
                if mb3 then
                    mb3.client.GuildResp(action_config.MSG_APPLY_TO_JOIN_NOTIFY, 0, {PlayerName,})
                end
            end
        end

        if vicepresidentDbid3 then
            local vicepresidentInfo = self.PlayerInfo[vicepresidentDbid3]
            if vicepresidentInfo and vicepresidentInfo[1] then
                local mb4 = mogo.UnpickleBaseMailbox(vicepresidentInfo[1])
                if mb4 then
                    mb4.client.GuildResp(action_config.MSG_APPLY_TO_JOIN_NOTIFY, 0, {PlayerName,})
                end
            end
        end

    end

    self:TableInsertSql(sql, OnCreateGuildMessage)

end


function GuildMgr:GetGuildMessagesCount(MbStr, PlayerDbid, type)
    local mb = mogo.UnpickleBaseMailbox(MbStr)

    if not self.PlayerInfo[PlayerDbid] or not self.PlayerDbid2GuildDbid[PlayerDbid] then
        --玩家没有公会
        if mb then
            mb.client.GuildResp(action_config.MSG_GET_GUILD_MESSAGES_COUNT, guild_config.ERROR_GET_GUILD_MESSAGE_COUNT_NO_GUILD, {})
        end
        return
    end

    local GuildId = self:PresidentGetGuildId(PlayerDbid)

    if GuildId then

        local Messages = self.guildMessages[GuildId] or {}

--        if not Messages then
--            --该公会没有数据
--            if mb then
--                mb.client.GuildResp(guild_config.MSG_GET_GUILD_MESSAGES_COUNT, 0, {0})
--            end
--        end

--        local count = 0
--        for _, info in pairs(Messages) do
--            --table.insert(Messages, {dbid, info.type, info.extend, info.timestamp,})
--            if info[2] == type then
--                count = count + 1
--            end
--        end

        if mb then
            mb.client.GuildResp(action_config.MSG_GET_GUILD_MESSAGES_COUNT, 0, {lua_util.get_table_real_count(Messages)})
        end
    else
        --玩家没有公会或者权限不足，不可查看公会消息
        if mb then
            mb.client.GuildResp(action_config.MSG_GET_GUILD_MESSAGES_COUNT, guild_config.ERROR_GET_GUILD_MESSAGE_COUNT_NO_RIGHT, {})
        end
    end
end

function GuildMgr:GetGuildMessages(MbStr, PlayerDbid, StartIndex, Count, type)
    log_game_debug("GuildMgr:GetGuildMessages", "MbStr=%s;Playerdbid=%q;StartIndex=%d;Count=%d;type=%d",
                                                 MbStr, PlayerDbid, StartIndex, Count, type)

    local mb = mogo.UnpickleBaseMailbox(MbStr)

    if not self.PlayerInfo[PlayerDbid] or not self.PlayerDbid2GuildDbid[PlayerDbid] then
        --玩家没有公会
        if mb then
            mb.client.GuildResp(action_config.MSG_GET_GUILD_MESSAGES, guild_config.ERROR_GET_GUILD_MESSAGES_NO_GUILD, {})
        end
        return
    end

    local GuildId = self:PresidentGetGuildId(PlayerDbid)

    if GuildId then

        local Messages = self.guildMessages[GuildId]

        if not Messages then
            --公会没有消息
            if mb then
                local ClientResult = {}
                log_game_debug("GuildMgr:GetGuildMessages", "MbStr=%s;Playerdbid=%q;StartIndex=%d;Count=%d;type=%d",
                                                         MbStr, PlayerDbid, StartIndex, Count, type)
                table.insert(ClientResult, 0)
                table.insert(ClientResult, {})
                mb.client.GuildResp(action_config.MSG_GET_GUILD_MESSAGES, 0, ClientResult)
            end
            return
        end

        local result = {}
        local j = 0
        for i=StartIndex, StartIndex + Count, 1 do
            local Message = Messages[i]
            --table.insert(Messages, 1, {guildMessageId, guild_config.GUILD_MESSAGE_TYPE_JOIN_IN, {PlayerDbid, PlayerName, PlyaerVocation, PlayerLevel, PlayerFight,}, now})
            if Message and Message[2] == type then
                j = j + 1
                table.insert(result, {Message[1] or 0, Message[3][2] or '', Message[3][3] or 0, Message[3][4] or 0, Message[3][5] or 0,})
            end
        end

        if mb then
            local ClientResult = {}
            log_game_debug("GuildMgr:GetGuildMessages", "MbStr=%s;Playerdbid=%q;StartIndex=%d;Count=%d;type=%d;j=%d;result=%s",
                                                         MbStr, PlayerDbid, StartIndex, Count, type, j, mogo.cPickle(result))
            table.insert(ClientResult, j)
            table.insert(ClientResult, result)
            mb.client.GuildResp(action_config.MSG_GET_GUILD_MESSAGES, 0, ClientResult)
        end
    else
        --玩家没有公会或者权限不足，不可查看公会消息
        if mb then
            mb.client.GuildResp(action_config.MSG_GET_GUILD_MESSAGES, guild_config.ERROR_GET_GUILD_MESSAGES_NO_RIGHT, {})
        end
    end

end

function GuildMgr:AnswerApply(MbStr, PlayerDbid, opt, MessageId)

    log_game_debug("GuildMgr:AnswerApply", "MbStr=%s;Playerdbid=%q;opt=%d;MessageId=%d",
                                            MbStr, PlayerDbid, opt, MessageId)

    local mb = mogo.UnpickleBaseMailbox(MbStr)

    if not self.PlayerInfo[PlayerDbid] or not self.PlayerDbid2GuildDbid[PlayerDbid]then
        --玩家没有公会
        if mb then
            mb.client.GuildResp(action_config.MSG_ANSWER_APPLY, guild_config.ERROR_ANSWER_APPLY_NO_GUILD, {})
        end
        return
    end

    local GuildId = self:PresidentGetGuildId(PlayerDbid)

    if GuildId then

        local guild = self.guilds[GuildId]
        if lua_util.get_table_real_count(guild.members) >= gGuildDataMgr:getMemberCountByLevel(guild.level) then
            --公会人数超过最大值
            if mb then
                mb.client.GuildResp(action_config.MSG_ANSWER_APPLY, guild_config.ERROR_ANSWER_APPLY_TOO_MUCH_MEMBERS, {})
            end
            return
        end

        if guild.status == guild_config.GUILD_STATUS_FREEZE then
            --处于冻结状态得的公会不能批准新人加入？
            if mb then
                mb.client.GuildResp(action_config.MSG_ANSWER_APPLY, guild_config.ERROR_ANSWER_APPLY_STATUS_FREEZE, {})
            end
            return
        end

        local result = {}
        local Messages = self.guildMessages[GuildId]

        if not Messages then
            --玩家没有公会或者权限不足，不可查看公会消息
            if mb then
                mb.client.GuildResp(action_config.MSG_ANSWER_APPLY, guild_config.ERROR_ANSWER_APPLY_NO_MESSAGE, {})
            end
            return
        end

        if opt == guild_config.GUILD_ANSWER_APPLY_JOIN_IN_YES then
            --同意
            --table.insert(Messages, {dbid, info.type, info.extend, info.timestamp,})

            for j, info in pairs(Messages) do
                if info[1] == MessageId then
                    log_game_debug("GuildMgr:AnswerApply", "MbStr=%s;Playerdbid=%q;opt=%d;MessageId=%d;guild=%s", MbStr, PlayerDbid, opt, MessageId, mogo.cPickle(self.guilds[GuildId]))

                    if mb then
                        mb.client.GuildResp(action_config.MSG_ANSWER_APPLY, 0, {guild_config.GUILD_ANSWER_APPLY_JOIN_IN_YES})
                    end

                    --实现申请人加入到工会的流程
                    local PlayerDbid = info[3][1]

                    for position, playerDbid in pairs(guild.members) do
                        --如果申请人已经在工会了，不处理
                        if playerDbid == PlayerDbid then
                            return
                        end
                    end

                    local i = self:GetIdleNormalPoistion(GuildId)
                    self.guilds[GuildId].members[i] = PlayerDbid

                    local PlayerInfo = self.PlayerInfo[PlayerDbid] or {}
                    self.guilds[GuildId].members_online_time[PlayerDbid] = PlayerInfo[5] or 0
--                    table.insert(guild.members, PlayerDbid)

                    self.DirtyGuildIds[GuildId] = true

                    self.PlayerDbid2GuildDbid[PlayerDbid] = GuildId
                    globalbase_call("UserMgr", "UpdatePlayerGuildDbid", PlayerDbid, GuildId)
 
                    local function ExcCallBack(ret)
                        if ret ~= 0 then
                            log_game_error("GuildMgr:AnswerApply", "ret = %d", ret)
                        else
                            table.remove(self.guildMessages[GuildId], j)

                            if not self.PlayerInfo[PlayerDbid] then
                               --如果当前公会系统没有数据则加载回来
                                globalbase_call('UserMgr', 'GuildQueryInfoByPlayerDbids', GuildId,    --公会dbid
                                                                 mogo.pickleMailbox(self), {PlayerDbid,},
                                                                {public_config.USER_MGR_PLAYER_DBID_INDEX,
                                                                 public_config.USER_MGR_PLAYER_NAME_INDEX,
                                                                 public_config.USER_MGR_PLAYER_LEVEL_INDEX,
                                                                 public_config.USER_MGR_PLAYER_FIGHT_INDEX,})
                                self.PlayerInfo[PlayerDbid] = {}
                            end

                            log_game_debug("GuildMgr:AnswerApply", "GuildId=%d;guild=%s;PlayerInfo=%s",
                                                                    GuildId, mogo.cPickle(guild), mogo.cPickle(self.PlayerInfo[PlayerDbid]))

                            --通知申请人已经成功加入公会
                            if self.PlayerInfo[PlayerDbid] and self.PlayerInfo[PlayerDbid][1] and self.PlayerInfo[PlayerDbid][1] ~= '' then
                                local mb1 = mogo.UnpickleBaseMailbox(self.PlayerInfo[PlayerDbid][1])
                                if mb1 then
                                    mb1.client.GuildResp(action_config.MSG_APPLY_TO_JOIN_RESULT, 0, {guild_config.GUILD_ANSWER_APPLY_JOIN_IN_YES, self.guilds[GuildId].name,})
                                end
                            end
                        end
                    end

                    local sql1 = string.format('DELETE FROM `tbl_GuildMessage` WHERE `id`=%d', MessageId)

                    self:TableExcuteSql(sql1, ExcCallBack)

                    return
                end
            end

            if mb then
                mb.client.GuildResp(action_config.MSG_ANSWER_APPLY, guild_config.ERROR_ANSWER_APPLY_MESSAGE_NOT_EXIT, {})
            end

        elseif opt == guild_config.GUILD_ANSWER_APPLY_JOIN_IN_NO then
            --不同意
            --table.insert(Messages, {dbid, info.type, info.extend, info.timestamp,})
            for i, info in pairs(Messages) do
                if info[1] == MessageId then

                    if mb then
                        mb.client.GuildResp(action_config.MSG_ANSWER_APPLY, 0, {guild_config.GUILD_ANSWER_APPLY_JOIN_IN_NO})
                    end

                    --通知申请人被拒绝加入公会
                    local PlayerDbid = info[3][1]
                    if self.PlayerInfo[PlayerDbid] and self.PlayerInfo[PlayerDbid][1] ~= '' then
                        local mb1 = mogo.UnpickleBaseMailbox(self.PlayerInfo[PlayerDbid][1])
                        if mb1 then
                            mb1.client.GuildResp(action_config.MSG_APPLY_TO_JOIN_RESULT, 0, {guild_config.GUILD_ANSWER_APPLY_JOIN_IN_NO, self.guilds[GuildId].name,})
                        end
                    end

                    local function ExcCallBack(ret)
                        if ret ~= 0 then
                            log_game_error("GuildMgr:AnswerApply", "ret = %d", ret)
                        else
                            log_game_debug("GuildMgr:AnswerApply", "ret = %d", ret)
                            self.guildMessages[GuildId][i] = nil

--                            if not self.PlayerInfo[PlayerDbid] then
--                               --如果当前公会系统没有数据则加载回来
--                                globalbase_call('UserMgr', 'GuildQueryInfoByPlayerDbids', GuildId,    --公会dbid
--                                                                 mogo.pickleMailbox(self), {PlayerDbid,},
--                                                                {public_config.USER_MGR_PLAYER_DBID_INDEX,
--                                                                 public_config.USER_MGR_PLAYER_NAME_INDEX,
--                                                                 public_config.USER_MGR_PLAYER_LEVEL_INDEX,
--                                                                 public_config.USER_MGR_PLAYER_FIGHT_INDEX,})
--                                self.PlayerInfo[PlayerDbid] = {}
--                            end
--
--                            log_game_debug("GuildMgr:AnswerApply", "GuildId=%d;guild=%s;PlayerInfo=%s",
--                                                                    GuildId, mogo.cPickle(guild), mogo.cPickle(self.PlayerInfo[PlayerDbid]))
--
--                            --通知申请人已经成功加入公会
--                            if self.PlayerInfo[PlayerDbid] and self.PlayerInfo[PlayerDbid][1] and self.PlayerInfo[PlayerDbid][1] ~= '' then
--                                local mb1 = mogo.UnpickleBaseMailbox(self.PlayerInfo[PlayerDbid][1])
--                                if mb1 then
--                                    mb1.client.GuildResp(action_config.MSG_APPLY_TO_JOIN_RESULT, 0, {guild_config.GUILD_ANSWER_APPLY_JOIN_IN_YES, self.guilds[GuildId].name,})
--                                end
--                            end
                        end
                    end

                    local sql1 = string.format('DELETE FROM `tbl_GuildMessage` WHERE `id`=%d', MessageId)

                    self:TableExcuteSql(sql1, ExcCallBack)

                    return
                end
            end

            --玩家没有公会或者权限不足，不可查看公会消息
            if mb then
                mb.client.GuildResp(action_config.MSG_ANSWER_APPLY, guild_config.ERROR_ANSWER_APPLY_MESSAGE_NOT_EXIT, {})
            end
            return
        end

    else
        --玩家没有公会或者权限不足，不可查看公会消息
        if mb then
            mb.client.GuildResp(action_config.MSG_ANSWER_APPLY, guild_config.ERROR_ANSWER_APPLY_NO_RIGHT, {})
        end
    end

end

function GuildMgr:Invite(MbStr, PlayerDbid, ToDbid, ToPlayerMbStr)
    log_game_debug("GuildMgr:Invite", "MbStr=%s;Playerdbid=%q;Todbid=%q;ToPlayerMbStr=%s",
                                       MbStr, PlayerDbid, ToDbid, ToPlayerMbStr)

    local mb = mogo.UnpickleBaseMailbox(MbStr)

    if self:IsPlayerInGuild(ToDbid) then
        if mb then
            mb.client.GuildResp(action_config.MSG_INVITE, guild_config.ERROR_INVITE_ALREADY_IN_GUILD, {})
        end
        return
    end

    local GuildId = self:PresidentGetGuildId(PlayerDbid)

    if GuildId then

        local InviteCode = self:GetInviteCode()
        local Invites = self.InviteInfo[ToDbid] or {}
        table.insert(Invites, {InviteCode, GuildId})
        self.InviteInfo[ToDbid] = Invites

        --通知邀请方邀请发送成功
        if mb then
            mb.client.GuildResp(action_config.MSG_INVITE, 0, {PlayerDbid})
        end

        --通知被邀请方
        local mb1 = mogo.UnpickleBaseMailbox(ToPlayerMbStr)
        if mb1 then
            mb1.client.GuildResp(action_config.MSG_INVITED, 0, {InviteCode, self.guilds[GuildId].name,})
        end
    else
        --玩家没有公会或者权限不足，不可查看公会消息
        if mb then
            mb.client.GuildResp(action_config.MSG_INVITE, guild_config.ERROR_INVITE_NO_RIGHT, {})
        end
    end
end

function GuildMgr:AnswerInvite(MbStr, PlayerDbid, InviteCode, opt)
    log_game_debug("GuildMgr:AnswerInvite", "MbStr=%s;Playerdbid=%q;InviteCode=%d;opt=%d",
                                             MbStr, PlayerDbid, InviteCode, opt)

    local mb = mogo.UnpickleBaseMailbox(MbStr)

    if self:IsPlayerInGuild(PlayerDbid) and opt == guild_config.GUILD_INVITED_ANSWER_YES then
        if mb then
            mb.client.GuildResp(action_config.MSG_ANSWER_INVITE, guild_config.ERROR_INVITE_ALREADY_IN_GUILD, {})
        end
        return
    end

    local Invites = self.InviteInfo[PlayerDbid]
    if Invites then
        for i, invite in pairs(Invites) do
            if invite[1] == InviteCode then
                local GuildId = invite[2]

                if opt == guild_config.GUILD_INVITED_ANSWER_YES then

                    local guild = self.guilds[GuildId]
                    if lua_util.get_table_real_count(guild.members) >= gGuildDataMgr:getMemberCountByLevel(guild.level) then
                    --公会人数超过最大值
                        if mb then
                            mb.client.GuildResp(action_config.MSG_ANSWER_INVITE, guild_config.ERROR_ANSWER_INVITE_TOO_MUCH_MEMBERS, {})
                        end
                        return
                    end

                    if guild.status == guild_config.GUILD_STATUS_FREEZE then
                    --公会人数超过最大值
                        if mb then
                            mb.client.GuildResp(action_config.MSG_ANSWER_INVITE, guild_config.ERROR_ANSWER_INVITE_STATUS_FREEZE, {})
                        end
                        return
                    end

                    local j = self:GetIdleNormalPoistion(GuildId)
                    self.guilds[GuildId].members[j] = PlayerDbid

--                    table.insert(self.guilds[GuildId].members, PlayerDbid)
                    self.DirtyGuildIds[GuildId] = true
                    self.PlayerDbid2GuildDbid[PlayerDbid] = GuildId
                    globalbase_call("UserMgr", "UpdatePlayerGuildDbid", PlayerDbid, GuildId)
                    if mb then
                        mb.client.GuildResp(action_config.MSG_ANSWER_INVITE, 0, {self.guilds[GuildId].name,})
                    end
                elseif opt == guild_config.GUILD_INVITED_ANSWER_NO then
                    
                end

                --最后删除邀请
                self.InviteInfo[PlayerDbid][i] = nil
            end
        end
    end

    if mb then
        mb.client.GuildResp(action_config.MSG_ANSWER_INVITE, guild_config.ERROR_INVITE_NOT_EXIT, {})
    end
end

function GuildMgr:Quit(MbStr, PlayerDbid)
    log_game_debug("GuildMgr:Quit", "MbStr=%s;Playerdbid=%q", MbStr, PlayerDbid)

    local mb = mogo.UnpickleBaseMailbox(MbStr)
    for GuildId, info in pairs(self.guilds) do
        for i, playerDbid in pairs(info.members) do
            if playerDbid == PlayerDbid then
                if info.president_dbid == PlayerDbid then
                    if mb then
                        mb.client.GuildResp(action_config.MSG_QUIT, guild_config.ERROR_QUIT_ONLY_NORMAL_MEMBER, {})
                    end
                else
                    if info.vice_president1_dbid == PlayerDbid then
                        info.vice_president1_dbid = 0
                    end

                    if info.vice_president2_dbid == PlayerDbid then
                        info.vice_president2_dbid = 0
                    end

                    if info.vice_president3_dbid == PlayerDbid then
                        info.vice_president3_dbid = 0
                    end

                    info.members[i] = nil
                    info.contribute[PlayerDbid] = nil
                    self.DirtyGuildIds[GuildId] = true
                    self.PlayerDbid2GuildDbid[PlayerDbid] = nil
                    globalbase_call("UserMgr", "UpdatePlayerGuildDbid", PlayerDbid, 0)
                    if mb then
                        mb.client.GuildResp(action_config.MSG_QUIT, 0, {})
                    end
                end
                return
            end
        end
    end

    if mb then
        mb.client.GuildResp(action_config.MSG_QUIT, guild_config.ERROR_QUIT_NO_GUILD, {})
    end
end

function GuildMgr:Promote(MbStr, PlayerDbid, toPlayerDbid)
    log_game_debug("GuildMgr:Promote", "MbStr=%s;Playerdbid=%q;toPlayerdbid=%q", MbStr, PlayerDbid, toPlayerDbid)

    local mb = mogo.UnpickleBaseMailbox(MbStr)

    local GuildId = self:PresidentGetGuildId(PlayerDbid)
    if GuildId and self.guilds[GuildId] and self.guilds[GuildId].president_dbid == PlayerDbid then
        local guild = self.guilds[GuildId]

        local flag = false
        for i, playerDbid in pairs(guild.members) do
            if playerDbid == toPlayerDbid then
                flag = true
                break
            end
        end

        if flag then
            if guild.vice_president1_dbid == 0 then
                self.guilds[GuildId].vice_president1_dbid = toPlayerDbid
                self.DirtyGuildIds[GuildId] = true
                if mb then
                    mb.client.GuildResp(action_config.MSG_PROMOTE, 0, {})
                end
            elseif guild.vice_president2_dbid == 0 then
                self.guilds[GuildId].vice_president2_dbid = toPlayerDbid
                self.DirtyGuildIds[GuildId] = true
                if mb then
                    mb.client.GuildResp(action_config.MSG_PROMOTE, 0, {})
                end
            elseif guild.vice_president3_dbid == 0 then
                self.guilds[GuildId].vice_president3_dbid = toPlayerDbid
                self.DirtyGuildIds[GuildId] = true
                if mb then
                    mb.client.GuildResp(action_config.MSG_PROMOTE, 0, {})
                end
            else
                if mb then
                    mb.client.GuildResp(action_config.MSG_PROMOTE, guild_config.ERROR_PROMOTE_FULL, {})
                end
            end

        else
            if mb then
                mb.client.GuildResp(action_config.MSG_PROMOTE, guild_config.ERROR_PROMOTE_NO_RIGHT, {})
            end
        end

    else
        if mb then
            mb.client.GuildResp(action_config.MSG_PROMOTE, guild_config.ERROR_PROMOTE_NO_RIGHT, {})
        end
    end
end

function GuildMgr:Demote(MbStr, PlayerDbid, toPlayerDbid)
    log_game_debug("GuildMgr:Demote", "MbStr=%s;Playerdbid=%q;toPlayerdbid=%q", MbStr, PlayerDbid, toPlayerDbid)

    local mb = mogo.UnpickleBaseMailbox(MbStr)

    local GuildId = self:PresidentGetGuildId(PlayerDbid)
    if GuildId and self.guilds[GuildId] and self.guilds[GuildId].president_dbid == PlayerDbid then
        local guild = self.guilds[GuildId]

        if guild.vice_president1_dbid == toPlayerDbid then
            self.guilds[GuildId].vice_president1_dbid = 0
            self.DirtyGuildIds[GuildId] = true
            if mb then
                mb.client.GuildResp(action_config.MSG_DEMOTE, 0, {})
            end
        elseif guild.vice_president2_dbid == toPlayerDbid then
            self.guilds[GuildId].vice_president2_dbid = 0
            self.DirtyGuildIds[GuildId] = true
            if mb then
                mb.client.GuildResp(action_config.MSG_DEMOTE, 0, {})
            end
        elseif guild.vice_president3_dbid == toPlayerDbid then
            self.guilds[GuildId].vice_president3_dbid = 0
            self.DirtyGuildIds[GuildId] = true
            if mb then
                mb.client.GuildResp(action_config.MSG_DEMOTE, 0, {})
            end
        else
            if mb then
                mb.client.GuildResp(action_config.MSG_DEMOTE, guild_config.ERROR_DEMOTE_NO_RIGHT, {})
            end
        end

    else
        if mb then
            mb.client.GuildResp(action_config.MSG_DEMOTE, guild_config.ERROR_DEMOTE_NO_RIGHT, {})
        end
    end
end

function GuildMgr:Expel(MbStr, PlayerDbid, toPlayerDbid)
    log_game_debug("GuildMgr:Expel", "MbStr=%s;Playerdbid=%q;toPlayerdbid=%q", MbStr, PlayerDbid, toPlayerDbid)

    local mb = mogo.UnpickleBaseMailbox(MbStr)

    local GuildId = self:PresidentGetGuildId(PlayerDbid)
    if GuildId and self.guilds[GuildId] and (self.guilds[GuildId].GUILD_POST_PRESIDENT == PlayerDbid or 
    
                                             (self.guilds[GuildId].vice_president1_dbid == PlayerDbid and 
                                             self.guilds[GuildId].president_dbid ~= toPlayerDbid and 
                                             self.guilds[GuildId].vice_president2_dbid ~= toPlayerDbid and 
                                             self.guilds[GuildId].vice_president3_dbid ~= toPlayerDbid) or

                                             (self.guilds[GuildId].vice_president2_dbid == PlayerDbid and 
                                             self.guilds[GuildId].president_dbid ~= toPlayerDbid and 
                                             self.guilds[GuildId].vice_president1_dbid ~= toPlayerDbid and 
                                             self.guilds[GuildId].vice_president3_dbid ~= toPlayerDbid) or 

                                             (self.guilds[GuildId].vice_president3_dbid == PlayerDbid and 
                                             self.guilds[GuildId].president_dbid ~= toPlayerDbid and 
                                             self.guilds[GuildId].vice_president1_dbid ~= toPlayerDbid and 
                                             self.guilds[GuildId].vice_president3_dbid ~= toPlayerDbid)
                                             ) then

        local guild = self.guilds[GuildId]

        local flag = false
        local oldIndex = 0
        for i, playerDbid in pairs(guild.members) do
            if playerDbid == toPlayerDbid then
                oldIndex = i
                flag = true
                break
            end
        end

        if flag then

            if self.guilds[GuildId].vice_president1_dbid == toPlayerDbid then
                self.guilds[GuildId].vice_president1_dbid = 0
            end

            if self.guilds[GuildId].vice_president2_dbid == toPlayerDbid then
                self.guilds[GuildId].vice_president2_dbid = 0
            end

            if self.guilds[GuildId].vice_president3_dbid == toPlayerDbid then
                self.guilds[GuildId].vice_president3_dbid = 0
            end

            self.guilds[GuildId].members[oldIndex] = nil
            self.DirtyGuildIds[GuildId] = true
            self.PlayerDbid2GuildDbid[toPlayerDbid] = nil
            globalbase_call("UserMgr", "UpdatePlayerGuildDbid", toPlayerDbid, 0)
            if mb then
                mb.client.GuildResp(action_config.MSG_EXPEL, 0, {})
            end

        else
            if mb then
                mb.client.GuildResp(action_config.MSG_EXPEL, guild_config.ERROR_EXPEL_NOT_EXIT, {})
            end
        end

    else
        if mb then
            mb.client.GuildResp(action_config.MSG_EXPEL, guild_config.ERROR_EXPEL_NO_RIGHT, {})
        end
    end
end

function GuildMgr:Demise(MbStr, PlayerDbid, toPlayerDbid)
    log_game_debug("GuildMgr:Demise", "MbStr=%s;Playerdbid=%q;toPlayerdbid=%q", MbStr, PlayerDbid, toPlayerDbid)

    local mb = mogo.UnpickleBaseMailbox(MbStr)

    local GuildId = self:PresidentGetGuildId(PlayerDbid)
    if GuildId and self.guilds[GuildId] and (self.guilds[GuildId].president_dbid == PlayerDbid) then

        local guild = self.guilds[GuildId]

        local flag = false
        for i, playerDbid in pairs(guild.members) do
            if playerDbid == toPlayerDbid then
                flag = true
                break
            end
        end

        if flag then
            self.guilds[GuildId].president_dbid = toPlayerDbid

            self.DirtyGuildIds[GuildId] = true
            if mb then
                mb.client.GuildResp(action_config.MSG_DEMISE, 0, {})
            end

        else
            if mb then
                mb.client.GuildResp(action_config.MSG_DEMISE, guild_config.ERROR_DEMISE_NOT_EXIT, {})
            end
        end

    else
        if mb then
            mb.client.GuildResp(action_config.MSG_DEMISE, guild_config.ERROR_DEMISE_NO_RIGHT, {})
        end
    end
end

function GuildMgr:Dismiss(MbStr, PlayerDbid)
    log_game_debug("GuildMgr:Dismiss", "MbStr=%s;Playerdbid=%q", MbStr, PlayerDbid)

    local mb = mogo.UnpickleBaseMailbox(MbStr)

    local GuildId = self:PresidentGetGuildId(PlayerDbid)
    if not GuildId then
        if mb then
            mb.client.GuildResp(action_config.MSG_DISMISS, guild_config.ERROR_DISMISS_NO_RIGHT, {})
        end
    else
        if self.guilds[GuildId].president_dbid ~= PlayerDbid then
            if mb then
                mb.client.GuildResp(action_config.MSG_DISMISS, guild_config.ERROR_DISMISS_NO_RIGHT, {})
            end
            return
        end

        if self.guilds[GuildId].timestamp ~= 0 and self.guilds[GuildId].status == guild_config.GUILD_STATUS_FREEZE then
            if mb then
                mb.client.GuildResp(action_config.MSG_DISMISS, guild_config.ERROR_DISMISS_ALREADY_IN_DELETED, {self.guilds[GuildId].timestamp})
            end
            return
        end

        self.guilds[GuildId].status = guild_config.GUILD_STATUS_FREEZE
        self.guilds[GuildId].timestamp = os.time()
        self.DirtyGuildIds[GuildId] = true

        if mb then
            mb.client.GuildResp(action_config.MSG_DISMISS, 0, {})
        end

--        local function ExcCallBack(ret)
--            if ret ~= 0 then
--                log_game_error("GuildMgr:Dismiss", "ret = %d", ret)
--            else
--                log_game_debug("GuildMgr:Dismiss", "guild=%s", mogo.cPickle(GuildId))
--                self.DeletedGuildIds[GuildId] = os.time()
--                if mb then
--                    mb.client.GuildResp(guild_config.MSG_DISMISS, 0, {})
--                end
--            end
--        end
--
----        local sql = 'UPDATE tbl_Guild SET sm_timestamp=' .. os.time() .. ' WHERE id=' .. GuildId
--        local sql = string.format("UPDATE tbl_Guild SET sm_timestamp=%d, sm_status=%d WHERE id=%d", os.time(), GuildId, guild_config.GUILD_STATUS_FREEZE)
--
--        self:TableExcuteSql(sql,ExcCallBack)

    end
end


function GuildMgr:Thaw(MbStr, PlayerDbid)
    log_game_debug("GuildMgr:Thaw", "MbStr=%s;Playerdbid=%q", MbStr, PlayerDbid)

    local mb = mogo.UnpickleBaseMailbox(MbStr)

    local flag =  false
    for GuildId, Guild in pairs(self.guilds) do
        for _, playerDbid in pairs(Guild.members) do
            if playerDbid == PlayerDbid then
                if Guild.timestamp == 0 then
                    if mb then
                        mb.client.GuildResp(action_config.MSG_THAW, guild_config.ERROR_THAW_NO_NEED, {})
                    end
                    return
                else
                    Guild.timestamp = 0
                    Guild.status = guild_config.GUILD_STATUS_NORMAL
                    self.DirtyGuildIds[GuildId] = true
                    if mb then
                        mb.client.GuildResp(action_config.MSG_THAW, 0, {})
                    end
                    return
                end
            end
        end
    end

    if mb then
        mb.client.GuildResp(action_config.MSG_THAW, guild_config.ERROR_THAW_NO_GUILD, {})
    end
end

--工会频道聊天
function GuildMgr:Chat(dbid, name, level, mbstr, msg)
    local guildId = self.PlayerDbid2GuildDbid[dbid]
    if guildId then
        local guild = self.guilds[guildId]
        if guild then
            for _, playerDbid in pairs(guild.members) do
                local PlayerInfo = self.PlayerInfo[playerDbid]
                if PlayerInfo[1] ~= '' then
                    local mb = mogo.UnpickleBaseMailbox(PlayerInfo[1])
                    if mb then
                        mb.client.ChatResp(public_config.CHANNEL_ID_UNION, dbid, name, level, msg)
                    end
                    return
                end
            end
            local mb = mogo.UnpickleBaseMailbox(mbstr)
            if mb then
                mb.client.ShowTextID(CHANNEL.TIPS, error_code.CHAT_PERSON_NOT_EXIT)
            end
            return
        end
    end

    local mb = mogo.UnpickleBaseMailbox(mbstr)
    if mb then
        mb.client.ShowTextID(CHANNEL.TIPS, error_code.CHAT_GUILD_NOT_EXIT)
    end
    return
end

function GuildMgr:GetGuildMembers(MbStr, PlayerDbid, StartIndex, Count)
    log_game_debug("GuildMgr:GetGuildMembers", "MbStr=%s;Playerdbid=%q;StartIndex=%d;Count=%d", MbStr, PlayerDbid, StartIndex, Count)

    local mb = mogo.UnpickleBaseMailbox(MbStr)

    local guildId = self.PlayerDbid2GuildDbid[PlayerDbid]
    if not guildId then
        if mb then
            mb.client.GuildResp(action_config.MSG_GET_GUILD_MEMBERS, guild_config.ERROR_GET_GUILD_MEMBERS_NO_GUILD, {})
        end
        return
    end

    local guild = self.guilds[guildId]
    if not guild then
        if mb then
            mb.client.GuildResp(action_config.MSG_GET_GUILD_MEMBERS, guild_config.ERROR_GET_GUILD_MEMBERS_NO_GUILD, {})
        end
        return
    end

    local index = 1
    local result = {}
    local i = 0
    local position = 0
    for _, playerDbid in pairs(guild.members) do

        if index >= StartIndex then
            local PlayerInfo = self.PlayerInfo[playerDbid]
            log_game_debug("GuildMgr:GetGuildMembers", "playerdbid=%q", playerDbid)

            if playerDbid == guild.president_dbid then
                position = guild_config.GUILD_POST_PRESIDENT
            elseif playerDbid == guild.vice_president1_dbid then
                position = guild_config.GUILD_POST_VICE_PRESIDENT1
            elseif playerDbid == guild.vice_president2_dbid then
                position = guild_config.GUILD_POST_VICE_PRESIDENT2
            elseif playerDbid == guild.vice_president3_dbid then
                position = guild_config.GUILD_POST_VICE_PRESIDENT3
            else
                position = guild_config.GUILD_POST_MEMBER
            end

            if PlayerInfo then
                table.insert(result, {playerDbid, PlayerInfo[2] or '', 
                                                  PlayerInfo[3] or 0, 
                                                  position, 
                                                  PlayerInfo[4] or 0, 
                                                  (guild.contribute[playerDbid] or 0), 
                                                  (guild.members_online_time[playerDbid] or 0)})
                i = i + 1
            end
        end

        index = index + 1

        if i >= Count then
            break
        end
    end

    if mb then
        log_game_debug("GuildMgr:GetGuildMembers", "MbStr=%s;Playerdbid=%q;StartIndex=%d;Count=%d;result=%s", MbStr, PlayerDbid, StartIndex, Count, mogo.cPickle(result))
        mb.client.GuildResp(action_config.MSG_GET_GUILD_MEMBERS, 0, result)
    end
end

function GuildMgr:Recharge(MbStr, PlayerDbid, PlayerName, Money, PlayerLevel, Type, Charge)
    log_game_debug("GuildMgr:Recharge", "MbStr=%s;Playerdbid=%q;PlayerName=%s;Money=%d;PlayerLevel=%d;Type=%d;Charge=%d", MbStr, PlayerDbid, PlayerName, Money, PlayerLevel, Type, Charge)

    if Type ~= guild_config.GUILD_RECHARGE_TYPE_GOLD and Type ~= guild_config.GUILD_RECHARGE_TYPE_DIAMOND then
        log_game_error("GuildMgr:Recharge", "MbStr=%s;Playerdbid=%q;PlayerName=%s;PlayerLevel=%d;Money=%d;Type=%d;Charge=%d", MbStr, PlayerDbid, PlayerName, PlayerLevel, Money, Type, Charge)
        return
    end

    local mb = mogo.UnpickleBaseMailbox(MbStr)

    local guildId = self.PlayerDbid2GuildDbid[PlayerDbid]
    if not guildId then
        if mb then
            mb.client.GuildResp(action_config.MSG_RECHARGE, guild_config.ERROR_RECHARGE_NO_GUILD, {})
        end
        return
    end

    local guild = self.guilds[guildId]
    if not guild then
        if mb then
            mb.client.GuildResp(action_config.MSG_RECHARGE, guild_config.ERROR_RECHARGE_NO_GUILD, {})
        end
        return
    end

    local DragonLimit = gGuildDataMgr:getGuildDragonLimit(guild.level, PlayerLevel)
    if not DragonLimit or DragonLimit <= guild.dragon_value then
        if mb then
            mb.client.GuildResp(action_config.MSG_RECHARGE, guild_config.ERROR_RECHARGE_OVER_LIMIT, {})
        end
        return
    end

    local Cost = gGuildDataMgr:getCostByLevel(guild.level, PlayerLevel, Type)
    if not Cost then
        if mb then
            mb.client.GuildResp(action_config.MSG_RECHARGE, guild_config.ERROR_RECHARGE_CAN_NOT, {})
        end
        return
    end

    local times = math.floor(Charge / Cost)
    if times < 1 then
        if mb then
            if Type == guild_config.GUILD_RECHARGE_TYPE_GOLD then
                mb.client.GuildResp(action_config.MSG_RECHARGE, guild_config.ERROR_RECHARGE_NOT_ENOUGH_GOLD, {})
            else
                mb.client.GuildResp(action_config.MSG_RECHARGE, guild_config.ERROR_RECHARGE_NOT_ENOUGH_DIAMOND, {})
            end
        end
        return
    end

    local RealCost = times * Cost
    if Money < RealCost then
        if mb then
            if Type == guild_config.GUILD_RECHARGE_TYPE_GOLD then
                mb.client.GuildResp(action_config.MSG_RECHARGE, guild_config.ERROR_RECHARGE_NOT_ENOUGH_GOLD, {})
            else
                mb.client.GuildResp(action_config.MSG_RECHARGE, guild_config.ERROR_RECHARGE_NOT_ENOUGH_DIAMOND, {})
            end
        end
        return
    end

    local number_of_times = guild.player_recharge_number_of_times[PlayerDbid]
    if number_of_times and number_of_times >= g_GlobalParamsMgr:GetParams('guild_recharge_day_times', 3) then
        if mb then
            mb.client.GuildResp(action_config.MSG_RECHARGE, guild_config.ERROR_RECHARGE_DAY_TIMES, {})
        end
        return
    end

    local now = os.time()
    local LastRechargeTime = guild.player_recharge_times[PlayerDbid]
    if LastRechargeTime and LastRechargeTime + g_GlobalParamsMgr:GetParams('guild_recharge_cd_time', 3600) > now then
        if mb then
            mb.client.GuildResp(action_config.MSG_RECHARGE, guild_config.ERROR_RECHARGE_CD, {})
        end
        return
    end

    guild.dragon_value = guild.dragon_value + times
--    guild.money = guild.money + (gGuildDataMgr:getMoneyByLevel(guild.level, PlayerLevel, Type) or 0)
    self:AddMoney(guildId, (gGuildDataMgr:getMoneyByLevel(guild.level, PlayerLevel, Type) or 0))
    guild.player_recharge_times[PlayerDbid] = now
    guild.player_recharge_number_of_times[PlayerDbid] = (guild.player_recharge_number_of_times[PlayerDbid] or 0) + 1
    self.DirtyGuildIds[guildId] = true

    if guild.dragon_value >= DragonLimit then
        --通知公会所有成员龙晶成长满了
    end

    if mb then
        mb.GuildB2BReq(action_config.MSG_RECHARGE_RESP, Type, RealCost, tostring(gGuildDataMgr:getExpByLevel(guild.level, PlayerLevel, Type) or 0))
        mb.client.GuildResp(action_config.MSG_RECHARGE, 0, {})
    end
end

--增加公会资金并升级的接口
function GuildMgr:AddMoney(guildId, guild, money)
    guild.money = guild.money + money
    for i = (guild.level + 1), 7, 1 do
        local UpgradeMoney = gGuildDataMgr:getUpgradeMoneyByLevel(i)
        if guild.money >= UpgradeMoney then
            guild.money = guild.money - UpgradeMoney
            guild.level = i
            log_game_debug("GuildMgr:AddMoney Upgrade", "guild=%s", mogo.cPickle(guild))
            --通知工会成员公会升级了
        end
    end
    self.DirtyGuildIds[guildId] = true
end

function GuildMgr:GetDragon(MbStr, PlayerDbid, PlayerName, PlayerLevel)
    log_game_debug("GuildMgr:GetDragon", "MbStr=%s;Playerdbid=%q;PlayerName=%s;PlayerLevel=%d", MbStr, PlayerDbid, PlayerName, PlayerLevel)

    local mb = mogo.UnpickleBaseMailbox(MbStr)

    local guildId = self.PlayerDbid2GuildDbid[PlayerDbid]
    if not guildId then
        if mb then
            mb.client.GuildResp(action_config.MSG_GET_DRAGON, guild_config.ERROR_GET_DRAGON_NO_GUILD, {})
        end
        return
    end

    local guild = self.guilds[guildId]
    if not guild then
        if mb then
            mb.client.GuildResp(action_config.MSG_GET_DRAGON, guild_config.ERROR_GET_DRAGON_NO_GUILD, {})
        end
        return
    end

    local DragonLimit = gGuildDataMgr:getGuildDragonLimit(guild.level, PlayerLevel)
    if not DragonLimit or DragonLimit > guild.dragon_value then
        if mb then
            mb.client.GuildResp(action_config.MSG_GET_DRAGON, guild_config.ERROR_GET_DRAGON_NOT_FULL, {})
        end
        return
    end

    local PlayerTimes = guild.player_get_dragon_times[PlayerDbid] or 0
    if PlayerTimes >= g_GlobalParamsMgr:GetParams('guild_get_dragon_times', 3) then
        if mb then
            mb.client.GuildResp(action_config.MSG_GET_DRAGON, guild_config.ERROR_GET_DRAGON_OVER_TIMES, {})
        end
        return
    end

    guild.player_get_dragon_times[PlayerDbid] = PlayerTimes + 1
    self.DirtyGuildIds[guildId] = true

    local DiamondReward = gGuildDataMgr:getDiamondRewardByLevel(guild.level, PlayerLevel) or 0
    local GoldReward = gGuildDataMgr:getGoldRewardByLevel(guild.level, PlayerLevel) or 0

    --到公会频道发公告

    if mb then
        mb.GuildB2BReq(action_config.MSG_GET_DRAGON_RESP, DiamondReward, GoldReward, '')
        mb.client.GuildResp(action_config.MSG_RECHARGE, 0, {})
    end
end

function GuildMgr:UpgradeGuildSkill(MbStr, PlayerDbid, PlayerName, SkillType)
    log_game_debug("GuildMgr:UpgradeGuildSkill", "MbStr=%s;Playerdbid=%q;PlayerName=%s;SkillType=%d", MbStr, PlayerDbid, PlayerName, SkillType)

    local mb = mogo.UnpickleBaseMailbox(MbStr)

    if SkillType ~= guild_config.GUILD_SKILL_TYPE_ATTACK and SkillType ~= guild_config.GUILD_SKILL_TYPE_DEFENSE and SkillType ~= guild_config.GUILD_SKILL_TYPE_HP then
        mb.client.GuildResp(action_config.MSG_UPGRADE_GUILD_SKILL, guild_config.ERROR_UPGRADE_GUILD_SKILL_NO_SUCH_TYPE, {})
        return
    end

    local guildId = self.PlayerDbid2GuildDbid[PlayerDbid]
    if not guildId then
        if mb then
            mb.client.GuildResp(action_config.MSG_UPGRADE_GUILD_SKILL, guild_config.ERROR_UPGRADE_GUILD_SKILL_NO_GUILD, {})
        end
        return
    end

    local guild = self.guilds[guildId]
    if not guild then
        if mb then
            mb.client.GuildResp(action_config.MSG_UPGRADE_GUILD_SKILL, guild_config.ERROR_UPGRADE_GUILD_SKILL_NO_GUILD, {})
        end
        return
    end

    if guild.president_dbid ~= PlayerDbid then
        if mb then
            mb.client.GuildResp(action_config.MSG_UPGRADE_GUILD_SKILL, guild_config.ERROR_UPGRADE_GUILD_SKILL_NO_RIGHT, {})
        end
        return
    end

    local TargetLevel = (guild.skill[SkillType] or 0) + 1
    local SkillLevelLimit = gGuildDataMgr:getSkillLevelLimitByLevel(guild.level)
    if TargetLevel > SkillLevelLimit then
        if mb then
            mb.client.GuildResp(action_config.MSG_UPGRADE_GUILD_SKILL, guild_config.ERROR_UPGRADE_GUILD_SKILL_ALREADY_LIMIT, {})
        end
        return
    end

    local MoneyCost = gGuildDataMgr:getSkillMoneyCost(SkillType, TargetLevel)
    if not MoneyCost or MoneyCost > guild.money then
        if mb then
            mb.client.GuildResp(action_config.MSG_UPGRADE_GUILD_SKILL, guild_config.ERROR_UPGRADE_GUILD_SKILL_NOT_ENOUGH_MONEY, {})
        end
        return
    end

    --成功升级技能
    guild.skill[SkillType] = TargetLevel
    self:AddMoney(guildId, guild, -MoneyCost)
    if mb then
        mb.client.GuildResp(action_config.MSG_UPGRADE_GUILD_SKILL, 0, {SkillType, TargetLevel,})
    end

    --通知工会内的所有人成功升级技能了
    for _, playerDbid in pairs(guild.members) do
        local PlayerInfo = self.PlayerInfo[playerDbid]
        if PlayerInfo then
            local mb = mogo.UnpickleBaseMailbox(PlayerInfo[1])
            if mb then
                --公会长升级成功后通知每一个公会成员
                mb.GuildB2BReq(action_config.MSG_UPGRADE_GUILD_SKILL_RESP, 0, 0, '')
            end
        end
    end
end

function GuildMgr:GetRecommedList(MbStr, PlayerDbid)
    log_game_debug("GuildMgr:GetRecommedList", "MbStr=%s;Playerdbid=%q", MbStr, PlayerDbid)

    if self:PresidentGetGuildId(PlayerDbid) then
        globalbase_call("UserMgr", "GetRecommedList", MbStr)
    else
        local mb = mogo.UnpickleBaseMailbox(MbStr)
        if mb then
            mb.client.GuildResp(action_config.MSG_GET_RECOMMEND_LIST, guild_config.ERROR_GET_RECOMMEND_LIST_NO_RIGHT, {})
        end
    end
end

function GuildMgr:GetDragonInfo(MbStr, PlayerDbid)
    log_game_debug("GuildMgr:GetDragonInfo", "MbStr=%s;Playerdbid=%q", MbStr, PlayerDbid)

    local mb = mogo.UnpickleBaseMailbox(MbStr)

    local guildId = self.PlayerDbid2GuildDbid[PlayerDbid]
    if not guildId or not self.guilds[guildId]then
        if mb then
            mb.client.GuildResp(action_config.MSG_GET_DRAGON_INFO, guild_config.ERROR_GET_DRAGON_INFO_NO_GUILD, {})
        end
    else
        local guild = self.guilds[guildId]
        local number_of_times = guild.player_recharge_number_of_times[PlayerDbid] or 0
        local LastRechargeTime = guild.player_recharge_times[PlayerDbid] or 0
        if mb then
            log_game_debug("GuildMgr:GetDragonInfo", "MbStr=%s;Playerdbid=%q;number_of_times=%d;LastRechargeTime=%d", MbStr, PlayerDbid, number_of_times, LastRechargeTime)
            mb.client.GuildResp(action_config.MSG_GET_DRAGON_INFO, 0, {number_of_times, LastRechargeTime,})
        end
    end
end

--玩家更新属性时调用该方法，加上公会的加成
function GuildMgr:GuildProcessBasePropertiesReq(MbStr, PlayerDbid, BaseProps)
    log_game_debug("GuildMgr:ProcessBaseProperties", "MbStr=%s;Playerdbid=%q;BaseProps=%s", MbStr, PlayerDbid, mogo.cPickle(BaseProps))

    local guildId = self.PlayerDbid2GuildDbid[PlayerDbid]
    if guildId then
        local guild = self.guilds[guildId]
        if guild then
            local AtkSkillLevel = guild.skill[guild_config.GUILD_SKILL_TYPE_ATTACK]
            if AtkSkillLevel then
                local AtkAdd = gGuildDataMgr:getSkillAdd(guild_config.GUILD_SKILL_TYPE_ATTACK, AtkSkillLevel)
                if AtkAdd then
                    BaseProps['atk'] = BaseProps['atk'] + AtkAdd
                    log_game_debug("GuildMgr:ProcessBaseProperties AddAtk", "MbStr=%s;Playerdbid=%q;AtkAdd=%d;BaseProps['atk']=%d", MbStr, PlayerDbid, AtkAdd, BaseProps['atk'])
                end
            end

            local DefSkillLevel = guild.skill[guild_config.GUILD_SKILL_TYPE_DEFENSE]
            if DefSkillLevel then
                local DefAdd = gGuildDataMgr:getSkillAdd(guild_config.GUILD_SKILL_TYPE_DEFENSE, DefSkillLevel)
                if DefAdd then
                    BaseProps['def'] = BaseProps['def'] + DefAdd
                    log_game_debug("GuildMgr:ProcessBaseProperties AddDef", "MbStr=%s;Playerdbid=%q;DefAdd=%d;BaseProps['def']=%d", MbStr, PlayerDbid, DefAdd, BaseProps['def'])
                end
            end

            local HpLevel = guild.skill[guild_config.GUILD_SKILL_TYPE_HP]
            if HpLevel then
                local HpAdd = gGuildDataMgr:getSkillAdd(guild_config.GUILD_SKILL_TYPE_HP, HpLevel)
                if HpAdd then
                    BaseProps['hp'] = BaseProps['hp'] + HpAdd
                    log_game_debug("GuildMgr:ProcessBaseProperties AddHp", "MbStr=%s;Playerdbid=%q;HpAdd=%d;BaseProps['hp']=%d", MbStr, PlayerDbid, HpAdd, BaseProps['hp'])
                end
            end
        end
    end

    local mb = mogo.UnpickleBaseMailbox(MbStr)
    if mb then
        mb.GuildProcessBasePropertiesResp(BaseProps)
    end
end

function GuildMgr:IsPlayerInGuild(PlayerDbid)
--    for _, info in pairs(self.guilds) do
--        for _, playerDbid in pairs(info.members) do
--            if playerDbid == PlayerDbid then
--                return true
--            end
--        end
--    end
    if self.PlayerDbid2GuildDbid[PlayerDbid] then
        return true
    else
        return false
    end
end

function GuildMgr:GetInviteCode()
    self.InviteCode = self.InviteCode + 1
    return self.InviteCode
end

function GuildMgr:PresidentGetGuildId(PresidentDbid)
    if self.PlayerInfo[PresidentDbid] then
        local GuildId = self.PlayerDbid2GuildDbid[PresidentDbid]
        if not GuildId then
            return
        end

        local info = self.guilds[GuildId]
        if info
            and (info.president_dbid == PresidentDbid 
            or info.vice_president1_dbid == PresidentDbid 
            or info.vice_president2_dbid == PresidentDbid 
            or info.vice_president3_dbid == PresidentDbid) then
        return GuildId
        end

    end
end

--获取指定公会指定职位的角色名称
function GuildMgr:GetPositionName(guildId, position)
    local guild = self.guilds[guildId]
    if guild then
        local playerDbid = 0
        if position == guild_config.GUILD_POST_PRESIDENT then
            playerDbid = guild.president_dbid
        end
        if position == guild_config.GUILD_POST_VICE_PRESIDENT1 then
            playerDbid = guild.vice_president1_dbid
        end
        if position == guild_config.GUILD_POST_VICE_PRESIDENT2 then
            playerDbid = guild.vice_president2_dbid
        end
        if position == guild_config.GUILD_POST_VICE_PRESIDENT3 then
            playerDbid = guild.vice_president3_dbid
        end
        local playerInfo = self.PlayerInfo[playerDbid]
        if playerInfo and playerInfo[2] then
            return playerInfo[2]
        end
    end

    return ''
end

--获取指定公会里面除了会长和副会长以外的空闲位置，用于添加一个新人
function GuildMgr:GetIdleNormalPoistion(guildId)
    local guild = self.guilds[guildId]
    if not guild then
        return 0
    end

    for i=1, gGuildDataMgr:getMemberCountByLevel(guild.level), 1 do
        if not guild.members[i] then
            return i
        end
    end
end

function GuildMgr:GetIdleVicePresidentPoistion(guildId)
    local guild = self.guilds[guildId]
    if not guild then
        return 0
    end

    if guild.vice_president1_dbid == 0 then
        return guild_config.GUILD_POST_VICE_PRESIDENT1
    end

    if guild.vice_president2_dbid == 0 then
        return guild_config.GUILD_POST_VICE_PRESIDENT2
    end

    if guild.vice_president3_dbid == 0 then
        return guild_config.GUILD_POST_VICE_PRESIDENT3
    end

end

return GuildMgr