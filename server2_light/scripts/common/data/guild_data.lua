
require "guild_config"
require "lua_util"

local _readXml = lua_util._readXml
local log_game_debug = lua_util.log_game_debug

local GuildDataMgr = {}
GuildDataMgr.__index = GuildDataMgr

function GuildDataMgr:initData()
    self._guild_data = _readXml('/data/xml/GuildLevel.xml', 'level_i')
end

function GuildDataMgr:initGragonData()
    self._guild_gragon_data = {}
    local tmp = _readXml('/data/xml/GuildLevel.xml', 'id_i')
    for k, v in pairs(tmp) do
        local tbl = self._guild_gragon_data[v['guild_level']] or {}
        local tbl1 = tbl[v['player_level']] or {}
        tbl1['dragon_limit'] = v['dragon_limit']
        tbl1['gold_recharge_cost'] = v['gold_recharge_cost']
        tbl1['gold_recharge_exp'] = v['gold_recharge_exp']
        tbl1['gold_recharge_money'] = v['gold_recharge_money']
        tbl1['diamond_recharge_cost'] = v['diamond_recharge_cost']
        tbl1['diamond_recharge_exp'] = v['diamond_recharge_exp']
        tbl1['diamond_recharge_money'] = v['diamond_recharge_money']
        tbl1['get_diamond_reward'] = v['get_diamond_reward']
        tbl1['get_gold_reward'] = v['get_gold_reward']
        tbl[v['player_level']] = tbl1
        self._guild_gragon_data[v['guild_level']] = tbl
    end

    log_game_debug("GuildDataMgr:initGragonData", "data=%s", mogo.cPickle(self._guild_gragon_data))
end

function GuildDataMgr:initGuildSkill()
    self._guild_skill_data = {}
    local tmp = _readXml('/data/xml/GuildLevel.xml', 'id_i')
    for k, v in pairs(tmp) do
        local tbl = self._guild_gragon_data[v['type']] or {}
        local tbl1 = tbl[v['level']] or {}
        tbl1['money'] = v['money']
        tbl1['add'] = v['add']
        tbl[v['level']] = tbl1
        self._guild_skill_data[v['type']] = tbl
    end

    log_game_debug("GuildDataMgr:initGuildSkill", "data=%s", mogo.cPickle(self._guild_skill_data))
end

function GuildDataMgr:getSkillAdd(SkillType, Level)
    local tmp = self._guild_skill_data[SkillType] or {}
    local tmp1 = tmp[Level] or {}
    if tmp1 then
        return tmp1['add']
    end
end


function GuildDataMgr:getSkillMoneyCost(SkillType, Level)
    local tmp = self._guild_skill_data[SkillType] or {}
    local tmp1 = tmp[Level] or {}
    if tmp1 then
        return tmp1['money']
    end
end

function GuildDataMgr:getMemberCountByLevel(level)
    local cfg = self._guild_data[level] or {}
    return cfg['memberCount'] or 0
end

function GuildDataMgr:getUpgradeMoneyByLevel(level)
    local cfg = self._guild_data[level] or {}
    return cfg['upgradeMoney'] or 0
end

function GuildDataMgr:getSkillLevelLimitByLevel(level)
    local cfg = self._guild_data[level] or {}
    return cfg['skillLevelLimit'] or 0
end

function GuildDataMgr:getCostByLevel(GuildLevel, PlayerLevel, Type)

    if Type ~= guild_config.GUILD_RECHARGE_TYPE_GOLD and Type ~= guild_config.GUILD_RECHARGE_TYPE_DIAMOND then
        return
    end

    local tmp = self._guild_gragon_data[GuildLevel] or {}
    local tmp1 = tmp[PlayerLevel] or {}
    if tmp1 then
        if Type == guild_config.GUILD_RECHARGE_TYPE_GOLD then
            return tmp1['gold_recharge_cost']
        else
            return tmp1['diamond_recharge_cost']
        end
    end
end

function GuildDataMgr:getExpByLevel(GuildLevel, PlayerLevel, Type)

    if Type ~= guild_config.GUILD_RECHARGE_TYPE_GOLD and Type ~= guild_config.GUILD_RECHARGE_TYPE_DIAMOND then
        return
    end

    local tmp = self._guild_gragon_data[GuildLevel] or {}
    local tmp1 = tmp[PlayerLevel] or {}
    if tmp1 then
        if Type == guild_config.GUILD_RECHARGE_TYPE_GOLD then
            return tmp1['gold_recharge_exp']
        else
            return tmp1['diamond_recharge_exp']
        end
    end
end

function GuildDataMgr:getMoneyByLevel(GuildLevel, PlayerLevel, Type)

    if Type ~= guild_config.GUILD_RECHARGE_TYPE_GOLD and Type ~= guild_config.GUILD_RECHARGE_TYPE_DIAMOND then
        return
    end

    local tmp = self._guild_gragon_data[GuildLevel] or {}
    local tmp1 = tmp[PlayerLevel] or {}
    if tmp1 then
        if Type == guild_config.GUILD_RECHARGE_TYPE_GOLD then
            return tmp1['gold_recharge_money']
        else
            return tmp1['diamond_recharge_money']
        end
    end
end

function GuildDataMgr:getGuildDragonLimit(GuildLevel, PlayerLevel)

    local tmp = self._guild_gragon_data[GuildLevel] or {}
    local tmp1 = tmp[PlayerLevel] or {}
    if tmp1 then
        return tmp1['dragon_limit']
    end
end

function GuildDataMgr:getDiamondRewardByLevel(GuildLevel, PlayerLevel)

    local tmp = self._guild_gragon_data[GuildLevel] or {}
    local tmp1 = tmp[PlayerLevel] or {}
    if tmp1 then
        return tmp1['get_diamond_reward']
    end
end

function GuildDataMgr:getGoldRewardByLevel(GuildLevel, PlayerLevel)

    local tmp = self._guild_gragon_data[GuildLevel] or {}
    local tmp1 = tmp[PlayerLevel] or {}
    if tmp1 then
        return tmp1['get_gold_reward']
    end
end

gGuildDataMgr = GuildDataMgr
return gGuildDataMgr
