local cfg = {

----------------------------------------------------------
----------------------事件接口----------------------------
----------------------------------------------------------

EVENT_AVATAR_DEADTH                    = 1,  --玩家死亡事件
EVENT_MONSTER_DEADTH                   = 2,  --怪物死亡事件
EVENT_AVATAR_USE_DRUG                  = 3,  --玩家喝药事件
EVENT_AVATAR_PROPERTIES_RECALCULATE    = 4,  --通知角色重新计算战斗属性值事件
EVENT_EVENT_BEGIN                      = 5,  --活动开启{活动ID}
EVENT_EVENT_END                        = 6,  --活动结束{活动ID}
EVENT_SPIRIT_LEVELUP_SKILL             = 7,  --契约技能升级{升级前等级，升级后等级}
EVENT_SPIRIT_LEVELUP_MARK              = 8,  --元素刻印升级{升级前等级，升级后等级}
EVENT_ROLE_LEVELUP                     = 9,  --玩家升级{事件ID,升级后等级}
EVENT_PLAYER_GET_EQUP                  = 10, --玩家获得道具{事件ID, 道具ID}
EVENT_PLAYER_ADD_FRIEND_SCCESS         = 11, --加好友成功{事件ID, 好友数量}
EVENT_PLAYER_KILL_MONSTER              = 12, --杀死怪物{事件ID, 怪物ID}
EVENT_KILL_BOSS                        = 13, --击杀世界boss
EVENT_FINISH_TOWER                     = 14, --完成试炼之塔
EVENT_ENTER_BOSS                       = 15, --参加世界boss
EVENT_VIP_LEVEL_CHANGED                = 16, --vip等级变化

EVENT_FINISH_FB_NORMAL					=17,	--	完成普通副本n次
EVENT_FINISH_FB_HARD					=18,	--	完成困难副本n次
EVENT_STRONG_EQUIP 						=19,	--	强化装备
EVENT_SKILL_LEVEL_UP  					=20,	--	升级技能
EVENT_COST_DIAMOND						=21,	--	消耗钻石
EVENT_LIANJIN						=22,	--	炼金
EVENT_RUNE_EXTRACT					=23,	--	龙语抽符文
EVENT_GHOST_DEVELOP					=24,	--	精灵培养（待定）
EVENT_JEWRL_COMBINE 				=25,	--	合成宝石
EVENT_GIVE_ENERGY					=26,	--	赠送好友体力
EVENT_COMPETE_PVP					=27,	--	竞技场pvp
EVENT_TD_FINISH						=28,	--	参与圣域守卫战
EVENT_GATE_FINISH 					=29,	--	参与湮灭之门
EVENT_TOWER_FINISH					=30,	--	参与试炼之塔
EVENT_LONGJIN_INJECT 				=31,	--	参与公会龙晶注魔
EVENT_UNION_WAR						=32,	--	公会战
EVENT_REFRESH_SHOP					=33,	--	刷新商店


EVENT_BREAK_EQUIP					=34,	--	分解装备 
EVENT_GET_ENERGY_FROM_EVENT			=35,	--	领取体力 (运营活动)
EVENT_GET_LOGIN_REWARD				=36,	--	领取登陆奖励 
EVENT_GET_REWARD_FROM_COMP			=37,	--	竞技场积分奖励兑换 
EVENT_MAKE_FUWEN					=38,	--	合成符文 
EVENT_REFRESH_COMP					=39,	--	竞技场刷新对手 
EVENT_BUY_ENERGY					=40,	--	购买体力 
EVENT_ROLL_CARD						=41,	--	副本结算翻牌 （missionRandomReward表，找前端）
EVENT_ORC							=42,	--	兽人必死
EVENT_DRAGON						=43,	--	飞龙
EVENT_ORC_RUSH_COUNT				=44,	--	单次兽人必须死副本结束时完成的波数   数量 
EVENT_ORC_MVP						=45,	--	单次兽人必须死副本结束时为MVP（输出最高）  次数  
EVENT_ORC_WIN						=46,	--	兽人必须死战斗副本胜利 次数 
EVENT_DRAGON_WIN					=47,	--	飞龙大赛袭击胜利    次数   
EVENT_DRAGON_LEVELUP				=48,	--	飞龙大赛提升飞龙品质  次数   
EVENT_DRAGON_BEST					=49,	--	使用金色品质飞龙进行飞龙大赛  次数   



}

event_config = cfg
return event_config