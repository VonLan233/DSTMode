-- 饭团伙伴 - 简化版
local assets = {
    Asset("ANIM", "anim/onigiri.zip"), -- 使用伯尼的动画
}

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
    
    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("onigiri", fn, assets)