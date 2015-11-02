require "lua_util"
local log_game_debug = lua_util.log_game_debug

FormularMgr = {}
FormularMgr.__index = FormularMgr

--读取配置数据
function FormularMgr:initData()
    local cfgDatas = lua_util._readXml("/data/xml/FormulaParameters.xml", "id_i")
    if cfgDatas then
        self.cfgdatas = cfgDatas or {}
    end 
end

--取得二级属性计算公式所需参数
function FormularMgr:GetFormulaCfg(propType)
    if not self.cfgdatas then
        log_game_debug("FormularMgr:GetFormulaCfg", "cfg nil")
        return 
    end

    local paras = self.cfgdatas[propType]
    return paras
end


g_formular_mgr = FormularMgr
return g_formular_mgr

