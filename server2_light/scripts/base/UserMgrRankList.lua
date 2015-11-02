require "error_code"
require "public_config"
require "lua_util"
require "RankListData"
require "ServerChineseData"
require "gm_setting_state"
-------------------------------------------------------------------------------
local log_game_debug            = lua_util.log_game_debug
local log_game_info             = lua_util.log_game_info
local log_game_error            = lua_util.log_game_error
local globalbase_call           = lua_util.globalbase_call
--------------------------------------------------------------------------------
local RANK_LIST_TYPE_MIN        = public_config.RANK_LIST_TYPE_MIN --排行榜编号最小值
local RNAk_LIST_TYPE_MAX        = public_config.RNAk_LIST_TYPE_MAX --排行榜编号最大值
--------------------------------------------------------------------------------
local RANK_LIST_FIGHTFORCE      = public_config.RANK_LIST_FIGHTFORCE      --角色战力榜
local RANK_LIST_UP_LEVEL        = public_config.RANK_LIST_UP_LEVEL        --角色等级榜
local RANK_LIST_ARENIC_CREDIT   = public_config.RANK_LIST_ARENIC_CREDIT   --竞技荣誉榜
local RANK_LIST_ARENIC_SCORE    = public_config.RANK_LIST_ARENIC_SCORE    --竞技积分榜
local RANK_LIST_SANCTUARY       = public_config.RANK_LIST_SANCTUARY       --圣域贡献榜
local RANK_LIST_TOWER_CHALLENGE = public_config.RANK_LIST_TOWER_CHALLENGE --试炼挑战榜
local RANK_LIST_MISSION_SBRAND  = public_config.RANK_LIST_MISSION_SBRAND  --S达人榜
local RANK_LIST_TIME_STAMP      = public_config.RANK_LIST_TIME_STAMP      --更新时间戳
--------------------------------------------------------------------------------------------------
local AVATAR_INFO_NAME          = public_config.AVATAR_INFO_NAME
local AVATAR_INFO_LEVEL         = public_config.AVATAR_INFO_LEVEL
local AVATAR_INFO_VOCATION      = public_config.AVATAR_INFO_VOCATION
local AVATAR_INFO_GENDER        = public_config.AVATAR_INFO_GENDER
local AVATAR_INFO_EQUIPMENT     = public_config.AVATAR_INFO_EQUIPMENT
local AVATAR_INFO_RANK_LIST     = public_config.AVATAR_INFO_RANK_LIST
--------------------------------------------------------------------------------------------------
local AVATAR_RANK_UNIQUE_RANK   = public_config.AVATAR_RANK_UNIQUE_RANK
local AVATAR_RANK_UNIQUE_DBID   = public_config.AVATAR_RANK_UNIQUE_DBID
local AVATAR_RANK_RECORD_NAME   = public_config.AVATAR_RANK_RECORD_NAME
local AVATAR_RANK_HIGHESTLEVEL  = public_config.AVATAR_RANK_HIGHESTLEVEL
local AVATAR_RANK_ATTRIBUTION   = public_config.AVATAR_RANK_ATTRIBUTION
local AVATAR_RANK_FANS_COUNT    = public_config.AVATAR_RANK_FANS_COUNT
local AVATAR_RANK_SECOND_DEFINE = public_config.AVATAR_RANK_SECOND_DEFINE
local AVATAR_RANK_CLIENT_DBID   = public_config.AVATAR_RANK_CLIENT_DBID
----------------------------------public_config.--------------------------------------------------
local AVATAR_RANK_FIGHTFORCE    = public_config.AVATAR_RANK_FIGHTFORCE
local AVATAR_RANK_ARENIC_SCORE  = public_config.AVATAR_RANK_ARENIC_SCORE
local AVATAR_RANK_ARENIC_CREDIT = public_config.AVATAR_RANK_ARENIC_CREDIT
local AVATAR_RANK_SANCTUARY     = public_config.AVATAR_RANK_SANCTUARY
local AVATAR_RANK_SMISSION      = public_config.AVATAR_RANK_SMISSION
local AVATAR_RANK_TOWER_FLOOR   = public_config.AVATAR_RANK_TOWER_FLOOR
--------------------------------------------------------------------------------
local USER_MGR_TIMER_ID_FIXED   = public_config.USER_MGR_TIMER_ID_FIXED
--------------------------------------------------------------------------------
local AVATAR_RANK_ITEM_TYPEID   = public_config.ITEM_INSTANCE_TYPEID
local AVATAR_RANK_ITEM_INDEX    = public_config.ITEM_INSTANCE_GRIDINDEX
local AVATAR_RANK_ITEM_SLOTS    = public_config.ITEM_INSTANCE_SLOTS
--------------------------------------------------------------------------------
local AVATAR_RANK_TYPEID        = public_config.AVATAR_RANK_TYPEID  
local AVATAR_RANK_INDEX         = public_config.AVATAR_RANK_INDEX 
local AVATAR_RANK_SLOTS         = public_config.AVATAR_RANK_SLOTS 
--------------------------------------------------------------------------------------------------
local FIGHTFORCE_NAME_INDEX     = public_config.USER_MGR_PLAYER_NAME_INDEX --用户数据名字索引
--------------------------------------------------------------------------------------------------
--初始化处理接口
--------------------------------------------------------------------------------------------------
function UserMgr:InitRankListTable()
    local rankList = {}
    local startIdx = RANK_LIST_TYPE_MIN
    local endIdx   = RNAk_LIST_TYPE_MAX
    for i = startIdx, endIdx do
        rankList[i] = {}
    end
    rankList[RANK_LIST_TIME_STAMP] = 0
    return rankList
end
--整点刷新定时器处理
function UserMgr:InitFixedTimer()
    local lapsed   = lua_util.lapsed_from_zero_of_yesterday()
    local interval = 3600 - math.fmod(lapsed, 3600)
    --local interval = 100
    self:addTimer(interval, 3600, USER_MGR_TIMER_ID_FIXED)
end
--零点进入结算流程
function UserMgr:RewardSettleOfEveryDay(rankType)
    local dbidToMaps = self.DbidToRank
    local curr_time  = os.time() + 30  --保证结算的准确性向后推算30秒
    local last_time  = dbidToMaps[RANK_LIST_TIME_STAMP] 
    if not last_time then 
        last_time = os.time()
    end
    if lua_util.is_same_day(curr_time, last_time) then
        return
    end
    local rankSimps = dbidToMaps[rankType]
    self.RankToReward = rankSimps
    self:WritingFFRLToRedis(rankType, rankSimps)
end
--writing fight force temple rank list to redis
function UserMgr:WritingFFRLToRedis(rankType, rankData)
    local valList = mogo.cPickle(rankData)
    local fKey    = self:FormatFFRLKey()
    self.RankToRedis:set(rankType, valList, fKey)
end

function UserMgr:FormatFFRLKey()
    return string.format("UserMgr:FightForceRankList")
end 
function UserMgr:ParseKeyTable(keyTable)
    if keyTable[1] == "UserMgr" and
       keyTable[2] == "FightForceRankList" then
       return true
    end
    return false
end
--reading fight force temple rank list from redis
function UserMgr:ReadingFFRLFromRedis()
    local fKey = self:FormatFFRLKey()
    self.RankToRedis:load(fKey)
end
function UserMgr:LoadingFFRLToReward(vals)
    local valList = mogo.cUnpickle(vals)
    log_game_debug("UserMgr:LoadingFFRLToReward", "vals=%s", vals)
    self.RankToReward = valList[RANK_LIST_FIGHTFORCE] or {}
end
function UserMgr:GMLoadingRankList(isGm)
    log_game_debug("UserMgr:GMLoadingRankList", "isGm=%d", isGm)
    if isGm and isGm <= 1 and isGm >= 0  then
        self:DefaultLoadingRankList(isGm)
    end
end
function UserMgr:LoadingRankList()
    self:DefaultLoadingRankList(0) --默认整点更新剔除GM
end
function UserMgr:InitRankList()
    self:DefaultLoadingRankList(0) --默认初始化剔除GM
    self:InitFixedTimer()
    self:ReadingFFRLFromRedis()
end
function UserMgr:DefaultLoadingRankList(gm)
    self:RewardSettleOfEveryDay(RANK_LIST_FIGHTFORCE)
    self.RankList   = self:InitRankListTable()
    self.DbidToRank = self:InitRankListTable()
    self:LoadingFightForceRank(gm)
    self:LoadingLevelRank(gm)
    self:LoadingArenicCreditRank(gm)
    self:LoadingMissionSScoresRank(gm)
    self:LoadingTowerHighestFloorRank(gm)
    self:LoadingArenicScoreRank(gm)
    self:LoadingSanctuaryRank(gm)
    self.RankList[RANK_LIST_TIME_STAMP]   = os.time()
    self.DbidToRank[RANK_LIST_TIME_STAMP] = os.time()
    self.InfoToRank = {}
end
--------------------------------------------------------------------------------------------------
--将dbid和排名映射
--------------------------------------------------------------------------------------------------
function UserMgr:DbidToRankMap(rankType, rankList)
    local dbidMaps = self.DbidToRank[rankType]
    for rankLevel, item in pairs(rankList) do
        dbidMaps[item[AVATAR_RANK_UNIQUE_DBID]] = rankLevel
    end
end
function UserMgr:HasOnRankList(rankType, dbid)
    local dbidMaps  = self.DbidToRank[rankType]
    local rankLevel = dbidMaps[dbid] 
    if rankLevel then
        return rankLevel
    else
        return 0
    end
end
--------------------------------------------------------------------------------------------------
--生成排名查询sql语句 
--------------------------------------------------------------------------------------------------
function UserMgr:MakeSelectSql(arg, limit, gm)
    local mysql = string.format("SELECT `id`, `sm_name`, `sm_level`, `sm_vocation`, `sm_equipeds`, `sm_%s`, `sm_fightForce` FROM tbl_Avatar \
        WHERE sm_level > 0 and sm_%s > 0 and (((sm_gm_setting & %d ) >> %d ) <= %d) ORDER BY sm_%s DESC, sm_fightForce DESC LIMIT %d",
        arg, arg, math.pow(2, gm_setting_state.RANKLIST_STATE), gm_setting_state.RANKLIST_STATE, gm, arg, limit)
    return mysql
end
function UserMgr:MakeFightForceSql(limit, gm)
  local mysql = string.format("SELECT `id`, `sm_name`, `sm_level`, `sm_vocation`, `sm_equipeds`, `sm_fightForce` FROM tbl_Avatar \
        WHERE sm_level > 0 and sm_fightForce > 0 and (((sm_gm_setting & %d ) >> %d ) <= %d) ORDER BY sm_fightForce DESC, sm_level DESC LIMIT %d", 
        math.pow(2, gm_setting_state.RANKLIST_STATE), gm_setting_state.RANKLIST_STATE, gm, limit)
    return mysql
end
function UserMgr:MakeLevelSql(limit, gm)
    local mysql = string.format("SELECT `id`, `sm_name`, `sm_level`, `sm_vocation`, `sm_equipeds`, `sm_fightForce` FROM tbl_Avatar \
        WHERE sm_level > 0 and sm_fightForce > 0 and (((sm_gm_setting & %d ) >> %d ) <= %d) ORDER BY sm_level DESC, sm_fightForce DESC LIMIT %d", 
        math.pow(2, gm_setting_state.RANKLIST_STATE), gm_setting_state.RANKLIST_STATE, gm, limit)
    return mysql
end
function UserMgr:MakeArenicScoreSql(limit, gm)
    local mysql = string.format("SELECT b.id, b.sm_name, b.sm_level, b.sm_vocation, b.sm_equipeds, b.sm_fightForce, a.sm_weekScore FROM \
        (SELECT `sm_avatarDbid`, `sm_weekScore` FROM tbl_ArenaData WHERE sm_weekScore > 0) as a \
        LEFT JOIN \
        (SELECT `id`, `sm_name`, `sm_fightForce`, `sm_level`, `sm_vocation`, `sm_gm_setting`, `sm_equipeds` FROM tbl_Avatar ) as b \
        ON a.sm_avatarDbid = b.id WHERE (((sm_gm_setting & %d ) >> %d ) <= %d) \
        ORDER BY a.sm_weekScore DESC, b.sm_fightForce DESC LIMIT %d", 
        math.pow(2, gm_setting_state.RANKLIST_STATE), gm_setting_state.RANKLIST_STATE, gm, limit)
    return mysql
end
function UserMgr:MakeSanctuarySql(limit, gm)
    local mysql = string.format("SELECT b.id, b.sm_name, b.sm_level, b.sm_vocation, b.sm_equipeds, b.sm_fightForce, a.sm_weekContribution FROM \
        (SELECT sm_avatarDbid, sm_weekContribution FROM tbl_WorldBossData WHERE sm_weekContribution > 0) as a \
        LEFT JOIN \
        (SELECT `id`, `sm_name`, `sm_fightForce`, `sm_level`, `sm_vocation`, `sm_gm_setting`, `sm_equipeds` FROM tbl_Avatar ) as b \
        ON a.sm_avatarDbid = b.id WHERE (((sm_gm_setting & %d ) >> %d ) <= %d) \
        ORDER BY a.sm_weekContribution DESC, b.sm_fightForce DESC LIMIT %d", 
        math.pow(2, gm_setting_state.RANKLIST_STATE), gm_setting_state.RANKLIST_STATE, gm, limit)
    return mysql
end
--------------------------------------------------------------------------------------------------
--查询排名数据和回调
--------------------------------------------------------------------------------------------------
function UserMgr:GetRankItem(id, name, level, firstDef, secondDef)
    local rankItem = {}
    local fans     = self:GetFansCount(id)
    rankItem[AVATAR_RANK_UNIQUE_DBID]   = id
    rankItem[AVATAR_RANK_RECORD_NAME]   = name
    rankItem[AVATAR_RANK_HIGHESTLEVEL]  = level
    rankItem[AVATAR_RANK_ATTRIBUTION]   = firstDef
    rankItem[AVATAR_RANK_FANS_COUNT]    = fans
    rankItem[AVATAR_RANK_SECOND_DEFINE] = secondDef
    return rankItem
end
--获取角色信息项
function UserMgr:ParseInfoItem(name, level, vocation, equipeds)
    local infoItem = {}
    infoItem[AVATAR_INFO_NAME]     = name
    infoItem[AVATAR_INFO_LEVEL]    = level
    infoItem[AVATAR_INFO_VOCATION] = vocation
    local items = {}
    for k, v in pairs(equipeds) do
        local item = {}
        item[AVATAR_RANK_INDEX]  = v[AVATAR_RANK_ITEM_INDEX]
        item[AVATAR_RANK_TYPEID] = v[AVATAR_RANK_ITEM_TYPEID]
        item[AVATAR_RANK_SLOTS]  = v[AVATAR_RANK_ITEM_SLOTS]
        table.insert(items, item)
    end
    infoItem[AVATAR_INFO_EQUIPMENT] = items
    return infoItem
end
function UserMgr:GetFansCount(dbid)
    local fansMap = self.DbidToFans
    local count   = fansMap[dbid]
    if not count or count <= 0 then
        return 0
    end
    return count
end
--注册角色的信息项
function UserMgr:RegisterInfoItem(dbid, name, level, vocation, equipeds)
    local infoMaps = self.InfoToRank
    local infoItem = self:ParseInfoItem(name, level, vocation, equipeds)
    if infoMaps[dbid] then
        return
    end
    infoMaps[dbid] = infoItem
end
-------------------------------------------------------------------------------------------------
--角色战斗力排行榜
--------------------------------------------------------------------------------------------------
local function FightForceSort(a, b)
    local rst  = true
    if a[AVATAR_RANK_FIGHTFORCE] == b[AVATAR_RANK_FIGHTFORCE] then
        rst = a[AVATAR_RANK_HIGHESTLEVEL] > b[AVATAR_RANK_HIGHESTLEVEL]
    else
        rst = a[AVATAR_RANK_FIGHTFORCE] > b[AVATAR_RANK_FIGHTFORCE]
    end
    return rst
end
--------------------------------------------------------------------------------------------------
function UserMgr:LoadingFightForceRank(gm)
    local limit = g_rankList_mgr:GetRankLimit(RANK_LIST_FIGHTFORCE)
    local mysql = self:MakeFightForceSql(limit, gm)
    self:TableSelectSql("LoadingFightForceRankCallback", "Avatar", mysql)
end
function UserMgr:LoadingFightForceRankCallback(retSet)
    local fightForce = self.RankList[RANK_LIST_FIGHTFORCE]
    for k, v in pairs(retSet) do
        local rankItem = self:GetRankItem(k, v.name, v.level, v.fightForce)
        self:RegisterInfoItem(k, v.name, v.level, v.vocation, v.equipeds)
        table.insert(fightForce, rankItem)
    end
    table.sort(fightForce, FightForceSort)
    self:DbidToRankMap(RANK_LIST_FIGHTFORCE, fightForce)
    return true
end
--------------------------------------------------------------------------------------------------
--角色等级排行榜
--------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
local function AvatarLevelSort(a, b)
    local rst  = true
    if a[AVATAR_RANK_HIGHESTLEVEL] == b[AVATAR_RANK_HIGHESTLEVEL] then
        rst = a[AVATAR_RANK_FIGHTFORCE] > b[AVATAR_RANK_FIGHTFORCE]
    else
        rst = a[AVATAR_RANK_HIGHESTLEVEL] > b[AVATAR_RANK_HIGHESTLEVEL]
    end
    return rst
end
-------------------------------------------------------------------------------------------
function UserMgr:LoadingLevelRank(gm)
    local limit = g_rankList_mgr:GetRankLimit(RANK_LIST_UP_LEVEL)
    local mysql = self:MakeLevelSql(limit, gm)
    self:TableSelectSql("LoadingLevelRankCallback", "Avatar", mysql)
end
function UserMgr:LoadingLevelRankCallback(retSet)
    --log_game_debug("UserMgr:LoadingLevelRankCallback", "LevelRankList=%s", mogo.cPickle(retSet))
    local avatarLevel = self.RankList[RANK_LIST_UP_LEVEL]
    for k, v in pairs(retSet) do
        local rankItem = self:GetRankItem(k, v.name, v.level, v.fightForce)
        self:RegisterInfoItem(k, v.name, v.level, v.vocation, v.equipeds)
        table.insert(avatarLevel, rankItem)
    end
    table.sort(avatarLevel, AvatarLevelSort)
    self:DbidToRankMap(RANK_LIST_UP_LEVEL, avatarLevel)
    return true
end
--------------------------------------------------------------------------------------------------
--竞技场荣誉排行榜
--------------------------------------------------------------------------------------------------
local function ArenicCreditSort(a, b)
    local rst  = true
    if a[AVATAR_RANK_ARENIC_CREDIT] == b[AVATAR_RANK_ARENIC_CREDIT] then
        rst = a[AVATAR_RANK_SECOND_DEFINE] > b[AVATAR_RANK_SECOND_DEFINE]
    else
        rst = a[AVATAR_RANK_ARENIC_CREDIT] > b[AVATAR_RANK_ARENIC_CREDIT]
    end
    return rst
end
-------------------------------------------------------------------------------------------
function UserMgr:LoadingArenicCreditRank(gm)
    local limit = g_rankList_mgr:GetRankLimit(RANK_LIST_ARENIC_CREDIT)
    local mysql = self:MakeSelectSql("arenicCredit", limit, gm)
    self:TableSelectSql("LoadingArenicCreditRankCallback", "Avatar", mysql)
end
function UserMgr:LoadingArenicCreditRankCallback(retSet)
    --log_game_debug("UserMgr:LoadingArenicCreditCallback", "arenicCredit=%s", mogo.cPickle(retSet))
    local arenicCredit = self.RankList[RANK_LIST_ARENIC_CREDIT]
    for k, v in pairs(retSet) do
        local rankItem = self:GetRankItem(k, v.name, v.level, v.arenicCredit, v.fightForce)
        self:RegisterInfoItem(k, v.name, v.level, v.vocation, v.equipeds)
        table.insert(arenicCredit, rankItem)
    end
    table.sort(arenicCredit, ArenicCreditSort)
    self:DbidToRankMap(RANK_LIST_ARENIC_CREDIT, arenicCredit)
    return true
end
--------------------------------------------------------------------------------------------------
--副本S评分获得数量排行榜
--------------------------------------------------------------------------------------------------
local function MissionSort(a, b)
    local rst  = true
    if a[AVATAR_RANK_SMISSION] == b[AVATAR_RANK_SMISSION] then
        rst = a[AVATAR_RANK_SECOND_DEFINE] > b[AVATAR_RANK_SECOND_DEFINE]
    else
        rst = a[AVATAR_RANK_SMISSION] > b[AVATAR_RANK_SMISSION]
    end
    return rst
end
--------------------------------------------------------------------------------------------
function UserMgr:LoadingMissionSScoresRank(gm)
    local limit = g_rankList_mgr:GetRankLimit(RANK_LIST_MISSION_SBRAND)
    local mysql = self:MakeSelectSql("MissionSSum", limit, gm)
    self:TableSelectSql("LoadingMissionSScoresRankCallback", "Avatar", mysql)
end
function UserMgr:LoadingMissionSScoresRankCallback(retSet)
    --log_game_debug("UserMgr:LoadingMissionSScoresRankCallback", "MissionSSum=%s", mogo.cPickle(retSet))
    local missionScores = self.RankList[RANK_LIST_MISSION_SBRAND]
    for k, v in pairs(retSet) do
        local rankItem = self:GetRankItem(k, v.name, v.level, v.MissionSSum, v.fightForce)
        self:RegisterInfoItem(k, v.name, v.level, v.vocation, v.equipeds)
        table.insert(missionScores, rankItem)
    end
    table.sort(missionScores, MissionSort)
    self:DbidToRankMap(RANK_LIST_MISSION_SBRAND, missionScores)
    return true
end
--------------------------------------------------------------------------------------------------
--试炼之塔最高层排行榜
--------------------------------------------------------------------------------------------------
local function TowerSort(a, b)
    local rst  = true
    if a[AVATAR_RANK_TOWER_FLOOR] == b[AVATAR_RANK_TOWER_FLOOR] then
        rst = a[AVATAR_RANK_SECOND_DEFINE] > b[AVATAR_RANK_SECOND_DEFINE]
    else
        rst = a[AVATAR_RANK_TOWER_FLOOR] > b[AVATAR_RANK_TOWER_FLOOR]
    end
    return rst
end

--------------------------------------------------------------------------------------------------
function UserMgr:LoadingTowerHighestFloorRank(gm)
    local limit = g_rankList_mgr:GetRankLimit(RANK_LIST_TOWER_CHALLENGE)
    local mysql = self:MakeSelectSql("TowerHighestFloor", limit, gm)
    self:TableSelectSql("LoadingTowerHighestFloorRankCallback", "Avatar", mysql)
end
function UserMgr:LoadingTowerHighestFloorRankCallback(retSet)
    --log_game_debug("LoadingTowerHighestFloorRankCallback", "TowerHighestFloor=%s", mogo.cPickle(retSet))
    local towerHighestFloor = self.RankList[RANK_LIST_TOWER_CHALLENGE]
    for k, v in pairs(retSet) do
        local rankItem = self:GetRankItem(k, v.name, v.level, v.TowerHighestFloor, v.fightForce)
        self:RegisterInfoItem(k, v.name, v.level, v.vocation, v.equipeds)
        table.insert(towerHighestFloor, rankItem)
    end
    table.sort(towerHighestFloor, TowerSort)
    self:DbidToRankMap(RANK_LIST_TOWER_CHALLENGE, towerHighestFloor)
    return true
end
---------------------------------------------------------------------------------------------------
--竞技场周积分排名
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
local function ArenicScoreSort(a, b)
    local rst  = true
    if a[AVATAR_RANK_ARENIC_SCORE] == b[AVATAR_RANK_ARENIC_SCORE] then
        rst = a[AVATAR_RANK_SECOND_DEFINE] > b[AVATAR_RANK_SECOND_DEFINE]
    else
        rst = a[AVATAR_RANK_ARENIC_SCORE] > b[AVATAR_RANK_ARENIC_SCORE]
    end
    return rst
end
---------------------------------------------------------------------------------------------------
function UserMgr:LoadingArenicScoreRank(gm)
    local limit = g_rankList_mgr:GetRankLimit(RANK_LIST_ARENIC_SCORE)
    local mysql = self:MakeArenicScoreSql(limit, gm)
    self:TableSelectSql("LoadingArenicScoreRankCallback", "RankListData", mysql)
end
function UserMgr:LoadingArenicScoreRankCallback(retSet)
    --log_game_debug("LoadingArenicScoreRankCallback", "ArenicScore=%s", mogo.cPickle(retSet))
    local arenicRankList = self.RankList[RANK_LIST_ARENIC_SCORE]
    for k, v in pairs(retSet) do
        local rankItem = self:GetRankItem(v.id, v.name, v.level, v.weekScore, v.fightForce)
        self:RegisterInfoItem(v.id, v.name, v.level, v.vocation, v.equipeds)
        table.insert(arenicRankList, rankItem)
    end
    table.sort(arenicRankList, ArenicScoreSort)
    self:DbidToRankMap(RANK_LIST_ARENIC_SCORE, arenicRankList)
    return true
end
-----------------------------------------------------------------------------------------------------
--圣域周贡献排名
-------------------------------------------------------------------------------------------------------
local function SanctuarySort(a, b)
    local rst  = true
    if a[AVATAR_RANK_SANCTUARY] == b[AVATAR_RANK_SANCTUARY] then
        rst = a[AVATAR_RANK_SECOND_DEFINE] > b[AVATAR_RANK_SECOND_DEFINE]
    else
        rst = a[AVATAR_RANK_SANCTUARY] > b[AVATAR_RANK_SANCTUARY]
    end
    return rst
end
-----------------------------------------------------------------------------------------------------
function UserMgr:LoadingSanctuaryRank(gm)
    local limit = g_rankList_mgr:GetRankLimit(RANK_LIST_SANCTUARY)
    local mysql = self:MakeSanctuarySql(limit, gm)
    self:TableSelectSql("LoadingSanctuaryRankCallback", "RankListData", mysql)
end
function UserMgr:LoadingSanctuaryRankCallback(retSet)
    --log_game_debug("LoadingArenicScoreRankCallback", "ArenicScore=%s", mogo.cPickle(retSet))
    local sanctuaryRankList = self.RankList[RANK_LIST_SANCTUARY]
    for k, v in pairs(retSet) do
        local rankItem = self:GetRankItem(v.id, v.name, v.level, v.weekContribution, v.fightForce)
        self:RegisterInfoItem(v.id, v.name, v.level, v.vocation, v.equipeds)
         table.insert(sanctuaryRankList, rankItem)
    end
    table.sort(sanctuaryRankList, SanctuarySort)
    self:DbidToRankMap(RANK_LIST_SANCTUARY, sanctuaryRankList)
    return true
end
----------------------------------------------------------------------------------------------
--与客服端之间的交互逻辑
----------------------------------------------------------------------------------------------
function UserMgr:IsDataUpdate(currTime, lastTime)
    local delta = currTime - lastTime 
    if delta > 1 then
        return true
    end
    return false
end
--获取下页列表
--返回false：表示没有后续列表
--返回true ：表示还有后续数据
function UserMgr:GetOffsetData(rankList, idx, count, retList)
  local startIdx = (idx - 1)*count + 1
  local endIdx   = startIdx + count - 1
    for level = startIdx, endIdx do
        if rankList[level] then
            local item  = {}
            local rank = rankList[level]
            local dbid  = rank[AVATAR_RANK_UNIQUE_DBID]
            item[AVATAR_RANK_UNIQUE_RANK]  = level
            item[AVATAR_RANK_RECORD_NAME]  = rank[AVATAR_RANK_RECORD_NAME]
            item[AVATAR_RANK_HIGHESTLEVEL] = rank[AVATAR_RANK_HIGHESTLEVEL]
            item[AVATAR_RANK_ATTRIBUTION]  = rank[AVATAR_RANK_ATTRIBUTION]
            item[AVATAR_RANK_FANS_COUNT]   = self:GetFansCount(dbid)
            item[AVATAR_RANK_CLIENT_DBID]  = rank[AVATAR_RANK_UNIQUE_DBID]
            retList[level] = item
        else
              return false
        end
    end
    if not rankList[endIdx + 1] then
        return false
    end
    return true
end
--------------------------------------------------------------------------------------------
function UserMgr:RankListReq(mbstr, rankType, idx, count, timeStamp)
    local avatarMb = mogo.UnpickleBaseMailbox(mbstr)
    local rankList = self.RankList[rankType] or {}
    local retList  = {}
    local retCode  = 0
    local hasMore  = 0
    if self:GetOffsetData(rankList, idx, count, retList) then
        hasMore    = 1
    end
    local updateTime = self.RankList[RANK_LIST_TIME_STAMP]
    if self:IsDataUpdate(updateTime, timeStamp) then
         retCode   = 1
    end
    
    if avatarMb then
        avatarMb.BaseRankListResp(retCode, retList, updateTime, hasMore)
    end
end
--------------------------------------------------------------------------------------------
--获取角色各个排行榜的列表
--------------------------------------------------------------------------------------------
function UserMgr:GetAvatarRankList(dbid, infoItem)
    local rList    = {}
    local startIdx = RANK_LIST_TYPE_MIN
    local endIdx   = RNAk_LIST_TYPE_MAX
    for i = startIdx, endIdx do
        rList[i]   = self:HasOnRankList(i, dbid)
    end
    infoItem[AVATAR_INFO_RANK_LIST]  = rList
end
---------------------------------------------------------------------------------------------
--查看角色的个人信息：装备，等级，名字
---------------------------------------------------------------------------------------------
function UserMgr:RankAvatarInfoReq(mbstr, dbid, isIdol)
    local avatarMb = mogo.UnpickleBaseMailbox(mbstr)
    local infoItem = self.InfoToRank[dbid]
    if not infoItem then
        return 
    end
    local vocation = infoItem[AVATAR_INFO_VOCATION]   
    local gender   = 1
    --法师和刺客
    if vocation == public_config.VOC_ASSASSIN or 
       vocation == public_config.VOC_MAGE then
       gender = 0
    end
    self:GetAvatarRankList(dbid, infoItem)
    if avatarMb then
        avatarMb.BaseRankAvatarInfoResp(infoItem, gender, isIdol)
    end
end
function UserMgr:AvatarIdolNameReq(mbstr, dbid)
    local avatarMb = mogo.UnpickleBaseMailbox(mbstr)
    local player   = self.DbidToPlayers[dbid]
    local idolName = ""
    if player then
        idolName = player[FIGHTFORCE_NAME_INDEX]
    end
    if avatarMb then
        avatarMb.BaseAvatarIdolNameResp(idolName)
    end
end
--------------------------------------------------------------------------------------------
--检索角色的当前排名：rank
--------------------------------------------------------------------------------------------
function UserMgr:HasOnRankReq(mbstr, rankType, dbid)
    local rankLevel = self:HasOnRankList(rankType, dbid)
    local avatarMb  = mogo.UnpickleBaseMailbox(mbstr)
    if avatarMb then
        avatarMb.BaseHasOnRankResp(rankLevel)
    end
end
--------------------------------------------------------------------------------------------
--角色上线粉丝奖励请求
--------------------------------------------------------------------------------------------
function UserMgr:FansRewardOnlineReq(mbstr, dbid)
    local idolLevel  = self:GetIdolFightForceRank(dbid)
    local avatarMb = mogo.UnpickleBaseMailbox(mbstr)
    if avatarMb then
        avatarMb.FansRewardOnlineResp(idolLevel)
    end
end
function UserMgr:GetIdolFightForceRank(dbid)
    local fightForce = {}
    local idolLevel  = self:GetIdolRewardLevel(dbid)
    local player     = self.DbidToPlayers[dbid]
    if player then
        fightForce[idolLevel] = player[FIGHTFORCE_NAME_INDEX]
    end
    return fightForce
end
function UserMgr:GetIdolRewardLevel(dbid)
    local lv = self.RankToReward[dbid]
    if lv then
        return lv
    end
    return 0
end
--------------------------------------------------------------------------------------------
