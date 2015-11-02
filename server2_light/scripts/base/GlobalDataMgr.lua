
--全局数据管理系统


require "lua_util"
require "lua_map"
require "public_config"
require "channel_config"
require "reason_def"


local log_game_info         = lua_util.log_game_info
local log_game_debug        = lua_util.log_game_debug
local log_game_error        = lua_util.log_game_error
local _readXml 	            = lua_util._readXml
local confirm               = lua_util.confirm
local globalbase_call       = lua_util.globalbase_call


GlobalDataMgr 	= {}
setmetatable(GlobalDataMgr, {__index = BaseEntity})


function GlobalDataMgr:__ctor__()
	log_game_debug("GlobalDataMgr:__ctor__", "")

    --当前正在处理的MailBoxStr
    self.nowMailBoxStr    = ""

    if self:getDbid() == 0 then
        --首次创建
        self:writeToDB(lua_util.on_basemgr_saved('GlobalDataMgr'))
    else
        self:RegisterGlobally("GlobalDataMgr", lua_util.basemgr_register_callback("GlobalDataMgr", self:getId()))
    end
end

function GlobalDataMgr:OnRegistered()
    log_game_debug("GlobalDataMgr:on_registered", "")
	
	self:registerTimeSave('mysql') --注册定时存盘
	
    globalbase_call('GameMgr', 'OnMgrLoaded', 'GlobalDataMgr')



    mogo.setBaseData("forbidden_ips", self.forbidden_ips)
    mogo.setBaseData("forbidden_accounts", self.forbidden_accounts)
   
end

function GlobalDataMgr:GetNowMailBox()
    if not self.nowMailBoxStr or mbStr == "" then return nil end
    return mogo.UnpickleBaseMailbox(self.nowMailBoxStr)
end

function GlobalDataMgr:GetNowMailBoxStr()
    return self.nowMailBoxStr
end

function GlobalDataMgr:MgrEventDispatch(mbStr, mgr_func_name, mgr_func_param_table, callback_sys_name, callback_func_name, callback_func_param_table)
    log_game_debug("GlobalDataMgr:MgrEventDispatch", "Execute!")

    if not mbStr then return end
    self.nowMailBoxStr = mbStr

    local a, b, c, d
	local theFunc = self[mgr_func_name]
    local theSize = lua_util.get_table_real_count(mgr_func_param_table)
    if theSize == 0 then 
        a, b, c, d = theFunc(self)
    elseif theSize == 1 then
        a, b, c, d = theFunc(self, mgr_func_param_table[1])
    elseif theSize == 2 then
        a, b, c, d = theFunc(self, mgr_func_param_table[1], mgr_func_param_table[2])
    elseif theSize == 3 then
        a, b, c, d = theFunc(self, mgr_func_param_table[1], mgr_func_param_table[2], mgr_func_param_table[3])
    elseif theSize == 4 then
        a, b, c, d = theFunc(self, mgr_func_param_table[1], mgr_func_param_table[2], mgr_func_param_table[3], mgr_func_param_table[4])
    elseif theSize == 5 then
        a, b, c, d = theFunc(self, mgr_func_param_table[1], mgr_func_param_table[2], mgr_func_param_table[3], mgr_func_param_table[4], mgr_func_param_table[5])
    elseif theSize == 6 then
        a, b, c, d = theFunc(self, mgr_func_param_table[1], mgr_func_param_table[2], mgr_func_param_table[3], mgr_func_param_table[4], mgr_func_param_table[5], mgr_func_param_table[6])
    else
        log_game_debug("GlobalDataMgr:MgrEventDispatch", "mgr_func_param_table too more params!")
        return
    end
    if not callback_func_name or callback_func_name == "" or not callback_func_param_table then return end

    log_game_debug("GlobalDataMgr:MgrEventDispatch", "Transmit!")

	local mb = self:GetNowMailBox()
    if not mb then
        log_game_debug("GlobalDataMgr:MgrEventDispatch", "Mailbox not found!")
    	return
    end

	local new_arg
	local org_arg = callback_func_param_table
    theSize = lua_util.get_table_real_count(org_arg)
    if theSize == 0 then
    	new_arg = {a, b, c, d}
    elseif theSize == 1 then
    	new_arg = {org_arg[1], a, b, c, d}
    elseif theSize == 2 then
    	new_arg = {org_arg[1], org_arg[2], a, b, c, d}
    elseif theSize == 3 then
    	new_arg = {org_arg[1], org_arg[2], org_arg[3], a, b, c, d}
    elseif theSize == 4 then
    	new_arg = {org_arg[1], org_arg[2], org_arg[3], org_arg[4], a, b, c, d}
    elseif theSize == 5 then
    	new_arg = {org_arg[1], org_arg[2], org_arg[3], org_arg[4], org_arg[5], a, b, c, d}
    elseif theSize == 6 then
    	new_arg = {org_arg[1], org_arg[2], org_arg[3], org_arg[4], org_arg[5], org_arg[6], a, b, c, d}
    else
        log_game_debug("GlobalDataMgr:MgrEventDispatch", "callback_func_param_table too more params!")
        return
    end

    log_game_debug("GlobalDataMgr:MgrEventDispatch", "Transmit Execute!")
    mb.EventDispatch(callback_sys_name, callback_func_name, new_arg)
end


----------------------------------------------------------------------------------------

function GlobalDataMgr:EventMarketQuotaBuy(grid_id, limit_quota)
    if not self.marketSharedQuota then return 0 end

    local sharedQuota = self.marketSharedQuota
    if not sharedQuota[grid_id] then
        sharedQuota[grid_id] = 0
    end
    if sharedQuota[grid_id] >= limit_quota then return 0 end

    sharedQuota[grid_id] = sharedQuota[grid_id] + 1
    return 1    
end

function GlobalDataMgr:EventGetMarketQuota(grid_id, limit_quota)
    if not self.marketSharedQuota or not self.marketSharedQuota[grid_id] then return limit_quota end
    if self.marketSharedQuota[grid_id] >= limit_quota then return 0 end
    return (limit_quota - self.marketSharedQuota[grid_id])
end

function GlobalDataMgr:EventClearMarketQuota()
    self.marketSharedQuota = {}
end

--  ip_ban
-- ip 需封禁或者解禁IP，若存在多个以逗号分隔
-- is_forbid 封/解标识.1=封IP； 0=解IP
-- forbid_time 封禁的截至日期.0=永久封禁，否则以此作为时间戳，代表封号结束时间。若is_forbid为0（即解封），则忽略此参数
function GlobalDataMgr:ip_ban(ip, is_forbid, forbid_time)

    local split_douhao = lua_util.split_str(ip, ",")

    if is_forbid == 1 then
        for i,v in ipairs(split_douhao) do
            self:add_forbid_ip(v, forbid_time)        
        end
    elseif is_forbid == 0 then
        for i,v in ipairs(split_douhao) do
            self:del_forbid_ip(v)        
        end
     end
end

--同上 但是这里是封账号
function GlobalDataMgr:forbid_login(account, is_forbid, forbid_time)
    
    local split_douhao = lua_util.split_str(account, ",")

    if is_forbid == 1 then
        for i,v in ipairs(split_douhao) do
            self:add_forbid_account(v, forbid_time)        
        end
    elseif is_forbid == 0  then
        for i,v in ipairs(split_douhao) do
            self:del_forbid_account(v)        
        end
     end
end


function GlobalDataMgr:add_forbid_ip(ip, forbid_time)
    self.forbidden_ips[ip] = forbid_time
    mogo.setBaseData("forbidden_ips", self.forbidden_ips)
end

function GlobalDataMgr:del_forbid_ip(ip)
    self.forbidden_ips[ip] = nil
    mogo.setBaseData("forbidden_ips", self.forbidden_ips)
end

function GlobalDataMgr:add_forbid_account(ip, forbid_time)
    self.forbidden_accounts[ip] = forbid_time
    mogo.setBaseData("forbidden_accounts", self.forbidden_accounts)

end

function GlobalDataMgr:del_forbid_account(ip)
    self.forbidden_accounts[ip] = nil
    mogo.setBaseData("forbidden_accounts", self.forbidden_accounts)
end


----------------------------------------------------------------------------------------

g_GlobalDataMgr = GlobalDataMgr
return g_GlobalDataMgr


















