local assets = {
    Asset("ANIM", "anim/vox.zip"),
    Asset("ANIM", "anim/ghost_vox_build.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("vox")
    inst.AnimState:PlayAnimation("idle")
    
    -- 确保可以在选择角色界面上正常显示
    inst:AddTag("character")
    inst:AddTag("vox")
    inst:AddTag("NOBLOCK")
    inst:AddTag("scarytoprey")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- 这个函数确保角色选择界面的预览正常运行
    inst:AddComponent("inspectable")

    return inst
end

return Prefab("vox_none", fn, assets)