local Mogo = require "BTNode"
require "DecoratorNodes"
require "ConditionNodes"
require "ActionNodes"

BT11 = Mogo.AI.BehaviorTreeRoot:new()

function BT11:new()
		 
			local tmp = {}
			setmetatable(tmp, {__index = BT11})
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
						node4:AddChild(Mogo.AI.AOI:new(10));
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
							local node11 = Mogo.AI.SelectorNode:new();
							node10:AddChild(node11);
							do
								local node12 = Mogo.AI.SequenceNode:new();
								node11:AddChild(node12);
								node12:AddChild(Mogo.AI.InSkillCoolDown:new(2));
								node12:AddChild(Mogo.AI.InSkillRange:new(2));
								node12:AddChild(Mogo.AI.CastSpell:new(2,0));
								node12:AddChild(Mogo.AI.EnterCD:new(0));
							end
							do
								local node17 = Mogo.AI.SequenceNode:new();
								node11:AddChild(node17);
								node17:AddChild(Mogo.AI.ChooseCastPoint:new(2));
								node17:AddChild(Mogo.AI.MoveTo:new());
							end
						end
						do
							local node20 = Mogo.AI.SelectorNode:new();
							node10:AddChild(node20);
							do
								local node21 = Mogo.AI.SequenceNode:new();
								node20:AddChild(node21);
								node21:AddChild(Mogo.AI.InSkillCoolDown:new(1));
								node21:AddChild(Mogo.AI.InSkillRange:new(1));
								node21:AddChild(Mogo.AI.CastSpell:new(1,0));
								node21:AddChild(Mogo.AI.EnterCD:new(0));
							end
							do
								local node26 = Mogo.AI.SequenceNode:new();
								node20:AddChild(node26);
								node26:AddChild(Mogo.AI.ChooseCastPoint:new(1));
								node26:AddChild(Mogo.AI.MoveTo:new());
							end
						end
						node10:AddChild(Mogo.AI.EnterRest:new(500));
					end
				end
			end

			return tmp
end

return BT11:new()
