
require "lua_util"
require "GMData"
require "t2s"


local ret_error_cfg=
{
	GM_SUCCESSFUL = 0,
	GM_COMMAND_NOT_FOUNT = 1,
	GM_COMMAND_ACCOUNT_NOT_IN_GROUP = 2, --账户无该权限
	GM_COMMAND_NOT_GM = 3, --账户无该权限
	GM_COMMAND_TOO_SHORT = 4, --GM命令 太短
	GM_COMMAND_NOT_HAS_CMD = 5, --该组没有该cmd命令 
	GM_COMMAND_PARAM_FORMAT_ERROR = 6,	--参数格式错误
	GM_COMMAND_SU_GROUP_NOT_FOUND = 7, --提权组未找到
	GM_COMMAND_SU_YOU_NOT_IN_GROUP = 8, --账号不在该组内，提权失败	
	GM_COMMAND_DISPATCHER_NOT_FOUND	 = 9, --处理器未找到	

}

--local log_game_info = lua_util.log_game_info
local log_game_debug = lua_util.log_game_debug
local _readXml = lua_util._readXml
local globalbase_call = lua_util.globalbase_call

GMSystem = {}
--GMSystem.__index = GMSystem

require "GM_Func"


function GMSystem:Init()
	g_GMData:initData() --初始化数据
   	self.userGroup = {} --用来记录账号当前所使用的组
end




local function len_event(op)
  
    if type(op) == "table" then
           return #op              -- primitive table length
    end
end

local function unpack(t, i) 
	i = i or 1 
	if t[i] then
		return t [i], unpack(t, i + 1) 
	end 
end 


function GMSystem:IsAccountInGroup(account, group)

	if g_GMData.data.roleData[group] == nil then		
		log_game_debug("GMSystem:IsAccountInGroup", "group %s not found  ", group) 	
		return ret_error_cfg.GM_COMMAND_SU_GROUP_NOT_FOUND --提权组未找到		
	end
	
	if g_GMData.data.roleData[group][account] == nil then		 	
		log_game_debug("GMSystem:IsAccountInGroup", "account %s not found in group %s ", account, group) 	
		return ret_error_cfg.GM_COMMAND_SU_YOU_NOT_IN_GROUP --账号不在该组内，提权失败		
	end
	
	return ret_error_cfg.GM_SUCCESSFUL
end



function GMSystem:su(accountName,group)

	--todo: delete
	--log_game_debug("GMSystem:su", " su before  user=%s  userGroup= %s ", accountName,  t2s(self.userGroup))
	
	local retCode = self:IsAccountInGroup(accountName, group)
	
	log_game_debug("GMSystem:IsAccountInGroup", "error_ret = %d ", retCode) 	

	if ret_error_cfg.GM_SUCCESSFUL ~= retCode then			--用户不在该组内
		self.userGroup.accountName = nil  --删除
		log_game_debug("GMSystem:su", " su failed, Account %s Not in group %s  error code: %d", accountName, group, retCode) 	
		return retCode		
	end
	
	self.userGroup[accountName] = group		
	log_game_debug("GMSystem:su", " su success  user=%s  userGroup= %s ", accountName,  t2s(self.userGroup))
	return ret_error_cfg.GM_SUCCESSFUL
	
end

--GM命令为所有人共同使用， 一份拷贝即可，没有必要挂在avatar身上，avatar用传的

function GMSystem:excutCommandLine(accountName, cmdLine, var)
		
	-- 是否是su	
	log_game_debug("GMSystem:excutCommandLine", " cmdLine = %s ", t2s(cmdLine)) 
	
	local params = lua_util.split_str(cmdLine, " ", tostring)	
	
	log_game_debug("GMSystem:excutCommandLine", "name =%s .... params = %s ",accountName,cmdLine) 

	if len_event(params) < 1 then		
		log_game_debug("GMSystem:excutCommandLine", "cmdLine = %s error ", cmdLine) 
		return ret_error_cfg.GM_COMMAND_TOO_SHORT --GM命令 太短
	end
	local cmd = params[1]
	if "su" == cmd then	
		
		if len_event(params) < 2 then			
			log_game_debug("GMSystem:excutCommandLine", "cmdLine = %s error (su) ", cmdLine) 
			return ret_error_cfg.GM_COMMAND_TOO_SHORT --GM命令 太短			
		end	
		
		return self:su(accountName, tostring(params[2]))	 --提权			
	end
	
	local group = self.userGroup[accountName]
	
	log_game_debug("GMSystem:excutCommandLine", " U In Group %s ", t2s(group)) 
	--先检查权限
	
	if  group == nil then  --没有GM 权限 
		log_game_debug("GMSystem:excutCommandLine", " U are not GM(not in group ) ") 
		return ret_error_cfg.GM_COMMAND_NOT_GM		
	end
	
	if not g_GMData:HasCommand(group,cmd) then --没有执行该命令的权限
		log_game_debug("GMSystem:excutCommandLine", " Group %s NOT have the command  %s", group, cmd) 
		return ret_error_cfg.GM_COMMAND_NOT_HAS_CMD	--该组没有该cmd命令 
	end
	
	
	if not g_GMData.data.instructionData[cmd] then --检查命令库
		log_game_debug("GMSystem:excutCommandLine", " command (%s) not found in instruction.xml ",cmd ) 
		return ret_error_cfg.GM_COMMAND_NOT_HAS_CMD	--该组没有该cmd命令 		
	end
	
	
	local args = table.remove(params, 1) --删除命令 保留参数
	
	--log_game_debug("GMSystem:excutCommandLine", "before = %s \nafter = %s", t2s(params),(args)) 
	local ret, newParams = self:CheckFormat(g_GMData.data.instructionData[cmd].usage, params) --检查参数格式
	log_game_debug("GMSystem:excutCommandLine", " ret = %s", t2s(ret)) 
	if  ret ~= 0 then
		log_game_debug("GMSystem:excutCommandLine", " cmdline = %s Param format error! index = %d", cmdLine, ret) 
		return ret_error_cfg.GM_COMMAND_PARAM_FORMAT_ERROR	--参数格式错误
		
	end
	log_game_debug("GMSystem:excutCommandLine", "funcName = %s",g_GMData.data.instructionData[cmd].name) 

	--log_game_debug("GMSystem:excutCommandLine", "funcName = %s",t2s(funcSplit)) 
	--funcSplit[1][funcSplit[2]](newParams)
	--return Avatar[funcSplit[2]](self.theOwner, unpack(newParams))  --TODO 目前放到avat身上 ，
	
	--[[
	if not g_GMData.data.instructionData[cmd].dispatcher then
		log_game_debug("GMSystem:excutCommandLine", " funcName = %s Dispatcher NotFound",cmd) 
		return ret_error_cfg.GM_COMMAND_DISPATCHER_NOT_FOUND	--处理器未找到	
	end	
	]]
	-- log_game_debug("GMSystem:excutCommandLine", " funcName = %s Dispatcher = %s \n params =%s \n var = %s",cmd, g_GMData.data.instructionData[cmd].dispatcher, t2s(newParams), t2s(var)) 
	 --globalbase_call(g_GMData.data.instructionData[cmd].dispatcher, "GM_Dispacher", accountName, cmd, newParams, var)
	 self[cmd](accountName,var,table.unpack(newParams))
	 return ret_error_cfg.GM_SUCCESSFUL
end




function GMSystem:CheckFormat(usage, args)
		
	local cmd_lower =  string.lower(usage)	
	
	local usageParams = lua_util.split_str(cmd_lower, " ", tostring)
	table.remove(usageParams,1 ) --删掉函数
	log_game_debug("GMSystem:CheckFormat", "\nusage = %s \ninput = %s",t2s(usageParams), t2s(args)) 
	
	local inputParamsSize = len_event(args)
	local usageMaxSize = len_event(usageParams)
	local usageMinSize = self:GetMinSize(usageParams) --必须输入的参数个数（%s %d 的个数和）
	
	
	local newParams = {}	
	if(inputParamsSize > usageMaxSize or inputParamsSize <  usageMinSize) then  --输入的参数个数不能大于 usage个数，并且不能小于 必须输入的参数个数
		log_game_debug("GMSystem:CheckFormat", "inuputParams num=%d not in [%d, %d]",  inputParamsSize, usageMinSize, usageMaxSize) 
		return -1,newParams
	end
	
	local error_index = 0
		
	for i=1, inputParamsSize do	
		local usageValue = usageParams[i]
		local inputValue = args[i]
		if ("%d" == usageValue or "%od" == usageValue) then
						
			local value = tonumber(inputValue)
			if value == nil then				
				error_index = i		
				break	
			end
			table.insert(newParams,value)
									
		elseif ("%s" == usageValue or "%os" == usageValue)then
			local value = tostring(inputValue)
			if value == nil then				
				error_index = i
				break			
			end
			table.insert(newParams,value)		
		else
			log_game_debug("GMSystem:CheckFormat", "%s error in usage :%s ",usageValue,usage) 
			error_index = i --返回错误参数index
			break
		end
	end 
	log_game_debug("GMSystem:CheckFormat", "22ret (%s, %s)", t2s(error_index), t2s(newParams)) 
	return error_index,	newParams
end


function GMSystem:GetMinSize(args)
		local ret = 0
		for k,v in pairs(args) do			
			if v == "%d" or  v == "%s" then				
				ret = ret + 1
			end
		end
		return ret
end

function GMSystem:SupportApi(client_fd, cmd, params)

--[[
	if not g_GMData.data.instructionData[cmd].dispatcher then
		log_game_debug("GMSystem:SupportApi", " funcName = %s Dispatcher NotFound",cmd) 
		return ret_error_cfg.GM_COMMAND_DISPATCHER_NOT_FOUND	--处理器未找到	
	end	
	]]

	 --self[cmd](cmd,var,params)
	 local ret, result = self:GetUnpack(cmd, params)
	 if ret ~= 0 then
	 	log_game_debug("GMSystem:SupportApi", " GetUnpack error : %s %s", ret, t2s(result)) 

	 	mogo.browserResponse(client_fd, "param_error") --返回给浏览器:参数错误

	 	return  ret_error_cfg.GM_COMMAND_PARAM_FORMAT_ERROR ----参数格式错误
	 end
	 local var = {"SupportApi", client_fd}

	 if  self[cmd] == nil then
	 	 mogo.browserResponse(client_fd, "param_error") --返回给浏览器:成功
		 return ret_error_cfg.GM_COMMAND_PARAM_FORMAT_ERROR ----参数格式错误
	 end 

	local tmp = self[cmd](self,var,table.unpack(result))
	 --globalbase_call("Collector","Response",client_fd, "success")

	 --mogo.browserResponse(client_fd, "success") --返回给浏览器:成功
	 return ret_error_cfg.GM_SUCCESSFUL

end

function GMSystem:GetUnpack(cmd, params)	

	local  result  = {}
	if g_GMData.data.Apis[cmd] then
		local params_num = lua_util.get_table_real_count(g_GMData.data.Apis[cmd])
		for i=1,params_num do 
			local param_i = "param_" .. i
			if g_GMData.data.Apis[cmd][param_i] then
				local name = g_GMData.data.Apis[cmd][param_i].name
				local is_ness = g_GMData.data.Apis[cmd][param_i].is_ness
				local value_type = g_GMData.data.Apis[cmd][param_i].type

				if (is_ness == 1) and  params[name] == nil then
					return i,{"param must ness"}  --参数出错 必须的 这里却没有
				else
					if params[name] then
						if value_type == "int" and params[name] ~= "" then
							if tonumber(params[name]) then
							 	table.insert(result, tonumber(params[name]))
							else
								return i, {"format error"}  --参数转换错误
							end
						else
							table.insert(result, params[name])
						end
					end

				end
--			else
--				return i, {param_i} --找不到下个参数就返回了
			end 
		
		end

		return 0 , result
	end
end


--g_GMSystem = GMSystem
return GMSystem



