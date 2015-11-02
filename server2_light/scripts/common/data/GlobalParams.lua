
require "lua_util"

local log_game_debug = lua_util.log_game_debug
local _readXml = lua_util._readXml


local GlobalParamsMgr = {}
GlobalParamsMgr.__index = GlobalParamsMgr

local function Convert( str )
    if tonumber(str) then
        return tonumber(str)
    end
    return str
end

function GlobalParamsMgr:initData()

    self.globalParams = _readXml('/data/xml/global_params.xml', 'key')
    setmetatable(self.globalParams, {__index = function(t, k) return nil end})

    local result = {}
    for key, value in pairs(self.globalParams) do
        local prefix = string.sub(key, -2)
        local key2 = string.sub(key, 0, -3)
        if prefix == "_i" then
            result[key2] = tonumber(value['value'])
        elseif prefix == "_f" then
            result[key2] = tonumber(value['value'])
        elseif prefix == "_s" then
            result[key2] = tostring(value['value'])
        elseif prefix == "_l" then
            --list
            result[key2] = lua_util.split_str(value['value'], ',', Convert)
        elseif prefix == "_k" then
            --key table
            local tmp = lua_util.split_str(value['value'], ',', Convert)
            local tmp2 = {}
            for _, k in pairs(tmp) do
                tmp2[k] = 1
            end
            result[key2] = tmp2
        elseif prefix == "_m" then
            local tmp = lua_util.split_str(value['value'], ',')
            local tmp2 = {}
            for _, v in pairs(tmp) do
                local tmp = lua_util.split_str(v, ':')
                local id = tonumber(tmp[1]) or tmp[1]
                local num = tonumber(tmp[2]) or tmp[2]
                tmp2[id] = num
            end
            result[key2] = tmp2

            --特殊处理迷雾深渊用到的次数对应概率
            if key2 == "mwsyRate" then
                local mwsyMaxTimes = 0
                local mwsyMinTimes = 10000000
                for k, _ in pairs(tmp2) do
                    if k >= mwsyMaxTimes then
                        mwsyMaxTimes = k
                    end
                    if k <= mwsyMinTimes then
                        mwsyMinTimes = k
                    end
                end
                result['mwsyMinTimes'] = mwsyMinTimes
                result['mwsyMaxTimes'] = mwsyMaxTimes
            end

        elseif prefix == "_d" then
            local tmp = lua_util.split_str(value['value'], '-')
            result[key2] = os.time{year=tmp[1], month=tmp[2], day=tmp[3], hour=tmp[4], min=tmp[5], sec=tmp[6] }
        elseif prefix == "_t" then
            local tmp = lua_util.split_str(value['value'], '-')
            result[key2] = os.time{year=2000, month=1, day=1, hour=tmp[1], min=tmp[2], sec=tmp[3]}
        --特殊处理副本进入点
        elseif key == "init_scene_random_enter_point" or key == 'tower_defence_scene_random_enter_point' or 
            key == "defense_pvp_enter_point" then
            local tmp = lua_util.split_str(value['value'], ';')
            local tmp2 = {}
            for _, v in pairs(tmp) do
                local tmp = lua_util.split_str(v, ',')
                table.insert(tmp2, {tonumber(tmp[1]) or tmp[1], tonumber(tmp[2]) or tmp[2]})
            end
            result[key] = tmp2
--            log_game_debug("GlobalParamsMgr:initData", "key=%s;value=%s", key, mogo.cPickle(tmp2))
        else
            result[key] = value['value']
        end
    end

    self.globalParams = result

--    log_game_debug("GlobalParamsMgr:initData", "globalParams=%s", mogo.cPickle(self.globalParams))
end

function GlobalParamsMgr:GetParams(key, default)
    return self.globalParams[key] or default
end

g_GlobalParamsMgr = GlobalParamsMgr
return g_GlobalParamsMgr
