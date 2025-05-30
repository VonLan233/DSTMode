-- 参照bernie_inactive.lua的结构重构onigiri_inactive

local assets =
{
    Asset("ANIM", "anim/onigiri.zip"),
    Asset("ATLAS", "images/inventoryimages/onigiri.xml"),
    Asset("IMAGE", "images/inventoryimages/onigiri.tex"),
}

local prefabs =
{
    "onigiri_active",
}

local function CanActivate(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner ~= nil and owner:HasTag("player") and owner:HasTag("vox") then
        local health = owner.components.health
        return health ~= nil and health:GetPercent() <= 0.3
    end
    return false
end

local function OnPutInInventory(inst, owner)
    -- 当放入物品栏时，停止任何可能的激活检查
    if inst._activatetask ~= nil then
        inst._activatetask:Cancel()
        inst._activatetask = nil
    end
end

local function TryActivate(inst)
    if CanActivate(inst) then
        local owner = inst.components.inventoryitem:GetGrandOwner()
        local active = SpawnPrefab("onigiri_active")
        if active ~= nil then
            active.Transform:SetPosition(inst.Transform:GetWorldPosition())
            active.Transform:SetRotation(inst.Transform:GetRotation())
            
            -- 传递冷却状态
            local cooldown = inst.components.timer:GetTimeLeft("rage_cooldown")
            if cooldown ~= nil then
                active.components.timer:StartTimer("rage_cooldown", cooldown)
            end
            
            -- 设置所有者关系
            if owner ~= nil and owner:HasTag("vox") then
                active.onigiriowner = owner
                active:ListenForEvent("death", function() active:GoInactive() end, owner)
            end
            
            inst:Remove()
            return active
        end
    end
    return nil
end

local function Activate(inst)
    if inst._activatetask == nil then
        inst._activatetask = inst:DoPeriodicTask(1, TryActivate)
    end
end

local function Deactivate(inst)
    if inst._activatetask ~= nil then
        inst._activatetask:Cancel()
        inst._activatetask = nil
    end
end

local function OnDropped(inst)
    if inst.entity:IsAwake() then
        Activate(inst)
    end
end

local function OnEntityWake(inst)
    if not inst.components.inventoryitem:IsHeld() then
        Activate(inst)
    end
end

local function OnEntitySleep(inst)
    Deactivate(inst)
end

local function OnSave(inst, data)
    -- 保存冷却状态
    local ragecooldown = inst.components.timer:GetTimeLeft("rage_cooldown")
    if ragecooldown ~= nil then
        data.ragecooldown = ragecooldown
    end
end

local function OnLoad(inst, data)
    if data ~= nil and data.ragecooldown ~= nil then
        inst.components.timer:StartTimer("rage_cooldown", data.ragecooldown)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    
    MakeInventoryPhysics(inst)
    
    inst.AnimState:SetBank("onigiri")
    inst.AnimState:SetBuild("onigiri")
    inst.AnimState:PlayAnimation("idle", true)
    
    inst:AddTag("companion")
    inst:AddTag("notraptrigger")
    inst:AddTag("noauradamage")
    inst:AddTag("onigiri")
    inst:AddTag("voxitem")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst._activatetask = nil
    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)
    inst.components.inventoryitem.imagename = "onigiri"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/onigiri.xml"
    
    inst:AddComponent("inspectable")
    
    inst:AddComponent("timer")
    
    -- 当在地上时，检查附近是否有满足条件的Vox玩家
    if not inst.components.inventoryitem:IsHeld() and inst.entity:IsAwake() then
        Activate(inst)
    end
    
    -- 保存与加载
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    
    -- 睡眠与唤醒
    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake
    
    inst.CanActivate = CanActivate

    return inst
end

return Prefab("onigiri_inactive", fn, assets, prefabs)