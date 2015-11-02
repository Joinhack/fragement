require "_father"



local globalbase_call = lua_util.globalbase_call
local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error



---------------------引擎可能会回调的方法 begin-----------------------------------------------



local event_task = {}
setmetatable(event_task, {__index = g_father} )--继承自父类 


--task
function event_task.GetConditions(index)
    return g_eventData.GetConditions(index)
end


function event_task.InitDefualt(trigger, index, args)  --默认什么都不做
    return true
end
function event_task.WhenDefualt(trigger, index, args)  
    EventTask.IncCount(trigger, index, 1)    --默认+1
    return true
end
function event_task.TestDefualt(trigger, index, args)        
    return EventTask.Test(trigger, index, args)  
end


--兽人
function event_task.WhenOrcRushCount(trigger, index, rush_count)   
    EventTask.IncCount(trigger, index, rush_count or 0)  --+波数
	return true
end

function event_task.WhenFinishFloor(trigger, index, cur_floor)  
    EventTask.IncCount(trigger, index, cur_floor)   
    return true
end





function event_task.IncCount(trigger, index, count)  

    local data = trigger:GetData(index)

    local id = data.config_id --日常任务 配置id

    local avatar = trigger.ptr.theOwner    

    if avatar.event_ing[id] then
        avatar.event_ing[id][event_def.event_cur_num] = avatar.event_ing[id][event_def.event_cur_num] + count 
    end
    
    return true
end


function event_task.Test(trigger, index, args)  

    local data = trigger:GetData(index)
    local id = data.config_id --日常任务 配置id

    local avatar = trigger.ptr.theOwner

    if avatar.event_ing[id] then
        local target_num = tonumber(args[1])
        if not target_num then
            return false
        end
        return avatar.event_ing[id][event_def.event_cur_num] >= target_num --达到目标
    end
    
    return false
end



function event_task.finish(trigger, index)

    local data = trigger:GetData(index)
    local id = data.config_id
    local avatar = trigger.ptr.theOwner

    if avatar.event_ing[id] then

        avatar.event_ing[id][event_def.is_finish] = event_def.task_finish --任务完成        
        avatar.event_ing[id][event_def.task_end_time] = global_data.GetServerTime(public_config.SERVER_TIMESTAMP) --任务结束时候的时间戳
        trigger:destroy(index) --删除该触发器  
        if avatar:hasClient() then
            avatar.client.finish_task(id)
            avatar.client.get_event_ing_Resp(avatar.event_ing, avatar.today_events)
        end

    end

    return true  
end


function event_task.InitLevelUp(trigger,index, event_id)

    local data = trigger:GetData(index)
    local id = data.config_id
    local avatar = trigger.ptr.theOwner

    if avatar.event_ing[id] then
        avatar.event_ing[id][event_def.event_cur_num] = avatar.level
    end

    return true
end



function event_task.InitAddFriend(trigger, index, args)

    local data = trigger:GetData(index)
    local id = data.config_id
    local avatar = trigger.ptr.theOwner

    if avatar.event_ing[id] then
        local friendNum = lua_util.get_table_real_count(avatar.friends)
        avatar.event_ing[id][event_def.event_cur_num] = friendNum
    end

    return true
end




EventTask = event_task
return EventTask

