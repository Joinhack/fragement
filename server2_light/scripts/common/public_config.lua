local cfg = {

--mailbox中key的定义
MAILBOX_KEY_SERVER_ID    = 1,      --server_id
MAILBOX_KEY_CLASS_TYPE   = 2,      --entity class_type
MAILBOX_KEY_ENTITY_ID    = 3,      --entity id

--性别
GENDER_FEMALE = 0,                 --性别:女
GENDER_MALE   = 1,                 --性别:男

LV_MAX = 60,

-- 职业
VOC_MIN       = 1,         -- 最小职业编号
VOC_WARRIOR   = 1,         -- 战士
VOC_ASSASSIN  = 2,         -- 刺客
VOC_ARCHER    = 3,         -- 弓箭手
VOC_MAGE      = 4,         -- 法师
VOC_MAX       = 4,         -- 最大职业编号

--特殊物品id
EXP_ID                  = 1,  --经验
GOLD_ID                 = 2,  --金币
DIAMOND_ID              = 3,  --钻石
VIP_ID                  = 4,  --vip卡
CUBE_ID                 = 5,  --特殊宝箱
ENERGY_ID               = 6,  --体力
BUFF_ID                 = 7,  --buff
GUILD_CARD_ID           = 8,  --公会招募卡
ARENA_CREDIT            = 11, --竞技场荣誉
ARENA_SCORE             = 12, --竞技场积分
WING_ID                 = 13, --翅膀
RUNE_ID                 = 14, --符文
MAX_OTHER_ITEM_ID       = 99, --最大的特殊道具编号
ITEM_ID                 = 100000,--道具类 

--使用道具奖励,修改标记参考
--AVATAR_PROP_DIAMOND     = 1, --钻石
--AVATAR_PROP_GOLD        = 2, --金币
--AVATAR_PROP_EXP         = 3, --经验




SIZE_INVENTORY_NORMAL   = 40,
SIZE_INVENTORY_JEWEL    = 40,
SIZE_INVENTORY_MATERIAL = 40,

--1、装备编号,2、宝石编号,3、普通道具，4、材料
ITEM_GRID_EQUIPMENT  = 1,
ITEM_GRID_JEWEL      = 2,
ITEM_GRID_COMMON     = 3,
ITEM_GRID_MATERIAL   = 4,

ITEM_ACTIVE_TYPE     = 8,  --激活道具标识
ITEM_ACTIVE_SUBTYPE  = 1,  --激活子类型标识

ITEM_ACTIVED_OK      = 1,  --已激活
ITEM_ACTIVED_NO      = 0,  --没有激活

ITEM_LOCKED_OK       = 1,  --已锁
ITEM_LOCKED_NO       = 0,  --解锁
--ITEM_EQUIPED_SHOWID  = 1130,
--ITEM_UNEQUIP_SHOWID  = 1131,
ITEM_EXTINFO_LOCKED  = 0,  --装备是否加锁
ITEM_EXTINFO_ACTIVE  = 1,  --道具激活标识
--帐号的角色状态
CHARACTER_NONE       = 0,
CHARACTER_CREATING   = 1,
CHARACTER_CREATED    = 2,

-->角色信息

CHARACTER_KEY_DBID       = 1,       --int
CHARACTER_KEY_NAME       = 2,       --string
CHARACTER_KEY_VOCATION   = 3,       --int
CHARACTER_KEY_LEVEL      = 4,       --int

CHATACTER_KEY_EQUIP_WEAPON   = 5,       --武器
CHATACTER_KEY_EQUIP_CUIRASS  = 6,        --胸甲
CHATACTER_KEY_EQUIP_LEG      = 7,        --腿甲
CHATACTER_KEY_EQUIP_ARMGUARD = 8,        --护手
CHATACTER_KEY_SHOW_WING      = 9,        --翅膀
CHATACTER_KEY_SHOW_JEWEL     = 10,       --宝石特效
CHATACTER_KEY_SHOW_EQUIP     = 11,       --装备特效
CHATACTER_KEY_SHOW_STRGE     = 12,       --强化特效



--CHATACTER_KEY_EQUIP2     = 6,
--CHATACTER_KEY_EQUIP3     = 7,
--<角色信息

TIMER_TICK_COUNT_PER_SECOND = 10,     --1秒=n tick, 与引擎里的参数一致
-->退出
QUIT_NONE     = 0,   --没有退
QUIT_UNNORMAL = 1,   --异常退出(先走onClientDeath)
QUIT_NORMAL   = 2,   --玩家主动退出(立即走销魂所有缓存流程)
QUIT_BACK     = 3,   --回退选角色界面 

LOGOUT_QUIT = 0,
LOGOUT_BACK = 1,

--缓存销毁标志
DESTROY_FLAG_NONE = 0,
DESTROY_FLAG_DESTROYING = 1,

--<退出

--实体类型(自定义,不用引擎里def那个id)
ENTITY_TYPE_AVATAR      = 1,
ENTITY_TYPE_SPAWNPOINT  = 2,
ENTITY_TYPE_MONSTER     = 3,
ENTITY_TYPE_NPC         = 4,
ENTITY_TYPE_CLICKITEM   = 5,
ENTITY_TYPE_TELEPORTSRC = 6,
ENTITY_TYPE_TELEPORTDES = 7,
ENTITY_TYPE_MERCENARY   = 8,
--ENTITY_TYPE_BOSS        = 10, --需要跨spaceloader共享血量的boss

--monster配置isClient字段的意义
MONSTER_IS_CLIENT_MONSTER = 0,  --服务器端怪物
MONSTER_IS_CLIENT_DUMMY   = 1,  --客户端怪物
MONSTER_IS_CLIENT_BOSS    = 2,  --服务器端boss,共享血量
MONSTER_IS_CLIENT_MERCENARY = 3, --雇佣兵类型怪

CHANNEL_WORLD          = 1,            --世界频道
CHANNEL_GUILD          = 2,            --帮派频道
CHANNEL_PRIVATE        = 3,            --私聊频道

MAP_TYPE_NORMAL                  = 0,             --普通地图
MAP_TYPE_SPECIAL                 = 1,             --副本地图
MAP_TYPE_SLZT                    = 2,             --试炼之塔地图
MAP_TYPE_MUTI_PLAYER_NOT_TEAM    = 3,             --多人非组队地图
MAP_TYPE_WB                      = 4,             --世界boss地图
MAP_TYPE_OBLIVION                = 5,             --湮灭之门地图
MAP_TYPE_ARENA                   = 6,             --竞技场地图
MAP_TYPE_NEWBIE                  = 7,             --新手关地图
MAP_TYPE_TOWER_DEFENCE           = 8,             --塔防地图
MAP_TYPE_DRAGON                  = 9,             --飞龙大赛地图
MAP_TYPE_RANDOM                  = 10,            --随机副本
MAP_TYPE_DEFENSE_PVP             = 11,            --守护PvP
MAP_TYPE_MWSY                    = 12,            --迷雾深渊


BASEDDATA_KEY_SPACELOADER_CELL = "BASEDDATA_KEY_SPACELOADER_CELL",


BASE_SPEED_PER_SECOND = 10,


--Avatar的tmp_data中的key
TMP_DATA_KEY_QUIT_FLAG                        = 1,            --退出标志
TMP_DATA_KEY_TELEPORT_MAP                     = 2,            --跨cellApp传送的目标地图ID
TMP_DATA_KEY_TELEPORT_LINE                    = 3,            --跨cellApp传送的目标分线ID
TMP_DATA_KEY_TELEPORT_X                       = 4,            --跨cellApp传送的目标地图x值
TMP_DATA_KEY_TELEPORT_Y                       = 5,            --跨cellApp传送的目标地图y值
TMP_DATA_KEY_MISSION_ID                       = 6,            --进入副本的关卡ID
TMP_DATA_KEY_MISSION_DIFFICULT                = 7,            --进入副本的关卡难度
TMP_DATA_KEY_CREATING_CELL                    = 8,            --正在创建cell部分
--TMP_DATE_KEY_KINDOM_MAP_ID                  = 9,            --上一次所在的王城地图ID
TMP_DATE_KEY_KINDOM_X                         = 9,            --上一次在王城的坐标X
TMP_DATE_KEY_KINDOM_Y                         = 10,           --上一次在王城的坐标Y
TMP_DATA_KEY_ARENA                            = 11,           --标志竞技场是否已new
TMP_DATA_KEY_SPACE_MB                         = 12,           --跨cellapp传送时记录目标场景的mb
TMP_DATA_KEY_MISSION_SWEEP_REWARD             = 13,           --副本扫荡时用到的临时值
TMP_DATA_KEY_CONSOLE_MISSION_REWARD           = 14,           --玩家进行单机副本的奖励池数据
TMP_DATA_KEY_CONSOLE_MISSION_STARTTIME        = 15,           --玩家进行单机副本的奖励池数据
TMP_DATA_KEY_CONSOLE_MISSION_ID               = 16,           --玩家进行单机副本的关卡ID
TMP_DATA_KEY_CONSOLE_MISSION_DIFFICULT        = 17,           --玩家进行单机副本的关卡难度
TMP_DATA_KEY_MISSION_RANDOM_REWARD            = 18,           --玩家的翻牌结果
TMP_DATA_KEY_MISSION_ID_RANDOM                = 19,           --玩家进行随机副本的关卡ID
TMP_DATA_KEY_MISSION_DIFFICULT_RANDOM         = 20,           --玩家进行随机副本的难度
TMP_DATA_KEY_IS_RANDOM_MISSION                = 21,           --是否随机副本
--TMP_DATA_KEY_MISSION_ID_RANDOM_REAL         = 22,           --玩家进行随机副本时客户端传进来的关卡ID
--TMP_DATA_KEY_MISSION_DIFFICULTY_RANDOM_REAL = 23,           --玩家进行随机副本时客户端传进来的关卡难度
TMP_DATA_KEY_DRAGON_TIMERID                   = 24,           --飞龙定时器
TMP_DATA_KEY_MISSION_DATA                     = 25,           --副本用到的临时数据
TMP_DATA_KEY_IS_MWSY                          = 26,           --标记玩家是否在迷雾深渊


TMP_DATA_QUIT_MODE_NOEN   = 0, --不退出
TMP_DATA_QUIT_MODE_NORMAL = 1, --普通退出（走完整的退出流程）
TMP_DATA_QUIT_MODE_SPECIAL = 2, --只销毁base和cell上的角色相关数据



CHANGE_MAP_COUNT_ADD = 0,    --玩家进入一个分线时通知MapMgr累加人数
CHANGE_MAP_COUNT_SUB = 1,    --玩家离开一个分线时通知MapMgr扣除人数


--SpaceLoader上注册的实体
SPACE_LOADER_ENTITY_TYPE_SPAWNPOINT = 1, --刷怪点
SPACE_LOADER_ENTITY_TYPE_MONSTER    = 2, --怪物

USER_MGR_DETAIL_DATA_CACHE_LEVEL        = 10, --usermgr缓存详细数据所需等级
USER_MGR_SAVE_INTERVAL                  = 60,
USER_MGR_CLEAN_INTERVAL                 = 86400,
USER_MGR_SAVE_NUM                       = 100, --每次存储的量
USER_MGR_TIMER_ID_SAVE_INDEX            = 1, --usermgr存储定时器id索引
USER_MGR_TIMER_ID_CLEAN_INDEX           = 2, --usermgr清理缓存定时器id索引
USER_MGR_TIMER_ID_FIXED                 = 3, --usermgr排行榜数据定时加载数据
--UserMgr返回的数据里面LUA_TABLE(DbidToPlayers)的index
USER_MGR_PLAYER_BASE_MB_INDEX            = 1,
USER_MGR_PLAYER_CELL_MB_INDEX            = 2,
USER_MGR_PLAYER_DBID_INDEX               = 3,
USER_MGR_PLAYER_NAME_INDEX               = 4,
USER_MGR_PLAYER_LEVEL_INDEX              = 5,
USER_MGR_PLAYER_VOCATION_INDEX           = 6,
USER_MGR_PLAYER_GENDER_INDEX             = 7,
USER_MGR_PLAYER_UNION_INDEX              = 8,
USER_MGR_PLAYER_FIGHT_INDEX              = 9, --20级以下才有值，否则为空，20级及以上战斗力放进m_lFights中排序存储,通过USER_MGR_PLAYER_ARENIC_FIGHT_RANK_INDEX去取值
USER_MGR_PLAYER_IS_ONLINE_INDEX          = 10,
USER_MGR_PLAYER_FRIEND_NUM_INDEX         = 11, --该值存储于offlinemgr，todo：解耦
USER_MGR_PLAYER_OFFLINETIME_INDEX        = 12,
USER_MGR_PLAYER_ITEMS_INDEX              = 13, --装备信息
USER_MGR_PLAYER_BATTLE_PROPS             = 14, --20级及以上才有值，否则为空
USER_MGR_PLAYER_SKILL_BAG                = 15, --20级及以上才有值，否则为空
USER_MGR_PLAYER_LOADED_ITEMS             = 16, --20级及以上才有值，否则为空
--USER_MGR_PLAYER_BODY_INDEX             = 17,
USER_MGR_PLAYER_ARENIC_FIGHT_RANK_INDEX  = 18, --竞技场标准战斗力排名
USER_MGR_PLAYER_ARENIC_GRADE_INDEX       = 19, --
USER_MGR_PLAYER_IDOL_INDEX               = 20, --角色偶像
USER_MGR_PLAYER_GM_SETTING               = 21, --gm配置的行为控制
USER_MGR_PLAYER_ACCOUNT                  = 22, --帐号名字

--[[UserMgr临时数据]]
USER_MGR_PLAYER_SKILL_BAG_TMP            = 31,
USER_MGR_PLAYER_ITEMS_INDEX_TMP          = 32,
USER_MGR_PLAYER_BODY_INDEX_TMP           = 33,
USER_MGR_PLAYER_RUNE_INDEX_TMP           = 34,
USER_MGR_PLAYER_FRIEND_NUM_INDEX_TMP     = 35, --用于纠正好友数量
USER_MGR_PLAYER_ENCHANT_INDEX_TMP        = 36, --附魔
USER_MGR_PLAYER_ELFPROG_INDEX_TMP        = 37, --精灵系统女神之泪进度
USER_MGR_PLAYER_WING_INDEX_TMP           = 38, --翅膀系统
--[[临时数据]]

--UserMgr的数据(m_lFights)的index
USER_MGR_FIGHTS_DBID_INDEX = 1,
USER_MGR_FIGHTS_FIGHT_INDEX = 2,
--UserMgr的数据(DbidToPlayers)的值(USER_MGR_PLAYER_ITEMS_INDEX)的数据的index
USER_MGR_ITEMS_BODY_INDEX = 1,
USER_MGR_ITEMS_TYPE_INDEX = 2,
USER_MGR_ITEMS_SLOT_INDEX = 3,

USER_MGR_PLAYER_ONLINE  = 0,
USER_MGR_PLAYER_OFFLINE = 1,

CHANNEL_ID_PERSONAL 		= 1,     --私聊频道
CHANNEL_ID_WORLD    		= 2,     --世界频道
CHANNEL_ID_TEAM     		= 3,     --队伍频道
CHANNEL_ID_UNION    		= 4,     --工会频道
CHANNEL_ID_SYSTEM   		= 5,     --系统频道
CHANNEL_ID_TOWER_DEFENCE 	= 6,	 --女神保卫战频道
CHANNEL_ID_DEFECSE_PVP 		= 7,	 --女神保卫战频道

----------------------------------------------------------
------------------------任务------------------------------
----------------------------------------------------------
TASK_TYPE_MAIN      = 0,    --主线任务
TASK_TYPE_ACTIVE    = 1,    --任务

TASK_ASK_TYPE_NPC_TALK  = 0,        --与npc对话
TASK_ASK_TYPE_MISSION_COMPLITE = 1, --副本完成



----------------------------------------------------------
-------------------副本-------------------------
----------------------------------------------------------
PLAYER_INFO_INDEX_EID                = 1,    --PlayerInfo字段的index，entityId
PLAYER_INFO_INDEX_DEADTIMES          = 2,    --PlayerInfo字段的index，玩家死亡次数
PLAYER_INFO_INDEX_USE_DRUG_TIMES     = 3,    --PlayerInfo字段的index，玩家喝药次数
PLAYER_INFO_INDEX_NAME               = 4,    --PlayerInfo字段的index，玩家的姓名
PLAYER_INFO_INDEX_REWARDS            = 5,    --PlayerInfo字段的index，玩家的奖励
PLAYER_INFO_REWARDS_EXP              = 1,    --PlyaerInfo的经验奖励key
PLAYER_INFO_REWARDS_ITEMS            = 2,    --PlayerInfo的道具奖励key
PLAYER_INFO_REWARDS_MONEY            = 3,    --PlayerInfo的金钱奖励key
PLAYER_INFO_INDEX_DAMEGE             = 6,    --PlayerInfo字段的index，玩家输出伤害累计
PLAYER_INFO_INDEX_BASEMB             = 7,    --PlayerInfo字段的index，玩家BASE上的mailbox

----------------------------------------------------------
-------------------身体强化子系统-------------------------
----------------------------------------------------------
BODY_POS_HEAD             = 1,
BODY_POS_NECK             = 2,
BODY_POS_SHOULDER         = 3,
BODY_POS_CHEST            = 4,
BODY_POS_WAIST            = 5,
BODY_POS_ARM              = 6,
BODY_POS_LEG              = 7,
BODY_POS_FOOT             = 8,
BODY_POS_FINGER           = 9,
BODY_POS_WEAPON           = 10,

MAX_BODY_POS_LEVEL        = 200,

----------------------------------------------------------
------------------- 离线管理系统 -------------------------
----------------------------------------------------------
OFFLINE_SAVE_MYSQL = 0,
OFFLINE_SAVE_REDIS = 1,

OFFLINE_MAX_TIMEOUT    = 5184000, --两个月的秒数
OFFLINE_SAVE_INTERVAL  = 60, --5分钟写库一次（数据库是5分钟一次）
OFFLINE_CLEAN_INTERVAL = 86400, --一天的秒数
OFFLINE_CLEAN_HOUR     = 4,
OFFLINE_ITEM_TIMEOUT_INDEX = 99,
OFFLINE_MSG_LIMIT = 500, --每种类型的离线数据只保留最新的500条
------------------------------------------------------------
--------------------背包子系统类型定义----------------------
-------------------------------------------------------------
--  for inventory --
ITEM_TYPE_EQUIPMENT = 1,  --装备
ITEM_TYPE_JEWEL     = 2,  --宝石
ITEM_TYPE_MATERIAL  = 3,  --材料
ITEM_TYPE_RUNE      = 4,  --符文
ITEM_TYPE_AVATAR    = 5,  --已穿戴装备
ITEM_TYPE_DELETE    = 6,  --装备删除表
--  for config file initial
ITEM_TYPE_CFG_TBL          = 1, --道具配置表
ITEM_TYPE_EQUIPMENTATTRI   = 2, --装备数值
ITEM_TYPE_JEWELATTRI       = 3, --角色永久数值表
ITEM_TYPE_INITITEMS        = 4, --角色创建时默认道具配置
ITEM_TYPE_DEEQUIPMENT      = 5, --装备分解数值配置表
ITEM_TYPE_SUITEQUIPMENT    = 6, --装备套装数值配置
ITEM_TYPE_PURPLE_EXCHANGE  = 7, --紫装兑换

OFFLINE_SAVE_ARRAY_NUM = 5, --每次入库玩家数量
OFFLINE_SAVE_ARRAY_NUM_ALTER = 100, --每次入库玩家数量
----------------------------------------------------------
------------------- 好友系统 -------------------------
----------------------------------------------------------
FRIEND_NOTE_TIMEOUT          = 604800, --好友留言保留一周
FRIEND_REQ_TIMEOUT           = 604800, --好友请求有效时间
--FRIEND_RESP_TIMEOUT          = 604800, --好友答应有效时间
FRIEND_BLESS_TIMEOUT         = 86400, --好友请求有效时间
FRIEND_MAX_LIMIT             = 50,
FRIEND_BE_BLESS_ENERGY       = 3,
FRIEND_BLESS_ENERGY          = 3,
FRIEND_BLESS_DEGREE          = 1,
FRIEND_DEGREE_MAX            = 100,
FRIEND_RECV_ENERGY_MAX       = 30, --好友祝福系统可领取最大体力上限
FRIEND_BLESS_ENERGY_MAX      = 30, --好友祝福系统可祝福最大体力上限   
FRIEND_BLESS_TIME_LIMIT      = 1, --一天只能祝福一次
FRIEND_HIRE_TIMESUP          = 1200,
FRIEND_CONTEXT_LEN_LIMIT     = 300,
----------------------------------------------------------
------------------- 邮件系统 -------------------------
----------------------------------------------------------
MAIL_TIMEOUT = 5184000, --两个月的秒数
MAIL_CLEAN_INTERVAL = 86400, --两个月的秒数
MAIL_CLEAN_HOUR     = 3,

MAIL_STATE_NONE = 0, --未读,无附件 0 => 2
MAIL_STATE_HAVE = 1, --未读,带附件 1 => 3 OR 4
MAIL_STATE_READ = 2, --已读,无附件
MAIL_STATE_HERE = 3, --已读,附件未领取
MAIL_STATE_RECE = 4, --已读,附件已领取

MAIL_TYPE_TEXT = 0,
MAIL_TYPE_ID   = 1,

MAIL_PUBLIC  = 0,
MAIL_PRIVATE = 1,
--经验来源
--EXP_SOURCE_MAIL    = 1,           --来自邮件
--EXP_SOURCE_MISSION = 2,           --来自关卡副本


--服务器时间接口的宏
SERVER_TIMESTAMP            = 1,    --获取服务器时间戳
SERVER_PASSTIME             = 2,    --获取游戏开始以后流逝的时间
SERVER_SERVER_START_TIME    = 3,    --配置在表里面的服务器开服时间
SERVER_TIMEZONE             = 4,    --获取时区
SERVER_TICK             	= 5,    --获取TICK（毫秒级）

--BaseData数据的key
BASE_DATA_KEY_GAME_START_TIME = "GAME_START_TIME",    --游戏开始时间

--vip字段映射key

DAILY_GOLD_METALLURGY_TIMES      = 1, --每日已炼金次数
DAILY_RUNE_WISH_TIMES            = 2, --符文已许愿次数
DAILY_ENERGY_BUY_TIMES           = 3, --体力已购买次数
DAILY_EXTRA_CHALLENGE_TIMES      = 4, --每日额外挑战次数
DAILY_HARD_MOD_RESET_TIMES       = 5, --困难副本进入已重置次数
DAILY_RAID_SWEEP_TIMES           = 6, --剧情关卡已扫荡次数
DAILY_TOWER_SWEEP_TIMES          = 7, --试炼之塔已扫荡次数
DAILY_TIME_STAMP                 = 8, --每日玩家时间戳记录
DAILY_ITEM_CAN_BUY_ENTER_SDTIMES = 9, --圣域守卫战额外购买次数
--DAILY_MISSION_TIMES              = 10,--每天副本的进入次数
DAILY_DRAGON_ATK_BUY_TIMES       = 11,--每日飞龙袭击购买次数
DAILY_DRAGON_CONVOY_BUY_TIMES    = 12,--每日飞龙附送购买次数
----------------------------------------------------------
------------------- 圣域守卫战 -------------------------
----------------------------------------------------------
NUM_PLAYER_PER_MAP      = 4,
SANCTUARY_BOSS_SPWAN_ID = 99,

--装备位
EXCH_BODY_RING       = 9,
EXCH_BODY_WEAPON     = 10,
--全职业定义
AVATAR_ALL_VOC       = 5,

--角色装备有外观属性定义
BODY_CHEST           = 4,
BODY_ARMGUARD        = 6,
BODY_SHOES           = 8, --原先是要鞋子8，后面改为腿7
BODY_WEAPON          = 11,
BODY_LEG             = 7,

BODY_WING            = 12, --翅膀ID
BODY_SPEC_JEWEL      = 13, --宝石特效
BODY_SPEC_EQUIP      = 14, --装备特效
BODY_SPEC_STRGE      = 15, --强化特效

SPEC_JEWEL_IDNEX     = 1, --宝石特效
SPEC_EQUIP_IDNEX     = 2, --装备特效
SPEC_STRGE_IDNEX     = 3, --强化特效
--装备品质定义
ITEM_QUALITY_WHITE   = 1, --白色
ITEM_QUALITY_GREEN   = 2, --绿色
ITEM_QUALITY_BLUE    = 3, --蓝色
ITEM_QUALITY_PURPLE  = 4, --紫色
ITEM_QUALITY_ORANGE  = 5, --橙色
ITEM_QUALITY_GOLD    = 6, --暗金




--道具数据项脏标记类型
ITEM_DATA_TYPE_RAW      = 0,   --数据没有改变，不需要系统处理
ITEM_DATA_TYPE_NEW      = 1,  --新增加数据，需要insert data item
ITEM_DATA_TYPE_UPDATE   = 2,  --源数据被修改，需update data item
ITEM_DATA_TYPE_DELETE   = 3,  --数据被删除， 需要delete data item

ITEM_STATUS_COMPLE      = 0,   --当前内存数据与DB一致
ITEM_STATUS_DELETE      = 1,   --当前数据需要被删除
ITEM_STATUS_UPDATE      = 2,   --当前数据需要被更新
ITEM_STATUS_INSERT      = 3,   --当前数据需要插入到数据库



ITEM_OPTION_DELETE      = 1, --删除 前端数据0
ITEM_OPTION_UPDATE      = 2, --更新 前端数据1
ITEM_OPTION_ADD         = 3, --增加 前端数据

AVATAR_DESTROY          = 1, --角色销毁   
AVATAR_EXISTED          = 2, --角色存在

SUMMON_MOD_ALL_DEAD  	= 1,  --之前的怪物全部死光才刷
SUMMON_MOD_NUM_LIMIT 	= 2,  --达到上限不触发召唤
SUMMON_MOD_KILL_LEFT 	= 3,  --杀死之前剩下的小怪

ITEM_SAVE_UNDO        	= 0,  --当前数据没有存盘
--以下三种状态表示存盘过程中状态变更
ITEM_SAVE_COMPLE      	= 1,  --回调前数据与回调后保持一致
ITEM_SAVE_UPDATE      	= 2,  --回调前数据再次被改变
ITEM_SAVE_MOVED       	= 3,  --回调前数据背包格子发生变化

TEM_DATA_CLIENT_DELETE  = 1,  --当前道具流为删除1
ITEM_DATA_CLIENT_UPDATE = 2,  --当前道具流为更新2
ITEM_DATA_CLIENT_ADDNEW = 3,  --当前道具流为增加3

--湮灭之门
OBLIVION_GATE_TO_MAP    = {[1] = 30001, [2] = 30002},
OBLIVION_MAP_TO_GATE    = {[30001] = 1, [30002] = 2},
OBLIVION_CLOSED_TIME    = 2 * 60 * 60,    --副本结束时间，单位：秒
OBLIVION_ENTER_TIME     = 60 * 60,        --副本进入CD时间，单位：秒

--禁言类型
NO_SPEAK_FOREVER           = -1,
SPEAK_FREE                 = 0,  --能够自由发言

PRICE_GOLD                 = 1,  --体力花费金币
PRICE_DIAMOND              = 2,  --体力花费钻石
VARIABLE_PRICE             = 1,  --可变价格
FIXED_PRICE                = 2,  --固定价格

--购买的物品类型
PRICE_LIST_BUY_TYPE_HP                = 1, --表示血瓶
PRICE_LIST_BUY_TYPE_RUNE              = 2, --表示金币抽符文
PRICE_LIST_BUY_TYPE_DIAMOND           = 3, --表示钻石抽符文
--体力系统
PRICE_LIST_ENERGY_PRICE_LIST_INDEX    = 4,  --体力价格索引
--副本重置次数
PRICE_LIST_MISSION_RESET_INDEX        = 10, --副本重置次数索引
--炼金系统 
PRICE_LIST_GOLDMETALLURGY_COST_INDEX  = 11, --炼金消耗
PRICE_LIST_GOLDMETALLURGY_GAIN_INDEX  = 12, --炼金产出
--塔防副本复活次数索引
PRICE_LIST_TOWER_DEFENCE_REVIVE_INDEX = 20,
--飞龙相关价格索引

SINGLE_TIME                = 0, --单次购买
ALL_TIEMS                  = 1, --全部购买

--道具实例
ITEM_INSTANCE_GRIDINDEX    = 1, --背包索引
ITEM_INSTANCE_TYPEID       = 2, --道具id
ITEM_INSTANCE_ID           = 3, --实例id
ITEM_INSTANCE_BINDTYPE     = 4, --绑定类型
ITEM_INSTANCE_COUNT        = 5, --堆叠数量
ITEM_INSTANCE_SLOTS        = 6, --宝石插槽
ITEM_INSTANCE_EXTINFO      = 7, --扩展信息

--二级属性率分类定义
PROP_RATE_DEFENCE          = 1, --防御
PROP_RATE_CRIT             = 2, --暴击
PROP_RATE_TRUESTRIKE       = 3, --破击
PROP_RATE_ANTIDEFENSE      = 4, --穿透
PROP_RATE_PVPADDITION      = 5, --PVP增伤
PROP_RATE_PVPANTI          = 6, --PVP减伤
PROP_RATE_ANTICRITRATE     = 7, --抗暴击
PROP_RATE_ANTITSTKRATE     = 8, --抗破击

JEWEL_SLOT_TYPE            = 8, --通用宝石插槽
--vip buff callback
VIP_BUFF_START             = 0, --buff开始
VIP_BUFF_END               = 1, --buff结束
VIP_LEVEL_ZERO             = 0, --没有buff

ARENA_BUFF_ID              = 41,
ARENA_WEAK                 = 1,
ARENA_STRONG               = 2,
ARENA_ENEMY                = 3,


--排行榜系统
RANK_LIST_TYPE_MIN         =  1, --排行榜编号最小值
RNAk_LIST_TYPE_MAX         =  7, --排行榜编号最大值
RANK_LIST_FIGHTFORCE       =  1, --角色战力榜
RANK_LIST_UP_LEVEL         =  2, --角色等级榜
RANK_LIST_ARENIC_CREDIT    =  3, --竞技荣誉榜
RANK_LIST_ARENIC_SCORE     =  4, --竞技积分榜
RANK_LIST_SANCTUARY        =  5, --圣域贡献榜
RANK_LIST_TOWER_CHALLENGE  =  6, --试炼挑战榜
RANK_LIST_MISSION_SBRAND   =  7, --S达人榜
RANK_LIST_TIME_STAMP       =  8, --记录更新时间戳
-------------------------------------------------
AVATAR_RANK_TYPEID         =  1, --角色装备ID
AVATAR_RANK_INDEX          =  2, --角色装备部位
AVATAR_RANK_SLOTS          =  3, --角色装备宝石插槽
-------------------------------------------------
AVATAR_RANK_UNIQUE_RANK    =  1, -- 角色排名
AVATAR_RANK_UNIQUE_DBID    =  1, -- 角色dbid
AVATAR_RANK_RECORD_NAME    =  2, -- 角色名称
AVATAR_RANK_HIGHESTLEVEL   =  3, -- 角色等级
AVATAR_RANK_ATTRIBUTION    =  4, -- 角色排行榜属性
AVATAR_RANK_FANS_COUNT     =  5, -- 粉丝数量
AVATAR_RANK_SECOND_DEFINE  =  6, -- 排行榜第二属性
AVATAR_RANK_CLIENT_DBID    =  6, -- 前端用的dbid
-------------------------- -- -, -- ---------------------------------------------------------------
AVATAR_RANK_FIGHTFORCE     =  4, -- 战斗力
AVATAR_RANK_ARENIC_SCORE   =  4, -- 竞技场周积分
AVATAR_RANK_ARENIC_CREDIT  =  4, -- 竞技场荣誉
AVATAR_RANK_SANCTUARY      =  4, -- 圣域之战
AVATAR_RANK_SMISSION       =  4, -- 副本S数量
AVATAR_RANK_TOWER_FLOOR    =  4, -- 试炼之塔历史通关最高层
------------------------------------------------------------------------------------------------
AVATAR_INFO_NAME           =  1, --角色名称
AVATAR_INFO_LEVEL          =  2, --角色等级
AVATAR_INFO_VOCATION       =  3, --角色职业
AVATAR_INFO_EQUIPMENT      =  4, --角色装备
AVATAR_INFO_RANK_LIST      =  5, --角色所有榜单列表
AVATAR_INFO_GENDER         =  6, --角色性别
------------------------------------------------------------------------------------------------
AVATAR_IDOL_DBID           =  1, --偶像的dbid
AVATAR_IDOL_CHANGE         =  2, --今日是否变更偶像
AVATAR_IDOL_REWARD         =  3, --是否领取过奖励
AVATAR_IDOL_SELF           =  7, --不能成为自己的粉丝
-------------------------------------------------------------------------------------------------
AVATAR_DRAGON_OVER         =  8, --飞龙护送次数已用完

-------------------------------------------------------------------------------------------------
IDOL_NAME_PREFIX           =  6,   --玩家称呼前缀：比如：亲爱的
----------------------------- -------------------------------------------------------------
HAS_IDOL_TITLE             =  3,   --邮件主题(有偶像)
HAS_IDOL_TEXT              =  5,   --邮件内容(有偶像)
----------------------------- -------------------------------------------------------------
NOT_IDOL_TITLE             =  3,   --邮件主题(没有偶像)
NOT_IDOL_TEXT              =  4,   --邮件内容(没有偶像)
NOT_IDOL_NAME              =  2,   --发件人名称(没有偶像)
------------------------------------------------------------------------------------------------
--飞龙大赛配置:avatar
------------------------------------------------------------------------------------------------
DRAGON_BASE                =  1,  --飞龙基本配置表
DRAGON_QUALITY             =  2,  --飞龙品质配置表
DRAGON_REWARDS             =  3,  --飞龙奖励配置表
DRAGON_STATION             =  4,  --飞龙站点配置表
DRAGON_EVENTS              =  5,  --飞龙事件配置表

DRAGON_STATION_MAX         =  10,  --站点最大编号

AVATAR_DRAGON_STIME        =  1,   --结束时间戳
AVATAR_DRAGON_ATKTIMES     =  2,   --袭击别人的次数
AVATAR_DRAGON_ATKTIME      =  3,   --袭击别人时间戳
AVATAR_DRAGON_CURRRING     =  4,   --当前的环数
AVATAR_DRAGON_REVENGE      =  5,   --复仇次数
AVATAR_DRAGON_QUALITY      =  6,   --飞龙的品质
AVATAR_DRAGON_REWDS        =  7,   --获取奖励
AVATAR_DRAGON_ADVES        =  8,   --飞龙对手
AVATAR_DRAGON_RSTIME       =  9,   --每天重置时间戳
AVATAR_DRAGON_LASTBUF      =  10,  --角色上次的buff标记
AVATAR_DRAGON_CURRBUF      =  11,  --本次护送是否触发buff
AVATAR_DRAGON_CCRING       =  12,  --当前附送次数
AVATAR_DRAGON_EXPLRE       =  9,   --探索标记


DRAGON_START_BUFF_OK       =  1,   --探索开始加buff
DRAGON_START_BUFF_NO       =  0,   --直接开始不加buff

DRAGON_QUALITY_GREEN       =  2,   --飞龙绿色品质
DRAGON_QUALITY_BLUE        =  3,   --飞龙蓝色品质
DRAGON_QUALITY_PURPLE      =  4,   --飞龙粉色品质
DRAGON_QUALITY_ORANGE      =  5,   --飞龙橙色品质
DRAGON_QUALITY_GOLD        =  6,   --飞龙暗金品质
-----------------------------------------------------------------------------------------------------
DRAGON_RING_START          =  1,   --护送开始
DRAGON_RING_END            =  2,   --护送结束
-----------------------------------------------------------------------------------------------------
--fly dragon mgr
-----------------------------------------------------------------------------------------------------
AVATAR_DRAGON_EVENTS       =  1,   --事件列表
AVATAR_DRAGON_ATKEDSTIMES  =  2,   --被袭击成功次数
AVATAR_DRAGON_LEVEL        =  3,   --角色等级
AVATAR_DRAGON_DAGQUA       =  4,   --飞龙品质
AVATAR_DRAGON_CNTRING      =  5,   --当前环数
AVATAR_DRAGON_STARTTIME    =  6,   --护送开始时间
AVATAR_DRAGON_ADVERSARY    =  7,   --对手信息
AVATAR_DRAGON_EQUIPS       =  8,   --对手显示装备
--EVENT DEFINE
EVENT_REVENGE_NO           =  0,   --等待复仇
EVENT_REVENGE_OK           =  1,   --已复仇
EVENT_REVENGE_UNUSE        =  2,   --不需复仇       

EVENT_DRAGON_DBID          =  1,   --对象
EVENT_DRAGON_ETYPE         =  2,   --事件类型
EVENT_DRAGON_QUALITY       =  3,   --飞龙品质
EVENT_DRAGON_GAIN          =  4,   --奖励物品
EVENT_DRAGON_STAMP         =  5,   --时间戳
EVENT_DRAGON_REVENGE       =  6,   --复仇状态
EVENT_DRAGON_NAME          =  7,   --对象名称

EVENT_TYPE_CONVOY          =  1,   --护送事件
EVENT_TYPE_ATK_WIN         =  2,   --袭击成功事件
EVENT_TYPE_ATK_LOSE        =  3,   --袭击失败事件
EVENT_TYPE_ATKED_WIN       =  4,   --战胜被袭击者事件
EVENT_TYPE_ATKED_LOSE      =  5,   --战败被袭击者事件

ADVERSARY_INFO_DBID        =  1,  --角色dbid
ADVERSARY_INFO_FFORCE      =  2,  --角色战斗力
ADVERSARY_INFO_GUILD       =  3,  --角色公会名称
ADVERSARY_INFO_QUALITY     =  4,  --角色飞龙品质
ADVERSARY_INFO_ASTATUS     =  5,  --角色袭击状态
ADVERSARY_INFO_ATIMES      =  6,  --角色被成功袭击次数
ADVERSARY_INFO_REWARD      =  7,  --角色袭击成功可获得的奖励
ADVERSARY_INFO_LEVEL       =  8,  --角色等级
ADVERSARY_INFO_NAME        =  9,  --角色名称
ADVERSARY_INFO_CHEST       =  10, --胸甲
ADVERSARY_INFO_WEAPON      =  11, --武器
ADVERSARY_INFO_VOCATION    =  12, --职业

ADVERSARY_ATK_CAN          =  0,  --可袭击状态
ADVERSARY_ATK_CANNOT       =  1,  --不可袭击

AVATAR_BASE_INFO           =  1,  --角色基本信息
AVATAR_BASE_ADVERS         =  2,  --角色袭击对手

--副本定时器ID
TIMER_ID_END               =  1,
TIMER_ID_SUCCESS           =  2,
TIMER_ID_MONSTER_DIE       =  3,
TIMER_ID_DESTROY           =  4,
TIMER_ID_START             =  5,
TIMER_ID_PREPARE_START     =  6,
TIMER_ID_ACITVITY_SETTLE   =  7,
TIMER_ID_DELAY_ACTIVE      =  8,

-----------------------------------------------
DRAGON_TITLE_WIN           =  25030,   --战斗胜利标题
DRAGON_TEXT_WIN            =  25031,   --战斗胜利内容
DRAGON_TITLE_LOSS          =  25032,   --战斗失败标题
DRAGON_TEXT_LOSS           =  25033,   --战斗失败内容
-----------------------------------------------

DRAGON_PVP_DBID            =  1,        --dbid
DRAGON_PVP_NAME            =  2,        --name
DRAGON_PVP_LEVEL           =  3,        --level
DRAGON_PVP_QUALITY         =  4,        --dragon quality
DRAGON_PVP_CURRNG          =  5,        --current ring

DRAGON_BATTLE_LOSE         =  0,        --战斗失败
DRAGON_BATTLE_WIN          =  1,        --战斗胜利

WORLD_GOLD_START           =  26334,    --开始护送金龙
WORLD_GOLD_ATK             =  26335,    --袭击金色金龙

FRESH_DRAGON_OK            =  26344,    --飞龙刷新成功
START_DRAGON_OK            =  26347,    --飞龙开始浮空
--Avatar的base上的标记位
AVATAR_BASE_STATE_NEWBIE   = 0,    --Avatar身上的标记位


GM_RIGHT_OPEN              = 1,    --开始GM关联
GM_RIGHT_CLOSE             = 0,    --关闭GM关联
-----------------------------------------------
SPAWNPOINT_TRIGGER_TYPE_STEP  = 0,  --踩点触发出生点刷出怪物
SPAWNPOINT_TRIGGER_TYPE_BEGIN = 1, --开场触发出生点刷出怪物
-----------------------------------------------
WING_BASE_INDEX            = 1,    --翅膀配置
WING_LEVEL_INDEX           = 2,    --翅膀等级配置

WING_ORDINARY_TYPE         = 1,    --普通翅膀
WING_MAGIC_TYPE            = 2,    --幻化翅膀

WING_LIMIT_VOC             = 1,    --翅膀职业限制
WING_LIMIT_VIP             = 2,    --翅膀VIP限制

WING_DATA_LEVEL            = 1,    --翅膀等级  
WING_DATA_EXP              = 2,    --翅膀经验
WING_DATA_ACT              = 3,    --激活标志

WING_MAGIC_NOACTED         = 0,    --没激活
WING_MAGIC_ACTIVED         = 1,    --已激活

WING_INIT_LEVEL            = 1,    --初始化等级
WING_INIT_EXP              = 0,    --初始化经验值

WING_BODY_INDEX            = 1,    --穿戴的翅膀
WING_DATA_INDEX            = 2,    --翅膀数据

JEWEL_AUTO_INLAY_TEXT      = 14,   --宝石自动镶嵌邮件内容
JEWEL_AUTO_INLAY_TITLE     = 15,   --宝石自动镶嵌邮件主题
JEWEL_AUTO_INLAY_PREFIX    = 13,   --宝石自动镶嵌邮件称呼
JEWEL_AUTO_INLAY_SYS       = 12,   --宝石自动镶嵌邮件发送者

JWEl_AUTO_MSG_OK           = 1089,  --宝石全部镶嵌到新装备上
JWEl_AUTO_MSG_BAG          = 1090,  --宝石进入背包
JWEl_AUTO_MSG_MAIL         = 1091,  --宝石进入邮件

JEWL_AUTO_MAIL_SENDER      = 40020,  --发件人称呼
JEWL_AUTO_MAIL_TEXT        = 40022,  --发件人内容
JEWL_AUTO_MAIL_TITLE       = 40021,  --发件人主题
}

----------------------------------------------------------------------------------------------------
public_config = cfg
return public_config

