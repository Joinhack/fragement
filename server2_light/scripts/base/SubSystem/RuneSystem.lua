require "runeData"
require "event_config"
require "public_config"
require "PriceList"
require "reason_def"
require "vip_privilege"
-- 符文系统

local log_game_info = lua_util.log_game_info
local log_game_debug = lua_util.log_game_debug
local _readXml = lua_util._readXml

local runeData = {}

--符文背包中数据类,要记入数据库
Rune = {}
Rune.__index = function (table, key)
    if key == "resData" then
        return g_runeDataMgr:GetRuneById(table[2])
    elseif key == "uuid" then
        return table[1]
    elseif key == "resID" then
        return table[2]
    elseif key == "currExp" then
        return table[3]
    elseif key == "idx" then
        return table[4]
    elseif key == "inBag" then
        return table[5]
    end
end

Rune.__newindex = function (table, key, value)
    if key == "resData" then
        return
    elseif key == "uuid" then
        table[1] = value
    elseif key == "resID" then
        table[2] = value
    elseif key == "currExp" then
        table[3] = value
    elseif key == "idx" then
        table[4] = value
    elseif key == "inBag" then
        table[5] = value
    end
end

function Rune:new(_uuid, _resID, _exp, _idx, _inBag)
    --1:uuid
    --2:resID
    --3:currExp
    --4:idx
    --5:inBag
    local newObj = {[1] = _uuid, [2] = _resID, [3] = _exp, [4] = _idx, [5] = _inBag}
    setmetatable(newObj, Rune)
    --newObj.resData = g_runeDataMgr:GetRuneById(_resID)
    return newObj
end

--角色符文位数据类,要记入数据库
BodyRune = {}
BodyRune.__index = function (table, key)
    if key == "posi" then
        return table[1]
    elseif key == "locked" then
        return table[2]
    elseif key == "rune" then
        if table[3] == 0 then
            return nil
        end
        return table[3]
    end
end

BodyRune.__newindex = function (table, key, value)
    if key == "posi" then
        table[1] = value
    elseif key == "locked" then
        table[2] = value
    elseif key == "rune" then
        if value == nil then
            table[3] = 0
            return
        end
        table[3] = value
    end
end

function BodyRune:new(_posi, _locked, _rune)
    --1:posi
    --2:locked
    --3:rune
    if _rune == nil then
        _rune = 0
    end
    local newObj = {[1] = _posi, [2] = _locked, [3] = _rune}
    setmetatable(newObj, BodyRune)
    return newObj
end

DbRuneBag = {}
DbRuneBag.__index = function (table, key)
    if key == "body" then
        return table[1]
    elseif key == "bag" then
        return table[2]
    end
end

DbRuneBag.__newindex = function (table, key, value)
    if key == "body" then
        table[1] = value
    elseif key == "bag" then
        table[2] = value
    end
end

function DbRuneBag:new(_body, _bag)
    --1:body
    --2:bag
    local newObj = {[1] = _body, [2] = _bag}
    setmetatable(newObj, DbRuneBag)
    return newObj
end

--符文管理类
RuneSystem = {}
RuneSystem.__index = RuneSystem
local BAG_LEN = 16 --符文背包长度
local BAG_WISH_LEN = 16 --许愿符文背包长度
local BODY_POSI_LEN = 11 --身体符文位个数
local RUNE_PROPERTY = 1
local RUNE_MONEY = 2
local RUNE_EXP = 3

function RuneSystem:new( owner )
    local newObj = {}
    newObj.ptr = {}

    setmetatable(newObj, {__index = RuneSystem})
    setmetatable(newObj.ptr, {__mode = "kv"})

    newObj.ptr.theOwner = owner

    newObj.bag = {} --索引从0开始 16-31为符文背包 0-15为许愿背包
    newObj.body = {} --索引从0开始
    newObj.rndmID = 1 --随机ID
    newObj.preCost = false --上次随机用金币还是钻石,false为上次用金币,true为上次用钻石
    for i = 0, BODY_POSI_LEN - 1, 1 do
        newObj.body[i] = BodyRune:new(i, 1, nil)
    end
    return newObj
end

--存储这里要修改下,不存resData
function RuneSystem:SetDbTable(runeBag, lv)
    --log_game_debug("dddd", "%s", mogo.cPickle(runeBag))
    if runeBag[1] == nil and runeBag[2] == nil then
        runeBag[1] = self.body
        runeBag[2] = self.bag
    else
        self.body = runeBag[1]
        self.bag = runeBag[2]
    end
    for k, v in pairs(self.body) do
        setmetatable(v, BodyRune)
        if v.rune then
            setmetatable(v.rune, Rune)
        end
    end
    for k, v in pairs(self.bag) do
        setmetatable(v, Rune)
    end
--    log_game_debug("rune body", "%s", mogo.cPickle(self.body))
--    log_game_debug("rune bag", "%s", mogo.cPickle(self.bag))
    --self.runeBag = runeBag
    --local lv = self.ptr.theOwner.level
    if not lv then
        do return end
    end
    local num = 0
    local cfgs = g_runeDataMgr.runeData.runePosi
    for k, v in pairs(cfgs) do
        if v.level <= lv then
            if v.id > num then
                num = v.id
            end 
        end
    end
    for l = 0, BODY_POSI_LEN - 1, 1 do
        if self.body[l] == nil then
            self.body[l] = BodyRune:new(l, 1, nil)
        end
    end
    for i = 0, num, 1 do
        if i == num then
            break
        end
        self.body[i].locked = 1
    end
end

function RuneSystem:initData()
    runeData = _readXml('/data/xml/runeData.xml', 'id_i')
end

function RuneSystem:SyncRuneBag()
--    log_game_debug("syncRuneBag", "%d", 1)
    self:UpdatePriceToClient()
    for k, v in pairs(self.bag) do
        if v then
            self.ptr.theOwner.client.AddRuneToBagReq(v.uuid, v.idx, v.resID, v.currExp)
        end
    end
end

function RuneSystem:SyncBodyRunes()
    for k, v in pairs(self.body) do
        if v.rune then
            self.ptr.theOwner.client.AddRuneToBodyReq(v.rune.uuid, v.rune.idx, v.rune.resID, v.rune.currExp)
        end
    end
end

--得到空格子索引,只查许愿背包位置
function RuneSystem:GetWishSpaceIdx()
    for i = 0 , BAG_WISH_LEN - 1, 1 do
        if not self.bag[i] then
            do return i end
        end
    end
    return nil
end

--得到符文背包空格子索引
function RuneSystem:GetRuneBagSpaceIdx()
    for i = 16, BAG_WISH_LEN + BAG_LEN - 1, 1 do
        if not self.bag[i] then
            do return i end
        end
    end
    return nil
end

--得到身上空符文位
function RuneSystem:GetSpacePosi()
    for i = 0, BODY_POSI_LEN - 1, 1 do
        if not self.body[i].rune and (self.body[i].locked == 1) then
            do return i end
        end
    end
    return nil
end

function RuneSystem:AddRune(resID, idx)
    local uuid = "uuid"
    local rune = Rune:new(uuid, resID, 0, idx, 1)
    self.bag[idx] = rune
    return rune
end

function RuneSystem:GetNextLvRune(rune)
    local id = g_runeDataMgr:GetRuneID(RUNE_PROPERTY, rune.resData.subtype, rune.resData.quality, rune.resData.level + 1)
    if not id then
        do return nil end
    end
    local uuid = "uuid"
    local r = Rune:new(uuid, id, rune.currExp, rune.idx, rune.inBag)
    if r.currExp >= r.resData.expNeed and
        g_runeDataMgr:GetRuneID(RUNE_PROPERTY, r.resData.subtype, r.resData.quality, r.resData.level + 1) then
        return self:GetNextLvRune(r)
    end
    return r
end

--判断品质随机结果
function RuneSystem:GetQ(rndm, percent)
    local prcnt = percent
    local q = 1 -- 1-7对应金钱,经验,白,绿,蓝,紫,橙
    --按RuneRandom配置判断生成哪个品质
    local m = rndm.money or 0
    local e = rndm.exp or 0
    local w = rndm.white or 0
    local g = rndm.green or 0
    local b = rndm.blue or 0
    local p = rndm.purple or 0
    local o = rndm.orange or 0
    if prcnt <= m then
        q = 1
    elseif prcnt <= m + e then
        q = 2
    elseif prcnt <= m + e + w then
        q = 3
    elseif prcnt <= m + e + w + g then
        q = 4
    elseif prcnt <= m + e + w + g + b then
        q = 5
    elseif prcnt <= m + e + w + g + b + p then
        q = 6
    else
        q = 7
    end
    -----
    return q
end

function RuneSystem:RandomResID(rmd)
    --rmd为true 随机ID为7-12(按RuneRandom表说明)
    local p = math.random(1, 10000)
    if rmd and not self.preCost then
        self.rndmID = 1
    end
    if not rmd and self.preCost then
        self.rndmID = 1
    end
    self.preCost = rmd
    local id = self.rndmID
    local rndm = nil
    if rmd then
        rndm = g_runeDataMgr:GetRandomById(id + 6)
    else
        rndm = g_runeDataMgr:GetRandomById(id)
    end
    if p <= rndm.nextId then
        --随机ID自增1
        self.rndmID = self.rndmID + 1
    else
        --随机ID返回初始值1
        self.rndmID = 1
    end
    local q = self:GetQ(rndm, p)
    if q == 1 then
        return g_runeDataMgr:GetMoneyMinID()
    elseif q == 2 then
        --return g_runeDataMgr:GetExpMinID()
        local vocation = self.ptr.theOwner.vocation
        local lv = self.ptr.theOwner.level
        local rndmVctn = g_runeDataMgr:GetRandomVctn(vocation, lv)
        local stLen = #rndmVctn.expSubtypeRange
        local i = math.random(1, stLen)
        local st = rndmVctn.expSubtypeRange[i] --随机得到子类型
        return g_runeDataMgr:GetExpRandomID(RUNE_EXP, st, 1)
    end
    local vocation = self.ptr.theOwner.vocation
    local lv = self.ptr.theOwner.level
    local rndmVctn = g_runeDataMgr:GetRandomVctn(vocation, lv)
    local stLen = #rndmVctn.subtypeRange
    local i = math.random(1, stLen)
    local st = rndmVctn.subtypeRange[i] --随机得到子类型
    q = q - 2 --向前移2,保持和属性符文的品质相同
    local resID = g_runeDataMgr:GetRuneID(RUNE_PROPERTY, st, q, 1) 
    return resID
end

--游戏币刷新符文
function RuneSystem:GameMoneyRefresh()
    local cfg = g_priceList_mgr:GetPriceData(2)
    --local m = g_runeDataMgr:GetRandomPayById(1)
    local m = cfg.priceList[1]
    --m = m.gameMoney
    if m > self.ptr.theOwner.gold then
        do return end
    end
    local idx = self:GetWishSpaceIdx()
    if not idx then
        --没有空格子 记录日志
        do return end
    end
    --if not self:VipControl() then
    --    log_game_info("vip rune wish limit", "%d", 1)
    --    return
    --end
    local resID = self:RandomResID(false) --从随机规则得到
    if not resID then
        log_game_info("can not random rune resID maybe rune cfg is not right", "%d", 1)
        return
    end
    local r = self:AddRune(resID, idx)
    --self.ptr.theOwner.VipRealState[public_config.DAILY_RUNE_WISH_TIMES] = (self.ptr.theOwner.VipRealState[public_config.DAILY_RUNE_WISH_TIMES] or 0) + 1
    --同步到前端
    self.ptr.theOwner.client.AddRuneToBagReq(r.uuid, r.idx, r.resID, r.currExp)
    --self.ptr.theOwner.gold = self.ptr.theOwner.gold - m
    self.ptr.theOwner:AddGold(-m, reason_def.rune_system)
    self.ptr.theOwner:OnRuneExtract()
    self:RefreshToCell()
end

function RuneSystem:VipControl()
    local VipTbl = g_vip_mgr:GetVipPrivileges(self.ptr.theOwner.VipLevel)
    if not VipTbl then
        return false
    end
    local times = (self.ptr.theOwner.VipRealState[public_config.DAILY_RUNE_WISH_TIMES] or 0)
    if times >= (VipTbl['dailyRuneWishLimit'] or 0) then
        return false
    end
    return true
end

function RuneSystem:UpdatePriceToClient()
    local cfg = g_priceList_mgr:GetPriceData(2)
    local gameMoney = cfg.priceList[1]
    cfg = g_priceList_mgr:GetPriceData(3)
    local rmb = cfg.priceList[1]
    self.ptr.theOwner.client.UpdateRefreshPriceReq(gameMoney, rmb)
end

--一键刷新符文
function RuneSystem:FullRefresh()
    for i = 0, BAG_LEN - 1, 1 do
        if not self.bag[i] then
            self:GameMoneyRefresh()
        end
    end
end

--人民币刷新符文
function RuneSystem:RMBRefresh()
    --local m = g_runeDataMgr:GetRandomPayById(1)
    local cfg = g_priceList_mgr:GetPriceData(3)
    local m = cfg.priceList[1]
    --m = m.RMB
    if m > self.ptr.theOwner.diamond then
        do return end
    end
    local idx = self:GetWishSpaceIdx()
    if not idx then
        do return end
    end
    if not self:VipControl() then
        log_game_info("vip rune wish time limit ", "%d", 1)
        return
    end
    local resID = self:RandomResID(true) --从随机规则得到
    if not resID then
        log_game_info("can not random rune resID maybe rune cfg is not right", "%d", 1)
        return
    end
    local r = self:AddRune(resID, idx)
    self.ptr.theOwner.VipRealState[public_config.DAILY_RUNE_WISH_TIMES] = (self.ptr.theOwner.VipRealState[public_config.DAILY_RUNE_WISH_TIMES] or 0) + 1
    --同步到前端
    self.ptr.theOwner.client.AddRuneToBagReq(r.uuid, r.idx, r.resID, r.currExp)
    --self.ptr.theOwner.diamond = self.ptr.theOwner.diamond - m
    self.ptr.theOwner:AddDiamond(-m, reason_def.rune_system)
    self.ptr.theOwner:OnRuneExtract()
end

local function Cmp(t1, t2)
    if t1.resData.quality ~= t2.resData.quality then
        do return t1.resData.quality > t2.resData.quality end
    end
    if t1.resData.level ~= t2.resData.level then
        do return t1.resData.level > t2.resData.level end
    end
    return t1.currExp > t2.currExp
end

function RuneSystem:GetMaxRune(startIdx, endIdx)
    local props = {}
    for i = startIdx, endIdx, 1 do
        if self.bag[i] and self.bag[i].resData.type == RUNE_PROPERTY then
            table.insert(props, self.bag[i])
        end
    end
    if not props[1] then
        do return nil end
    end
    if not props[2] then
        return props[1]
    end
    table.sort(props, Cmp)
    return props[1]
end

function RuneSystem:Combine(startIdx, endIdx)
    local r = self:GetMaxRune(startIdx, endIdx)
    for i = startIdx, endIdx, 1 do
        if not self.bag[i] then
            goto continue
        end
        if self.bag[i].resData.type == RUNE_MONEY then
            --给角色加游戏币
            self:UseGoldRune(self.bag[i].resData.price)
            self.bag[i] = nil
            self.ptr.theOwner.client.DelRuneFromBagReq(i)
            goto continue
        end
        if r and r ~= self.bag[i] then
            r.currExp = r.currExp + self.bag[i].currExp + self.bag[i].resData.expValue
            if r.currExp >= r.resData.expNeed then
                --升级处理
                local nextRune = self:GetNextLvRune(r)
                if nextRune then
                    r = nextRune
                    self.bag[r.idx] = r
                end
            end
            self.bag[i] = nil
            self.ptr.theOwner.client.DelRuneFromBagReq(i)
        end
        ::continue::
    end
    if r then
        self.ptr.theOwner.client.DelRuneFromBagReq(r.idx)
        self.ptr.theOwner.client.AddRuneToBagReq(r.uuid, r.idx, r.resID, r.currExp)
    end
end

--一键合成符文
function RuneSystem:AutoCombine(isWish)
    if isWish == 1 then
        --合成许愿背包
        self:Combine(0, BAG_WISH_LEN - 1)
    else
        --合成符文背包
        self:Combine(BAG_WISH_LEN, BAG_WISH_LEN + BAG_LEN - 1)
    end
end

--一键拾取,将许愿背包的符文放入符文背包
function RuneSystem:AutoPickUp()
    for i = 0, BAG_LEN - 1, 1 do
        if not self.bag[i] then
            goto continue
        end
        if self.bag[i].resData.type == RUNE_MONEY then
            --金币符文直接使用
            self:UseGoldRune(self.bag[i].resData.price)
            self.bag[i] = nil
            self.ptr.theOwner.client.DelRuneFromBagReq(i)
            goto continue
        end
        local idx = self:GetRuneBagSpaceIdx()
        if not idx then
            log_game_debug("AutoPickUp no space idx", "%d", 1)
            break
        end
        self:ChangeIndex(i, idx)
        ::continue::
    end
end

--使用符文,要区分经验,金钱,属性
function RuneSystem:UseRune(idx)
    if not self.bag[idx] then
        --不存在的符文
        do return end
    end
    if self.bag[idx].resData.type == RUNE_PROPERTY then
        if idx < BAG_WISH_LEN then
            local newIdx = self:GetRuneBagSpaceIdx()
            if newIdx then
                self:ChangeIndex(idx, newIdx)
            end
        else
            --使用属性符文
            local posi = self:GetSpacePosi()
            if not posi then
                --没有空位穿符文
                do return end
            end
            self:PutOn(idx, posi)
        end
    elseif self.bag[idx].resData.type == RUNE_MONEY then
        --使用金钱符文
        self:UseGoldRune(self.bag[idx].resData.price)
        self.ptr.theOwner.client.DelRuneFromBagReq(idx)
        self.bag[idx] = nil
    elseif self.bag[idx].resData.type == RUNE_EXP then
        --使用经验符文
        if idx < BAG_WISH_LEN then
            local newIdx = self:GetRuneBagSpaceIdx()
            if newIdx then
                self:ChangeIndex(idx, newIdx)
            end
        end
    end
end

--吞噬规则统一处理n mean new   o mean old
--品质高的 等级最高的 经验最多的 位置在前的
--n能否吞o   n o最多只能一个是经验符文
function RuneSystem:EatAble(n, o)
    if n.resData.type == RUNE_EXP and o.resData.type ~= RUNE_EXP then
        return false
    end
    if o.resData.type == RUNE_EXP and n.resData.type ~= RUNE_EXP then
        return true
    end
    if n.resData.quality < o.resData.quality then
        return false
    end
    if n.resData.quality > o.resData.quality then
        return true
    end
    if n.currExp >= o.currExp then
        return true
    end
    return false
end

--吞噬r1吞r2
function RuneSystem:Eat(r1, r2)
    r1.currExp = r1.currExp + r2.currExp + r2.resData.expValue
    if r1.currExp >= r1.resData.expNeed then
        local nextRune = self:GetNextLvRune(r1)
        if nextRune then
            r1 = nextRune
        end
    end
    return r1
end

function RuneSystem:HasSubTypeOnBody(subType)
    for k, v in pairs(self.body) do
        if v ~= nil and v.rune ~= nil and v.rune.resData ~= nil and v.rune.resData.subtype == subType then
            return true
        end
    end
    return false
end

--穿上符文,目标位置posi为-1时系统找一个空位
function RuneSystem:PutOn(idx, posi)
    local p = posi
    local r = self.bag[idx]
    if not r then
        --格子是空的
        do return end
    end
    if p == -1 then
        p = self:GetSpacePosi()
        if not p then
            --没有空位
            do return end
        end
    end
    if r.resData.type == RUNE_MONEY then
        --给角色加游戏币
        self:UseRune(idx)
        do return end
    end
    if self:HasSubTypeOnBody(r.resData.subtype) then
        log_game_info("has subtype rune on body ", "%d", r.resData.subtype)
        do return end
    end
    if not self.body[p].rune then
        if r.resData.type == RUNE_EXP then
            do return end
        end
        self.bag[idx] = nil
        r.idx = p
        r.inBag = 0
        self.body[p].rune = r
        log_game_debug("puton ", "%s", mogo.cPickle(self.body))
        self.ptr.theOwner.client.PutOnRuneResp(idx, p)
        self.ptr.theOwner:triggerEvent(event_config.EVENT_AVATAR_PROPERTIES_RECALCULATE)
        do return end
    end
    --吞噬处理
    local pr = self.body[p].rune
    self.bag[idx] = nil
    self.ptr.theOwner.client.DelRuneFromBagReq(idx)
    self.ptr.theOwner.client.DelRuneFromBodyReq(p)
    local a
    if self:EatAble(pr, r) then
        a = self:Eat(pr, r)
    else
        a = self:Eat(r, pr)
    end
    a.idx = p
    a.inBag = 0
    self.body[p].rune = a
    log_game_debug("puton ", "%s", mogo.cPickle(self.body))
    self.ptr.theOwner.client.AddRuneToBodyReq(a.uuid, a.idx, a.resID, a.currExp)
    self.ptr.theOwner:triggerEvent(event_config.EVENT_AVATAR_PROPERTIES_RECALCULATE)
end

--脱下符文,目标位置desIdx为-1时系统找一个空位
function RuneSystem:PutDown(posi, desIdx)
    local i = desIdx
    local r = self.body[posi].rune
    if not r then
        --位置是空的
        do return end
    end
    if i == -1 then
        i = self:GetRuneBagSpaceIdx()
        if not i then
            --没有空格子
            do return end
        end
    end
    if not self.bag[i] then
        self.body[posi].rune = nil
        r.idx = i
        r.inBag = 1
        self.bag[i] = r
        self.ptr.theOwner.client.PutDownRuneResp(posi, i)
        self.ptr.theOwner:triggerEvent(event_config.EVENT_AVATAR_PROPERTIES_RECALCULATE)
        do return end
    end
    local br = self.bag[i]
    local a
    if br.resData.type == RUNE_MONEY then
        --给角色加游戏币
        self:UseGoldRune(br.resData.price)
        a = r
    else
    --吞噬处理
        if self:EatAble(br, r) then
            a = self:Eat(br, r)
        else
            a = self:Eat(r, br)
        end
    end
    self.body[posi].rune = nil
    a.idx = i
    a.inBag = 1
    self.bag[i] = a
    self.ptr.theOwner.client.DelRuneFromBagReq(i)
    self.ptr.theOwner.client.DelRuneFromBodyReq(posi)
    self.ptr.theOwner.client.AddRuneToBagReq(a.uuid, a.idx, a.resID, a.currExp)
    self.ptr.theOwner:triggerEvent(event_config.EVENT_AVATAR_PROPERTIES_RECALCULATE)
end

--更换身上位置,判断是否吞噬
function RuneSystem:ChangePosi(oldPosi, newPosi)
    local r = self.body[oldPosi].rune
    if not r then
        --源位置为空
        do return end
    end
    if oldPosi == newPosi then
        do return end
    end
    if not self.body[newPosi].rune and (self.body[newPosi].locked == 1) then
        self.body[oldPosi].rune = nil
        r.idx = newPosi
        self.body[newPosi].rune = r
        self.ptr.theOwner.client.DelRuneFromBodyReq(oldPosi)
        self.ptr.theOwner.client.AddRuneToBodyReq(r.uuid, r.idx, r.resID, r.currExp)
        do return end
    end
    --吞噬
    local o = self.body[oldPosi].rune
    local n = self.body[newPosi].rune
    local a
    if self:EatAble(n, o) then
        a = self:Eat(n, o)
        a.idx = newPosi
        self.body[newPosi].rune = a
    else
        a = self:Eat(o, n)
        a.idx = newPosi
        self.body[newPosi].rune = a
    end
    self.body[oldPosi].rune = nil
    self.ptr.theOwner.client.DelRuneFromBodyReq(oldPosi)
    self.ptr.theOwner.client.DelRuneFromBodyReq(newPosi)
    self.ptr.theOwner.client.AddRuneToBodyReq(a.uuid, a.idx, a.resID, a.currExp)
    self.ptr.theOwner:triggerEvent(event_config.EVENT_AVATAR_PROPERTIES_RECALCULATE)
end

--更换背包中位置,判断是否吞噬(这方法好长 要想想办法和上面几个整合一下)
function RuneSystem:ChangeIndex(oldIdx, newIdx)
    local r = self.bag[oldIdx]
    if not r then
        --源位置为空
        do return end
    end
    if oldIdx == newIdx then
        do return end
    end
    if not self.bag[newIdx] then
        self.bag[oldIdx] = nil
        self.ptr.theOwner.client.DelRuneFromBagReq(oldIdx)
        if r.resData.type == RUNE_MONEY then
            self:UseGoldRune(r.resData.price)
            do return end 
        end
        r.idx = newIdx
        self.bag[newIdx] = r
        self.ptr.theOwner.client.AddRuneToBagReq(r.uuid, r.idx, r.resID, r.currExp)
        do return end
    end
    local o = self.bag[oldIdx]
    local n = self.bag[newIdx]
    self.ptr.theOwner.client.DelRuneFromBagReq(oldIdx)
    if o.resData.type == RUNE_MONEY then
        --给角色加游戏币
        self:UseGoldRune(o.resData.price)
        self.bag[oldIdx] = nil
        do return end
    end
    self.ptr.theOwner.client.DelRuneFromBagReq(newIdx)
    if n.resData.type == RUNE_MONEY then
        --给角色加游戏币
        self.bag[newIdx] = nil
        self.bag[oldIdx] = nil
        self:UseGoldRune(n.resData.price)
        o.idx = newIdx
        self.bag[newIdx] = o
        self.ptr.theOwner.client.AddRuneToBagReq(o.uuid, o.idx, o.resID, o.currExp)
        do return end
    end
    --吞噬
    local a
    if self:EatAble(n, o) then
        a = self:Eat(n, o)
    else
        a = self:Eat(o, n)
    end
    self.bag[oldIdx] = nil
    a.idx = newIdx
    self.bag[newIdx] = a
    self.ptr.theOwner.client.AddRuneToBagReq(a.uuid, a.idx, a.resID, a.currExp)
end

function RuneSystem:CellGetRuneEffects()
    self:RefreshToCell()
end

function RuneSystem:UseGoldRune(price)
    local _p = price
    if not _p then
        _p = 0
    end
    --self.ptr.theOwner.gold = self.ptr.theOwner.gold + _p
    self.ptr.theOwner:AddGold(_p, reason_def.rune_system)
end

function RuneSystem:BaseGetRuneEffects()
    --取得符文效果ID列表
    local rst = {}
    for k, v in pairs(self.body) do
        if v.rune then
            --log_game_debug("RuneSystem:BaseGetRuneEffects", "effectID = %d", v.rune.resData.effectID)
            table.insert(rst, v.rune.resData.effectID)
        end
    end
    return rst
end

function RuneSystem:RefreshToCell()
--    log_game_debug("refresh to cell " , "%d", 1)
    self.ptr.theOwner.cell.RuneEffects({1, 2})
end

return RuneSystem
