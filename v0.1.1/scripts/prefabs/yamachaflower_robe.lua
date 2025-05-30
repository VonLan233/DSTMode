local assets =
{
    Asset("ANIM", "anim/yamchaflower_robe.zip"),
    Asset("ATLAS", "images/inventoryimages/yamchaflower_robe.xml"),
    Asset("IMAGE", "images/inventoryimages/yamchaflower_robe.tex"),
}

inst.components.inventoryitem.imagename = "sweatervest"  -- 占位
inst.components.inventoryitem.atlasname = "images/inventoryimages/sweatervest.xml"

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "yamchaflower_robe", "swap_body")
    
    -- 提供80%的护甲值和5%的移速加成
    inst.components.armor:SetAbsorption(0.8)
    
    if owner.components.locomotor then
        owner.components.locomotor:SetExternalSpeedMultiplier(owner, "yamchaflower_robe", 1.05)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    
    if owner.components.locomotor then
        owner.components.locomotor:RemoveExternalSpeedMultiplier(owner, "yamchaflower_robe")
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("yamchaflower_robe")
    inst.AnimState:SetBuild("yamchaflower_robe")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("voxitem")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "yamchaflower_robe"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/yamchaflower_robe.xml"

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(0, 0.8) -- 无耐久，80%护甲值
    inst.components.armor.indestructible = true

    MakeHauntableLaunch(inst)

    return inst
end

Prefab("yamchaflower_robe", fn, assets)