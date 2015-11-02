require "BaseEntity" 
require "public_config"
require "action_config"
require "mission_config"
require "lua_util"

local error_code = require "error_code"

require "mgr_action"

require "mgr_channel"

require "map_data"
--require "mgr_map"

--require "AvatarLevel"
require "event_config"
require "TaskSystem"
require "MissionSystem"
require "ActivitySystem"
require "FriendSystem"
require "RuneSystem"
require "BodyEnhanceSystem"
require "GuildSystem"
require "NPCSystem"
require "npcData"
require "vip_config"
require "ElfSystem"

require "InventorySystem"
require "SceneSystem"
require "SpiritSystem"
require "JewelSystem"
require "MercenarySystem"
--require "MailSystem"
require "MarketSystem"
require "HotSalesSystem"
require "OblivionGateSystem"
require "DefensePvPSystem"
require "LevelGiftSystem"
require "TowerSystem"
require "CampaignSystem"
require "avatar_level_data"
require "global_data"
require "GlobalParams"
require "role_data"
require "vip_privilege"
require "Trigger"
require "tower_config"
require "item_effect"
require "energy_data"
require "PriceList"
require "attri_cal"
require "ArenaSystem"
require "AvatarHp"
require "GoldMetallurgy"
require "ItemExchange"
require "RankListData"
require "ServerChineseData"
require "CampaignSystem"
require "dragon_data"
require "FlyDragonSystem"
require "SpecialEffects"
require "SkillUpgradeSystem"
require "WingSystem"
--local map_mgr = g_map_mgr

local globalbase_call   = lua_util.globalbase_call
local log_game_debug    = lua_util.log_game_debug
local log_game_info     = lua_util.log_game_info
local log_game_warning  = lua_util.log_game_warning
local log_game_error    = lua_util.log_game_error


local function generic_avatar_call(...)
    g_action_mgr.generic_avatar_call(g_action_mgr, ...)
end

local function generic_avatar_call_ne0(...)
    g_action_mgr.generic_avatar_call_ne0(g_action_mgr, ...)
end

--定时器Id
local TIMER_ID_DESTROY      = 1    --销毁的定时器
local TIMER_ID_ZERO_POINT   = 2    --0点定时器
local TIMER_ID_FIVE_MINUTES = 3    --5分钟一次
--local TIMER_ID_8            = 4    --每天8点的定时器
local TIMER_ID_ENERGY       = 5    --上线体力首次恢复时间

local FIVE_MINUTES = 5 * 60

local TIMER_ID_UPDATE_ONLINE_DATA = 3 -- 更新用户管理中心数据

--守护PVP的复活点默认值
local DEFENSE_PVP_RELIVE_POINT  = {{1520,1279}, {1520,11043}}

--守护PVP的地图ID默认值
local DEFENSE_PVP_MAP_ID        = 42000


Avatar = {}
setmetatable(Avatar, {__index = BaseEntity} )
----------------------------------------------------------------------------------------------------
--hasTimer中定时器的key
local timerType = {
    DESTROY = 1, --销魂定时器
}
---------------------引擎可能会回调的方法 begin--------------------------------------------------------

--mogo.loadAvatars的回调方法
--注意:这个方法不需要entity
function Avatar.onEntitiesLoaded(count)
    log_game_info("Avatar.onEntitiesLoaded", string.format("count=%d", count))

    local mgr = globalBases['UserMgr']
    if mgr then
        --通知管理器entity的总数
        mgr.set_entities_count(count)
    end
end

function Avatar:__ctor__()
    --log_game_info("Avatar:__ctor__", "-------------------------------------------")
    self.dbid = self:getDbid()

    self.base_mbstr         = mogo.pickleMailbox(self)
    self.taskSystem         = TaskSystem:new(self)
--    self.missionSystem    = MissionSystem:new(self)
    self.activitySystem     = ActivitySystem:new(self)
    self.inventorySystem    = InventorySystem:new(self)
    self.friendSystem       = FriendSystem:new(self)
    self.runeSystem         = RuneSystem:new(self)
    self.bodyEnhanceSystem  = BodyEnhanceSystem:new(self)
    self.SpiritSystem       = SpiritSystem:new(self)
--    self.sceneSystem      = SceneSystem:new(self)
    self.jewelSystem        = JewelSystem:new(self)
    self.mercenarySystem    = MercenarySystem:new(self)
    --self.mailSystem         = MailSystem:new(self)
    self.marketSystem       = MarketSystem:new(self)
    self.hotSalesSystem     = HotSalesSystem:new(self)
    self.levelGiftSystem    = LevelGiftSystem:new(self)
--    self.towerSystem      = TowerSystem:new(self)
    self.oblivionGateSystem = OblivionGateSystem:new(self)
    self.defensePvPSystem   = DefensePvPSystem:new(self)
    self.triggerSystem      = Trigger:new(self)
--    self.guildSystem      = GuildSystem:new(self)
    self.elfSystem          = ElfSystem:new(self)

    local runeBag = self.rune or {}
    self.runeSystem:SetDbTable(runeBag, self.level)
    if self.level >= g_arena_config.OPEN_LV then
        self.arenaSystem = ArenaSystem:new(self)   --todo:20级以后的才初始化竞技场系统,并触发前端UI显示
    end
    --设定每天0点触发的定时器
    self:addTimer(lua_util.get_left_secs_until_next_hhmiss(0, 0, 0) + math.random(0, 10), 24*60*60, TIMER_ID_ZERO_POINT)

--    --设定每天8点触发的定时器
--    self:addTimer(lua_util.get_left_secs_until_next_hhmiss(8, 0, 0) + math.random(0, 10), 24*60*60, TIMER_ID_8)

    --5分钟一次，定时设置自己的离线时间，由于服务器崩溃的原因，如果只在玩家下线时设置，可能会导致出错
    self:addTimer(FIVE_MINUTES, FIVE_MINUTES, TIMER_ID_FIVE_MINUTES)

    self:addEventListener(self:getId(), event_config.EVENT_AVATAR_PROPERTIES_RECALCULATE, "ProcessBaseProperties")
    self:addEventListener(self:getId(), event_config.EVENT_VIP_LEVEL_CHANGED, "VipLevelChanged")


    --角色登陆体力回复检测
    local intervals, remainder = self:EnergyCheck()
    --体力自然回复定时间隔
    self:addTimer(remainder, intervals, TIMER_ID_ENERGY)
    
    local vipLevel = g_vip_mgr:GetVipLevel(self.chargeSum)
    self.VipLevel  = vipLevel

    self:DragonOnlineCheck()
    --角色粉丝奖励
    self:RecivedFansWelfareToday()
    self:WingInit()
    --设定定时上报用户管理管理中心
--    local interval = g_GlobalParamsMgr:GetParams('update_online_data_interval', 300)
    --self:addTimer(interval, interval, TIMER_ID_UPDATE_ONLINE_DATA)
      --初始化
    self.tmp_data[public_config.TMP_DATA_KEY_QUIT_FLAG] = public_config.TMP_DATA_QUIT_MODE_NOEN
    self.tmp_data[public_config.TMP_DATA_KEY_ARENA] = 0
    if self.tmp_flag == 1 then
    	self.tmp_flag = 0 
    end
end
function Avatar:WingInit()
    if not next(self.wingBag) then
        self.wingBag[public_config.WING_BODY_INDEX] = 0
        self.wingBag[public_config.WING_DATA_INDEX] = {}
    end
end
function Avatar:OnCompensate(vt)
	--log_game_debug("Avatar:OnCompensate", "mgr_compensate")
	if vt == "last_server_compensate" then
		self.tmp_flag = 2
	end
end

--cell创建好的回调方法
function Avatar:onGetCell()
    log_game_info("Avatar:onGetCell", "dbid=%q;id=%d", self.dbid, self:getId())
    --    gMapActionMgr:onGetCell(self)
    gSceneSystem:onGetCell(self)
    gMissionSystem:onGetCell(self)
    self.taskSystem:CreateAvatarInitAll()
    --初始化一级战斗属性并通知cell初始化战斗属性

    --self:InitLevelInfo()
    self:ProcessBaseProperties()
    --同步角色身上的其他角色可见装备属性
    --角色特效值需求策划未定，待续
    self.inventorySystem:SyncVisibleProps()
    SpecialEffectsSystem:SyncSpecialEffectsMode(self)
    WingSystem:SyncWingShowMode(self)
    --vip状态检查,若玩家零点时在线，由零点timer处理数据重置。
    self:VipStateCheck()
    --log_game_debug("Avatar:onGetCell", "dbid=%q;name=%s;VipRealState=%s", self.dbid, self.name, mogo.cPickle(self.VipRealState))

    local friendNum = lua_util.get_table_real_count(self.friends)

    self:CheckResetElfSysData()

    --注册UserMgr管理器
    globalbase_call("UserMgr", "PlayerOnLine",
    self.base_mbstr,                  --base的mb
    mogo.cPickle(self.cell),          --cell的mb
    self.dbid,
    self.name,
    self.level,
    self.vocation,
    self.gender,
    0,                             --工会dbid
    self.fightForce,               --战斗力
    friendNum                      --好友信息
    )

    --玩家上线时把信息注册到公会管理器
    globalbase_call("GuildMgr","Register", self.dbid, self.base_mbstr, self.name, self.level, self.fightForce)

--    if mogo.stest(self.baseflag, public_config.AVATAR_BASE_STATE_NEWBIE) ~= 0 then
--        gMissionSystem:EnterMission(self, g_GlobalParamsMgr:GetParams('newbie_mission_id', 10004), g_GlobalParamsMgr:GetParams('newbie_difficulty', 1))
--        self.baseflag = mogo.sunset(self.baseflag, public_config.AVATAR_BASE_STATE_NEWBIE)
--    end

--    local missionId = g_GlobalParamsMgr:GetParams('newbie_mission_id', 10004)
--    local difficulty = g_GlobalParamsMgr:GetParams('newbie_difficulty', 1)
--    local tbl = {}
--    table.insert(tbl, tostring(missionId))
--    table.insert(tbl, tostring(difficulty))
--    local MissionCfg = g_mission_mgr:getCfgById(table.concat(tbl, '_'))
--    if MissionCfg and MissionCfg['scene'] and self.sceneId == MissionCfg['scene'] then
--        local SpaceLoader = self.SpaceLoaderMb
--        if SpaceLoader then
--            SpaceLoader.SetMissionInfo(self.dbid, self.name, mogo.pickleMailbox(self), missionId, difficulty)
--        end
--    end

    --    self:DestroyCellEntity()
end

--创建cell失败的回调方法
function Avatar:onCreateCellFailed(err_id)
    log_game_info("Avatar:onCreateCellFailed", "dbid=%q;id=%d;err=%d",
    self:getDbid(), self:getId(), err_id)
end

--失去了cell
function Avatar:onLoseCell(result)
    log_game_info("Avatar:onLoseCell", "dbid=%q;id=%d", self.dbid, self:getId())
    --设置了退出标记
    if self.tmp_data[public_config.TMP_DATA_KEY_QUIT_FLAG] ~= public_config.TMP_DATA_QUIT_MODE_NOEN then
        --注册UserMgr管理器
        --globalbase_call("UserMgr", "PlayerOffLine", self.dbid)
        --下线的时候把usermgr上的数据更新下
        --self:OnUpdateUserMgrData()
        local friendList = {}
        for k,_ in pairs(self.friends) do
            table.insert(friendList, k)
        end
        log_game_debug('FriendSystem:Logout', '')
        --globalbase_call("UserMgr", "FriendOffline", self.dbid, friendList)
    end
    --gMapActionMgr:onLoseCell(self)
    gSceneSystem:onLoseCell(self)
end

--销毁前操作
function Avatar:onDestroy()
    local account = mogo.getEntity(self.accountId)
    if account then
        account.activeAvatarId = 0
    end

    self.offlineTime = os.time()

    --下线时把公会管理器的数据注销掉
    globalbase_call("GuildMgr", "DisRegister", self.dbid)

    --注册UserMgr管理器
    globalbase_call("UserMgr", "PlayerOffLine", self.dbid)

--    --下线的时候通知地图管理器
--    globalbase_call("MapMgr", "ChangeMapCount", public_config.CHANGE_MAP_COUNT_SUB, self.sceneId, self.imap_id, 1)

    --下线的时候离开活动
    globalbase_call('ActivityMgr', 'CampaignLeaveAll', self.base_mbstr, self.dbid)

    log_game_info("Avatar:onDestroy", "dbid=%q;id=%d", self.dbid, self:getId())

    local accountName, platName = self:SplitAccountNameByString(self.accountName)

    local cur_time = os.time()
    local insert_table ={
            role_id         =   self.dbid,            
            account_name    =   accountName,
            plat_name       =   platName,
            login_level     =   self.login_level,
            logout_level    =   self.level,
            login_ip        =   self.login_ip,
            login_time      =   self.login_time,
            logout_time     =   cur_time,
            time_duration   =   (cur_time - self.login_time),  --在线时长
            msg             =   "正常退出",
            os              = "android iphone",   --temp temp temp这里先写死 客户端还没做
            os_version      = "2.3.4",
            device          = "三星GT-S5830",
            device_type     = "android、iPhone、iPad",
            screen          = "480*800",
            mno             = "中国移动,",
            nm              = "3G，WIFI",
            happend_time    =   os.time(),
        }

    globalbase_call("Collector", "table_insert", "tbllog_quit", insert_table)
    gMissionSystem:onDestroy(self)

    --通知守护PvP系统
    self.defensePvPSystem:Del()
end

--Account通知base二次登录
function Avatar:onMultiLogin()
    log_game_info("Avatar:onMultiLogin", "dbid=%q;name=%s;id=%d, self.sceneId = %d, self.imap_id = %d",
    self.dbid, self.name, self:getId(), self.sceneId, self.imap_id)

    local friendNum = lua_util.get_table_real_count(self.friends)
    --注册UserMgr管理器
    globalbase_call("UserMgr", "PlayerOnLine",
    self.base_mbstr,                  --base的mb
    mogo.cPickle(self.cell),          --cell的mb
    self.dbid,
    self.name,
    self.level,
    self.vocation,
    self.gender,
    0,                             --工会dbid
    self.fightForce,               --战斗力
    friendNum                      --好友信息
    )
--    local map_id = tostring(self.sceneId) .. '_' .. tostring(self.imap_id)
    local sp = self.SpaceLoaderMb
    if sp and sp ~= {} then
        sp.onMultiLogin(self.dbid)
    end

--    --玩家被顶号时，如果不再王城，则回去王城
--    if self.sceneId ~= g_GlobalParamsMgr:GetParams('init_scene', 10004) then
--        self:MissionReq(action_config.MSG_EXIT_MAP, 0, 0, '')
--    end

    if self:hasClient() then
        self.client.OnMultiLogin()
    end

--    lua_util.globalbase_call("MapMgr", "onMultiLogin", self.ptr.theOwner.sceneId, self.ptr.theOwner.imap_id, self.ptr.theOwner.dbid)
end

--Account通知base不是二次登录
function Avatar:onFirstLogin(spBaseMb)

    log_game_debug("Avatar.onFirstLogin", "dbid=%q;id=%d;name=%s", self.dbid, self:getId(), self.name )

    if self.inventorySystem then
        self.inventorySystem:UpdateArrayToClient()
    else
        log_game_error("Avatar:onFirstLogin", "inventorySystem is nil")
        return
    end

    --创建角色的cell部分
    self:_create_cell(spBaseMb)

    local spBaseMbStr = mogo.cPickle(spBaseMb)
    self:SetSpaceLoaderMb(mogo.UnpickleBaseMailbox(spBaseMbStr))

    --        --如果断线在副本里,则退出
    --        if mogo.stest(self.state, public_config.STATE_IN_INS_SPAWNER) > 0 then
    --            ins_mgr:ins_abort_req(self)
    --        end
    --        self:register_user_info()

    --上线时算一遍试炼之塔数据
    gTowerSystem:OnClientGetBase(self)

    --上线时判断是否需要清除每天的副本次数
    gMissionSystem:OnClientGetBase(self)

    --上线时判断是否需要清空活动挑战次数
    gCampaignSystem:OnClientGetBase(self)

    self:registerTimeSave('mysql') --注册定时存盘
    

    self.offlineTime    = os.time()     --更新下线时间

    self.login_ip       = self:GetIPAddr()
    self.login_level    = self.level
    self.login_time     = self.offlineTime

    globalbase_call("Collector","tbllog_player",
        self.dbid,--  角色ID
        self.name, --  角色名
        self.accountId, --  用户账号ID
        self.accountName, --  用户账号名
        0,--  阵营
        self.vocation, --  职业
        self.gender,--  性别
        self.createTime,--  注册时间
        self.level, --  用户等级
        self.VipLevel,--  VIP等级
        self.exp,--  当前经验
        "", --  帮派名称
        0,--  战斗力
        self.diamond,--  元宝数
        0,--  首充时间
        0,--  最后充值时间
        0--  最后登录时间
        )

    local accountName, platName = self:SplitAccountNameByString(self.accountName)
    
    local insert_table ={
                role_id         = self.dbid,--  角色ID
                account_name    = accountName, 
                plat_name       = platName,
                dim_level       = self.level, 
                user_ip         = self.login_ip, 
                os              = "android iphone",
                os_version      = "2.3.4",
                device          = "三星GT-S5830",
                device_type     = "android、iPhone、iPad",
                screen          = "480*800",
                mno             = "中国移动,",
                nm              = "3G，WIFI",
                happend_time    = self.login_time,
        }

    globalbase_call("Collector", "table_insert", "tbllog_login", insert_table)
    --
    globalbase_call("OfflineMgr", "GetAll",self.base_mbstr, self.dbid)
    
    self:SanctuaryLogin(self.base_mbstr)
end

--客户端连接到entity的回调方法(引擎调用)
function Avatar:onClientGetBase()

--    local temp = self:getDbid()

    log_game_debug("Avatar.onClientGetBase", "dbid=%q;id=%d;name=%s", self.dbid, self:getId(), self.name )
    local account = mogo.getEntity(self.accountId)
    if account then
        account.avatarState = public_config.CHARACTER_CREATED
    else
        log_game_error("Avatar.onClientGetBase", "account is nil.")
    end

    --客户端连接到base时注册
    global_data:register(self)
    
--    if temp > 0 then
----        self.dbid = temp
--        --        self:init()
--        --      当背包数据加载完在执行回调
--        --self:_create_cell()
--        if self.inventorySystem then
--            self.inventorySystem:GetItemsFromDb()
----            self:addLocalTimer("FlushDataToDb", 2000, 0)
--        else
--            log_game_error("Avatar:onClientGetBase", "inventorySystem is nil")
--            return
--        end
--        --        --如果断线在副本里,则退出
--        --        if mogo.stest(self.state, public_config.STATE_IN_INS_SPAWNER) > 0 then
--        --            ins_mgr:ins_abort_req(self)
--        --        end
--        --        self:register_user_info()
--        self:registerTimeSave('mysql') --注册定时存盘
--        --self:onEnterGame()
--    end

    --    log_game_debug("Avatar.onClientGetBase BroadcastClientRpc", "dbid=%q;id=%d;name=%s", temp, self:getId(), self.name)
    --    mogo.BroadcastClientRpc("Avatar", "ChatResp", public_config.CHANNEL_ID_WORLD, self.dbid, self.name, "")
    --获取所有不在线时的消息
    --[[
    globalbase_call("OfflineMgr", "GetAll",
    self.base_mbstr, self.dbid)
    ]]
end
--离线消息登陆处理
function Avatar:OnGetAllOfflineItem( allOffInfo )
    --test
    --CommonXmlConfig:TestData(allOffInfo)

--    log_game_debug("Avatar:OnGetAllOfflineItem", "")
    --好友系统登陆处理
    self.friendSystem:Req(msgFriendSys.MSG_FRIEND_LOGIN, allOffInfo)
    --一开始把邮件load过来子系统
    --local mails = allOffInfo[OfflineType.OFFLINE_RECORD_MAIL]
    --self.mailSystem:Login(mails)
    self:_LoginMailMgr()
    --竞技场
    if self.level >= g_arena_config.OPEN_LV then
        self.arenaSystem:Login()
    end
    --临时补偿
    local mm = globalBases['mgr_compensate']
    if not mm then log_game_warning("Avatar:OnGetAllOfflineItem", "no mgr_compensate,self.dbid=%q",self.dbid) end
    if mm and self.tmp_flag == 0 then
    	--log_game_warning("Avatar:OnGetAllOfflineItem", "no mgr_compensate,self.dbid=%q",self.dbid)
		mm.Compensate(self.base_mbstr,self.accountName,self.dbid,self.vocation,"last_server_compensate")
		self.tmp_flag = 1
	end
end

--客户端断开连接的回调方法
--如果是被顶掉的号则不增加销魂定时器 被顶号不会走这个接口
function Avatar:onClientDeath()
    log_game_info("Avatar.onClientDeath", "dbid=%q", self.dbid )
--    --注册UserMgr管理器
--    globalbase_call("UserMgr", "PlayerOffLine", self.dbid)
    --通知Account我退出了
    local account = mogo.getEntity(self.accountId)
    if account then
        --如果是客户端主动调用logout推出返回
        if account.avatarQuitFlag == public_config.QUIT_NORMAL then
            return
        end
        account.avatarQuitFlag = public_config.QUIT_UNNORMAL
    end

    --增加定时器销毁
--    local timerId = 0
    local timerId = self:addTimer(g_GlobalParamsMgr:GetParams('quit_delay_destroy_time', 300), 0, TIMER_ID_DESTROY)
    if self.hasTimer[timerType.DESTROY] then
        log_game_warning("Avatar:onClientDeath","self.hasTimer[timerType.DESTROY] = %d,timerId = %d",self.hasTimer[timerType.DESTROY], timerId)
        --把老的定时器删除掉
        self:delTimer(self.hasTimer[timerType.DESTROY])
    else
        --加入定时器集合
        self.hasTimer[timerType.DESTROY] = timerId
    end
    log_game_debug("Avatar:addTimer","dbid=%q;name=%s;timerId=%d;user_data=%d", self.dbid, self.name, timerId, TIMER_ID_DESTROY)

    gMissionSystem:onClientDeath(self)

    --客户端从base断开时反注册
    global_data:deregister(self)
    --重置临时变量
    if self.tmp_flag == 1 then self.tmp_flag = 0 end
end

function Avatar:Logout(flag)
    log_game_info("Avatar.Logout", "dbid=%q;id=%d;flag=%d", self.dbid, self:getId(), flag)
    --客户端收到回调0立即断开socket,回调1立即返回重选角色界面，确保登出rpc调用被处理完毕
    if self:hasClient() then
        self.client.OnLogoutResp(flag)
    end
    --客户端断开就存盘下线,不用像端游那样的15秒等待时间
    --通知Account我退出了
    --客户端申请退出flag
    local account = mogo.getEntity(self.accountId)

    if account and public_config.LOGOUT_BACK == flag then
        account.avatarQuitFlag = public_config.QUIT_BACK
        account:UpdateAvatarsInfo(self, self.dbid)
        self:GiveClientTo(account)
        return
    end

    self:DeleteAll()
end
--[[
function Avatar:Quit(flag)
    local account = mogo.getEntity(self.accountId)
    if account then
        if account.avatarQuitFlag == public_config.QUIT_NORMAL or
            account.accountDestroyFlag == public_config.DESTROY_FLAG_DESTROYING then
            log_game_error("Avatar:Quit", "already on destroying.")
            return
        end
    end

    if flag == public_config.TMP_DATA_QUIT_MODE_NORMAL then
        if account then
            --设置立即销魂
            account.avatarQuitFlag = public_config.QUIT_NORMAL
            --标记正在销毁流程中,预防异步问题：login->dbmgr先于base->dbmgr，但是base已经发出了销毁命令 
            account.accountDestroyFlag = public_config.DESTROY_FLAG_DESTROYING
        end
        --走完整的销毁流程：dbmgr上account的数据(此时角色登录会创建第二个account)->account销毁，cell实体销毁->base实体销毁
        self:NotifyDbDestroyAccountCache(self.accountName)
    elseif flag == public_config.TMP_DATA_QUIT_MODE_SPECIAL then
        --完整流程也最后也会走到这里
        --走只删除avatar缓存 cell实体销毁->base实体销毁
        if account then
            --更新下角色信息
            account:UpdateAvatarsInfo(self,self.dbid)
        end
        if self:HasCell() then
            self.sceneSystem:quit_if_has_cell(flag)
        elseif self.tmp_data[public_config.TMP_DATA_KEY_CREATING_CELL] then
            self.sceneSystem:quit_if_creating_cell(flag)
        else
            self:real_quit()
        end
    else
        log_game_error("Avatar:Quit", "flag[%d] illegal.", flag)
    end
end
]]
function Avatar:DeleteAll()
    local account = mogo.getEntity(self.accountId)
    if account then
        if account.avatarQuitFlag == public_config.QUIT_NORMAL or
            account.accountDestroyFlag == public_config.DESTROY_FLAG_DESTROYING then
            log_game_error("Avatar:Quit", "already on destroying.")
            return
        end
        --设置立即销魂
        account.avatarQuitFlag = public_config.QUIT_NORMAL
        --标记正在销毁流程中,预防异步问题：login->dbmgr先于base->dbmgr，但是base已经发出了销毁命令 
        account.accountDestroyFlag = public_config.DESTROY_FLAG_DESTROYING
    end
    --走完整的销毁流程：dbmgr上account的数据(此时角色登录会创建第二个account)->account销毁，cell实体销毁->base实体销毁
    self:NotifyDbDestroyAccountCache(self.accountName)
end

function Avatar:DeleteSelf()
    local account = mogo.getEntity(self.accountId)
    --走只删除avatar缓存 cell实体销毁->base实体销毁
    if account then
        --更新下角色信息
        account:UpdateAvatarsInfo(self,self.dbid)
    end
    if self:HasCell() then
        gSceneSystem:quit_if_has_cell(self, public_config.TMP_DATA_QUIT_MODE_SPECIAL)
    elseif self.tmp_data[public_config.TMP_DATA_KEY_CREATING_CELL] then
        gSceneSystem:quit_if_creating_cell(self, public_config.TMP_DATA_QUIT_MODE_SPECIAL)
    else
        self:real_quit()
    end
end

function Avatar:init( account, name, gender, vocation )
    log_game_debug("Avatar:initData", "dbid=%q;id=%d", self:getDbid(), self:getId())
    self.name = name
    self.vocation = vocation
    self.gender = gender
    self.accountName = account.name
    self.accountId = account:getId()
    self.createTime = os.time()

    self.sceneId = g_GlobalParamsMgr:GetParams('init_scene', 10004)
    self.map_x = g_GlobalParamsMgr:GetParams('init_x', 0)
    self.map_y = g_GlobalParamsMgr:GetParams('init_y', 0)
    --初始等级
    self.level = 1
    --初始任务
    self.taskMain = g_GlobalParamsMgr:GetParams('init_task', 1)
    --初始精灵系统已学技能
    self.elfSystem:InitResetElfSysData() 
    self.elfSystem:InitElfAreaTearProg()
    self.elfSystem:InitElfLearnedSkillId()

    self.imap_id = 0
    self:ResetVipState()
    self:InitEnergy()
    self.SpiritSystem:InitSpiritDataOnCreateRole()
    self.skillBag = self:InitSkillsForAvatar(self.vocation)

    self.body = {
        0,0,0,0,0,0,0,0,0,0,
    }
    self.arenicData = {
        [arenicDataKey.avatar_cdEndTime] = 0,
        [arenicDataKey.avatar_buyTimes] = 0,
        --[arenicDataKey.avatar_bufAtk] = 0,
        --[arenicDataKey.avatar_bufHp] = 0,
        [arenicDataKey.avatar_weak] = 0,
        [arenicDataKey.avatar_strong] = 0,
        [arenicDataKey.avatar_inspire_buf] = 0,
        [arenicDataKey.avatar_weakRange] = {10000,0},
        [arenicDataKey.avatar_strongRange] = {10000,0},
        [arenicDataKey.avatar_DailyBuys] = 0,
        [arenicDataKey.avatar_DailyBuyCd] = 0,
    }
    --    --初始化时把关卡数据的存盘值转成内存值
    --    self:MissionPToM()
    --    self:addTimer(5*60, 5*60, TIMER_ID_1)
end
---------------------------------------------------------------<
--体力系统
---------------------------------------------------------------<
--体力扣除
function Avatar:DeductEnergy(count)
    return g_energy_mgr:SubEnergy(self, count)
end
--角色体力初始化
function Avatar:InitEnergy()
    g_energy_mgr:InitEnergy(self)
end
--自然回复定时器处理
--在线时按照时间间隔触发
--下线时需要记录时间戳，上线时计算需要回复的点
function Avatar:EnergyNatureRcy()
    g_energy_mgr:RecoveryEnergy(self)
end
--角色上线时的体力检查
function Avatar:EnergyCheck()
    return g_energy_mgr:EnergyCheck(self)
end
function Avatar:BuyEnergyReq(key, count)
    if key == public_config.SINGLE_TIME then
        if count > 1 then
           return
        end
        self:BuyEnergy()
    elseif key == public_config.ALL_TIEMS then
        self:BuyAllEnergy(count)
    end
end
--单次购买体力
function Avatar:BuyEnergy()
    g_energy_mgr:BuyEnergy(self, 1)
end
--一次性全部购买
function Avatar:BuyAllEnergy(count)
    g_energy_mgr:BuyAllEnergy(self, count)
end
 --角色升级体力奖励
function Avatar:RewardLevelUp()
    g_energy_mgr:RewardLevelUp(self)
end
function Avatar:AddEnergy(count, reason)
    local limit = g_energy_mgr:GetEnergyLimit(self.level)
	if count < 0 then
		if self.energy < -count then
			return false
		end
	end
    local tpCnt = self.energy + count
    if tpCnt > limit and self.energy >= limit then
        return false
    end
    if tpCnt >= limit then
        self.energy = limit
        log_game_info("Avatar:AddEnergy", "dbid=%q;name=%s;energy=%d;addEnergy=%d;reason=%d", 
            self.dbid, self.name, self.energy, (limit - self.energy), reason)
   else
        self.energy = tpCnt
        log_game_info("Avatar:AddEnergy", "dbid=%q;name=%s;energy=%d;addEnergy=%d;reason=%d", 
            self.dbid, self.name, self.energy, count, reason)
   end
   return true 
end
----------------------------------------------------------------->
----------------------------------------------------------------->
-- function Avatar:MaxEnergyToCell()
--     local ecfg = g_energyData_mgr:GetEnergyData()
--     self.cell.SyncMaxEnergy(ecfg.maxEnergy)
-- end



--function Avatar:Upgrade( new_level )
--    if self.level >= new_level then
--        return
--    end
--
--    self.level = new_level
--
--    self:EnergyLevelUpRcy()
--    --重新计算二级战斗属性
--    self:ProcessBaseProperties()
--    --[[
--    self.dexterity = AvatarLevel[self.level]["dexterity"]
--    self.intelligence = AvatarLevel[self.level]["intelligence"]
--    self.recoverEnergy = AvatarLevel[self.level]["recoverEnergy"]
--    --]]
--    -- body
--end

--重新计算二级战斗属性
function Avatar:ProcessBaseProperties()
    local lv = self.level
    local vocation = self.vocation

    local baseProps = {}
    --local runeBag = self.inventorySystem:GetAllItem(public_config.ITEM_TYPE_RUNE)
    --local bodyEquip = self.inventorySystem:GetAllItem(public_config.ITEM_TYPE_AVATAR)

    self.baseProps = battleAttri:GetPropertiesWithArenic(baseProps, self.body, self.rune, self.equipeds, self.level, self.arenicGrade, self.fumoinfo, self.elfAreaTearProg, self.wingBag)
    --self.baseProps = battleAttri:GetPropertiesWithParms(baseProps, self.body, self.rune, self.equipeds, self.level)
    self.fightForce = battleAttri:GetFightForce(baseProps)

    --绕到GuildMgr获取公会的加成
    globalbase_call("GuildMgr","GuildProcessBasePropertiesReq", self.base_mbstr, self.dbid, baseProps)

--    --通知cell更新战斗属性
--    if self:HasCell() then
--        self.cell.ProcessBattleProperties(baseProps)
--    end
    self.state = mogo.sset(self.state, state_config.STATE_PROCESSING_BASE_PROP)
end

--公会管理期回调的接口
function Avatar:GuildProcessBasePropertiesResp(baseProps)
    --通知cell更新战斗属性
    if self:HasCell() then
        self.cell.ProcessBattleProperties(baseProps)
    end
    self.state = mogo.sunset(self.state, state_config.STATE_PROCESSING_BASE_PROP)
end

--function Avatar:DoPrint(baseProps)
--    for k, v in pairs(baseProps) do
--        log_game_debug("Avatar:============", "key = %s value = %d", tostring(k), tostring(v))
--    end
--end
--真正可以quit了
function Avatar:real_quit()
    log_game_info("Avatar:real_quit", "dbid=%q", self:getDbid())
    --g_cdtimes_mgr:clear_timeout_cd(self)
    --title_mgr:check_title_time(self)

    --向多个管理器注销自己
    --    self:deregister_user_info()

    --[[
    local account = mogo.getEntity(self.accountId)
    if account then
        local errNo = account:UpdateAvatarsInfo(self,self.dbid)
        log_game_debug("account:UpdateAvatarsInfo",'account still here.')
    end
    ]]
    self.offlineTime = os.time()


    --销毁并存盘,destroy(writeToDB, delete),存盘后回调方法发给对应的account
    local function __dummy(a, b, c)
        log_game_error("Avatar:real_quit","")
    end
    self:writeToDB(__dummy)
    mogo.DestroyBaseEntity(self:getId())

    --[[
    if public_config.TMP_DATA_QUIT_MODE_SPECIAL == self.tmp_data[public_config.TMP_DATA_KEY_QUIT_FLAG] or 
        public_config.TMP_DATA_QUIT_MODE_SPECIAL == flag then
        --直接走销魂base流程, 跳过account相关销毁
        mogo.DestroyBaseEntity(self:getId())
        --self:DestroyCellEntity()
    else
        --开始走真正的销毁流程
        self:NotifyDbDestroyAccountCache(self.accountName)
    end
    ]]
end

function Avatar:onTimer(timer_id, user_data)
--    log_game_debug("Avatar:onTimer","timer_id = %d, user_data = %d",timer_id, user_data)
    if user_data == TIMER_ID_DESTROY then
        log_game_debug("Avatar:onTimer destroy", "dbid=%q;name=%s", self.dbid, self.name)
        if self.hasTimer[timerType.DESTROY] and (timer_id == self.hasTimer[timerType.DESTROY]) then
            --这里是否需要判断是否还有客户端连接，有就不销毁(如果游戏逻辑正确是永远不会进来的)
            if self:hasClient() then
                log_game_debug("Avatar:onTimer","destroy avatar which still has client!")

                return
            end
            --self:Quit(public_config.TMP_DATA_QUIT_MODE_NORMAL)
            self:DeleteAll()
            if self.hasTimer[timerType.DESTROY] then self.hasTimer[timerType.DESTROY] = nil end
        end

    elseif user_data == TIMER_ID_ZERO_POINT then
        log_game_info("Avatar:onTimer zero_point_timer", "dbid=%q;name=%s", self.dbid, self.name)
        gTowerSystem:OnZeroPointTimer(self)
        gMissionSystem:OnZeroPointTimer(self)
        gCampaignSystem:OnZeroPointTimer(self)
        self:reset_day_task() --0点重置日常任务
        self:refresh_login_days()--0点重置登陆
        globalbase_call('EventMgr', 'OnLevelUp', self.base_mbstr)  --得到今天要做的限时活动
        self:ResetVipState()  --vip
        self:ZeroDragonCstCheck()
--    elseif user_data == TIMER_ID_8 then
--        log_game_info("Avatar:onTimer", "8_point_timer id=%d", TIMER_ID_8)
        
        
        --[[
    elseif user_data == TIMER_ID_UPDATE_ONLINE_DATA then
        if self.hasTimer[timerType.DESTROY] then
            return
        end
        self:OnUpdateUserMgrData()
        ]]
    elseif user_data == TIMER_ID_FIVE_MINUTES then
        self.offlineTime = os.time()
    elseif user_data == TIMER_ID_ENERGY then
        --体力恢复定时处理
        self:EnergyNatureRcy()
    else
        log_game_warning("Avatar:onTimer","unknown timer = %d",timer_id)
    end
end

--竞技场开启之前都是由升级来触发更新，
--竞技场等级满足后只能通过竞技场来更更新战斗力以及战斗相关属性
function Avatar:OnUpdateUserMgrData(bCtrl)
    --todo:判断是否需要更新
--    log_game_debug('Avatar:OnUpdateUserMgrData', '')
    local newData = {
        [public_config.USER_MGR_PLAYER_LEVEL_INDEX] = self.level, 
    }
    if not bCtrl and self.level >= g_arena_config.OPEN_LV then
        globalbase_call("UserMgr", "Update", self.dbid, newData)
        return
    end
    --如果是竞技场需要更新usermgr上的数据，但是战斗力比历史值低则不更新
    if bCtrl and self.fightMax >= self.fightForce then
    	--log_game_debug("Avatar:OnUpdateUserMgrData","self.fightMax=%d self.fightForce=%d",self.fightMax,self.fightForce)
        globalbase_call("UserMgr", "Update", self.dbid, newData)
        return
    end

    if self.fightMax < self.fightForce then
        newData[public_config.USER_MGR_PLAYER_FIGHT_INDEX] = self.fightForce
        if self.level >= public_config.USER_MGR_DETAIL_DATA_CACHE_LEVEL then
--            log_game_debug("Avatar:OnUpdateUserMgrData", "update fight data.")
            newData[public_config.USER_MGR_PLAYER_BATTLE_PROPS] = self.baseProps
            local bodyEquip = self.inventorySystem:GetAllItem(public_config.ITEM_TYPE_AVATAR)
            local items = {}
            for _, v in pairs(bodyEquip) do
                local ntbl = 
                {
                    [public_config.USER_MGR_ITEMS_BODY_INDEX] = v[public_config.ITEM_INSTANCE_GRIDINDEX],
                    [public_config.USER_MGR_ITEMS_TYPE_INDEX] = v[public_config.ITEM_INSTANCE_TYPEID],
                    [public_config.USER_MGR_ITEMS_SLOT_INDEX] = v[public_config.ITEM_INSTANCE_SLOTS],
                }
                table.insert(items, ntbl)
            end
            newData[public_config.USER_MGR_PLAYER_ITEMS_INDEX] = items
            newData[public_config.USER_MGR_PLAYER_SKILL_BAG] = self.skillBag
            newData[public_config.USER_MGR_PLAYER_ARENIC_GRADE_INDEX] = self.arenicGrade
        end
        self.fightMax = self.fightForce
    end
    --log_game_debug("Avatar:OnUpdateUserMgrData","%s",mogo.cPickle(newData))
    globalbase_call("UserMgr", "Update", self.dbid, newData)
end

function Avatar:UpdateUserMgrAboutFight()
    local newData = {
        [public_config.USER_MGR_PLAYER_LEVEL_INDEX] = self.level, 
    }
    if self.level < g_arena_config.OPEN_LV then
        return
    end
    --如果是竞技场需要更新usermgr上的数据，但是战斗力比历史值低则不更新
    
    newData[public_config.USER_MGR_PLAYER_FIGHT_INDEX] = self.fightForce
    
    newData[public_config.USER_MGR_PLAYER_BATTLE_PROPS] = self.baseProps
    local bodyEquip = self.inventorySystem:GetAllItem(public_config.ITEM_TYPE_AVATAR)
    local items = {}
    for _, v in pairs(bodyEquip) do
        local ntbl = 
        {
            [public_config.USER_MGR_ITEMS_BODY_INDEX] = v[public_config.ITEM_INSTANCE_GRIDINDEX],
            [public_config.USER_MGR_ITEMS_TYPE_INDEX] = v[public_config.ITEM_INSTANCE_TYPEID],
            [public_config.USER_MGR_ITEMS_SLOT_INDEX] = v[public_config.ITEM_INSTANCE_SLOTS],
        }
        table.insert(items, ntbl)
    end
    newData[public_config.USER_MGR_PLAYER_ITEMS_INDEX] = items
    newData[public_config.USER_MGR_PLAYER_SKILL_BAG] = self.skillBag

    self.fightMax = self.fightForce

    globalbase_call("UserMgr", "Update",
    self.dbid,
    newData
    )
end

--redis_hash类型数据load的回调方法
function Avatar:onRedisReply(key, value)
--if key == "mails_r" then
--    g_mail_mgr:init_mails(self, value)
--elseif key == "following_r" then
--    g_friend_mgr:init_following(self, value)
--end
end

---------------------引擎可能会回调的方法 end--------------------------------------------------------------


----玩家登录游戏(onClientGetBase)之后才调用
--function Avatar:register_user_info()
--    self:registerTimeSave() --注册定时存盘
--
--    --登录时先更新一下下线时间,以防异常掉线捕获不到
--    self.offlineTime = os.time()
--
--    local dbid = self:getDbid()
--
--    --向用户管理器注册自己
----    globalbase_call("UserMgr", "register_user", self.base_mbstr, dbid)
--    --竞技场注册
----    globalbase_call("ArenaMgr", "register_user", self.base_mbstr, dbid)
----    --向帮派管理器注册
----    globalbase_call("GuildMgr", "register_user", self.base_mbstr, dbid)
----    --向社会管理器注册
----    globalbase_call("SocialMgr", "register_user", self.base_mbstr, dbid, self.name)
--end

----首次创建角色的特殊注册
--function Avatar:register_new_user_info()
--    --向用户管理器注册自己
----    globalbase_call("UserMgr", "register_new_user", self.base_mbstr, self:getDbid(),
----    self.name, self.gender, self.vocation, self.level, self.vip)
--end

----下线时调用
--function Avatar:deregister_user_info()
--    self.offlineTime = os.time()     --更新下线时间
--
----    local dbid = self:getDbid()
--
----    --向用户管理器注销自己
----    globalbase_call("UserMgr", "deregister_user", dbid)
----    --竞技场注销
----    if self.level >= 20 then
----        arena_mgr:on_arena_get_ad(self, 1)   --下线前保存自己的最新战斗数据
----    end
--    --globalbase_call("ArenaMgr", "deregister_user", dbid)
--    --向帮派管理器注销
--    --globalbase_call("GuildMgr", "deregister_user", dbid)
--    --向社会管理器注销
--    --globalbase_call("SocialMgr", "deregister_user", dbid, self.name)
--end

--创建cell部分
function Avatar:_create_cell(spBaseMb)

    log_game_debug("Avatar:_create_cell", "dbid=%q;id=%d", self:getDbid(), self:getId() )

    --存盘后才能创建cell
    if self:getDbid() == 0 then
        return
    end

    --    self.sceneId = g_GlobalParamsMgr:GetParams('init_scene', 10004)
    --    self.map_x = g_GlobalParamsMgr:GetParams('init_x', 0)
    --    self.map_y = g_GlobalParamsMgr:GetParams('init_y', 0)

    gSceneSystem:CreateCell(self, spBaseMb)

    --    gMapActionMgr:create_cell(self, self.sceneId, self.imap_id, self.map_x, self.map_y)
end

--function Avatar:GetSpaceLoaderMbResp(sp)
--    log_game_debug("Avatar:GetSpaceLoaderMbResp", "dbid=%q;id=%d;name=%s;x=%d;y=%d",
--                                                   self:getDbid(), self:getId(), self.name, self.map_x, self.map_y)
--    self:CreateCellEntity(mogo.UnpickleBaseMailbox(sp), self.map_x, self.map_y)
--end

function Avatar:SetSpaceLoaderMb(sp)
    log_game_debug("Avatar:SetSpaceLoaderMb", "dbid=%q;id=%d;name=%s;sp=%s", self:getDbid(), self:getId(), self.name, mogo.cPickle(sp))

    self.SpaceLoaderMb = sp
end

--初始玩家升级
function Avatar:on_levelup()
    log_game_info("Avatar:on_levelup", "dbid=%q;level=%d", self.dbid, self.level)

    --更新UserMgr那里的等级
    globalbase_call("UserMgr", "update_user_info", self.dbid,
    public_config.USERINFO_KEY_LEVEL, self.level)
end


--local function avatar_writetodb_callback(entity, dbid, db_err)
----do nothing
--end

----客户端timer
--function Avatar:on_client_timer(timer_id)
--    if timer_id == public_config.CLIENT_TIMER_ID_4CLOCK then
--        self:reset_4clock_data()
--    elseif timer_id == public_config.CLIENT_TIMER_ID_21CLOCK then
--        arena_mgr:reset_arena_count(self)
--    elseif timer_id == public_config.CLIENT_TIMER_ID_TLCLOCK then
--        misc_mgr:restore_tl(self)
--    elseif timer_id == public_config.CLIENT_TIMER_ID_SITCLOCK then
--        misc_mgr:restore_sit(self)
--    end
--end


----任务事件触发
--function Avatar:on_quest_event(event_id, params)
--    --任务事件
--    quest_mgr:on_event(self, event_id, params)
--end
--
----事件触发,和任务事件独立开
--function Avatar:on_event(event_id, params)
--    --其他事件
--    event_mgr:on_event(self, event_id, params)
--end

----客户端请求一个table类型的值
--function Avatar:table_get_req(prop_name)
--    local t = self[prop_name] or {}
--    self.client.table_get_resp(prop_name, t)
--end

---执行gm指令
--function Avatar:gm_req(req)
--    g_gm_mgr:dispatch(self, req)
--end

--玩家进入传送点校验
function Avatar:EnterTeleportpointReq(tp_eid)
    --    generic_avatar_call_ne0(self, action_config.TELEPORT_ENTER_POINT, map_mgr, "enter_teleportpoint_req",
    --        "tp_eid=%d", tp_eid)

    --    --暂时不做状态校验
    --    gMapActionMgr:EnterTeleportpointReq(self, tp_eid)
    log_game_debug("Avatar:EnterTeleportpointReq", "tp_eid=%d", tp_eid)
    generic_avatar_call_ne0(self, action_config.TELEPORT_ENTER_POINT, gSceneSystem, "EnterTeleportpointReq", "tp_eid=%d", tp_eid)
--    gSceneSystem:EnterTeleportpointReq(self, tp_eid)
end

--玩家在cell上校验了距离以后回调到base
function Avatar:TeleportCell2Base(targetSceneId, targetX, targetY)
    gSceneSystem:TeleportCell2Base(self, targetSceneId, targetX, targetY)
end

--无论是哪一种切换space的方式都调用，通知base
function Avatar:ChangeScene(scene, line, x, y)

    log_game_debug("Avatar:ChangeScene", "dbid=%q;id=%d;sceneId=%d;imap_id=%d;map_x=%d;map_y=%d;scene=%d;line=%d;x=%d;y=%d", self:getDbid(), self:getId(), self.sceneId, self.imap_id, self.map_x, self.map_y, scene, line, x, y)

--    --副本正式切成功时才通知地图管理器
--    --只有切换到不同的场景分线时，才需要更新人数
--    if scene ~= self.sceneId or line ~= self.imap_id then
--        globalbase_call("MapMgr", "ChangeMapCount", public_config.CHANGE_MAP_COUNT_ADD, scene, line, 1)
--        globalbase_call("MapMgr", "ChangeMapCount", public_config.CHANGE_MAP_COUNT_SUB, self.sceneId, self.imap_id, 1)
--    end

    --如果这时候base拥有cell，则说明玩家是在同一个cell进程之间跳转，则由这个函数负责同步场景、分线id给客户端，否则，由ongetcell函数负责
    if self:HasCell() then
--    if self.sceneId ~= scene then
        self.sceneId = scene
--    end

--    if self.imap_id ~= line then
        self.imap_id = line
--    end

--    if self.map_x ~= x then
        self.map_x = x
--    end

--    if self.map_y ~= y then
        self.map_y = y
    end
--    end

    self.mercenaryDbid = 0


    --跳转场景成功后通知关卡子系统
    gMissionSystem:OnChangeScene(self, scene, line)

    gTowerSystem:OnChangeScene(self, scene)

    --把avatar上正在进出场景的状态去掉
    self.state = mogo.sunset(self.state, state_config.STATE_SCENE_CHANGING)

    if g_map_mgr:IsWBMap(scene) then
        log_game_debug("MissionSystem:OnChangeScene", "EnterResp")
        --跳转世界Boss成功后通知世界Boss管理器
        local mm = globalBases['WorldBossMgr'] 
        if not mm then 
            log_game_debug("MissionSystem:OnChangeScene", "no mm.")
        end
        --(dbid, name, level, mbStr, errId)
        self:triggerEvent(event_config.EVENT_ENTER_BOSS, event_config.EVENT_ENTER_BOSS) --触发 参加世界boss事件
        local mapId = tostring(scene) .. "_" .. tostring(line)
        mm.EnterResp(self.dbid, self.name, self.level, mapId, self.base_mbstr, 0)
    end
end

function Avatar:TeleportRemotely(spBaseMb, sceneId, line, x, y)

    log_game_debug("Avatar:TeleportRemotely", "dbid=%q;id=%d;name=%s;spBaseMb=%s;sceneId=%s;line=%d;x=%d;y=%d;tmp_data=%s", self:getDbid(), self:getId(), self.name, mogo.cPickle(spBaseMb), sceneId, line, x, y, mogo.cPickle(self.tmp_data))

    if g_GlobalParamsMgr:GetParams('init_scene', 10004) == sceneId
    and self.tmp_data[public_config.TMP_DATE_KEY_KINDOM_X]
    and self.tmp_data[public_config.TMP_DATE_KEY_KINDOM_Y] then

        local locations = g_GlobalParamsMgr:GetParams('init_scene_random_enter_point', {})
        local index = math.random(1, lua_util.get_table_real_count(locations))

        log_game_debug("Avatar:TeleportRemotely init_scene", "dbid=%q;id=%d;name=%s;sceneId=%s;line=%d;x=%d;y=%d", self:getDbid(), self:getId(), self.name, sceneId, line, locations[index][1], locations[index][2])

        gSceneSystem:TeleportRemotely(self, spBaseMb, sceneId, line, locations[index][1], locations[index][2])

        self.tmp_data[public_config.TMP_DATE_KEY_KINDOM_X] = nil
        self.tmp_data[public_config.TMP_DATE_KEY_KINDOM_Y] = nil
    else
        --    gMapActionMgr:TeleportRemotely(self, sceneId, line, x, y)
        gSceneSystem:TeleportRemotely(self, spBaseMb, sceneId, line, x, y)
    end

end

function Avatar:TelportSameCell(spId, sceneId, x, y)

    log_game_debug("Avatar:TelportSameCell", "dbid=%q;id=%d;name=%s;spId=%d,sceneId=%d;x=%d;y=%d;tmp_data=%s", self:getDbid(), self:getId(), self.name, spId, sceneId, x, y, mogo.cPickle(self.tmp_data))

    if g_GlobalParamsMgr:GetParams('init_scene', 10004) == sceneId 
    and self.tmp_data[public_config.TMP_DATE_KEY_KINDOM_X] 
    and self.tmp_data[public_config.TMP_DATE_KEY_KINDOM_Y] then

        local locations = g_GlobalParamsMgr:GetParams('init_scene_random_enter_point', {})
        local index = math.random(1, lua_util.get_table_real_count(locations))
        self.cell.TelportSameCell(spId, locations[index][1], locations[index][2])

        self.tmp_data[public_config.TMP_DATE_KEY_KINDOM_X] = nil
        self.tmp_data[public_config.TMP_DATE_KEY_KINDOM_Y] = nil
    else
        --    gMapActionMgr:TeleportRemotely(self, sceneId, line, x, y)
        self.cell.TelportSameCell(spId, x, y)
    end
end

function Avatar:SelectMapResp(map_id, imap_id, spBaseMb, spCellMb, dbid, params)

    local spBaseMbStr =  mogo.cPickle(spBaseMb)

    log_game_debug("Avatar:SelectMapResp", "dbid=%q;id=%d;sceneId=%d;imap_id=%d;spBaseMb=%s;spCellMb=%s;params=%s", self:getDbid(), self:getId(), map_id, imap_id, spBaseMbStr, mogo.cPickle(spCellMb), mogo.cPickle(params))


    self:SetSpaceLoaderMb(mogo.UnpickleBaseMailbox(spBaseMbStr))

    if not self:HasCell() then
        --当地图管理器返回地图分线信息时，Avatar已经没有了cell部分
        log_game_warning("Avatar:SelectMapResp", "dbid=%q;id=%d;sceneId=%d;imap_id=%d;spBaseMb=%s;spCellMb=%s;params=%s", self:getDbid(), self:getId(), map_id, imap_id, spBaseMbStr, mogo.cPickle(spCellMb), mogo.cPickle(params))
        return
    end

    if map_id == self.sceneId and imap_id == self.imap_id then

        local MapCfgData = g_map_mgr:getMapCfgData(self.sceneId)
        --如果是同一场景，但是不在场景进入点，则teleport到场景进入点
        if MapCfgData and (MapCfgData['enterX'] ~= self.map_x or MapCfgData['enterY'] ~= self.map_y) then
            self.cell.TelportLocally(MapCfgData['enterX'], MapCfgData['enterY'])
        end

    else
        --如果玩家在王城，记录王城的坐标
        if self.sceneId == g_GlobalParamsMgr:GetParams('init_scene', 10004) then
            self.tmp_data[public_config.TMP_DATE_KEY_KINDOM_X] = self.map_x
            self.tmp_data[public_config.TMP_DATE_KEY_KINDOM_Y] = self.map_y
        end

        local MapCfgData = g_map_mgr:getMapCfgData(map_id)
        if self.cell[public_config.MAILBOX_KEY_SERVER_ID] == spCellMb[public_config.MAILBOX_KEY_SERVER_ID] then
            local sp_id = spCellMb[public_config.MAILBOX_KEY_ENTITY_ID]

            if map_id == g_GlobalParamsMgr:GetParams('tower_defence_scene_id', 30002) then

                self.tmp_data[public_config.TMP_DATA_KEY_MISSION_DATA] = {0, g_GlobalParamsMgr:GetParams("tower_defence_mission", 30002), g_GlobalParamsMgr:GetParams("tower_defence_difficulty", 1),}

                local locations = g_GlobalParamsMgr:GetParams('tower_defence_scene_random_enter_point', {})
                local index = math.random(1, lua_util.get_table_real_count(locations))
                self:TelportSameCell(sp_id, map_id, locations[index][1], locations[index][2])

                --如果玩家进入的是塔防副本，则触发事件
                self:OnOrc()

                log_game_debug("Avatar:SelectMapResp 1", "dbid=%d;name=%s;map_id=%d;x=%d;y=%d", self.dbid, self.name, map_id, locations[index][1], locations[index][2])

            elseif map_id == g_GlobalParamsMgr:GetParams('defense_pvp_map_id', DEFENSE_PVP_MAP_ID) then
                local points = g_GlobalParamsMgr:GetParams('defense_pvp_enter_point', DEFENSE_PVP_RELIVE_POINT)
                local index = 1
                if params then
                    index = params[1] or 1
                    if index ~= 1 and index ~= 2 then index = 1 end
                end

                self:TelportSameCell(sp_id, map_id, points[index][1], points[index][2])

                log_game_debug("Avatar:SelectMapResp 2", "dbid=%d;name=%s;map_id=%d;x=%d;y=%d", self.dbid, self.name, map_id, points[index][1], points[index][2])

            else
                self:TelportSameCell(sp_id, map_id, MapCfgData['enterX'], MapCfgData['enterY'])

                log_game_debug("Avatar:SelectMapResp 3", "dbid=%d;name=%s;map_id=%d;x=%d;y=%d", self.dbid, self.name, map_id,  MapCfgData['enterX'], MapCfgData['enterY'])
            end

        else
            if map_id == g_GlobalParamsMgr:GetParams('tower_defence_scene_id', 30002) then

                self.tmp_data[public_config.TMP_DATA_KEY_MISSION_DATA]  = {0, g_GlobalParamsMgr:GetParams("tower_defence_mission", 30002), g_GlobalParamsMgr:GetParams("tower_defence_difficulty", 1),}

                local locations = g_GlobalParamsMgr:GetParams('tower_defence_scene_random_enter_point', {})
                local index = math.random(1, lua_util.get_table_real_count(locations))
                self:TeleportRemotely(spBaseMb, map_id, imap_id, locations[index][1], locations[index][2])

                --如果玩家进入的是塔防副本，则触发事件
                self:OnOrc()

                log_game_debug("Avatar:SelectMapResp 4", "dbid=%d;name=%s;map_id=%d;x=%d;y=%d", self.dbid, self.name, map_id, locations[index][1], locations[index][2])

            elseif map_id == g_GlobalParamsMgr:GetParams('defense_pvp_map_id', DEFENSE_PVP_MAP_ID) then
                local points = g_GlobalParamsMgr:GetParams('defense_pvp_enter_point', DEFENSE_PVP_RELIVE_POINT)
                local index = 1
                if params then
                    index = params[1] or 1
                    if index ~= 1 and index ~= 2 then index = 1 end
                end

                self:TeleportRemotely(spBaseMb, map_id, imap_id, points[index][1], points[index][2])

                log_game_debug("Avatar:SelectMapResp 5", "dbid=%d;name=%s;map_id=%d;x=%d;y=%d", self.dbid, self.name, map_id, points[index][1], points[index][2])

            else
                self:TeleportRemotely(spBaseMb, map_id, imap_id, MapCfgData['enterX'], MapCfgData['enterY'])

                log_game_debug("Avatar:SelectMapResp 6", "dbid=%d;name=%s;map_id=%d;x=%d;y=%d", self.dbid, self.name, map_id, MapCfgData['enterX'], MapCfgData['enterY'])

            end

        end

    end

end

--当场景跳转失败时返回
function Avatar:SelectMapFailResp(scene, line)
    if g_map_mgr:IsWBMap(scene) then
        --跳转世界Boss成功后通知世界Boss管理器
        local mm = globalBases['WorldBossMgr']
        local mapId = tostring(scene) .. "_" .. tostring(line)
        log_game_debug("Avatar:SelectMapFailResp", mapId)
        mm.EnterResp(self.dbid, self.name, self.level, mapId, self.base_mbstr, -1)
    end
end

--传送成功的回调,参数:sceneId,x,y
function Avatar:on_teleport_suc_resp()
    gSceneSystem:on_teleport_suc_resp(self)
    --    gMapActionMgr:on_teleport_suc_resp(self)
end

--传送失败的回调
function Avatar:on_teleport_fail_resp()
    gSceneSystem:on_teleport_fail_resp(self)
    --    gMapActionMgr:on_teleport_fail_resp(self)
end

----获取服务器时间
--function Avatar:get_server_time_req(clienttime)
--    self.client.get_server_time_resp(clienttime, os.time())
--end

function Avatar:DelDestroyTimer()
    if self.hasTimer[timerType.DESTROY] then
        self:delTimer(self.hasTimer[timerType.DESTROY])
        self.hasTimer[timerType.DESTROY] = nil
    end
end

function Avatar:UseSkillReq(clientTick, x, y, face, skillID, targetsID)
    self.cell.UseSkillReq(clientTick, x, y, face, skillID, targetsID)
end

function Avatar:MercenaryUseSkillReq(clientTick, mercenaryID, x, y, face, skillID, targetsID)
    self.cell.MercenaryUseSkillReq(clientTick, mercenaryID, x, y, face, skillID, targetsID)
end

function Avatar:ChargeSkillReq(clientTick)
    self.cell.ChargeSkillReq(clientTick)
end

function Avatar:CancelChargeSkillReq()
    self.cell.CancelChargeSkillReq()
end

function Avatar:Chat(ChannelId, to_dbid, msg)

    log_game_debug("Avatar:Chat", "ChannelId=%d;to_dbid=%q;msg=%s", ChannelId, to_dbid, msg)

    if string.len(msg) > 1 and string.byte("@") == string.byte(msg) then
        local cmd = string.sub(msg, 2) --去掉@符号就是cmd命令
        log_game_debug("Avatar:Chat", "msg=%s,cmdLine=%s", msg, cmd)
        local ret = self:Execute(cmd)
        local  gm_msg = "gm failed!! errorcode:" .. ret
        if (ret == 0) then
            gm_msg = "gm success!!"
        end
        self:ChatResp(public_config.CHANNEL_ID_PERSONAL, self.dbid, "GM", self.level, msg)
        self:ChatResp(public_config.CHANNEL_ID_PERSONAL, self.dbid, "GM", self.level, gm_msg)
        return
    end


        if not self:CanSpeak() then 
            --todo 这里的中文要改成chinesedata id
            if self.noSpeakTime == public_config.NO_SPEAK_FOREVER then --永久禁言
                self:ShowTextID(CHANNEL.CHATDLG, 1007012)
                return
            else
                local left_time = math.floor((self.noSpeakTime - os.time()) / 60) --剩余多少分钟
                self:ShowTextID(CHANNEL.CHATDLG, 1007010 ,left_time)
                return
            end      
        else  
             self:ban_chat(0, 0, "u can speak now") ----封号/解封标识.1=封号； 0=解封   
        end 


    if self.bannedToPost[1] ~= nil and self.bannedToPost[2] ~= nil then
        if self.bannedToPost[1] + self.bannedToPost[2] < os.time() then
            local msg = "banned chat"
            self:ChatResp(public_config.CHANNEL_ID_PERSONAL, self.dbid, self.name, self.level, msg)
            return
        end 
    end

    if ChannelId == public_config.CHANNEL_ID_UNION then
        globalbase_call("GuildMgr", "Chat", self.dbid, self.name, self.level, self.base_mbstr, msg)
    elseif ChannelId == public_config.CHANNEL_ID_TOWER_DEFENCE then
        if self.SpaceLoaderMb then
            self.SpaceLoaderMb.Chat(ChannelId, to_dbid, msg, self.name)
        end
    elseif ChannelId == public_config.CHANNEL_ID_DEFECSE_PVP then
        if self.defensePvPSystem then
            self.defensePvPSystem:OnChat(msg)
        end
    elseif ChannelId == public_config.CHANNEL_ID_WORLD then
        global_data:channel_req(ChannelId, self.dbid, self.name, to_dbid, msg, self.level)
    else
        globalbase_call("UserMgr", "Chat", ChannelId, self.dbid, self.name, self.level, self.base_mbstr, to_dbid, msg)
    end

end

function Avatar:PickDropReq(dropEid)
    log_game_debug("Avatar:PickDropReq", "dropEid=%d;dbid=%q;name=%s", dropEid, self.dbid, self.name)
    self.cell.PickDropReq(dropEid)
end

------------------------------------baseMethods属性变化函数 begin----------------------------------------------------------
function Avatar:AddExp(addExp, condition)
    if addExp == 0 then
        return
    end

    log_game_info("Avatar:AddExp", "dbid=%q;name=%s;exp=%d;addExp=%d;reason=%d", self.dbid, self.name, self.exp, addExp, condition)

    if self.level >= g_GlobalParamsMgr:GetParams('hightest_level', 50) then
        log_game_warning("Avatar:AddExp", "dbid=%q;name=%s;level=%d", self.dbid, self.name, self.level)
        return
    end

    local cur_exp = self.exp + addExp
    local level = self.level
    
    local cfgs = g_avatar_level_mgr:getCfg()
    if cfgs and cfgs[level] then

        if cur_exp >= cfgs[level].nextLevelExp then --加的经验足以升级
            if self:LevelUp() then
                self:AddExp(cur_exp - cfgs[level].nextLevelExp, condition) --升级成功， 将剩下的经验继续递归 确保每次升级都触发
            end            
        else
            self.exp = cur_exp
        end
    end

end
--增加竞技场荣誉arenicGrade arenicCredit
function Avatar:AddCredit(value)
    log_game_info("Avatar:AddCredit", "dbid=%q;name=%s;arenicCredit=%d;addCredit=%d",
        self.dbid, self.name, self.arenicCredit, value)
    self.arenicCredit = self.arenicCredit + value
    local tt = g_arenic_level:GetCredit(self.arenicGrade + 1)
    if tt <= self.arenicCredit then
        self.arenicGrade = self.arenicGrade + 1
        self:triggerEvent(event_config.EVENT_AVATAR_PROPERTIES_RECALCULATE)
    end
end

function Avatar:LevelUp()

    local bLevelUp = false
    local level = self.level
    local cfgs = g_avatar_level_mgr:getCfg()
    if cfgs[level+1] then --不能超过最高级

        local last_level = self.level
        local last_exp  = self.exp

        self.level = self.level + 1
        self.exp = 0  --升级成功这里需要 设置经验为0

        bLevelUp = true 
        self:OnLevelUp(last_level, last_exp)   
     end

     return bLevelUp
end

function Avatar:OnLevelUp(_level, _exp)

        --升级触发的事件
        self:DealWithLevelUpEvent()
        g_energy_mgr:RewardLevelUp(self, _level)
        self:ProcessBaseProperties()
        self:refresh_day_task() --刷新日常任务(等级变化可能会引起日常任务的接取)
        globalbase_call('EventMgr', 'OnLevelUp', self.base_mbstr)
        self:triggerEvent(event_config.EVENT_ROLE_LEVELUP, event_config.EVENT_ROLE_LEVELUP, self.level)

        local accountName, platName = self:SplitAccountNameByString(self.accountName)

        local insert_table =  {
                    role_id         = self.dbid,        --角色ID
                    role_name       = self.name,        --角色名
                    account_name    = accountName, --平台账号
                    plat_name       = platName,
                    last_level      = _level,           --上一等级
                    current_level   = self.level,       --当前等级
                    last_exp        = _exp,             --上一经验值
                    current_exp     = self.exp,         --当前经验值
                    happend_time    = os.time(),        --变动时间
                }

    globalbase_call("Collector", "table_insert", "tbllog_level_up", insert_table)    
end

--升级触发的事件
function Avatar:DealWithLevelUpEvent()
    self:OnUpdateUserMgrData()
    if self.level >= g_arena_config.OPEN_LV then
        --new 子系统
        if self.tmp_data[public_config.TMP_DATA_KEY_ARENA] == 0 then
            --第一次开启竞技场
            self:OnUpdateUserMgrData(true)
            self.arenaSystem = ArenaSystem:new(self)
            if self.arenaSystem then
                self.arenaSystem:Login()
            end
            --全局管理器里增加一个玩家信息
            local mm = globalBases["ArenaMgr"]
            if mm then
                log_game_debug("Avatar:LevelUp", "self.fightForce[%d]", self.fightForce)
                mm.AddNewPlayer(self.dbid, self.fightForce, self.level)
            end
        end
    end
end

function Avatar:MarkCheat(u8IsKick)
    self.cheatCount = self.cheatCount + 1
    if u8IsKick ~= 0 then
        self.cheatKickCount = self.cheatKickCount + 1
    end
end


------------------------------------中转函数 begin----------------------------------------------------------

function Avatar:DrawGift(grid_id)
    if not self.levelGiftSystem then
        log_game_error("Avatar:DrawGift", "levelGiftSystem is nil dbid=%q;name=%s", self.dbid, self.name)
        return
    end

    self.levelGiftSystem:OnDrawGift(grid_id)
end

function Avatar:LevelGiftRecordReq()
    if not self.levelGiftSystem then
        log_game_error("Avatar:LevelGiftRecordReq", "levelGiftSystem is nil dbid=%q;name=%s", self.dbid, self.name)
        return
    end

    self.levelGiftSystem:OnLevelGiftRecordReq()
end

function Avatar:HotSalesBuy(version, item_id, price_type, price)
    if not self.hotSalesSystem then
        log_game_error("Avatar:HotSalesBuy", "hotSalesSystem is nil dbid=%q;name=%s", self.dbid, self.name)
        return
    end

    self.hotSalesSystem:OnHotSalesBuy(version, item_id, price_type, price)
end

function Avatar:HotSalesVersionCheck(version)
    if not self.hotSalesSystem then
        log_game_error("Avatar:HotSalesVersionCheck", "hotSalesSystem is nil dbid=%q;name=%s", self.dbid, self.name)
        return
    end

    self.hotSalesSystem:OnHotSalesVersionCheck(version)
end

function Avatar:MarketBuy(version, grid_id, item_id, item_number, price_now, buy_count)
    if not self.marketSystem then
        log_game_error("Avatar:MarketBuy", "marketSystem is nil dbid=%q;name=%s", self.dbid, self.name)
        return
    end

    self.marketSystem:OnMarketBuy(version, grid_id, item_id, item_number, price_now, buy_count)
end

function Avatar:MarketGridDataReq(version, grid_id)
    if not self.marketSystem then
        log_game_error("Avatar:MarketGridDataReq", "marketSystem is nil dbid=%q;name=%s", self.dbid, self.name)
        return
    end

    self.marketSystem:OnMarketGridDataReq(version, grid_id)
end

function Avatar:MarketVersionCheck(version)
    if not self.marketSystem then
        log_game_error("Avatar:MarketVersionCheck", "marketSystem is nil dbid=%q;name=%s", self.dbid, self.name)
        return
    end

    self.marketSystem:OnMarketVersionCheck(version)
end

function Avatar:TransferMarketDataReq()
    if not self.marketSystem then
        log_game_error("Avatar:TransferMarketDataReq", "marketSystem is nil dbid=%q;name=%s", self.dbid, self.name)
        return
    end

    self.marketSystem:OnTransferMarketData()
end

------------------------------------------------------------------------<
--道具系统
------------------------------------------------------------------------<
--更新单条数据给客服端
function Avatar:UpdateItem(op, item)
    if self.inventorySystem then
        if self:hasClient() then
            self.client.UpdateItem(op, item)
        end
    end
end
--更新批量数据给客服端
function Avatar:UpdateArrayItem(list)
    if self.inventorySystem then
        if self:hasClient() then
            self.client.UpdateArrayItem(list)
        end
    end
end

--客服端调用整理背包接口
function Avatar:TidyInventory()
    if self.inventorySystem then
        self.inventorySystem:TidyInventory()
        return
    end
    log_game_error("Avatar:TidyInventory", "inventorySystem is nil dbid=%q;name=%s", self.dbid, self.name)
end
--客服端请求全部背包数据
function Avatar:InventoryReq()
    if self.inventorySystem then
        self.inventorySystem:UpdateArrayToClient()
        return
    end
    log_game_error("Avatar:InventoryReq", "inventorySystem is nil dbid=%q;name=%s", self.dbid, self.name)
end
--换装请求
function Avatar:ExchangeEquipment(id, idx)
    if self.inventorySystem then
        --log_game_info("Avatar:ExchangeEquipment", "id = %s idx = %s", tostring(id), tostring(idx))
        local id, respCode = self.inventorySystem:ReplaceEquipment(id, idx + 1)
        if id ~= -1 then
            self:triggerEvent(event_config.EVENT_AVATAR_PROPERTIES_RECALCULATE)
        end
        if self:hasClient() then
            self.client.RespsForChgAndRmEquip(id, respCode)
            log_game_debug("Avatar:ExchangeEquipment", "dbid=%q;name=%s;typeId=%d;retCode=%d", 
                self.dbid, self.name, id, respCode)
        end
        return
    end
    log_game_error("Avatar:ExchangeEquipment", "inventorySystem is nil dbid=%q;name=%s", self.dbid, self.name)
end
--卸装功能未用注释掉
-- function Avatar:RemoveEquipment(id, idx)
--     if self.inventorySystem then
--         local id, respCode = self.inventorySystem:RemoveEquipment(id, idx + 1)
--         if id ~= -1 then
--             self:triggerEvent(event_config.EVENT_AVATAR_PROPERTIES_RECALCULATE)
--             --self:ProcessBaseProperties()
--         end
--         --log_game_debug("RemoveEquipment", "id = %d respCode = %d", id, respCode)
--         if self:hasClient() then
--             self.client.RespsForChgAndRmEquip(id, respCode)
--         end
--         return
--     end
--     log_game_error("Avatar:RemoveEquipment", "inventorySystem is nil")
-- end
function Avatar:DecomposeEquipment(id, idx)
    if self.inventorySystem then
        local index, ret, hasJewel = self.inventorySystem:DecomposeEquipment(id, idx + 1)
        if self:hasClient() then
            if hasJewel then
                hasJewel = 1
            else
                hasJewel = 0
            end
            self.client.DeEquipmentResp(idx, ret, hasJewel)
        end
--        log_game_debug("Avatar:DecomposeEquipment", "idx = %d ret = %d", index, ret)
        return
    end
    log_game_error("Avatar:RemoveEquipment", "inventorySystem is nil dbid=%q;name=%s", self.dbid, self.name)
end
function Avatar:ReqForLock(id, idx)
    if self.inventorySystem then
        local ret = self.inventorySystem:LockEquipment(id, idx + 1)
        --log_game_debug("Avatar:ReqForLock", "idx = %d, ret = %d", idx, ret)
        if self:hasClient() then
            self.client.ReqForLockResp(idx, ret)
        end
        return
    end
    log_game_error("Avatar:ReqForLock", "inventorySystem is nil dbid=%q;name=%s", self.dbid, self.name)
end
function Avatar:InitItemsForAvatar(vocation, dbid)
    if self.inventorySystem then
        self.inventorySystem:CreateRoleInitItems(vocation, dbid)
        return
    end
    log_game_error("Avatar:InitItemsForAvatar", "inventorySystem is nil dbid=%q;name=%s", self.dbid, self.name)
end

--add item to invtry
function Avatar:add_item(typeId, count)
   self:AddItem(typeId, count, reason_def.gm)
end
function Avatar:del_item(typeId, count)
    self:DelItem(typeId, count, reason_def.gm)
end
-- function Avatar:del_equip(id, idx)
--     if self.inventorySystem then
--         local tbl = self.inventorySystem:DelForEquip(id, idx)
--         return
--     end
--     log_game_error("Avatar:DelItemForTest", "inventorySystem is nil")
-- end

function Avatar:SellForItems(id, idx, typeId, count)
    if self.inventorySystem then
        local ret = self.inventorySystem:SellItems(id, idx + 1, typeId, count)
        if self:hasClient() then
            self.client.SellForResp(ret)
        end
        return
    end
    log_game_error("Avatar:SellForItems", "inventorySystem is nil dbid=%q;name=%s", self.dbid, self.name)
end
-----------------道具使用----------------------
--没有效果id的道具可以批量使用，有效果id的道具只能一次使用一个
function Avatar:UseItemReq(id, idx, count)
    if self.inventorySystem then
        local typeId, ret, tbl = self.inventorySystem:UseItem(id, idx + 1, count)
        if self:hasClient() then
            self.client.UseItemResp(typeId, ret, tbl or {})
        end
        return
    end
    log_game_error("Avatar:UseItemReq", "inventorySystem is nil dbid=%q;name=%s", self.dbid, self.name)
end
------------------------------------------------------------------->
------------------------------------------------------------------->
------------------------------------------------------------------------------------------------------------------
function Avatar:MissionReq(msg_id, arg1, arg2, arg3)

    generic_avatar_call_ne0(self, msg_id, gMissionSystem, gMissionSystem:getFuncByMsgId(msg_id), "", arg1, arg2, arg3)
--    if self.missionSystem then
--        self.missionSystem:MissionReq(msg_id, arg1, arg2, arg3)
--    end
end

function Avatar:MissionExReq(msg_id, arg1, arg2, arg3, arg4)

    generic_avatar_call_ne0(self, msg_id, gMissionSystem, gMissionSystem:getFuncByMsgId(msg_id), "", arg1, arg2, arg3, arg4)
end

function Avatar:MissionC2BReq(msg_id, arg1, arg2, arg3)
    generic_avatar_call_ne0(self, msg_id, gMissionSystem, gMissionSystem:getC2BFuncByMsgId(msg_id), "", arg1, arg2, arg3)
end

function Avatar:set_mission_finished(MissionId, difficulty, Star)
    log_game_debug("Avatar:set_mission_finished", "dbid=%q;name=%s;MissionId=%d;difficulty=%d;Star=%d",
    self.dbid, self.name, MissionId, difficulty, Star)
    gMissionSystem:GmAddFinishedMissions(self, MissionId, difficulty, Star)
end

function Avatar:reset_mission()
    log_game_debug("Avatar:reset_mission", "dbid=%q;name=%s", self.dbid, self.name)
    self.FinishedMissions = {}
end

function Avatar:set_mission_times(MissionId, difficulty, times)
    log_game_debug("Avatar:set_mission_times", "dbid=%q;name=%s;MissionId=%d;difficulty=%d;times=%d",
                                                self.dbid, self.name, MissionId, difficulty, times)
    if self.MissionTimes[MissionId] then
        self.MissionTimes[MissionId][difficulty] = times
    else
        self.MissionTimes[MissionId] = {[difficulty] = times,}
    end
end

function Avatar:gotomission(mission, difficulty)
    gMissionSystem:GotoMission(self, mission, difficulty)
end

function Avatar:finishmission(mission, difficulty)
    gMissionSystem:FinishMission(self, mission, difficulty)
end

function Avatar:trigger_mwsy()
    gMissionSystem:trigger_mwsy(self)
end

function Avatar:CampaignReq(msg_id, arg1, arg2, arg3)
    generic_avatar_call_ne0(self, msg_id, gCampaignSystem, gCampaignSystem:getFuncByMsgId(msg_id) or "", "", arg1, arg2, arg3)
end

function Avatar:CampaignC2BReq(msg_id, arg1, arg2, arg3)
    generic_avatar_call_ne0(self, msg_id, gCampaignSystem, gCampaignSystem:getC2BFuncByMsgId(msg_id) or "", "", arg1, arg2, arg3)
end

function Avatar:TowerReq(msg_id, arg1, arg2, arg3)
--    if self.towerSystem then
--        self.towerSystem:TowerReq(msg_id, arg1, arg2, arg3)
--    end
    generic_avatar_call_ne0(self, msg_id, gTowerSystem, gTowerSystem:getFuncByMsgId(msg_id), "", arg1, arg2, arg3)

end

function Avatar:TowerC2BReq(msg_id, arg1, arg2, arg3)
    generic_avatar_call_ne0(self, msg_id, gTowerSystem, gTowerSystem:getC2BFuncByMsgId(msg_id), "", arg1, arg2, arg3)
end

function Avatar:GuildReq(msg_id, arg1, arg2, arg3)
    generic_avatar_call_ne0(self, msg_id, gGuildSystem, gGuildSystem:getFuncByMsgId(msg_id), "", arg1, arg2, arg3)
--    if self.guildSystem then
--        self.guildSystem:GuildReq(msg_id, arg1, arg2, arg3)
--    end
end

function Avatar:GuildB2BReq(msg_id, arg1, arg2, arg3)
    generic_avatar_call_ne0(self, msg_id, gGuildSystem, gGuildSystem:getB2BFuncByMsgId(msg_id), "", arg1, arg2, arg3)
end

function Avatar:set_tower_current_level(level)
    log_game_debug("Avatar:set_tower_current_level", "dbid=%q;name=%s;level=%d", self.dbid, self.name, level)
    self.TowerInfo[tower_config.TOWER_INFO_CURRENT_FLOOR] = level
end

function Avatar:set_tower_highest_level(level)
    log_game_debug("Avatar:set_tower_highest_level", "dbid=%q;name=%s;level=%d", self.dbid, self.name, level)

    self.TowerInfo[tower_config.TOWER_INFO_HIGHEST_FLOOR] = level
    self.TowerHighestFloor = level
end

function Avatar:clear_sweep_cd()
    log_game_debug("Avatar:clear_sweep_cd", "dbid=%q;name=%s", self.dbid, self.name)

    self.TowerInfo[tower_config.TOWER_INFO_LAST_SWEEP_TIME] = 0
    self.TowerInfo[tower_config.TOWER_INFO_VIP_SWEEP_TIMES] = 0
end

function Avatar:start_tower_defence_match()
    log_game_debug("Avatar:start_tower_defence_match", "dbid=%q;name=%s", self.dbid, self.name)

    globalbase_call('ActivityMgr', 'TowerDefenceMatch')
end

function Avatar:start_activity(id)
    log_game_debug("Avatar:start_activity", "dbid=%q;name=%s;id=%d", self.dbid, self.name, id)

    globalbase_call('ActivityMgr', 'StartActivity', id)
end

function Avatar:stop_activity(id)
    log_game_debug("Avatar:stop_activity", "dbid=%q;name=%s;id=%d", self.dbid, self.name, id)

    globalbase_call('ActivityMgr', 'StopActivity', id)
end

function Avatar:TaskCompleteReq(taskId)
    if self.taskSystem then
        self.taskSystem:ApplyComplete(taskId)
    end
end

-->与UserMgr交互接口
function Avatar:LoginUserMgr(props)
    --log_game_debug("Avatar:LoginUserMgr", "%s", mogo.cPickle(props))
    for k,v in pairs(props) do
        if self[k] then
            self[k] = v
        end
    end
end

function Avatar:QueryInfoByPlayerNameResp( MsgId, PlayerName, PlayerInfo )
    if self:FriendQueryInfoByPlayerNameResp( MsgId, PlayerName, PlayerInfo ) then
        --log_game_debug("Avatar:FriendQueryInfoByPlayerNameResp", " msgid = %d", MsgId)
    else
        log_game_error("Avatar:QueryInfoByPlayerNameResp", "unknown msgid = %d", MsgId)
    end
    --[[
    if msgUserMgr.MSG_USER_FRIEND_QUERY_BY_NAME == MsgId then
    local err = error_code.ERR_FRIEND_SUCCEED
    if not PlayerInfo or lua_util.get_table_real_count(PlayerInfo) == 0 then
    PlayerInfo = {}
    err = error_code.ERR_FRIEND_NOT_EXISTS
    end
    self.client.OnFriendResearchReqResp(PlayerInfo, err)
    else
    log_game_debug("Avatar:QueryInfoByPlayerNameResp", "unknown msgid = %d", MsgId)
    end
    ]]
end

function Avatar:QueryInfoByPlayerDbidResp( MsgId, PlayerDbid, PlayerInfo )
    if self:FriendQueryInfoByPlayerDbidResp( MsgId, PlayerDbid, PlayerInfo ) then
        --log_game_debug("Avatar:FriendQueryInfoByPlayerDbidResp", " msgid = %d", MsgId)
    else
        log_game_error("Avatar:FriendQueryInfoByPlayerDbidResp", "unknown msgid = %d", MsgId)
    end
    --[[
    --查看好友详细信息,这个如果好友在线可以查看更多好友信息，待扩展
    if     MsgId == msgUserMgr.MSG_USER_FRIEND_QUERY_BY_DBID then
    if PlayerInfo and lua_util.get_table_real_count(PlayerInfo) > 0 then

    else
    --self.client.OnFriendAddResp(error_code.ERR_FRIEND_NOT_EXISTS)
    end
    --返回所有好友信息
    elseif MsgId == msgUserMgr.MSG_USER_FRIEND_QUERY_BY_ALL_DBID then
    if PlayerInfo and lua_util.get_table_real_count(PlayerInfo) > 0 then
    self.client.OnFriendListResp(PlayerInfo, error_code.ERR_FRIEND_SUCCEED)
    else
    self.client.OnFriendListResp({}, error_code.ERR_FRIEND_NOT_EXISTS)
    end
    else
    log_game_debug("Avatar:QueryInfoByPlayerNameResp", "unknown msgid = %d", MsgId)
    end
    ]]
end

--UserMgr回调
function Avatar:RpcRelayCallback( MsgId, dbid, PlayerInfo, err)
    if self:FriendRpcRelayCallback( MsgId, dbid, PlayerInfo, err ) then
        --log_game_debug("Avatar:FriendRpcRelayCallback", " msgid = %d", MsgId)
    else
        log_game_error("Avatar:RpcRelayCallback", "unknown msgid = %d", MsgId)
    end
end
--OfflineMgr回调
function Avatar:OfflineMgrCallback( MsgId, dbid, PlayerInfo, err )
    if self:FriendOfflineMgrCallback( MsgId, dbid, PlayerInfo, err ) then
        --log_game_debug("Avatar:FriendOfflineMgrCallback", " msgid = %d", MsgId)
    --elseif self:MailOfflineMgrCallback(MsgId, dbid, PlayerInfo, err) then
        --log_game_debug("Avatar:MailOfflineMgrCallback", " msgid = %d", MsgId)
    else
        log_game_error("Avatar:OfflineMgrCallback", "unknown msgid = %d", MsgId)
    end
end
--[[
--MailMgr回调
function Avatar:MailMgrCallback( msgId, mail, mailId, err )
    if self:MailMailMgrCallback( msgId, mail, mailId, err ) then
        log_game_debug("Avatar:MailMailMgrCallback", " msgid = %d", msgId)
    else
        log_game_error("Avatar:MailMgrCallback", "unknown msgid = %d", msgId)
    end
end
]]
--被动
function Avatar:BeRpcRelayCall( MsgId, InfoItem )
    if self:FriendBeRpcRelayCall(  MsgId, InfoItem ) then
        --log_game_debug("Avatar:FriendBeRpcRelayCall", " msgid = %d", MsgId)
    elseif self:MailBeRpcRelayCall(MsgId, InfoItem) then
        --log_game_debug("Avatar:MailBeRpcRelayCall", " msgid = %d", MsgId)
    else
        log_game_error("Avatar:BeRpcRelayCall", "unknown msgid = %d", MsgId)
    end
end
--<与UserMgr交互接口

require "AvatarRune" --加载符文接口
require "AvatarFriend" --加载好友接口
require "AvatarBodyEnhance" --加载身体强化接口
require "AvatarJewel"
require "AvatarMail"
require "AvatarArena"
require "Avatar_activity"

require "AvatarOblivionGate"
require "AvatarSanctuaryDefense" --圣域守卫战，即世界boss
require "Avatar_Event"
require "Avatar_fumo"
require "AvatarGm"
require "AvatarCharge"
require "AvatarRoulette"

--require "Avatar_bot"

function Avatar:ChatResp(ChannelId, dbid, name, level, msg)
    log_game_debug("Avatar:ChatResp", "ChannelId=%d;dbid=%q;name=%s;level=%d;msg=%s;", ChannelId, dbid, name, level, msg)
    self.client.ChatResp(ChannelId, dbid, name, level, msg)
end

function Avatar:ClientCastSkill(skillId, pos)
    log_game_debug("Avatar:ClientCastSkill", "skillId=%d;pos=%d;", skillId, pos)
    local code = self.SpiritSystem:ClientCastSkill(skillId, pos)
    self.client.ClientCastSkillResp(skillId, pos, code)
end


function Avatar:ClientCastMark(skillId, pos)
    log_game_debug("Avatar:ClientCastMark", "markId=%d;pos=%d;", skillId, pos)
    local code = self.SpiritSystem:ClientCastMark(skillId, pos)
    self.client.ClientCastMarkResp(skillId, pos, code)
end


function Avatar:LevelUpSpiritSkill()
    local code = self.SpiritSystem:LevelUpSkill()
    self.client.LevelUpSkillResp(code)
end


function Avatar:LevelUpMark()
    local code =  self.SpiritSystem:LevelUpMark()
    self.client.LevelUpMarkResp(code)
end



function Avatar:addspiritbyid(id,id1)
    self.SpiritSystem:AddSpiritSkill(id)
    self.SpiritSystem:AddSpiritMark(id1)
end
--[[
function Avatar:Execute(cmdLine)
    local var = {}
    table.insert(var, self.dbid) --此Dbid供userMgr 解析
    return g_GMSystem:excutCommandLine(self.accountName, cmdLine, var) --accountName 执行了某个cmd命令

end]]

function Avatar:Execute(cmdLine)
    local var = {}
    table.insert(var,"Avatar")
    table.insert(var, self) --此Dbid供userMgr 解析
    return GMSystem:excutCommandLine(self.accountName, cmdLine, var) --accountName 执行了某个cmd命令
end

function Avatar:add_gold(value)
    self.gold = self.gold + value
end

function Avatar:add_diamond(value)
    self.diamond = self.diamond + value
end

function Avatar:add_level(value)
    if value > 0 then
        for i=1,value do
            self:LevelUp()
        end
    end
end


function Avatar:query_prop(prop)
    if self[prop] then
        local msg = prop .." = ".. t2s(self[prop])
        self:ChatResp(public_config.CHANNEL_ID_PERSONAL, self.dbid, "GM", self.level, msg)
    end
end

function Avatar:set_prop(prop, value)
    if prop == "limit" then
        self:ResetVipState()
        return
    end
    if self[prop] ~= nil then
        self[prop] = value
    else
        self.cell.set_prop(prop, value)
    end
end


function Avatar:has_diamond(value)
    return self.diamond >= value
end

function Avatar:hot_update(sysName)
    if sysName == "market" then
        MarketSystem:initData()
        self:ShowText(CHANNEL.DLG, "hot_update market ok!")
    elseif sysName == "" then
        HotSalesSystem:initData()
        self:ShowText(CHANNEL.DLG, "hot_update hot sales market ok!")
    else
        self:ShowText(CHANNEL.DLG, "hot_update false: Unknown system name!")
    end
end

--把玩家的位置设回场景进入点
function Avatar:reset_user_pos()
    local MapCfgData = g_map_mgr:getMapCfgData(self.sceneId)
    if self:HasCell() then
        self.cell.TelportLocally(MapCfgData['enterX'], MapCfgData['enterY'])
    end
end

function Avatar:ShowText(channelID, text, ...)
    self.client.ShowText(channelID, string.format(text, ...))
end


--通知客户端显示         （UserMgr中的次方法则是向所有玩家显示）
--channelID  ,显示位置  定义在channel_config中     例：CHANNEL.DLG_WORLD 则 世界悬浮 && 对话框,同时显示
--textID   文本ID  客户端根据该ID显示相应的文字
-- ...  可变参数
function Avatar:ShowTextID(channelID, textID, ...)
    if ...  then
        if self:hasClient() then
            self.client.ShowTextIDWithArgs(channelID, textID, {...})
        end         
    else
        if self:hasClient() then
            self.client.ShowTextID(channelID, textID)
        end
    end

end

function Avatar:OblivionGateReq(msg_id, arg1, arg2)
    if self.oblivionGateSystem then
        self.oblivionGateSystem:OnOblivionGateReq(msg_id, arg1, arg2)
    end
end

function Avatar:DefensePvPReq(msg_id, arg1, arg2)
    if self.defensePvPSystem then
        self.defensePvPSystem:OnDefensePvPReq(msg_id, arg1, arg2)
    end
end

function Avatar:NPCReq(npcId, taskId, funcId)
    --功能能funcId暂时没有用到，作为保留字段为NPC系统的扩展
    --传给NPC系统的数据需要等级和职业判定
    local ret = -1
    ret = NPCSystem:NPCReq(self, funcId, npcId, taskId)
    --其他任务待扩展
    --todo
    if ret ~= nil then
        self.client.NPCResp(ret)
    end
end

function Avatar:SkillBagReq()
    self.client.SkillSyncToClient(self.skillBag)
end

function Avatar:SkillBagSyncToBase(skillBag)
    --存盘操作
    self.skillBag = skillBag
    self.client.SkillSyncToClient(self.skillBag)
end

function Avatar:SkillBuffSyncToBase(skillBuff)
    self.skillBuffSave = skillBuff
end

function Avatar:GetServerTimeReq(TimeType)
    local result = global_data.GetServerTime(TimeType)

    if result then
        self.client.GetServerTimeResp(TimeType, result)
    end
    --    if TimeType ==  public_config.SERVER_TIMESTAMP then
    --        self.client.GetServerTimeResp(TimeType, os.time())
    --    elseif TimeType == public_config.SERVER_PASSTIME then
    --
    --        local ServerStartTime = global_data.GetBaseData(public_config.BASE_DATA_KEY_GAME_START_TIME)
    --        local result = os.time() - ServerStartTime
    --        log_game_debug("Avatar:GetServerTimeReq", "ServerStartTime=%d;result=%d", ServerStartTime, result)
    --
    --        self.client.GetServerTimeResp(TimeType, result)
    --    elseif TimeType == public_config.SERVER_SERVER_START_TIME then
    --        self.client.GetServerTimeResp(TimeType, g_GlobalParamsMgr:GetParams('server_start_time', os.time()))
    --    end
end

function Avatar:EventDispatch(sub_system_name, member_func_name, param_table)
    log_game_debug("Avatar:EventDispatch", "[%s]:[%s] Execute!", sub_system_name, member_func_name)

    if not member_func_name then return end
    if not param_table then return end

    local theSelf = nil
    local theFunc = nil
    if not sub_system_name or sub_system_name == "" or  sub_system_name == "Avatar" then
        theSelf = self
        theFunc = self[member_func_name]
    elseif sub_system_name == "client" then
        theSelf = nil
        theFunc = self.client[member_func_name]
    else
        theSelf = self[sub_system_name]
        theFunc = theSelf[member_func_name]
    end
    
    if not theFunc then
        log_game_warning("Avatar:EventDispatch", "theFunc is nil")
        return
    end

    local theSize = lua_util.get_table_real_count(param_table)
    if theSelf then
        if theSize == 0 then
            theFunc(theSelf)
        elseif theSize == 1 then
            theFunc(theSelf, param_table[1])
        elseif theSize == 2 then
            theFunc(theSelf, param_table[1], param_table[2])
        elseif theSize == 3 then
            theFunc(theSelf, param_table[1], param_table[2], param_table[3])
        elseif theSize == 4 then
            theFunc(theSelf, param_table[1], param_table[2], param_table[3], param_table[4])
        elseif theSize == 5 then
            theFunc(theSelf, param_table[1], param_table[2], param_table[3], param_table[4], param_table[5])
        elseif theSize == 6 then
            theFunc(theSelf, param_table[1], param_table[2], param_table[3], param_table[4], param_table[5], param_table[6])
        else
            log_game_debug("Avatar:EventDispatch", "Too more params！")
            return
        end
    else
        if theSize == 0 then
            theFunc()
        elseif theSize == 1 then
            theFunc(param_table[1])
        elseif theSize == 2 then
            theFunc(param_table[1], param_table[2])
        elseif theSize == 3 then
            theFunc(param_table[1], param_table[2], param_table[3])
        elseif theSize == 4 then
            theFunc(param_table[1], param_table[2], param_table[3], param_table[4])
        elseif theSize == 5 then
            theFunc(param_table[1], param_table[2], param_table[3], param_table[4], param_table[5])
        elseif theSize == 6 then
            theFunc(param_table[1], param_table[2], param_table[3], param_table[4], param_table[5], param_table[6])
        else
            log_game_debug("Avatar:EventDispatch", "Too more params！")
            return
        end
    end
end

function Avatar:InitSkillsForAvatar(vocation)
    local skillTbl = g_roleDataMgr:GetRoleDataByVocation(vocation)
    if skillTbl == nil then
        log_game_error("Avatar:InitSkillsForAvatar", "role configure data missed!")
        return
    end
    local skillIds = skillTbl.skillId
    local stbl = {}
    for k, v in pairs(skillIds) do
        stbl[v] = 1
    end
    return stbl
end

function Avatar:SkillUpgradeReq(skillId, nextSkillId)
    SkillUpgradeSystem:SkillUpReq(self, skillId, nextSkillId)
end

--vip权限状态初始化
function Avatar:ResetVipState()
    local tbl = {}
    local vipTbl = g_vip_mgr:GetVipPrivileges(self.VipLevel)
    tbl[public_config.DAILY_TIME_STAMP]                 = os.time()
    tbl[public_config.DAILY_GOLD_METALLURGY_TIMES]      = 0
    tbl[public_config.DAILY_RUNE_WISH_TIMES]            = 0
    tbl[public_config.DAILY_ENERGY_BUY_TIMES]           = 0
    tbl[public_config.DAILY_EXTRA_CHALLENGE_TIMES]      = 0
    tbl[public_config.DAILY_HARD_MOD_RESET_TIMES]       = 0
    tbl[public_config.DAILY_RAID_SWEEP_TIMES]           = 0
    tbl[public_config.DAILY_TOWER_SWEEP_TIMES]          = 0
    tbl[public_config.DAILY_ITEM_CAN_BUY_ENTER_SDTIMES] = 0
--    tbl[public_config.DAILY_MISSION_TIMES]              = 0
    tbl[public_config.DAILY_DRAGON_ATK_BUY_TIMES]       = 0
    tbl[public_config.DAILY_DRAGON_CONVOY_BUY_TIMES]    = 0
    self.VipRealState = tbl
    self:VipRealStateResp()

    --加入调用栈，观察清空vip信息的操作
    log_game_debug("Avatar:ResetVipState", "dbid=%q;name=%s", self.dbid, self.name)
    lua_util.traceback()
end

--更新Vip实时状态
function Avatar:SetVipState(key, value)
    --获取对应key值指向的数据对象
    local kState = self.VipRealState[key]
    if kState == nil then
        return false
    end
    --根据VIP等级获取对应的权限列表
    local vipLimit = g_vip_mgr:GetVipPrivileges(self.VipLevel)
    --根据当前key值取出映射的权限表中配置的限制
    local kLimit = vipLimit[vip_config[key]]
    local tpVal = kState + value
    if tpVal > kLimit then
        return false
    else
        local varState = self.VipRealState
        self.VipRealState[key] = kState + value
        self:VipRealStateResp()
        return true
    end
end

--获取vip指定状态
function Avatar:GetVipState(key)
    local kState = self.VipRealState[key]
    if kState == nil then
        return
    end
    return kState
end

function Avatar:VipStateCheck()
    --玩家登陆判断当前vip状态是否需要重置
    local ctime = os.time()
    local ltime = self.VipRealState[public_config.DAILY_TIME_STAMP]
    --为兼容老角色的特殊处理
    if ltime == nil then
        ltime = ctime
    end
    local ret = lua_util.is_same_day(ctime, ltime)
    if not ret then
        self:ResetVipState()
    end
end
function Avatar:VipRealStateResp()
    local vipState = self.VipRealState or {} 
    if self:hasClient() then
        self.client.VipRealStateResp(vipState)
    end
end
function Avatar:GetCdTime(cdtype)
    return self.ItemCdTime[cdtype]
end

function Avatar:SetCdTime(cdtype)
    local cdt = self.ItemCdTime or {}
    cdt[cdtype] = os.time()
    self.ItemCdTime = cdt
end

--使用血瓶转接口
function Avatar:UseHpBottleReq(count)
    if g_GlobalParamsMgr:GetParams('init_scene', 10004) == self.sceneId then
        return
    end
    if count > 1 then
      return
    end
    self.cell.UseHpBottleVerifyReq()
end

--购买血瓶接口
function Avatar:BuyHpBottleReq(count)
    if g_GlobalParamsMgr:GetParams('init_scene', 10004) == self.sceneId then
        return
    end
    if count > 1 then
       return
    end
    --g_hpSystem_mgr:BuyHpBottle(self)
end

function Avatar:UseHpBottleVerifyResp(retCode)
    if retCode ~= error_code.ERR_HP_VERIFY_SUCCESS then
        self:ShowTextID(CHANNEL.TIPS, retCode)
        return
    end
    g_hpSystem_mgr:UseHpBottle(self)
end

--查询角色信息的gm指令
function Avatar:get_dbid(name)
    if name then
        self:TableSelectSql("GetDbidCallback", "Avatar", string.format("select id from tbl_Avatar where sm_name = '%s'", name))
    end
    return
end

function Avatar:GetDbidCallback(avatarInfo)
    log_game_debug("Avatar:GetDbidCallback", "start:%s", mogo.cPickle(avatarInfo))
    local msg = "角色ID: "
    for k, v in pairs(avatarInfo) do
        msg = msg .. k
    end
    log_game_debug("Avatar:GetDbidCallback", "msg = %s", tostring(msg))
    self:ChatResp(public_config.CHANNEL_ID_PERSONAL, self.dbid, "GM", self.level, msg)
    return
end

function Avatar:get_info(dbid)
    if dbid then
        self:TableSelectSql("GetInfoCallback", "Avatar", 
                string.format("select id, sm_accountName, sm_vocation, sm_level, sm_exp, sm_energy, sm_gold, sm_diamond, sm_gender, sm_VipLevel from tbl_Avatar where id = '%d'", dbid)) 
    end
    return
end

function Avatar:GetInfoCallback(avatarInfo)
    log_game_debug("Avatar:GetInfoCallback", "start:%s", mogo.cPickle(avatarInfo))
    local msg = "角色信息: \n"
    for k, v in pairs(avatarInfo) do
        for tk, tv in pairs(v) do
            if tk ==  "gender" then
                if tv == 1 then
                    tv = "男"
                else
                    tv = "女"
                end
            end
            msg = string.format("%s [%s = %s]\n", msg, self:GetCHN(tk), tostring(tv))
        end
    end
    self:ChatResp(public_config.CHANNEL_ID_PERSONAL, self.dbid, "GM", self.level, msg)
    return
end

function Avatar:GetCHN(key)
    local eng2chn = {
        VipLevel    = "vip等级", 
        vocation    = "职业",
        exp         = "经验",
        energy      = "体力",
        gold        = "金币",
        diamond     = "钻石",
        gender      = "性别",
        level       = "角色等级",
        id          = "角色ID",
        accountName = "账号"
    }
    for k, v in pairs(eng2chn) do
        if k == key  then
            return v
        end
    end
    return "error"
end

function Avatar:gm_mail(to, title, text, attach, dbid)
    --log_game_debug("Avatar:send_mail", "%s %s %s %s %s",
    --tostring(to), tostring(title), tostring(text), tostring(attach), tostring(dbid))
    local msg
    local from = self.name
    local attachment = {}
    local attTbl = lua_util.split_str(attach, ",")
    local itemCfgType = public_config.ITEM_TYPE_CFG_TBL
    for k, v in pairs(attTbl) do
        local idx = string.find(v, "=")
        local id = tonumber(string.sub(v, 1, idx - 1))
        local num = tonumber(string.sub(v, idx + 1, -1))
        if id ~= 0 and num ~= 0 then
            if id > public_config.MAX_OTHER_ITEM_ID then
                local item = g_itemdata_mgr:GetItem(itemCfgType, id)
                if not item then
                    msg = string.format("item [%d] not existed!", id)
                    self:ChatResp(public_config.CHANNEL_ID_PERSONAL, self.dbid, "GM", self.level, msg)
                    return
                end
            end
            attachment[id] = num
        end

    end
    if attach == nil then
        msg = "attachment error"
        self:ChatResp(public_config.CHANNEL_ID_PERSONAL, self.dbid, "GM", self.level, msg)
        return
    end

    if dbid == '0' or dbid == nil then
        globalbase_call("MailMgr", "SendAllEx", title, to, text, from, os.time(), attachment, reason_def.gm)
        return
    end
    local dbids = lua_util.split_str(dbid, ",", tonumber)

    log_game_debug("Avatar:send_mail", "dbid = %s", mogo.cPickle(dbids))

    globalbase_call("MailMgr", "SendEx", title, to, text, from, os.time(), attachment, dbids, reason_def.gm)
end
--玩家禁言
--function Avatar:ban_chat(dbid, time)
--   local data = {os.time(), time}
    --todo 等待屈荣完成工作
    --globalbase_call("UserMgr", "Update",dbid, data) 
--end
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
MAX_OTHER_ITEM_ID       = 99, --最大的特殊道具编号
]]
function Avatar:get_rewards(rewards, reason)
    if not rewards then
        return
    end
    for k,v in pairs(rewards) do
        if public_config.EXP_ID == k then
            self:AddExp(v, reason)
        elseif public_config.GOLD_ID == k then
            self:AddGold(v, reason)
        elseif public_config.DIAMOND_ID == k then
            self:AddDiamond(v, reason)
        elseif public_config.VIP_ID == k then

        elseif public_config.CUBE_ID == k then

        elseif public_config.ENERGY_ID == k then
        	self:AddEnergy(v, reason)
        elseif public_config.BUFF_ID == k then

        elseif public_config.GUILD_CARD_ID == k then

        elseif public_config.ARENA_CREDIT == k then
            if self.arenaSystem.AddCredit then
                self.arenaSystem:AddCredit(v)
            end
        elseif public_config.ARENA_SCORE == k then
            if self.arenaSystem.AddScore then
                self.arenaSystem:AddScore(v)
            end
        elseif k < public_config.MAX_OTHER_ITEM_ID then
            log_game_error("Avatar:get_rewards", "Unknown rewards id [%d]", k)
        else
            self:AddItem(k, v, reason)
        end
    end
end

--人物加金钱
--value  改变的值 ，可以为负数，表示减少
--reason 改变的原因（来源或者用途）,用于日志记录 int类型 定义在 reason_def.lua中
function Avatar:AddGold(value, reason)
    if value == 0 then
        log_game_debug("Avatar:AddGold", "value = 0! reason= %s", reason)
        return
    end

    local tmp = self.gold + value 
    
    local max_gold = g_GlobalParamsMgr:GetParams('max_gold_limit', 1000000000)

    if tmp < 0 then
        self.gold = 0 
    elseif tmp > max_gold then
        self.gold = max_gold 
    else
        self.gold = tmp
    end

    log_game_info("Avatar:AddGold", "dbid=%q;name=%s;gold=%d;addGold=%d;reason=%d",
        self.dbid, self.name, self.gold, value, reason)
    --globalbase_call("Collector","player_gold",self.name,value,reason) --player, num, to
    local opt = 1
    if value < 0 then opt = 2 end
 
    local accountName, platName = self:SplitAccountNameByString(self.accountName)

    local insert_table =  {
                            role_id         = self.dbid, --角色id
                            account_name    = accountName, --平台账户
                            plat_name       = platName,--平台名
                            dim_level       = self.level, --等级
                            dim_prof        = self.vocation, --职业id
                            money_type      = 3, --货币类型（1=金币，2=绑定金币，3=铜币，4=绑定铜币，5=礼券，6=积分/荣誉, 7=兑换）
                            amount          = math.abs(value), --货币数量
                            opt             = opt, --货币加减（1=增加，2=减少）
                            action_1        = reason, --行为分类1（一级消费点）
                            action_2        = reason,
                            happend_time    = os.time(), --事件发生时间
                        }


    globalbase_call("Collector", "table_insert", "tbllog_gold", insert_table)    


end
--人物加钻石
--value  改变的值 ，可以为负数，表示减少
--reason 改变的原因（来源或者用途）,用于日志记录 int类型 定义在 reason_def.lua中
function Avatar:AddDiamond(value, reason)

    log_game_info("Avatar:AddDiamond", "dbid=%q;name=%s;addDiamond=%d;reason=%d",
        self.dbid, self.name, value, reason)
    if value == 0 then
        log_game_warning("Avatar:AddDiamond", "dbid=%q;name=%s;reason=%d", self.dbid, self.name, tonumber(reason))
        return
    end

    local tmp = self.diamond + value 
 
    if tmp < 0 then
        self.diamond = 0 
    else
        self.diamond = tmp
    end

    --globalbase_call("Collector", "AddDiamond", value, reason)
     --globalbase_call("Collector","player_diamond",self.name,value,reason) --player, num, to
     if value < 0 then
        self:OnCostDiamond(math.abs(value))
     end
        
    local opt = 1
    if value < 0 then opt = 2 end

    local accountName, platName = self:SplitAccountNameByString(self.accountName)

    local insert_table =  {
                            role_id         = self.dbid, --角色id
                            account_name    = accountName, --平台账户
                            plat_name       = platName, --平台名
                            dim_level       = self.level, --等级
                            dim_prof        = self.vocation, --职业id
                            money_type      = 1, --货币类型（1=金币，2=绑定金币，3=铜币，4=绑定铜币，5=礼券，6=积分/荣誉, 7=兑换）
                            amount          = math.abs(value), --货币数量
                            opt             = opt, --货币加减（1=增加，2=减少）
                            action_1        = reason, --行为分类1（一级消费点）
                            action_2        = reason,
                            happend_time    = os.time(), --事件发生时间
                        }

    globalbase_call("Collector", "table_insert", "tbllog_gold", insert_table)

end
--人物加道具
--id  ,num
--reason 改变的原因（来源或者用途）,用于日志记录 int类型 定义在 reason_def.lua中
function Avatar:AddItem(id, num, reason)
    local ret = -1
    if self.inventorySystem then
        log_game_info("Avatar:AddItem", "before:dbid=%q;name=%s;id=%d;num=%d;reason=%d",
                self.dbid, self.name, id, num, reason)
        ret = self.inventorySystem:AddItems(id, num)
        if ret then  --成功
            log_game_info("Avatar:AddItem", "after:dbid=%q;name=%s;id=%d;num=%d;reason=%d",
                self.dbid, self.name, id, num, reason)
            self:OnAddItem(id,num,reason)

            local accountName, platName = self:SplitAccountNameByString(self.accountName)
            local insert_table ={
                    role_id         =   self.dbid,   --角色id
                    account_name    =   accountName,   --平台账户
                    plat_name       =   platName,   --平台名
                    dim_level       =   self.level,   --等级
                    opt             =   1,   --操作类型 --( 1 是获得，0 是使用)
                    action_id       =   reason,   --操作id
                    item_id         =   id,   --物品id
                    item_number     =   num,   --物品数量
                    happend_time    =   os.time(),   --事件发生时间
                }
            globalbase_call("Collector", "table_insert", "tbllog_items", insert_table)

			return 0
       end
    end
    return 1
end
--人物删除道具
--id
--reason 改变的原因（来源或者用途）,用于日志记录  int类型 定义在 reason_def.lua中
function Avatar:DelItem(id, num, reason)
    local ret = -1
    if self.inventorySystem then
        log_game_info("Avatar:DelItem", "before:dbid=%q;name=%s;id=%d;num=%d;reason=%d",
                self.dbid, self.name, id, num, reason)
        ret = self.inventorySystem:DelItems(id, num)
        if ret then  --成功
            log_game_info("Avatar:DelItem", "after:dbid=%q;name=%s;id=%d;num=%d;reason=%d",
                self.dbid, self.name, id, num, reason)

            local accountName, platName = self:SplitAccountNameByString(self.accountName)

            local insert_table ={
                    role_id         =   self.dbid,   --角色id
                    account_name    =   accountName,   --平台账户
                    plat_name       =   platName,--平台名
                    dim_level       =   self.level,   --等级
                    opt             =   0,   --操作类型 --( 1 是获得，0 是使用)
                    action_id       =   reason,   --操作id
                    item_id         =   id,   --物品id
                    item_number     =   num,   --物品数量
                    happend_time    =   os.time(),   --事件发生时间
                }
            globalbase_call("Collector", "table_insert", "tbllog_items", insert_table)
			return 0
        end
    end
    return 1
end

function Avatar:KickedOut()
    self:CKickedOut()
end

function Avatar:GmCallback()
    
end
function Avatar:get_item()
    
end

function Avatar:CliEntityActionReq(eid, actionId, param1, param2)
    self.cell.CliEntityActionReq(eid, actionId, {param1, param2})
end

function Avatar:ResetHpCount()
    local vipLimit = g_vip_mgr:GetVipPrivileges(self.VipLevel)
    local hpBottles = vipLimit.hpBottles
    for _, vCount in pairs(hpBottles) do 
        self.hpCount = vCount
    end
    self.buyCount = 0
    --
end

function Avatar:MercenaryInfoReq(msg_id, arg1, arg2)
    if self.mercenarySystem then
        self.mercenarySystem:MercenaryReq(mercenary_config.MSG_GET_LIST_MERCENARY)
    end
end

function Avatar:MercenaryInfoCallBack(result)
    self.mercenaryInfoList = result
    for k,v in pairs(self.mercenaryInfoList) do
        local tblPlayerInfo = v
        local degreee = 0
        if v[7] ~= 0 then
            local dbid = v[1]
            if self.friends[dbid] then
                degreee = self.friends[dbid][friendsInfoIndex.degreeIndex]
            end
        end
        table.insert(v, degreee)
    end
    --发送响应给客户端
    self.client.MercenaryInfoResp(self.mercenaryInfoList)   
end

function Avatar:CreateMercenaryReq(isPvp)
    local theDbid = 0
    if 0 ~= isPvp then
        theDbid = self.pvpDbid
    else
        theDbid = self.mercenaryDbid
    end
    if theDbid > 0 then
        local mm = globalBases["UserMgr"]
        if mm then
            mm.GetPlayerBattleProperties(self.dbid, 'MercenaryBattlePropertiesCallBack', theDbid, isPvp)
        end
    end
end

function Avatar:MercenaryBattlePropertiesCallBack(attri, modes, skill, other_info, isPvp)
    self.cell.MercenaryBattleProperties(attri, modes, skill, other_info, isPvp) 
end

function Avatar:UpdateMercenaryCoord(mercenaryID, x, y, face, curHp)
    self.cell.UpdateMercenaryCoord(mercenaryID, x, y, face, curHp)
end


function Avatar:ban_chat(is_ban, ban_date, reason)
    if is_ban == 1 then --封号/解封标识.1=封号； 0=解封
        if ban_date == 0 then --0 表示永久禁言
            self.noSpeakTime = public_config.NO_SPEAK_FOREVER 
            self:ShowTextID(CHANNEL.CHATDLG, 1007011 ,reason) -- 被永久禁言
            return 
        end
        self.noSpeakTime = ban_date

        self:ShowTextID(CHANNEL.CHATDLG, 1007011 ,reason) --被禁言
    else
         self.noSpeakTime = 0
    end
end
function Avatar:CanSpeak()

     if self.noSpeakTime ~= 0  then --被禁言
        if self.noSpeakTime == public_config.NO_SPEAK_FOREVER then --永久禁言
            return false            
        end 

        if self.noSpeakTime >= os.time() then --还在禁言范围内
            return false
        else      
            return true
        end
  
    end
    return true
end

function Avatar:LookItems(type)
    if self.inventorySystem then
        if 0 == type then
            self.inventorySystem:PrintItems()
            return 
        end
        local bagItems = self.inventorySystem:GetItemsByType(type)
        local INST_GRIDIDX = public_config.ITEM_INSTANCE_GRIDINDEX 
        local INST_TYPEID  = public_config.ITEM_INSTANCE_TYPEID    
        local INST_ID      = public_config.ITEM_INSTANCE_ID        
        local INST_COUNT   = public_config.ITEM_INSTANCE_COUNT     
        local INST_SLOTS   = public_config.ITEM_INSTANCE_SLOTS     
        local function less(a, b)
            return a[INST_GRIDIDX] < b[INST_GRIDIDX] 
        end
        table.sort(bagItems, less)
        local msg = ""
        msg = string.format("%s%s:%s:%s:%s:%s\n", msg, "id", "idx", "typeId", "count", "slots")
        self:ChatResp(public_config.CHANNEL_ID_PERSONAL, self.dbid, "GM", self.level, msg)
        for k, v in pairs(bagItems) do
            msg = ""
            local slots = "{"
            for tk, tv in pairs(v[INST_SLOTS]) do
                slots = slots .. '[' .. tk .. '=' .. tv .. ']'
            end
            slots = slots .. "}"
            msg = string.format("%s%d:%d:%d:%d:%s\n", msg, 
                v[INST_ID], v[INST_GRIDIDX], v[INST_TYPEID], v[INST_COUNT], slots)
            self:ChatResp(public_config.CHANNEL_ID_PERSONAL, self.dbid, "GM", self.level, msg)
        end
    end
end
function Avatar:UpdateAutoFightProgress(value)
    self.FBProgress = 1--value
end

function Avatar:SetStateToBase(state)
    log_game_debug("SetStateToBase", "dbid=%q;name=%s;state=%d", self.dbid, self.name, state)
    self.state = mogo.sset(self.state, state)
end

function Avatar:UnsetStateToBase(state)
    log_game_debug("UnsetStateToBase", "dbid=%q;name=%s;state=%d", self.dbid, self.name, state)
    self.state = mogo.sunset(self.state, state)
end

--所有与Vip等级变化相关的处理逻辑都添加到此处
--Vip等级变化都需要添加以下语句触发该事件
--self:triggerEvent(event_config.EVENT_VIP_LEVEL_CHANGED)
function Avatar:VipLevelChanged()
    self:VipRealStateResp()
    self:refresh_day_task()--刷新日常任务(等级变化可能会引起日常任务的接取)
end

--炼金请求接口
function Avatar:GoldMetallurgyReq(count)
    g_goldmeta_mgr:ExchangeGold(self, count)
end

function Avatar:PurpleExchangeReq(id)
    local ret = 0
    if not g_exchange_mgr:PurpleExchange(self, id) then
        ret = 1
    end
    if self:hasClient() then
        self.client.PurpleExchangeResp(ret)
    end
end
--查看战斗力计算参数数值 
--fight force parameters
function Avatar:GetFFP()
    local msg = battleAttri:GetFFP(self.baseProps)
    msg = string.format("%s[fightForce=%d]", msg, self.fightForce)
    local msgList = lua_util.split_str(msg, ";")
    for k, v in pairs(msgList) do
        self:ChatResp(public_config.CHANNEL_ID_PERSONAL, self.dbid, "GM", self.level, v)
    end
end
--Vip Buff 到期
function Avatar:VipBuffNoitfy(status, vLevel)
    log_game_debug("Avatar:VipBuffNoitfy", "dbid=%q;name=%s;status=%d;vLevel=%d", 
        self.dbid, self.name, status, vLevel)
    local vipLevel = g_vip_mgr:GetVipLevel(self.chargeSum)
    if self:VipZeroStatus(vLevel, vipLevel) then 
        return true
    end
    if self:VipStartStatus(vLevel, status) then
        return true 
    end
    if self:VipEndStatus(vLevel, vipLevel, status) then
        return true
    end
end
--没有buff存在
function Avatar:VipZeroStatus(vLevel, vipLevel)
    if vLevel == public_config.VIP_LEVEL_ZERO then
        if self.VipLevel > vipLevel then
            self.VipLevel = vipLevel
            self:VipLevelChanged()
        end
        return true
    end
    return false
end
--buff开始
function Avatar:VipStartStatus(vLevel, status)
    if status == public_config.VIP_BUFF_START then
        if vLevel > self.VipLevel then
            self.VipLevel = vLevel
            self:VipLevelChanged()
            return true
        end
    end 
    return false
end
--buff结束
function Avatar:VipEndStatus(vLevel, vipLevel, status)
    if status == public_config.VIP_BUFF_END then
        if vLevel < self.VipLevel then
            if vLevel > vipLevel then
                self.VipLevel = vLevel
            else
                self.VipLevel = vipLevel
            end
            self:VipLevelChanged()
            return true
        end
    end
    return false
end
------------------------------------中转函数 end----------------------------------------------------------

function Avatar:bug_report(type, title, text)

    local accountName, platName = self:SplitAccountNameByString(self.accountName)

    local insert_table =  {
                            role_id           = self.dbid, --角色id
                            role_name         = self.name,
                            account_name      = accountName, --平台账户
                            plat_name         = platName, --平台名
                            complaint_type    = type, --投诉类型('全部',11='bug',12='投诉',13='建议',10='其他')
                            complaint_title   = title, --投诉的标题
                            complaint_content = text,--投诉的正文
                            complaint_time    = os.time(), --事件发生时间
                        }

    globalbase_call("Collector", "table_insert", "tbllog_complaints", insert_table)     

end
------------------------------------------------------------------
--排行榜系统
------------------------------------------------------------------
function Avatar:RankListReq(rankType, idx, timeStamp)
    if self:IsRankListLevelLimit() then return end
    local mb_str = self.base_mbstr
    local count  = 10
    globalbase_call("UserMgr", "RankListReq", mb_str, rankType, idx, count, timeStamp)    
end
function Avatar:BaseRankListResp(retCode, retList, timeStamp, hasMore)
    if self:hasClient() then
        self.client.RankListResp(retCode, retList, timeStamp, hasMore)
    end
end
-------------------------------------------------------------------
function Avatar:RankAvatarInfoReq(dbid)
    if self:IsRankListLevelLimit() then return end
    local mb_str   = self.base_mbstr
    local idolDbid = self.idol[public_config.AVATAR_IDOL_DBID]
    local isIdol   = 0
    if idolDbid and idolDbid == dbid then
        isIdol = 1
    end
    globalbase_call("UserMgr", "RankAvatarInfoReq", mb_str, dbid, isIdol)
end
function Avatar:BaseRankAvatarInfoResp(infoItem, gender, isIdol)
    if self:hasClient() then
        self.client.RankAvatarInfoResp(infoItem, gender, isIdol)
    end
end
function Avatar:GMRankList(isGm)
    globalbase_call("UserMgr", "GMLoadingRankList", isGm)
end 
----------------------------------------------------------------------
function Avatar:HasOnRankReq(rankType)
    if self:IsRankListLevelLimit() then return end
    local mb_str = self.base_mbstr
    globalbase_call("UserMgr", "HasOnRankReq", mb_str, rankType, self.dbid)
end
--回调
function Avatar:BaseHasOnRankResp(level)
    if self:hasClient() then
        self.client.HasOnRankResp(level)
    end
end
--------------------------------------------------------------------
--粉丝系统
--------------------------------------------------------------------
function Avatar:IsIdolChangedTodayReq(dbid)
    if self:IsRankListLevelLimit() then return end
    if dbid == self.dbid then
        local flips  = g_text_mgr:GetText(public_config.AVATAR_IDOL_SELF)
        self:ShowText(CHANNEL.TIPS, flips)
        return 
    end
    local idolName  = ""
    if dbid <= 0 then
        if self:hasClient() then
            self.client.FansIdolResp(error_code.FANS_IDOL_PARAS_ERROR, idolName)
        end
        return
    end
    if self:HasDoneIdolToday(public_config.AVATAR_IDOL_CHANGE) then
        if self:hasClient() then
            self.client.FansIdolResp(error_code.FANS_IDOL_HAS_CHANGE, idolName)
        end
        return
    end
    local mb_str = self.base_mbstr
    local iDbid = self.idol[public_config.AVATAR_IDOL_DBID]
    if not iDbid then
        if self:hasClient() then
            self.client.FansIdolResp(error_code.FANS_IDOL_SUCCESS, idolName)
        end
        return
    end
    globalbase_call("UserMgr", "AvatarIdolNameReq", mb_str, iDbid)
end

function Avatar:BaseAvatarIdolNameResp(idolName)
    if not idolName then
        idolName = ""
    end
    if self:hasClient() then
        self.client.FansIdolResp(error_code.FANS_IDOL_SUCCESS, idolName)
    end
end


function Avatar:SelfIdolReq()
    if self:IsRankListLevelLimit() then return end
    local udbid = self.idol[public_config.AVATAR_IDOL_DBID] or 0
    if self:hasClient() then
        self.client.SelfIdolResp(udbid)
    end
end
--------------------------------------------------------------------
--变更偶像请求
--------------------------------------------------------------------
function Avatar:ChangeIdolReq(dbid)
    if self:IsRankListLevelLimit() then return end
    if dbid == self.dbid then
        local flips  = g_text_mgr:GetText(public_config.AVATAR_IDOL_SELF)
        self:ShowText(CHANNEL.TIPS, flips)
        return
    end
    local idolName = ""
    local udbid = self.idol[public_config.AVATAR_IDOL_DBID]
    if udbid and udbid == dbid then
        globalbase_call("UserMgr", "UnregisterFans", udbid)
        if self:hasClient() then
            self.client.FansIdolResp(error_code.FANS_IDOL_SUCCESS, idolName)
        end
        return
    end
    if dbid <= 0 then
        if self:hasClient() then
            self.client.FansIdolResp(error_code.FANS_IDOL_PARAS_ERROR, idolName)
        end
        return 
    end
    if udbid then
        globalbase_call("UserMgr", "UnregisterFans", udbid)
    end
    globalbase_call("UserMgr", "RegisterFans",  dbid)
    self.idol[public_config.AVATAR_IDOL_DBID]   = dbid
    self.idol[public_config.AVATAR_IDOL_CHANGE] = os.time()
    if self:hasClient() then
        self.client.FansIdolResp(error_code.FANS_IDOL_SUCCESS, idolName)
        self.client.SelfIdolResp(dbid)
    end
end
--检查当天偶像变更和奖励领取状态
function Avatar:HasDoneIdolToday(typeIdx)
    local idols     = self.idol
    local curr_time = os.time()
    local save_time = idols[typeIdx]
    if not save_time then
        return false
    end  
    if lua_util.is_same_day(curr_time, save_time) then
        return true
    end
    return false
end
--检查当天粉丝福利领取状况
function Avatar:RecivedFansWelfareToday()
    if self:IsRankListLevelLimit() then return end
    if self:HasDoneIdolToday(public_config.AVATAR_IDOL_REWARD) then
        return
    end
    local mb_str = self.base_mbstr
    local dbid   = self.idol[public_config.AVATAR_IDOL_DBID]
    if not dbid then
        self:WithoutIdol()
        self.idol[public_config.AVATAR_IDOL_REWARD] = os.time()
        return
    end
    globalbase_call("UserMgr", "FansRewardOnlineReq", mb_str, dbid)
end
--每日偶像战力排名查询回调
function Avatar:FansRewardOnlineResp(idolRank)
    log_game_debug("Avatar:FansRewardOnlineResp", "dbid=%q;name=%s;idolRank=%s", self.dbid, self.name, mogo.cPickle(idolRank))
    for rankLevel, idolName in pairs(idolRank) do
        local rewards = g_rankList_mgr:GetReward(self.level, rankLevel)
        self:IdolDailyReward(idolName, rewards)
    end
    self.idol[public_config.AVATAR_IDOL_REWARD] = os.time()
end
function Avatar:IsRankListLevelLimit()
    local lvLimit = g_GlobalParamsMgr:GetParams('rankListLimit', 30)
    if self.level < lvLimit then return true end
    return false
end
--hasIdol标识是否有偶像
----------------------------------------------------
function Avatar:WithoutIdol()
    local title  = g_text_mgr:GetText(public_config.NOT_IDOL_TITLE)
    local text   = g_text_mgr:GetText(public_config.NOT_IDOL_TEXT)
    local prefix = g_text_mgr:GetText(public_config.IDOL_NAME_PREFIX)
    local sName  = g_text_mgr:GetText(public_config.NOT_IDOL_NAME)
    local rName  = string.format("%s[%s]", prefix, self.name)
    self:SendRewardMail(title, rName, text, sName, {}, reason_def.idol_reward)
end
function Avatar:IdolDailyReward(idolName, rewards)
    local title  = g_text_mgr:GetText(public_config.HAS_IDOL_TITLE)
    local text   = g_text_mgr:GetText(public_config.HAS_IDOL_TEXT)
    local prefix = g_text_mgr:GetText(public_config.IDOL_NAME_PREFIX)
    local sName  = idolName
    local rName  = string.format("%s[%s]", prefix, self.name)
    self:SendRewardMail(title, rName, text, sName, rewards, reason_def.idol_reward)
end
function Avatar:SendRewardMail(title, to, text, from, attachment, reason)
    local dbids = {self.dbid}
    globalbase_call("MailMgr", "SendEx", title, to, text, from, 
        os.time(), attachment, dbids, reason)
    log_game_debug("Avatar:SendRewardMail", "dbid=%q;name=%s;sender=%s;reciver=%s", self.dbid, self.name, to, from)
end
----------------------------------------------------------------------------------------
--飞龙大赛初始化
----------------------------------------------------------------------------------------
--角色上线数据检查
function Avatar:DragonOnlineCheck()
    FlyDragonSystem:DragonOnlineCheck(self)
end
----------------------------------------------------------------------------------------
function Avatar:DragonShowText(channelID, id)
    self:ShowTextID(channelID, id)
end
function Avatar:RemainConvoyTimesReq()
    FlyDragonSystem:RemainConvoyTimesReq(self)
end
function Avatar:ExploreDragonEventReq()
    FlyDragonSystem:ExploreDragonEventReq(self)
end
--角色上线打开飞龙系统数据请求
function Avatar:OnlineDragonInfoReq()
    FlyDragonSystem:OnlineDragonInfoReq(self)
end
--袭击开始请求
function Avatar:DragonAttackReq(dbid)
    FlyDragonSystem:DragonAttackReq(self, dbid)
end
--复仇开始请求
function Avatar:DragonRevengeReq(dbid)
    FlyDragonSystem:DragonRevengeReq(self, dbid)
end
--开始飞龙护送请求
function Avatar:StartDragonConvoyReq(pathMark)
    FlyDragonSystem:StartDragonConvoyReq(self, pathMark)
end
--刷新飞龙品质请求
function Avatar:FreshDragonQualityReq()
    FlyDragonSystem:FreshDragonQualityReq(self)
end
--刷新对手请求
function Avatar:FreshAdversaryReq()
    FlyDragonSystem:FreshAdversaryReq(self)
end
--购买金龙请求
function Avatar:BuyGoldDragonReq()
    FlyDragonSystem:BuyGoldDragonReq(self)
end
--清楚袭击cd请求
function Avatar:ClearAttackCDReq()
    FlyDragonSystem:ClearAttackCDReq(self)
end
function Avatar:BuyAtkTimesReq()
    FlyDragonSystem:BuyAtkTimesReq(self)
end
--减少护送时间请求
function Avatar:ReduceConvoyTimeReq()
    FlyDragonSystem:ReduceConvoyTimeReq(self)
end
--立即完成护送请求
function Avatar:ImmediateCompleteConvoyReq()
    FlyDragonSystem:ImmediateCompleteConvoyReq(self)
end
--购买护送次数请求
function Avatar:BuyConvoyTimesReq()
    FlyDragonSystem:BuyConvoyTimesReq(self)
end
--护送奖励领取请求
function Avatar:DragonCvyRewardReq()
    FlyDragonSystem:DragonCvyRewardReq(self)
end
function Avatar:FreshConvoyReward()
    FlyDragonSystem:FreshConvoyReward(self)
end
function Avatar:DragonContestSettleReq()
    FlyDragonSystem:DragonContestSettleReq(self)
end
function Avatar:AllDragonEventListReq()
    FlyDragonSystem:AllDragonEventListReq(self)
end
function Avatar:DragonStatusReq()
    FlyDragonSystem:DragonStatusReq(self)
end
----------------------------------------------------------------------------------------
function Avatar:BaseFreshConvoyRewardResp(curTimes, level, curRng)
    FlyDragonSystem:BaseFreshConvoyRewardResp(self, curTimes, level, curRng)
end
function Avatar:BaseStartDragonConvoyResp(retCode, etime)
    FlyDragonSystem:BaseStartDragonConvoyResp(self, retCode, etime)
end
function Avatar:BaseReduceConvoyTimeResp(retCode, etime)
    FlyDragonSystem:BaseReduceConvoyTimeResp(self, retCode, etime)
end
function Avatar:BaseDragonAdversariesResp(infoList)
    FlyDragonSystem:DragonInfosResp(self, infoList)
end
----------------------------------------------------------------------------------------
function Avatar:BaseDragonRevengeCheckResp(retCode, dbid)
    FlyDragonSystem:DragonAttackResp(self, retCode)
end
function Avatar:BaseDragonContestSettleResp(sucTimes, level, curRng)
    FlyDragonSystem:BaseDragonContestSettleResp(self, sucTimes, level, curRng)
end
----------------------------------------------------------------------------------------
function Avatar:BaseDragonAttackResp(retCode)
    FlyDragonSystem:DragonAttackResp(self, retCode)
end

function Avatar:BaseUpdateRelateTimes(tKey)
    FlyDragonSystem:BaseUpdateRelateTimes(self, tKey)
end
function Avatar:DragonBattleCallback(isWin, rewards, defier, quality)
    FlyDragonSystem:DragonBattleCallback(self, isWin, rewards, defier, quality)
end
function Avatar:InitBasePvpBattle(pvpInfo)
    local mm = globalBases["MapMgr"]
    local defier = pvpInfo.defier
    local dbid   = defier[public_config.DRAGON_PVP_DBID]
    self.pvpDbid = dbid
    local mbStr  = self.base_mbstr
    if mm then
        mm.CreateDragonPvpMapInstance(mbStr, 31000, pvpInfo)
    end
    local retCode = error_code.ERR_DRAGON_OK
    if self:hasClient() then
        self.client.DragonAttackResp(retCode)
    end
end
function Avatar:ZeroDragonCstCheck()
    FlyDragonSystem:DragonContestStatusCheck(self)
end

function Avatar:SetProgress(progress)
    log_game_debug("Avatar:SetProgress", "dbid=%d;name=%s;progress=%d", self.dbid, self.name, progress)
    local account = mogo.getEntity(self.accountId)
    if account then
        account:SetProgress(progress)
    end
end  
----------------------------------------------------------------------------------------
function Avatar:ActivedSuitEquipmentReq(typeId)
    local inventorySystem = self.inventorySystem
    inventorySystem:ActivedSuitEquipmentReq(typeId)
end
function Avatar:BaseUpdateGmSetting(gmSetting, gmDbid, gmName)
    self.gm_setting = gmSetting
    if gmDbid and gmName then
        log_game_debug("Avatar:BaseUpdateGmSetting", "dbid=%q;name=%s;gm_dbid=%q;gm_name=%s", self.dbid, self.name, gmDbid, gmName)
    end
end

function Avatar:reset_dragon()
    FlyDragonSystem:InitDragonContest(self)
end

----------------------------------------------------精灵系统接口------------------------------------
function Avatar:ElfUseTearProgReq()--打开领域界面
    self.client.ElfAreaTearProgResp(self.elfAreaTearProg)
end

function Avatar:ElfUseTearReq(areaId, useNum)
    if self.elfSystem == nil then
        return
    end
    self.elfSystem:ApplyUseTear(areaId, useNum)    
end

function Avatar:LearnElfSkillReq()
    if self.elfSystem == nil then
        return
    end
    self.elfSystem:RandomLearnElfSkill()
end

function Avatar:ResetElfSkillReq()
    if self.elfSystem == nil then 
        return
    end
    self.elfSystem:ResetElfSkill()
end
function Avatar:SyncSepcialEffectsReq()
    SpecialEffectsSystem:SyncSepcialEffectsResp(self)
end

function Avatar:ElfSkillUpgradeReq(newSkillId)
    if self.elfSystem == nil then 
        return
    end
    self.elfSystem:ElfSkillUpgrade(newSkillId)
end

function Avatar:ElfEquipSkillReq(skillId)
    if self.elfSystem == nil then 
        return
    end
    self.elfSystem:ElfEquipSkill(skillId)
end

function Avatar:ElfSkillInfoReq()--打开技能界面
    if self.elfSystem == nil then
        return
    end

    if not self.ElfLearnedSkillId then
        --以防旧号没有精灵技能信息
        self.elfSystem:InitElfLearnedSkillId()
    end

    
    self.elfSystem:UpdateElfLearnedSkillId() 
    self.client.UpdateElfSkillPoint(self.ElfSkillPoint)
end

function Avatar:CheckResetElfSysData()
    self.elfSystem:CheckResetElfSysData()
end

function Avatar:GMApplyUseTear(areaId, useNum)
    self.elfSystem:GMApplyUseTear(areaId, useNum)
end

----------------------------------------------------------------------------------------
--翅膀接口
----------------------------------------------------------------------------------------
function Avatar:TrainWingReq(id)
    WingSystem:TrainWingReq(self, id)
    log_game_debug("Avatar:TrainWingReq", "dbid=%q;name=%s;id=%d;wingBag=%s", 
        self.dbid, self.name, id, mogo.cPickle(self.wingBag))
end
function Avatar:MagicWingActiveReq(id)
    WingSystem:MagicWingActiveReq(self, id)
    log_game_debug("Avatar:MagicWingActiveReq", "dbid=%q;name=%s;id=%d;wingBag=%s", 
        self.dbid, self.name, id, mogo.cPickle(self.wingBag))
end
function Avatar:WingExchangeReq(id)
    WingSystem:WingExchangeReq(self, id)
end
function Avatar:SyncWingBagReq()
    WingSystem:SyncWingBagReq(self)
end
----------------------------------------------------------------------------------------
--特效激活接口
----------------------------------------------------------------------------------------
function Avatar:ActiveSepciaclEffectsReq(id)
    SpecialEffectsSystem:ActiveSepciaclEffectsReq(self, id)
end


function Avatar:SplitAccountNameByString(platAccountName)
    
    local result = lua_util.split_str(platAccountName, "_")
    local count = 0
    for k,v in pairs(result) do
        count = count + 1
    end

    if count == 1 then--truck开发
        return result[1], "4399"
    end

    if count == 2 then--平台
        return result[2], result[1]
    end

    return "", ""--错误
end
