--author:hwj
--date:2013-12-31
--补偿管理器，主要负责一些临时性的玩家补偿
--

require "lua_util"


local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error
local globalbase_call = lua_util.globalbase_call




mgr_compensate = {}
setmetatable(mgr_compensate, {__index = BaseEntity} )


local l_last_compensation = {}

local function get_compensation(vocation,level)
	--log_game_debug("get_compensation 1 ","%s,    %d",mogo.cPickle(l_last_compensation),level)
	for id,v in pairs(l_last_compensation) do
		--log_game_debug("get_compensation 2 ","%s",mogo.cPickle(v))
		if v.level[1] <= level and level <= v.level[2] then
			if v.vocation == 0 then
				--log_game_debug("get_compensation 3 ","%s",mogo.cPickle(v.items))
				return v.items
			elseif vocation == v.vocation then
				return v.items
			end
		end
	end
end

--某个功能Mgr注册globalbase后的回调方法
local function basemgr_register_callback(mgr_name, eid)
    local mm_eid = eid
    local function __callback(ret)
        local gm = mogo.getEntity(mm_eid)
        if gm then
            if ret == 1 then
                --注册成功
                gm:on_registered()
            else
                --注册失败
                log_game_warning(mgr_name..".registerGlobally error", '')
                --destroy方法未实现,todo
                --gm.destroy()
            end
        end
    end
    return __callback
end

--某个功能Mgr写数据库的回调方法
local function on_basemgr_saved(mgr_name1)
    local mgr_name = mgr_name1
    local function __callback(entity, dbid, err)
        if dbid > 0 then
            log_game_info("create_"..mgr_name.."_success", '')
            entity:RegisterGlobally(mgr_name, basemgr_register_callback(mgr_name, entity:getId()))
        else
            --写数据库失败
            log_game_info("create_"..mgr_name.."_failed", err)
        end
    end
    return __callback
end

function mgr_compensate:__ctor__()
    log_game_info('mgr_compensate:__ctor__', '')

    --self.m_arenicData = {}
    --self.m_Save = {}
    self:initData()
    --回调方法
    if self:getDbid() == 0 then
        --首次创建
        self:writeToDB(on_basemgr_saved('mgr_compensate'))
    else
        self:RegisterGlobally("mgr_compensate", basemgr_register_callback("mgr_compensate", self:getId()))
    end
end

--注册globalbase成功后回调方法
function mgr_compensate:on_registered()
    --self:registerTimeSave('mysql') --注册定时存盘
	--load 公共邮件
	local sql = "SELECT id, sm_account,sm_level FROM tbl_last_server_account"
	self:TableSelectSql("OnLoad", "last_server_account", sql)
end

function mgr_compensate:OnLoad(rst)
	for _,info in pairs(rst) do
		self.m_lastDate[info.account] = info.level
	end
	globalbase_call('GameMgr', 'OnMgrLoaded', 'mgr_compensate')
end

--初始化配置数据
function mgr_compensate:initData()
    l_last_compensation = lua_util._readXml("/data/xml/compensation_last_server.xml", "id_i")
    --check
    for id,v in pairs(l_last_compensation) do
    	if not v.level or #v.level ~= 2 then
    		log_game_error("mgr_compensate:initData","id=%d",id)
    	end
    end
end

--登录邮件补偿
function mgr_compensate:Compensate(mbstr,account,dbid,vocation,vt)
	--上一个测试服的补偿
	--log_game_debug("mgr_compensate:Compensate", "mgr_compensate mbstr=%s, dbid=%q",mbstr,dbid)
	if vt == "last_server_compensate" then
		self:OnLastServerCompensate(mbstr,account,dbid,vocation,vt)
	end
end

function mgr_compensate:Reload()
	local sql = "SELECT id, sm_account,sm_level FROM tbl_last_server_account"
	self:TableSelectSql("OnReLoad", "last_server_account", sql)
end

function mgr_compensate:OnReLoad( rst )
	self.m_lastDate = {}
	for _,info in pairs(rst) do
		self.m_lastDate[info.account] = info.level
	end
end

--[[
1~9级 游戏币1万 钻石200
10~19级 游戏币5万 钻石1000
20~29级 游戏币10万 钻石2000 100体力
30~39级 游戏币20万 钻石3000 200体力 暗金碎片300
40级 游戏币50万 钻石5000 500体力 暗金碎片500 暗金手套 
]]
local s_compensation = 
{
	[10] = {[2] = 10000, [3] = 200,},
	[20] = {[2]=50000,[3]=1000},
	[30] = {[2]=100000,[3]=2000,[6]=100},
	[40] = {[2]=200000,[3]=3000,[6]=200,[1100021]=300},
	[60] = {
		{[2]=500000,[3]=5000,[6]=500,[1100021]=500,[1261601]=1},
		{[2]=500000,[3]=5000,[6]=500,[1100021]=500,[1262601]=1},
		{[2]=500000,[3]=5000,[6]=500,[1100021]=500,[1263601]=1},
		{[2]=500000,[3]=5000,[6]=500,[1100021]=500,[1264601]=1},
	}
}
function mgr_compensate:OnLastServerCompensate(mbstr,account,dbid,vocation,vt)
	--log_game_debug("mgr_compensate:OnLastServerCompensate","")
	local level = self.m_lastDate[account]
	if not level then return end
	
	local avatar_mb = mogo.UnpickleBaseMailbox(mbstr)
	if avatar_mb then
		self:last_server_compensate(dbid,vocation,level)
		avatar_mb.OnCompensate(vt)
	end
end

function mgr_compensate:last_server_compensate(dbid,vocation,level)
	--[[
	local att = {}
	if level < 10 then 
		att = s_compensation[10]
	elseif level < 20 then
		att = s_compensation[20]
	elseif level < 30 then
		att = s_compensation[30]
	elseif level < 40 then
		att = s_compensation[40]
	else
		att = s_compensation[60][vocation]
	end
	]]
	--log_game_debug("mgr_compensate:last_server_compensate","")
	local att = get_compensation(vocation,level)
	if not att then 
		return 
	end
	--log_game_debug("mgr_compensate:last_server_compensate","att=%s",mogo.cPickle(att))
	local name  = g_text_mgr:GetText(9)
	local title = g_text_mgr:GetText(10)
	local text  = g_text_mgr:GetText(11)
	text = string.format(text,level)
	local sign  = g_text_mgr:GetText(12)
	local mm = globalBases['MailMgr']
	if not mm then return end
	--log_game_debug("mgr_compensate:last_server_compensate","")
	mm.SendEx(title, name, text, sign, os.time(), att, {dbid}, reason_def.last_server)

end

return mgr_compensate