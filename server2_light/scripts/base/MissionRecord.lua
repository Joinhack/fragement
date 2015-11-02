
require "lua_util"

local log_game_debug = lua_util.log_game_debug
local log_game_warning = lua_util.log_game_warning
local log_game_info = lua_util.log_game_info
local log_game_error = lua_util.log_game_error
local globalbase_call = lua_util.globalbase_call

MissionRecord = {}
setmetatable( MissionRecord, {__index = BaseEntity} )

function MissionRecord.onEntitiesLoaded(count)
    log_game_info("MissionRecord.onEntitiesLoaded", "count=%d", count)

    globalbase_call('MissionMgr', 'OnMissionRecordLoaded', count)
end

function MissionRecord:__ctor__()
    local eid = self:getId()
    log_game_debug("MissionRecord:__ctor__", "id=%d", eid)

    if self:getDbid() > 0 then
        self:RegisterToMissionMgr()
    end
end

function MissionRecord:RegisterToMissionMgr()
    self.base_mbstr = mogo.pickleMailbox(self)

    self.mgr = lua_util.getGlobalbaseEntity("MissionMgr")
    self.mgr:RegisterToMission(self)
end

--写数据库成功后的回调方法
local function OnMissionRecordWritten(RecordMission, dbid, err)
    if dbid > 0 then
        log_game_info("OnMissionRecordWritten success", "MissionId=%d;Difficulty=%d;PlayerDbid=%d;PlayerName=%s;PassTime=%d;Combo%d;Point=%d;dbid=%d", RecordMission.MissionId, RecordMission.Difficulty, RecordMission.PlayerDbid, RecordMission.PlayerName, RecordMission.TimeStamp, RecordMission.Combo, RecordMission.Point, dbid)
        RecordMission:RegisterToMissionMgr()

    else
        --写数据库失败
        log_game_error("OnMissionRecordWritten fail", "MissionId=%d;Difficulty=%d;PlayerDbid=%d;PlayerName=%s;PassTime=%d;Combo%d;Point=%d;Err=%s", RecordMission.MissionId, RecordMission.Difficulty, RecordMission.PlayerDbid, RecordMission.PlayerName, RecordMission.TimeStamp, RecordMission.Combo, RecordMission.Point,  err)
    end
end

function MissionRecord:OnCreated(MissionId, Difficulty, PlayerDbid, PlayerName, PlayerVocation, PassTime, Combo, Point)
    log_game_debug("MissionRecord:OnCreated", "MissionId=%d;Difficulty=%d;PlayerDbid=%q;PlayerName=%s;PlayerVocation=%d;PassTime=%d;Combo%d;Point=%d", MissionId, Difficulty, PlayerDbid, PlayerName, PlayerVocation, PassTime, Combo, Point)

    if self:getDbid() == 0 then
        self.MissionId = MissionId
        self.Difficulty = Difficulty
        self.PlayerDbid = PlayerDbid
        self.PlayerName = PlayerName
        self.PlayerVocation = PlayerVocation
        self.Combo = Combo
        self.Point = Point
        self.PassTime = PassTime
        self.TimeStamp = os.time()

        self:writeToDB(OnMissionRecordWritten)
    end


end


