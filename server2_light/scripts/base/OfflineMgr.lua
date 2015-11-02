--author:hwj
--date:2013-4-28
--此为离线管理类，需要在加载其他管理器之前加载

require "lua_util"
require "public_config"
require "error_code"
--[[
local MAX_SIZE = 1000000
local recordType = {
    FRIEND_NOTE = 1,
    FRIEND_REQ  = 2,
    LOGIN_CMD   = 3,
    NONE        = 9,
}
]]
local log_game_debug = lua_util.log_game_debug
local log_game_warning = lua_util.log_game_warning
local log_game_info = lua_util.log_game_info
local log_game_error = lua_util.log_game_error

local globalbase_call = lua_util.globalbase_call
----------------------------------------------------------------------------------
--hasTimer中定时器的key
local timerType = {
SAVE  = 1, --销魂定时器
CLEAN = 2, --清理定时器
}
--
local Item = {}
Item.__index = Item
function Item:new(  )
    --local timeout = os.time() + public_config.OFFLINE_MAX_TIMEOUT
    local newItem = {
        
    }
    setmetatable(newItem, {__index = Item})
    return newItem
end
---------------------------------存储item-----------------------------------------
local ItemSave = {}
ItemSave.__index = ItemSave
function ItemSave:new( dbid, con )
    --local timeout = os.time() + public_config.OFFLINE_MAX_TIMEOUT
    local newItem = {
        ["avatarDbid"] = dbid,
        ["content"] = con,
    }
    setmetatable(newItem, {__index = ItemSave})
    return newItem
end

--------------------------------------------------------------------------------------
OfflineMgr = {}
--OfflineMgr.__index = BaseEntity

setmetatable(OfflineMgr, {__index = BaseEntity} )

require "OfflineMgrRedis"
require "OfflineMgrEx"
--------------------------------------------------------------------------------------

--回调方法
local function OfflineMgrRegisterCallback(eid)
    local mm_eid = eid
    local function __callback(ret)
        local gm = mogo.getEntity(mm_eid)
        if gm then
            if ret == 1 then
                --注册成功
                gm:on_registered()
            else
                --注册失败
                log_game_error("UserMgr.registerGlobally error", '')
                --这里注册失败应该直接重启整个服务器群
                --destroy方法未实现,todo
                --gm.destroy()
            end
        end
    end
    return __callback
end

function OfflineMgr:__ctor__()
    --self.base_mbstr = mogo.pickleMailbox(self)
    log_game_info('OfflineMgr:__ctor__', '========')
    self.redis_key_format = "OfflineMgr:%d"
    self.updateItems = {}

    local meta = {}
    --[[
    meta.__index = function (t, k)
        return t[k]
    end
    ]]
    meta.__newindex = function (t, k, v)
        if v then
            --触发写库事件
            if not self.m_OfflineInf[k] then
                log_game_warning("self.updateItems", "__newindex")
                return
            end
            local con = {}
            for vt,v in pairs(self.m_OfflineInf[k]) do
                --if g_offline_data_save_type[vt] ~= public_config.OFFLINE_SAVE_REDIS then
                if not self:IsSaveByRedis(vt) then
                    con[vt] = v
                end
            end
            local it = ItemSave:new(k, con)
            mogo.UpdateBatchToDb({it}, "OfflineData", "avatarDbid")
            --t[k] = v
        end
    end
    setmetatable(self.updateItems, meta)
    --[[
    self.updateItems.__newindex = function (t, k, v)
        if v then
            --触发写库事件
            if not self.m_OfflineInf[k] then
                log_game_warning("self.updateItems", "__newindex")
                return
            end
            local it = ItemSave:new(k, self.m_OfflineInf[k])
            mogo.UpdateBatchToDb({it}, "OfflineData", "avatarDbid")
            t[k] = v
        end
    end
    ]]
    self:RegisterGlobally("OfflineMgr", OfflineMgrRegisterCallback(self:getId()))
end

--注册globalbase成功后回调方法
function OfflineMgr:on_registered()
    log_game_info("OfflineMgr:on_registered", "")

    --lua_util.globalbase_call('GameMgr', 'OnMgrLoaded', 'OfflineMgr')

    --预load用户数据
    --self:TableSelectSql("onSelectResp", "OfflineData", " SELECT sm_avatarDbid, sm_content FROM tbl_OfflineData ")
    self:onSelectResp({})
end

--销毁前操作
function OfflineMgr:onDestroy()
    log_game_info("ArenaMgr:onDestroy", "")
    --self:Save()
end

local tmp_avatar_count = 0 --用于控制起服

function OfflineMgr:onSelectResp(rst)
    local count = 0

    for _, info in pairs(rst) do       
        --log_game_debug("OfflineMgr:onSelectResp", "rst.")
        self.m_OfflineInf[info["avatarDbid"]] = info["content"] or {}
        count = count + 1
    end
    --CommonXmlConfig:TestData(self.m_OfflineInf)
    log_game_info("OfflineMgr:onSelectResp", "avatar_loaded=%d", count)
    
    --注册定时存储器,modify by winj
    --[[
    local timerId= self:addTimer(public_config.OFFLINE_SAVE_INTERVAL, public_config.OFFLINE_SAVE_INTERVAL, 1)
    if self.hasTimer[timerType.SAVE] then
        log_game_warning("OfflineMgr:onSelectResp","addTimer self.hasTimer[timerType.SAVE]")
    else
        --加入定时器集合
        self.hasTimer[timerType.SAVE] = timerId
        log_game_debug('OfflineMgr:onSelectResp', 'addTimer save')
    end
    ]]
    local time = os.time()
    local wdate = os.date("*t", time)
    
    wdate.hour = public_config.OFFLINE_CLEAN_HOUR
    wdate.sec = 0
    wdate.min = 0
    local tt = os.time(wdate)
    while tt < time do
        tt = tt + public_config.OFFLINE_CLEAN_INTERVAL
    end
    local startTick = tt - time
     --注册定时清理器
    timerId= self:addTimer(startTick, public_config.OFFLINE_CLEAN_INTERVAL, 2)
    if self.hasTimer[timerType.CLEAN] then
        log_game_warning("OfflineMgr:onSelectResp","addTimer self.hasTimer[timerType.CLEAN]")
    else
        --加入定时器集合
        self.hasTimer[timerType.CLEAN] = timerId
        log_game_debug('OfflineMgr:onSelectResp', 'addTimer Clean')
    end
    lua_util.globalbase_call('GameMgr', 'OnMgrLoaded', 'OfflineMgr')
    --[[
    if count < 1 then
        lua_util.globalbase_call('GameMgr', 'OnMgrLoaded', 'OfflineMgr')
        return
    end

    local redis_key 
    --log_game_debug("OfflineMgr:onSelectResp", "timerId = %d", timerId)
    for k,_ in pairs(self.m_OfflineInf) do
        self.redis_seq[k] = 0
        redis_key = string.format(self.redis_key_format, k)
        self.redis_ud:load(redis_key)
        tmp_avatar_count = tmp_avatar_count + 1
    end
    ]]
end

--定时定量整理,当前还没有定时某个时刻执行的接口，后面考虑做
--循环一天分若干次清理完所有的过期信息
function OfflineMgr:Clean(  )
    log_game_debug("OfflineMgr:Clean", "")
    for dbid, myInf in pairs(self.m_OfflineInf) do
        for key, aContent in pairs(myInf) do
            for k, v in pairs(aContent) do
                if v[public_config.OFFLINE_ITEM_TIMEOUT_INDEX] and 
                os.time() < v[public_config.OFFLINE_ITEM_TIMEOUT_INDEX] then
                    log_game_debug("OfflineMgr:Clean", "timeout")
                    --过期删除
                    --self:Update(dbid)
                    local tmp = aContent[k]
                    aContent[k] = nil
                    self:UpdateEx(dbid, key, tmp, true)
                end
            end
        end
    end
end

--定时器
function OfflineMgr:onTimer( timer_id, user_data )
    --log_game_debug("OfflineMgr:onTimer","timer_id = %d, user_data = %d.", timer_id, user_data)
    if(timer_id == self.hasTimer[timerType.SAVE]) then
        --self:Save()
    elseif (timer_id == self.hasTimer[timerType.CLEAN]) then
        log_game_debug("OfflineMgr:onTimer","Clean.")
        self:Clean()
    else
        log_game_warning("OfflineMgr:onTimer","unknown timer = %d",timer_id)
    end
end


function OfflineMgr:Update( id )
    --log_game_debug("OfflineMgr:Update", "id = %q", id)
    --如果没有进入定时保存就设定保存
    if not self.updateItems[id] then
        self.updateItems[id] = 1
    end
end

local function deep_copy(depth, t, cpy)
	if depth < 1 then
		return
	end
	for k,v in pairs(t) do
		if type(v) == 'table' then
      local cpy_2 = {}
			deep_copy(depth-1, v, cpy_2)
      cpy[k]=cpy_2
		else
			cpy[k]=v
		end
	end
end

function OfflineMgr:LimitCtrolAdd(id, tbl, it, vt)
    if lua_util.get_table_real_count(tbl) > public_config.OFFLINE_MSG_LIMIT then
        local nn = 0
        for k,v in pairs(tbl) do
            if nn == 0 then
                nn = k
            end
            if nn < k then
                nn = k
            end
        end
        local tmp = tbl[nn]
        tbl[nn] = nil
        self:UpdateEx(id, vt, tmp, true)
        
    end
    --[[
    while #tbl >= public_config.OFFLINE_MSG_LIMIT do
        local to_del = tbl[1]
        self:UpdateEx(id, vt, to_del, true)
        table.remove(tbl, 1)
    end
    ]]
    local tbl_cpy = {}
    deep_copy(3, it, tbl_cpy)
    table.insert(tbl, tbl_cpy)
    self:UpdateEx(id, vt, tbl_cpy)
    --self:Update(id)
end
--[[ delete interfaces

--定时定量入库,todo:根据处理时间的大小来动态变化处理入库数据的大小
function OfflineMgr:Save( )
    local needToSave = {
    --[1] = {
    --["avatarDbid"] = dbid,
    --["content"] = content,
    --}
    } 
    local function OnSave( ret )
        log_game_debug("OfflineMgr:SaveCb", "saved. ret = %d", ret)
    end
    local num = 0
    for k,_ in pairs(self.updateItems) do
        log_game_debug('OfflineMgr:Save', 'id = %d', k)
        table.insert( needToSave, ItemSave:new(k, self.m_OfflineInf[k]) )
        num = num + 1
        self.updateItems[k] = nil
        if num >= 300 then
            mogo.UpdateBatchToDb(needToSave, "OfflineData", "avatarDbid", OnSave )
            needToSave = {}
        end
    end
    --self.updateItems = {}
    if 0 == num then
        --log_game_debug("OfflineMgr:Save", "nothing to save.")
        return
    end 
    --
    mogo.UpdateBatchToDb(needToSave, "OfflineData", "avatarDbid", OnSave )
end
--增加某个角色一类离线信息一个值,可重复
function OfflineMgr:AddOfflineItem( OffType, acceptId, it )
    log_game_debug("OfflineMgr:AddOfflineItem", "OffType = %d, acceptId = %d", OffType, acceptId)
    if not self.m_OfflineInf[acceptId] then
        log_game_error('OfflineMgr:AddOfflineItem', 'can not find obj.')
        self.m_OfflineInf[acceptId] = {}
        --return error_code.ERR_OFFLINE_OBJ_NOT_EXISIST
    end

    if not self.m_OfflineInf[acceptId][OffType] then
        self.m_OfflineInf[acceptId][OffType] = Item:new()
    end
    self:LimitCtrolAdd(acceptId, self.m_OfflineInf[acceptId][OffType], it, OffType)
    --table.insert( self.m_OfflineInf[acceptId][OffType], it )
    --self:Update(acceptId)
    return error_code.ERR_OFFLINE_SUCCEED
end
--替换某个角色来自某个角色的一类离线信息一个值，不存在则增加
--fromIdIndex:unique key
function OfflineMgr:ReplaceInto( OffType, acceptId, it, fromIdIndex, dbid )
    log_game_debug("OfflineMgr:ReplaceInto", "OffType = %d, acceptId = %d", OffType, acceptId)
    if not self.m_OfflineInf[acceptId] then
        log_game_error('OfflineMgr:ReplaceInto', 'can not find obj.')
        self.m_OfflineInf[acceptId] = {}
        --return error_code.ERR_OFFLINE_OBJ_NOT_EXISIST
    end
    if not it or type(it) ~= 'table' then 
    	log_game_warning("OfflineMgr:ReplaceInto", "it is illegal:OffType[%d], acceptId[%q]", OffType, acceptId)
    	return 
    end
    local theInfos = self.m_OfflineInf[acceptId][OffType]
    if not theInfos then
        --add
        self.m_OfflineInf[acceptId][OffType] = Item:new()
        self:LimitCtrolAdd(acceptId, self.m_OfflineInf[acceptId][OffType], it, OffType)       
        --table.insert( self.m_OfflineInf[acceptId][OffType], it )
        --self:Update(acceptId)
        return error_code.ERR_OFFLINE_SUCCEED
    end

    for i,v in pairs(theInfos) do
        if v[fromIdIndex] == dbid then
            --replace
            local nSeq = theInfos[i]['nSeq']
            if nSeq then
                it['nSeq'] = nSeq
            end
            theInfos[i] = it
            self:UpdateEx(acceptId, OffType, it)
            --self:Update(acceptId)
            return error_code.ERR_OFFLINE_SUCCEED
        end
    end
    --add
    self:LimitCtrolAdd(acceptId, self.m_OfflineInf[acceptId][OffType], it, OffType)
    --table.insert( self.m_OfflineInf[acceptId][OffType], it )
    --self:Update(acceptId)
    return error_code.ERR_OFFLINE_SUCCEED
end

--删除某个角色一类离线信息
function OfflineMgr:DelOfflineItemByOffType( offType, acceptId )
    local theOfflineInfo = self.m_OfflineInf[acceptId]
    if not theOfflineInfo then
        return error_code.ERR_OFFLINE_OBJ_NOT_EXISIST
    end 
    local theInfos = theOfflineInfo[offType] 
    if not theInfos then
        return error_code.ERR_OFFLINE_OBJ_NOT_EXISIST
    end
    
    --self:Update(acceptId)
    self.m_OfflineInf[acceptId][offType] = nil
    if self:IsSaveByRedis(offType) then
    	--redis需要挨个写库
	    for k, v in pairs(theInfos) do
	        self:UpdateEx(acceptId, offType, v, true)
	    end
	else
		self:UpdateEx(acceptId, offType, v)
	end
    return error_code.ERR_OFFLINE_SUCCEED
end

--删除来自某个dbid角色的某类离线信息
function OfflineMgr:DelOfflineItem( offType, acceptId, fromIdIndex, dbid )
    log_game_debug("OfflineMgr:DelOfflineItem", "offType = %d, acceptId = %d, fromIdIndex = %d, dbid = %q", offType, acceptId, fromIdIndex, dbid)
    local err = error_code.ERR_OFFLINE_OBJ_NOT_EXISIST
    local theOfflineInfo = self.m_OfflineInf[acceptId]
    if not theOfflineInfo then
        log_game_debug("OfflineMgr:DelOfflineItem","self.m_OfflineInf[acceptId] is nil.")
        return err
    end 
    local theInfos = theOfflineInfo[offType] 
    if not theInfos then
        log_game_debug("OfflineMgr:DelOfflineItem","self.m_OfflineInf[acceptId][offType] is nil.")
        return err
    end
    --log_game_debug('OfflineMgr:DelOfflineItem', 'theInfos size1 = %d', lua_util.get_table_real_count(theInfos) )
    --local count = 0
    for k, v in pairs(theInfos) do
        --count = count + 1
        if v[fromIdIndex] == dbid then
            --log_game_debug("OfflineMgr:DelOfflineItem", "remove.")
            --table.remove(theInfos, i)
            --self:Update(acceptId)
            local tmp = theInfos[k]
           	theInfos[k] = nil
            self:UpdateEx(acceptId, offType, tmp, true)
            err = error_code.ERR_OFFLINE_SUCCEED
        end
    end
    --log_game_debug('OfflineMgr:DelOfflineItem', 'theInfos size2 = %d', count)
    return err
end

--带回调的删除来自某个角色dbid的某类离线信息
function OfflineMgr:DelOfflineItemWithCB( mbStr, msgId, offType, acceptId, fromIdIndex, dbid )
    log_game_debug("OfflineMgr:DelOfflineItemWithCB", "")
    local err = self:DelOfflineItem( offType, acceptId, fromIdIndex, dbid )
    --如果id为零表示不需要回调
    
    if msgId == 0 then
        return
    end
    local mb = mogo.UnpickleBaseMailbox(mbStr)
    if mb then
        mb.OfflineMgrCallback(msgId, dbid, {}, err)
    end
end

--带回调的获取某个角色一类离线数据
function OfflineMgr:GetOfflineItemByOffTypeWithCB( mbStr, msgId, offType, acceptId, remo )
    log_game_debug('OfflineMgr:GetOfflineItemByOffTypeWithCB', 'acceptId = %d', acceptId)
    local infos = {}
    local function GetInfo( )
        local theOfflineInfo = self.m_OfflineInf[acceptId]
        if not theOfflineInfo then
            return error_code.ERR_OFFLINE_OBJ_NOT_EXISIST
        end 
        local theInfos = theOfflineInfo[offType] 
        if not theInfos then
            return error_code.ERR_OFFLINE_OBJ_NOT_EXISIST
        end
        infos = theInfos
        return error_code.ERR_OFFLINE_SUCCEED
    end
    local errID = GetInfo()
    log_game_debug('OfflineMgr:GetOfflineItemByOffTypeWithCB', 'errID = %d', errID)
     --如果id为零表示不需要回调
    if msgId ~= 0 then
        local mb = mogo.UnpickleBaseMailbox(mbStr)
        if mb then
            log_game_debug('OfflineMgr:GetOfflineItemByOffTypeWithCB', 'have mb')
            mb.OfflineMgrCallback(msgId, acceptId, infos, errID)
        end
    end
    --如果remo非零get完删除
    if remo ~= 0 then
        self:DelOfflineItemByOffType( offType, acceptId )
        log_game_debug('GetOfflineItemByOffTypeWithCB', 'delete.')
    end
end

--带回调的获取来自某个角色的某类离线数据
function OfflineMgr:GetOfflineItemWithCB( mbStr, msgId, offType, acceptId, fromIdIndex, dbid, remo )
    local info = {}
    local function GetInfo( )
        local err = error_code.ERR_OFFLINE_OBJ_NOT_EXISIST
        local theOfflineInfo = self.m_OfflineInf[acceptId]
        if not theOfflineInfo then
            return err
        end 
        local theInfos = theOfflineInfo[offType] 
        if not theInfos then
            return err
        end
        for i,v in pairs(theInfos) do
            if v[fromIdIndex] == dbid then
                table.insert(info, v)
                err = error_code.ERR_OFFLINE_SUCCEED
            end
        end
        return err
    end
    local errID = GetInfo()
    --如果id为零表示不需要回调
    if msgId ~= 0 then
        local mb = mogo.UnpickleBaseMailbox(mbStr)
        if mb then
            mb.OfflineMgrCallback(msgId, dbid, info, errID)
        end
    end
    --如果remo非零get完删除
    if remo ~= 0 then
        self:DelOfflineItem( offType, acceptId, fromIdIndex, dbid )
    end
end

--获取某个玩家所有离线消息
function OfflineMgr:GetAllOfflineItem( mbStr, dbid )
    local allInfo = self.m_OfflineInf[dbid]
    if not allInfo then
        allInfo = {}
    end
    local mb = mogo.UnpickleBaseMailbox(mbStr)
    if mb then
        --需要調用者去實現
        mb.OnGetAllOfflineItem(allInfo)
    end
end



--新创建角色
function OfflineMgr:NewCharacter( dbid )
    log_game_debug('OfflineMgr:NewCharacter', '%d', dbid)
    if self.m_OfflineInf[dbid] then
        return
    end
    self.m_OfflineInf[dbid] = {}
    self:Update(dbid)
end

--替换某个角色一类离线信息
function OfflineMgr:RepOfflineItemByOffType( offType, acceptId, it )
    if not self.m_OfflineInf[acceptId] then
        self.m_OfflineInf[acceptId] = Item:new()
    end  
    if not self.m_OfflineInf[acceptId][offType] then
        self.m_OfflineInf[acceptId][offType] = Item:new()
    end
    if self:IsSaveByRedis(offType) then
        --如果是redis的数据需要一个一个的删除
        for k,v in pairs(self.m_OfflineInf[acceptId][offType]) do
            self:UpdateEx(acceptId, offType, v, true)
        end
    end
    self.m_OfflineInf[acceptId][offType] = it
    if self:IsSaveByRedis(offType) then
        --如果是redis的数据需要一个一个的增加
        for k,v in pairs(self.m_OfflineInf[acceptId][offType]) do
            self:UpdateEx(acceptId, offType, v)
        end
    else
        --mysql一次性存储
        self:UpdateEx(acceptId, offType, v)
    end
end

--redis回调
function OfflineMgr:onRedisReply(key, value)
    --log_game_debug("OfflineMgr:onRedisReply", "key[%s]", key)
    tmp_avatar_count = tmp_avatar_count - 1

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
    --log_game_debug("OfflineMgr:onRedisReply", "========[%d]========", tmp_avatar_count)
    if tmp_avatar_count > 0 then
        return
    end

    --
    
end
]]

return OfflineMgr
