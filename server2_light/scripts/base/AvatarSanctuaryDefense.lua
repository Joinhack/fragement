--author:hwj
--date:2013-07-01
--此为Avatar扩展类,只能由Avatar require使用
--避免Avatar.lua文件过长
--圣域守卫战，即世界boss
require "reason_def"

local log_game_debug = lua_util.log_game_debug
local log_game_warning = lua_util.log_game_warning
local log_game_info = lua_util.log_game_info
local log_game_error = lua_util.log_game_error

--下次开启时间，正在开启，返回0
function Avatar:SanctuaryDefenseTimeReq()
	local mm = globalBases['WorldBossMgr']
	if mm then
		mm.GetNextStartTime(self.base_mbstr, self.dbid)
	end
end

--进入
function Avatar:EnterSanctuaryDefenseReq()
	local mm = globalBases['WorldBossMgr']
	if mm then
		mm.Enter(self.base_mbstr, self.dbid, self.name, self.level, self.VipLevel)
		--数据中心数据采集
		self:OnFinishSantuaryDefense()
	end
end
--申请我游戏数据
function Avatar:SantuaryDefenseMyInfoReq()
	local mm = globalBases['WorldBossMgr']
	if mm then
		mm.GetMyInfo(self.base_mbstr, self.dbid,self.name,self.level)
	end
end

--排行榜申请
function Avatar:SanctuaryDefenseRankReq()
	log_game_debug("Avatar:SanctuaryDefenseRankReq", "self.dbid = %q", self.dbid)
	local mm = globalBases['WorldBossMgr']
	if mm then
		mm.GetRankingList(self.base_mbstr, self.dbid)
	end
end

--buyEnterTime
function Avatar:BuySanctuaryDefenseTimeReq()
	local mm = globalBases['WorldBossMgr']
	if mm then
		mm.BuyEnterTimeReq(self.base_mbstr, self.dbid, self.VipLevel)
	end
end
function Avatar:OnSanctuaryDefenseBuy(err, diamond, gold)
	log_game_debug("Avatar:OnSanctuaryDefenseBuy", "err = %d", err)
	if err ~= error_code.ERR_WB_BUY_CAN then
		--self.client.BuySanctuaryDefenseTimeResp(err)
		return
	end
	--ERR_WB_BUY_NO_MONEY
	if self.gold < gold or self.diamond < diamond then
		--self.client.BuySanctuaryDefenseTimeResp(error_code.ERR_WB_BUY_NO_MONEY)
		self.client.ShowTextID(CHANNEL.TIPS, g_text_id.WB_BUY_NO_MONEY)
		return
	end
	if gold > 0 then
		self:AddGold(-gold, reason_def.wb_buy)
	end
	if diamond > 0 then
		self:AddDiamond(-diamond, reason_def.wb_buy)
	end
	local mm = globalBases['WorldBossMgr']
	if mm then
		mm.AddBuyTime(self.base_mbstr, self.dbid, self.name, self.level, self.VipLevel)
	end
	--self.client.BuySanctuaryDefenseTimeResp(err)
	self.client.ShowTextID(CHANNEL.TIPS, g_text_id.WB_BUY_CAN)
end

--canBuyEnterTime
function Avatar:CanBuySanctuaryDefenseTimeReq()
	--CanBuyEnterInfo(mbStr, dbid, viplevel)
	local mm = globalBases['WorldBossMgr']
	if mm then
		mm.CanBuyEnterInfo(self.base_mbstr, self.dbid, self.VipLevel)
	end
end

--
function Avatar:OnSanctuaryDefenseReward(rewards, weekRank)
	--AddGold(value, reason)
	--AddItem(id, num, reason)
	--AddExp(addExp, condition)
	local mm = globalBases["MailMgr"]
    if not mm then
        log_game_error("Avatar:OnSanctuaryDefenseReward", "no MailMgr mailbox.")
    end
    local time = os.time()
    for i, info in ipairs(rewards) do
        local att = {}
        if info.exp and info.exp > 0 then
            self:AddExp(info.exp, reason_def.wb_contribution)
        end
        if info.gold and info.gold > 0 then
            self:AddGold(info.gold, reason_def.wb_contribution)
        end
        if info.items then
        	local attachment = {}
            for id, num in pairs(info.items) do
                if 0 ~= self:AddItem(id, num, reason_def.wb_contribution) then
                	attachment[id] = num
                end
            end

            if lua_util.get_table_real_count(attachment) > 0 then
            	--todo:mail
            	if mm then
            		mm.SendIdEx(info.mailTitle, self.name, info.mailText, 
            			info.mailFrom, time, attachment, {self.dbid}, 
            			{tostring(rewards.contribution)}, reason_def.wb_contribution)
            	end
            end
        end
        info.mailTitle = nil
        info.mailText = nil
        info.mailFrom = nil
    end
    log_game_debug("Avatar:OnSanctuaryDefenseReward", mogo.cPickle(rewards))
    if self:hasClient() then
		self.client.OnSanctuaryDefenseRewardResp(rewards, weekRank)
	end
end

function Avatar:sd_open(openTime, startTime, endTime)
	log_game_debug("Avatar:sd_open", "")
	local mm = globalBases['WorldBossMgr']
	if mm then
		mm.GMOpen(openTime, startTime, endTime)
	end
end

function Avatar:SanctuaryLogin(mbStr)
	local mm = globalBases['WorldBossMgr']
	if mm then
		mm.SanctuaryLogin(mbStr)
	end
end

function Avatar:SanctuaryNotice(msg)
	if msg == 1 and self:hasClient() then
		self.client.OnSanctuaryStartResp()
	end
end

function Avatar:GetWeekCtrbuRewardReq(id)
	return lua_util.globalbase_call('WorldBossMgr','GetWeekCtrbuRewardReq',self.base_mbstr,self.dbid,id)
end

function Avatar:OnWorldBossWeekCtrbuRewardResp(id,rewards)
	self:get_rewards(rewards,reason_def.wb_contribution)
	--触发盖章
	if self:hasClient() then
		self.client.GetWeekCtrbuRewardResp(id)
		--飘文字
		self:ShowTextID(CHANNEL.TIPS,g_text_id.WB_CTRBU_REWARD_SU)
	end
end
