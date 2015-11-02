-- 帐号管理模块

require "lua_util"
local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error
local globalbase_call = lua_util.globalbase_call

require "map_data"
require "error_code"
require "GlobalParams"
require "Item_data"
require "mission_config"
require "banned_char"
require "state_config"
require "special_effects_data"
local stopword_mgr = require "mgr_stopword"

--帐号状态
local ACCOUNT_STATE_INIT       = 0          --初始状态
local ACCOUNT_STATE_CREATING   = 1          --帐号正在创建角色、等待回调的状态
local ACCOUNT_STATE_DESTORYING = 2          --角色正在删除状态
local ACCOUNT_STATE_LOGINING   = 3          --帐号正在登录角色、等待回调的状态


Account = {}
setmetatable(Account, {__index = BaseEntity} )

-- 帐号存盘回调
local function FirstWriteToDb(entity, dbid, db_err)
    if dbid > 0 then
        --成功
        log_game_info("Account.FirstWriteToDb.success", "account=%s;dbid=%q", entity.name, entity:getDbid() )

        entity:NotifyClientToAttach(entity.name)
    else
        --失败
        log_game_error("Account.FirstWriteToDb.failed", "name=%s;dbid=%q;err=%s", entity.name, dbid, db_err )
    end
end

--[[ 不可能从accountid去从数据库生成avatar现在 hwj
local function OnAvatarCreatedFromDb(accountId)
    local l_account_id = accountId
    local function _real_callback(avatar)
        local account = mogo.getEntity(l_account_id)
        if account then
            avatar.accountId = accountId
            account:GiveClientTo(avatar)
        end
    end

    return _real_callback
end
--]]
local function OnAvatarWrited(avatar, dbid, err)
    if dbid > 0 then
        log_game_info("OnAvatarWrited", "account=%s;avatar=%s;dbid=%q,avatar.accountId = %d",
                                         avatar.accountName, avatar.name, dbid, avatar.accountId )

        --提前注册UserMgr管理器, 
        globalbase_call("UserMgr", "PlayerOnLine",
        '',                  --base的mb
        '',                  --cell的mb
        dbid,
        avatar.name,
        1,                   --level      
        avatar.vocation,
        avatar.gender,
        0,                                --工会dbid
        0,                                --战斗力
        0                                 --好友信息
        )

        local account = mogo.getEntity(avatar.accountId)
        if account then

            --记录account 对应的 avatars
            avatar.dbid = dbid

            --玩家创建角色的状态回来以后，把状态改回来
            account.state = ACCOUNT_STATE_INIT

            --帐号的角色列表里面增加一条记录
            account:AddAvatarsInfo(avatar, dbid)

            --增加默认道具给新建角色 
            avatar:InitItemsForAvatar(avatar.vocation, dbid)

            --保存下这个实体id，进入游戏的时候如果跟所选择的角色不同立即销魂该baseentity
            account.activeAvatarId = avatar:getId()

--            log_game_debug("Account:CreateCharacter", "")
            local mm = globalBases["NameMgr"]
            if mm then
                log_game_debug("OnAvatarWrited", "account.name=%s;avatar.name=%s", account.name, avatar.name)
                mm.UseName(account.name, avatar.name)
            end

--            --记录该角色应该进入新手关卡
--            account.NeedToNewbieMission[dbid] = 1

            --设置该玩家为新手
            avatar.baseflag = mogo.sset(avatar.baseflag, public_config.AVATAR_BASE_STATE_NEWBIE)

            account.avatarState = public_config.CHARACTER_CREATED
            --标记gm角色
            if g_GMData:IsGm(account.name) then
                --默认特殊处理gm帐号的竞技场行为
                Bit.Set(avatar.gm_setting, gm_setting_state.AREANA_STATE)
                local mm = globalBases['UserMgr']
                if mm then
                    mm.AddPlayer(avatar.dbid, account.name,avatar.gm_setting)
                    --mm.GmSetting(avatar.dbid,avatar.gm_setting)
                end
            end
            
            local accountName, platName = avatar:SplitAccountNameByString(avatar.accountName)

            local insert_table ={
                        role_id         =   dbid,
                        role_name       =   avatar.name,
                        account_name    =   accountName,
                        plat_name       =   platName,
                        dim_prof        =   avatar.vocation, 
                        os              = "android iphone",   --temp temp temp这里先写死 客户端还没做
                        os_version      = "2.3.4",
                        device          = "三星GT-S5830",
                        device_type     = "android、iPhone、iPad",
                        screen          = "480*800",
                        mno             = "中国移动,",
                        nm              = "3G，WIFI",
                        happend_time    =   os.time(),
                    }

            globalbase_call("Collector", "table_insert", "tbllog_role", insert_table)
        end
    else
        --写数据库失败
        log_game_error("OnAvatarWrited", "dbid = %q", dbid)
        local account = mogo.getEntity(avatar.accountId)
        if account and account:hasClient() then
            account.client.OnCreateCharacterResp(error_code.ERR_CREATE_AVATAR_DB, 0)
            --前面一个步骤中删掉了之前的avatar的缓存
            account.avatarState = public_config.CHARACTER_NONE
            account.activeAvatarId = 0
        end
        mogo.DestroyBaseEntity(avatar:getId())
    end
end


--构造函数
function Account:__ctor__()

    log_game_debug("Account.__ctor__", "id=%d;name=%s", self:getId(), self.name)
    --第一次创建
    if(self:getDbid() == 0) then
        self.createTime = os.time()
        self:writeToDB(FirstWriteToDb)
    else
        --通知客户端连接
        --log_game_debug("Account:NotifyClientToAttach", "name=%d", self.name)
        self:NotifyClientToAttach(self.name)
    end

    --log_game_debug("Account:bhliang", "name=%d", self.name)

    --log_game_debug("Account.__ctor__", "name=%d", self.name)

    --如果该帐号已经创建了角色(并且该角色没有并预先load),load Avatar
    --if self.activeAvatarDbid > 0 and self.activeAvatarDbid == 0 then
        --mogo.createBaseFromDBID('Avatar', self.avatar_dbid, OnAvatarCreatedFromDb(self:getId()) )
    --end
    
    self.mailBoxStr = mogo.pickleMailbox(self)  

    self.avatarState = public_config.CHARACTER_NONE

    --初始化帐号的状态
    self.state = ACCOUNT_STATE_INIT
end

--销毁前操作
function Account:onDestroy()
    log_game_info("Account:onDestroy", "dbid=%q;id=%d;activeAvatarId=%d;avatarsInfo=%s", 
                                        self:getDbid(), self:getId(), self.activeAvatarId, mogo.cPickle(self.avatarsInfo))
    if self.activeAvatarId > 0 then
        local avatar = mogo.getEntity(self.activeAvatarId)
        if avatar then
            --删除baseEntity and cellEntity
            --avatar:Quit(public_config.TMP_DATA_QUIT_MODE_SPECIAL)
            avatar:DeleteSelf()
        end
        --mogo.DestroyBaseEntity(self.activeAvatarId)
    end
    local function _dummy(a,b,c)
        log_game_error("Account:writeToDB", "")
    end
    self:writeToDB(_dummy)
end

--客户端连接到entity的回调方法
function Account:onClientGetBase()
    log_game_debug("Account:onClientGetBase", "dbid=%q;IP=%s", self:getDbid(), self:GetIPAddr())
    --如果是回退选角色界面的话不作任何处理
    if self.avatarQuitFlag == public_config.QUIT_BACK then
        --self.avatarQuitFlag = public_config.QUIT_NONE
        return
    end
    --连接到已经创建的avatar entity,转交客户端控制权
    self.avatarQuitFlag = public_config.QUIT_NONE

    --修改代码,使得bot_开头的帐号直接进入游戏

    local tmp = self.avatarsInfo[1]
    if tmp then
        local dbid = tmp[1]
        if string.find(self.name ,'bot_') then
            log_game_debug("bot............................", "test.........................")
            self:StartGameReq(dbid)
        end
    end

end

--把客户端交给激活的Avatar
function Account:GetClientToActiveAvatar()
    if self.activeAvatarId > 0 then
        local avatar = mogo.getEntity(self.activeAvatarId)
        if avatar and self:hasClient() then
            self.client.OnLoginResp(error_code.ERR_LOGIN_SUCCEED)
            avatar:DelDestroyTimer()
            self:GiveClientTo(avatar)
--            --avatar:register_user_info()
--            --删除已经添加的销毁定时器
--            avatar:DelDestroyTimer()
--            self.client.OnLoginResp(error_code.ERR_LOGIN_SUCCEED)
--            self.hasActiveAvatar = 1
--
--            --通知base客户端二次登录(这里注意区分两个客户端顶号和同一个客户端二次登录的情况)
--            avatar:onMultiLogin()
--
--            self:GiveClientTo(avatar)
--            log_game_debug("Account:GetClientToActiveAvatar", "")
--
--            --通知cell客户端二次登录
--            if avatar:HasCell() then
--                avatar.cell.onMultiLogin()
--            end
        end
    end
end

--客户端断开连接的回调方法
function Account:onClientDeath()
    log_game_debug("Account:onClientDeath", "dbid=%q", self:getDbid())
    local mm = globalBases["NameMgr"]
    if mm then
        mm.UnuseName(self.name)
    end

    --可以销毁Account,也可以不处理
    --设置立即销魂
    self.avatarQuitFlag = public_config.QUIT_UNNORMAL
    --开始走真正的销毁流程
    --self.accountDestroyFlag = public_config.DESTROY_FLAG_DESTROYING
    if self.activeAvatarId > 0 then
        local avatar = mogo.getEntity(self.activeAvatarId)
        if avatar then
            --走完整的销毁流程
            --avatar:Quit(public_config.TMP_DATA_QUIT_MODE_NORMAL)
            avatar:DeleteAll()
        else
            --有问题
            log_game_error("Account:onClientDeath", "avatar has some problem.")
            self:NotifyDbDestroyAccountCache(self.name)
        end
    else
        --走只删除account流程
        self:NotifyDbDestroyAccountCache(self.name)
    end 
end

--多个客户端连接的回调方法(包括二次登陆)
function Account:onMultiLogin()
    log_game_debug("Account:onMultiLogin", "dbid=%q;name=%s", self:getDbid(), self.name)

    --如果已经开始走销毁流程就不允许登陆
    if self.accountDestroyFlag == public_config.DESTROY_FLAG_DESTROYING then
        self:NotifyClientMultiLogin(self.name)
        log_game_warning("Account:onMultiLogin", "%s is destroying.", self.name)
        return
    end

    if self.state ~= ACCOUNT_STATE_INIT then
        self:NotifyClientMultiLogin(self.name)
        log_game_warning("Account:onMultiLogin", "dbid=%q;name=%s;state=%d", self:getDbid(), self.name, self.state)
        return
    end

    --如果这时候的account或者avatar有client，则通知新的客户端和老的客户端断开连接
    local hasClient = false
    if self:hasClient() then
        hasClient = true
    else
        if self.activeAvatarId ~= 0 then
            local avatar = mogo.getEntity(self.activeAvatarId)
            if avatar and avatar:hasClient() then
                hasClient = true
            end
        end
    end

    if not hasClient and self.activeAvatarId == 0 then
        self:NotifyClientToAttach(self.name)
    elseif not hasClient and self.activeAvatarId ~= 0 then
        self:NotifyClientToAttach(self.name)
        local avatar = mogo.getEntity(self.activeAvatarId)
        if avatar then
            avatar:DeleteSelf()
        end
    else
        self.avatarQuitFlag = public_config.QUIT_NONE
        self:NotifyClientMultiLogin(self.name)
        --通知老的客户端需要断开连接了
        if self:hasClient() then
            log_game_debug("Account:onMultiLogin account OnMultiLogin", "dbid=%q;name=%s", self:getDbid(), self.name)
            self.client.OnMultiLogin()
            self:NotifyDbDestroyAccountCache(self.name)
        else
            if self.activeAvatarId ~= 0 then
                local avatar = mogo.getEntity(self.activeAvatarId)
                if avatar and avatar:hasClient() then
                    log_game_debug("Account:onMultiLogin avatar OnMultiLogin", "dbid=%q;name=%s", self:getDbid(), self.name)
                    avatar.client.OnMultiLogin()

                    --一旦被顶号，则把玩家正在玩的avatar删除掉
                    avatar:DeleteAll()
                end
            end
        end
    end
    --[[
    --如果关联avatar没有退出,则顶号
    if self.avatarQuitFlag == 0 then
        log_game_debug("Account:onMultiLogin", "NotifyClientToAttach")
        self:NotifyClientToAttach(self.name)
    else 
       -->在开始游戏的时候如果角色还在缓存中直接连接该avatar hwj
        if self.activeAvatarId ~= 0 then
            avatar = mogo.getEntity(self.activeAvatarId)
            if avatar and self:hasClient() then
                --self.avatarId = avatar:getId()
                --avatar.accountId = self:getId()
                avatar:register_user_info()
                self:GiveClientTo(avatar)
                --todo:删除已经添加的销魂定时器
                avatar:DelDestroyTimer()
                log_game_debug("Account.__ctor__", "name=%s,reconnection exist avatar", self.name)          
            end
        else
            log_game_debug("Account:onMultiLogin", "NotifyClientToAttach too")
            self:NotifyClientToAttach(self.name)
        end
        --<hwj
    end
    ]]
end

--关联avatar存盘下线后的回调方法
function Account:onAvatarDestroyed()
    log_game_debug("Account:onAvatarDestroyed", "dbid=%q", self:getDbid())

    --销毁不存盘,但要通知dbmgr entity已经销毁了
    self.activeAvatarId = 0
--    self:destroy(2, self.name)
end

--创建新角色请求
--local _DEFAULT_BORN_POINT = {10102,287,214}      --缺省的出生点
function Account:CreateCharacterReq(name, gender, vocation)
    --正在创建角色中
    if self.avatarState == public_config.CHARACTER_CREATING then
        return
    end
    --如果刚刚创建了，但是又创建

    --检查是否超过角色可创建数量
    local num = 0
    for _, avatar in pairs(self.avatarsInfo) do
        if avatar[public_config.CHARACTER_KEY_NAME] == name then
            self.client.OnCreateCharacterResp(error_code.ERR_CREATE_AVATAR_NAME_EXISTS, 0)
            return
        end
        if avatar.dbid ~= 0 then 
            num = num + 1
        end
    end

--    if self.activeAvatarId > 0 then
--        local lastAvatar = mogo.getEntity(self.activeAvatarId)
--        --多次申请同一个角色创建
--        if lastAvatar and name == lastAvatar.name then
--            return
--        end
--    end
    --角色名字检查
    --长度
    local nNameLen = lua_util.utfstrlen(name)
    if nNameLen < 2 then
        self.client.OnCreateCharacterResp(error_code.ERR_CREATE_AVATAR_NAME_TOO_SHORT, 0)
        return
    elseif nNameLen > 8 then
        self.client.OnCreateCharacterResp(error_code.ERR_CREATE_AVATAR_NAME_TOO_LONG, 0)
        return
    end
    --检查特殊字符
    if not g_banned_char:Check(name) then
        self.client.OnCreateCharacterResp(error_code.ERR_CREATE_AVATAR_NAME_INVALID, 0)
        return
    end

    --检查敏感字
    if stopword_mgr:isStopWord(name) then
        self.client.OnCreateCharacterResp(error_code.ERR_CREATE_AVATAR_NAME_BANNED, 0)
        return
    end

    if gender ~= public_config.GENDER_MALE and gender ~= public_config.GENDER_FEMALE then
        self.client.OnCreateCharacterResp(error_code.ERR_CREATE_AVATAR_GENDER, 0)
        return
    end

    if vocation < public_config.VOC_MIN or vocation > public_config.VOC_MAX then
        self.client.OnCreateCharacterResp(error_code.ERR_CREATE_AVATAR_VOCATION, 0)
        return
    end

--    --由于发布原因，暂时禁止创建弓箭手
--    if vocation ~= public_config.VOC_WARRIOR and vocation ~= public_config.VOC_ASSASSIN and vocation ~= public_config.VOC_MAGE then
--        log_game_error("Account:CreateCharacterReq", "dbid=%q;name=%s;vocation=%d", self:getDbid(), self.name, vocation)
--        self.client.OnCreateCharacterResp(error_code.ERR_CREATE_AVATAR_VOCATION, 0)
--        return
--    end
--
--    if num >= g_GlobalParamsMgr:GetParams('max_avatar_num', 4) then
--        self.client.OnCreateCharacterResp(error_code.ERR_CREATE_AVATAR_TOO_MUCH, 0)
--        return
--    end

    --设置帐号在创建角色中
    self.avatarState = public_config.CHARACTER_CREATING
    --名字检查
    local mm = globalBases["UserMgr"]
    if mm then
        --CheckName(mbStr, name, param, cbFunc)
        mm.CheckName(self.mailBoxStr, name , {name, gender, vocation}, "CreateCharacter")
    else
        log_game_error("Account:CreateCharacterReq", '')
    end
end

function Account:CreateCharacter(tabInfo, ret)
    if ret ~= 0 then
        self.client.OnCreateCharacterResp(error_code.ERR_CREATE_AVATAR_NAME_EXISTS, 0)
        if self.activeAvatarId > 0 then 
            self.avatarState = public_config.CHARACTER_CREATED
        else
            self.avatarState = public_config.CHARACTER_NONE
        end
        return
    end

    if self.activeAvatarId > 0 then
        --mogo.DestroyBaseEntity(self.activeAvatarId)
        local lastAvatar = mogo.getEntity(self.activeAvatarId)
        if lastAvatar then 
          self.avatarQuitFlag = public_config.QUIT_NONE
          lastAvatar:DeleteSelf()
        end
    end

    local avatar = mogo.createBase("Avatar")
    avatar:init(self, tabInfo[1], tabInfo[2], tabInfo[3] )

    self.state = ACCOUNT_STATE_CREATING
    
    avatar:writeToDB(OnAvatarWrited)
end

function Account:SelectMapResp(map_id, imap_id, spBaseMb, spCellMb, dbid, params)

    log_game_debug("Account:SelectMapResp", "map_id=%d;imap_id=%d;activeAvatarId=%d;spBaseMb=%s;spCellMb=%s;dbid=%q;params=%s", map_id, imap_id, self.activeAvatarId, mogo.cPickle(spBaseMb), mogo.cPickle(spCellMb), dbid, mogo.cPickle(params))

--    self.NeedToNewbieMission[dbid] = nil

    local avatar = mogo.getEntity(self.activeAvatarId)
    if avatar then
        avatar.sceneId = map_id
        avatar.imap_id = imap_id

        if map_id ==  g_GlobalParamsMgr:GetParams('init_scene', 10004) then
            local locations = g_GlobalParamsMgr:GetParams('init_scene_random_enter_point', {})
            local index = math.random(1, lua_util.get_table_real_count(locations))
            avatar.map_x = locations[index][1]
            avatar.map_y = locations[index][2]
        else
            local MapCfgData = g_map_mgr:getMapCfgData(avatar.sceneId)

            if MapCfgData then
                avatar.map_x = MapCfgData['enterX']
                avatar.map_y = MapCfgData['enterY']
            end
        end

        if self:hasClient() then
            self.client.OnLoginResp(error_code.ERR_LOGIN_SUCCEED)
            self:GiveClientTo(avatar)
            avatar:onFirstLogin(spBaseMb)
        end

        --if self.avatarQuitFlag ~= public_config.QUIT_BACK then

        --end
    end
end
--当场景跳转失败时返回
function Account:SelectMapFailResp(scene, line)
    log_game_warning("Account:SelectMapFailResp","name=%s;scene=%d;line=%d", self.name, scene, line)
    --[[
    if g_map_mgr:IsWBMap(scene_line) then
        --跳转世界Boss成功后通知世界Boss管理器
        local mm = globalBases['WorldBossMgr'] 
        mm.EnterResp(self.ptr.theOwner.dbid, self.ptr.theOwner.name, scene_line, self.ptr.theOwner.base_mbstr, 0)
    end
    ]]
end
function Account:UpdateAvatarMode(avatarObj, avatar)
    --角色外观显示，数据存盘操作
    self:UpdateEquipMode(avatarObj, avatar)
    self:UpdateWingMode(avatarObj, avatar)
    self:UpdateSpecialEffectsMode(avatarObj, avatar)
end

function Account:UpdateEquipMode(avatarObj, avatar)
    local bagDatas = avatarObj.equipeds or {}
    avatar[public_config.CHATACTER_KEY_EQUIP_CUIRASS]  = 0
    avatar[public_config.CHATACTER_KEY_EQUIP_ARMGUARD] = 0
    avatar[public_config.CHATACTER_KEY_EQUIP_LEG]      = 0
    avatar[public_config.CHATACTER_KEY_EQUIP_WEAPON]   = 0

    for k, v in pairs(bagDatas) do
        local typeId = v[public_config.ITEM_INSTANCE_TYPEID]
        local item = g_itemdata_mgr:GetItem(public_config.ITEM_TYPE_CFG_TBL, typeId)
        if item.mode and item.mode ~= -1 then
            if v[public_config.ITEM_INSTANCE_GRIDINDEX] == public_config.BODY_CHEST then 
                avatar[public_config.CHATACTER_KEY_EQUIP_CUIRASS]  = item.mode
            end
            if v[public_config.ITEM_INSTANCE_GRIDINDEX] == public_config.BODY_ARMGUARD then
                avatar[public_config.CHATACTER_KEY_EQUIP_ARMGUARD] = item.mode
            end
            if v[public_config.ITEM_INSTANCE_GRIDINDEX] == public_config.BODY_LEG then
                avatar[public_config.CHATACTER_KEY_EQUIP_LEG]      = item.mode
            end
            if v[public_config.ITEM_INSTANCE_GRIDINDEX] == public_config.BODY_WEAPON then
                avatar[public_config.CHATACTER_KEY_EQUIP_WEAPON]   = item.mode
            end
        end
    end
end
function Account:UpdateWingMode(avatarObj, avatar)
    avatar[public_config.CHATACTER_KEY_SHOW_WING] = 0
    local wingBag = avatarObj.wingBag or {}
    local wingId  = wingBag[public_config.WING_BODY_INDEX]
    if wingId then
        avatar[public_config.CHATACTER_KEY_SHOW_WING] = wingId
    end
end
function Account:UpdateSpecialEffectsMode(avatarObj, avatar)
    avatar[public_config.CHATACTER_KEY_SHOW_JEWEL] = 0
    avatar[public_config.CHATACTER_KEY_SHOW_EQUIP] = 0
    avatar[public_config.CHATACTER_KEY_SHOW_STRGE] = 0
    local specBag = avatarObj.specEffects or {}
    local maxLvs  = {}
    maxLvs[public_config.SPEC_JEWEL_IDNEX] = 0
    maxLvs[public_config.SPEC_EQUIP_IDNEX] = 0
    maxLvs[public_config.SPEC_STRGE_IDNEX] = 0
    local specIds = {}
    for sId, _ in pairs(specBag) do
        local cfgData = g_spec_mgr:GetCfgData(sId)
        local nLevel  = cfgData.level or 0
        local nGrpId  = cfgData.group or 0
        if maxLvs[nGrpId] then
            if maxLvs[nGrpId] < nLevel then
                maxLvs[nGrpId]  = nLevel
                specIds[nGrpId] = sId
            end
        end
    end
    for gId, sId in pairs(specIds) do
        if gId == public_config.SPEC_JEWEL_IDNEX then
            avatar[public_config.CHATACTER_KEY_SHOW_JEWEL] = sId
        elseif gId == public_config.SPEC_EQUIP_IDNEX then
            avatar[public_config.CHATACTER_KEY_SHOW_EQUIP] = sId
        elseif gId == public_config.SPEC_STRGE_IDNEX then
            avatar[public_config.CHATACTER_KEY_SHOW_STRGE] = sId
        end
    end
end
function Account:AddAvatarsInfo(avatarObj, dbid)
    --if(table.getn(self.avatarsInfo) >= public_config.MAX_AVATAR_NUM) then
        --errNo = 1
        --return
    --end
    log_game_info("Account:AddAvatarsInfo",",avatarObj.vocation = %d, dbid = %q", avatarObj.vocation, dbid)
    local avatarInfo = {}   
    table.insert(avatarInfo, public_config.CHARACTER_KEY_DBID, dbid)
    table.insert(avatarInfo, public_config.CHARACTER_KEY_NAME, avatarObj.name)
    table.insert(avatarInfo, public_config.CHARACTER_KEY_VOCATION, avatarObj.vocation)
    table.insert(avatarInfo, public_config.CHARACTER_KEY_LEVEL, avatarObj.level)
    self:UpdateAvatarMode(avatarObj, avatarInfo)
    
    table.insert(self.avatarsInfo, avatarInfo)

    log_game_debug("Account:AddAvatarsInfo","dbid=%q;avatarsInfo=%s", dbid, mogo.cPickle(self.avatarsInfo))
    return 0
end

--已存在则更新，没有则判断是否可以插入，可以则插入
function Account:UpdateAvatarsInfo(avatarObj, dbid)
    for i, avatar in pairs(self.avatarsInfo) do

        if dbid == avatar[public_config.CHARACTER_KEY_DBID] then
            log_game_info("UpdateAvatar","dbid=%q;name=%s;vocation=%d;level=%d",
                                          dbid, avatarObj.name, avatarObj.vocation, avatarObj.level)
            --avatar[public_config.CHARACTER_KEY_DBID] = avatarObj.dbid
            avatar[public_config.CHARACTER_KEY_NAME]     = avatarObj.name
            avatar[public_config.CHARACTER_KEY_VOCATION] = avatarObj.vocation
            avatar[public_config.CHARACTER_KEY_LEVEL]    = avatarObj.level

            self:UpdateAvatarMode(avatarObj, avatar)

            log_game_debug("UpdateAvatarsInfo","dbid=%q;level=%d", dbid, avatarObj.level)
            return 0
        end
    end
end

--删除角色信息
function Account:DelCharacterReq(characterDbid)
    log_game_debug("Account:DelCharacterReq","characterdbid=%q;name=%s", characterDbid, self.name)
    local err = 1
    for i, avatar in pairs(self.avatarsInfo) do
        if characterDbid == avatar[public_config.CHARACTER_KEY_DBID] then
            table.remove(self.avatarsInfo, i)
            err = error_code.ERR_SUCCESSFUL
        end
    end
    if self.activeAvatarId > 0 and err == error_code.ERR_SUCCESSFUL then
        --mogo.DestroyBaseEntity(self.activeAvatarId)
        local lastAvatar = mogo.getEntity(self.activeAvatarId)
        if lastAvatar and lastAvatar.dbid == characterDbid then 
            self.avatarQuitFlag = public_config.QUIT_NONE
            lastAvatar:DeleteSelf() 
        end
    end
    self.client.OnDelCharacterResp(err, characterDbid)
end

--申请角色信息
function Account:CharaterInfoReq(accountName)
    self.client.OnCharaterInfoResp(self.avatarsInfo)
end

function Account:IsMyCharacter(characterDbid)
    if characterDbid == 0 then
        return false
    end
    for _,avatarInfo in pairs(self.avatarsInfo) do
        if characterDbid == avatarInfo[public_config.CHARACTER_KEY_DBID] then
            return true
        end
    end
end

function Account:StartGameReq(characterDbid)
    log_game_debug("Account:StartGameReq", "name=%s;characterdbid=%q", self.name, characterDbid)
    --正在创建角色中
    if self.avatarState == public_config.CHARACTER_CREATING then
        return
    end
    if characterDbid < 1 then
        self.client.OnLoginResp(error_code.ERR_LOGIN_AVATAR_BAD)
        return
    end
    if self:IsMyCharacter(characterDbid) ~= true then
        self.client.OnLoginResp(error_code.ERR_LOGIN_NOT_MY_CHARACTER)
        return
    end


    if self:IsIpForbidden() then
        self.client.OnLoginResp(error_code.ERR_LOGIN_IP_FORBIDDEN)--IP禁止登陆
        return
    end

    if self:IsAccountForbidden() then
        self.client.OnLoginResp(error_code.ERR_LOGIN_ACCOUNT_FORBIDDEN)--账号禁止登陆
        return
    end


--    log_game_debug("Account:StartGameReq", "name=%s;characterdbid=%q", self.name, characterDbid)
    --如果刚刚创建了，但是又不是选择刚刚创建的角色登陆

    if self.activeAvatarId > 0 then
        local lastAvatar = mogo.getEntity(self.activeAvatarId)

        --avatar存在
        if lastAvatar then
            if mogo.stest(lastAvatar.state, state_config.STATE_SCENE_CHANGING) ~= 0 then
                --如果玩家处于传送场景的状态，则不理会
                log_game_warning("Account:StartGameReq lastAvatar in changeing scene", "characterdbid=%q;lastAvatar.dbid=%q;activeAvatarId=%d", characterDbid, lastAvatar.dbid, self.activeAvatarId)
                return
            end

            if characterDbid ~= lastAvatar.dbid then
            log_game_debug("Account:StartGameReq", "DestroyBaseEntity characterdbid=%q;lastAvatar.dbid=%q;activeAvatarId=%d", 
                                                                      characterDbid, lastAvatar.dbid, self.activeAvatarId)
            --mogo.DestroyBaseEntity(self.activeAvatarId)
                lastAvatar:DeleteSelf()
            else
                log_game_debug("Account:StartGameReq", "already has avatar start to SelectMapReq lastAvatar.sceneId=%d;lastAvatar.imap_id=%d", lastAvatar.sceneId, lastAvatar.imap_id)

                if self.avatarQuitFlag == public_config.QUIT_BACK then
                    self:GetClientToActiveAvatar()
                else
--                        globalbase_call("MapMgr", "SelectMapReq", self.mailBoxStr, lastAvatar.sceneId, lastAvatar.imap_id, lastAvatar.dbid, lastAvatar.name, {})
                    globalbase_call("MapMgr", "SelectMapReq", self.mailBoxStr, g_GlobalParamsMgr:GetParams('init_scene', 10004), 0, lastAvatar.dbid, lastAvatar.name, {})
                    --设置avatar正在进出场景
                    lastAvatar.state = mogo.sset(lastAvatar.state, state_config.STATE_SCENE_CHANGING)
                end
--                end

--                lastAvatar.sceneId = g_GlobalParamsMgr:GetParams('init_scene', 10004)
--                lastAvatar.map_x = g_GlobalParamsMgr:GetParams('init_x', 0)
--                lastAvatar.map_y = g_GlobalParamsMgr:GetParams('init_y', 0)


                --if self:hasClient() then
                    --lastAvatar:register_new_user_info()
                    --self.client.OnLoginResp(error_code.ERR_LOGIN_SUCCEED)
                    --self:GiveClientTo(lastAvatar)
                --end
                return
            end
        end
    end

    local accountID = self:getId()

    local function onAvatarLogined(avatar)
        log_game_info("onAvatarLogined", "accountID=%d;account=%s;avatar=%s;dbid=%q", accountID, avatar.accountName, avatar.name, avatar.dbid )

        --玩家登录的状态回来以后，把状态改回来
        self.state = ACCOUNT_STATE_INIT

        if avatar then 
            self.activeAvatarId = avatar:getId()
--            avatar.dbid = characterDbid
            avatar.accountId = self:getId()
            local function _dummy(a,b,c)
            end
            self:writeToDB(_dummy)

--            if not self.NeedToNewbieMission[avatar.dbid] then
--                avatar.sceneId = g_GlobalParamsMgr:GetParams('init_scene', 10004)
--                avatar.map_x = g_GlobalParamsMgr:GetParams('init_x', 0)
--                avatar.map_y = g_GlobalParamsMgr:GetParams('init_y', 0)

--            --非断线重连的登录
--            avatar:onFirstLogin()

            globalbase_call("MapMgr", "SelectMapReq", self.mailBoxStr, g_GlobalParamsMgr:GetParams('init_scene', 10004), 0, avatar.dbid, avatar.name, {})

            --设置avatar正在进出场景
            avatar.state = mogo.sset(avatar.state, state_config.STATE_SCENE_CHANGING)
--            else
--                local missionId = g_GlobalParamsMgr:GetParams('newbie_mission_id', 10004)
--                local difficulty = g_GlobalParamsMgr:GetParams('newbie_difficulty', 1)
--                local tbl = {}
--                table.insert(tbl, tostring(missionId))
--                table.insert(tbl, tostring(difficulty))
--                local MissionCfg = g_mission_mgr:getCfgById(table.concat(tbl, '_'))
--
--
--                avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_ID] = missionId
--                avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_DIFFICULT] = difficulty
--
--                if MissionCfg and MissionCfg['scene'] then
--                    globalbase_call("MapMgr", "SelectMapReq", self.mailBoxStr, MissionCfg['scene'], 0, avatar.dbid, avatar.name)
--
--                    --设置avatar正在进出场景
--                    avatar.state = mogo.sset(avatar.state, state_config.STATE_SCENE_CHANGING)
--                end
--            end
            --if self:hasClient() then
                --avatar:register_new_user_info()
                --self.client.OnLoginResp(error_code.ERR_LOGIN_SUCCEED)
                --self:GiveClientTo(avatar)
            --end
        else
            --读数据库失败
            -- 应该是判断
            if self:hasClient() then
                self.client.OnLoginResp(error_code.ERR_LOGIN_READ_DB_FAILED)
            end
            --创建角色结束s
            self.avatarState = public_config.CHARACTER_NONE
            return
        end
    end

--    log_game_debug("start to createBaseFromDBID", "...")
    --正在创建角色中
    self.avatarState = public_config.CHARACTER_CREATING
    mogo.createBaseFromDBID("Avatar", characterDbid, onAvatarLogined)
    self.avatarQuitFlag = public_config.QUIT_NONE

    self.state = ACCOUNT_STATE_LOGINING
end

--function Account:Logout()
--    log_game_info("Account.Logout", "dbid=%q,id=%d", self:getDbid(),self:getId())
--    --正在销毁中
--    local mm = globalBases["NameMgr"]
--    if mm then
--        mm.UnuseName(self.name)
--    end
--    if self.accountDestroyFlag == public_config.DESTROY_FLAG_DESTROYING then
--        log_game_error("Account:Logout", 'already destroying.')
--        return
--    end
--    --走avatar正常(立即)退出流程
--    if self.activeAvatarId > 0 then
--        local lastAvatar = mogo.getEntity(self.activeAvatarId)
--        if lastAvatar then
--            lastAvatar:Logout(public_config.LOGOUT_QUIT)
--            log_game_debug("Account:Logout", 'goto avatar logout.')
--            return
--        end
--    end
--
--    self.client.OnLogoutResp(public_config.LOGOUT_QUIT)
--    --默认处理：销毁自身
--    self.accountDestroyFlag = public_config.DESTROY_FLAG_DESTROYING
--    self:NotifyDbDestroyAccountCache(self.name)
--    self.avatarQuitFlag = public_config.QUIT_NORMAL
--end

function Account:Check(canLoginVersions, strVersion, delim)
    local ver = lua_util.split_str(strVersion, delim, tonumber)
--    log_game_debug('Account:CheckVersionReq', 'ver size = %d', lua_util.get_table_real_count(ver) )

    if canLoginVersions[1] then
--        log_game_debug('Account:CheckVersionReq', canLoginVersions[1])
        local minVer = lua_util.split_str(canLoginVersions[1], delim, tonumber)
--        log_game_debug('Account:CheckVersionReq', 'minVer size = %d', lua_util.get_table_real_count(minVer))

        if #ver ~= #minVer then 
            return false
        end
        for i,v in ipairs(minVer) do
--            log_game_debug('Account:CheckVersionReq', 'ver[i] = %d, minVer[i] = %d', ver[i] , minVer[i])
            if ver[i] < minVer[i] then
                return false
            elseif ver[i] > minVer[i] then
                break
            end
            if i == #minVer then
                return ver[i] == minVer[i]
            end
        end
    end
    if canLoginVersions[2] then
--        log_game_debug('Account:CheckVersionReq', canLoginVersions[2])
        local maxVer = lua_util.split_str(canLoginVersions[2], delim, tonumber)
--        log_game_debug('Account:CheckVersionReq', 'maxVer size = %d', lua_util.get_table_real_count(maxVer))

        if #ver ~= #maxVer then
            return false
        end
        for i,v in ipairs(maxVer) do
--            log_game_debug('Account:CheckVersionReq', 'ver[i] = %d, maxVer[i] = %d', ver[i] , maxVer[i])
            if ver[i] > maxVer[i] then
--                log_game_debug('Account:CheckVersionReq', 'ver[%d] > maxVer[%d]', i, i)
                return false
            elseif ver[i] < maxVer[i] then
                break
            end
            if i == #maxVer then
                return ver[i] == maxVer[i]
            end
        end
    end
    return true
end

function Account:CheckVersionReq( strVersion )
    local delim = '%.'
    local version = g_GlobalParamsMgr:GetParams('version', '0')
--    log_game_debug('Account:CheckVersionReq', version)
    if version ~= '0' and strVersion == version then
        self.client.OnCheckVersionResp(error_code.ERR_VERSION_SUCCEED)
        return
    end

    local canLoginVersions = g_GlobalParamsMgr:GetParams('server_version', {})

    if self:Check(canLoginVersions, strVersion, delim) then
        self.client.OnCheckVersionResp(error_code.ERR_VERSION_CAN)
    else
        --todo:记录更新情况
--        log_game_info('CheckVersion', '%s', self.name)
        self.client.OnCheckVersionResp(error_code.ERR_VERSION_FORBID)
    end
--    if self.avatarQuitFlag ~= public_config.QUIT_BACK then  
--        self:GetClientToActiveAvatar()
--    end

end

function Account:RandomNameReq(vocation)
    --self.client.RandomNameResp("test")
    --todo:
    local mm = globalBases["NameMgr"]
    if mm then
        --log_game_debug("Account:RandomNameReq", "name = %s, vocation = %d", self.name, vocation)
        mm.GetRandomName(self.name, vocation, self.mailBoxStr)
    end
end

function Account:PhoneInfo(guid, str_info)
    --globalbase_call("Collector","PhoneInfo",self.name, guid, str_info)
    self.cellphone = str_info
end

--ip是否被封
function Account:IsIpForbidden()

    local forbidden_ips = global_data.GetBaseData("forbidden_ips")
    local ip = self:GetIPAddr()

    if forbidden_ips  and forbidden_ips[ip] then
        
        local cur_time = os.time()
        local forbid_time = forbidden_ips[ip] 
        if forbid_time == 0 then  -- 0表示永久禁止登陆
            return true
        else
            return cur_time < forbid_time --账号被禁止 还没到时间
        end 
    end
    return false    
end

--账号是否被封
function Account:IsAccountForbidden()

    local forbidden_accounts = global_data.GetBaseData("forbidden_accounts")
    local name = self.name
    
    if forbidden_accounts and forbidden_accounts[name] then
        
        local cur_time = os.time()
        local forbid_time = forbidden_accounts[name]
        if forbid_time == 0 then  -- 0表示永久禁止登陆
            return true
        else
            return cur_time < forbid_time --账号被禁止 还没到时间
        end 
    end
    return false     
end

--设置平台帐号
function Account:SetPlatAccountReq(platAccount)
    self.platAccount = platAccount
end

--设置客户端的进度
function Account:SetProgress(progress)
    log_game_debug("Account:SetProgress", "name=%s;platAccount=%s;OldProgress=%d;NewProgress=%d", self.name, self.platAccount, self.progress, progress)

    if self.progress < progress then
        log_game_info("Account:SetProgress", "name=%s;platAccount=%s;progress=%d", self.name, self.platAccount, self.progress)
        self.progress = progress
    end
end

return Account
