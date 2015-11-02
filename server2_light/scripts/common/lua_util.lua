require "public_config"

local log_game_info = mogo.logInfo
local log_game_debug = mogo.logDebug
local log_game_error = mogo.logError
local log_game_warning = mogo.logWarning


lua_util = {}
lua_util.__index = lua_util
-------------------------------------------------------------------------------------------------------

--根据分隔符切割字符串
function lua_util.split_str(str, delim, func)
    local i = 0
    local j = 1
    local t = {}
    while i ~= nil do
        i = string.find(str, delim, j)
        if i ~= nil then
            if func then
                table.insert(t, func(string.sub(str, j, i-1)))
            else
                table.insert(t, string.sub(str, j, i-1))
            end
            j = i + 1
        else
            if func then
                table.insert(t, func(string.sub(str, j)))
            else
                table.insert(t, string.sub(str, j))
            end
        end
    end
    return t
end

--根据分隔符切割字符串,每2个项归为一个k,v对
function lua_util.split_str_2_dict(str, delim, func)
    local t = lua_util.split_str(str, delim, func)
    local t2 = {}
    for i = 1,999,2 do
        local k = t[i]
        local v = t[i+1]
        if k and v then
            t2[k] = v
        end
    end

    return t2
end

--判断一个字符串是否以另外一个字符串开头
function lua_util.is_start_with_str(str, substr)
    local i,j = string.find(str, substr)
    return i == 1
end

--生成一个日期的整数，默认以凌晨4:00为界
local _ONEDAY_SECONDS = 24*60*60
function lua_util.get_number_date(from_time, from_clock)
    local now_time=from_time or os.time()
    local _from_clock=from_clock or 4
    local now_time_table=(os.date("*t",now_time))
    if now_time_table==nil then
        return 0
    end
    if now_time_table.hour<_from_clock then
         local now_time_table_2=(os.date("*t",now_time-_ONEDAY_SECONDS))
         return  now_time_table_2.year*10000+now_time_table_2.month*100+now_time_table_2.day
    end
    return  now_time_table.year*10000+now_time_table.month*100+now_time_table.day
end

--获得某日某个时刻点对应的秒数
function lua_util.get_number_secs(from_time, from_clock)
    local now_time=from_time or os.time()
    local _from_clock=from_clock or 4
    local now_time_table=(os.date("*t",now_time))
    if now_time_table==nil then
        return 0
    end
    if now_time_table.hour<_from_clock then
         local now_time_table_2=(os.date("*t",now_time-_ONEDAY_SECONDS))
         now_time_table_2['hour'] = from_clock
         now_time_table_2['min'] = 0
         now_time_table_2['sec'] = 0
         return os.time(now_time_table_2)
    end
    now_time_table['hour'] = from_clock
    now_time_table['min'] = 0
    now_time_table['sec'] = 0
    return os.time(now_time_table)
end

--获取YYYYMMDD格式的日期
function lua_util.get_yyyymmdd(from_time1)
    local from_time = from_time1 or os.time()
    return os.date("%Y%m%d", from_time)
end

--获取YYmmWd格式,YY是年的后2位,mm是月份,Wd是当前时间所在周的周一的日期
function lua_util.get_number_yymmwd(from_time)
    local now = from_time or os.time()
    local now_tm = os.date('*t', now)
    local wday = now_tm.wday    --lua中sunday是1
    if wday == 1 then
        wday = 8
    end

    local time1 = now - (wday - 2)*86400
    local time1_tm = os.date('*t', time1)

    return (time1_tm.year-2000)*10000+time1_tm.month*100+time1_tm.day
end


--判断两个时间戳是否为同一天, 
function lua_util.is_same_day(stamp1, stamp2)
    local dayb = tonumber(os.date("%y%m%d", stamp1))
    local daya = tonumber(os.date("%y%m%d", stamp2))
    if dayb == daya  then
        return true
    else
        return false
    end
end
local function _format_key_value(key, value)
    local nKeyLen = #key
    if nKeyLen > 2 then
        local prefix = string.sub(key, -2)
        local key2 = string.sub(key, 0, -3)
        if prefix == "_i" then
            return key2, tonumber(value)
        elseif prefix == "_f" then
            return key2, tonumber(value)
		elseif prefix == "_s" then
            return key2, tostring(value)
        elseif prefix == "_l" then
            --list
            return key2, lua_util.split_str(value, ',', tonumber)
        elseif prefix == "_k" then
            --key table
            local tmp = lua_util.split_str(value, ',', tonumber)
            local tmp2 = {}
            for _, k in pairs(tmp) do
                tmp2[k] = 1
            end
            return key2, tmp2
--        elseif prefix == "_t" then
----            local f = loadstring('return ' .. value)
--            return key2, loadstring('return ' .. value)
        elseif prefix == "_t" then
            --00:00:00
            local tmp = lua_util.split_str(value, ':')
            local sec = 0
            for i,v in ipairs(tmp) do
                local t = tonumber(v)
                if t then
                    sec = t + sec * 60
                end
            end
            return key2, sec
        elseif prefix == "_y" then
            --2014-01-25 0:12:00
            local i = string.find(value,' ',1)
            local str_data = string.sub(value,1,i-1)
            local str_time = string.sub(value,i+1)
            local dd = lua_util.split_str(str_data,'-',tonumber)
            local tt = lua_util.split_str(str_time,':',tonumber)
            return key2, os.time{year=dd[1],month=dd[2],day=dd[3],hour=tt[1],min=tt[2],sec=tt[3]}
        elseif prefix == "_m" then
            local tmp = lua_util.split_str(value, ',')
            local tmp2 = {}
            for _, v in pairs(tmp) do
                local tmp = lua_util.split_str(v, ':')
                local id = tonumber(tmp[1]) or tmp[1]
                local num = tonumber(tmp[2]) or tmp[2]
                tmp2[id] = num
            end
            return key2, tmp2
        else
            return key, value
        end
    else
        return key, value
    end
end

function lua_util.format_key_value(key, value)
    return _format_key_value(key, value)
end

--格式化一个table,该table只有一层关系
local function _format_table(t)
    local v2 = {}
    for key, value in pairs(t) do
        local key2, value2 = _format_key_value(key, value)
        v2[key2] = value2
    end

    return v2
end

lua_util.format_table = _format_table

--根据字段名后缀的含义修改从xml读取的数据类型
function lua_util.format_xml_table(t)
    local t2 = {}
    for k,v in pairs(t) do
        local v2 = _format_table(v)
        if tonumber(k) ~= nil then
            t2[tonumber(k)] = v2
        else
            t2[k] = v2
        end
    end
    return t2
end

--从M个数里(等概率)随机出N个不重复的数
function lua_util.choose_n_norepeated( t, n )
    local m = #t
    --集合数目不够抽取数目
    if m <= n then
        return t
    end

    local t2 = {}   --返回结果
    local i = 0     --已抽取个数
    local mrandom = math.random
    while true do
        local r = t[mrandom(1,m)]
        if t2[r] == nil then
            t2[r] = 1
            i = i+1
            if i >= n then
                return t2
            end
        end
    end

    return t2
end

--从{k = prob}表里挑选一个满足概率的k
function lua_util.choose_prob(t, min_prob, max_prob)
    local ram
    if min_prob and max_prob then
        ram = math.random(min_prob, max_prob)
    else
        ram = math.random()
    end
    local prob = 0
    for k, prob1 in pairs(t) do
        prob = prob + prob1
        if ram <= prob then
            return k
        end
    end
end

--从格式"道具id1,数量1,概率1,道具id2,数量2,概率2,..."中随机出一个道具id和数量
function lua_util.choose_random_item(drop)
    if drop then
        local ram = math.random()
        local n = #drop
        local prop = 0
        for i=3, n, 3 do
            local p = drop[i]
            if p then
                prop = prop + p
                if ram < prop then
                    return {drop[i-2], drop[i-1]}
                end
            end
        end
    end
end

--x=0.3 0.3概率发生
function lua_util.prob(x)
    if(x <= 0) then
        return false
    end
    return (math.random() <= x)
end

--{0.2,0.3,0.5}，总和1,返回按各自概率返回索引20%返回1，30%返回2,50%返回3
function lua_util.choice(x)
    local d = math.random()
    local sum = 0
    for k,v in pairs(x) do
        if d <= v + sum then
            return k
        end
        sum = sum + v
    end
    return nil
end

--从一个列表中随机一个值
function lua_util.choose_1(t)
    local n = #t
    if n == 0 then
        return nil
    end
    return t[math.random(1, n)]
end

--从一个列表中随机一个值,从其关联列表也返回一个值
function lua_util.choose_2(t, t2)
    local n = #t
    if n == 0 then
        return nil
    end
    local idx = math.random(1, n)
    return t[idx],t2[idx]
end

--从不等概率的一组值里面随机选择个
--table格式如：{[值]=概率}；函数返回 值，概率
function lua_util.getrandomseed(a)
   if type(a)=="table" then
      local max=0
      for k,v in pairs(a) do
            max=max+v
      end
      local seed=math.random(1,max)
      local sumvv=0
      for kk,vv in pairs(a) do
           sumvv=sumvv+vv
           if seed<=sumvv then
               return kk,vv
           end
      end
   end
end

--读取xml文件
local g_lua_rootpath = G_LUA_ROOTPATH
local mogo_readXml = mogo.readXml
function lua_util._readXml(path, key)
    local fn = g_lua_rootpath .. path
    local tmp = mogo_readXml(fn, key)
    if tmp == nil then
        error(string.format("Failed to read '%s', format error or file not exists.", fn))
    end
    return lua_util.format_xml_table( tmp )
end

local mogo_readXml2List = mogo.readXmlToList
--根据两个关键字来读xml文件,例如科技表根据科技id和科技等级来决定相关的数据
--注意,这里的key和key2不能带后缀
function lua_util._readXmlBy2Key(path, key, key2)
    local fn = g_lua_rootpath .. path
    local tmp = mogo_readXml2List(fn)

    local data = {}
    for k, v in pairs(tmp) do
        for k2, v2 in pairs(v) do
            --k,k2都是没用的字段
            local t = _format_table(v2)
            local vv1 = t[key]
            local vv2 = t[key2]

            local tt = data[vv1]
            if tt == nil then
                data[vv1] = { [vv2] = t }
            else
                tt[vv2] = t
            end
        end
    end

    return data
end

function lua_util._readXml2List(fn0)
    local fn = g_lua_rootpath .. fn0
    local tmp = mogo_readXml2List(fn)

    if tmp then
        local data = {}
        for k, v in pairs(tmp) do
            for k2, v2 in pairs(v) do
                local t = _format_table(v2)
                table.insert(data, t)
            end
        end
        return data
    end
end

--读取两层结构的xml文件
function lua_util._read2dpXml(path, key)
    local fn = g_lua_rootpath .. path
    local tmp = mogo_readXml(fn, key)
    if tmp == nil then
        error(string.format("Failed to read '%s', format error or file not exists.", fn))
    end
    local tmp2 = {}
    for k1, v1 in pairs(tmp) do
        --print(k1, v1)
        local tmp22 = {}
        for k2, v2 in pairs(v1) do
            --print(k2, v2)
            if type(v2) == 'table' then
                tmp22[k2] = _format_table(v2)
            else
                local kk2,vv2 = _format_key_value(k2, v2)
                tmp22[kk2] = vv2
            end
        end
        tmp2[tonumber(k1)] = tmp22
    end

    return tmp2
end

--读取一个表,取其中的一个key生成一个list
function lua_util.readXml2KeyList(fn0, key)
    local fn = g_lua_rootpath .. fn0
    local tmp = mogo_readXml2List(fn)

    if tmp then
        local data = {}
        for k, v in pairs(tmp) do
            for k2, v2 in pairs(v) do
                local t = _format_table(v2)
                table.insert(data, t[key])
            end
        end
        return data
    end
end

--读取一个表,取其中的2个key生成2个list
function lua_util.readXml2KeyList2(fn0, key1,key2)
    local fn = g_lua_rootpath .. fn0
    local tmp = mogo_readXml2List(fn)

    if tmp then
        local data = {}
        local data2 = {}
        for k, v in pairs(tmp) do
            for k2, v2 in pairs(v) do
                local t = _format_table(v2)
                table.insert(data, t[key1])
                table.insert(data2, t[key2])
            end
        end
        return {data,data2}
    end
end

--读取一个表,取两个key生成一个表{k=v}
function lua_util.readXml2KVDict(fn0, key1, key2)
    local fn = g_lua_rootpath .. fn0
    local tmp = mogo_readXml2List(fn)

    if tmp then
        local data = {}
        for k, v in pairs(tmp) do
            for k2, v2 in pairs(v) do
                local t = _format_table(v2)
                data[t[key1]] = t[key2]
            end
        end
        return data
    end
end

--获取一个表中不为nil的项的数目
function lua_util.get_table_real_count(t)
    --log_game_debug("lua_util.get_table_real_count", string.format(mogo.cpickle(t)) )
    local i = 0
    for k,v in pairs(t) do
        i = i + 1
    end
    return i
end

--获取一个表中第一个可插入的位置(为nil的项的索引值)
function lua_util.get_table_insert_pos(t, maxn)
    if maxn == nil then
        maxn = table.maxn(t)
    end

    for i=1, maxn do
        if t[i] == nil then
            return i
        end
    end

    return nil
end

--在表里第一个为nil的位置插入一个新项,并且返回该位置
function lua_util.insert_table(t, item)
    local maxn = table.maxn(t)
    local pos = lua_util.get_table_insert_pos(t, maxn)
    if pos == nil then
        table.insert(t, item)
        return maxn + 1
    else
        t[pos]=item
        --table.insert(t, pos, item)
        return pos
    end
end

---一个通用的方法调用,适用于一个返回参数
--输入参数:  entity   : rpc所在的实体
--         rpc_name  : rpc方法名,
--         base_mbstr: 返回的entity mb
--         callback  : 返回的回调方法
--         ...       : rpc对应的参数
function lua_util.generic_base_call(entity, rpc_name, base_mbstr, callback, ...)
    local p1 = entity[rpc_name](entity, ...)
    local mb = mogo.UnpickleBaseMailbox(base_mbstr)
    mb[callback](p1)
end

function lua_util.generic_base_call_client(entity, rpc_name, base_mbstr, action_id, log_fm, ...)
    local p1 = entity[rpc_name](entity, ...)
    local mb = mogo.UnpickleBaseMailbox(base_mbstr)
    mb.client.err_resp(action_id, p1)

    log_game_debug(rpc_name, string.format("err_id=%d;"..log_fm, p1, ...))
end

function lua_util.generic_base_call_client_ne0(entity, rpc_name, base_mbstr, action_id, log_fm, ...)
    local p1 = entity[rpc_name](entity, ...)
    local mb = mogo.UnpickleBaseMailbox(base_mbstr)
    if p1 ~= 0 then
        mb.client.err_resp(action_id, p1)
    end

    log_game_debug(rpc_name, string.format("err_id=%d;"..log_fm, p1, ...))
end

-----调用Avatar的一个方法,转给一个mgr进行处理,并且返回错误码给客户端
--function lua_util.generic_avatar_call(avatar, action_id, mgr, func, log_fm, ...)
--    local err_id = mgr[func](mgr, avatar, ...)
--    if avatar:hasClient() then
--        avatar.client.err_resp(action_id, err_id)
--    end
--    log_game_debug(func, string.format('dbid=%q;err=%d;'..log_fm, avatar:getDbid(), err_id, ...))
--end
--
-----调用Avatar的一个方法,转给一个mgr进行处理,并且返回错误码(如果不为0)给客户端
--function lua_util.generic_avatar_call_ne0(avatar, action_id, mgr, func, log_fm, ...)
--    local err_id = mgr[func](mgr, avatar, ...)
--    if err_id ~= 0 and avatar:hasClient() then
--        avatar.client.err_resp(action_id, err_id)
--    end
--    log_game_debug(func, string.format('dbid=%q;err=%d;'..log_fm, avatar:getDbid(), err_id, ...))
--end

--mailbox call
function lua_util.mailbox_call(mbstr, rpc_name, ...)
    local mb = mogo.UnpickleBaseMailbox(mbstr)
    mb[rpc_name](...)
end

function lua_util.mailbox_client_call(mbstr, rpc_name, ...)
    local mb = mogo.UnpickleBaseMailbox(mbstr)
    mb.client[rpc_name](...)
end

--globalbases rpc
function lua_util.globalbase_call(mgr_name, rpc_name, ...)
    local mgr = globalBases[mgr_name]
    if mgr then
        mgr[rpc_name](...)
    end
end

--经过UserMgr给一个玩家发送系统邮件
function lua_util.send_sys_mail(to_name, mail)
    --base_mbstr设为'',from_dbid设为0
    lua_util.globalbase_call('UserMgr', 'mail_send_req', '', 0, to_name, mogo.cpickle(mail))
end

--某个功能Mgr注册globalbase后的回调方法
function lua_util.basemgr_register_callback(mgr_name, eid)
    local mm_eid = eid
    local function __callback(ret)
        local gm = mogo.getEntity(mm_eid)
        if gm then
            if ret == 1 then
                --注册成功
                gm:OnRegistered()
            else
                --注册失败
                log_game_warning(mgr_name..".registerGlobally error", '')
                --destroy方法未实现,todo
                --gm.destroy()
            end
        end
    end
    return __callback
end

--某个功能Mgr写数据库的回调方法
function lua_util.on_basemgr_saved(mgr_name1)
    local mgr_name = mgr_name1
    local function __callback(entity, dbid, err)
        if dbid > 0 then
            log_game_info("create_"..mgr_name.."_success", '')
            entity:RegisterGlobally(mgr_name, lua_util.basemgr_register_callback(mgr_name, entity:getId()))
        else
            --写数据库失败
            log_game_info("create_"..mgr_name.."_failed", err)
        end
    end
    return __callback
end

--获取某个globalbase的entity(如果在同一个baseapp上的话)
function lua_util.getGlobalbaseEntity(name)
    local mgr = globalBases[name]
    if mgr then
        local en = mogo.getEntity(mgr[public_config.MAILBOX_KEY_ENTITY_ID])
        return en
    end
end

--deepcopy,只copy1层
function lua_util.deepcopy_1(t)
    local t2 = {}
    for k, v in pairs(t) do
        t2[k] = v
    end
    return t2
end

--计算utf编码字符串的长度
local _utf_arr = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
local _utf_arr_len = #_utf_arr
function lua_util.utfstrlen(str)
    local len = #str
    local left = len
    local cnt = 0
    while left > 0 do
        local tmp = string.byte(str, -left)
        local i = _utf_arr_len
        while _utf_arr[i] do
            if tmp >=_utf_arr[i] then
                left = left-i
                break
            end
            i=i-1
        end
        cnt=cnt+1
    end
    return cnt
end

function lua_util.utf_str_cut(str, len)
    local length = #str
    local left = 1
    local cnt = 0
    local ret = ''
    while left <= length do
        local tmp = string.byte(str, left)
        local pre = left
        local i = _utf_arr_len
        while _utf_arr[i] do
            if tmp >=_utf_arr[i] then
                left = left + i
                break
            end
            i=i-1
        end
        cnt=cnt+1
        ret = ret .. string.sub(str, pre, left - 1)
        if cnt == len then
            break
        end
    end
    return ret
end

--检查utf字符串是否含有char(< 0xc0)字符
function lua_util.utfstr_check_char(str, char)
    --local byte_char = string.byte(char)
    if char < 0 or char >= 0xc0 then
        lua_util.log_game_warning("utfstr_check_char", "")
        return
    end 
    local len = #str
    local left = len
    while left > 0 do
        local tmp = string.byte(str, -left)
        if tmp == char then
            return true
        end
        local i = _utf_arr_len
        while _utf_arr[i] do
            if tmp >=_utf_arr[i] then
                left = left-i
                break
            end
            i=i-1
        end
    end
    return false
end

--获取当前时间到下一个X分钟时刻点的剩余秒数
--比如当前时间为15:09分,到下一个5分钟时刻点的剩余时间为1分
--到下一个15分钟时刻点的剩余时间为6分,
--到下一个30分钟时刻点的剩余时间为21分,
--到下一个60分钟时刻点的剩余时间为51分,
-- -- -- 等等
function lua_util.get_left_secs_until_next_x_mins(min_interval)
    --这个值不能大于60分钟
    if min_interval > 60 then
        min_interval = 60
    end

    local now_secs = os.time() % 3600  --当前时间的秒数
    local sec_int = min_interval * 60
    local left = sec_int - now_secs % sec_int
    return left
end

--获取当前时间到下一个hh:mi:ss的剩余秒数
function lua_util.get_left_secs_until_next_hhmiss(nh, nm, ns)
    local now = os.date('*t', os.time())

    local s1 = now.hour * 3600 + now.min * 60 + now.sec
    local s2 = nh * 3600 + nm * 60 + ns
    local delta_s = s2 - s1
    if delta_s < 0 then
        --加一天的时间
        delta_s = delta_s + 86400
    end

    return delta_s
end
--获取当前时间到下一个星期:hh:mi:ss的剩余秒数
function lua_util.get_secs_until_next_wdate(nd, nh, nm, ns)
    local now = os.date('*t', os.time())
    local delta_d = nd - now.wday
    if delta_d < 0 then
        delta_d = delta_d + 7
    end
    local s1 = now.hour * 3600 + now.min * 60 + now.sec
    local s2 = nh * 3600 + nm * 60 + ns
    local delta_s = s2 - s1
    if delta_s <= 0 and delta_d == 0 then
        delta_s = delta_s + 86400 * 7
    else
        delta_s = delta_s + 86400 * delta_d
    end
    return delta_s
end

--获取下一个hh:mi:ss的秒数
function lua_util.get_secs_until_next_hhmiss(nh, nm, ns)
    local now = os.time()
    local date_n = os.date('*t')

    local s1 = date_n.hour * 3600 + date_n.min * 60 + date_n.sec
    local s2 = nh * 3600 + nm * 60 + ns
    local delta_s = s2 - s1
    if delta_s < 0 then
        --加一天的时间
        delta_s = delta_s + 86400
    end

    return delta_s + now
end

--按时间间隔检测时间流逝了多少次
function lua_util.test_and_set_time_interval(avatar, interval)
    local attri_name
    if interval == 1800 then
        attri_name = 'time_flag_30m'
    else
        return 0
    end

    local attri = avatar[attri_name]
    local now = os.time()

    --该时间为第一次设置
    if attri == 0 then
        avatar[attri_name] = now
        return 1
    end

    --计算间隔次数
    local times = math.floor((now - attri)/interval)
    if times <= 0 then
        --间隔时间不到
        return 0
    end

    --设置新的时间
    avatar[attri_name] = now - (now - attri) % interval
    return times
end

--日志
function lua_util.log_game_info(head, pattern, ...)
    log_game_info(head, string.format(pattern, ...) )
end

function lua_util.log_game_debug(head, pattern, ...)
    log_game_debug(head, string.format(pattern, ...) )
end

function lua_util.log_game_error(head, pattern, ...)
    log_game_error(head, string.format(pattern, ...) )
end

function lua_util.log_game_warning(head, pattern, ...)
    log_game_warning(head, string.format(pattern, ...) )
end

--获取table中key的值,如果为nil则返回缺省值
function lua_util.get_table_value(t, key, df)
    local v = t[key]
    if v == nil then
        return df
    end

    return v
end

--获取某字符串pos上的字符
function lua_util.get_char_at(s,pos)
    return string.sub(s, pos, pos)
end

--将字符串s的pos位置设置成为newchar
function lua_util.set_char_value(s, pos, newchar)
    local s1 = string.sub(s, 1, pos - 1)
    local s2 = string.sub(s, pos + 1, string.len(s))
    s1 = s1..newchar..s2
    return s1
end

--判断四个数字互不相等
function lua_util.fournum_is_diff(a, b, c, d)
    local t = {}
    t[a] = 1
    t[b] = 1
    t[c] = 1
    t[d] = 1
    if lua_util.get_table_real_count(t) == 4 then
        return true
    end
    return false
end

--获取x的整数部分
function lua_util.getIntPart(x)
    --[[if x <= 0 then
       return math.ceil(x);
    end

    if math.ceil(x) == x then
       x = math.ceil(x);
    else
       x = math.ceil(x) - 1;
    end
    return x;]]
    local a = math.modf(x)
    return a
end

--添加或累加table的某个字段的值
function lua_util._add_attri(t, k, v)
    local v2 = t[k]

    if v == nil then
        v = 0
    end

    if v2 then
        t[k] = v2 + v
    else
        t[k] = v
    end
end

--获取个位数数字
function lua_util.get_data1(value)
    return math.mod(value, 10)
end

--获取十位数数字
function lua_util.get_data2(value)
    return lua_util.getIntPart(value / 10)
end

function lua_util.BinarySearch(array, len, v, func)
    local left = 1
    local right = len
    local middle = 0

    while left < right + 1 do
        middle = (left + right) / 2
        if func(array[middle]) < v then
            left = middle + 1
        elseif func(array[middle]) > v then
            right = middle - 1
        else
            return middle
        end
    end

    return 1
end

function _print(...)

    log_game_debug("", ...)
end

--只有一个返回参数的pcall调用封装
function lua_util.pcall(func, default_ret, ...)
    local ret, err_msg = pcall(func, ...)
    if ret then
        --调用成功,err_msg其实是返回参数的第一个参数
        return err_msg
    else
        --调用出错,记录异常,返回缺省值
        lua_util.log_game_warning("mypcall", "%s", err_msg)
        return default_ret
    end
end

function lua_util.print_stack(prefix, level, func)
    local t = debug.getinfo(level,'Sln')

    if not t then return false end

    local debug_table = {}

    for k,v in pairs(t) do
       if v and k == 'name' or k == 'currentline' or k =='short_src' then
           debug_table[#debug_table + 1] = string.format('%s=%s',tostring(k),tostring(v))
       end
    end

    func(string.format('%s: {%s}',prefix,table.concat(debug_table,' ')))
    return true
end

function lua_util.traceback()
    for level = 1, math.huge do
        if not lua_util.print_stack("stack", level, _print) then break end
    end
end

function lua_util.confirm(expr, ...)
    if expr == true then return end
    lua_util.log_game_debug("Assert Error Stack:", debug.traceback())
    lua_util.log_game_debug("Assert Error Info:", ...)
    mogo.confirm(false)
    local auto_continue = false
    if auto_continue == false then
        error "Throw Assert Error!!!"
    end
end

function lua_util.sectorAngle(x1,y1,x2,y2)
    local h = y2 - y1
    local w = x2 - x1
    --求射线AB的弧度
    local radianAB
    if w > 0 then
        radianAB = math.atan(h / w)
    elseif w < 0 then
        radianAB = math.atan(h / w) + math.pi
    else
        if h > 0 then
            radianAB = math.pi / 2
        elseif h < 0 then
            radianAB = -math.pi / 2
        else           
            return true
        end
    end

    --确保射线AB的弧度在第一圆周周期内
    if radianAB < 0 then radianAB = radianAB + 2 * math.pi end
    --弧度转角度
    radianAB = math.deg(radianAB)
    radianAB = (450 - radianAB) % 360
    return radianAB
end

function lua_util.print_table( tbl )
    for key, val in pairs(tbl) do
        if type(val) == "table" then
            print("".. tostring(key).. " = {")
            lua_util.print_table( val )
            print("}")
        else 
            print(key, val)
        end
    end
end

function lua_util.deep_copy(depth, t, cpy)
    if depth < 1 then
        return
    end
    for k,v in pairs(t) do
        if type(v) == 'table' then
      local cpy_2 = {}
            lua_util.deep_copy(depth-1, v, cpy_2)
      cpy[k]=cpy_2
        else
            cpy[k]=v
        end
    end
end
--获取昨天零点到现在流失的秒数
function lua_util.lapsed_from_zero_of_yesterday()
    local  curr_time = os.time()
    local  curr_hour = os.date("%H", curr_time)
    local  curr_min  = os.date("%M", curr_time)
    local  curr_sec  = os.date("%S", curr_time)
    local  interval  = curr_hour*3600 + curr_min*60 + curr_sec
    return interval
end

-----------------------------------------------------------------------------------------
return lua_util

