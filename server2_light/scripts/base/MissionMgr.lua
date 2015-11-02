
require "lua_util"
require "action_config"

local log_game_debug = lua_util.log_game_debug
local log_game_warning = lua_util.log_game_warning
local log_game_info = lua_util.log_game_info
local log_game_error = lua_util.log_game_error
local globalbase_call = lua_util.globalbase_call

MissionMgr = {}

setmetatable( MissionMgr, {__index = BaseEntity} )

function MissionMgr:__ctor__()

    log_game_debug("MissionMgr:__ctor__", "")

    local function RegisterGloballyCB(ret)
        log_game_debug("RegisterGloballyCB", "")
        if 1 == ret then
             --注册成功
             self:OnRegistered()
        else
            --注册失败
            log_game_error("MissionMgr:RegisterGlobally error", '')
        end
    end

    self:RegisterGlobally("MissionMgr", RegisterGloballyCB)

end

function MissionMgr:OnRegistered()

    self.missionRecords = {}

    --在本进程内加载所有副本记录实体
    mogo.loadEntitiesOfType("MissionRecord")

--    self:TableSelectSql("OnMissionRecordCountResp", "MissionRecord", "SELECT COUNT(*) AS `id` FROM `tbl_MissionRecord`")

end

function MissionMgr:OnMissionRecordLoaded(count)

    --记录所有记录的总数量
    log_game_info("MissionMgr:OnMissionRecordLoaded", "count=%d", count)
    self.AllRecordsCount = count
    if self.AllRecordsCount == self.AllLoadedRecordsCount then
        globalbase_call('GameMgr', 'OnMgrLoaded', 'MissionMgr')
    end

end

function MissionMgr:RegisterToMission(missionRecord)
    local LoadedCount = self.AllLoadedRecordsCount + 1
    self.AllLoadedRecordsCount = LoadedCount

    local MissionId = missionRecord.MissionId
    local Difficulty = missionRecord.Difficulty

    local tmp = self.missionRecords[MissionId] or {}
    tmp[Difficulty] = missionRecord

    self.missionRecords[MissionId] = tmp

    log_game_debug("MissionMgr:RegisterToMission", "MissionId=%d;Difficulty=%d;PlayerDbid=%d;PlayerName=%s;PassTime=%d;Combo=%d;Point=%d;TimeStamp=%d",
        missionRecord.MissionId, missionRecord.Difficulty, missionRecord.PlayerDbid, missionRecord.PlayerName, missionRecord.PassTime, missionRecord.Combo,
        missionRecord.Point, missionRecord.TimeStamp)

    if self.AllLoadedGuildsCount == self.AllGuildsCount then
        globalbase_call('GameMgr', 'OnMgrLoaded', 'MissionMgr')
    end
end


function MissionMgr:UpdateMissionRecord(MissionId, Difficulty, PlayerDbid, PlayerName, PlayerVocation, PassTime, Combo, Point)
    log_game_debug('MissionMgr:UpdateMissionRecord', 'MissionId=%d;Difficulty=%d;Playerdbid=%q;PlayerName=%s;PlayerVocation=%d;PassTime=%d;Combo=%d;Point=%d',
        MissionId, Difficulty, PlayerDbid, PlayerName, PlayerVocation, PassTime, Combo, Point)

     if not self.missionRecords[MissionId] or not self.missionRecords[MissionId][Difficulty] then
         --该难度的关卡原来没有记录，则新增
         local MissionRecord = mogo.createBase("MissionRecord")
         MissionRecord:OnCreated(MissionId, Difficulty, PlayerDbid, PlayerName, PlayerVocation, PassTime, Combo, Point)
     else
         local missionRecord = self.missionRecords[MissionId][Difficulty]
         if missionRecord.Point < Point then
             log_game_debug('MissionMgr:UpdateMissionRecord', 'MissionId=%d;Difficulty=%d;Playerdbid=%q;PlayerName=%s;PlayerVocation=%d;OldPlayerVocation=%d;OldDbid=%d;OldName=%s', MissionId, Difficulty, PlayerDbid, PlayerName,PlayerVocation,  missionRecord.PlayerVocation, missionRecord.PlayerDbid, missionRecord.PlayerName)

             missionRecord.PlayerDbid = PlayerDbid
             missionRecord.PlayerName = PlayerName
             missionRecord.PlayerVocation = PlayerVocation
             missionRecord.Combo = Combo
             missionRecord.Point = Point
             missionRecord.TimeStamp = PassTime
         end
     end
end

function MissionMgr:GetMissionRecord(MbStr, MissionId, Difficulty)
    local mb = mogo.UnpickleBaseMailbox(MbStr)
    if mb then
        if not self.missionRecords[MissionId] or not self.missionRecords[MissionId][Difficulty] then
            mb.client.MissionResp(action_config.MSG_GET_MISSION_RECORD, {})
        else
            local missionRecord = self.missionRecords[MissionId][Difficulty]
            mb.client.MissionResp(action_config.MSG_GET_MISSION_RECORD, {missionRecord.PlayerName, missionRecord.Point, missionRecord.PlayerVocation,})
        end
    end
end

--function MissionMgr:OnMissionRecordCountResp(rst)
--
--    for count, _ in pairs(rst) do
--        self.AllRecordsCount = count
--    end
--
--    if self.AllRecordsCount == 0 then
--        globalbase_call('GameMgr', 'OnMgrLoaded', 'MissionMgr')
--        return
--    end
--
--    local times = math.ceil(self.AllRecordsCount / 100)
--    log_game_debug('MissionMgr:OnMissionRecordCountResp', 'rst=%s;times=%d', mogo.cPickle(rst), times)
--
--    for i=1, times, 1 do
--
--          local sql = string.format("SELECT `id`, `sm_MissionId`, `sm_Difficulty`, `sm_PlayerDbid`, `sm_PassTime`, `sm_Combo`, `sm_TimeStamp` FROM `tbl_MissionRecord` LIMIT %d, %d",
--                                     (i-1) * 100, 100)
--
--        log_game_debug('MissionMgr:OnRecordSelectResp', 'sql=%s', sql)
--        self:TableSelectSql("OnRecordSelectResp", "MissionRecord", sql)
--    end
--
--end
--
--function MissionMgr:OnRecordSelectResp(rst)
--    log_game_debug('MissionMgr:OnRecordSelectResp', 'rst=%s', mogo.cPickle(rst))
--
--    for dbid, info in pairs(rst) do
--        local result = self.missionRecords[info.MissionId]
--        if not result then
--            self.missionRecords[info.MissionId] = {}
--        end
--        self.missionRecords[info.MissionId][info.Difficulty] = {dbid, info.PlayerDbid, info.PassTime, info.Combo, info.TimeStamp,}
--    end
--end

return MissionMgr

