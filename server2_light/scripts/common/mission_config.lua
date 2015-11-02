local cfg = {

----客户端与服务器通讯使用msg_id
--MSG_ENTER_MISSION                  = 1,         --进入指定难度的关卡副本
--MSG_EXIT_MISSION                   = 2,         --胜利前退出关卡副本
--MSG_START_MISSION                  = 3,         --客户端通知副本开始
--MSG_GET_STARS_MISSION              = 4,         --客户端获取所有副本的星数
--MSG_RESET_MISSION_TIMES            = 5,         --客户端请求重置玩家的挑战次数
--MSG_GET_MISSION_TIMES              = 6,         --客户端请求获取已挑战次数
--MSG_GET_FINISHED_MISSIONS          = 7,         --客户端请求已完成的副本关卡信息
--MSG_GET_NOTIFY_TO_CLENT_EVENT      = 8,         --服务器通知客户端事件发生
--MSG_NOTIFY_TO_CLIENT_RESULT        = 9,         --通知客户端结果
--MSG_GET_MISSION_LEFT_TIME          = 10,        --客户端获取副本关卡的剩余时间
--MSG_SPAWNPOINT_START               = 11,        --客户端通知服务器指定刷怪点开始刷怪
--MSG_SPWANPOINT_STOP                = 12,        --客户端通知服务器指定刷怪点停止刷怪
--MSG_NOTIFY_TO_CLIENT_RESULT_SUCCESS= 13,        --服务器通知客户端成功，并下通关时间和星数
--MSG_NOTIFY_TO_CLIENT_RESULT_FAILED = 14,        --服务器通知客户端失败
--MSG_GET_MISSION_REWARDS            = 15,        --客户端获取奖励池信息
--MSG_CLIENT_MISSION_INFO            = 16,        --客户端设置的副本关卡状态，服务器无须理解其格式
--MSG_CLIENT_RESET                   = 17,        --客户端收到以后把副本的机关等状态重置成开始状态
--MSG_SWEEP_MISSION                  = 18,        --扫荡制定难度的关卡副本
--MSG_NOTIFY_MISSION_EXP             = 19,        --通知客户端飘经验
--MSG_QUIT_MISSION                   = 20,        --胜利后退出管卡副本
--MSG_ADD_FRIEND_DEGREE              = 21,        --副本胜利加好友度
--MSG_NOTIFY_TO_CLENT_SPAWNPOINT     = 22,        --服务器通知客户端刷怪点的怪已经死了
--MSG_UPLOAD_COMBO                   = 23,        --客户端上传连击数
--MSG_GET_MISSION_TRESURE_REWARDS    = 24,        --客户端获取已经拿到的关卡副本宝箱奖励
--MSG_REVIVE                         = 25,        --复活
--MSG_GET_REVIVE_TIMES               = 26,        --客户端获取已复活次数

----cell到base的请求部分
--MSG_REVIVE_SUCCESS        = 250,     --cell通知base复活成功
--MSG_ADD_FRIEND_DEGREE_C2B = 251,     --cell通知base加好友好感度
--MSG_EXIT_MAP              = 252,     --cell通知base离开地图
--MSG_ADD_REWARD_ITEMS      = 253,     --cell通知base增加奖励道具
--MSG_ADD_FINISHED_MISSIONS = 254,     --cell通知base累加已通关关卡
--MSG_ADD_MISSION_TIMES     = 255,     --cell开始副本以后通知base累加挑战次数


--副本关卡信息
SPECIAL_MAP_INFO_OWNER_DBID                           = 1,    --副本所有者的dbid
SPECIAL_MAP_INFO_OWNER_NAME                           = 2,    --副本所有者的名字
SPECIAL_MAP_INFO_OWNER_MBSTR                          = 3,    --副本所有者的mb
SPECIAL_MAP_INFO_MISSION_ID                           = 4,    --副本的关卡ID
SPECIAL_MAP_INFO_DIFFICULT                            = 5,    --副本的关卡难度
SPECIAL_MAP_INFO_STARTED_SPAWN_POINT                  = 6,    --客户端已经触发的刷怪点
SPECIAL_MAP_INFO_MISSION_PROCESS                      = 7,    --副本进度
SPECIAL_MAP_INFO_END_TIMER_ID                         = 8,    --副本结束定时器ID
SPECIAL_MAP_INFO_SUCCESS_TIMER_ID                     = 9,    --副本胜利的定时器ID
SPECIAL_MAP_INFO_FINISHED_SPAWN_POINT                 = 10,   --已经完成的刷怪点
SPECIAL_MAP_INFO_MONSTER_AUTO_DIE                     = 11,   --副本怪物自动死亡定时器ID
SPECIAL_MAP_INFO_DROP                                 = 12,   --副本已经掉落的信息
SPECIAL_MAP_INFO_TOWER_DESTORY_TIMER_ID               = 13,   --试炼之塔开始被陨石砸的定时器
SPECIAL_MAP_INFO_AVATAR_DAMAGE                        = 14,   --每个玩家的输出伤害
SPECAIL_MAP_INFO_DELAY_EVENT                          = 15,   --延迟触发的事件
SPECAIL_MAP_INFO_DELAY_TIMER_ID                       = 16,   --延迟触发的事件定时器ID

--副本关卡事件
SPECIAL_MAP_EVENT_SPAWNPOINT_MONSTER_ALL_DEAD         = 1,    --副本指定刷怪点的怪全部死亡
SPECIAL_MAP_EVENT_INIT                                = 2,    --副本初始化事件


--客户端通知服务器刷怪点的开启或者关闭动作
SPAWNPOINT_START    =    1,
SPAWNPOINT_STOP     =    0,


--副本关卡的评价
MISSION_VALUATION_NOT_PASS    = 1,       --标识没有通关 C
MISSION_VALUATION_B           = 2,       --标识副本评价 B
MISSION_VALUATION_A           = 3,       --标识副本评价 A
MISSION_VALUATION_S           = 4,       --标识副本评价 S

--翻牌公告的消息ID
RANDOM_REWARD_MSG_PURPLE     = 46996,  --紫色装备公告
RANDOM_REWARD_MSG_ORANGE     = 46997,  --橙色装备公告

--迷雾深渊副本用到的key
MWSY_MISSION_LAST_TIME  = 1,        --上一次触发迷雾深渊的时间戳
MWSY_MISSION_DIFFICULTY = 2,        --当前迷雾深渊的进度
MWSY_MISSION_IS_FINISH  = 3,        --表示当前的迷雾深渊副本是否已经完成

MWSY_MISSION_DIFFICULTY_JD = 1,     --迷雾深渊难度简单
MWSY_MISSION_DIFFICULTY_JY = 2,     --迷雾深渊难度精英
MWSY_MISSION_DIFFICULTY_DY = 3,     --迷雾深渊难度地狱

}

mission_config = cfg
return mission_config
