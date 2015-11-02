--附魔
require "lua_util"
require "Item_data"
require "public_config"
require "role_data"
require "reason_def"
require "vip_privilege"
require "energy_data"
require "reason_def"


local log_game_debug = lua_util.log_game_debug
local log_game_info  = lua_util.log_game_info
local log_game_error = lua_util.log_game_error

local index_def =
{
	prop  = 1, --加的属性序号位
	value = 2,	--加的值序号位	
}


local VALUE_TYPE_INT = 1
local VALUE_TYPE_FLOAT = 2

local INDEX_PD_PROP_NAME = 1  --对应prop_def中的属性名
local INDEX_PD_VALUE_TYPE = 2  --对应prop_def中的属性类型




local ITEM_INSTANCE_GRIDINDEX    = public_config.ITEM_INSTANCE_GRIDINDEX --背包索引
local ITEM_INSTANCE_TYPEID    = public_config.ITEM_INSTANCE_TYPEID --道具id



Enchantment = {}
Enchantment.__index = Enchantment

local  EMT_REPLACE_INDEX = 0

local emt_def =
{
    successful = 0,          --成功
    error_id_not_found=1,    --未找到相应配置
    error_fumo_info_nil =2, --附魔信息不存在
    error_fumo_index_not_found=3, --未找到该部位的附魔信息
    error_pos_item_not_found = 4, -- 该部位没有道具
    error_cost_not_enough = 5, -- 材料不够
    error_no_job =6 , --没有未完成的附魔
    error_replace_index_nil = 7, --选择替换附魔的序号有误
    error_have_job = 8, --你有未完成的流程
    error_equip_cant_fumo =9 , --该装备不能附魔
    error_job_save_error =10 , --未完成流程数据有误
}

local prop_def=
{ 	--1 int 2float(会除以1000) 3 百分比(会除以1000)
		[1] =	{"hpBase",             VALUE_TYPE_INT},    --生命,
		[2] =	{"defenseBase",        VALUE_TYPE_INT},    --防御,
		[3] =	{"attackBase",         VALUE_TYPE_INT},    --伤害,
		[4] =	{"crit",               VALUE_TYPE_INT},    --暴击,
		[5] =	{"critExtraAttack",    VALUE_TYPE_INT},    --暴伤加成,
		[6] =	{"trueStrike",         VALUE_TYPE_INT},    --破击,
		[7] =	{"antiDefense",        VALUE_TYPE_INT},    --穿透,
		[8] =	{"pvpAddition",        VALUE_TYPE_INT},    --PVP强度,
		[9] =	{"pvpAnti",            VALUE_TYPE_INT},    --PVP抗性,

		[10] =	{"extraHitRate",       VALUE_TYPE_FLOAT},  --额外命中率,
		[11] =	{"antiCritRate",       VALUE_TYPE_FLOAT},  --抗暴击率,
		[12] =	{"antiTrueStrikeRate", VALUE_TYPE_FLOAT},  --抗破击率,

		[13] =	{"jewelPct",           VALUE_TYPE_FLOAT},  --该部位宝石属性百分比提升, --jewel percent
		[14] =	{"bPosiPct",           VALUE_TYPE_FLOAT},  --该部位强化属性百分比提升, --body position percent
		[15] =	{"levelPct",           VALUE_TYPE_FLOAT},  --等级属性百分比提升, --level percent
}



function Enchantment:fumo(avatar, body_pos)
	
	log_game_info("Enchantment:fumo", "dbid=%q;name=%s;body_pos=%s",
        avatar.dbid, avatar.name, body_pos)    

	local  ret, pos_item = self:can_fumo(avatar,body_pos)
	if ret == emt_def.successful then
		if pos_item then			
			local enchant = pos_item.enchant
			for item_id, fumo_num in pairs(enchant) do

				local item_data = g_itemdata_mgr:GetItem(public_config.ITEM_TYPE_CFG_TBL, item_id)

				local effect_id = item_data.effectId
				local prop_index, value = self:create_value(effect_id)

				if prop_index and value then
					local prop_name = prop_def[prop_index][INDEX_PD_PROP_NAME]
					local value_type = prop_def[prop_index][INDEX_PD_VALUE_TYPE]
					if value_type == VALUE_TYPE_FLOAT then											
						value = value/10000  --浮点除以1000
					end
					--local prop_name = prop_def[prop_index]	
					--看该位置是否有相同的	      
					local pos_fumoinfo = avatar.fumoinfo[body_pos]
					local same_index = self:HasSameProp(pos_fumoinfo, prop_index)
			        if same_index then
			        	--avatar.fumoinfo[index][same_index] = {prop_index, value}  --麻痹 直接替换
			        	pos_fumoinfo[EMT_REPLACE_INDEX] = {prop_index, value} --保存在EMT_REPLACE_INDEX位置 ，等待客户端选择是否替换
			        else
			       		if #pos_fumoinfo == fumo_num then  --达到最大数量 还要询问客户端，要保存 
			       			pos_fumoinfo[EMT_REPLACE_INDEX] = {prop_index, value}
			       		else
			       			table.insert(pos_fumoinfo, {prop_index, value})   
			       		end
		          	end			               
			        
			        log_game_info("Enchantment:fumo", "dbid=%q;name=%s;body_pos=%s fumo successfully",
        					avatar.dbid, avatar.name, body_pos) 
			        avatar:DelItem(item_id, 1, reason_def.fumo) --删除材料
			        avatar:triggerEvent(event_config.EVENT_AVATAR_PROPERTIES_RECALCULATE) --触发属性刷新
					if avatar:hasClient() then
					   avatar.client.GetFumoInfoResp(body_pos, pos_fumoinfo)  --通知客户端
					end	

				end
			end			
		end
	end
	
	if avatar:hasClient() then
		avatar.client.fumoResp(body_pos, ret)
	end	
end


function Enchantment:can_fumo(avatar, body_pos)

		local pos_item = self:get_item_by_index(avatar, body_pos) --该部位的道具数据

		if not pos_item then
			return emt_def.error_pos_item_not_found
		end

		local enchant = pos_item.enchant
		if not enchant then 
			return emt_def.error_equip_cant_fumo
		end

		for item_id, fumo_num in pairs(enchant) do
			local bOk = avatar.inventorySystem:HasEnoughItems(item_id,1) --只要一个
			if not bOk then
				return emt_def.error_cost_not_enough
			end
		end

		if not avatar.fumoinfo then	
			return emt_def.error_fumo_info_nil
		end		

		if not avatar.fumoinfo[body_pos] then
			avatar.fumoinfo[body_pos] = {}
		end
			
		if self:HasUnfinishJob(avatar,body_pos) then
			return emt_def.error_have_job  --有未完成的附魔流程
		end	

		return emt_def.successful, pos_item --成功才返回 位置的装备 

end



function Enchantment:get_item_by_index(avatar, index)

 	local bagDatas = avatar.equipeds or {}

 	for k,a_equip in pairs(bagDatas) do 		
 		if a_equip[ITEM_INSTANCE_GRIDINDEX] == index then
 			local equip_id = a_equip[ITEM_INSTANCE_TYPEID] 
 			if equip_id then 	
 				return g_itemdata_mgr:GetItem(public_config.ITEM_TYPE_CFG_TBL, equip_id)
 			end
 		end 		
 	end

 	return nil

end



function Enchantment:create_value(effect_id)
	
	local data_effect = g_fumodata:get_effect_data()
	local data_fumo_random = g_fumodata:get_fumo_random()
	if data_effect then
		local a_effect = data_effect[effect_id]
		if  a_effect then
			local prop_index = self:get_one(a_effect.prop_weight)
			local range_index = self:get_one(a_effect.range_weight)
			if prop_index  and range_index then
				if data_fumo_random[prop_index] and data_fumo_random[prop_index][range_index] then
          			local range = data_fumo_random[prop_index][range_index]
					local value = math.random(range.min, range.max)
					return  prop_index, value
				end
			end
		end
	end
	return nil
end


--tab:{index=weight,}
function Enchantment:get_one(tab)

	if not tab then
		return nil
	end

	local sum = 0
	for index , weight in pairs(tab) do
		sum = sum +	weight
	end
	if sum <= 0 then
		return nil
	end

	local random_num = math.random(0, sum-1)  --When called with a number m, math.random returns a pseudo-random integer in the range [1, m].
	local tmp = 0
	for index , weight in pairs(tab) do
		tmp = tmp + weight
		if tmp > random_num then
			return index
		end
	end

	return nil
end


function Enchantment:replace(avatar, body_pos, index)
	
	log_game_info("Enchantment:replace", "dbid=%q;name=%s;body_pos=%s, fumo_index=%s",
        avatar.dbid, avatar.name, body_pos, index)    

	local pos_fumoinfo = avatar.fumoinfo[body_pos]
	if not pos_fumoinfo then
		return emt_def.error_fumo_index_not_found
	end

	if not self:HasUnfinishJob(avatar, body_pos) then
		return emt_def.error_no_job
	end

	if not pos_fumoinfo[index] then	
		return emt_def.error_replace_index_nil
	end


	if index ~= EMT_REPLACE_INDEX then		--替换的位置为0 则是取消替换	 不为0 则是替换指定的位置	
		local prop = pos_fumoinfo[EMT_REPLACE_INDEX][index_def.prop]
		if not prop then
			return emt_def.error_job_save_error  --未完成流程数据有误
		end

		local same_index =  self:HasSameProp(pos_fumoinfo, prop)  --替换的时候看有没有相同的					
		if same_index then
			pos_fumoinfo[same_index] = pos_fumoinfo[EMT_REPLACE_INDEX] --替换相同的位置为保存的想			
		else
			pos_fumoinfo[index] = pos_fumoinfo[EMT_REPLACE_INDEX] --替换index的位置为保存的项
		end	
	end

	pos_fumoinfo[EMT_REPLACE_INDEX] = nil --消掉保存项				
    avatar:triggerEvent(event_config.EVENT_AVATAR_PROPERTIES_RECALCULATE) --触发属性刷新

    if avatar:hasClient() then
       avatar.client.GetFumoInfoResp(body_pos, pos_fumoinfo)  --通知客户端
    end	
	return emt_def.successful
end


-- 身上的body_pos位置 是否还有未完成的
function Enchantment:HasUnfinishJob(avatar, body_pos)

	local pos_fumoinfo = avatar.fumoinfo[body_pos]
	if pos_fumoinfo then
		if pos_fumoinfo[EMT_REPLACE_INDEX]  then
			return true
		else
			return false
		end
	else
		return false
	end	

end

-- 是否已经有相同的属性  返回对应的位置
function Enchantment:HasSameProp(pos_fumoinfo, prop)

	--序号从1开始
	for k,a_fumo in ipairs(pos_fumoinfo) do
		if a_fumo[index_def.prop] == prop then
			return k --
		end
	end

	return nil

end

-- 是否
function Enchantment:UpdateProps(pos_fumoinfo, equip_id)

		local ret = {}
		if pos_fumoinfo then			
			local pos_item = g_itemdata_mgr:GetItem(public_config.ITEM_TYPE_CFG_TBL, equip_id)--该部位的道具数据
			if pos_item then
				local enchant = pos_item.enchant
				if enchant then 
					for item_id, fumo_num in pairs(enchant) do
						local available_num = math.min(fumo_num, #pos_fumoinfo)	 --取生效的个数		
						for i=1, available_num do  --从1开始
							local a_fumo = pos_fumoinfo[i]
							local prop_index = a_fumo[index_def.prop] 
							local value 	 = a_fumo[index_def.value]	
							local prop_str   = prop_def[prop_index][INDEX_PD_PROP_NAME]	 --转换成字符串							
							ret[prop_str] = value					
						end					
						break
					end
				end
			end
		end

		return ret
end

--------------------------------------------------------
return Enchantment
