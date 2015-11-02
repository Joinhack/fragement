local Mogo = require "BTNode"
require "DecoratorNodes"
require "ConditionNodes"
require "ActionNodes"

BT2017 = Mogo.AI.BehaviorTreeRoot:new()

function BT2017:new()
		 
			local tmp = {}
			setmetatable(tmp, {__index = BT2017})
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
					local node6 = Mogo.AI.SequenceNode:new();
					node1:AddChild(node6);
					do
						local node7 = Mogo.AI.SelectorNode:new();
						node6:AddChild(node7);
						node7:AddChild(Mogo.AI.HasFightTarget:new());
						node7:AddChild(Mogo.AI.AOI:new());
					end
					do
						local node10 =  Mogo.AI.Not:new();
						node6:AddChild(node10);
						node10:Proxy(Mogo.AI.ISCD:new());
					end
					node6:AddChild(Mogo.AI.IsTargetCanBeAttack:new());
					do
						local node13 = Mogo.AI.SelectorNode:new();
						node6:AddChild(node13);
						do
							local node14 = Mogo.AI.SequenceNode:new();
							node13:AddChild(node14);
							node14:AddChild(Mogo.AI.InSkillCoolDown:new(3));
							do
								local node16 = Mogo.AI.SelectorNode:new();
								node14:AddChild(node16);
								do
									local node17 = Mogo.AI.SequenceNode:new();
									node16:AddChild(node17);
									node17:AddChild(Mogo.AI.InSkillRange:new(3));
									node17:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,100));
									node17:AddChild(Mogo.AI.CastSpell:new(3));
									node17:AddChild(Mogo.AI.EnterCD:new(0));
								end
								do
									local node22 = Mogo.AI.SequenceNode:new();
									node16:AddChild(node22);
									node22:AddChild(Mogo.AI.ChooseCastPoint:new(3));
									node22:AddChild(Mogo.AI.MoveTo:new());
								end
							end
						end
						do
							local node25 = Mogo.AI.SequenceNode:new();
							node13:AddChild(node25);
							node25:AddChild(Mogo.AI.InSkillCoolDown:new(2));
							do
								local node27 = Mogo.AI.SelectorNode:new();
								node25:AddChild(node27);
								do
									local node28 = Mogo.AI.SequenceNode:new();
									node27:AddChild(node28);
									node28:AddChild(Mogo.AI.InSkillRange:new(2));
									node28:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,100));
									node28:AddChild(Mogo.AI.CastSpell:new(2));
									node28:AddChild(Mogo.AI.EnterCD:new(0));
								end
								do
									local node33 = Mogo.AI.SequenceNode:new();
									node27:AddChild(node33);
									node33:AddChild(Mogo.AI.ChooseCastPoint:new(2));
									node33:AddChild(Mogo.AI.MoveTo:new());
								end
							end
						end
						do
							local node36 = Mogo.AI.SequenceNode:new();
							node13:AddChild(node36);
							node36:AddChild(Mogo.AI.InSkillCoolDown:new(1));
							do
								local node38 = Mogo.AI.SequenceNode:new();
								node36:AddChild(node38);
								node38:AddChild(Mogo.AI.InSkillRange:new(2));
								do
									local node40 =  Mogo.AI.Not:new();
									node38:AddChild(node40);
									node40:Proxy(Mogo.AI.InSkillCoolDown:new(2));
								end
								node38:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.lt,100));
								node38:AddChild(Mogo.AI.CastSpell:new(1));
								node38:AddChild(Mogo.AI.EnterCD:new(0));
							end
						end
						node13:AddChild(Mogo.AI.Think:new());
					end
				end
			end

			return tmp
end

return BT2017:new()
