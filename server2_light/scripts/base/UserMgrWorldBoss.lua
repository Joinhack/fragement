--author:hwj
--date:2013-09-03
--此为usermgr扩展世界boss相关接口,只能由UserMgr require使用
--避免UserMgr.lua文件过长
require "public_config"

local log_game_debug = lua_util.log_game_debug
local log_game_warning = lua_util.log_game_warning
local log_game_info = lua_util.log_game_info
local log_game_error = lua_util.log_game_error
local globalbase_call = lua_util.globalbase_call
--[[与usermgr里的前面的local变量一致]]
local PLAYER_BASE_MB_INDEX = public_config.USER_MGR_PLAYER_BASE_MB_INDEX
local PLAYER_CELL_MB_INDEX = public_config.USER_MGR_PLAYER_CELL_MB_INDEX
local PLAYER_DBID_INDEX = public_config.USER_MGR_PLAYER_DBID_INDEX
local PLAYER_NAME_INDEX = public_config.USER_MGR_PLAYER_NAME_INDEX
local PLAYER_LEVEL_INDEX = public_config.USER_MGR_PLAYER_LEVEL_INDEX
local PLAYER_VOCATION_INDEX = public_config.USER_MGR_PLAYER_VOCATION_INDEX
local PLAYER_GENDER_INDEX = public_config.USER_MGR_PLAYER_GENDER_INDEX
local PLAYER_UNION_INDEX = public_config.USER_MGR_PLAYER_UNION_INDEX
local PLAYER_FIGHT_INDEX = public_config.USER_MGR_PLAYER_FIGHT_INDEX --todo:优化
local PLAYER_IS_ONLINE_INDEX = public_config.USER_MGR_PLAYER_IS_ONLINE_INDEX
local PLAYER_FRIEND_NUM_INDEX = public_config.USER_MGR_PLAYER_FRIEND_NUM_INDEX         --好友數量
local PLAYER_OFFLINETIME_INDEX = public_config.USER_MGR_PLAYER_OFFLINETIME_INDEX
-->以下存盘字段begin
local PLAYER_ITEMS_INDEX = public_config.USER_MGR_PLAYER_ITEMS_INDEX            --只缓存身上装备信息，但是会从数据load符文信息来算战斗力，计算完会delete
local PLAYER_BATTLE_PROPS_INDEX = public_config.USER_MGR_PLAYER_BATTLE_PROPS
local PLAYER_SKILL_BAG_INDEX =  public_config.USER_MGR_PLAYER_SKILL_BAG
--<end
local PLAYER_LOADED_ITEMS_INDEX = public_config.USER_MGR_PLAYER_LOADED_ITEMS    --todo:delete

--local PLAYER_BODY_INDEX = public_config.USER_MGR_PLAYER_BODY_INDEX --会从数据load身体信息来算战斗力，计算完会delete
local PLAYER_ARENIC_FIGHT_RANK_INDEX = public_config.USER_MGR_PLAYER_ARENIC_FIGHT_RANK_INDEX
local PLAYER_ARENIC_GRADE_INDEX  = public_config.USER_MGR_PLAYER_ARENIC_GRADE_INDEX
--[[UserMgr临时数据]]
local PLAYER_SKILL_BAG_INDEX_TMP = public_config.USER_MGR_PLAYER_SKILL_BAG_TMP
local PLAYER_ITEMS_INDEX_TMP     = public_config.USER_MGR_PLAYER_ITEMS_INDEX_TMP
local PLAYER_BODY_INDEX_TMP      = public_config.USER_MGR_PLAYER_BODY_INDEX_TMP
local PLAYER_RUNE_INDEX_TMP      = public_config.USER_MGR_PLAYER_RUNE_INDEX_TMP
--[[临时数据]]
--self.m_lFights的下标
local FIGHTS_DBID_INDEX = public_config.USER_MGR_FIGHTS_DBID_INDEX
local FIGHTS_FIGHT_INDEX = public_config.USER_MGR_FIGHTS_FIGHT_INDEX --存盘



function UserMgr:SendSDRewards(rewards, dbid, weekRank)
    log_game_debug("UserMgr:SendSDRewards", "dbid = %q", dbid)
    local theInfo = self.DbidToPlayers[dbid]
    if not theInfo then return end

    if theInfo[PLAYER_IS_ONLINE_INDEX] == public_config.USER_MGR_PLAYER_ONLINE then
        local mb = mogo.UnpickleBaseMailbox(theInfo[PLAYER_BASE_MB_INDEX])
        if not mb then
            log_game_error("UserMgr:SendSDRewards", "no mb but online.")
            return
        end
        mb.OnSanctuaryDefenseReward(rewards, weekRank)
    else
        local mm = globalBases["MailMgr"]
        if not mm then
            log_game_error("UserMgr:SendSDRewards", "no MailMgr mailbox.")
            return
        end

        local attachments = {}
        for i, info in ipairs(rewards) do
            local att = {}
            if info.exp and info.exp > 0 then
                att[public_config.EXP_ID] = info.exp
            end
            if info.gold and info.gold > 0 then
                att[public_config.GOLD_ID] = info.gold
            end
            if info.items then
                for k,v in pairs(info.items) do
                    att[k] = v
                end
            end
            table.insert(attachments, att)
        end

        local time = os.time()
        for i, attachment in ipairs(attachments) do
            --mm.SendId(rewards[i].mailTitle, theInfo[PLAYER_NAME_INDEX], rewards[i].mailText, 
                --rewards[i].mailFrom, time, attachment, {dbid}, {tostring(rewards.contribution)})
            mm.SendIdEx(rewards[i].mailTitle, theInfo[PLAYER_NAME_INDEX], rewards[i].mailText, 
                rewards[i].mailFrom, time, attachment, {dbid}, {tostring(rewards.contribution)}, 
                reason_def.wb_contribution)
        end
    end
end
