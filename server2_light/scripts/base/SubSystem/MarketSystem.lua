
--商城系统


require "lua_util"
require "lua_map"
require "channel_config"
require "reason_def"
require "public_config"


local log_game_info         = lua_util.log_game_info
local log_game_debug        = lua_util.log_game_debug
local log_game_error        = lua_util.log_game_error
local _readXml 	            = lua_util._readXml
local confirm               = lua_util.confirm
local market_data 		    = {}
local market_version        = 0


local globalbase_call = lua_util.globalbase_call



--限购模式，由MarketData.xml中的mode字段给出定义
local MARKET_NORMAL_MODE		= 0		--普通模式
local MARKET_TIME_MODE		    = 1		--限时模式
local MARKET_TOTAL_QUOTA_MODE	= 2		--总量限购模式
local MARKET_VIP_QUOTA_MODE	    = 3		--VIP用户限购模式

--消息提示，对应ChineseData.xml表定义
local TEXT_NOT_ENOUGH_DIAMOND   = 1000001       --您的钻石不足
local TEXT_NOT_ENOUGH_BAG_GRID  = 1000002       --背包没有足够的空格
local TEXT_BUY_SUCCEED          = 1000003       --购买成功！
local TEXT_VERSION_ERROR        = 1000004       --商城版本已更新，请刷新后再试
local TEXT_DATA_NOT_EXIST       = 1000005       --商城数据已更新，请刷新后再试
local TEXT_DATA_ERROR           = 1000006       --商城数据不正确，请刷新后再试
local TEXT_VIP_LIMIT            = 1000007       --您的VIP等级不足
local TEXT_QUOTA_LIMIT          = 1000008       --该商品的限购次数已达上限！
local TEXT_TIME_LIMIT           = 1000009       --该商品是限时购买，当前时间未开放！
local TEXT_NUMBER_LIMIT         = 1000010       --限购商品每次只允许购买一件！


MarketSystem = {}
MarketSystem.__index = MarketSystem


function MarketSystem:initData()
    market_data     = _readXml('/data/xml/MarketData.xml', 'id_i')
    market_version  = 0
    for k, v in pairs(market_data) do
        if not v.vipLevel then v.vipLevel = 0 end
        if not v.totalCount then v.totalCount = 0 end
        if not v.mode then v.mode = MARKET_NORMAL_MODE end

        --标记商城版本号
        if market_version == 0 and v.marketVersion then
            market_version = v.marketVersion
        end

        --价格容错处理
        if v.priceNow == nil or v.priceNow == 0 then
            v.priceNow = v.priceOrg
        end
        confirm(not v.priceNow or v.priceNow > 0, "商城数据错误：商品价格必须是正整数[商品栏id=%d]", k);
        confirm(not v.itemNumber or v.itemNumber > 0, "商城数据错误：商品数量必须是正整数[商品栏id=%d]", k);

        --检查是否限时模式，并进行数据整理
        if v.mode == MARKET_TIME_MODE then
            if not v.startTime or not v.duration then
                log_game_error("MarketSystem:initData", "No time define! gridId=%d", k)
                v.mode = MARKET_NORMAL_MODE
            elseif not v.startTime[1] or not v.startTime[2] or not v.startTime[3] or
                   not v.startTime[4] or not v.startTime[5] or not v.startTime[6] then
                log_game_error("MarketSystem:initData", "Time define error! gridId=%d", k)
                v.mode = MARKET_NORMAL_MODE
            else
                v.beginTime = os.time{year=v.startTime[1], month=v.startTime[2], day=v.startTime[3], 
                                      hour=v.startTime[4], min=v.startTime[5], sec=v.startTime[6]}
                if not v.beginTime then
                    log_game_error("MarketSystem:initData", "beginTime init failed! gridId=%d", k)
                    v.mode = MARKET_NORMAL_MODE
                end

                v.endTime = v.beginTime + v.duration
                if not v.endTime then
                    log_game_error("MarketSystem:initData", "endTime init failed! gridId=%d", k)
                    v.mode = MARKET_NORMAL_MODE
                end
            end
        end
    end
end

function MarketSystem:new(owner)
    local newObj    = {}
    newObj.ptr      = {}
    setmetatable(newObj,        {__index = MarketSystem})
    setmetatable(newObj.ptr,    {__mode = "v"})

    newObj.ptr.theOwner = owner

    return newObj
end


------------------------------------------------------------------------

function MarketSystem:GetQuotaCount(grid_id)
    local quotaRecord   = self.ptr.theOwner.marketQuotaRecord
    if not quotaRecord then return 0 end
    return quotaRecord[grid_id] or 0
end

function MarketSystem:MarkQuotaCount(grid_id)
    local quotaRecord   = self.ptr.theOwner.marketQuotaRecord
    if not quotaRecord then return end
    if not quotaRecord[grid_id] then
        quotaRecord[grid_id] = 1
    else
        quotaRecord[grid_id] = quotaRecord[grid_id] + 1
    end
end

function MarketSystem:GetVipLevel()
    return self.ptr.theOwner.VipLevel or 0
end


------------------------------------------------------------------------

--购买
function MarketSystem:OnMarketBuy(version, grid_id, item_id, item_number, price_now, buy_count)
    local theOwner = self.ptr.theOwner
    
	--检查版本
	if market_version ~= version then
        theOwner:ShowTextID(CHANNEL.TIPS, TEXT_VERSION_ERROR)
    	self:Send_MarketNeedUpdate()
    	return
	end

	--校验参数
	if not grid_id or not item_id or not item_number or not price_now or not buy_count then return end
    if buy_count <= 0 or buy_count > 255 then return end
	
    --校验栏位
    local marketData = market_data[grid_id]
    if not marketData then
        theOwner:ShowTextID(CHANNEL.TIPS, TEXT_DATA_NOT_EXIST)
    	self:Send_MarketNeedUpdate()
    	return
	elseif marketData.itemId ~= item_id or marketData.itemNumber ~= item_number or marketData.priceNow ~= price_now then
        theOwner:ShowTextID(CHANNEL.TIPS, TEXT_DATA_ERROR)
    	self:Send_MarketNeedUpdate()
		return
	end

    --检查是否限时模式
    if marketData.mode == MARKET_TIME_MODE then
        local nowTime = os.time()
        if nowTime < marketData.beginTime or nowTime > marketData.endTime then
            --限时购买，时间未开放
            theOwner:ShowTextID(CHANNEL.TIPS, TEXT_TIME_LIMIT)
            return
        end
    end

    --判断钻石是否足够
    local totalPrice = price_now * buy_count
    if self:IsDiamondEnough(totalPrice) == false then
        --没有足够的钻石
        theOwner:ShowTextID(CHANNEL.TIPS, TEXT_NOT_ENOUGH_DIAMOND)
        return
    end

    --检查背包是否足够
    local totalNumber = item_number * buy_count
    if self:IsPackageEnough(item_id, totalNumber) == false then
        --背包没有足够的空格
        theOwner:ShowTextID(CHANNEL.TIPS, TEXT_NOT_ENOUGH_BAG_GRID)
        return
    end

	--检查是否限购
    if marketData.mode == MARKET_TOTAL_QUOTA_MODE then
        --总量限购模式
        if buy_count ~=1 then
            theOwner:ShowTextID(CHANNEL.TIPS, TEXT_NUMBER_LIMIT)
            return
        end

        self:MgrCall("EventMarketQuotaBuy", {grid_id, marketData.totalCount}, "EventMarketQuotaBuyComplete", {item_id, totalNumber, totalPrice})
        return

    elseif marketData.mode == MARKET_VIP_QUOTA_MODE then
        --VIP用户限购模式
        if buy_count ~=1 then
            theOwner:ShowTextID(CHANNEL.TIPS, TEXT_NUMBER_LIMIT)
            return
        end
        if self:GetVipLevel() < marketData.vipLevel then
            theOwner:ShowTextID(CHANNEL.TIPS, TEXT_VIP_LIMIT)
            return
        end
        if self:GetQuotaCount(grid_id) >= marketData.totalCount then
            theOwner:ShowTextID(CHANNEL.TIPS, TEXT_QUOTA_LIMIT)
            return
        end
        if self:AddItem(item_id, totalNumber) == false then return end
        self:UseDiamond(totalPrice)
        self:MarkQuotaCount(grid_id)
        self:OnMarketBuySuccess(item_id, totalNumber, totalPrice)
    else
        --不限购模式
        if self:AddItem(item_id, totalNumber) == false then return end
        self:UseDiamond(totalPrice)
        self:OnMarketBuySuccess(item_id, totalNumber, totalPrice)
    end

    --购买成功！
    theOwner:ShowTextID(CHANNEL.TIPS, TEXT_BUY_SUCCEED)
end

--获取商品栏位上的剩余数量
function MarketSystem:OnMarketGridDataReq(version, grid_id)
	--检查版本
	if market_version ~= version then
    	self:Send_MarketNeedUpdate()
    	return
	end

	--校验参数
	if not grid_id then return end

    --校验栏位
    local marketData = market_data[grid_id]
	if not marketData then
    	self:Send_MarketNeedUpdate()
    	return
    elseif (marketData.mode ~= MARKET_TOTAL_QUOTA_MODE and marketData.mode ~= MARKET_VIP_QUOTA_MODE) then
        self:Send_MarketNeedUpdate()
        return
	end

    --检查栏位剩余量
    if marketData.mode == MARKET_TOTAL_QUOTA_MODE then
        --总量限购模式
        self:MgrCallToClient("EventGetMarketQuota", {grid_id, marketData.totalCount}, "MarketGridDataResp", {grid_id})
    else
        --VIP用户限购模式
        local remainCount = marketData.totalCount - self:GetQuotaCount(grid_id)
        if remainCount < 0 then remainCount = 0 end
        self:Send_MarketGridDataResp(grid_id, remainCount)
    end
end

--检查商城版本
function MarketSystem:OnMarketVersionCheck(version)
    --检查版本
    if market_version ~= version then
        self:Send_MarketNeedUpdate()
    end
end

--查询商城数据
function MarketSystem:OnTransferMarketData()
    self:Send_MarketData()
end


------------------------------------------------------------------------

function MarketSystem:EventMarketQuotaBuyComplete(item_id, total_number, total_price, is_ok)
    local theOwner = self.ptr.theOwner
    if is_ok ~= 1 then
        theOwner:ShowTextID(CHANNEL.TIPS, TEXT_QUOTA_LIMIT)
        return
    end

    if self:IsDiamondEnough(total_price) == false then
        --没有足够的钻石
        theOwner:ShowTextID(CHANNEL.TIPS, TEXT_NOT_ENOUGH_DIAMOND)
        return
    end

    if self:AddItem(item_id, total_number) == false then return end
    self:UseDiamond(total_price)
    self:OnMarketBuySuccess(item_id, total_number, total_price)
end


------------------------------------------------------------------------

--通知需要更新版本
function MarketSystem:Send_MarketNeedUpdate()
    self.ptr.theOwner.client.MarketNeedUpdate()
end

--通知栏位更新
function MarketSystem:Send_MarketGridDataResp(grid_id, remain_number)
    self.ptr.theOwner.client.MarketGridDataResp(grid_id, remain_number)
end

--通知栏位更新
function MarketSystem:Send_MarketData()
    local theOwner  = self.ptr.theOwner
    local theData   = {}

    for k, v in pairs(market_data) do
        theData[k] = {}
        table.insert(theData[k], v.hot or 0)
        table.insert(theData[k], v.hotSort or 0)
        table.insert(theData[k], v.jewel or 0)
        table.insert(theData[k], v.jewelSort or 0)
        table.insert(theData[k], v.item or 0)
        table.insert(theData[k], v.itemSort or 0)
        table.insert(theData[k], v.wing or 0)
        table.insert(theData[k], v.wingSort or 0)
        table.insert(theData[k], v.mode or 0)
        table.insert(theData[k], v.label or 0)
        table.insert(theData[k], v.itemId or 0)
        table.insert(theData[k], v.itemNumber or 0)
        table.insert(theData[k], v.priceOrg or 0)
        table.insert(theData[k], v.priceNow or 0)
        table.insert(theData[k], v.vipLevel or 0)
        table.insert(theData[k], v.totalCount or 0)
        table.insert(theData[k], v.startTime or 0)
        table.insert(theData[k], v.duration or 0)
    end

    theOwner.client.TransferMarketDataResp(market_version, theData)
end

--发送消息至Mgr管理器并回调至本子系统
function MarketSystem:MgrCall(mgr_func_name, mgr_func_param_table, callback_func_name, callback_func_param_table)
    local theOwner = self.ptr.theOwner
    if not callback_func_param_table then callback_func_param_table = {} end
    globalbase_call("GlobalDataMgr", "MgrEventDispatch", theOwner.base_mbstr, mgr_func_name, mgr_func_param_table,
                    "marketSystem", callback_func_name, callback_func_param_table)
end

--发送消息至Mgr管理器并回调至Client
function MarketSystem:MgrCallToClient(mgr_func_name, mgr_func_param_table, callback_func_name, callback_func_param_table)
    local theOwner = self.ptr.theOwner
    if not callback_func_param_table then callback_func_param_table = {} end
    globalbase_call("GlobalDataMgr", "MgrEventDispatch", theOwner.base_mbstr, mgr_func_name, mgr_func_param_table,
                    "client", callback_func_name, callback_func_param_table)
end


------------------------------------------------------------------------

--判断背包是否有足够空间
function MarketSystem:IsPackageEnough(item_id, item_number)
    return self.ptr.theOwner.inventorySystem:IsSpaceEnough(item_id, item_number)
end

--添加道具至背包
function MarketSystem:AddItem(item_id, item_number)
    local ret = self.ptr.theOwner:AddItem(item_id, item_number, reason_def.market)
    if ret == 0 then
        self.ptr.theOwner:OnBuyItemFromShop(item_id, item_number)
        return true
    end
    return false
end

--判断钻石是否有足够
function MarketSystem:IsDiamondEnough(price)
    if not price or price < 0 then return false end
    return (self.ptr.theOwner.diamond >= price)
end

--扣除钻石
function MarketSystem:UseDiamond(price)
    self.ptr.theOwner:AddDiamond(-price, reason_def.market)
end

function MarketSystem:OnMarketBuySuccess(item_id, item_number, money)
    local money_type = public_config.DIAMOND_ID --钻石
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


return MarketSystem












