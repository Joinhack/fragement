
require "BasicPlayManager"
require "map_data"
require "lua_util"


local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning


OblivionPlayManager = BasicPlayManager.init()

function OblivionPlayManager:init(avatar_mb_str, gate_id)
--    log_game_debug("OblivionPlayManager:init", "")

    local newObj = {}
    newObj.ptr   = {}
    setmetatable(newObj, 		{__index = OblivionPlayManager})
    setmetatable(newObj.ptr,    {__mode = "v"})

    newObj.ptr.theAvatarMB = mogo.UnpickleBaseMailbox(avatar_mb_str)

    newObj.gateID = gate_id

    return newObj
end

function OblivionPlayManager:ExitMission(avatar_dbid, space_loader)
    space_loader.cell.ExitMission(avatar_dbid)
end










----------------------------------------------------------------

return OblivionPlayManager




