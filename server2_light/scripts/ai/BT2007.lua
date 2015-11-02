local Mogo = require "BTNode"
require "DecoratorNodes"
require "ConditionNodes"
require "ActionNodes"

BT2007 = Mogo.AI.BehaviorTreeRoot:new()

function BT2007:new()
		 
			local tmp = {}
			setmetatable(tmp, {__index = BT2007})
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
							node11:AddChild(Mogo.AI.InSkillCoolDown:new(12));
							do
								local node13 = Mogo.AI.SequenceNode:new();
								node11:AddChild(node13);
								node13:AddChild(Mogo.AI.CastSpell:new(12));
								node13:AddChild(Mogo.AI.EnterCD:new(0));
							end
						end
						do
							local node16 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node16);
							node16:AddChild(Mogo.AI.InSkillCoolDown:new(11));
							do
								local node18 = Mogo.AI.SequenceNode:new();
								node16:AddChild(node18);
								node18:AddChild(Mogo.AI.CastSpell:new(11));
								node18:AddChild(Mogo.AI.EnterCD:new(0));
							end
						end
						do
							local node21 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node21);
							node21:AddChild(Mogo.AI.InSkillCoolDown:new(10));
							do
								local node23 = Mogo.AI.SequenceNode:new();
								node21:AddChild(node23);
								node23:AddChild(Mogo.AI.CastSpell:new(10));
								node23:AddChild(Mogo.AI.EnterCD:new(0));
							end
						end
						do
							local node26 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node26);
							node26:AddChild(Mogo.AI.InSkillCoolDown:new(9));
							do
								local node28 = Mogo.AI.SequenceNode:new();
								node26:AddChild(node28);
								node28:AddChild(Mogo.AI.CastSpell:new(9));
								node28:AddChild(Mogo.AI.EnterCD:new(0));
							end
						end
						do
							local node31 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node31);
							node31:AddChild(Mogo.AI.InSkillCoolDown:new(8));
							do
								local node33 = Mogo.AI.SequenceNode:new();
								node31:AddChild(node33);
								node33:AddChild(Mogo.AI.CastSpell:new(8));
								node33:AddChild(Mogo.AI.EnterCD:new(0));
							end
						end
						do
							local node36 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node36);
							node36:AddChild(Mogo.AI.InSkillCoolDown:new(7));
							do
								local node38 = Mogo.AI.SequenceNode:new();
								node36:AddChild(node38);
								node38:AddChild(Mogo.AI.CastSpell:new(7));
								node38:AddChild(Mogo.AI.EnterCD:new(0));
							end
						end
						do
							local node41 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node41);
							node41:AddChild(Mogo.AI.InSkillCoolDown:new(6));
							do
								local node43 = Mogo.AI.SequenceNode:new();
								node41:AddChild(node43);
								node43:AddChild(Mogo.AI.CastSpell:new(6));
								node43:AddChild(Mogo.AI.EnterCD:new(0));
							end
						end
						do
							local node46 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node46);
							node46:AddChild(Mogo.AI.InSkillCoolDown:new(5));
							do
								local node48 = Mogo.AI.SequenceNode:new();
								node46:AddChild(node48);
								node48:AddChild(Mogo.AI.CastSpell:new(5));
								node48:AddChild(Mogo.AI.EnterCD:new(0));
							end
						end
						do
							local node51 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node51);
							node51:AddChild(Mogo.AI.InSkillCoolDown:new(4));
							do
								local node53 = Mogo.AI.SequenceNode:new();
								node51:AddChild(node53);
								node53:AddChild(Mogo.AI.CastSpell:new(4));
								node53:AddChild(Mogo.AI.EnterCD:new(0));
							end
						end
						do
							local node56 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node56);
							node56:AddChild(Mogo.AI.InSkillCoolDown:new(3));
							do
								local node58 = Mogo.AI.SequenceNode:new();
								node56:AddChild(node58);
								node58:AddChild(Mogo.AI.CastSpell:new(3));
								node58:AddChild(Mogo.AI.EnterCD:new(0));
							end
						end
						do
							local node61 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node61);
							node61:AddChild(Mogo.AI.InSkillCoolDown:new(2));
							do
								local node63 = Mogo.AI.SequenceNode:new();
								node61:AddChild(node63);
								node63:AddChild(Mogo.AI.CastSpell:new(2));
								node63:AddChild(Mogo.AI.EnterCD:new(0));
							end
						end
						do
							local node66 = Mogo.AI.SequenceNode:new();
							node10:AddChild(node66);
							node66:AddChild(Mogo.AI.InSkillCoolDown:new(1));
							do
								local node68 = Mogo.AI.SequenceNode:new();
								node66:AddChild(node68);
								node68:AddChild(Mogo.AI.CastSpell:new(1));
								node68:AddChild(Mogo.AI.EnterCD:new(0));
							end
						end
						node10:AddChild(Mogo.AI.EnterRest:new(0));
					end
				end
			end

			return tmp
end

return BT2007:new()
