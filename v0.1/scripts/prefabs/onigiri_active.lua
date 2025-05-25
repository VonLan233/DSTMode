-- 参照bernie_active.lua的结构重构onigiri_active
local brain = require("brains/onigiribrain") -- 此处假设已存在该brain文件，如果没有需要创建

local assets =
{
    Asset("ANIM", "anim/onigiri.zip"),
    Asset("ANIM", "anim/onigiri_active.zip"),
    Asset("SOUND", "sound/together.fsb"),
}

local prefabs =
{
    "onigiri_inactive",
    "onigiri_big", -- 激活状态的onigiri
    "onigiri_ragefx",
}

local function GoInactive(inst)
    local inactive = SpawnPrefab("onigiri_inactive")
    if inactive ~= nil then
        inactive.Transform:SetPosition(inst.Transform:GetWorldPosition())
        inactive.Transform:SetRotation(inst.Transform:GetRotation())
        
        -- 传递冷却状态
        local ragecooldown = inst.components.timer:GetTimeLeft("rage_cooldown") 
        if ragecooldown ~= nil then
            inactive.components.timer:StartTimer("rage_cooldown", ragecooldown)
        end
        
        inst:Remove()
        return inactive
    end
end

local function GoBig(inst, leader)
    if leader.bigonigiris then
        return
    end

    local big = SpawnPrefab("onigiri_big")
    if big ~= nil then
        if not leader.bigonigiris then
            leader.bigonigiris = {}
        end

        leader.bigonigiris[big] = true
        
        big.Transform:SetPosition(inst.Transform:GetWorldPosition())
        big.Transform:SetRotation(inst.Transform:GetRotation())
        
        if inst.components.health ~= nil then
            big.components.health:SetPercent(inst.components.health:GetPercent())
        end

        big:OnLeaderChanged(leader)

        inst:Remove()

        return big
    end
end

local function ReplaceOnPickup(inst, container, src_pos)
    local inactive = GoInactive(inst)

    if inactive ~= nil then
        container:GiveItem(inactive, nil, src_pos)
    end

    return true -- True because inst was removed.
end

local function OnPickup(inst, pickupguy, src_pos)
    ReplaceOnPickup(inst, pickupguy.components.inventory, src_pos)
    return true -- True because inst was removed.
end

local function OnPutInInventory(inst, owner)
    ReplaceOnPickup(inst, owner.components.container or owner.components.inventory, inst:GetPosition())
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

local function OnSave(inst, data)
    data.onigiriowner = inst.onigiriowner ~= nil and inst.onigiriowner.GUID or nil
    
    local ragecooldown = inst.components.timer:GetTimeLeft("rage_cooldown")
    if ragecooldown ~= nil then
        data.ragecooldown = ragecooldown
    end
end

local function OnLoad(inst, data)
    if data ~= nil then
        if data.ragecooldown ~= nil then
            inst.components.timer:StartTimer("rage_cooldown", data.ragecooldown)
        end
    end
end

local function OnLoadPostPass(inst, newents, data)
    if data ~= nil and data.onigiriowner ~= nil then
        local owner = newents[data.onigiriowner]
        if owner ~= nil then
            inst.onigiriowner = owner.entity
            inst:ListenForEvent("death", function() inst:GoInactive() end, owner.entity)
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

    MakeCharacterPhysics(inst, 50, .25)
    inst.DynamicShadow:SetSize(1, .5)
    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("onigiri")
    inst.AnimState:SetBuild("onigiri_active")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst:AddTag("smallcreature")
    inst:AddTag("companion")
    inst:AddTag("soulless")
    inst:AddTag("onigiri")
    inst:AddTag("voxitem")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(100)
    inst.components.health.nofadeout = true

    inst:AddComponent("inspectable")
    
    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 4 -- 根据需要调整
    
    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(0) -- 非暴走状态无伤害
    inst.components.combat:SetRange(2)
    
    inst:AddComponent("timer")
    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnPickupFn(OnPickup)
    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)
    inst.components.inventoryitem:SetSinks(true)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:SetStateGraph("SGonigiri") -- 假设已存在此状态图，需要创建
    inst:SetBrain(brain)

    inst.GoInactive = GoInactive
    inst.GoBig = GoBig
    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake
    
    -- 保存加载函数
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnLoadPostPass = OnLoadPostPass

    return inst
end

return Prefab("onigiri_active", fn, assets, prefabs)