local cfg = {

--    MSG_GET_TOWER_INFO            = 1,          --获取试炼之塔的数据
--    MSG_ENTER_TOWER               = 2,          --进入指试炼之塔的指定层
--    MSG_TOWER_SWEEP               = 3,          --普通扫荡
--    MSG_TOWER_VIP_SWEEP           = 4,          --VIP扫荡
--    MSG_CLEAR_TOWER_SWEEP_CD      = 5,          --清除扫荡副本的CD
--    MSG_CLIENT_TOWER_SUCCESS      = 6,          --试炼之塔成功后由服务器返回到客户端
--    MSG_CLIENT_TOWER_FAIL         = 7,          --试炼之态失败后有服务器返回到客户端
--    MSG_CLIENT_REPORT             = 8,          --服务器向客户端发送战报
--    MSG_TOWER_SWEEP_ALL           = 9,          --全部扫荡



--    MSG_CELL2BASE_SENT_REWARD     = 253,        --cell通知base加临时奖励池道具
--    MSG_TOWER_FAIL                = 254,        --cell通知base副本失败，增加失败次数
--    MSG_CELL2BASE_TOWER_SUCCESS   = 255,        --cell通知base指定难度的副本成功了

    TOWER_INFO_HIGHEST_FLOOR        = 1,          --历史最高层数
    TOWER_INFO_CURRENT_FLOOR        = 2,          --当前层数
    TOWER_INFO_GOT_PACKAGES         = 3,          --已经拿到的包裹
    TOWER_INFO_LAST_SWEEP_TIME      = 4,          --上一次扫荡的时间戳
    TOWER_INFO_FAIL_TIMES           = 5,          --失败次数
    TOWER_INFO_LAST_FAIL_TIME       = 6,          --上一次失败时间戳
    TOWER_INFO_PACKAGES_POOL        = 7,          --试炼之塔的临时奖励池(物品)
    TOWER_INFO_PACKAGES_POOL_MONEY  = 8,          --试炼之塔的临时奖励池(钱)
    TOWER_INFO_PACKAGES_POOL_EXP    = 9,          --试炼之塔的临时奖励池(经验)
    TOWER_INFO_LAST_VIP_SWEEP_TIME  = 10,         --上一次vip扫荡的时间戳
    TOWER_INFO_VIP_SWEEP_TIMES      = 11,         --已经使用的vip扫荡的次数
    TOWER_INFO_CLEAR_SWEEP_CD_TIMES = 12,         --每日清除普通扫荡cd的次数
    TOWER_INFO_LAST_CLEAR_SWEEP_CD_TIME = 13,     --上次清除普通扫荡cd的时间戳
    TOWER_INFO_LAST_SUCCESS_TIMES   = 14,         --上一次成功的时间戳
    TOWER_INFO_NOT_HAVE_GET_PACKAGE_REWARD=15,    --未领取的奖励
    TOWER_INFO_LAST_ENTER_TIME      = 16,         --记录上一次进入试炼之塔的时间戳

    --试炼之塔错误码
    TOWER_ERROR_CODE_FAIL_TIMES  = 1,          --失败次数已超过上限，不能再进入
    TOWER_ERROR_CODE_SYSTEM_ERROR= 2,          --系统错误
    TOWER_ERROR_CODE_CFG         = 3,          --配置表错误
    TOWER_ERROR_CODE_CURRENT_NOT_SUCCESS = 4,  --当前层数还没有成功，不能进入下一层
    TOWER_ERROR_CODE_SWEEP_CD    = 5,          --2小时cd时间没过，不允许扫荡
    TOWER_ERROR_CODE_NOT_ENOUGH_TO_CLEAR_SWEEP_CD = 6, --没有足够砖石清空普通扫荡cd时间
    TOWER_ERROR_CODE_NOT_VIP     = 7,          --玩家没有vip等级
    TOWER_ERROR_CODE_NOT_VIP_DATA= 8,          --vip数据没有配置
    TOWER_ERROR_CODE_VIP_SWEEP_TIMES_UP = 9,   --vip扫荡的次数已经用完
    TOWER_ERROR_CODE_VIP_SWEEP_DATA = 10,      --vip扫荡的次数出错
    TOWER_ERROR_CODE_SWEEP_LEVEL    = 11,      --当前层数太低，不能扫荡
    TOWER_ERROR_CODE_SWEEP_TIMES_UP = 12,      --扫荡次数已经用完，今天不能再扫荡
    TOWER_ERROR_CODE_SWEEP_ALL_LEVEL= 13,      --VIP等级不足，不能全部扫荡
    TOWER_ERROR_CODE_SWEEP_NO_REWARD= 14,      --配置错误，不能获取奖励
    TOWER_ERROR_CODE_VIP_SWEEP_NO_REWARD= 15,      --配置错误，不能获取奖励
}

tower_config = cfg
return tower_config