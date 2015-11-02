
require "event_def"
require "eventData"
require "Trigger"
require "global_data"
require "reason_def"
require "channel_config"
require "public_config"
require "Enchantment"





local globalbase_call     = lua_util.globalbase_call
local log_game_debug      = lua_util.log_game_debug
local log_game_info       = lua_util.log_game_info
local log_game_warning    = lua_util.log_game_warning
local log_game_error      = lua_util.log_game_error



--完成副本 fb_id=副本id
function Avatar:GetFumoInfo(body_pos)

  if body_pos == 0 then
     if self:hasClient() then
        self.client.GetFumoInfoResp(body_pos, self.fumoinfo)  --返回所有
      end
  else
      if self:hasClient() then
        self.client.GetFumoInfoResp(body_pos, self.fumoinfo[body_pos]) 
      end
     
  end
 
end

function Avatar:fumo(body_pos)
  Enchantment:fumo(self, body_pos) 
end

function Avatar:fumo_replace(body_pos, index)
  local ret = Enchantment:replace(self, body_pos , index) 

  if self:hasClient() then
    self.client.fumo_replaceResp(body_pos, index, ret)
  end  

end


function Avatar:GetFumoAddProps(body_pos)

  local info = Enchantment:UpdateProps(self, body_pos)
  return info
end


function Avatar:GetAllFumoProps()
  local  ret = {}
  local bagDatas = self.equipeds or {}

  for k,a_equip in pairs(bagDatas) do  
    local body_pos = a_equip[ITEM_INSTANCE_GRIDINDEX]
    local info = Enchantment:UpdateProps(self, body_pos)
    ret[body_pos] = info
  end
end






