
local EventDispatcher = {}
EventDispatcher.__index = EventDispatcher

function EventDispatcher:init()
    self.handlers = {}
end

function EventDispatcher:AddEventListener(triggerEid, nEventId, eid, func)
    --参数：触发者eid，事件id，观察者eid，观察者函数

    local triggers = self.handlers[triggerEid]
    if triggers then
        local eids = triggers[nEventId]
        if eids then
--            for _eid, _func in pairs(self.handlers[triggerEid][nEventId]) do
--                if _eid == eid and _func == func then
--                    return
--                end
--            end
            self.handlers[triggerEid][nEventId][eid] = func
        else
            self.handlers[triggerEid][nEventId] = {[eid] = func,}
        end
    else
        self.handlers[triggerEid] = {[nEventId] = {[eid] = func},}
    end
end

function EventDispatcher:DeleteFromMap(triggerEid, nEventId, eid)

    --参数：触发者，事件id，观察者
    local triggers = self.handlers[triggerEid]
    if not triggers then
        return
    else
        if not triggers[nEventId] then
            return
        else
            self.handlers[triggerEid][nEventId][eid] = nil
        end
    end
end

function EventDispatcher:TriggerEvent(triggerEid, nEventId, ...)

    local triggers = self.handlers[triggerEid]
    if triggers then
        local v = self.handlers[triggerEid][nEventId]
        if v then
            for eid, func in pairs(v) do
                local entity = mogo.getEntity(eid)
                if entity then
                    --触发调用该函数
                end
            end
        end
    end
end

function EventDispatcher:DeleteEntity(eid)

--    log_game_debug("EventDispatcher:DeleteEntity", "eid=%d", eid)

    self.handlers[eid] = nil

    for _, v in pairs(self.handlers) do
        for _, eid_func in pairs(v) do
            eid_func[eid] = nil
        end
    end
end

gEventDispatcher = EventDispatcher
return gEventDispatcher