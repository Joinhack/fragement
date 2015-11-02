
require "lua_util"
require "public_config"
require "state_config"
require "map_data"

local log_game_debug = lua_util.log_game_debug
local log_game_error = lua_util.log_game_error
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local globalbase_call = lua_util.globalbase_call

SceneSystem = {}
SceneSystem.__index = SceneSystem

function SceneSystem:EnterTeleportpointReq(avatar, tp_eid)

--     if avatar:HasCell() then
--         avatar.cell.EnterTeleportpointReq(tp_eid)
--     end

    log_game_debug("SceneSystem:EnterTeleportpointReq", "dbid=%q;name=%s;tp_eid=%d;sceneId=%d", avatar.dbid, avatar.name, tp_eid, avatar.sceneId)

    local map_entity_cfg_data = g_map_mgr:GetMapEntityCfgData(avatar.sceneId)

    if map_entity_cfg_data then
        for i, v in pairs(map_entity_cfg_data) do
--            lua_util.log_game_debug("SceneSystem:EnterTeleportpointReq", "dbid=%q;name=%s;tp_eid=%d;i=%d;v=%s", 
--                                                                          avatar.dbid, avatar.name, tp_eid, i, mogo.cPickle(v))
            if v['type'] == 'TeleportPointSrc' and i == tp_eid then
                self:TeleportCell2Base(avatar, tonumber(v['targetSceneId']), tonumber(v['targetX']), tonumber(v['targetY']))
            end
        end
    end

    return 0

end

function SceneSystem:TeleportCell2Base(avatar, targetSceneId, targetX, targetY)

    log_game_debug("SceneSystem:TeleportCell2Base", "dbid=%q;name=%s;sceneId=%d;targetSceneId=%d;targetX=%d;targetY=%d", avatar.dbid, avatar.name, avatar.sceneId, targetSceneId, targetX, targetY)

    if avatar.sceneId == targetSceneId then
        --同一个场景传送
        avatar.cell.TelportLocally(targetX, targetY)
--        local TeleportPoinDes = globalBases[des]
--        if TeleportPoinDes then
--            TeleportPoinDes.Teleport(mogo.cPickle(self.ptr.theOwner.cell), 0)
--        else
--            lua_util.log_game_error("SceneSystem:TeleportCell2Base", "avatar.sceneId=%d;scene=%d;des=%s",
--                                                                      self.ptr.theOwner.sceneId, scene, des)
--        end
    else
        --先把跨场景传送的分支屏蔽掉
        log_game_warning("SceneSystem:TeleportCell2Base", "dbid=%q;name=%s;sceneId=%d;targetSceneId=%d;targetX=%d;targetY=%d", avatar.dbid, avatar.name, avatar.sceneId, targetSceneId, targetX, targetY)
--        --不同场景，则需要到MapMgr里面判断是否同一个cell进程
--        globalbase_call("MapMgr", "Teleport", avatar.base_mbstr, mogo.cPickle(avatar.cell), targetSceneId, targetX, targetY)
    end

end

function SceneSystem:TeleportRemotely(avatar, spaceMb, sceneId, line, x, y)

    local tmp_data = avatar.tmp_data
    tmp_data[public_config.TMP_DATA_KEY_SPACE_MB] = spaceMb
    tmp_data[public_config.TMP_DATA_KEY_TELEPORT_MAP] = sceneId
    tmp_data[public_config.TMP_DATA_KEY_TELEPORT_LINE] = line
    tmp_data[public_config.TMP_DATA_KEY_TELEPORT_X] = x
    tmp_data[public_config.TMP_DATA_KEY_TELEPORT_Y] = y

    --设置玩家处于传送状态
    local avatar_state = avatar.state
    avatar.state = mogo.sset(avatar_state, state_config.STATE_IN_TELEPORT)

    log_game_info("SceneSystem:TeleportRemotely", "dbid=%q;name=%s;id=%d;spaceMb=%s;x=%d;y=%d", avatar:getDbid(), avatar.name, avatar:getId(), mogo.cPickle(spaceMb), x, y)

--    --先赋值，再跳转，否则会出现场景id切换的问题
--    avatar.sceneId = sceneId
--    avatar.imap_id = line

    --销毁cell部分，由onLoseCell重建
    avatar:DestroyCellEntity()

end

--创建cell部分
function SceneSystem:CreateCell(avatar, spBaseMb)
--    local sp = globalBases['SpaceLoader_' .. map_id .. "_" .. imap_id]
--    if sp then
--        lua_util.log_game_info("SceneSystem:CreateCell", "id=%d;map=%d;imap_id=%d;x=%d;y=%d", self.ptr.theOwner:getId(), map_id, imap_id, x, y)
--        self.ptr.theOwner.tmp_data[public_config.TMP_DATA_KEY_CREATING_CELL] = 1
--
--        self.ptr.theOwner:CreateCellEntity(sp, x, y)
--    end
    avatar:CreateCellEntity(spBaseMb, avatar.map_x, avatar.map_y)

end

--玩家失去cell
function SceneSystem:onLoseCell(avatar)
    --设置了退出标记
    if avatar.tmp_data[public_config.TMP_DATA_KEY_QUIT_FLAG] ~= public_config.TMP_DATA_QUIT_MODE_NOEN then
        avatar:real_quit()
        return
    end

    if mogo.stest(avatar.state, state_config.STATE_IN_TELEPORT) == 0 then
        return
    end

    local tmp_data = avatar.tmp_data
    local spaceMb = tmp_data[public_config.TMP_DATA_KEY_SPACE_MB]
    local x = tmp_data[public_config.TMP_DATA_KEY_TELEPORT_X]
    local y = tmp_data[public_config.TMP_DATA_KEY_TELEPORT_Y]

    log_game_debug("SceneSystem:onLoseCell", "dbid=%q;name=%s;spaceMb=%s;x=%d;y=%d", avatar.dbid, avatar.name, mogo.cPickle(spaceMb), x, y)

    avatar.map_x = x
    avatar.map_y = y

    --重新创建新的cell
    self:CreateCell(avatar, spaceMb)

end

--玩家获得cell
function SceneSystem:onGetCell(avatar)
    avatar.tmp_data[public_config.TMP_DATA_KEY_CREATING_CELL] = nil

    local state = avatar.tmp_data[public_config.TMP_DATA_KEY_QUIT_FLAG]
    --设置了退出标记
    if state ~= public_config.TMP_DATA_QUIT_MODE_NOEN then
        self:quit_if_has_cell(avatar, state)
        return
    end

    if mogo.stest(avatar.state, state_config.STATE_IN_TELEPORT) == 0 then
        return
    end

    self:on_teleport_suc_resp(avatar)
end


--传送成功的回调,参数:map_id,x,y
function SceneSystem:on_teleport_suc_resp(avatar)
    local tmp_data = avatar.tmp_data

    --设置了退出标记
    if tmp_data[public_config.TMP_DATA_KEY_QUIT_FLAG] ~= public_config.TMP_DATA_QUIT_MODE_NOEN then
        self:quit_if_has_cell(avatar, tmp_data[public_config.TMP_DATA_KEY_QUIT_FLAG])
        return
    end

    local spaceMb = tmp_data[public_config.TMP_DATA_KEY_SPACE_MB]
    local sceneId = tmp_data[public_config.TMP_DATA_KEY_TELEPORT_MAP]
    local line = tmp_data[public_config.TMP_DATA_KEY_TELEPORT_LINE]
    local x = tmp_data[public_config.TMP_DATA_KEY_TELEPORT_X]
    local y = tmp_data[public_config.TMP_DATA_KEY_TELEPORT_Y]

    log_game_debug("teleport_suc", "dbid=%d;name=%s;id=%d;spaceMb=%s;x=%d;y=%d;map_x=%d;map_y=%d", avatar.dbid, avatar.name, avatar:getId(), mogo.cPickle(spaceMb), x, y, avatar.map_x, avatar.map_y)

    --记录新的数据
    --玩家是在跨cell进程之间跳转，则由这个函数负责同步场景、分线id给客户端
    avatar.sceneId = sceneId
    avatar.imap_id = line
    avatar.map_x = x
    avatar.map_y = y
    avatar.state = mogo.sunset(avatar.state, state_config.STATE_IN_TELEPORT)

    --清除临时数据
    tmp_data[public_config.TMP_DATA_KEY_SPACE_MB] = nil
    tmp_data[public_config.TMP_DATA_KEY_TELEPORT_MAP] = nil
    tmp_data[public_config.TMP_DATA_KEY_TELEPORT_LINE] = nil
    tmp_data[public_config.TMP_DATA_KEY_TELEPORT_X] = nil
    tmp_data[public_config.TMP_DATA_KEY_TELEPORT_Y] = nil
--    --如果是打坐状态的话重设为默认状态
--    avatar:reset_action_state()


end

--传送失败的回调
function SceneSystem:on_teleport_fail_resp(avatar)
    local tmp_data = avatar.tmp_data

    --设置了退出标记
    if tmp_data[public_config.TMP_DATA_KEY_QUIT_FLAG] ~= public_config.TMP_DATA_QUIT_MODE_NOEN then
        self:quit_if_has_cell(avatar, tmp_data[public_config.TMP_DATA_KEY_QUIT_FLAG])
        return
    end

    local map_id = tmp_data[public_config.TMP_DATA_KEY_TELEPORT_MAP]
    local x = tmp_data[public_config.TMP_DATA_KEY_TELEPORT_X]
    local y = tmp_data[public_config.TMP_DATA_KEY_TELEPORT_Y]

    avatar.state = mogo.sunset(avatar.state, state_config.STATE_IN_TELEPORT)

    --清除临时数据
    tmp_data[public_config.TMP_DATA_KEY_TELEPORT_MAP] = nil
    tmp_data[public_config.TMP_DATA_KEY_TELEPORT_X] = nil
    tmp_data[public_config.TMP_DATA_KEY_TELEPORT_Y] = nil

    log_game_info("teleport_fail", "id=%d;map=%d;x=%d;y=%d", avatar:getId(), map_id, x, y)
end


--玩家有cell情况下的退出流程
function SceneSystem:quit_if_has_cell(avatar, flag)
    lua_util.log_game_debug("quit_if_has_cell","*******************")
    if avatar.tmp_data[public_config.TMP_DATA_KEY_QUIT_FLAG] == flag then
        log_game_error("quit_if_has_cell", "on destroying.")
        return
    end

    avatar.tmp_data[public_config.TMP_DATA_KEY_QUIT_FLAG] = flag   --设退出标记

    if mogo.stest(avatar.state, state_config.STATE_IN_TELEPORT) == 0 then
        avatar:DestroyCellEntity()
    --else
        --玩家正在teleport中,什么都不做,等待
    end
end

--创建cell过程中又有退出请求的退出流程
function SceneSystem:quit_if_creating_cell(avatar, flag)
    log_game_debug("quit_if_creating_cell","*******************")
    avatar.tmp_data[public_config.TMP_DATA_KEY_QUIT_FLAG] = flag   --设退出标记
    --什么都不做,等待
end

----回城
--function SceneSystem:TownPortal(avatar)
--    local owner = avatar
--    local mm = globalBases["MapMgr"]
--    if mm and owner then
--        lua_util.log_game_debug("SceneSystem:TownPortal", "dbid[%d]",owner.dbid)
----        self.ptr.theOwner.state = mogo.sset(self.ptr.theOwner.state, public_config.STATE_IN_TELEPORT)
--        mm.SelectMapReq(owner.base_mbstr, g_GlobalParamsMgr:GetParams('init_scene', 10004), 
--            0, owner.dbid, owner.name)
--    else
--        lua_util.log_game_error("SceneSystem:TownPortal", "")
--    end
--end

gSceneSystem = SceneSystem
return gSceneSystem

