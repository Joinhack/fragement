

lua_map 		= {}
Lua_Map_Size	= {}

setmetatable(Lua_Map_Size, {__mode = "kv"})

--创建Map
function lua_map:new()
	local map_tab =	{}
	setmetatable(map_tab, {__index = lua_map})
	Lua_Map_Size[map_tab] = 0
	return map_tab
end

--克隆Map
function lua_map:clone()
	local map_tab = lua_map:new()

	for k, v in pairs(self) do
		map_tab:insert(k, v)
	end

	return map_tab
end

--获取首个key和value，若表为空则返回nil
function lua_map.begin(map_table)
	return map_table:next(nil)
end

--获取下一个key和value
function lua_map.next(map_table, key)
	local fun, tab = pairs(map_table)
	return fun(tab, key)
end

--向Map插入元素，返回是否成功，若key或value为nil则失败，若key元素已存在同样返回失败
function lua_map.insert(map_table, key, value)
	if not key or not value then return false end
	if map_table[key] then return false end

	map_table[key]			= value
	Lua_Map_Size[map_table] = Lua_Map_Size[map_table] + 1
	return true
end

--向Map更新或插入元素，返回是否成功，若key或value为nil则失败
function lua_map.replace(map_table, key, value)
	if (not key) or (not value) then return false end
	if not map_table[key] then Lua_Map_Size[map_table] = Lua_Map_Size[map_table] + 1 end
	map_table[key] = value
	return true
end

--删除Map中的元素，返回是否成功，若Map中不存在该key值元素则返回失败
function lua_map.erase(map_table, key)
	if not map_table[key] then return false end

	map_table[key]			= nil
	Lua_Map_Size[map_table] = Lua_Map_Size[map_table] - 1
	return true
end

--获取Map容器中元素的数量
function lua_map.size(map_table)
	return Lua_Map_Size[map_table]
end

--判断Map容器是否为空
function lua_map.empty(map_table)
	return (Lua_Map_Size[map_table] == 0)
end

--清空Map容器
function lua_map.clear(map_table)
	map_table = lua_map.new()
end

--查找Map中的元素，返回指定key的元素值
function lua_map.find(map_table, key)
	return map_table[key]
end

--单元测试
function lua_map_unit_test()
	local tab0 = lua_map:new()

	local tab1 = lua_map:new()
	tab1:insert(10, "a")
	tab1:insert(20, "b")
	tab1:insert(30, "c")

	local tab2 = lua_map:new()
	tab2:insert("a", 10)
	tab2:insert("b", 20)
	tab2:insert("c", 30)
	tab2:insert("d", 40)

	local tab3 = lua_map:new()
	tab3:insert("a", 10)
	tab3:insert("b", 20)
	tab3:insert(1, "a")
	tab3:insert(2, "b")
	tab3:insert(3, "c")
	tab3:insert({}, "x")
	tab3:insert({}, "y")

	print(#tab0, table.maxn(tab0), tab0:size(), tab0:empty())
	print("------------------------------------------------")

	for i,v in pairs(tab1) do
		print(i, v)
	end
	print("key=", 20, "value=", tab1:find(20))
	print(#tab1, table.maxn(tab1), tab1:size(), tab1:empty())
	print("------------------------------------------------")

	for i,v in pairs(tab2) do
		print(i, v)
	end
	print("key=", "a", "value=", tab2:find("a"))
	print(#tab2, table.maxn(tab2), tab2:size(), tab2:empty())
	print("------------------------------------------------")

	for i,v in pairs(tab3) do
		print(i, v)
	end
	print("key=", "30", "value=", tab3:find(30))
	print(#tab3, table.maxn(tab3), tab3:size(), tab3:empty())
	print("------------------------------------------------")

	k = {}
	tab3:insert(k, "z")
	if tab3:replace(k, {"z"}) == false then print("false1 !") return end
	print("key=", k, "value=", tab3:find(k))
	for i,v in pairs(tab3) do
		print(i, v)
	end
	print(#tab3, table.maxn(tab3), tab3:size(), tab3:empty())
	print("------------------------------------------------")

	if tab3:erase(3) == false then print("false2 !") return end
	if tab3:erase("b") == false then print("false3 !") return end
	if tab3:erase(k) == false then print("false4 !") return end
	for i,v in pairs(tab3) do
		print(i, v)
	end
	print("------------------------------------------------")

	print(#tab0, table.maxn(tab0), tab0:size(), tab0:empty())
	print(#tab1, table.maxn(tab1), tab1:size(), tab1:empty())
	print(#tab2, table.maxn(tab2), tab2:size(), tab2:empty())
	print(#tab3, table.maxn(tab3), tab3:size(), tab3:empty())
end





