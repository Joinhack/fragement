--author:hwj
--date:2013-8-23
--此为Avatar 竞技场相应接口扩展类,只能由Avatar require使用
--避免Avatar.lua文件过长
require "arena_config"

--进入竞技场
function Avatar:EnterArenaReq()
	if self.arenaSystem.EnterArena then 
		self.arenaSystem:EnterArena(self.level)
	else
		self:ShowTextID(CHANNEL.TIPS, arena_text_id.NEED_LEVEL)
	end
end

--刷新弱对手
function Avatar:RefreshWeakReq()
	if self.arenaSystem.RefreshWeak then 
		self.arenaSystem:RefreshWeak()
	end
end

--刷新强对手
function Avatar:RefreshStrongReq()
	if self.arenaSystem.RefreshStrong then 
		self.arenaSystem:RefreshStrong()
	end
end

--购买加强buff
function Avatar:RevengeBuffReq()
	if self.arenaSystem.RevengeBuff then 
		self.arenaSystem:RevengeBuff()
	end
end

--刷新竞技场显示数据，积分，挑战cd，次数
function Avatar:RefreshArenaDataReq()
	if self.arenaSystem.RefreshArenaData then 
		self.arenaSystem:RefreshArenaData()
	end
end

--清除竞技场CD
function Avatar:ClearArenaCDReq()
	if self.arenaSystem.ClearArenaCD then 
		self.arenaSystem:ClearArenaCD()
	end
end

--增加竞技挑战次数
function Avatar:AddArenaTimesReq()
	if self.arenaSystem.AddArenaTimes then 
		self.arenaSystem:AddArenaTimes()
	end
end

function Avatar:GetArenaRewardInfoReq()
	if self.arenaSystem.GetArenaRewardInfo then 
		self.arenaSystem:GetArenaRewardInfo()
	end
end

--获取竞技场积分奖励
function Avatar:GetArenaRewardReq(idx)
	if self.arenaSystem.GetArenaReward then 
		self.arenaSystem:GetArenaReward(idx)
	end
end

--挑战
function Avatar:ChallengeReq(type)
	if self.arenaSystem.Challenge then 
		self.arenaSystem:Challenge(type)
	end
end

function Avatar:add_arena_credit(var, def)
	if self.arenaSystem.AddCredit then
		self.arenaSystem:AddCredit(var)
	end
end

function Avatar:add_arena_score(var, def)
	if self.arenaSystem.AddScore then
		self.arenaSystem:AddScore(var)
	end
end

function Avatar:foe(var, def)
	if self.arenaSystem.foe then
		self.arenaSystem:foe(var)
	end
end

function Avatar:CanGetScoreRewardsReq()
	if self.arenaSystem.TriggerScoreEvent then
		self.arenaSystem:TriggerScoreEvent()
	end
end

local function CanGetExp(avatar)
    local level_pro_cfg = g_avatar_level_mgr:GetLevelProps(g_arena_config.OPEN_LV)
    if not level_pro_cfg then
        log_game_error("ArenaSystem:GetArenaRewardInfo", "level_pro_cfg nil")
        return
    end
    local reward_cfg = g_arena_config:GetScoreLvCfg(g_arena_config.OPEN_LV)
    if not reward_cfg then
        log_game_error("ArenaSystem:GetArenaRewardInfo", "reward_cfg nil")
        return
    end
    local can_get_exp = 0
    for idx, rewards in pairs(reward_cfg) do
        for k,v in pairs(rewards.reward) do
            if k == public_config.EXP_ID then
                local exp = v * level_pro_cfg.expStandard
                can_get_exp = can_get_exp + exp
            end
        end
    end
    if avatar:hasClient() then
        avatar.client.CanGetExpResp(can_get_exp)
    end
end

function Avatar:CanGetExpReq()
	if self.arenaSystem.CanGetExp then
		self.arenaSystem:CanGetExp()
  else
    if self:hasClient() then
        CanGetExp(self)
    end
  end
end