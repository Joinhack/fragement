-----------------好友信息--------------------
-- { 
--    [dbid] = { [degreeIndex] = 好感度值, [nextHireTimeIndex] = 上一次雇佣时间, [nextBlessTimeIndex] = 下一次可祝福时间 }
--    ...
-- }
--friendsEnergy 
--friendRefreshTime
friendsInfoIndex = {
    degreeIndex = 1,
    nextHireTimeIndex = 2,
    nextBlessTimeIndex = 3,
}
-----------------留言-------------------------
noteIndex = {
    fromId   = 1,
    fromName = 2,
    note     = 3,
    time     = 4,
    timeout  = public_config.OFFLINE_ITEM_TIMEOUT_INDEX,
}
--------------------好友请求-----------------------
reqIndex = {
    fromId   = 1,
    fromName = 2,
    level = 3,
    vocation = 4,
    timeout  = public_config.OFFLINE_ITEM_TIMEOUT_INDEX,
}
--------------------好友答应-----------------------
respIndex = {
    fromId   = 1,
    fromName = 2,
    --timeout  = 3,
}
--------------------好友删除-----------------------
delIndex = {
    fromId   = 1,
}
--------------------好友祝福-----------------------
FriendBeBlessIndex = {
    fromId   = 1,
    timeout  = public_config.OFFLINE_ITEM_TIMEOUT_INDEX,
}
--------------------好友接口协议-----------------------
msgFriendSys = {
    MSG_FRIEND_LIST  = 1,
    MSG_FRIEND_DEL  = 2,
    MSG_FRIEND_INFO = 3,
    MSG_FRIEND_QUERY = 4,
    MSG_FRIEND_NOTE_W  = 5,
    MSG_FRIEND_NOTE_R  = 6,
    --MSG_FRIEND_NOTE_D  = 7,
    --MSG_FRIEND_REJECT  = 8,
    MSG_FRIEND_ACCEPT  = 9,
    MSG_FRIEND_REQ_ADD = 10,
    MSG_FRIEND_REQ_DEL = 11, 
    MSG_FRIEND_LOGIN   = 12, --登陆处理
    MSG_FRIEND_CHECK   = 13, --检查是否有该好友
    MSG_FRIEND_REMOVE  = 14, --立即删除自己的好友
    MSG_FRIEND_INSERT  = 15, --立即新增自己的好友
    MSG_FRIEND_ISFULL  = 16, --检查好友是否已满
    MSG_FRIEND_REQ_LIST= 17, --获取好友申请的所有信息

}
--与中excel表一致
friendTipsId = 
{
    TEXT_SEND_REQ_SUCCEED = 724, --发送好友请求成功
    TEXT_ALREADY_HAVE     = 725, --对方已存在好友列表中
    TEXT_SEND_REQ_FAIL    = 726, --发送好友请求失败
    TEXT_FULL             = 727, --好友个数已满
    TEXT_THE_PLAYER_FRIEND_FULL = 728, --对方好友已满
    TEXT_SEND_NOTE_SUCCEED = 729, --发送留言成功
    TEXT_SEND_NOTE_FAIL    = 730, --发送留言失败
    TEXT_SEND_NOTE_NOT_FRIEND = 731, --不是好友不能留言
    TEXT_RECV_BLESS_FULL = 732, --今日可领体力已满
    TEXT_ADD_MYSELF      = 734,
}
