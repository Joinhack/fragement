--author:hwj
--date:2013-5-2
--此为邮件管理中心，需要在加载离线管理器之后加载
require "mail_config"
require "lua_util"
require "public_config"
require "error_code"

local log_game_debug = lua_util.log_game_debug
local log_game_warning = lua_util.log_game_warning
local log_game_info = lua_util.log_game_info
local log_game_error = lua_util.log_game_error
local globalbase_call = lua_util.globalbase_call
local confirm                  = lua_util.confirm

local max_title_len = 20 --前端UI只显示12个字节
local max_from_len = 10
local max_to_len = 20
local max_text_len = 300

--下发邮件信息格式转换
local function formatSimpleInfo(src,des)
    des[1] = src.id --int
    des[2] = src.from   --string
    des[3] = src.title  --string
    des[4] = src.state  --int
    des[5] = src.mail_type or public_config.MAIL_TYPE_TEXT  --int
    des[6] = src.time   --int
end
--与前端接收的数据结构保持一致
local function formatDetailInfo(src,des)
    local attachItemIds = {}
    local attachNums = {}
    for k,v in pairs(src.attachment) do
        table.insert(attachItemIds, k)
        table.insert(attachNums, v)
    end
    des[1]  = src.title
    des[2]  = src.name
    des[3]  = src.text
    des[4]  = src.from
    des[5]  = src.time
    des[6]  = attachItemIds
    des[7]  = attachNums
    des[8]  = src.mail_type or public_config.MAIL_TYPE_TEXT
    des[9]  = src.extern_info or {}
    des[10] = src.state
    des[11] = src.id
end
--------------------邮件信息结构(用来通知在线前端收到一封新邮件)-----------------------
local Notice = {}
Notice.__index = Notice

function Notice:new(mail)
	local obj = {mail.id,mail.from,mail.title,mail.state,mail.mail_type,mail.time,}
	--[[
		[mailOfflineItemIndex.mailId]     = mail.id,
        [mailOfflineItemIndex.from]       = mail.from,
        [mailOfflineItemIndex.title]      = mail.title,
        [mailOfflineItemIndex.state]      = mail.state, 
        [mailOfflineItemIndex.attachment] = mail.attachment,
        [mailOfflineItemIndex.timeout]    = mail.timeout,
        [mailOfflineItemIndex.mailType]   = mail.mail_type,
        [mailOfflineItemIndex.mailParam]  = mail.extern_info,
        [mailOfflineItemIndex.reason]     = mail.reason,
        [mailOfflineItemIndex.time]       = mail.time,
	}
	]]
	setmetatable(obj, {__index = Notice})
	return obj
end

local PublicNotice = {}
PublicNotice.__index = PublicNotice

function PublicNotice:new(mail)
	local obj = {
		mail_dbid     = mail.id,
        mail_time     = mail.time,
	}
	setmetatable(obj, {__index = PublicNotice})
	return obj
end
--------------------邮件管理中心-----------------------
MailMgr = {}

setmetatable( MailMgr, {__index = BaseEntity} )


function MailMgr:__ctor__()
	log_game_debug("MailMgr:__ctor__", "")
	--回调方法
	local function RegisterGloballyCB(ret)
		log_game_debug("RegisterGloballyCB", "MailMgr")
		if 1 == ret then
			--注册成功
            self:OnRegistered()
		else
			--注册失败
            log_game_error("MailMgr:RegisterGlobally error", '')
		end
	end
	self:RegisterGlobally("MailMgr", RegisterGloballyCB)
end

function MailMgr:OnRegistered()
	--load 公共邮件
	local sql = "SELECT id,sm_mail_type,sm_title,sm_name,sm_text,sm_from,sm_time,sm_timeout,sm_attachment,sm_reason,sm_state,sm_extern_info FROM tbl_mail_public WHERE sm_timeout > %s ORDER BY sm_time DESC "
	sql = string.format(sql,os.time())
	self:TableSelectSql("OnPublicLoad", "mail_public", sql)
end

function MailMgr:OnPublicLoad(rst)
	for _,mail in pairs(rst) do
		table.insert(self.public_mails,mail)
	end
	globalbase_call('GameMgr', 'OnMgrLoaded', 'MailMgr')
end

--last_time:最近一次领取群邮件的时间
function MailMgr:Login(mb_str, dbid, last_time)
	self.geting_list[dbid] = mb_str
	if not self.private_mails[dbid] then
		--load
		self.private_mails[dbid] = {}
	    --处理群邮件
	    self:HandlePublic(dbid, last_time)
		self:Load(dbid)
		return
	end
	--处理群邮件
	self:HandlePublic(dbid, last_time)
	--下发邮件信息
	self:SendAll2Client(dbid)
end

function MailMgr:MailInfoReq(mb_str,dbid,last_time)
	if self.geting_list[dbid] then return end
	self.geting_list[dbid] = mb_str
	if not self.private_mails[dbid] then
		--load
		self.private_mails[dbid] = {}
	    --处理群邮件
	    self:HandlePublic(dbid, last_time)
		self:Load(dbid)
		return
	end
	--下发邮件信息
	self:SendAll2Client(dbid)
end

function MailMgr:Read(mb_str, dbid, mail_dbid)
	local b,avatar,mails = self:CheckPlayer(mb_str,dbid)
	if not b then return end
  
    local mail = mails[mail_dbid]
	if not mail then
		avatar.OnMailReadReq({},error_code.ERR_MAIL_NOT_EXISTS)
		return
	end
    local ss = 0

    --标识已读取邮件
    if public_config.MAIL_STATE_NONE == mail.state then
        ss = public_config.MAIL_STATE_READ
    end
    if public_config.MAIL_STATE_HAVE == mail.state then
        ss = public_config.MAIL_STATE_HERE
    end

    if ss ~= 0 then
        mail.state = ss
        local sql = self:MakeUpdateSql(mail_dbid,"sm_state",ss)
        local function ExcCallBack(ret)
            if ret ~= 0 then
                log_game_error("MailMgr:Read", "mail_dbid = %q", mail_dbid)
            end
        end
        self:TableExcuteSql(sql, ExcCallBack)
    end
    local mail = {}
    formatDetailInfo(mails[mail_dbid],mail)
    avatar.OnMailReadReq(mail, error_code.ERR_MAIL_SUCCEED)
end

function MailMgr:Del(mb_str, dbid, mail_dbid)
	--防止重复点击发上来的请求
	if self.del_list[dbid] then return end
	local b,avatar,mails = self:CheckPlayer(mb_str,dbid)
	if not b then return end
	local mail = mails[mail_dbid]
	if not mail then
		avatar.OnMailMgrCB(mailTextId.MAIL_DEL_NOT_EXISTS)
		return
	end

	if mail.state == public_config.MAIL_STATE_HERE then
		avatar.OnMailMgrCB(mailTextId.MAIL_DEL_ATTA_HERE)
		return
	end

	if mail.state  == public_config.MAIL_STATE_NONE or 
		mail.state == public_config.MAIL_STATE_HAVE then
		avatar.OnMailMgrCB(mailTextId.MAIL_DEL_NOT_READ)
		return
	end

	local sql = self:MakeDeleteSql(mail_dbid)
	self.del_list[dbid] = true
    local function ExcCallBack(ret)
    	self.del_list[dbid] = nil
        if ret ~= 0 then
            log_game_error("MailMgr:Del", "mail_dbid = %q", mail_dbid)
        else
            mails[mail_dbid] = nil
            --触发前端关闭当前界面
            avatar.OnMailDelReq()
            --刷新
            self.geting_list[dbid] = mb_str
		    self:SendAll2Client(dbid)
            avatar.OnMailMgrCB(mailTextId.MAIL_DEL_SUCCEED)
        end
    end
    self:TableExcuteSql(sql, ExcCallBack)
end

function MailMgr:DelAll(mb_str, dbid)
	--防止重复点击发上来的请求
	if self.del_list[dbid] then return end
	local b,avatar,mails = self:CheckPlayer(mb_str,dbid)
	if not b then return end

	local del_ids = {}
    for mailId, mail in pairs(mails) do
        if  mail.state == public_config.MAIL_STATE_READ or 
            mail.state == public_config.MAIL_STATE_RECE then
            table.insert(del_ids,mailId)
        end
    end
    if #del_ids < 1 then
    	avatar.OnMailMgrCB(mailTextId.MAIL_DEL_ALL_NO)
        return
    end
    local sql = self:MakeDelAllSql(del_ids)
    local function ExcCallBack(ret)
    	self.del_list[dbid] = nil
        if ret ~= 0 then
            log_game_error("MailMgr:DelAll", "dbid = %q", dbid)
        else
            for _,mail_dbid in pairs(del_ids) do
            	mails[mail_dbid] = nil
            end
            --刷新
            self.geting_list[dbid] = mb_str
		    self:SendAll2Client(dbid)
		    avatar.OnMailMgrCB(mailTextId.MAIL_DEL_ALL_SUCCEED)
        end
    end
    self.del_list[dbid] = true
    self:TableExcuteSql(sql, ExcCallBack)    
end

function MailMgr:GetAttachInfo(mb_str, dbid, mail_dbid)
	--防止重复点击发上来的请求
	if self.recv_list[dbid] then return end
	local b,avatar,mails = self:CheckPlayer(mb_str,dbid)
	if not b then return end
	local mail = mails[mail_dbid]
	if not mail then
		avatar.OnMailMgrCB(mailTextId.MAIL_GET_ATTA_NOT_EXISTS)
		return
	end
	if mail.state == public_config.MAIL_STATE_RECE then
        avatar.OnMailMgrCB(mailTextId.MAIL_GET_ATTA_GETED)
        return
    end
    if  mail.state ~= public_config.MAIL_STATE_HAVE and 
        mail.state ~= public_config.MAIL_STATE_HERE then
        avatar.OnMailMgrCB(mailTextId.MAIL_GET_ATTA_NO_ATTA)
        return
    end

    if lua_util.get_table_real_count(mail.attachment) < 1 then
        avatar.OnMailMgrCB(mailTextId.MAIL_GET_ATTA_NO_ATTA)
        log_game_error("MailMgr:GetAttachInfo", "mail_dbid[%q]", mail_dbid)
        return
    end
    avatar.OnGetAttachInfo(mail)
end

function MailMgr:RecvAttach(mb_str, dbid, mail_dbid)
	--防止重复点击发上来的请求
	if self.recv_list[dbid] then return end
	local b,avatar,mails = self:CheckPlayer(mb_str,dbid)
	if not b then return end
	local mail = mails[mail_dbid]
	if not mail then
		avatar.OnMailMgrCB(mailTextId.MAIL_GET_ATTA_NOT_EXISTS)
		return
	end
	if mail.state == public_config.MAIL_STATE_RECE then
        avatar.OnMailMgrCB(mailTextId.MAIL_GET_ATTA_GETED)
        return
    end
    if  mail.state ~= public_config.MAIL_STATE_HAVE and 
        mail.state ~= public_config.MAIL_STATE_HERE then
        avatar.OnMailMgrCB(mailTextId.MAIL_GET_ATTA_NO_ATTA)
        return
    end

    if lua_util.get_table_real_count(mail.attachment) < 1 then
        avatar.OnMailMgrCB(mailTextId.MAIL_GET_ATTA_NO_ATTA)
        log_game_error("MailMgr:RecvAttach", "mail_dbid[%q]", mail_dbid)
        return
    end
    local sql = self:MakeUpdateSql(mail_dbid,"sm_state",public_config.MAIL_STATE_RECE)
    local function ExcCallBack(ret)
    	self.recv_list[dbid] = nil
        if ret ~= 0 then
            log_game_error("MailMgr:RecvAttach", "mail_dbid = %q", mail_dbid)
        else
            avatar.OnMailAttachGetReq(mail)
            mail.state = public_config.MAIL_STATE_RECE
            avatar.OnMailMgrCB(mailTextId.MAIL_GET_ATTA_SUCCEED)
        end
    end
    self.recv_list[dbid] = true
    self:TableExcuteSql(sql, ExcCallBack)
end

function MailMgr:SendEx(til, name, txt, frm, time, attachment, dbids, reason)
	self:Send(til, name, txt, frm, time, attachment, dbids, reason)
end

function MailMgr:SendIdEx(titleId, name, textId, fromId, time, attachment, dbids, params, reason)
	self:SendId(titleId, name, textId, fromId, time, attachment, dbids, params, reason)
end

function MailMgr:SendAllEx(til, name, txt, frm, time, attachment, reason)
	self:SendAll(til, name, txt, frm, time, attachment, reason)
end

function MailMgr:Load(dbid)
	local sql = self:MakeSelectSql(dbid)
	self:TableSelectSql("OnLoad", "mail_private", sql)
end

function MailMgr:OnLoad(rst)
	local dbid = 0
	for id,mail in pairs(rst) do
		dbid = mail.avatarDbid
    	mail.id = id
		self.private_mails[dbid][id] = mail
	end
  	if dbid ~= 0 then
    	self:SendAll2Client(dbid)
  	end
end

function MailMgr:HandlePublic(dbid, last_time)
	local m = #self.public_mails
	for i=m,1,-1 do
		local mail = self.public_mails[i]
		if mail.time > last_time then
			self:Send(mail.title, mail.name, mail.text, mail.from, mail.time, mail.attachment, {dbid}, mail.reason)
		end
	end
end

function MailMgr:SendAll2Client(dbid)
	local mb_str = self.geting_list[dbid]
	if not mb_str then return end
	local mb = mogo.UnpickleBaseMailbox(mb_str)

	self.geting_list[dbid] = nil
	
	if not mb then return end

	local smp_info = {}
	for mail_dbid, mail in pairs(self.private_mails[dbid]) do
		local t = {}
		formatSimpleInfo(mail, t)
		table.insert(smp_info,t)
	end
	mb.OnMailInfoReq(smp_info)
end

function MailMgr:CreateAMail(dbid, til, name, txt, frm, time, attachment, reason)
	local timeout = time + public_config.MAIL_TIMEOUT
	local state = public_config.MAIL_STATE_NONE
	if lua_util.get_table_real_count(attachment) > 0 then
		state = public_config.MAIL_STATE_HAVE
	end
    local mail = {
    	avatarDbid  = dbid,
        title       = tostring(til),
        name        = name,
        text        = tostring(txt),
        from        = tostring(frm),
        time        = time,
        attachment  = lua_util.deepcopy_1(attachment),
        timeout     = timeout,
        state       = state,
        mail_type   = public_config.MAIL_TYPE_TEXT,
        extern_info = {},
        reason      = reason,
    }
    return mail
end

function MailMgr:MakeUpdateSql(mail_dbid,field,value)
  local sql = "UPDATE tbl_mail_private SET %s = %s WHERE id = %s"
  if type(value) == 'string' then
    sql = "UPDATE tbl_mail_private SET %s = \"%s\" WHERE id = %s"
  end
	return string.format(sql,field,value,mail_dbid)
end

function MailMgr:MakeDelAllSql(mail_dbids)
	local sql = "DELETE FROM tbl_mail_private WHERE "
	local condition = " id = %s "
	local n = 0
	for _,mail_dbid in ipairs(mail_dbids) do
		local ss = condition
		if n ~= 0 then
			ss = " or " .. ss
		end
		sql = sql .. string.format(ss,mail_dbid)
    n = n + 1
	end
	return sql
end

function MailMgr:MakeDeleteSql(mail_dbid)
	local sql = "DELETE FROM tbl_mail_private WHERE id = %s"
	return string.format(sql,mail_dbid)
end

function MailMgr:MakeSelectSql(dbid)
	local sql = "SELECT id,sm_avatarDbid,sm_mail_type,sm_title,sm_name,sm_text,sm_from,sm_time,sm_timeout,sm_attachment,sm_reason,sm_state,sm_extern_info FROM tbl_mail_private WHERE sm_avatarDbid = %s"
	return string.format(sql,dbid)
end

function MailMgr:MakeInsertSql(mail)
	local sql = "INSERT INTO tbl_mail_private(sm_avatarDbid,sm_mail_type,sm_title,sm_name,sm_text,sm_from,sm_time,sm_timeout,sm_attachment,sm_reason,sm_state,sm_extern_info) VALUES(%s,%s,\"%s\",\"%s\",\"%s\",\"%s\",%s,%s,\"%s\",%s,%s,\"%s\")"
	return string.format(sql,
		mail.avatarDbid,
		mail.mail_type,
		mail.title,
		mail.name,
		mail.text,
		mail.from,
		mail.time,
		mail.timeout,
		mogo.cPickle(mail.attachment),
		mail.reason,
		mail.state,
		mogo.cPickle(mail.extern_info))
end

--被别的系统调用或gm使用
function MailMgr:Send(til, name, txt, frm, time, attachment, dbids, reason)
	--检查
	local title, from, to_name, text = self:Cut(til, frm, name, txt)
	local att = self:CheckAttachment(attachment, text)
	if not att then return end
	--入库
	for _, dbid in ipairs(dbids) do
		if next(att) then
			for i,v in ipairs(att) do
				--生成
				local mail = self:CreateAMail(dbid,title,to_name,text,from,time,v,reason)
				local sql  = self:MakeInsertSql(mail)
				local function OnInserted(id)
					if 0 == id then
						log_game_error("MailMgr:Send", "SaveCB failed.")
						return
					end
					mail.id = id
					--缓存中增加该邮件信息
				    if self.private_mails[dbid] then
				    	self.private_mails[dbid][id] = mail
				    end
					--发送给在线管理器去处理所有的系统邮件
					local notice = Notice:new(mail)
					globalbase_call('UserMgr', 'BroacastRpcToOthers', msgUserMgr.MSG_USER_MAIL_RECEIVE, notice, {mail.avatarDbid})		
				end
				self:TableInsertSql(sql, OnInserted)
			end
		else
			--生成
			local mail = self:CreateAMail(dbid,title,to_name,text,from,time,att,reason)
			local sql  = self:MakeInsertSql(mail)
			local function OnInserted(id)
				if 0 == id then
					log_game_error("MailMgr:Send", "SaveCB failed.")
					return
				end
				mail.id = id
				--缓存中增加该邮件信息
			    if self.private_mails[dbid] then
			    	self.private_mails[dbid][id] = mail
			    end
				--发送给在线管理器去处理所有的系统邮件
				local notice = Notice:new(mail)
				globalbase_call('UserMgr', 'BroacastRpcToOthers', msgUserMgr.MSG_USER_MAIL_RECEIVE, notice, {mail.avatarDbid})		
			end
			self:TableInsertSql(sql, OnInserted)
		end
	end
end

function MailMgr:SendId(titleId, name, textId, fromId, time, attachment, dbids, params, reason)
	--检查
	local att = self:CheckAttachment(attachment, text)
	if not att then return end

	--入库
	for _, dbid in ipairs(dbids) do
		if next(att) then
			for i,v in ipairs(att) do
				--生成
				local mail = self:CreateAMail(dbid,titleId,name,textId,fromId,time,v,reason)
				--填入参数
				mail.extern_info = lua_util.deepcopy_1(params)
				--改设类型为id类型
				mail.mail_type = public_config.MAIL_TYPE_ID
				local sql  = self:MakeInsertSql(mail)
				local function OnInserted(id)
					if 0 == id then
						log_game_error("MailMgr:Send", "SaveCB failed.")
						return
					end
					mail.id = id
					--缓存中增加该邮件信息
				    if self.private_mails[dbid] then
				    	self.private_mails[dbid][id] = mail
				    end
					--发送给在线管理器去处理所有的系统邮件
					local notice = Notice:new(mail)
					globalbase_call('UserMgr', 'BroacastRpcToOthers', msgUserMgr.MSG_USER_MAIL_RECEIVE, notice, {mail.avatarDbid})		
				end
				self:TableInsertSql(sql, OnInserted)
			end
		else
			--生成
			local mail = self:CreateAMail(dbid,titleId,name,textId,fromId,time,att,reason)
			--填入参数
			mail.extern_info = lua_util.deepcopy_1(params)
			--改设类型为id类型
			mail.mail_type = public_config.MAIL_TYPE_ID
			local sql  = self:MakeInsertSql(mail)
			local function OnInserted(id)
				if 0 == id then
					log_game_error("MailMgr:Send", "SaveCB failed.")
					return
				end
				mail.id = id
				--缓存中增加该邮件信息
			    if self.private_mails[dbid] then
			    	self.private_mails[dbid][id] = mail
			    end
				--发送给在线管理器去处理所有的系统邮件
				local notice = Notice:new(mail)
				globalbase_call('UserMgr', 'BroacastRpcToOthers', msgUserMgr.MSG_USER_MAIL_RECEIVE, notice, {mail.avatarDbid})		
			end
			self:TableInsertSql(sql, OnInserted)
		end
	end
end

function MailMgr:CreatePublicMail(til, name, txt, frm, time, attachment, reason)
	local timeout = time + public_config.MAIL_TIMEOUT
	local state = public_config.MAIL_STATE_NONE
	if lua_util.get_table_real_count(attachment) > 0 then
		state = public_config.MAIL_STATE_HAVE
	end
    local mail = {
        title       = tostring(til),
        name        = name,
        text        = tostring(txt),
        from        = tostring(frm),
        time        = time,
        attachment  = lua_util.deepcopy_1(attachment),
        timeout     = timeout,
        state       = state,
        mail_type   = public_config.MAIL_TYPE_TEXT,
        extern_info = {},
        reason      = reason,
    }

    return mail
end

function MailMgr:MakeInsertPublicSql(mail)
	local sql = "INSERT INTO tbl_mail_public(sm_mail_type,sm_title,sm_name,sm_text,sm_from,sm_time,sm_timeout,sm_attachment,sm_reason,sm_state,sm_extern_info) VALUES(%s,\"%s\",\"%s\",\"%s\",\"%s\",%s,%s,\"%s\",%s,%s,\"%s\")"
	return string.format(sql,
		mail.mail_type,
		mail.title,
		mail.name,
		mail.text,
		mail.from,
		mail.time,
		mail.timeout,
		mogo.cPickle(mail.attachment),
		mail.reason,
		mail.state,
		mogo.cPickle(mail.extern_info))
end

function MailMgr:SendAll(til, name, txt, frm, time, attachment, reason)
	--检查
	local title, from, to_name, text = self:Cut(til, frm, name, txt)
	local att = self:CheckAttachment(attachment, text)
	if not att then return end
	if next(att) then
		for i,v in ipairs(att) do
			--生成
			local mail = self:CreatePublicMail(title,to_name,text,from,time,v,reason)
			--标识为公用邮件
			local sql  = self:MakeInsertPublicSql(mail)
			local function OnInserted(id)
				if 0 == id then
					log_game_error("MailMgr:Send", "SaveCB failed.")
					return
				end
				mail.id = id
				--缓存中增加该邮件信息
				table.insert(self.public_mails, mail)
				--发送给在线管理器去处理所有的系统邮件
				local notice = PublicNotice:new(mail)
				globalbase_call('UserMgr', 'BroacastRpc', msgUserMgr.MSG_USER_MAIL_RECV_PUBLIC, notice)		
			end
			--入库
			self:TableInsertSql(sql, OnInserted)
		end
	else
		--生成
		local mail = self:CreatePublicMail(title,to_name,text,from,time,att,reason)
		--标识为公用邮件
		local sql  = self:MakeInsertPublicSql(mail)
		local function OnInserted(id)
			if 0 == id then
				log_game_error("MailMgr:Send", "SaveCB failed.")
				return
			end
			mail.id = id
			--缓存中增加该邮件信息
			table.insert(self.public_mails, mail)
			--发送给在线管理器去处理所有的系统邮件
			local notice = PublicNotice:new(mail)
			globalbase_call('UserMgr', 'BroacastRpc', msgUserMgr.MSG_USER_MAIL_RECV_PUBLIC, notice)		
		end
		--入库
		self:TableInsertSql(sql, OnInserted)
	end
end

--
function MailMgr:OnSendAll(dbid,public_notice)
	local mail = self:SearchPublicMail(public_notice.mail_dbid, public_notice.mail_time)
	if mail then
		self:Send(mail.title, mail.name, mail.text, mail.from, mail.time, mail.attachment, {dbid}, mail.reason)
	end
end

function MailMgr:SearchPublicMail(mail_dbid, mail_time)
	local m = #self.public_mails
	for i=m,1,-1 do
		local mail = self.public_mails[i]
		if mail.time < mail_time then
			return
		end
		if mail.id == mail_dbid then
			return mail
		end
	end
end

--附件格式的检查
function MailMgr:CheckAttachment(attachment, text)
	--confirm(type(attachment) == 'table', "邮件附件格式为table, 现在是%s, text[%s]", type(attachment), text)
	local n = 0
	local i = 0
	local att = {}
	local tmp = {}
	for k,v in pairs(attachment) do
		--confirm(type(k) == 'number', "邮件附件格式不对, key为id, 值是number, attachment[%s],text[%s]", mogo.cPickle(attachment), text)
		--confirm(type(v) == 'number', "邮件附件格式不对, key为id, 值是number, attachment[%s],text[%s]", mogo.cPickle(attachment), text)
		if type(k) ~= 'number' then
			attachment = {}
			return
		end
		if type(v) ~= 'number' then
			attachment = {}
			return
		end
		n = n + 1
		tmp[k] = v
		if n == 5 then
			i = i + 1
			att[i] = tmp
			tmp = {}
			n = 0
		end
	end
	if n > 0 then
		i = i + 1
		att[i] = tmp
	end
	--confirm(n < 6, "邮件附件个数不对, 最多不能超过5个, attachment[%s], text[%s]", mogo.cPickle(attachment), text)
	return att
end

function MailMgr:Cut(title, from, to, text)
	local til = lua_util.utf_str_cut(title, max_title_len)
	if #til < #title then
		til = til .. "..."
	end
	local frm = lua_util.utf_str_cut(from, max_from_len)
	if #frm < #from then
		frm = frm .. "..."
	end
	local to  = lua_util.utf_str_cut(to, max_to_len)
	local txt = lua_util.utf_str_cut(text, max_text_len)
	return til,frm,to,txt
end

function MailMgr:CheckPlayer(mb_str,dbid)
	local mb = mogo.UnpickleBaseMailbox(mb_str)
	if not mb then return false end

	local mails = self.private_mails[dbid]
	if not mails then return false end

	return true, mb, mails
end

function MailMgr:JewlMailReq(mb_str,dbid)
	local mb = mogo.UnpickleBaseMailbox(mb_str)
	if not mb then return false end
	local mails = self.private_mails[dbid]
	if not mails then return false end
	local t = 0
	local id = 0
	for mailId, mail in pairs(mails) do
        if  mail.state == public_config.MAIL_STATE_HAVE or 
            mail.state == public_config.MAIL_STATE_HERE then
            if (t == 0 or mail.time < t) then
            	for i,_ in pairs(mail.attachment) do
            		if g_jewel_mgr:GetJewelInfoById(i) then
            			t = mail.time
            			id = mailId
            			break
            		end
            	end
            end
        end
    end
    log_game_debug('MailMgr:JewlMailReq','id=%s',id)
    mb.client.JewlMailResp(id)
end

return MailMgr
