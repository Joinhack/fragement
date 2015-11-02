local Mogo = require "BTNode"
require "DecoratorNodes"
require "ConditionNodes"
require "ActionNodes"

BT101 = Mogo.AI.BehaviorTreeRoot:new()

function BT101:new()
		 
			local tmp = {}
			setmetatable(tmp, {__index = BT101})
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
						node4:AddChild(Mogo.AI.AOI:new(0));
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
							node11:AddChild(Mogo.AI.InSkillCoolDown:new(4));
							do
								local node13 = Mogo.AI.SequenceNode:new();
								node11:AddChild(node13);
								node13:AddChild(Mogo.AI.CastSpell:new(4,0));
								node13:AddChild(Mogo.AI.EnterCD:new(10000));
							end
						end
						do
							local node16 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node16);
							node16:AddChild(Mogo.AI.InSkillCoolDown:new(3));
							do
								local node18 = Mogo.AI.SequenceNode:new();
								node16:AddChild(node18);
								node18:AddChild(Mogo.AI.CastSpell:new(3,0));
								node18:AddChild(Mogo.AI.EnterCD:new(10000));
							end
						end
						do
							local node21 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node21);
							node21:AddChild(Mogo.AI.InSkillCoolDown:new(2));
							do
								local node23 = Mogo.AI.SequenceNode:new();
								node21:AddChild(node23);
								node23:AddChild(Mogo.AI.CastSpell:new(2,0));
								node23:AddChild(Mogo.AI.EnterCD:new(10000));
							end
						end
						do
							local node26 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node26);
							node26:AddChild(Mogo.AI.InSkillCoolDown:new(1));
							do
								local node28 = Mogo.AI.SequenceNode:new();
								node26:AddChild(node28);
								node28:AddChild(Mogo.AI.CastSpell:new(1,0));
								node28:AddChild(Mogo.AI.EnterCD:new(10000));
							end
						end
						node10:AddChild(Mogo.AI.EnterRest:new(1000));
					end
				end
			end

			return tmp
end

return BT101:new()
