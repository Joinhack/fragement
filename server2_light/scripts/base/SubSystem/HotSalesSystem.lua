
--促销系统


require "lua_util"
require "lua_map"
require "channel_config"
require "reason_def"
require "public_config"


local globalbase_call   = lua_util.globalbase_call
local log_game_info     = lua_util.log_game_info
local log_game_debug    = lua_util.log_game_debug
local log_game_error    = lua_util.log_game_error
local _readXml          = lua_util._readXml
local hotsales_data     = {}
local hotsales_version  = 0

--消息提示，对应ChineseData.xml表定义
local TEXT_NOT_ENOUGH_DIAMOND   = 1005001       --没有足够的钻石
local TEXT_NOT_ENOUGH_MONEY     = 1005002       --没有足够的金钱
local TEXT_NOT_ENOUGH_BAG_GRID  = 1005003       --背包没有足够的空格
local TEXT_BUY_SUCCEED          = 1005004       --购买成功！
local TEXT_BUY_DATE_LIMIT       = 1005005       --限购期内不能再购买
local TEXT_NO_DATA              = 1005006       --当前时间没有商品可购买

local BUY_RESP_OK                   = 0         --购买成功
local BUY_RESP_VERSION_ERROR        = 1         --版本错误
local BUY_RESP_VERIFY_ERROR         = 2         --数据校验错误
local BUY_RESP_DATE_ERROR           = 3         --不在限购期内
local BUY_RESP_MONEY_NOTENOUGH      = 4         --金钱不足
local BUY_RESP_DIAMOND_NOTENOUGH    = 5         --钻石不足
local BUY_RESP_BAG_NOTENOUGH        = 6         --背包空间不足


HotSalesSystem = {}
HotSalesSystem.__index = HotSalesSystem


function HotSalesSystem:initData()
	hotsales_data		= lua_map:new()
    hotsales_version 	= 0
    local data 			= _readXml('/data/xml/LoginMarketData.xml', 'id_i')
    for k, v in pairs(data) do
        repeat
            --标记商城版本号
            if hotsales_version == 0 and v.version then
                hotsales_version = v.version
            end
            
            if not v.itemId then break end
            if not v.priceType then break end
            if not v.price then break end

            hotsales_data:insert(k, v)
        until true
    end
end

function HotSalesSystem:new(owner)
    local newObj    = {}
    newObj.ptr      = {}
    setmetatable(newObj,        {__index = HotSalesSystem})
    setmetatable(newObj.ptr,    {__mode = "v"})

    newObj.ptr.theOwner = owner

    return newObj
end


------------------------------------------------------------------------

--购买
function HotSalesSystem:OnHotSalesBuy(version, item_id, price_type, price)
    local theOwner = self.ptr.theOwner
    
    --检查版本
    if hotsales_version ~= version then
        self:Send_HotSalesNeedUpdate()
        self:Send_HotSalesBuyResp(BUY_RESP_VERSION_ERROR)
        return
    end

    --校验参数
    if not item_id or not price_type or not price then return end
    local data = hotsales_data:find(tonumber(os.date("%d")))
    if not data then
        theOwner:ShowTextID(CHANNEL.TIPS, TEXT_NO_DATA)
        self:Send_HotSalesBuyResp(BUY_RESP_VERIFY_ERROR)
        return
    elseif data.itemId ~= item_id or data.priceType ~= price_type or data.price ~= price then
        self:Send_HotSalesNeedUpdate()
        self:Send_HotSalesBuyResp(BUY_RESP_VERIFY_ERROR)
        return
    end

    --检查是否在限购期内
    if os.date("%x", theOwner.buyHotSalesLastTime) == os.date("%x") then
        theOwner:ShowTextID(CHANNEL.TIPS, TEXT_BUY_DATE_LIMIT)
        self:Send_HotSalesBuyResp(BUY_RESP_DATE_ERROR)
        return
    end

    --检查钻石/金钱是否足够
    if data.priceType == 1 then
        --判断钻石是否足够
        if self:IsDiamondEnough(price) == false then
            --没有足够的钻石
            theOwner:ShowTextID(CHANNEL.TIPS, TEXT_NOT_ENOUGH_DIAMOND)
            self:Send_HotSalesBuyResp(BUY_RESP_DIAMOND_NOTENOUGH)
            return
        end
    else
        --判断金钱是否足够
        if self:IsMoneyEnough(price) == false then
            --没有足够的金钱
            theOwner:ShowTextID(CHANNEL.TIPS, TEXT_NOT_ENOUGH_MONEY)
            self:Send_HotSalesBuyResp(BUY_RESP_MONEY_NOTENOUGH)
            return
        end
    end

    --检查背包是否足够
    if self:IsPackageEnough(item_id, 1) == false then
        --背包没有足够的空格
        theOwner:ShowTextID(CHANNEL.TIPS, TEXT_NOT_ENOUGH_BAG_GRID)
        self:Send_HotSalesBuyResp(BUY_RESP_BAG_NOTENOUGH)
        return
    end

    if self:AddItem(item_id, 1) == false then return end

    if data.priceType == 1 then
        self:UseDiamond(price)
        self:OnHotSalesBuySuccess(item_id, 1, public_config.DIAMOND_ID, price)   --
    else
        self:UseMoney(price)
         self:OnHotSalesBuySuccess(item_id, 1, public_config.GOLD_ID, price)
    end

    --更新购买日期
    theOwner.buyHotSalesLastTime = os.time()

    --购买成功！
    theOwner:ShowTextID(CHANNEL.TIPS, TEXT_BUY_SUCCEED)
    self:Send_HotSalesBuyResp(BUY_RESP_OK)
end

--检查商城版本
function HotSalesSystem:OnHotSalesVersionCheck(version)
    --检查版本
    if hotsales_version ~= version then
        self:Send_HotSalesNeedUpdate()
    end
end


------------------------------------------------------------------------

--通知需要更新版本
function HotSalesSystem:Send_HotSalesNeedUpdate()
    self.ptr.theOwner.client.HotSalesNeedUpdate()
end

--通知需要更新版本
function HotSalesSystem:Send_HotSalesBuyResp(reason)
    self.ptr.theOwner.client.HotSalesBuyResp(reason)
end



------------------------------------------------------------------------

--判断背包是否有足够空间
function HotSalesSystem:IsPackageEnough(item_id, item_number)
    return self.ptr.theOwner.inventorySystem:IsSpaceEnough(item_id, item_number)
end

--添加道具至背包
function HotSalesSystem:AddItem(item_id, item_number)
    return (self.ptr.theOwner:AddItem(item_id, item_number, reason_def.hot_sales) == 0)
end

--判断钻石是否有足够
function HotSalesSystem:IsDiamondEnough(price)
    if not price or price < 0 then return false end
    return (self.ptr.theOwner.diamond >= price)
end

--扣除钻石
function HotSalesSystem:UseDiamond(price)
    self.ptr.theOwner:AddDiamond(-price, reason_def.hot_sales)
end

--判断金钱是否有足够
function HotSalesSystem:IsMoneyEnough(price)
    if not price or price < 0 then return false end
    return (self.ptr.theOwner.gold >= price)
end

--扣除金钱
function HotSalesSystem:UseMoney(price)
    self.ptr.theOwner:AddGold(-price, reason_def.hot_sales)
end


function HotSalesSystem:OnHotSalesBuySuccess(item_id, item_number, money_type, money)

    local avatar = self.ptr.theOwner

    local accountName, platName = avatar:SplitAccountNameByString(avatar.accountName)

    local insert_table ={
            role_id         =   avatar.dbid ,
            account_name    =   accountName,
            plat_name       =   platName,
            dim_level       =   avatar.level    ,
            dim_prof        =   avatar.vocation ,
            money_type      =   money_type  ,
            amount          =   money   ,
            item_type_1     =   0   ,
            item_type_2     =   0   ,
            item_id         =   item_id ,
            item_number     =   item_number ,
            happend_time    =   os.time()   ,
        }

    globalbase_call("Collector", "table_insert", "tbllog_shop", insert_table)



end


------------------------------------------------------------------------

return HotSalesSystem



























