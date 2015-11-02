
--活动管理系统
require "eventData"
require "t2s"
require "Trigger"
require "event_def"
require "global_data"


local globalbase_call = lua_util.globalbase_call
local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error


local index_def =
{
	func_name_index = 1,  --方法名序号
	var_index = 2,	--变量名序号
}

EventMgr = {}
setmetatable(EventMgr, {__index = BaseEntity} )


--回调方法
local function _event_mgr_register_callback(eid)
    local mm_eid = eid
    local function __callback(ret)
        local gm = mogo.getEntity(mm_eid)
        if gm then
            if ret == 1 then
                --注册成功
                gm:on_registered()
            else
                --注册失败
                log_game_warning("EventMgr.registerGlobally error", '')
                --destroy方法未实现,todo
                --gm.destroy()
            end
        end
    end
    return __callback
end


function EventMgr:__ctor__()
    log_game_info('EventMgr:__ctor__', '')

 	
    --注册回调
    self:RegisterGlobally("EventMgr", _event_mgr_register_callback(self:getId()))
    --end

end





--注册globalbase成功后回调方法
function EventMgr:on_registered()
    log_game_info("EventMgr:on_registered", "")    
    self.funcTable = {}
    
    self.eventTable = {} --活动列表
	self.dateRec ={} --记录哪些已经触发  {[0]={[0]=是否触发，[1]=是否触发}...}
	self.lastCheckDay = 0
	self.lastCheckWeek = 8 --启动则是新的一周
	self.lastCheckMonth = 0 
	self.lastCheckYear = 0

	self:InitTable()
	self:ReFreshBillboard()

	--log_game_info("EventMgr:on_registered", "InitTable eventTable %s", t2s(self.eventTable))    

	--注册活动类型回调
	self.funcTable[event_def.forever_event] = EventMgr.foreverEvent
	self.funcTable[event_def.day_event] = EventMgr.dateEvent
	self.funcTable[event_def.week_event] = EventMgr.weekEvent
	self.funcTable[event_def.month_event] = EventMgr.monthEvent 
	self.funcTable[event_def.forever_event_in_time] = EventMgr.foreverEvent   --这个和永久活动一样
	self.funcTable[event_def.festivalEvent] = EventMgr.festivalEvent
	self.funcTable[event_def.festivalDayEvent] = EventMgr.festivalDayEvent
	self.funcTable[event_def.festivalWeekEvent] = EventMgr.festivalWeekEvent
	self.funcTable[event_def.serverEvent] = EventMgr.serverEvent
	self.funcTable[event_def.serverDayEvent] = EventMgr.serverDayEvent
	self.funcTable[event_def.serverWeekEvent] = EventMgr.serverWeekEvent
	


    local timerId= self:addTimer(event_def.eventHeartBeatDelay, event_def.eventHeartBeat, event_def.TIMER_ID_EVENT)

    globalbase_call('GameMgr', 'OnMgrLoaded', 'EventMgr')--表示自己已经注册完成

end


--定时器
function EventMgr:onTimer( timer_id, user_data )
	--log_game_info("EventMgr:onTimer", "into timer")  
	 if user_data == event_def.TIMER_ID_EVENT then
	 	 self:ReFresh() 
    end   
end



function EventMgr:InitTable()

	local data = g_eventData:GetData()
	for i,v in pairs(data) do
		self.eventTable[i] = event_def.switch_off  --初始都为0 
		self.dateRec[i] = {0,0}

		if event_def.forever_event == v.type  or event_def.forever_event_in_time == v.type then
			self.eventTable[i] = event_def.switch_on --永久活动则为1 表示一直开启 
		end
	end
end



--创建人物的时候数据初始化
function EventMgr:ReFresh()	
	local t = self:GetDateTable()

	self:CheckNewDate(t) --检查是不是新的一天
	local data = g_eventData:GetData()
	if data then		
		for k,v in pairs(data) do
			if self.funcTable[v.type] then				
				self.funcTable[v.type](self, v, t) --根据type解析对应的函数
			end
		end
	end
	
end


---t 格式 {year = 1998, month = 9, day = 16, yday = 259, wday = 4, hour = 23, min = 48, sec = 10, isdst = false}

function EventMgr:CheckNewDate(t)
	if tonumber(t.day) ~= tonumber(self.lastCheckDay)  then --新的一天 重置所有 日更新
--		log_game_debug("EventMgr:CheckNewDate", "new day !!!!! last :%s !=cur:%s", self.lastCheckDay , t.day)
		self.lastCheckDay = t.day
		self:update(event_def.daily_update)		
	end


	if tonumber(t.wday) < tonumber(self.lastCheckWeek) then --新的一周(星期发生变化的时候 则是新周了 周日更新) 重置周更新
--			log_game_debug("EventMgr:CheckNewDate", "new week !!!!! last :%s !=cur:%s", self.lastCheckWeek , t.wday)
			self.lastCheckWeek = t.wday	
			self:update(event_def.week_update)
				
		end

	if tonumber(t.month) ~= tonumber(self.lastCheckMonth) then 
--			log_game_debug("EventMgr:CheckNewDate", "new week !!!!! last :%s !=cur:%s", self.lastCheckWeek , t.wday)
			self.lastCheckMonth = t.month	
			self:update(event_def.month_update)
				
	end

	if tonumber(t.year) ~= tonumber(self.lastCheckYear) then --新的一年 重置年更新
--			log_game_debug("EventMgr:CheckNewDate", "new year !!!!! last :%s !=cur:%s", self.lastCheckYear , t.year)
			self.lastCheckYear = t.year
			self:update(event_def.year_update)					
	end

end


function EventMgr:update(update_type)
	
	local event_update_table = g_eventData:GetData_event_update_table()
	local  data = g_eventData:GetData()
	for i,v in pairs(data) do			
			if event_update_table[v.type] ==  update_type then

				local aDate = {0, 0} --新的一天/一周/一年 重置活动未开始 重置活动未结束	
				self.dateRec[i] = aDate	
			end		
	end		

end



--{event_id = 1...}
function EventMgr:GetEventTable()

	return self.eventTable
end



function EventMgr:join_event(event_id, mbStr)

	local mb = mogo.UnpickleBaseMailbox(mbStr)
    if mb then
    	local event_table = self:GetEventTable()
    	mb.join_event_from_eventmgr(event_table, event_id) --
    end

end


function EventMgr:EnterEvents(mbStr)

	local mb = mogo.UnpickleBaseMailbox(mbStr)
    if mb then
    	local event_table = self:GetEventTable()
        mb.EnterEvents(event_table)
    end    
end

function EventMgr:OnLevelUp(mbStr)

	local mb = mogo.UnpickleBaseMailbox(mbStr)
    if mb then
    	local event_table = self:GetEventTable()
        mb.RefreshTask(event_table)
    end    
end




function EventMgr:EventOpenList(mbStr)

	local mb = mogo.UnpickleBaseMailbox(mbStr)
    if mb then
    	local event_table = self:GetEventTable()
		local open_list = {}
		for i,v in pairs(event_table) do
			if event_def.switch_on == v then --活动开启
			  table.insert(open_list, i)    
			end
		end
        mb.client.EventOpenListResp(open_list)
    end    
end



-----------以下为事件类型回调函数---------


function EventMgr:foreverEvent(event)
	-- 永久活动不需要做任何操作 初始化已经ok	
end


--time_t {year = 1998, month = 9, day = 16, yday = 259, wday = 4, hour = 23, min = 48, sec = 10, isdst = false}
function EventMgr:dateEvent(event, time_t)

	local cur_time = string.format("%02d:%02d:%02d",  time_t.hour, time_t.min, time_t.sec)
	local _begin = event.arg_1
	local _end = event.arg_2

	self:cmp(event, cur_time, _begin, _end)	
end


--time_t {year = 1998, month = 9, day = 16, yday = 259, wday = 4, hour = 23, min = 48, sec = 10, isdst = false}
function EventMgr:weekEvent(event, time_t)

	local cur_week = time_t.wday - 1
	if cur_week == 0 then --0为星期天
		cur_week = 7
	end 

	local cur_time = string.format("%s:%02d:%02d:%02d", cur_week, time_t.hour, time_t.min, time_t.sec)
	local _begin = string.format("%s:%s", event.arg_3, event.arg_1)
	local _end = string.format("%s:%s", event.arg_4, event.arg_2)

	self:cmp(event, cur_time, _begin, _end)
	
end

function EventMgr:monthEvent(event, time_t)

	local cur_time = string.format("%02d:%02d:%02d:%02d", time_t.day , time_t.hour, time_t.min, time_t.sec)
	local _begin = string.format("%02d:%s", tonumber(event.arg_3), event.arg_1)
	local _end = string.format("%02d:%s", tonumber(event.arg_4),event.arg_2)

	self:cmp(event, cur_time, _begin, _end)	
end



--节日不循环活动		节日开始日期[07-01]	节日结束日期[07-07]
function EventMgr:festivalEvent(event, time_t)

	local cur_time = string.format("%02d-%02d", time_t.month , time_t.day)
	local _begin = event.arg_1
	local _end = event.arg_2
	self:cmp(event, cur_time, _begin, _end)	
end


--节日日循环活动	5	节日开始日期	节日结束日期	开始时间	结束时间	
function EventMgr:festivalDayEvent(event, time_t)	

	local _cur = string.format("%02d-%02d", time_t.month , time_t.day)
	local _min = event.arg_1
	local _max = event.arg_2
	if not self:IsBetween(_cur, _min, _max) then  --先判断是否在节日里面
		return 
	end


	local cur_time = string.format("%02d:%02d:%02d",  time_t.hour, time_t.min, time_t.sec)
	local _begin = event.arg_3
	local _end = event.arg_4

	self:cmp(event, cur_time, _begin, _end)	
	--self:dateEvent(event, time_t)

end

--节日周循环活动	6	节日开始日期	节日结束日期	周几开始	周几结束 开始时间		结束时间

function EventMgr:festivalWeekEvent(event, time_t)	

	local _cur = string.format("%02d-%02d", time_t.month , time_t.day)
	local _min = event.arg_1
	local _max = event.arg_2
	if not self:IsBetween(_cur, _min, _max) then  --先判断是否在节日里面
		return 
	end

	local cur_week = time_t.wday - 1
	if cur_week == 0 then --0为星期天
		cur_week = 7
	end 

	local cur_time = string.format("%s:%02d:%02d:%02d", cur_week, time_t.hour, time_t.min, time_t.sec)
	local _begin = string.format("%s:%s", event.arg_3, event.arg_5)
	local _end = string.format("%s:%s", event.arg_4, event.arg_6)

	self:cmp(event, cur_time, _begin, _end)

	--self:weekEvent(event, time_t)

end


--服务器不循环活动	10	开始服务器天数	结束服务器天数	
function EventMgr:serverEvent(event, time_t)

	local cur_time= global_data.GetCurDay()
	local _begin= global_data.GetDayAfterSeverStart(tonumber(event.arg_1))	
	local _end= global_data.GetDayAfterSeverStart(tonumber(event.arg_2))

	self:cmp(event, cur_time, _begin, _end)	

end



--服务器日循环活动	8	开始服务器天数	结束服务器天数	开始时间	结束时间	
function EventMgr:serverDayEvent(event, time_t)	

	local _cur= global_data.GetCurDay()
	local _min= global_data.GetDayAfterSeverStart(tonumber(event.arg_1))	
	local _max= global_data.GetDayAfterSeverStart(tonumber(event.arg_2))

	if not self:IsBetween(_cur, _min, _max) then
		return 
	end


	local cur_time = string.format("%02d:%02d:%02d",  time_t.hour, time_t.min, time_t.sec)
	local _begin = event.arg_3
	local _end = event.arg_4

	self:cmp(event, cur_time, _begin, _end)	
	--self:dateEvent(event, time_t)

end

--服务器周循环活动	9	1开始服务器天数	2结束服务器天数	3周几开始	4周几结束	5开始时间 6结束时间
function EventMgr:serverWeekEvent(event, time_t)	

	local _cur= global_data.GetCurDay()
	local _min= global_data.GetDayAfterSeverStart(tonumber(event.arg_1))
	local _max= global_data.GetDayAfterSeverStart(tonumber(event.arg_2))

	if not self:IsBetween(_cur, _min, _max) then
		return 
	end


	local cur_week = time_t.wday - 1
	if cur_week == 0 then --0为星期天
		cur_week = 7
	end 
	local cur_time = string.format("%s:%02d:%02d:%02d", cur_week, time_t.hour, time_t.min, time_t.sec)
	local _begin = string.format("%s:%s", event.arg_3, event.arg_5)
	local _end = string.format("%s:%s", event.arg_4, event.arg_6)

	self:cmp(event, cur_time, _begin, _end)
	
	--self:weekEvent(event, time_t)

end



function EventMgr:OpenEvent(event)
--		log_game_debug("EventMgr:dateEvent", "event(%s) open", event.id )

		self.dateRec[event.id][1] = 1 --设置活动开始已经触发
		self.eventTable[event.id] = event_def.switch_on --设置整个活动为开启状态
		self:triggerEvent(event_config.EVENT_EVENT_BEGIN, event.id) --EVENT_EVENT_BEGIN				   = 4, --活动开启{活动ID}
		--log_game_debug("EventMgr:dateEvent", "event_id = %s opened!!!!! \n dateRec = %s", event.id,t2s(self.dateRec))
		globalbase_call("UserMgr", "join_event", event.id)

end


function EventMgr:CloseEvent(event)
--		log_game_debug("EventMgr:dateEvent", "event(%s) close!!!", event.id )
		--log_game_debug("EventMgr:dateEvent", "curTime(%s)>=endTime(%s)", curTime, endTime )
		self.dateRec[event.id][2] = 1 --设置活动结束已经触发
		self.eventTable[event.id] = event_def.switch_off --设置整个活动为关闭状态
		self:triggerEvent(event_config.EVENT_EVENT_END, event.id) --EVENT_EVENT_END				   	   = 5, --活动结束{活动ID}
		--log_game_debug("EventMgr:dateEvent", "event_id = %s closed!!!! \n dateRec = %s", event.id, t2s(self.dateRec) )
		globalbase_call("UserMgr", "leave_event", event.id)
end


function EventMgr:open_event(event_id)
		local event = g_eventData:GetDataById(event_id)
		self:OpenEvent(event)

end


function EventMgr:close_event(event_id)
		local event = g_eventData:GetDataById(event_id)
		self:CloseEvent(event)
end



--刷新公告牌(可能要热更新)
function EventMgr:ReFreshBillboard()
	--self.data_billboard = lua_util._readXml("/server_data/billbord.xml", "id_i")  --公告牌

	self.data_sorry = lua_util._readXml("/server_data/sorry_gift.xml", "id_i")  --补偿
end


--公告牌
function EventMgr:Billboard(mbStr)
	
	--local mb = mogo.UnpickleBaseMailbox(mbStr)
    --if mb then
    	--mb.client.Billboard(self.data_billboard) -- 发送公告牌
    --end	
end


function EventMgr:sorry_gift(mbStr)
	
	local mb = mogo.UnpickleBaseMailbox(mbStr)
    if mb then
    	mb.get_sorry_gift(self.data_sorry)
    end	
end

function EventMgr:offline_mail(mbStr)
	
	local mb = mogo.UnpickleBaseMailbox(mbStr)
    if mb then
    	mb.get_offline_mail(self.data_sorry)
    end	
end

function EventMgr:OnPlayerEnterGame(mbStr)
	--self:Billboard(mbStr)  --发送公告牌  不再发送公告牌
	self:sorry_gift(mbStr)  --查询看有没有补偿，并且发送 补偿
	--self:offline_mail(mbStr) --
end






function EventMgr:cmp(event, curTime, beginTime, endTime)		

	--log_game_debug("EventMgr:cmp", "cur_time(%s), beginTime(%s), endTime(%s)", curTime, beginTime, endTime )
	if 1 ~= self.dateRec[event.id][1] then  -- 已经触发了 就不管
		if curTime >= beginTime then
			self:OpenEvent(event)
		end
	end

	if 1 ~= self.dateRec[event.id][2] then  -- 已经触发了 就不管
		if curTime >= endTime then
			self:CloseEvent(event)
		end 
	end
end



function EventMgr:IsBetween(v, min, max)	
	return  (v >= min and v <= max)
end

--"*t" {year = 1998, month = 9, day = 16, yday = 259, wday = 4, hour = 23, min = 48, sec = 10, isdst = false}
function EventMgr:GetDateTable()	
	return os.date("*t",os.time())
end




-- 1=to_one 2 =to_all
function EventMgr:add_online_action_to_one(role_name, func_name, var)	


	local tmp  = {}
	tmp[index_def.func_name_index] = func_name
	tmp[index_def.var_index] = var

	if  not self.to_one[role_name] then
		self.to_one[role_name] = {}
	end

	table.insert(self.to_one[role_name], tmp)         

end

function EventMgr:add_online_action_to_all(func_name, var)	

	local tmp  = {}
	tmp[index_def.func_name_index] = func_name
	tmp[index_def.var_index] = var

	if  not self.to_all then
		self.to_all = {}
	end

	table.insert(self.to_all, tmp)  
end



function EventMgr:online_action(role_name)	

	if self.to_one[role_name] then
		for k, action in pairs(self.to_one[role_name]) do
			local func_name = action[index_def.func_name_index]  --第一位为方法名
			local var = action[index_def.var_index]

			globalbase_call("UserMgr", "run_func", role_name, func_name, var)
			--mb[run_func](func_name, var)
			log_game_debug("EventMgr:online_action_to_one", "to one: role_name:%s func_name %s", role_name, func_name )

		end		
		self.to_one[role_name] = nil
	end


	if self.to_all then
		for k,action in pairs(self.to_all) do
			local func_name = action[index_def.func_name_index]  
			local var = action[index_def.var_index]
		
			globalbase_call("UserMgr", "run_func", role_name, func_name, var)
			--mb[run_func](func_name, var)
			log_game_debug("EventMgr:online_action_to_all", "to all: role_name:%s func_name %s", role_name, func_name )
			
		end
	end	
end


return EventMgr



