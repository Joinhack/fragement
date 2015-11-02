--author:hwj
--date:2013-12-20
--此为Avatar扩展类,一些gm系统调用的接口可以放到该文件中来，只能由Avatar require使用
--避免Avatar.lua文件过长
local log_game_debug    = lua_util.log_game_debug
local log_game_warning  = lua_util.log_game_warning
local log_game_error    = lua_util.log_game_error
local globalbase_call   = lua_util.globalbase_call

function Avatar:GmSet(systemName, arg)
	if "arena" == systemName then
		if arg > 0 then
			self.gm_setting = Bit.Set(self.gm_setting, gm_setting_state.AREANA_STATE)
		else
			self.gm_setting = Bit.Reset(self.gm_setting, gm_setting_state.AREANA_STATE)
		end
	elseif "ranklist" == systemName then
		if arg > 0 then
			self.gm_setting = Bit.Set(self.gm_setting, gm_setting_state.RANKLIST_STATE)
		else
			self.gm_setting = Bit.Reset(self.gm_setting, gm_setting_state.RANKLIST_STATE)
		end
	--elseif 
	else
		log_game_warning("Avatar:GmSet","%s, %q",systemName, self.dbid)
	end
	--触发一些即时事件
	self:GmSetChangeEvent(systemName,arg)
end

function Avatar:GmSetChangeEvent(systemName,arg)
	if "arena" == systemName then
		if arg > 0 then
			log_game_debug("Avatar:GmSetChangeEvent","arena %q, set",self.dbid)
		else
			log_game_debug("Avatar:GmSetChangeEvent","arena %q, reset",self.dbid)
		end
	elseif "ranklist" == systemName then
		if arg > 0 then
			log_game_debug("Avatar:GmSetChangeEvent","ranklist %q, set",self.dbid)
		else
			log_game_debug("Avatar:GmSetChangeEvent","ranklist %q, reset",self.dbid)
		end
	--elseif 
	else
		log_game_warning("Avatar:GmSetChangeEvent","%s, %q",systemName, self.dbid)
	end
end

function Avatar:SetAccount(sys, id, stat)
    if "arena" == sys then
    	log_game_debug("Avatar:SetAccount","arena %q, set",self.dbid)
    	--local bitVal = math.pow(2, gm_setting_state.AREANA_STATE)
    	globalbase_call("UserMgr", "SetGMAccount", id, gm_setting_state.AREANA_STATE, stat, self.dbid, self.name) 
    elseif "ranklist" == sys then
    	log_game_debug("Avatar:SetAccount","dbid=%q;name=%s;system=%s;id=%q;stat=%d",self.dbid, self.name, sys, id, stat)
    	--local bitVal = math.pow(2, gm_setting_state.RANKLIST_STATE)
    	globalbase_call("UserMgr", "SetGMAccount", id, gm_setting_state.RANKLIST_STATE, stat, self.dbid, self.name)
    else
    	log_game_warning("Avatar:SetAccount","%s, %q",sys, self.dbid)
    end
end

function Avatar:gm_compensate()
	globalbase_call("mgr_compensate","Reload")
end

function Avatar:gm_charge(var,rmb)
	local acc = self.accountName
	local dbid = '0'
	if var ~= 0 then
		dbid = tostring(self.dbid)
	end
	local ord = tostring(os.time())
	local s_url = 'order_id=%s&game_id=1375328379751540&server_id=999&uid=%s&pay_way=1&amount=%s&callback_info=%s&order_status=S&failed_desc=&sign=5927751be595de7afc2d28f6fe91f58b&plat=0'
	local url = string.format(s_url,ord,acc,rmb,dbid)

	lua_util.globalbase_call('ChargeMgr','onChargeReq',0,'0',url)
end
--%s %s %d gm001,dbid,rmb dbid为零时就是充值到
function Avatar:gm_charge_ex(acc,dbid,rmb)
	local ord = tostring(os.time())
	local s_url = 'order_id=%s&game_id=1375328379751540&server_id=999&uid=%s&pay_way=1&amount=%s&callback_info=%s&order_status=S&failed_desc=&sign=5927751be595de7afc2d28f6fe91f58b&plat=0'
	local url = string.format(s_url,ord,acc,rmb,dbid)

	lua_util.globalbase_call('ChargeMgr','onChargeReq',0,'0',url)
end

function Avatar:add_week_score(var)
	lua_util.globalbase_call('WorldBossMgr','add_week_score',self.base_mbstr,self.dbid,var)
end