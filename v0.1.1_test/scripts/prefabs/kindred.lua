
local assets =
{
    Asset("ANIM", "anim/kindred.zip"),
    Asset("ATLAS", "images/inventoryimages/kindred.xml"),
    Asset("IMAGE", "images/inventoryimages/kindred.tex"),
}

local brain = require "brains/kindredbrain"

local function OnStopFollowing(inst)
    inst:RemoveTag("companion")
end

local function OnStartFollowing(inst)
    inst:AddTag("companion")
end

local function OnAttacked(inst, data)
    if data and data.attacker and not data.attacker:HasTag("vox") then
        inst.components.combat:SetTarget(data.attacker)
    end
end

local function ShouldAcceptItem(inst, item, giver)
    -- 接受工具或者武器
    return item ~= nil and (item:HasTag("tool") or item:HasTag("weapon") or item:HasTag("armor"))
end

local function OnGetItemFromPlayer(inst, giver, item)
    -- 根据物品类型给予不同的能力
    if item:HasTag("tool") then
        -- 接受工具，可以砍树挖矿等
        inst:AddTag("worker")
        inst.components.talker:Say("我会帮你工作的！")
        
        -- 添加工作组件
        if inst.components.worker == nil then
            inst:AddComponent("worker")
            inst.components.worker:SetAction(ACTIONS.CHOP, 1)
            inst.components.worker:SetAction(ACTIONS.MINE, 1)
            inst.components.worker:SetAction(ACTIONS.DIG, 1)
            inst.components.worker:SetAction(ACTIONS.HAMMER, 1)
        end
    elseif item:HasTag("weapon") then
        -- 接受武器，提高攻击能力
        inst.components.combat:SetDefaultDamage(item.components.weapon.damage or 17)
        inst.components.talker:Say("我会为你而战！")
    elseif item:HasTag("armor") then
        -- 接受护甲，提高防御能力
        if inst.components.health then
            inst.components.health:SetAbsorptionAmount(item.components.armor.absorb_percent or 0.5)
            inst.components.talker:Say("现在我更安全了！")
        end
    end
    
    -- 移除物品
    item:Remove()
end

local function OnRefuseItem(inst, item)
    inst.components.talker:Say("我不需要这个...")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 50, .5)

    inst.DynamicShadow:SetSize(1.5, .75)
    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("kindred")
    inst.AnimState:SetBuild("kindred")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("kindred")
    inst:AddTag("companion")
    inst:AddTag("notraptrigger")
    inst:AddTag("character")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("knownlocations")
    
    inst:AddComponent("follower")
    inst.components.follower.maxfollowtime = -1
    inst.components.follower:SetReturnToSpawnOnStop(false)
    inst.components.follower.keepdeadleader = true
    inst.components.follower.keepleaderduringminigame = true
    
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(150)
    
    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(17)
    inst.components.combat:SetRetargetFunction(3, function(inst)
        local leader = inst.components.follower.leader
        if leader ~= nil and leader.components.combat ~= nil and leader.components.combat.target ~= nil then
            return leader.components.combat.target
        end
        return nil
    end)
    
    inst:AddComponent("talker")
    inst.components.talker.fontsize = 24
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.offset = Vector3(0, -500, 0)
    inst.components.talker:StopUIAnimations()
    
    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 4
    inst.components.locomotor.runspeed = 7
    
    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.onrefuse = OnRefuseItem
    
    inst:ListenForEvent("attacked", OnAttacked)
    
    inst:SetStateGraph("SGkindred")
    inst:SetBrain(brain)
    
    -- 随机事件，有时会回复san，有时会减少san
    inst:DoPeriodicTask(30, function()
        local owner = inst.components.follower.leader
        if owner ~= nil and owner:HasTag("vox") and owner.components.sanity ~= nil then
            local rand = math.random()
            if rand < 0.7 then
                -- 70%几率回复san
                inst.components.talker:Say("主人，你看起来不错！")
                owner.components.sanity:DoDelta(5)
                
                -- 播放特效
                local fx = SpawnPrefab("heart_fx")
                if fx then
                    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
                    fx.Transform:SetScale(0.7, 0.7, 0.7)
                end
            else
                -- 30%几率减少san
                inst.components.talker:Say("哎呀，我好像做错事了...")
                owner.components.sanity:DoDelta(-3)
                
                -- 播放特效
                local fx = SpawnPrefab("shadow_puff")
                if fx then
                    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
                end
            end
        end
    end)
    
    return inst
end

Prefab("kindred", fn, assets)