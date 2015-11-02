
require "BasicPlayManager"
require "mission_config"


NewbiePlayManager = BasicPlayManager.init()

function NewbiePlayManager:init()

    local obj = {}
    setmetatable(obj, {__index = NewbiePlayManager})
    obj.__index = obj

    obj.StartTime = 0
    obj.Info = {}
    obj.Info[mission_config.SPECIAL_MAP_INFO_OWNER_DBID] = 0
    obj.Info[mission_config.SPECIAL_MAP_INFO_OWNER_NAME] = ''
    obj.Info[mission_config.SPECIAL_MAP_INFO_OWNER_MBSTR] = ''
    obj.Info[mission_config.SPECIAL_MAP_INFO_STARTED_SPAWN_POINT] = {}              --初始化已触发的刷怪点
    obj.Info[mission_config.SPECIAL_MAP_INFO_FINISHED_SPAWN_POINT] = {}             --初始化已经完成的刷怪点
    obj.Info[mission_config.SPECIAL_MAP_INFO_MISSION_ID] = 0
    obj.Info[mission_config.SPECIAL_MAP_INFO_DIFFICULT] = 0
    obj.Info[mission_config.SPECIAL_MAP_INFO_DROP] = {}                             --初始化已经掉落的物品信息

    return obj
end