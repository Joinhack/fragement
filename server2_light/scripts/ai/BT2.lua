local Mogo = require "BTNode"
require "DecoratorNodes" 
require "ConditionNodes"
require "ActionNodes" 

BT2 = Mogo.AI.BehaviorTreeRoot:new()

function BT2:new()
		 
			local tmp = {}
			setmetatable(tmp, {__index = BT2})
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
							node12:AddChild(Mogo.AI.InSkillRange:new(1));
							do
								local node14 = Mogo.AI.SequenceNode:new();
								node12:AddChild(node14);
								node14:AddChild(Mogo.AI.ChooseCastPoint:new(1));
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
								do
									local node21 =  Mogo.AI.Not:new();
									node20:AddChild(node21);
									node21:Proxy(Mogo.AI.InSkillCoolDown:new(1));
								end
								node20:AddChild(Mogo.AI.InSkillCoolDown:new(2));
								node20:AddChild(Mogo.AI.InSkillRange:new(2));
								node20:AddChild(Mogo.AI.CastSpell:new(2));
								node20:AddChild(Mogo.AI.EnterCD:new(2));
							end
							do
								local node27 = Mogo.AI.SequenceNode:new();
								node19:AddChild(node27);
								node27:AddChild(Mogo.AI.InSkillCoolDown:new(1));
								node27:AddChild(Mogo.AI.InSkillRange:new(1));
								node27:AddChild(Mogo.AI.CastSpell:new(1));
								node27:AddChild(Mogo.AI.EnterCD:new(2));
							end
							do
								local node32 = Mogo.AI.SelectorNode:new();
								node19:AddChild(node32);
								do
									local node33 = Mogo.AI.SequenceNode:new();
									node32:AddChild(node33);
									do
										local node34 =  Mogo.AI.Not:new();
										node33:AddChild(node34);
										node34:Proxy(Mogo.AI.InSkillRange:new(1));
									end
									node33:AddChild(Mogo.AI.ChooseCastPoint:new(1));
									node33:AddChild(Mogo.AI.MoveTo:new());
								end
							end
						end
					end
				end
			end

			return tmp
end

return BT2:new()
