require "Item_data"
require "public_config"
require "lua_util"
require "bodyEnhance_config"
require "error_code"
require "CommonXmlConfig"
require "RuneSystem"
require "avatar_level_data"
require "arenic_level"
require "FormularPara"
require "Enchantment"
require "FightForceFactor_data"
require "WingSystem"

local log_game_debug = lua_util.log_game_debug
local log_game_error = lua_util.log_game_error
local log_game_info  = lua_util.log_game_info
--道具配置属性索引
local ITEM_TYPE_CONFIGURE      = public_config.ITEM_TYPE_CFG_TBL
local ITEM_TYPE_ATTRI          = public_config.ITEM_TYPE_EQUIPMENTATTRI
local ITEM_TYPE_SUIT           = public_config.ITEM_TYPE_SUITEQUIPMENT
local ITEM_TYPE_JEWELATTRI     = public_config.ITEM_TYPE_JEWELATTRI
local ITEM_QUALITY_GOLD        = public_config.ITEM_QUALITY_GOLD
local AVATAR_ALL_VOC           = public_config.AVATAR_ALL_VOC
--公式参数索引
local PROP_RATE_DEFENCE        = public_config.PROP_RATE_DEFENCE          
local PROP_RATE_CRIT           = public_config.PROP_RATE_CRIT             
local PROP_RATE_TRUESTRIKE     = public_config.PROP_RATE_TRUESTRIKE       
local PROP_RATE_ANTIDEFENSE    = public_config.PROP_RATE_ANTIDEFENSE      
local PROP_RATE_PVPADDITION    = public_config.PROP_RATE_PVPADDITION     
local PROP_RATE_PVPANTI        = public_config.PROP_RATE_PVPANTI
local PROP_RATE_ANTICRITRATE   = public_config.PROP_RATE_ANTICRITRATE   --抗暴
local PROP_RATE_ANTITSTKRATE   = public_config.PROP_RATE_ANTITSTKRATE   --抗破
--
local INSTANCE_GRIDINDEX       = public_config.ITEM_INSTANCE_GRIDINDEX  --背包索引
local INSTANCE_TYPEID          = public_config.ITEM_INSTANCE_TYPEID     --道具id
local INSTANCE_SLOTS           = public_config.ITEM_INSTANCE_SLOTS      --宝石插槽
local ITEM_INSTANCE_EXTINFO    = public_config.ITEM_INSTANCE_EXTINFO    --扩展信息

local ITEM_ACTIVED_OK          = public_config.ITEM_ACTIVED_OK          --已激活
local ITEM_ACTIVED_NO          = public_config.ITEM_ACTIVED_NO          --没有激活
local ITEM_EXTINFO_ACTIVE      = public_config.ITEM_EXTINFO_ACTIVE      --道具激活标识

local PropsSystem = {}
PropsSystem.__index = PropsSystem

------------------------------------------------------------
-- 角色战斗力计算公式
------------------------------------------------------------
function PropsSystem:GetFightForce(baseProps)
    local fffData = g_fightForce_mgr:GetCfg()
    local fightForce = 0
    for kName, vValue in pairs(fffData) do
        fightForce = fightForce + baseProps[kName]*vValue
        --log_game_debug("PropsSystem:GetFightForce", "facName=%s;facValue=%d;bsValue=%d;add=%d;fightForce=%d;",
        --    kName, vValue, baseProps[kName], baseProps[kName]*vValue, fightForce)
    end
    fightForce = math.ceil(fightForce)
    return fightForce
end
--do for GM command
function PropsSystem:GetFFP(baseProps)
    local fffData = g_fightForce_mgr:GetCfg()
    local retmsg = ""
    for kName, vValue in pairs(fffData) do
        local val = baseProps[kName]
        val = tostring(val)
        retmsg = string.format("%s[%s=%s];", retmsg, kName, val)
    end
    return retmsg
end
------------------------------------------------------------
--三种属性获取接口
------------------------------------------------------------
--竞技场接口
function PropsSystem:GetPropertiesWithArenic(baseProps, bodyTbl, runeBag, bodyEquip, level, arenicLevel, allMagic, elfAreaTearProg, wingBag)
    self:GetBaseProps(baseProps, bodyTbl, runeBag, bodyEquip, level, allMagic, elfAreaTearProg, wingBag)
    self:GetArenicEffectValues(baseProps, arenicLevel)
    self:GetBattleProps(baseProps)
    baseProps["id"] = nil
    return baseProps
end
--角色基础属性计算：包括装备，镶嵌的宝石，符文效果，精灵系统的被动技能
function PropsSystem:GetBaseProps(baseProps, bodyTbl, runeBag, bodyEquip, level, allMagic, elfAreaTearProg, wingBag)
    if not baseProps then
        return
    end
    setmetatable(baseProps,
        {__index =
            function (table, key)
                return 0          
            end
        }
    )
    local levelPct = 0 --角色等级属性附魔加成比
    local tblEquipEffects = self:GetEquipmentEffects(bodyEquip, level, bodyTbl, allMagic, levelPct)
    for k, v in pairs(tblEquipEffects) do
        baseProps[k] = baseProps[k] + v
    end

    local effectId = g_avatar_level_mgr:GetLevelEffectId(level)
    if not effectId then
        log_game_error("PropsSystem:GetBaseProps", "avatar level cfg error:level=%d", level)
        return baseProps
    end
    local prop = CommonXmlConfig:GetPassivePropertyEffect(effectId) or {}
    local bPosiPct = 0
    for k, v in pairs(prop) do
        baseProps[k] = baseProps[k] + v*(1 + levelPct)
    end

    self:GetBodyEffects(baseProps, bodyTbl)
    self:GetRuneEffectValues(runeBag, level, baseProps)
    self:GetElfEffects(baseProps, elfAreaTearProg)
    self:GetWingEffects(baseProps, wingBag)
    baseProps["scores"] = nil
    
    return baseProps
end
function PropsSystem:GetWingEffects(baseProps, wingBag)
    local propsId = WingSystem:DealWingBagProps(wingBag)
--    log_game_debug("PropsSystem:GetWingEffects", "propsId=%s", mogo.cPickle(propsId))
    for propId, count in pairs(propsId) do
        local prop = CommonXmlConfig:GetPassivePropertyEffect(propId) or {}
        for k, v in pairs(prop) do
            baseProps[k] = baseProps[k] + v*count
        end
    end
end
function PropsSystem:GetBodyEffects(baseProps, bodyEnhance)
    for kPosi, vLevel in pairs(bodyEnhance) do
        self:GetBodyEnhanceAttri(baseProps, kPosi, vLevel) 
    end
end

function PropsSystem:GetElfEffects(baseProps, elfAreaTearProg)
    --收集每个领域的已激活Node
    
    for areaId=1, #elfAreaTearProg do
        local nodeList = {}
        local nodeCount = g_elf_mgr:getAwardList(nodeList, areaId, 0, elfAreaTearProg[areaId])
        if nodeCount > 0 then
            for i=1, nodeCount do
                local tmpNode = nodeList[i]
                if tmpNode then
                    if tmpNode.AwardPropCfgId ~= nil and tmpNode.AwardPropCfgId ~= 0 then
                        local props = CommonXmlConfig:GetPassivePropertyEffect(tmpNode.AwardPropCfgId)
                        if props ~= nil then
                            for tk, tv in pairs(props) do     
                                baseProps[tk] = baseProps[tk] + tv
                            end                 
                        end                   
                    end
                end
            end
        end
    end    
end

--获取装备效果
function PropsSystem:GetEquipmentEffects(itemList, avatarLevel, bodyEnhance, allMagic, levelPct)
    local baseProps = self:GetPrivMetaTable()
    if not next(itemList) then
        return baseProps
    end
    local suitProps = self:GetPrivMetaTable()
    for _, vItem in pairs(itemList) do
        local typeId = vItem[INSTANCE_TYPEID]
        local itemData = self:GetCfgData(ITEM_TYPE_CONFIGURE, typeId)
        if not itemData then
            return baseProps
        end
        local magicInfo = self:GetBodyMagicAttrByIdx(allMagic, vItem[INSTANCE_GRIDINDEX], typeId) or {}
        local jewelPct  = magicInfo.jewelPct or 0 --宝石附魔加成比
        local bPosiPct  = magicInfo.bPosiPct or 0 --身体部分附魔加成比
        levelPct = levelPct + (magicInfo.levelPct or 0)
        self:GetMagicEffects(baseProps, magicInfo)
        self:GetJewelEffects(baseProps, vItem[INSTANCE_SLOTS], typeId, vItem[INSTANCE_GRIDINDEX], jewelPct)
        local equipProps   = self:GetEquipAttri(itemData, avatarLevel)
        local enhanceLevel = self:GetEnhanceStarRate(baseProps, equipProps, itemData, bodyEnhance, bPosiPct)
        local mark = vItem[ITEM_INSTANCE_EXTINFO][ITEM_EXTINFO_ACTIVE] or ITEM_ACTIVED_NO
        if mark == ITEM_ACTIVED_OK then
            self:SuitNumberAccumulate(typeId, suitProps)
        end
    end
    self:GetSuitAttri(baseProps, suitProps)
    return baseProps
end
--获取装备永久属性值
function PropsSystem:GetEquipAttri(itemData, avatarLevel)
    local level = self:GetLevelkey(itemData, avatarLevel)
    local equipAttri = self:GetPrivAttri(itemData, level)
    return equipAttri
end
--获取竞技场等级属性
function PropsSystem:GetArenicEffectValues(baseProps, arenicLevel)
    local effectId = g_arenic_level:GetPropEffect(arenicLevel)
    if effectId ~= nil then
        local  prop = CommonXmlConfig:GetPassivePropertyEffect(effectId)
        if prop ~= nil then
            for k, v in pairs(prop) do
                baseProps[k] = baseProps[k] + v
            end
        end
    end
end

function PropsSystem:GetFinalProps(base, addRate, addtion)
    --a = a_base * (1 + a_rate/10000) + a_addion
    local val = 0
    val = base*(1 + addRate/10000) + addtion
    return val
end
--获取战斗def，atk，hp, hitRate
function PropsSystem:GetBattleProps(battleProps)
    battleProps.hp  = self:GetHp(battleProps)
    battleProps.atk = self:GetAtk(battleProps)
    battleProps.def = self:GetDef(battleProps)
    self:GetEffectsRate(battleProps)
    return true
end
function PropsSystem:GetHp(baseProps)
    local hpBase    = baseProps.hpBase
    local hpAddRate = baseProps.hpAddRate
    local hpAddtion = baseProps.hpAddtion
    return self:GetFinalProps(hpBase, hpAddRate, hpAddtion)
end
function PropsSystem:GetAtk(baseProps)
    local attackBase    = baseProps.attackBase
    local attackAddRate = baseProps.attackAddRate
    local attackAddtion = baseProps.attackAddtion
    return self:GetFinalProps(attackBase, attackAddRate, attackAddtion)
end
function PropsSystem:GetDef(baseProps)
    local defenseBase    = baseProps.defenseBase
    local defenseAddRate = baseProps.defenseAddRate
    local defenseAddtion = baseProps.defenseAddtion
    return self:GetFinalProps(defenseBase, defenseAddRate, defenseAddtion)
end
function PropsSystem:GetEffectsRate(baseProps)
    self:GetDefenceRate(baseProps)
    self:GetCritRate(baseProps)
    self:GetAntiDefenseRate(baseProps)
    self:GetTrueStrikeRate(baseProps)
    self:GetPvpAntiRate(baseProps)
    self:GetPvpAdditionRate(baseProps)
    self:GetHitRate(baseProps)
    self:GetDamageReduceRate(baseProps)
    self:GetAntiTrueStrikeRate(baseProps)
    self:GetAntiCritRate(baseProps)
    self:GetMissRate(baseProps)
end
function PropsSystem:GetFinalRate(prop, propType, extraProp)
    local formular  = g_formular_mgr:GetFormulaCfg(propType)
    local final     = 0
    local thresHold = formular.thresHold
    local baseDeno  = formular.baseDenominator
    if prop < formular.thresHold then
        final = prop/baseDeno
    else
        local firstDeno  = formular.firstDenominator
        local firstNume  = formular.firstNumerator
        local secondDeno = formular.secondDenominator
        local secondNume = formular.secondNumerator
        local a = firstNume/firstDeno
        local b = secondNume/secondDeno
        final = prop/(a*prop + b)
    end
    final = final + extraProp
    return final
end
-- function PropsSystem:GetAntiTrueStrikeRate(baseProps)
--     local antiTrueStrikeRate = baseProps.antiTrueStrikeRate or 0
--     antiTrueStrikeRate = antiTrueStrikeRate*0.0001
--     baseProps["antiTrueStrikeRate"] =  antiTrueStrikeRate
-- end
function PropsSystem:GetDamageReduceRate(baseProps)
     local damReduceRate = baseProps.damageReduceRate or 0
     damReduceRate = damReduceRate*0.0001
     baseProps["damageReduceRate"] = damReduceRate
end
function PropsSystem:GetDefenceRate(baseProps)
    local defence      = baseProps.def or 0
    local extraDefRate = baseProps.extraDefenceRate or 0
    extraDefRate = extraDefRate*0.0001
    local defenceRate  = self:GetFinalRate(defence, PROP_RATE_DEFENCE, extraDefRate)
    baseProps['defenceRate'] = defenceRate
    baseProps['extraDefenceRate'] = extraDefRate
end
--暴击
function PropsSystem:GetCritRate(baseProps)
    local crit       = baseProps.crit
    local exCritRate = baseProps.extraCritRate or 0
    exCritRate = exCritRate*0.0001
    local critRate   = self:GetFinalRate(crit, PROP_RATE_CRIT, exCritRate)
    baseProps['critRate'] = critRate
    baseProps['extraCritRate'] = exCritRate
end
--穿透
function PropsSystem:GetAntiDefenseRate(baseProps)
    local antiDef       = baseProps.antiDefense
    local exAntiDefRate = baseProps.extraAntiDefenceRate or 0
    exAntiDefRate = exAntiDefRate*0.0001
    local antiDefRate   = self:GetFinalRate(antiDef, PROP_RATE_ANTIDEFENSE, exAntiDefRate)
    baseProps['antiDefenseRate'] = antiDefRate
    baseProps['extraAntiDefenceRate'] = exAntiDefRate
end
--破击
function PropsSystem:GetTrueStrikeRate(baseProps)
    local trueStrike       = baseProps.trueStrike
    local exTrueStrikeRate = baseProps.extraTrueStrikeRate or 0
    exTrueStrikeRate = exTrueStrikeRate*0.0001
    local trueStrikeRate   = self:GetFinalRate(trueStrike, PROP_RATE_TRUESTRIKE, exTrueStrikeRate)
    baseProps['trueStrikeRate'] = trueStrikeRate
    baseProps['extraTrueStrikeRate'] = exTrueStrikeRate
end
--pvp增伤
function PropsSystem:GetPvpAntiRate(baseProps)
    local pvpAdd          = baseProps.pvpAddition
    local pvpAdditionRate = self:GetFinalRate(pvpAdd, PROP_RATE_PVPADDITION, 0)
    baseProps['pvpAdditionRate'] = pvpAdditionRate
end
--pvp减伤
function PropsSystem:GetPvpAdditionRate(baseProps)
    local pvpAnti = baseProps.pvpAnti
    local pvpAntiRate = self:GetFinalRate(pvpAnti, PROP_RATE_PVPANTI, 0)
    baseProps['pvpAntiRate'] = pvpAntiRate
end
------------------------------------------------------------------------------------------------------
function PropsSystem:GetAntiCritRate(baseProps)
    local antiCrit = baseProps.antiCrit
    local extraAntiCritRate = baseProps.extraAntiCritRate or 0
    extraAntiCritRate = extraAntiCritRate*0.0001
    local antiCritRate = self:GetFinalRate(antiCrit, PROP_RATE_ANTICRITRATE, extraAntiCritRate)
    baseProps['antiCritRate'] = antiCritRate
    baseProps['extraAntiCritRate'] = extraAntiCritRate
end
function PropsSystem:GetAntiTrueStrikeRate(baseProps)
    local antiTrueStrike = baseProps.antiTrueStrike
    local extraAntiTrueStrikeRate = baseProps.extraAntiTrueStrikeRate or 0
    extraAntiTrueStrikeRate = extraAntiTrueStrikeRate*0.0001
    local antiTrueStrikeRate = self:GetFinalRate(antiTrueStrike, PROP_RATE_ANTITSTKRATE, extraAntiTrueStrikeRate)
    baseProps['antiTrueStrikeRate'] = antiTrueStrikeRate
    baseProps['extraAntiTrueStrikeRate'] = extraAntiTrueStrikeRate
end
function PropsSystem:GetMissRate(baseProps)
    local missRate = baseProps.missRate
    missRate = missRate*0.0001
    baseProps["missRate"] = missRate or 0
end
------------------------------------------------------------------------------------------------------
--命中
function PropsSystem:GetHitRate(baseProps)
    local bsHitRate = baseProps.baseHitRate
    local exHitRate = baseProps.extraHitRate
    local hitRate = (bsHitRate + exHitRate)*0.0001
    baseProps['baseHitRate'] = bsHitRate*0.0001
    baseProps['extraHitRate'] = exHitRate
    baseProps['hitRate'] = hitRate
end
--获取强化属性值
function PropsSystem:GetEnhanceProperty(position, level)
    local info = g_body_mgr:GetBodyInfo(position, level)
    if info and info.propertyEffectId then
        local propEffectId = info.propertyEffectId
        local prop = CommonXmlConfig:GetPassivePropertyEffect(propEffectId)
        if prop then
            return prop, error_code.ERR_BODY_ENHANCE_SUCCEED
        end
        log_game_error("PropsSystem:GetEnhanceProperty", "prop %d is nil.", propEffectId)
    end
    return nil, error_code.ERR_BODY_ENHANCE_CONFIG
end
--计算符文系统的属性值
function PropsSystem:GetRuneEffectValues(runeBag, avatarLevel, baseProps)
    if not next(runeBag) then
        return
    end
    local rune = RuneSystem:new({}) -- {} 容错处理
    rune:SetDbTable(runeBag, avatarLevel)
    local runeEffectIds = rune:BaseGetRuneEffects()
    for _, runeId in pairs(runeEffectIds) do
        local properties = CommonXmlConfig:GetPassivePropertyEffect(runeId)
        if not properties then
            log_game_error("PropsSystem:GetRuneEffectValues", "rune effect error!")
            return
        end
        for k, v in pairs(properties) do
            baseProps[k] = baseProps[k] + v
        end
    end
end
--获取身体强化加成比
function PropsSystem:GetEnhanceRate(position, level)
    local info = g_body_mgr:GetBodyInfo(position, level)
    if info and info.enhanceRate then
        return info.enhanceRate, error_code.ERR_BODY_ENHANCE_SUCCEED
    end 
    return nil, error_code.ERR_BODY_ENHANCE_CONFIG  
end
--获取带有元表设置的table
function PropsSystem:GetPrivMetaTable()
    local tbl = {}
    setmetatable(tbl, {__index = 
        function (table, key)
            return 0
        end
    })
    return tbl
end
--获取配置属性
function PropsSystem:GetCfgData(cfgType, cfgId)
    local itemData = g_itemdata_mgr:GetItem(cfgType, cfgId)
    if not itemData then
        log_game_error("PropsSystem:GetCfgData", "item cfg error:type=%d;id=%s", cfgType, tostring(cfgId))
    end
    return itemData
end
--获取装备永久属性level
function PropsSystem:GetLevelkey(itemData, avatarLevel)
    local level = 0
    if itemData.quality == ITEM_QUALITY_GOLD then
        if itemData.levelLimit < avatarLevel then
            level = itemData.levelLimit
        else
            level = avatarLevel
        end
    else
        level = itemData.levelNeed
    end
    return level
end
--获取装备的配置属性
function PropsSystem:GetPrivAttri(itemData, level)
    local key = itemData.quality .. AVATAR_ALL_VOC .. itemData.type .. level
    local equipAttri = self:GetCfgData(ITEM_TYPE_ATTRI, key)
    if not equipAttri then
        key = itemData.quality .. itemData.vocation .. itemData.type .. level
        equipAttri = self:GetCfgData(ITEM_TYPE_ATTRI, key)
        if not equipAttri then
            log_game_error("PropsSystem:GetPrivAttri", "equipment attri nil:typeId=%d;key=%s", itemData.id, key)
            return 
        end
    end
    return equipAttri
end
--获取装备的星级强化加成比
function PropsSystem:GetEnhanceStarRate(baseProps, equipProps, itemData, bodyEnhance, bPosiPct)
    local posi  = itemData.type
    local enhanceLevel = bodyEnhance[posi]
    local enhanceRate, errCode = self:GetEnhanceRate(posi, enhanceLevel)
    local addRate = 1
    if errCode == error_code.ERR_BODY_ENHANCE_SUCCEED then
       addRate = addRate + enhanceRate*0.0001 --添加身体强化星级加成比
    end
    addRate = addRate + bPosiPct  --附魔加成比
    for tk, tv in pairs(equipProps) do
        if tk == "hpBase" or tk == "attackBase" 
            or tk == "defenseBase" then
            baseProps[tk] = baseProps[tk] + tv*addRate
        else
            baseProps[tk] = baseProps[tk] + tv
        end
    end
    return enhanceLevel
end
--计算已镶嵌宝石的属性值
function PropsSystem:GetJewelEffects(baseProps, slots, typeId, posi, jewelPct)
    for k, v in pairs(slots) do  --加宝石属性
        local jewel = self:GetCfgData(ITEM_TYPE_CONFIGURE, v)
        if jewel then
            local propEffectId = jewel.propertyEffectId --获取宝石的加成属性配置
            local jewelAttri = self:GetCfgData(ITEM_TYPE_JEWELATTRI, propEffectId)
            if jewelAttri then
                for tk, tv in pairs(jewelAttri) do  --累加属性值到baseProps中
                    baseProps[tk] = baseProps[tk] + tv*(1 + jewelPct)
                end
            end
        end
    end
end
--计算已穿戴装备的属性值
function PropsSystem:GetBodyEnhanceAttri(baseProps, posi, enhanceLevel)
    local bodyAttri, errCode = self:GetEnhanceProperty(posi, enhanceLevel)
    if errCode == error_code.ERR_BODY_ENHANCE_SUCCEED then
        for tk, tv in pairs(bodyAttri) do
            baseProps[tk] = baseProps[tk] + tv
        end
    end
end
--获取套装属性
function PropsSystem:GetSuitAttri(baseProps, suitProps)
    for suitId, cnt in pairs(suitProps) do
        local suitAttri = self:GetCfgData(ITEM_TYPE_SUIT, suitId)
        if suitAttri then
            local suits = suitAttri.suitId or {}
            self:CheckSuitDemand(baseProps, suits, cnt)
        end
    end
end
function PropsSystem:SuitNumberAccumulate(typeId, suitProps)
    local itemData = self:GetCfgData(ITEM_TYPE_CONFIGURE, typeId)
    if not itemData.suitId or itemData.suitId <= 0 then
        return
    end
    local suitId = itemData.suitId
    local num = suitProps[suitId] or 0
    suitProps[suitId] = num + 1
end
--检查套装需求
function PropsSystem:CheckSuitDemand(baseProps, suits, currNum)
    for count, effectId in pairs(suits) do --统一套装id对应多个配置，需求件数不同,满足要求对属性叠加
        if count <= currNum then
            self:AddSuitAttri(baseProps, effectId)
        end
    end
end
--累加套装属性
function PropsSystem:AddSuitAttri(baseProps, effectId)
    local props = CommonXmlConfig:GetPassivePropertyEffect(effectId) or {}
    for k, v in pairs(props) do
        baseProps[k] = baseProps[k] + v
    end
end

function PropsSystem:GetBodyMagicAttrByIdx(allMagic, posi, typeId)
    local posiInfo = allMagic[posi] or {}
    if next(posiInfo) then
        local attrInfo = Enchantment:UpdateProps(posiInfo, typeId)
        return attrInfo
    end
    return {}
end
function PropsSystem:GetMagicEffects(baseProps, magicInfo)
    for key, val in pairs(magicInfo) do
        if key == "extraHitRate" or 
           key == "antiCritRate" or 
           key == "antiTrueStrikeRate" then
           val = val*10000
        end
        baseProps[key] = baseProps[key] + val
    end
    baseProps["jewelPct"] = nil
    baseProps["bPosiPct"] = nil
    baseProps["levelPct"] = nil
end 
----------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------



battleAttri = PropsSystem
return battleAttri
