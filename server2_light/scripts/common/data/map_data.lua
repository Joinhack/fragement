

require "public_config"
require "error_code"
require "action_config"
require "lua_util"
--require "mgr_action"
--local global_data = require "global_data"


local log_game_info = lua_util.log_game_info
local log_game_debug = lua_util.log_game_debug
local _readXml = lua_util._readXml
--local choose_1 = lua_util.choose_1

--local _MAP_TYPE_NORMAL = public_config.MAP_TYPE_NORMAL

local MapDataMgr = {}
MapDataMgr.__index = MapDataMgr
-------------------------------------------------------------------------------------------------

--读取配置数据
function MapDataMgr:initData()
    --地图表
    self._map_data = _readXml('/data/xml/map_setting.xml', 'id_i')

    self.randomScene = {}
    for k, v in pairs(self._map_data) do
        if v['isRandom'] and v['isRandom'] == 1 then
--            log_game_debug("MapDataMgr:initData random scene", "k=%d", k)
            self.randomScene[k] = true
--            table.insert(self.randomScene, k)
        end
    end
--    for k, v in pairs(self._map_data) do
--        local data = v['position']
--        log_game_debug("MapDataMgr:init_data", "x=%d;y=%d", data.x, data.y)
--    end
--    --预生成加了分线数的map_id和原始map_id对应关系
--    local _map_id_data = {}
--    local _normal_maps = {}     --普通地图的对应表，格式：{真实地图ID : 分线地图ID}
--    local _special_maps = {}    --副本地图的对应表，格式：{真实地图ID : 副本地图ID}

--    for map_id, data in pairs(self._map_data) do
--        local fx = data['line']
--        if fx then
--            local tmp2
--            local is_normal = data['type'] == public_config.MAP_TYPE_NORMAL
--            if is_normal then
--                tmp2 = _normal_maps[map_id]
--                if tmp2 == nil then
--                    tmp2 = {}
--                    _normal_maps[map_id] = tmp2
--                end
--            else
--                tmp2 = _special_maps[map_id]
--                if tmp2 == nil then
--                    tmp2 = {}
--                    _special_maps[map_id] = tmp2
--                end
--            end
--
--            for i = 1, fx do
--                local map_id_str = tostring(map_id) .. "_" .. tostring(i)
--                _map_id_data[map_id_str] = map_id
--                if is_normal then
--                    table.insert(tmp2, map_id_str)
----                    log_game_debug("MapDataMgr:initData", "map_id=%d;map_id_str=%s", map_id, map_id_str)
--                end
--            end
--        end
--    end

--    self._map_id_data = _map_id_data
--
--    self._normal_maps = _normal_maps
--    self._special_maps = _special_maps

    --读取所有的场景配置表
    self:load_space_data()
--    --传送点表
--    self._tp_data = _readXml('/data/xml/teleport_setting.xml', 'id_i')
end

----获取新的随机副本
--function MapDataMgr:GetRandomSceneId()
--    return choose_1(self.randomScene)
--end

--获取所有随机副本的场景ID
function MapDataMgr:GetRandomSceneIds()
    return self.randomScene
end

--读取所有的场景配置表
function MapDataMgr:load_space_data()
    local tmp = {}
    local fn_prefix = G_LUA_ROOTPATH .. '/data/spaces/'
    local bm_fn_prefix = G_LUA_ROOTPATH .. '/data/blockmap'
    for map_id, data in pairs(self._map_data) do

        if data['spaceName'] and data['spaceName'] ~= '' then
            local fn = fn_prefix .. data['spaceName'] .. '.xml'
            --log_game_debug("MapDataMgr:load_space_data", "map_id=%d;fn=%s", map_id, fn)
            local sptmp = mogo.readSpace(fn)

            if sptmp then
                tmp[map_id] = sptmp
                --log_game_debug("MapDataMgr:load_space_data", "map_id=%d;sptmp=%s", map_id, mogo.cPickle(sptmp))

                --            log_game_info("MapDataMgr:load_space_data", " sptmp['mapname']=%s", sptmp['mapname'])
                --读取障碍信息
                mogo.load_bm(map_id, string.format("%s/%s.bm", bm_fn_prefix, data['mapname']))
            end
        else
            log_game_debug("load_space_data", "map_id=%d;spaceName=%s", map_id, data['spaceName'])
        end

    end

    self._space_data = tmp
    --for k,v in pairs(tmp) do
    --    print(k,mogo.cpickle(v))
    --end
end

--function MapDataMgr:extendMapFx(map_id, num)
--    log_game_debug("MapDataMgr:extendMapFx", "map_id[%s], num[%d]", tostring(map_id), num)
--    local maps = self._normal_maps[map_id]
--    if maps then
--        local maxNum = table.maxn(maps)
--        for i = 1, num do
--            local mapNum = maxNum + i
--            local map_id_str = tostring(map_id) .. "_" .. tostring(mapNum)
--            table.insert(maps, map_id_str)
--            self._map_id_data[map_id_str] = map_id
--        end
--        return true
--    end
--end

--获取一个map_id的原始map_id(map_id可能是原始map_id+分线数)
function MapDataMgr:GetSrcMapId(map_id)
    local tmp_mid = tostring(map_id)
    if tmp_mid then
        local tmp = lua_util.split_str(tmp_mid, '_', tonumber)
        if tmp[1] then return tmp[1] end
    end
    return map_id
end

function MapDataMgr:getMapCfgData(map_id)
    return self._map_data[map_id]
end

--获取配置表的地图配置表的数据
function MapDataMgr:getMapData()
    return self._map_data
end

--获取一个entity在场景配置里的信息
function MapDataMgr:GetEntityCfgData(map_id, eid)
    local tmp = self._space_data[map_id]
    if tmp then
        local tmp2 = tmp['entities']
        if tmp2 then
            return tmp2[eid]
        end
    end
end

--获取指定一个场景的Entity配置数据
function MapDataMgr:GetMapEntityCfgData(map_id)
        
    local tmp = self._space_data[map_id]
    if tmp then
        local tmp2 = tmp['entities']
        if tmp2 then
            return tmp2
        end
    end
end

--
function MapDataMgr:IsWBMap(map_id)
    local id = self:GetSrcMapId(map_id)
    local data = self:getMapCfgData(id)
    if not data then
        lua_util.log_game_error("MapDataMgr:IsWBMap", "map_id = %s", map_id)
        return false
    end
    return public_config.MAP_TYPE_WB == data['type']
end

----玩家上线校验map_id
--function MapDataMgr:init_avatar_data(avatar)
--    local map_id = self:GetSrcMapId(avatar.map_id)
--    local data = self._map_data[map_id]
--    if data then
--        local mtype = data['type']
--        if mtype == public_config.MAP_TYPE_NORMAL then
--            --普通场景,移到人数较多的分线
--            local map_id2 = self:get_available_fx(map_id)
--            if map_id2 then
--                --print('map_init', avatar.map_id, map_id, map_id2)
--                avatar.map_id = map_id2
--            end
--        elseif mtype == public_config.MAP_TYPE_BOSS_SPAWNER then
--            --boss战刷怪地图,要先离开
--            avatar:boss_abort_on_init()
--        elseif mtype == public_config.MAP_TYPE_MPINS then
--            
--            --退出多人战斗场景
--            avatar:mpins_vs33_abort_on_init()
--        end
--    end
--end

--判断玩家是否处于多人副本场景
function MapDataMgr:is_in_mpins(map_id)
    local src_map_id = self:GetSrcMapId(map_id)
    local data = self._map_data[src_map_id]
    if data then
        return data['type'] == public_config.MAP_TYPE_MPINS
    end

    return false
end

--判断玩家是否处于普通场景
function MapDataMgr:is_in_normal_map(map_id)
    local data = self._map_data[map_id]
    if data then
        return data['type'] == public_config.MAP_TYPE_NORMAL
    end

    return false
end


----根据map_id获取可进入的分线map_id
--function MapDataMgr:get_available_fx(map_id)
--    local tmp = self._normal_maps[map_id]
--    if tmp == nil then
--        return map_id
--    end
--
--    for _, fx_map_id in ipairs(tmp) do
--        if global_data:is_sp_available(fx_map_id) then
--            return fx_map_id
--        end
--    end
--
--    return nil
--end

--[[
function MapDataMgr:DestroyBaseEntity(avatar)
	log_game_debug("map_mgr:DestroyBaseEntity","%s",avatar.name)
	account = mogo.getEntity(avatar.accountId)
	account.activeAvatarId = 0
	local function _dummy()
	end
	account:writeToDB(_dummy)
	
	local function onDestroyAccount()
		mogo.DestroyBaseEntity(avatar:getId())
		mogo.DestroyBaseEntity(account::getId())
	end
	avatar:NotifyDbDestroyAccount(avatar.accountName, onDestroyAccount)
end
--]]
-------------------------------------------------------------------------------------------------

g_map_mgr = MapDataMgr
return g_map_mgr
