

--table转字符串(只取标准写法，以防止因系统的遍历次序导致ID乱序)

function t2s(obj)
	local lua = ""
	local t = type(obj)
	if t == "number" then
		lua = lua .. obj
	elseif t == "boolean" then
		lua = lua .. tostring(obj)
	elseif t == "string" then
		lua = lua .. string.format("%q", obj)
	elseif t == "table" then
		lua = lua .. "{\n"
		for k, v in pairs(obj) do
			lua = lua .. "[" .. t2s(k) .. "]=" .. t2s(v) .. ",\n"
		end
		local metatable = getmetatable(obj)
		if metatable ~= nil and type(metatable.__index) == "table" then
			for k, v in pairs(metatable.__index) do
				lua = lua .. "[" .. t2s(k) .. "]=" .. t2s(v) .. ",\n"
			end
		end
		lua = lua .. "}"
	elseif t == "nil" then
		return nil
	elseif t == "function" then
		return lua .. "function"
	else
		error("can not t2s a " .. t .. " type.")
	end
	return lua
end

function lua2json(obj)
	local lua = ""
	local t = type(obj)
	if t == "number" then
		lua = lua .. obj
	elseif t == "boolean" then
		lua = lua .. tostring(obj)
	elseif t == "string" then
		lua = lua .. string.format("%s", obj)
	elseif t == "table" then
		lua = lua .. "{\n"
		for k, v in pairs(obj) do
			local v_type = type(v)
			if v_type == "table" then
				lua = lua .. string.format("%s,\n", lua2json(v)) --不需要输出key
			else
				lua = lua .. string.format("%s:%s,\n", lua2json(k),lua2json(v))
			end			
		end
		lua = lua .. "}"
	elseif t == "nil" then
		return nil
	elseif t == "function" then
		return lua .. "function"
	else
		error("can not lua2json a " .. t .. " type.")
	end
	return lua
end

function lua2json_qs(obj)
	local lua = ""
	local t = type(obj)
	if t == "number" then
		lua = lua .. obj
	elseif t == "boolean" then
		lua = lua .. tostring(obj)
	elseif t == "string" then
		lua = lua .. string.format("%q", obj)
	elseif t == "table" then
		lua = lua .. "{\n"
		for k, v in pairs(obj) do
			local v_type = type(v)
			if v_type == "table" then
				lua = lua .. string.format("%s,\n", lua2json_qs(v)) --不需要输出key
			else
				lua = lua .. string.format("%q:%s,\n", lua2json_qs(k),lua2json_qs(v))
			end			
		end
		lua = lua .. "}"
	elseif t == "nil" then
		return nil
	elseif t == "function" then
		return lua .. "function"
	else
		error("can not lua2json_qs a " .. t .. " type.")
	end
	return lua
end




function formatjson(obj)
	local lua = ""
	local t = type(obj)
	if t == "table" then
		lua = lua .. "{\n"
		for k, v in pairs(obj) do
			local v_type = type(v)
			if v_type == "table" then
				lua = lua .. string.format("%s,\n", lua2json_array(v)) --不需要输出key
			else
				lua = lua .. string.format("%q:%s,\n", lua2json_array(k),lua2json_array(v))
			end			
		end
		lua = lua .. "}"
	elseif t == "nil" then
		return nil
	elseif t == "function" then
		return lua .. "function"
	else
		error("can not lua2json_array a " .. t .. " type.")
	end
	return lua
end



function data2json(obj)	
	local lua = ""
	local t_fa = type(obj)

	if t_fa == "table" then
		 for index, tab in pairs(obj) do	
		 	local t_son = type(tab)
			if t_son == "table" then
				lua = lua .. "{\n"
				for k, v in pairs(tab) do
					lua = lua .. string.format("%q:%q,\n", k, v)	
				end
				lua = lua .. "},"			
			end
		end
	end

	if #obj > 1 then
		lua = "["..lua.."]"  --数组
	end

	return lua
end