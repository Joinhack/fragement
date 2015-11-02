---
-- Created by IntelliJ IDEA.
-- User: Administrator
-- Date: 13-3-1
-- Time: 上午11:12
-- 通用的action能否进行的判断类.
--

require "action_config"
require "lua_util"
local error_code = require "error_code"


local _readXml = lua_util._readXml
local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning


local ActionMgr = {}
ActionMgr.__index = ActionMgr
-------------------------------------------------------------------------------------------------

--读取配置数据
function ActionMgr:init_data()
    local tmp = _readXml("/data/xml/action.xml", "aid_i")
    local tmp2 = {}
    local string_byte = string.byte
    local string_sub = string.sub
    local schr = string_byte('s', 1)
    --预处理一下配置数据,期待格式:{1={1=1,2=1,3=1},11={1=1,2=1,3=1},13={1=1,2=2,3=1},12={1=1,2=2}}
    for k,v in pairs(tmp) do
        local tmp3 = {}
        for k2,v2 in pairs(v) do
            if string_byte(k2, 1) == schr then
                tmp3[tonumber(string_sub(k2, 2))] = v2
            elseif k2 ~= "aid" then
                tmp3[k2] = v2
            end
        end
        tmp2[k] = tmp3
    end

    self._action_data = tmp2

--    log_game_debug("ActionMgr:init_data", "_action_data=%s", mogo.cPickle(self._action_data))
end

--根据玩家当前状态判断一个action是否可以进行
function ActionMgr:get_action_err(action_id, avatar)

    local data = self._action_data[action_id]
    if data == nil then
        --未配置该操作,表示无限制
        return 0
    end

    local stest = mogo.stest
    local state = avatar.state

    for state2, ret in pairs(data) do
        if state2 == "vip_level" then
            if avatar.VipLevel < ret then
                return error_code.ERR_STATE_LEVEL
            end
        elseif state2 == "level" then
            if avatar.level < ret then
                return error_code.ERR_STATE_VIP_LEVEL
            end
        else
            if ret == 1 then
                --该状态下不可进行该操作
                if stest(state, state2) > 0 then
                    log_game_warning("ActionMgr:get_action_err 1", "dbid=%q;name=%s;action_id=%d;state2=%d", 
                                                                    avatar.dbid, avatar.name, action_id, state2)
                    return error_code.ERR_STATE_HAS_STATE
                end
            elseif ret == 2 then
                --必须拥有该状态才能进行该操作
                if stest(state, state2) == 0 then
                    log_game_warning("ActionMgr:get_action_err 2", "dbid=%q;name=%s;action_id=%d;state2=%d", 
                                                                    avatar.dbid, avatar.name, action_id, state2)
                    return error_code.ERR_STATE_HASNT_STATE
                end
            end
        end
    end

    return 0
end

---调用Avatar的一个方法,转给一个mgr进行处理,并且返回错误码给客户端
function ActionMgr:generic_avatar_call(avatar, action_id, mgr, func, log_fm, ...)
    --判断玩家状态能否进行这个操作
    local err_id = self:get_action_err(action_id, avatar)

    --调用mgr进行操作
    if err_id == 0 then
        err_id = mgr[func](mgr, avatar, ...)
    end

    --返回错误码给客户端
    if avatar:hasClient() then
        avatar.client.err_resp(action_id, err_id)
    end

    log_game_debug(func, 'dbid=%q;err=%d;'..log_fm, avatar:getDbid(), err_id, ...)
end

---调用Avatar的一个方法,转给一个mgr进行处理,并且返回错误码(如果不为0)给客户端
function ActionMgr:generic_avatar_call_ne0(avatar, action_id, mgr, func, log_fm, ...)
    --判断玩家状态能否进行这个操作
    local err_id = self:get_action_err(action_id, avatar)

    --调用mgr进行操作
    if err_id == 0 then
        err_id = mgr[func](mgr, avatar, ...)
    end

--    lua_util.traceback()

    --返回错误码给客户端
    if err_id ~= 0 and avatar:hasClient() then
        log_game_debug("generic_avatar_call_ne0", "action_id=%d;func=%s;dbid=%q;nam=%s", action_id, func, avatar.dbid, avatar.name)
        avatar.client.err_resp(action_id, err_id)
    end

    log_game_debug(func, 'dbid=%q;err=%d;'..log_fm, avatar:getDbid(), err_id, ...)
end

----------------------------------------------------------------------------------------------------
--道具系统测试用例
----------------------------------------------------------------------------------------------------
function ActionMgr:test_add_items(avatar, typeId, count)
    print(string.format('test_add_items:id=%d', avatar:getDbid()))
    for k = 1, 600 do
        avatar.inventorySystem:AddItems(typeId, count)
    end
    
    for k = 1, 1 do
        avatar.inventorySystem:DelItems(typeId, count)
    end
    avatar.inventorySystem:AddItems(1211600, 10)
    avatar.inventorySystem:DelItems(1211600, 9)
    avatar.inventorySystem:PrintItems()
    
    -- local generals = avatar.generals
    -- log_game_debug("ActionMgr:test_add_items","count=%d;generls=%s", #generals, mogo.cPickle(generals))

    -- local jewels = avatar.jewels
    -- log_game_debug("ActionMgr:test_add_items","count=%d", #jewels)

    -- local materials = avatar.materials
    -- log_game_debug("ActionMgr:test_add_items","count=%d;generls=%s", #materials, mogo.cPickle(materials))
    return 0
end
function ActionMgr:test_del_items(avatar, typeId, count)
    print(string.format('test_del_items:id=%d', avatar:getDbid()))
    avatar.inventorySystem:DelItems(typeId, count)
    local generals = avatar.generals
    log_game_debug("ActionMgr:test_del_items","count=%d;generls=%s", #generals, mogo.cPickle(generals))
    return 0
end
function ActionMgr:test_init_role(avatar, vocation, dbid)
    print(string.format('test_init_role:id=%d', avatar:getDbid()))
    -- local initItems      = {}
    -- initItems[1211600] = 1
    -- initItems[1221600] = 1
    -- initItems[1231600] = 1
    -- initItems[1241600] = 1
    -- initItems[1251600] = 1
    -- initItems[1261600] = 1
    -- initItems[1271600] = 1
    -- initItems[1281600] = 1
    -- initItems[1291600] = 2
    -- initItems[1316000] = 1
    --initItems为临时参数
    --avatar.inventorySystem:CreateRoleInitItems(vocation, dbid, initItems)
    local equipeds = avatar.equipeds
    log_game_debug("ActionMgr:test_del_items","count=%d;equipeds=%s", #equipeds, mogo.cPickle(equipeds))
    return 0
end
function ActionMgr:test_tidy_inventory(avatar, vocation, dbid)
    print(string.format('test_tidy_inventory:id=%d', avatar:getDbid()))
    local initItems    = {}
    --装备(不可堆叠)
    -- initItems[1211600] = 12   
    -- initItems[1221600] = 16   
    -- initItems[1231600] = 15   
    -- initItems[1241600] = 11   
    -- initItems[1251600] = 1   
    -- initItems[1261600] = 19   
    -- initItems[1271600] = 18   
    -- initItems[1281600] = 1   
    -- initItems[1291600] = 6  
    -- initItems[1316000] = 11   
    --普通道具(堆叠和不可堆叠)
     
    initItems[1281600] = 13
    initItems[1291600] = 6
    initItems[1316000] = 11
    initItems[1100011] = 40
    initItems[1100012] = 40
    initItems[1100013] = 40
    initItems[1100036] = 40
    initItems[1100037] = 40
    initItems[1100038] = 40
    initItems[1100039] = 40
    initItems[1100040] = 40
    --宝石(堆叠)
    -- initItems[1411011] = 3000
    -- initItems[1411021] = 3000
    -- initItems[1411031] = 3000
    -- initItems[1411041] = 3000
    -- initItems[1411051] = 3000
    -- initItems[1411061] = 3000
    -- initItems[1411071] = 3000
    -- initItems[1411081] = 1300
    -- initItems[1411091] = 2300
    -- initItems[1412011] = 3000
    -- initItems[1412021] = 100
    -- initItems[1412031] = 500
    --材料(堆叠)
    -- initItems[1910001] = 20000
    -- initItems[1921030] = 20000
    -- initItems[1921040] = 20000
    -- initItems[1921050] = 20000
    -- initItems[1921060] = 20000
    -- initItems[1922030] = 20000
    -- initItems[1922040] = 20000
    -- initItems[1922050] = 20000
    -- initItems[1922060] = 20000

    for k, v in pairs(initItems) do
        avatar.inventorySystem:AddItems(k, v)
    end
    avatar.inventorySystem:PrintItems()
    avatar.inventorySystem:TidyInventory()
    avatar.inventorySystem:PrintItems()

    local equipeds = avatar.equipeds
    log_game_debug("ActionMgr:test_del_items","count=%d", #equipeds)

    -- local jewels = avatar.jewels
    -- log_game_debug("ActionMgr:test_del_items","count=%d", #jewels)

    -- local materials = avatar.materials
    -- log_game_debug("ActionMgr:test_del_items","count=%d", #materials)
    return 0
end
function ActionMgr:test_use_item(avatar, vocation, dbid)
    print(string.format('test_use_item:id=%d', avatar:getDbid()))
    local initItems = {}
    --vip卡
    -- initItems[1100001] = 1
    -- initItems[1100002] = 2
    -- initItems[1100003] = 1
    -- initItems[1100004] = 1
    --宝石袋
    -- initItems[1100038] = 2
    -- initItems[1100039] = 2
    -- initItems[1100040] = 2
    -- initItems[1100041] = 2
    -- initItems[1414021] = 3955
    --装备箱
    -- initItems[1100042] = 1
    -- initItems[1100043] = 1
    -- initItems[1100044] = 1
    --金箱子
    initItems[1100023] = 1
    initItems[1100024] = 1
    initItems[1100027] = 1
    initItems[1100028] = 1

    --add_item
    for k, v in pairs(initItems) do
        avatar.inventorySystem:AddItems(k, v)
    end
    avatar.inventorySystem:PrintItems()
    --use_item
    local BAG_TYPE_EQUIPMENT = 1
    
    local item = avatar.inventorySystem:GetItemByIdx(1, BAG_TYPE_EQUIPMENT)
    avatar.inventorySystem:use_item(item.id, item.gridIndex, 1)
    avatar.inventorySystem:PrintItems()

    -- item = avatar.inventorySystem:GetItemByIdx(1, BAG_TYPE_EQUIPMENT)
    -- avatar.inventorySystem:use_item(item.id, item.gridIndex, 1)
    -- avatar.inventorySystem:PrintItems()

    item = avatar.inventorySystem:GetItemByIdx(2, BAG_TYPE_EQUIPMENT)
    avatar.inventorySystem:use_item(item.id, item.gridIndex, 1)
    avatar.inventorySystem:PrintItems()

    -- item = avatar.inventorySystem:GetItemByIdx(3, BAG_TYPE_EQUIPMENT)
    -- avatar.inventorySystem:use_item(item.id, item.gridIndex, 1)
    -- avatar.inventorySystem:PrintItems()
    --log_game_debug("ActionMgr:test_use_item", "diamond=%d", avatar.diamond)
    return 0
end
function ActionMgr:test_replace_equipment(avatar, vocation, dbid)
    print(string.format('test_replace_equipment:id=%d', avatar:getDbid()))
    -- local initItems    = {}
    -- initItems[1211600] = 1
    -- initItems[1221600] = 1
    -- initItems[1231600] = 1
    -- initItems[1241600] = 1
    -- initItems[1251600] = 1
    -- initItems[1261600] = 1
    -- initItems[1271600] = 1
    -- initItems[1281600] = 1
    -- initItems[1291600] = 2
    -- initItems[1316000] = 1
    local genItems     = {}
    genItems[1313001]  = 1
    genItems[1323001]  = 1
    genItems[1211301]  = 1
    genItems[1221301]  = 1
    genItems[1231301]  = 1
    genItems[1241301]  = 1
    genItems[1251301]  = 1
    genItems[1261301]  = 1
    genItems[1271301]  = 1
    genItems[1281301]  = 1
    genItems[1291301]  = 2
    genItems[1291600]  = 2
    --avatar.inventorySystem:InitBodyItems(initItems, dbid)
    for k, v in pairs(genItems) do
        avatar.inventorySystem:AddItems(k, v)
    end
    avatar.inventorySystem:PrintItems()
    local BAG_TYPE_EQUIPMENT = 1
    for k = 1, 14  do
        log_game_debug("ActionMgr:test_replace_equipment", "idx=%d", k)
        local item = avatar.inventorySystem:GetItemByIdx(k, BAG_TYPE_EQUIPMENT)
        avatar.inventorySystem:ReplaceEquipment(item.id, item.gridIndex)
        avatar.inventorySystem:PrintItems()
    end
    --avatar.inventorySystem:PrintItems()
    return 0
end
function ActionMgr:test_decompose_equipment(avatar, vocation, dbid)
    print(string.format('test_decompose_equipment:id=%d', avatar:getDbid()))
    -- local initItems    = {}
    -- initItems[1211600] = 1
    -- initItems[1221600] = 1
    -- initItems[1231600] = 1
    -- initItems[1241600] = 1
    -- initItems[1251600] = 1
    -- initItems[1261600] = 1
    -- initItems[1271600] = 1
    -- initItems[1281600] = 1
    -- initItems[1291600] = 2
    -- initItems[1316000] = 1
    -- for k, v in pairs(initItems) do
    --     avatar.inventorySystem:AddItems(k, v)
    -- end
    --avatar.inventorySystem:AddItems(1711061, 39560)
    avatar.inventorySystem:PrintItems()
    local BAG_TYPE_EQUIPMENT = 1
    for k = 1, 100 do
        --log_game_debug("ActionMgr:test_decompose_equipment", "idx=%d", k)
        avatar.inventorySystem:AddItems(1291301, 1)
        local item = avatar.inventorySystem:GetItemByIdx(1, BAG_TYPE_EQUIPMENT)
        avatar.inventorySystem:DecomposeEquipment(item.id, item.gridIndex)
        avatar.inventorySystem:PrintItems()
        --log_game_debug("ActionMgr:test_decompose_equipment", "gold=%d", avatar.gold)
    end
    --avatar.inventorySystem:PrintItems()
    return 0
end
function ActionMgr:test_sell_items(avatar, vocation, dbid)
    print(string.format('test_sell_items:id=%d', avatar:getDbid()))
    local BAG_TYPE_EQUIPMENT = 1
    local BAG_TYPE_MATERIALS = 3
    --先分解，在出售
    -- local initItems    = {}
    -- initItems[1211600] = 1
    -- initItems[1221600] = 1
    -- initItems[1231600] = 1
    -- initItems[1241600] = 1
    -- initItems[1251600] = 1
    -- initItems[1261600] = 1
    -- initItems[1271600] = 1
    -- initItems[1281600] = 1
    -- initItems[1291600] = 2
    -- initItems[1316000] = 1
    -- for k, v in pairs(initItems) do
    --     avatar.inventorySystem:AddItems(k, v)
    -- end
   
    -- local item = 1
    -- for k = 1, 11 do
    --     item = avatar.inventorySystem:GetItemByIdx(k, BAG_TYPE_EQUIPMENT)
    --     avatar.inventorySystem:DecomposeEquipment(item.id, item.gridIndex)
    --     --avatar.inventorySystem:PrintItems()
    -- end
    local initItems    = {}
    initItems[1711011] = 1000
    initItems[1711021] = 1000
    initItems[1711031] = 1000
    initItems[1711041] = 1000
    initItems[1711051] = 1000
    initItems[1711061] = 1000
    initItems[1721011] = 1000
    initItems[1721021] = 1000
    initItems[1721031] = 1000
    initItems[1721041] = 1000
    initItems[1721051] = 1000
    initItems[1721061] = 1000
    for k, v in pairs(initItems) do
        avatar.inventorySystem:AddItems(k, v)
    end
    avatar.inventorySystem:PrintItems()
    for k = 1, 0 do
        item = avatar.inventorySystem:GetItemByIdx(k, BAG_TYPE_MATERIALS)
        if item then
            log_game_debug("ActionMgr:test_sell_items", "nil item")
            avatar.inventorySystem:SellItems(item.id, item.gridIndex, item.typeId, item.count)
        end
        log_game_debug("ActionMgr:test_sell_items", "gold=%d", avatar.gold)
        avatar.inventorySystem:PrintItems()
    end
   
    
    return 0
end
function ActionMgr:test_lock_equipemnt(avatar, vocation, dbid)
    print(string.format('test_lock_equipemnt:id=%d', avatar:getDbid()))
    local BAG_TYPE_EQUIPMENT = 1
    local initItems    = {}
    initItems[1211600] = 1
    initItems[1221600] = 1
    for k, v in pairs(initItems) do
        avatar.inventorySystem:AddItems(k, v)
    end
    avatar.inventorySystem:PrintItems()
    --lock
    for k = 1, 2 do
        local item = avatar.inventorySystem:GetItemByIdx(k, BAG_TYPE_EQUIPMENT)
        avatar.inventorySystem:LockEquipment(item.id, item.gridIndex)
        avatar.inventorySystem:PrintItems()
    end
    --unlock
    for k = 1, 2 do
        local item = avatar.inventorySystem:GetItemByIdx(k, BAG_TYPE_EQUIPMENT)
        avatar.inventorySystem:LockEquipment(item.id, item.gridIndex)
        avatar.inventorySystem:PrintItems()
    end
    return 0
end
function ActionMgr:test_charge_diamond(avatar, rmb, diamond)
     print(string.format('test_charge_diamond:id=%d', avatar:getDbid()))
     avatar.inventorySystem:ChargeDiamond(rmb, diamond)
     log_game_debug("ActionMgr:test_charge_diamond", "gold=%d;diamond=%d;VipLevel=%d;chargeSum=%d", 
        avatar.gold, avatar.diamond, avatar.VipLevel, avatar.chargeSum)
     return 0
end
function ActionMgr:test_present_diamond(avatar, diamond)
     print(string.format('test_present_diamond:id=%d', avatar:getDbid()))
     avatar.inventorySystem:PresentDiamond(diamond)
     log_game_debug("ActionMgr:test_present_diamond", "gold=%d;diamond=%d;VipLevel=%d;chargeSum=%d", 
        avatar.gold, avatar.diamond, avatar.VipLevel, avatar.chargeSum)
     return 0
end
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

g_action_mgr = ActionMgr
return g_action_mgr
