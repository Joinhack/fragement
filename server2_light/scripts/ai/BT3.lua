local Mogo = require "BTNode"
require "DecoratorNodes"
require "ConditionNodes"
require "ActionNodes"

BT3 = Mogo.AI.BehaviorTreeRoot:new()

function BT3:new()
		 
			local tmp = {}
			setmetatable(tmp, {__index = BT3})
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
					local node6 = Mogo.AI.SequenceNode:new();
					node1:AddChild(node6);
					do
						local node7 = Mogo.AI.SelectorNode:new();
						node6:AddChild(node7);
						node7:AddChild(Mogo.AI.HasFightTarget:new());
						node7:AddChild(Mogo.AI.AOI:new());
					end
					do
						local node10 =  Mogo.AI.Not:new();
						node6:AddChild(node10);
						node10:Proxy(Mogo.AI.ISCD:new());
					end
					node6:AddChild(Mogo.AI.IsTargetCanBeAttack:new());
					do
						local node13 = Mogo.AI.SelectorNode:new();
						node6:AddChild(node13);
						do
							local node14 = Mogo.AI.SequenceNode:new();
							node13:AddChild(node14);
							do
								local node15 = Mogo.AI.SelectorNode:new();
								node14:AddChild(node15);
								do
									local node16 = Mogo.AI.SequenceNode:new();
									node15:AddChild(node16);
									node16:AddChild(Mogo.AI.InSkillRange:new(2));
									node16:AddChild(Mogo.AI.InSkillCoolDown:new(2));
									node16:AddChild(Mogo.AI.CastSpell:new(2));
									node16:AddChild(Mogo.AI.EnterCD:new(0));
								end
								do
									local node21 = Mogo.AI.SequenceNode:new();
									node15:AddChild(node21);
									node21:AddChild(Mogo.AI.ChooseCastPoint:new(2));
									node21:AddChild(Mogo.AI.MoveTo:new());
								end
							end
						end
						do
							local node24 = Mogo.AI.SequenceNode:new();
							node13:AddChild(node24);
							do
								local node25 = Mogo.AI.SelectorNode:new();
								node24:AddChild(node25);
								do
									local node26 = Mogo.AI.SequenceNode:new();
									node25:AddChild(node26);
									node26:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,100));
									node26:AddChild(Mogo.AI.EnterRest:new(200));
								end
								do
									local node29 = Mogo.AI.SequenceNode:new();
									node25:AddChild(node29);
									node29:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,50));
									node29:AddChild(Mogo.AI.EnterRest:new(400));
								end
								node25:AddChild(Mogo.AI.EnterRest:new(600));
							end
							node24:AddChild(Mogo.AI.Think:new());
						end
					end
				end
			end

			return tmp
end

return BT3:new()
