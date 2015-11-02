require "_father"

local globalbase_call = lua_util.globalbase_call
local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error



---------------------引擎可能会回调的方法 begin-----------------------------------------------



local day_task = {}

setmetatable(day_task, {__index = g_father} ) --继承自父类 

--day_task
function day_task.GetConditions(index)
    return g_eventData.GetDayTaskConditions(index)
end


function day_task.WhenDefualt(trigger, index, args)  
    DayTask.IncTaskCount(trigger, index, 1)    
    return true
end

function day_task.WhenCostDiamond(trigger, index, cost) 
    DayTask.IncTaskCount(trigger, index, cost or 0)   
    return true
end


function day_task.WhenOrcRushCount(trigger, index, rush_count)  
    DayTask.IncTaskCount(trigger, index, rush_count or 0)   
    return true
end



function day_task.TestDefualt(trigger, index, args)        
    return DayTask.Test(trigger, index, args)  
end


function day_task.IncTaskCount(trigger, index, count)  

    local data = trigger:GetData(index)
    local dt_data = g_eventData:GetData_DayTask()
    local id = data.config_id --日常任务 配置id

    local avatar = trigger.ptr.theOwner    

    if avatar.day_task[id] then
        avatar.day_task[id][event_def.cur_num] = avatar.day_task[id][event_def.cur_num] + count 
        --avatar.client.get_achievement_Resp(aid, avatar.day_task[id]) --同步
        if avatar:hasClient() then
             avatar.client.day_task_change(id, avatar.day_task[id])--同步给客户端 该条
        end
    end
    
    return true
end


function day_task.Test(trigger, index, args)  

    local data = trigger:GetData(index)
    local dt_data = g_eventData:GetData_DayTask()
    local id = data.config_id --日常任务 配置id

    local avatar = trigger.ptr.theOwner

    if avatar.day_task[id] then
        return avatar.day_task[id][event_def.cur_num] >= dt_data[id].finish[2] --达到目标
    end
    
    return false
end



function day_task.finish(trigger, index)

    local data = trigger:GetData(index)
    local dt_data = g_eventData:GetData_DayTask()
    local avatar = trigger.ptr.theOwner

    local id = data.config_id

    if avatar.day_task[id] then
        avatar.day_task[id][event_def.is_finish] = event_def.task_finish 
        trigger:destroy(index) --该日常任务完成了 触发器没有存在的必要了
        if avatar:hasClient() then
            avatar.client.finish_day_task(id) --通知客户端该日常任务完成
        end
        avatar:refresh_day_task()
    end

    return true  
end


DayTask = day_task
return DayTask

