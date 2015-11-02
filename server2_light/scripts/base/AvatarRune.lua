--author:Hooke Hu
--date:2013-4-7
--此为Avatar扩展类,只能由Avatar require使用
--避免Avatar.lua文件过长

function Avatar:GetRuneBagReq()
    self.runeSystem:SyncRuneBag()
end

function Avatar:GetBodyRunesReq()
    self.runeSystem:SyncBodyRunes()
end

function Avatar:GameMoneyRefreshReq()
    self.runeSystem:GameMoneyRefresh()
end

function Avatar:FullRefreshReq()
    self.runeSystem:FullRefresh()
end

function Avatar:RMBRefreshReq()
    self.runeSystem:RMBRefresh()
end

function Avatar:AutoCombineReq(isWish)
    self.runeSystem:AutoCombine(isWish)
end

function Avatar:AutoPickUpReq()
    self.runeSystem:AutoPickUp()
end

function Avatar:UseRuneReq(idx)
    self.runeSystem:UseRune(idx)
end

function Avatar:PutOnRuneReq(idx, posi)
    self.runeSystem:PutOn(idx, posi)
end

function Avatar:PutDownRuneReq(idx, posi)
    self.runeSystem:PutDown(idx, posi)
end

function Avatar:ChangeRuneIndexReq(old, new)
    self.runeSystem:ChangeIndex(old, new)
end

function Avatar:ChangeRunePosiReq(old, new)
    self.runeSystem:ChangePosi(old, new)
end

function Avatar:GetRuneEffects()
    self.runeSystem:CellGetRuneEffects()
end
