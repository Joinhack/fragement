require "lua_util"

local log_game_debug = lua_util.log_game_debug
local log_game_info  = lua_util.log_game_info
local log_game_error = lua_util.log_game_error

local VipCfgData = {}
VipCfgData.__index = VipCfgData

function VipCfgData:initData()
    self.vipDatas = {}
    local cfgDatas = lua_util._readXml("/data/xml/privilege.xml", "id_i")
    for k, v in pairs(cfgDatas) do
        local rangeSum = v.accumulatedAmount
        if rangeSum == nil then
            log_game_error("VipCfgData:GetVipLevel", "vip config table error:rangeSum nil")
            return
        end
        if rangeSum[1] > rangeSum[2] then
            log_game_error("VipCfgData:GetVipLevel", "vip config table error:rangeSum data error")
            return 
        end
    end
    self.vipDatas = cfgDatas
end

--通过等级获取VIP权限配置属性表
function VipCfgData:GetVipPrivileges(level)
    if self.vipDatas then
        local vt = self.vipDatas[level]
        if vt ~= nil then
            return vt
        end
    end
end

--根据累计充值金额获取当前所属等级
function VipCfgData:GetVipLevel(chrgeSum)
    if chrgeSum < 0 then
        log_game_error("VipCfgData:GetVipLevel", "chrgeSum %d illegal", chrgeSum)
        return 
    end
    if self.vipDatas == nil then
        log_game_error("VipCfgData:GetVipLevel", "vip config table error")
        return
    end
    local m = 0
    for k, v in pairs(self.vipDatas) do
        local rangeSum = v.accumulatedAmount
        if rangeSum and chrgeSum >= rangeSum[1] and chrgeSum <= rangeSum[2] then
            return k
        elseif rangeSum and chrgeSum > rangeSum[2] and k > m then
            m = k
        end
    end
    return m
end

g_vip_mgr = VipCfgData
return g_vip_mgr

