local Mogo = require "BTNode"
require "DecoratorNodes"
require "ConditionNodes"
require "ActionNodes"

BT4 = Mogo.AI.BehaviorTreeRoot:new()

function BT4:new()
		 
			local tmp = {}
			setmetatable(tmp, {__index = BT4})
			tmp.__index = tmp

			do
				local node1 = Mogo.AI.SelectorNode:new();
				self:AddChild(node1);
				do
					local node2 = Mogo.AI.SequenceNode:new();
					node1:AddChild(node2);
					node2:AddChild(Mogo.AI.ISRest:new());
					node2:AddChild(Mogo.AI.Rest:new());
				end
				node1:AddChild(Mogo.AI.CmpEnemyNum:new(Mogo.AI.CmpType.eq,0));
				do
					local node6 = Mogo.AI.SelectorNode:new();
					node1:AddChild(node6);
					do
						local node7 = Mogo.AI.SequenceNode:new();
						node6:AddChild(node7);
						do
							local node8 = Mogo.AI.SelectorNode:new();
							node7:AddChild(node8);
							node8:AddChild(Mogo.AI.HasFightTarget:new());
							node8:AddChild(Mogo.AI.AOI:new());
						end
						node7:AddChild(Mogo.AI.ISCD:new());
						do
							local node12 = Mogo.AI.SelectorNode:new();
							node7:AddChild(node12);
							node12:AddChild(Mogo.AI.InSkillRange:new(2));
							do
								local node14 = Mogo.AI.SequenceNode:new();
								node12:AddChild(node14);
								node14:AddChild(Mogo.AI.ChooseCastPoint:new(2));
								node14:AddChild(Mogo.AI.MoveTo:new());
							end
						end
					end
					do
						local node17 = Mogo.AI.SequenceNode:new();
						node6:AddChild(node17);
						node17:AddChild(Mogo.AI.IsTargetCanBeAttack:new());
						do
							local node19 = Mogo.AI.SelectorNode:new();
							node17:AddChild(node19);
							do
								local node20 = Mogo.AI.SequenceNode:new();
								node19:AddChild(node20);
								node20:AddChild(Mogo.AI.InSkillCoolDown:new(2));
								node20:AddChild(Mogo.AI.InSkillRange:new(2));
								node20:AddChild(Mogo.AI.CastSpell:new(2));
								node20:AddChild(Mogo.AI.EnterCD:new(2000));
							end
							do
								local node25 = Mogo.AI.SequenceNode:new();
								node19:AddChild(node25);
								do
									local node26 =  Mogo.AI.Not:new();
									node25:AddChild(node26);
									node26:Proxy(Mogo.AI.InSkillRange:new(2));
								end
								node25:AddChild(Mogo.AI.ChooseCastPoint:new(2));
								node25:AddChild(Mogo.AI.MoveTo:new());
							end
						end
					end
				end
			end

			return tmp
end
return BT4:new()
