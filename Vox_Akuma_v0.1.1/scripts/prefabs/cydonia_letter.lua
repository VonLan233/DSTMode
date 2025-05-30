-- 简化版 cydonia_letter.lua
local assets =
{
    Asset("ANIM", "anim/cydonia_letter.zip"),
    Asset("ATLAS", "images/inventoryimages/cydonia_letter.xml"),
    Asset("IMAGE", "images/inventoryimages/cydonia_letter.tex"),
}

local function onread(inst, reader)
    if reader and reader:HasTag("vox") then
        -- 回复10点san值
        if reader.components.sanity then
            reader.components.sanity:DoDelta(10)
        end
        
        -- 显示信件内容
        if reader.components.talker then
            reader.components.talker:Say("亲爱的Vox，我始终在注视着你的冒险。——Kindreds")
        end
        
        -- 播放读信音效
        if reader.SoundEmitter then
            reader.SoundEmitter:PlaySound("dontstarve/common/use_book")
        end
    else
        if reader and reader.components.talker then
            reader.components.talker:Say("这封信似乎不是写给我的...")
        end
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
    inst.components.inspectable:SetDescription("来自New Cydonia的信件")
    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "cydonia_letter"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/cydonia_letter.xml"

    inst:AddComponent("book")
    inst.components.book.onread = onread
    
    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("cydonia_letter", fn, assets)