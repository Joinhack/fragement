
require "lua_util"

local log_game_debug = lua_util.log_game_debug

NormalPlayManager = {}
NormalPlayManager.__index = NormalPlayManager


function NormalPlayManager:init()
--    log_game_debug("NormalPlayManager:init", "")

    local obj = {}
    setmetatable(obj, {__index = NormalPlayManager})
    obj.__index = obj

    return obj
end

function NormalPlayManager:Open()
--    log_game_debug("NormalPlayManager:Open", "MapId = %s", MapId)
end

function NormalPlayManager:InitData()
--    log_game_debug("NormalPlayManager:InitData", "p1=%s p2=%s p3=%s p4=%s", p1, p2, p3, p4)
end

function NormalPlayManager:Start()
--    log_game_debug("NormalPlayManager:Start", "")
end

function NormalPlayManager:StartByServer()
--    log_game_debug("NormalPlayManager:StartByServer", "")
end

function NormalPlayManager:Stop()
--    log_game_debug("NormalPlayManager:Stop", "")
end

function NormalPlayManager:Reset(MapId)
    log_game_debug("NormalPlayManager:Reset", "MapId=%s", MapId)
    lua_util.globalbase_call("MapMgr", "Reset", MapId)
end

function NormalPlayManager:CheckEnter()
--    log_game_debug("NormalPlayManager:CheckEnter", "")
end

function NormalPlayManager:SetMissionInfo()
--    log_game_debug("NormalPlayManager:SetMissionInfo", "")
end

function NormalPlayManager:Restart()
--    log_game_debug("NormalPlayManager:Restart", "")
end

function NormalPlayManager:SpawnPointEvent()
--    log_game_debug("NormalPlayManager:SpawnPointEvent", "")
end

function NormalPlayManager:GetMissionRewards()
--    log_game_debug("NormalPlayManager:GetMissionRewards", "")
end

function NormalPlayManager:onClientDeath()
--    log_game_debug("NormalPlayManager:onClientDeath", "")
end

function NormalPlayManager:onMultiLogin()
--    log_game_debug("NormalPlayManager:onMultiLogin", "dbid=%q", dbid)
end

function NormalPlayManager:Summon()
--    log_game_debug("NormalPlayManager:Summon", "")
end

function NormalPlayManager:ExitMission()
--    log_game_debug("NormalPlayManager:ExitMission", "")
end

function NormalPlayManager:QuitMission()
--    log_game_debug("NormalPlayManager:QuitMission", "")
end

function NormalPlayManager:KickAllPlayer()
--    log_game_debug("NormalPlayManager:KickAllPlayer", "")
end

function NormalPlayManager:AddFinishedSpawnPoint()
--    log_game_debug("NormalPlayManager:AddFinishedSpawnPoint", "")
end

function NormalPlayManager:SetPvpInfo()
end

function NormalPlayManager:CreateClientDrop()
end

function NormalPlayManager:Chat()
end

return NormalPlayManager
