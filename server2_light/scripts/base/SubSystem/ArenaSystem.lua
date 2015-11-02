--author:hwj
--date:2013-8-21
--竞技场子系统
require "PriceList"
require "arena_config"
require "public_config"
require "lua_util"

local log_game_debug = lua_util.log_game_debug
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error

local pvp_type_weak   = 1
local pvp_type_strong = 2
local pvp_type_enemy  = 3

local score_type_day  = 1
local score_type_week = 2


ArenaSystem = {}
ArenaSystem.__index = ArenaSystem

function ArenaSystem:new(owner)
    
    local newObj = {}
    newObj.ptr = {}

    setmetatable(newObj, {__index = ArenaSystem})
    setmetatable(newObj.ptr, {__mode = "kv"})

    newObj.ptr.theOwner = owner
    
    newObj.m_systemData = {
        [arenicDataKey.tmp_scoresOfDay] = 0,
        [arenicDataKey.tmp_rewardOfDay]  = {},
        [arenicDataKey.tmp_scoresOfWeek] = 0,
        [arenicDataKey.tmp_rewardOfWeek] = {},
        [arenicDataKey.tmp_challengeTimes] = 0,
        [arenicDataKey.tmp_weakFoes] = {},
        --[arenicDataKey.tmp_theWeakFoe] = 0,
        [arenicDataKey.tmp_strongFoes] = {},
        --[arenicDataKey.tmp_theStrongFoe] = 0,
        [arenicDataKey.tmp_theEnemy] = 0,
        [arenicDataKey.tmp_beatEnemy] = 0,
        [arenicDataKey.tmp_weakFoesRange] = {10000,0},
        [arenicDataKey.tmp_strongFoesRange] = {10000,0},
        [arenicDataKey.tmp_dayLevel] = 0,
        [arenicDataKey.tmp_weekLevel] = 0,
    }
    --兼容旧数据
    if not owner.arenicData[arenicDataKey.avatar_weakRange] then
        owner.arenicData[arenicDataKey.avatar_weakRange] = {10000,0}
    end
    if not owner.arenicData[arenicDataKey.avatar_strongRange] then
        owner.arenicData[arenicDataKey.avatar_strongRange] = {10000,0}
    end
    if not owner.arenicData[arenicDataKey.avatar_DailyBuys] then
        owner.arenicData[arenicDataKey.avatar_DailyBuys] = 0
    end
    if not owner.arenicData[arenicDataKey.avatar_DailyBuyCd] then
        --提前一分钟
        local t = lua_util.get_left_secs_until_next_hhmiss(0,0,0)
        owner.arenicData[arenicDataKey.avatar_DailyBuyCd] = os.time() + t
    end

    newObj.entered = 0
    newObj.dated = 1 --临时数据是否过期
    newObj.m_state = 0 --状态，控制重复rpc call，主要是场景跳转的时候
    newObj.m_reChoose = {0,0,0,}
    owner.tmp_data[public_config.TMP_DATA_KEY_ARENA] = 1
    return newObj
end

function ArenaSystem:EnterArena(level)
    --log_game_debug("ArenaSystem:EnterArena", "%s", os.time())
    if level < g_arena_config.OPEN_LV then
        return
    end
    self.entered = 1
    local arenicData = self.ptr.theOwner.arenicData
    if os.time() >= arenicData[arenicDataKey.avatar_DailyBuyCd] then
        arenicData[arenicDataKey.avatar_DailyBuys] = 0
        local t = lua_util.get_left_secs_until_next_hhmiss(0,0,0)
        arenicData[arenicDataKey.avatar_DailyBuyCd] = os.time() + t
    end

    if self.dated == 1 or arenicData[arenicDataKey.avatar_weak] == 0 or arenicData[arenicDataKey.avatar_strong] == 0 then
        --数据过期，重登管理中心
        self:Login()
        return
    end
    self:RefreshArenaData()
    self:GiveWeakFoesDetailToClient()
    self:GiveStrongFoesDetailToClient()
    self:GiveEnemyDetailToClient()
end

function ArenaSystem:RefreshArenaData()
    local owner = self.ptr.theOwner
    local theOwnerInfo = owner.arenicData
    local cd = 0
    if theOwnerInfo[arenicDataKey.avatar_cdEndTime] and theOwnerInfo[arenicDataKey.avatar_cdEndTime] ~= 0 then
        cd = theOwnerInfo[arenicDataKey.avatar_cdEndTime] - os.time()
    end
    if cd < 0 then
        theOwnerInfo[arenicDataKey.avatar_cdEndTime] = 0
        cd = 0
    end
    if not theOwnerInfo[arenicDataKey.avatar_buyTimes] then theOwnerInfo[arenicDataKey.avatar_buyTimes] = 0 end
    local canCha = theOwnerInfo[arenicDataKey.avatar_buyTimes]
    if self.m_systemData[arenicDataKey.tmp_challengeTimes] < g_arena_config.CHALLENGE_TIME_PER_DAY then
        canCha = canCha + g_arena_config.CHALLENGE_TIME_PER_DAY - self.m_systemData[arenicDataKey.tmp_challengeTimes]
    end
    if canCha < 0 then
        log_game_error("ArenaSystem:RefreshArenaData", "can challenge time less than 0.")
        canCha = 0
    end
    local tmp = {
        [1] = self.m_systemData[arenicDataKey.tmp_scoresOfDay],
        [2] = self.m_systemData[arenicDataKey.tmp_scoresOfWeek],
        [3] = canCha,
        [4] = self.m_systemData[arenicDataKey.tmp_beatEnemy],
        [5] = cd,
        [6] = theOwnerInfo[arenicDataKey.avatar_buyTimes],
        --[7] = theOwnerInfo[arenicDataKey.avatar_bufAtk],
        --[8] = theOwnerInfo[arenicDataKey.avatar_bufHp],
        [7] = theOwnerInfo[arenicDataKey.avatar_inspire_buf],
        [8] = theOwnerInfo[arenicDataKey.avatar_weakRange],
        [9] = theOwnerInfo[arenicDataKey.avatar_strongRange],
    }
    if owner:hasClient() then
        owner.client.RefreshArenaDataResp(tmp)
    end
    log_game_debug("ArenaSystem:EnterArena", "%s", os.time())
end

function ArenaSystem:ClearArenaCD()
    local owner = self.ptr.theOwner
    local theOwnerInfo = owner.arenicData
    if not theOwnerInfo[arenicDataKey.avatar_cdEndTime] or theOwnerInfo[arenicDataKey.avatar_cdEndTime] == 0 then
        self:ShowTextID(arena_text_id.CLEAR_CD_NO_NEED)
        return
    end
    local lefTime =  theOwnerInfo[arenicDataKey.avatar_cdEndTime] - os.time()
    if lefTime > g_arena_config.CHALLENGE_CD then
        log_game_error("ArenaSystem:ClearArenaCD", "cd time error.")
        lefTime = g_arena_config.CHALLENGE_CD
    end
    lefTime = math.ceil(lefTime/60)
    if lefTime <= 0 then
        self:ShowTextID(arena_text_id.CLEAR_CD_NO_NEED)
        return
    end
    
    local price = g_priceList_mgr:NeedMoney(g_arena_config.CLEAR_CD_PRICE_ID)
    if not price then
        log_game_error("ArenaSystem:ClearArenaCD", "no prince")
        return
    end
    local needGold = 0
    local needDiamond = 0
    for k,v in pairs(price) do
        if k == public_config.GOLD_ID then
            if owner.gold < v * lefTime then
                self:ShowTextID(arena_text_id.NO_MONEY)
                return
            else
                needGold = v * lefTime
            end
        elseif k == public_config.DIAMOND_ID then
            if owner.diamond < v * lefTime then
                self:ShowTextID(arena_text_id.NO_DIAMOND)
                return
            else
                needDiamond = v * lefTime
            end
        else
            log_game_error("ArenaSystem:RevengeBuff", "")
            return
        end
    end

    if needGold > 0 then
        owner:AddGold(-needGold,reason_def.arena_cd)
    end
    if needDiamond > 0 then
        owner:AddDiamond(-needDiamond, reason_def.arena_cd)
    end
    theOwnerInfo[arenicDataKey.avatar_cdEndTime] = 0
    self:RefreshArenaData()
    self:ShowTextID(arena_text_id.CLEAR_CD_SUC)
end

function ArenaSystem:AddArenaTimes()
    local owner = self.ptr.theOwner
    local price = g_priceList_mgr:NeedMoney(g_arena_config.BUY_ARENA_TIME_PRICE_ID)
    if not price then
        log_game_error("ArenaSystem:AddArenaTimes", "no prince")
        return
    end
    local vip_cfg = g_vip_mgr:GetVipPrivileges(owner.VipLevel)
    if not vip_cfg then
        log_game_error("ArenaSystem:AddArenaTimes", "no vip_cfg")
        return
    end
    local vip_limit = vip_cfg.dailyExtraChallengeLimit
    if owner.arenicData[arenicDataKey.avatar_DailyBuys] >= vip_limit then
        self:ShowTextID(arena_text_id.VIP_BUY_FULL)
        return
    end
    local needGold = 0
    local needDiamond = 0
    for k,v in pairs(price) do
        if k == public_config.GOLD_ID then
            if owner.gold < v then
                self:ShowTextID(arena_text_id.NO_MONEY)
                return
            else
                needGold = v
            end
        elseif k == public_config.DIAMOND_ID then
            if owner.diamond < v then
                self:ShowTextID(arena_text_id.NO_DIAMOND)
                return
            else
                needDiamond = v
            end
        else
            log_game_error("ArenaSystem:AddArenaTimes", "")
            return
        end
    end

    if needGold > 0 then
        owner:AddGold(-needGold,reason_def.arena_buy)
    end
    if needDiamond > 0 then
        owner:AddDiamond(-needDiamond, reason_def.arena_buy)
    end
    if not owner.arenicData[arenicDataKey.avatar_buyTimes] then
        owner.arenicData[arenicDataKey.avatar_buyTimes] = 0
    end
    owner.arenicData[arenicDataKey.avatar_buyTimes] = owner.arenicData[arenicDataKey.avatar_buyTimes] + 1
    owner.arenicData[arenicDataKey.avatar_DailyBuys] = owner.arenicData[arenicDataKey.avatar_DailyBuys] + 1
    self:RefreshArenaData()
    self:ShowTextID(arena_text_id.BUY_ARENA_TIME_SUC)
end

function ArenaSystem:RevengeBuff()
    local owner = self.ptr.theOwner
    if owner.arenicData[arenicDataKey.avatar_inspire_buf] and 
        owner.arenicData[arenicDataKey.avatar_inspire_buf] ~= 0 then
        --已经鼓舞过了
        self:ShowTextID(arena_text_id.INSPIRE_ED)
        return
    end
    local price = g_priceList_mgr:NeedMoney(g_arena_config.BUF_PRICE_ID)
    if not price then
        log_game_error("ArenaSystem:RevengeBuff", "no prince")
        return
    end
    local needGold = 0
    local needDiamond = 0
    for k,v in pairs(price) do
        if k == public_config.GOLD_ID then
            if owner.gold < v then
                self:ShowTextID(arena_text_id.NO_MONEY)
                return
            else
                needGold = v
            end
        elseif k == public_config.DIAMOND_ID then
            if owner.diamond < v then
                self:ShowTextID(arena_text_id.NO_DIAMOND)
                return
            else
                needDiamond = v
            end
        else
            log_game_error("ArenaSystem:RevengeBuff", "")
            return
        end
    end

    if needGold > 0 then
        owner:AddGold(-needGold,reason_def.arena_buff)
    end
    if needDiamond > 0 then
        owner:AddDiamond(-needDiamond, reason_def.arena_buff)
    end
    owner.arenicData[arenicDataKey.avatar_inspire_buf] = public_config.ARENA_BUFF_ID
    self:RefreshArenaData()
    self:ShowTextID(arena_text_id.INSPIRE_SUC)
    --[[
    if not owner.arenicData[arenicDataKey.avatar_bufAtk] then
        owner.arenicData[arenicDataKey.avatar_bufAtk] = 0
    end
    if not owner.arenicData[arenicDataKey.avatar_bufHp] then
        owner.arenicData[arenicDataKey.avatar_bufHp] = 0
    end 
    owner.arenicData[arenicDataKey.avatar_bufAtk] = owner.arenicData[arenicDataKey.avatar_bufAtk] + g_arena_config.BUF_ATK_PER
    owner.arenicData[arenicDataKey.avatar_bufHp] = owner.arenicData[arenicDataKey.avatar_bufHp] + g_arena_config.BUF_HP_PER
    local tmp = 
    {
        [1] = owner.arenicData[arenicDataKey.avatar_bufAtk],  
        [2] = owner.arenicData[arenicDataKey.avatar_bufHp],
    }
    owner.client.RevengeBuffResp(tmp)
    ]]
end

function ArenaSystem:RefreshWeak()
    local owner = self.ptr.theOwner
    local price = g_priceList_mgr:NeedMoney(g_arena_config.REFRESH_WEAK_PRICE_ID)
    if not price then
        log_game_error("ArenaSystem:RefreshWeak", "no prince")
        return
    end
    local needGold = 0
    local needDiamond = 0
    for k,v in pairs(price) do
        if k == public_config.GOLD_ID then
            if owner.gold < v then
                self:ShowTextID(arena_text_id.NO_MONEY)
                return
            else
                needGold = v
            end
        elseif k == public_config.DIAMOND_ID then
            if owner.diamond < v then
                self:ShowTextID(arena_text_id.NO_DIAMOND)
                return
            else
                needDiamond = v
            end
        else
            log_game_error("ArenaSystem:RefreshWeak", "")
            return
        end
    end
    
    if needGold > 0 then
        owner:AddGold(-needGold,reason_def.arena_refresh)
    end
    if needDiamond > 0 then
        owner:AddDiamond(-needDiamond, reason_def.arena_refresh)
    end
    self:ResetWeak(true)
    --运营数据采集
    owner:OnRefreshCompete()
end

function ArenaSystem:ResetWeak(bShow)
    local owner = self.ptr.theOwner
    local weakFoes = self.m_systemData[arenicDataKey.tmp_weakFoes]
    if #weakFoes < 1 then
        local mm = globalBases["ArenaMgr"]
        if mm then
            owner.arenicData[arenicDataKey.avatar_weak] = 0
            mm.GetWeakFoes(owner.dbid)
            if bShow then
                self:ShowTextID(arena_text_id.REFRESH_SUC)
            end
        end
        return
    end
    local t = math.random(1, #weakFoes)
    if weakFoes[t] then
        --self.m_systemData[arenicDataKey.tmp_theWeakFoe] = weakFoes[t]
        owner.arenicData[arenicDataKey.avatar_weak] = weakFoes[t]
        owner.arenicData[arenicDataKey.avatar_weakRange] = self.m_systemData[arenicDataKey.tmp_weakFoesRange]
        table.remove(self.m_systemData[arenicDataKey.tmp_weakFoes], t)
        self:GiveWeakFoesDetailToClient()
        self:RefreshArenaData()
        if bShow then
            self:ShowTextID(arena_text_id.REFRESH_SUC)
        end
    end
end

function ArenaSystem:RefreshStrong()
    local owner = self.ptr.theOwner
    local price = g_priceList_mgr:NeedMoney(g_arena_config.REFRESH_STRONG_PRICE_ID)
    if not price then
        log_game_error("ArenaSystem:RevengeBuff", "no prince")
        return
    end
    local needGold = 0
    local needDiamond = 0
    for k,v in pairs(price) do
        if k == public_config.GOLD_ID then
            if owner.gold < v then
                self:ShowTextID(arena_text_id.NO_MONEY)
                return
            else
                needGold = v
            end
        elseif k == public_config.DIAMOND_ID then
            if owner.diamond < v then
                self:ShowTextID(arena_text_id.NO_DIAMOND)
                return
            else
                needDiamond = v
            end
        else
            log_game_error("ArenaSystem:RevengeBuff", "")
            return
        end
    end
    
    if needGold > 0 then
        owner:AddGold(-needGold,reason_def.arena_refresh)
    end
    if needDiamond > 0 then
        owner:AddDiamond(-needDiamond, reason_def.arena_refresh)
    end
    self:ResetStrong(true)
    --运营数据采集
    owner:OnRefreshCompete()
end

function ArenaSystem:ResetStrong(bShow)
    local owner = self.ptr.theOwner
    local foes = self.m_systemData[arenicDataKey.tmp_strongFoes]
    if #foes < 1 then
        local mm = globalBases["ArenaMgr"]
        if mm then
            owner.arenicData[arenicDataKey.avatar_strong] = 0
            mm.GetStrongFoes(owner.dbid)
            if bShow then
                self:ShowTextID(arena_text_id.REFRESH_SUC)
            end
        end
        return
    end
    local t = math.random(1, #foes)
    if foes[t] then
        --self.m_systemData[arenicDataKey.tmp_theStrongFoe] = foes[t]
        owner.arenicData[arenicDataKey.avatar_strong] = foes[t]
        owner.arenicData[arenicDataKey.avatar_strongRange] = self.m_systemData[arenicDataKey.tmp_strongFoesRange]
        table.remove(self.m_systemData[arenicDataKey.tmp_strongFoes], t)
        self:RefreshArenaData()
        self:GiveStrongFoesDetailToClient()
        if bShow then
            self:ShowTextID(arena_text_id.REFRESH_SUC)
        end
    end
end

function ArenaSystem:GetArenaRewardInfo()
    local owner = self.ptr.theOwner
    local level_pro_cfg = g_avatar_level_mgr:GetLevelProps(owner.level)
    if not level_pro_cfg then
        log_game_error("ArenaSystem:GetArenaRewardInfo", "level_pro_cfg nil")
        return
    end
    local reward_cfg = g_arena_config:GetScoreLvCfg(owner.level)
    if not reward_cfg then
        log_game_error("ArenaSystem:GetArenaRewardInfo", "reward_cfg nil")
        return
    end
    local all_reward = {}
    local hasRecvReward = {}
    for idx, rewards in pairs(reward_cfg) do
        if self:CheckRecved(idx) then
            table.insert(hasRecvReward, idx)
        end
        local rr = {}    
        for k,v in pairs(rewards.reward) do
            if k == public_config.EXP_ID then
                local exp = v * level_pro_cfg.expStandard
                rr[1] = k
                rr[2] = exp 
            elseif k == public_config.GOLD_ID then
                local gold = v * level_pro_cfg.goldStandard
                rr[1] = k
                rr[2] = gold 
            else
                rr[1] = k
                rr[2] = v 
            end
        end
        all_reward[idx] = rr
    end
    --[[
    local hasRecvReward = {}
    for idx, _ in pairs(self.m_systemData[arenicDataKey.tmp_rewardOfDay]) do
        --local i = self:GetLevelIdx(1, idx, owner.level)
        table.insert(hasRecvReward, idx)
    end
    for idx, _ in pairs(self.m_systemData[arenicDataKey.tmp_rewardOfWeek]) do
        --local i = self:GetLevelIdx(2, idx, owner.level)
        table.insert(hasRecvReward, idx)
    end
    ]]
    if owner:hasClient() then
        owner.client.GetArenaRewardInfoResp(hasRecvReward, all_reward)
    end
end

function ArenaSystem:CanGetExp()
    local owner = self.ptr.theOwner
    local level_pro_cfg = g_avatar_level_mgr:GetLevelProps(owner.level)
    if not level_pro_cfg then
        log_game_error("ArenaSystem:GetArenaRewardInfo", "level_pro_cfg nil")
        return
    end
    local reward_cfg = g_arena_config:GetScoreLvCfg(owner.level)
    if not reward_cfg then
        log_game_error("ArenaSystem:GetArenaRewardInfo", "reward_cfg nil")
        return
    end
    local can_get_exp = 0
    for idx, rewards in pairs(reward_cfg) do
        if not self:CheckRecved(idx) then
            for k,v in pairs(rewards.reward) do
                if k == public_config.EXP_ID then
                    local exp = v * level_pro_cfg.expStandard
                    can_get_exp = can_get_exp + exp
                end
            end
        end
    end
    if owner:hasClient() then
        owner.client.CanGetExpResp(can_get_exp)
    end
end

function ArenaSystem:GetArenaReward(idx)
    --[[
    if self.m_systemData[arenicDataKey.tmp_rewardOfDay][idx] then
        self:ShowTextID(arena_text_id.SCORS_REWARD_RECV_ED)
        return
    end
    if self.m_systemData[arenicDataKey.tmp_rewardOfWeek][idx] then
        self:ShowTextID(arena_text_id.SCORS_REWARD_RECV_ED)
        return
    end
    ]]
    --todo:
    local owner = self.ptr.theOwner
    local rewards = g_arena_config:GetScoreRewardCfg(idx)
    
    if rewards then
        local lv = rewards.level
        if not lv then return end
        if owner.level < lv[1] or owner.level > lv[2] then
            self:ShowTextID(arena_text_id.SCORS_REWARD_RECV_LV)
            return
        end
        if self:CheckRecved(idx) then
            self:ShowTextID(arena_text_id.SCORS_REWARD_RECV_ED)
            return
        end
        local score = rewards.score
        local reason = reason_def.arena_day_score
        local mm = globalBases['ArenaMgr']
        if rewards.type ~= 1 then
            reason = reason_def.arena_week_score
            if score > self.m_systemData[arenicDataKey.tmp_scoresOfWeek] then
                self:ShowTextID(arena_text_id.SCORS_REWARD_RECV_WEEK)
                return
            end
            self.m_systemData[arenicDataKey.tmp_rewardOfWeek][idx] = 1
            mm.RecvWeekRewards(owner.dbid,owner.base_mbstr, idx)
            self:TriggerScoreEvent()
        else
            if score > self.m_systemData[arenicDataKey.tmp_scoresOfDay] then
                self:ShowTextID(arena_text_id.SCORS_REWARD_RECV_DAY)
                return
            end
            self.m_systemData[arenicDataKey.tmp_rewardOfDay][idx] = 1
            mm.RecvDayRewards(owner.dbid,owner.base_mbstr, idx)
            self:TriggerScoreEvent()
        end
        --运营数据采集
        owner:OnCompCreditExchange(score)
        --[[
        local rr = {}
        local level_pro_cfg = g_avatar_level_mgr:GetLevelProps(owner.level)
        if not level_pro_cfg then
            log_game_error("ArenaSystem:GetArenaReward", "")
            return
        end
        for k,v in pairs(rewards.reward) do
            if k == public_config.EXP_ID then
                local exp = v * level_pro_cfg.expStandard
                local a = exp / 10000
                local af = math.floor(a)
                if a - af >= 0.5 then
                    exp = (af + 1) * 10000
                else
                    exp = af * 10000
                end
                rr[k] = exp
            elseif k == public_config.GOLD_ID then
                local gold = v * level_pro_cfg.goldStandard
                local a = gold / 10000
                local af = math.floor(a)
                if a - af >= 0.5 then
                    gold = (af + 1) * 10000
                else
                    gold = af * 10000
                end
                rr[k] = gold
            else
                rr[k] = v
            end
        end
        owner:get_rewards(rr, reason)
        self:GetArenaRewardInfo()
        self:ShowTextID(arena_text_id.SCORS_REWARD_RECV_SUC)
        ]]
    end
end

function ArenaSystem:CheckRecved(idx)
    local all_cfg = g_arena_config:GetAllScoreRewardCfg()
    local cfg = g_arena_config:GetScoreRewardCfg(idx)
    local recv_ed = self.m_systemData[arenicDataKey.tmp_rewardOfDay]
    if cfg.type == score_type_week then
        recv_ed = self.m_systemData[arenicDataKey.tmp_rewardOfWeek]
    end
    
    for id,v in pairs(all_cfg) do
        if v.group == cfg.group and recv_ed[id] then return true end
    end
    return false
end

function ArenaSystem:TriggerScoreEvent()
    local owner = self.ptr.theOwner
    if not owner:hasClient() then return end
    local reward_cfg = g_arena_config:GetScoreLvCfg(owner.level)
    if not reward_cfg then
        log_game_error("ArenaSystem:ScoreAddEvent", "reward_cfg nil, level[%d]", owner.level)
        return
    end
    local day_score = self.m_systemData[arenicDataKey.tmp_scoresOfDay]
    local week_score = self.m_systemData[arenicDataKey.tmp_scoresOfWeek]

    for idx, cfg in pairs(reward_cfg) do
        if not self:CheckRecved(idx) then
            if cfg.type == score_type_day then
                if cfg.score <= day_score then
                    owner.client.CanGetScoreRewardsResp(1)
                    return
                end
            else
                if cfg.score <= week_score then
                    owner.client.CanGetScoreRewardsResp(1)
                    return
                end
            end
        end
    end
    owner.client.CanGetScoreRewardsResp(0)
end

function ArenaSystem:GetLevelIdx(ty, idx, level)
    local lv_cfg = g_arena_config:GetScoreCfgByLv(ty, level)
    local cfg = g_arena_config:GetScoreRewardCfg(idx)
    local score = cfg.score
    for k,v in pairs(lv_cfg) do
        if v.score == score then
            return k
        end
    end
end

function ArenaSystem:RealGetArenaReward(ret,idx)
    if ret == 1 then
        self:ShowTextID(arena_text_id.SCORS_REWARD_RECV_DAY)
        return
    elseif ret == 2 then
        self:ShowTextID(arena_text_id.SCORS_REWARD_RECV_WEEK)
        return
    end
    local owner = self.ptr.theOwner
    local rewards = g_arena_config:GetScoreRewardCfg(idx)
    
    if rewards then
        local lv = rewards.level
        if not lv then return end
        if owner.level < lv[1] or owner.level > lv[2] then
            self:ShowTextID(arena_text_id.SCORS_REWARD_RECV_LV)
            return
        end

        local score = rewards.score
        local reason = reason_def.arena_day_score
        if rewards.type == score_type_week then
            reason = reason_def.arena_week_score
            if score > self.m_systemData[arenicDataKey.tmp_scoresOfWeek] then
                self:ShowTextID(arena_text_id.SCORS_REWARD_RECV_WEEK)
                return
            end
            self.m_systemData[arenicDataKey.tmp_rewardOfWeek][idx] = 1
        else
            if score > self.m_systemData[arenicDataKey.tmp_scoresOfDay] then
                self:ShowTextID(arena_text_id.SCORS_REWARD_RECV_DAY)
                return
            end
            self.m_systemData[arenicDataKey.tmp_rewardOfDay][idx] = 1
        end
        local rr = {}
        local level_pro_cfg = g_avatar_level_mgr:GetLevelProps(owner.level)
        if not level_pro_cfg then
            log_game_error("ArenaSystem:GetArenaReward", "")
            return
        end
        --[[
        If a / 10000 - Int(a / 10000) >= 0.5 Then
        b = (Int(a / 10000) + 1) * 10000
        Else
        b = Int(a / 10000) * 10000
        ]]

        for k,v in pairs(rewards.reward) do
            if k == public_config.EXP_ID then
                local exp = v * level_pro_cfg.expStandard
                --[[
                local a = exp / 10000
                local af = math.floor(a)
                if a - af >= 0.5 then
                    exp = (af + 1) * 10000
                else
                    exp = af * 10000
                end
                ]]
                rr[k] = exp
            elseif k == public_config.GOLD_ID then
                local gold = v * level_pro_cfg.goldStandard
                --[[
                local a = gold / 10000
                local af = math.floor(a)
                if a - af >= 0.5 then
                    gold = (af + 1) * 10000
                else
                    gold = af * 10000
                end
                ]]
                rr[k] = gold
            else
                rr[k] = v
            end
        end

        owner:get_rewards(rr, reason)
        self:GetArenaRewardInfo()
        self:ShowTextID(arena_text_id.SCORS_REWARD_RECV_SUC)
    end
end

function ArenaSystem:Challenge(t)
    --挑战条件控制
    if self.m_state == 1 then
        return
    end
    local owner = self.ptr.theOwner

    local time = os.time()
    if owner.arenicData[arenicDataKey.avatar_cdEndTime] and owner.arenicData[arenicDataKey.avatar_cdEndTime] > time then
        self:ShowTextID(arena_text_id.CHALLENGE_CDING)
        return
    end
    
    if self.m_systemData[arenicDataKey.tmp_challengeTimes] >= g_arena_config.CHALLENGE_TIME_PER_DAY then
        if not owner.arenicData[arenicDataKey.avatar_buyTimes] or owner.arenicData[arenicDataKey.avatar_buyTimes] <= 0 then
            self:ShowTextID(arena_text_id.NO_ENTER_TIMES)
            return
        end
    end

    if t == pvp_type_weak then
        local the_weak_id = owner.arenicData[arenicDataKey.avatar_weak]
        if the_weak_id and the_weak_id > 0 then
            self:Pvp(the_weak_id, t)
            owner.arenicData[arenicDataKey.avatar_weak] = 0
            self:ResetWeak(false)
            return
        end
        --log_game_error("ArenaSystem:Challenge", "challenge weak.")
        self:ShowTextID(arena_text_id.NO_WEAK_FOE)
    elseif t == pvp_type_strong then
        local the_strong_id = owner.arenicData[arenicDataKey.avatar_strong]
        if the_strong_id and the_strong_id > 0 then
            self:Pvp(the_strong_id, t)
            owner.arenicData[arenicDataKey.avatar_strong] = 0
            self:ResetStrong(false)
            return
        end
        --log_game_error("ArenaSystem:Challenge", "challenge Strong Foe")
        self:ShowTextID(arena_text_id.NO_STRONG_FOE)
    elseif t == pvp_type_enemy then
        if self.m_systemData[arenicDataKey.tmp_beatEnemy] ~= 0 then
            self:ShowTextID(arena_text_id.ENEMY_BEATED)
            return
        end
        --todo：减少次数，增加cd
        if self.m_systemData[arenicDataKey.tmp_theEnemy] > 0 then
            self:Pvp(self.m_systemData[arenicDataKey.tmp_theEnemy], t)
            return
        end
        self:ShowTextID(arena_text_id.NO_ENEMY)
        return
    end
end

function ArenaSystem:Pvp(theDbid, pvpType)
    local owner = self.ptr.theOwner
    owner.pvpDbid = theDbid
    local pvpInfo = 
    {
        ['pvpType'] = pvpType,
        ['defier'] = theDbid,
        ['arenicGrade'] = owner.arenicGrade,
        ['challenger'] = owner.dbid,
        ['challengerName'] = owner.name,
        ['level'] = owner.level,
    }
    
    --[[if pvpType == 3 then
        local bufId = owner.arenicData[arenicDataKey.avatar_inspire_buf]
        if bufId and bufId > 0 then
            pvpInfo['bufId'] = bufId
        end
    end]]
    local mm = globalBases["MapMgr"]
    if mm then
        self.m_state = 1
        mm.CreateMirrorPvpMapInstance(owner.base_mbstr, 41000, pvpInfo)
        --mm.SelectMapReq(owner.base_mbstr, 41000, 0, owner.dbid, owner.name)
    end
end

function ArenaSystem:HavedEnter(ret_info)
    --self.m_state = 0
    if ret_info.ret ~= 0 then
        self:ShowTextID(arena_text_id.MAP_CHANGE_FAILED)
        return
    end
    local owner = self.ptr.theOwner
    if self.m_systemData[arenicDataKey.tmp_challengeTimes] >= g_arena_config.CHALLENGE_TIME_PER_DAY then
        owner.arenicData[arenicDataKey.avatar_buyTimes] = owner.arenicData[arenicDataKey.avatar_buyTimes] or 0
        owner.arenicData[arenicDataKey.avatar_buyTimes] = owner.arenicData[arenicDataKey.avatar_buyTimes] - 1
    end
    if owner.arenicData[arenicDataKey.avatar_buyTimes] < 0 then
        log_game_error("ArenaSystem:HavedEnter", "buyTimes[%d]", owner.arenicData[arenicDataKey.avatar_buyTimes])
        owner.arenicData[arenicDataKey.avatar_buyTimes] = 0
    end
    self.m_systemData[arenicDataKey.tmp_challengeTimes] = self.m_systemData[arenicDataKey.tmp_challengeTimes] + 1
    local mm = globalBases['ArenaMgr']
    if mm then
        mm.AddChallengeTime(owner.dbid, 1, owner.level)
    end
    --owner.arenicData[arenicDataKey.avatar_cdEndTime] = os.time() + g_arena_config.CHALLENGE_CD

    if ret_info.pvpType == pvp_type_enemy then
        local bufId = owner.arenicData[arenicDataKey.avatar_inspire_buf]
        if bufId and bufId > 0 then
            log_game_debug("ArenaSystem:HavedEnter", "AddBuff")
            owner.cell.AddBuff(bufId)
            owner.arenicData[arenicDataKey.avatar_inspire_buf] = 0
        end
    end

    self:RefreshArenaData()
    --更新竞技场镜像
    owner:OnUpdateUserMgrData(true)
end

function ArenaSystem:SetArenicData(data)
    for k,v in pairs(data) do
        self.m_systemData[k] = v
    end
    if self.entered ~= 0 then
        self:RefreshArenaData()
    end
end

function ArenaSystem:SetWeakFoes(foes, range)
    self.m_systemData[arenicDataKey.tmp_weakFoes] = foes
    self.m_systemData[arenicDataKey.tmp_weakFoesRange] = range
    local owner = self.ptr.theOwner
    if #foes < 1 then
        --self.m_systemData[arenicDataKey.tmp_theWeakFoe] = 0
        return
    end
    local the_weak = owner.arenicData[arenicDataKey.avatar_weak]
    if not the_weak or the_weak == 0 then
        local t = math.random(1, #foes)
        if foes[t] then
            --self.m_systemData[arenicDataKey.tmp_theWeakFoe] = foes[t]
            owner.arenicData[arenicDataKey.avatar_weak] = foes[t]
            table.remove(self.m_systemData[arenicDataKey.tmp_weakFoes], t)
            owner.arenicData[arenicDataKey.avatar_weakRange] = range
            if self.entered ~= 0 then
                self:RefreshArenaData()
            end
            --self.ptr.theOwner.client.RefreshWeakResp(foes[t])
            if self.entered ~= 0 then
                self:GiveWeakFoesDetailToClient()
            end
        end
    end
end

function ArenaSystem:SetEnemy(enemys)
    if #enemys < 1 then
        self.m_systemData[arenicDataKey.tmp_theEnemy] = 0
    else
        self.m_systemData[arenicDataKey.tmp_theEnemy] = enemys[1]
    end
    if self.entered ~= 0 then
        self:GiveEnemyDetailToClient()
    end
end

function ArenaSystem:SetStrongFoes(foes, range)
    self.m_systemData[arenicDataKey.tmp_strongFoes] = foes
    self.m_systemData[arenicDataKey.tmp_strongFoesRange] = range
    local owner = self.ptr.theOwner
    if not next(foes) then
        --self.m_systemData[arenicDataKey.tmp_theStrongFoe] = 0
        return
    end
    local the_strong = owner.arenicData[arenicDataKey.avatar_strong]
    if not the_strong or the_strong == 0 then
        local t = math.random(1, #foes)
        if foes[t] then
            --self.m_systemData[arenicDataKey.tmp_theStrongFoe] = foes[t]
            owner.arenicData[arenicDataKey.avatar_strong] = foes[t]
            table.remove(self.m_systemData[arenicDataKey.tmp_strongFoes], t)
            owner.arenicData[arenicDataKey.avatar_strongRange] = range
            --self.ptr.theOwner.client.RefreshStrongResp(foes[t])
            if self.entered ~= 0 then
                self:RefreshArenaData()
            end
            if self.entered ~= 0 then
                self:GiveStrongFoesDetailToClient()
            end
        end
    end
end

-------------------------------------------------以下不是RPC接口

--登录，从竞技场全局管理器获取数据
function ArenaSystem:Login()
    local owner = self.ptr.theOwner
    local mm = globalBases["ArenaMgr"]
    if mm then
        mm.Login(owner.base_mbstr, owner.dbid, owner.fightForce, owner.level)
        self.dated = 0
    end
end

function ArenaSystem:SendFoeDetailDown(detail_info)
    local owner = self.ptr.theOwner
    if detail_info[7] == pvp_type_weak then
        if self.m_reChoose[1] == 0 then
            local range = owner.arenicData[arenicDataKey.avatar_weakRange]
            if detail_info[4] > range[1] or detail_info[4] < range[2] then
                self:ResetWeak(false)
                self.m_reChoose[1] = 1
                return
            end
        end
        if owner:hasClient() then
            detail_info[7] = nil
            owner.client.RefreshWeakResp(detail_info)
        end
    elseif detail_info[7] == pvp_type_strong then
        if self.m_reChoose[2] == 0 then
            local range = owner.arenicData[arenicDataKey.avatar_strongRange]
            if detail_info[4] > range[1] or detail_info[4] < range[2] then
                self:ResetStrong(false)
                self.m_reChoose[2] = 1
            end
        end
        if owner:hasClient() then
            detail_info[7] = nil
            owner.client.RefreshStrongResp(detail_info)
        end
    elseif detail_info[7] == pvp_type_enemy then
        if owner:hasClient() then
            detail_info[7] = nil
            owner.client.RefreshRevengeResp(detail_info)
        end
    else
        log_game_error("ArenaSystem:SendFoeDetailDown", "")
    end
end

function ArenaSystem:GiveWeakFoesDetailToClient()
    --self.ptr.theOwner.client.RefreshWeakResp(weakFoes[t])
    local owner = self.ptr.theOwner
    local the_weak_id = owner.arenicData[arenicDataKey.avatar_weak]
    --self.m_systemData[arenicDataKey.tmp_theWeakFoe] == 0
    if not the_weak_id or the_weak_id == 0 then
        log_game_warning("ArenaSystem:GiveWeakFoesDetailToClient", "no weak foe.")
        return
    end
    local mm = globalBases["UserMgr"]
    if mm then
        --前端展示的数据格式
        local lFormat = 
        {
            public_config.USER_MGR_PLAYER_NAME_INDEX,
            public_config.USER_MGR_PLAYER_LEVEL_INDEX,
            public_config.USER_MGR_PLAYER_VOCATION_INDEX,
            public_config.USER_MGR_PLAYER_ARENIC_FIGHT_RANK_INDEX,
            public_config.USER_MGR_PLAYER_ITEMS_INDEX,
            public_config.USER_MGR_PLAYER_ARENIC_GRADE_INDEX,
            pvp_type_weak, --该值不下发:1代表弱敌，2代表强敌，3代表仇敌
        }
        mm.SendArenicDetailToClient(
            self.ptr.theOwner.dbid, 
            the_weak_id,
            "SendFoeDetailDown",
            lFormat
            )
    end
end

function ArenaSystem:GiveStrongFoesDetailToClient()
    --self.ptr.theOwner.client.RefreshStrongResp(foes[t])
    local owner = self.ptr.theOwner
    local the_strong_id = owner.arenicData[arenicDataKey.avatar_strong]
    if not the_strong_id or the_strong_id == 0 then
        log_game_warning("ArenaSystem:GiveStrongFoesDetailToClient", "no strong foe.")
        return
    end
    local mm = globalBases["UserMgr"]
    if mm then
        --前端展示的数据格式
        local lFormat = 
        {
            public_config.USER_MGR_PLAYER_NAME_INDEX,
            public_config.USER_MGR_PLAYER_LEVEL_INDEX,
            public_config.USER_MGR_PLAYER_VOCATION_INDEX,
            public_config.USER_MGR_PLAYER_ARENIC_FIGHT_RANK_INDEX,
            public_config.USER_MGR_PLAYER_ITEMS_INDEX,
            public_config.USER_MGR_PLAYER_ARENIC_GRADE_INDEX,
            pvp_type_strong, --该值不下发:1代表弱敌，2代表强敌，3代表仇敌
        }
        mm.SendArenicDetailToClient(
            self.ptr.theOwner.dbid, 
            the_strong_id,
            "SendFoeDetailDown",
            lFormat
            )
    end
end

function ArenaSystem:GiveEnemyDetailToClient()
    if self.m_systemData[arenicDataKey.tmp_theEnemy] == 0 then
        log_game_warning("ArenaSystem:GiveEnemyDetailToClient", "no enemy.")
        return
    end
    local mm = globalBases["UserMgr"]
      if mm then
        --前端展示的数据格式
        local lFormat = 
        {
            public_config.USER_MGR_PLAYER_NAME_INDEX,
            public_config.USER_MGR_PLAYER_LEVEL_INDEX,
            public_config.USER_MGR_PLAYER_VOCATION_INDEX,
            public_config.USER_MGR_PLAYER_ARENIC_FIGHT_RANK_INDEX,
            public_config.USER_MGR_PLAYER_ITEMS_INDEX,
            public_config.USER_MGR_PLAYER_ARENIC_GRADE_INDEX,
            pvp_type_enemy, --该值不下发:1代表弱敌，2代表强敌，3代表仇敌
        }
        mm.SendArenicDetailToClient(
              self.ptr.theOwner.dbid, 
              self.m_systemData[arenicDataKey.tmp_theEnemy],
              "SendFoeDetailDown",
              lFormat
              )
      end
end

--显示浮动文字提示
function ArenaSystem:ShowTextID(textId)
    local owner = self.ptr.theOwner
    if owner:hasClient() then
        owner.client.ShowTextID(CHANNEL.TIPS, textId)
    end
end

function ArenaSystem:DataDated()
    self.dated = 1
    local arenicData = self.ptr.theOwner.arenicData
    if os.time() >= arenicData[arenicDataKey.avatar_DailyBuyCd] then
        arenicData[arenicDataKey.avatar_DailyBuys] = 0
        local t = lua_util.get_left_secs_until_next_hhmiss(0,0,0)
        arenicData[arenicDataKey.avatar_DailyBuyCd] = os.time() + t
        --arenicData[arenicDataKey.avatar_DailyBuyCd] = arenicData[arenicDataKey.avatar_DailyBuyCd] + 86400
    end
end

function ArenaSystem:GetRewards(rewards)
    self.m_state = 0
    local owner = self.ptr.theOwner

    owner:get_rewards(rewards, reason_def.arena_fight)
    --完成pvp竞技场事件
    owner:OnFinishPvP()
    --活动结束后再开启CD，开始挑战的时候也会开启一个，用于控制跳过CD刷竞技场
    owner.arenicData[arenicDataKey.avatar_cdEndTime] = os.time() + g_arena_config.CHALLENGE_CD
end

function ArenaSystem:AddCredit(value)
    self.m_state = 0
    local owner = self.ptr.theOwner
    owner:AddCredit(value)
end

function ArenaSystem:AddScore(value)
    self.m_state = 0
    self.m_systemData[arenicDataKey.tmp_scoresOfDay] = self.m_systemData[arenicDataKey.tmp_scoresOfDay] + value
    self.m_systemData[arenicDataKey.tmp_scoresOfWeek] = self.m_systemData[arenicDataKey.tmp_scoresOfWeek] + value
    local mm = globalBases['ArenaMgr']
    if mm then
        mm.AddScore(self.ptr.theOwner.dbid, value)
    end
    self:TriggerScoreEvent()
end

function ArenaSystem:BeatEnemy()
    self.m_systemData[arenicDataKey.tmp_beatEnemy] = 1
    local mm = globalBases['ArenaMgr']
    if mm then
        mm.MarkBeatEnemy(self.ptr.theOwner.dbid)
    end
end

function ArenaSystem:foe(var)
    local id = 0
    local owner = self.ptr.theOwner
    local flag = 0
    if var == 'weak' then
        id = owner.arenicData[arenicDataKey.avatar_weak]
        flag = pvp_type_weak
    elseif var == 'strong' then
        id = owner.arenicData[arenicDataKey.avatar_strong]
        flag = pvp_type_strong
    elseif var == 'enemy' then
        id = self.m_systemData[arenicDataKey.tmp_theEnemy]
        flag = pvp_type_enemy
    elseif var == 'self' then
        local msg = owner.name .. "begin====:"
        for k,v in pairs(owner.baseProps) do
            if k ~= 'vt' then
                msg = "<<" .. msg .. tostring(k) .. ':' .. tostring(v) .. ">> | "
            end
        end
        msg = msg .. '====end'
        return owner:ChatResp(public_config.CHANNEL_ID_PERSONAL, owner.dbid, "GM", owner.level, msg)
    else
        return
    end
    if id < 1 then return end
    local mm = globalBases['UserMgr']
    if mm then
        mm.foe(owner.dbid, id, flag)
    end
end