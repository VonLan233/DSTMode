-- 简单工作版 onigiri.lua
local assets =
{
    Asset("ANIM", "anim/onigiri.zip"),
    Asset("ATLAS", "images/inventoryimages/onigiri.xml"),
    Asset("IMAGE", "images/inventoryimages/onigiri.tex"),
}

-- 激活函数
local function Activate(inst, owner)
    if inst.is_active then return end
    
    inst.is_active = true
    inst.owner = owner
    
    -- 改变外观表示激活
    inst.AnimState:SetScale(1.2, 1.2, 1.2)
    inst.AnimState:SetMultColor(1, 0.8, 0.8, 1)
    
    if owner and owner.components.talker then
        owner.components.talker:Say("饭团启动了!")
    end
    
    -- 定期攻击附近敌人
    inst.attack_task = inst:DoPeriodicTask(2, function()
        if not inst.owner or not inst.owner:IsValid() then
            inst:Remove()
            return
        end
        
        local x, y, z = inst.Transform:GetWorldPosition()
        local enemies = TheSim:FindEntities(x, y, z, 8, {"_combat"}, {"player", "companion"})
        
        for _, enemy in ipairs(enemies) do
            if enemy.components.health and not enemy.components.health:IsDead() then
                enemy.components.health:DoDelta(-51) -- AOE伤害
                
                -- 简单的伤害特效
                if enemy.SoundEmitter then
                    enemy.SoundEmitter:PlaySound("dontstarve/creatures/spider/hurt")
                end
            end
        end
    end)
    
    -- 30秒后自动失效
    inst.deactivate_task = inst:DoTaskInTime(30, function()
        if inst.owner and inst.owner.components.talker then
            inst.owner.components.talker:Say("饭团累了...")
        end
        
        -- 变回普通状态
        inst.is_active = false
        inst.owner = nil
        inst.AnimState:SetScale(1, 1, 1)
        inst.AnimState:SetMultColor(1, 1, 1, 1)
        
        if inst.attack_task then
            inst.attack_task:Cancel()
            inst.attack_task = nil
        end
    end)
end

-- 检查是否可以激活
local function CanActivate(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    return owner ~= nil and owner:HasTag("vox") and owner.components.health and owner.components.health:GetPercent() <= 0.3
end

-- 当掉落在地上时检查是否应该激活
local function OnDropped(inst)
    if inst:CanActivate() then
        local owner = inst.components.inventoryitem:GetGrandOwner()
        inst:Activate(owner)
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
    inst:AddTag("onigiri")
    inst:AddTag("voxitem")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable:SetDescription("Vox的专属饭团伙伴")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "onigiri"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/onigiri.xml"
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)

    -- 添加函数
    inst.CanActivate = CanActivate
    inst.Activate = Activate
    
    -- 初始状态
    inst.is_active = false
    inst.owner = nil

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("onigiri", fn, assets)