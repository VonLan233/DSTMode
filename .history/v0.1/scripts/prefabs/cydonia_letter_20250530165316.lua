local assets =
{
    Asset("ANIM", "anim/cydonia_letter.zip"),
    Asset("ATLAS", "images/inventoryimages/cydonia_letter.xml"),
    Asset("IMAGE", "images/inventoryimages/cydonia_letter.tex"),
}

nst.components.inventoryitem.imagename = "book"         -- 占位
inst.components.inventoryitem.atlasname = "images/inven

local function onread(inst, reader)
    if reader.prefab == "vox" then
        -- 回复10点san值
        if reader.components.sanity then
            reader.components.sanity:DoDelta(10)
        end
        
        -- 显示信件内容
        reader.components.talker:Say("亲爱的Vox，我始终在注视着你的冒险。不要忘记你的使命，也不要忘记你真正的力量来源。\n——Kindreds")
        
        -- 播放读信效果
        reader.SoundEmitter:PlaySound("dontstarve/common/use_book")
        
        -- 视觉效果
        local fx = SpawnPrefab("fx_book_light")
        if fx then
            fx.Transform:SetPosition(reader.Transform:GetWorldPosition())
        end
    else
        reader.components.talker:Say("这封信似乎不是写给我的...")
    end
    
    return true
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("cydonia_letter")
    inst.AnimState:SetBuild("cydonia_letter")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("voxitem")
    inst:AddTag("readablebook")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "cydonia_letter"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/cydonia_letter.xml"

    inst:AddComponent("book")
    inst.components.book.onread = onread
    
    MakeHauntableLaunch(inst)

    return inst
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("cydonia_letter")
    inst.AnimState:SetBuild("cydonia_letter")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("voxitem")
    inst:AddTag("readablebook")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "cydonia_letter"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/cydonia_letter.xml"

    inst:AddComponent("book")
    inst.components.book.onread = onread
    
    MakeHauntableLaunch(inst)

    return inst
end

Prefab("cydonia_letter", fn, assets)