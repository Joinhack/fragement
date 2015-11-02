action_config = {

--TELEPORT_ENTER_POINT = 1,  --进入传送点传送范围
--
----TELEPORT_2_MAP = 1,     --请求传送至某场景
--
--INS_REFRESH          = 8,  --重置副本次数
--INS_SWEEP            = 9,  --扫荡副本
--INS_CLICKITEM        = 10, --战斗场景点击物品
--INS_ACCEPT           = 11, --请求进入副本
--INS_ABORT            = 12, --放弃副本
--INS_ATTACK           = 13, --进入副本的战斗场景
--INS_CAST_SPELL       = 14, --战斗场景中释放技能
--INS_EXIT_CMB         = 15, --请求退出战斗场景
--INS_MOVE             = 16, --请求在战斗场景中移动
--BOSS_ACCEPT          = 17, --申请进入boss战刷怪场景
--BOSS_ABORT           = 18, --申请离开boss战刷怪场景
--BOSS_ATTACK          = 19, --申请攻击boss
--
--ITEM_USE             = 20, --使用物品
--ITEM_MOVE            = 21, --物品移动
--ITEM_REDEEM          = 22, --赎回已出售物品
--ITEM_SORT            = 23, --整理背包/仓库
--ITEM_BUY             = 24, --商店购买物品
--ITEM_GUILD_BUY       = 25, --帮派神秘商店购买物品
--ITEM_DROP            = 26, --丢弃物品
--ITEM_SELL            = 27, --出售道具
--ITEM_GUILD_GET       = 28, --获取神秘商店数据
--ITEM_GUILD_GC_REFRESH = 29, --元宝刷新神秘商店数据

--关卡系统对应的操作
MSG_ENTER_MISSION                  = 1,         --进入指定难度的关卡副本
MSG_EXIT_MISSION                   = 2,         --胜利前退出关卡副本
MSG_START_MISSION                  = 3,         --客户端通知副本开始
MSG_GET_STARS_MISSION              = 4,         --客户端获取所有副本的星数
MSG_RESET_MISSION_TIMES            = 5,         --客户端请求重置玩家的挑战次数
MSG_GET_MISSION_TIMES              = 6,         --客户端请求获取已挑战次数
MSG_GET_FINISHED_MISSIONS          = 7,         --客户端请求已完成的副本关卡信息
MSG_GET_NOTIFY_TO_CLENT_EVENT      = 8,         --服务器通知客户端事件发生
MSG_NOTIFY_TO_CLIENT_RESULT        = 9,         --通知客户端结果
MSG_GET_MISSION_LEFT_TIME          = 10,        --客户端获取副本关卡的剩余时间
MSG_SPAWNPOINT_START               = 11,        --客户端通知服务器指定刷怪点开始刷怪
MSG_SPWANPOINT_STOP                = 12,        --客户端通知服务器指定刷怪点停止刷怪
MSG_NOTIFY_TO_CLIENT_RESULT_SUCCESS= 13,        --服务器通知客户端成功，并下通关时间和星数
MSG_NOTIFY_TO_CLIENT_RESULT_FAILED = 14,        --服务器通知客户端失败
MSG_GET_MISSION_REWARDS            = 15,        --客户端获取奖励池信息
MSG_CLIENT_MISSION_INFO            = 16,        --客户端设置的副本关卡状态，服务器无须理解其格式
MSG_CLIENT_RESET                   = 17,        --客户端收到以后把副本的机关等状态重置成开始状态
MSG_SWEEP_MISSION                  = 18,        --扫荡制定难度的关卡副本
MSG_NOTIFY_MISSION_EXP             = 19,        --通知客户端飘经验
MSG_QUIT_MISSION                   = 20,        --胜利后退出管卡副本
MSG_ADD_FRIEND_DEGREE              = 21,        --副本胜利加好友度
MSG_NOTIFY_TO_CLENT_SPAWNPOINT     = 22,        --服务器通知客户端刷怪点的怪已经死了
MSG_UPLOAD_COMBO                   = 23,        --客户端上传连击数
MSG_GET_MISSION_TREASURE_REWARDS   = 24,        --客户端获取已经拿到的关卡副本宝箱奖励
MSG_REVIVE                         = 25,        --复活
MSG_GET_REVIVE_TIMES               = 26,        --客户端获取已复活次数

--试炼之塔对应的操作id
MSG_GET_TOWER_INFO                 = 27,          --获取试炼之塔的数据
MSG_ENTER_TOWER                    = 28,          --进入指试炼之塔的指定层
MSG_TOWER_SWEEP                    = 29,          --普通扫荡
MSG_TOWER_VIP_SWEEP                = 30,          --VIP扫荡
MSG_CLEAR_TOWER_SWEEP_CD           = 31,          --清除扫荡副本的CD
MSG_CLIENT_TOWER_SUCCESS           = 32,          --试炼之塔成功后由服务器返回到客户端
MSG_CLIENT_TOWER_FAIL              = 33,          --试炼之态失败后有服务器返回到客户端
MSG_CLIENT_REPORT                  = 34,          --服务器向客户端发送战报
MSG_TOWER_SWEEP_ALL                = 35,          --全部扫荡

--公会系统客户端与服务器交互的msg_id
MSG_GET_GUILDS                     = 36,          --分页获取服务器的公会，                          请求：(参数1：开始索引Index，参数2：偏移值，参数3：无效    例子：从第1个公会开始，取10个公会，则传 1, 10)； 回应lua_table：({1=数量, 2={1={1=公会dbid,2=名称,3=等级,4=人数}, ...}})
MSG_GET_GUILDS_COUNT               = 37,          --获取公会的个数，                                       请求：(参数无效)； 回应lua_table：({1=数量})
MSG_CREATE_GUILD                   = 38,          --创建一个公会                                                 请求：(参数1：无效， 参数2：无效， 参数3：公会名称)；回应lua_table：({1=公会名, 2=公会人数， 3=公会职位})
MSG_GET_GUILD_INFO                 = 39,          --获取玩家自己的公会信息                         请求：(参数无须)；回应lua_table：({1=公会名, 2=公会职位})
MSG_SET_GUILD_ANNOUNCEMENT         = 40,          --设置公会公告                                                请求：(参数1：无效， 参数2：无效， 参数3：公告全文)； 回应lua_table：({})
MSG_GET_GUILD_ANNOUNCEMENT         = 41,          --获取公会公告                                                请求：(参数无效)； 回应lua_table：({1=公告全文})
MSG_APPLY_TO_JOIN                  = 42,          --申请加入指定公会                                       请求：(参数1：申请加入的公会的dbid， 参数2：无效， 参数3：无效)；回应lua_table：({})
MSG_APPLY_TO_JOIN_NOTIFY           = 43,          --通知会长和副会长有人申请了                回应lua_table：({1=申请人姓名})
MSG_GET_GUILD_DETAILED_INFO        = 44,          --获取公会详细信息                                       请求：(参数无效)； 回应lua_table：({1=公告,2=公会资金,3=公会等级,4=公会人数,5=公会长名称,6=当前龙晶值,7={技能ID=等级,...}})
MSG_GET_GUILD_MESSAGES_COUNT       = 45,         --获取公会消息的数量                                  请求：(参数1：消息类型， 参数2：无效， 参数3：无效              消息类型目前只有一种，传1表示获取申请加入公会的消息类型)；回应lua_table：({1=消息数量})
MSG_GET_GUILD_MESSAGES             = 46,         --分页获取公会消息                                       请求：(参数1：开始索引Index，参数2：偏移值，参数3：消息类型(先转成字符串))； 回应lua_table：({1=消息数量,2={1={1=消息dbid,2=申请人名称,3=申请人职业,4=申请人等级,5=申请人战力}, ...}})
MSG_ANSWER_APPLY                   = 47,         --回应申请                                                         请求：(参数1：同意或者不同意(0或者1)， 参数2：申请消息的dbid，参数3：无效)； 回应lua_table：({1=同意或者不同意})
MSG_INVITE                         = 48,         --邀请好友加入公会                                       请求：(参数1：被邀请的人的dbid， 参数2：无效， 参数3：无效)；回应lua_table：({1=被邀请的人的dbid,...})
MSG_INVITED                        = 49,         --通知客户端被某公会邀请                          请求：()； 回应lua_table：({1=邀请流水号, 2=发出邀请的公会名称})
MSG_ANSWER_INVITE                  = 50,         --回应公会邀请                                                请求：(参数1：邀请号， 参数2：同意或者不同意，参数3：无效)； 回应lua_table：({1=发出邀请的公会名称})
MSG_APPLY_TO_JOIN_RESULT           = 51,         --通知给客户端申请结果                              请求：()； 回应lua_table：({1=被同意或者拒绝, 2=同意或者拒绝的公会名字})
MSG_QUIT                           = 52,         --退出公会                                                         请求：(参数无效)；回应lua_table：({})
MSG_PROMOTE                        = 53,         --升职                                                                  请求：(参数1：被升级的人的dbid， 参数2：无效， 参数3：无效)；回应lua_table：({})
MSG_DEMOTE                         = 54,         --降职                                                                 请求：(参数1：被降级的人的dbid， 参数2：无效， 参数3：无效)； 回应lua_table：({})
MSG_EXPEL                          = 55,         --开除                                                                 请求：(参数1：被开除的人的dbid， 参数2：无效， 参数3：无效)；回应lua_table：({})
MSG_DEMISE                         = 56,         --转让                                                                 请求：(参数1：被转让的人的dbid， 参数2：无效， 参数3：无效)；回应lua_table：({})
MSG_DISMISS                        = 57,         --解散                                                                 请求：(参数无效)； 回应lua_table：({})
MSG_THAW                           = 58,         --解冻                                                                 请求：(参数无效)； 回应lua_table：({})
MSG_RECHARGE                       = 59,         --注魔                                                                 请求：(参数1：注魔类型，参数2：注魔量，参数3：无效)； 回应lua_table：({})
MSG_GET_GUILD_MEMBERS              = 60,         --获取工会成员列表                                      请求：(参数1：开始索引Index，参数2：偏移值，参数3：无效)； 回应lua_table：({1={1=玩家dbid,2=姓名,3=等级,4=职位ID,5=战斗力,6=贡献度,7=上线时间}, ...})
MSG_GET_DRAGON                     = 61,         --敲龙晶                                                                请求：(参数无效)； 回应lua_table：({})
MSG_UPGRADE_GUILD_SKILL            = 62,         --升级公会技能                                                  请求：(参数1：技能类型，参数2：无效，参数3：无效)； 回应lua_table：({1=技能类型, 2=技能等级,})
MSG_GET_RECOMMEND_LIST             = 63,         --公会长和副公会长获取推荐成员列表     请求：(参数无效)； 回应lua_table：({1={1=玩家dbid,2=姓名,3=等级,4=战斗力}, ...})
MSG_GET_DRAGON_INFO                = 64,         --获取龙晶信息                                                  请求：(参数无效)； 回应lua_table：({1=注魔次数,2=上一次注魔时间})


TELEPORT_ENTER_POINT               = 65,  --进入传送点传送范围


--关卡系统的操作ID
--MSG_RESET_MISSION_TIMES            = 66,  --玩家重置关卡每天次数
MSG_GET_MISSION_SWEEP_LIST         = 66,  --获取副本的怪物和奖励
MSG_GET_RESET_TIMES                = 67,  --客户端获取关卡总的已重置次数
--MSG_GET_RESET_TIMES_BY_MISSION     = 68,  --获取指定关卡难度的已重置次数
MSG_NOTIFY_TO_CLIENT_TO_UPLOAD_COMBO=69,  --通知客户端上传连击数
MSG_GET_MISSION_DROPS               = 70,     --base获取某副本可能的掉落物
MSG_GO_TO_INIT_MAP                 = 71,  --回到王城(不收副本与否、时间是否已到等限制)
MSG_GET_SWEEP_TIMES                = 72,  --获取可扫荡次数
MSG_GET_MISSION_TREASURE           = 73,  --获取指定id的关卡副本宝箱奖励
MSG_CREATE_CLIENT_DROP             = 74,  --客户端通知服务器创建瓦罐、宝箱等的掉落物
MSG_NOTIFY_TO_CLIENT_MISSION_REWARD= 75,  --单机副本开始前服务器通知客户端奖励数据
MSG_UPLOAD_COMBO_AND_BOTTLE        = 76,  --单机副本结束，上传连击数和使用的药瓶数量

--通知试炼之塔倒数秒数
MSG_TOWER_NOTIFY_COUNT_DOWN        = 77,   --通知客户端倒数开始
MSG_TOWER_START_DESTROY            = 78,   --告诉客户端开始破坏

--关卡系统的操作ID
MSG_NOTIFY_TO_CLIENT_TO_LOAD_INIT_MAP= 79,  --通知客户端加载场景
MSG_GET_MISSION_RECORD             = 80,    --获取关卡的最优记录
MSG_NOTIFY_TO_CLIENT_MISSION_INFO  = 81,    --通知客户端关卡号和难度
MSG_GET_ACQUIRED_MISSION_BOSS_TREASURE      = 82,    --获取已经拿到的boss宝箱
MSG_GET_MISSION_BOSS_TREASURE      = 83,    --获取指定ID的boss宝箱
MSG_MWSY_MISSION_NOTIFY_CLIENT     = 84,    --服务器通知客户端触发迷雾深渊
MSG_MWSY_MISSION_GET_INFO          = 85,    --获取当前迷雾深渊的信息
MSG_MWSY_MISSION_ENTER             = 86,    --进入迷雾深渊副本

--活动系统操作ID
MSG_CAMPAIGN_GET_ONLINE_FRIENDS  = 10000,  --获取可邀请的好友列表
MSG_CAMPAIGN_INVITE              = 10001,  --邀请指定玩家
MSG_CAMPAIGN_INVITED             = 10002,  --被邀请方收到邀请信息
MSG_CAMPAIGN_INVITED_RESP        = 10003,  --回应对方的邀请
MSG_CAMPAIGN_JOIN                = 10004,  --玩家参与指定的活动
MSG_CAMPAIGN_MATCH               = 10005,  --系统通知客户端匹配结果
MSG_CAMPAIGN_LEAVE               = 10006,  --客户端请求离开队列
MSG_CAMPAIGN_RESULT              = 10007,  --服务器通知客户端结果
MSG_CAMPAIGN_REWARD_C2B          = 10008,  --cell服务器把塔防副本奖励通知到base服务器
MSG_CAMPAIGN_NOTIFY_TO_CLIENT_START=10009, --服务器通知客户端活动开始
MSG_CAMPAIGN_NOTIFY_TO_CLIENT_FINISH=10010,--服务器通知客户端活动结束
MSG_CAMPAIGN_COUNT_DOWN          = 10011,  --副本准备时间倒计时
MSG_CAMPAIGN_MISSION_COUNT_DOWN  = 10012,  --副本总时间倒计时
MSG_CAMPAIGN_ADD_TIMES           = 10013,  --累加副本的每日次数
MSG_CAMPAIGN_GET_LEFT_TIMES      = 10014,  --获取指定活动的剩余次数
MSG_CAMPAIGN_GET_ACVIVITY_LEFT_TIME=10015, --获取活动剩余的时间
MSG_CAMPAIGN_NOTIFY_WAVE_COUNT   = 10016,  --服务器通知客户端怪物的波数

--cell到base的请求部分

--试炼之塔
MSG_CELL2BASE_SEND_TOWER_INFO = 65521,        --cell通知base获取试炼之塔的层数，下发给客户端

--公会系统服务器内部使用
MSG_UPGRADE_GUILD_SKILL_RESP  = 65522,        --公会长升级技能成功后通知每一个公会成员
MSG_GET_DRAGON_RESP           = 65523,        --摇龙晶后获得的奖励
MSG_RECHARGE_RESP             = 65524,        --龙晶充魔的返回
MSG_SUBMIT_CREATE_GUILD_COST  = 65525,        --创建公会成功后扣除资源
MSG_SET_GUILD_ID              = 65526,        --设置玩家的公会ID

--试炼之塔
MSG_CELL2BASE_SENT_REWARD     = 65527,        --cell通知base加临时奖励池道具
MSG_TOWER_FAIL                = 65528,        --cell通知base副本失败，增加失败次数
MSG_CELL2BASE_TOWER_SUCCESS   = 65529,        --cell通知base指定难度的副本成功了

--关卡系统
MSG_REVIVE_SUCCESS            = 65530,     --cell通知base复活成功
MSG_ADD_FRIEND_DEGREE_C2B     = 65531,     --cell通知base加好友好感度
MSG_EXIT_MAP                  = 65532,     --cell通知base离开地图
MSG_ADD_REWARD_ITEMS          = 65533,     --cell通知base增加奖励道具
MSG_ADD_FINISHED_MISSIONS     = 65534,     --cell通知base累加已通关关卡
MSG_ADD_MISSION_TIMES         = 65535,     --cell开始副本以后通知base累加挑战次数



}

return action_config
