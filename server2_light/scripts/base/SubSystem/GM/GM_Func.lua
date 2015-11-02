
require "reason_def"
require "public_config"
require "state_config"
require "channel_config"

local globalbase_call = lua_util.globalbase_call
local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error

local gold_def =
{
	public_config.DIAMOND_ID,   -- 1元宝对应钻石
	public_config.GOLD_ID,	--2绑定元宝/金币  也是对应金币
	public_config.GOLD_ID,   -- 3铜币对应金币	
}

--改变自身属性（来自聊天框） 直接从avatar身上调即可。不需要经过UserMgr
function GMSystem:set_account(var, sys, id, stat)
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:SetAccount(sys, id, stat)
		end
	end
end

function GMSystem:add_gold(var, value)
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:AddGold(value, reason_def.gm)	
		end	
	end
end

function GMSystem:add_item(var, id, num)

	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:AddItem(id, num, reason_def.gm)
		end
	end		
end
function GMSystem:del_item(var, id, num)
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:DelItem(id, num, reason_def.gm)
		end
	end			
end

function GMSystem:add_diamond(var, value)
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:AddDiamond(value, reason_def.gm)
		end
	end		

end

function GMSystem:set_mission_finished(var, MissionId, difficulty, Star)
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:set_mission_finished(MissionId, difficulty, Star)
		end
	end		
	
end

function GMSystem:set_mission_times(var, MissionId, difficulty, times)
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:set_mission_times(MissionId, difficulty, times)
		end
	end	
end

function GMSystem:gotomission(var, MissionId, difficulty)
    local from = var[1]
    if from == "Avatar" then
        local avatar = var[2]
        if avatar then
            avatar:gotomission(MissionId, difficulty)
        end
    end
end

function GMSystem:finishmission(var, MissionId, difficulty)
    local from = var[1]
    if from == "Avatar" then
        local avatar = var[2]
        if avatar then
            avatar:finishmission(MissionId, difficulty)
        end
    end
end

function GMSystem:reset_mission(var)
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:reset_mission()
		end
	end			
end

function GMSystem:trigger_mwsy(var)
    local from = var[1]
    if from == "Avatar" then
        local avatar = var[2]
        if avatar then
            avatar:trigger_mwsy()
        end
    end
end

function GMSystem:add_level(var, value)
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:add_level(value)
		end
	end			
end


function GMSystem:hot_update(var, sysName)
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:hot_update(sysName)
		end
	end		
end

function GMSystem:query_prop(var, prop)
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:query_prop(prop)
		end
	end	
end

function GMSystem:set_prop(var, prop, value)
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:set_prop(prop, value)
		end
	end	
end

function GMSystem:set_tower_current_level(var, level)
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:set_tower_current_level(level)
		end
	end	
end

function GMSystem:set_tower_highest_level(var, level)
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:set_tower_highest_level(level)
		end
	end	
end

function GMSystem:start_tower_defence_match(var)
    local from = var[1]
    if from == "Avatar" then
        local avatar = var[2]
        if avatar then
            avatar:start_tower_defence_match()
        end
    end
end

function GMSystem:start_activity(var, id)
    local from = var[1]
    if from == "Avatar" then
        local avatar = var[2]
        if avatar then
            avatar:start_activity(id)
        end
    end
end

function GMSystem:stop_activity(var, id)
    local from = var[1]
    if from == "Avatar" then
        local avatar = var[2]
        if avatar then
            avatar:stop_activity(id)
        end
    end
end

--get_fight_force_parameters
function GMSystem:get_paras(var) 
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:GetFFP()
		end
	end
end
function GMSystem:load_rank(var, isGm)
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:GMRankList(isGm)
		end
	end
end
function GMSystem:open_event(var, event_id)
	globalbase_call("EventMgr", "open_event", event_id)		
end


function GMSystem:close_event(var, event_id)
	globalbase_call("EventMgr", "close_event", event_id)		
end



--非改变自身，需要经过UserMgr 或者其他系统
function GMSystem:add_gold_bydbid(dbid, value)	
	globalbase_call("UserMgr", "GMCall", accountName, dbid, "AddGold", value)
end


function GMSystem:sd_open(var, openTime, startTime, endTime)
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:sd_open(openTime, startTime, endTime)
		end
	end	
end


--var 为gm被调用的地方传来的参数
function GMSystem:kick_out(var, name)
    globalbase_call("UserMgr", "KickOut", name)
end

--var 为gm被调用的地方传来的参数
function GMSystem:forbid_login(var, name, seconds)
    mogo.forbidLogin(name, seconds)
end

--var 为gm被调用的地方传来的参数
function GMSystem:gm_mail(var, to, title, text, attach, dbid)  
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:gm_mail(to, title, text, attach, dbid)
		end
	end	

end

--var 为gm被调用的地方传来的参数
function GMSystem:gm_setting(var, systemName, arg)  
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:GmSet(systemName, arg)
		end
	end	

end

--var 为gm查看玩家的道具
function GMSystem:look_items(var, type)  
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:LookItems(tonumber(type))
		end
	end	

end
--var 为gm被调用的地方传来的参数
function GMSystem:get_info(var, dbid)  
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:get_info(dbid)
		end
	end	

end
--var 为gm被调用的地方传来的参数
function GMSystem:get_dbid(var, name)
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:get_dbid(name)
		end
	end	
end


--var 为gm被调用的地方传来的参数
function GMSystem:add_exp(var, value)
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:AddExp(value, reason_def.gm)
		end
	end	
end


function GMSystem:open_mission(var)
    local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
    	if avatar then
        	avatar.state = mogo.sset(avatar.state, state_config.STATE_MISSION_ALL_ALLOW)
        end
    end	
end

function GMSystem:open_gate(var)
    local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
    	if avatar then
			avatar.oblivionGateSystem:CreateGate()
		end
	end	
end

function GMSystem:reset_gate(var)
    local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
    	if avatar then
			avatar.oblivionGateSystem:ResetLastEnterTime()
		end
	end	
end

function GMSystem:reset_market(var)
    local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
    	if avatar then
			avatar.marketQuotaRecord = {}
		end
	end
    globalbase_call("GlobalDataMgr", "MgrEventDispatch", "", "EventClearMarketQuota", {}, "", "", {})
end

function GMSystem:task_over(var)

    local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
    	if avatar then
        	avatar.taskSystem:GMCurTaskComplete()
        end
    end
end

function GMSystem:add_buff(var, buff_id)
    local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
    	if avatar then
        	avatar.cell.AddBuffId(buff_id)
        end
    end
end

function GMSystem:remove_buff(var, buff_id)
    local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
    	if avatar then
	    	if not buff_id then buff_id = 0 end
        	avatar.cell.RemoveBuff(buff_id)
    	end
    end
end
function GMSystem:reset_dragon(var)
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:reset_dragon()
		end
	end
end

--var 为gm被调用的地方传来的参数
function GMSystem:send_sys_bulletin(var, msg_type, content)
--function GMSystem:send_sys_bulletin(var, msg_type, content)
	local from = var[1]
	if from == "SupportApi" then	

		local tmp_type = {CHANNEL.CHATDLG, CHANNEL.WORLD, CHANNEL.DLG}	--1表示聊天栏，2表示顶部滚动, 3弹窗。

		globalbase_call("UserMgr", "ShowTextID", tmp_type[msg_type] or CHANNEL.CHATDLG , 442 , {content})  --这里直接顶部滚动

		local client_fd = var[2]
		mogo.browserResponse(client_fd, "success") --返回给浏览器:成功
	elseif from == "Avatar" then
		globalbase_call("UserMgr", "ShowTextID", msg_type , 442 , {content})  --这里直接顶部滚动

	end
end


function GMSystem:user_info_detail(var, user_id, user_name, account)
--function GMSystem:send_sys_bulletin(var, msg_type, content)
	local from = var[1]
	if from == "SupportApi" then
		local client_fd = var[2]
		local my_user_id = user_id  -- 这里有可能传来个空字符串 没有转换成int 所以我自己转换一下
		if user_id == "" then
			my_user_id = -1
		end
		globalbase_call("Collector", "user_info_detail", client_fd, my_user_id, user_name, account)
	end
end


--[[
function GMSystem:forbid_login(var, account, is_forbid, forbid_time)
   	local from = var[1]
	if from == "SupportApi" then
		
		if is_forbid == 1 then
			mogo.forbidLogin(account, forbid_time) 
		else
			mogo.forbidLogin(account, 0) -- 0表示解禁
		end

		local client_fd = var[2]
		mogo.browserResponse(client_fd, "success") --返回给浏览器:成功
		
	end
end

function GMSystem:ip_ban(var, ip, is_forbid, forbid_time)
   	local from = var[1]
	if from == "SupportApi" then
		if is_forbid == 1 then
			mogo.forbidLoginByIp(ip, forbid_time) 
		else
			mogo.forbidLoginByIp(ip, 0)  -- 0表示解禁
		end
		local client_fd = var[2]
		mogo.browserResponse(client_fd, "success") --返回给浏览器:成功
	end
end
]]

function GMSystem:forbid_login(var, account, is_forbid, forbid_time)
   	local from = var[1]
	if from == "SupportApi" then
		
		local mm = globalBases["GlobalDataMgr"]

		mm.forbid_login(account, is_forbid, forbid_time)

		local client_fd = var[2]
		mogo.browserResponse(client_fd, "success") --返回给浏览器:成功
		
	end
end

function GMSystem:ip_ban(var, ip, is_forbid, forbid_time)
   	local from = var[1]
	if from == "SupportApi" then
		local mm = globalBases["GlobalDataMgr"]

		mm.ip_ban(ip, is_forbid, forbid_time)

		local client_fd = var[2]
		mogo.browserResponse(client_fd, "success") --返回给浏览器:成功
	end
end


--踢人接口  踢单个玩家下线或所有玩家下线。
function GMSystem:kick_user(var, user_names, kick_all, reason)
   	local from = var[1]
	if from == "SupportApi" then
		globalbase_call("UserMgr", "kick_user", user_names, kick_all)

		local client_fd = var[2]
		mogo.browserResponse(client_fd, "success") --返回给浏览器:成功
	end
end

--禁言 / 解禁
function GMSystem:ban_chat(var, user_names, is_ban, ban_date, reason)
   	local from = var[1]
	if from == "SupportApi" then
		globalbase_call("UserMgr", "ban_chat", user_names, is_ban, ban_date,reason or "")	

		local client_fd = var[2]
		mogo.browserResponse(client_fd, "success") --返回给浏览器:成功
	end
end



--complain_reply  GM回复玩家接口
function GMSystem:complain_reply(var, user_name,content,compain_id)
   	local from = var[1]
	if from == "SupportApi" then
		globalbase_call("UserMgr", "complain_reply", user_name,content,compain_id)

		local client_fd = var[2]
		mogo.browserResponse(client_fd, "success") --返回给浏览器:成功
		
	end
end


--complain_reply  GM回复玩家接口
function GMSystem:reset_user_pos(var, user_name)
   	local from = var[1]
	if from == "SupportApi" then
		--todo这里暂时没有接口 等待实现
		local client_fd = var[2]
		mogo.browserResponse(client_fd, "success") --返回给浏览器:成功
		
	end
end

--[[
--send_mail  给予符合条件的用户发送邮件。
function GMSystem:send_mail(var, action,user_names,user_ids,min_lv,max_lv,min_login_time,max_login_time,
							min_reg_time,max_reg_time,sex,career,guild,mail_title,mail_content,viptype,orderid)
   	local from = var[1]
   	local client_fd = var[2]

    if from == "SupportApi" then
      --self:sendtoonline(mail_title, mail_content) --这里先只发送给所有在线用户
      if action == 0 then   --发送给全服所有人
      	globalbase_call("MailMgr", "SendAll", mail_title, "system", mail_content, "system", os.time(), {})
      elseif action == 1  then -- 当action为1时，只对参数 user_names 和 user_ids 指定的用户发送。user_names 与 user_ids 只有其中一个值有效，另外一值为空 
  	  	if (user_names = "" and user_ids = "") or (user_names ~= "" and user_ids ~= "") then --不能同时为空 也不能同时都有
  	  		 mogo.browserResponse(client_fd, "param_error") --返回给浏览器:参数错误
  	  		 return 
  	  	end

  	  	local tab = {}

		tab.action = action
		tab.user_names = user_names
		tab.user_ids = user_ids
		tab.min_lv = min_lv
		tab.max_lv = max_lv
		tab.min_login_time = min_login_time
		tab.max_login_time = max_login_time
		tab.min_reg_time = min_reg_time
		tab.max_reg_time = max_reg_time
		tab.sex = sex
		tab.career = career
		tab.guild = guild
		tab.mail_title = mail_title
		tab.mail_content = mail_content
		tab.viptype = viptype
		tab.orderid = orderid


		globalbase_call("EventMgr", "AddOnlineOp", "Avatar:OnAddEmailOnline", tab)
    
  	  	
  	  	globalbase_call("MailMgr", "SendAll", mail_title, "system", mail_content, "system", os.time(), {})

  	  end 


      
      mogo.browserResponse(client_fd, "success") --返回给浏览器:成功
    end
end]]



--send_mail  给予符合条件的用户发送邮件。
function GMSystem:send_mail(var, action,user_names,user_ids,min_lv,max_lv,min_login_time,max_login_time,
							min_reg_time,max_reg_time,sex,career,guild,mail_title,mail_content,viptype,orderid)
   	local from = var[1]
   	local client_fd = var[2]

    if from == "SupportApi" then
    	self:__send(client_fd, action, user_names, user_ids, mail_title, mail_content, {})       --没有附件
    end
end

--admin_send_gift  --发带附件的邮件
function GMSystem:admin_send_gift(var, action,user_names,user_ids,min_lv,max_lv,min_login_time,max_login_time,
							min_reg_time,max_reg_time,sex,career,guild,mail_title,mail_content,
							money_amounts,
							money_types,
							item_ids,
							item_types,
							item_counts,
							item_levels,
							viptype,orderid)
   	local from = var[1]
   	local client_fd = var[2]

    if from == "SupportApi" then
    	local money_amounts_split 	= lua_util.split_str(money_amounts, ',', tonumber)
    	local money_types_split		= lua_util.split_str(money_types, ',', tonumber)
    	local item_ids_split 		= lua_util.split_str(item_ids, ',', tonumber)
    	local item_counts_split 	= lua_util.split_str(item_counts, ',', tonumber)

    	if (#money_amounts_split  == #money_types_split) and (#item_ids_split == #item_counts_split) then --个数要相等

    		local items ={}
    		for i,v in ipairs(money_amounts_split) do  -- 这里从1开始
	          local money_t = tonumber(money_types_split[i])
	          local count = tonumber(money_amounts_split[i])
				if money_t and  count then
					if money_t == 1 or money_t == 3 then  --只有元宝和铜币有效
						table.insert(items, gold_def[money_t], count)    
					end
					         
				end          
    			
    		end

    		for i,v in ipairs(item_ids_split) do  -- 这里从1开始
		          local item_id = tonumber(item_ids_split[i])
		          local count = tonumber(item_counts_split[i])
		          if item_id and  count then
		            table.insert(items, item_id, count)             
		          end      
		    			
    		end
    		--这里先构造items 附件列表
    		self:__send(client_fd, action, user_names, user_ids, mail_title, mail_content, items)      
      else
         mogo.browserResponse(client_fd, "param_error") --返回给浏览器:参数错误        
    	end    
    end

end




--send_mail  给予符合条件的用户发送道具。
function GMSystem:__send(client_fd, action, user_names, user_ids, mail_title, mail_content, items)
--self:sendtoonline(mail_title, mail_content) --这里先只发送给所有在线用户
      if action == 0 then   --发送给全服所有人
      		globalbase_call("MailMgr", "SendAllEx", mail_title, " ", mail_content, "system", os.time(), items or {}, reason_def.gm)
      elseif action == 1  then -- 当action为1时，只对参数 user_names 和 user_ids 指定的用户发送。user_names 与 user_ids 只有其中一个值有效，另外一值为空 
  	  		if (user_names == "" and user_ids == "") or (user_names ~= "" and user_ids ~= "") then --不能同时为空 也不能同时都有
  	  		 	mogo.browserResponse(client_fd, "param_error") --返回给浏览器:参数错误
  	  			return 
  	  		end
	  	  	if user_ids ~= "" then
				local to_dbids = {}
				local ids = lua_util.split_str(user_ids, ',')
				for i,str_dbid in ipairs(ids) do
					local dbid = tonumber(str_dbid)
					table.insert(to_dbids, dbid)
				end
	  	  		globalbase_call("MailMgr", "SendEx", mail_title, " ", mail_content, "System", os.time(), items or {}, to_dbids, reason_def.gm)
	  	  	else
	  	  		globalbase_call("UserMgr", "send_mail_by_names", user_names, mail_title or "", mail_content or "", items or {})
	  	  	end
  	  elseif action == 2  then
  	  		mogo.browserResponse(client_fd, "failed, not support condition send(action = 2)！！") --返回给浏览器:参数错误
  	  		return 
  	  elseif action == 3  then --给所有在线玩家
  	  		 globalbase_call("UserMgr", "send_mail_online",  mail_title or "", mail_content or "", items or {})
  	  end 
  	  mogo.browserResponse(client_fd, "success") --返回给浏览器:参数错误
  	  		
end


--var 为gm被调用的地方传来的参数
function GMSystem:add_arena_credit(var, value)
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:add_arena_credit(value, reason_def.gm)
		end
	end	
end

--var 为gm被调用的地方传来的参数
function GMSystem:add_arena_score(var, value)
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:add_arena_score(value, reason_def.gm)
		end
	end	
end

--var 为gm被调用的地方传来的参数
function GMSystem:foe(var, value)
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:foe(value, reason_def.gm)
		end
	end	
end


--var 为gm被调用的地方传来的参数
--加礼包
function GMSystem:add_giftbag(var, dbid, item_id)
	log_game_debug("GMSystem:add_giftbag", "dbid:%q : item_id %s", dbid, item_id)
   	local from = var[1]
	if from == "SupportApi" then
		globalbase_call("UserMgr", "AddGiftBag", dbid,item_id ,1)	
		local client_fd = var[2]
		log_game_debug("GMSystem:add_giftbag", "browserResponse :clien_fd: %s", clien_fd)
		mogo.browserResponse(client_fd, "success") --返回给浏览器:参数错误	
	end
end

function GMSystem:gm_compensate(var)
   	local from = var[1]
   	log_game_debug("GMSystem:gm_compensate", "")
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:gm_compensate()
		end
	end
end

--var 为gm被调用的地方传来的参数
--充值接口
function GMSystem:charge(var, plat, ...)
	log_game_debug("GMSystem:charge", "dbid:%s : item_id %s", dbid, item_id)
   	local from = var[1]
	if from == "SupportApi" then
		local client_fd = var[2]

		log_game_debug("GMSystem:charge", "callback_info: %s", callback_info)

		globalbase_call("UserMgr", "onChargeReq", client_fd, plat, {plat, ...})	 --这里充值暂时给个QQ群礼包供测试用， 等待文杰的接口
		
	end
end

function GMSystem:gm_charge(var,f,rmb)
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:gm_charge(f,rmb)
		end
	end
end

function GMSystem:gm_charge_ex(var,acc,dbid,rmb)
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:gm_charge_ex(acc,dbid,rmb)
		end
	end
end

function GMSystem:add_week_score(var,score)
	local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
		if avatar then
			avatar:add_week_score(score)
		end
	end
end

function GMSystem:open_pvp(var)
    local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
    	if avatar then
    		globalbase_call("DefensePvPMgr", "MgrEventDispatch", "", "EventGmOpen", {1}, "", "", {})
		end
	end	
end

function GMSystem:close_pvp(var)
    local from = var[1]
	if from == "Avatar" then
		local avatar = var[2]
    	if avatar then
    		globalbase_call("DefensePvPMgr", "MgrEventDispatch", "", "EventGmOpen", {0}, "", "", {})
		end
	end	
end