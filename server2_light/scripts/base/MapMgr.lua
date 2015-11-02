
require "lua_util"
require "error_code"
--require "global_data"
require "map_data"
require "public_config"
require "GlobalParams"


local log_game_debug = lua_util.log_game_debug
local log_game_warning = lua_util.log_game_warning
local log_game_info = lua_util.log_game_info
local log_game_error = lua_util.log_game_error
local _readXml = lua_util._readXml
local confirm                  = lua_util.confirm
local generic_base_call_client = lua_util.generic_base_call_client
local globalbase_call = lua_util.globalbase_call

local _STATE_INIT            = 0      --初始状态
local _STATE_MAP_LOADED      = 1      --所有地图加载完毕
local _STATE_CITIES_LOADED   = 2      --所有玩家城市加载完毕
local _STATE_MAP_LOADING     = 3      --正在加载地图


local _TIMER_ID_24_CLOCK = 11      --每日0点的timer
local _TIMER_ID_EVERY_HOUR = 12    --每个小时一次的timer

local _INIT_MAP_COUNT = 2000    --初始创建的空的spaceloader数量

local _EXTEND_MAP_COUNT = 1    --每次扩展场景时需要创建的分线

MapMgr = {}
--MapMgr.__index = MapMgr

setmetatable(MapMgr, {__index = BaseEntity} )

--------------------------------------------------------------------------------------

--回调方法
local function _map_mgr_register_callback(eid)
    local mm_eid = eid
    local function __callback(ret)
        local gm = mogo.getEntity(mm_eid)
        if gm then
            if ret == 1 then
                --注册成功
                gm:on_registered()
            else
                --注册失败
                log_game_warning("MapMgr.registerGlobally error", '')
                --destroy方法未实现,todo
                --gm.destroy()
            end
        end
    end
    return __callback
end

function MapMgr:__ctor__()
    log_game_info('MapMgr:__ctor__', '')

    self.MapCount = 0              --地图的总数
    self.MapLoadedCount = 0        --已加载地图数
    self.State = _STATE_INIT       --状态:初始/地图加载完毕/玩家城市加载完毕

    --所有space的entity对应mb的哈希table
    self.MapPool = {}

    --空闲的副本区
    self.IdleSpecialMapPool = {}   --数据结构：{{base的mb, cell的mb}, ...}

    --正在启用的副本区
    self.BusySpecialMapPool = {}    --数据结构：{地图ID={分线ID={base的mb， cell的mb}, ...}, ...}

    self.SpaceLoaderCount = {}      --每一个分线里面有多少人，做成一个table对应，格式：{地图ID={分线ID=人数, ...}, ...}

    --记录全服总人数
    self.SumPlayerCount = 0

--    --记录每一个场景各个分线的总人数
--    self.ScenePlayerCount = {}

    --初始化各个场景对应的分线信息
    local MapData = g_map_mgr:getMapData()
    for sceneId, _ in pairs(MapData) do
        self.SpaceLoaderCount[sceneId] = {}
        self.BusySpecialMapPool[sceneId] = {}
    end

    log_game_debug('MapMgr:__ctor__', 'SpaceLoaderCount=%s;BusySpecialMapPool=%s',  mogo.cPickle(self.SpaceLoaderCount), mogo.cPickle(self.BusySpecialMapPool))

    self:RegisterGlobally("MapMgr", _map_mgr_register_callback(self:getId()))

end

--注册globalbase成功后回调方法
function MapMgr:on_registered()
    log_game_info("MapMgr:on_registered", "")
--    self:registerTimeSave('mysql') --注册定时存盘
    self:LoadAllSpace()

    self.State = _STATE_MAP_LOADING
end

--加载所有场景管理器
function MapMgr:LoadAllSpace()
    log_game_info('MapMgr:LoadAllSpace', '')

    --默认创建5000个地图map_id为空的spaceloader
    for i=1, _INIT_MAP_COUNT, 1 do
        mogo.createBaseAnywhere("SpaceLoader", {map_id=''})
    end

    self.MapCount = _INIT_MAP_COUNT
end

--一个地图加载完成之后的回调方法
function MapMgr:OnMapLoaded(SpaceLoaderEntityId, SpaceLoaderBaseMbStr, SpaceLoaderCellMbStr)

    local loaded_count = self.MapLoadedCount + 1
    local all_count = self.MapCount
    self.MapLoadedCount = loaded_count

    --log_game_debug("MapMgr.OnMapLoaded", "loaded_count=%d;all_count=%d;SpaceLoaderEntityId=%d;SpaceLoaderBaseMbStr=%s;SpaceLoaderCellMbStr=%s", loaded_count, all_count, SpaceLoaderEntityId, SpaceLoaderBaseMbStr, SpaceLoaderCellMbStr)

    self.MapPool[SpaceLoaderEntityId] = {SpaceLoaderBaseMbStr, SpaceLoaderCellMbStr }
    self.IdleSpecialMapPool[SpaceLoaderEntityId] = 1

    if loaded_count == all_count then
        self.State = _STATE_MAP_LOADED
        log_game_info("MapMgr._STATE_MAP_LOADED", "")

        --通知MapMgr加载完毕,Avatar加载完毕之后由UserMgr通知
        local gm = globalBases['GameMgr']
        if gm then
            gm.OnMgrLoaded('MapMgr')
        end
    end

end

function MapMgr:ChangeMapCount(flag, scene, line, count)

    if scene and line then
        local MapCount = self.SpaceLoaderCount[scene]
        if MapCount then
            if MapCount[line] then
                if flag == public_config.CHANGE_MAP_COUNT_ADD then
                    MapCount[line] = MapCount[line] + count

                    self.SumPlayerCount = self.SumPlayerCount + count

--                    local SceneCount = self.ScenePlayerCount[scene]
--                    if SceneCount then
--                        self.ScenePlayerCount[scene] = self.ScenePlayerCount[scene] + count
--                    else
--                        self.ScenePlayerCount[scene] = count
--                    end

                    log_game_debug("MapMgr:ChangeMapCount", "flag=%d;scene=%d;line=%d;count=%d;MapCount[line]=%d", flag, scene, line, count, MapCount[line])

                elseif flag == public_config.CHANGE_MAP_COUNT_SUB then
                    MapCount[line] = MapCount[line] - count

                    local SumPlayerCount = self.SumPlayerCount - count
                    if SumPlayerCount < 0 then
                        SumPlayerCount = 0
                    end

                    self.SumPlayerCount = SumPlayerCount
                    log_game_debug("MapMgr:ChangeMapCount", "flag=%d;scene=%d;line=%d;count=%d;MapCount[line]=%d", flag, scene, line, count, MapCount[line])

--                    local SceneCount = self.ScenePlayerCount[scene]
--                    if SceneCount then
--                        self.ScenePlayerCount[scene] = self.ScenePlayerCount[scene] - count
--                    else
--                        log_game_error("MapMgr:ChangeMapCount", "scene=%d", scene)
--                    end

                end

                if MapCount[line] < 0 then
                    MapCount[line] = 0
                end

                self.SpaceLoaderCount[scene] = MapCount
--                log_game_debug("MapMgr:ChangeMapCount", "flag=%d;scene=%d;line=%d;count=%d", flag, scene, line, MapCount[line])

            end

        else
            log_game_error("MapMgr:ChangeMapCount", "flag=%d;scene=%d;line=%d", flag, scene, line)
        end
    end
end

--从空闲副本池获取一个分线
function MapMgr:GetAIdleMap(targetSceneId, targetLine)
    for k, _ in pairs(self.IdleSpecialMapPool) do
        self.BusySpecialMapPool[targetSceneId] = self.BusySpecialMapPool[targetSceneId] or {}
        if self.BusySpecialMapPool[targetSceneId][targetLine] then
            log_game_warning("MapMgr:GetAIdleMap", "entityId=%d;targetSceneId=%d;targetLine=%d", self.BusySpecialMapPool[targetSceneId][targetLine], targetSceneId, targetLine)
            return self.MapPool[self.BusySpecialMapPool[targetSceneId][targetLine]]
        else
            self.BusySpecialMapPool[targetSceneId][targetLine] = k
            self.IdleSpecialMapPool[k] = nil
            return self.MapPool[k]
        end
    end
    return nil
end

function MapMgr:GetSpaceLoaderMb(sceneId, line)
    local mbs = self.BusySpecialMapPool[sceneId] or {}
    local entityId = mbs[line]
    if entityId then
        return self.MapPool[entityId]
    else
        log_game_warning("MapMgr:GetSpaceLoaderMb", "sceneId=%d;line=%d", sceneId, line)
        lua_util.traceback()
    end
end

--获取空闲副本的数量，用于判断是否需要新建副本
function MapMgr:GetIdleMapCount()
    local i = 0
    for _, _ in pairs(self.IdleSpecialMapPool) do
        i = i + 1
    end
    return i
end

function MapMgr:ExtendIdleMap()

    if self.State == _STATE_MAP_LOADING then
        return
    end

    local IdleMapCount = self:GetIdleMapCount()
    if IdleMapCount <= _INIT_MAP_COUNT * 0.2 then
        --当当前空闲分线的数量小于等于原空闲分线副本数量的80%时，开始新创建分线
        for i=1, _EXTEND_MAP_COUNT, 1 do
            mogo.createBaseAnywhere("SpaceLoader", {map_id=''})
        end

        self.State = _STATE_MAP_LOADING

        self.MapCount = self.MapCount + _EXTEND_MAP_COUNT
        log_game_debug("MapMgr:ExtendIdleMap", "self.MapCount=%d", self.MapCount)
    end
end

function MapMgr:CreateOblivionMapInstance(avarta_mb_str, gate_id, map_id, owner_dbid, owner_name, owner_level)
    local mb = mogo.UnpickleBaseMailbox(avarta_mb_str)
    local mapInfo = g_map_mgr:getMapCfgData(map_id)
    if not mb or not mapInfo then
        globalbase_call("OblivionGateMgr", "MgrEventDispatch", avarta_mb_str, "EventCreateGateComplete", {gate_id, 1}, "", "", {})
        return
    end

    if mapInfo['type'] ~= public_config.MAP_TYPE_OBLIVION then
        globalbase_call("OblivionGateMgr", "MgrEventDispatch", avarta_mb_str, "EventCreateGateComplete", {gate_id, 2}, "", "", {})
        return
    end

    local spaceLoaderData = self.SpaceLoaderCount[map_id]
    if spaceLoaderData then
        confirm(spaceLoaderData[gate_id] == nil, "此GateID已被占用(=%s)", gate_id)
    else
        self.SpaceLoaderCount[map_id] = {}
    end

    --从空闲分线池里面拿一个出来
    local sp = self:GetAIdleMap(map_id, gate_id)
    if not sp or sp == false then
        globalbase_call("OblivionGateMgr", "MgrEventDispatch", avarta_mb_str, "EventCreateGateComplete", {gate_id, 3}, "", "", {})
        return
    end
    sp = mogo.UnpickleBaseMailbox(sp[1])
    sp.SetMapId(avarta_mb_str, map_id, gate_id, owner_dbid, owner_name, {})
    self.SpaceLoaderCount[map_id][gate_id] = 1

    --获取管理器的MailBoxStr
    local oblivion_mb_str = mogo.cPickle(globalBases['OblivionGateMgr'])

    --初始化副本数据
    sp.InitData({oblivion_mb_str, owner_level})

    --判断是否需要创建space
    self:ExtendIdleMap()

    --创建成功
    globalbase_call("OblivionGateMgr", "MgrEventDispatch", avarta_mb_str, "EventCreateGateComplete", {gate_id, 0}, "", "", {})
end

function MapMgr:CreateDefensePvPMapInstance(game_id, map_id, players, maxLevel)
    local mapInfo = g_map_mgr:getMapCfgData(map_id)
    if not mapInfo then
        globalbase_call("DefensePvPMgr", "MgrEventDispatch", "", "EventCreateGameComplete", {game_id, 1}, "", "", {})
        return
    end

    if mapInfo['type'] ~= public_config.MAP_TYPE_DEFENSE_PVP then
        globalbase_call("DefensePvPMgr", "MgrEventDispatch", "", "EventCreateGameComplete", {game_id, 2}, "", "", {})
        return
    end

    local spaceLoaderData = self.SpaceLoaderCount[map_id]
    if spaceLoaderData then
        if spaceLoaderData[game_id] ~= nil then
            log_game_error("MapMgr:CreateDefensePvPMapInstance", "game_id(=%s) already used!", game_id)
            return
        end
    else
        self.SpaceLoaderCount[map_id] = {}
    end

    --从空闲分线池里面拿一个出来
    local sp = self:GetAIdleMap(map_id, game_id)
    if not sp or sp == false then
        globalbase_call("DefensePvPMgr", "MgrEventDispatch", "", "EventCreateGameComplete", {game_id, 3}, "", "", {})
        return
    end
    sp = mogo.UnpickleBaseMailbox(sp[1])
    sp.SetMapId("", map_id, game_id, 0, "", {})
    self.SpaceLoaderCount[map_id][game_id] = 1

    --获取管理器的MailBoxStr
    local defense_pvp_mb_str = mogo.cPickle(globalBases['DefensePvPMgr'])

    --初始化副本数据
    sp.InitData({[1] = defense_pvp_mb_str, [2] = players, [3] = maxLevel})

    --判断是否需要创建space
    self:ExtendIdleMap()

    --创建成功
    globalbase_call("DefensePvPMgr", "MgrEventDispatch", "", "EventCreateGameComplete", {game_id, 0}, "", "", {})
end

function MapMgr:CreateMirrorPvpMapInstance(avarta_mb_str, map_id, pvpInfo) --owner_dbid, owner_name
    local mb = mogo.UnpickleBaseMailbox(avarta_mb_str)
    if not mb then
        log_game_error("MapMgr:CreateMirrorPvpMapInstance", "")
        return
    end
    local mapInfo = g_map_mgr:getMapCfgData(map_id)
    if not mapInfo then
        --lua_util.globalbase_call("OblivionGateMgr", "MgrEventDispatch", avarta_mb_str, "EventCreateGateComplete", {gate_id, 1}, "", "", {})
        mb.EventDispatch('arenaSystem', 'HavedEnter', {{ret = 1, pvpType = pvpInfo.pvpType}})
        return
    end

    if mapInfo['type'] ~= public_config.MAP_TYPE_ARENA then
        --lua_util.globalbase_call("OblivionGateMgr", "MgrEventDispatch", avarta_mb_str, "EventCreateGateComplete", {gate_id, 2}, "", "", {})
        mb.EventDispatch('arenaSystem', 'HavedEnter', {{ret = 1, pvpType = pvpInfo.pvpType}})
        return
    end
    local MaxLine = 0    --现在的最大分线数
    local spaceLoaderData = self.SpaceLoaderCount[map_id]
    if not spaceLoaderData then
        self.SpaceLoaderCount[map_id] = {}
    else
        for imap, count in pairs(spaceLoaderData) do
            if imap > MaxLine then
                MaxLine = imap
            end
        end
    end
    --
    MaxLine = MaxLine + 1
    --从空闲分线池里面拿一个出来
    local sp = self:GetAIdleMap(map_id, MaxLine)
    if not sp or sp == false then
        --lua_util.globalbase_call("OblivionGateMgr", "MgrEventDispatch", avarta_mb_str, "EventCreateGateComplete", {gate_id, 3}, "", "", {})
        mb.EventDispatch('arenaSystem', 'HavedEnter', {{ret = 1, pvpType = pvpInfo.pvpType}})
        return
    end
    sp = mogo.UnpickleBaseMailbox(sp[1])
    sp.SetMapId(avarta_mb_str, map_id, MaxLine, pvpInfo.challenger, pvpInfo.challengerName, pvpInfo)
    --设置pvp信息
    --sp.SetPvpInfo(pvpInfo)

    self.SpaceLoaderCount[map_id][MaxLine] = 1

    mb.EventDispatch('arenaSystem', 'HavedEnter', {{ret = 0, pvpType = pvpInfo.pvpType}})
    --初始化副本数据
    --sp.InitData({oblivion_mb_str, owner_level})

    --判断是否需要创建space
    self:ExtendIdleMap()

    --创建成功
    --lua_util.globalbase_call("OblivionGateMgr", "MgrEventDispatch", avarta_mb_str, "EventCreateGateComplete", {gate_id, 0}, "", "", {})
end
function MapMgr:CreateDragonPvpMapInstance(mbStr, map_id, pvpInfo)
    local mb = mogo.UnpickleBaseMailbox(mbStr)
    if not mb then
        log_game_error("MapMgr:CreateDragonPvpMapInstance", "")
        return
    end
    local mapInfo = g_map_mgr:getMapCfgData(map_id)
    if not mapInfo then
        return
    end

    if mapInfo['type'] ~= public_config.MAP_TYPE_DRAGON then
        return
    end
    local MaxLine = 0    --现在的最大分线数
    local spaceLoaderData = self.SpaceLoaderCount[map_id]
    if not spaceLoaderData then
        self.SpaceLoaderCount[map_id] = {}
    else
        for imap, count in pairs(spaceLoaderData) do
            if imap > MaxLine then
                MaxLine = imap
            end
        end
    end
    
    MaxLine = MaxLine + 1
    --从空闲分线池里面拿一个出来
    local sp = self:GetAIdleMap(map_id, MaxLine)
    if not sp or sp == false then
        return
    end
    sp = mogo.UnpickleBaseMailbox(sp[1])
    sp.SetMapId(mbStr, map_id, MaxLine, pvpInfo.atker, pvpInfo.name, pvpInfo)
    --设置pvp信息
    --更新袭击次数
    mb.BaseUpdateRelateTimes(public_config.AVATAR_DRAGON_ATKTIMES)
    
    self.SpaceLoaderCount[map_id][MaxLine] = 1

    --判断是否需要创建space
    self:ExtendIdleMap()
end
function MapMgr:CreateTowerDefenceMapInstance(sceneId, line)
    local sp = self:GetAIdleMap(sceneId, line)
    --判断是否需要创建space
    self:ExtendIdleMap()

    sp = mogo.UnpickleBaseMailbox(sp[1])
    sp.SetMapId(mogo.cPickle(globalBases['ActivityMgr']), sceneId, line, 0, '', {})
end

--function MapMgr:SelectMapResp()
--end

function MapMgr:SelectMapReq(mbStr, map_id, line, dbid, name, params)

    local mb = mogo.UnpickleBaseMailbox(mbStr)
    local mapInfo = g_map_mgr:getMapCfgData(map_id)

    log_game_debug("MapMgr:SelectMapReq", "map_id=%d;line=%d;dbid=%q;name=%s;params=%s", map_id, line, dbid, name, mogo.cPickle(params))

    if mb and mapInfo then
        if mapInfo['type'] == public_config.MAP_TYPE_NORMAL or mapInfo['type'] == public_config.MAP_TYPE_MUTI_PLAYER_NOT_TEAM then
            --如果玩家进入一个普通地图，则需要选择一个分线，选择分线本身不会触发新创建分线
            local MapCount = self.SpaceLoaderCount[map_id]
            if MapCount then
                local MaxLine = 0    --现在的最大分线数

                for imap, count in pairs(MapCount) do

                    if imap > MaxLine then
                        MaxLine = imap
                    end

                   --找到一条分线，则分配该分线号
                    if count < mapInfo['maxPlayerNum'] then
                       --mb.SelectMapResp(imap)
                       --成功进入一条分线
                        local spaceLoaderMbs = self:GetSpaceLoaderMb(map_id, imap)
                        mb.SelectMapResp(map_id, imap, mogo.UnpickleBaseMailbox(spaceLoaderMbs[1]), mogo.UnpickleCellMailbox(spaceLoaderMbs[2]), dbid, params)

--                        self.SpaceLoaderCount[map_id][imap] = count + 1

                        log_game_debug("MapMgr:SelectMapReq 1", "map_id=%d;imap=%d;dbid=%q;name=%s;count=%d", map_id, imap, dbid, name, self.SpaceLoaderCount[map_id][imap])

                        return
                    else
                        log_game_warning("MapMgr:SelectMapReq full", "map_id=%d;imap=%d;count=%d;maxPlayerNum=%d", map_id, imap, count, mapInfo['maxPlayerNum'])
                    end
                end

                local TargetLine = 1
                for i=1, MaxLine+1 do
                    if not MapCount[i] then
                        TargetLine = i
                        break
                    end
                end

                --该地图的所有分线都已经不可进入，则从空闲分线池里面拿一个出来
                local sp = self:GetAIdleMap(map_id, TargetLine)
                if sp then
                    sp = mogo.UnpickleBaseMailbox(sp[1])

                    sp.SetMapId(mbStr, map_id, TargetLine, dbid, name, params)

--                    self.SpaceLoaderCount[map_id][TargetLine] = 1

                    log_game_debug("MapMgr:SelectMapReq 2", "map_id=%d;TargetLine=%d;dbid=%q;name=%s", map_id, TargetLine, dbid, name)

                    --判断是否需要创建space
                    self:ExtendIdleMap()
                else
                    --无法找到可进入副本分线
                    log_game_error("MapMgr:SelectMapReq -1", "map_id=%d;line=%d;dbid=%q;name=%s", map_id, line, dbid, name)
                end
            else
                --无法找到可进入副本分线
                log_game_error("MapMgr:SelectMapReq -2", "map_id=%d;line=%d;dbid=%q;name=%s", map_id, line, dbid, name)

            end

        --湮灭之门地图选择
        elseif mapInfo['type'] == public_config.MAP_TYPE_OBLIVION then
            --先从已经创建的分线中选择分线
            local spaceLoaderData = self.SpaceLoaderCount[map_id]
            if spaceLoaderData then
                local gateID = line
                if spaceLoaderData[gateID] then
                    --关卡分线已存在，切入地图
                    local spaceLoaderMbs = self:GetSpaceLoaderMb(map_id, gateID)
                    mb.SelectMapResp(map_id, gateID, mogo.UnpickleBaseMailbox(spaceLoaderMbs[1]), mogo.UnpickleCellMailbox(spaceLoaderMbs[2]), dbid, params)
                    return
                end
            end
            --无法找到可进入副本分线
            log_game_error("MapMgr:SelectMapReq oblivion", "map_id=%d;line=%d;dbid=%q;name=%s", map_id, line, dbid, name)

        --守护PvP地图选择
        elseif mapInfo['type'] == public_config.MAP_TYPE_DEFENSE_PVP then
            --先从已经创建的分线中选择分线
            local spaceLoaderData = self.SpaceLoaderCount[map_id]
            if spaceLoaderData then
                local gameID = line
                if spaceLoaderData[gameID] then
                    --关卡分线已存在，切入地图
                    local spaceLoaderMbs = self:GetSpaceLoaderMb(map_id, gameID)
                    mb.SelectMapResp(map_id, gameID, mogo.UnpickleBaseMailbox(spaceLoaderMbs[1]), mogo.UnpickleCellMailbox(spaceLoaderMbs[2]), dbid, params)
                    return
                end
            end
            --无法找到可进入副本分线
            log_game_error("MapMgr:SelectMapReq defense_pvp", "map_id=%d;line=%d;dbid=%q;name=%s", map_id, line, dbid, name)

        --世界boss分线选择
        elseif mapInfo['type'] == public_config.MAP_TYPE_WB then
            --先从已经创建的分线中选择分线
            local MapCount = self.SpaceLoaderCount[map_id]
            local MaxLine = 0

            if MapCount then
                for _line, _count in pairs(MapCount) do
                    if _count < mapInfo['maxPlayerNum'] then
                        --mb.SelectMapResp(map_id, _line, dbid, name)
                        --self.SpaceLoaderCount[map_id][_line] = _count + 1
                        local targetMapPool = self.BusySpecialMapPool[map_id]
                        if targetMapPool then
                            local sp = targetMapPool[_line]
                            if sp then
                                --到指定的副本检查是否允许进入
                                --sp = mogo.UnpickleBaseMailbox(sp[1])
                                log_game_debug("MapMgr:SelectMapReq 1", "map_id=%d;line=%d;dbid=%q;name=%s", map_id, _line, dbid, name)
                                --sp.CheckEnter(mbStr, dbid, name)
                                globalbase_call("WorldBossMgr", "CheckEnter", mbStr, map_id, _line, dbid, name)
                                return
                            else
                                log_game_error("MapMgr:SelectMapReq", "have count data but BusySpecialMapPool data.[%s][%s]", tostring(map_id), tostring(_line))
                            end
                        else
                            log_game_error("MapMgr:SelectMapReq", "have count data but BusySpecialMapPool data.[%s][%s]", tostring(map_id), tostring(_line))
                        end
                    end

                    if _line > MaxLine then MaxLine = _line end 
                end
            else
                self.SpaceLoaderCount[map_id] = {}
            end

            local TargetLine = MaxLine + 1

            --该地图的所有分线都已经不可进入，则从空闲分线池里面拿一个出来
            local sp = self:GetAIdleMap(map_id, TargetLine)
            if sp then
                sp = mogo.UnpickleBaseMailbox(sp[1])

                sp.SetMapId(mbStr, map_id, TargetLine, dbid, name, params)

                self.SpaceLoaderCount[map_id][TargetLine] = 0

                log_game_debug("MapMgr:SelectMapReq 2", "map_id=%d;line=%d;dbid=%q;name=%s", map_id, TargetLine, dbid, name)

                --判断是否需要创建space
                self:ExtendIdleMap()
            else
                --无法找到可进入副本分线
                log_game_error("MapMgr:SelectMapReq -1", "map_id=%d;line=%d;dbid=%q;name=%s", map_id, line, dbid, name)
            end
        else
            if line == 0 then
                --如果分线号为0，表示玩家想进入一个新副本
                local MapCount = self.SpaceLoaderCount[map_id]
                if MapCount then
                    local MaxLine = 0    --现在的最大分线数

                    for imap, count in pairs(MapCount) do
                        if imap > MaxLine then
                            MaxLine = imap
                        end
                    end

                    --获取目标分线号
                    local TargetLine = 1
                    for i=1, MaxLine+1 do
                        if not MapCount[i] then
                            TargetLine = i
                            break
                        end
                    end

                    --该地图的所有分线都已经不可进入，则从空闲分线池里面拿一个出来
                    local sp = self:GetAIdleMap(map_id, TargetLine)
                    if sp then
                        sp = mogo.UnpickleBaseMailbox(sp[1])

                        sp.SetMapId(mbStr, map_id, TargetLine, dbid, name, params)

                        self.SpaceLoaderCount[map_id][TargetLine] = 1

                        log_game_debug("MapMgr:SelectMapReq 4", "map_id=%d;TargetLine=%d;dbid=%q;name=%s", map_id, TargetLine, dbid, name)

                        --判断是否需要创建space
                        self:ExtendIdleMap()
                    else
                        --无法找到可进入副本分线
                        log_game_error("MapMgr:SelectMapReq -3", "map_id=%d;line=%d;dbid=%q;name=%s", map_id, line, dbid, name)
                    end
                else
                    --无法找到可进入副本分线
                    log_game_error("MapMgr:SelectMapReq -4", "map_id=%d;line=%d;dbid=%q;name=%s", map_id, line, dbid, name)
--                    --该地图的所有分线都已经不可进入，则从空闲分线池里面拿一个出来
--                    local sp = self:GetAIdleMap(map_id, 1)
--                    if sp then
--                        sp = mogo.UnpickleBaseMailbox(sp[1])
--
--                        sp.SetMapId(mbStr, map_id, 1, dbid, name)
--
--                        self.SpaceLoaderCount[map_id] = {[1] = 1}
--
--                        log_game_debug("MapMgr:SelectMapReq 5", "map_id=%d;TargetLine=%d;dbid=%q;name=%s", map_id, 1, dbid, name)
--
--                        --判断是否需要创建space
--                        self:ExtendIdleMap()
--                    else
--                        --无法找到可进入副本分线
--                        log_game_error("MapMgr:SelectMapReq -4", "map_id=%d;line=%d;dbid=%q;name=%s", map_id, line, dbid, name)
--                    end
                end
            elseif line > 0 then
                local targetMapPool = self.BusySpecialMapPool[map_id]
                if targetMapPool then
                    local sp = targetMapPool[line]
                    if sp then
                        --到指定的副本检查是否允许进入
                        sp = mogo.UnpickleBaseMailbox(sp[1])
                        sp.CheckEnter(mbStr, dbid, name)
                        return
                    end
                end

                --该角色想要进入的场景分线已经不存在了，直接把玩家送回王城
                local targetSceneId = g_GlobalParamsMgr:GetParams('init_scene', 10004)
                local mapInfo = g_map_mgr:getMapCfgData(targetSceneId)

                local MapCount = self.SpaceLoaderCount[targetSceneId]
                if MapCount then
                    local MaxLine = 0    --现在的最大分线数

                    for imap, count in pairs(MapCount) do

                        if imap > MaxLine then
                            MaxLine = imap
                        end

                       --找到一条分线，则分配该分线号
                        if count < mapInfo['maxPlayerNum'] then
                           --mb.SelectMapResp(imap)
                           --成功进入一条分线
                            local spaceLoaderMbs = self:GetSpaceLoaderMb(targetSceneId, imap)
                            mb.SelectMapResp(targetSceneId, imap, mogo.UnpickleBaseMailbox(spaceLoaderMbs[1]), mogo.UnpickleCellMailbox(spaceLoaderMbs[2]), dbid, params)

                            self.SpaceLoaderCount[targetSceneId][imap] = self.SpaceLoaderCount[targetSceneId][imap] + 1

                            log_game_debug("MapMgr:SelectMapReq 6", "map_id=%d;line=%d;imap=%d;dbid=%q;name=%s", targetSceneId, line, imap, dbid, name)

                            return
                        end
                    end

                    local TargetLine = 1
                    for i=1, MaxLine+1 do
                        if not MapCount[i] then
                            TargetLine = i
                            break
                        end
                    end

                    --该地图的所有分线都已经SpaceLoaderCount不可进入，则从空闲分线池里面拿一个出来
                    local sp = self:GetAIdleMap(targetSceneId, TargetLine)
                    if sp then
                        sp = mogo.UnpickleBaseMailbox(sp[1])

                        sp.SetMapId(mbStr, targetSceneId, TargetLine, dbid, name, params)

                        self.SpaceLoaderCount[targetSceneId][TargetLine] = 1

                        log_game_debug("MapMgr:SelectMapReq 7", "map_id=%d;line=%d;TargetLine=%d;dbid=%q;name=%s", targetSceneId, line, TargetLine, dbid, name)

                        --判断是否需要创建space
                        self:ExtendIdleMap()
                    else
                        --无法找到可进入副本分线
                        log_game_error("MapMgr:SelectMapReq -5", "map_id=%d;line=%d;dbid=%q;name=%s", targetSceneId, line, dbid, name)
                    end
                else
                    --该地图的所有分线都已经不可进入，则从空闲分线池里面拿一个出来
                    local sp = self:GetAIdleMap(targetSceneId, 1)
                    if sp then
                        sp = mogo.UnpickleBaseMailbox(sp[1])

                        sp.SetMapId(mbStr, targetSceneId, 1, dbid, name, params)

                        self.SpaceLoaderCount[targetSceneId] = self.SpaceLoaderCount[targetSceneId] or {[1] = 1}

                        log_game_debug("MapMgr:SelectMapReq 8", "map_id=%d;line=%d;TargetLine=%d;dbid=%q;name=%s", targetSceneId, line, 1, dbid, name)

                        --判断是否需要创建space
                        self:ExtendIdleMap()
                    else
                        --无法找到可进入副本分线
                        log_game_error("MapMgr:SelectMapReq -6", "map_id=%d;line=%d;dbid=%q;name=%s", targetSceneId, line, dbid, name)
                    end
                end	
            else
                --无法找到可进入副本分线
                log_game_error("MapMgr:SelectMapReq -7", "map_id=%d;line=%d;dbid=%q;name=%s", map_id, line, dbid, name)
            end
        end
    end

end

--function MapMgr:GetSpaceLoaderMbReq(mbStr, sceneId, line)
--
--    log_game_debug("MapMgr:GetSpaceLoaderMbReq", "mbStr=%s;sceneId=%d;line=%d", mbStr, sceneId, line)
--
--    self.BusySpecialMapPool[sceneId] = self.BusySpecialMapPool[sceneId] or {}
--    local sp = self.BusySpecialMapPool[sceneId][line]
--    if sp and sp[1] then
--        local mb = mogo.UnpickleBaseMailbox(mbStr)
--        mb.GetSpaceLoaderMbResp(sp[1])
--    else
--        log_game_error("MapMgr:GetSpaceLoaderMbReq", "mbStr=%s;sceneId=%d;line=%d", mbStr, sceneId, line)
--    end
--
--end

function MapMgr:CheckEnterResp(result, playerMbStr, map_id, line, dbid, name)

    local mb = mogo.UnpickleBaseMailbox(playerMbStr)
    if mb then

        if result < 0 then
            --该已打开的副本不属于该玩家，则需要把玩家传送到王城？
            if g_map_mgr:IsWBMap(map_id) then
                --如果是世界boss的场景跳转失败需要通知worldbossmgr
                --SelectMapFailResp(scene, line)
                mb.SelectMapFailResp(map_id, line)
            end

            local spaceLoaderMbs = self:GetSpaceLoaderMb(map_id, line)

            mb.SelectMapResp(g_GlobalParamsMgr:GetParams('init_scene', 10004), 1, mogo.UnpickleBaseMailbox(spaceLoaderMbs[1]), mogo.UnpickleCellMailbox(spaceLoaderMbs[2]), dbid, {})
            log_game_error("MapMgr:CheckEnterResp", "result=%d;map_id=%d;line=%d;dbid=%q;name=%s", result, map_id, line, dbid, name)
        else
            local spaceLoaderMbs = self:GetSpaceLoaderMb(map_id, line)
            --该打开的副本属于该玩家，则玩家重新进入副本
            mb.SelectMapResp(map_id, line, mogo.UnpickleBaseMailbox(spaceLoaderMbs[1]), mogo.UnpickleCellMailbox(spaceLoaderMbs[2]), dbid, {})
        end

    end

end

--function MapMgr:SelectIdleSpecialMap(map_id)
--
--    log_game_debug("MapMgr:SelectIdleSpecialMap", "map_id=%d", map_id)
--
--    --local mb = mogo.unpickleBaseMailbox(mbStr)
--
--    local IdleSpecialMap = self.IdleSpecialMapPool[map_id]
--    if IdleSpecialMap then
--        for imap, spaceLoaderMbStr in pairs(IdleSpecialMap) do
--            if self.IdleSpecialMapPool[map_id][imap] then
--                --把副本从空闲池里面删除掉
--                self.IdleSpecialMapPool[map_id][imap] = nil
--
--                --把副本移到启用池里面
--                local BuySpecialMap = self.BusySpecialMapPool[map_id]
--                if not BuySpecialMap then
--                    self.BusySpecialMapPool[map_id] = {}
--                end
--                self.BusySpecialMapPool[map_id][imap] = os.time()
--
--                log_game_debug("MapMgr:SelectIdleSpecialMap", "imap=%d", imap)
--                return imap
--
--                --mb.SelectMapResp(imap)
--                --return 0
--            end
--        end
--        log_game_error("MapMgr:SelectIdleSpecialMap", "imap=%d", -1)
--        return -1
--
--    end
--end

--function MapMgr:Teleport(playerBaseMbStr, playerCellMbStr, targetSceneId, targetX, targetY)
--    log_game_debug("MapMgr:Teleport", "playerCellMbStr=%s;targetSceneId=%d;targetX=%d;targetY=%d", playerCellMbStr, targetSceneId, targetX, targetY)
--
--    local playeCellrMb = mogo.UnpickleCellMailbox(playerCellMbStr)
--
----    local scene_teleport = lua_util.split_str(_des, "|")
--
----    local TargetScene = tonumber(scene_teleport[1])    --目标场景ID
----    local line  = scene_teleport[2]          --传送点所在的分线号
----    local des   = scene_teleport[3]          --传送点标识
--
--    local mapInfo = g_map_mgr:getMapCfgData(targetSceneId)
--
--    --获取分线号
--    if mapInfo then
--        if mapInfo['type'] == public_config.MAP_TYPE_NORMAL then
----            log_game_debug("MapMgr:Teleport normal", "")
--            --如果玩家进入一个普通地图，则需要选择一个分线，选择分线本身不会触发新创建分线
--            local line = self:SelectNormalMap(targetSceneId, mapInfo)
--            if line > 0 then
--                local target_map_id = tostring(targetSceneId) .. "_" .. tostring(line)
--
--                local TargetSpaceLoaderMbs = self.MapInfo[target_map_id]
----                log_game_debug("MapMgr:Teleport normal", "target_map_id=%s", target_map_id)
--                if TargetSpaceLoaderMbs then
--
--                    local TargetSpaceLoaderCellMb = mogo.UnpickleCellMailbox(TargetSpaceLoaderMbs[2])
----                    local TeleportPoinDes = globalBases[_des]
--
--                    if TargetSpaceLoaderCellMb then
--                        if playeCellrMb[public_config.MAILBOX_KEY_SERVER_ID] == TargetSpaceLoaderCellMb[public_config.MAILBOX_KEY_SERVER_ID] then
----                            log_game_debug("MapMgr:Teleport normal same cell", "target_map_id=%s", target_map_id)
--                            --同一个cell进程的跳转
--                            local sp_id = TargetSpaceLoaderCellMb[public_config.MAILBOX_KEY_ENTITY_ID]
--
--                            log_game_debug("MapMgr:Teleport normal same cell", "target_map_id=%s;sp_id=%d",
--                                                                                    target_map_id, sp_id)
----                            TeleportPoinDes.Teleport(playerCellMbStr, sp_id)
----                            local playerCellMb = mogo.UnpickleCellMailbox(playerCellMbStr)
--                            playeCellrMb.TelportSameCell(sp_id, targetX, targetY)
--
--                        else
--                            log_game_debug("MapMgr:Teleport normal different cell", "target_map_id=%s", target_map_id)
--                            --先到传送点获取x，y坐标回到base，再通知cell销毁
----                            local playerCellMb = mogo.UnpickleCellMailbox(playerCellMbStr)
--                            playeCellrMb.TeleportRemotely(targetSceneId, line, targetX, targetY)
--
--                        end
--                    end
--                else
--                    log_game_error("MapMgr:Teleport", "playerCellMbStr=%s;targetSceneId=%d;targetX=%d;targetY=%d", playerCellMbStr, targetSceneId, targetX, targetY)
--                end
--            else
--                log_game_error("MapMgr:Teleport", "playerCellMbStr=%s;targetSceneId=%d;targetX=%d;targetY=%d", playerCellMbStr, targetSceneId, targetX, targetY)
--            end
--        elseif mapInfo['type'] == public_config.MAP_TYPE_SPECIAL or
--               mapInfo['type'] == public_config.MAP_TYPE_SLZT or
--               mapInfo['type'] == public_config.MAP_TYPE_MUTI_PLAYER_NOT_TEAM then
----            log_game_debug("MapMgr:Teleport special", "")
--            local NewLine = self:SelectIdleSpecialMap(targetSceneId)
--            if NewLine > 0 then
--                local target_map_id = tostring(targetSceneId) .. "_" .. tostring(NewLine)
--
--                local TargetSpaceLoaderMbs = self.MapInfo[target_map_id]
----                log_game_debug("MapMgr:Teleport special", "target_map_id=%s", target_map_id)
--                if TargetSpaceLoaderMbs then
--
--                    local TargetSpaceLoaderCellMb = mogo.UnpickleCellMailbox(TargetSpaceLoaderMbs[2])
----                    local TeleportPoinDes = globalBases[(target_map_id .. des)]
--
--                    if TargetSpaceLoaderCellMb then
--                        if playeCellrMb[public_config.MAILBOX_KEY_SERVER_ID] == TargetSpaceLoaderCellMb[public_config.MAILBOX_KEY_SERVER_ID] then
----                            log_game_debug("MapMgr:Teleport special same cell", "target_map_id=%s", target_map_id)
--                            --同一个cell进程的跳转
--                            local sp_id = TargetSpaceLoaderCellMb[public_config.MAILBOX_KEY_ENTITY_ID]
--
--                            log_game_debug("MapMgr:Teleport special same cell", "target_map_id=%s;sp_id=%d;targetX=%d;targetY=%d", target_map_id, targetX, targetY)
--                            playeCellrMb.TelportSameCell(sp_id, targetX, targetY)
--
--                        else
--                            log_game_debug("MapMgr:Teleport special different cell", "target_map_id=%s", target_map_id)
--                            --先到传送点获取x，y坐标回到base，再通知cell销毁
----                            TeleportPoinDes.TeleportRemotely(playerBaseMbStr, TargetScene, NewLine)
--                            playeCellrMb.TeleportRemotely(targetSceneId, NewLine, targetX, targetY)
--
--                        end
--                    end
--                else
--                    log_game_error("MapMgr:Teleport", "playerCellMbStr=%s;targetSceneId=%d;targetX=%d;targetY=%d", playerCellMbStr, targetSceneId, targetX, targetY)
--                end
--            else
--                log_game_error("MapMgr:Teleport", "playerCellMbStr=%s;targetSceneId=%d;targetX=%d;targetY=%d", playerCellMbStr, targetSceneId, targetX, targetY)
--            end
--        end
--    end
--end

--function MapMgr:TeleportSpaceLoader(playerBaseMbStr, playerCellMbStr, sceneId, line)
--
--    log_game_debug("MapMgr:TeleportSpaceLoader", "playerBaseMbStr=%s;playerCellMbStr=%s;sceneId=%d;line=%d", playerBaseMbStr, playerCellMbStr, sceneId, line)
--
--    if not self.BusySpecialMapPool[sceneId] then
--        log_game_error("MapMgr:TeleportSpaceLoader", "playerBaseMbStr=%s;playerCellMbStr=%s;sceneId=%d;line=%d", playerBaseMbStr, playerCellMbStr, sceneId, line)
--    end
--
--    local SpaceLoader = self.BusySpecialMapPool[sceneId][line]
--    local MapCfgData = g_map_mgr:getMapCfgData(sceneId)
--    if SpaceLoader and MapCfgData then
--        local spaceLoaderCellMb = mogo.UnpickleCellMailbox(SpaceLoader[2])
--        local palyerCellMb = mogo.UnpickleCellMailbox(playerCellMbStr)
----        local scene_line = lua_util.split_str(map_id, "_", tonumber)
--        if palyerCellMb[public_config.MAILBOX_KEY_SERVER_ID] == spaceLoaderCellMb[public_config.MAILBOX_KEY_SERVER_ID] then
--
----            local sceneId = g_map_mgr:GetSrcMapId(map_id)
--            log_game_debug("MapMgr:TeleportSpaceLoader", "sceneId=%d", sceneId)
--            local MapCfgData = g_map_mgr:getMapCfgData(sceneId)
--
--            local sp_id = spaceLoaderCellMb[public_config.MAILBOX_KEY_ENTITY_ID]
--            local palyerBaseMb = mogo.UnpickleBaseMailbox(playerBaseMbStr)
--            palyerBaseMb.TelportSameCell(sp_id, sceneId, line, MapCfgData['enterX'], MapCfgData['enterY'])
--
--        else
--            local palyerBaseMb = mogo.UnpickleBaseMailbox(playerBaseMbStr)
--
--            log_game_debug("MapMgr:TeleportSpaceLoader", "sceneId=%d;line=%d", sceneId, line)
--
--            palyerBaseMb.TeleportRemotely(sceneId, line, MapCfgData['enterX'], MapCfgData['enterY'])
--        end
--    end
--
--end

function MapMgr:Reset(map_id)

    local scene_line = lua_util.split_str(map_id, "_", tonumber)

    local sceneId = scene_line[1]
    local line = scene_line[2]

    local entityId = self.BusySpecialMapPool[sceneId][line]

    self.BusySpecialMapPool[sceneId][line]=nil

    self.SpaceLoaderCount[sceneId][line]=nil

    self.IdleSpecialMapPool[entityId] = 1

    log_game_debug("MapMgr:Reset", "map_id=%s;sceneId=%d;line=%d;entityId=%d", map_id, sceneId, line, entityId)
--    self.SpaceLoaderCount[scene_line[1]][scene_line[2]] = nil

--    --从繁忙副本池里面删除掉
--    local BusySpecialMaps = self.BusySpecialMapPool[scene_line[1]]
--    if not BusySpecialMaps then
--        return
--    end
--
--    local BusySpacialMap = BusySpecialMaps[scene_line[2]]
--    if BusySpacialMap then
--        self.IdleSpecialMapPool[scene_line[1]][scene_line[2]] = true
--
--        self.BusySpecialMapPool[scene_line[1]][scene_line[2]] = nil
--
--    end
end

--function MapMgr:AddToBusyPool(scene_line)
--    log_game_debug("MapMgr:AddToBusyPool", "scene_line = %s", scene_line)
--    local sl = lua_util.split_str(scene_line, "_", tonumber)
--
--    if not self.IdleSpecialMapPool[sl[1]][sl[2]] then
--        return
--    end
--    self.IdleSpecialMapPool[sl[1]][sl[2]] = nil
--
--    --从繁忙副本池里面删除掉
--    local BusySpecialMaps = self.BusySpecialMapPool[sl[1]]
--    if not BusySpecialMaps then
--        self.BusySpecialMapPool[sl[1]] = {}
--    end
--    self.BusySpecialMapPool[sl[1]][sl[2]] = os.time()
--
--end


return MapMgr


