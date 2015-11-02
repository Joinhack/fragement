local client_text_id = 
{
	FRIEND_BLESS_CDING                = 735,
	FRIEND_BLESS_NOT_FRIEND           = 736,
	FRINED_BLESS_SUC                  = 737,

	--祝福提示
	FRIEND_BLESS_LIMIT_1              = 739,
	FRIEND_BLESS_LIMIT_2              = 740,
	FRIEND_BLESS_ENERGY               = 741,

	WB_ENTER_SUCCESS                  = 24010,       --进入成功
	WB_ENTER_NOT_OPEN                 = 24011,       --活动没开始
	WB_ENTER_LV                       = 24012,       --等级不够
	--WB_ENTER_VIP                      = 3,       --vip数值错误（前端可以忽略）
	WB_ENTER_TIME                     = 24013,       --可进入次数为零
	WB_ENTER_STATE                    = 24014,       --已经是进入状态
	WB_ENTER_FULL                     = 24015,       --人数已满

	WB_BUY_CAN                        = 24020,       --可购买或者购买成功
	WB_BUY_NO_NEED                    = 24021,       --无需购买
	WB_BUY_FULL                       = 24022,       --可购买次数已用完
	WB_BUY_NO_MONEY                   = 24023,       --金钱不够

	WB_FIGHT_FAIL_TITLE               = 24026,
	WB_FIGHT_FAIL_TEXT                = 24027,
	WB_FIGHT_SUC_TITLE                = 24028,
	WB_FIGHT_SUC_TEXT                 = 24029,

	--领取周累计贡献奖励
	WB_CTRBU_REWARD_ID                = 24050,        --非法id
	WB_CTRBU_REWARD_LV                = 24051,        --等级与id不匹配
	WB_CTRBU_REWARD_ED                = 24052,        --已经领取过
	WB_CTRBU_REWARD_LE                = 24053,        --贡献不够
	WB_CTRBU_REWARD_SU                = 24054,        --领取成功

	MISSION_MAIL_REWARD_FROM          = 40000,
	MISSION_MAIL_REWARD_TITLE         = 40001,
	MISSION_MAIL_REWARD_TEXT          = 40002,

	MISSION_SWEEP_MAIL_REWARD_TITLE   = 40003,
	MISSION_SWEEP_MAIL_REWARD_TEXT    = 40004,

	MISSION_TREASURE_MAIL_REWARD_TITLE   = 40005,
	MISSION_TREASURE_MAIL_REWARD_TEXT    = 40006,

    MISSION_MAIL_RANDOM_REWARD_FROM          = 40007,
    MISSION_MAIL_RANDOM_REWARD_TITLE         = 40008,
    MISSION_MAIL_RANDOM_REWARD_TEXT          = 40009,

    MISSION_MAIL_OFFLINE_RANDOM_REWARD_FROM          = 40010,
    MISSION_MAIL_OFFLINE_RANDOM_REWARD_TITLE         = 40011,
    MISSION_MAIL_OFFLINE_RANDOM_REWARD_TEXT          = 40012,

    MISSION_MAIL_BOSS_TREASURE                       = 40013,    --副本boss宝箱
    TOWER_SWEEP_REWARD                               = 40014,    --试炼之塔扫荡奖励
    TOWER_VIP_SWEEP_REWARD                           = 40015,    --试炼之塔VIP扫荡奖励
    TOWER_ALL_SWEEP_REWARD                           = 40016,    --全部扫荡奖励
    TOWER_TREASURE                                   = 40017,    --试炼之塔宝箱
    TOWER                                            = 40018,    --试炼之塔
    TOWER_NEW                                        = 40019,    --新的试炼之塔奖励邮件
}

g_text_id = client_text_id
return g_text_id