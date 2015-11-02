local Mogo = require "BTNode"
require "DecoratorNodes"
require "ConditionNodes"
require "ActionNodes"

BT2008 = Mogo.AI.BehaviorTreeRoot:new()

function BT2008:new()
		 
			local tmp = {}
			setmetatable(tmp, {__index = BT2008})
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
							node11:AddChild(Mogo.AI.InSkillCoolDown:new(5));
							do
								local node13 = Mogo.AI.SelectorNode:new();
								node11:AddChild(node13);
								do
									local node14 = Mogo.AI.SequenceNode:new();
									node13:AddChild(node14);
									node14:AddChild(Mogo.AI.InSkillRange:new(5));
									node14:AddChild(Mogo.AI.CastSpell:new(5));
									node14:AddChild(Mogo.AI.EnterCD:new(0));
								end
								do
									local node18 = Mogo.AI.SequenceNode:new();
									node13:AddChild(node18);
									node18:AddChild(Mogo.AI.ChooseCastPoint:new(5));
									node18:AddChild(Mogo.AI.MoveTo:new());
								end
							end
						end
						do
							local node21 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node21);
							node21:AddChild(Mogo.AI.InSkillCoolDown:new(4));
							do
								local node23 = Mogo.AI.SelectorNode:new();
								node21:AddChild(node23);
								do
									local node24 = Mogo.AI.SequenceNode:new();
									node23:AddChild(node24);
									node24:AddChild(Mogo.AI.InSkillRange:new(4));
									node24:AddChild(Mogo.AI.CastSpell:new(4));
									node24:AddChild(Mogo.AI.EnterCD:new(0));
								end
								do
									local node28 = Mogo.AI.SequenceNode:new();
									node23:AddChild(node28);
									node28:AddChild(Mogo.AI.ChooseCastPoint:new(4));
									node28:AddChild(Mogo.AI.MoveTo:new());
								end
							end
						end
						do
							local node31 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node31);
							node31:AddChild(Mogo.AI.InSkillCoolDown:new(3));
							do
								local node33 = Mogo.AI.SelectorNode:new();
								node31:AddChild(node33);
								do
									local node34 = Mogo.AI.SequenceNode:new();
									node33:AddChild(node34);
									node34:AddChild(Mogo.AI.InSkillRange:new(3));
									node34:AddChild(Mogo.AI.CastSpell:new(3));
									node34:AddChild(Mogo.AI.EnterCD:new(0));
								end
								do
									local node38 = Mogo.AI.SequenceNode:new();
									node33:AddChild(node38);
									node38:AddChild(Mogo.AI.ChooseCastPoint:new(3));
									node38:AddChild(Mogo.AI.MoveTo:new());
								end
							end
						end
						do
							local node41 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node41);
							node41:AddChild(Mogo.AI.InSkillCoolDown:new(2));
							do
								local node43 = Mogo.AI.SelectorNode:new();
								node41:AddChild(node43);
								do
									local node44 = Mogo.AI.SequenceNode:new();
									node43:AddChild(node44);
									node44:AddChild(Mogo.AI.InSkillRange:new(2));
									node44:AddChild(Mogo.AI.CastSpell:new(2));
									node44:AddChild(Mogo.AI.EnterCD:new(0));
								end
								do
									local node48 = Mogo.AI.SequenceNode:new();
									node43:AddChild(node48);
									node48:AddChild(Mogo.AI.ChooseCastPoint:new(2));
									node48:AddChild(Mogo.AI.MoveTo:new());
								end
							end
						end
						do
							local node51 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node51);
							node51:AddChild(Mogo.AI.InSkillCoolDown:new(1));
							do
								local node53 = Mogo.AI.SelectorNode:new();
								node51:AddChild(node53);
								do
									local node54 = Mogo.AI.SequenceNode:new();
									node53:AddChild(node54);
									node54:AddChild(Mogo.AI.InSkillRange:new(1));
									node54:AddChild(Mogo.AI.CastSpell:new(1));
									node54:AddChild(Mogo.AI.EnterCD:new(0));
								end
								do
									local node58 = Mogo.AI.SequenceNode:new();
									node53:AddChild(node58);
									node58:AddChild(Mogo.AI.ChooseCastPoint:new(1));
									node58:AddChild(Mogo.AI.MoveTo:new());
								end
							end
						end
						do
							local node61 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node61);
							do
								local node62 = Mogo.AI.SequenceNode:new();
								node61:AddChild(node62);
								node62:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,70));
								node62:AddChild(Mogo.AI.EnterRest:new(200));
							end
						end
						node10:AddChild(Mogo.AI.EnterRest:new(0));
					end
				end
			end

			return tmp
end

return BT2008:new()
