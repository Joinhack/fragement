-- 技能计算


require "lua_util"
require "lua_map"
require "public_config"


local log_game_info             = lua_util.log_game_info
local log_game_debug            = lua_util.log_game_debug


--敌我阵营
Faction = 
{
	Friend	= 1,			--友方
	Enemy	= 2,			--敌方
}

--伤害类别
ATTACK_HARM_TYPE =
{
	MISS			= 1, 	--Miss
	NORMAL 			= 2, 	--普通伤害
	STRIKE 			= 3, 	--破击伤害
	CRITICAL 		= 4, 	--暴击伤害
	STRIKE_CRITICAL = 5, 	--同时破击和暴击伤害
}

--等级修正率
local VALUE_LEVEL_CORRECT		= 0.05

--最小等级修正率
local VALUE_MIN_LEVEL_CORRECT	= 0.1

--暴击增伤率
local VALUE_CRITICAL_ADD 		= 0.2


SkillCalculate = {}
SkillCalculate.__index = SkillCalculate


function SkillCalculate.GetAttr(theObj, attrName)
	return theObj.battleProps[attrName] or 0
end

--获取命中率
function SkillCalculate.GetHitRate(attacker, defender)
	local hitRate 	= SkillCalculate.GetAttr(attacker, "hitRate")
	local missRate 	= SkillCalculate.GetAttr(defender, "missRate")
	return hitRate - missRate
end

--获取破击率
function SkillCalculate.GetTrueStrikeRate(attacker, defender)
	local trueStrikeRate 		= SkillCalculate.GetAttr(attacker, "trueStrikeRate")
	local antiTrueStrikeRate	= SkillCalculate.GetAttr(defender, "antiTrueStrikeRate")
	return trueStrikeRate - antiTrueStrikeRate
end

--获取暴击率
function SkillCalculate.GetCritRate(attacker, defender)
	local critRate 		= SkillCalculate.GetAttr(attacker, "critRate")
	local antiCritRate 	= SkillCalculate.GetAttr(defender, "antiCritRate")
	return critRate - antiCritRate
end

function SkillCalculate.GetAtk(theObj)
	--获取角色伤害
	return SkillCalculate.GetAttr(theObj, "atk")
	--local attackBase 		= SkillCalculate.GetAttr(theObj, "attackBase")
	--local attackAddRate 	= SkillCalculate.GetAttr(theObj, "attackAddRate")
	--local attackAddition 	= SkillCalculate.GetAttr(theObj, "attackAddition")
	--return attackBase * (1 + attackAddRate / 10000) + attackAddition
end

function SkillCalculate.GetDef(theObj)
	--获取角色防御力
	return SkillCalculate.GetAttr(theObj, "def")
	--local defenseBase 		= SkillCalculate.GetAttr(theObj, "defenseBase")
	--local defenseAddRate 		= SkillCalculate.GetAttr(theObj, "defenseAddRate")
	--local defenseAddition 	= SkillCalculate.GetAttr(theObj, "defenseAddition")
	--return defenseBase * (1 + defenseAddRate / 10000) + defenseAddition
end

function SkillCalculate.GetDmgCorrect(attacker, defender)
	--获取伤害修正值（没发生破击时），已废弃
	return 0

	--local def 			= SkillCalculate.GetDef(defender)
	--local antiDefense	= SkillCalculate.GetAttr(attacker, "antiDefense")
	--local real_def 		= def - antiDefense
	--if real_def < 0 then real_def = 0 end

	--local levelPram4 	= SkillCalculate.GetAttr(attacker, "levelPram4")
	--local temp	   		= levelPram4 + real_def
	--if levelPram4 == 0 then return 0.1 end
	--if temp == 0 then return 1 end

	--return levelPram4 / temp
end

--获取PVP修正值
function SkillCalculate.GetPvPCorrect(attacker, defender)
	if (attacker.c_etype == public_config.ENTITY_TYPE_AVATAR and (defender.c_etype == public_config.ENTITY_TYPE_MERCENARY and defender.isPVP ~= 0)) or
	   (defender.c_etype == public_config.ENTITY_TYPE_AVATAR and (attacker.c_etype == public_config.ENTITY_TYPE_MERCENARY and attacker.isPVP ~= 0))
		then 
			local pvpAdditionRate	= SkillCalculate.GetAttr(attacker, "pvpAdditionRate")
			local pvpAntiRate		= SkillCalculate.GetAttr(defender, "pvpAntiRate")
			return (1 + pvpAdditionRate) * (1 - pvpAntiRate) * 0.4
    end
	return 1
end

--获取等级修正值
function SkillCalculate.GetLevelCorrect(attacker, defender)
	if attacker.c_etype == public_config.ENTITY_TYPE_MONSTER or
	   attacker.c_etype == public_config.ENTITY_TYPE_MERCENARY then return 1 end

	local lvDiffer = defender.level - attacker.level
	if lvDiffer <= 10 then return 1 end
	if lvDiffer > 10 and lvDiffer < 20 then return (1 - lvDiffer * VALUE_LEVEL_CORRECT) end
	return VALUE_MIN_LEVEL_CORRECT
end

function SkillCalculate.GetElemDamage(attacker, defender)
	if true then return 0 end

	local allElementsDamage		= SkillCalculate.GetAttr(attacker, "allElementsDamage")
	local allElementsDefense	= SkillCalculate.GetAttr(defender, "allElementsDefense")
	local all    				= allElementsDamage - allElementsDefense

	local earthDamage 	= SkillCalculate.GetAttr(attacker, "earthDamage")
	local earthDefense 	= SkillCalculate.GetAttr(defender, "earthDefense")
	local earth    		= earthDamage - earthDefense + all
	if earth < 0 then earth = 0 end

	local airDamage 	= SkillCalculate.GetAttr(attacker, "airDamage")
	local airDefense 	= SkillCalculate.GetAttr(defender, "airDefense")
	local air    		= airDamage - airDefense + all
	if air < 0 then air = 0 end

	local waterDamage 	= SkillCalculate.GetAttr(attacker, "waterDamage")
	local waterDefense 	= SkillCalculate.GetAttr(defender, "waterDefense")
	local water    		= waterDamage - waterDefense + all
	if water < 0 then water = 0 end

	local fireDamage 	= SkillCalculate.GetAttr(attacker, "fireDamage")
	local fireDefense 	= SkillCalculate.GetAttr(defender, "fireDefense")
	local fire    		= fireDamage - fireDefense + all
	if fire < 0 then fire = 0 end

	return earth + air + water + fire
end

function SkillCalculate.GetDamage(attacker, defender, skillMul, skillAdd)
	if math.random() > SkillCalculate.GetHitRate(attacker, defender) then return ATTACK_HARM_TYPE.MISS, 0 end

	skillMul				= skillMul or 0
	skillAdd				= skillAdd or 0
	local atk 				= SkillCalculate.GetAtk(attacker) --角色伤害值
	local dmgNormal			= atk * skillMul + skillAdd
	local elemDmg 			= SkillCalculate.GetElemDamage(attacker, defender)
	local pvpCorrect 		= SkillCalculate.GetPvPCorrect(attacker, defender)
	local lvCorrect			= SkillCalculate.GetLevelCorrect(attacker, defender)
	local damageReduceRate	= SkillCalculate.GetAttr(defender, "damageReduceRate")
	local tempRate			= (1 - damageReduceRate) * pvpCorrect * lvCorrect * (math.random(9000, 11000) / 10000)

	local mode, harm
	if math.random() <= SkillCalculate.GetCritRate(attacker, defender) then
		--暴击
		local critExtraAttack 	= SkillCalculate.GetAttr(attacker, "critExtraAttack")	--暴伤加成
		local antiDefenseRate 	= SkillCalculate.GetAttr(attacker, "antiDefenseRate")	--穿透率
		local defenceRate 		= SkillCalculate.GetAttr(defender, "defenceRate")		--防御减伤率
		harm 					= ((dmgNormal + atk * VALUE_CRITICAL_ADD + critExtraAttack) * (1 - defenceRate + antiDefenseRate) + elemDmg) * tempRate
		mode 					= ATTACK_HARM_TYPE.CRITICAL
	elseif math.random() <= SkillCalculate.GetTrueStrikeRate(attacker, defender) then
		--破击
		harm 					= (dmgNormal + elemDmg) * tempRate
		mode 					= ATTACK_HARM_TYPE.STRIKE
	else
		--普通伤害
		local antiDefenseRate 	= SkillCalculate.GetAttr(attacker, "antiDefenseRate")	--穿透率
		local defenceRate 		= SkillCalculate.GetAttr(defender, "defenceRate")		--防御减伤率
		harm 					= (dmgNormal * (1 - defenceRate + antiDefenseRate) + elemDmg) * tempRate
		mode 					= ATTACK_HARM_TYPE.NORMAL
	end
	harm = math.ceil(harm)
	if harm <= 1 then harm = 1 end

	--测试代码
	--harm = SkillCalculate.Debug_AvatarAttack(attacker, harm)

	return mode, harm
end

--测试代码，让玩家很厉害，返回伤害值
function SkillCalculate.Debug_AvatarAttack(attacker, harm)
	if attacker.c_etype == public_config.ENTITY_TYPE_AVATAR then
		--return 1
		return 100 * 1000 * 1000 * 1000
	elseif attacker.c_etype == public_config.ENTITY_TYPE_MONSTER then
		return 1
	else
		return 1
	end
	return harm
end

--获取敌我阵营
function SkillCalculate.GetFaction(entityA, entityB)
	--针对一般地图的情况
	--[[
	if entityA.c_etype == public_config.ENTITY_TYPE_AVATAR then
		if entityB.c_etype == public_config.ENTITY_TYPE_AVATAR then
			return Faction.Friend
		else
			return Faction.Enemy
		end
	else
		if entityB.c_etype == public_config.ENTITY_TYPE_AVATAR then
			return Faction.Enemy
		else
			return Faction.Friend
		end
	end
	--]]

	--针对PK地图的情况
	if entityA.factionFlag ~= entityB.factionFlag then
		return Faction.Enemy
	else
		return Faction.Friend
	end
end

--根据敌我阵营寻找有效目标（不包括自身）
function SkillCalculate.FindTargets(theOwner, faction)
    local aoi_targets 	= theOwner:getAOI(0)
    local targets 		= lua_map:new()
    for k, v in pairs(aoi_targets) do
    	--死亡状态判断
    	if v.IsDeath and v:IsDeath() ~= true then
    		--敌我阵营判断
    		if SkillCalculate.GetFaction(theOwner, v) == faction then
    			targets:insert(k, v)
    		end
    	end
    end
    return targets
end

--获取两点之间的距离
function SkillCalculate.GetDistance(x1, y1, x2, y2)
    if not x1 or not y1 or not x2 or not y2 then return 0 end

    local h = y2 - y1
    local w = x2 - x1

    return math.sqrt(h^2 + w^2)
end

--判断entityB是否在以entityA为原点的扇形区域内
function SkillCalculate.TestInSector(x1, y1, face1, x2, y2, radius, angle)
    if not x1 or not y1 or not x2 or not y2 or not face1 then return false end

    local h = y2 - y1
    local w = x2 - x1
    local r	= math.sqrt(h^2 + w^2)

    --判断半径是否超出范围
    if r > radius then return false end

    --求射线AB的弧度
    local radianAB
    if w > 0 then
    	radianAB = math.atan(h / w)
    elseif w < 0 then
    	radianAB = math.atan(h / w) + math.pi
    else
    	if h > 0 then
    		radianAB = math.pi / 2
    	elseif h < 0 then
    		radianAB = -math.pi / 2
    	else
    		return true
    	end
    end
    --确保射线AB的弧度在第一圆周周期内
    if radianAB < 0 then radianAB = radianAB + 2 * math.pi end

    ----face1				= face1 * 2 						--转换成真实角度
    --face1 				= ((450 - face1) % 360) 			--调整角度的旋转方向为逆时针，相对于Y+轴为0度
    --local theRadian		= face1 * math.pi / 180				--转换成弧度
    local theRadian		= SkillCalculate.Direction_GameToWorld(face1)
    angle 				= angle % 360						--注意：Lua语言对负数求余会取其正补数（例如：-7%3=2）,与C++不一样。
    local half_radian 	= (angle * math.pi / 180) / 2		--转换成弧度并除以2
    local maxRadian		= theRadian + half_radian
    local minRadian		= theRadian - half_radian

    --确保最小弧度和最大弧度落在第一或第二圆周周期内
    if minRadian < 0 then
    	maxRadian = maxRadian + 2 * math.pi
    	minRadian = minRadian + 2 * math.pi
    end

    if radianAB >= minRadian and radianAB <= maxRadian then
    	return true
    else
    	radianAB = radianAB + 2 * math.pi
    	if radianAB >= minRadian and radianAB <= maxRadian then
    		return true
    	else
    		return false
    	end
    end
end

--判断entityB是否在以entityA为原点的直线区域内
function SkillCalculate.TestInRectangle(x1, y1, face1, x2, y2, radius, width)
    if not x1 or not y1 or not x2 or not y2 or not face1 then return nil end

    --调整角度的旋转方向为逆时针
    --face1 = ((450 - face1 * 2) % 360) / 2
    --local theRadian = face1 * math.pi / 90			--Face转换成弧度，注意：（Face*2）才是真正面向角度

    local theRadian	= SkillCalculate.Direction_GameToWorld(face1)
    theRadian = math.pi / 2 - theRadian 				--与正向Y轴的弧度差

    --计算相对（x1，y1）的坐标
    local dy = y2 - y1
    local dx = x2 - x1

    --坐标旋转
    local x = dx * math.cos(theRadian) - dy * math.sin(theRadian)
    local y = dy * math.cos(theRadian) + dx * math.sin(theRadian)

    local half_width = width / 2
    if x < -half_width or x > half_width then return false end
    if y < 0 or y > radius then return false end

    return true
end

--获取指定点（x, y）前方指定距离（distance）的坐标
function SkillCalculate.GetFrontPosition(x, y, face, distance)
    if not x or not y or not face or not distance then return nil end

    --face				= face * 2 						--转换成真实角度
    --face 				= ((450 - face) % 360) 			--调整角度的旋转方向为逆时针，相对于Y+轴为0度
    --local theRadian	= face * math.pi / 180			--转换成弧度
    local theRadian		= SkillCalculate.Direction_GameToWorld(face)

    x = x + distance * math.cos(theRadian)
    y = y + distance * math.sin(theRadian)

    return x, y
end

--获取指定点（x, y）是否在指定的矩形区域内（x1, y1, x2, y2）
function SkillCalculate.TestInWorldRectangle(x, y, x1, y1, x2, y2)
	if x1 > x2 then
		local tmp 	= x1
		x1 			= x2
		x2 			= tmp
	end
	if y1 > y2 then
		local tmp 	= y1
		y1 			= y2
		y2 			= tmp
	end

	if x < x1 then return false end
	if x > x2 then return false end
	if y < y1 then return false end
	if y > y2 then return false end

	return true
end

function SkillCalculate.GetRelatePostion(entityA, entityB, radius)
	--取相对位移，以entityA到entityB的射线距离加上radius值，用于位移技能计算
    local x1, y1 = entityA:getXY()
    local x2, y2 = entityB:getXY()
    if not x1 or not y1 or not x2 or not y2 then return nil end

    local h = y2 - y1
    local w = x2 - x1
    local r	= math.sqrt(h^2 + w^2)


end

function SkillCalculate.GetInflatePostion(entityA, entityB, radius)
	if not radius or radius < 0 then return nil end

    local x1, y1 = entityA:getXY()
    local x2, y2 = entityB:getXY()
    if not x1 or not y1 or not x2 or not y2 then return nil end

    local h = y2 - y1
    local w = x2 - x1
    local r	= math.sqrt(h^2 + w^2)
    if r == 0 then return nil end
    local R = r + radius

    return (R * w / r + x1), (R * h / r + y1)
end

function SkillCalculate.GetDeflatePostion(entityA, entityB)
	--取相对位移，以entityA和entityB为射线，长度为100厘米的位置
    local x1, y1 = entityA:getXY()
    local x2, y2 = entityB:getXY()
    if not x1 or not y1 or not x2 or not y2 then return nil end

    local R = 100
    local h = y2 - y1
    local w = x2 - x1
    local r	= math.sqrt(h^2 + w^2)
    if r <= R then return nil end

    return (R * w / r + x1), (R * h / r + y1)
end

--把世界逻辑方向（标准笛卡尔坐标系）转换成游戏朝向，并把弧度转换成角度
function SkillCalculate.Direction_WorldToGame(radius)
	local face 	= radius * 180 / math.pi 				--转换成角度
    face 		= ((450 - face) % 360) 					--转换成游戏朝向
    return face
end

--把游戏朝向转换成世界逻辑方向（标准笛卡尔坐标系），并把角度转换成弧度
function SkillCalculate.Direction_GameToWorld(face)
    face 				= ((450 - face) % 360) 			--调整角度的旋转方向为逆时针，相对于Y+轴为0度
    local theRadian		= face * math.pi / 180			--转换成弧度
    return theRadian
end

--相对坐标轴原点的旋转
function SkillCalculate.Rotate(x, y, radius)
    x = x * math.cos(radius) - y * math.sin(radius)
    y = y * math.cos(radius) + x * math.sin(radius)
    return x, y
end

--计算矢量点（x1, y1, face1）移动后的坐标，其中a为矢量坐标系的正X轴向距离，b为矢量坐标系的正Y轴向距离
--（矢量坐标系是指以矢量点为原点的平面坐标系，其正Y轴向与矢量方向重合）
function SkillCalculate.Offset(x1, y1, face1, a, b)
	local theRadius
	if a == 0 then
		if b > 0 then
			theRadius = math.pi / 2
		elseif b < 0 then 
			theRadius = 3 * math.pi / 2
		else
			return x1, y1
		end
	else
		theRadius = 2 * math.pi + math.atan(b / a)
	end
	local faceRadius = SkillCalculate.Direction_GameToWorld(face1)
	theRadius = (2 * math.pi + theRadius + faceRadius - (math.pi / 2)) % (2 * math.pi)

	local a1, b1 = SkillCalculate.Rotate(a, b, theRadius)
	return x1 + b1, y1 - a1
end



