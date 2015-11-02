require "lua_util"
require "t2s"

local log_game_debug = lua_util.log_game_debug

local roleDataMgr = {}
roleDataMgr.__index = roleDataMgr

function roleDataMgr:initData()

    self.role_data = lua_util._readXml("/data/xml/role_data.xml", "vocation_i")
    --log_game_debug("roleDataMgr:initData", "roledata = %s", mogo.cPickle(self.role_data))

end


function roleDataMgr:GetRoleDataByVocation(vocation)
    if self.role_data then
        return self.role_data[vocation]
    end
    return nil
end

g_roleDataMgr = roleDataMgr
return g_roleDataMgr
