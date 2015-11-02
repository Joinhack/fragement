require "lua_util"

local RuneDataMgr = {}
RuneDataMgr.__index = RuneDataMgr

function RuneDataMgr:initData()
    self.runeData = {}
    local runes = lua_util._readXml("/data/xml/Rune.xml", "id_i")
    local runeVocation = lua_util._readXml("/data/xml/RuneVocation.xml", "id_i")
    local runePosi = lua_util._readXml("/data/xml/RunePosiUnLock.xml", "id_i")
    --local runeRandomPay = lua_util._readXml("/data/xml/RuneRandomPay.xml", "id_i")
    local runeRandom = lua_util._readXml("/data/xml/RuneRandom.xml", "id_i")

    self.runeData.runes = runes
    self.runeData.runePosi = runePosi
    --self.runeData.runeRandomPay = runeRandomPay
    self.runeData.runeRandom = runeRandom
    self.runeData.runeVocation = runeVocation

end

function RuneDataMgr:GetRuneById(id)
    if self.runeData then
        return self.runeData.runes[id]
    end
    return nil
end

function RuneDataMgr:GetLvByPosi(posi)
    if self.runeData then
        return self.runeData.runePosi[posi]
    end
    return nil
end

function RuneDataMgr:GetRandomPayById(id)
    if self.runeData then
        return self.runeData.runeRandomPay[id]
    end
    return nil
end

function RuneDataMgr:GetRandomById(id)
    if self.runeData then
        return self.runeData.runeRandom[id]
    end
    return nil
end

function RuneDataMgr:GetRandomVctn(vocation, lv)
    if not self.runeData then
        do return nil end
    end
    for k,v in pairs(self.runeData.runeVocation) do
        if v.vocation == vocation and lv >= v.levelRange[1] and lv <= v.levelRange[2] then
            do return v end
        end
    end
    return nil
end

--以下三方法要优化
function RuneDataMgr:GetMoneyMinID()
    for k, v in pairs(self.runeData.runes) do
        if v.type == 2 and v.level == 1 then
            do return v.id end
        end
    end
end

function RuneDataMgr:GetExpMinID()
    for k, v in pairs(self.runeData.runes) do
        if v.type == 3 and v.level == 1 then
            do return v.id end
        end
    end
end

function RuneDataMgr:GetExpRandomID(t, st, lv)
    for k, v in pairs(self.runeData.runes) do
        if v.type == t and v.subtype == st and v.level == lv then
            do return v.id end
        end
    end
    return nil
end

function RuneDataMgr:GetRuneID(t, st, q, lv)
    for k, v in pairs(self.runeData.runes) do
        if v.type == t and v.subtype == st and v.quality == q and v.level == lv then
            do return v.id end
        end
    end
    return nil
end

g_runeDataMgr = RuneDataMgr
return g_runeDataMgr
