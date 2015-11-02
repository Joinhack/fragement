require "HpBottleType"
require "lua_util"
require "vip_privilege"
require "public_config"
require "reason_def"
require "mission_data"

local log_game_debug = lua_util.log_game_debug
local log_game_error = lua_util.log_game_error
local log_game_info  = lua_util.log_game_info

local HpSystem = {}
HpSystem.__index = HpSystem

function HpSystem:UseHpBottle(avatar)
    local vipPrivs = g_vip_mgr:GetVipPrivileges(avatar.VipLevel)
    if avatar.hpCount <= 0 then
        avatar:ShowTextID(CHANNEL.TIPS, error_code.ERR_HP_BOTTLE_UNENOUGH)
        return
    end

    local MissionTempData = avatar.tmp_data[public_config.TMP_DATA_KEY_MISSION_DATA] or {}
    local mission = MissionTempData[2] or 0
    local difficulty = MissionTempData[3] or 0

    local MissionCfg = g_mission_mgr:getCfgById(mission .. "_" .. difficulty)
    if not MissionCfg or not MissionCfg['can_use_hpBottle'] or MissionCfg['can_use_hpBottle'] == 0 then
        log_game_debug("HpSystem:UseHpBottle", "dbid=%q;name=%s;mission=%d;difficulty=%d", avatar.dbid, avatar.name, mission, difficulty)
        avatar:ShowTextID(CHANNEL.TIPS, error_code.ERR_HP_MISSION_NOT_ALLOW)
        return
    end

    local bottles = vipPrivs.hpBottles
    if not bottles then
        avatar:ShowTextID(CHANNEL.TIPS, error_code.ERR_HP_CFG_ERROR)
        return
    end
    local hpData = 0
    for k, v in pairs(bottles) do
        hpData = g_hpBottleType_mgr:GetBottleData(k)
        if hpData == nil then
            avatar:ShowTextID(CHANNEL.TIPS, error_code.ERR_HP_CFG_ERROR)
            return
        end
    end
    if os.time() - avatar.hpTStamp < hpData.cd then
        avatar:ShowTextID(CHANNEL.TIPS, error_code.ERR_HP_CD_LIMITED)
        return
    end
    avatar.hpCount = avatar.hpCount - 1
    avatar.cell.AddBuffId(hpData.buffId)
    avatar.hpTStamp = os.time()
    avatar.client.UseHpBottleResp(0)
    return 
end

function HpSystem:BuyHpBottle(avatar)
    if avatar.hpCount > 0 then --数值为零才可以购买血瓶
        avatar:ShowTextID(CHANNEL.TIPS, error_code.ERR_HP_FORBID_BUY)
        return
    end
    local tpCount = avatar.buyCount + 1
    local vipLimits = g_vip_mgr:GetVipPrivileges(avatar.VipLevel)
    if vipLimits.hpMaxCount < tpCount then --血瓶必须有最大购买数量
        avatar:ShowTextID(CHANNEL.TIPS, error_code.ERR_HP_BUY_TIMES_LIMIT)
        return
    end
    local tp = g_priceList_mgr:GetPriceData(public_config.PRICE_LIST_BUY_TYPE_HP)
    if tp == nil then
        avatar:ShowTextID(CHANNEL.TIPS, error_code.ERR_HP_CFG_ERROR)
        return
    end
    local dias = tp.priceList[tpCount]
    if avatar.diamond < dias then
        avatar:ShowTextID(CHANNEL.TIPS, error_code.ERR_HP_FORBID_BUY)
        return
    end
    --avatar.diamond = avatar.diamond - dias
    avatar:AddDiamond(-dias, reason_def.hp_system)
    avatar.buyCount = avatar.buyCount + 1 
    avatar.hpCount = avatar.hpCount + 1
    local ret = self:UseHpBottle(avatar)
end

g_hpSystem_mgr = HpSystem
return g_hpSystem_mgr