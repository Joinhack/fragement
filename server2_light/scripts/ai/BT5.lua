local Mogo = require "BTNode"
require "DecoratorNodes"
require "ConditionNodes"
require "ActionNodes"

BT5 = Mogo.AI.BehaviorTreeRoot:new()

function BT5:new()
		 
			local tmp = {}
			setmetatable(tmp, {__index = BT5})
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
							node14:AddChild(Mogo.AI.LastCastIs:new(2));
							do
								local node16 = Mogo.AI.SelectorNode:new();
								node14:AddChild(node16);
								node16:AddChild(Mogo.AI.InSkillRange:new(3));
								do
									local node18 =  Mogo.AI.Not:new();
									node16:AddChild(node18);
									node18:Proxy(Mogo.AI.ReinitLastCast:new());
								end
							end
							node14:AddChild(Mogo.AI.CastSpell:new(3));
							node14:AddChild(Mogo.AI.EnterCD:new(0));
						end
						do
							local node22 = Mogo.AI.SequenceNode:new();
							node13:AddChild(node22);
							node22:AddChild(Mogo.AI.LastCastIs:new(1));
							do
								local node24 = Mogo.AI.SelectorNode:new();
								node22:AddChild(node24);
								node24:AddChild(Mogo.AI.InSkillRange:new(2));
								do
									local node26 =  Mogo.AI.Not:new();
									node24:AddChild(node26);
									node26:Proxy(Mogo.AI.ReinitLastCast:new());
								end
							end
							node22:AddChild(Mogo.AI.CastSpell:new(2));
							node22:AddChild(Mogo.AI.EnterCD:new(0));
						end
						do
							local node30 = Mogo.AI.SequenceNode:new();
							node13:AddChild(node30);
							node30:AddChild(Mogo.AI.InSkillCoolDown:new(5));
							node30:AddChild(Mogo.AI.InSkillRange:new(5));
							node30:AddChild(Mogo.AI.CastSpell:new(5));
							node30:AddChild(Mogo.AI.EnterCD:new(5000));
						end
						do
							local node35 = Mogo.AI.SequenceNode:new();
							node13:AddChild(node35);
							node35:AddChild(Mogo.AI.InSkillCoolDown:new(4));
							node35:AddChild(Mogo.AI.InSkillRange:new(4));
							node35:AddChild(Mogo.AI.CastSpell:new(4));
							node35:AddChild(Mogo.AI.EnterCD:new(2000));
						end
						do
							local node40 = Mogo.AI.SequenceNode:new();
							node13:AddChild(node40);
							node40:AddChild(Mogo.AI.InSkillCoolDown:new(1));
							node40:AddChild(Mogo.AI.InSkillRange:new(1));
							node40:AddChild(Mogo.AI.CastSpell:new(1));
							node40:AddChild(Mogo.AI.EnterCD:new(0));
						end
						do
							local node45 = Mogo.AI.SelectorNode:new();
							node13:AddChild(node45);
							do
								local node46 =  Mogo.AI.Not:new();
								node45:AddChild(node46);
								node46:Proxy(Mogo.AI.ReinitLastCast:new());
							end
							do
								local node48 = Mogo.AI.SequenceNode:new();
								node45:AddChild(node48);
								node48:AddChild(Mogo.AI.InSkillCoolDown:new(5));
								do
									local node50 =  Mogo.AI.Not:new();
									node48:AddChild(node50);
									node50:Proxy(Mogo.AI.InSkillRange:new(5));
								end
								node48:AddChild(Mogo.AI.ChooseCastPoint:new(5));
								node48:AddChild(Mogo.AI.MoveTo:new());
							end
							do
								local node54 = Mogo.AI.SequenceNode:new();
								node45:AddChild(node54);
								node54:AddChild(Mogo.AI.InSkillCoolDown:new(4));
								do
									local node56 =  Mogo.AI.Not:new();
									node54:AddChild(node56);
									node56:Proxy(Mogo.AI.InSkillRange:new(4));
								end
								node54:AddChild(Mogo.AI.ChooseCastPoint:new(4));
								node54:AddChild(Mogo.AI.MoveTo:new());
							end
							do
								local node60 = Mogo.AI.SequenceNode:new();
								node45:AddChild(node60);
								do
									local node61 =  Mogo.AI.Not:new();
									node60:AddChild(node61);
									node61:Proxy(Mogo.AI.InSkillRange:new(1));
								end
								node60:AddChild(Mogo.AI.ChooseCastPoint:new(1));
								node60:AddChild(Mogo.AI.MoveTo:new());
							end
							do
								local node65 = Mogo.AI.SequenceNode:new();
								node45:AddChild(node65);
								node65:AddChild(Mogo.AI.EnterRest:new(1000));
								node65:AddChild(Mogo.AI.Think:new());
							end
						end
					end
				end
			end

			return tmp
end
return BT5:new()
