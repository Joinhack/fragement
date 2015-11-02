local Mogo = require "BTNode"
require "DecoratorNodes"
require "ConditionNodes"
require "ActionNodes"

BT7 = Mogo.AI.BehaviorTreeRoot:new()

function BT7:new()
		 
			local tmp = {}
			setmetatable(tmp, {__index = BT7})
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
							node14:AddChild(Mogo.AI.LastCastIs:new(1));
							do
								local node16 = Mogo.AI.SelectorNode:new();
								node14:AddChild(node16);
								node16:AddChild(Mogo.AI.InSkillRange:new(2));
								do
									local node18 =  Mogo.AI.Not:new();
									node16:AddChild(node18);
									node18:Proxy(Mogo.AI.ReinitLastCast:new());
								end
							end
							node14:AddChild(Mogo.AI.CastSpell:new(2));
							node14:AddChild(Mogo.AI.EnterCD:new(0));
						end
						do
							local node22 = Mogo.AI.SequenceNode:new();
							node13:AddChild(node22);
							node22:AddChild(Mogo.AI.InSkillCoolDown:new(3));
							node22:AddChild(Mogo.AI.InSkillRange:new(3));
							node22:AddChild(Mogo.AI.CastSpell:new(3));
							node22:AddChild(Mogo.AI.EnterCD:new(0));
						end
						do
							local node27 = Mogo.AI.SequenceNode:new();
							node13:AddChild(node27);
							node27:AddChild(Mogo.AI.InSkillCoolDown:new(4));
							node27:AddChild(Mogo.AI.InSkillRange:new(4));
							node27:AddChild(Mogo.AI.CastSpell:new(3));
							node27:AddChild(Mogo.AI.EnterCD:new(0));
						end
						do
							local node32 = Mogo.AI.SequenceNode:new();
							node13:AddChild(node32);
							node32:AddChild(Mogo.AI.InSkillCoolDown:new(1));
							node32:AddChild(Mogo.AI.InSkillRange:new(1));
							node32:AddChild(Mogo.AI.CastSpell:new(1));
							node32:AddChild(Mogo.AI.EnterCD:new(0));
						end
						do
							local node37 = Mogo.AI.SelectorNode:new();
							node13:AddChild(node37);
							do
								local node38 =  Mogo.AI.Not:new();
								node37:AddChild(node38);
							end
							do
								local node39 = Mogo.AI.SequenceNode:new();
								node37:AddChild(node39);
								node39:AddChild(Mogo.AI.ChooseCastPoint:new(1));
								node39:AddChild(Mogo.AI.MoveTo:new());
							end
							do
								local node42 = Mogo.AI.SequenceNode:new();
								node37:AddChild(node42);
								node42:AddChild(Mogo.AI.EnterRest:new(1000));
								node42:AddChild(Mogo.AI.Think:new());
							end
						end
					end
				end
			end

			return tmp
end
return BT7:new()
