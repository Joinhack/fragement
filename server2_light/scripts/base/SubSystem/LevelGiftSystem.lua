require "lua_util"
require "reason_def"


local function DebugOutput(head, pattern, ...)
    local log_to_console = false
    if log_to_console == true then
        print(string.format("[%s]%s", head, string.format(pattern, ...)))
    else
        --lua_util.log_game_debug(head, pattern, ...)
    end
end


local log_game_info             = lua_util.log_game_info
local log_game_debug            = DebugOutput
local _readXml                  = lua_util._readXml
local confirm                   = lua_util.confirm
local gift_data 		    	= {}


--消息提示，对应ChineseData.xml表定义
local TEXT_HAS_DRAW    		= 1007001       --此物品已领取过
local TEXT_NO_DATA     		= 1007002       --数据错误：礼品不存在，请更新游戏
local TEXT_LEVEL_LIMIT 		= 1007003		--领取礼包的等级不足
local TEXT_VOCATION_LIMIT	= 1007004		--领取礼包的职业不相符，请更新游戏
local TEXT_ADD_ITEM_FAILED	= 1007005		--领取礼包的失败，无法添加道具
local TEXT_DRAW_SUCCEEDED	= 1007006		--领取礼包成功！
local TEXT_MAIL_TITLE   	= 1007007       --等级礼包
local TEXT_MAIL_TEXT    	= 1007008       --由于领取礼包时背包已满，礼包将以附件形式随本邮件发放，请查收！
local TEXT_MAIL_FROM    	= 1007009       --等级礼包系统


LevelGiftSystem = {}
LevelGiftSystem.__index = LevelGiftSystem


function LevelGiftSystem:initData()
    gift_data = _readXml('/data/xml/LevelGiftData.xml', 'id_i')
    for k, v in pairs(gift_data) do
        if not v.item then v.item = 0 end
        if not v.level then v.level = 0 end
        if not v.vocation then v.vocation = 0 end
    end
end

function LevelGiftSystem:new(owner)
    local newObj    = {}
    newObj.ptr      = {}
    setmetatable(newObj,        {__index = LevelGiftSystem})
    setmetatable(newObj.ptr,    {__mode = "v"})

    newObj.ptr.theOwner = owner

    return newObj
end


------------------------------------------------------------------------

function LevelGiftSystem:HasDraw(grid_id)
    local theOwner = self.ptr.theOwner
	return (theOwner.drawGiftRecord[grid_id] ~= nil)
end

function LevelGiftSystem:MarkDraw(grid_id)
    local theOwner = self.ptr.theOwner
	theOwner.drawGiftRecord[grid_id] = grid_id
end

--添加道具至背包
function LevelGiftSystem:AddItem(item_id)
    if self.ptr.theOwner:AddItem(item_id, 1, reason_def.level_gift) ~= 0 then
        local mailMgr = globalBases["MailMgr"]
        if mailMgr then
            local theOwner = self.ptr.theOwner
            mailMgr.SendIdEx(TEXT_MAIL_TITLE, "", TEXT_MAIL_TEXT, TEXT_MAIL_FROM, os.time(), {[item_id] = 1}, {theOwner.dbid}, {}, reason_def.level_gift)
            return true
        end
    	return false
    end

    return true
end

------------------------------------------------------------------------

--领取物品
function LevelGiftSystem:OnDrawGift(grid_id)
    local theOwner = self.ptr.theOwner
    local theData  = gift_data[grid_id]

    if not theData or theData.item == 0 then
    	theOwner:ShowTextID(CHANNEL.TIPS, TEXT_NO_DATA)
    	return
    end

    if theOwner.level < theData.level then
    	theOwner:ShowTextID(CHANNEL.TIPS, TEXT_LEVEL_LIMIT)
    	return
    end

    if theOwner.vocation ~= theData.vocation and theData.vocation ~= 0 then
    	theOwner:ShowTextID(CHANNEL.TIPS, TEXT_VOCATION_LIMIT)
    	return
    end

	if self:HasDraw(grid_id) then
    	theOwner:ShowTextID(CHANNEL.TIPS, TEXT_HAS_DRAW)
    	return
	end

	if self:AddItem(theData.item) ~= true then
    	theOwner:ShowTextID(CHANNEL.TIPS, TEXT_ADD_ITEM_FAILED)
		return
	end

	self:MarkDraw(grid_id)

    --领取成功！
   	theOwner:ShowTextID(CHANNEL.TIPS, TEXT_DRAW_SUCCEEDED)
end

--查询等级礼包已领取的记录信息
function LevelGiftSystem:OnLevelGiftRecordReq()
	local theRecord = {}
    local theOwner = self.ptr.theOwner
    if theOwner.drawGiftRecord then
	    for grid_id, _ in pairs(theOwner.drawGiftRecord) do
	    	table.insert(theRecord, grid_id)
	    end
    end
    theOwner.client.LevelGiftRecordResp(theRecord)
end

------------------------------------------------------------------------

return LevelGiftSystem










