--湮灭之门子系统


require "lua_util"
require "lua_map"
require "oblivion_config"
require "channel_config"
require "public_config"
require "GlobalParams"


local log_game_debug 	= lua_util.log_game_debug
local log_game_warning 	= lua_util.log_game_warning
local log_game_info 	= lua_util.log_game_info
local log_game_error 	= lua_util.log_game_error
local _readXml          = lua_util._readXml
local globalbase_call   = lua_util.globalbase_call


local SPREAD_LEVEL_LIMIT    = 25                                          --传播等级限制
local ENTER_CD_TICK         = public_config.OBLIVION_ENTER_TIME           --进入副本的CD时间，单位：秒
local MAP_ID_A              = public_config.OBLIVION_GATE_TO_MAP[1]       --A副本(恶魔)的地图ID
local MAP_ID_B              = public_config.OBLIVION_GATE_TO_MAP[2]       --B副本(邪神)的地图ID


--消息提示，对应ChineseData.xml表定义
local TEXT_NOT_EXIST    = 1001001           --湮灭之门副本不存在！
local TEXT_LOCKED       = 1001002           --湮灭之门正在封印中！

--触发表数据
local trigger_data      = {}


OblivionGateSystem = {}
OblivionGateSystem.__index = OblivionGateSystem


function OblivionGateSystem:InitData()
    SPREAD_LEVEL_LIMIT    = g_GlobalParamsMgr:GetParams('oblivion_gate_level_limit', 25)   --传播等级限制
    ENTER_CD_TICK         = g_GlobalParamsMgr:GetParams('oblivion_gate_enter_cd', public_config.OBLIVION_ENTER_TIME) --进入副本的CD时间，单位：秒
    trigger_data          = _readXml('/data/xml/OblivionTrigger.xml', 'id_i')
    if trigger_data then
        for _, data in pairs(trigger_data) do
            if not data.triggerBoss then data.triggerBoss = 0 end
            if not data.trigger1 then data.trigger1 = {} end
            if not data.trigger2 then data.trigger2 = {} end

            data.trigger = {[1] = {}, [2] = {}}
            data.trigger[1].order = {}
            for k, v in pairs(data.trigger1) do
                data.trigger1[k] = v / 10000
                table.insert(data.trigger[1].order, k)
            end
            table.sort(data.trigger[1].order)
            data.trigger[1].data = data.trigger1

            data.trigger[2].order = {}
            for k, v in pairs(data.trigger2) do
                data.trigger2[k] = v / 10000
                table.insert(data.trigger[2].order, k)
            end
            table.sort(data.trigger[2].order)
            data.trigger[2].data = data.trigger2

            data.triggerBoss = data.triggerBoss / 10000
        end
    else
        trigger_data = {}
    end    
    self:CheckData()
end

function OblivionGateSystem:CheckData()
    for i = 1, 100 do
        if not trigger_data[i] then
            trigger_data[i] = {id=i, trigger1 = {}, trigger2 = {}, triggerBoss = 0}
            trigger_data[i].trigger = {[1] = {data={}, order={}}, [2] = {data={}, order={}}}
        end
    end
end

function OblivionGateSystem:new(owner)
    local newObj    = {}
    newObj.ptr      = {}
    setmetatable(newObj,        {__index = OblivionGateSystem})
    setmetatable(newObj.ptr,    {__mode = "v"})

    newObj.ptr.theOwner = owner

    local msgMapping = {
        [OBLIVION_CONFIG.MSG_ENTER] 		= OblivionGateSystem.OnEnterGate,		--进入副本
        [OBLIVION_CONFIG.MSG_GET_LIST]      = OblivionGateSystem.OnGetListReq,      --获取副本列表
        [OBLIVION_CONFIG.MSG_QUERY_STATE] 	= OblivionGateSystem.OnQueryStateReq,	--查询状态
    }
    newObj.msgMapping       = msgMapping

    --湮灭之门的ID列表
    newObj.mapGates         = lua_map:new()

    return newObj
end

function OblivionGateSystem:OnOblivionGateReq(msg_id, ...)
    log_game_debug("OblivionGateSystem:OnOblivionGateReq", "msg_id=%d;dbid=%q;name=%s", msg_id, self.ptr.theOwner.dbid, self.ptr.theOwner.name)

    local func = self.msgMapping[msg_id]
    if func ~= nil then
        func(self, ...)
    end
end

--发送消息至Mgr管理器
function OblivionGateSystem:MgrPost(mgr_func_name, mgr_func_param_table)
    local theOwner = self.ptr.theOwner
    globalbase_call("OblivionGateMgr", "MgrEventDispatch", theOwner.base_mbstr, mgr_func_name, mgr_func_param_table,
                    "", "", {})
end

--发送消息至Mgr管理器并回调至Avatar实例
function OblivionGateSystem:MgrCallToAvatar(mgr_func_name, mgr_func_param_table, callback_func_name, callback_func_param_table)
    local theOwner = self.ptr.theOwner
    if not callback_func_param_table then callback_func_param_table = {} end
    globalbase_call("OblivionGateMgr", "MgrEventDispatch", theOwner.base_mbstr, mgr_func_name, mgr_func_param_table,
                    "", callback_func_name, callback_func_param_table)
end

--发送消息至Mgr管理器并回调至Client
function OblivionGateSystem:MgrCallToClient(mgr_func_name, mgr_func_param_table, callback_func_name, callback_func_param_table)
    local theOwner = self.ptr.theOwner
    if not callback_func_param_table then callback_func_param_table = {} end
    globalbase_call("OblivionGateMgr", "MgrEventDispatch", theOwner.base_mbstr, mgr_func_name, mgr_func_param_table,
                    "client", callback_func_name, callback_func_param_table)
end

--发送消息至Mgr管理器并回调至本子系统
function OblivionGateSystem:MgrCall(mgr_func_name, mgr_func_param_table, callback_func_name, callback_func_param_table)
    local theOwner = self.ptr.theOwner
    if not callback_func_param_table then callback_func_param_table = {} end
    globalbase_call("OblivionGateMgr", "MgrEventDispatch", theOwner.base_mbstr, mgr_func_name, mgr_func_param_table,
                    "oblivionGateSystem", callback_func_name, callback_func_param_table)
end

--发送消息至Mgr管理器
function OblivionGateSystem:UserMgrCallToAvatar(dbid, callback_func_name, callback_func_param_table)
    local theOwner = self.ptr.theOwner
    if not dbid or not callback_func_name then return end
    if not callback_func_param_table then callback_func_param_table = {} end
    globalbase_call("UserMgr", "EventDispatch", dbid, "oblivionGateSystem", callback_func_name, callback_func_param_table)
end

--------------------------------------------------------------------------

--获取副本开启的倒计时（封印CD时间），单位：秒，为0代表倒计时完毕
function OblivionGateSystem:GetOpenRemainTime()
    local theOwner  = self.ptr.theOwner
    local cdTick    = 0
    if theOwner.oblivionLastEnterTime ~= 0 then
        local elapse_time = os.time() - theOwner.oblivionLastEnterTime
        if elapse_time < ENTER_CD_TICK then
            cdTick = ENTER_CD_TICK - elapse_time
        end
    end
    return cdTick
end

--标记副本封印进入时间
function OblivionGateSystem:MarkLastEnterTime()
    self.ptr.theOwner.oblivionLastEnterTime = os.time()
end

--重置副本封印进入时间（标记成从未进入）
function OblivionGateSystem:ResetLastEnterTime()
    self.ptr.theOwner.oblivionLastEnterTime = 0
end

--标记最后一次创建湮灭之门的时间
function OblivionGateSystem:MarkLastCreateTime()
    self.ptr.theOwner.oblivionLastCreateTime = os.time()
end

--获取最后一次创建湮灭之门的已过时间，单位：分钟
function OblivionGateSystem:GetLastCreateElapseTime()
    local elapseTime = os.time() - self.ptr.theOwner.oblivionLastCreateTime
    if elapseTime <= 0 then return 0 end
    return (elapseTime / 60)
end

--尝试触发副本，返回nil不触发，1触发恶魔副本，2触发邪神副本
function OblivionGateSystem:TryTrigger(mode)
    local theOwner      = self.ptr.theOwner
    local theElapseTime = self:GetLastCreateElapseTime()
    local theTrigger    = trigger_data[theOwner.level].trigger[mode]
    local idx           = 0
    for _, t in pairs(theTrigger.order) do
        if theElapseTime < t then break end
        idx = t
    end
    if idx == 0 then return nil end

    if math.random() > theTrigger.data[idx] then
        --不触发
        return nil
    elseif math.random() > trigger_data[theOwner.level].triggerBoss then
        --触发恶魔副本
        return 1
    else
        return 1

        --触发邪神副本（策划已删除此需求）
        --return 2
    end
end


------------------------------------------------------------------------

function OblivionGateSystem:OnEnterGate(gate_id)
    local theOwner = self.ptr.theOwner
    if self:GetOpenRemainTime() ~= 0 then
        theOwner:ShowTextID(CHANNEL.DLG, TEXT_LOCKED)
        return
    end

    local mapGates = self.mapGates
    if not mapGates:find(gate_id) then
        theOwner:ShowTextID(CHANNEL.DLG, TEXT_NOT_EXIST)
        return
    end

    self:SendMgr_EnterGate(gate_id)
end

function OblivionGateSystem:OnGetListReq()
    log_game_debug("OblivionGateSystem:OnGetListReq", "")
	self:SendMgr_GetListReq()
end

function OblivionGateSystem:OnQueryStateReq()
    log_game_debug("OblivionGateSystem:OnQueryStateReq", "")
    self:SendMgr_GetQueryStateReq()
end

--------------------------------------------------------------------------

--触发湮灭之门副本，参数mode为1代表剧情关卡，为2代表试炼之塔
function OblivionGateSystem:TriggerGate(mode)
    local gateMode = self:TryTrigger(mode)
    if not gateMode then return end

    --标记湮灭之门的创建时间
    self:MarkLastCreateTime()

    --重置封印时间（策划说不应该重置，注释掉）
    --self:ResetLastEnterTime()

    --创建湮灭之门
    self:SendMgr_CreateGate(public_config.OBLIVION_GATE_TO_MAP[gateMode])
end

--创建湮灭之门副本（GM命令调用接口）
function OblivionGateSystem:CreateGate()
    --local mode = 1
    --if math.random(0,1) == 1 then mode = 2 end
    --self:TriggerGate(mode)
    --if true then return end

    --重置封印时间
    self:ResetLastEnterTime()
    if math.random(0,1) == 0 then
	   self:SendMgr_CreateGate(MAP_ID_A)
    else
       self:SendMgr_CreateGate(MAP_ID_A)

       --self:SendMgr_CreateGate(MAP_ID_B) 策划已删除此需求
    end
end

--传播湮灭之门副本
function OblivionGateSystem:SpreadGate(gate_id)
    log_game_debug("OblivionGateSystem:SpreadGate", "gate_id=%d", gate_id)

    local theOwner = self.ptr.theOwner
    local mapGates = self.mapGates
    if not mapGates:find(gate_id) then return end

    local friends = theOwner.friends
    for friend_dbid, _ in pairs(friends) do
        self:UserMgrCallToAvatar(friend_dbid, "EventSpreadGate", {gate_id})
    end

    self:Send_SpreadGate(gate_id)
end

--------------------------------------------------------------------------

--有新的湮灭之门副本已被创建
function OblivionGateSystem:EventCreateGateComplete(gate_id)
    if not gate_id then return end

	local mapGates = self.mapGates
	if mapGates:insert(gate_id, gate_id) == false then return end

	self:Send_GateCreated(gate_id, 0)
end

--湮灭之门进入完毕
function OblivionGateSystem:EventEnterGateComplete(error_no)
    if error_no == 0 then
        self:MarkLastEnterTime()
    end
end

function OblivionGateSystem:EventGetListComplete(gate_list)
    self.mapGates:clear()
    local mapGates = self.mapGates
    for _, gateID in ipairs(gate_list) do
        mapGates:insert(gateID, gateID)
    end
end

function OblivionGateSystem:EventSpreadGate(gate_id)
    if not gate_id then return end
    if self.ptr.theOwner.level < SPREAD_LEVEL_LIMIT then return end

    local mapGates = self.mapGates
    if mapGates:insert(gate_id, gate_id) == false then return end

    self:Send_GateCreated(gate_id, 1)
    self:Send_ReceiveSpreadGate(gate_id)
end


--------------------------------------------------------------------------

--通知湮灭之门被创建
function OblivionGateSystem:Send_GateCreated(gate_id, create_from_others)
    local theOwner = self.ptr.theOwner
    if theOwner:hasClient() then
        theOwner.client.OblivionGateCreate(gate_id, create_from_others)
    end
end

--通知管理器进入湮灭之门
function OblivionGateSystem:Send_SpreadGate(gate_id)
    local theOwner = self.ptr.theOwner
    if theOwner:hasClient() then
        theOwner.client.OblivionGateSpread(gate_id)
    end
end

--通知管理器创建湮灭之门
function OblivionGateSystem:SendMgr_CreateGate(map_id)
    log_game_debug("OblivionGateSystem:SendMgr_CreateGate", "")
    local theOwner = self.ptr.theOwner
    local params = {map_id, theOwner.dbid, theOwner.name, theOwner.vocation, theOwner.level}
    self:MgrPost("EventCreateGate", params)
    --self:MgrCall("EventCreateGate", params, "EventCreateGateComplete", {})
    --globalbase_call('OblivionGateMgr', 'EventCreateGate', theOwner.base_mbstr, theOwner.dbid, theOwner.name)
end

--通知管理器获取湮灭之门列表
function OblivionGateSystem:SendMgr_GetListReq()
--    log_game_debug("OblivionGateSystem:SendMgr_GetListReq", "")
    local theOwner = self.ptr.theOwner
    self:MgrCallToClient("EventGetListReq", {theOwner.dbid}, "OblivionGateListResp", {self:GetOpenRemainTime()})
    --self:MgrCallToClient("EventGetListReq", {theOwner.dbid, self.mapGates}, "OblivionGateListResp", {self:GetOpenRemainTime()})
    --globalbase_call('OblivionGateMgr', 'EventGetListReq', theOwner.base_mbstr, enter_cd_tick, self.mapGates)
end

--通知管理器查询湮灭之门状态
function OblivionGateSystem:SendMgr_GetQueryStateReq()
--    log_game_debug("OblivionGateSystem:SendMgr_GetQueryStateReq", "")
    local theOwner = self.ptr.theOwner
    self:MgrCallToClient("EventQueryStateReq", {theOwner.dbid, self.mapGates}, "OblivionQueryStateResp", {self:GetOpenRemainTime()})
end

--通知管理器进入湮灭之门
function OblivionGateSystem:SendMgr_EnterGate(gate_id)
    local theOwner = self.ptr.theOwner
    local params = {gate_id, theOwner.dbid}
    self:MgrCall("EventEnterGate", params, "EventEnterGateComplete", {})
    --self:MgrPost("EventEnterGate", params)
    --globalbase_call('OblivionGateMgr', 'EventEnterGate', theOwner.base_mbstr, theOwner.dbid, gate_id)
end

--通知管理器有湮灭之门传播
function OblivionGateSystem:Send_ReceiveSpreadGate(gate_id)
    self:MgrPost("EventReceiveSpreadGate", {self.ptr.theOwner.dbid, gate_id})
end

--------------------------------------------------------------------------

function atest(id)                                                          --调试函数，临时代码需要移除
    adebug(true)
    log_game_debug("atest", "Run begin")                                    --输出调试，临时代码需要移除
    log_game_debug("atest", "Run End")                                      --输出调试，临时代码需要移除
end

function arcol()
    return test_oblivion
end

function adebug(flag)                                                       --调试函数，临时代码需要移除
    if flag == 0 then
        log_game_debug    = lua_util.log_game_debug
    else
        log_game_debug    = arcol_console
    end
end

function arcol_console(head, pattern, ...)                                  --调试函数，临时代码需要移除
    print(head, string.format(pattern, ...))
    lua_util.log_game_debug(head, string.format(pattern, ...))
end

function reload()                                                           --调试函数，临时代码需要移除
    dofile "../scripts/base/OblivionGateMgr.lua"
    dofile "../scripts/base/SubSystem/OblivionGateSystem.lua"
end

function redo()                                                             --调试函数，临时代码需要移除
    reload()
    atest()
end


------------------------------------------------------------------------

g_OblivionGateSystem = OblivionGateSystem
return g_OblivionGateSystem














































