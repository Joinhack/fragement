local Mogo = require "BTNode"
require "DecoratorNodes"
require "ConditionNodes"
require "ActionNodes"

BT502 = Mogo.AI.BehaviorTreeRoot:new()

function BT502:new()
		 
			local tmp = {}
			setmetatable(tmp, {__index = BT502})
			tmp.__index = tmp

			do
				local node1 = Mogo.AI.SequenceNode:new();
				self:AddChild(node1);
				do
					local node2 =  Mogo.AI.Not:new();
					node1:AddChild(node2);
					node2:Proxy(Mogo.AI.ISCD:new());
				end
				node1:AddChild(Mogo.AI.TowerDefenseMonsterAOI:new());
				node1:AddChild(Mogo.AI.IsTargetCanBeAttack:new());
				do
					local node6 = Mogo.AI.SelectorNode:new();
					node1:AddChild(node6);
					do
						local node7 = Mogo.AI.SequenceNode:new();
						node6:AddChild(node7);
						node7:AddChild(Mogo.AI.InSkillCoolDown:new(4));
						node7:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,20));
						node7:AddChild(Mogo.AI.InSkillRange:new(4));
						node7:AddChild(Mogo.AI.CastSpell:new(4,0));
						node7:AddChild(Mogo.AI.EnterCD:new(0));
					end
					do
						local node13 = Mogo.AI.SequenceNode:new();
						node6:AddChild(node13);
						node13:AddChild(Mogo.AI.InSkillCoolDown:new(3));
						node13:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,30));
						node13:AddChild(Mogo.AI.InSkillRange:new(3));
						node13:AddChild(Mogo.AI.CastSpell:new(3,0));
						node13:AddChild(Mogo.AI.EnterCD:new(0));
					end
					do
						local node19 = Mogo.AI.SequenceNode:new();
						node6:AddChild(node19);
						node19:AddChild(Mogo.AI.InSkillCoolDown:new(2));
						node19:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,50));
						node19:AddChild(Mogo.AI.InSkillRange:new(2));
						node19:AddChild(Mogo.AI.CastSpell:new(2,0));
						node19:AddChild(Mogo.AI.EnterCD:new(0));
					end
					do
						local node25 = Mogo.AI.SequenceNode:new();
						node6:AddChild(node25);
						node25:AddChild(Mogo.AI.InSkillCoolDown:new(1));
						node25:AddChild(Mogo.AI.InSkillRange:new(1));
						node25:AddChild(Mogo.AI.CastSpell:new(1,0));
						node25:AddChild(Mogo.AI.EnterCD:new(0));
					end
					do
						local node30 = Mogo.AI.SequenceNode:new();
						node6:AddChild(node30);
						node30:AddChild(Mogo.AI.ChooseCastPoint:new(1));
						node30:AddChild(Mogo.AI.MoveTo:new());
					end
				end
			end

			return tmp
end

return BT502:new()
