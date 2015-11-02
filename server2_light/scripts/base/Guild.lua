
require "BaseEntity"
require "lua_util"
require "public_config"

local log_game_debug = lua_util.log_game_debug
local log_game_warning = lua_util.log_game_warning
local log_game_info = lua_util.log_game_info
local log_game_error = lua_util.log_game_error
local globalbase_call = lua_util.globalbase_call


Guild = {}
setmetatable( Guild, {__index = BaseEntity} )

function Guild.onEntitiesLoaded(count)
    log_game_info("Guild.onEntitiesLoaded", "count=%d", count)

    globalbase_call('GuildMgr', 'OnGuildsLoaded', count)
end


function Guild:__ctor__()
    local eid = self:getId()
    log_game_debug("Guild:__ctor__", "id=%d", eid)

    if self:getDbid() > 0 then
        self:RegisterToGuildMgr()
    end
end

function Guild:RegisterToGuildMgr()
    self.base_mbstr = mogo.pickleMailbox(self)

    self.mgr = lua_util.getGlobalbaseEntity("GuildMgr")
    self.mgr:RegisterToGuild(self)
end

local function OnGuildWritten(guild, dbid, err)
    if dbid > 0 then
    else
        log_game_error("CreateGuildFailed", "GuildName=%s;err=%d", guild.name, err)
    end
end

function Guild:OnCreated(MbStr, GuildName, PlayerDbid, PlayerName, PlayerLevel, PlayerFight)
    if self:getDbid() == 0 then

        local now = os.time()

        --创建时尚未存盘，先写记录
        self.name = GuildName
        self.level = 1
        self.members[guild_config.GUILD_POST_PRESIDENT] = PlayerDbid
        self.contribute = {}
        self.announcement = ""
        self.money = 0
        self.buildtime = now
        self.timestamp = 0
        self.members_online_time[PlayerDbid] = now
        self.status = public_config.GUILD_STATUS_NORMAL
        self.dragon_value = 0
        self.dragon_clear_time = 0
        self.player_recharge_times = {}
        self.player_recharge_number_of_times = {}
        self.player_get_dragon_times = {}
        self.skill = {}
        self.builder_dbid = PlayerDbid
        self.president_dbid = PlayerDbid
        self.vice_president1_dbid = 0
        self.vice_president2_dbid = 0
        self.vice_president3_dbid = 0
        self.messages = {}

        self:writeToDB(OnGuildWritten)

    end
end