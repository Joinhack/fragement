local Mogo = require "BTNode"
require "DecoratorNodes"
require "ConditionNodes"
require "ActionNodes"

BT1001 = Mogo.AI.BehaviorTreeRoot:new()

function BT1001:new()
		 
			local tmp = {}
			setmetatable(tmp, {__index = BT1001})
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
							node11:AddChild(Mogo.AI.InSkillRange:new(2));
							do
								local node13 = Mogo.AI.SelectorNode:new();
								node11:AddChild(node13);
								do
									local node14 = Mogo.AI.SequenceNode:new();
									node13:AddChild(node14);
									node14:AddChild(Mogo.AI.InSkillCoolDown:new(2));
									node14:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,20));
									node14:AddChild(Mogo.AI.CastSpell:new(2));
									node14:AddChild(Mogo.AI.EnterCD:new(0));
								end
								do
									local node19 = Mogo.AI.SequenceNode:new();
									node13:AddChild(node19);
									node19:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,50));
									node19:AddChild(Mogo.AI.Escape:new(1000));
								end
							end
						end
						do
							local node22 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node22);
							do
								local node23 =  Mogo.AI.Not:new();
								node22:AddChild(node23);
								node23:Proxy(Mogo.AI.InSkillRange:new(2));
							end
							do
								local node25 = Mogo.AI.SelectorNode:new();
								node22:AddChild(node25);
								do
									local node26 = Mogo.AI.SequenceNode:new();
									node25:AddChild(node26);
									node26:AddChild(Mogo.AI.InSkillRange:new(1));
									node26:AddChild(Mogo.AI.InSkillCoolDown:new(1));
									node26:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,30));
									node26:AddChild(Mogo.AI.CastSpell:new(1));
									node26:AddChild(Mogo.AI.EnterCD:new(0));
								end
								do
									local node32 = Mogo.AI.SequenceNode:new();
									node25:AddChild(node32);
									node32:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,50));
									node32:AddChild(Mogo.AI.ChooseCastPoint:new(1));
									node32:AddChild(Mogo.AI.MoveTo:new());
								end
							end
						end
						do
							local node36 = Mogo.AI.SelectorNode:new();
							node10:AddChild(node36);
							do
								local node37 = Mogo.AI.SequenceNode:new();
								node36:AddChild(node37);
								node37:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,20));
								node37:AddChild(Mogo.AI.EnterRest:new(1200));
							end
							do
								local node40 = Mogo.AI.SequenceNode:new();
								node36:AddChild(node40);
								node40:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,20));
								node40:AddChild(Mogo.AI.EnterRest:new(1000));
							end
							do
								local node43 = Mogo.AI.SequenceNode:new();
								node36:AddChild(node43);
								node43:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,20));
								node43:AddChild(Mogo.AI.EnterRest:new(800));
							end
							do
								local node46 = Mogo.AI.SequenceNode:new();
								node36:AddChild(node46);
								node46:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,20));
								node46:AddChild(Mogo.AI.EnterRest:new(600));
							end
							do
								local node49 = Mogo.AI.SequenceNode:new();
								node36:AddChild(node49);
								node49:AddChild(Mogo.AI.ChooseCastPoint:new(1));
								node49:AddChild(Mogo.AI.MoveTo:new());
							end
							node36:AddChild(Mogo.AI.EnterRest:new(400));
						end
					end
				end
			end

			return tmp
end

return BT1001:new()
