--------------------邮件结构-----------------------
mailIndex = {
    fromId     = 1,
    fromName   = 2,
    status     = 3,
    attachment = 4,
    timeout    = public_config.OFFLINE_ITEM_TIMEOUT_INDEX,
}

--------------------邮件信息结构(存储在tbl_OfflineData)-----------------------
mailOfflineItemIndex = {
	mailId = 1,
	from = 2,
	title = 3,
	state = 4,
	attachment = 5,
	mailType = 6,                     --表示是文字邮件还是ID邮件
	mailParam = 7,                    --当mailType为ID类型时，组合成文字类型的邮件时需要的参数
	reason = 8,                       --原因说明，说明附件的来源
	time = 9,
	timeout = public_config.OFFLINE_ITEM_TIMEOUT_INDEX,
}
--[[
ERR_MAIL_SUCCEED                  = 0,                --邮件操作成功
ERR_MAIL_NOT_EXISTS               = 1,                --邮件不存在
ERR_MAIL_NO_ATTACHMENT            = 2,                --邮件没有附件可领取
ERR_MAIL_ATTACHMENT_GETED         = 3,                --邮件附件已被领取过
ERR_MAIL_TIMEOUT                  = 4,
ERR_MAIL_BAG_FULL                 = 5,                --背包已满不能领取附件
]]
mailTextId = {
	--领取附件
	MAIL_GET_ATTA_SUCCEED                  = 758,                --邮件操作成功
	MAIL_GET_ATTA_NOT_EXISTS               = 759,                --邮件不存在
	MAIL_GET_ATTA_NO_ATTA                  = 760,                --邮件没有附件可领取
	MAIL_GET_ATTA_GETED                    = 761,                --邮件附件已被领取过
	MAIL_GET_ATTA_BAG_FULL                 = 762,                --背包已满不能领取附件
	--删除邮件
	MAIL_DEL_SUCCEED                       = 763,
	MAIL_DEL_ATTA_HERE                     = 764,
	MAIL_DEL_NOT_READ                      = 765,
	MAIL_DEL_ALL_SUCCEED                   = 766,
	MAIL_DEL_ALL_NO                        = 767,
	MAIL_DEL_NOT_EXISTS                    = 759,
}
