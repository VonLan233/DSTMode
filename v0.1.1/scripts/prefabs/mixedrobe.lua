
local assets =
{
    Asset("ANIM", "anim/mixedrobe.zip"),
    Asset("ATLAS", "images/inventoryimages/mixedrobe.xml"),
    Asset("IMAGE", "images/inventoryimages/mixedrobe.tex"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "mixedrobe", "swap_body")
    
    -- 提供85%的护甲值和10%的移速加成
    inst.components.armor:SetAbsorption(0.85)
    
    if owner.components.locomotor then
        owner.components.locomotor:SetExternalSpeedMultiplier(owner, "mixedrobe", 1.1)
    end
    
    -- 混天绫特效
    if inst.fx == nil then
        inst.fx = SpawnPrefab("wathgrithr_spirit")
        inst.fx.entity:SetParent(owner.entity)
        inst.fx.Transform:SetPosition(0, -0.25, 0)
        inst.fx.Transform:SetScale(0.7, 0.7, 0.7)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    
    if owner.components.locomotor then
        owner.components.locomotor:RemoveExternalSpeedMultiplier(owner, "mixedrobe")
    end
    
    -- 移除特效
    if inst.fx ~= nil then
        inst.fx:Remove()
        inst.fx = nil
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("mixedrobe")
    inst.AnimState:SetBuild("mixedrobe")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("voxitem")
    inst:AddTag("maxlevelitem")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "mixedrobe"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/mixedrobe.xml"

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(0, 0.85) -- 无耐久，85%护甲值
    inst.components.armor.indestructible = true

    MakeHauntableLaunch(inst)

    return inst
end

Prefab("mixedrobe", fn, assets)