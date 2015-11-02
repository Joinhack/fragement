
require "t2s"
--require "trigger_data"
--require "lib"
require "_achievement"
require "_task"
require "_day_task"

local globalbase_call = lua_util.globalbase_call
local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error


Trigger = {}
setmetatable(Trigger, {__index = Trigger} )



---------------------引擎可能会回调的方法 begin-----------------------------------------------



function Trigger:new(owner)

    local newObj = {}
    newObj.ptr = {}

    setmetatable(newObj, {__index = Trigger})
    setmetatable(newObj.ptr, {__mode = "kv"})

    newObj.ptr.theOwner = owner

    newObj.dispather =
    {
        [event_def.task_condition_config] = EventTask,  --任务完成条件读取id    
        [event_def.achievement_condition_config] = Achievement,   --achievement读取id 
        [event_def.day_task_config] = DayTask,   --日常任务读取位置
    }


    return newObj

end


function Trigger:destroy(index)
    self:onDestroy(index)
end


function Trigger:onDestroy(index)
    --对象销毁时需要删除监听的事件
    --log_game_info("Trigger.onDestroy  ", "")
    local data = self:GetData(index)
    
    for listener_id,v in pairs(data.listen_table) do       
        if self.ptr.theOwner:TestDeleteListener(listener_id, index) then
             self.ptr.theOwner:delEventListener(self.ptr.theOwner:getId(), listener_id)      --删除监听的事件
        end
    end

    self.ptr.theOwner:RemoveTrigger(index) --从宿主身上删除该触发器

end



function Trigger:Add(id, trigger_type)
    local index = self.ptr.theOwner:GetTriggerId()

--    log_game_info("Trigger.Add temp ", "new index =  %d ", index)

    local data = {}

    data.index = index
    data.config_id = id  --属于哪个任务
    data.type = trigger_type  --触发器类型
    data.listen_table = {}

    local dispather = self.dispather[data.type] --根据类型得到处理器 到底是成就还是任务    
    
    local conditions = dispather.GetConditions(data.config_id)

    for i,v in pairs(conditions) do

        if dispather.condition_event[v.cid] then

            local listen_id = dispather.condition_event[v.cid].listen_id
            if listen_id then
                self.ptr.theOwner:addEventListener(self.ptr.theOwner:getId(), listen_id, "runEventByType") 

                if not data.listen_table[listen_id] then
                    data.listen_table[listen_id] = {}
                end

                data.listen_table[listen_id] = v.args

            else
    --            log_game_info("Trigger.Add temp ", "error  listen_id = %s not found", listen_id)
            end
        end

    end


    self.ptr.theOwner.trigger_save[index] = data

    for k,v in pairs(data.listen_table) do
        local listen_id = k
        local func = dispather.init_func[listen_id]
        if func then
            func(self, index)
        end
    end

    self:TestTrigger(index)--这里需要触发一下 该触发器（因为没有监听活动开始） 而且必须是加了之后 不然 testtrigger有可能会删除掉这个对象
   
end


--[[
function Trigger:init_with_data_index(data)
    
end
]]


function Trigger:GetData(index)

    return self.ptr.theOwner.trigger_save[index]
end


 function Trigger:runEventByType(index, event_id, ...)

    local data = self:GetData(index)

    local dispather = self.dispather[data.type] --根据类型得到处理器 到底是成就还是任务

    local func = dispather.event_func[event_id]

    if func then
        func(self, index, ...)
    end

    self:TestTrigger(index)     


 end


--检查条件
function Trigger:TestCondition(index)
--    log_game_debug("Trigger.TestCondition temp","")
    
    --{{listen_id=?, args={a,b,c,d}}
    local data = self:GetData(index)

    local dispather = self.dispather[data.type] --根据类型得到处理器 到底是成就还是任务

    local conditions = dispather.GetConditions(data.config_id) ---- 返回{condition_id, args={}}

    for i,v in pairs(conditions) do  
        if  dispather.condition_event[v.cid] then
            local listen_id = dispather.condition_event[v.cid].listen_id
            if listen_id then
                local func = dispather.condition_func[listen_id]
                if func then       
                    if not func(self, index, v.args) then
                        return false
                    end
                end
            end
        end
    end

--    log_game_info("Trigger.TestCondition", "trigger_id = %d all condition ok ", index)
    return true

end



function Trigger:TestTrigger(index)

--    log_game_debug("Trigger.TestTrigger temp","")
    if self:TestCondition(index) then
--        log_game_debug("Trigger.TestTrigger temp","")
        self:trigger(index)
    end    
 end

 --触发事件
function Trigger:trigger(index)   

    local data = self:GetData(index)

    local dispather = self.dispather[data.type] --根据类型得到处理器 到底是成就还是任务

    dispather.finish(self, index)

end




g_Trigger = Trigger
return g_Trigger

