
require "lua_util"
require "public_config"

local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_error = lua_util.log_game_error

GameMgr = {}
--GameMgr.__index = GameMgr

setmetatable(GameMgr, {__index = BaseEntity} )

--------------------------------------------------------------------------------------

function GameMgr:__ctor__()
    log_game_info('GameMgr:__ctor__', '')
end

--registerGlobally成功后回调方法
function GameMgr:on_registered()
    log_game_info('GameMgr:on_registered', '')

    local mgrs = self.mgrs

    --加载离线管理器
    mogo.createBaseAnywhere("OfflineMgr")
    mgrs['OfflineMgr'] = 1
    
    --向每个进程广播游戏开始时间
    mogo.setBaseData(public_config.BASE_DATA_KEY_GAME_START_TIME, os.time())

end

--管理器装载完成之后的回调方法
function GameMgr:OnMgrLoaded(mgr_name)
    log_game_info("GameMgr:OnMgrLoaded", "mgr_name = %s", mgr_name)

    local mgrs = self.mgrs
    local needInit = self.needInit
    --在加载完离线管理器后加载其他管理器
    if 'OfflineMgr' == mgr_name then
        log_game_info("GameMgr:OnMgrLoaded", "mgr_name = OfflineMgr loaded.")
        --加载地图管理器(世界地图需要到WorldBossMgr注册)
        mogo.createBaseAnywhere("MapMgr")
        mgrs['MapMgr'] = 2

        --用户管理器
        mogo.createBaseAnywhere("UserMgr")
        mgrs['UserMgr'] = 3
        needInit['UserMgr'] = 1

        --邮件管理器
        mogo.createBaseAnywhere("MailMgr")
        mgrs['MailMgr'] = 4

        --竞技场管理器由UserMgr创建
        mogo.createBaseFromDbByNameAnywhere("ArenaMgr", "ArenaMgr")
        mgrs['ArenaMgr'] = 5
        needInit['ArenaMgr'] = 1

        
        --加载命名管理器
        mogo.createBaseAnywhere("NameMgr")
        mgrs['NameMgr'] = 6
        needInit['NameMgr'] = 1

        --运营数据采集器
        mogo.createBaseAnywhere("Collector")
        mgrs['Collector'] = 7
        
        --加载世界boss管理器
        mogo.createBaseFromDbByNameAnywhere("WorldBossMgr", "WorldBossMgr")
        mgrs['WorldBossMgr'] = 8
        needInit['WorldBossMgr'] = 1

        --湮灭之门管理器
        mogo.createBaseAnywhere("OblivionGateMgr")
        mgrs['OblivionGateMgr'] = 9

        --加载公会管理器
        mogo.createBaseAnywhere("GuildMgr")
        mgrs['GuildMgr'] = 10
        needInit['GuildMgr'] = 1

        mogo.createBaseAnywhere("EventMgr")
        mgrs['EventMgr'] = 11

        --加载副本记录管理器
        mogo.createBaseAnywhere("MissionMgr")
        mgrs['MissionMgr'] = 12
        --needInit['ArenaMgr'] = 1

        --加载全局数据管理器
        mogo.createBaseFromDbByNameAnywhere("GlobalDataMgr", "GlobalDataMgr")
        mgrs['GlobalDataMgr'] = 13

        --加载活动管理器
        mogo.createBaseAnywhere("ActivityMgr")
        mgrs['ActivityMgr'] = 14
      
        --加载飞龙活动管理器
        mogo.createBaseAnywhere("FlyDragonMgr")
        mgrs['FlyDragonMgr'] = 15
        needInit['FlyDragonMgr'] = 1

        --加载补偿管理器
        mogo.createBaseAnywhere("mgr_compensate")
        mgrs['mgr_compensate'] = 16

        --充值管理器
        mogo.createBaseAnywhere("ChargeMgr")
        mgrs['ChargeMgr'] = 17

        --守护PvP管理器
        mogo.createBaseAnywhere("DefensePvPMgr")
        mgrs['DefensePvPMgr'] = 18

        --加载vip抽奖管理器
        mogo.createBaseFromDbByNameAnywhere("RouletteMgr", "RouletteMgr")
        --mogo.createBaseAnywhere("RouletteMgr")
        mgrs['RouletteMgr'] = 19
        needInit['RouletteMgr'] = 1
    end

    mgrs[mgr_name] = nil

    if lua_util.get_table_real_count(mgrs) == 0 then
        log_game_info("GameMgr.all_mgrs_loaded", '')
        self:_initMgr()
    end
end

--初始化mgrs
function GameMgr:_initMgr()
    for mgr_name, _ in pairs(self.needInit) do
        log_game_debug("GameMgr:_initMgr", "")
        local mm = globalBases[mgr_name]
        if mm then
            mm.Init()
        else
            log_game_error("GameMgr:_initMgr", '')
        end
    end
end

--
function GameMgr:OnInited(mgr_name)
    log_game_debug("GameMgr:OnInited", mgr_name)
    self.needInit[mgr_name] = nil
    if lua_util.get_table_real_count(self.needInit) == 0 then
        log_game_info("GameMgr.all_mgrs_inited", '')
        --所有管理器初始化完毕后通知loginapp可以开放玩家登录
        mogo.setLogin(1)
    end
end

--销毁前操作
function GameMgr:onDestroy()
    log_game_info("GameMgr:onDestroy", "")
end
--------------------------------------------------------------------------------------

return GameMgr


