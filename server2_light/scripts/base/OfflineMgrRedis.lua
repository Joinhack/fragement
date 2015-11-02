--author:hwj
--date:2013-9-28
--此为离线管理扩展类，使用Redis存储的接口

require "OfflineDataType"

local log_game_debug = lua_util.log_game_debug
local log_game_warning = lua_util.log_game_warning
local log_game_info = lua_util.log_game_info
local log_game_error = lua_util.log_game_error

function OfflineMgr:IsSaveByRedis(vt)
	return g_offline_data_save_type[vt] == public_config.OFFLINE_SAVE_REDIS
end

function OfflineMgr:MakeKey(dbid)
	return string.format(self.redis_key_format, dbid)
end

function OfflineMgr:MakeSeq(dbid)
	if not self.redis_seq[dbid] then
		self.redis_seq[dbid] = 0
	end
	local nn = self.redis_seq[dbid] + 1
	self.redis_seq[dbid] = nn
	return nn
end

function OfflineMgr:BuildRedisData(dbid, vt, val)
  if not val['nSeq'] then
      val['nSeq'] = self:MakeSeq(dbid)
  end
	--val['nSeq'] = val['nSeq'] or self:MakeSeq(dbid)
	val['vt'] = vt
	return val
end

function OfflineMgr:UpdateEx(dbid, vt, val, del)
	if not self:IsSaveByRedis(vt) then
		--mysql存储
	    if not self.updateItems[dbid] then
	        self.updateItems[dbid] = 1
	    end
	    return
	end
	--redis存储
	if del then
		self:RedisDel(val['nSeq'], dbid)
	else
		self:RedisSet(dbid, vt, val)
	end
end

function OfflineMgr:RedisSet(dbid, vt, val)
	local redis_data = self:BuildRedisData(dbid, vt, val)
	local redis_key = self:MakeKey(dbid)
	self.redis_ud:set(redis_data['nSeq'], mogo.cPickle(redis_data), redis_key)
end

function OfflineMgr:RedisDel(seq, dbid)
	local redis_key = self:MakeKey(dbid)
	--删除redis,不用等回调
    self.redis_ud:del(seq, redis_key)
end

