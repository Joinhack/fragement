local Mogo = require "BTNode"
require "DecoratorNodes"
require "ConditionNodes"
require "ActionNodes"

BT2009 = Mogo.AI.BehaviorTreeRoot:new()

function BT2009:new()
		 
			local tmp = {}
			setmetatable(tmp, {__index = BT2009})
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
								node12:Proxy(Mogo.AI.InSkillRange:new(4));
							end
							do
								local node14 = Mogo.AI.SelectorNode:new();
								node11:AddChild(node14);
								do
									local node15 = Mogo.AI.SequenceNode:new();
									node14:AddChild(node15);
									node15:AddChild(Mogo.AI.InSkillCoolDown:new(6));
									do
										local node17 = Mogo.AI.SequenceNode:new();
										node15:AddChild(node17);
										do
											local node18 = Mogo.AI.SelectorNode:new();
											node17:AddChild(node18);
											node18:AddChild(Mogo.AI.InSkillRange:new(6));
											node18:AddChild(Mogo.AI.CastSpell:new(6));
											node18:AddChild(Mogo.AI.EnterCD:new(0));
										end
										do
											local node22 = Mogo.AI.SequenceNode:new();
											node17:AddChild(node22);
											node22:AddChild(Mogo.AI.ChooseCastPoint:new(6));
											node22:AddChild(Mogo.AI.MoveTo:new());
										end
									end
								end
								do
									local node25 = Mogo.AI.SequenceNode:new();
									node14:AddChild(node25);
									node25:AddChild(Mogo.AI.InSkillCoolDown:new(7));
									do
										local node27 = Mogo.AI.SequenceNode:new();
										node25:AddChild(node27);
										do
											local node28 = Mogo.AI.SelectorNode:new();
											node27:AddChild(node28);
											node28:AddChild(Mogo.AI.InSkillRange:new(7));
											node28:AddChild(Mogo.AI.CastSpell:new(7));
											node28:AddChild(Mogo.AI.EnterCD:new(0));
										end
										do
											local node32 = Mogo.AI.SequenceNode:new();
											node27:AddChild(node32);
											node32:AddChild(Mogo.AI.ChooseCastPoint:new(7));
											node32:AddChild(Mogo.AI.MoveTo:new());
										end
									end
								end
								do
									local node35 = Mogo.AI.SequenceNode:new();
									node14:AddChild(node35);
									node35:AddChild(Mogo.AI.ChooseCastPoint:new(1));
									node35:AddChild(Mogo.AI.MoveTo:new());
								end
							end
						end
						do
							local node38 = Mogo.AI.SelectorNode:new();
							node10:AddChild(node38);
							do
								local node39 = Mogo.AI.SequenceNode:new();
								node38:AddChild(node39);
								node39:AddChild(Mogo.AI.InSkillCoolDown:new(4));
								node39:AddChild(Mogo.AI.CastSpell:new(4));
								node39:AddChild(Mogo.AI.EnterCD:new(0));
							end
							do
								local node43 = Mogo.AI.SequenceNode:new();
								node38:AddChild(node43);
								node43:AddChild(Mogo.AI.InSkillRange:new(5));
								do
									local node45 = Mogo.AI.SelectorNode:new();
									node43:AddChild(node45);
									do
										local node46 = Mogo.AI.SequenceNode:new();
										node45:AddChild(node46);
										node46:AddChild(Mogo.AI.InSkillCoolDown:new(5));
										node46:AddChild(Mogo.AI.CastSpell:new(5));
										node46:AddChild(Mogo.AI.EnterCD:new(0));
									end
									do
										local node50 = Mogo.AI.SequenceNode:new();
										node45:AddChild(node50);
										node50:AddChild(Mogo.AI.InSkillCoolDown:new(3));
										node50:AddChild(Mogo.AI.CastSpell:new(3));
										node50:AddChild(Mogo.AI.EnterCD:new(0));
									end
									do
										local node54 = Mogo.AI.SequenceNode:new();
										node45:AddChild(node54);
										node54:AddChild(Mogo.AI.InSkillCoolDown:new(1));
										node54:AddChild(Mogo.AI.CastSpell:new(1));
										node54:AddChild(Mogo.AI.EnterCD:new(0));
									end
									do
										local node58 = Mogo.AI.SequenceNode:new();
										node45:AddChild(node58);
										node58:AddChild(Mogo.AI.InSkillCoolDown:new(2));
										node58:AddChild(Mogo.AI.CastSpell:new(2));
										node58:AddChild(Mogo.AI.EnterCD:new(0));
									end
									node45:AddChild(Mogo.AI.EnterRest:new(100));
								end
							end
							do
								local node63 = Mogo.AI.SequenceNode:new();
								node38:AddChild(node63);
								node63:AddChild(Mogo.AI.InSkillRange:new(1));
								do
									local node65 = Mogo.AI.SelectorNode:new();
									node63:AddChild(node65);
									do
										local node66 = Mogo.AI.SequenceNode:new();
										node65:AddChild(node66);
										do
											local node67 = Mogo.AI.SelectorNode:new();
											node66:AddChild(node67);
											node67:AddChild(Mogo.AI.InSkillCoolDown:new(5));
											node67:AddChild(Mogo.AI.InSkillCoolDown:new(3));
										end
										node66:AddChild(Mogo.AI.ChooseCastPoint:new(5));
										node66:AddChild(Mogo.AI.MoveTo:new());
									end
									do
										local node72 = Mogo.AI.SequenceNode:new();
										node65:AddChild(node72);
										node72:AddChild(Mogo.AI.InSkillCoolDown:new(1));
										node72:AddChild(Mogo.AI.CastSpell:new(1));
										node72:AddChild(Mogo.AI.EnterCD:new(0));
									end
									do
										local node76 = Mogo.AI.SequenceNode:new();
										node65:AddChild(node76);
										node76:AddChild(Mogo.AI.InSkillCoolDown:new(2));
										node76:AddChild(Mogo.AI.CastSpell:new(2));
										node76:AddChild(Mogo.AI.EnterCD:new(0));
									end
									node65:AddChild(Mogo.AI.EnterRest:new(100));
								end
							end
							do
								local node81 = Mogo.AI.SequenceNode:new();
								node38:AddChild(node81);
								node81:AddChild(Mogo.AI.ChooseCastPoint:new(1));
								node81:AddChild(Mogo.AI.MoveTo:new());
							end
							node38:AddChild(Mogo.AI.EnterRest:new(0));
						end
					end
				end
			end

			return tmp
end

return BT2009:new()
