-- 增强版 vox.lua
local MakePlayerCharacter = require "prefabs/player_common"

local assets = {
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
    Asset("ANIM", "anim/vox.zip"),
    Asset("ANIM", "anim/ghost_vox_build.zip"),
}

-- 初始物品
local start_inv = {
    "yamchaflower_robe",
    "cydonia_letter", 
    "onigiri",
}

-- 通用初始化
local function common_postinit(inst)
    inst:AddTag("vox")
    inst:AddTag("demonicswordsman")
    
    -- 使用wilson的音效
    inst.soundsname = "wilson"
    inst.talker_path_override = "dontstarve/characters/wilson/talk_LP"
end

-- 主要初始化
local function master_postinit(inst)
    -- 设置属性
    inst.components.health:SetMaxHealth(TUNING.VOX_STATS.HEALTH)
    inst.components.hunger:SetMax(TUNING.VOX_STATS.HUNGER)
    inst.components.sanity:SetMax(TUNING.VOX_STATS.SANITY)
    
    -- 海鲜厌恶标签
    inst:AddTag("hates_seafood")
    
    -- 战斗设置
    inst.components.combat.damagemultiplier = 1.0
    inst.components.combat:SetRange(2)
    
    -- Boss能力相关的工作效率加成
    local old_GetEffectiveness = inst.components.worker.GetEffectiveness
    inst.components.worker.GetEffectiveness = function(self, action)
        local eff = old_GetEffectiveness(self, action)
        if inst.work_efficiency_mult and (action == ACTIONS.CHOP or action == ACTIONS.MINE) then
            return eff * inst.work_efficiency_mult
        end
        return eff
    end
    
    -- 火焰免疫处理
    local old_DoDelta = inst.components.health.DoDelta
    inst.components.health.DoDelta = function(self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
        if inst.fire_immunity and cause == "fire" then
            return 0
        end
        return old_DoDelta(self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    end
    
    -- 新玩家生成时给予初始物品
    inst.OnNewSpawn = function(inst)
        inst.components.inventory:GiveItem(SpawnPrefab("yamchaflower_robe"))
        inst.components.inventory:GiveItem(SpawnPrefab("cydonia_letter"))
        inst.components.inventory:GiveItem(SpawnPrefab("onigiri"))
    end
    
    -- 保存/加载Boss能力
    inst.OnSave = function(inst, data)
        if inst.current_boss_ability then
            data.current_boss_ability = inst.current_boss_ability
            if inst.boss_ability_task then
                data.ability_time_left = inst.boss_ability_task.time
            end
        end
    end
    
    inst.OnLoad = function(inst, data)
        if data and data.current_boss_ability then
            local ability = BOSS_ABILITIES[data.current_boss_ability]
            if ability and data.ability_time_left then
                -- 恢复Boss能力
                inst.current_boss_ability = data.current_boss_ability
                inst:AddTag(data.current_boss_ability.."_buff")
                
                -- 重新应用效果
                if data.current_boss_ability == "deerclops" and inst.components.freezable then
                    inst.components.freezable:SetResistance(999)
                elseif data.current_boss_ability == "bearger" then
                    inst.work_efficiency_mult = 2
                elseif data.current_boss_ability == "dragonfly" then
                    inst.fire_immunity = true
                elseif data.current_boss_ability == "spiderqueen" then
                    inst:AddTag("spiderwhisperer")
                end
                
                -- 重新设置任务
                inst.boss_ability_task = inst:DoTaskInTime(data.ability_time_left, function()
                    -- 移除能力的逻辑...
                end)
            end
        end
    end
end

-- 创建角色函数
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 75, .5)
    inst.DynamicShadow:SetSize(1.3, .6)
    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("vox")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("scarytoprey")
    inst:AddTag("vox")
    inst:AddTag("demonicswordsman")

    -- 通用初始化
    common_postinit(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- 添加必要组件
    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.WILSON_WALK_SPEED * 1.05
    inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED * 1.05

    inst:AddComponent("inventory")
    inst:AddComponent("inspectable")
    inst:AddComponent("health")
    inst:AddComponent("hunger")
    inst:AddComponent("sanity")
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "torso"
    inst:AddComponent("temperature")
    inst:AddComponent("eater")
    inst:AddComponent("builder")
    inst:AddComponent("moisture")
    inst:AddComponent("freezable")
    inst:AddComponent("grogginess")
    inst.components.grogginess:SetResistance(3)
    inst:AddComponent("worker")

    -- 主要初始化
    master_postinit(inst)

    return inst
end

-- 返回角色
return MakePlayerCharacter("vox", fn, start_inv, assets)