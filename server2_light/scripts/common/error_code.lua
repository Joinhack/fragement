---系统消息id命名规则:
--
--    错误码: 1~29999
--    服务器系统公告: 30000~49999
--    客户端系统公告: 50000~59999
--    操作码: 60000+action_id
--

error_code = {

-------------------------------------------------------------------------------------------------------
---错误码

ERR_SUCCESSFUL                    = 0,

ERR_STATE_HAS_STATE                  = 1,      --操作id和玩家现有状态冲突
ERR_STATE_HASNT_STATE                = 2,      --玩家没有操作id需要的状态
ERR_STATE_LEVEL                      = 3,      --等级不符合操作id需要的最低要求
ERR_STATE_VIP_LEVEL                  = 4,      --VIP等级不符合操作id需要的最低要求

ERR_ILLEGAL_PET_POS               = 6,         --非法小弟位置输入，该小弟不存在

ERR_CREATE_AVATAR_CREATED         = 11,                --该帐号下已经创建过角色了
ERR_CREATE_AVATAR_NAME_TOO_SHORT  = 12,                --角色姓名太短,至少为4个字符（2个汉字）
ERR_CREATE_AVATAR_NAME_TOO_LONG   = 13,                --角色姓名太长,至多为16个字符（8个汉字）
ERR_CREATE_AVATAR_NAME_INVALID    = 14,                --角色姓名包含非法字符
ERR_CREATE_AVATAR_NAME_EXISTS     = 15,                --该角色姓名已经被占用
ERR_CREATE_AVATAR_NAME_BANNED     = 16,                --角色姓名包含敏感字
ERR_CREATE_AVATAR_GENDER          = 17,                --角色性别取值错误
ERR_CREATE_AVATAR_VOCATION        = 18,                --角色职业取值错误
ERR_CREATE_AVATAR_TOO_MUCH        = 19,                --超过角色数量
ERR_CHANNEL_ERR_CH_ID             = 20,               --聊天频道,错误的频道id
ERR_CHANNEL_CD                    = 21,               --聊天cd中,你发言太频繁了
ERR_CHANNEL_PRIVATE_SELF          = 23,               --不要和自己私聊吧
ERR_CHANNEL_TEXT_EMPTY            = 24,               --不能发表空的消息
ERR_CHANNEL_TEXT_TOO_LONG         = 25,               --消息太长,一次最多只能发送60个字符
ERR_CHANNEL_NOTIN_GUILD           = 26,               --你尚未加入帮派,无法在帮派频道发言

ERR_GOLD_LIMIT                    = 27,               -- 金币超过上限
ERR_CREATE_AVATAR_DB              = 28,               --数据库存在问题

-->version check
ERR_VERSION_SUCCEED               = 0,                --跟当前版本一样
ERR_VERSION_CAN                   = 1,                --跟服务版本兼容，但提醒不是相同版本
ERR_VERSION_FORBID                = 2,                --跟当前服务器版本不兼容
--<
-->login begin
ERR_LOGIN_SUCCEED                 = 0,
ERR_LOGIN_READ_DB_FAILED          = 1,
ERR_LOGIN_NOT_MY_CHARACTER        = 2,
ERR_LOGIN_AVATAR_BAD              = 3,                --该角色数据有问题，请联系gm
ERR_LOGIN_IP_FORBIDDEN            = 4,              --你的IP被禁止登陆
ERR_LOGIN_ACCOUNT_FORBIDDEN       = 5,          --你的账号被禁止登陆
--<login end

-->body enhance begin
ERR_BODY_ENHANCE_SUCCEED          = 0,                --成功
ERR_BODY_ENHANCE_PARA             = 1,                --参数错误
ERR_BODY_LEVEL_ALREADY_MAX        = 2,                --等级已达最高
ERR_BODY_ENHANCE_CONFIG           = 3,                --配置错误
ERR_BODY_ENHANCE_GOLD_NOT_ENOUGH  = 4,                --金币不够
ERR_BODY_ENHANCE_MATERIAL_NOT_ENOUGH = 5,             --材料不齐
ERR_BODY_ENHANCE_LEVEL            = 6,                --等级不够
ERR_BODY_ENHANCE_POS_LEVEL        = 7,                --不能跨等级升级
ERR_BODY_ENHANCE_OTHER            = 9,                --其他
--<body enhance end

-->jewel subSystem begin
ERR_JEWEL_SUCCEED                 = 0,                --成功
ERR_JEWEL_PARA                    = 1,                --参数错误
ERR_JEWEL_CONFIG                  = 2,                --配置错误
ERR_JEWEL_NOT_ENOUGH_DIAMOND      = 3,
ERR_JEWEL_NOT_ENOUGH_MATERIAL     = 4,
ERR_JEWEL_DEL_FAILED              = 5,
ERR_JEWEL_CAN_NOT_INLAY           = 6,                --宝石和装备不匹配
ERR_JEWEL_LEVEL_ALREADY_MAX       = 7,
ERR_JEWEL_EQUI_NOT_EXISTS         = 8,
ERR_JEWEL_NOT_EXISTS              = 9,
ERR_JEWEL_NO_EMPTY_GRID           = 10,                --背包没有足够的空格
ERR_JEWEL_SLOT_NOT_EXISTS         = 11,
ERR_JEWEL_SLOT_FULL_OR_NOT_MATCH  = 12,                --装备插槽满了或者与镶嵌宝石不匹配
ERR_JEWEL_EQUI_SLOT_NOT_EXISTS    = 13,                --装备的插槽不存在
ERR_JEWEL_CAN_NOT_OUTLAY          = 14,
ERR_JEWEL_SLOT_NO_JEWEL           = 15,                --装备的插槽上没有宝石
ERR_JEWEL_NUM_TOO_MUCH            = 16,                --卖出宝石大于当前格子的数量
ERR_JEWEL_CAN_NOT_SELL            = 17,                --该宝石不能出售
--<jewel subSystem end

-->offline mgr
ERR_OFFLINE_SUCCEED               = 0,
ERR_OFFLINE_OBJ_NOT_EXISIST       = 1,
ERR_OFFLINE_FAILED                = 2,
ERR_OFFLINE_REQ_TIMEOUT           = 3,

--<offline mgr

-->friend system
ERR_FRIEND_SUCCEED                = 0,
ERR_FRIEND_NOT_EXISTS             = 1,
ERR_FRIEND_REQ_NOT_EXISTS         = 2,
ERR_FRIEND_ALREADY_HAS            = 3,
ERR_FRIEND_FULL                   = 4,
ERR_FRIEND_NOT_MY_FRIEND          = 5,
ERR_FRIEND_BLESS_CDING            = 6, --对单个人的祝福CD中
ERR_FRIEND_BLESS_GET_FULL         = 7, --领取的祝福已满
ERR_FRIEND_BLESS_NOT_EXISTS       = 8, --祝福不存在
ERR_FRIEND_RECV_BLESS_FULL        = 9, --祝福领取成功，今日可领取祝福已满

ERR_FRIEND_MSG_TOO_MUCH           = 738, --对应着中文字符表
--<friend system

-->UserMgr
ERR_USER_MGR_SUCCEED              = 0,
ERR_USER_MGR_OFFLINE              = 1,                --玩家不在线
ERR_USER_MGR_PLAYER_NOT_EXISTS    = 2,
ERR_USER_MGR_PLAYER_FRIEND_FULL   = 3,                --玩家好友已满
ERR_USER_MGR_MY_FRIEND_FULL       = 4,                --我的好友列表好友已满
--<UserMgr

-->mail system
ERR_MAIL_SUCCEED                  = 0,                --邮件操作成功
ERR_MAIL_NOT_EXISTS               = 1,                --邮件不存在
ERR_MAIL_NO_ATTACHMENT            = 2,                --邮件没有附件可领取
ERR_MAIL_ATTACHMENT_GETED         = 3,                --邮件附件已被领取过
ERR_MAIL_TIMEOUT                  = 4,
ERR_MAIL_BAG_FULL                 = 5,                --背包已满不能领取附件
--<mail system

-->hp--error_code

--ERR_HP_VERIFY_DEATH               = 1,           --角色死亡
--ERR_HP_VERIFY_FULL                = 2,           --血量满状态        


--<hp--error_code


-->hp--ShowId
ERR_HP_VERIFY_SUCCESS              = 0,          --校验成功
ERR_HP_FULL                        = 510,        --血量已满
ERR_HP_BOTTLE_UNENOUGH             = 511,        --血瓶不足
ERR_HP_CFG_ERROR                   = 512,        --配置错误
ERR_HP_CD_LIMITED                  = 513,        --冷却时间受限
ERR_HP_FORBID_BUY                  = 514,        --钻石不足，不可购买
ERR_HP_BUY_TIMES_LIMIT             = 515,        --购买数量已达上限
ERR_HP_BUY_BOTTLE                  = 516,        --血瓶数量为零，花费钻石购买确认
ERR_HP_MISSION_NOT_ALLOW           = 517,        --该关卡不能使用血瓶
ERR_HP_AVATAR_DEATH                = 2113,       --角色已死亡，不可使用
---<hp

-->use item
ERR_USEITEM_SUCCESS                = 0,          --使用成功
ERR_USEITEM_IDX_ERROR              = 1,          --道具索引错误
ERR_USEITEM_ID_ERROR               = 2,          --道具id错误
ERR_USEITEM_CFG_ERROR              = 3,          --配置错误
ERR_USEITEM_FORBID_USE             = 4,          --不可使用
ERR_USEITEM_COUNT_ERROR            = 5,          --数量错误
ERR_USEITEM_COLD_LIMIT             = 6,          --冷却未结束
ERR_USEITEM_VIP_LEVEL_LIMIT        = 7,          --VIP等级受限
ERR_USEITEM_VOCATION_LIMIT         = 8,          --职业受限
ERR_USEITEM_USELEVEL_LIMIT         = 9,          --使用等级受限
ERR_USEITEM_SPACE_UNENOUGH         = 10,         --空间不足
ERR_USEITEM_VIP_UNEFFECT           = 11,         --VIP效果不足
ERR_USERITEM_COST_UNENOUGH         = 12,         --消耗不足
ERR_USEITEM_BUFF_CFG_ERROR         = 13,         --BUFF配置错误
ERR_USEITEM_ENERGY_LIMIT           = 14,         --体力已达上限
ERR_USEITEM_EXP_LIMIT              = 15,         --经验不足
ERR_USEITEM_GOLD_LIMIT             = 16,         --金币不足
ERR_USEITEM_DIAMOND_LIMIT          = 17,         --钻石不足
ERR_USEITEM_CREDIT_LIMIT           = 18,         --荣誉不足
ERR_USEITEM_WING_LIMIT             = 19,         --已经拥有该翅膀
ERR_USEITEM_RUNE_LIMIT             = 20,         --符文背包已满
---<use item

-->worldboss
ERR_WB_ENTER_SUCCESS                  = 0,       --进入成功
ERR_WB_ENTER_NOT_OPEN                 = 1,       --活动没开始
ERR_WB_ENTER_LV                       = 2,       --等级不够
ERR_WB_ENTER_VIP                      = 3,       --vip数值错误（前端可以忽略）
ERR_WB_ENTER_TIME                     = 4,       --可进入次数为零
ERR_WB_ENTER_STATE                    = 5,       --已经是进入状态
ERR_WB_ENTER_FULL                     = 6,       --人数已满

ERR_WB_BUY_CAN                        = 0,       --可购买或者购买成功
ERR_WB_BUY_NO_NEED                    = 1,       --无需购买
ERR_WB_BUY_FULL                       = 2,       --可购买次数已用完
ERR_WB_BUY_NO_MONEY                   = 3,       --金钱不够
--<worldboss



--换装
CHG_EQUIP_SUCCESS                          = 0,  --换装成功
CHG_EQUIP_EQUIPMENT_NOT_EXISTED            = 1, --背包中不存在该装备
CHG_EQUIP_EQUIPMENT_INVENTORY_FULL         = 2, --背包已满
CHG_EQUIP_EQUIPMENT_NOT_EXISTED_IN_CFG_TBL = 3, --系统没有该装备
CHG_EQUIP_LEVEL_NOT_ENOUGH                 = 5, --职业等级不够
CHG_EQUIP_DATA_UNMATCH                     = 6, --前后端数据不匹配
CHG_EQUIP_VOCATION_UNMATCH                 = 7, --职业资格受限
CHG_EQUIP_NOT_KNOWN                        = 8, --位置错误


--卸装错误码

RM_EQUIP_SUCCESS                           = 0, --卸装成功
RM_EQUIP_EQUIPMENT_NOT_EXISTED             = 1, --背包中不存在该装备
RM_EQUIP_DATA_UNMATCH                      = 2, --前后端数据不匹配
RM_EQUIP_EQUIPMENT_INVENTORY_FULL          = 3, --背包已满
RM_EQUIP_UNKNOW                            = 4, --未知错误


--分解装备错误码

DEP_EQUIP_SUCCESS                          = 0, --成功
DEP_EQUIP_EQUIP_NOT_IN_CFG_TBL             = 1, --系统不存在该装备
DEP_EQUIP_EQUIP_NOT_IN_INVRY               = 2, --装备不在背包中
DEP_EQUIP_EQUIP_NOT_IN_DEP_TBL             = 3, --装备分解没有定义
DEP_EQUIP_SPACE_LIMITED                    = 4, --背包空间受限，无法分解
DEP_EQUIP_DATA_UNMATCH                     = 5, --前后端数据不匹配
DEP_EQUIP_UNKNOW                           = 6, --未知错误

--出售错误码

ITEM_SELL_SUCCESS                          = 0, --出售成功
ITEM_SELL_ITEM_NOT_EXISTED                 = 1, --道具系统中不存在
ITEM_SELL_COUNT_ERROR                      = 2, --数量错误
ITEM_SELL_FORBID_SELL                      = 3, --不可售卖
ITEM_SELL_DATA_UNMATCH                     = 4, --前后端数据不匹配
ITEM_SELL_UNKNOW                           = 5, --位置错误



ERR_NPC_NPC_CFG                            = 1,  --npc配置错误
ERR_NPC_TSK_CFG                            = 2,  --任务系统配置错误
ERR_NPC_LEVEL_FORBID                       = 3,  --等级受限
ERR_NPC_ID_UNMATCH                         = 4,  --ID不匹配
ERR_NPC_SUCCESS                            = 0,  --成功

--副本扫荡
SWEEP_MISSION_DAILY_TIMES                  = 25018,   --副本当天次数用完，不能扫荡

--体力
ENERGY_SUCCESS                             = 25101,   --购买成功
ENERGY_LIMITED                             = 25102,   --体力值到达上限
ENERGY_MAX_BUY_TIMES                       = 25103,   --已达最大购买次数
ENERGY_GOLD_UNENOUGH                       = 25104,   --金币不足
ENERGY_DIAMOND_UNENOUGH                    = 25105,   --钻石不足
ENERGY_COUNT                               = 25106,   --数量错误

--炼金
GOLD_META_TIMES_LIMIT                      = 1202,    --购买次数已达上限
GOLD_META_DIMAOND_UNENOUGH                 = 1201,    --钻石不足
GOLD_META_SUCCESS                          = 1203,    --炼金成功
--紫装兑换
PURPLE_EXCHANGE_SUCCESS                    = 1301,   --兑换成功
PURPLE_EXCHANGE_LIMITED                    = 1302,   --材料不足
PURPLE_EXCHANGE_BAG_FULL                   = 1303,   --背包已满
PURPLE_EXCHANGE_ID_NIL                     = 1304,   --找不到配置数据
PURPLE_EXCHANGE_GOLD_LIMIT                 = 1305,   --金币不足
--聊天
CHAT_PERSON_NOT_EXIT                       = 200000,  --对方不存在
CHAT_PERSON_NOT_ONLINE                     = 200001,  --对方不在线
CHAT_GUILD_NOT_EXIT                        = 200002,  --工会不存在



--排行榜系统
RANK_LIST_REQUIRE_SUCCESS                   = 0,    --排行榜系统回调成功   
RANK_LIST_REQUIRE_FAILURE                   = 1,    --排行榜系统回调失败

FANS_IDOL_HAS_CHANGE                        = 3,   --今日已用完偶像变更次数
FANS_IDOL_HAS_REWARD                        = 2,   --已领取奖励
FANS_IDOL_PARAS_ERROR                       = 1,   --参数错误
FANS_IDOL_SUCCESS                           = 0,   --变更偶像成功

--活动系统错误码
ERR_ACTIVITY_NOT_EXIT                       = 1,    --该活动不存在
ERR_ACTIVITY_INVITE_SELF                    = 2,    --不能邀请自己参加活动
ERR_ACTIVITY_INVITE_NOT_FRIEND              = 3,    --只能邀请自己的好友
ERR_ACTIVITE_INVITE_NOT_EXIT                = 4,    --被邀请的用户不存在
ERR_ACTIVITE_INVITE_NOT_ONLINE              = 5,    --被邀请的用户不在线
ERR_ACTIVITE_INVITE_AC_NOT_EXIT             = 6,    --活动没开始，不能邀请
ERR_ACTIVITE_INVITE_ALLREADY_INVITED        = 7,    --已经邀请过了，不能重复邀请
ERR_ACTIVITE_INVITED_RESP_NOT_EXIT          = 8,    --邀请不存在
ERR_ACTIVITY_JOIN_NOT_STARTED               = 9,    --活动未开始
ERR_ACTIVITY_JOIN_NOT_EXIT                  = 10,   --该活动不存在
ERR_ACTIVITY_JOIN_LEVEL_NOT_MATCH           = 11,   --玩家等级不符合要求，不能参加
ERR_ACTIVITY_JOIN_LEVEL_TIMES_OUT           = 12,   --玩家的挑战次数已经用完
ERR_ACTIVITY_TOWER_DEFENCE_MATCH_FAIL       = 13,   --玩家在塔防副本匹配失败
ERR_ACTIVITY_JOIN_ALREADY                   = 14,   --玩家已经在队列中
ERR_ACTIVITY_GET_LEFT_TIMES_NOT_EXIT        = 15,   --玩家获取指定活动的剩余次数时，活动不存在
ERR_ACTIVITY_GET_ACTIVITY_LEFT_TIME_NOT_EXIT= 16,   --玩家获取指定活动的剩余时间时，活动不存在
ERR_ACTIVITY_GET_ACTIVITY_LEFT_TIME_NOT_STARTED=17, --玩家获取指定活动的剩余时间时，活动没开始

ERR_DRAGON_OK                               = 0,    --开始袭击切换战斗
ERR_DRAGON_NOATKED                          = 1,    --袭击对手数据错误
ERR_DRAGON_MAX_ATKED_TIMES                  = 2,    --对手已达最大被袭击次数
ERR_DRAGON_MAX_ATK_TIMES                    = 3,    --已达最大袭击次数
ERR_DRAGON_ATK_CDLIMIT                      = 4,    --袭击CD未结束
ERR_DRAGON_MAX_RVG                          = 5,    --复仇已达最大次数
ERR_DRAGON_NOCONVOY                         = 6,    --对手没有护送飞龙
ERR_DRAGON_UNNEED                           = 7,    --不需要购买
ERR_DRAGON_ATKBUY_LIMIT                     = 8,    --袭击购买次数达到上限
ERR_DRAGON_GOLDED                           = 9,    --已是金色飞龙
ERR_DRAGON_COST_LIMIT                       = 10,   --消耗不足
ERR_DRAGON_DEDUCT_WRONG                     = 11,   --扣除失败
ERR_DRAGON_CFG_ERR                          = 12,   --配置错误
ERR_DRAGON_ATKCD_END                        = 13,   --袭击cd已结束
ERR_DRAGON_ALL_LIMIT                        = 14,   --今日袭击次数和购买已达最大值
ERR_DRAGON_NOEND                            = 15,   --护送还没有结束
ERR_DRAGON_NOGET_REWAED                     = 16,   --奖励没有领取
ERR_DRAGON_CONVOY_TIMES_LIMIT               = 17,   --今日护送次数已用完
ERR_DRAGON_CONVOY_END                       = 18,   --护送已完成
ERR_DRAGON_INFO_LOSE                        = 19,   --角色信息丢失
ERR_DRAGON_FRESH_FAIL                       = 20,   --刷新失败
ERR_DRAGON_HAS_GAINED                       = 1,    --已经领取奖励


ERR_EXPORE_CVY_NOTEND                       = 1,    --护送没有结束
ERR_EXPORE_CANNOT_EXPLORE                   = 2,    --今日没有完成护送不能探索
ERR_EXPORE_HAS_EXPLORE                      = 3,    --本站点已经探索过
ERR_EXPORE_EXPLORE_OK                       = 0,    --探索成功   

ERR_ITEM_ACTIVE_OK                          = 0,    --兑换成功
ERR_ITEM_ACTIVE_CFG                         = 1,    --配置有问题
ERR_ITEM_ACTIVE_NO                          = 2,    --不存在可激活的装备
ERR_ITEM_ACTIVE_WRONG                       = 3,    --不是套装ID
ERR_ITEM_ACTIVE_UNCOSTS                     = 4,    --激活消耗不足


ERR_ITEM_LOCK_OK                            = 0,    --装备加锁或解锁ok
ERR_ITEM_LOCK_NO                            = 1,    --装备加锁或解锁失败


--翅膀培养
WING_TRAIN_OK                               = 0,    --培养ok
WING_NOT_EXIST                              = 1,    --没有购买该翅膀
WING_CFG_ERROR                              = 2,    --翅膀配置错误
WING_NO_DIAORITEMS                          = 3,    --道具或钻石不足
WING_HAS_CEIL                               = 4,    --已培养到顶级
--翅膀激活
WING_ACTIVE_SUCCESS                         = 0,    --激活成功
WING_ACTIVE_NOWING                          = 1,    --没有该翅膀
WING_ACTIVE_CFG                             = 2,    --配置错误
WING_ACTIVE_GOLD                            = 3,    --金币不足
WING_ACTIVE_DIA                             = 4,    --钻石不足
WING_ACTIVE_ITEM                            = 5,    --道具不足
WING_ACTIVE_ACTIVED                         = 6,    --已被激活
WING_ACTIVE_TYPE                            = 7,    --类型错误
WING_ACTIVE_VOC                             = 8,    --职业限制
WING_ACTIVE_VIP                             = 9,    --VIP等级受限
WING_ACTIVE_LESS                            = 10,   --激活条件不足
--翅膀穿戴
WING_EXCHANGE_OK                            = 0,    --换装OK
WING_EXCHANGE_NO                            = 1,    --没有该翅膀
WING_EXCHANGE_DONE                          = 2,    --已经穿戴该翅膀

ERR_SPECIAL_EFFECTS_OK                      = 0,    --激活成功
ERR_SPECIAL_EFFECTS_HAS                     = 1,    --已经激活
ERR_SPECIAL_EFFECTS_JEWEL_LESS              = 2,    --宝石积分不足
ERR_SPECIAL_EFFECTS_EQUIP_LESS              = 3,    --装备积分不足
ERR_SPECIAL_EFFECTS_STRGE_LESS              = 4,    --强化积分不足
ERR_SPECIAL_EFFECTS_GROUPID                 = 5,    --组ID错误
ERR_SPECIAL_EFFECTS_CFG                     = 6,    --特效ID错误

ERR_JEWEl_INLAY_OK                          = 0,    --宝石全部镶嵌到替换的装备上
ERR_JEWEl_INLAY_BAG                         = 1,    --宝石已放入背包                       
ERR_JEWEl_INLAY_MAIL                        = 2,    --宝石发邮件   

ERR_ROUL_SUC                                = 0,
ERR_ROUL_CFG                                = 1,
ERR_ROUL_NOT_OPEN                           = 2,
ERR_ROUL_END                                = 3,

--充值系统
ERR_BROWSER_RESP_SUC                       = "1",  --充值成功
ERR_BROWSER_RESP_REDUP                     = "2",  --订单重复
ERR_BROWSER_RESP_PARAM                     = "-1", --提交参数不全
ERR_BROWSER_RESP_SIGN                      = "-2", --签名验证失败
ERR_BROWSER_RESP_NO                        = "-3", --用户不存在
ERR_BROWSER_RESP_TIMEOUT                   = "-4", --请求超时
ERR_BROWSER_RESP_FAILE                     = "-5", --充值失败
--------------------------------------------------------------------------------------------------------
}

return error_code

