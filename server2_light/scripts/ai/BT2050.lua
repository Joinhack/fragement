local Mogo = require "BTNode"
require "DecoratorNodes"
require "ConditionNodes"
require "ActionNodes"

BT2050 = Mogo.AI.BehaviorTreeRoot:new()

function BT2050:new()
		 
			local tmp = {}
			setmetatable(tmp, {__index = BT2050})
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
						node4:AddChild(Mogo.AI.AOI:new(80));
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
							node11:AddChild(Mogo.AI.InSkillCoolDown:new(3));
							do
								local node13 = Mogo.AI.SequenceNode:new();
								node11:AddChild(node13);
								node13:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,30));
								node13:AddChild(Mogo.AI.CastSpell:new(3,0));
								node13:AddChild(Mogo.AI.EnterCD:new(2000));
							end
						end
						do
							local node17 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node17);
							node17:AddChild(Mogo.AI.InSkillCoolDown:new(2));
							do
								local node19 = Mogo.AI.SequenceNode:new();
								node17:AddChild(node19);
								node19:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,70));
								node19:AddChild(Mogo.AI.CastSpell:new(2,0));
								node19:AddChild(Mogo.AI.EnterCD:new(2000));
							end
						end
						do
							local node23 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node23);
							node23:AddChild(Mogo.AI.InSkillCoolDown:new(1));
							do
								local node25 = Mogo.AI.SequenceNode:new();
								node23:AddChild(node25);
								node25:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,70));
								node25:AddChild(Mogo.AI.CastSpell:new(1,0));
								node25:AddChild(Mogo.AI.EnterCD:new(2000));
							end
						end
						node10:AddChild(Mogo.AI.EnterRest:new(1000));
					end
				end
			end

			return tmp
end

return BT2050:new()
