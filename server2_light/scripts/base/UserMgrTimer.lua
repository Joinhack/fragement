--author:hwj
--date:2013-09-03
--此为usermgr扩展定时类,只能由UserMgr require使用
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
 
function UserMgr:onTimer( timer_id, user_data )
    if(timer_id == self.m_timers[public_config.USER_MGR_TIMER_ID_SAVE_INDEX]) then
        --log_game_debug("UserMgr:onTimer","Save.")
        self:Save()
    --[[
    elseif (timer_id == self.m_timers[public_config.USER_MGR_TIMER_ID_CLEAN_INDEX]) then
        log_game_debug("UserMgr:onTimer","Clean.")
        self:Clean()
    ]]

    elseif user_data == public_config.USER_MGR_TIMER_ID_FIXED then
        self:LoadingRankList()
    else
        log_game_warning("UserMgr:onTimer","unknown timer = %d",timer_id)
    end
end

function UserMgr:GetSaveInfo(PlayerDbid)
    local theInfo = self.DbidToPlayers[PlayerDbid]
    if not theInfo or not theInfo[PLAYER_ARENIC_FIGHT_RANK_INDEX] then
        return
    end
    --if theInfo[PLAYER_LEVEL_INDEX] < g_arena_config.OPEN_LV then
        --return
    --end
    local rr = theInfo[PLAYER_ARENIC_FIGHT_RANK_INDEX]
    if not self.m_lFights[rr] then
        return
    end
    local tt = 
    {
        ['avatarDbid'] = PlayerDbid,
        ['items'] = theInfo[PLAYER_ITEMS_INDEX],
        ['battleProps'] = theInfo[PLAYER_BATTLE_PROPS_INDEX],
        ['skillBag'] = theInfo[PLAYER_SKILL_BAG_INDEX],
        ['arenicFight'] = self.m_lFights[rr][FIGHTS_FIGHT_INDEX],
    }
    return tt
end

function UserMgr:Save()
    local needToSave = {
    --[1] = {
    --["avatarDbid"] = dbid,
    --["content"] = content,
    --}
    }
    local num = 0
    for dbid, _ in pairs(self.m_save) do
        if num >= public_config.USER_MGR_SAVE_NUM then break end
        num = num + 1
        local theInfo = self:GetSaveInfo(dbid)
        if theInfo then
            table.insert(needToSave, theInfo)
        else
            log_game_error("WorldBossMgr:Save", "dbid = %q", dbid)
        end
        self.m_save[dbid] = nil
    end

    local function OnSave( ret )
        if ret ~= 0 then
            log_game_error("WorldBossMgr:OnSave", '')
        end
        log_game_debug("WorldBossMgr:OnSave", "saved. ret = %d", ret)
    end
    if #needToSave ~= 0 then
        mogo.UpdateBatchToDb(needToSave, "UserMgrData", "avatarDbid", OnSave )
    end
end