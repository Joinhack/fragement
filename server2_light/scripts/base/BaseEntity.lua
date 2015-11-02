--所有entity类在lua里的基类

require "lua_util"

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info

BaseEntity = {}

BaseEntity.__index = BaseEntity

function BaseEntity:__init__()
    
    log_game_debug("BaseEntity:__init__", string.format("id=%d", self:getId()) )
end

--构造函数
function BaseEntity:__ctor__()
    log_game_debug("BaseEntity.__ctor__", string.format("id=%d", self:getId()) )
end

--客户端连接到entity的回调方法 
function BaseEntity:onClientGetBase()
    log_game_debug("BaseEntity.onClientGetBase", string.format("id=%d", self:getId()) )
end

--客户端断开连接的回调方法 
function BaseEntity:onClientDeath()
	log_game_debug("BaseEntity.onClientDeath", string.format("id=%d", self:getId()) )
end

--多个客户端连接的回调方法
function BaseEntity:onMultiLogin()
    log_game_debug("BaseEntity.onMultiLogin", string.format("id=%d", self:getId()) )
end

--cell创建好的回调方法
function BaseEntity:onGetCell()
    log_game_debug("BaseEntity.onGetCell", string.format("id=%d", self:getId()) )
end

--
function BaseEntity:onDestroy()
    log_game_debug("BaseEntity.onDestroy", string.format("id=%d", self:getId()))
end

return BaseEntity

