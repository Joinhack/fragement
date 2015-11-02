
require "public_config"
require "lua_util"
require "mercenary_config"

-- 佣兵支援系统

MercenarySystem = {}
MercenarySystem.__index = MercenarySystem

function MercenarySystem:new( owner )

    local newObj = {}
    newObj.ptr = {}

    setmetatable(newObj, {__index = MercenarySystem})
    setmetatable(newObj.ptr, {__mode = "kv"})

    newObj.ptr.theOwner = owner

    local msgMapping = {

        --客户端到base的请求
        [mercenary_config.MSG_EMPLOY_MERCENARY]         = MercenarySystem.Employ,                --雇佣一个玩家
        [mercenary_config.MSG_GET_LIST_MERCENARY]       = MercenarySystem.GetList,               --获取可雇用的列表
    }
    newObj.msgMapping = msgMapping

    return newObj
end

function MercenarySystem:tostring()
    local l = {}
    for k, v in pairs(self) do
        l[#l + 1] = v
    end

    return "{" .. table.concat(l, ", ") .. "}"
end

--雇佣指定dbid的玩家
function MercenarySystem:Employ(PlayerDbid)

    if PlayerDbid ~= self.ptr.theOwner.dbid then
        lua_util.globalbase_call("UserMgr", "Employ", mogo.cPickle(self.ptr.theOwner.cell), PlayerDbid)
    end

end

function MercenarySystem:MercenaryReq(msg_id, ...)
    lua_util.log_game_debug("MercenarySystem:MercenaryReq", "msg_id=%d", msg_id)

    local func = self.msgMapping[msg_id]
    if func ~= nil then
        func(self, ...)
    end
end

--获取可雇佣玩家的列表
function MercenarySystem:GetList()
    local friendsData = {}
    for k,v in pairs(self.ptr.theOwner.friends) do
        friendsData[k] = v[friendsInfoIndex.nextHireTimeIndex]
--        print(k, v)
    end
    lua_util.globalbase_call("UserMgr", "QueryMercenaryList", self.ptr.theOwner.base_mbstr, self.ptr.theOwner.dbid, friendsData)
end

return MercenarySystem


