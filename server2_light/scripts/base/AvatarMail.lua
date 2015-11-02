--author:hwj
--date:2013-05-03
--此为Avatar扩展类,只能由Avatar require使用
--避免Avatar.lua文件过长
require "MailMgr"
--require "MailSystem"

local log_game_debug = lua_util.log_game_debug
-->邮件子系统begin
--test
local globalbase_call = lua_util.globalbase_call

--函数命名规则带_开始的只能由entity调用，其他的可以rpc调用
--由EventDispatch转发进来
function Avatar:_LoginMailMgr()
	local mm = globalBases['MailMgr']
	if mm then
		if self.mail_tag == 0 then
			self.mail_tag = self.createTime
		end
		mm.Login(self.base_mbstr, self.dbid, self.mail_tag)
		self.mail_tag = os.time()
	end
end
--------------------------------------------------------------------
--mail_mgr返回所有邮件的简单信息
function Avatar:OnMailInfoReq(smp_mails)
	if self:hasClient() then
		self.client.OnMailInfoResp(smp_mails)
	end
end
function Avatar:OnMailReadReq(mail,err_id)
	if self:hasClient() then
		self.client.OnMailReadResp(mail, err_id)
	end
end
function Avatar:OnMailDelReq()
	--触发前端关闭窗口
	if self:hasClient() then
		self.client.OnMailDelResp(0)
	end
end
function Avatar:OnGetAttachInfo(mail)
	local items = {}
    for k,v in pairs(mail.attachment) do
        if public_config.MAX_OTHER_ITEM_ID < k then
            items[k] = v
        end
    end
    if not self.inventorySystem:SpaceForItems(items) then
        self:ShowTextID(CHANNEL.TIPS, mailTextId.MAIL_GET_ATTA_BAG_FULL)
        return
    end
    local mm = globalBases['MailMgr']
	if mm then
		--self.mailSystem:RecvAttachment(mailId)
		mm.RecvAttach(self.base_mbstr, self.dbid, mail.id)
	end
end
--[[
EXP_ID                  = 1,  --经验
GOLD_ID                 = 2,  --金币
DIAMOND_ID              = 3,  --钻石
VIP_ID                  = 4,  --vip卡
CUBE_ID                 = 5,  --特殊宝箱
ENERGY_ID               = 6,  --体力
BUFF_ID                 = 7,  --buff
GUILD_CARD_ID           = 8,  --公会招募卡
ARENA_CREDIT            = 11, --竞技场荣誉
ARENA_SCORE             = 12, --竞技场积分
]]
function Avatar:OnMailAttachGetReq(mail)
	--真正领取
    local reason = mail.reason or reason_def.mail --如果邮件无reason，默认邮件
    self:get_rewards(mail.attachment, reason)
    --[[
    for id,num in pairs(mail.attachment) do
        if public_config.EXP_ID == id then
            self:AddExp(num, reason)
        end
        if public_config.GOLD_ID == id then
            self:AddGold(num, reason)
        end
        if public_config.DIAMOND_ID == id then
            self:AddDiamond(num, reason)
        end
        --其他是物品
        if public_config.MAX_OTHER_ITEM_ID < id then
            self:AddItem(id, num, reason)
        end  
    end
    ]]
    --触发前端盖章
    if self:hasClient() then
        self.client.OnMailAttachGetResp(error_code.ERR_MAIL_SUCCEED)
    end
end
--在线收到邮件
function Avatar:OnRecvMail(smp_mail)
    if not self:hasClient() then return end
    self.client.OnReceiveMailResp(smp_mail)
end

function Avatar:OnSendAll(public_notice)
    local mm = globalBases["MailMgr"]
    if mm then
    	if self.mail_tag < public_notice.mail_time then
    		self.mail_tag = public_notice.mail_time
    	end
        mm.OnSendAll(self.dbid,public_notice)
    end
end
function Avatar:OnMailMgrCB(txt_id)
  if self:hasClient() then
    self:ShowTextID(CHANNEL.TIPS, txt_id)
  end
end
--------------------------------------------------------------------
--申请邮件信息
function Avatar:MailInfoReq()
	local mm = globalBases['MailMgr']
	if mm then
		--self.mailSystem:MailInfoReq()
		mm.MailInfoReq(self.base_mbstr, self.dbid,self.mail_tag)
	end
end

--申请阅读邮件信息
function Avatar:MailReadReq( mailId )
	local mm = globalBases['MailMgr']
	if mm then
		--self.mailSystem:ReadReq(mailId)
		mm.Read(self.base_mbstr, self.dbid, mailId)
	end
end

--申请删除邮件信息
function Avatar:MailDelReq( mailId )
	local mm = globalBases['MailMgr']
	if mm then
		--self.mailSystem:Del(mailId)
		mm.Del(self.base_mbstr, self.dbid, mailId)
	end
end

function Avatar:MailDelAllReq()
	local mm = globalBases['MailMgr']
	if mm then
		--self.mailSystem:DelAll()
		mm.DelAll(self.base_mbstr, self.dbid)
	end
end

--申请领取邮件附件
function Avatar:MailAttachGetReq(mailId)
	local mm = globalBases['MailMgr']
	if mm then
		--self.mailSystem:RecvAttachment(mailId)
		mm.GetAttachInfo(self.base_mbstr, self.dbid, mailId)
	end
end

--被动的被UserMgr调用
function Avatar:MailBeRpcRelayCall( MsgId, InfoItem )
	if MsgId == msgUserMgr.MSG_USER_MAIL_RECEIVE then
		log_game_debug('Avatar:MailBeRpcRelayCall', 'MSG_USER_MAIL_RECEIVE')
		--self.mailSystem:Recv(InfoItem)
		self:OnRecvMail(InfoItem)
	elseif MsgId == msgUserMgr.MSG_USER_MAIL_RECV_PUBLIC then
    self:OnSendAll(InfoItem)
  else
		return false
	end
	return true
end

function Avatar:JewlMailReq()
	local mm = globalBases['MailMgr']
	if mm then
		mm.JewlMailReq(self.base_mbstr, self.dbid)
	end
end

function Avatar:TestSystemMail()
	local time = os.time()
	local dbids = {self.dbid}
	local mm = globalBases["MailMgr"]
	if mm then
		--MailMgr:SendEx(til, name, txt, frm, time, attachment, dbids, reason)
		local reward = g_sanctuary_defense_mgr:GetDayRankReward(1)
		local attachment = {}
        if reward.exp and reward.exp > 0 then
            attachment[public_config.EXP_ID] = reward.exp
        end
        if reward.gold and reward.gold > 0 then
            attachment[public_config.GOLD_ID] = reward.gold
        end
        if reward.items then
            for k,v in pairs(reward.items) do
                attachment[k] = v
            end
        end
		mm.SendIdEx(reward.mailTitle, self.name, reward.mailText, 
            reward.mailFrom, time, attachment, dbids, {tostring(1)}, reason_def.wb_day_rank)
	end
	--MailMgr:SendSystemMail(title, to, text, from, time, attachment, dbids)
	--globalbase_call("MailMgr", "SendAll", title, to, text, from, time, attachment)
end
--------------------------------------------------------------------------------------
--[[
function Avatar:TestSystemMail( title, to, text, from )
	local time = os.time()
	local attachment = {[10001] = 5,}
	--local dbids = {[1] = 1}
	--globalbase_call("MailMgr", "Send", title, to, text, from, time, attachment, dbids)
	--MailMgr:SendSystemMail(title, to, text, from, time, attachment, dbids)
	globalbase_call("MailMgr", "SendAll", title, to, text, from, time, attachment)
end
--OfflineMgr回调
function Avatar:MailOfflineMgrCallback(MsgId, dbid, PlayerInfo, err)
	log_game_debug('MailOfflineMgrCallback', 'MsgId = %d', MsgId)
	if MsgId == msgOfflineMgr.MSG_OFFLINE_MAIL_SUB_SYSTEM then
		--self.client.OnMailInfoResp(PlayerInfo)
		self.mailSystem:SendAllMailInfoToClient(PlayerInfo, err)
	elseif MsgId == msgOfflineMgr.MSG_OFFLINE_MAIL_DEL then
		--触发前端关闭窗口
		self.client.OnMailDelResp(err)
		--刷新下前端邮件数据
		self.mailSystem:MailInfoReq()
	elseif MsgId == msgOfflineMgr.MSG_OFFLINE_MAIL_ATTACHMENT_GET then
		--todo：操作背包或者金币等
		if err == error_code.ERR_MAIL_SUCCEED then
			self.mailSystem:GetAttachment(PlayerInfo)
		end
		self.client.OnMailAttachGetResp(err)
	else
		return false
	end
	return true
end

--被动的被UserMgr调用
function Avatar:MailBeRpcRelayCall( MsgId, InfoItem )
	if MsgId == msgUserMgr.MSG_USER_MAIL_RECEIVE then
		log_game_debug('Avatar:MailBeRpcRelayCall', 'MSG_USER_MAIL_RECEIVE')
		self.mailSystem:Recv(InfoItem)
	else
		return false
	end
	return true
end

--MailMgr回调
function Avatar:MailMailMgrCallback( msgId, mail, mailId, err )
	if msgId == msgMailMgr.MSG_MAIL_MGR_GET_MAIL then
		--self.client.OnMailReadResp(mail, err)
		self.mailSystem:SendMailToClient(mail, mailId, err)
	else
		return false
	end
	return true
end

--申请邮件信息
function Avatar:MailInfoReq()
--	log_game_debug('Avatar:MailInfoReq','')
	self.mailSystem:MailInfoReq()
end

--申请阅读邮件信息
function Avatar:MailReadReq( mailId )
	self.mailSystem:ReadReq(mailId)
end

--申请删除邮件信息
function Avatar:MailDelReq( mailId )
	self.mailSystem:Del(mailId)
end

function Avatar:MailDelAllReq()
	self.mailSystem:DelAll()
end

--申请领取邮件附件
function Avatar:MailAttachGetReq( mailId )
	--self.mailSystem:ReceiveAttachment(mailId)
	self.mailSystem:RecvAttachment(mailId)
end
]]

-------------------------------------------------------------------