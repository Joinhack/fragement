--local p = {}
--setmetatable(p, {__index = _G})
--setfenv(1, p)

require "lua_util" 

local log_game_info = lua_util.log_game_info

local Mogo = require "BTNode"

------------------------
local AOI = Mogo.AI.ActionNode:new()

function AOI:new()
        local tmp = {}
        setmetatable(tmp, {__index = AOI})
        tmp.__index = tmp
        return tmp
end

function AOI:Proc(entity)
        --查找目标，记录到blackBoard
         --log_game_info("AI","AOI")
        local rnt = entity:ProcAOI()
        return rnt
end

-------------------------
local Stand = Mogo.AI.ActionNode:new()

function Stand:new()
        local tmp = {}
        setmetatable(tmp, {__index = Stand})
        tmp.__index = tmp
        return tmp
end

function Stand:Proc(entity)
        --站立
        return true
end

--------------------------
local ChooseCastPoint = Mogo.AI.ActionNode:new()

function ChooseCastPoint:new(skillId)
        local tmp = {_skillId = skillId}
        setmetatable(tmp, {__index = ChooseCastPoint})
        tmp.__index = tmp
        return tmp
end

function ChooseCastPoint:Proc(entity)
        --查找移动目标点，记录到blackBoard
        local rnt = entity:ProcChooseCastPoint(self._skillId)

        return rnt
end

-------------------------
local MoveTo = Mogo.AI.ActionNode:new()

function MoveTo:new()
        local tmp = {}
        setmetatable(tmp, {__index = MoveTo})
        tmp.__index = tmp
        return tmp
end

function MoveTo:Proc(entity)
        --调用移动方法
         --log_game_info("AI","MoveTo")
        local rnt = entity:ProcMoveTo()
        return true
end

------------------------
local Rest = Mogo.AI.ActionNode:new()

function Rest:new()
        local tmp = {}
        setmetatable(tmp, {__index = Rest})
        tmp.__index = tmp
        return tmp
end

function Rest:Proc(entity)
        --Sleep一段时间，用timeout解决(timeout一段时间后再次思考)
         --log_game_info("AI","Rest")
        local rnt = entity:ProcRest()
        return true
end

------------------------
local Think = Mogo.AI.ActionNode:new()

function Think:new()
        local tmp = {}
        setmetatable(tmp, {__index = Think})
        tmp.__index = tmp
        return tmp
end

function Think:Proc(entity)
        --异步调用（这里可用尾调用），进行一次思考
         --log_game_info("AI","Think")
        local rnt = entity:ProcThink()
        return true
end

--------------------------
local EnterThink = Mogo.AI.ActionNode:new()

function EnterThink:new()
        local tmp = {}
        setmetatable(tmp, {__index = EnterThink})
        tmp.__index = tmp
        return tmp
end

function EnterThink:Proc(entity)
         --log_game_info("AI","EnterThink")  
        entity.blackBoard:ChangeState(Mogo.AI.AIState.THINK_STATE)
        return true
end

--------------------------
local EnterPatrol = Mogo.AI.ActionNode:new()

function EnterPatrol:new()
        local tmp = {}
        setmetatable(tmp, {__index = EnterPatrol})
        tmp.__index = tmp
        return tmp
end

function EnterPatrol:Proc(entity)
         --log_game_info("AI","EnterPatrol")  
        entity.blackBoard:ChangeState(Mogo.AI.AIState.PATROL_STATE)
        return true
end

--------------------------
local EnterEscape = Mogo.AI.ActionNode:new()

function EnterEscape:new()
        local tmp = {}
        setmetatable(tmp, {__index = EnterEscape})
        tmp.__index = tmp
        return tmp
end

function EnterEscape:Proc(entity)
         --log_game_info("AI","EnterEscape")  
        entity.blackBoard:ChangeState(Mogo.AI.AIState.ESCAPE_STATE)
        return true
end

-------------------------
local EnterFight = Mogo.AI.ActionNode:new()

function EnterFight:new()
        local tmp = {}
        setmetatable(tmp, {__index = EnterFight})
        tmp.__index = tmp
        return tmp
end

function EnterFight:Proc(entity)
         --log_game_info("AI","EnterFight")  
        entity.blackBoard:ChangeState(Mogo.AI.AIState.FIGHT_STATE)
        return true
end

-----------------------
local EnterRest = Mogo.AI.ActionNode:new()

function EnterRest:new(sec)
        local tmp = {_sec = sec}
        setmetatable(tmp, {__index = EnterRest})
        tmp.__index = tmp
        return tmp
end

function EnterRest:Proc(entity)
        entity:ProcEnterRest(self._sec)
--        entity.blackBoard:ChangeState(Mogo.AI.AIState.REST_STATE):
--        entity.blackBoard.waitSec = self._sec
        return true
end

----------------------
local EnterCD = Mogo.AI.ActionNode:new()

function EnterCD:new(sec)
        local tmp = {_sec = sec}
        setmetatable(tmp, {__index = EnterCD})
        tmp.__index = tmp
        return tmp
end

function EnterCD:Proc(entity)

        entity:ProcEnterCD(self._sec)
        return true
end

----------------------
local CastSpell = Mogo.AI.ActionNode:new()

function CastSpell:new(skillId, reversal)
        local tmp = {_skillId = skillId, _reversal = reversal}
        setmetatable(tmp, {__index = CastSpell})
        tmp.__index = tmp
        return tmp
end

function CastSpell:Proc(entity)
        --调用使用技能，参数为blackBoard上的spellID
    --log_game_info("AI","CastSpell")  
        local rnt = entity:ProcCastSpell(self._skillId, self._reversal)
        return rnt
end

-----------------------
local Say = Mogo.AI.ActionNode:new()

function Say:new(content)
        local tmp = {_content = content}
        setmetatable(tmp, {__index = Say})
        tmp.__index = tmp
        return tmp
end

function Say:Proc(entity)
        --调用说话，参数为self._content
  --log_game_info("AI","Say")  
        local rnt = entity:ProcSay(self._content)
        return true 
end

--------------------------------
local CallTeammate = Mogo.AI.ActionNode:new()

function CallTeammate:new()
        local tmp = {}
        setmetatable(tmp, {__index = CallTeammate})
        tmp.__index = tmp
        return tmp
end

function CallTeammate:Proc(entity)
        --调用召唤队友
        return true
end


--------------------------------
local ReinitLastCast = Mogo.AI.ActionNode:new()

function ReinitLastCast:new()
        local tmp = {}
        setmetatable(tmp, {__index = ReinitLastCast})
        tmp.__index = tmp
        return tmp
end

function ReinitLastCast:Proc(entity)
        --调用跑动
         --log_game_info("AI","ReinitLastCast")  
        entity:ProcReinitLastCast()
        return true
end

--------------------------------
local Escape = Mogo.AI.ActionNode:new()

function Escape:new(sec)
        local tmp = {_sec = sec}
        setmetatable(tmp, {__index = Escape})
        tmp.__index = tmp
        return tmp
end

function Escape:Proc(entity)
--后端暂时木有实现
        return true
end
--------------------------------
local LookOn = Mogo.AI.ActionNode:new()

function LookOn:new(farAroundModeSpeedFactor, farModeIntervalMax, farModeIntervalMin, skillId)
        
        local tmp = {_farAroundModeSpeedFactor = farAroundModeSpeedFactor,
		     _farModeIntervalMax = farModeIntervalMax,
		     _farModeIntervalMin = farModeIntervalMin,
		     _skillId = skillId	}
        setmetatable(tmp, {__index = LookOn})
        tmp.__index = tmp
        return tmp
end

function LookOn:Proc(entity)
--后端暂时木有实现
        return true
end
--
Mogo.AI.AOI = AOI
Mogo.AI.CallTeammate = CallTeammate
Mogo.AI.CastSpell = CastSpell
Mogo.AI.ChooseCastPoint = ChooseCastPoint
Mogo.AI.EnterEscape = EnterEscape
Mogo.AI.EnterFight = EnterFight
Mogo.AI.EnterPatrol = EnterPatrol
Mogo.AI.EnterThink = EnterThink
Mogo.AI.EnterRest = EnterRest
Mogo.AI.EnterCD = EnterCD
Mogo.AI.MoveTo = MoveTo
Mogo.AI.Say = Say
Mogo.AI.Stand = Stand
Mogo.AI.Think = Think
Mogo.AI.Rest = Rest
Mogo.AI.ReinitLastCast = ReinitLastCast
Mogo.AI.Escape = Escape
Mogo.AI.LookOn = LookOn
