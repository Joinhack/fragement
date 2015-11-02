require "public_config"

--离线数据类型
OfflineType = 
{
    -->friend system
    OFFLINE_RECORD_FRIEND_NOTE               = 1,
    OFFLINE_RECORD_FRIEND_REQ                = 2,
    OFFLINE_RECORD_FRIEND_ACCEPT_BE          = 3,
    OFFLINE_RECORD_FRIEND_DEL_BE             = 4,
    --<friend system

    --OFFLINE_RECORD_CMD           = 4,
    --OFFLINE_RECORD_EMAIL         = 5,

    --user mgr
    OFFLINE_RECORD_USER_MGR_FRIEND_NUM      = 7, --在线管理器需要存盘的数据 --已经不在离线管理器
    --mail system
    OFFLINE_RECORD_MAIL                     = 8,                            --已经不在离线管理器
    MSG_RECORD_BLESS_BE                     = 9, --离线被祝福
}

--离线数据存储类型
g_offline_data_save_type = 
{
    [OfflineType.OFFLINE_RECORD_FRIEND_NOTE] = public_config.OFFLINE_SAVE_REDIS,
    [OfflineType.OFFLINE_RECORD_FRIEND_REQ] = public_config.OFFLINE_SAVE_REDIS,
    [OfflineType.OFFLINE_RECORD_FRIEND_ACCEPT_BE] = public_config.OFFLINE_SAVE_REDIS,
    [OfflineType.OFFLINE_RECORD_FRIEND_DEL_BE] = public_config.OFFLINE_SAVE_REDIS,
    [OfflineType.OFFLINE_RECORD_USER_MGR_FRIEND_NUM] = public_config.OFFLINE_SAVE_REDIS,
    [OfflineType.OFFLINE_RECORD_MAIL] = public_config.OFFLINE_SAVE_MYSQL,
    [OfflineType.MSG_RECORD_BLESS_BE] = public_config.OFFLINE_SAVE_REDIS,
}

return OfflineType