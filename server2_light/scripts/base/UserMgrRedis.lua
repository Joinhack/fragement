--author:hwj
--date:2013-9-28
--此为在线管理扩展类，使用Redis存储的接口
require "UserDataType"

local log_game_debug = lua_util.log_game_debug
local log_game_warning = lua_util.log_game_warning
local log_game_info = lua_util.log_game_info
local log_game_error = lua_util.log_game_error

function UserMgr:GetRedisKey(dbid)
	return string.format(self.redis_key_format,dbid)
end

function UserMgr:GetRedisSeq(vt_name)
	return redis_vt_seq[vt_name]
end

function UserMgr:BuildRedisData(dbid, vt_name, val)
	if not val['vt'] then 
        val['vt'] = vt_name
    end
	return val
end

function UserMgr:Save(dbid, vt_name)
	local redis_seq = self:GetRedisSeq(vt_name)
    if redis_seq then
		--redis存储
        local theKey = redis_DbidToPlayers_index[vt_name]
        local val = false
        if theKey then
            val = self.DbidToPlayers[dbid][theKey]
        else
            theKey = redis_m_lFights_index[vt_name]
            if not theKey then return end
            local rank = self.DbidToPlayers[dbid][public_config.USER_MGR_PLAYER_ARENIC_FIGHT_RANK_INDEX]
            if self.m_lFights[rank] then
                val = self.m_lFights[rank][theKey]
            end
        end
        --delete
        local redis_key = self:GetRedisKey(dbid)
        if not val then
            return self.m_redisUd:del(redis_seq, redis_key)
        end

        local theData = val
        if type(val) ~= 'table' then
            theData = {}
            table.insert(theData, val)
        end
        
        local redis_data = self:BuildRedisData(dbid, vt_name, theData)
        self.m_redisUd:set(redis_seq, mogo.cPickle(redis_data), redis_key)
	end
	--local mysql
end

function UserMgr:SaveAll(dbid)
    log_game_debug("UserMgr:SaveAll", "%d",dbid)
    for vt_name, _ in pairs(redis_DbidToPlayers_index) do
        self:Save(dbid, vt_name)
    end
    for vt_name,_ in pairs(redis_m_lFights_index) do
        self:Save(dbid, vt_name)
    end
end

--[[
--设置userdata的数目
function UserMgr:SetUserDataCount(count)
    log_game_debug("UserMgr:SetUserDataCount", "max=%d;loaded=%d", count, self.m_user_loaded_count)
    self.m_user_data_count = count

    if self.m_user_data_count == self.m_user_loaded_count then
        self:on_userdata_loaded()
    end
end

--设置一个arenadata
function UserMgr:SetUserData(eid)
    log_game_debug("UserMgr:SetArenaData", "max=%d;loaded=%d", self.m_user_data_count, self.m_user_loaded_count+1)

    self.m_user_loaded_count = self.m_user_loaded_count + 1

    local ad = mogo.getEntity(eid)
    self.m_arenicData[ad.avatarDbid] = ad

    if self.m_user_data_count == self.m_user_loaded_count then
        self:on_userdata_loaded()
    end
end

function UserMgr:on_userdata_loaded()
    
end
]]