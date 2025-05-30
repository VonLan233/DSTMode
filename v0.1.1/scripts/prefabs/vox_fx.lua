-- 这个文件包含Vox角色的所有特效
local assets =
{
    Asset("ANIM", "anim/vox_demon_fx.zip"),
}

--------------------------------------------------------------------------
-- 恶魔变身特效
--------------------------------------------------------------------------

local function CreateTransformFX()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("vox_demon_fx")
    inst.AnimState:SetBuild("vox_demon_fx")
    inst.AnimState:PlayAnimation("transform")
    inst.AnimState:SetMultColor(1.2, 0.5, 0.5, 1)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetLightOverride(0.1)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("animover", inst.Remove)
    inst.persists = false

    return inst
end

--------------------------------------------------------------------------
-- 恶魔反伤特效
--------------------------------------------------------------------------

local function CreateReflectFX()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("vox_demon_fx")
    inst.AnimState:SetBuild("vox_demon_fx")
    inst.AnimState:PlayAnimation("reflect")
    inst.AnimState:SetMultColor(1.2, 0.5, 0.5, 1)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetLightOverride(0.1)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/hit")
    
    inst:ListenForEvent("animover", inst.Remove)
    inst.persists = false

    return inst
end

--------------------------------------------------------------------------
-- 恶魔特殊攻击特效
--------------------------------------------------------------------------

local function CreateSpecialAttackFX()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("vox_demon_fx")
    inst.AnimState:SetBuild("vox_demon_fx")
    inst.AnimState:PlayAnimation("special_attack")
    inst.AnimState:SetMultColor(1.2, 0.5, 0.5, 1)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetLightOverride(0.1)
    
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/taunt")
    
    inst:ListenForEvent("animover", inst.Remove)
    inst.persists = false

    return inst
end

--------------------------------------------------------------------------
-- 恶魔环状冲击波特效
--------------------------------------------------------------------------

local function CreateShockwaveFX()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("groundpoundring_fx")
    inst.AnimState:SetBuild("groundpoundring_fx")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetMultColor(1.2, 0.3, 0.3, 1)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetLightOverride(0.1)
    
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/hit")
    
    inst:ListenForEvent("animover", inst.Remove)
    inst.persists = false
    
    inst.SetScale = function(inst, scale)
        inst.Transform:SetScale(scale, scale, scale)
    end

    return inst
end

--------------------------------------------------------------------------
-- 特效注册
--------------------------------------------------------------------------

return Prefab("vox_demon_transform_fx", CreateTransformFX, assets),
       Prefab("vox_demon_reflect_fx", CreateReflectFX, assets),
       Prefab("vox_demon_attack_fx", CreateSpecialAttackFX, assets),
       Prefab("vox_demon_shockwave_fx", CreateShockwaveFX, assets)