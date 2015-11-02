local Mogo = require "BTNode"
require "DecoratorNodes"
require "ConditionNodes"
require "ActionNodes"

BT2016 = Mogo.AI.BehaviorTreeRoot:new()

function BT2016:new()
		 
			local tmp = {}
			setmetatable(tmp, {__index = BT2016})
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
							do
								local node12 =  Mogo.AI.Not:new();
								node11:AddChild(node12);
								node12:Proxy(Mogo.AI.InSkillRange:new(2));
							end
							do
								local node14 = Mogo.AI.SelectorNode:new();
								node11:AddChild(node14);
								do
									local node15 = Mogo.AI.SequenceNode:new();
									node14:AddChild(node15);
									node15:AddChild(Mogo.AI.InSkillCoolDown:new(6));
									do
										local node17 = Mogo.AI.SelectorNode:new();
										node15:AddChild(node17);
										do
											local node18 = Mogo.AI.SequenceNode:new();
											node17:AddChild(node18);
											node18:AddChild(Mogo.AI.InSkillRange:new(6));
											node18:AddChild(Mogo.AI.CastSpell:new(6));
											node18:AddChild(Mogo.AI.EnterCD:new(0));
										end
										do
											local node22 = Mogo.AI.SequenceNode:new();
											node17:AddChild(node22);
											do
												local node23 =  Mogo.AI.Not:new();
												node22:AddChild(node23);
												node23:Proxy(Mogo.AI.InSkillRange:new(6));
											end
											node22:AddChild(Mogo.AI.ChooseCastPoint:new(6));
											node22:AddChild(Mogo.AI.MoveTo:new());
										end
									end
								end
								do
									local node27 = Mogo.AI.SequenceNode:new();
									node14:AddChild(node27);
									node27:AddChild(Mogo.AI.InSkillCoolDown:new(4));
									do
										local node29 = Mogo.AI.SelectorNode:new();
										node27:AddChild(node29);
										do
											local node30 = Mogo.AI.SequenceNode:new();
											node29:AddChild(node30);
											node30:AddChild(Mogo.AI.InSkillRange:new(4));
											node30:AddChild(Mogo.AI.CastSpell:new(4));
											node30:AddChild(Mogo.AI.EnterCD:new(0));
										end
										do
											local node34 = Mogo.AI.SequenceNode:new();
											node29:AddChild(node34);
											do
												local node35 =  Mogo.AI.Not:new();
												node34:AddChild(node35);
												node35:Proxy(Mogo.AI.InSkillRange:new(4));
											end
											node34:AddChild(Mogo.AI.ChooseCastPoint:new(4));
											node34:AddChild(Mogo.AI.MoveTo:new());
										end
									end
								end
								do
									local node39 = Mogo.AI.SequenceNode:new();
									node14:AddChild(node39);
									node39:AddChild(Mogo.AI.InSkillCoolDown:new(3));
									do
										local node41 = Mogo.AI.SelectorNode:new();
										node39:AddChild(node41);
										do
											local node42 = Mogo.AI.SequenceNode:new();
											node41:AddChild(node42);
											node42:AddChild(Mogo.AI.InSkillRange:new(3));
											node42:AddChild(Mogo.AI.CastSpell:new(3));
											node42:AddChild(Mogo.AI.EnterCD:new(0));
										end
										do
											local node46 = Mogo.AI.SequenceNode:new();
											node41:AddChild(node46);
											do
												local node47 =  Mogo.AI.Not:new();
												node46:AddChild(node47);
												node47:Proxy(Mogo.AI.InSkillRange:new(3));
											end
											node46:AddChild(Mogo.AI.ChooseCastPoint:new(3));
											node46:AddChild(Mogo.AI.MoveTo:new());
										end
									end
								end
							end
						end
						do
							local node51 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node51);
							node51:AddChild(Mogo.AI.InSkillRange:new(2));
							do
								local node53 = Mogo.AI.SelectorNode:new();
								node51:AddChild(node53);
								do
									local node54 = Mogo.AI.SequenceNode:new();
									node53:AddChild(node54);
									node54:AddChild(Mogo.AI.InSkillCoolDown:new(5));
									node54:AddChild(Mogo.AI.CastSpell:new(5));
									node54:AddChild(Mogo.AI.EnterCD:new(0));
								end
								do
									local node58 = Mogo.AI.SequenceNode:new();
									node53:AddChild(node58);
									node58:AddChild(Mogo.AI.InSkillCoolDown:new(2));
									node58:AddChild(Mogo.AI.CastSpell:new(2));
									node58:AddChild(Mogo.AI.EnterCD:new(0));
								end
							end
						end
						do
							local node62 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node62);
							node62:AddChild(Mogo.AI.InSkillCoolDown:new(1));
							do
								local node64 = Mogo.AI.SelectorNode:new();
								node62:AddChild(node64);
								do
									local node65 = Mogo.AI.SequenceNode:new();
									node64:AddChild(node65);
									node65:AddChild(Mogo.AI.InSkillRange:new(1));
									node65:AddChild(Mogo.AI.CastSpell:new(1));
									node65:AddChild(Mogo.AI.EnterCD:new(0));
								end
								do
									local node69 = Mogo.AI.SequenceNode:new();
									node64:AddChild(node69);
									node69:AddChild(Mogo.AI.ChooseCastPoint:new(1));
									node69:AddChild(Mogo.AI.MoveTo:new());
								end
							end
						end
						node10:AddChild(Mogo.AI.EnterRest:new(200));
					end
				end
			end

			return tmp
end

return BT2016:new()
