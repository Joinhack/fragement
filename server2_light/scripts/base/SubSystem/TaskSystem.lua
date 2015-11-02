
require "public_config"
require "error_code"
require "lua_util"
require "reason_def"
require "MissionSystem"

-- 任务系统

local log_game_info = lua_util.log_game_info
local log_game_debug = lua_util.log_game_debug
local _readXml = lua_util._readXml

--[[
error:
0.客户端暂时只允许申请与NPC对话类型任务
1.交的任务和当前主线任务不一样
2.找不到该任务
3.木有这种任务ASK类型
--]]


TaskSystem = {}
TaskSystem.__index = TaskSystem


function TaskSystem:SendError(errorId)
    if self.ptr.theOwner == nil or self.ptr.theOwner.client == nil then
	return
    end
    self.ptr.theOwner.client.TaskErrorResp(errorId)
end

function TaskSystem:SendTaskComplete(completeTaskId)

    --触发迷雾深渊
    gMissionSystem:TriggerMwsyByTask(self.ptr.theOwner, completeTaskId)

    if self.ptr.theOwner == nil or self.ptr.theOwner.client == nil then
	return
    end
    self.ptr.theOwner.client.TaskCompleteResp(completeTaskId)
end

--处理客户端申请某任务完成协议
function TaskSystem:ApplyComplete( taskId, param )
    
    local cfgData = self:GetTaskCfg(taskId)
    if cfgData ~= nil then
        if cfgData['conditionType'] ~= public_config.TASK_ASK_TYPE_NPC_TALK then
            self:SendError(0)
            
            return
        end
        --因为是客户端，所以要验证。看看当前任务==taskId？
        if taskId == self.ptr.theOwner.taskMain then
            self:UpdateTaskProgress(cfgData['conditionType'], param)
        else
            self:SendError(1)
        end
    else
        self:SendError(2)
    end
end

function TaskSystem:GetTaskCfg( taskId )
    local cfgData = self.taskCfg[taskId]
    if cfgData ~= nil then
        return cfgData
    else
        return nil
    end
end


function TaskSystem:UpdateTaskProgress(taskAskId, param)
    --找该类型任务
    local tmpAskTypeTbl = self.taskAsks[taskAskId]
    if tmpAskTypeTbl == nil then
        self:SendError(3)
        return 
    end

    local tblAddTask = {}
    --处理旧任务
    for taskId, tblData in pairs(tmpAskTypeTbl) do
    
        if taskAskId == public_config.TASK_ASK_TYPE_MISSION_COMPLITE and
           param.missionId == tblData['condition'][1] and 
           param.difficulty == tblData['condition'][2] then
            --玩家所在地图是否和任务需求地图一致             
            tblData['finishNum'] = tblData['finishNum'] + 1
        elseif taskAskId == public_config.TASK_ASK_TYPE_NPC_TALK then
            tblData['finishNum'] = tblData['finishNum'] + 1
        else
            return
        end
        
        if tblData['finishNum'] >= tblData['askNum'] then
            tblData['isFinish'] = 1
        end

        if tblData['isFinish'] == 1 then
            table.insert(tblAddTask, tblData['nextId'])
            --干掉任务           
            self.taskAsks[taskAskId][taskId] = nil
            --(未完成)通知客户端完成任务
            self:TaskComplete(taskId)
            
            
        end
    end
    --增加因旧任务触发的新任务
    for index=1, #tblAddTask do
        --更新主线任务记录，装入新的主线任务
        local cfgData = self:GetTaskCfg(tblAddTask[index])
        self.ptr.theOwner.taskMain = tblAddTask[index]
        
        if cfgData ~= nil then
            self.taskAsks[cfgData['conditionType']][self.ptr.theOwner.taskMain] = 
            {isFinish = 0, 
            nextId = cfgData['nextId'], 
            condition = cfgData['condition'],
            finishNum = 0, 
            askNum = 1}  
        else
            self:SendError(2)
        end
    end
    
end

function TaskSystem:GMCurTaskComplete()
    
    local taskId = self.ptr.theOwner.taskMain
    local cfgData = self:GetTaskCfg(taskId)
    if cfgData['conditionType'] == public_config.TASK_ASK_TYPE_MISSION_COMPLITE then
        self:UpdateTaskProgress(cfgData['conditionType'], {missionId = cfgData['condition'][1], difficulty = cfgData['condition'][2]})
    elseif cfgData['conditionType'] == public_config.TASK_ASK_TYPE_NPC_TALK then
        self:UpdateTaskProgress(cfgData['conditionType'], {})
    end
end

function TaskSystem:TaskComplete(taskId)
    
    local avatar = self.ptr.theOwner
    --奖励
    local cfgData = self:GetTaskCfg(taskId)

    --exp
    self.ptr.theOwner:AddExp(cfgData['exp'], reason_def.task) 
    --money
    self.ptr.theOwner:AddGold(cfgData['money'], reason_def.task)
    --awards
    local myVocation = self.ptr.theOwner.vocation
    local awardsCfgName = 'awards' .. myVocation
    local awardsTbl = cfgData[awardsCfgName]
    if awardsTbl == nil then
    end
    
    if awardsTbl ~= nil then
        for itemId, itemCount in pairs(awardsTbl) do
            if itemCount > 0 then
                self.ptr.theOwner:AddItem(itemId, itemCount, reason_def.task)
            end
        end
    end

    --(未完成)通知客户端完成任务
    self:SendTaskComplete(taskId)

    log_game_debug("TaskSystem:TaskComplete", "dbid=%q;name=%s;mainTaskId=%d",avatar.dbid, avatar.name, taskId) 
end

function TaskSystem:CreateAvatarInitAll()
    
    if self.ptr.theOwner == nil then
        return
    end

    --主线任务
--    self.ptr.theOwner.taskMain = 1--kevintest

    self:Init()
    
    --self:ApplyComplete(1)
    --self:ApplyComplete(2)
    --self:ApplyComplete(3)
    --self:ApplyComplete(4)
end

function TaskSystem:Init()--取得db数据之后
    local cfgData
    --主线任务
    cfgData = self:GetTaskCfg(self.ptr.theOwner.taskMain)
    if cfgData ~= nil then
        self.taskAsks[cfgData['conditionType']][self.ptr.theOwner.taskMain] = 
            {isFinish = 0, 
            nextId = cfgData['nextId'], 
            condition = cfgData['condition'], 
            finishNum = 0, 
            askNum = 1}  
            --isFinish:任务已完成标记  finishNum：当前完成数  askNum：目标完成数    如果以后多条件达成才触发完成任务那么finishNum和askNum要变成list管理，条件都达成才isFinish=1

    else
        self:SendError(2)
    end



end

function TaskSystem:new( owner )
    local newObj = { }
    setmetatable(newObj, {__index = TaskSystem})
    newObj.ptr = {}
    setmetatable(newObj.ptr, {__mode = "v"})


    newObj.ptr.theOwner = owner
    newObj.taskAsks = {}
    
    newObj.taskAsks[public_config.TASK_ASK_TYPE_NPC_TALK] = {}
    newObj.taskAsks[public_config.TASK_ASK_TYPE_MISSION_COMPLITE] = {}
    
 
    return newObj
end

function TaskSystem:initData()
    self.taskCfg = _readXml('/data/xml/TaskData.xml', 'id_i')
end

return TaskSystem
