

local public_config = require "public_config"
--local lua_util = require "lua_util"
--
--local log_game_info = lua_util.log_game_info
--local _readXml = lua_util._readXml
--local _MAP_TYPE_NORMAL = public_config.MAP_TYPE_NORMAL
--local get_table_value = lua_util.get_table_value
--
--
--
---------------------------------------------------------------------------------------------------
local MapActionCellMgr = {}
MapActionCellMgr.__index = MapActionCellMgr
---------------------------------------------------------------------------------------------------
--
----读取配置数据
--function MapActionCellMgr:initData()
--    --地图表
--    self._map_data = _readXml('/data/xml/map_setting.xml', 'id_i')
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
--                end
--            end
--        end
--    end
--
--    self._map_id_data = _map_id_data
--
--    self._normal_maps = _normal_maps
--    self._special_maps = _special_maps
--
--    --读取所有的场景配置表
--    self:load_space_data()
--
--
--
--end
--
--
----读取所有的场景配置表
--function MapActionCellMgr:load_space_data()
--    local tmp = {}
--    local fn_prefix = G_LUA_ROOTPATH .. '/data/spaces/'
--    local bm_fn_prefix = G_LUA_ROOTPATH .. '/data/blockmap'
--    for map_id, data in pairs(self._map_data) do
--        local fn = fn_prefix .. data['spaceName'] .. '.xml'
--        local sptmp = mogo.readSpace(fn)
--        if sptmp then
--            tmp[map_id] = sptmp
----            log_game_info("MapActionMgr:load_space_data", " sptmp['mapname']=%s", sptmp['mapname'])
--            --读取障碍信息
--        --    mogo.load_bm(map_id, string.format("%s/%s.bm", bm_fn_prefix, sptmp['mapname']))还没实现c++接口
--        end
--    end
--
--    self._space_data = tmp
--end
--
--
----获取一个map_id的原始map_id(map_id可能是原始map_id+分线数)
--function MapActionCellMgr:get_src_map_id(map_id)
--    local tmp = self._map_id_data[map_id]
--    if tmp then
--        return tmp
--    else
--        return map_id
--    end
--end
--
----场景新进入一个玩家
--function MapActionCellMgr:on_avatar_ctor(sp)
--    local count = sp.avatar_count + 1
--    sp.avatar_count = count
--    local max = self._map_max_data[sp.map_id]
--    --print("sp++", sp.map_id, count, max)
--    if max then
--        if count >= max then
--            --超过了人数上限,通知base禁止玩家进入
--            sp.avatar_max_flag = 1
--            sp.base.set_avatar_max_flag(1)
--            --print("sp_flag1", sp.map_id, count, max)
--        end
--    end
--
--end
--
----场景离开了一个玩家
--function MapActionCellMgr:on_avatar_dctor(sp)
--    local count = sp.avatar_count - 1
--    if count < 0 then
--        count = 0
--    end
--    sp.avatar_count = count
--    --print("sp--", sp.map_id, count)
--    if sp.avatar_max_flag == 1 then
--        local max = self._map_max_data[sp.map_id]
--        if count < max*0.9 then
--            --玩家人数小于人数上限后不马上解除禁止进入,要小于10%之后才开放进入
--            sp.avatar_max_flag = 0
--            sp.base.set_avatar_max_flag(0)
--            --print("sp_flag0", sp.map_id, count, max)
--        end
--    end
--end
--
----获取指定一个场景的Entity配置数据
--function MapActionCellMgr:get_map_entity_cfg_data(map_id)
--    local tmp = self._space_data[map_id]
--    if tmp then
--        local tmp2 = tmp['entities']
--        if tmp2 then
--            return tmp2
--        end
--    end
--end

function MapActionCellMgr:EnterTeleportpointReq(avatar, tp_eid)
    local entity = mogo.getEntity(tp_eid)
    if entity and entity.c_etype == public_config.ENTITY_TYPE_TELEPORTSRC then
        --根据eid找到entity，并且该entity的类型是传送点
        --todo：计算玩家和传送点距离
        avatar.base.TeleportCell2Base(entity.targetSceneId, entity.targetX, entity.targetY)
    end
end

-------------------------------------------------------------------------------------------------

gCellMapMgr = MapActionCellMgr
return gCellMapMgr

