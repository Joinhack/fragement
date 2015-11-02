require "event_def"
require "eventData"
require "Trigger"
require "global_data"
require "reason_def"
require "channel_config"
require "public_config"




local globalbase_call = lua_util.globalbase_call
local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error

local item_def = {
              diamond = 1,  --1钻石          
              gold = 2,     --2金币 
              exp = 3,      --3经验

}
  
local ID_SYSTEM       = 1100008 -- 系统
local ID_NULL         = 1100009 --无
local ID_FULL_TITTLE  = 1100010 --背包已满
local ID_FULL_TEXT    = 1100011 --背包已满，邮件补发
local ID_LOGIN_TITTLE = 1100012 --登陆补发
local ID_LOGIN_TEXT   = 1100013 --因你昨天登陆未领取奖励，邮件补发该奖励(第{0}天奖励)
local ID_TASK_TEXT    = 1100014 --因你的任务已完成, 未及时领取奖励, 邮件补发该任务奖励


function Avatar:TriggerEvent(event_id, ...)
        --log_game_debug("Avatar:TriggerEvent", "event_id")
       self:triggerEvent(event_id, event_id, ...)
end


function Avatar:onEnterGame()

    self:on_login_achievement()
    self:refresh_login_days()
    log_game_debug("Avatar:onEnterGame temp", "onEnterGame")
		--先加载那些已经参加的触发器 保存的触发器 都加载进去
    --self:LoadExistsTrigger()
 	self:on_login_day_task()
    
    
    globalbase_call('EventMgr', 'EnterEvents', self.base_mbstr)
    globalbase_call('EventMgr', 'OnPlayerEnterGame', self.base_mbstr) --补偿、公告 等等
    globalbase_call('EventMgr', 'online_action', self.name) --上线动作管理
    

end


----先加载那些已经参加的触发器 保存的触发器 都加载进去

function Avatar:LoadExistsTrigger()
   --log_game_debug("Avatar:LoadExistsTrigger temp", "ing =  %s ",t2s(self.event_ing))
    for i,v in pairs(self.event_ing) do  --查找各个任务状态 
          if v[event_def.is_finish] == event_def.task_not_finish then--已经接了任务了并且未完成 就加触发器  
            log_game_debug("Avatar:LoadExistsTrigger temp", "AddTrigger  id  =  %s ",v[event_def.id])
            self:AddTrigger(v[event_def.id], event_def.task_condition_config) 
          end
    end
end

--
function Avatar:EnterEvents(event_table)
         --log_game_debug("Avatar:EnterEvents temp", "event_table %s ",t2s(event_table))

        log_game_debug("Avatar:EnterEvents", "before delete_timeout_event_on_login :%s",self.event_ing)
       self:delete_timeout_event_on_login(event_table)--①删除过期任务
       log_game_debug("Avatar:EnterEvents", "after delete_timeout_event_on_login :%s",self.event_ing)
       self:LoadExistsTrigger() --这个要在删除过期任务之后 加载那些剩下的触发器
      self:join_opens(event_table) --参加已经开启的

end


--得到活动开启列表
function Avatar:EventOpenList(event_table)
     globalbase_call('EventMgr', 'EventOpenList', self.base_mbstr)

end



function Avatar:IsEventOpen(event_table, event_id)
    return  event_table[event_id] == event_def.switch_on --开启状态
end


function Avatar:delete_timeout_event_on_login(event_table)

--   log_game_debug("Avatar:delete_timeout_event_on_login", "!!!!!!! ")   

   local remove_table ={} -- 存储需要删除的 过时的活动，不在循环中删除。避免序号错位

--    log_game_debug("Avatar:delete_timeout_event_on_login TEMP", "event_ing=%s", t2s(self.event_ing) ) 

    for i,v in pairs(self.event_ing) do  --正在做的活动任务 

      local event_id = v[event_def.id]

      log_game_debug("Avatar:delete_timeout_event_on_login TEMP", "event_id = %s ", event_id)  
      local a_data = g_eventData:GetDataById(event_id) --该活动的数据
      if a_data then
         if a_data.limit_time  then 
          log_game_debug("Avatar:delete_timeout_event_on_login TEMP", "event_id = %s Has Limittime ", event_id)  
           if global_data.GetServerTime(public_config.SERVER_TIMESTAMP) >= v[event_def.accept_time] + a_data.limit_time *60 then--超过时间
              log_game_debug("Avatar:delete_timeout_event_on_login TEMP", "time out")  
              table.insert(remove_table,event_id) 
            end
        else
          if self:IsEventTimeOut(event_id, v[event_def.accept_time], event_table) then
            log_game_debug("Avatar:delete_timeout_event_on_login TEMP", "add int remove_table")  
            table.insert(remove_table,event_id)         
          end
        end  
      end  
  end

  log_game_debug("Avatar:delete_timeout_event_on_login TEMP", "remove_table=%s", t2s(remove_table) ) 

      for k,v in pairs(remove_table) do
        self:delete_task(v)
        globalbase_call("MailMgr", "SendEx", "event_delete", self.name, tostring(v), "System", os.time(), reason_def.activity)
      end    
end


function Avatar:delete_task(event_id)

   if not self.event_ing[event_id] then
      return 
    end

    --玩家是否领取奖励
     if self.event_ing[event_id][event_def.is_reward] == event_def.not_reward then-- 没有领奖
        --未领奖 则判断有没有完成该任务
       if self.event_ing[event_id][event_def.is_finish] == event_def.task_finish  then--任务完成
          local a_data = g_eventData:GetDataById(event_id) --该活动的数据

          if a_data.reward_type == event_def.reward_type_yes  then --邮件补发
            --将奖励用邮件发送给玩家
            local resend_items = self:get_items_by_vocation(a_data)
            --local text = string.format("因你的任务已完成, 未及时领取奖励, 邮件补发该任务奖励, 任务id:%s, time: %s", event_id, os.time())
            self:send_reward_by_email(tonumber(a_data.name), ID_TASK_TEXT, resend_items, 0, a_data.gold or 0, 0, a_data.energy or 0)   --补发活动奖励       
          end       
       end
     end
    self.event_ing[event_id] = nil    

    if self:hasClient() then
        self.client.get_event_ing_Resp(self.event_ing, self.today_events)
    end

end

function Avatar:send_reward_by_email(titleId, textId, items,diamond,gold, exp, energy, params)
--todo
  local attachment = {}
  if items then
    attachment = items
  end

  if diamond and (diamond ~= 0) then
    table.insert(attachment,public_config.DIAMOND_ID,diamond)   
  end

  if gold and (gold ~= 0) then
    table.insert(attachment,public_config.GOLD_ID,gold)   
  end

  if exp and (exp ~= 0) then
    table.insert(attachment,public_config.EXP_ID,exp)   
  end

  if energy and (energy ~= 0) then
    table.insert(attachment,public_config.ENERGY_ID,energy)   
  end

  globalbase_call("MailMgr", "SendIdEx", titleId or ID_NULL, self.name, textId or ID_NULL, ID_SYSTEM, os.time(), attachment, {self.dbid}, params or {}, reason_def.activity)
 
 --log_game_debug("Avatar:send_reward_by_email", "send_reward_by_email!!!!!!! %s ",event_id)   
end



--活动是否过时(活动关闭，则过时，活动还是开启 但是已经不是上次下线时候的那个活动，则活动也过时了)
function Avatar:IsEventTimeOut(event_id, accept_time, event_table)
  if not self:IsEventOpen(event_table, event_id) then --活动关闭 则过时
    log_game_debug("Avatar:IsEventTimeOut TEMP", "event (%s) closed", event_id)  
    return true
  end

  if self:NotInTime(event_id, accept_time) then
    return true
  end

  return false

end

--是否不在时间内
function Avatar:NotInTime(event_id, accept_time)

  if not  accept_time then  
    return true  -- 不在时间呢
  end

  --活动开启 则判断 参加的活动是不是
  local accept_time_t = global_data.GetTimeByFormat(accept_time,"*t")
  local cur_time_t = global_data.GetCurTimeByFormat("*t")

  local a_data = g_eventData:GetDataById(event_id) --该活动的数据

  if a_data then
    local event_update_table = g_eventData:GetData_event_update_table()
    local update_type = event_update_table[a_data.type]

    if update_type == event_def.daily_update then --日更新
      if accept_time_t.day ~= cur_time_t.day then
        log_game_debug("Avatar:IsEventTimeOut TEMP", "day")  
        return true
      end
    elseif update_type == event_def.week_update  then --周更新
      if not global_data.IsInSameWeek(accept_time_t, cur_time_t) then
        log_game_debug("Avatar:IsEventTimeOut TEMP", "week") 
        return true
      end
    elseif update_type == event_def.year_update  then --年更新
      if accept_time_t.year ~= cur_time_t.year then
         log_game_debug("Avatar:IsEventTimeOut TEMP", "year") 
        return true
      end
      else --不更新的 不用管
    end   

  end

  return false

end


--得到event_ing
function Avatar:get_event_ing()  
  if self:hasClient() then
      self.client.get_event_ing_Resp(self.event_ing, self.today_events)
  end 
end



--客户端请求参加活动 --这时候活动已经开启
function Avatar:join_event(event_id)
    
  local event_table = {}
  event_table[event_id] = event_def.switch_on
  local  bSuccess, result = self:join_event_from_eventmgr(event_table, event_id)
  if  bSuccess then
      self.today_events[event_id] = result
      if self:hasClient() then
          self.client.get_event_ing_Resp(self.event_ing, self.today_events)
      end 
  end


end



--活动开启之后的判断
function Avatar:join_event_from_eventmgr(event_table, event_id)

    --log_game_debug("Avatar:join_event temp", "event_id %s ",event_id)   
    local bSuccess, result = self:can_join_event(event_table, event_id)

    if not bSuccess then
      --log_game_debug("Avatar:join_event", "join event  %s  failed return code =%s",event_id, bSuccess) 
      --self.client.join_event_Resp(event_id, result)
      return false, result
    end

    self:get_task(event_id)    --接任务

    return true, {}
    --self.client.join_event_Resp(event_id, result)
end



function Avatar:get_task(event_id)
    local tmp ={}
    local tmp1 ={}
    local cur_time = global_data.GetServerTime(public_config.SERVER_TIMESTAMP)
    local last_count = 0
    if self.accepted_event[event_id] then
      last_count = self.accepted_event[event_id][event_def.count] or 0
    end

    local a_data = g_eventData:GetDataById(event_id) --该活动的数据
    local close_time = 0
    if a_data and a_data.limit_time then
      close_time = cur_time + a_data.limit_time * 60   --limit_time 是分钟
    end



    tmp[event_def.id] = event_id
    tmp[event_def.is_finish] = event_def.task_not_finish  --任务未完成
    tmp[event_def.is_reward] = event_def.not_reward -- 没有领奖
    tmp[event_def.accept_time] = cur_time
    tmp[event_def.close_time] = close_time --截止时间,没有 则为0
    tmp[event_def.event_cur_num] = 0--当前进度 




    tmp1[event_def.id] = event_id
    tmp1[event_def.accept_time] = cur_time
    tmp1[event_def.count] = last_count + 1


    self.event_ing[event_id] = tmp 
    self.accepted_event[event_id] = tmp1

    self:AddTrigger(event_id, event_def.task_condition_config)   

end





--是否能参加活动
function Avatar:can_join_event(event_table, event_id)
  local result = {}
  local bSuccess = false
  if not self:IsEventOpen(event_table, event_id) then
    result[event_def.error_code_event_closed] = 1  --活动已关闭
  end

  if self.event_ing[event_id] then
    result[event_def.error_code_event_ing] = 1   --正在做 
  end

  if self.accepted_event[event_id] then  --检查是不是可以在时间内接受（一天一次，一周一次 一年一次）
    if not self:NotInTime(event_id, self.accepted_event[event_id][event_def.accept_time]) then
      result[event_def.error_code_event_done] = 1   --已经做过该任务 
    end
  end
   
  local a_data = g_eventData:GetDataById(event_id) --该活动的数据

  --次数判断
  if a_data.limit_count  then --有次数限制 则判断时间
         if self.accepted_event[event_id] then
          if not self.accepted_event[event_id][event_def.count] then 
             log_game_error("can_join_event", "event_id=%s, %s",event_id,t2s(self.accepted_event))  
          end

           if self.accepted_event[event_id][event_def.count] >= a_data.limit_count then
            result[event_def.error_code_event_beyond_count] = self.accepted_event[event_id][event_def.count]   --超过次数 
           end
         end
  end

  if a_data.conditions then
    if  not self:IsInCondition(a_data.conditions) then
      result[event_def.error_code_event_cant_get_task] = 1   --没有达到接取任务条件 
    end   
  end

  if not next(result)  then
    bSuccess = true
  end


  return bSuccess, result
end

function Avatar:IsInCondition(conditions)

  for id, args in pairs(conditions) do
    local need_level = tonumber(args.args[1]) or 0
      if self.level < need_level then
        return false      
      end      
  end

  return true
  
end



--离开活动
function Avatar:leave_event(event_id)

    --log_game_debug("Avatar:leave_event temp", "event_id %s ",event_id)   

    local a_data = g_eventData:GetDataById(event_id) --该活动的数据
  --时间判断
    if not a_data.limit_time  then --没有时间限制 就直接删任务就是了。
         self:delete_task(event_id)
     end
end



function Avatar:AddTrigger(id, config_type)
    --log_game_debug("Avatar:AddTrigger", "id %d,config_type:%d",id, config_type)
    self.triggerSystem:Add(id, config_type)
    return true
end



--删除触发器
function Avatar:RemoveTrigger(index)

      if self.trigger_save then
        if self.trigger_save[index] then
          self.trigger_save[index] = nil
        end
        --[[
        for i,v in pairs(self.trigger_save) do
          log_game_debug("Avatar:RemoveTrigger  temp", "v.index (%d) index(%d)", v.index , index)
          if v.index == index then
            log_game_debug("Avatar:RemoveTrigger  temp", "before: %s",  t2s(self.trigger_save))
            --self.triggerContainer[i] =nil
            --table.remove(self.trigger_save,i)     
            self.trigger_save[index] = nil
            log_game_debug("Avatar:RemoveTrigger  temp", "after: %s",  t2s(self.trigger_save))
          end
        end   ]]   
      end 
end



function Avatar:GetTriggerId()

	if not self.trigger_save then
		log_game_debug("Avatar:GetTriggerId", "not have self.trigger_save")
		return nil
	end

	local i = 2  --这里从2开始 以便做索引 删除的时候序号就不会变了

	while self.trigger_save[i]	do
		i = i + 1 
	end

	return i
end




 --获取某个活动的奖励
function Avatar:get_reward(event_id)

  --log_game_debug("Avatar:get_reward", "event_ing  = %s", t2s(self.event_ing))
  log_game_info("Avatar:get_reward", "dbid=%q;name=%s;event_id=%s",
        self.dbid, self.name, event_id)    
  local ret = self:can_get_reward(event_id)

	if  ret == event_def.error_code_successful then
    local data  = g_eventData:GetData()
    local  a_data = data[event_id]
    if a_data then

  		self.event_ing[event_id][event_def.is_reward] = event_def.has_reward  --已领奖
        if a_data.gold then  --加金钱
          self:AddGold(a_data.gold, reason_def.event)
        end

        if a_data.energy then  -- 加体力
          self:AddEnergy(a_data.energy, reason_def.event)
        end
        
        self:item_reward(a_data, reason_def.event)

              --self:delete_task(event_id)      

      if self:hasClient() then
        self.client.get_event_ing_Resp(self.event_ing, self.today_events)
      end 

    end
    
	end
 

    if self:hasClient() then
      self.client.get_reward_Resp(event_id, ret)
  end 

end


--是否
function Avatar:can_get_reward(event_id)
  if not self.event_ing[event_id] then
    return event_def.error_code_event_no_begin --没有做该任务
  end

  if self.event_ing[event_id][event_def.is_finish] ~=  event_def.task_finish  then
    return event_def.error_code_event_not_finish-- 还没有完成该任务
  end

  if self.event_ing[event_id][event_def.is_reward] ~= event_def.not_reward then
    return event_def.error_code_event_rewarded --已经领过奖了
  end
  return event_def.error_code_successful    
end



function Avatar:runEventByType(event_id, ...)

    --log_game_debug("Avatar:runEventByType", "comes a event id= %s args =%s", event_id, t2s(...))

    if self.trigger_save then
         for i,v in pairs(self.trigger_save) do
            if v.listen_table[event_id]  then   --看该触发器对该事件敢不敢兴趣 
                local index = i
                self.triggerSystem:runEventByType(index, event_id, ...)
            end
         end
    end

  
  --[[
    if self.triggerContainer then
        log_game_debug("Avatar:runEventByType", "num  %d", #self.triggerContainer)
         for i,v in pairs(self.triggerContainer) do
          local  trigger = v 
            if trigger.listen_table[event_id]  then   --看该触发器对该事件敢不敢兴趣
               log_game_debug("Avatar:runEventByType", "sub num  %d", #self.triggerContainer)
           
                log_game_debug("Avatar:runEventByType", "trigger.index= %s", trigger.index)
                trigger:runEventByType(event_id, ...)
            end
         end
    end ]]
end

--判断该事件是否还有触发器监听，如果没有 则需要删除
function Avatar:TestDeleteListener(event_id, index)  
    if self.trigger_save then
         for i,v in pairs(self.trigger_save) do
            local  trigger = v 
            if index ~= trigger.index then --这时候触发器还没删除 则肯定不能判断自己的触发器
                if trigger.listen_table[event_id]  then   --看该触发器对该事件敢不敢兴趣
                     return false --还有其他监听器监听该消息 不能删
                end
            end
         end
    end 
    return true
end





------------------以下是充值奖励活动----------------------------------------


--充值奖励
function Avatar:get_reward_recharge(id)

  --log_game_debug("Avatar:get_reward", "event_ing  = %s", t2s(self.event_ing))
  log_game_info("Avatar:get_reward_recharge", "dbid=%q;name=%s;id=%s",
        self.dbid, self.name, id)    
  local ret = self:can_get_reward_recharge(id)
  if  ret == event_def.error_code_successful then
    local data  = g_eventData:GetData_Recharge()
    local  a_data = data[id]
    if a_data then

      self.done_recharge[id] = event_def.has_reward --已领奖
      self:item_reward(a_data,reason_def.recharge)
      --[[
        local items = a_data.items
        for i,v in pairs(items) do
            self:add_item(i,v)
        end]]
        
    end    
  end

  if self:hasClient() then
      self.client.get_reward_recharge_Resp(id, ret)
  end 



end

-- 得到已经领取的充值奖励
function Avatar:get_done_recharge()   
  if self:hasClient() then
      self.client.get_done_recharge_Resp(self.done_recharge)
  end 
end

--得到充值的数目
function Avatar:GetRecharge()
  return self.chargeSum or 0
end

function Avatar:IsNewPlayer()
  return true
end

function Avatar:GetNextLevelExp(cur_level)

  local cfgs = g_avatar_level_mgr:getCfg()
  if cfgs and cfgs[cur_level] then
      return cfgs[cur_level].nextLevelExp or 0
  end

  return 0
end


function Avatar:can_get_reward_recharge(id)

  if  self.done_recharge[id]  == event_def.has_reward then  -- 已领取该奖励
      return event_def.error_code_event_rewarded --已经领过奖了
  end

    local data  = g_eventData:GetData_Recharge()
    local  a_data = data[id]
    if a_data then
        log_game_debug("Avatar:can_get_reward_recharge", "%s  >= %s  ???", self:GetRecharge(), a_data.money)
        if self:GetRecharge() >= a_data.money  then --超过奖励
          return  event_def.error_code_successful 
        else
          return event_def.error_code_event_less_recharge
        end
    end

  return event_def.error_code_event_unknow

end


------------------登陆奖励------------------------------------------------------


function Avatar:get_reward_login()

    --self:refresh_login_days()

    log_game_info("Avatar:get_reward_login", "dbid=%q;name=%s;days=%s",
        self.dbid, self.name, self.login_days)    

      if not self.login_data.has_reward  then 
       self.login_data.has_reward = {}
      end
 
      local ret = self:login_reward_by_days(self.login_days, false)   --领取今天的奖励

    

      if self.login_days > 1 then
        self:login_reward_by_days(self.login_days-1, true)   --领取昨天的奖励
      end

    if self:hasClient() then
        self.client.get_reward_login_Resp(ret)
    end 
      
      
end



--领取第xx天 的登陆奖励
function Avatar:login_reward_by_days(days, bEmail)

  if not self.login_data.has_reward[days] then --该天未登陆
    return event_def.error_code_event_not_login
  end

  if 1 == self.login_data.has_reward[days] then --已经领取奖励
    return  event_def.error_code_event_rewarded 
  end

  local day_mod = days % g_eventData:GetMaxLoginDay()
  if day_mod == 0 then day_mod = g_eventData:GetMaxLoginDay() end

   local data  = g_eventData:GetData_Login()    
    for k,v in pairs(data) do     

       if day_mod == v.days and  self.level >= v.level[1]  and self.level <= v.level[2] then

          self.login_data.has_reward[days] = event_def.has_reward --已领奖   
          if days == self.login_days then
            self.login_is_reward = event_def.has_reward  --当天已经领取
          end

          local exp = math.floor(self:GetNextLevelExp(self.level) * v.exp /10000 ) 
          if bEmail then
            local resend_items = self:get_items_by_vocation(v)
            self:send_reward_by_email( ID_LOGIN_TITTLE, ID_LOGIN_TEXT, resend_items, v.diamond,v.gold,exp, v.energy, {days})
          else
            --[[
                for i,v in pairs(v.items) do --奖励道具
                    self:MyAddItem(i,v, reason_def.login)
                end ]]

                self:item_reward(v, reason_def.login)
                self:AddExp(exp,reason_def.login)   --加经验
                self:AddGold(v.gold,reason_def.login)  --加金钱
                self:AddEnergy(v.energy, reason_def.login) --体力没有道具？就直接加了
                self:OnGetLoginReward(days)--触发领取奖励
          end
        
         -- self.energy = self.energy + v.energy --体力没有道具？就直接加了

          return  event_def.error_code_successful                
        end     
    end
   return event_def.error_code_event_config_not_found     

end




--登陆，设置登陆天数
function Avatar:refresh_login_days()

  local cur_day = global_data.GetCurTimeByFormat("%F") -- 2013-05-06

  log_game_debug("Avatar:whenLogin temp", "cur_day  = %s , last_login = %s ", cur_day, self.login_data.last_login)

  if  cur_day ~=  self.login_data.last_login then --登陆不是同一天

      if self.login_data.last_login ~= global_data.GetYesterday() then --上次登陆不是昨天 则重置 连续登陆天数为1
        self.login_days = 1
        --self.login_data.has_reward = {} --清除所有的已经领奖
        log_game_debug("Avatar:whenLogin temp", "login_data.days  = 1")
      else
        self.login_days = self.login_days + 1 --登陆天数加1
        log_game_debug("Avatar:whenLogin temp", "login_data.days  = %s", self.login_days)
      end

      self.login_data.last_login = cur_day

      if not self.login_data.has_reward  then 
       self.login_data.has_reward = {}
      end

      self.login_data.has_reward[self.login_days] = event_def.not_reward --当天未领取奖励
      self.login_is_reward = event_def.not_reward
  end
end



--充值奖励
function Avatar:get_reward_achievement(id)

  --log_game_debug("Avatar:get_reward_achievement Temp ", "event_ing  = %s", id)
  log_game_info("Avatar:get_reward_achievement", "dbid=%q;name=%s;id=%s",
        self.dbid, self.name, id)    
  local ret = self:can_get_reward_achievement(id)
  if ret == event_def.error_code_successful  then
    local data  = g_eventData:GetData_Achievement()
    local  a_data = data[id]
    if a_data then 
        local aid = a_data.aid
        --log_game_debug("Avatar:get_reward_achievement", "a_data =%s, add diamond OK, diamond num  = %s",t2s(a_data), a_data.diamond)   
        self:AddDiamond(a_data.diamond, reason_def.achievement)
        if self.achievement[aid] then
          self.achievement[aid][event_def.reward_level] = self.achievement[aid][event_def.reward_level] + 1 --已领奖
          self:get_achievement(aid)
        end
    end    
  end

    if self:hasClient() then
        self.client.get_reward_achievement_Resp(id, ret)
    end 
  
end

--
function Avatar:can_get_reward_achievement(id)

    local data  = g_eventData:GetData_Achievement()
    local  a_data = data[id]

    if a_data then 
      local level = a_data.level
      local aid = a_data.aid
      if self.achievement[aid] then   

        if level ~=  self.achievement[aid][event_def.reward_level] + 1 then --必须要是 下个等级才能领
          return event_def.error_code_event_cur_cant
        end

        if  self.achievement[aid][event_def.level] == event_def.max_achievmt_level then  --最高等级,则可以领
           return event_def.error_code_successful    
        end

        if level < self.achievement[aid][event_def.level] then --小于即可领取
          return event_def.error_code_successful
        else
         return event_def.error_code_event_not_finish-- 还没有完成该任务
        end
      end

    end    
     return event_def.error_code_event_config_not_found-- 未找到对应的config
end


--[[
function Avatar:on_login_achievement()
    local aids = g_eventData:GetAllAids() --所有成就
    log_game_error("Avatar:on_login_achievement", "done achievment = %s", t2s(self.finish_achievement))         
    for aid,v in pairs(aids) do  

      if self.finish_achievement[aid]  then -- 该成就已经完成
         log_game_error("Avatar:on_login_achievement", "achievment %d already finish to level %s", aid,self.finish_achievement[aid][event_def.level])
         local next_level = self.finish_achievement[aid][event_def.level] + 1
         if v[next_level] then
            self:AddTrigger(v[next_level], event_def.achievement_condition_config) 
          else
            --该成就已经没有最高等级了 已经完成
         end
       else --该成就一个都没完成  从第一级开始
         log_game_error("Avatar:on_login_achievement", "new achievment %d ", aid)

        if v[1] then
          self:AddTrigger(v[1], event_def.achievement_condition_config) 
        else
          log_game_error("Avatar:on_login_achievement", "achievment %d not found level=1 config", aid)
        end
      end
    end
end
]]

function Avatar:on_login_achievement()
    local aids = g_eventData:GetAllAids() --所有成就

    for aid,v in pairs(aids) do  
      if not self.achievement[aid] then
        local tmp = {}
        tmp[event_def.aid] = aid  --成就
        tmp[event_def.level] = 1 --默认从1级开始
        tmp[event_def.reward_level] = 0 --领奖领到的等级
        tmp[event_def.cur_num] = 0  --当前进度
        self.achievement[aid] = tmp
      end
      
      local level = self.achievement[aid][event_def.level]
      if level ~= event_def.max_achievmt_level then --成就还没做到最大等级
        if aids[aid][level] then 
          self:AddTrigger( aids[aid][level], event_def.achievement_condition_config) 
        else
          log_game_error("on_login_achievement", "config not found aid = %s, level = %s",aid, level)
        end
      end

    end
end


--[[
--增加到最新的触发器
function Avatar:AddNextAchi(aid_value)  
    for level,id in ipairs(aid_value) do --ipairs 从1开始
       if not self.finish_achievement[id] then --成就已经完成 则看下一个
            self:AddTrigger(id, event_def.achievement_condition_config) 
          break
       end
     end
end
]]



function Avatar:MyAddItem(item_id,num,reason)  
   if   self:AddItem(item_id,num,reason) ~= 0  then
      local attachment = {[item_id] = num}
      self:send_reward_by_email(ID_FULL_TITTLE, ID_FULL_TEXT, attachment )   --补发背包加入失败

   end
end


function Avatar:get_achievement(index)  
  if 0 == index then
    if self:hasClient() then
        self.client.get_achievement_Resp(index, self.achievement)  
    end   
  else
    local tmp = {}
    tmp[index] = self.achievement[index]
    if self:hasClient() then
        self.client.get_achievement_Resp(index, tmp)
    end   
  end  
end


function Avatar:item_reward(data, reason) 

    local items = self:get_items_by_vocation(data) 
    if items then
        for i,v in pairs(items) do
            self:MyAddItem(i,v, reason)
        end
    end

end

--根据职业得到对应的奖励 没有则返回{}
function Avatar:get_items_by_vocation(data) 
  local  items = {} 
  if data then
    local zhiye = self.vocation --职业
    items = data["items"..zhiye] or {}--查找职业对应的奖励
  end
  return items
end



--客户端计时器到了请求这个
function Avatar:event_timeout(event_id)  

    local a_data = g_eventData:GetDataById(event_id) --该活动的数据
    if a_data.limit_time and self.event_ing[event_id] then 
        if global_data.GetServerTime(public_config.SERVER_TIMESTAMP) >= self.event_ing[event_id][event_def.accept_time] + a_data.limit_time *60 then--超过时间
          self:delete_task(event_id)
        end     
    end
end

function Avatar:get_sorry_gift(sorry_table)
  local time = global_data.GetServerTime(public_config.SERVER_TIMESTAMP)
  for id, a_data in pairs(sorry_table) do    
        if a_data then          
          if ((a_data.start_time or 0)  <= time) and ((a_data.end_time or 20000000000) >= time) then  --必须在时间内  最大时间 默认 2603年10月11日 下午7:33:20
            if not self.got_sorry[a_data.id] then  --没领过的才给领
                --local  time  = global_data.GetServerTime(public_config.SERVER_TIMESTAMP)
                local  dbids = {}
                table.insert(dbids, self.dbid)
                globalbase_call("MailMgr", "SendEx", a_data.title or "" , self.name , a_data.text or "", "System", time, a_data.items or {}, dbids, reason_def.activity)
                self.got_sorry[a_data.id] = 1
              end            
          end

        end
    end
end



function Avatar:get_day_task()  

 

    if self:hasClient() then
     self.client.day_task_change(0, self.day_task) --刷新给客户端
  end 

end

--重置任务
function Avatar:reset_day_task()  

  for id, triggerdata in pairs(self.trigger_save) do

    if triggerdata.type == event_def.day_task_config then

       self.triggerSystem:destroy(triggerdata.index) --删除所有
    end     
  end

  self.day_task = {}

  local now_date = global_data.GetCurDay()
  self.last_daytask_date = now_date
  
  self:refresh_day_task() --刷新所有日常
  
  if self:hasClient() then
    self.client.day_task_change(0, self.day_task) --刷新给客户端
  end 

end



function Avatar:refresh_day_task()

  local dt_data = g_eventData:GetData_DayTask()
  for id, a_data in pairs(dt_data) do
    if self:can_get_day_task(a_data, id) then
        local new_day_task = {}
        new_day_task[event_def.is_finish] = event_def.task_not_finish  --任务未完成
        new_day_task[event_def.cur_num] = 0                            --0
        new_day_task[event_def.is_reward] = event_def.not_reward       --未领奖
        local gold, exp = self:GetTaskReward(self.level, a_data.gold, a_data.exp)    
        new_day_task[event_def.gold] = gold
        new_day_task[event_def.exp] = exp
        self.day_task[id]= new_day_task
        self:AddTrigger(id, event_def.day_task_config)   --这个必须在上一句self.day_task[id]= new_day_task的之后，不然 finish的时候不会找到该数据

    end    
  end

    if self:hasClient() then
    self.client.day_task_change(0, self.day_task) --刷新给客户端
  end 

end

--能否接取该任务
function Avatar:can_get_day_task(a_data, id)
  if a_data then
        local min_level = a_data.level[1]
        local max_level = a_data.level[2]
        local min_viplevel = a_data.viplevel[1]
        local max_viplevel = a_data.viplevel[2]

        --验证等级
        if not (self.level >= min_level and self.level <=  max_level)   then
          return false
        end  
        --验证vip等级
        if not (self.VipLevel >= min_viplevel and self.VipLevel <=  max_viplevel) then
          return false 
        end  
        if self:has_same_group_id(id) then
          return false
        end

        if self.day_task[id] then
          if self.day_task[id][event_def.is_finish] == event_def.task_finish then  --今天做了该任务
              return false
          end
        end
        return true

  end   

end

--看是否有一样的groupid 的任务
function Avatar:has_same_group_id(id)

    local dt_data = g_eventData:GetData_DayTask()
    local my_group = dt_data[id].group

    for ing_id,data_ing in pairs(self.day_task) do
      local ing_group = dt_data[ing_id].group
      if ing_group == my_group then
          return true
      end
    end
    return false   
end



--每日活动领奖
function Avatar:get_reward_day_task(id)

  --log_game_debug("Avatar:get_reward_day_task Temp ", "taskid  = %s", id)  
  log_game_info("Avatar:get_reward_day_task", "dbid=%q;name=%s;taskid=%d",
        self.dbid, self.name, id)
  local ret = self:can_get_reward_day_task(id)
  if ret == event_def.error_code_successful  then
    local data  = g_eventData:GetData_DayTask()
    local  a_data = data[id]
    if a_data then 
        self.day_task[id][event_def.is_reward] = event_def.has_reward
        self:AddExp(self.day_task[id][event_def.exp], reason_def.day_task)
        self:AddGold(self.day_task[id][event_def.gold], reason_def.day_task)        
        
        if self:hasClient() then
            self.client.day_task_change(id, self.day_task[id])
        end 
    end    
  end 

  if self:hasClient() then
      self.client.get_reward_day_task_Resp(id, ret)
  end 

end

function Avatar:can_get_reward_day_task(id)

      if self.day_task[id] then
        if self.day_task[id][event_def.is_finish] ~= event_def.task_finish then
           return event_def.error_code_event_not_finish-- 还没有完成该任务
        end

        if self.day_task[id][event_def.is_reward] == event_def.has_reward then
           return event_def.error_code_event_rewarded-- 已经领过了。
        end

        return event_def.error_code_successful
      end

     return event_def.error_code_event_config_not_found-- 未找到对应的config
end


function Avatar:on_login_day_task()

  -- 获得当天日期 格式20130605 
  local now_date = global_data.GetCurDay()

  if self.last_daytask_date ~= now_date then

    self:reset_day_task() --不是同一天则重置
  else
      for id,v in pairs(self.day_task) do
          if v[event_def.is_finish] == event_def.task_not_finish then  -- 没完成的才加
            self:AddTrigger(id, event_def.day_task_config) 
          end     
      end
  end

end


--level=等级 gold=金钱系数 exp=经验系数
function Avatar:GetTaskReward(level, gold, exp)

  local __gold = 0
  local __exp = 0

  --经验奖励expReward=expStandard_i*exp_i/10000
  --金币奖励goldReward=goldStandard_i*gold_i/10000
  local cfgs = g_avatar_level_mgr:getCfg()
  if cfgs and cfgs[level] then
    local expStandard = cfgs[level].expStandard or 0
    local goldStandard = cfgs[level].goldStandard or 0
    local gold_i = gold or 0
    local exp_i = exp or 0

    __exp = math.floor( expStandard* exp_i/10000)
    __gold = math.floor( goldStandard * gold_i/10000)
  end

  return __gold, __exp
end



function Avatar:join_opens(event_table)

  local ret = {}
  for event_id,v in pairs(event_table) do
     local  bSuccess, result = self:join_event_from_eventmgr(event_table, event_id)
     ret[event_id] = result
  end


  local todays = self:GetTodayEvents()
  for event_id,v in pairs(ret) do
    if todays[event_id] then
      todays[event_id] = v
    end    
  end
  self.today_events = todays
  
  if self:hasClient() then
      self.client.get_event_ing_Resp(self.event_ing, self.today_events)
  end 

end

function Avatar:RefreshTask(event_table)
  self:join_opens(event_table)
end



function Avatar:GetTodayEvents()

  local ret = {}
  local data  = g_eventData:GetData()

  if data then
    for event_id, a_data in pairs(data) do
      if self:IsInDay(a_data) then
        ret[event_id] = 1 --没有条件
     end

    end
  end

  return ret
end

function Avatar:IsInDay(a_data)

  if a_data then
    if a_data.type == event_def.week_event then
        return global_data.GetCurTimeByFormat("%w") == tonumber(arg_3)
    else
        return true
    end
  end
  return false
end






--能否领取该礼包
function Avatar:CanGetBag(bag_id)    

    if self.received_bag[bag_id] == event_def.has_reward then
        return event_def.error_code_giftbag_already_received --该角色已经领取过该礼包
    end

    local data_bags = g_eventData:Get_gift_bag()

    if data_bags then
        if  data_bags[bag_id] then
            local cur_type = data_bags[bag_id].type
            for received_id,v in pairs(self.received_bag) do
              if data_bags[received_id] and data_bags[received_id].type then
                if data_bags[received_id].type == cur_type then
                  return event_def.error_code_giftbag_mutex --已经领取过互斥的包
                end
              end              
            end
            return event_def.error_code_successful  --成功
        end
    end

    return event_def.error_code_giftbag_cant_found  --找不到该礼包的配置 请检查
    
        --[[
        if data_bags[bag_id]  and data_bags[bag_id].mutex then
            for k,mutex_id in pairs(data_bags[bag_id].mutex ) do
                if self.received_bag[mutex_id] == event_def.has_reward then
                    return event_def.error_code_giftbag_mutex --已经领取过互斥的包
                end
            end
            return event_def.error_code_successful  --成功
        end
        ]]


end

function Avatar:AddGiftBag(bag_id, num)

     log_game_info("Avatar:AddGiftBag", "dbid=%q;name=%s;bag_id=%s",
        self.dbid, self.name, bag_id)    

     self:MyAddItem(bag_id,num, reason_def.serial_number_giftbag)

     self:ShowTextID(CHANNEL.TIPS, 1007006)

--[[
    local ret = self:CanGetBag(bag_id)
    if event_def.error_code_successful == ret then         
        self.received_bag[bag_id] = event_def.has_reward  --已经领取

        local data_bags = g_eventData:Get_gift_bag()
        if data_bags then
            if data_bags[bag_id]  then
                local items = data_bags[bag_id].items
                for i,v in pairs(items) do
                    self:MyAddItem(i,v, reason_def.serial_number_giftbag)
                end
            end                
        end
    end

    log_game_info("Avatar:AddGiftBag", "ret =%s",ret)   
    if self:hasClient() then
        self.client.AddGiftBagResp(bag_id, ret)
    end       
]]
end



function Avatar:On_ban_chat(var)

     log_game_info("Avatar:Online_ban_chat", "dbid=%q;name=%s;var=%s",
        self.dbid, self.name, t2s(var))    

     self:ban_chat(var.is_ban, var.ban_date, var.reason)
end

function Avatar:run_func(func_name, var)

     log_game_info("Avatar:run_func", "dbid=%q;name=%s;func_name=%s, var=%s",
        self.dbid, self.name, func_name, t2s(var))    

     if self[func_name] then
      self[func_name](self, var)
     end

end