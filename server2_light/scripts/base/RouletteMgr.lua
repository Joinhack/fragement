--author:hwj
--date:2014-01-23
--抽奖管理器

require "lua_util"

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_error = lua_util.log_game_error
local mailbox_call = lua_util.mailbox_call
local mailbox_client_call = lua_util.mailbox_client_call
local globalbase_call = lua_util.globalbase_call

reward_type = {
    items = 1,
    times = 2,
    pool  = 3,
}

----------------------------------------------------------------------------------------------------
RouletteMgr = {}
RouletteMgr.__index = RouletteMgr
----------------------------------------------------------------------------------------------------

function RouletteMgr:__ctor__()
    log_game_info('RouletteMgr:__ctor__', '')

    if self:getDbid() == 0 then
        --首次创建
        --self.create_time = os.time()
        self:writeToDB(lua_util.on_basemgr_saved('RouletteMgr'))
    else
        self:RegisterGlobally("RouletteMgr", lua_util.basemgr_register_callback("RouletteMgr", self:getId()))
    end
end

--注册globalbase成功后回调方法
function RouletteMgr:OnRegistered()
    log_game_info("RouletteMgr:OnRegistered", "")
    self:registerTimeSave('mysql') --注册定时存盘
    ----预加载完成之后才能注册
    ----向GameMgr注册
    globalbase_call('GameMgr', 'OnMgrLoaded', 'RouletteMgr')
end

function RouletteMgr:Init()

    globalbase_call('GameMgr', 'OnInited', 'RouletteMgr')
end

--
function RouletteMgr:RouletteReq(mb_str,dbid,roule_id)
    local avatar = mogo.UnpickleBaseMailbox(mb_str)
    if not avatar then 
        log_game_error("RouletteMgr:RouletteReq","dbid=%q,mailbox is nil.",dbid)
        return 
    end
    
    --roulette
    local rew_id = self:Roulette(roule_id)
    if rew_id then
        --get rewards
        local rew_cfg = g_roulette_data:GetRewardCfg(rew_id)
        if rew_cfg then
            local rews = self:GetRewards(roule_id,rew_cfg) or {}
            avatar.OnRoulette(roule_id,rew_id,rews)
        end
    else
        log_game_error("RouletteMgr:RouletteReq","no rew_cfg.")
    end
end

function RouletteMgr:GetRewards(roule_id,rew_cfg)
    local rewards = {}
    if rew_cfg.reward_type == reward_type.items then
        local item_id, num = rew_cfg.arg1, rew_cfg.arg2
        rewards[item_id] = num      
    elseif rew_cfg.reward_type == reward_type.times then
        --add times    
        rewards.times = rew_cfg.arg1
    elseif rew_cfg.reward_type == reward_type.pool then
        --pool
        local pool = self.reward_pool[roule_id]
        if pool then
            for item_id,num in pairs(pool) do
                rewards[item_id] = math.floor(num * rew_cfg.arg1 / 10000)
            end
        end
    end
    return rewards
end


function RouletteMgr:Roulette(roule_id)
    local rewards = g_roulette_data:GetRouletteRewards(roule_id)
    local limit_rew = self.limit_rewards
    local now = os.time()
    if not limit_rew[roule_id] then
        limit_rew[roule_id] = {}
    end
    local lim = limit_rew[roule_id]
    for r_id,tt in pairs(lim) do
        if tt < now then
            limit_rew[roule_id][r_id] = nil
        end
    end
    
    local sum = 0
    local rews = {}
    for _,rew in pairs(rewards) do
        if not lim[rew.id] then
            table.insert(rews,rew)
            sum = sum + rew.chance
        end 
    end
    local n = math.random(1,sum)
    local tmp = 0
    for _,rew in ipairs(rews) do
        tmp = tmp + rew.chance
        if tmp >= n then
            --limit it
            if rew.limit and rew.limit == 1 then
                local at = math.random(rew.time[1]*3600,rew.time[2]*3600)
                limit_rew[roule_id][rew.id] = now + at
            end
            --add to pool
            local cfg = g_roulette_data:GetRouletteCfg(roule_id)
            if not self.reward_pool[roule_id] then
                self.reward_pool[roule_id] = {}
            end
            local pool_type = cfg.pool_type
            if not self.reward_pool[roule_id][pool_type] then
                self.reward_pool[roule_id][pool_type] = 0
            end
            for _,v in pairs(cfg.cost) do
                for a,b in pairs(cfg.pool_add) do
                    self.reward_pool[roule_id][pool_type] = self.reward_pool[roule_id][pool_type] + math.floor(v * b / a)
                end
                --pool limit
                if self.reward_pool[roule_id][pool_type] >= cfg.pool_limit then
                    self.reward_pool[roule_id][pool_type] = cfg.pool_limit
                    break 
                end
            end
            --get it
            return rew.id
        end
    end
end

function RouletteMgr:onDestroy()

end

return RouletteMgr