-- throne_ruin.lua (王座废墟)

local assets = 
{
    Asset("ANIM", "anim/throne_ruin.zip"),
    Asset("ANIM", "anim/throne_repaired.zip"),
    Asset("ATLAS", "images/inventoryimages/throne_ruin.xml"),
    Asset("IMAGE", "images/inventoryimages/throne_ruin.tex"),
}

local prefabs =
{
    "throne_repaired",
    "memory_ghost",
    "memory_battle",
}

-- 需要的修复材料
local repair_materials = {
    moonrock = 15,
    thulecite = 15,
    marble = 10,
    nightmarefuel = 25,
}

-- 王座和玩家的交互
local function OnRepair(inst, doer, repair_item)
    if not doer or not doer:HasTag("vox") then
        if doer and doer.components.talker then
            doer.components.talker:Say("这似乎是某个强大存在的王座，与我无关...")
        end
        return false
    end
    
    -- 检查材料是否足够
    local has_materials = true
    local materials_needed = {}
    
    for material, amount in pairs(repair_materials) do
        local current_amount = 0
        
        if doer.components.inventory then
            local items = doer.components.inventory:FindItems(function(item)
                return item.prefab == material
            end)
            
            for _, item in ipairs(items) do
                current_amount = current_amount + (item.components.stackable and item.components.stackable:StackSize() or 1)
            end
        end
        
        if current_amount < amount then
            has_materials = false
            materials_needed[material] = amount - current_amount
        end
    end
    
    if not has_materials then
        if doer.components.talker then
            local message = "我需要更多材料来修复王座: "
            for material, amount in pairs(materials_needed) do
                local material_name = STRINGS.NAMES[string.upper(material)] or material
                message = message .. material_name .. "×" .. amount .. ", "
            end
            message = message:sub(1, -3) -- 移除最后的逗号和空格
            doer.components.talker:Say(message)
        end
        return false
    end
    
    -- 消耗材料
    for material, amount in pairs(repair_materials) do
        local remaining = amount
        
        while remaining > 0 do
            local item = doer.components.inventory:FindItem(function(item)
                return item.prefab == material
            end)
            
            if item and item.components.stackable then
                local to_remove = math.min(remaining, item.components.stackable:StackSize())
                item.components.stackable:SetStackSize(item.components.stackable:StackSize() - to_remove)
                
                if item.components.stackable:StackSize() <= 0 then
                    item:Remove()
                end
                
                remaining = remaining - to_remove
            elseif item then
                item:Remove()
                remaining = remaining - 1
            else
                break
            end
        end
    end
    
    -- 显示特效
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    
    -- 播放修复音效
    inst.SoundEmitter:PlaySound("dontstarve/common/repair")
    
    -- 修复王座，生成新的修复后的王座
    local throne = SpawnPrefab("throne_repaired")
    if throne then
        throne.Transform:SetPosition(inst.Transform:GetWorldPosition())
        throne.owner = doer
        
        -- 为Vox提供生命值加成
        if doer.components.health then
            local old_max = doer.components.health.maxhealth
            doer.components.health:SetMaxHealth(old_max + 50)
            doer.components.talker:Say("我感受到了王座的力量...最大生命值提升了50点！")
        end
    end
    
    -- 移除废墟
    inst:Remove()
    
    return true
end

local function OnSave(inst, data)
    -- 保存玩家是否已经修复过王座的信息
    if inst.owner then
        data.owner_userid = inst.owner.userid
    end
end

local function OnLoad(inst, data)
    if data and data.owner_userid then
        -- 在游戏加载时找到对应的玩家
        for i, v in ipairs(AllPlayers) do
            if v.userid == data.owner_userid then
                inst.owner = v
                break
            end
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.MiniMapEntity:SetIcon("throne_ruin.tex")

    inst.AnimState:SetBank("throne_ruin")
    inst.AnimState:SetBuild("throne_ruin")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("structure")
    inst:AddTag("throne_ruin")
    
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable:SetDescription("一个古老而破败的王座，似乎与某种强大的力量相连。")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.REPAIR)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(OnRepair)
    inst.components.workable:SetOnWorkCallback(nil)
    
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    MakeHauntableWork(inst)

    return inst
end

-- throne_repaired.lua (修复后的王座)

local function OnActivate(inst, doer)
    if not doer:HasTag("vox") then
        if doer.components.talker then
            doer.components.talker:Say("这不是我的王座...")
        end
        return false
    end
    
    -- 玩家坐上王座
    if doer.components.talker then
        doer.components.talker:Say("我将在此休息片刻...")
    end
    
    -- 设置玩家为睡眠状态
    if doer.components.sleeper then
        doer.components.sleeper:AddSleepiness(10, 15)
    end
    
    -- 回复状态
    if doer.components.hunger then
        doer.components.hunger:DoDelta(150) -- 帐篷的1.5倍
    end
    
    if doer.components.sanity then
        doer.components.sanity:DoDelta(150) -- 帐篷的1.5倍
    end
    
    if doer.components.health then
        doer.components.health:DoDelta(60) -- 帐篷的1.5倍
    end
    
    -- 显示特效
    local fx = SpawnPrefab("statue_transition")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    
    -- 如果是晚上，有机会触发记忆事件
    if TheWorld.state.isnight and math.random() < 0.5 then
        inst:DoTaskInTime(1, function()
            inst:PushEvent("start_memory_event", {player = doer})
        end)
    end
    
    return true
end

local function StartMemoryEvent(inst, data)
    if not data or not data.player then return end
    
    local player = data.player
    
    if player.components.talker then
        player.components.talker:Say("我看到了过去的记忆...")
    end
    
    -- 生成记忆幽灵
    local num_ghosts = math.random(2, 5)
    inst.memory_ghosts = {}
    
    for i = 1, num_ghosts do
        local angle = i * (2 * PI / num_ghosts)
        local offset = Vector3(math.cos(angle) * 10, 0, math.sin(angle) * 10)
        local pos = Vector3(inst.Transform:GetWorldPosition()) + offset
        
        local ghost = SpawnPrefab("memory_ghost")
        if ghost then
            ghost.Transform:SetPosition(pos:Get())
            table.insert(inst.memory_ghosts, ghost)
        end
    end
    
    -- 生成战斗记忆
    local battle = SpawnPrefab("memory_battle")
    if battle then
        local pos = Vector3(inst.Transform:GetWorldPosition())
        pos.x = pos.x + 15
        battle.Transform:SetPosition(pos:Get())
        inst.memory_battle = battle
    end
    
    -- 在天亮时结束事件
    inst.memory_event_task = inst:DoPeriodicTask(1, function()
        if TheWorld.state.isday then
            inst:PushEvent("end_memory_event")
        end
    end)
end

local function EndMemoryEvent(inst)
    if inst.memory_event_task then
        inst.memory_event_task:Cancel()
        inst.memory_event_task = nil
    end
    
    -- 移除所有记忆幽灵
    if inst.memory_ghosts then
        for _, ghost in ipairs(inst.memory_ghosts) do
            if ghost:IsValid() then
                ghost:Remove()
            end
        end
        inst.memory_ghosts = nil
    end
    
    -- 移除战斗记忆
    if inst.memory_battle and inst.memory_battle:IsValid() then
        inst.memory_battle:Remove()
        inst.memory_battle = nil
    end
end

local function OnSave(inst, data)
    if inst.owner then
        data.owner_userid = inst.owner.userid
    end
end

local function OnLoad(inst, data)
    if data and data.owner_userid then
        for i, v in ipairs(AllPlayers) do
            if v.userid == data.owner_userid then
                inst.owner = v
                break
            end
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.MiniMapEntity:SetIcon("throne_repaired.tex")

    inst.AnimState:SetBank("throne_repaired")
    inst.AnimState:SetBuild("throne_repaired")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("structure")
    inst:AddTag("throne")
    
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable:SetDescription("一个修复完好的王座，充满了力量。")

    inst:AddComponent("activatable")
    inst.components.activatable.OnActivate = OnActivate
    inst.components.activatable.standingaction = true
    
    inst:ListenForEvent("start_memory_event", StartMemoryEvent)
    inst:ListenForEvent("end_memory_event", EndMemoryEvent)
    
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    MakeHauntableLaunch(inst)

    return inst
end

-- memory_ghost.lua (记忆幽灵)

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("ghost")
    inst.AnimState:SetBuild("ghost_kindred_build")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetMultColour(0.5, 0.8, 1, 0.5)
    
    inst.Light:SetRadius(2)
    inst.Light:SetFalloff(0.7)
    inst.Light:SetIntensity(.5)
    inst.Light:SetColour(0.5, 0.8, 1)
    inst.Light:Enable(true)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    
    -- 幽灵随机漂移
    inst:DoPeriodicTask(3, function()
        local pos = Vector3(inst.Transform:GetWorldPosition())
        local angle = math.random() * 2 * PI
        local distance = math.random(2, 5)
        
        local target_pos = pos + Vector3(math.cos(angle) * distance, 0, math.sin(angle) * distance)
        inst:DoTaskInTime(0.1, function()
            inst.Transform:SetPosition(target_pos:Get())
        end)
    end)

    inst.persists = false

    return inst
end

-- memory_battle.lua (记忆战斗)

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("kindred")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetMultColour(0.5, 0.8, 1, 0.5)
    
    inst.Light:SetRadius(3)
    inst.Light:SetFalloff(0.7)
    inst.Light:SetIntensity(.3)
    inst.Light:SetColour(0.5, 0.8, 1)
    inst.Light:Enable(true)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    
    -- 创建敌人投影
    inst:DoTaskInTime(0.1, function()
        local enemy = CreateEntity()
        
        enemy.entity:AddTransform()
        enemy.entity:AddAnimState()
        
        enemy.AnimState:SetBank("spider")
        enemy.AnimState:SetBuild("spider")
        enemy.AnimState:PlayAnimation("idle")
        enemy.AnimState:SetMultColour(0.5, 0.8, 1, 0.5)
        
        enemy:AddTag("FX")
        enemy:AddTag("NOCLICK")
        
        local pos = Vector3(inst.Transform:GetWorldPosition())
        pos.x = pos.x + 3
        enemy.Transform:SetPosition(pos:Get())
        
        -- 模拟战斗动画
        inst:DoPeriodicTask(3, function()
            inst.AnimState:PlayAnimation("atk")
            inst.AnimState:PushAnimation("idle", true)
            
            enemy.AnimState:PlayAnimation("hit")
            enemy.AnimState:PushAnimation("idle")
            
            inst.SoundEmitter:PlaySound("dontstarve/creatures/spiderape/attack", nil, 0.3)
        end)
        
        -- 记住敌人实体以便后续移除
        inst.enemy = enemy
    end)
    
    -- 清理函数
    inst.OnRemoveEntity = function(inst)
        if inst.enemy and inst.enemy:IsValid() then
            inst.enemy:Remove()
        end
    end
    
    inst:ListenForEvent("onremove", inst.OnRemoveEntity)
    
    inst.persists = false

    return inst
end

-- modmain.lua中添加的代码片段

-- 随机生成王座废墟
local function PlaceRandomThroneRuin()
    local function CanSpawnAt(x, y, z)
        if TheWorld.Map:IsVisualGroundAtPoint(x, y, z) and 
           not TheWorld.Map:IsPointNearHole(Vector3(x, y, z)) then
            
            -- 检查是否离其他结构太近
            local ents = TheSim:FindEntities(x, y, z, 8, {"structure"})
            if #ents > 0 then
                return false
            end
            
            return true
        end
        return false
    end
    
    -- 在地图上找一个合适的位置
    local attempts = 0
    local x, y, z
    
    repeat
        x, y, z = TheWorld.Map:GetRandomPointOnLand()
        attempts = attempts + 1
    until CanSpawnAt(x, y, z) or attempts > 100
    
    if attempts <= 100 then
        local throne = SpawnPrefab("throne_ruin")
        throne.Transform:SetPosition(x, y, z)
    end
end

-- 在世界生成时创建王座废墟
AddPrefabPostInit("world", function(inst)
    if not TheWorld.ismastersim then return end
    
    inst:DoTaskInTime(0.1, function()
        -- 确保每个世界只有一个王座废墟
        if not inst.throne_ruin_spawned then
            PlaceRandomThroneRuin()
            inst.throne_ruin_spawned = true
        end
    end)
end)

-- 添加修复后王座对Vox的特殊交互
AddComponentPostInit("inventory", function(self, inst)
    if inst.prefab == "vox" then
        local old_OnLoad = inst.OnLoad
        inst.OnLoad = function(inst, data)
            if old_OnLoad then
                old_OnLoad(inst, data)
            end
            
            if data and data.throne_health_bonus and inst.components.health then
                inst.components.health:SetMaxHealth(inst.components.health.maxhealth + 50)
            end
        end
        
        local old_OnSave = inst.OnSave
        inst.OnSave = function(inst, data)
            if old_OnSave then
                old_OnSave(inst, data)
            end
            
            -- 保存王座生命值加成信息
            if inst.throne_restored then
                data.throne_health_bonus = true
            end
        end
    end
end)

-- 将新的预制体添加到游戏中
PrefabFiles = {
    "throne_ruin",
    "throne_repaired",
    "memory_ghost",
    "memory_battle",
}

-- 添加新的资源
Assets = {
    Asset("IMAGE", "images/inventoryimages/throne_ruin.tex"),
    Asset("ATLAS", "images/inventoryimages/throne_ruin.xml"),
    Asset("IMAGE", "images/inventoryimages/throne_repaired.tex"),
    Asset("ATLAS", "images/inventoryimages/throne_repaired.xml"),
    Asset("IMAGE", "images/map_icons/throne_ruin.tex"),
    Asset("ATLAS", "images/map_icons/throne_ruin.xml"),
    Asset("IMAGE", "images/map_icons/throne_repaired.tex"),
    Asset("ATLAS", "images/map_icons/throne_repaired.xml"),
}

-- 注册Vox的王座修复功能
AddPrefabPostInit("vox", function(inst)
    if not TheWorld.ismastersim then return end
    
    -- 监听王座修复事件
    inst:ListenForEvent("throne_repaired", function(inst)
        inst.throne_restored = true
        
        if inst.components.health then
            inst.components.health:SetMaxHealth(inst.components.health.maxhealth + 50)
        end
    end)
end)

-- 添加字符串定义
STRINGS.NAMES.THRONE_RUIN = "古老王座废墟"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.THRONE_RUIN = "一个古老而破败的王座，似乎与某种强大的力量相连。"

STRINGS.NAMES.THRONE_REPAIRED = "恶魔王座"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.THRONE_REPAIRED = "一个修复完好的王座，充满了力量。"

STRINGS.CHARACTERS.VOX.DESCRIBE.THRONE_RUIN = "这似乎是属于我的...我应该修复它。"
STRINGS.CHARACTERS.VOX.DESCRIBE.THRONE_REPAIRED = "我的力量源泉，我的王座。"

-- 添加小地图图标
AddMinimapAtlas("images/map_icons/throne_ruin.xml")
AddMinimapAtlas("images/map_icons/throne_repaired.xml")

-- 返回预制体
return Prefab("throne_ruin", fn, assets, prefabs),
       Prefab("throne_repaired", fn, assets),
       Prefab("memory_ghost", fn),
       Prefab("memory_battle", fn)