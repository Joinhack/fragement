
require "lua_util"
require "map_data"
require "public_config"
require "mission_config"
require "monster_data"

require "BasicPlayManager"
require "TowerPlayManager"
require "NormalPlayManager"
require "MultiPlayManager"
require "WorldBossPlayManager"
require "OblivionPlayManager"
require "ArenaPlayManager"
require "NewbiePlayManager"
require "TowerDefencePlayManager"
require "RandomPlayManager"
require "DragonPlayManager"
require "DefensePvPManager"

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_error = lua_util.log_game_error
local log_game_warning = lua_util.log_game_warning
local globalbase_call = lua_util.globalbase_call
local _splitStr = lua_util.split_str

local REGISTER_TO_MAP_MGR = 1

SpaceLoader = {}
--SpaceLoader.__index = SpaceLoader

setmetatable(SpaceLoader, {__index = BaseEntity} )

--------------------------------------------------------------------------------------

function SpaceLoader:__ctor__()
--    log_game_info("SpaceLoader:__ctor__", "map_id=%s;id=%d", self.map_id, self:getId() )
--    self:load_data()
    --加载场景数据
    self:CreateInNewSpace()

--    --初始化玩法逻辑
--    local src_map_id = g_map_mgr:GetSrcMapId(self.map_id)
--    local cfg = g_map_mgr:getMapCfgData(src_map_id)
--    if not cfg then
--        log_game_error("SpaceLoader:__ctor__", "map_id=%s", self.map_id)
--        return
--    end
--    if cfg['type'] == public_config.MAP_TYPE_SLZT then
--        self.BasePlayManager = TowerPlayManager.init()
--    elseif cfg['type'] == public_config.MAP_TYPE_SPECIAL then
--        self.BasePlayManager = BasicPlayManager.init()
--    elseif cfg['type'] == public_config.MAP_TYPE_MUTI_PLAYER_NOT_TEAM then
--        self.BasePlayManager = MultiPlayManager.init()
--    elseif cfg['type'] == public_config.MAP_TYPE_WB then
--        self.BasePlayManager = WorldBossPlayManager.init()
--    else
--        self.BasePlayManager = NormalPlayManager.init()
--    end
end

----加载场景数据
--function SpaceLoader:load_data()
--    log_game_info("SpaceLoader:load_data", "")
--    self:CreateInNewSpace()
--end

function SpaceLoader:onTimer(timer_id, user_data)
    if user_data == REGISTER_TO_MAP_MGR then
        log_game_warning("SpaceLoader:onTimer", "timer_id=%d;user_data=%d", timer_id, user_data)
        local mm = globalBases['MapMgr']
        if mm then
            log_game_warning("SpaceLoader:onTimer finish", "id=%d", self:getId())
            mm.OnMapLoaded(self:getId(), mogo.pickleMailbox(self), mogo.cPickle(self.cell))
            self:delTimer(self.registerTimerId)
        else
            log_game_warning("SpaceLoader:onTimer again", "id=%d", self:getId())
        end
    end
end

--cell创建好的回调方法
function SpaceLoader:onGetCell()
--    --将cell设为basedata
--    mogo.setBaseData(public_config.BASEDDATA_KEY_SPACELOADER_CELL, {[self.map_id]=mogo.cPickle(self.cell)})
--    log_game_debug("SpaceLoader:onGetCell", "map_id=%s", self.map_id)
    --原来的做法是把cell注册到basedata里面，现在则把它注册到MapMgr里
--    local mm = globalBases['MapMgr']
--    if mm then
--        mm.RegisterSpaceLoader(self.map_id, mogo.pickleMailbox(self), mogo.cPickle(self.cell))
--    end

--    log_game_debug("SpaceLoader:onGetCell", "")
    local mm = globalBases['MapMgr']
    if mm then
--        log_game_warning("SpaceLoader:onGetCell", "id=%d", self:getId())
        mm.OnMapLoaded(self:getId(), mogo.pickleMailbox(self), mogo.cPickle(self.cell))
    else
        log_game_warning("SpaceLoader:onGetCell", "self.registerTimerId=%d;id=%d", self.registerTimerId, self:getId())
        self.registerTimerId = self:addTimer(1, 1, REGISTER_TO_MAP_MGR)
    end

    --winj test 注册到WorldBossMgr todo:判断是否是世界boss地图
    --[[
    if g_map_mgr:IsWBMap(self.map_id) then
        log_game_debug('SpaceLoader:onGetCell', '')
        local mgr = globalBases['WorldBossMgr']
        if mgr then
            mgr.Register(self.map_id, mogo.pickleMailbox(self), mogo.cPickle(self.cell))
        end
    end 
    ]]
--    --当cell创建好以后在调用该方法注册globalbase和创建传送点等实体
--    self:OnMapLoaded()

end

--玩家掉线重登
function SpaceLoader:onMultiLogin(dbid)
    log_game_debug("SpaceLoader:onMultiLogin", "self.map_id=%s;dbid=%q", self.map_id, dbid)
    if self.BasePlayManager then
        self.BasePlayManager:onMultiLogin(dbid, self)
    end
end

--function SpaceLoader:OnMapLoaded()
--    log_game_debug("SpaceLoader:OnMapLoaded", "map_id=%s", self.map_id)
--
--    local mm = globalBases['MapMgr']
--    if mm then
--        mm.OnMapLoaded(self.map_id)
--    end

--    local function _sl_mgr_register_callback(ret)
--
--        if ret ~= 1 then
--            log_game_error("SpaceLoader:OnMapLoaded register fail", "map_id=%s", self.map_id)
--            return
--        end
--
--        local mm = globalBases['MapMgr']
--        if mm then
--            mm.OnMapLoaded(self.map_id)
--        end

--        --创建TeleportPointDes和TelportPointSrc
--        local src_map_id = g_map_mgr:GetSrcMapId(self.map_id)
--        local sp = globalBases['SpaceLoader_' .. self.map_id]
--        if src_map_id ~= nil and sp ~= nil then
--        local map_entity_cfg_data = g_map_mgr:GetMapEntityCfgData(src_map_id)
--            if map_entity_cfg_data ~= nil then
--                for i, v in pairs(map_entity_cfg_data) do
--                    if v['type'] == 'TeleportPointSrc' then
--                        --local tbl = {}
--                        --table.insert(tbl, v['targetSceneId'])
--                        --table.insert(tbl, string.sub(self.map_id, -1))
--                        --table.insert(tbl, v['des'])
--                        local entity = mogo.createBase(v['type'],
--                                                      {map_id=self.map_id;map_x=v['posx'];map_y=v['posy'];
--                                                       targetSceneId=v['targetSceneId'];
--                                                       targetX=v['targetX'];
--                                                       targetY=v['targetY']})
--                        if entity ~= nil then
--                            entity:CreateCellEntity(sp, v['posx'], v['posy'])
--                        end
--                        --log_game_debug("SpaceLoader:Entity", "src_map_id=%s;type=%s", src_map_id, v['type'])
--
--                    end
--                end
--            end
--        end
--    end

--    --注册到globalbase
--    local key = string.format("SpaceLoader_%s", self.map_id)
--    --log_game_debug("SpaceLoader:OnMapLoaded", "key=%s", key)
--
--    self:RegisterGlobally(key, _sl_mgr_register_callback)
--end

function SpaceLoader:getMapMonsterInfo(difficult, vocation)
    --找map 找SpawnPointLevel 找monster 找drop
    local tblDst = {{}, {}, 0, 0}--怪物表：monsterId<=>num 奖励表：itemId<=>num 金钱累计：0 经验累计：0
    local src_map_id = g_map_mgr:GetSrcMapId(self.map_id)
    if src_map_id ~= nil then
        local map_entity_cfg_data = g_map_mgr:GetMapEntityCfgData(src_map_id)
        if map_entity_cfg_data ~= nil then
            for i, v in pairs(map_entity_cfg_data) do
                if v['type'] == 'SpawnPoint' then
                    local levelID = _splitStr(v['levelID'], ",", tonumber)
                    local tarDifficultSpawnPointLevel = levelID[difficult]
                    if tarDifficultSpawnPointLevel ~= nil then
                        g_monster_mgr:getSpawnPointLevelCfgInfoById(tblDst, tarDifficultSpawnPointLevel)
                    end
                end
            end
        end
    end

    for monsterId, num in pairs(tblDst[1]) do
        local tmpMonsterCfgData = g_monster_mgr:getCfgById(monsterId)
        if tmpMonsterCfgData then
            --经验累加
            tblDst[4] = tblDst[4] + num * tmpMonsterCfgData.exp
            --道具获得（包括金钱）
                for index = 1, num do--逐个怪逐数量
                    local vocationDropRecordId = tmpMonsterCfgData.dropId[vocation]
                    for index=1, #vocationDropRecordId, 2 do
                        local tmpRandom = math.random(1, 10000)
                        if tmpRandom < vocationDropRecordId[index+1] then
                            g_drop_mgr:GetAwards(tblDst[2], vocationDropRecordId[index])

                            local dropCfgData = g_drop_mgr:getCfgById(vocationDropRecordId[index]) 
                            if dropCfgData then
                                --累计获得游戏币
                                local goldNum = tblDst[2][0]
                                if goldNum and goldNum > 0 then
                                    for index = 1, goldNum do
                                        local tmpGold = math.random(dropCfgData['goldMin'], dropCfgData['goldMax'])
                                        if tmpGold > 0 then
                                            tblDst[3] = tblDst[3] + tmpGold
                                        end
                                    end
                                    tblDst[2][0] = 0
                                end
                            end
                        end--if
                    end--for
                end
        end
    end

    tblDst[2][0] = nil--金钱次数没用了删掉
--    log_game_info('getMapMonsterInfo', '%s', mogo.cPickle(tblDst))
    return tblDst
end

----需要分线的普通场景设置玩家人数已达上限标记
--function SpaceLoader:set_avatar_max_flag(flag)
--    --这里不做记录,直接广播给basedata
--    mogo.setBaseData(public_config.BASEDDATA_KEY_SP_MAX_FLAG, {[self.map_id]=flag})
--end

function SpaceLoader:SetMapId(mbStr, sceneId, line, dbid, name, params)
    log_game_debug("SpaceLoader:SetMapId", "mbStr=%s;sceneId=%d;line=%d;dbid=%q;name=%s;params=%s", mbStr, sceneId, line, dbid, name, mogo.cPickle(params))

    self.map_id = sceneId .. '_' .. line

    if params['type'] then
        if params['type'] == public_config.MAP_TYPE_SLZT then
            self.BasePlayManager = TowerPlayManager.init()
        elseif params['type'] == public_config.MAP_TYPE_OBLIVION then
            self.BasePlayManager = OblivionPlayManager:init(self, line, sceneId)
        elseif params['type'] == public_config.MAP_TYPE_SPECIAL then
            self.BasePlayManager = BasicPlayManager.init()
        elseif params['type'] == public_config.MAP_TYPE_MUTI_PLAYER_NOT_TEAM then
            self.BasePlayManager = MultiPlayManager.init()
        elseif params['type'] == public_config.MAP_TYPE_WB then
            self.BasePlayManager = WorldBossPlayManager:init(self, sceneId)
        elseif params['type'] == public_config.MAP_TYPE_ARENA then
            self.BasePlayManager = ArenaPlayManager:init(self, params)
        elseif params['type'] == public_config.MAP_TYPE_NEWBIE then
            self.BasePlayManager = NewbiePlayManager.init()
        elseif params['type'] == public_config.MAP_TYPE_TOWER_DEFENCE then
            self.BasePlayManager = TowerDefencePlayManager:init(self)
        elseif params['type'] == public_config.MAP_TYPE_DRAGON then
            self.BasePlayManager = DragonPlayerManager:init(self, dbid, params)
        elseif params['type'] == public_config.MAP_TYPE_RANDOM then
            self.BasePlayManager = RandomPlayManager.init()
        elseif params['type'] == public_config.MAP_TYPE_DEFENSE_PVP then
            self.BasePlayManager = DefensePvPManager:init(line)
        elseif params['type'] == public_config.MAP_TYPE_MWSY then
            self.BasePlayManager = BasicPlayManager.init()
        else
            self.BasePlayManager = NormalPlayManager.init()
        end
    else
        local cfg = g_map_mgr:getMapCfgData(sceneId)
        if not cfg then
            log_game_error("SpaceLoader:SetMapId", "map_id=%s", self.map_id)
            return
        end

        if cfg['type'] == public_config.MAP_TYPE_SLZT then
            self.BasePlayManager = TowerPlayManager.init()
        elseif cfg['type'] == public_config.MAP_TYPE_OBLIVION then
            self.BasePlayManager = OblivionPlayManager:init(mbStr, line)
        elseif cfg['type'] == public_config.MAP_TYPE_SPECIAL then
            self.BasePlayManager = BasicPlayManager.init()
        elseif cfg['type'] == public_config.MAP_TYPE_MUTI_PLAYER_NOT_TEAM then
            self.BasePlayManager = MultiPlayManager.init()
        elseif cfg['type'] == public_config.MAP_TYPE_WB then
            self.BasePlayManager = WorldBossPlayManager:init(self)
        elseif cfg['type'] == public_config.MAP_TYPE_ARENA then
            self.BasePlayManager = ArenaPlayManager:init(mbStr, dbid, params)
        elseif cfg['type'] == public_config.MAP_TYPE_NEWBIE then
            self.BasePlayManager = NewbiePlayManager:init()
        elseif cfg['type'] == public_config.MAP_TYPE_TOWER_DEFENCE then
            self.BasePlayManager = TowerDefencePlayManager:init()
        elseif cfg['type'] == public_config.MAP_TYPE_DRAGON then
            self.BasePlayManager = DragonPlayManager:init(mbStr, dbid, params)
        elseif cfg['type'] == public_config.MAP_TYPE_RANDOM then
            self.BasePlayManager = RandomPlayManager.init()
        elseif cfg['type'] == public_config.MAP_TYPE_DEFENSE_PVP then
            self.BasePlayManager = DefensePvPManager:init(line)
        elseif cfg['type'] == public_config.MAP_TYPE_MWSY then
            self.BasePlayManager = BasicPlayManager.init()
        else
            self.BasePlayManager = NormalPlayManager.init()
        end
    end

    self.cell.SetMapId(mbStr, sceneId, line, dbid, name, params)

--    local mb = mogo.UnpickleBaseMailbox(mbStr)
--    if mb then
--        mb.SelectMapResp(sceneId, line, dbid, name)
--    end

end

function SpaceLoader:ChangeMapCount(flag, count)
    local mm = globalBases['MapMgr']
    if mm then
        log_game_debug("SpaceLoader:ChangeMapCount", "flag=%d;map_id=%s;count=%d", flag, self.map_id, count)
        mm.ChangeMapCount(flag, self.map_id, count)
    end
end

function SpaceLoader:Open()
    self.BasePlayManager:Open(self.map_id)
end

function SpaceLoader:InitData(params_tab)
    self.BasePlayManager:InitData(params_tab[1], params_tab[2], params_tab[3], params_tab[4])
    self.cell.InitData(params_tab)
end

function SpaceLoader:Start(_StartTime)
    self.BasePlayManager:Start(_StartTime, self)
end

function SpaceLoader:StartByServer(_StartTime)
    log_game_debug("SpaceLoader:StartByServer", "self.map_id = %s", self.map_id)
    if self.BasePlayManager then
        self.BasePlayManager:StartByServer(_StartTime, self)
    end
end

function SpaceLoader:Stop()
    self.BasePlayManager:Stop(self)
end

function SpaceLoader:CheckEnter(mbStr, dbid, name)
    self.BasePlayManager:CheckEnter(mbStr, dbid, name, self.map_id)
end

function SpaceLoader:OnDataReseted()
    log_game_debug("SpaceLoader:OnDataReseted", "map_id=%s", self.map_id)
end

function SpaceLoader:SetMissionInfo(playerDbid, playerName, playerMbStr, missionId, difficult)
    if self.BasePlayManager then
        self.BasePlayManager:SetMissionInfo(playerDbid, playerName, playerMbStr, missionId, difficult, self)
    else
        log_game_error("SpaceLoader:SetMissionInfo", "playerDbid=%q;playerName=%s;playerMbStr=%s;missionId=%d;difficult=%d", playerDbid, playerName, playerMbStr, missionId, difficult)
    end
end

function SpaceLoader:Restart(playerDbid, playerName, playerMbStr, missionId, difficult)
    self.BasePlayManager:Restart(playerDbid, playerName, playerMbStr, missionId, difficult, self)
end

function SpaceLoader:Reset()
    self.BasePlayManager:Reset(self.map_id)

    self.BasePlayManager = nil
end

function SpaceLoader:SpawnPointEvent(EventId, dbid, avatar_x, avatar_y, SpawnPointId)
    self.BasePlayManager:SpawnPointEvent(EventId, dbid, avatar_x, avatar_y, SpawnPointId, self)
end

function SpaceLoader:GetMissionRewards(PlayerDbid)
    self.BasePlayManager:GetMissionRewards(PlayerDbid, self)
end

function SpaceLoader:onClientDeath(PlayerDbid)
    if self.BasePlayManager then
        self.BasePlayManager:onClientDeath(PlayerDbid, self)
    else
        log_game_error("SpaceLoader:onClientDeath", "PlayerDbid=%q;map_id=%s", PlayerDbid, self.map_id)
    end
end

function SpaceLoader:WorldBossDie(killerId)
    self.BasePlayManager:WorldBossDie(killerId)
end
--------------------------------------------------------------------------------------
function SpaceLoader:UpdateWBRankList(rankList)
    self.BasePlayManager:UpdateWBRankList(rankList)
end

function SpaceLoader:Summon(spawnId, mod)
    if self.BasePlayManager then
        self.BasePlayManager:Summon(spawnId, mod, self)
    else
        log_game_error("SpaceLoader:Summon", "spawnId=%d;mod=%d;map_id=%s", spawnId, mod, self.map_id)
    end
end

function SpaceLoader:ExitMission(dbid)
    if self.BasePlayManager then
        self.BasePlayManager:ExitMission(dbid, self)
    else
        log_game_error("SpaceLoader:ExitMission", "dbid=%q;map_id=%s", dbid, self.map_id)
    end
end

function SpaceLoader:QuitMission(dbid)
    if self.BasePlayManager then
        self.BasePlayManager:QuitMission(dbid, self)
    else
        log_game_error("SpaceLoader:QuitMission", "dbid=%q;map_id=%s", dbid, self.map_id)
    end
end

function SpaceLoader:KickAllPlayer()
    if self.BasePlayManager then
        self.BasePlayManager:KickAllPlayer(self)
    else
        log_game_error("SpaceLoader:KickAllPlayer", "map_id=%s", self.map_id)
    end
end

function SpaceLoader:AddFriendDegree(selfDbid, mercenaryDbid)
    self.cell.AddFriendDegree(selfDbid, mercenaryDbid)
end

function SpaceLoader:AddFinishedSpawnPoint(SpawnPointId)
--    log_game_debug("SpaceLoader:AddFinishedSpawnPoint", "SpawnPointId=%d", SpawnPointId)
    if self.BasePlayManager then
        self.BasePlayManager:AddFinishedSpawnPoint(SpawnPointId)
    else
        log_game_error("SpaceLoader:AddFinishedSpawnPoint", "SpawnPointId=%d;map_id=%s", SpawnPointId, self.map_id)
    end
end

function SpaceLoader:DeathEvent(dbid)
    self.BasePlayManager:DeathEvent(dbid)
end

function SpaceLoader:CreateClientDrop(mbStr, DropId, x, y)
--    log_game_debug("SpaceLoader:CreateClientDrop", "mbStr=%s;DropId=%d;x=%d;y=%d", mbStr, DropId, x, y)
    if self.BasePlayManager then
        self.BasePlayManager:CreateClientDrop(self, mbStr, DropId, x, y)
    else
        log_game_error("SpaceLoader:CreateClientDrop", "mbStr=%s;DropId=%d;x=%d;y=%d", mbStr, DropId, x, y)
    end
end

function SpaceLoader:PlayerLeave(dbid)
    self.BasePlayManager:PlayerLeave(dbid)
end

function SpaceLoader:Chat(ChannelId, to_dbid, msg)
    if self.BasePlayManager then
        self.BasePlayManager:Chat(ChannelId, to_dbid, msg)
    end
end

return SpaceLoader


