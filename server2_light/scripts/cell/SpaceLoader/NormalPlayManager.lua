
require "lua_util"

local log_game_debug = lua_util.log_game_debug

NormalPlayManager = {}
NormalPlayManager.__index = NormalPlayManager


function NormalPlayManager:init()
--    log_game_debug("NormalPlayManager:init", "")

    local obj = {}
    setmetatable(obj, {__index = NormalPlayManager})
    obj.__index = obj

    obj.PlayerInfo = {}

    return obj
end

function NormalPlayManager:OnAvatarCtor(avatar)

    log_game_debug("NormalPlayManager:OnAvatarCtor", "dbid=%q;name=%s", avatar.dbid, avatar.name)
    --记录该场景玩家的dbid与id的key-value对应关系，记录玩家在当前场景的一些数据
    --格式:{玩家dbid = {玩家ID}}
    self.PlayerInfo[avatar.dbid] = {[public_config.PLAYER_INFO_INDEX_EID]=avatar:getId()}

end

function NormalPlayManager:OnAvatarDctor(avatar)

    log_game_debug("NormalPlayManager:OnAvatarDctor", "dbid=%q;name=%s", avatar.dbid, avatar.name)

    --删除对应关系
    self:DeletePlayer(avatar.dbid)

end

--回收
function NormalPlayManager:Recover(SpaceLoader)
    log_game_debug("NormalPlayManager:Recover", "")

    SpaceLoader:Stop()
    --副本重置
    SpaceLoader:Reset()
end

function NormalPlayManager:SetCellInfo()

    log_game_debug("NormalPlayManager:SetCellInfo", "")

end

function NormalPlayManager:SpawnPointEvent()

    log_game_debug("NormalPlayManager:SpawnPointEvent", "")

end

function NormalPlayManager:AddRewards()

    log_game_debug("NormalPlayManager:AddRewards", "")

end

function NormalPlayManager:AddMoney()

    log_game_debug("NormalPlayManager:AddMoney", "")

end

function NormalPlayManager:AddExp()

    log_game_debug("NormalPlayManager:AddExp", "")

end

function NormalPlayManager:GetMissionRewards()

    log_game_debug("NormalPlayManager:GetMissionRewards", "")

end

function NormalPlayManager:NotifyRewardsToClient()

    log_game_debug("NormalPlayManager:NotifyRewardsToClient", "")

end

function NormalPlayManager:OnSpawnPointMonsterDeath()

    log_game_debug("NormalPlayManager:OnSpawnPointMonsterDeath", "")

end

function NormalPlayManager:InitData(p1, p2, p3, p4)
    log_game_debug("NormalPlayManager:InitData", "p1=%s p2=%s p3=%s p4=%s", p1, p2, p3, p4)
end

function NormalPlayManager:Start()

    log_game_debug("NormalPlayManager:Start", "")

end

function NormalPlayManager:DeletePlayer(dbid)

    log_game_debug("NormalPlayManager:DeletePlayer", "dbid=%q", dbid)

    self.PlayerInfo[dbid] = nil
end

function NormalPlayManager:onClientDeath()

    log_game_debug("NormalPlayManager:onClientDeath", "")

end

function NormalPlayManager:IsSpaceLoaderSuccess()

    log_game_debug("NormalPlayManager:IsSpaceLoaderSuccess", "")

end

--发奖
function NormalPlayManager:SendReward()

    log_game_debug("NormalPlayManager:SendReward", "")

end

function NormalPlayManager:AutoPickUpDrops()

    log_game_debug("NormalPlayManager:AutoPickUpDrops", "")

end

function NormalPlayManager:MonsterAutoDie()
    log_game_debug("NormalPlayManager:MonsterAutoDie", "")
end

function NormalPlayManager:Stop()

    log_game_debug("NormalPlayManager:Stop", "")

end

function NormalPlayManager:Reset(SpaceLoader)

    log_game_debug("NormalPlayManager:Reset", "")

    SpaceLoader.base.Reset()

end

function NormalPlayManager:SetWorldBossMgr(wbMgrMbStr)
    log_game_debug("NormalPlayManager:SetWorldBossMgr", wbMgrMbStr)
end

function NormalPlayManager:Summon()
    log_game_debug("NormalPlayManager:Summon", "")
end

function NormalPlayManager:ExitMission()
    log_game_debug("NormalPlayManager:ExitMission", "")
end

function NormalPlayManager:QuitMission()
    log_game_debug("NormalPlayManager:QuitMission", "")
end

function NormalPlayManager:KickAllPlayer()
    log_game_debug("NormalPlayManager:KickAllPlayer", "")
end

function NormalPlayManager:AddFriendDegree()
    log_game_debug("NormalPlayManager:AddFriendDegree", "")
end

function NormalPlayManager:MonsterHpChange(attacker, monster, hp_change)
    --log_game_debug("NormalPlayManager:MonsterHpChange", "")
end

function NormalPlayManager:DoDamageAction(attacker, defender, harm)
    --log_game_debug("NormalPlayManager:DoDamageAction", "")
end

function NormalPlayManager:OnLocalTimer(timer_id, active_count, ...)
end

function NormalPlayManager:DeathEvent(dbid, SpaceLoader)
end

function NormalPlayManager:MonsterDeathEvent(killer_mb_str)
    -- body
end

function NormalPlayManager:Revive()
    log_game_debug("NormalPlayManager:Revive", "")
end

function NormalPlayManager:SpaceDestroy()
end

function NormalPlayManager:AddDamage()
end

function NormalPlayManager:PrepareStart()
end

function NormalPlayManager:onTimer(timer_id, user_data)
end

return NormalPlayManager
