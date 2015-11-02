require "lua_util"
require "t2s"

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info

local eventData = {}
eventData.__index = eventData

setmetatable( eventData, {__index = eventData} )

function eventData:initData()
    self.data ={}

    self.data = lua_util._readXml("/data/xml/Event.xml", "id_i") 
    self.data_login = lua_util._readXml("/data/xml/Reward_Login.xml", "id_i") 
    self.data_recharge = lua_util._readXml("/data/xml/Reward_Recharge.xml", "id_i") 
    self.data_achievement = lua_util._readXml("/data/xml/Reward_Achievement.xml", "id_i") 

    self.data_day_task = lua_util._readXml("/data/xml/day_task.xml", "id_i") 

    self.data_gift_bag = lua_util._readXml("/server_data/gift_bag.xml", "id_i")  --激活码礼包

   for i,v in pairs(self.data) do
        if  v.conditions then
            v.conditions = self.format_data(v.conditions) --现在都是字符串,需要格式化一下
        end

        if v.task_conditions then
            v.task_conditions = self.format_data(v.task_conditions)--现在都是字符串,需要格式化一下
        end  

        --v.triggers = self.format_data_reward(v.gold, v.items)      
   end

    
   for i,v in pairs(self.data_day_task) do
        v.conditions = self.format_data_daytask(v.finish)
   end

   local max_login_day = 0
   for i,v in pairs(self.data_login) do
        if v.days > max_login_day then
            max_login_day = v.days
        end
   end

    local aids = {}
    for k,v in pairs(self.data_achievement) do
         if aids[v.aid] then
            aids[v.aid][v.level]= v.id
        else
            local  tmp = {}
            tmp[v.level] = v.id
            aids[v.aid] = tmp            --成就,等级和ID做个索引
        end
    end

   self.max_login_day = max_login_day --增加一个循环登陆天数
   self.aids = aids --所有成就ID

    self.event_update_table = {}

    self.event_update_table[event_def.forever_event]        = event_def.no_update --永远都不刷新
    self.event_update_table[event_def.day_event ]             = event_def.daily_update
    self.event_update_table[event_def.week_event]             = event_def.week_update
    self.event_update_table[event_def.month_event]           = event_def.month_update
    self.event_update_table[event_def.forever_event_in_time]  = event_def.no_update--永远都不不刷新
    self.event_update_table[event_def.festivalEvent]        = event_def.year_update --一年一次
    self.event_update_table[event_def.festivalDayEvent]     = event_def.daily_update
    self.event_update_table[event_def.festivalWeekEvent]   = event_def.week_update --一周一次
    self.event_update_table[event_def.serverEvent]          = event_def.no_update--永远都不不刷新
    self.event_update_table[event_def.serverDayEvent]       = event_def.daily_update
    self.event_update_table[event_def.serverWeekEvent]      = event_def.week_update

 

   --log_game_debug("eventData:initData", "max_login_day = %s", self.max_login_day   ) 
   --log_game_debug("eventData:initData", "aids = %s", t2s(self.aids) ) 

    --log_game_debug("eventData:initData", "data = %s",t2s(self.data)  ) 
    --log_game_debug("eventData:initData", "data_login = %s",t2s(self.data_login) ) 
    --log_game_debug("eventData:initData", "data_recharge = %s",t2s(self.data_recharge) ) 
    --log_game_debug("eventData:initData", "data_achievement = %s",t2s(self.data_achievement) ) 

end

function eventData.format_data(data)

        if data then
            --a:b:c:d, x:y:z 格式化为  {{listen_id = a,{b,c,d}, {listen_id = x{y,z}}
            --log_game_debug("eventData:format_data", "data = %s",t2s(data)  ) 
           local tmp = lua_util.split_str(data, ',')
            local tmp2 = {}
            for _, v in pairs(tmp) do
                local tmp = lua_util.split_str(v, ':')
                local a_condition = {}  

                a_condition.cid = tonumber(tmp[1]) --condition_id

                table.remove(tmp, 1)   
                a_condition.args = tmp
                table.insert(tmp2, a_condition)  
            end
            --log_game_debug("eventData:format_data", "data = %s",t2s(tmp2)  ) 
            return tmp2

        end

        return nil             
end

function eventData.format_data_daytask(finish)

        local  ret = {}
        local  tmp = {}
        if #finish >=2 then
            tmp.cid = finish[1]
            tmp.args = {finish[2]}
            table.insert(ret, tmp)    
        end
        return ret
         
end



function eventData:GetDataById(id)
    if self.data then
        return self.data[id]
    end
    return nil
end


function eventData:GetData()
      return self.data  -- {[1]={"id" = 1, "type" = 1, "name"="活动"，"arg1"="19:00:00"}....}
end

function eventData:GetData_Login()
        return  self.data_login
    
end
function eventData:GetMaxLoginDay()
        return  self.max_login_day
    
end

function eventData:GetData_Recharge()
     return self.data_recharge
    
end

function eventData:GetData_Achievement()
      return self.data_achievement
end

function eventData:GetData_DayTask()
      return self.data_day_task
end


function eventData:GetData_event_update_table()
      return self.event_update_table
end



function eventData:GetNextAchievement(cur_aid, cur_level)
    --local cur_aid = self.data_achievement[id].aid
    --local cur_level = self.data_achievement[id].level

    for k,v in pairs(self.data_achievement) do
        if cur_aid == v.aid and cur_level + 1 ==v.level then
            return v  --返回该条数据
        end
    end
    return nil    
end

--得到成就最高等级
function eventData:GetMaxLevelByAid(aid)

    local max_level  = 0
    for k,v in pairs(self.data_achievement) do
        if v.aid == aid  and v.level  > v.max_level then
            max_level = v.level
        end
    end

    return max_level    
end



--得到所有的 成就
function eventData:GetAllAids()
    return self.aids    
end




--获得活动列表
function eventData:GetEventList()
    local ret = {}

    for i,v in pairs(self.data) do
        table.insert(ret, i)
    end

    return ret
end


--获得任务完成的条件
--这里因为是从别的对象调用 而且是指针调用 所以self就是其他对象 故不用:调用
function eventData.GetConditions(id)

    --log_game_debug("eventData:GetConditions  temp", "") 
    local ret = {}

     local a_data = g_eventData:GetDataById(id)

    if a_data then
        --log_game_debug("eventData:temp", "a_data = %s",t2s(a_data)  ) 
        if a_data.task_conditions then   
        ret = a_data.task_conditions         
        end
    end
    return ret
end

--获得开启任务的条件
function eventData.GetTaskOpenConditions(id)
    --log_game_debug("eventData:GetTaskOpenConditions  temp", "") 
     local ret = {}
     local a_data = g_eventData:GetDataById(id)
    if a_data then
        --log_game_debug("eventData:temp", "a_data = %s",t2s(a_data)  ) 
        if a_data.conditions then   
        ret = a_data.conditions         
        end
    end
    return ret

end


--这里因为是从别的对象调用 而且是指针调用 所以self就是其他对象 故不用:调用
function eventData.GetTriggers(id)

    --log_game_debug("eventData:GetTriggers  temp", "") 
    local ret = {}
    
    local tmp = {id=2,args={}} --这里的 2 代表触发的是  trigger_dispatcher_lib里面的   libDataMgr.finish_task 
    table.insert(ret, tmp)

    return ret
end

--获得开启任务的条件
function eventData.GetTaskOpenTriggers(id)
      --log_game_debug("eventData:GetTaskOpenTriggers  temp", "") 
      local  ret = {}
     local tmp = {}
     tmp.id = 1
     tmp.args = {}    
     table.insert(ret, tmp)
    return ret

end


function eventData.GetAchievementConditions(id)

    --log_game_debug("eventData:GetAchievementConditions  temp", "") 
    local ret = {}

    local data = g_eventData:GetData_Achievement()
    local a_data = data[id]

    if a_data then
        --log_game_debug("eventData:GetAchievementConditions", "a_data = %s",t2s(a_data)  ) 
        local  tmp = {}
        tmp.cid = a_data.type
        tmp.args = a_data.args
        table.insert(ret, tmp)
    end
    return ret

end

function eventData.GetDayTaskConditions(id)

    local ret = {}
    local data = g_eventData:GetData_DayTask()
    local a_data = data[id]

    if a_data then
        --log_game_debug("eventData:temp", "a_data = %s",t2s(a_data)  ) 
        if a_data.conditions then   
            ret = a_data.conditions         
        end
    end
    return ret

end

function eventData:Get_gift_bag()
    return self.data_gift_bag
end


g_eventData = eventData
return g_eventData
