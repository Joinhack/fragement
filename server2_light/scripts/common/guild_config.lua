local cfg = {

----客户端与服务器交互的msg_id
--MSG_GET_GUILDS                  = 1,          --分页获取服务器的公会，                          请求：(参数1：开始索引Index，参数2：偏移值，参数3：无效    例子：从第1个公会开始，取10个公会，则传 1, 10)； 回应lua_table：({1=数量, 2={1={1=公会dbid,2=名称,3=等级,4=人数}, ...}})
--MSG_GET_GUILDS_COUNT            = 2,          --获取公会的个数，                                       请求：(参数无效)； 回应lua_table：({1=数量})
--MSG_CREATE_GUILD                = 3,          --创建一个公会                                                 请求：(参数1：无效， 参数2：无效， 参数3：公会名称)；回应lua_table：({1=公会名, 2=公会人数， 3=公会职位})
--MSG_GET_GUILD_INFO              = 4,          --获取玩家自己的公会信息                         请求：(参数无须)；回应lua_table：({1=公会名, 2=公会职位})
--MSG_SET_GUILD_ANNOUNCEMENT      = 5,          --设置公会公告                                                请求：(参数1：无效， 参数2：无效， 参数3：公告全文)； 回应lua_table：({})
--MSG_GET_GUILD_ANNOUNCEMENT      = 6,          --获取公会公告                                                请求：(参数无效)； 回应lua_table：({1=公告全文})
--MSG_APPLY_TO_JOIN               = 7,          --申请加入指定公会                                       请求：(参数1：申请加入的公会的dbid， 参数2：无效， 参数3：无效)；回应lua_table：({})
--MSG_APPLY_TO_JOIN_NOTIFY        = 8,          --通知会长和副会长有人申请了                回应lua_table：({1=申请人姓名})
--MSG_GET_GUILD_DETAILED_INFO     = 9,          --获取公会详细信息                                       请求：(参数无效)； 回应lua_table：({1=公告,2=公会资金,3=公会等级,4=公会人数,5=公会长名称,6=当前龙晶值,7={技能ID=等级,...}})
--MSG_GET_GUILD_MESSAGES_COUNT    = 10,         --获取公会消息的数量                                  请求：(参数1：消息类型， 参数2：无效， 参数3：无效              消息类型目前只有一种，传1表示获取申请加入公会的消息类型)；回应lua_table：({1=消息数量})
--MSG_GET_GUILD_MESSAGES          = 11,         --分页获取公会消息                                       请求：(参数1：开始索引Index，参数2：偏移值，参数3：消息类型(先转成字符串))； 回应lua_table：({1=消息数量,2={1={1=消息dbid,2=申请人名称,3=申请人职业,4=申请人等级,5=申请人战力}, ...}})
--MSG_ANSWER_APPLY                = 12,         --回应申请                                                         请求：(参数1：同意或者不同意(0或者1)， 参数2：申请消息的dbid，参数3：无效)； 回应lua_table：({1=同意或者不同意})
--MSG_INVITE                      = 13,         --邀请好友加入公会                                       请求：(参数1：被邀请的人的dbid， 参数2：无效， 参数3：无效)；回应lua_table：({1=被邀请的人的dbid,...})
--MSG_INVITED                     = 14,         --通知客户端被某公会邀请                          请求：()； 回应lua_table：({1=邀请流水号, 2=发出邀请的公会名称})
--MSG_ANSWER_INVITE               = 15,         --回应公会邀请                                                请求：(参数1：邀请号， 参数2：同意或者不同意，参数3：无效)； 回应lua_table：({1=发出邀请的公会名称})
--MSG_APPLY_TO_JOIN_RESULT        = 16,         --通知给客户端申请结果                              请求：()； 回应lua_table：({1=被同意或者拒绝, 2=同意或者拒绝的公会名字})
--MSG_QUIT                        = 17,         --退出公会                                                         请求：(参数无效)；回应lua_table：({})
--MSG_PROMOTE                     = 18,         --升职                                                                  请求：(参数1：被升级的人的dbid， 参数2：无效， 参数3：无效)；回应lua_table：({})
--MSG_DEMOTE                      = 19,         --降职                                                                 请求：(参数1：被降级的人的dbid， 参数2：无效， 参数3：无效)； 回应lua_table：({})
--MSG_EXPEL                       = 20,         --开除                                                                 请求：(参数1：被开除的人的dbid， 参数2：无效， 参数3：无效)；回应lua_table：({})
--MSG_DEMISE                      = 21,         --转让                                                                 请求：(参数1：被转让的人的dbid， 参数2：无效， 参数3：无效)；回应lua_table：({})
--MSG_DISMISS                     = 22,         --解散                                                                 请求：(参数无效)； 回应lua_table：({})
--MSG_THAW                        = 23,         --解冻                                                                 请求：(参数无效)； 回应lua_table：({})
--MSG_RECHARGE                    = 24,         --注魔                                                                 请求：(参数1：注魔类型，参数2：注魔量，参数3：无效)； 回应lua_table：({})
--MSG_GET_GUILD_MEMBERS           = 25,         --获取工会成员列表                                      请求：(参数1：开始索引Index，参数2：偏移值，参数3：无效)； 回应lua_table：({1={1=玩家dbid,2=姓名,3=等级,4=职位ID,5=战斗力,6=贡献度,7=上线时间}, ...})
--MSG_GET_DRAGON                  = 26,         --敲龙晶                                                                请求：(参数无效)； 回应lua_table：({})
--MSG_UPGRADE_GUILD_SKILL         = 27,         --升级公会技能                                                  请求：(参数1：技能类型，参数2：无效，参数3：无效)； 回应lua_table：({1=技能类型, 2=技能等级,})
--MSG_GET_RECOMMEND_LIST          = 28,         --公会长和副公会长获取推荐成员列表     请求：(参数无效)； 回应lua_table：({1={1=玩家dbid,2=姓名,3=等级,4=战斗力}, ...})
--MSG_GET_DRAGON_INFO             = 29,         --获取龙晶信息                                                  请求：(参数无效)； 回应lua_table：({1=注魔次数,2=上一次注魔时间})
--
----服务器内部使用
--MSG_UPGRADE_GUILD_SKILL_RESP    = 251,        --公会长升级技能成功后通知每一个公会成员
--MSG_GET_DRAGON_RESP             = 252,        --摇龙晶后获得的奖励
--MSG_RECHARGE_RESP               = 253,        --龙晶充魔的返回
--MSG_SUBMIT_CREATE_GUILD_COST    = 254,        --创建公会成功后扣除资源
--MSG_SET_GUILD_ID                = 255,        --设置玩家的公会ID

GUILD_POST_PRESIDENT            = 1,          --公会长
GUILD_POST_VICE_PRESIDENT1      = 2,          --副会长1
GUILD_POST_VICE_PRESIDENT2      = 3,          --副会长2
GUILD_POST_VICE_PRESIDENT3      = 4,          --副会长3
GUILD_POST_MEMBER               = 5,          --普通成员开始

GUILD_INFO_DBID                 = 1,          --Avatar身上的公会信息index，公会dbid
GUILD_INFO_NAME                 = 2,          --Avatar身上的公会信息index，公会名字
GUILD_INFO_POST                 = 3,          --Avatar身上的公会信息index，公会职位

--公会消息类型
GUILD_MESSAGE_TYPE_JOIN_IN      = 1,          --申请加入公会的消息

--公会长回应公会加入请求
GUILD_ANSWER_APPLY_JOIN_IN_YES  = 0,          --允许
GUILD_ANSWER_APPLY_JOIN_IN_NO   = 1,          --不允许

--被邀请方回应邀请
GUILD_INVITED_ANSWER_YES        = 0,          --被邀请方接受邀请
GUILD_INVITED_ANSWER_NO         = 1,          --被邀请方拒绝邀请

--公会的状态
GUILD_STATUS_NORMAL             = 0,          --正常状态
GUILD_STATUS_FREEZE             = 1,          --冻结状态

--注魔类型
GUILD_RECHARGE_TYPE_GOLD        = 0,          --普通注魔
GUILD_RECHARGE_TYPE_DIAMOND     = 1,          --钻石注魔

--公会技能类型
GUILD_SKILL_TYPE_ATTACK         = 1,          --攻击技能
GUILD_SKILL_TYPE_DEFENSE        = 2,          --防御技能
GUILD_SKILL_TYPE_HP             = 3,          --生命技能


--错误码
ERROR_CREATE_GUILD_LEVEL_TOO_LOW      = 1,         --创建公会时等级太低
ERROR_CREATE_GUILD_NOT_ENOUGH_DIAMOND = 2,         --钻石不足，不能创建关卡
ERROR_CREATE_GUILD_NAME_ALREADY_USED  = 3,         --公会名字已经被占用
ERROR_CREATE_GUILD_ALREADY_IN_GUILD   = 4,         --创建者已经处于一个公会，不能再创建
ERROR_SET_ANNOUNCEMENT_NO_GUILD       = 5,         --玩家没有公会不允许设置公会公告
ERROR_SET_ANNOUNCEMENT_NO_RIGHT       = 6,         --权限不足，不能设置公会公告
ERROR_GET_ANNOUNCEMENT_NO_GUILD       = 7,         --玩家没有公会不允许获取公会公告
ERROR_GET_GUILD_DETAILED_INFO_NO_GUILD= 8,         --没有公会，不能获取详细信息
ERROR_APPLY_TO_JOIN_ALREADY_IN_GUILD  = 9,         --已经属于一个公会，不能再申请
ERROR_APPLY_TO_JOIN_GUILD_NOT_EXIT    = 10,        --指定的公会不存在，不能申请加入
ERROR_GET_GUILD_MESSAGE_COUNT_NO_GUILD= 11,        --获取公会消息数量时发现没有公会
ERROR_GET_GUILD_MESSAGE_COUNT_NO_RIGHT= 12,        --获取公会消息数量时发现没有权限
ERROR_GET_GUILD_MESSAGES_NO_GUILD     = 13,        --获取公会消息数据时发现玩家没有公会
ERROR_GET_GUILD_MESSAGES_NO_RIGHT     = 14,        --获取公会消息数据时发现玩家没有权限
ERROR_ANSWER_APPLY_NO_GUILD           = 15,        --回应公会信息时发现客户端没有公会
ERROR_ANSWER_APPLY_NO_RIGHT           = 16,        --回应公会信息时发现客户端没有权限
ERROR_ANSWER_APPLY_NO_MESSAGE         = 17,        --公会没有消息
ERROR_ANSWER_APPLY_MESSAGE_NOT_EXIT   = 18,        --指定的公会消息不存在
ERROR_INVITE_NO_RIGHT                 = 19,        --没有权限，不能邀请玩家
ERROR_INVITE_NO_EXIT                  = 20,        --被邀请的玩家不存在
ERROR_INVITE_ALREADY_IN_GUILD         = 21,        --对方已经处于一个公会中，不能邀请
ERROR_INVITE_NOT_EXIT                 = 22,        --邀请不存在
ERROR_QUIT_ONLY_NORMAL_MEMBER         = 23,        --只有更普通成员才能退出
ERROR_QUIT_NO_GUILD                   = 24,        --没有公会，不能退出
ERROR_APPLY_TO_JOIN_TOO_MUCH_MEMBERS  = 25,        --公会人数已经超过了上限
ERROR_ANSWER_INVITE_TOO_MUCH_MEMBERS  = 26,        --回应邀请时公会人数已经超过了上限
ERROR_ANSWER_APPLY_TOO_MUCH_MEMBERS   = 27,        --回应申请时公会人数已经超过上限
ERROR_PROMOTE_NO_RIGHT                = 28,        --没有权限不能升级
ERROR_PROMOTE_NOT_IN_GUILD            = 29,        --要被等级提升的玩家不在公会
ERROR_PROMOTE_NOT_MYSELF              = 30,        --不能提升自己
ERROR_PROMOTE_FULL                    = 31,        --位置已满，不能再提升
ERROR_DEMOTE_NOT_MYSELF               = 32,        --不能把自己降职
ERROR_DEMOTE_NO_RIGHT                 = 33,        --没有权限不能降职
ERROR_DEMOTE_FULL                     = 34,        --位置已满，不能再降级
ERROR_EXPEL_NOT_MYSELF                = 35,        --不能开除自己
ERROR_EXPEL_NO_RIGHT                  = 36,        --没有权限不能开除
ERROR_DEMISE_NOT_MYSELF               = 37,        --不能转让给我自己
ERROR_DEMISE_NO_RIGHT                 = 38,        --没有权限，不能转让
ERROR_DISMISS_NO_RIGHT                = 39,        --没有权限解散公会
ERROR_DISMISS_ALREADY_IN_DELETED      = 40,        --已经进入冻结状态不能再删除
ERROR_THAW_NOT_ENOUGH_DIAMOND         = 41,        --不够钻石解冻
ERROR_THAW_NO_NEED                    = 42,        --没有冻结，无须解冻
ERROR_THAW_NO_GUILD                   = 43,        --没有公会，无须解冻
ERROR_ANSWER_APPLY_STATUS_FREEZE      = 44,        --公会处于冻结状态中，不能接受申请
ERROR_ANSWER_INVITE_STATUS_FREEZE     = 45,        --公会处于冻结状态中，不能接受邀请
ERROR_APPLY_TO_JOIN_STATUS_FREEZE     = 46,        --公会处于冻结状态，不能申请加入
ERROR_RECHARGE_NOT_ENOUGH_DIAMOND     = 47,        --钻石不足，不能注魔
ERROR_RECHARGE_NOT_ENOUGH_GOLD        = 48,        --金币不足，不能注魔
ERROR_RECHARGE_NO_GUILD               = 49,        --没有公会，不能注魔
ERROR_RECHARGE_OVER_LIMIT             = 50,        --超过上限，不能注魔
ERROR_RECHARGE_CAN_NOT                = 51,        --配置数据问题，不能注魔
ERROR_GET_GUILD_MEMBERS_NO_GUILD      = 52,        --没有公会，不能获取成员
ERROR_RECHARGE_CD                     = 53,        --cd时间没过，不能注魔
ERROR_RECHARGE_DAY_TIMES              = 54,        --每天注魔上限已到，不能再注魔了
ERROR_GET_DRAGON_NO_GUILD             = 55,        --玩家没有公会，不能摇龙晶
ERROR_GET_DRAGON_NOT_FULL             = 56,        --龙晶还没成长满，不能摇龙晶
ERROR_GET_DRAGON_OVER_TIMES           = 57,        --次数已满，不能再摇龙晶
ERROR_UPGRADE_GUILD_SKILL_NO_SUCH_TYPE= 58,        --没有该种类公会技能
ERROR_UPGRADE_GUILD_SKILL_NO_GUILD    = 59,        --没有公会，不能升级技能
ERROR_UPGRADE_GUILD_SKILL_NO_RIGHT    = 60,        --不是公会长，不能升级技能
ERROR_UPGRADE_GUILD_SKILL_ALREADY_LIMIT=61,        --公会技能已经到了上限，不能再升级
ERROR_GET_GUILD_INFO_NO_GUILD         = 62,        --没有公会
ERROR_UPGRADE_GUILD_SKILL_NOT_ENOUGH_MONEY = 63,   --没有足够的资金，不能升级
ERROR_GET_RECOMMEND_LIST_NO_RIGHT     = 64,        --没有权限，不能获取推荐列表
ERROR_GET_RECOMMEND_LIST_NO_PLAYERS   = 65,        --找不到，不能获取推荐列表
ERROR_APPLY_TO_JOIN_ALREADY_APPLY     = 66,        --已经申请过该公会了，不能再申请
ERROR_EXPEL_NOT_EXIT                  = 67,        --开除会员的时候发现公会没有该成员
ERROR_DEMISE_NOT_EXIT                 = 68,        --转让是发现对方不在本公会
ERROR_GET_DRAGON_INFO_NO_GUILD        = 69,        --没有公会，不能获取龙晶信息
}


guild_config = cfg
return guild_config