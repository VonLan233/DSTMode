local assets =
{
    Asset("ANIM", "anim/lord_tachi.zip"),
    Asset("ATLAS", "images/inventoryimages/lord_tachi_normal.xml"),
    Assets("ATLAS", "images/inventoryimages/lord_tachi_fire.xml"),
    Asset("IMAGE", "images/inventoryimages/lord_tachi.tex"),
}

-- inst.components.inventoryitem.imagename = "nightsword"   -- 占位
-- inst.components.inventoryitem.atlasname = "images/inventoryimages/nightsword.xml"

local function onattack(inst, owner, target)
    if owner.prefab == "vox" then
        if target and target.prefab == "dragonfly" then
            -- 对龙蝇造成1.5倍伤害
            return inst.components.weapon.damage * 1.5
        end
    end
    return inst.components.weapon.damage
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "lord_tachi", "swap_object")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    
    -- 检查是否开启了火焰附魔
    if inst.fireenabled then
        -- 添加火焰视觉效果
        if inst.firefx == nil then
            inst.firefx = SpawnPrefab("torchfire")
            inst.firefx.Transform:SetPosition(0, 0, 0)
            inst:AddChild(inst.firefx)
            
            -- 调整火焰大小和位置
            inst.firefx.Transform:SetScale(0.6, 0.6, 0.6)
        end
    end
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    
    -- 移除火焰视觉效果
    if inst.firefx ~= nil then
        inst:RemoveChild(inst.firefx)
        inst.firefx:Remove()
        inst.firefx = nil
    end
end

local function ToggleFireEnchant(inst)
    inst.fireenabled = not inst.fireenabled
    
    if inst.fireenabled then
        -- 开启火焰附魔
        inst.components.weapon.damage = inst.basedamage + 10 -- 火焰附魔额外+10伤害
        
        -- 如果已装备，添加火焰视觉效果
        if inst.components.equippable:IsEquipped() then
            if inst.firefx == nil then
                inst.firefx = SpawnPrefab("torchfire")
                inst.firefx.Transform:SetPosition(0, 0, 0)
                inst:AddChild(inst.firefx)
                inst.firefx.Transform:SetScale(0.6, 0.6, 0.6)
            end
        end
    else
        -- 关闭火焰附魔
        inst.components.weapon.damage = inst.basedamage
        
        -- 移除火焰视觉效果
        if inst.firefx ~= nil then
            inst:RemoveChild(inst.firefx)
            inst.firefx:Remove()
            inst.firefx = nil
        end
    end
end

local function UpgradeSword(inst, item, doer)
    if item and item.prefab == "redgem" and doer and doer.prefab == "vox" then
        if inst.level < 10 then
            -- 升级太刀
            inst.level = inst.level + 1
            inst.basedamage = inst.basedamage + 2
            
            -- 更新武器伤害
            if inst.fireenabled then
                inst.components.weapon.damage = inst.basedamage + 10
            else
                inst.components.weapon.damage = inst.basedamage
            end
            
            -- 移除红宝石
            item:Remove()
            
            -- 播放升级效果
            local fx = SpawnPrefab("lavaarena_player_revive_from_corpse_fx")
            fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
            
            -- 提示升级成功
            doer.components.talker:Say("太刀提升到了 "..inst.level.." 级！伤害: "..inst.components.weapon.damage)
            
            -- 满级解锁火焰附魔
            if inst.level == 10 then
                doer.components.talker:Say("太刀达到最高等级！右键可开关火焰附魔。")
                inst:AddTag("maxlevel")
            end
            
            return true
        else
            doer.components.talker:Say("太刀已经达到最高等级了。")
        end
    end
    
    return false
end

local function onRightClick(inst)
    if inst:HasTag("maxlevel") then
        ToggleFireEnchant(inst)
        
        if inst.fireenabled then
            if inst.components.inventoryitem.owner then
                inst.components.inventoryitem.owner.components.talker:Say("火焰附魔已启动！")
            end
        else
            if inst.components.inventoryitem.owner then
                inst.components.inventoryitem.owner.components.talker:Say("火焰附魔已关闭。")
            end
        end
        
        return true
    end
    
    return false
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("lord_tachi")
    inst.AnimState:SetBuild("lord_tachi")
    inst.AnimState:PlayAnimation("idle")
    
    inst:AddTag("sharp")
    inst:AddTag("voxitem")
    
    -- 允许右键使用
    inst:AddComponent("inspectable")
    
    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(59.9)
    inst.components.weapon:SetOnAttack(onattack)
    
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "lord_tachi"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/lord_tachi.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    
    -- 添加可升级组件
    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(function(inst, item)
        return item.prefab == "redgem"
    end)
    inst.components.trader.onaccept = UpgradeSword
    
    -- 太刀等级和基础伤害
    inst.level = 1
    inst.basedamage = 59.9
    inst.fireenabled = false
    
    -- 添加右键动作(满级才能开关火焰附魔)
    inst:AddComponent("useableitem")
    inst.components.useableitem:SetOnUseFn(onRightClick)
    
    -- 设置为不可损毁
    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(9999999)
    inst.components.finiteuses:SetUses(9999999)
    inst.components.finiteuses:SetOnFinished(function() end) -- 空函数，永不损坏
    
    -- 火焰附魔特效
    inst.firefx = nil
    
    MakeHauntableLaunch(inst)

    return inst
end

Prefab("lord_tachi", fn, assets)