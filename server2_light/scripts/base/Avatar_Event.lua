--Avatar身上的事件函数 可以都放在这个文件


require "event_def"
require "eventData"
require "Trigger"
require "global_data"
require "reason_def"
require "channel_config"
require "public_config"




local globalbase_call = lua_util.globalbase_call
local log_game_debug = lua_util.log_game_debug
local log_game_info = lua_util.log_game_info
local log_game_warning = lua_util.log_game_warning
local log_game_error = lua_util.log_game_error



--完成副本 fb_id=副本id
function Avatar:OnFinishFB(fb_id, diff)
    --log_game_debug("Avatar:OnFinishFB", "temp temp temp temp temp temp temp temp temp temp temp temp ") 
    
    if diff == 1 then  --1普通，2 困难
      self:triggerEvent(event_config.EVENT_FINISH_FB_NORMAL, event_config.EVENT_FINISH_FB_NORMAL, fb_id) --完成普通副本n次 
    elseif diff == 2 then
       self:triggerEvent(event_config.EVENT_FINISH_FB_HARD, event_config.EVENT_FINISH_FB_HARD, fb_id) --完成困难副本n次 
    end
end



--强化身体(强化成功时候触发)  equip_id=装备id
function Avatar:OnStrongEquip(equip_id)
  --log_game_debug("Avatar:OnStrongEquip", "temp temp temp temp temp temp temp temp temp temp temp temp ") 
  self:triggerEvent(event_config.EVENT_STRONG_EQUIP, event_config.EVENT_STRONG_EQUIP, equip_id) --完成普通副本n次 
   
end


--升级技能 skill_id = 升级技能的id
function Avatar:OnSkillLevelUp(skill_id)
  --log_game_debug("Avatar:OnStrongEquip", "temp temp temp temp temp temp temp temp temp temp temp temp ") 
  self:triggerEvent(event_config.EVENT_SKILL_LEVEL_UP, event_config.EVENT_SKILL_LEVEL_UP, skill_id) --升级技能 
   
end


--消耗钻石 delta=消耗的数量
function Avatar:OnCostDiamond(delta)
   --log_game_debug("Avatar:OnCostDiamond", "temp temp temp temp temp temp temp temp temp temp temp temp ")
   self:triggerEvent(event_config.EVENT_COST_DIAMOND, event_config.EVENT_COST_DIAMOND, delta) --消耗钻石 
   
end


--炼金 暂时没这个功能
function Avatar:OnLianjin()
   --log_game_debug("Avatar:OnLianjin", "temp temp temp temp temp temp temp temp temp temp temp temp ")
   self:triggerEvent(event_config.EVENT_LIANJIN, event_config.EVENT_LIANJIN) --炼金 
   

end


--龙语抽符文
function Avatar:OnRuneExtract()
        --log_game_debug("Avatar:OnRuneExtract", "temp temp temp temp temp temp temp temp temp temp temp temp ")
        self:triggerEvent(event_config.EVENT_RUNE_EXTRACT, event_config.EVENT_RUNE_EXTRACT) --龙语抽符文 
    
end


--精灵培养（待定）
--[[
function Avatar:OnRuneExtract()
         --log_game_debug("Avatar:OnStrongEquip", "temp temp temp temp temp temp temp temp temp temp temp temp ") 
       
end]]

--合成宝石  jewel_id=合成宝石ID
function Avatar:OnJewelCombine(jewel_id)
         --log_game_debug("Avatar:OnJewelCombine", "temp temp temp temp temp temp temp temp temp temp temp temp ") 
         self:triggerEvent(event_config.EVENT_JEWRL_COMBINE, event_config.EVENT_JEWRL_COMBINE, jewel_id) --合成宝石 
   
end

--赠送好友体力  energy_num=赠送数量
function Avatar:OnGiveEnergy(energy_num)
         --log_game_debug("Avatar:OnGiveEnergy", "temp temp temp temp temp temp temp temp temp temp temp temp ") 
         self:triggerEvent(event_config.EVENT_GIVE_ENERGY, event_config.EVENT_GIVE_ENERGY, energy_num) --赠送好友体力 
   
end

--竞技场pvp(完成一次触发)
function Avatar:OnFinishPvP()
      --log_game_debug("Avatar:OnRuneExtract", "temp temp temp temp temp temp temp temp temp temp temp temp ") 
      self:triggerEvent(event_config.EVENT_COMPETE_PVP, event_config.EVENT_COMPETE_PVP) --竞技场pvp 
   
end

--参与圣域守卫战（完成一次）
function Avatar:OnFinishSantuaryDefense()
         --log_game_debug("Avatar:OnFinishSantuaryDefense", "temp temp temp temp temp temp temp temp temp temp temp temp ") 
         self:triggerEvent(event_config.EVENT_TD_FINISH, event_config.EVENT_TD_FINISH) --参与圣域守卫战（完成一次） 
   
end

--参与湮灭之门(完成一次)
function Avatar:OnFinishOblivionGate()
         --log_game_debug("Avatar:OnFinishOblivionGate", "temp temp temp temp temp temp temp temp temp temp temp temp ") 
         self:triggerEvent(event_config.EVENT_GATE_FINISH, event_config.EVENT_GATE_FINISH) --参与湮灭之门 
   
end

--参与试炼之塔(完成一次) cur_floor=当前层数
function Avatar:OnFinishTower(cur_floor)
         --log_game_debug("Avatar:OnFinishTower", "temp temp temp temp temp temp temp temp temp temp temp temp ") 
         self:triggerEvent(event_config.EVENT_TOWER_FINISH, event_config.EVENT_TOWER_FINISH,cur_floor) --完成普通副本n次 
   
       
end

--[[参与公会龙晶注魔
function Avatar:OnRuneExtract()
         --log_game_debug("Avatar:OnStrongEquip", "temp temp temp temp temp temp temp temp temp temp temp temp ") 
       
end]]

--[[公会战
function Avatar:OnRuneExtract()
         --log_game_debug("Avatar:OnStrongEquip", "temp temp temp temp temp temp temp temp temp temp temp temp ") 
       
end]]

--刷新商店
function Avatar:OnRefreshShop()
         --log_game_debug("Avatar:OnRefreshShop", "temp temp temp temp temp temp temp temp temp temp temp temp ") 
         self:triggerEvent(event_config.EVENT_REFRESH_SHOP, event_config.EVENT_REFRESH_SHOP) --刷新商店   
      
end

--杀死一个怪 id=怪物id
function Avatar:OnKillMonster(id)
         --log_game_debug("Avatar:OnRefreshShop", "temp temp temp temp temp temp temp temp temp temp temp temp ") 
         self:triggerEvent(event_config.EVENT_PLAYER_KILL_MONSTER, event_config.EVENT_PLAYER_KILL_MONSTER, id) --刷新商店   
      
end

--分解装备 id=装备id
function Avatar:OnBreakEquip(id)
  self:triggerEvent(event_config.EVENT_BREAK_EQUIP, event_config.EVENT_BREAK_EQUIP, id) --分解装备


end


 --领取体力 (运营活动)
function Avatar:OnAddItem(id,num,reason)  
    if id ==public_config.ENERGY_ID and reason == reason_def.activity  then
      self:triggerEvent(event_config.EVENT_GET_ENERGY_FROM_EVENT, event_config.EVENT_GET_ENERGY_FROM_EVENT, num) --领取体力 (运营活动)    
     end            
      
end


--领取登陆奖励 days=天数
function Avatar:OnGetLoginReward(days)  

  self:triggerEvent(event_config.EVENT_GET_LOGIN_REWARD, event_config.EVENT_GET_LOGIN_REWARD, days) --领取登陆奖励      
     
      
end


--竞技场积分兑换 num=数量
function Avatar:OnCompCreditExchange(num)  

  self:triggerEvent(event_config.EVENT_GET_REWARD_FROM_COMP, event_config.EVENT_GET_REWARD_FROM_COMP, num) --竞技场积分兑换      
            
end

--合成符文 id=合成后的id
function Avatar:OnMakeFuwen(id)        
     
  self:triggerEvent(event_config.EVENT_MAKE_FUWEN, event_config.EVENT_MAKE_FUWEN, id) --合成符文  
      
end

--竞技场刷新对手
function Avatar:OnRefreshCompete()      
  
  self:triggerEvent(event_config.EVENT_REFRESH_COMP, event_config.EVENT_REFRESH_COMP) --竞技场刷新对手      
      
end


--购买体力 count=购买次数
function Avatar:OnBuyEnergy(count)    

      self:triggerEvent(event_config.EVENT_BUY_ENERGY, event_config.EVENT_BUY_ENERGY, count) --购买体力   
     
end

--商店购买道具 id=道具id num=数量
function Avatar:OnBuyItemFromShop(id, num)    

    if id ==public_config.ENERGY_ID then
      self:triggerEvent(event_config.EVENT_BUY_ENERGY, event_config.EVENT_BUY_ENERGY, num) --购买体力   
    end       
    
end


--副本结算翻牌  num=本次翻牌的数量(结算时加完道具后调用)
function Avatar:OnRollCard(num)       
  self:triggerEvent(event_config.EVENT_ROLL_CARD, event_config.EVENT_ROLL_CARD, num) --副本结算翻牌     
      
end

--参加兽人必须死  
function Avatar:OnOrc()       
  self:triggerEvent(event_config.EVENT_ORC, event_config.EVENT_ORC) --参加兽人必须死    
      
end

--参加飞龙
function Avatar:OnDragon()       
  self:triggerEvent(event_config.EVENT_DRAGON, event_config.EVENT_DRAGON) --参加飞龙         
end





--单次兽人必须死副本结束时完成的波数 rush_count =波数
function Avatar:OnOrcCount(rush_count)       
  self:triggerEvent(event_config.EVENT_ORC_RUSH_COUNT, event_config.EVENT_ORC_RUSH_COUNT,rush_count) --
end


--单次兽人必须死副本结束时为MVP（输出最高）
function Avatar:OnOrcMvp()       
  self:triggerEvent(event_config.EVENT_ORC_MVP, event_config.EVENT_ORC_MVP) --参加飞龙         
end


--兽人必须死战斗副本胜利
function Avatar:OnOrcWin()       
  self:triggerEvent(event_config.EVENT_ORC_WIN, event_config.EVENT_ORC_WIN) --参加飞龙         
end


--飞龙大赛袭击胜利
function Avatar:OnDragonAttackWin()       
  self:triggerEvent(event_config.EVENT_DRAGON_WIN, event_config.EVENT_DRAGON_WIN) --参加飞龙         
end


--飞龙大赛提升飞龙品质  bSuccess =是否成功
function Avatar:OnDragonLevelUp(bSuccess)       
  self:triggerEvent(event_config.EVENT_DRAGON_LEVELUP, event_config.EVENT_DRAGON_LEVELUP) --参加飞龙         
end

--使用金色品质飞龙进行飞龙大赛
function Avatar:OnDragonBest()       
  self:triggerEvent(event_config.EVENT_DRAGON_BEST, event_config.EVENT_DRAGON_BEST) --参加飞龙         
end

