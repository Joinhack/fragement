--author:hwj
--date:2014-01-08
--充值管理器

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_error = lua_util.log_game_error
local mailbox_call = lua_util.mailbox_call
local mailbox_client_call = lua_util.mailbox_client_call
local globalbase_call = lua_util.globalbase_call

----------------------------------------------------------------------------------------------------
ChargeMgr = {}
ChargeMgr.__index = ChargeMgr
----------------------------------------------------------------------------------------------------

function ChargeMgr:__ctor__()
    log_game_info('ChargeMgr:__ctor__', '')

    if self:getDbid() == 0 then
        --首次创建
        --self.create_time = os.time()
        self:writeToDB(lua_util.on_basemgr_saved('ChargeMgr'))
    else
        self:RegisterGlobally("ChargeMgr", lua_util.basemgr_register_callback("ChargeMgr", self:getId()))
    end
end

--注册globalbase成功后回调方法
function ChargeMgr:OnRegistered()
    log_game_info("ChargeMgr:OnRegistered", "")

    --预加载所有的充值记录
    self:TblSelect(self:get_callback_id(), "ChargeMgr_recs",
        "select id,sm_order_id,sm_game_id,sm_server_id,sm_account,sm_pay_way,sm_amount,sm_avatar_dbid,sm_order_status,sm_failed_desc,sm_sign,sm_create_time,sm_use from tbl_ChargeMgr_recs")

    ----预加载完成之后才能注册
    ----向GameMgr注册
    --globalbase_call('GameMgr', 'OnMgrLoaded', 'ChargeMgr')
end

function ChargeMgr:onTblSelectResp(cb, rst)
    log_game_debug("ChargeMgr:onTblSelectResp","")
    local count = 0
    local recs = self.recs
    for dbid, rec in pairs(rst) do
        local tmp = recs[rec.account]
        if tmp then
            tmp[dbid] = rec
        else
            recs[rec.account] = {[dbid] = rec }
        end

        count = count + 1
    end
    log_game_info("ChargeMgr:onTblSelectResp", "rec_loaded=%d", count)

    --向GameMgr注册
    globalbase_call('GameMgr', 'OnMgrLoaded', 'ChargeMgr')
end

--获取新的callback_id
function ChargeMgr:get_callback_id()
    local cb = self.callback_id + 1
    self.callback_id = cb

    return cb
end

--[[
order_id=2014012214084267823008&
game_id=1375328379751540&
server_id=999&
uid=275247220&
pay_way=1&
amount=1.00&
callback_info=4294967302&
order_status=S&
failed_desc=&
sign=5927751be595de7afc2d28f6fe91f58b&
plat=uc
]]

local function _make_rec(ord_info)
    local plat = ord_info.plat
    local t = {
        order_id = ord_info.order_id .. '_' .. plat, --订单号加平台id作为唯一的订单号
        game_id = ord_info.game_id or '',
        server_id = ord_info.server_id or '',
        account = '' .. plat .. '_' .. ord_info.uid,
        --account = ord_info[5],
        pay_way = ord_info.pay_way or '',
        amount = tonumber(ord_info.amount),
        avatar_dbid = tonumber(ord_info.callback_info or '0') or 0,
        order_status = ord_info.order_status or '',
        failed_desc = ord_info.failed_desc or '',
        sign = ord_info.sign or '',
        create_time = os.time(),
        use = 0,
    }
    --兼容测试
    if plat == '0' then
        t.account = ord_info.uid
    end
    return t
end

local function _format_key_value(value)    
        local tmp = lua_util.split_str(value, '&')
        local tmp2 = {}
        for _, v in pairs(tmp) do
            if string.find(v, "=") ~= nil then --有“=”的才算参数
                local tmp = lua_util.split_str(v, '=')
                local id =  tmp[1] or ""
                local num =  tmp[2] or ""
                tmp2[id] = num
            end
        end
        return tmp2
      
end

function ChargeMgr:browserResponse(fd,err)
    mogo.browserResponse(fd,err)
    --if err ~= '1' then
        log_game_info("ChargeMgr:browserResponse","fd[%d],err[%s]",fd,err)
    --end
end

--来自web的充值请求, client_fd,plat_id(str),lua_table
function ChargeMgr:onChargeReq(fd,cmd,url) 
    log_game_info("ChargeMgr:onChargeReq", "fd[%d],cmd[%s],url[%s]",fd,cmd,url)
    local ord_info = _format_key_value(url)
    local rec = _make_rec(ord_info)
    --检查订单是否重复
    for acc,v in pairs(self.recs) do
        for dbid,t_rec in pairs(v) do
            if rec.order_id == t_rec.order_id then
                return self:browserResponse(fd,error_code.ERR_BROWSER_RESP_REDUP)
            end
        end 
    end
    
    if rec and rec.account and rec.order_id and rec.amount > 0 then
        --输入参数是完整的,先存盘,存盘成功后才继续后面的流程
        local cb = self:get_callback_id()
        self:TblInsert(cb, "ChargeMgr_recs", rec)
        self.recs_tmp[cb] = {fd,rec}
    else
        self:browserResponse(fd,error_code.ERR_BROWSER_RESP_PARAM)
    end
end

function ChargeMgr:onTblInsertResp(cb, newid, err)
    local tmp = self.recs_tmp[cb]
    if not tmp then return end
    self.recs_tmp[cb] = nil
    if newid == 0 then
        self:browserResponse(tmp[1],error_code.ERR_BROWSER_RESP_FAILE)
        return
    end
    local rec = tmp[2]

    local account = rec['account']

    local tmp2 = self.recs[account]
    if tmp2 then
        tmp2[newid] = rec
    else
        self.recs[account] = {[newid]=rec }
    end

    --记录充值成功日志,用于对账
    log_game_info("charge_new_rec", "avatar_dbid=%s,ord_dbid=%q;account=%s;ord=%s;amount=%d",
        rec['avatar_dbid'],newid, account, rec['order_id'], rec['amount'])

    --通知UserMgr看玩家是否在线,如果在线则领取充值元宝
    local ord_list = {
        [1] = {avatar_dbid=rec['avatar_dbid'],ord_dbid=newid,create_time=rec['create_time'],diamond=self:Rmb2Diamon(rec.amount),}
    }
    globalbase_call("UserMgr", "NotifyCharge", account,rec['avatar_dbid'],ord_list,tmp[1])
    --通知web那边充值成功,结果码1是充值成功
    self:browserResponse(tmp[1],error_code.ERR_BROWSER_RESP_SUC)
end

--查询是否有离线时的充值
function ChargeMgr:CheckChargeReq(base_mbstr,account_name,avatar_dbid)
    local recs = self.recs[account_name]
    if not recs then return end
    local ord_list = {}
    for dbid, rec in pairs(recs) do
        if rec.use == 0 then
            if rec['avatar_dbid'] == 0 or rec['avatar_dbid'] == avatar_dbid then
                table.insert(ord_list,{avatar_dbid=rec['avatar_dbid'],ord_dbid=dbid,create_time=rec['create_time'],diamond=self:Rmb2Diamon(rec.amount),})
            end
        end
    end
    if next(ord_list) then
        mailbox_call(base_mbstr,"OnNotifyCharge",ord_list)
    end
end

--领取充值
function ChargeMgr:WithdrawReq(base_mbstr, account_name, avatar_dbid, ord_dbid)
    local tmp = self.recs[account_name]
    if tmp == nil then
        return
    end
    local the_ord = tmp[ord_dbid]
    if not the_ord then return end
    --self.recs[account_name][ord_dbid] = nil

    if the_ord.use == 0 then
        --先到数据库修改记录
        local ord_avatar = the_ord['avatar_dbid']
        if ord_avatar == avatar_dbid or ord_avatar == 0 then
            local cb = self:get_callback_id()
            local sql = string.format("update tbl_ChargeMgr_recs set sm_use = 1 where id = %q",ord_dbid)
            the_ord.use = 1
            self:TblExcute(cb, sql)
            --需要存库这种未处理，担心回来时客户端掉线
            self.recs_exc[cb] = {base_mbstr, avatar_dbid, the_ord}
        end
    end
end

--tableDelete的回调方法,ret:删除结果0:成功
function ChargeMgr:onTblExcuteResp(cb, ret, err)
    local tmp = self.recs_exc[cb]
    if tmp then
        --删除内存中的数据
        self.recs_exc[cb] = nil

        local rec = tmp[3]
        --记录日志
        log_game_info("charge_del_rec", "avatar_dbid=%q;account=%s;ord=%s;amount=%d",
            tmp[2], rec.account, rec.order_id, rec.amount)
        if ret == 0 then
            --发消息给Avatar进行充值
            local diamond = self:Rmb2Diamon(rec.amount)
            mailbox_call(tmp[1], "OnWithdrawResp", rec.amount, diamond)
        end
    end
    if ret ~= 0 then
        log_game_error('ChargeMgr:onTblExcuteResp',err)
    end
end

function ChargeMgr:Rmb2Diamon(rmb)
    return math.floor(rmb * 10)
end

--销毁前操作
function ChargeMgr:onDestroy()
    
end
----------------------------------------------------------------------------------------------------

return ChargeMgr

