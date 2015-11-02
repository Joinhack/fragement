require "t2s"
require "lua_util"

-- 精灵系统、技能契约、元素刻印

--local log_game_info = lua_util.log_game_info
local log_game_debug = lua_util.log_game_debug
local _readXml = lua_util._readXml

local GMData = {}
GMData.__index = GMData

function GMData:initData()
    self.data = {}
--/base/SubSystem/GM
    local roleData = lua_util._readXml("/server_data/gm_data/role.xml", "name_s")
	local authorityData = lua_util._readXml("/server_data/gm_data/authority.xml", "name_s")
	local instructionData = lua_util._readXml("/server_data/gm_data/instruction.xml", "name_s")
	local Apis = lua_util._readXml("/server_data/gm_data/Api.xml", "name_s")
	
 
	
    --log_game_debug("GMData:initData", "roleData = %s",t2s(roleData)  ) 
    --log_game_debug("GMData:initData", "authorityData = %s",t2s(authorityData)  ) 
    --log_game_debug("GMData:initData", "instructionData = %s",t2s(instructionData)  ) 
	
	
	
	--[[roleData = lua_util._readXml2List("/base/SubSystem/GM/role.xml")
	authorityData = lua_util._readXml2List("/base/SubSystem/GM/authority.xml")
	instructionData = lua_util._readXml2List("/base/SubSystem/GM/instruction.xml")
	
	
	log_game_debug("GMData:initData", "roleData = %s",t2s(roleData)  ) 
    log_game_debug("GMData:initData", "authorityData = %s",t2s(authorityData)  ) 
    log_game_debug("GMData:initData", "instructionData = %s",t2s(instructionData)  ) 
	
	--]]
	
	
	self.data.roleData = self.format_role_data(roleData)  -- 组 账号
    self.data.authorityData = authorityData --组 命令
    self.data.instructionData = instructionData    --命令 用法
    self.data.Apis = Apis    --命令 用法
	
end


function GMData:GetGroupFlagByName(group)
	
		if self.data.roleData[group] then
		--log_game_debug("GMData:GetGroupFlagByName", " flag %s", t2s(self.data.roleData[group])) 
		return self.data.roleData[group].flag
	end
		
	return nil	

end

function GMData:GetGroupNameByFlag(flag)
		
	local data = self.data.roleData
    if data then		
		for k,v in pairs(data) do			
			if v.flag == flag  then				
				return k
			end
		end
    end		
	return nil	
end

function GMData:HasCommand(group, cmd)
	
		if self.data.authorityData[group] then
			
			if self.data.authorityData[group].instruction == "*" then --星号表示所有权限，优先判断
				return true
			end
			
			return self.data.authorityData[group][cmd] ~= nil
		end		
		return nil

end


function GMData.format_role_data(data)
		
		local resut = {}
		if data then
			for group,v in pairs(data) do
				resut[group] = {}
				if v.accounts then
					
					local tmp = string.gsub(v.accounts, "\t", "") --tab
					tmp = string.gsub(tmp, "\r\n", "")   --去回车
					tmp = string.gsub(tmp, " ", "")--去空格
					local split_douhao = lua_util.split_str(tmp, ",")
					for i,account in pairs(split_douhao) do	
            if account ~= "" then
              resut[group][account] = 1
            end 
					end	
				end						
			end			
			
		end		
		return resut

end



function GMData:IsGm(account)
	for grounp,accounts in pairs(self.data.roleData) do
		if accounts[account] then
			return true
		end
	end
	return false
end


g_GMData = GMData
return g_GMData
