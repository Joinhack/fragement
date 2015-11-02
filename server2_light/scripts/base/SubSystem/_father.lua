
require "t2s"
--require "trigger_data"
require "event_config"
require "event_def"

require "lua_util"
require "global_data"
require "TowerSystem"

local globalbase_call = lua_util.globalbase_call
local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error


local father = {}
--setmetatable(father, {__index = father} )


father.event_interest ={}

---------------------引擎可能会回调的方法 begin-----------------------------------------------


function father:initData()
        self.init_func = {}
        self.event_func = {}
        self.condition_func = {}
        self.condition_event = {}
        self.ce = {}


        self:AddListener(1, event_config.EVENT_ROLE_LEVELUP, "LevelUp")                  --人物升级不处理该事件
        self:AddListener(2, event_config.EVENT_PLAYER_ADD_FRIEND_SCCESS, "AddFriend")    --添加好友不处理该事件
        self:AddListener(3, event_config.EVENT_PLAYER_KILL_MONSTER, "KillMonster")       --杀怪记录
        self:AddListener(4, event_config.EVENT_ENTER_BOSS, "KillBoss")                   --记录世界boss击杀次数
        self:AddListener(5, event_config.EVENT_FINISH_TOWER, "FinishFloor")              --记录层数
        self:AddListener(6, event_config.EVENT_FINISH_FB_NORMAL, "FinishFB")             --完成普通副本n次
        self:AddListener(7, event_config.EVENT_FINISH_FB_HARD, "FinishFB")               --完成困难副本n次
        self:AddListener(8, event_config.EVENT_STRONG_EQUIP, "StrongEquip")              --强化装备
        self:AddListener(9, event_config.EVENT_SKILL_LEVEL_UP, "SkillLevelUp")           --升级技能
        self:AddListener(10, event_config.EVENT_COST_DIAMOND, "CostDiamond")             --消耗钻石
        self:AddListener(11, event_config.EVENT_LIANJIN, "Lianjin") --炼金
        self:AddListener(12, event_config.EVENT_RUNE_EXTRACT, "RuneExtract")             --龙语抽符文
        --self:AddListener(13, event_config.EVENT_GHOST_DEVELOP, ")                      --精灵培养（待定）
        self:AddListener(14, event_config.EVENT_JEWRL_COMBINE, "JewelCombine")           --合成宝石
        self:AddListener(15, event_config.EVENT_GIVE_ENERGY, "GiveEnergy")               --赠送好友体力
        self:AddListener(16, event_config.EVENT_COMPETE_PVP, "FinishPvP")                --竞技场pvp
        self:AddListener(17, event_config.EVENT_TD_FINISH, "FinishTD")                   --参与圣域守卫战
        self:AddListener(18, event_config.EVENT_GATE_FINISH, "FinishGate")               --参与湮灭之门
        self:AddListener(19, event_config.EVENT_TOWER_FINISH, "FinishTower")             --参与试炼之塔
        --self:AddListener(20, event_config.EVENT_LONGJIN_INJECT, ")                     --参与公会龙晶注魔
        --self:AddListener(21, event_config.EVENT_UNION_WAR, ")                          --公会战
        self:AddListener(22, event_config.EVENT_REFRESH_SHOP, "RefreshShop")             --刷新商店
        self:AddListener(23, event_config.EVENT_BREAK_EQUIP, "BreakEquip")             --分解装备
        self:AddListener(24, event_config.EVENT_GET_ENERGY_FROM_EVENT, "GetEnergyFromEvent")             --领取体力 (运营活动)
        self:AddListener(25, event_config.EVENT_GET_LOGIN_REWARD, "GetLoginReward")             --领取登陆奖励 
        self:AddListener(26, event_config.EVENT_GET_REWARD_FROM_COMP, "CompCreditExchange")             --竞技场积分奖励兑换 
        self:AddListener(27, event_config.EVENT_MAKE_FUWEN, "MakeFuwen")             --合成符文 
        self:AddListener(28, event_config.EVENT_REFRESH_COMP, "RefreshCompete")             --竞技场刷新对手 
        self:AddListener(29, event_config.EVENT_BUY_ENERGY, "BuyEnergy")             --购买体力 
        self:AddListener(30, event_config.EVENT_ROLL_CARD, "RollCard")             --副本结算翻牌 （missionRandomReward表，找前端）
        self:AddListener(31, event_config.EVENT_ORC, "ORC")             --兽人必死 
        self:AddListener(32, event_config.EVENT_DRAGON, "DRAGON")             --飞龙     
        self:AddListener(33, event_config.EVENT_ORC_RUSH_COUNT, "OrcRushCount")             --单次兽人必须死副本结束时完成的波数   数量 
        self:AddListener(34, event_config.EVENT_ORC_MVP, "OrcMvp")             --单次兽人必须死副本结束时为MVP（输出最高）  次数   
        self:AddListener(35, event_config.EVENT_ORC_WIN, "OrcWin")             --兽人必须死战斗副本胜利 次数   
        self:AddListener(36, event_config.EVENT_DRAGON_WIN, "DragonWin")             --飞龙大赛袭击胜利    次数     
        self:AddListener(37, event_config.EVENT_DRAGON_LEVELUP, "DragonLevelUp")             --飞龙大赛提升飞龙品质  次数     
        self:AddListener(38, event_config.EVENT_DRAGON_BEST, "DragonBest")             --使用金色品质飞龙进行飞龙大赛  次数   



 end
 
--增加监视 表示 index 监听event_id 消息，交由 func处理
 function father:AddListener(index, event_id, func)  

    if index == nil or self.condition_event[index] ~= nil then
        log_game_error("father.self:AddListener", "index=%s  already exist，please check！", index)
        return
    end

    if event_id == nil or self.event_func[event_id] ~= nil then
        log_game_error("father.self:AddListener", "event_id=%s func= %s already exist，please check！",event_id, func )
        return
    end

    --[[
    if self["When".. func] == nil or self["Test".. func] == nil then
         log_game_error("father.self:AddListener", "func=%s func not exist，please  check！",func )
    end]]



    self.init_func[event_id] = self["Init".. func] or self.InitDefualt  --没有找到处理函数 就用默认的
    self.event_func[event_id] = self["When".. func] or self.WhenDefualt  --没有找到处理函数 就用默认的
    self.condition_func[event_id] = self["Test".. func] or self.TestDefualt    --没有找到处理函数 就用默认的
    self.condition_event[index] = {listen_id = event_id}
    self.ce[index] = event_id  -- conditionid - event_id 对应表
    
    return true
end

--父类
function father.InitDefualt(trigger, index, args)
    log_game_debug("father.InitDefualt", "DoNothing!!!!!!")
    return true
end

function father.WhenDefualt(trigger, index, args)  
    log_game_debug("father.WhenDefualt", "DoNothing!!!!!!")
    return true
end

function father.TestDefualt(trigger, index, args)  
    log_game_debug("father.TestDefualt", "DoNothing!!!!!!")
    return false
end


g_father = father
return g_father