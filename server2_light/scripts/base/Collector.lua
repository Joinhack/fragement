--运营活动数据采集器
require "lua_util"
require "public_config"


local globalbase_call = lua_util.globalbase_call
local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error


--游戏的金钱类型入库需要转换下
local gold2data ={}
gold2data[public_config.DIAMOND_ID] = 1  -- 1元宝对应钻石
gold2data[public_config.GOLD_ID] = 3 -- 3铜币对应金币 
setmetatable(gold2data, {__index =
function (table, key)   
    return 0
end } )--默认返回0


--collector define
local  cc_def = 
{
    HEART_DELAY = 1, --延迟这么多再加心跳
    HEART_BEAT = 60*10,        --活动检测心跳为XX秒一次
    TIMER_ID_CC =112,      


    HEART_DELAY_ZERO = 1, --延迟这么多再加心跳
    HEART_BEAT_ZERO = 10,        --活动检测心跳为XX秒一次
    TIMER_ID_CC_ZERO =113,      --活动检测心跳ID 



    TIMER_ID_CC_LOGIN_5MIN =114,      --3.1.5 在线日志（tbllog_online）PS：每5分钟记录一次
}

local tab_user_info_detail  =
{
    sm_level = "等级",
    sm_name = "角色名字",
    sm_gender = "性别",
    sm_gold = "金钱",
    sm_diamond = "钻石",
    sm_accountName = "账户名",
    sm_createTime = "创建时间",
    sm_VipLevel = "vip等级",
    sm_vocation = "职业",
}



Collector = {}
setmetatable(Collector, {__index = BaseEntity} )


--回调方法
local function _collector_register_callback(eid)
    local mm_eid = eid
    local function __callback(ret)
        local gm = mogo.getEntity(mm_eid)
        if gm then
            if ret == 1 then
                --注册成功
                gm:on_registered()
            else
                --注册失败
                log_game_warning("Collector.registerGlobally error", '')
                --destroy方法未实现,todo
                --gm.destroy()
            end
        end
    end
    return __callback
end


--写入数据库回调方法
local function sql_write_callback(sql)

   local function __callback(resut)
        if 0 == resut then
            log_game_error("Collector:InsertIntoDb", "SaveCB failed. sql: %s", sql)
            return
        else
            log_game_debug("Collector:InsertIntoDb", "SaveCB .Success!!!  sql: %s", sql) 
            return
        end
    end
     return __callback
 end




function Collector:__ctor__()
    log_game_info('Collector:__ctor__', '')

    self.login_player_num = 0

    
    --注册回调
    self:RegisterGlobally("Collector", _collector_register_callback(self:getId()))
    --end
end


--注册globalbase成功后回调方法
function Collector:on_registered()
    log_game_info("Collector:on_registered", "")    
    
    local timer= self:addTimer(cc_def.HEART_DELAY, 60*5, cc_def.TIMER_ID_CC_LOGIN_5MIN)

    --local timer_zero = self:addTimer(cc_def.HEART_DELAY_ZERO, cc_def.HEART_BEAT_ZERO, cc_def.TIMER_ID_CC_ZERO)
    globalbase_call('GameMgr', 'OnMgrLoaded', 'Collector')--表示自己已经注册完成

end
--------------------------------------------------------------------------------------


--定时器
function Collector:onTimer( timer_id, user_data )
    if user_data == cc_def.TIMER_ID_CC then
         self:ReFresh() 
    elseif user_data == cc_def.TIMER_ID_CC_ZERO then
        if self:IsNewDay() then
             log_game_info("Collector:onTimer", "new day")  
             self:ResetTodayLoginAccount() --重置今日登陆账号   
        end
    elseif user_data == cc_def.TIMER_ID_CC_LOGIN_5MIN then
        globalbase_call("UserMgr", "GetOnlineCount") --UserMgr 知道在线人数

    end   
end

function Collector:ResetTodayLoginAccount() 
    log_game_info("Collector:ResetTodayLoginAccount", "record_day %s ", self.record_day)     
    self.account_tab = {}     
    self.record_day = global_data.GetCurTimeByFormat("%d")   --%d day of the month (16) [01-31]
    log_game_info("Collector:IsNewDay", "record_day %s ", self.record_day)    

end

function Collector:IsNewDay()    
   local day = global_data.GetCurTimeByFormat("%d")   --%d day of the month (16) [01-31]
    --log_game_info("Collector:IsNewDay", "record_day %s day %s", self.record_day, day)  
   return tonumber(day) ~= tonumber(self.record_day) --现在和记录的不是同一天 则是新的一天
end



function Collector:ReFresh()    
    log_game_info("Collector:ReFresh TEMP", "") 
    self:OnTimeRecharge()   
    globalbase_call("UserMgr", "GetOnlineCount")
end


function Collector:SetOnlineCount(OnlineCount)   

    --log_game_info("Collector:SetOnlineCount TEMP", "player_num %s", OnlineCount)  

    --local sql = string.format("INSERT INTO tbl_online(online_count, timestamp) VALUES(%d, %d)", OnlineCount, global_data.GetServerTime(public_config.SERVER_TIMESTAMP))

    local sql = string.format("INSERT INTO tbllog_online(people, happend_time, log_time) VALUES(%d, %d, %d)", OnlineCount, os.time(), os.time())

    --log_game_debug("Collector:SetOnlineCount", "sql = %s", sql)    

    self:InsertIntoDb(sql)

--[[
    local function OnSetOnlineCount(resut)
        if 0 == resut then
            log_game_error("Collector:OnSetOnlineCount", "SaveCB failed.")
            return
        else
            log_game_debug("Collector:OnSetOnlineCount", "SaveCB .Success!") 
            return
        end
    end
        --写入数据库
    self:TableInsertSql(sql, OnSetOnlineCount)
    ]]
end



function Collector:OnTimeRecharge()   

    log_game_info("Collector:OnTimeRecharge TEMP", "recharge_sum %s", self.recharge_sum)  

    local player_num = lua_util.get_table_real_count(self.recharge_player)

    local sql = string.format("INSERT INTO tbl_recharge(recharge_player_num,recharge_sum,timestamp) VALUES(%d, %d)", player_num, self.recharge_sum, global_data.GetServerTime(public_config.SERVER_TIMESTAMP))

    self:InsertIntoDb(sql)
end

--插入数据库
function Collector:InsertIntoDb(sql) 

    --log_game_info("Collector:InsertIntoDb TEMP", "SQL:%s", sql)  
    mogo.logCollect(sql)
end




function Collector:OnPlayerLogin(account)
    --log_game_info("Collector:OnPlayerLogin TEMP", "")
    if not self.account_tab[account] then  --今天第一次登陆则计数
        self.login_player_num = self.login_player_num + 1
    end

    self.account_tab[account] = 1 --这里记录该账号当天已近登陆过
end

function Collector:GetPlayerNum()
    return self.login_player_num 
end

--实时充值情况： 精准到每10分钟。 包括 付费 人数， 付费总额
function Collector:recharge(player_name, money)
    if not self.recharge_player[player_name] then
        self.recharge_player[player_name] = 0
    end
    self.recharge_player[player_name] = self.recharge_player[player_name] + money
    self.recharge_sum = self.recharge_sum + money
end


--关键道具掉落细节： 包括掉落来源， 道具id，数量， 拾取人，掉落时间。
function Collector:important_drop(item_id, item_num,owner,reason )



    local sql = string.format("INSERT INTO tbl_important_drop(item_id, item_num, player, reason, timestamp) VALUES(%d, %d, '%s', %d, %d)", 
        item_id, 
        item_num, 
        owner,
        reason,
        global_data.GetServerTime(public_config.SERVER_TIMESTAMP))

    self:InsertIntoDb(sql)
end


--关键道具消耗情况： 包括消耗的途径， 道具id， 数量， 使用者，,用途, 消耗时间。
function Collector:important_item_consume(item_id, item_num,owner,reason )

    local sql = string.format("INSERT INTO tbl_item_consume(item_id, item_num, player, reason, timestamp) VALUES(%d, %d, '%s', %d, %d)", 
        item_id, 
        item_num, 
        owner,
        reason,
        global_data.GetServerTime(public_config.SERVER_TIMESTAMP))

    self:InsertIntoDb(sql)
end


--商城道具购买情况。 包括 道具id，数量， 购买者，购买时间。 消耗的钻石。
function Collector:shop(item_id, item_num,player,diamond )

    local sql = string.format("INSERT INTO tbl_shop(item_id, item_num, player, diamond, timestamp) VALUES(%d, %d, '%s', %d, %d)", 
        item_id, 
        item_num, 
        player,
        diamond,
        global_data.GetServerTime(public_config.SERVER_TIMESTAMP))

    self:InsertIntoDb(sql)
end
 --玩家掉线情况。 重登录间隔时间
function Collector:miss(player, second)

   local sql = string.format("INSERT INTO tbl_miss_connect(player, disconnect_time) VALUES('%s',  %d)", 
        player,
        second)

    self:InsertIntoDb(sql)
end


--记录单个玩家的每次金币/钻石的产出、消耗：途径、数量、时间
function Collector:player_gold(player, num, reason)

   local sql = string.format("INSERT INTO tbl_player_gold(player, num, reason, timestamp) VALUES('%s', %d, %d, %d)", 
        player,
        num,
        reason,
        global_data.GetServerTime(public_config.SERVER_TIMESTAMP))

    self:InsertIntoDb(sql)
end


--记录单个玩家的每次金币/钻石的产出、消耗：途径、数量、时间
function Collector:player_diamond(player, num, reason)

  local sql = string.format("INSERT INTO tbl_player_diamond(player, num, reason, timestamp) VALUES('%s', %d, %d, %d)", 
        player,
        num,
        reason,
        global_data.GetServerTime(public_config.SERVER_TIMESTAMP))

    self:InsertIntoDb(sql)
end


--记录账号手机端信息
function Collector:PhoneInfo(account, guid, str_info)

  local sql = string.format("INSERT INTO tbl_phone(guid, account, info) VALUES('%s','%s','%s')",         
        guid,
        account,
        str_info)

    self:InsertIntoDb(sql)
end



function Collector:tbllog_role( role_id, --    角色id
                                    account_name   , --    平台账户
                                    dim_prof    , --    职业id
                                    happend_time ) --    事件发生时间

    local sql = string.format("INSERT INTO tbllog_role(role_id, account_name, dim_prof,  happend_time, log_time) VALUES(%d, '%s', %d, %d, %d)",         
        role_id, --    角色id
        account_name   , --    平台账户
        dim_prof    , --    职业id       
        happend_time, os.time()) 

    self:InsertIntoDb(sql)
end


function Collector:tbllog_login( 
                                    role_id    , --    角色id
                                    account_name   , --    平台账户
                                    dim_level   , --    等级
                                    user_ip, --    登陆IP
                                    happend_time) --    事件发生时间



    local sql = string.format("INSERT INTO tbllog_login(role_id, account_name, dim_level, user_ip, happend_time, log_time) VALUES(%d, '%s', %d, '%s', %d, %d)",         
                        role_id    , --    角色id
                        account_name   , --    平台账户
                        dim_level   , --    等级
                        user_ip, --    登陆IP
                        happend_time, os.time()) --    事件发生时间

    self:InsertIntoDb(sql)
end



function Collector:tbllog_shop( 
                                    role_id , --    角色id
                                    account_name   , --    平台账户
                                    dim_level   , --    等级
                                    dim_prof    , --    职业id
                                    money_type  , --    货币类型
                                    amount  , --    货币数量
                                    item_type_1 , --    物品分类1
                                    item_type_2 , --    物品分类2
                                    item_id , --    物品id
                                    item_number  , --    物品数量
                                    happend_time ) --    事件发生时间



    local sql = string.format("INSERT INTO tbllog_shop(role_id, account_name, dim_level, dim_prof,  money_type, amount, item_type_1, item_type_2, item_id, item_number, happend_time, log_time) VALUES(%d, '%s', %d,  %d, %d,  %d, %d, %d,  %d, %d, %d, %d)",         
                            role_id , --    角色id
                            account_name   , --    平台账户
                            dim_level   , --    等级
                            dim_prof    , --    职业id
                            gold2data[money_type]  , --    货币类型
                            amount  , --    货币数量
                            item_type_1 , --    物品分类1
                            item_type_2 , --    物品分类2
                            item_id , --    物品id
                            item_number  , --    物品数量
                            happend_time , os.time()) --    事件发生时间

    self:InsertIntoDb(sql)
end







function Collector:tbllog_items(role_id ,       --    角色id
                                    account_name   ,   --    平台账户
                                    opt ,           --    操作类型( 1 是获得，0 是使用)
                                    reason    ,  --    物品类型
                                    item_id ,       --    物品id
                                    item_number  ,       --    物品数量
                                    happend_time)      --    事件发生时间         

    local sql = string.format("INSERT INTO tbllog_items(role_id, account_name, opt, action_id, item_id, item_number, happend_time, log_time) VALUES(%d, '%s', %d, %d, %d, %d, %d, %d)",         
                            role_id ,       --    角色id
                            account_name   ,   --    平台账户
                            opt ,           --    操作类型
                            reason    ,  --    物品类型
                            item_id ,       --    物品id
                            item_number  ,       --    物品数量
                            happend_time, os.time() )       --   事件发生时间

    self:InsertIntoDb(sql)

end

function Collector:tbllog_gold(role_id, --角色id
                                    account_name, --平台账户
                                    dim_level, --等级
                                    dim_prof, --职业id
                                    money_type, --货币类型（1=金币，2=绑定金币，3=铜币，4=绑定铜币，5=礼券，6=积分/荣誉, 7=兑换）
                                    amount, --货币数量
                                    opt,
                                    action_1, --行为分类1（一级消费点）
                                    happend_time) --事件发生时间

    local sql = string.format("INSERT INTO tbllog_gold(role_id, account_name, dim_level, dim_prof, money_type, amount, opt, action_1, action_2,  happend_time, log_time) VALUES(%d, '%s', %d, %d, %d, %d, %d, %d, %d, %d, %d)",         
                               role_id, --角色id
                               account_name, --平台账户
                                dim_level, --等级
                                dim_prof, --职业id
                                gold2data[money_type], --货币类型（1=金币，2=绑定金币，3=铜币，4=绑定铜币，5=礼券，6=积分/荣誉, 7=兑换）
                                math.abs (amount), --货币数量
                                opt, --货币加减（1=增加，2=减少）
                                action_1, --行为分类1（一级消费点）
                                0, --行为分类2（二级消费点），若消费点没有一级、二级之分，二级消费点设置为0
                                --0, --物品数量
                                happend_time, os.time()) --事件发生时间

    self:InsertIntoDb(sql)

end


function Collector:tbllog_player(role_id    , --    角色ID
                                    role_name   , --    角色名
                                    account_id  , --    用户账号ID
                                    account_name    , --    用户账号名
                                    dim_nation  , --    阵营
                                    dim_prof    , --    职业
                                    dim_sex , --    性别
                                    reg_time    , --    注册时间
                                    dim_level   , --    用户等级
                                    dim_vip_level   , --    VIP等级
                                    dim_exp , --    当前经验
                                    dim_guild   , --    帮派名称
                                    dim_power   , --    战斗力
                                    gold_number , --    元宝数
                                    first_pay_time  , --    首充时间
                                    last_pay_time   , --    最后充值时间
                                    last_login_time  --    最后登录时间
                                    )
    

    local sql = string.format("INSERT INTO tbllog_player(role_id, role_name, account_id, account_name, dim_nation, dim_prof, dim_sex, reg_time, dim_level, dim_vip_level, dim_exp, dim_guild, dim_power, gold_number, first_pay_time, last_pay_time, last_login_time, happend_time, log_time) VALUES(%d, '%s', %d, '%s', %d, %d, %d, %d, %d, %d, %d, '%s', %d, %d, %d, %d, %d, %d, %d)",         
                               role_id    , --    角色ID
                                role_name   , --    角色名
                                account_id  , --    用户账号ID
                                account_name    , --    用户账号名
                                dim_nation  , --    阵营
                                dim_prof    , --    职业
                                dim_sex , --    性别
                                reg_time    , --    注册时间
                                dim_level   , --    用户等级
                                dim_vip_level   , --    VIP等级
                                dim_exp , --    当前经验
                                dim_guild   , --    帮派名称
                                dim_power   , --    战斗力
                                gold_number , --    元宝数
                                first_pay_time  , --    首充时间
                                last_pay_time   , --    最后充值时间
                                last_login_time,  --    最后登录时间
                                os.time(),
                                os.time()
                                ) 

    self:InsertIntoDb(sql)
end


function Collector:user_info_detail(client_fd, user_id, user_name, account)

        local all_nil= true
        local where = ""
        if  user_id ~= -1 then
            all_nil = false
            where =  where .. string.format(" and id = %s", user_id)
        end

        if  user_name ~= "" then
            all_nil = false
            where =  where .. string.format(" and sm_name = '%s'", user_name)
        end

        if  account ~= "" then
            all_nil = false
            where = where .. string.format(" and sm_accountName = '%s'", account)
        end

        if all_nil then
             mogo.browserResponse(client_fd, "param_error") --返回给浏览器:参数错误
             return
        end

        where = string.sub(where, string.len(" and "))

        local sql = string.format("SELECT sm_level,sm_name,sm_gender,sm_gold,sm_diamond,sm_accountName,\
    sm_createTime,sm_VipLevel,sm_vocation,%s as __tmp_client_fd  \
    FROM tbl_Avatar Where ",client_fd)
        sql = sql ..where
    self:TableSelectSql("On_SQL_RESPONSE", "Avatar", sql) -- --这里取个巧 __tmp_client_fd 用它来返回client_Fd  __tmp_client_fd 必须在avatar.xml中定义
end


function Collector:user_info_detail(client_fd, user_id, user_name, account)

        local all_nil= true
        local where = ""
        if  user_id ~= -1 then
            all_nil = false
            where =  where .. string.format(" and id = %s", user_id)
        end

        if  user_name ~= "" then
            all_nil = false
            where =  where .. string.format(" and sm_name = '%s'", user_name)
        end

        if  account ~= "" then
            all_nil = false
            where = where .. string.format(" and sm_accountName = '%s'", account)
        end

        if all_nil then
             mogo.browserResponse(client_fd, "param_error") --返回给浏览器:参数错误
             return
        end

        where = string.sub(where, string.len(" and "))

        local sql = string.format("SELECT sm_level,sm_name,sm_gender,sm_gold,sm_diamond,sm_accountName,\
    sm_createTime,sm_VipLevel,sm_vocation,%s as __tmp_client_fd  \
    FROM tbl_Avatar Where ",client_fd)
        sql = sql ..where
    self:TableSelectSql("On_SQL_RESPONSE", "Avatar", sql) -- --这里取个巧 __tmp_client_fd 用它来返回client_Fd  __tmp_client_fd 必须在avatar.xml中定义
end



function Collector:On_SQL_RESPONSE(rst)
    local data = {}
    local client_fd = -1
    for id, info in pairs(rst) do
        client_fd = info.__tmp_client_fd
        table.insert( data, info )
        
    end
    if client_fd ~= -1 then
        local result = {}
        result.state = "\"success\""
        result.desc = t2s(tab_user_info_detail)
        result.data = data2json(data)
        mogo.browserResponse(client_fd, lua2json_qs(result)) 
        return 
    end    

end




function Collector:API(client_fd, cmd, params_str)
    local params = self:_format_key_value(params_str)

    GMSystem:SupportApi(client_fd, cmd, params)

    log_game_info("Collector:API", "SQL:%s %s", cmd, params_str)  

end

function Collector:_format_key_value(value)    
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

--trim掉最左边的del字符
function Collector:ltrim(str, del)
	local result = str
	if #del ~= 0 then 
		if string.sub(str, 1, #del) == del then
			result = string.sub(str, #del+1)
		end
	end
	return result
end   

function Collector:table_insert(table_name, tab)   

	local cols = ""
	local values = ""


	for key, value in pairs(tab) do       
		cols =  string.format("%s, %s", cols, key)
		if type(value) == "string" then
			values = string.format("%s, %q",values,  value)   --字符串就加个双引号吧
		else
			values = string.format("%s, %s",values,  value) 
		end
		
	end

	cols 	= self:ltrim(cols, ",")
	values 	= self:ltrim(values, ",")

	local sql = string.format("INSERT INTO %s(%s, log_time) values (%s,%s)",   table_name, cols, values, os.time()) 

	self:InsertIntoDb(sql)


end


return Collector