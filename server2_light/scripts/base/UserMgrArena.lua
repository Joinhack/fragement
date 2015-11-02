--author:hwj
--date:2013-09-03
--此为usermgr扩展竞技场相关接口,只能由UserMgr require使用
--避免UserMgr.lua文件过长
require "public_config"

local log_game_debug = lua_util.log_game_debug
local log_game_warning = lua_util.log_game_warning
local log_game_info = lua_util.log_game_info
local log_game_error = lua_util.log_game_error
local globalbase_call = lua_util.globalbase_call
--[[与usermgr里的前面的local变量一致]]
local PLAYER_BASE_MB_INDEX = public_config.USER_MGR_PLAYER_BASE_MB_INDEX
local PLAYER_CELL_MB_INDEX = public_config.USER_MGR_PLAYER_CELL_MB_INDEX
local PLAYER_DBID_INDEX = public_config.USER_MGR_PLAYER_DBID_INDEX
local PLAYER_NAME_INDEX = public_config.USER_MGR_PLAYER_NAME_INDEX
local PLAYER_LEVEL_INDEX = public_config.USER_MGR_PLAYER_LEVEL_INDEX
local PLAYER_VOCATION_INDEX = public_config.USER_MGR_PLAYER_VOCATION_INDEX
local PLAYER_GENDER_INDEX = public_config.USER_MGR_PLAYER_GENDER_INDEX
local PLAYER_UNION_INDEX = public_config.USER_MGR_PLAYER_UNION_INDEX
local PLAYER_FIGHT_INDEX = public_config.USER_MGR_PLAYER_FIGHT_INDEX --todo:优化
local PLAYER_IS_ONLINE_INDEX = public_config.USER_MGR_PLAYER_IS_ONLINE_INDEX
local PLAYER_FRIEND_NUM_INDEX = public_config.USER_MGR_PLAYER_FRIEND_NUM_INDEX         --好友數量
local PLAYER_OFFLINETIME_INDEX = public_config.USER_MGR_PLAYER_OFFLINETIME_INDEX
-->以下存盘字段begin
local PLAYER_ITEMS_INDEX = public_config.USER_MGR_PLAYER_ITEMS_INDEX            --只缓存身上装备信息，但是会从数据load符文信息来算战斗力，计算完会delete
local PLAYER_BATTLE_PROPS_INDEX = public_config.USER_MGR_PLAYER_BATTLE_PROPS
local PLAYER_SKILL_BAG_INDEX =  public_config.USER_MGR_PLAYER_SKILL_BAG
--<end
local PLAYER_LOADED_ITEMS_INDEX = public_config.USER_MGR_PLAYER_LOADED_ITEMS    --todo:delete

--local PLAYER_BODY_INDEX = public_config.USER_MGR_PLAYER_BODY_INDEX --会从数据load身体信息来算战斗力，计算完会delete
local PLAYER_ARENIC_FIGHT_RANK_INDEX = public_config.USER_MGR_PLAYER_ARENIC_FIGHT_RANK_INDEX
local PLAYER_ARENIC_GRADE_INDEX  = public_config.USER_MGR_PLAYER_ARENIC_GRADE_INDEX
local PLAYER_GM_SETTING              = public_config.USER_MGR_PLAYER_GM_SETTING
--[[UserMgr临时数据]]
local PLAYER_SKILL_BAG_INDEX_TMP = public_config.USER_MGR_PLAYER_SKILL_BAG_TMP
local PLAYER_ITEMS_INDEX_TMP     = public_config.USER_MGR_PLAYER_ITEMS_INDEX_TMP
local PLAYER_BODY_INDEX_TMP      = public_config.USER_MGR_PLAYER_BODY_INDEX_TMP
local PLAYER_RUNE_INDEX_TMP      = public_config.USER_MGR_PLAYER_RUNE_INDEX_TMP
--[[临时数据]]
--self.m_lFights的下标
local FIGHTS_DBID_INDEX = public_config.USER_MGR_FIGHTS_DBID_INDEX
local FIGHTS_FIGHT_INDEX = public_config.USER_MGR_FIGHTS_FIGHT_INDEX --存盘

--[[
function UserMgr:InitArenaMgr()
    local mm = globalBases['ArenaMgr']
    self.InitArenaMgrCount = 0
    if mm then
        local arenicData = {}
        local n = 0
        for dbid, info in pairs(self.DbidToPlayers) do
            if info[PLAYER_LEVEL_INDEX] >= g_arena_config.OPEN_LV then
                n = n + 1
                table.insert(arenicData, {dbid, info[PLAYER_FIGHT_INDEX]})
                if n == g_arena_config.INIT_NUM then
                    mm.InitData(arenicData)
                    n = 0
                    arenicData = {}
                    self.InitArenaMgrCount = self.InitArenaMgrCount + 1
                end
            end
        end
        mm.InitData(arenicData)
        self.InitArenaMgrCount = self.InitArenaMgrCount + 1
    else
        log_game_error("UserMgr:InitArenaMgr", "ArenaMgr is not exist.")
    end
end

function UserMgr:InitedArenaMgr()
    self.InitArenaMgrCount = self.InitArenaMgrCount - 1
    if self.InitArenaMgrCount == 0 then
        local mm = globalBases['ArenaMgr']
        mm.Inited()
    end
end
]]

--离散有序序列m_lFights（降序）中找到fight值小于等于f的最小的pos
function UserMgr:BinaryDownFind(f, bp, ep)
    if bp == ep then
        if self.m_lFights[bp][FIGHTS_FIGHT_INDEX] > f then
            return 0 
        else
            return bp
        end
    end
    local p = math.floor((bp + ep)/2)
    if p < 1 then
        p = 1
    end

    if self.m_lFights[p][FIGHTS_FIGHT_INDEX] > f then
        if p >= ep then
            return 0
        else
            if f >= self.m_lFights[p+1][FIGHTS_FIGHT_INDEX] then
                return p+1
            else
                if p + 2 > ep then
                    return 0
                else
                    if f >= self.m_lFights[p+2][FIGHTS_FIGHT_INDEX] then
                        return p+2
                    else
                        return self:BinaryDownFind(f, p+2, ep)
                    end
                end
            end
        end
    elseif self.m_lFights[p][FIGHTS_FIGHT_INDEX] < f then
        if p <= bp then
            return bp
        else
            if self.m_lFights[p-1][FIGHTS_FIGHT_INDEX] > f then
                return p
            else
                if p - 2 < bp then
                    return p-1
                else
                    if self.m_lFights[p-2][FIGHTS_FIGHT_INDEX] > f then
                        return p-1
                    else
                        return self:BinaryDownFind(f, bp, p-2)
                    end
                end
            end
        end
    else
        while p >= bp do
            if self.m_lFights[p][FIGHTS_FIGHT_INDEX] > f then
                return p + 1
            end
            p = p - 1
        end
        return p - 1
    end
end

function UserMgr:BinaryDownFindEx(f, bp, ep)
    if bp == ep then
        if self.m_lFights[bp][FIGHTS_FIGHT_INDEX] > f then
            return 0 
        else
            return bp
        end
    end
    local p = math.floor((bp + ep)/2)
    if p < 1 then
        p = 1
    end

    if self.m_lFights[p].fight > f then
        if f >= self.m_lFights[p+1][FIGHTS_FIGHT_INDEX] then
            return p+1
        else
            if p + 2 > ep then
                return 0
            else
                if f >= self.m_lFights[p+2][FIGHTS_FIGHT_INDEX] then
                    return p+2
                else
                    return self:BinaryDownFindEx(f, p+2, ep)
                end
            end
        end
    elseif self.m_lFights[p][FIGHTS_FIGHT_INDEX] < f then
        if self.m_lFights[p-1][FIGHTS_FIGHT_INDEX] > f then
            return p
        else
            if p - 2 < bp then
                return p-1
            else
                if self.m_lFights[p-2][FIGHTS_FIGHT_INDEX] > f then
                    return p-1
                else
                    return self:BinaryDownFindEx(f, bp, p-2)
                end
            end
        end
    else
        while p >= bp do
            if self.m_lFights[p][FIGHTS_FIGHT_INDEX] > f then
                return p + 1
            end
            p = p - 1
        end
        return p - 1
    end
end


--离散有序序列m_arenicData（降序）中找到fight值大于等于f的最大的pos
function UserMgr:BinaryUpFind(f, bp, ep)
    if bp == ep then
        if self.m_lFights[bp][FIGHTS_FIGHT_INDEX] < f then
            return 0 
        else
            return bp
        end
    end
    local p = math.floor((bp + ep)/2)
    if p < 1 then
        p = 1
    end

    if self.m_lFights[p][FIGHTS_FIGHT_INDEX] > f then
        if p >= ep then
            return ep
        else
            if self.m_lFights[p+1][FIGHTS_FIGHT_INDEX] < f then
                return p
            else
                if p + 2 > ep then
                    return p + 1
                else
                    if self.m_lFights[p+2][FIGHTS_FIGHT_INDEX] < f then
                        return p + 1
                    else
                        return self:BinaryUpFind(f, p+2, ep)
                    end
                end
            end
        end
    elseif self.m_lFights[p][FIGHTS_FIGHT_INDEX] < f then
        if p <= bp then
            return 0
        else
            if self.m_lFights[p-1][FIGHTS_FIGHT_INDEX] >= f then
                return p - 1
            else
                if p - 2 < bp then
                    return 0
                else
                    if self.m_lFights[p-2][FIGHTS_FIGHT_INDEX] >= f then
                        return p - 2
                    else
                        return self:BinaryUpFind(f, bp, p-2)
                    end
                end
            end
        end
    else
        while p <= ep do
            if self.m_lFights[p][FIGHTS_FIGHT_INDEX] < f then
                return p - 1
            end
            p = p + 1
        end
        return p - 1
    end
end

function UserMgr:BinaryUpFindEx(f, bp, ep)
    if bp == ep then
        if self.m_lFights[bp][FIGHTS_FIGHT_INDEX] < f then
            return 0 
        else
            return bp
        end
    end
    local p = math.floor((bp + ep)/2)
    if p < 1 then
        p = 1
    end

    if self.m_lFights[p][FIGHTS_FIGHT_INDEX] > f then
        if self.m_lFights[p+1][FIGHTS_FIGHT_INDEX] < f then
            return p
        else
            if p + 2 > ep then
                return p + 1
            else
                if self.m_lFights[p+2][FIGHTS_FIGHT_INDEX] < f then
                    return p + 1
                else
                    return self:BinaryUpFindEx(f, p+2, ep)
                end
            end
        end
    elseif self.m_lFights[p][FIGHTS_FIGHT_INDEX] < f then
        if self.m_lFights[p-1][FIGHTS_FIGHT_INDEX] >= f then
            return p - 1
        else
            if p - 2 < bp then
                return 0
            else
                if self.m_lFights[p-2][FIGHTS_FIGHT_INDEX] >= f then
                    return p - 2
                else
                    return self:BinaryUpFindEx(f, bp, p-2)
                end
            end
        end
    else
        while p <= ep do
            if self.m_lFights[p][FIGHTS_FIGHT_INDEX] < f then
                return p - 1
            end
            p = p + 1
        end
        return p - 1
    end
end

local find_up   = UserMgr.BinaryUpFind
local find_down = UserMgr.BinaryDownFind

local m_selfHeal = 0
local function selfHealing()
    if m_selfHeal == 1 then
        log_game_error("UserMgr selfHealing","")
        return
    end
    find_up   = UserMgr.BinaryUpFind
    find_down = UserMgr.BinaryDownFind
    m_selfHeal = 1
end

--获取攻击范围在固定范围内的对手，为了优化跟业务相关,其他系统请用GetPlayerFightBetween接口
function UserMgr:GetFoes(fLow, fUp, foes, myPos, bp, ep, limit)
    local n = lua_util.get_table_real_count(foes)
    --需要获取n个对手
    if n >= limit then
        return true
    else
        n = limit - n
    end
    if ep < bp then
        log_game_error("UserMgr:GetFoes", "1")
        return false
    end
    local up = find_up(self, fLow, bp, ep)
    local low = find_down(self, fUp, bp, ep)
    --local up = self:BinaryUpFind(fLow, bp, ep)
    --local low = self:BinaryDownFind(self, fUp, bp, ep)
    if up == 0 or low == 0 then
        return true
    end

    if not self.m_lFights[up] or not self.m_lFights[low] then
        log_game_error("UserMgr:GetFoes", "2")
        return false
    end

    if up == low then
        if up ~= myPos then
            --only one foes
            table.insert(foes, self.m_lFights[up][FIGHTS_DBID_INDEX])
        end
        return true
    elseif up < low then
        --log_game_error("UserMgr:GetFoes", " find up little than low ")
        --selfHealing()
        return true
    else 
        local tmp = up - low
        if tmp < n then
            if low ~= myPos then
                table.insert(foes, self.m_lFights[low][FIGHTS_DBID_INDEX])
            end
            for i=1,tmp do
                local t = low+i
                if t ~= myPos then
                    table.insert(foes, self.m_lFights[t][FIGHTS_DBID_INDEX])
                end
            end
            return true
        elseif tmp < 2*n then
            local pos = math.random(low, up)
            if pos > up or pos < low then
                log_game_error("UserMgr:GetFoes", "random pos error")
                --selfHealing()
                return false
            end
            local i = 0
            while i < n do
                local t = (pos + i)%tmp + low
                if not self.m_lFights[t] then
                    log_game_error("UserMgr:GetFoes", "pos calc error.")
                    selfHealing()
                    return false
                end
                if t ~= myPos then
                    table.insert(foes, self.m_lFights[t][FIGHTS_DBID_INDEX])
                else
                    n = n + 1
                end
                i = i + 1
            end
            return true
        else
            local pos = math.random(low, up)
            if pos > up or pos < low then
                log_game_error("UserMgr:GetFoes", "random pos error 2")
                --selfHealing()
                return false
            end
            --公平的取值于高中低三档,具有不稳定性
            local ref = math.floor(tmp/3)
            local tt = 0
            local i = 0 
            while i < n do
                if tt > 2 then
                    tt = 0
                end
                local t = (pos + tt*ref + i)%tmp + low
                if not self.m_lFights[t] then
                    log_game_error("UserMgr:GetFoes", "pos calc error 2.")
                    selfHealing()
                    return false
                end
                if t ~= myPos then
                    table.insert(foes, self.m_lFights[t][FIGHTS_DBID_INDEX])
                else
                    n = n + 1
                end
                i = i + 1
            end 
            return true
        end
    end
end

--获取弱对手,为了优化跟业务相关,其他系统请用GetPlayerFightBetween接口
function UserMgr:GetWeakFoes(dbid, myFight)
    --if #self.m_lFights < 2 then return end
    local theInfo = self.DbidToPlayers[dbid]
    if not theInfo then
        log_game_warning("UserMgr:GetWeakFoes", "")
        return
    end

    if not theInfo[PLAYER_BASE_MB_INDEX] then
        log_game_warning("UserMgr:GetWeakFoes", "dbid[%d] no mailboxstring.", dbid)
        return
    end
    local mb = mogo.UnpickleBaseMailbox(theInfo[PLAYER_BASE_MB_INDEX])
    if not mb then
        log_game_warning("UserMgr:GetWeakFoes", "dbid[%d] no mb.", dbid)
        return
    end
    local myPos = theInfo[PLAYER_ARENIC_FIGHT_RANK_INDEX]
    if not myPos or myPos == 0 then
        log_game_warning("UserMgr:GetWeakFoes", "no info")
        if theInfo[PLAYER_LEVEL_INDEX] >= g_arena_config.OPEN_LV then
            if not theInfo[PLAYER_FIGHT_INDEX] then
                log_game_error("UserMgr:GetWeakFoes", "no fight.")
                return
            end
            self:InsertMyFights(theInfo[PLAYER_FIGHT_INDEX], dbid)
            --启动保存
            --log_game_debug("UserMgr:Update", "set save.")
            self.m_save[dbid] = 0
            mb.UpdateUserMgrAboutFight()
            log_game_debug("UserMgr:GetWeakFoes", "InsertMyFights")
        end
        myPos = theInfo[PLAYER_ARENIC_FIGHT_RANK_INDEX]
        if not myPos then
            log_game_error("UserMgr:GetWeakFoes", "no myPos.")
            return
        end
    end
    local m = #self.m_lFights
    if myPos > m then
        log_game_error("UserMgr:GetWeakFoes", "myPos > #self.m_lFights")
        return
    end
    local param = g_arena_config.WEAK_FOE_PICK_PARAM
    local foes = {}
    --local myFight = self.m_lFights[myPos][FIGHTS_FIGHT_INDEX]
    local fUp  = math.floor(myFight * param[1]/100)
    local fLow = math.ceil(myFight* param[2]/100)
    
    --记录选择对手的战斗力范围
    local upRange = fUp
    local downRange = fLow

    local bp = 1
    local ep = m
    --[[取消优化
    if myFight > fUp then
        bp = myPos + 1
        if bp > ep then
            bp = ep
        end
    end
    if myFight < fLow then
        log_game_warning("UserMgr:GetWeakFoes", "1")
        ep = myPos - 1
    end
    ]]
    if not self:GetFoes(fLow, fUp, foes, myPos, bp, ep, g_arena_config.FOES_NUM_FOR_RAND) then
        log_game_error("UserMgr:GetWeakFoes", "2")
        --return
    end

    --剔除gm角色
    local t_foes = {}
    for _,id in ipairs(foes) do
        local thePlayer = self.DbidToPlayers[id]
        --Bit.Test(self.stateFlag, state_config.DEATH_STATE)
        local gm_setting = thePlayer[PLAYER_GM_SETTING] or 0
        if not Bit.Test(gm_setting,gm_setting_state.AREANA_STATE) then
            table.insert(t_foes,id)
        end
    end
    foes = t_foes

    if #foes < 2 then
        local other_info = {
            level = theInfo[PLAYER_LEVEL_INDEX],
            vocation = theInfo[PLAYER_VOCATION_INDEX],
            arenicGrade = theInfo[PLAYER_ARENIC_GRADE_INDEX],
            ref_fight = myFight,
            fight = theInfo[PLAYER_FIGHT_INDEX],
        }
        if not theInfo[PLAYER_ITEMS_INDEX] then
            log_game_error("UserMgr:GetWeakFoes", "theInfo[%s]", mogo.cPickle(theInfo))
        end
        for _, v in pairs(theInfo[PLAYER_ITEMS_INDEX]) do
            if v[public_config.USER_MGR_ITEMS_BODY_INDEX] == public_config.BODY_WEAPON then
                local weaponType = v[public_config.USER_MGR_ITEMS_TYPE_INDEX]
                local itInfo = g_itemdata_mgr:GetItem(public_config.ITEM_TYPE_CFG_TBL, weaponType)
                if itInfo then
                    other_info.weapon_subtype = itInfo.subtype
                end
                break
            end
        end
        local battleProps = theInfo[PLAYER_BATTLE_PROPS_INDEX]
        local modes = theInfo[PLAYER_LOADED_ITEMS_INDEX]
        local skill = theInfo[PLAYER_SKILL_BAG_INDEX]
        local items = theInfo[PLAYER_ITEMS_INDEX]
        local ff = self:CreateRobot(dbid, battleProps, modes, skill, items, other_info, public_config.ARENA_WEAK)
        if not ff then return end
        if ff < downRange then downRange = ff end
        if ff > upRange then upRange = ff end
        table.insert(foes,dbid)
    end
    --[[
    if param[3] and param[4] then
        fUp  = math.floor(myFight * param[3]/100)
        fLow = math.ceil(myFight* param[4]/100)
        if #foes < g_arena_config.FOES_NUM_FOR_RAND then
            if upRange < fUp then
                upRange = fUp
            end
            if downRange > fLow then
                downRange = fLow
            end
        end
        if not self:GetFoes(fLow, fUp, foes, myPos, bp, ep, g_arena_config.FOES_NUM_FOR_RAND) then
            log_game_error("UserMgr:GetWeakFoes", "4")
            --return
        end
    end
    
    
    --只能找范围外的对手
    if not next(foes) then
        --找战斗力范围下限向下最接近的一位
        local tPos = find_down(self, downRange, 1, m)
        if tPos then
            if tPos == myPos then
                tPos = tPos + 1
            end
            local tt = self.m_lFights[tPos]
            if tt then
                table.insert(foes, tt[FIGHTS_DBID_INDEX])
                local ff = tt[FIGHTS_FIGHT_INDEX]
                if downRange > ff then
                    downRange = ff
                end
            end
        end
    end
    if not next(foes) then
        --找战斗力范围上限限向上最接近的一位
        local tPos = find_up(self, upRange, 1, m)
        if tPos then
            if tPos == myPos then
                tPos = tPos - 1
            end
            local tt = self.m_lFights[tPos]
            if tt then
                table.insert(foes, tt[FIGHTS_DBID_INDEX])
                local ff = tt[FIGHTS_FIGHT_INDEX]
                if upRange < ff then
                    upRange = ff
                end
            end
        end
    end
    ]]
    --如果没有随机人直接去比自己低一位的人
    --[[
    if #foes < 1 then
        if self.m_lFights[myPos + 1] then
            table.insert(foes, self.m_lFights[myPos + 1][FIGHTS_DBID_INDEX])
            if downRange > self.m_lFights[myPos + 1][FIGHTS_FIGHT_INDEX] then
                downRange = self.m_lFights[myPos + 1][FIGHTS_FIGHT_INDEX]
            end
        elseif self.m_lFights[myPos - 1] then
            table.insert(foes, self.m_lFights[myPos - 1][FIGHTS_DBID_INDEX])
            if upRange < self.m_lFights[myPos - 1][FIGHTS_FIGHT_INDEX] then
                upRange = self.m_lFights[myPos - 1][FIGHTS_FIGHT_INDEX]
            end
        end
    end]]
    --log_game_debug("UserMgr:GetWeakFoes", "SetWeakFoes dbid[%q], foes[%s]", dbid, mogo.cPickle(foes))
    --批量的获取弱对手
    mb.EventDispatch("arenaSystem","SetWeakFoes", {foes, {upRange, downRange}})
end

--获取强对手
function UserMgr:GetStrongFoes(dbid, myFight)
    --if #self.m_lFights < 2 then return end
    local theInfo = self.DbidToPlayers[dbid]
    if not theInfo then
        log_game_warning("UserMgr:GetStrongFoes", "")
        return
    end

    if not theInfo[PLAYER_BASE_MB_INDEX] then
        log_game_warning("UserMgr:GetStrongFoes", "dbid[%d] no mbstr", dbid)
        return
    end
    local mb = mogo.UnpickleBaseMailbox(theInfo[PLAYER_BASE_MB_INDEX])
    if not mb then
        log_game_warning("UserMgr:GetStrongFoes", "dbid[%d] no mb.", dbid)
        return
    end
    local myPos = theInfo[PLAYER_ARENIC_FIGHT_RANK_INDEX]
    if not myPos or myPos == 0 then
        log_game_warning("UserMgr:GetStrongFoes", "no info")
        if theInfo[PLAYER_LEVEL_INDEX] >= g_arena_config.OPEN_LV then
            if not theInfo[PLAYER_FIGHT_INDEX] then
                log_game_error("UserMgr:GetStrongFoes", "no fight.")
                return
            end
            self:InsertMyFights(theInfo[PLAYER_FIGHT_INDEX], dbid)
            --启动保存
            --log_game_debug("UserMgr:Update", "set save.")
            self.m_save[dbid] = 0
            mb.UpdateUserMgrAboutFight()
            log_game_debug("UserMgr:GetStrongFoes", "InsertMyFights")
        end
        myPos = theInfo[PLAYER_ARENIC_FIGHT_RANK_INDEX]
        if not myPos then
            log_game_error("UserMgr:GetStrongFoes", "no myPos.")
            return
        end
    end
    local m = #self.m_lFights
    if myPos > m then
        log_game_error("UserMgr:GetStrongFoes", "myPos > #self.m_lFights")
        return
    end
    local param = g_arena_config.STRONG_FOE_PICK_PARAM
    local foes = {}
    --local myFight = self.m_lFights[myPos][FIGHTS_FIGHT_INDEX]
    local fUp  = math.floor(myFight * param[1]/100)
    local fLow = math.ceil(myFight* param[2]/100)

    --记录选择对手的战斗力范围
    local upRange = fUp
    local downRange = fLow

    local bp = 1
    local ep = m
    --[[取消优化
    if myFight > fUp then
        bp = myPos
    end
    if myFight < fLow then
        log_game_warning("UserMgr:GetStrongFoes", "1")
        ep = myPos
    end
    ]]
    if not self:GetFoes(fLow, fUp, foes, myPos, bp, ep, g_arena_config.FOES_NUM_FOR_RAND) then
        log_game_error("UserMgr:GetStrongFoes", "1:fLow[%d], fUp[%d], myPos[%d], bp[%d], ep[%d]", fLow, fUp, myPos, bp, ep)
        --return
    end

    --剔除gm角色
    local t_foes = {}
    for _,id in ipairs(foes) do
        local thePlayer = self.DbidToPlayers[id]
        local gm_setting = thePlayer[PLAYER_GM_SETTING] or 0
        if not Bit.Test(gm_setting,gm_setting_state.AREANA_STATE) then
            table.insert(t_foes,id)
        end
    end
    foes = t_foes

    --如果小于两个对手捏造一个假的
    if #foes < 2 then
        local other_info = {
            level = theInfo[PLAYER_LEVEL_INDEX],
            vocation = theInfo[PLAYER_VOCATION_INDEX],
            arenicGrade = theInfo[PLAYER_ARENIC_GRADE_INDEX],
            ref_fight = myFight,
            fight = theInfo[PLAYER_FIGHT_INDEX],
        }
        if not theInfo[PLAYER_ITEMS_INDEX] then
            log_game_error("UserMgr:GetStrongFoes", "theInfo[%s]", mogo.cPickle(theInfo))
        end
        for _, v in pairs(theInfo[PLAYER_ITEMS_INDEX]) do
            if v[public_config.USER_MGR_ITEMS_BODY_INDEX] == public_config.BODY_WEAPON then
                local weaponType = v[public_config.USER_MGR_ITEMS_TYPE_INDEX]
                local itInfo = g_itemdata_mgr:GetItem(public_config.ITEM_TYPE_CFG_TBL, weaponType)
                if itInfo then
                    other_info.weapon_subtype = itInfo.subtype
                end
                break
            end
        end
        local battleProps = theInfo[PLAYER_BATTLE_PROPS_INDEX]
        local modes = theInfo[PLAYER_LOADED_ITEMS_INDEX]
        local skill = theInfo[PLAYER_SKILL_BAG_INDEX]
        local items = theInfo[PLAYER_ITEMS_INDEX]
        local ff = self:CreateRobot(dbid, battleProps, modes, skill, items, other_info, public_config.ARENA_STRONG)
        if not ff then
            log_game_error("UserMgr:GetStrongFoes", "CreateRobot failed.")
            return 
        end
        if ff < downRange then downRange = ff end
        if ff > upRange then upRange = ff end
        table.insert(foes,dbid)
    end
    --[[
    if param[3] and param[4] then
        fUp  = math.floor(myFight * param[3]/100)
        fLow = math.ceil(myFight* param[4]/100)
        
        if #foes < g_arena_config.FOES_NUM_FOR_RAND then
            if upRange < fUp then
                upRange = fUp
            end
            if downRange > fLow then
                downRange = fLow
            end
        end
        if not self:GetFoes(fLow, fUp, foes, myPos, bp, ep, g_arena_config.FOES_NUM_FOR_RAND) then
            log_game_error("UserMgr:GetStrongFoes", "2:fLow[%d], fUp[%d], myPos[%d], bp[%d], ep[%d]", fLow, fUp, myPos, bp, ep)
            --return
        end
    end

    if param[5] and param[6] then
        fUp  = math.floor(myFight * param[5]/100)
        fLow = math.ceil(myFight* param[6]/100)

        if #foes < g_arena_config.FOES_NUM_FOR_RAND then
            if upRange < fUp then
                upRange = fUp
            end
            if downRange > fLow then
                downRange = fLow
            end
        end
        if not self:GetFoes(fLow, fUp, foes, myPos, bp, ep, g_arena_config.FOES_NUM_FOR_RAND) then
            log_game_error("UserMgr:GetStrongFoes", "3:fLow[%d], fUp[%d], myPos[%d], bp[%d], ep[%d]", fLow, fUp, myPos, bp, ep)
            --return
        end
    end

    --只能找范围外的对手
    if not next(foes) then
        --找战斗力范围上限限向上最接近的一位
        local tPos = find_up(self, upRange, 1, m)
        if tPos then
            if tPos == myPos then
                tPos = tPos - 1
            end
            local tt = self.m_lFights[tPos]
            if tt then
                table.insert(foes, tt[FIGHTS_DBID_INDEX])
                local ff = tt[FIGHTS_FIGHT_INDEX]
                if upRange < ff then
                    upRange = ff
                end
            end
        end
    end
    if not next(foes) then
        --找战斗力范围下限向下最接近的一位
        local tPos = find_down(self, downRange, 1, m)
        if tPos then
            if tPos == myPos then
                tPos = tPos + 1
            end
            local tt = self.m_lFights[tPos]
            if tt then
                table.insert(foes, tt[FIGHTS_DBID_INDEX])
                local ff = tt[FIGHTS_FIGHT_INDEX]
                if downRange > ff then
                    downRange = ff
                end
            end
        end
    end
    ]]
    --[[
     --如果没有随机人直接去比自己低一位的人
    if #foes < 1 then
        if self.m_lFights[myPos - 1] then
            table.insert(foes, self.m_lFights[myPos - 1][FIGHTS_DBID_INDEX])
            if upRange < self.m_lFights[myPos - 1][FIGHTS_FIGHT_INDEX] then
                upRange = self.m_lFights[myPos - 1][FIGHTS_FIGHT_INDEX]
            end
        elseif self.m_lFights[myPos + 1] then
            table.insert(foes, self.m_lFights[myPos + 1][FIGHTS_DBID_INDEX])
            if downRange > self.m_lFights[myPos + 1][FIGHTS_FIGHT_INDEX] then
                downRange = self.m_lFights[myPos + 1][FIGHTS_FIGHT_INDEX]
            end
        end
    end]]
    --log_game_debug("UserMgr:GetStrongFoes", "SetStrongFoes dbid[%q], foes[%s]", dbid, mogo.cPickle(foes))
    --批量的获取弱对手
    mb.EventDispatch("arenaSystem","SetStrongFoes", {foes, {upRange, downRange}})
end

--获取战斗力在fLow, fUp之间的玩家的dbid,前不超过n个
--得到的结果不包括自己
function UserMgr:GetPlayerFightMax(fLow, fUp, myDbid, n, mbStr, callback_func)
    --if #self.m_lFights < 2 then return end
    local theInfo = self.DbidToPlayers[myDbid]
    if not theInfo then
        log_game_warning("UserMgr:GetPlayerFightMax", "no player[%q] info.", myDbid)
        return
    end
    local my_mb_str = theInfo[PLAYER_BASE_MB_INDEX]
    --if not my_mb_str then
        --log_game_warning("UserMgr:GetPlayerFightMax", "no player[%q] mb.", myDbid)
        --return
    --end

    local foes = {}
    local myPos = theInfo[PLAYER_ARENIC_FIGHT_RANK_INDEX]
    if not myPos and my_mb_str then
        log_game_error("UserMgr:GetPlayerFightMax", "no myPos.")
        if theInfo[PLAYER_LEVEL_INDEX] >= g_arena_config.OPEN_LV then
            if not theInfo[PLAYER_FIGHT_INDEX] then
                log_game_error("UserMgr:GetPlayerFightMax", "no fight.")
                return
            end
            self:InsertMyFights(theInfo[PLAYER_FIGHT_INDEX], myDbid)
            --启动保存
            --log_game_debug("UserMgr:Update", "set save.")
            self.m_save[myDbid] = 0
            local myMb = mogo.UnpickleBaseMailbox(my_mb_str)
            if myMb then
                myMb.UpdateUserMgrAboutFight()
                log_game_debug("UserMgr:GetPlayerFightMax", "InsertMyFights")
            end
        end
        myPos = theInfo[PLAYER_ARENIC_FIGHT_RANK_INDEX]
        if not myPos then
            log_game_error("UserMgr:GetPlayerFightMax", "no myPos.")
            return
        end
    end
    local m = #self.m_lFights
    --local up = find_up(fLow, 1, #self.m_lFights)
    local low = find_down(self, fUp, 1, m)
    local pp = low
    while n > 0 do
        if self.m_lFights[low] and low ~= myPos and self.m_lFights[low][FIGHTS_FIGHT_INDEX] > fLow then
            local the_id = self.m_lFights[low][FIGHTS_DBID_INDEX]
            local thePlayer = self.DbidToPlayers[the_id]
            --剔除gm
            if thePlayer then
                local gm_setting = thePlayer[PLAYER_GM_SETTING] or 0
                if not Bit.Test(gm_setting,gm_setting_state.AREANA_STATE) then
                    n = n - 1
                    table.insert(foes, the_id)
                end
            end
        else
            break
        end
        low = low + 1
    end

    if not next(foes) then
        local other_info = {
            level = theInfo[PLAYER_LEVEL_INDEX],
            vocation = theInfo[PLAYER_VOCATION_INDEX],
            arenicGrade = theInfo[PLAYER_ARENIC_GRADE_INDEX],
            ref_fight = 0,
            fight = theInfo[PLAYER_FIGHT_INDEX],
        }
        if not theInfo[PLAYER_ITEMS_INDEX] then
            log_game_error("UserMgr:GetPlayerFightMax", "theInfo[%s]", mogo.cPickle(theInfo))
        end
        for _, v in pairs(theInfo[PLAYER_ITEMS_INDEX]) do
            if v[public_config.USER_MGR_ITEMS_BODY_INDEX] == public_config.BODY_WEAPON then
                local weaponType = v[public_config.USER_MGR_ITEMS_TYPE_INDEX]
                local itInfo = g_itemdata_mgr:GetItem(public_config.ITEM_TYPE_CFG_TBL, weaponType)
                if itInfo then
                    other_info.weapon_subtype = itInfo.subtype
                end
                break
            end
        end
        local battleProps = theInfo[PLAYER_BATTLE_PROPS_INDEX]
        local modes = theInfo[PLAYER_LOADED_ITEMS_INDEX]
        local skill = theInfo[PLAYER_SKILL_BAG_INDEX]
        local items = theInfo[PLAYER_ITEMS_INDEX]
        local ff = self:CreateRobot(myDbid, battleProps, modes, skill, items, other_info, public_config.ARENA_ENEMY)
        if not ff then
            log_game_error("UserMgr:GetStrongFoes", "CreateRobot failed.")
            return 
        end
        foes[1] = myDbid
    end
    --[[
    --只能找范围外的对手
    if not next(foes) then
        --找战斗力范围上限限向上最接近的一位
        local tPos = pp
        if tPos == myPos then
            tPos = pp - 1
            if tPos > 0 then
                table.insert(foes, self.m_lFights[tPos][FIGHTS_DBID_INDEX])
            else
                tPos = pp + 1
                table.insert(foes, self.m_lFights[tPos][FIGHTS_DBID_INDEX])
            end
        elseif tPos == 0 then
            if myPos == 1 then
                tPos = 2
            else
                tPos = 1
            end
            table.insert(foes, self.m_lFights[tPos][FIGHTS_DBID_INDEX])
        else
            table.insert(foes, self.m_lFights[tPos][FIGHTS_DBID_INDEX])
        end
    end
    ]]
    --[[
    --如果没有随机人直接去比自己低一位的人
    if #foes < 1 then
        if self.m_lFights[myPos - 1] then
            table.insert(foes, self.m_lFights[myPos - 1][FIGHTS_DBID_INDEX])
        elseif self.m_lFights[myPos + 1] then
            table.insert(foes, self.m_lFights[myPos + 1][FIGHTS_DBID_INDEX])
        end
    end
    ]]
    local mb = mogo.UnpickleBaseMailbox(mbStr)
    if mb then
        mb[callback_func](myDbid, foes)
    end
    
    --log_game_debug("UserMgr:GetPlayerFightMax", "SetEnemy myDbid[%q], foes[%s]", myDbid, mogo.cPickle(foes))
    if my_mb_str then
        local myMb = mogo.UnpickleBaseMailbox(my_mb_str)
        if myMb then
            myMb.EventDispatch("arenaSystem", "SetEnemy", {foes})
        end
    end
end

--获取战斗力在fLow, fUp之间的玩家的dbid,随机不超过n个
--得到的结果不包括自己 no use
function UserMgr:GetPlayerFightBetween(fLow, fUp, myDbid, n, subSystem, callback_func)
    local theInfo = self.DbidToPlayers[myDbid]
    if not theInfo then
        log_game_warning("UserMgr:GetWeakFoes", "")
        return
    end
    local foes = {}
    local myPos = theInfo[PLAYER_ARENIC_FIGHT_RANK_INDEX]
    if not myPos then
        log_game_error("UserMgr:GetPlayerFightBetween", "no myPos.")
        return
    end
    if not self:GetFoes(fLow, fUp, foes, myPos, 1, #self.m_lFights, n) then
        log_game_error("UserMgr:GetPlayerFightBetween", "")
        return
    end
    local mb = mogo.UnpickleBaseMailbox(theInfo[PLAYER_BASE_MB_INDEX])
    if mb then
        mb.EventDispatch(subSystem, callback_func, {foes})
    end
end

--
function UserMgr:SendArenicDetailToClient(myDbid, theDbid, callback_func, _format)
    local myInfo = self.DbidToPlayers[myDbid]
    if not myInfo[PLAYER_BASE_MB_INDEX] then
        return
    end
    local mb = mogo.UnpickleBaseMailbox(myInfo[PLAYER_BASE_MB_INDEX])
    if not mb then return end
    local tmp = {}
    if myDbid == theDbid then
        tmp = self:_GetRobotData(theDbid, _format)
        mb.EventDispatch("arenaSystem", callback_func, {tmp})
        return
    end

    local theInfo = self.DbidToPlayers[theDbid]
    if not theInfo then
        log_game_error("UserMgr:SendArenicDetailToClient", "")
        return
    end
    
    local m = #_format
    for i, k in ipairs(_format) do
        if i == m then
            --自带信息返回，最后一位
            tmp[i] = k
        elseif k == PLAYER_ARENIC_FIGHT_RANK_INDEX then
            local t = self.m_lFights[theInfo[k]]
            if t then
                table.insert(tmp, t[FIGHTS_FIGHT_INDEX])
            end
        elseif k == PLAYER_ITEMS_INDEX then
            local tt = {}
            if not theInfo[k] then
                log_game_error("UserMgr:SendArenicDetailToClient", "myDbid[%q], theDbid[%q], callback_func[%s], myInfo[%s], theInfo[%s]", myDbid, theDbid, callback_func, mogo.cPickle(myInfo),mogo.cPickle(theInfo))
            else
                for _, item in pairs(theInfo[k]) do
                    table.insert(tt, item[public_config.USER_MGR_ITEMS_TYPE_INDEX])
                end
            end
            table.insert(tmp, tt)
        elseif theInfo[k] then
            table.insert(tmp, theInfo[k])
        else
            log_game_error("UserMgr:SendArenicDetailToClient", "theDbid[%d], key[%d]", theDbid, k)
        end
    end
    --mb.client[callback_func](tmp)
    mb.EventDispatch("arenaSystem", callback_func, {tmp})
    --log_game_debug("UserMgr:SendArenicDetailToClient", "%s", os.time())
end
--[[
--前端展示的数据格式
        local lFormat = 
        {
            public_config.USER_MGR_PLAYER_NAME_INDEX,
            public_config.USER_MGR_PLAYER_LEVEL_INDEX,
            public_config.USER_MGR_PLAYER_VOCATION_INDEX,
            public_config.USER_MGR_PLAYER_ARENIC_FIGHT_RANK_INDEX,
            public_config.USER_MGR_PLAYER_ITEMS_INDEX,
            1, --该值不下发:1代表弱敌，2代表强敌，3代表仇敌
        }
]]
function UserMgr:_GetRobotData(theDbid, _format)
    local m = #_format
    local flag = _format[m]
    if not self.m_robots[theDbid] then self.m_robots[theDbid] = {} end
    local robot = self.m_robots[theDbid][flag]
    if not robot then 
        --由于机器人不存库，所以在下次启服后有可能找不到自己的机器人
        local theInfo = self.DbidToPlayers[theDbid]
        if not theInfo then return end
        local other_info = {
            level = theInfo[PLAYER_LEVEL_INDEX],
            vocation = theInfo[PLAYER_VOCATION_INDEX],
            arenicGrade = theInfo[PLAYER_ARENIC_GRADE_INDEX],
            ref_fight = theInfo[PLAYER_FIGHT_INDEX],
            fight = theInfo[PLAYER_FIGHT_INDEX],
        }
        for _, v in pairs(theInfo[PLAYER_ITEMS_INDEX]) do
            if v[public_config.USER_MGR_ITEMS_BODY_INDEX] == public_config.BODY_WEAPON then
                local weaponType = v[public_config.USER_MGR_ITEMS_TYPE_INDEX]
                local itInfo = g_itemdata_mgr:GetItem(public_config.ITEM_TYPE_CFG_TBL, weaponType)
                if itInfo then
                    other_info.weapon_subtype = itInfo.subtype
                end
                break
            end
        end
        local battleProps = theInfo[PLAYER_BATTLE_PROPS_INDEX]
        local modes = theInfo[PLAYER_LOADED_ITEMS_INDEX]
        local skill = theInfo[PLAYER_SKILL_BAG_INDEX]
        local items = theInfo[PLAYER_ITEMS_INDEX]
        local ff = self:CreateRobot(theDbid, battleProps, modes, skill, items, other_info, flag)
        if not ff then
            log_game_error("UserMgr:_GetRobotData", "CreateRobot failed.")
            return 
        end
        robot = self.m_robots[theDbid][flag]
    end

    local tmp = {}
    for i, k in ipairs(_format) do
        if i == m then
            --自带信息返回，最后一位
            tmp[i] = k
        elseif k == PLAYER_ARENIC_FIGHT_RANK_INDEX then
            local t = robot.fightForce
            if t then
                table.insert(tmp, t)
            end
        elseif k == PLAYER_ITEMS_INDEX then
            local tt = {}
            for _, item in pairs(robot.items) do
                table.insert(tt, item[public_config.USER_MGR_ITEMS_TYPE_INDEX])
            end
            table.insert(tmp, tt)
        elseif k == PLAYER_NAME_INDEX then
            table.insert(tmp, robot.name)
        elseif k == PLAYER_LEVEL_INDEX then
            table.insert(tmp, robot.level)
        elseif k == PLAYER_VOCATION_INDEX then
            table.insert(tmp, robot.vocation)
        elseif k == PLAYER_ARENIC_GRADE_INDEX then
            table.insert(tmp, robot.arenicGrade)
        else
            log_game_error("UserMgr:_GetRobotData", "theDbid[%d], key[%d]", theDbid, k)
        end
    end
    return tmp
end

function UserMgr:UpdateDefierInfo(challenger_dbid, defier_dbid)
    local challenger_info = self.DbidToPlayers[challenger_dbid]
    local defier_info = self.DbidToPlayers[defier_dbid]
    if not challenger_info or not defier_info then
        log_game_warning("UserMgr:UpdateDefierInfo", "")
        return
    end

    local rr = challenger_info[PLAYER_ARENIC_FIGHT_RANK_INDEX]
    local ff = 0
    if rr > 0 then
        ff = self.m_lFights[rr][FIGHTS_FIGHT_INDEX]
    else
        log_game_error("UserMgr:UpdateDefierInfo", "")
        return
    end
    --gm不被作为别人的仇敌
    local gm_setting = challenger_info[PLAYER_GM_SETTING] or 0
    if Bit.Test(gm_setting,gm_setting_state.AREANA_STATE) then
        return
    end
    local mm = globalBases['ArenaMgr']
    if mm then
        mm.UpdateCandidateEnemy(challenger_dbid, defier_dbid, ff)
    end
end

function UserMgr:RefreshRefFightReq()
    log_game_debug("UserMgr:RefreshRefFightReq", "time = %d", os.time())
    local mm = globalBases['ArenaMgr']
    if not mm then
        log_game_error("UserMgr:RefreshRefFightReq", "")
        return
    end
    local n = 0
    local tt = {}
    for _, v in pairs(self.m_lFights) do
        n = n +1
        tt[v[FIGHTS_DBID_INDEX]] = v[FIGHTS_FIGHT_INDEX]
        if n >= 300 then
            n = 0
            mm.RefreshRefFightResp(tt)
            --
            tt = {}
        end
    end
    mm.RefreshRefFightResp(tt)
    self:addLocalTimer("NotifyDataDated", 5000, 1)
end

function UserMgr:NotifyDataDated(timer_id, count, arg1, arg2)
    --通知在线玩家
    self:DataDated('arenaSystem', 'DataDated', {})
end

--gm
function UserMgr:foe(dbid, theFoe, flag)
    local myInfo = self.DbidToPlayers[dbid]
    if not myInfo then return end
    local theInfo = self.DbidToPlayers[theFoe]
    if not theInfo then return end

    local mb = mogo.UnpickleBaseMailbox(myInfo[PLAYER_BASE_MB_INDEX])
    if dbid == theFoe then
        return self:robot(mb, dbid, flag)
    end
    local battle_info = theInfo[PLAYER_BATTLE_PROPS_INDEX]
    if not battle_info then return end
    local msg = theInfo[PLAYER_NAME_INDEX] .. "begin====:"
    for k,v in pairs(battle_info) do
        if k ~= 'vt' then
            msg = "<<" .. msg .. tostring(k) .. ':' .. tostring(v) .. ">> | "
        end
    end
    msg = msg .. '====end'
    mb.client.ChatResp(public_config.CHANNEL_ID_PERSONAL, dbid, "GM", msg)
end

function UserMgr:robot(mb, dbid, flag)
    local theRobot = self.m_robots[dbid]
    if not theRobot then return end
    local theInfo = theRobot[flag]
    if not theInfo then return end
    local battle_info = theInfo.battleProps
    if not battle_info then return end
    local msg = theInfo.name .. "begin====:"
    for k,v in pairs(battle_info) do
        if k ~= 'vt' then
            msg = "<<" .. msg .. tostring(k) .. ':' .. tostring(v) .. ">>    "
        end
    end
    msg = msg .. '====end'
    mb.client.ChatResp(public_config.CHANNEL_ID_PERSONAL, dbid, "GM", msg)
end

function UserMgr:CreateRobot(dbid, battleProps, modes, skill, items, other_info, flag)
    if not self.m_robots[dbid] then self.m_robots[dbid] = {} end
    if self.m_robots[dbid][flag] then
        self:DestroyRobot(dbid, flag)
    end
    local m = #self.m_robotsName
    if m < 1 then
        log_game_warning("UserMgr:CreateRobot", "no names can use.")
        return
    end
    local name = self.m_robotsName[m]
    self.m_robotsName[m] = nil
    m = #self.m_robotsName
    if m < 5 then
        --todo:获取随机名称
        globalbase_call('NameMgr', 'random_n_names', 5)
    end
    local robot = {
        battleProps = {},
        modes = {},
        skill = {},
        name = name,
        level = other_info.level,
        vocation = other_info.vocation,
        dbid = 0, --机器人的dbid为0
        fightForce = 0,
        arenicGrade = other_info.arenicGrade,
        weapon_subtype = other_info.weapon_subtype,
        items = {},
    }
    lua_util.deep_copy(5, battleProps, robot.battleProps)
    lua_util.deep_copy(5, modes, robot.modes)
    lua_util.deep_copy(5, skill, robot.skill)
    lua_util.deep_copy(5, items, robot.items)

    local ref_fight = other_info.ref_fight
    local fight = other_info.fight
    local factor = 1
    local attri = robot.battleProps
    --不加战斗力计算会出错
    setmetatable(attri,      
        {__index =               
            function (table, key)
                --log_game_error("battleProps ASK", "%s", key)
                return 0         
            end                  
        }                        
    )
    if flag == public_config.ARENA_WEAK then
        if fight > 0 then
            factor = ref_fight / fight
        end
        attri.hp = math.ceil(attri.hp * self.weak_factor * factor/ 100)
        attri.atk = math.ceil(attri.atk * self.weak_factor * factor / 100)
    elseif flag == public_config.ARENA_STRONG then
        if fight > 0 then
            factor = ref_fight / fight
        end
        attri.hp = math.ceil(attri.hp * self.strong_factor * factor / 100)
        attri.atk = math.ceil(attri.atk * self.strong_factor * factor / 100)
    elseif flag == public_config.ARENA_ENEMY then
        attri.hp = math.ceil(attri.hp * self.enemy_factor * factor / 100)
        attri.atk = math.ceil(attri.atk * self.enemy_factor * factor / 100)
    else
        log_game_error("UserMgr:CreateRobot", "flag[%d]", flag)
    end
    --计算战斗力
    local fightForce = battleAttri:GetFightForce(robot.battleProps)
    robot.fightForce = fightForce
    self.m_robots[dbid][flag] = robot
    return fightForce
end

--销毁机器人,主要是归还name
function UserMgr:DestroyRobot(dbid, flag)
    if not self.m_robots[dbid][flag] then return end
    local mm = globalBases['NameMgr']
    if mm then
        local nn = self.m_robots[dbid][flag].name
        mm.RecoverName(nn)
    end
    self.m_robots[dbid][flag] = nil
end

function UserMgr:SetRobotNames(names)
    for _,v in pairs(names) do
        table.insert(self.m_robotsName, v)
    end
end