local Mogo = require "BTNode"
require "DecoratorNodes"
require "ConditionNodes"
require "ActionNodes"

BT1 = Mogo.AI.BehaviorTreeRoot:new()

function BT1:new()
		 
			local tmp = {}
			setmetatable(tmp, {__index = BT1})
			tmp.__index = tmp

			do
				local node1 = Mogo.AI.SelectorNode:new();
				self:AddChild(node1);
				node1:AddChild(Mogo.AI.CmpEnemyNum:new(Mogo.AI.CmpType.eq,0));
				do
					local node3 = Mogo.AI.SequenceNode:new();
					node1:AddChild(node3);
					do
						local node4 =  Mogo.AI.Not:new();
						node3:AddChild(node4);
						node4:Proxy(Mogo.AI.ISCD:new());
					end
					do
						local node6 = Mogo.AI.SelectorNode:new();
						node3:AddChild(node6);
						node6:AddChild(Mogo.AI.HasFightTarget:new());
						node6:AddChild(Mogo.AI.AOI:new());
					end
					node3:AddChild(Mogo.AI.IsTargetCanBeAttack:new());
					do
						local node10 = Mogo.AI.SelectorNode:new();
						node3:AddChild(node10);
						do
							local node11 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node11);
							node11:AddChild(Mogo.AI.InSkillRange:new(1));
							node11:AddChild(Mogo.AI.InSkillCoolDown:new(1));
							node11:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,20));
							node11:AddChild(Mogo.AI.CastSpell:new(1));
							node11:AddChild(Mogo.AI.EnterCD:new(0));
						end
						do
							local node17 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node17);
							do
								local node18 =  Mogo.AI.Not:new();
								node17:AddChild(node18);
								node18:Proxy(Mogo.AI.InSkillRange:new(1));
							end
							node17:AddChild(Mogo.AI.ChooseCastPoint:new(1));
							node17:AddChild(Mogo.AI.MoveTo:new());
						end
						do
							local node22 = Mogo.AI.SelectorNode:new();
							node10:AddChild(node22);
							do
								local node23 = Mogo.AI.SequenceNode:new();
								node22:AddChild(node23);
								node23:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,30));
								node23:AddChild(Mogo.AI.EnterRest:new(600));
							end
							do
								local node26 = Mogo.AI.SequenceNode:new();
								node22:AddChild(node26);
								node26:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,50));
								node26:AddChild(Mogo.AI.EnterRest:new(600));
							end
							node22:AddChild(Mogo.AI.EnterRest:new(600));
						end
					end
				end
			end

			return tmp
end

return BT1:new()
