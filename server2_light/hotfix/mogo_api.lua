local AVATAR_TYPE = 4

--枚举所有的玩家
function EnumAllAvatar(callback_function)
	print("Call EnumAllAvatar...")
	for k, obj in pairs(mogo_entities) do
		if obj:getEntityType() == AVATAR_TYPE then
	    	callback_function(obj)
		end
	end
end

--枚举指定的玩家
function EnumAvatar(avatar_eid, callback_function)
	if not avatar_eid or avatar_eid == 0 then return end

	print("Call EnumAvatar...")
	local avatarObj = mogo.getEntity(avatar_eid)
	if avatarObj and avatarObj:getEntityType() == AVATAR_TYPE then
		callback_function(avatarObj)
	else
		print("EnumAvatar False!")
	end
end

--枚举指定的实体
function EnumEntity(entity_eid, callback_function)
	if not entity_eid or entity_eid == 0 then return end
	
	print("Call EnumEntity...")
	local entityObj = mogo.getEntity(entity_eid)
	if entityObj then
		callback_function(entityObj)
	else
		print("EnumEntity False!")
	end
end































