--用于与avatar交互
msgUserMgr = 
{
    MSG_USER_FRIEND_QUERY_BY_NAME = 1,

    MSG_USER_FRIEND_QUERY_BY_DBID = 2,

    MSG_USER_FRIEND_ADD_REQ       = 3,
    MSG_USER_FRIEND_ADD_REQ_BE    = 4,

    MSG_USER_FRIEND_ACCEPT        = 5,
    MSG_USER_FRIEND_ACCEPT_BE     = 6,

    MSG_USER_FRIEND_DEL_REQ_BE       = 7,

    MSG_USER_FRIEND_SEND_NOTE     = 8,
    MSG_USER_FRIEND_SEND_NOTE_BE  = 9,

    MSG_USER_FRIEND_QUERY_BY_ALL_DBID= 10,
    --在线收到邮件
    MSG_USER_MAIL_RECEIVE = 11,
    
    MSG_USER_FRIEND_BLESS        = 12,
    MSG_USER_FRIEND_BLESS_BE     = 13,

    MSG_USER_GUILD_APPLY         = 14,
    MSG_USER_GUILD_APPLY_BE      = 15,
    --在线收到群发邮件
    MSG_USER_MAIL_RECV_PUBLIC = 16,
}   



--离线管理器消息集，用于与其他entity交互
msgOfflineMgr = 
{
    --friend system
    MSG_OFFLINE_FRIEND_REQ_DEL    = 1, --
    MSG_OFFLINE_FRIEND_NOTE_GET   = 2, --
    MSG_OFFLINE_FRIEND_REQ_GET    = 3,
    --user mgr
    MSG_OFFLINE_USER_MGR_INFO_GET   = 4, --在线管理器在启动的时候获取之前保持的所有离线数据
    --mail system
    MSG_OFFLINE_MAIL_SUB_SYSTEM     = 5, --邮件信息申请
    MSG_OFFLINE_MAIL_DEL            = 6, --邮件删除
    MSG_OFFLINE_MAIL_ATTACHMENT_GET = 7, --邮件附件领取
    --friend system
    MSG_OFFLINE_FRIEND_BLESS_RECV   = 8, --离线被祝福
    MSG_OFFLINE_FRIEND_BLESS_RECV_ALL = 9, --获取所有的离线数据
}

--mail mgr 协议集
msgMailMgr = {
    MSG_MAIL_MGR_GET_MAIL = 1,

}
