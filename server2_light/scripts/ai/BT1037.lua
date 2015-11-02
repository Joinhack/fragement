local Mogo = require "BTNode"
require "DecoratorNodes"
require "ConditionNodes"
require "ActionNodes"

BT1037 = Mogo.AI.BehaviorTreeRoot:new()

function BT1037:new()
		 
			local tmp = {}
			setmetatable(tmp, {__index = BT1037})
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
							do
								local node13 = Mogo.AI.SelectorNode:new();
								node11:AddChild(node13);
								do
									local node14 = Mogo.AI.SequenceNode:new();
									node13:AddChild(node14);
									node14:AddChild(Mogo.AI.InSkillRange:new(2));
									node14:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,10));
									node14:AddChild(Mogo.AI.CastSpell:new(2));
									node14:AddChild(Mogo.AI.EnterCD:new(0));
								end
								do
									local node19 = Mogo.AI.SequenceNode:new();
									node13:AddChild(node19);
									node19:AddChild(Mogo.AI.ChooseCastPoint:new(2));
									node19:AddChild(Mogo.AI.MoveTo:new());
								end
							end
						end
						do
							local node22 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node22);
							node22:AddChild(Mogo.AI.InSkillCoolDown:new(1));
							do
								local node24 = Mogo.AI.SelectorNode:new();
								node22:AddChild(node24);
								do
									local node25 = Mogo.AI.SequenceNode:new();
									node24:AddChild(node25);
									node25:AddChild(Mogo.AI.InSkillRange:new(1));
									node25:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,40));
									node25:AddChild(Mogo.AI.CastSpell:new(1));
									node25:AddChild(Mogo.AI.EnterCD:new(0));
								end
								do
									local node30 = Mogo.AI.SequenceNode:new();
									node24:AddChild(node30);
									node30:AddChild(Mogo.AI.ChooseCastPoint:new(1));
									node30:AddChild(Mogo.AI.MoveTo:new());
								end
							end
						end
						do
							local node33 = Mogo.AI.SelectorNode:new();
							node10:AddChild(node33);
							do
								local node34 = Mogo.AI.SequenceNode:new();
								node33:AddChild(node34);
								node34:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,30));
								node34:AddChild(Mogo.AI.EnterRest:new(200));
							end
							do
								local node37 = Mogo.AI.SequenceNode:new();
								node33:AddChild(node37);
								node37:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,50));
								node37:AddChild(Mogo.AI.EnterRest:new(400));
							end
							node33:AddChild(Mogo.AI.EnterRest:new(600));
						end
					end
				end
			end

			return tmp
end

return BT1037:new()
