local Mogo = require "BTNode"
require "DecoratorNodes"
require "ConditionNodes"
require "ActionNodes"

BT501 = Mogo.AI.BehaviorTreeRoot:new()

function BT501:new()
		 
			local tmp = {}
			setmetatable(tmp, {__index = BT501})
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
						node7:AddChild(Mogo.AI.InSkillCoolDown:new(2));
						node7:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,40));
						node7:AddChild(Mogo.AI.InSkillRange:new(2));
						node7:AddChild(Mogo.AI.CastSpell:new(2,0));
						node7:AddChild(Mogo.AI.EnterCD:new(0));
					end
					do
						local node13 = Mogo.AI.SequenceNode:new();
						node6:AddChild(node13);
						node13:AddChild(Mogo.AI.InSkillCoolDown:new(1));
						node13:AddChild(Mogo.AI.InSkillRange:new(1));
						node13:AddChild(Mogo.AI.CastSpell:new(1,0));
						node13:AddChild(Mogo.AI.EnterCD:new(0));
					end
					do
						local node18 = Mogo.AI.SequenceNode:new();
						node6:AddChild(node18);
						node18:AddChild(Mogo.AI.ChooseCastPoint:new(1));
						node18:AddChild(Mogo.AI.MoveTo:new());
					end
				end
			end

			return tmp
end

return BT501:new()
