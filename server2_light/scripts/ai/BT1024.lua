local Mogo = require "BTNode"
require "DecoratorNodes"
require "ConditionNodes"
require "ActionNodes"

BT1024 = Mogo.AI.BehaviorTreeRoot:new()

function BT1024:new()
		 
			local tmp = {}
			setmetatable(tmp, {__index = BT1024})
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
							node11:AddChild(Mogo.AI.InSkillCoolDown:new(3));
							do
								local node13 = Mogo.AI.SelectorNode:new();
								node11:AddChild(node13);
								do
									local node14 = Mogo.AI.SequenceNode:new();
									node13:AddChild(node14);
									node14:AddChild(Mogo.AI.InSkillRange:new(3));
									node14:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,30));
									node14:AddChild(Mogo.AI.CastSpell:new(3));
									node14:AddChild(Mogo.AI.EnterCD:new(0));
								end
								do
									local node19 = Mogo.AI.SequenceNode:new();
									node13:AddChild(node19);
									node19:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,50));
									node19:AddChild(Mogo.AI.ChooseCastPoint:new(3));
									node19:AddChild(Mogo.AI.MoveTo:new());
								end
							end
						end
						do
							local node23 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node23);
							node23:AddChild(Mogo.AI.InSkillCoolDown:new(2));
							do
								local node25 = Mogo.AI.SelectorNode:new();
								node23:AddChild(node25);
								do
									local node26 = Mogo.AI.SequenceNode:new();
									node25:AddChild(node26);
									node26:AddChild(Mogo.AI.InSkillRange:new(2));
									node26:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,30));
									node26:AddChild(Mogo.AI.CastSpell:new(2));
									node26:AddChild(Mogo.AI.EnterCD:new(0));
								end
								do
									local node31 = Mogo.AI.SequenceNode:new();
									node25:AddChild(node31);
									node31:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,50));
									node31:AddChild(Mogo.AI.ChooseCastPoint:new(2));
									node31:AddChild(Mogo.AI.MoveTo:new());
								end
							end
						end
						do
							local node35 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node35);
							node35:AddChild(Mogo.AI.InSkillCoolDown:new(1));
							do
								local node37 = Mogo.AI.SelectorNode:new();
								node35:AddChild(node37);
								do
									local node38 = Mogo.AI.SequenceNode:new();
									node37:AddChild(node38);
									node38:AddChild(Mogo.AI.InSkillRange:new(1));
									node38:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,30));
									node38:AddChild(Mogo.AI.CastSpell:new(1));
									node38:AddChild(Mogo.AI.EnterCD:new(0));
								end
								do
									local node43 = Mogo.AI.SequenceNode:new();
									node37:AddChild(node43);
									node43:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,50));
									node43:AddChild(Mogo.AI.ChooseCastPoint:new(1));
									node43:AddChild(Mogo.AI.MoveTo:new());
								end
							end
						end
						do
							local node47 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node47);
							do
								local node48 = Mogo.AI.SelectorNode:new();
								node47:AddChild(node48);
								do
									local node49 = Mogo.AI.SequenceNode:new();
									node48:AddChild(node49);
									node49:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,30));
									node49:AddChild(Mogo.AI.EnterRest:new(400));
								end
								do
									local node52 = Mogo.AI.SequenceNode:new();
									node48:AddChild(node52);
									node52:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,50));
									node52:AddChild(Mogo.AI.EnterRest:new(600));
								end
								node48:AddChild(Mogo.AI.EnterRest:new(800));
							end
							node47:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,50));
							node47:AddChild(Mogo.AI.ChooseCastPoint:new(1));
							node47:AddChild(Mogo.AI.MoveTo:new());
						end
					end
				end
			end

			return tmp
end

return BT1024:new()
