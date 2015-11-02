--author:hwj
--date:2013-7-9
--此为名字管理中心，需要在加载在线管理器之后加载
--todo:随机了但是立即离开游戏的优化

require "lua_util"
require "public_config"
require "error_code"
require "NameData"

local log_game_debug = lua_util.log_game_debug
local log_game_warning = lua_util.log_game_warning
local log_game_info = lua_util.log_game_info
local log_game_error = lua_util.log_game_error

local globalbase_call = lua_util.globalbase_call




NameMgr = {}
--OfflineMgr.__index = BaseEntity

setmetatable(NameMgr, {__index = BaseEntity} )

function NameMgr:__ctor__()
    log_game_info('NameMgr:__ctor__', '========')
    self.base_mbstr = mogo.pickleMailbox(self)
    --回调方法
	local function RegisterCallback(ret)
        log_game_debug("NameMgr:__ctor__", "RegisterCallback")
		if 1 == ret then
			--注册成功
               self:OnRegistered()
		else
			--注册失败
            log_game_error("NameMgr:__ctor__", 'RegisterCallback')
		end
	end
    self:RegisterGlobally("NameMgr", RegisterCallback)
end

--注册globalbase成功后回调方法
function NameMgr:OnRegistered()
	log_game_debug("NameMgr:OnRegistered", "")
    --读取配置数据
    g_name_mgr:initData()
    
    globalbase_call('GameMgr', 'OnMgrLoaded', 'NameMgr')

    --预load用户数据
    
end

--服务器开启所有mgr后的初始化
function NameMgr:Init()
	log_game_debug("NameMgr:Init", "")
	--预load用户数据
    self:TableSelectSql("onAvatarSelectResp", "Avatar", "SELECT id,sm_name FROM tbl_Avatar")
	--[[
	local mm = globalBases['UserMgr']
	if mm then
		mm.InitNameMgr()
	else
		log_game_error("NameMgr:Init", "")
	end
	]]
end

function NameMgr:onAvatarSelectResp(rst)
	local names = {}
	for id, info in pairs(rst) do
		names[info.name] = id
	end
	self:OnInited(names)
	self:ReleaseInitData()
end
--
function NameMgr:OnInited(names)
	log_game_debug("NameMgr:OnInited", '')
	if not names then names = {} end
	g_name_mgr:InitByDB(names)
	local rand_names = g_name_mgr:random_n_names(10)
	globalbase_call('UserMgr', 'SetRobotNames', rand_names)
	globalbase_call('GameMgr', 'OnInited', 'NameMgr')
end

function NameMgr:ReleaseInitData()
	g_name_mgr:ReleaseInitData()
end

function NameMgr:GetRandomName(account, vocation, mbStr)
	--重复点击
	if self.usingPool[account] then
		g_name_mgr:BackToUnused(self.usingPool[account])
		self.usingPool[account] = nil
	end
	local name, ty = g_name_mgr:GetRandomName(vocation)
	--log_game_debug("NameMgr:GetRandomName", "name = %s, ty = %d", name, ty)
	--命名库用完
	if not name then
		log_game_error("NameMgr:GetRandomName", "run out of name data.")
		return
	end
	self.usingPool[account] = {name, ty}
	--名字检查
    local mm = globalBases["UserMgr"]
    if mm then
        --CheckName(mbStr, name, param, cbFunc)
        mm.CheckName(self.base_mbstr, name , {account, vocation, mbStr}, "SendName")
    else
        log_game_error("Account:CreateCharacterReq", '')
    end
end

function NameMgr:SendName(tableP, ret)
	local account = tableP[1]
	local vocation = tableP[2]
	local mbStr = tableP[3]
	if not self.usingPool[account] then return end
	local name = self.usingPool[account][1]
	if not name then
		return
	end
	--名字已存在
	if ret ~= 0 then
		log_game_info("NameMgr:SendName", "")
		self.usingPool[account] = nil
		--重复随机
		self:GetRandomName(account, vocation, mbStr)
		return
	end

	local mb = mogo.UnpickleBaseMailbox(mbStr)
	if mb then
		mb.client.RandomNameResp(name)
	else
		--对方下线
		g_name_mgr:BackToUnused(self.usingPool[account])
		self.usingPool[account] = nil
	end
end

function NameMgr:UseName(account, name)
	--log_game_debug("NameMgr:UseName", "account = %s, name = %s", account, name)
	if self.usingPool[account] then
		if self.usingPool[account][1] ~= name then
			--如果使用的名字不是随机的则back to字库
			g_name_mgr:BackToUnused(self.usingPool[account])
		end
		self.usingPool[account] = nil
	end
end

function NameMgr:UnuseName(account)
	--log_game_debug("NameMgr:UnuseName", "account = %s", account)
	if self.usingPool[account] then
		self.usingPool[account] = nil
	end
end

function NameMgr:random_n_names(n)
	local rand_names = g_name_mgr:random_n_names(n)
	globalbase_call('UserMgr', 'SetRobotNames', rand_names)
end

function NameMgr:RecoverName(name)
	g_name_mgr:RecoverName(name)
end