require "timer_config"
require "lua_util"
require "public_config"
require "dragon_data"
require "error_code"

---------------------------------------------------------------------------------------
local log_game_info              = lua_util.log_game_info
local log_game_debug             = lua_util.log_game_debug
local log_game_error             = lua_util.log_game_error
local log_game_warning           = lua_util.log_game_warning
local globalbase_call            = lua_util.globalbase_call
local choose_1                   = lua_util.choose_1
---------------------------------------------------------------------------------------
local TIMER_ID_ZERO              = 1
local REDIS_INFO_SEQ             = 1
---------------------------------------------------------------------------------------
local AVATAR_DRAGON_EVENTS       =  public_config.AVATAR_DRAGON_EVENTS       --事件列表
local AVATAR_DRAGON_ATKEDSTIMES  =  public_config.AVATAR_DRAGON_ATKEDSTIMES  --被成功袭击次数
local AVATAR_DRAGON_LEVEL        =  public_config.AVATAR_DRAGON_LEVEL        --角色等级
local AVATAR_DRAGON_CNTRING      =  public_config.AVATAR_DRAGON_CNTRING      --当前环数
local AVATAR_DRAGON_DAGQUA       =  public_config.AVATAR_DRAGON_DAGQUA       --飞龙品质
local AVATAR_DRAGON_STARTTIME    =  public_config.AVATAR_DRAGON_STARTTIME    --护送结束时间
local AVATAR_DRAGON_ADVERSARY    =  public_config.AVATAR_DRAGON_ADVERSARY    --对手信息
local AVATAR_DRAGON_EQUIPS       =  public_config.AVATAR_DRAGON_EQUIPS       --对手装备
---------------------------------------------------------------------------------------
local EVENT_TYPE_CONVOY          =  public_config.EVENT_TYPE_CONVOY          --护送事件
local EVENT_TYPE_ATK_WIN         =  public_config.EVENT_TYPE_ATK_WIN         --袭击成功事件
local EVENT_TYPE_ATK_LOSE        =  public_config.EVENT_TYPE_ATK_LOSE        --袭击失败事件
local EVENT_TYPE_ATKED_WIN       =  public_config.EVENT_TYPE_ATKED_WIN       --战胜袭击者事件
local EVENT_TYPE_ATKED_LOSE      =  public_config.EVENT_TYPE_ATKED_LOSE      --战败袭击者事件
---------------------------------------------------------------------------------------
local EVENT_REVENGE_NO           =  public_config.EVENT_REVENGE_NO           --没有复仇
local EVENT_REVENGE_OK           =  public_config.EVENT_REVENGE_OK           --已复仇
local EVENT_REVENGE_UNUSE        =  public_config.EVENT_REVENGE_UNUSE        --不用复仇
---------------------------------------------------------------------------------------
local EVENT_DRAGON_DBID          =  public_config.EVENT_DRAGON_DBID          --作用对象
local EVENT_DRAGON_ETYPE         =  public_config.EVENT_DRAGON_ETYPE         --事件类型
local EVENT_DRAGON_QUALITY       =  public_config.EVENT_DRAGON_QUALITY       --飞龙品质
local EVENT_DRAGON_GAIN          =  public_config.EVENT_DRAGON_GAIN          --袭击战利品
local EVENT_DRAGON_STAMP         =  public_config.EVENT_DRAGON_STAMP         --时间戳
local EVENT_DRAGON_REVENGE       =  public_config.EVENT_DRAGON_REVENGE       --复仇状态
---------------------------------------------------------------------------------------
local DRAGON_QUALITY_GREEN       =  public_config.DRAGON_QUALITY_GREEN       --飞龙绿色品质
local DRAGON_QUALITY_BLUE        =  public_config.DRAGON_QUALITY_BLUE        --飞龙蓝色品质
local DRAGON_QUALITY_PURPLE      =  public_config.DRAGON_QUALITY_PURPLE      --飞龙粉色品质
local DRAGON_QUALITY_ORANGE      =  public_config.DRAGON_QUALITY_ORANGE      --飞龙橙色品质
local DRAGON_QUALITY_GOLD        =  public_config.DRAGON_QUALITY_GOLD        --飞龙暗金品质
---------------------------------------------------------------------------------------
local ADVERSARY_INFO_DBID        =  public_config.ADVERSARY_INFO_DBID      --角色dbid
local ADVERSARY_INFO_FFORCE      =  public_config.ADVERSARY_INFO_FFORCE    --角色战斗力
local ADVERSARY_INFO_GUILD       =  public_config.ADVERSARY_INFO_GUILD     --角色公会名称
local ADVERSARY_INFO_QUALITY     =  public_config.ADVERSARY_INFO_QUALITY   --角色飞龙品质
local ADVERSARY_INFO_ASTATUS     =  public_config.ADVERSARY_INFO_ASTATUS   --角色袭击状态
local ADVERSARY_INFO_ATIMES      =  public_config.ADVERSARY_INFO_ATIMES    --角色被成功袭击次数
local ADVERSARY_INFO_REWARD      =  public_config.ADVERSARY_INFO_REWARD    --角色袭击成功可获得的奖励
local ADVERSARY_INFO_LEVEL       =  public_config.ADVERSARY_INFO_LEVEL     --角色等级
local ADVERSARY_INFO_NAME        =  public_config.ADVERSARY_INFO_NAME      --角色名称
local ADVERSARY_INFO_CHEST       =  public_config.ADVERSARY_INFO_CHEST     --胸甲
local ADVERSARY_INFO_WEAPON      =  public_config.ADVERSARY_INFO_WEAPON    --武器
---------------------------------------------------------------------------------------
local ADVERSARY_ATK_CAN          =  public_config.ADVERSARY_ATK_CAN        --可袭击状态
local ADVERSARY_ATK_CANNOT       =  public_config.ADVERSARY_ATK_CANNOT     --不可袭击
-------------------------------------------------------------------------------------
local NEED_AVATAR_COUNT_ON       =  4      --开始护送角色请求数量

---------------------------------------------------------------------------------------
local tmpCountLoaded             =  0    --加载数据回调所用
FlyDragonMgr = {}
setmetatable(FlyDragonMgr, {__index = BaseEntity} )

---------------------------------------------------------------------------------------
--重置飞龙数据接口
---------------------------------------------------------------------------------------
function FlyDragonMgr:ResetAvatarInfo(dbid)
    local info = self:GetAvatarInfo(dbid)
    if not info then
      return 
    end
    info[AVATAR_DRAGON_LEVEL]       = 0
    info[AVATAR_DRAGON_DAGQUA]      = 0
    info[AVATAR_DRAGON_STARTTIME]   = 0
    info[AVATAR_DRAGON_CNTRING]     = 0
    info[AVATAR_DRAGON_ATKEDSTIMES] = 0
    info[AVATAR_DRAGON_EQUIPS]      = {}
end
---------------------------------------------------------------------------------------
--获取飞龙数据接口
---------------------------------------------------------------------------------------
function FlyDragonMgr:GetAvatarInfo(dbid)
    local info = self.DbidToPlayers[dbid]
    if not info then
        log_game_error("FlyDragonMgr:GetAvatarInfo", "dbid=%d not register", dbid)
    end
    return info
end
---------------------------------------------------------------------------------------
--刷新飞龙对手Base请求接口
---------------------------------------------------------------------------------------
function FlyDragonMgr:FreshDragonAdversariesReq(mbStr, dbid, level)
    local info  = self:GetAvatarInfo(dbid)
    if not info then
        return
    end
    local mb = mogo.UnpickleBaseMailbox(mbStr)
    if not mb then
        return
    end
    local aList = self:FreshDragonAdversary(dbid, level, NEED_AVATAR_COUNT_ON)
    self:SaveAvatar(dbid)
    log_game_debug("FlyDragonMgr:FreshDragonAdversariesReq", "dbid=%q;level=%d;adversaries=%s", 
        dbid, level, mogo.cPickle(aList))
    globalbase_call("UserMgr", "DragonAdversariesReq", mbStr, aList)
end

---------------------------------------------------------------------------------------
--初始化数据处理，注册角色数据和生成对手列表
---------------------------------------------------------------------------------------
function FlyDragonMgr:DragonAdversariesReq(mbStr, dbid)
    local info  = self:GetAvatarInfo(dbid)
    if not info then return end
    local level = info[AVATAR_DRAGON_LEVEL]
    local aList = info[AVATAR_DRAGON_ADVERSARY] or {}
    local infoList = self:GetAvatarAdvListInfo(dbid, level, aList)
    log_game_debug("FlyDragonMgr:DragonAdversariesReq", "dbid=%q;level=%d;adv_list=%s", 
        dbid, level, mogo.cPickle(aList))
    globalbase_call("UserMgr", "DragonAdversariesReq", mbStr, infoList)
end
function FlyDragonMgr:RegisterInfoRecoveryReq(dbid, level, cRing, dgnColor, endTime, equipeds)
    log_game_debug("FlyDragonMgr:RegisterInfoRecoveryReq", "dbid=%q;level=%d;ring=%d;quality=%d;endTime=%d;equips=%s",
        dbid, level, cRing, dgnColor, endTime, mogo.cPickle(equipeds))
    local info = self:GetAvatarInfo(dbid)
    if info then return end
    self:SpeciDealForStart(dbid, endTime, level, dgnColor, cRing, equipeds)
end
function FlyDragonMgr:SpeciDealForStart(dbid, endTime, level, dgnColor, cRing, equipeds)
    self:RegisterDragonContestReq(dbid, level)
    local info = self:GetAvatarInfo(dbid)
    info[AVATAR_DRAGON_LEVEL]     = level
    info[AVATAR_DRAGON_DAGQUA]    = dgnColor
    info[AVATAR_DRAGON_STARTTIME] = endTime
    info[AVATAR_DRAGON_EQUIPS]    = equipeds
    if cRing <= 0 then
        cRing = 1
    end
    info[AVATAR_DRAGON_CNTRING]   = cRing
    local aList = self:GetAvatarAdvDbidList(dbid, level, NEED_AVATAR_COUNT_ON)
    info[AVATAR_DRAGON_ADVERSARY] = aList
    local curTime = os.time()
    if curTime < endTime then
        self:AddToLevelList(level, dbid)
    end
end
---------------------------------------------------------------------------------------
--获取飞龙对手列表
---------------------------------------------------------------------------------------
function FlyDragonMgr:FreshDragonAdversary(dbid, level, count)
    local info  = self:GetAvatarInfo(dbid)
    if not info then
        return
    end
    local aList    = self:GetAvatarAdvDbidList(dbid, level, count)
    log_game_debug("FlyDragonMgr:FreshDragonAdversary", "dbid=%q;level=%d;advsDbid=%s", 
        dbid, level, mogo.cPickle(aList))
    local infoList = self:GetAvatarAdvListInfo(dbid, level, aList)
    log_game_debug("FlyDragonMgr:FreshDragonAdversary", "dbid=%q;level=%d;advsInfo=%s", 
        dbid, level, mogo.cPickle(infoList))
    info[AVATAR_DRAGON_ADVERSARY] = aList
    return infoList
end
---------------------------------------------------------------------------------------
--对手选取接口,只记录dbid
---------------------------------------------------------------------------------------
function FlyDragonMgr:GetAvatarAdvDbidList(dbid, level, count)
    local aList  = {dbid}
    local minLv  = level - 10
    local maxLv  = level + 10
    local tpCnt  = 0
    local lvList = {}
    local result = {}
    while minLv <= maxLv do
        if minLv ~= level then
            tpCnt = tpCnt + 1
            self:GetAdvList(minLv, result, lvList)
            if math.fmod(tpCnt, 5) == 0 then
                if next(result) then
                    local tDbid = choose_1(result)
                    if not self:HasSameOpponent(aList, tDbid) then
                        table.insert(aList, tDbid)
                    end
                    result = {}
                end
            end
        end
        minLv = minLv + 1
    end
    tpCnt = #aList --取已找到对手个数
    if tpCnt <= count then --对手个数没有到达上限(包含自己)
        self:GetAdvList(level, result, lvList)
        if #lvList <= count then  --当前范围内对手不足(全部取出来)
            for _, sDbid in pairs(lvList) do
                if not self:HasSameOpponent(aList, sDbid) then
                    table.insert(aList, sDbid)
                end
            end
        else  --对手足够
            while tpCnt <= count do
                local sDbid = choose_1(lvList)
                if sDbid then
                    if not self:HasSameOpponent(aList, sDbid) then
                        table.insert(aList, sDbid)
                        tpCnt = tpCnt + 1
                    end
                end
            end
        end
    end
    return aList
end
---------------------------------------------------------------------------------------
--根据实际dbid生成对手信息
---------------------------------------------------------------------------------------
function FlyDragonMgr:GetAvatarAdvListInfo(sDbid, level, dbidList)
    local infoList = {}
    for _, dbid in pairs(dbidList) do
        local dInfo = self:GetAdversaryInfo(sDbid, dbid, level)
        if dInfo then
            table.insert(infoList, dInfo)
        end
    end
    return infoList
end
function FlyDragonMgr:GetAdvList(level, result, lvList)
    local lList = self.LevelList[level] or {}
    for k, _ in pairs(lList) do
        table.insert(result, k)
        table.insert(lvList, k)
    end
end
---------------------------------------------------------------------------------------
--判断对手列表中是否有相同的对手
---------------------------------------------------------------------------------------
function FlyDragonMgr:HasSameOpponent(aList, dbid)
    for _, vDbid in pairs(aList) do
        if vDbid == dbid then
            return true
        end
    end
    return false
end
---------------------------------------------------------------------------------------
--获取对手数据信息
---------------------------------------------------------------------------------------
function FlyDragonMgr:GetAdversaryInfo(sDbid, dbid, sLevel)
    local regInfo  = self:GetAvatarInfo(dbid)
    if not regInfo then
        return
    end
    local gainInfo = {}
    local level    = regInfo[AVATAR_DRAGON_LEVEL]
    if level == 0 then
        return 
    end
    gainInfo[ADVERSARY_INFO_ASTATUS] = ADVERSARY_ATK_CAN
    local quality  = regInfo[AVATAR_DRAGON_DAGQUA]
    local etime    = regInfo[AVATAR_DRAGON_STARTTIME]
    if etime <= os.time() then
        gainInfo[ADVERSARY_INFO_ASTATUS] = ADVERSARY_ATK_CANNOT
        self:RemoveFromLevelList(level, dbid)  --已经完成移除注册表
    end
    local atkTimes = regInfo[AVATAR_DRAGON_ATKEDSTIMES]
    local equips   = regInfo[AVATAR_DRAGON_EQUIPS]
    local curRng   = regInfo[AVATAR_DRAGON_CNTRING] or 0
    local rwds     = self:CaltAtkRewards(sLevel, level, quality, curRng)
    local cLimit   = g_dragon_mgr:GetConvoyAttackedTimes() 
    if cLimit <= atkTimes then
        gainInfo[ADVERSARY_INFO_ASTATUS] = ADVERSARY_ATK_CANNOT
    end
    gainInfo[ADVERSARY_INFO_DBID]    = dbid
    gainInfo[ADVERSARY_INFO_ATIMES]  = atkTimes
    gainInfo[ADVERSARY_INFO_QUALITY] = quality
    gainInfo[ADVERSARY_INFO_LEVEL]   = level
    gainInfo[ADVERSARY_INFO_REWARD]  = rwds
    gainInfo[ADVERSARY_INFO_CHEST]   = equips[public_config.BODY_POS_CHEST] or 0
    gainInfo[ADVERSARY_INFO_WEAPON]  = equips[public_config.BODY_POS_WEAPON + 1] or 0
    log_game_debug("FlyDragonMgr:GetAdversaryInfo", "self_level=%d;advy_level=%d;gainInfo=%s", 
        sLevel, level, mogo.cPickle(gainInfo))
    return gainInfo
end

---------------------------------------------------------------------------------------
--计算袭击奖励
---------------------------------------------------------------------------------------
function FlyDragonMgr:CaltAtkRewards(sLevel, level, quality, curRng)
    local rewards      = g_dragon_mgr:GetRewards(level) or {}                 --基本奖励(table)
    local pects        = g_dragon_mgr:GetAttackPercent()                      --袭击占比
    local awdAdd       = g_dragon_mgr:GetQualityRewardAdd(quality)            --品质加成系数
    local stnAdd       = g_dragon_mgr:GetAddFactor(curRng)                    --站点加成系数
    local baseVals     = g_dragon_mgr:GetLevelBase(sLevel)                    --获取等级基础经验和金币
    local upLimits     = g_dragon_mgr:GetAttackUpLimit()                      --袭击上限控制因子
    local rewds = {}
    for kType, val in pairs(rewards) do
        local atkPt = pects[kType] or 0
        local rest  = val*(1 + stnAdd*0.0001)*(1 + awdAdd*0.0001)*atkPt*0.0001
        local bsVal = baseVals[kType]
        local limit = upLimits[kType]
        if limit and bsVal then
           local nRest = limit*bsVal
           if rest > nRest then
               rest = nRest
           end
        end
        rewds[kType] = rest
    end
    return rewds
end
---------------------------------------------------------------------------------------
--飞龙护送结算请求接口
---------------------------------------------------------------------------------------
function FlyDragonMgr:DragonContestSettleReq(mbStr, dbid)
    local info = self:GetAvatarInfo(dbid)
    if not info then
        return
    end
    local mb = mogo.UnpickleBaseMailbox(mbStr)
    if not mb then
        return
    end
    local sucTimes = info[AVATAR_DRAGON_ATKEDSTIMES] or 0
    local level    = info[AVATAR_DRAGON_LEVEL] or 0
    local curRng   = info[AVATAR_DRAGON_CNTRING] or 0
    log_game_debug("FlyDragonMgr:DragonContestSettleReq", "dbid=%q;suc=%d;level=%d;curRng=%d", dbid, sucTimes, level, curRng)
    mb.BaseDragonContestSettleResp(sucTimes, level, curRng)
end
---------------------------------------------------------------------------------------
--刷新飞龙护送奖励接口
---------------------------------------------------------------------------------------
function FlyDragonMgr:FreshConvoyRewardReq(mbStr, dbid)
    local info = self:GetAvatarInfo(dbid)
    if not info then
        return
    end
    local mb = mogo.UnpickleBaseMailbox(mbStr)
    if not mb then
        return
    end
    local sucTimes = info[AVATAR_DRAGON_ATKEDSTIMES]
    local level    = info[AVATAR_DRAGON_LEVEL]
    local curRng   = info[AVATAR_DRAGON_CNTRING]
    mb.BaseFreshConvoyRewardResp(sucTimes, level, curRng)
end
---------------------------------------------------------------------------------------
--飞龙护送完成Base回调接口更新飞龙相关数据
---------------------------------------------------------------------------------------
function FlyDragonMgr:DragonConvoyCompleteResp(mbStr, dbid, rewds)
    local info = self:GetAvatarInfo(dbid)
    if not info then
        return 
    end
    local etime   = info[AVATAR_DRAGON_STARTTIME]
    local quality = info[AVATAR_DRAGON_DAGQUA]
    local level   = info[AVATAR_DRAGON_LEVEL]
    local eType   = EVENT_TYPE_CONVOY
    local rvge    = EVENT_REVENGE_UNUSE
    self:CompleteNewEvent(info, dbid, eType, quality, rvge, etime, rewds)
    log_game_debug("FlyDragonMgr:DragonConvoyCompleteResp", "dbid=%q;eventType=%d;quality=%d;revenge=%d;end_time=%d;rewds=%s",
        dbid, eType, quality, rvge, etime, mogo.cPickle(rewds))
    self:RemoveFromLevelList(level, dbid) 
    self:ResetAvatarInfo(dbid)    
    self:SaveAvatar(dbid)
end
---------------------------------------------------------------------------------------
--开始飞龙护送请求接口
---------------------------------------------------------------------------------------
function FlyDragonMgr:StartDragonConvoyReq(mbStr, dbid, level, currRng, quality, equips)
    local info = self:GetAvatarInfo(dbid)
    if not info then
        self:RegisterDragonContestReq(dbid, level)
        info = self:GetAvatarInfo(dbid)
    end
    local mb = mogo.UnpickleBaseMailbox(mbStr)
    if not mb then
        return
    end
    local cvyTime = g_dragon_mgr:GetConvoyTime(quality, currRng)
    local etime   = os.time() + cvyTime
    info[AVATAR_DRAGON_ATKEDSTIMES] = 0
    info[AVATAR_DRAGON_LEVEL]       = level
    info[AVATAR_DRAGON_CNTRING]     = currRng
    info[AVATAR_DRAGON_DAGQUA]      = quality
    info[AVATAR_DRAGON_STARTTIME]   = etime --护送结束时间
    info[AVATAR_DRAGON_EQUIPS]      = equips
    self:AddToLevelList(level, dbid)
    self:SaveAvatar(dbid)
    local retCode = error_code.ERR_DRAGON_OK
    mb.BaseStartDragonConvoyResp(retCode, etime)
end
---------------------------------------------------------------------------------------
--生成新的事件信息
---------------------------------------------------------------------------------------
function FlyDragonMgr:NewEvent(dbid, eType, quality, rvg, etime, rewds)
    local event   = {}
    event[EVENT_DRAGON_DBID]    = dbid        --作用对象
    event[EVENT_DRAGON_ETYPE]   = eType       --事件类型
    event[EVENT_DRAGON_QUALITY] = quality     --飞龙品质
    event[EVENT_DRAGON_GAIN]    = rewds       --物品获得
    event[EVENT_DRAGON_STAMP]   = etime       --结束时间
    event[EVENT_DRAGON_REVENGE] = rvg         --复仇标记
    return event
end
---------------------------------------------------------------------------------------
--新事件插入到角色事件列表中
---------------------------------------------------------------------------------------
function FlyDragonMgr:CompleteNewEvent(info, dbid, eType, quality, rvg, etime, rewds)
    local nEvent = self:NewEvent(dbid, eType, quality, rvg, etime, rewds)
    local eList  = info[AVATAR_DRAGON_EVENTS] or {}
    local rCount = lua_util.get_table_real_count(eList)
    if rCount < 20 then
        table.insert(eList, nEvent)
    else
        table.remove(eList, 1)
        table.insert(eList, nEvent)
    end
end
---------------------------------------------------------------------------------------
--请求所有角色事件接口
---------------------------------------------------------------------------------------
function FlyDragonMgr:AllDragonEventListReq(mbStr, dbid)
    local info = self:GetAvatarInfo(dbid)
    if not info then
        return
    end
    local eList = info[AVATAR_DRAGON_EVENTS]
    globalbase_call("UserMgr", "EventListAvatarNameReq", mbStr, eList)
end
---------------------------------------------------------------------------------------
--复仇状态数据检查
---------------------------------------------------------------------------------------
function FlyDragonMgr:DragonRevengeCheckReq(mbStr, atkId, atkedId)
    local mb = mogo.UnpickleBaseMailbox(mbStr)
    if not mb then
        return 
    end
    if not self:AttackAndRevengeCheck(mb, atkedId) then
        return
    end
    globalbase_call("UserMgr", "DragonAttackPvpNameReq", mbStr, atkId, atkedId)
end
function FlyDragonMgr:AttackAndRevengeCheck(mb, atkedId)
    local info    = self:GetAvatarInfo(atkedId)
    local retCode = error_code.ERR_DRAGON_OK
    if not info then
        retCode = error_code.ERR_DRAGON_NOATKED
        mb.BaseDragonAttackResp(retCode)
        return false
    end
    local etime   = info[AVATAR_DRAGON_STARTTIME] --结束时间
    if etime <= os.time() then
        retCode = error_code.ERR_DRAGON_NOCONVOY
        mb.BaseDragonAttackResp(retCode)
        return false
    end
    local sucTimes = info[AVATAR_DRAGON_ATKEDSTIMES]
    local sucLimit = g_dragon_mgr:GetConvoyAttackedTimes()
    if sucTimes >= sucLimit then
        retCode = error_code.ERR_DRAGON_MAX_ATKED_TIMES
        mb.BaseDragonAttackResp(retCode)
        return false
    end
    return true
end
---------------------------------------------------------------------------------------
--初始化角色基本信息
---------------------------------------------------------------------------------------
function FlyDragonMgr:InitAvatarInfos(dbid, level)
    local infos   = {}
    local dgnClor = DRAGON_QUALITY_GREEN
    infos[AVATAR_DRAGON_EVENTS]      = {}
    infos[AVATAR_DRAGON_ATKEDSTIMES] = 0
    infos[AVATAR_DRAGON_LEVEL]       = level
    infos[AVATAR_DRAGON_CNTRING]     = 0
    infos[AVATAR_DRAGON_DAGQUA]      = dgnClor
    infos[AVATAR_DRAGON_STARTTIME]   = 0
    infos[AVATAR_DRAGON_ADVERSARY]   = {}
    infos[AVATAR_DRAGON_EQUIPS]      = {}
    return infos
end
---------------------------------------------------------------------------------------
--飞龙袭击请求
---------------------------------------------------------------------------------------
function FlyDragonMgr:DragonAttackReq(mbStr, atkId, atkedId)
    local mb = mogo.UnpickleBaseMailbox(mbStr)
    if not mb then
        return
    end
    if not self:GetAvatarInfo(atkId) then
        return
    end
    if not self:GetAvatarInfo(atkedId) then
        return
    end
    if not self:AttackAndRevengeCheck(mb, atkedId) then
        return
    end
    globalbase_call("UserMgr", "DragonAttackPvpNameReq", mbStr, atkId, atkedId)
end
---------------------------------------------------------------------------------------
--飞龙袭击PVP名字获取回调接口
---------------------------------------------------------------------------------------
function FlyDragonMgr:DragonAttackPvpNameCallback(mbStr, atkInfo, atkedInfo)
    local mb = mogo.UnpickleBaseMailbox(mbStr)
    if not mb then
        return 
    end
    local atkDbid = atkInfo[public_config.DRAGON_PVP_DBID]
    local atkedId = atkedInfo[public_config.DRAGON_PVP_DBID]
    local infos   = self:GetAvatarInfo(atkedId)
    if not infos then return end
    local atkInfo = self:GetAvatarInfo(atkDbid)
    if not atkInfo then return end
    local atkName = atkInfo[public_config.DRAGON_PVP_NAME]
    local atklv   = atkInfo[public_config.DRAGON_PVP_LEVEL]
    atkedInfo[public_config.DRAGON_PVP_LEVEL]   = infos[public_config.AVATAR_DRAGON_LEVEL]
    atkedInfo[public_config.DRAGON_PVP_QUALITY] = infos[public_config.AVATAR_DRAGON_DAGQUA]
    atkedInfo[public_config.DRAGON_PVP_CURRNG]  = infos[public_config.AVATAR_DRAGON_CNTRING]
    self:InitPvpBattle(mbStr, atkDbid, atklv, atkName, atkedInfo)
end
---------------------------------------------------------------------------------------
--初始化PVP战斗接口
---------------------------------------------------------------------------------------
function FlyDragonMgr:InitPvpBattle(mbStr, atker, atkerLevel, atkerName, defierInfo)
    local mb = mogo.UnpickleBaseMailbox(mbStr)
    if not mb then
        return
    end
    local pvpInfo  = 
    {
        ['atker']  = atker,
        ['level']  = atkerLevel,
        ['name']   = atkerName,
        ['defier'] = defierInfo,
    }

    mb.InitBasePvpBattle(pvpInfo)

end
---------------------------------------------------------------------------------------
--PVP战斗结束回调接口
---------------------------------------------------------------------------------------
function FlyDragonMgr:DragonBattleCallback(mbStr, atker, defier, isWin, quality, rewds)
    local mb = mogo.UnpickleBaseMailbox(mbStr)
    if not mb then
        return 
    end
    local atkerInfo  = self:GetAvatarInfo(atker)
    local defierInfo = self:GetAvatarInfo(defier)
    local atkType    = EVENT_TYPE_ATK_WIN
    local defType    = EVENT_TYPE_ATKED_LOSE
    local rvgType    = EVENT_REVENGE_NO
    if isWin == public_config.DRAGON_BATTLE_LOSE then
        atkType = EVENT_TYPE_ATK_LOSE
        defType = EVENT_TYPE_ATKED_WIN
        rvgType = EVENT_REVENGE_UNUSE
    else
        local atkTimes = defierInfo[AVATAR_DRAGON_ATKEDSTIMES]
        local cLimit   = g_dragon_mgr:GetConvoyAttackedTimes()
        if atkTimes < cLimit then
            defierInfo[AVATAR_DRAGON_ATKEDSTIMES] = atkTimes + 1
        end
        if quality == public_config.DRAGON_QUALITY_GOLD then
            globalbase_call("UserMgr", "DragonShowText", atker, defier, rewds)
        end
    end
    local etime    = os.time()
    self:CompleteNewEvent(atkerInfo,  defier, atkType, quality, EVENT_REVENGE_UNUSE, etime, rewds)
    self:CompleteNewEvent(defierInfo, atker,  defType, quality, rvgType, etime, rewds)
    if isWin == public_config.DRAGON_BATTLE_WIN then
        if self:RevengeEventDeal(atkerInfo, defier) then
            mb.BaseUpdateRelateTimes(public_config.AVATAR_DRAGON_REVENGE)
        end
    end
    log_game_debug("FlyDragonMgr:DragonBattleCallback", "atker=%q;defier=%q;isWin=%d;quality=%d;rewds=%s",
        atker, defier, isWin, quality, mogo.cPickle(rewds))
    self:SaveAvatar(defier)
    self:SaveAvatar(atker)
end
---------------------------------------------------------------------------------------
--复仇事件处理接口，传入挑战者的信息和防御者的dbid
---------------------------------------------------------------------------------------
function FlyDragonMgr:RevengeEventDeal(info, defier)
    local eList = info[AVATAR_DRAGON_EVENTS]
    for id, eInst in pairs(eList) do
        if eInst[EVENT_DRAGON_DBID]    == defier and
           eInst[EVENT_DRAGON_ETYPE]   == EVENT_TYPE_ATKED_LOSE and
           eInst[EVENT_DRAGON_REVENGE] == EVENT_REVENGE_NO then
           eInst[EVENT_DRAGON_REVENGE] = EVENT_REVENGE_OK
           return true
        end
    end
    return false
end
---------------------------------------------------------------------------------------
--角色首次注册飞龙信息
---------------------------------------------------------------------------------------
function FlyDragonMgr:RegisterDragonContestReq(dbid, level)
    if self:HasConvoyedDragon(dbid) then
        return --已注册
    end
    local infos = self:InitAvatarInfos(dbid, level)
    self:AddAvatarItems(dbid, infos)
    self:SaveAvatar(dbid)
end
---------------------------------------------------------------------------------------
--映射角色的dbid和信息数据
---------------------------------------------------------------------------------------
function FlyDragonMgr:AddAvatarItems(dbid, infos)
    if not infos or not next(infos) then
        return
    end
    self.DbidToPlayers[dbid] = infos
end
---------------------------------------------------------------------------------------
--判断角色是否曾护送过飞龙
---------------------------------------------------------------------------------------
function FlyDragonMgr:HasConvoyedDragon(dbid)
    local info = self:GetAvatarInfo(dbid)
    if not info then
        return false
    end
    return true
end
---------------------------------------------------------------------------------------
--将角色调价到正在护送的队列中
---------------------------------------------------------------------------------------
function FlyDragonMgr:AddToLevelList(level, dbid)
    log_game_debug("FlyDragonMgr:AddToLevelList", "level=%d;dbid=%d", level, dbid)
    local llist = self.LevelList[level]
    if llist then
        llist[dbid] = 1
        return
    end
    if level <= 0 then return end
    local ltbl = {}
    ltbl[dbid] = 1
    self.LevelList[level] = ltbl
end
---------------------------------------------------------------------------------------
--将角色从正在护送的队列中移除
---------------------------------------------------------------------------------------
function FlyDragonMgr:RemoveFromLevelList(level, dbid)
    local llist = self.LevelList[level]
    if llist then
        if llist[dbid] then
            llist[dbid] = nil
        end
    end
end
---------------------------------------------------------------------------------------
--减少飞龙的护送时间接口
---------------------------------------------------------------------------------------
function FlyDragonMgr:ReduceConvoyTimeReq(mbStr, dbid, etime)
    local mb = mogo.UnpickleBaseMailbox(mbStr)
    if not mb then
        return 
    end
    local retCode = error_code.ERR_DRAGON_OK
    local Info    = self:GetAvatarInfo(dbid)
    if not Info then
        retCode = error_code.ERR_DRAGON_INFO_LOSE
        mb.BaseReduceConvoyTimeResp(retCode, etime)
        return
    end
    Info[AVATAR_DRAGON_STARTTIME] = etime
    mb.BaseReduceConvoyTimeResp(retCode, etime)
end
---------------------------------------------------------------------------------------
--管理器构建器
---------------------------------------------------------------------------------------
function FlyDragonMgr:__ctor__()
    log_game_debug("FlyDragonMgr:__ctor__", "")
    local function RegisterGloballyCallback(ret)
        if 1 == ret then --注册成功
             self:OnRegistered()
        else             --注册失败
            log_game_error("FlyDragonMgr:RegisterGlobally error", '')
        end
    end
    self:RegisterGlobally("FlyDragonMgr", RegisterGloballyCallback)
end
---------------------------------------------------------------------------------------
--管理器数据初始化
---------------------------------------------------------------------------------------
function FlyDragonMgr:Init()
    log_game_debug("FlyDragonMgr:Init", "")
    globalbase_call("UserMgr", "FlyDragonMgrGetPlayerCount")
end

function FlyDragonMgr:OnInited(allCount)
    log_game_debug("FlyDragonMgr:OnInited", "UserCount=%d", allCount)
    self.PlayerCount = allCount
    if allCount == 0 then
        globalbase_call('GameMgr', 'OnInited', 'FlyDragonMgr')
    end
    globalbase_call("UserMgr", "AllPlayerDbidReq")
end
---------------------------------------------------------------------------------------
--开服将在部分玩家的dbid回调
---------------------------------------------------------------------------------------
function FlyDragonMgr:PartPlayerDbidResp(dbidInfos)
    self:LoadingAvatarsFromRedis(dbidInfos)
end
---------------------------------------------------------------------------------------
---从数据库装载玩家信息
---------------------------------------------------------------------------------------
function FlyDragonMgr:LoadingAvatarsFromRedis(infoList)
    for dbid, _ in pairs(infoList) do
        local redisKey = string.format("FlyDragonMgr:%d", dbid)
        self.DragonRedis:load(redisKey)
    end
end
----------------------------------------------------------------------------------------
--管理器注册日志接口
----------------------------------------------------------------------------------------
function FlyDragonMgr:OnRegistered()
    log_game_debug("FlyDragonMgr:OnRegistered", "")
    globalbase_call('GameMgr', 'OnMgrLoaded', 'FlyDragonMgr')
end
----------------------------------------------------------------------------------------
--timer 回调接口
----------------------------------------------------------------------------------------
function FlyDragonMgr:onTimer(timer_id, user_data)
    if user_data == TIMER_ID_ZERO then
        
    end
end
-----------------------------------------------------------------------------------------
--实体销毁前处理逻辑
-----------------------------------------------------------------------------------------
function FlyDragonMgr:onDestroy()
    self:SaveAllAvatar()
    log_game_debug("FlyDragonMgr:onDestroy", "ok")

end
------------------------------------------------------------------------------------------
--redis load回调接口
------------------------------------------------------------------------------------------
function FlyDragonMgr:onRedisReply(key, value)

    local tblKey = lua_util.split_str(key, ':')
    local infos  = mogo.cUnpickle(value)
    if tblKey[1] == "FlyDragonMgr" then
        tmpCountLoaded = tmpCountLoaded + 1
        local dbid = tonumber(tblKey[2])
        if next(infos) then
            self:AddAvatarItems(dbid, infos[1])
            self:AvatarInfoDeal(dbid, infos[1])
        end
    end

    --log_game_debug("FlyDragonMgr:onRedisReply", "key=%s;value=%s;tmpCountLoaded=%d;PlayerCount=%d", key, value, tmpCountLoaded, self.PlayerCount)

    if tmpCountLoaded < self.PlayerCount then
        return
    end
    globalbase_call('GameMgr', 'OnInited', 'FlyDragonMgr')
end
--护送队列，若角色护送没有完成
function FlyDragonMgr:AvatarInfoDeal(dbid, infos)
    if not infos or not next(infos) then
      return
    end
    local endTime    = infos[AVATAR_DRAGON_STARTTIME] or 0
    local quality    = infos[AVATAR_DRAGON_DAGQUA]    or 0
    if quality < DRAGON_QUALITY_GREEN then return end
    local level      = infos[AVATAR_DRAGON_LEVEL] or 0
    if endTime > os.time() then
        self:AddToLevelList(level, dbid)
    end
end
--------------------------------------------------------------------------------------------
--保存数据到redis操作
--------------------------------------------------------------------------------------------
function FlyDragonMgr:SaveAvatar(dbid)
    local redisKey = string.format("FlyDragonMgr:%d", dbid)
    local infos    = self:GetAvatarInfo(dbid)
    if not infos then
        return
    end
    local infoStr  = mogo.cPickle(infos)
    --log_game_debug("FlyDragonMgr:SaveAvatar", "infoStr=%s", infoStr)
    self.DragonRedis:set(REDIS_INFO_SEQ, infoStr, redisKey)
end
---------------------------------------------------------------------------------------
--保存所有的觉得信息
---------------------------------------------------------------------------------------
function FlyDragonMgr:SaveAllAvatar()
    for dbid, _ in pairs(self.DbidToPlayers) do
        self:SaveAvatar(dbid)
    end
end

