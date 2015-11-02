require "lua_util"

local log_game_debug = lua_util.log_game_debug
local log_game_warning = lua_util.log_game_warning
local log_game_info = lua_util.log_game_info
local log_game_error = lua_util.log_game_error
local stopword_mgr = require "mgr_stopword"

local NameDataMgr = {}
NameDataMgr.__index = NameDataMgr

local Spliter = ''
local nameType = 
{
	occi_female = 1, --西方
    occi_male = 2, --西方
    cute = 3, --可爱
    orie_female = 4, --东方
    orie_male = 5, --东方
}

--[[
--性别
GENDER_FEMALE = 0,                 --性别:女
GENDER_MALE   = 1,                 --性别:男

VOC_WARRIOR   = 1,         -- 战士
VOC_ASSASSIN  = 2,         -- 刺客
VOC_ARCHER    = 3,         -- 弓箭手
VOC_MAGE      = 4,         -- 法师
]]
local vocation2Gender = 
{
	[public_config.VOC_WARRIOR] = public_config.GENDER_MALE,
	[public_config.VOC_ASSASSIN] = public_config.GENDER_FEMALE,
	[public_config.VOC_ARCHER] = public_config.GENDER_MALE,
	[public_config.VOC_MAGE] = public_config.GENDER_FEMALE,
}

local function CheckSame(a, b)
	for _,v1 in pairs(a) do
		for _,v2 in pairs(b) do
			if v1.name == v2.name then
				log_game_error("NameDataMgr:initData", "%s is mutiple.", v1.name)
			end
		end
	end
end

--读取配置数据
function NameDataMgr:initData()
    log_game_debug("NameDataMgr:initData", "")

    self.OccidentalLast  = lua_util._readXml("/data/xml/NameOccidentalLast.xml", "id_i")
    self.OccidentalFemale = lua_util._readXml("/data/xml/NameOccidentalFemale.xml", "id_i")
    self.OccidentalMale = lua_util._readXml("/data/xml/NameOccidentalMale.xml", "id_i")

    self.CuteFirst = lua_util._readXml("/data/xml/NameCuteFirst.xml", "id_i")
    self.CuteLast = lua_util._readXml("/data/xml/NameCuteLast.xml", "id_i")

    self.OrientalLast = lua_util._readXml("/data/xml/NameOrientalLast.xml", "id_i")
    self.OrientalFemale = lua_util._readXml("/data/xml/NameOrientalFemale.xml", "id_i")
    self.OrientalMale = lua_util._readXml("/data/xml/NameOrientalMale.xml", "id_i")

    self.occi_female = {} --西方
    self.occi_male = {} --西方
    self.cute = {} --可爱
    self.orie_female = {} --东方
    self.orie_male = {} --东方

    self.count = 0
    log_game_debug("NameDataMgr:initData", "over.")
end

function NameDataMgr:InitByDB(used_names)
	--组合名字
	--西方,姓在后
	for _,lastname in pairs(self.OccidentalLast) do
		--姓
		for _, femalename in pairs(self.OccidentalFemale) do
			--女名
			local name = femalename.name .. Spliter .. lastname.name
			if not used_names[name] then
				table.insert(self.occi_female, name)
				self.count = self.count + 1
			end
		end
		for _,malename in pairs(self.OccidentalMale) do
			--男名
			local name = malename.name .. Spliter .. lastname.name
			if not used_names[name] then
				table.insert(self.occi_male, name)
				self.count = self.count + 1
			end
		end
	end
	--可爱,姓在前
	for _,lastname in pairs(self.CuteLast) do
		--姓
		for _,firstname in pairs(self.CuteFirst) do
			--名
			local name = lastname.name .. Spliter .. firstname.name
			if not used_names[name] then
				table.insert(self.cute, name)
				self.count = self.count + 1
			end
		end
	end
	--东方,姓在前
	for _,lastname in pairs(self.OrientalLast) do
		--姓
		for _, femalename in pairs(self.OrientalFemale) do
			--女名
			local name = lastname.name .. Spliter .. femalename.name
			if not used_names[name] then
				table.insert(self.orie_female, name)
				self.count = self.count + 1
			end
		end
		for _,malename in pairs(self.OrientalMale) do
			--男名
			local name = lastname.name .. Spliter .. malename.name
			if not used_names[name] then
				table.insert(self.orie_male, name)
				self.count = self.count + 1
			end
		end
	end
	log_game_debug("NameDataMgr:InitByDB", self.count)
	if self.count == 0 then
		log_game_error("NameDataMgr:InitByDB", "name space is running out.")
	end
end

function NameDataMgr:ReleaseInitData()
	self.OccidentalLast  = nil
    self.OccidentalFemale = nil
    self.OccidentalMale = nil

    self.CuteFirst = nil
    self.CuteLast = nil

    self.OrientalLast = nil
    self.OrientalFemale = nil
    self.OrientalMale = nil
end

function NameDataMgr:GetRandom(t)
	local max = #t
	if max > 0 then
		local n = math.random(1, max)
		name = t[n]
		table.remove(t, n)
		self.count = self.count - 1
		return name
	end
	return nil
end

local ts = 1

function NameDataMgr:GetRandomName(vocation)
	if self.count == 0 then
		log_game_error("NameDataMgr:GetRandomName", "name space is running out.")
		return
	end
	local name = false
	local name_type = 0
	while not name do
		ts = ts + 1
		if ts < 1 then
			ts = 1
		elseif ts > 3 then
			ts = 1
		end
		if ts == 1 then
			--根据职业从ma_mc, fa_mc中取
			if vocation2Gender[vocation] == public_config.GENDER_MALE then
				name = self:GetRandom(self.occi_male)
				name_type = nameType.occi_male
				if name then break end
		    else
		    	name = self:GetRandom(self.occi_female)
		    	name_type = nameType.occi_female
		    	if name then break end
		    end
		elseif ts == 2 then
			--
			name = self:GetRandom(self.cute)
			name_type = nameType.cute
			if name then break end
		elseif ts == 3 then
			--根据职业从ma_mc, fa_mc中取
			if vocation2Gender[vocation] == public_config.GENDER_MALE then
				name = self:GetRandom(self.orie_male)
				name_type = nameType.orie_male
				if name then break end
		    else
		    	name = self:GetRandom(self.orie_female)
		    	name_type = nameType.orie_female
		    	if name then break end
		    end
		else
			log_game_error("NameDataMgr:GetRandomName", "")
		end
	end

	if name then
		return name, name_type
	else
		log_game_error("NameDataMgr:GetRandomName", "name is nil.")
	end
end

function NameDataMgr:BackToUnused(poolItem) --{name, ty}
	local name = poolItem[1]
	local ty = poolItem[2]
	--log_game_debug("NameDataMgr:BackToUnused", "name = %s, ty = %d", name, ty)
	if nameType.occi_female == ty then
		table.insert(self.occi_female, name)
	elseif nameType.occi_male == ty then
		table.insert(self.occi_male, name)
	elseif nameType.cute == ty then
		table.insert(self.cute, name)
	elseif nameType.orie_female == ty then
		table.insert(self.orie_female, name)
	elseif nameType.orie_male == ty then
		table.insert(self.orie_male, name)
	else
		return
	end
	self.count = self.count + 1
end

function NameDataMgr:random_n_names(n)
	local t = {}
	for i=1,n do
		local vocation = math.modf(i/2)
		local name = self:GetRandomName(vocation)
		if name then t[i] = name end
	end
	return t
end

function NameDataMgr:RecoverName(name)
	table.insert(self.cute, name)
end

g_name_mgr = NameDataMgr
return g_name_mgr