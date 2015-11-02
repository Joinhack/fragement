--author:hwj
--date:2013-09-03
--此为usermgr扩展启动类,只能由UserMgr require使用
--避免UserMgr.lua文件过长
require "public_config"
require "attri_cal"
require "gm_setting_state"
local log_game_debug                 = lua_util.log_game_debug
local log_game_warning               = lua_util.log_game_warning
local log_game_info                  = lua_util.log_game_info
local log_game_error                 = lua_util.log_game_error
local globalbase_call                = lua_util.globalbase_call
--[[与usermgr里的前面的local         变量一致]]
local PLAYER_BASE_MB_INDEX           = public_config.USER_MGR_PLAYER_BASE_MB_INDEX
local PLAYER_CELL_MB_INDEX           = public_config.USER_MGR_PLAYER_CELL_MB_INDEX
local PLAYER_DBID_INDEX              = public_config.USER_MGR_PLAYER_DBID_INDEX
local PLAYER_NAME_INDEX              = public_config.USER_MGR_PLAYER_NAME_INDEX
local PLAYER_LEVEL_INDEX             = public_config.USER_MGR_PLAYER_LEVEL_INDEX
local PLAYER_VOCATION_INDEX          = public_config.USER_MGR_PLAYER_VOCATION_INDEX
local PLAYER_GENDER_INDEX            = public_config.USER_MGR_PLAYER_GENDER_INDEX
local PLAYER_UNION_INDEX             = public_config.USER_MGR_PLAYER_UNION_INDEX
local PLAYER_FIGHT_INDEX             = public_config.USER_MGR_PLAYER_FIGHT_INDEX --todo:优化
local PLAYER_IS_ONLINE_INDEX         = public_config.USER_MGR_PLAYER_IS_ONLINE_INDEX
local PLAYER_FRIEND_NUM_INDEX        = public_config.USER_MGR_PLAYER_FRIEND_NUM_INDEX   --好友數量
local PLAYER_OFFLINETIME_INDEX       = public_config.USER_MGR_PLAYER_OFFLINETIME_INDEX
local PLAYER_IDOL_INDEX              = public_config.USER_MGR_PLAYER_IDOL_INDEX         --偶像存储字段

-->以下存盘字段begin
local PLAYER_ITEMS_INDEX             = public_config.USER_MGR_PLAYER_ITEMS_INDEX            --只缓存身上装备信息，但是会从数据load符文信息来算战斗力，计算完会delete
local PLAYER_BATTLE_PROPS_INDEX      = public_config.USER_MGR_PLAYER_BATTLE_PROPS
local PLAYER_SKILL_BAG_INDEX         =  public_config.USER_MGR_PLAYER_SKILL_BAG
--<end
local PLAYER_LOADED_ITEMS_INDEX      = public_config.USER_MGR_PLAYER_LOADED_ITEMS    --todo:delete
--local PLAYER_BODY_INDEX = public_config.USER_MGR_PLAYER_BODY_INDEX --会从数据load身体信息来算战斗力，计算完会delete
local PLAYER_ARENIC_FIGHT_RANK_INDEX = public_config.USER_MGR_PLAYER_ARENIC_FIGHT_RANK_INDEX
local PLAYER_ARENIC_GRADE_INDEX      = public_config.USER_MGR_PLAYER_ARENIC_GRADE_INDEX
local PLAYER_GM_SETTING              = public_config.USER_MGR_PLAYER_GM_SETTING
local PLAYER_ACCOUNT                 = public_config.USER_MGR_PLAYER_ACCOUNT
--[[UserMgr临时数据]]
local PLAYER_SKILL_BAG_INDEX_TMP     = public_config.USER_MGR_PLAYER_SKILL_BAG_TMP
local PLAYER_ITEMS_INDEX_TMP         = public_config.USER_MGR_PLAYER_ITEMS_INDEX_TMP
local PLAYER_BODY_INDEX_TMP          = public_config.USER_MGR_PLAYER_BODY_INDEX_TMP
local PLAYER_RUNE_INDEX_TMP          = public_config.USER_MGR_PLAYER_RUNE_INDEX_TMP
local PLAYER_FRIEND_NUM_INDEX_TMP    = public_config.USER_MGR_PLAYER_FRIEND_NUM_INDEX_TMP
local PLAYER_ENCHANT_INDEX_TMP       = public_config.USER_MGR_PLAYER_ENCHANT_INDEX_TMP   --附魔字段
local PLAYER_ELFPROG_INDEX_TMP       = public_config.USER_MGR_PLAYER_ELFPROG_INDEX_TMP --灵系统女神之泪进度
local PLAYER_WING_INDEX_TMP          = public_config.USER_MGR_PLAYER_WING_INDEX_TMP --翅膀
--[[临时数据]]
--self.m_lFights的下标
local FIGHTS_DBID_INDEX              = public_config.USER_MGR_FIGHTS_DBID_INDEX
local FIGHTS_FIGHT_INDEX             = public_config.USER_MGR_FIGHTS_FIGHT_INDEX --存盘

local function NewTableWithDefault()
    local newTab = {}
    setmetatable(newTab, {__index =
        function (table, key)
            return 0
        end
        })
    return newTab
end

--for test
local function create_table(dbid)
    --这个值会导致内存泄漏，不过这里是不需要销毁的所以允许这样子
    local theTab = {}
    --[[
    local proxy = {}
    local meta = {}
    meta.__index = function (t, k)
        return theTab[k]
    end
    meta.__newindex = function (t, k, v)
        if k == PLAYER_FRIEND_NUM_INDEX then
            log_game_debug("attempt to change PLAYER_FRIEND_NUM_INDEX", "dbid %q %s", dbid, v)
        end
        theTab[k] = v
    end
    setmetatable(proxy, meta)]]
    return theTab
end

--回调方法
local function _user_mgr_register_callback(eid)
    local mm_eid = eid
    local function __callback(ret)
        local gm = mogo.getEntity(mm_eid)
        if gm then
            if ret == 1 then
                --注册成功
                gm:on_registered()
            else
                --注册失败
                log_game_warning("UserMgr.registerGlobally error", '')
                --destroy方法未实现,todo
                --gm.destroy()
            end
        end
    end
    return __callback
end

----二分查找中的取值函数
--local function LevelDbidGetValue(v)
--    return v[1]
--end

function UserMgr:__ctor__()
    log_game_info('UserMgr:__ctor__', '')

    self:RegisterGlobally("UserMgr", _user_mgr_register_callback(self:getId()))
end
--[[
function UserMgr:_create_a_player( ... )
    if tbl then
        if getmetatable(tbl) then
            return tbl
        end
    end
    if not cache then
        cache = {}
    end
    if not cache[dbid] then
        cache[dbid] = {}
    end
    local proxy = {}
    local meta = {}
    meta.__newindex = function (t, k, v)
        if v then
            --触发update or add 操作
            print('...' .. v)
            rawset(cache[dbid], k, v)
        else
            print("delete")
        end

    end
    setmetatable(proxy, meta)
    return proxy
end
]]
--注册globalbase成功后回调方法
function UserMgr:on_registered()
    log_game_info("UserMgr:on_registered", "")
    self.NameToDbid = {}
    self.m_lFights = {} --只存放20级以上的玩家的数据
    self.redis_key_format = "UserMgr:%d" --d:dbid
    self.m_save = {}
    self.m_robotsName = {}
    self.m_robots = {}
    local mt = {}

    mt.__newindex = function (t,dbid,vt_name)
        if type(dbid) ~= 'number' then
            log_game_error("UserMgr", "m_save __newindex k[%s],v[%s]", dbid, vt_name)
        end
        --触发save
        if not vt_name or type(vt_name) ~= 'string' then
            self:SaveAll(dbid)
        else
            self:Save(dbid, vt_name)
        end
    end
    setmetatable(self.m_save, mt)
    --预load用户数据
    self:TableSelectSql("onAvatarSelectCountResp", "Avatar", "SELECT COUNT(*) AS `id` FROM tbl_Avatar")
    --self:TableSelectSql("onAvatarSelectResp", "Avatar", "SELECT id,sm_name,sm_gender,sm_vocation,sm_level,sm_friends,sm_offlineTime,sm_skillBag, sm_body FROM tbl_Avatar")
    --self:TableSelectSql("onUserMgrDataSelectCountResp", "UserMgrData", "SELECT COUNT(*) AS `id` FROM tbl_UserMgrData")
    --mogo.loadEntitiesOfType("UserData")
    
end

----------------------------------------------------------------------
--粉丝系统
----------------------------------------------------------------------
function UserMgr:RegisterFans(dbid)
    local fansMap = self.DbidToFans
    if not fansMap[dbid] then
        fansMap[dbid] = 1
        return
    end
    fansMap[dbid] = fansMap[dbid] + 1
end

function UserMgr:UnregisterFans(dbid)
    local fansMap = self.DbidToFans
    if not fansMap[dbid] then
        return
    end
    local tpCount = fansMap[dbid] - 1
    if tpCount > 0 then
        fansMap[dbid] = tpCount
    else
        fansMap[dbid] = 0
    end
end
function UserMgr:CheckIdols(idol)
    if not idol then
        return
    end
    local dbid = idol[public_config.AVATAR_IDOL_DBID]
    if not dbid then
        return
    end
    self:RegisterFans(dbid)
end
----------------------------------------------------------------------
function UserMgr:SetGMAccount(dbid, sysBit, stat, gmDbid, gmName)
    log_game_debug("UserMgr:SetGMAccount", "dbid=%q;sysBit=%d;stat=%d;gm_dbid=%q;gm_name=%s", dbid, sysBit, stat, gmDbid, gmName)
    local player = self.DbidToPlayers[dbid]
    if not player then
        return
    end
    local gmSet = player[PLAYER_GM_SETTING] or 0
    if stat == public_config.GM_RIGHT_OPEN then
        gmSet = Bit.Set(gmSet, sysBit)
    elseif stat == public_config.GM_RIGHT_CLOSE then
        gmSet = Bit.Reset(gmSet, sysBit)
    else
        return
    end
    player[PLAYER_GM_SETTING] = gmSet
    local mb =  player[PLAYER_BASE_MB_INDEX]
    if mb then
        local pmb = mogo.UnpickleBaseMailbox(mb)
        if pmb then
            pmb.BaseUpdateGmSetting(gmSet, gmDbid, gmName)
        end
    end
    local sql = string.format("UPDATE tbl_Avatar SET sm_gm_setting = %d WHERE id = %d", gmSet, dbid)
    local function UpdateGMCallBack(ret)
        if ret ~= 0 then
            log_game_error("UserMgr:SetGMAccount", "ret = %d", ret)
        else
            log_game_debug("UserMgr:SetGMAccount", "ok!")
        end
    end
    self:TableExcuteSql(sql, UpdateGMCallBack)   
end
----------------------------------------------------------------------
function UserMgr:onAvatarSelectCountResp(rst)
    

    for count, _ in pairs(rst) do
        self.AllPlayersCount = count
    end

    if self.AllPlayersCount == 0 then
        lua_util.globalbase_call('GameMgr', 'OnMgrLoaded', 'UserMgr')
		return
    end

    local times = math.ceil(self.AllPlayersCount / 1000)
    log_game_debug('UserMgr:onAvatarSelectCountResp', 'rst=%s;times=%d', mogo.cPickle(rst), times)

    for i=1, times, 1 do
        --local leftCount = self.AllPlayersCount - (i-1) * 100
        --local sql = ''
        --if leftCount >= 100 then
        --local sql = "SELECT id,sm_name,sm_gender,sm_vocation,sm_level,sm_friends,sm_offlineTime,sm_skillBag, sm_body FROM tbl_Avatar LIMIT " .. (i-1) * 100 .. ", " .. 100

        --按等级的逆序加载 
        local sql = string.format("SELECT `id`, `sm_name`, `sm_accountName`, `sm_gender`, `sm_idol`, `sm_vocation`, `sm_level`, `sm_offlineTime`, `sm_skillBag`, `sm_body`, `sm_arenicGrade`, `sm_equipeds`, `sm_rune`, `sm_friends`, `sm_gm_setting`, `sm_fumoinfo`, `sm_elfAreaTearProg`, `sm_wingBag`  FROM tbl_Avatar ORDER BY `sm_level` DESC LIMIT %d, %d", 
                                            (i-1) * 1000, 1000)

        --else
        --    sql = "SELECT id,sm_name,sm_gender,sm_vocation,sm_level,sm_friends,sm_offlineTime,sm_skillBag, sm_body FROM tbl_Avatar LIMIT " .. (i-1) * 100 .. ", " .. leftCount
        --end
        log_game_debug('UserMgr:onAvatarSelectCountResp', 'sql=%s', sql)
        self:TableSelectSql("onAvatarSelectResp", "Avatar", sql)
    end
end

local tmp_avatar_count = 0
function UserMgr:onAvatarSelectResp(rst)

    --log_game_info("UserMgr:onAvatarSelectResp", "")

    local count = 0
    for dbid, info in pairs(rst) do
        --log_game_debug('UserMgr:onAvatarSelectResp', 'dbid=%q;info=%s', dbid, mogo.cPickle(info))
        local tmp = self.DbidToPlayers[dbid]
        local PlayerFriendNum = lua_util.get_table_real_count(info.friends)
        --log_game_debug("UserMgr:onSelectResp", "dbid = %q, FriendNum = %d", dbid, PlayerFriendNum)
        if not self.DbidToPlayers[dbid] then
            tmp = create_table(dbid)
        end
        tmp[PLAYER_DBID_INDEX]           = dbid
        tmp[PLAYER_NAME_INDEX]           = info.name
        tmp[PLAYER_LEVEL_INDEX]          = info.level
        tmp[PLAYER_VOCATION_INDEX]       = info.vocation
        tmp[PLAYER_GENDER_INDEX]         = info.gender
        tmp[PLAYER_UNION_INDEX]          = 0
        tmp[PLAYER_IS_ONLINE_INDEX]      = public_config.USER_MGR_PLAYER_OFFLINE
        tmp[PLAYER_FRIEND_NUM_INDEX_TMP] = PlayerFriendNum
        tmp[PLAYER_OFFLINETIME_INDEX]    = info.offlineTime
        tmp[PLAYER_SKILL_BAG_INDEX_TMP]  = info.skillBag
        tmp[PLAYER_BODY_INDEX_TMP]       = info.body
        tmp[PLAYER_ARENIC_GRADE_INDEX]   = info.arenicGrade
        --`sm_equipeds`, `sm_rune`
        tmp[PLAYER_ITEMS_INDEX_TMP]      = info.equipeds
        tmp[PLAYER_ENCHANT_INDEX_TMP]    = info.fumoinfo
        tmp[PLAYER_ELFPROG_INDEX_TMP]    = info.elfAreaTearProg
        tmp[PLAYER_WING_INDEX_TMP]       = info.wingBag

        --统计角色的粉丝数量
        self:CheckIdols(info.idol)    
        --回收角色偶像数据
        info.idol                        = nil
        --检查玩家装备
        self:CheckEquipment(dbid,info.vocation,info.equipeds)
        tmp[PLAYER_RUNE_INDEX_TMP]       = info.rune
        tmp[PLAYER_GM_SETTING]           = info.gm_setting or 0
        tmp[PLAYER_ACCOUNT]              = info.accountName
        --更新帐号索引dbid
        self:UpdateAc2Player(info.accountName,dbid)
        self.DbidToPlayers[dbid]         = tmp

        self.NameToDbid[info.name]       = dbid


        --log_game_debug("UserMgr:onSelectResp", "dbid=%q;name=%s", dbid, info.name)
        count = count + 1

        if not self.LevelToDbid[info.level] then
            self.LevelToDbid[info.level] = {}
        end

        self.LevelToDbid[info.level][dbid] = true
        
        rst[dbid] = nil
    end
    rst = nil
    local loadedCount = lua_util.get_table_real_count(self.DbidToPlayers)

    --log_game_info("UserMgr:onAvatarSelectResp", "avatar_loaded=%d;loadedCount=%d", count, loadedCount)

    if self.AllPlayersCount ~= loadedCount then
        return
    end

    log_game_info("UserMgr:onAvatarSelectResp", "AllPlayersCount=%d", self.AllPlayersCount)

    --    --根据等级排序
    --    table.sort(self.LevelToDbid, function(a, b) return a[1] < b[1] end)

    --注册定时存储器
    --local timerId= self:addTimer(public_config.USER_MGR_SAVE_INTERVAL, public_config.USER_MGR_SAVE_INTERVAL, 1)
    --self.m_timers[public_config.USER_MGR_TIMER_ID_SAVE_INDEX] = timerId
    --[[
    timerId= self:addTimer(public_config.USER_MGR_CLEAN_INTERVAL, public_config.USER_MGR_CLEAN_INTERVAL, 2)
    self.m_timers[public_config.USER_MGR_TIMER_ID_CLEAN_INDEX] = timerId
    ]]


    local redis_key 
    --log_game_debug("OfflineMgr:onSelectResp", "timerId = %d", timerId)
    for dbid,_ in pairs(self.DbidToPlayers) do
        redis_key = string.format(self.redis_key_format, dbid)
        self.m_redisUd:load(redis_key)
        tmp_avatar_count = tmp_avatar_count + 1
    end
    self:InitRankList()
    --lua_util.globalbase_call('GameMgr', 'OnMgrLoaded', 'UserMgr')
end

function UserMgr:UpdateAc2Player(account,dbid)
    if not self.AccountToDbid[account] then
        self.AccountToDbid[account] = {}
    end
    self.AccountToDbid[account][dbid] = 1
end

function UserMgr:CheckEquipment(dbid, vocation, equips)
    --[[1头盔、2项链、3肩甲、4胸甲、5腰带、6手套、7腿甲、8靴子、9戒指、10武器，类型与装备位的对应关系见]]
    --[[
    local bodyIndex2Name = 
    {
        [1]            = "head",
        [2]            = "neck",
        [3]            = "shoulder",
        [4]            = "chest",
        [5]            = "waist",
        [6]            = "arm",
        [7]            = "leg",
        [8]            = "foot",
        [9]            = "finger",
        [10]           = "weapon",
    }
    --道具实例
    ITEM_INSTANCE_GRIDINDEX    = 1, --背包索引
    ITEM_INSTANCE_TYPEID       = 2, --道具id
    ITEM_INSTANCE_ID           = 3, --实例id
    ITEM_INSTANCE_BINDTYPE     = 4, --绑定类型
    ITEM_INSTANCE_COUNT        = 5, --堆叠数量
    ITEM_INSTANCE_SLOTS        = 6, --宝石插槽
    ITEM_INSTANCE_EXTINFO      = 7, --扩展信息

    --UserMgr的数据(DbidToPlayers)的值(USER_MGR_PLAYER_ITEMS_INDEX)的数据的index
    USER_MGR_ITEMS_BODY_INDEX = 1,
    USER_MGR_ITEMS_TYPE_INDEX = 2,
    USER_MGR_ITEMS_SLOT_INDEX = 3,
    ]]
    for k,equ in pairs(equips) do
        if k ~= 'vt' then
            --排除掉一些没用的信息
            
            local body = equ[public_config.ITEM_INSTANCE_GRIDINDEX]
            local equ_id = equ[public_config.ITEM_INSTANCE_TYPEID]
            if not equ_id then
                log_game_debug("usermgr start up", "dbid[%q], eqips[%s]", dbid, mogo.cPickle(equ))
            else
                local equ_cfg = g_itemdata_mgr:GetItem(public_config.ITEM_TYPE_CFG_TBL, equ_id)
                if not equ_cfg then
                    log_game_error("usermgr start up", "dbid[%q],equ_id[%d] cfg is nil.", dbid, equ_id)
                else
                    if vocation ~= equ_cfg.vocation then
                        log_game_error("usermgr start up", "dbid[%q],vocation[%d],equ_id[%d],equ_vocation[%d] is not match.", dbid,vocation,equ_id,equ_cfg.vocation)
                    else
                        if equ_cfg.type < 9 and
                           equ_cfg.type ~= body then
                            log_game_error("usermgr start up", "dbid[%q],body[%d],equ_id[%d],equ_type[%d] is not match.", dbid,body,equ_id,equ_cfg.type)
                        elseif equ_cfg.type == 9 and (body ~= 9 and body ~= 10) then
                            log_game_error("usermgr start up", "dbid[%q],body[%d],equ_id[%d],equ_type[%d] is not match.", dbid,body,equ_id,equ_cfg.type)
                        elseif equ_cfg.type == 10 and body ~= 11 then
                            log_game_error("usermgr start up", "dbid[%q],body[%d],equ_id[%d],equ_type[%d] is not match.", dbid,body,equ_id,equ_cfg.type)
                        end
                    end
                end
            end
        end
    end
end

--redis回调
function UserMgr:onRedisReply(key, value)
--    log_game_debug("UserMgr:onRedisReply", "key[%s]", key)
    local key_tbl = lua_util.split_str(key,':')
    if self:ParseKeyTable(key_tbl) then
        self:LoadingFFRLToReward(value)
        return
    end
    local dbid_str = key_tbl[2]
    if not dbid_str then
        log_game_error("UserMgr:onRedisReply", "dbid is nil")
        return
    end
    local dbid = tonumber(dbid_str)
    local redis_data = mogo.cUnpickle(value)
    if not redis_data then
        log_game_error("UserMgr:onRedisReply", "redis_data is nil")
        return
    end
    --特殊处理好友个数的检查
    if "OfflineMgr" == key_tbl[1] then
        return self:OnLoadOthers(dbid,redis_data)
    end
    tmp_avatar_count = tmp_avatar_count - 1
    local nSeq = 0
    if not self.DbidToPlayers[dbid] then
        log_game_warning("UserMgr:onRedisReply", "dbid[%d]", dbid)
        self.DbidToPlayers[dbid] = {}
    end
    self:_init_redis_data(dbid, redis_data)
--    log_game_debug("UserMgr:onRedisReply", "========[%d]========", tmp_avatar_count)
    if tmp_avatar_count > 0 then
        return
    end

    self:_init_all_data()

    --战斗力降序排序
    local function gt(a, b)
        return a[FIGHTS_FIGHT_INDEX] > b[FIGHTS_FIGHT_INDEX]
    end
    table.sort( self.m_lFights, gt )

    local DbidToPlayers = self.DbidToPlayers
    for i,v in ipairs(self.m_lFights) do
        --把排位索引付给PLAYER_ARENIC_FIGHT_RANK_INDEX
        DbidToPlayers[v[FIGHTS_DBID_INDEX]][PLAYER_ARENIC_FIGHT_RANK_INDEX] = i
    end  
    lua_util.globalbase_call('GameMgr', 'OnMgrLoaded', 'UserMgr')
end

function UserMgr:AllPlayerDbidReq()
    --log_game_debug("UserMgr:AllPlayerDbidReq", "ok")

    local allCount  = self.AllPlayersCount
    local count     = 0
    local dbidMaps  = {}
    for dbid, _ in pairs(self.DbidToPlayers) do
        dbidMaps[dbid] = 1
        count = count + 1
        if count >= 3000 then
            --log_game_debug("UserMgr:AllPlayerDbidReq", "ko")
            globalbase_call("FlyDragonMgr", "PartPlayerDbidResp", dbidMaps)
            dbidMaps = {}
            count    = 0
        end
    end
    globalbase_call("FlyDragonMgr", "PartPlayerDbidResp", dbidMaps)
end
function UserMgr:_init_redis_data(dbid, redis_data)
    local thePlayer = self.DbidToPlayers[dbid]
    if not thePlayer then
        return log_game_error("UserMgr:_init_redis_data", "no thePlayer.")
    end
    for _, v in pairs(redis_data) do
        local vt = v['vt']
        if not vt then
            if v.antiDefense then 
                v.vt = battleProps 
            else
                return log_game_error("UserMgr:_init_redis_data", "no vt.")
            end
        end
        local index = redis_DbidToPlayers_index[vt]
        if index then
            if index == public_config.USER_MGR_PLAYER_FRIEND_NUM_INDEX then
                thePlayer[index] = v[1]
            else
                thePlayer[index] = v
            end
        else
            index = redis_m_lFights_index[vt]
            if index == FIGHTS_FIGHT_INDEX then
                table.insert(self.m_lFights, 
                {
                    [FIGHTS_DBID_INDEX] = dbid,
                    [index] = v[1],
                })
                thePlayer[PLAYER_FIGHT_INDEX] = v[1]
            end
        end   
    end
    log_game_debug("UserMgr:_init_redis_data", "%d", dbid)
    
    local items = thePlayer[public_config.USER_MGR_PLAYER_ITEMS_INDEX]
    if not items then
        return
    end
    --外观
    --先初始化所有的为0
    local tbl = {
        [public_config.BODY_CHEST] = 0,
        [public_config.BODY_ARMGUARD] = 0,
        [public_config.BODY_LEG] = 0,
        [public_config.BODY_WEAPON] = 0,
    }

    self:CheckEquipment(dbid, thePlayer[PLAYER_VOCATION_INDEX], items)
    for _,v in pairs(items) do
        --外观信息
        if v[public_config.USER_MGR_ITEMS_BODY_INDEX] == public_config.BODY_CHEST or 
           v[public_config.USER_MGR_ITEMS_BODY_INDEX] == public_config.BODY_ARMGUARD or
           v[public_config.USER_MGR_ITEMS_BODY_INDEX] == public_config.BODY_LEG or
           v[public_config.USER_MGR_ITEMS_BODY_INDEX] == public_config.BODY_WEAPON then
            tbl[v[public_config.USER_MGR_ITEMS_BODY_INDEX]] = v[public_config.USER_MGR_ITEMS_TYPE_INDEX]
        end
    end

    thePlayer[PLAYER_LOADED_ITEMS_INDEX] = tbl
end

function UserMgr:_init_all_data()
    for dbid, theInfo in pairs(self.DbidToPlayers) do
        local battleProp = NewTableWithDefault()
        --组织龙语和装备信息
        local runeBag = theInfo[PLAYER_RUNE_INDEX_TMP]
        local bodyEquip = theInfo[PLAYER_ITEMS_INDEX_TMP]
        local enchants  = theInfo[PLAYER_ENCHANT_INDEX_TMP]
        local elfAreaTearProg = theInfo[PLAYER_ELFPROG_INDEX_TMP]
        local wingBag  = theInfo[PLAYER_WING_INDEX_TMP]
        if not theInfo[PLAYER_BODY_INDEX_TMP] then
            self.DbidToPlayers[dbid][PLAYER_BODY_INDEX_TMP] = NewTableWithDefault()
        end
        --log_game_debug("UserMgr:onItemSelectResp", "bodyEquip : "..mogo.cPickle(bodyEquip))
        --log_game_debug("UserMgr:onItemSelectResp", "body : "..mogo.cPickle(self.DbidToPlayers[dbid][PLAYER_BODY_INDEX_TMP]))
        --计算战斗数值 
        local level = theInfo[PLAYER_LEVEL_INDEX]
        local dd = 0
        if level < 10 then
            dd = 0
        elseif level == 10 then
            dd = 1
        elseif level < g_arena_config.OPEN_LV then
            dd = 2
        elseif level == g_arena_config.OPEN_LV then
            dd = 3
        else
            dd = 4
        end
        battleAttri:GetPropertiesWithArenic(battleProp,
                                  theInfo[PLAYER_BODY_INDEX_TMP], 
                                  runeBag, 
                                  bodyEquip, 
                                  level,
                                  theInfo[PLAYER_ARENIC_GRADE_INDEX],
                                  enchants,
                                  elfAreaTearProg,
                                  wingBag)
        --计算战斗力
        local fightForce = battleAttri:GetFightForce(battleProp)

        --验证redis数据的正确性log
        if level >= g_arena_config.OPEN_LV then
            --够竞技场开启等级，但是没有战斗数值
            if not theInfo[PLAYER_ITEMS_INDEX] or 
                not theInfo[PLAYER_BATTLE_PROPS_INDEX] or 
                not theInfo[PLAYER_SKILL_BAG_INDEX] or
                not theInfo[PLAYER_LOADED_ITEMS_INDEX] then
                log_game_warning("UserMgr:_init_all_data", 
                    "dbid[%d], level[%d], [UserMgr:%d] hast arena redis data", dbid, level, dbid)
            end
        else
            --不够竞技场等级却有镜像redis数据
            if theInfo[PLAYER_ITEMS_INDEX] or 
                theInfo[PLAYER_BATTLE_PROPS_INDEX] or 
                theInfo[PLAYER_SKILL_BAG_INDEX] or
                theInfo[PLAYER_LOADED_ITEMS_INDEX] then
                log_game_warning("UserMgr:_init_all_data", 
                    "dbid[%d], level[%d], [UserMgr:%d] has arena redis data", dbid, level, dbid)
            end
        end
        --整理装备信息,只缓存 GRIDINDEX TYPEID SLOTS
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

        --如果redis上的数据丢失使用mysql重新计算的数据
        if not theInfo[PLAYER_FIGHT_INDEX] then
            if level >= g_arena_config.OPEN_LV then
                log_game_warning("UserMgr:_init_all_data", "redis data[UserMgr:%d] hast areanafight.", dbid)
                table.insert(self.m_lFights, 
                {
                    [FIGHTS_DBID_INDEX] = dbid,
                    [FIGHTS_FIGHT_INDEX] = fightForce,
                })
            end
            --更新战斗力，如果有竞技场数据的使用竞技场镜像的战斗力
            --当角色开启竞技场后该值不是实时的战斗力值，是竞技场的标准战斗力
            --与self.m_lFights里的战斗力值一样
            theInfo[PLAYER_FIGHT_INDEX] = fightForce    
        end

        if level >= public_config.USER_MGR_DETAIL_DATA_CACHE_LEVEL 
            --and level < g_arena_config.OPEN_LV --这里注释掉是为了兼容redis上的相关数据丢失后直接使用当前的数值
            then
            --等级达到usermgr需要缓存战斗数值时，缓存以下数据（用于雇佣兵）

            --缓存装备,
            if not theInfo[PLAYER_ITEMS_INDEX] then
                theInfo[PLAYER_ITEMS_INDEX] = items
            end

            --缓存外型数据
            if not theInfo[PLAYER_LOADED_ITEMS_INDEX] then
                --外观
                --先初始化所有的为0
                local tbl = {
                    [public_config.BODY_CHEST] = 0,
                    [public_config.BODY_ARMGUARD] = 0,
                    [public_config.BODY_LEG] = 0,
                    [public_config.BODY_WEAPON] = 0,
                }

                for k,v in pairs(bodyEquip) do
                    --外观信息
                    if v[public_config.ITEM_INSTANCE_GRIDINDEX] == public_config.BODY_CHEST or 
                       v[public_config.ITEM_INSTANCE_GRIDINDEX] == public_config.BODY_ARMGUARD or
                       v[public_config.ITEM_INSTANCE_GRIDINDEX] == public_config.BODY_LEG or
                       v[public_config.ITEM_INSTANCE_GRIDINDEX] == public_config.BODY_WEAPON then
                        tbl[v[public_config.ITEM_INSTANCE_GRIDINDEX]] = v[public_config.ITEM_INSTANCE_TYPEID]
                    end
                end
                theInfo[PLAYER_LOADED_ITEMS_INDEX] = tbl
            end

            --缓存二级战斗属性
            if not theInfo[PLAYER_BATTLE_PROPS_INDEX] then
                theInfo[PLAYER_BATTLE_PROPS_INDEX] = battleProp
            end

            --缓存技能信息,这里的tmp数值被引用，clear时要小心
            if not theInfo[PLAYER_SKILL_BAG_INDEX] then
                theInfo[PLAYER_SKILL_BAG_INDEX] = theInfo[PLAYER_SKILL_BAG_INDEX_TMP]
            else
                --销毁技能背包数据
                self.DbidToPlayers[dbid][PLAYER_SKILL_BAG_INDEX_TMP] = nil
            end

            --清除装备信息
            if theInfo[PLAYER_ITEMS_INDEX_TMP] then
                self.DbidToPlayers[dbid][PLAYER_ITEMS_INDEX_TMP] = nil
            end
            --销毁身体信息
            if theInfo[PLAYER_BODY_INDEX_TMP] then
                self.DbidToPlayers[dbid][PLAYER_BODY_INDEX_TMP] = nil
            end
            --销毁符文信息
            if theInfo[PLAYER_RUNE_INDEX_TMP] then
                self.DbidToPlayers[dbid][PLAYER_RUNE_INDEX_TMP] = nil
            end
            --销毁附魔信息
            if theInfo[PLAYER_ENCHANT_INDEX_TMP] then
                self.DbidToPlayers[dbid][PLAYER_ENCHANT_INDEX_TMP] = nil
            end
            --销毁精灵领域消耗女神之泪进度信息
            if theInfo[PLAYER_ELFPROG_INDEX_TMP] then
                self.DbidToPlayers[dbid][PLAYER_ELFPROG_INDEX_TMP] = nil
            end
            --翅膀
            if theInfo[PLAYER_WING_INDEX_TMP] then
                self.DbidToPlayers[dbid][PLAYER_WING_INDEX_TMP] = nil
            end
        else
            --销毁技能背包数据
            if theInfo[PLAYER_SKILL_BAG_INDEX_TMP] then
                self.DbidToPlayers[dbid][PLAYER_SKILL_BAG_INDEX_TMP] = nil
            end
            --清除装备信息
            if theInfo[PLAYER_ITEMS_INDEX_TMP] then
                self.DbidToPlayers[dbid][PLAYER_ITEMS_INDEX_TMP] = nil
            end
            --销毁身体信息
            if theInfo[PLAYER_BODY_INDEX_TMP] then
                self.DbidToPlayers[dbid][PLAYER_BODY_INDEX_TMP] = nil
            end
            --销毁符文信息
            if theInfo[PLAYER_RUNE_INDEX_TMP] then
                self.DbidToPlayers[dbid][PLAYER_RUNE_INDEX_TMP] = nil
            end
            --销毁附魔信息
            if theInfo[PLAYER_ENCHANT_INDEX_TMP] then
                self.DbidToPlayers[dbid][PLAYER_ENCHANT_INDEX_TMP] = nil
            end
            --销毁精灵领域消耗女神之泪进度信息
            if theInfo[PLAYER_ELFPROG_INDEX_TMP] then
                self.DbidToPlayers[dbid][PLAYER_ELFPROG_INDEX_TMP] = nil
            end
            --翅膀
            if theInfo[PLAYER_WING_INDEX_TMP] then
                self.DbidToPlayers[dbid][PLAYER_WING_INDEX_TMP] = nil
            end
        end
        local ove = true
    end
end

function UserMgr:Init()
	tmp_avatar_count = 0
	local mm = globalBases["OfflineMgr"]
	local self_mbstr = mogo.pickleMailbox(self)
    local redis_key = "OfflineMgr:%s"
	for dbid,_ in pairs(self.DbidToPlayers) do
        --获取离线管理器上的数据
        --mm.GetTypeOf(self_mbstr, 1, OfflineType.OFFLINE_RECORD_FRIEND_ACCEPT_BE, dbid, 0)
        self.m_redisUd:load(string.format(redis_key,dbid))
        tmp_avatar_count = tmp_avatar_count + 1
    end
    if tmp_avatar_count == 0 then
    	globalbase_call('GameMgr', 'OnInited', 'UserMgr')
    end
end
--飞龙系统查询人数
function UserMgr:FlyDragonMgrGetPlayerCount()
    log_game_debug("UserMgr:FlyDragonMgrGetPlayerCount", "AllPlayersCount=%d", self.AllPlayersCount)
    globalbase_call("FlyDragonMgr", "OnInited",  self.AllPlayersCount)
end
--飞龙系统查询人数
function UserMgr:FlyDragonMgrGetPlayerCount()
    log_game_debug("UserMgr:FlyDragonMgrGetPlayerCount", "AllPlayersCount=%d", self.AllPlayersCount)
    globalbase_call("FlyDragonMgr", "OnInited",  self.AllPlayersCount)
end

function UserMgr:OnLoadOthers(dbid,redis_data)
    tmp_avatar_count = tmp_avatar_count - 1
    local thePlayerInfo = self.DbidToPlayers[dbid]
    local be_accepted = redis_data[OfflineType.OFFLINE_RECORD_FRIEND_ACCEPT_BE] or {}
    for k,v in pairs(be_accepted) do
        thePlayerInfo[PLAYER_FRIEND_NUM_INDEX_TMP] = thePlayerInfo[PLAYER_FRIEND_NUM_INDEX_TMP] + 1
    end
    if not thePlayerInfo[PLAYER_FRIEND_NUM_INDEX] then
        thePlayerInfo[PLAYER_FRIEND_NUM_INDEX] = 0
    end
    if thePlayerInfo[PLAYER_FRIEND_NUM_INDEX_TMP] ~= thePlayerInfo[PLAYER_FRIEND_NUM_INDEX] then
        log_game_warning('UserMgr:OfflineMgrCallback', 
            "dbid[%q] db friends[%d], reids friends[%d]", 
            dbid,
            thePlayerInfo[PLAYER_FRIEND_NUM_INDEX_TMP], 
            thePlayerInfo[PLAYER_FRIEND_NUM_INDEX])
        self:PlayerFriendNumChange(dbid, thePlayerInfo[PLAYER_FRIEND_NUM_INDEX_TMP])
    end
    thePlayerInfo[PLAYER_FRIEND_NUM_INDEX_TMP] = nil
    if tmp_avatar_count == 0 then
        globalbase_call('GameMgr', 'OnInited', 'UserMgr')
        --self:ClearUp(self.DbidToPlayers)
        --self:initNILtable()
        --self.DbidToPlayers = {}
        --log_game_debug("TestMgr:OnMgrLoaded", "self.DbidToPlayers size = %d",lua_util.get_table_real_count(self.DbidToPlayers))
        --log_game_debug("TestMgr:OnMgrLoaded", "self.DbidToPlayers[4290672328711] = %s",mogo.cPickle(self.DbidToPlayers[4290672328711]))
        collectgarbage()
    end
end

function UserMgr:ClearData()
    log_game_debug("UserMgr:ClearData", "")
    self:ClearUp(self.DbidToPlayers)
    collectgarbage()
end

function UserMgr:ClearUp(t)
    for k,v in pairs(t) do
        if type(v) == 'table' then
            self:ClearUp(v)
        end
        t[k] = nil
    end
end

function UserMgr:initNILtable()
    for i=1,6000 do
        self.DbidToPlayers[i] = {}
    end
end
--处理飞龙大赛袭击对象相关信息
function UserMgr:DragonAdversariesReq(mbStr, aList)
    local mb = mogo.UnpickleBaseMailbox(mbStr)
    if not mb then
        return
    end
    local players = self.DbidToPlayers
    for _, info in pairs(aList) do
        local dbid       = info[public_config.ADVERSARY_INFO_DBID]
        local player     = players[dbid]
        if not player then
            log_game_error("UserMgr:DragonAdversariesReq", "adversary info error")
            mb.BaseDragonAdversariesResp(aList)
            return
        end
        local fightForce = player[PLAYER_FIGHT_INDEX]
        local guildName  = ""   --暂时没有
        local name       = player[PLAYER_NAME_INDEX]
        local vocation   = player[PLAYER_VOCATION_INDEX]
        info[public_config.ADVERSARY_INFO_FFORCE]   = fightForce
        info[public_config.ADVERSARY_INFO_GUILD]    = guildName
        info[public_config.ADVERSARY_INFO_NAME]     = name
        info[public_config.ADVERSARY_INFO_VOCATION] = vocation
    end
    log_game_debug("UserMgr:DragonAdversariesReq", "advs_info=%s", mogo.cPickle(aList))
    mb.BaseDragonAdversariesResp(aList)
end


--[[
--no use
function UserMgr:onUserMgrDataSelectCountResp(rst)
    for count, _ in pairs(rst) do
        self.AllUserMgrDataCount = count
    end

    if self.AllUserMgrDataCount == 0 then
        self:TableSelectSql("onAvatarSelectCountResp", "Avatar", "SELECT COUNT(*) AS `id` FROM tbl_Avatar")
        return
    end

    local times = math.ceil(self.AllUserMgrDataCount / 100)
    log_game_debug('UserMgr:onUserMgrDataSelectCountResp', 'rst=%s;times=%d', mogo.cPickle(rst), times)

    for i=1, times, 1 do
        local sql = string.format("SELECT `id`, `sm_avatarDbid`, `sm_items`, `sm_battleProps`, `sm_skillBag`, `sm_arenicFight` FROM tbl_UserMgrData LIMIT %d, %d", 
            (i-1) * 100, 100)
        log_game_debug('UserMgr:onUserMgrDataSelectCountResp', 'sql=%s', sql)
        self:TableSelectSql("onUserMgrDataSelectResp", "UserMgrData", sql)
    end
end
--no use
function UserMgr:onUserMgrDataSelectResp(rst)
    local count = 0
    for _, v in pairs(rst) do
        local dbid = v['avatarDbid']
        log_game_debug("UserMgr:onUserMgrDataSelectResp", "%d", dbid)
        --外观
        --先初始化所有的为0
        local tbl = {
            [public_config.BODY_CHEST] = 0,
            [public_config.BODY_ARMGUARD] = 0,
            [public_config.BODY_LEG] = 0,
            [public_config.BODY_WEAPON] = 0,
        }


        for _,v in pairs(v['items']) do
            --外观信息
            if v[public_config.USER_MGR_ITEMS_BODY_INDEX] == public_config.BODY_CHEST or 
               v[public_config.USER_MGR_ITEMS_BODY_INDEX] == public_config.BODY_ARMGUARD or
               v[public_config.USER_MGR_ITEMS_BODY_INDEX] == public_config.BODY_LEG or
               v[public_config.USER_MGR_ITEMS_BODY_INDEX] == public_config.BODY_WEAPON then
                tbl[ v[public_config.USER_MGR_ITEMS_BODY_INDEX] ] = v[public_config.USER_MGR_ITEMS_TYPE_INDEX]
            end
        end
        self.DbidToPlayers[dbid] = create_table(dbid)
        local tt = self.DbidToPlayers[dbid]
        tt[PLAYER_ITEMS_INDEX] = v['items']
        tt[PLAYER_BATTLE_PROPS_INDEX] = v['battleProps']
        tt[PLAYER_SKILL_BAG_INDEX] = v['skillBag']
        tt[PLAYER_LOADED_ITEMS_INDEX] = tbl

        table.insert(self.m_lFights, 
        {
            [FIGHTS_DBID_INDEX] = v['avatarDbid'],
            [FIGHTS_FIGHT_INDEX] = v['arenicFight'],
        })
        count = count + 1
    end
    self.AllUserMgrDataCount = self.AllUserMgrDataCount - count
    if self.AllUserMgrDataCount > 0 then
        return
    end
    --战斗力降序排序
    local function gt(a, b)
        return a[FIGHTS_FIGHT_INDEX] > b[FIGHTS_FIGHT_INDEX]
    end
    table.sort( self.m_lFights, gt )

    local DbidToPlayers = self.DbidToPlayers
    for i,v in ipairs(self.m_lFights) do
        --把排位索引付给PLAYER_ARENIC_FIGHT_RANK_INDEX
        DbidToPlayers[ v[FIGHTS_DBID_INDEX] ][PLAYER_ARENIC_FIGHT_RANK_INDEX] = i
    end
    --self.DbidToPlayers = DbidToPlayers

    self:TableSelectSql("onAvatarSelectCountResp", "Avatar", "SELECT COUNT(*) AS `id` FROM tbl_Avatar")
end
function UserMgr:OfflineMgrCallback(msgId, dbid, infos, errID)
	tmp_avatar_count = tmp_avatar_count - 1
  if dbid == 4290672328951 then
      local dd= 0
  end
	local thePlayerInfo = self.DbidToPlayers[dbid]
	for k,v in pairs(infos) do
		thePlayerInfo[PLAYER_FRIEND_NUM_INDEX_TMP] = thePlayerInfo[PLAYER_FRIEND_NUM_INDEX_TMP] + 1
	end
	if not thePlayerInfo[PLAYER_FRIEND_NUM_INDEX] then
		thePlayerInfo[PLAYER_FRIEND_NUM_INDEX] = 0
	end
	if thePlayerInfo[PLAYER_FRIEND_NUM_INDEX_TMP] ~= thePlayerInfo[PLAYER_FRIEND_NUM_INDEX] then
		log_game_warning('UserMgr:OfflineMgrCallback', 
			"dbid[%q] db friends[%d], reids friends[%d]", 
			dbid,
			thePlayerInfo[PLAYER_FRIEND_NUM_INDEX_TMP], 
			thePlayerInfo[PLAYER_FRIEND_NUM_INDEX])
		self:PlayerFriendNumChange(dbid, thePlayerInfo[PLAYER_FRIEND_NUM_INDEX_TMP])
	end
	thePlayerInfo[PLAYER_FRIEND_NUM_INDEX_TMP] = nil
	if tmp_avatar_count == 0 then
		globalbase_call('GameMgr', 'OnInited', 'UserMgr')
	end
end
]]
