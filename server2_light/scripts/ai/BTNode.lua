--local p = {}
--setmetatable(p, {__index = _G})
--setfenv(1, p)

require "lua_util"
local log_game_info = lua_util.log_game_info

----AIState Class -----
local AIState = {}
AIState.THINK_STATE = 1
AIState.REST_STATE = 2
AIState.PATROL_STATE = 3
AIState.ESCAPE_STATE = 4
AIState.FIGHT_STATE = 5
AIState.CD_STATE = 6

local AIEvent = {}
AIEvent.MoveEnd = 1
AIEvent.Born = 2
AIEvent.AvatarDie = 3
AIEvent.CDEnd = 4
AIEvent.RestEnd = 5
AIEvent.BeHit = 6
AIEvent.AvatarPosSync = 7
AIEvent.Self = 8
AIEvent.AvatarRevive = 9

-----BlackBoard Class -----
local BlackBoard = {}
BlackBoard.__index = BlackBoard

function BlackBoard:new()
        local tmp = {}
        setmetatable(tmp, {__index = BlackBoard})
        tmp.__index = tmp
        tmp.aiState = AIState.THINK_STATE
        tmp.aiEvent = AIEvent.MoveEnd
        tmp.waitSec = 0
        tmp.enemyId = nil -- -1表示无目标
        tmp.timeoutId = 0
        tmp.movePoint = nil
        tmp.isHited = false
        tmp.spellId = 0
        tmp.noEnemy = false
        tmp.lastCastIndex = 0
        tmp.skillActTime = 0
        tmp.skillActTick = 0
    	tmp.skillUseCount = {}
        tmp.towerDefennseCrystalEid = nil
        tmp.thinkCDTimeOut = 0
        tmp.thinkUpdateTimeoutId = 0
        tmp.coordUpdateTimeoutId = 0
        tmp.syncTimeout = 0 
        tmp.debugCount = 0

	for i = 1, 15 do 
		table.insert(tmp.skillUseCount, 0)
	end
        return tmp
end

function BlackBoard:ChangeState(state)
        self.aiState = state
end

function BlackBoard:ChangeEvent(event)
        self.aiEvent = event
end

-----Base Class ------
local BTNode = {}
BTNode.__index = BTNode

function BTNode:new()
        local tmp = {}
        setmetatable(tmp, {__index = BTNode})
        tmp.__index = tmp
        return tmp
end
        
function BTNode:Proc(entity)
        --print("not implement this interface")
end

----- BehaviorTreeRoot Class -----
local BehaviorTreeRoot = BTNode:new()

function BehaviorTreeRoot:new()
        local tmp = {}
        setmetatable(tmp, {__index = BehaviorTreeRoot})
        tmp.__index = tmp
        return tmp
end

function BehaviorTreeRoot:Proc(entity)
--        log_game_info('AI','BehaviorTreeRoot')
        local rst = self.root:Proc(entity) --不用尾调用
        return rst
end

function BehaviorTreeRoot:AddChild(child)
        self.root = child
end

----- ImpulseNode Class -----
local ImpulseNode = BTNode:new()

function ImpulseNode:new()
        local tmp = {}
        setmetatable(tmp, {__index = ImpulseNode})
        tmp.__index = tmp
        return tmp
end

function ImpulseNode:Proc(entity)
        return true
end

-----ConditionNode Class-----
local ConditionNode = BTNode:new()

function ConditionNode:new()
        local tmp = {}
        setmetatable(tmp, {__index = ConditionNode})
        tmp.__index = tmp
        return tmp
end

function ConditionNode:Proc(entity)
        return true
end

----- ActionNode Class -----
local ActionNode = BTNode:new()

function ActionNode:new()
        local tmp = {}
        setmetatable(tmp, {__index = ActionNode})
        tmp.__index = tmp
        return tmp
end

function ActionNode:Proc(entity)
        return true
end

----- DecoratorNode Class -----
local DecoratorNode = BTNode:new()

function DecoratorNode:new()
        local tmp = {}
        setmetatable(tmp, {__index = DecoratorNode})
        tmp.__index = tmp
        return tmp
end

function DecoratorNode:Proc(entity)
        local rst = self.child:Proc(entity) ---不用尾调用
        return rst
end

function DecoratorNode:Proxy(node)
        self.child = node
end

----- CompositeNode Class ------
local CompositeNode = BTNode:new()

function CompositeNode:new()
        local tmp = {}
        setmetatable(tmp, {__index = CompositeNode})
        tmp.__index = tmp
        return tmp
end

function CompositeNode:Proc(entity)
        --todo 由子类实现
        return true
end

function CompositeNode:AddChild(node)
        if not self.children then
                self.children = {}
        end
        table.insert(self.children, node)
end

----- SequenceNode Class -----
local SequenceNode = CompositeNode:new()

function SequenceNode:new()
        local tmp = {}
        setmetatable(tmp, {__index = SequenceNode})
        tmp.__index = tmp
        return tmp
end

function SequenceNode:Proc(entity)
--        log_game_info('AI','SequenceNode')
        for k, v in pairs(self.children) do
                if not v:Proc(entity) then
                        do return false end
                end
        end
        return true
end

----- SelectorNode Class -----
local SelectorNode = CompositeNode:new()

function SelectorNode:new()
        local tmp = {}
        setmetatable(tmp, {__index = SelectorNode})
        tmp.__index = tmp
        return tmp
end

function SelectorNode:Proc(entity)
--        log_game_info('AI','SelectorNode')
        for k, v in pairs(self.children) do
            if v:Proc(entity) then
                    do return true end
            end
        end
        return false
end

Mogo = {}
Mogo.AI = {BehaviorTreeRoot = BehaviorTreeRoot,
                 ImpulseNode = ImpulseNode,
                 DecoratorNode = DecoratorNode,
                 ConditionNode = ConditionNode,
                 ActionNode = ActionNode,
                 SequenceNode = SequenceNode,
                 SelectorNode = SelectorNode,
                 AIState = AIState,
                 AIEvent = AIEvent,
                 BlackBoard = BlackBoard,
                }
                
return Mogo
