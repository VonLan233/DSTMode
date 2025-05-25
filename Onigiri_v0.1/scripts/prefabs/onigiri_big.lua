-- 参照bernie_big.lua的结构重构onigiri_big
local brain = require("brains/onigiribigbrain") -- 此处假设已存在该brain文件，如果没有需要创建

local assets =
{
    Asset("ANIM", "anim/onigiri_big.zip"),
    Asset("ANIM", "anim/onigiri_rage.zip"),
}

local fireassets =
{
    Asset("ANIM", "anim/onigiri_fire_fx.zip"),
}

local prefabs =
{
    "onigiri_inactive",
    "onigiri_fire",
}

local TARGET_DIST = 15
local TAUNT_DIST = 20
local TAUNT_PERIOD = 2

local function OnReflectDamage(inst, data)
    if data.attacker ~= nil and data.attacker:IsValid() then
        local impactfx = SpawnPrefab("impact")
        if impactfx ~= nil then
            if data.attacker.components.combat ~= nil then
                local follower = impactfx.entity:AddFollower()
                follower:FollowSymbol(data.attacker.GUID, data.attacker.components.combat.hiteffectsymbol, 0, 0, 0)
            else
                impactfx.Transform:SetPosition(data.attacker.Transform:GetWorldPosition())
            end
            impactfx:FacePoint(inst.Transform:GetWorldPosition())
        end
    end
end

local function EndFireEffect(inst)
    if inst.fire_fx then
        inst.fire_fx:Remove()
        inst.fire_fx = nil
    end
    if inst.fire_task then
        inst.fire_task:Cancel()
        inst.fire_task = nil
    end
    inst:RemoveComponent("damagereflect")
    inst:RemoveEventCallback("onreflectdamage", OnReflectDamage)
end

local function GoInactive(inst)
    local inactive = SpawnPrefab("onigiri_inactive")
    if inactive ~= nil then
        inactive.Transform:SetPosition(inst.Transform:GetWorldPosition())
        inactive.Transform:SetRotation(inst.Transform:GetRotation())
        
        -- 开始冷却计时器
        inactive.components.timer:StartTimer("rage_cooldown", 60) -- 60秒冷却
        
        inst:Remove()
        return inactive
    end

    EndFireEffect(inst)
end

local function IsTauntable(inst, target)
    return not (target.components.health ~= nil and target.components.health:IsDead())
        and target.components.combat ~= nil
        and not target.components.combat:TargetIs(inst)
        and target.components.combat:CanTarget(inst)
        and (
                target:HasTag("monster") or
                (target.components.combat:HasTarget() and
                    (target.components.combat.target:HasTag("player") or
                    target.components.combat.target:HasTag("companion"))
                )
            )
end

local function IsTargetable(inst, target)
    return not (target.components.health ~= nil and target.components.health:IsDead())
        and target.components.combat ~= nil
        and target.components.combat:CanTarget(inst)
        and (target.components.combat:TargetIs(inst) or
            target:HasTag("monster") or
            (target.components.combat:HasTarget() and
                (target.components.combat.target:HasTag("player") or
                target.components.combat.target:HasTag("companion"))
            )
            or
            (inst.onigiriowner and 
                inst.onigiriowner.components.combat:HasTarget() and
                inst.onigiriowner.components.combat.target == target)
        )
end

local TAUNT_MUST_TAGS = { "_combat" }
local TAUNT_CANT_TAGS = { "INLIMBO", "player", "companion", "epic", "notaunt"}
local TAUNT_ONEOF_TAGS = { "locomotor" }

local function TauntCreatures(inst)
    if not inst.components.health:IsDead() then
        local x, y, z = inst.Transform:GetWorldPosition()
        for i, v in ipairs(TheSim:FindEntities(x, y, z, TAUNT_DIST, TAUNT_MUST_TAGS, TAUNT_CANT_TAGS, TAUNT_ONEOF_TAGS)) do
            if IsTauntable(inst, v) then
                v.components.combat:SetTarget(inst)
            end
        end
    end
end

local function OnLoadInit(inst)
    inst._taunttask:Cancel()
    inst._taunttask = inst:DoPeriodicTask(TAUNT_PERIOD, TauntCreatures, math.random() * TAUNT_PERIOD)
    inst.sg:GoToState("idle")
end

local RETARGET_MUST_TAGS = { "_combat" }
local RETARGET_CANT_TAGS = { "INLIMBO", "player", "companion", "retaliates"}
local RETARGET_ONEOF_TAGS = { "locomotor", "epic" }

local function RetargetFn(inst)
    if inst.components.combat:HasTarget() then
        return
    end
    
    -- 优先攻击主人的目标
    if inst.onigiriowner ~= nil and inst.onigiriowner.components.combat ~= nil and inst.onigiriowner.components.combat:HasTarget() then
        return inst.onigiriowner.components.combat.target
    end
    
    local x, y, z = inst.Transform:GetWorldPosition()
    for i, v in ipairs(TheSim:FindEntities(x, y, z, TARGET_DIST, RETARGET_MUST_TAGS, RETARGET_CANT_TAGS, RETARGET_ONEOF_TAGS)) do
        if IsTargetable(inst, v) then
            return v
        end
    end
end

local function KeepTargetFn(inst, target)
    return inst.components.combat:CanTarget(target) and inst:IsNear(target, TARGET_DIST) and not target:HasTag("retaliates")
end

local function ShouldAggro(combat, target)
    if target:HasTag("player") then
        return TheNet:GetPVPEnabled()
    end
    return true
end

local function OnAttacked(inst, data)
    local attacker = data ~= nil and data.attacker or nil
    if attacker ~= nil and not PreventTargetingOnAttacked(inst, attacker, TheNet:GetPVPEnabled() and "onigiriowner" or "player") then
        local target = inst.components.combat.target
        if not (target ~= nil and target:IsValid() and inst:IsNear(target, 3 + target:GetPhysicsRadius(0))) then
            inst.components.combat:SetTarget(attacker)
        end
    end
end

local function OnSleepTask(inst)
    inst._sleeptask = nil
    inst:GoInactive()
end

local function OnEntitySleep(inst)
    if inst._sleeptask ~= nil then
        inst._sleeptask = inst:DoTaskInTime(.5, OnSleepTask)
    end
end

local function OnEntityWake(inst)
    if inst._sleeptask ~= nil then
        inst._sleeptask:Cancel()
        inst._sleeptask = nil
    end
end

local function OnLeaderChanged(inst, leader)    
    if inst.onigiriowner ~= leader then
        inst.onigiriowner = leader
    end
    
    -- 基于主人属性调整onigiri的能力
    if leader then
        -- 添加暴走特效
        if inst.fire_fx == nil then
            inst.fire_fx = SpawnPrefab("onigiri_fire")
            inst.fire_fx.entity:SetParent(inst.entity)
            inst.fire_fx.AnimState:SetFinalOffset(-3)

            inst:AddComponent("damagereflect")
            inst.components.damagereflect:SetDefaultDamage(15) -- 反伤伤害
            inst:ListenForEvent("onreflectdamage", OnReflectDamage)
        end
        
        -- 设置持续时间
        if inst.fire_task == nil then
            inst.fire_task = inst:DoTaskInTime(15, function()
                EndFireEffect(inst)
                inst:GoInactive()
            end)
        end
    end
end

local function OnSave(inst, data)
    data.onigiriowner = inst.onigiriowner ~= nil and inst.onigiriowner.GUID or nil
end

local function OnLoad(inst, data)
    -- 没有特别需要加载的数据
end

local function OnLoadPostPass(inst, newents, data)
    if data ~= nil and data.onigiriowner ~= nil then
        local owner = newents[data.onigiriowner]
        if owner ~= nil then
            inst.onigiriowner = owner.entity
            inst:OnLeaderChanged(owner.entity)
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 500, .65)
    inst.DynamicShadow:SetSize(2.5, 1.5)

    inst.Transform:SetScale(1.2, 1.2, 1.2)
    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("onigiri_big")
    inst.AnimState:SetBuild("onigiri_rage")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst:AddTag("largecreature")
    inst:AddTag("companion")
    inst:AddTag("soulless")
    inst:AddTag("onigiri")
    inst:AddTag("raging")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(150)
    inst.components.health.nofadeout = true

    inst:AddComponent("inspectable")

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 6
    inst.components.locomotor.runspeed = 8

    inst:AddComponent("drownable")

    -- 启用船跳跃
    inst.components.locomotor:SetAllowPlatformHopping(true)
    inst:AddComponent("embarker")

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(51)
    inst.components.combat:SetAttackPeriod(2)
    inst.components.combat:SetRange(3, 4)
    inst.components.combat:SetRetargetFunction(1, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat:SetShouldAggroFn(ShouldAggro)
    inst.components.combat.battlecryinterval = 16
    inst.components.combat.hiteffectsymbol = "body"
    inst.components.combat:SetAreaDamage(3, 1) -- 3格范围AOE伤害

    inst:AddComponent("timer")

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst.hit_recovery = 0.5 -- 被击中后恢复时间

    inst:SetStateGraph("SGonigiribig") -- 需要创建此状态图
    inst:SetBrain(brain)

    inst._taunttask = inst:DoPeriodicTask(TAUNT_PERIOD, TauntCreatures, 0)
    inst.OnLoad = OnLoad
    inst.OnLoadInit = OnLoadInit
    inst.GoInactive = GoInactive
    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake
    inst.OnLeaderChanged = OnLeaderChanged
    
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnLoadPostPass = OnLoadPostPass

    inst:ListenForEvent("attacked", OnAttacked)

    return inst
end

local function FireFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()    
    inst.entity:AddNetwork()

    inst.Light:SetFalloff(1)
    inst.Light:SetIntensity(0.7)
    inst.Light:SetRadius(3)
    inst.Light:SetColour(1, 0.3, 0.3)
    inst.Light:Enable(true)
    inst.Light:EnableClientModulation(true)
    
    inst.AnimState:SetBank("onigiri_fire_fx")
    inst.AnimState:SetBuild("onigiri_fire_fx")
    inst.AnimState:PlayAnimation("fire_pre", false)
    inst.AnimState:PushAnimation("fire_loop", true)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetMultColour(1, 0.5, 0.3, 1)

    inst.SoundEmitter:PlaySound("dontstarve/common/campfire", "firelp")

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("onigiri_big", fn, assets, prefabs),
       Prefab("onigiri_fire", FireFn, fireassets)