local Mogo = require "BTNode"
require "DecoratorNodes" 
require "ConditionNodes"
require "ActionNodes" 

BTOne = Mogo.AI.BehaviorTreeRoot:new()

function BTOne:new()
		 
			local tmp = {}
			setmetatable(tmp, {__index = BTOne})
			tmp.__index = tmp

			do
				local node1 = Mogo.AI.SelectorNode:new();
				self:AddChild(node1);
				node1:AddChild(Mogo.AI.ISCD:new());
				do
					local node3 = Mogo.AI.SequenceNode:new();
					node1:AddChild(node3);
					node3:AddChild(Mogo.AI.ISRest:new());
					node3:AddChild(Mogo.AI.Rest:new());
				end
				do
					local node6 = Mogo.AI.SequenceNode:new();
					node1:AddChild(node6);
					do
						local node7 =  Mogo.AI.Not:new();
						node6:AddChild(node7);
						do
							local node8 = Mogo.AI.SelectorNode:new();
							node7:Proxy(node8);
							do
								local node9 = Mogo.AI.SequenceNode:new();
								node8:AddChild(node9);
								node9:AddChild(Mogo.AI.CmpEnemyNum:new(Mogo.AI.CmpType.eq,0));
								node9:AddChild(Mogo.AI.EnterPatrol:new());
							end
							do
								local node12 = Mogo.AI.SequenceNode:new();
								node8:AddChild(node12);
								node12:AddChild(Mogo.AI.EnterFight:new());
							end
						end
					end
				end
				do
					local node14 = Mogo.AI.SequenceNode:new();
					node1:AddChild(node14);
					node14:AddChild(Mogo.AI.ISPatrolState:new());
					do
						local node16 = Mogo.AI.SequenceNode:new();
						node14:AddChild(node16);
						node16:AddChild(Mogo.AI.EnterRest:new(10));
						node16:AddChild(Mogo.AI.Think:new());
					end
				end
				do
					local node19 = Mogo.AI.SequenceNode:new();
					node1:AddChild(node19);
					node19:AddChild(Mogo.AI.ISFightState:new());
					do
						local node21 = Mogo.AI.SelectorNode:new();
						node19:AddChild(node21);
						node21:AddChild(Mogo.AI.HasFightTarget:new());
						node21:AddChild(Mogo.AI.AOI:new());
					end
					node19:AddChild(Mogo.AI.IsTargetCanBeAttack:new());
					do
						local node25 = Mogo.AI.SelectorNode:new();
						node19:AddChild(node25);
						do
							local node26 = Mogo.AI.SelectorNode:new();
							node25:AddChild(node26);
							do
								local node27 = Mogo.AI.SequenceNode:new();
								node26:AddChild(node27);
								node27:AddChild(Mogo.AI.InSkillRange:new(1));
								node27:AddChild(Mogo.AI.CastSpell:new(1));
								node27:AddChild(Mogo.AI.EnterCD:new(2));
							end
							do
								local node31 = Mogo.AI.SequenceNode:new();
								node26:AddChild(node31);
								node31:AddChild(Mogo.AI.CmpRate:new(Mogo.AI.CmpType.le,50));
								node31:AddChild(Mogo.AI.ChooseCastPoint:new(1));
								node31:AddChild(Mogo.AI.MoveTo:new());
							end
						end
						do
							local node35 = Mogo.AI.SelectorNode:new();
							node25:AddChild(node35);
							do
								local node36 = Mogo.AI.SequenceNode:new();
								node35:AddChild(node36);
								node36:AddChild(Mogo.AI.InSkillRange:new(2));
								node36:AddChild(Mogo.AI.CastSpell:new(2));
								node36:AddChild(Mogo.AI.EnterCD:new(2));
							end
							do
								local node40 = Mogo.AI.SequenceNode:new();
								node35:AddChild(node40);
								node40:AddChild(Mogo.AI.ChooseCastPoint:new(2));
								node40:AddChild(Mogo.AI.MoveTo:new());
							end
						end
					end
				end
			end

			return tmp
end

