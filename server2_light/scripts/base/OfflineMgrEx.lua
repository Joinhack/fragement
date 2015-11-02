--author:hwj
--date:2013-9-28
--此为离线管理扩展类，重构

--redis回调
function OfflineMgr:onRedisReply(key, value)
    local key_tbl = lua_util.split_str(key,':')
    local dbid_str = key_tbl[2]
    if not dbid_str then
        log_game_error("OfflineMgr:onRedisReply", "dbid is nil")
        return
    end
    local dbid = tonumber(dbid_str)
    local redis_data = mogo.cUnpickle(value)
    if not redis_data then
        log_game_error("OfflineMgr:onRedisReply", "redis_data is nil")
        return
    end
    local nSeq = 0
    if not self.m_OfflineInf[dbid] then
        self.m_OfflineInf[dbid] = {}
    end
    for k,v in pairs(redis_data) do
        if k > nSeq then
            nSeq = k
        end
        if not self.m_OfflineInf[dbid][v.vt] then
            self.m_OfflineInf[dbid][v.vt] = {}
        end
        table.insert(self.m_OfflineInf[dbid][v.vt], v)
    end
    self.redis_seq[dbid] = nSeq
    --执行m_OpList的命令
    self:OP(dbid)
    self.m_Loading[dbid] = nil
end

function OfflineMgr:OP(dbid)
    for _,op in ipairs(self.m_OpList[dbid]) do
        if     op.cb == "Add" then
            self:Add(op.key,op.dbid,op.inf)

        elseif op.cb == "Rep" then
            self:Rep(op.key,op.dbid,op.inf,op.unique,op.value)
        
        elseif op.cb == "Del" then
            self:Del(op.key,op.dbid,op.unique,op.value)

        elseif op.cn == "DelTypeOf" then
            self:DelTypeOf(op.key,op.dbid)

        elseif op.cb == "DelCb" then
            self:DelCb(op.mbStr,op.msgId,op.key,op.dbid,op.unique,op.value)

        elseif op.cb == "Get" then
            self:Get(op.mbStr,op.msgId,op.key,op.dbid,op.unique,op.value,op.remo)

        elseif op.cb == "GetTypeOf" then
            self:GetTypeOf(op.mbStr,op.msgId,op.key,op.dbid,op.remo)

        elseif op.cb == "GetAll" then
            self:GetAll(op.mbStr, op.dbid)

        else
            log_game_error("OfflineMgr:OP","dbid[%q]",dbid)    
        end
    end
    self.m_OpList[dbid] = {}
end

--增加某个角色一类离线信息一个值,可重复 AddOfflineItem
--[[
m_OfflineInf
m_OpList
m_Loading
]]
--AddOfflineItem
function OfflineMgr:Add(key,dbid,inf)
    local my_inf = self.m_OfflineInf[dbid]
    if not my_inf then
        --self.m_OfflineInf[dbid] = {}
        if not self.m_OpList[dbid] then self.m_OpList[dbid] = {} end
        table.insert(self.m_OpList[dbid],{cb="Add",key=key,dbid=dbid,inf=inf})
        --load
        if self.m_Loading[dbid] then return end
        self.m_Loading[dbid] = true
        local redis_key = string.format(self.redis_key_format, dbid)
        self.redis_ud:load(redis_key)
        return
    end
    if not my_inf[key] then
        my_inf[key] = {}
    end
    self:LimitCtrolAdd(dbid,my_inf[key],inf,key)
end

--替换某个角色来自某个角色的一类离线信息一个值，不存在则增加 --ReplaceInto
function OfflineMgr:Rep(key,dbid,inf,unique,value)
    local my_inf = self.m_OfflineInf[dbid]
    if not my_inf then
        --self.m_OfflineInf[dbid] = {}
        if not self.m_OpList[dbid] then self.m_OpList[dbid] = {} end
        table.insert(self.m_OpList[dbid],{cb="Rep",key=key,dbid=dbid,inf=inf,unique=unique,value=value})
        --load
        if self.m_Loading[dbid] then return end
        self.m_Loading[dbid] = true
        local redis_key = string.format(self.redis_key_format, dbid)
        self.redis_ud:load(redis_key)
        return
    end
    if not my_inf[key] then
        my_inf[key] = {}
        self:LimitCtrolAdd(dbid,my_inf[key],inf,key)
        return
    end
    for k,v in pairs(my_inf[key]) do
        if v[unique] == value then
            local nSeq = v.nSeq
            if nSeq then inf.nSeq = nSeq end
            my_inf[key][k] = inf
            self:UpdateEx(dbid,key,inf)
            return
        end
    end
    self:LimitCtrolAdd(dbid,my_inf[key],inf,key)
end

--删除来自某项离线信息 --DelOfflineItem
function OfflineMgr:Del(key,dbid,unique,value)
    local my_inf = self.m_OfflineInf[dbid]
    if not my_inf then
        --self.m_OfflineInf[dbid] = {}
        if not self.m_OpList[dbid] then self.m_OpList[dbid] = {} end
        table.insert(self.m_OpList[dbid],{cb="Del",key=key,dbid=dbid,unique=unique,value=value})
        --load
        if self.m_Loading[dbid] then return end
        self.m_Loading[dbid] = true
        local redis_key = string.format(self.redis_key_format, dbid)
        self.redis_ud:load(redis_key)
        return
    end
    local inf = my_inf[key]
    if not inf then
        return
    end
    for k,v in pairs(inf) do
        if v[unique] == value then
            local tm = inf[k]
            inf[k] = nil
            self:UpdateEx(dbid,key,tm,true)
            return
        end
    end
end

--删除某个角色一类离线信息 --DelOfflineItemByOffType
function OfflineMgr:DelTypeOf(key,dbid)
    local my_inf = self.m_OfflineInf[dbid]
    if not my_inf then
        --self.m_OfflineInf[dbid] = {}
        if not self.m_OpList[dbid] then self.m_OpList[dbid] = {} end
        table.insert(self.m_OpList[dbid],{cb="DelTypeOf",key=key,dbid=dbid})
        --load
        if self.m_Loading[dbid] then return end
        self.m_Loading[dbid] = true
        if self.m_Loading[dbid] then return end
        local redis_key = string.format(self.redis_key_format, dbid)
        self.redis_ud:load(redis_key)
        return
    end
    local inf = my_inf[key]
    if not inf then
        return
    end
    my_inf[key] = nil
    if self:IsSaveByRedis(key) then
        --redis需要挨个写库
        for k, v in pairs(inf) do
            self:UpdateEx(dbid, key, v, true)
        end
    else
        self:UpdateEx(dbid, key, inf)
    end
end

--带回调的删除某项离线信息 DelOfflineItemWithCB
function OfflineMgr:DelCb(mbStr,msgId,key,dbid,unique,value)
    local my_inf = self.m_OfflineInf[dbid]
    if not my_inf then
        --self.m_OfflineInf[dbid] = {}
        if not self.m_OpList[dbid] then self.m_OpList[dbid] = {} end
        table.insert(self.m_OpList[dbid],{cb="DelCb",mbStr=mbStr,msgId=msgId,key=key,dbid=dbid,unique=unique,value=value})
        --load
        if self.m_Loading[dbid] then return end
        self.m_Loading[dbid] = true
        local redis_key = string.format(self.redis_key_format, dbid)
        self.redis_ud:load(redis_key)
        return
    end
    
    local inf = my_inf[key]
    local err_id = error_code.ERR_OFFLINE_OBJ_NOT_EXISIST
    if inf then
        for k,v in pairs(inf) do
            if v[unique] == value then
                local tm = inf[k]
                inf[k] = nil
                self:UpdateEx(dbid,key,tm,true)
                err_id = error_code.ERR_OFFLINE_SUCCEED
            end
        end
    end
    if 0 ~= msgId then
        local mb = mogo.UnpickleBaseMailbox(mbStr)
        if mb then 
            mb.OfflineMgrCallback(msgId, value, {}, err_id) 
        end
    end
end
 
--带回调的获取某项离线数据 --GetOfflineItemWithCB
function OfflineMgr:Get(mbStr,msgId,key,dbid,unique,value,remo)
    local my_inf = self.m_OfflineInf[dbid]
    if not my_inf then
        --self.m_OfflineInf[dbid] = {}
        if not self.m_OpList[dbid] then self.m_OpList[dbid] = {} end
        table.insert(self.m_OpList[dbid],{cb="Get",mbStr=mbStr,msgId=msgId,key=key,dbid=dbid,unique=unique,value=value,remo=remo})
        --load
        if self.m_Loading[dbid] then return end
        self.m_Loading[dbid] = true
        local redis_key = string.format(self.redis_key_format, dbid)
        self.redis_ud:load(redis_key)
        return
    end

    local cb_info = {}
    local err_id = error_code.ERR_OFFLINE_OBJ_NOT_EXISIST
    local inf = my_inf[key]
    if inf then
        for i,v in pairs(inf) do
            if v[unique] == value then
                table.insert(cb_info, v)
                err_id = error_code.ERR_OFFLINE_SUCCEED
            end
        end
    end
    --如果id为零表示不需要回调
    if msgId ~= 0 then
        local mb = mogo.UnpickleBaseMailbox(mbStr)
        if mb then
            mb.OfflineMgrCallback(msgId, value, cb_info, err_id)
        end
    end
    --如果remo非零get完删除
    if remo ~= 0 then
        self:Del(key,dbid,unique,value)
    end
end

--带回调的获取某个角色一类离线数据 --GetOfflineItemByOffTypeWithCB
function OfflineMgr:GetTypeOf(mbStr,msgId,key,dbid,remo)
    local my_inf = self.m_OfflineInf[dbid]
    if not my_inf then
        --self.m_OfflineInf[dbid] = {}
        if not self.m_OpList[dbid] then self.m_OpList[dbid] = {} end
        table.insert(self.m_OpList[dbid],{cb="GetTypeOf",mbStr=mbStr,msgId=msgId,key=key,dbid=dbid,remo=remo})
        --load
        if self.m_Loading[dbid] then return end
        self.m_Loading[dbid] = true
        local redis_key = string.format(self.redis_key_format, dbid)
        self.redis_ud:load(redis_key)
        return
    end

    local cb_info = {}
    local err_id = error_code.ERR_OFFLINE_OBJ_NOT_EXISIST
    local inf = my_inf[key]
    if inf then
        for i,v in pairs(inf) do
            table.insert(cb_info, v)
            err_id = error_code.ERR_OFFLINE_SUCCEED
        end
    end
    --如果id为零表示不需要回调
    if msgId ~= 0 then
        local mb = mogo.UnpickleBaseMailbox(mbStr)
        if mb then
            mb.OfflineMgrCallback(msgId, dbid, cb_info, err_id)
        end
    end
    --如果remo非零get完删除
    if remo ~= 0 then
        self:DelTypeOf(key,dbid)
    end
end

--获取某个玩家所有离线消息
function OfflineMgr:GetAll(mbStr, dbid)
    local my_inf = self.m_OfflineInf[dbid]
    if not my_inf then
        --self.m_OfflineInf[dbid] = {}
        if not self.m_OpList[dbid] then self.m_OpList[dbid] = {} end
        table.insert(self.m_OpList[dbid],{cb="GetAll",mbStr=mbStr,dbid=dbid})
        --load
        if self.m_Loading[dbid] then return end
        self.m_Loading[dbid] = true
        local redis_key = string.format(self.redis_key_format, dbid)
        self.redis_ud:load(redis_key)
        return
    end
    local mb = mogo.UnpickleBaseMailbox(mbStr)
    if mb then
        --需要調用者去實現
        mb.OnGetAllOfflineItem(my_inf)
    end
end
