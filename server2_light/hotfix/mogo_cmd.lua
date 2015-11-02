print("mogo_cmd.lua is runing...");

--枚举所有Avatar的回调函数
function OnAllAvatar(avatar_obj)
	print("OnAllAvatar", avatar_obj)

	--测试代码
	print("Avatar eID:", avatar_obj:getId())

	--此处填入代码
end

--
function OnAvatar(avatar_obj)
	print("OnAvatar", avatar_obj)

	--测试代码
	print("Avatar eID:", avatar_obj:getId())

	--此处填入代码
end


--枚举指定的Avatar
local the_avatar_eid = nil
EnumAvatar(the_avatar_eid, OnAvatar)

--枚举所有Avatar
EnumAllAvatar(OnAllAvatar)


















