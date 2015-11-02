
require "t2s"
require "event_def"
require "lua_util"
require "global_data"


local globalbase_call = lua_util.globalbase_call
local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error

local libDataMgr = {}
libDataMgr.__index = libDataMgr


function libDataMgr:initData()

        local data_lib = 
        {
            
            [event_def.condition_config] = { GetConditions = g_eventData.GetTaskOpenConditions, --活动开启条件
                                             GetTriggers = g_eventData.GetTaskOpenTriggers, --活动开启触发
                    },

            [event_def.task_condition_config] = {GetConditions = g_eventData.GetConditions, --活动完成条件
                                                    GetTriggers = g_eventData.GetTriggers, -- 活动完成触发
                    },
            [event_def.achievement_condition_config] = {GetConditions = g_eventData.GetAchievementConditions, --成就完成条件
                                                    GetTriggers = g_eventData.GetAchievementTriggers, -- 活动完成触发
                    },
                    

        }

        local event_dispatcher_lib =
        {
            [1] = libDataMgr.IncCount,
            [event_config.EVENT_ROLE_LEVELUP] = libDataMgr.DoContinue, --人物升级 不处理该事件
            [event_config.EVENT_PLAYER_ADD_FRIEND_SCCESS] = libDataMgr.DoContinue, --添加好友 不处理该事件
            [event_config.EVENT_PLAYER_KILL_MONSTER] = libDataMgr.IncMonster --杀怪记录

        }


        local condition_dispatcher_lib =
        {
            libDataMgr.IsBeyondCount,
            libDataMgr.TestPlayerLevel,
            libDataMgr.TestFriendNum,
            libDataMgr.TestMonster,
        }

        local trigger_dispatcher_lib =
        {
            libDataMgr.GetNewTask,
            libDataMgr.finish_task,
            libDataMgr.finish_an_achievement,
        }


        --这里吧条件和事件做个表
        local condition_type_event_t=
        {
            [1] = {listen_id = 1, need_args = 1},  --1号条件监听listen_id消息，need_args 表示是否需要参数（比如说监听打某怪则需要 怪物ID）
            [2] = {listen_id = event_config.EVENT_ROLE_LEVELUP}, --2号监听人物升级   人物升级来了 不做任何处理 
            [3] = {listen_id = event_config.EVENT_PLAYER_ADD_FRIEND_SCCESS}, --3号监听增加好友 ，不做任何处理
            [4] = {listen_id = event_config.EVENT_PLAYER_KILL_MONSTER} --4号条件监听杀怪事件

            --  1   活动是否开启  活动ID    
            --  2   充值rmb   rmb 
            --  3   主角等级    等级  
            --  4   精灵契约等级  等级  
            --  5   精灵元素等级  等级  
            --  6   主角pvp等级 等级  
            --  7   竞技场获胜次数 次数  
            --  8   遗忘之塔层数  层数  
            --  9   湮灭之门次数  次数  
            --  10  挚友数量    数量  
            --  11  被雇佣次数   次数  
            --  12  杀指定怪物数量 数量  
            --  13  通关全模式所有关卡       
            --  14  完成指定类型关卡次数  关卡类型    次数
            --  15  全身装备品质  "1绿 2蓝 3紫 4橙 5暗金"    
            --  16  全身强化星级  星级  
            --  17  拥有1颗宝石等级    数量  
            --  18  拥有9级宝石数量    数量  

        }



        --[[
        setmetatable(data_lib, {__index =    
            function (table, key)
                return libDataMgr.DoNothing--默认返回什么都不做函数
                 end}
                 )

        setmetatable(event_dispatcher_lib, {__index =
        function (table, key)
            return libDataMgr.DoNothing--默认返回什么都不做函数
        end
        }
        )
        ]]
       
         setmetatable(condition_dispatcher_lib, {__index =
        function (table, key)
            return libDataMgr.DoNothing--默认返回什么都不做函数
        end
        }
        ) 

         setmetatable(trigger_dispatcher_lib, {__index =
        function (table, key)
            return libDataMgr.DoNothing--默认返回什么都不做函数
        end
        }
        )
    --[[ 这个不是函数对应表 不需要做任何默认操作 此处 注释
        setmetatable(condition_type_event_t, {__index =
        function (table, key)
            return libDataMgr.DoNothing  --默认返回什么都不做函数
        end
        }
        )
-]]

        self.data_lib = data_lib 
        self.event_dispatcher_lib = event_dispatcher_lib
        self.condition_dispatcher_lib = condition_dispatcher_lib
        self.trigger_dispatcher_lib = trigger_dispatcher_lib
        self.condition_type_event_t = condition_type_event_t


         --log_game_debug("libDataMgr:temp", "data_lib ：%s ", t2s(data_lib)) 
         --log_game_debug("libDataMgr:temp", "event_dispatcher_lib ：%s ", t2s(event_dispatcher_lib)) 
        -- log_game_debug("libDataMgr:temp", "condition_dispatcher_lib ：%s ", t2s(condition_dispatcher_lib)) 
        -- log_game_debug("libDataMgr:temp", "trigger_dispatcher_lib ：%s ", t2s(trigger_dispatcher_lib)) 
        -- log_game_debug("libDataMgr:temp", "condition_type_event_t ：%s ", t2s(condition_type_event_t)) 
end
 


function libDataMgr:Get_data_lib()
    return self.data_lib
end


function libDataMgr:Get_condition_dispatcher_lib()
    return self.condition_dispatcher_lib
end

function libDataMgr:Get_condition_type_event_t()
    return self.condition_type_event_t
end


function libDataMgr:Get_event_dispatcher_lib()
   return  self.event_dispatcher_lib
end


function libDataMgr:Get_trigger_dispatcher_lib()
    return self.trigger_dispatcher_lib
end






 function libDataMgr:DoNothing(...)
             log_game_debug("libDataMgr:DoNothing", "!!!!!!")
             return true
 end
 function libDataMgr:DoContinue(...)
             log_game_debug("libDataMgr:DoContinue", "!!!!!!")
             return true
 end


-------------------------------以下是库------------

--事件处理库 event_dispatcher_lib -----------

--原型: function libDataMgr:func(...)-----------



--
function libDataMgr:IncCount(index, event_id, args, ...)  
    log_game_debug("libDataMgr:IncCount Temp","Into libDataMgr:IncCount  event_id = %s, ... = %s", 
        t2s(event_id), 
        t2s(...)) 

    --local event_id = tonumber(data[1])
    --local count = tonumber(data[2])

    if not self.data.eventCount then
        self.data.eventCount ={}
    end

    log_game_info("libDataMgr.IncCount", "before: count = %s",self.data.eventCount[event_id])
    self.data.eventCount[event_id]  = self.data.eventCount[event_id]  + 1
    log_game_info("libDataMgr.IncCount", "after: count = %s",self.data.eventCount[event_id])
    return true,{}
end

function libDataMgr:IncMonster(index, event_id, args, ...)  
    log_game_debug("libDataMgr:IncMonster Temp","Into libDataMgr:IncCount  event_id = %s, args=%s ... = %s", 
        t2s(event_id), 
        t2s(args), 
        t2s(arg)) 

    --a,b = ...          -- a gets the first vararg parameter, b gets
                        -- the second (both a and b can get nil if there
                        -- is no corresponding vararg parameter)

    local moster_id = tonumber(args[1])
    local a,b = ...
   
   log_game_info("libDataMgr.IncMonster", "a = %s monster_id = %s",a, moster_id)
    if moster_id ~= tonumber(a) then --不需要计数
        return false
    end
  
    local data = self:GetData(index)

    if data.trigger_type == event_def.achievement_condition_config then
        self.ptr.theOwner.monster_calc[moster_id] =  (self.ptr.theOwner.monster_calc[moster_id] or 0) + 1 
    elseif data.trigger_type == event_def.task_condition_config then
        if not self.ptr.theOwner.event_ing[data.config_id].monster_calc then
            self.ptr.theOwner.event_ing[data.config_id].monster_calc = {}
        end
        self.ptr.theOwner.event_ing[data.config_id].monster_calc[moster_id] = (self.ptr.theOwner.event_ing[data.config_id].monster_calc[moster_id] or 0) + 1
        log_game_info("libDataMgr.IncMonster", "monster_num = %s",self.ptr.theOwner.event_ing[data.config_id].monster_calc[moster_id])
    else
        log_game_error("libDataMgr:IncMonster", "error data.trigger_type = %s not have code !!!!!!",data.trigger_type)

    end
   

    return true
end




function libDataMgr:TestPlayerLevel(index, args)    
    
    log_game_info("libDataMgr.TestPlayerLevel", "args = %s player level = %s",t2s(args), self.ptr.theOwner.level )
    local level = tonumber(args[1])
   

    return self.ptr.theOwner.level >= level   
end

function libDataMgr:TestFriendNum(index, args)    
    
   log_game_info("libDataMgr.TestFriendNum", "args = %s",t2s(args))
   local need_num = tonumber(args[1])
   
   local friendNum = lua_util.get_table_real_count(self.ptr.theOwner.friends)
   return friendNum >= need_num   
end




function libDataMgr:TestMonster(index, args)  
    log_game_info("libDataMgr.TestMonster", "args = %s",t2s(args))
    local moster_id = tonumber(args[1])
    local count = tonumber(args[2])


    local data = self:GetData(index)
     log_game_info("libDataMgr.TestMonster", "data = %s",t2s(data))

    if data.trigger_type == event_def.achievement_condition_config then --成就怪物加的地方
         log_game_info("libDataMgr.TestMonster temp", "cur_monster_num =  %s",self.ptr.theOwner.monster_calc[moster_id])
        return self.ptr.theOwner.monster_calc[moster_id] >= count  

    elseif data.trigger_type == event_def.task_condition_config then --运营活动怪物位置
        if self.ptr.theOwner.event_ing[data.config_id].monster_calc then
            log_game_info("libDataMgr.TestMonster temp", "cur_monster_num =  %s", self.ptr.theOwner.event_ing[data.config_id].monster_calc[moster_id])
            return self.ptr.theOwner.event_ing[data.config_id].monster_calc[moster_id] >= count
        end
       
    else
        log_game_error("libDataMgr:TestMonster", "error data.trigger_type = %s not have code !!!!!!",data.trigger_type)
    end

    return false
end



--接任务
function libDataMgr:GetNewTask(index, args)    

    log_game_info("libDataMgr.GetNewTask", "args = %s",t2s(args))

    local data = self:GetData(index)

    local avatar = self.ptr.theOwner --这里用一个变量来存 因为等下要删除了 这个东东不会存在了

    --avatar:RemoveTrigger(self.index) --删除该触发器  
    if  avatar:AddTrigger(data.config_id, event_def.task_condition_config)  then

        local event_id = data.config_id
        if event_id then

             
            avatar.event_ing[event_id].is_in_task = event_def.in_task --已接取任务
            local cur_time = global_data.GetServerTime(public_config.SERVER_TIMESTAMP)
            avatar.event_ing[event_id].accept_time = cur_time
            avatar.event_ing[event_id].close_time = -1 --截止时间 没有则为-1
            avatar.accepted_event[event_id].limit_time = cur_time
            avatar.accepted_event[event_id].limit_count = avatar.accepted_event[event_id].limit_count + 1

            --[[
            local a_data = g_eventData:GetDataById(event_id) --该活动的数据
            if a_data.limit_time  then 
                avatar.event_ing[event_id].close_time = cur_time  + a_data.limit_time*60    --截止时间     
            end 
            ]]

        end
         
        self:destroy(index) --删除该触发器  

    end

    --avatar:AddTrigger(data.id, event_def.task_condition_config) 

    return true
end


function libDataMgr:finish_task(index, args)    

    log_game_info("libDataMgr.finish_task", "args = %s",t2s(args))
     
    local  data = self:GetData(index)

    local event_id = data.config_id

    if event_id then
        self.ptr.theOwner.event_ing[event_id].is_finish = event_def.task_finish --任务完成
        self.ptr.theOwner.event_ing[event_id].task_end_time = global_data.GetServerTime(public_config.SERVER_TIMESTAMP)
        self:destroy(index) --删除该触发器  
    end

    return true
end


--[[
function libDataMgr:finish_an_achievement(index, args)    

    local  data = self:GetData(index)
    if data.trigger_type ~= event_def.achievement_condition_config    then --不是成就类型的触发器
        return false
    end

    local event_id = data.config_id
    local arch_data = g_eventData:GetData_Achievement()
    local an_arch_data = arch_data[event_id]

    if an_arch_data then       
        log_game_info("libDataMgr.finish_an_achievement", "an_arch_data = %s",t2s(an_arch_data))   
        if  not self.ptr.theOwner.finish_achievement[an_arch_data.aid] then
            self.ptr.theOwner.finish_achievement[an_arch_data.aid] ={}
        end

        self.ptr.theOwner.finish_achievement[an_arch_data.aid].level = an_arch_data.level
        self.ptr.theOwner.finish_achievement[an_arch_data.aid].id = an_arch_data.aid
        local next_achievement = g_eventData:GetNextAchievement(event_id)
        if next_achievement then
            log_game_info("libDataMgr.finish_an_achievement", "next_id = %s", next_achievement.id) 
            self.ptr.theOwner.trigger_save[index].config_id = next_achievement.id  --配置文件指向下一个
        else
            log_game_info("libDataMgr.finish_an_achievement", "no next id  remove index = %s", index) 
            self:destroy(index) --该成就完成了 触发器没有存在的必要了
        end
    end

    return true
end
]]

function libDataMgr:finish_an_achievement(index, args)    

    local  data = self:GetData(index)
    if data.trigger_type ~= event_def.achievement_condition_config    then --不是成就类型的触发器
        return false
    end

    local event_id = data.config_id
    if not self.ptr.theOwner.finish_achievement[event_id] then
        self.ptr.theOwner.finish_achievement[event_id] ={}
    end
    
    self.ptr.theOwner.finish_achievement[event_id].is_reward = event_def.not_reward  --未奖励
    self.ptr.theOwner.finish_achievement[event_id].is_finish = event_def.task_finish --完成
    
    local next_achievement = g_eventData:GetNextAchievement(event_id)
    if next_achievement then
            log_game_info("libDataMgr.finish_an_achievement", "next_id = %s", next_achievement.id) 
            self.ptr.theOwner.trigger_save[index].config_id = next_achievement.id  --配置文件指向下一个
    else
            log_game_info("libDataMgr.finish_an_achievement", "no next id  remove index = %s", index) 
            self:destroy(index) --该成就完成了 触发器没有存在的必要了
    end

    return true
end




g_libDataMgr = libDataMgr
return g_libDataMgr