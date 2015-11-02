local Mogo = require "BTNode"
require "DecoratorNodes"
require "ConditionNodes"
require "ActionNodes"

BT12 = Mogo.AI.BehaviorTreeRoot:new()

function BT12:new()
		 
			local tmp = {}
			setmetatable(tmp, {__index = BT12})
			tmp.__index = tmp

			do
				local node1 = Mogo.AI.SelectorNode:new();
				self:AddChild(node1);
				node1:AddChild(Mogo.AI.CmpEnemyNum:new(Mogo.AI.CmpType.eq,0));
				do
					local node3 = Mogo.AI.SequenceNode:new();
					node1:AddChild(node3);
					do
						local node4 = Mogo.AI.SelectorNode:new();
						node3:AddChild(node4);
						node4:AddChild(Mogo.AI.HasFightTarget:new());
						node4:AddChild(Mogo.AI.AOI:new());
					end
					do
						local node7 =  Mogo.AI.Not:new();
						node3:AddChild(node7);
						node7:Proxy(Mogo.AI.ISCD:new());
					end
					node3:AddChild(Mogo.AI.IsTargetCanBeAttack:new());
					do
						local node10 = Mogo.AI.SelectorNode:new();
						node3:AddChild(node10);
						do
							local node11 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node11);
							node11:AddChild(Mogo.AI.InSkillCoolDown:new(2));
							node11:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,80));
							node11:AddChild(Mogo.AI.CastSpell:new(2));
							node11:AddChild(Mogo.AI.EnterCD:new(0));
						end
						do
							local node16 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node16);
							node16:AddChild(Mogo.AI.InSkillCoolDown:new(1));
							node16:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,60));
							node16:AddChild(Mogo.AI.CastSpell:new(1));
							node16:AddChild(Mogo.AI.EnterCD:new(0));
						end
						do
							local node21 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node21);
							node21:AddChild(Mogo.AI.EnterRest:new(300));
						end
					end
				end
			end

			return tmp
end

return BT12:new()
