-- 手动实现的 vox.lua - 完全避免 player_common
local assets = {
    Asset("ANIM", "anim/vox.zip"),
    Asset("ANIM", "anim/ghost_vox_build.zip"),
}

-- 通用初始化（客户端和服务器）
local function common_postinit(inst)
    inst:AddTag("vox")
    inst:AddTag("demonicswordsman")
    inst:AddTag("player")
    
    -- 音效设置
    inst.soundsname = "wilson"
    
    -- 小地图图标
    inst.MiniMapEntity:SetIcon("vox.tex")
end

-- 服务器端初始化
local function master_postinit(inst)
    -- 基础属性
    inst.components.health:SetMaxHealth(200)
    inst.components.hunger:SetMax(150)
    inst.components.sanity:SetMax(120)
    
    -- 标签
    inst:AddTag("hates_seafood")
    
    -- 新角色出生时给予初始物品
    inst.starting_inventory = {
        "yamachaflower_robe",
        "cydonia_letter", 
        "onigiri",
    }
    
    -- 实际给予初始物品的函数
    inst.OnSpawnInventory = function(inst)
        for _, item in ipairs(inst.starting_inventory) do
            local spawned_item = SpawnPrefab(item)
            if spawned_item then
                inst.components.inventory:GiveItem(spawned_item)
            end
        end
    end
    
    -- 延迟给予物品（确保组件已初始化）
    inst:DoTaskInTime(0, function()
        if inst.OnSpawnInventory then
            inst.OnSpawnInventory(inst)
        end
    end)
end

-- 创建角色预制体的主函数
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()
    inst.entity:AddMiniMapEntity()

    -- 物理设置
    MakeCharacterPhysics(inst, 75, .5)
    inst.DynamicShadow:SetSize(1.3, .6)
    inst.Transform:SetFourFaced()

    -- 动画设置
    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("vox")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:Hide("ARM_carry")
    inst.AnimState:Hide("hat")
    inst.AnimState:Hide("hat_hair")

    -- 基础标签
    inst:AddTag("character")
    inst:AddTag("scarytoprey")

    -- 通用初始化
    common_postinit(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- === 服务器端组件 ===
    
    -- 移动组件
    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.WILSON_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED

    -- 基础组件
    inst:AddComponent("inventory")
    inst:AddComponent("inspectable")
    
    -- 生命值组件
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(200)
    
    -- 饥饿值组件
    inst:AddComponent("hunger")
    inst.components.hunger:SetMax(150)
    
    -- 理智值组件
    inst:AddComponent("sanity")
    inst.components.sanity:SetMax(120)
    
    -- 战斗组件
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "torso"
    inst.components.combat.damagemultiplier = 1.0
    
    -- 温度组件
    inst:AddComponent("temperature")
    
    -- 饮食组件
    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODGROUP.OMNI }, { FOODGROUP.OMNI })
    
    -- 建造组件
    inst:AddComponent("builder")
    
    -- 湿度组件
    inst:AddComponent("moisture")
    
    -- 冰冻组件
    inst:AddComponent("freezable")
    
    -- 眩晕组件
    inst:AddComponent("grogginess")
    inst.components.grogginess:SetResistance(3)
    
    -- 工作组件
    inst:AddComponent("worker")
    
    -- 玩家控制组件
    inst:AddComponent("playercontroller")
    
    -- 发言组件
    inst:AddComponent("talker")
    inst.components.talker.fontsize = 35
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.offset = Vector3(0, -400, 0)
    
    -- 角色专用组件
    inst:AddComponent("playerlightningtarget")
    inst:AddComponent("playervision")
    
    -- 服务器端初始化
    master_postinit(inst)

    -- 设置描述信息（用于角色选择界面）
    inst.displayname = "Vox"
    inst.charactername = "vox"
    
    return inst
end

return Prefab("vox", fn, assets)