--author:hwj
--date:2013-07-05
--此为ChineseData扩展类,只能在服务端使用, (用于为热更新准备的)

require "lua_util"

local ServerChineseData = {}
ServerChineseData.__index = ServerChineseData


function ServerChineseData:initData()
	-- ServerChineseData.xml
	self.data = lua_util._readXml("/data/xml/ServerChineseData.xml", "id_i")
end

function ServerChineseData:GetText(textId)
	local t = self.data[textId]
	if t then
		return t.content
	else
		return ''
	end
end

g_text_mgr = ServerChineseData
return g_text_mgr