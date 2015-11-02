--author:hwj
--date:2014-01-27
--此为Avatar扩展类,轮盘抽奖相关接口,只能由Avatar require使用
--避免Avatar.lua文件过长

require "roulette_data"
local globalbase_call   = lua_util.globalbase_call
local log_game_debug    = lua_util.log_game_debug
local log_game_info     = lua_util.log_game_info
local log_game_warning  = lua_util.log_game_warning
local log_game_error    = lua_util.log_game_error

local txt_id = 
{
	err_no_cfg          = 10002,
	err_no_open         = 10003,
	err_is_end          = 10004,
	err_times_over      = 10005, --这个提示可以提示当前的vip等级对应次数


}

function Avatar:OpenUIReq()
	for _,v in pairs(self.dailyRouletteTimes) do
		local now = os.time()
    	if v.timeout < now then
    		v.timeout = lua_util.get_secs_until_next_hhmiss(0,0,0)
    		v.times = 0
    	end
	end
end

function Avatar:RouletteReq(roule_id)
	--检查配置
	local cfg = g_roulette_data:GetRouletteCfg(roule_id)
    if not cfg then
        return self:ShowTextID(CHANNEL.TIPS,txt_id.err_no_cfg)
    end
    --检查时间
    local now = os.time()
    if now < cfg.date_open then
        return self:ShowTextID(CHANNEL.TIPS,txt_id.err_no_open)
    end
    if now > cfg.date_end then
    	return self:ShowTextID(CHANNEL.TIPS,txt_id.err_is_end)
    end
    --
    if self:UseExtraTimes(roule_id) then
    	return
    end
    --check vip & times
    local the_roule_info = self.dailyRouletteTimes[roule_id]
    if not the_roule_info then
    	local timeout = lua_util.get_secs_until_next_hhmiss(0,0,0)
    	self.dailyRouletteTimes[roule_id] = {times=0,timeout=timeout}
    	the_roule_info = self.dailyRouletteTimes[roule_id]
    else
    	--update times
    	local now = os.time()
    	if the_roule_info.timeout < now then
    		the_roule_info.timeout = lua_util.get_secs_until_next_hhmiss(0,0,0)
    		the_roule_info.times = 0
    	end
    end
    local today_times = the_roule_info.times
    for vip,tim in pairs(cfg.times_limit) do
    	if vip == self.VipLevel then
    		if tim <= today_times then
    			return self:ShowTextID(CHANNEL.TIPS,txt_id.err_times_over)
    		end
    		break
    	end
    end

	local mm = globalBases['RouletteMgr']
	if mm then
		--cost,只能配一个，否则奖池的累积会出问题
		for k,v in pairs(cfg.cost) do
			if k == public_config.GOLD_ID then
				if self.gold < v then
					return self:ShowTextID(CHANNEL.TIPS,txt_id.err_gold)
				else
					self:AddGold(-v,reason_def.roulette)
				end
			elseif k == public_config.DIAMOND_ID then
				if self.diamond < v then
					return self:ShowTextID(CHANNEL.TIPS,txt_id.err_diamond)
				else
					self:AddDiamond(-v,reason_def.roulette)
				end
			else
				log_game_error("Avatar:RouletteReq",'cfg.cost is wrong.')
				return
			end
			break
		end
		mm.RouletteReq(self.base_mbstr,self.dbid,roule_id)
		the_roule_info.times = the_roule_info.times + 1
	end
end

function Avatar:UseExtraTimes(roule_id)
	local tt = self.extraDailyRouletteTimes[roule_id]
	if not tt or tt < 1 then return false end
	local mm = globalBases['RouletteMgr']
	if mm then
		mm.RouletteReq(self.base_mbstr,self.dbid,roule_id)
		self.extraDailyRouletteTimes[roule_id] = tt - 1
		return true
	end
end

--抽奖管理器回调
function Avatar:OnRoulette(roule_id,rew_id,rewards)
	for k,v in pairs(rewards) do
		if k == 'times' then
			--extra times
			local tt = self.extraDailyRouletteTimes[roule_id]
			if not tt then
				self.extraDailyRouletteTimes[roule_id] = v
			else
				self.extraDailyRouletteTimes[roule_id] = tt + v
			end
		else
			--items
			self:get_rewards(rewards,reason_def.roulette)
		end
	end
	if self:hasClient() then
		self.client.RouletteResp(roule_id,rew_id,rewards)
	end
end