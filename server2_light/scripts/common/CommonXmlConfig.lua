-- 公共配置
local log_game_info = lua_util.log_game_info
local log_game_debug = lua_util.log_game_debug
local log_game_error = lua_util.log_game_error
local _readXml = lua_util._readXml
--被动属性影响数据，提供给所有影响到角色被动属性的子系统使用
--effectData = {}

CommonXmlConfig = 
{
    EFFECT_PASSIVE_PROPERTY_DATA = {}, --永久性的属性提升数据
    EFFECT_PASSIVE_SKILL_DATA = {},    --被动技能影响
}
CommonXmlConfig.__index = CommonXmlConfig

function CommonXmlConfig:Read(  )
    local propEffectData = _readXml('/data/xml/PropertyEffect.xml', 'id_i')
    self.EFFECT_PASSIVE_PROPERTY_DATA = propEffectData
    --CommonXmlConfig:TestData(propEffectData)
    local passiveSkillData = _readXml('/data/xml/PassiveSkillEffect.xml', 'id_i')
    self.EFFECT_PASSIVE_SKILL_DATA = passiveSkillData
end

function CommonXmlConfig:TestData( data )
    for key, val in pairs(data) do
        if type(val) == "table" then
--            print("table [".. tostring(key).. "] = {")
            self:TestData( val )
--            print("}")
        else 
--            print(key, val)
        end
    end
end

function CommonXmlConfig:GetPassivePropertyEffect( effectId )
    local tmp = {}
    if effectId and self.EFFECT_PASSIVE_PROPERTY_DATA[effectId] then
        for key, val in pairs(self.EFFECT_PASSIVE_PROPERTY_DATA[effectId]) do
            if val ~= 0 then
                tmp[key] = val
            end
        end
    end
    return tmp
end
--todo:过滤没用的内容，减少网络传输
function CommonXmlConfig:GetPassiveSkillEffect( effectId )
    return self.EFFECT_PASSIVE_SKILL_DATA[effectId]
end
return CommonXmlConfig