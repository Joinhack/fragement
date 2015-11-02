local cfg = {

--状态Id，从0开始，至63
--Avatar的cell部分状态state值
DEATH_STATE      = 0,             --死亡状态
DIZZY_STATE      = 1,             --眩晕状态
POSSESS_STATE    = 2,             --魅惑状态
IMMOBILIZE_STATE = 3,             --定身状态
SILENT_STATE     = 4,             --沉默状态
STIFF_STATE      = 5,             --僵直状态
FLOAT_STATE      = 6,             --浮空状态
DOWN_STATE       = 7,             --击倒状态
BACK_STATE       = 8,             --击退状态
UP_STATE         = 9,             --击飞状态
IMMUNITY_STATE   = 10,            --免疫状态
NO_HIT_STATE     = 11,            --无法被击中状态
SLOW_DOWN_STATE  = 12,            --减速状态
BATI_STATE       = 13,            --霸体状态

--状态Id，从64开始，至8192
--Avatar的base部分状态state值
STATE_PROCESSING_BASE_PROP        = 63,           --正在计算二级属性的状态(由于需要跨进程计算其公会等的加成，需要设置该状态防止出现异步问题)
STATE_IN_TELEPORT                 = 64,           --传送状态
STATE_TOWER_CURRENT_FLOOR_SUCCESS = 65,           --试炼之塔当前层的胜利状态
STATE_MISSION_ALL_ALLOW           = 66,           --允许进入所有关卡
STATE_SCENE_CHANGING              = 67,           --玩家正在改变场景
STATE_CONSOLE                     = 68,           --玩家正在单机副本中
}

state_config = cfg
return state_config
