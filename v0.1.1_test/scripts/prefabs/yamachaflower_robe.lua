-- 山茶花羽织 - 简化版
local assets = {
    Asset("ANIM", "anim/yamachaflower_robe.zip"), -- 使用草甲的动画
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "armor_grass", "swap_body")
    
    -- 提供80%的护甲值和5%的移速加成
    if owner.components.locomotor then
        owner.components.locomotor:SetExternalSpeedMultiplier(owner, "yamachaflower_robe", 1.05)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    
    if owner.components.locomotor then
        owner.components.locomotor:RemoveExternalSpeedMultiplier(owner, "yamachaflower_robe")
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("yamachaflower_robe")
    inst.AnimState:SetBuild("yamachaflower_robe")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("voxitem")
    inst:AddTag("armor")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable:SetDescription("Vox的专属羽织，提供防护和移速加成")
    
    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(999999, 0.8) -- 超高耐久度，80%护甲值
    inst.components.armor.indestructible = true

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("yamachaflower_robe", fn, assets)