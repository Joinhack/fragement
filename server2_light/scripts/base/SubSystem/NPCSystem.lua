require "lua_util"
require "map_data"
require "TaskSystem"
require "npcData"
require "error_code"

local map_mgr = g_map_mgr

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_error = lua_util.log_game_error


NPCSystem = {}
setmetatable(NPCSystem, {__index = BaseEntity})

local NPC_config = 
{
	TASK_FUNC = 1, --任务功能
}


NPCSystem.funcMap = NPC_map

--构造函数
function NPCSystem:__ctor__()
    local NPC_map = 
    {
        [NPC_config.TASK_FUNC] = NPCSystem.TaskDispatch, --任务转接 	
    }
    self.funcMap = NPC_map 
end

function NPCSystem:NPCReq(avatar, funcId, ...)
    local func = self.funcMap[funcId]
    if func == nil then
        log_game_error("NPCSystem:NPCReq", "NPC function not existed:dbid=%q;name=%s;funId=%d", 
                                                    avatar.dbid, avatar.name, funcId)
	return 1
    end
    
    func(self, avatar, ...)
    return 
end

function NPCSystem:TaskDispatch(avatar, npcId, taskId)
    local npcTbl = g_npcData_mgr:GetNPCDataById(npcId)
    if not npcTbl then
        log_game_error("NPCSystem:TaskDispatch", "npcId error:dbid=%q;name=%s;taskId=%d;npcId=%d", 
                                                    avatar.dbid, avatar.name, taskId, npcId)
        return  error_code.ERR_NPC_NPC_CFG
    end
    local tskTbl = avatar.taskSystem:GetTaskCfg(taskId)
    if tskTbl == nil then
        log_game_error("NPCSystem:TaskDispatch", "taskId error:dbid=%q;name=%s;taskId=%d", 
                                                    avatar.dbid, avatar.name, taskId)
        return error_code.ERR_NPC_TSK_CFG
    end
    if tskTbl.level > avatar.level then
        log_game_error("NPCSystem:TaskDispatch", "level limited:dbid=%q;name=%s;taskLevel=%d;level=%d;taskId=%d", 
                                                    avatar.dbid, avatar.name, tskTbl.level, avatar.level, taskId)
        return error_code.ERR_NPC_LEVEL_FORBID
    end
    --职业判定暂留，待任务系统完善
    if tskTbl.npc ~= npcId then
        log_game_error("NPCSystem:TaskDispatch", "taskcfg npc unmatched NPCCfg:dbid=%q;name=%s;taskNpcId=%d;npcId=%d;taskId=%d",
                                                    avatar.dbid, avatar.name, tskTbl.npc, npcId, taskId)
        return error_code.ERR_NPC_ID_UNMATCH
    end
    --交由任务系统处理任务
    avatar.taskSystem:ApplyComplete(taskId)

    return error_code.ERR_NPC_SUCCESS
end

return NPCSystem
