require "_father"

local globalbase_call = lua_util.globalbase_call
local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error



---------------------引擎可能会回调的方法 begin-----------------------------------------------



local achievmt = {}

setmetatable(achievmt, {__index = g_father} ) --继承自父类 

--achievmt
function achievmt.GetConditions(index)
    return g_eventData.GetAchievementConditions(index)
end


function achievmt.WhenDefualt(trigger, index, args)  
    Achievement.IncAchivment(trigger, index, 1)    --默认+1
    return true
end

function achievmt.TestDefualt(trigger, index, args)        
    return Achievement.Test(trigger, index, args)  
end


function achievmt.WhenLevelUp(trigger, index, args)  
    local data = trigger:GetData(index)
    local achievemts_data = g_eventData:GetData_Achievement()
    local id = data.config_id --成就 配置id
    local aid = achievemts_data[id].aid

    local avatar = trigger.ptr.theOwner    

    if avatar.achievement[aid] then
        avatar.achievement[aid][event_def.cur_num] = avatar.level --等于当前等级
        avatar:get_achievement(aid)--同步给客户端 该条
    end
    
    return true
end

function achievmt.WhenFinishFloor(trigger, index, cur_floor)  
    Achievement.IncAchivment(trigger, index, cur_floor)   
    return true
end



function achievmt.WhenOrcRushCount(trigger, index, rush_count)  
    Achievement.IncAchivment(trigger, index, rush_count)    
    return true
end





function achievmt.IncAchivment(trigger, index, count)  

    local data = trigger:GetData(index)
    local achievemts_data = g_eventData:GetData_Achievement()
    local id = data.config_id --成就 配置id
    local aid = achievemts_data[id].aid

    local avatar = trigger.ptr.theOwner    

    if avatar.achievement[aid] then
        avatar.achievement[aid][event_def.cur_num] = avatar.achievement[aid][event_def.cur_num] + count
        --avatar.client.get_achievement_Resp(aid, avatar.achievement[aid]) --同步
        avatar:get_achievement(aid)--同步给客户端 该条
    end
    
    return true
end


function achievmt.Test(trigger, index, args)  

    local data = trigger:GetData(index)
    local achievemts_data = g_eventData:GetData_Achievement()
    local id = data.config_id --成就 配置id
    local aid = achievemts_data[id].aid

    local avatar = trigger.ptr.theOwner

    if avatar.achievement[aid] then
        return avatar.achievement[aid][event_def.cur_num] >= achievemts_data[id].args[1] --达到目标
    end
    
    return false
end



function achievmt.finish(trigger, index)

    local data = trigger:GetData(index)
    local achievemts_data = g_eventData:GetData_Achievement()
    local avatar = trigger.ptr.theOwner

    local id = data.config_id
    local aid = achievemts_data[id].aid --成就
    local level = achievemts_data[id].level --当前等级


    if avatar.achievement[aid] then

        local next_achievement = g_eventData:GetNextAchievement(aid, level)
        if next_achievement then
             avatar.achievement[aid][event_def.level]= level + 1 
             avatar.trigger_save[index].config_id = next_achievement.id  --配置文件指向下一个
             trigger:TestTrigger(index) --这里有可能下一级也会触发 所以要再次TestTrigger 看是否完成  --只有成就是这样

        else
             avatar.achievement[aid][event_def.level] = event_def.max_achievmt_level --置为最大了 同时删除 触发器
             trigger:destroy(index) --该成就完成了 触发器没有存在的必要了
        end  

        if avatar:hasClient() then
            avatar.client.finish_achievement(id) --通知客户端该成就完成
        end
        
    end

    return true  
end



Achievement = achievmt
return Achievement

