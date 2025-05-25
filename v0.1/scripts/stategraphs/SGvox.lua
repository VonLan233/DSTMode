-- Vox角色专用的状态图代码

require("stategraphs/commonstates")
require("stategraphs/SGwilson")

local ATTACK_COOLDOWN = 6
local INTERRUPT_ATTACK_THRESHOLD = 3
local WILSON_WALK_SPEED = 4
local WILSON_RUN_SPEED = 6
local DEMON_MULT = 1.5

local function GetDemonSpeedMult(inst)
    if inst.voxform ~= nil and inst.voxform:value() == 1 then
        return DEMON_MULT
    end
    return 1
end

local actionhandlers = 
{
    ActionHandler(ACTIONS.CHOP, 
        function(inst)
            if inst.voxform ~= nil and inst.voxform:value() == 1 then
                return "demon_chop"
            end
            return "chop"
        end),
    ActionHandler(ACTIONS.MINE, 
        function(inst)
            if inst.voxform ~= nil and inst.voxform:value() == 1 then
                return "demon_mine"
            end
            return "mine"
        end),
    ActionHandler(ACTIONS.HAMMER, 
        function(inst)
            if inst.voxform ~= nil and inst.voxform:value() == 1 then
                return "demon_hammer"
            end
            return "hammer"
        end),
    ActionHandler(ACTIONS.ATTACK, 
        function(inst)
            if inst.voxform ~= nil and inst.voxform:value() == 1 then
                if not inst.sg:HasStateTag("attack") then
                    return "demon_attack"
                end
                return nil
            end
            if not inst.sg:HasStateTag("attack") then
                return "attack"
            end
            return nil
        end),
    ActionHandler(ACTIONS.USE_WEREFORM_SKILL, function(inst) return "demon_special" end),
}

local events =
{
    CommonHandlers.OnLocomote(true, false),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnFreeze(),
    
    EventHandler("doattack", function(inst, data)
        if inst.sg:HasStateTag("attack") or inst.components.health:IsDead() then return end
        
        if inst.voxform ~= nil and inst.voxform:value() == 1 then
            inst.sg:GoToState("demon_attack", data.target)
        else
            inst.sg:GoToState("attack", data.target)
        end
    end),
    
    EventHandler("transformtodemon", function(inst)
        if not inst.sg:HasStateTag("busy") and not inst.sg:HasStateTag("nomorph") and
           not inst.components.health:IsDead() and not inst:HasTag("playerghost") and
           (inst.voxform == nil or inst.voxform:value() == 0) then
            inst.sg:GoToState("transform_demon")
        end
    end),
    
    EventHandler("reverttohuman", function(inst)
        if not inst.sg:HasStateTag("busy") and not inst.sg:HasStateTag("nomorph") and
           not inst.components.health:IsDead() and not inst:HasTag("playerghost") and
           inst.voxform ~= nil and inst.voxform:value() == 1 then
            inst.sg:GoToState("revert_human")
        end
    end),
}

local states = {}

-- 添加变身相关状态
states.transform_demon = State{
    name = "transform_demon",
    tags = {"busy", "noattack", "nomorph", "nointerrupt"},
    
    onenter = function(inst)
        inst.components.locomotor:StopMoving()
        inst.AnimState:PlayAnimation("idle_loop", false) -- 替换成你的变身前动画
        inst.SoundEmitter:PlaySound("dontstarve/characters/woodie/transform_weremoose")
        inst.components.playercontroller:Enable(false)
        inst:AddTag("notarget") -- 变身过程中不会被敌人攻击
        -- 增加变身相关的音效
        inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/charge")
    end,
    
    timeline = {
        TimeEvent(10*FRAMES, function(inst) 
            inst.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/spawn", nil, 0.5)
        end),
        TimeEvent(20*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/transform")
            local fx = SpawnPrefab("statue_transition_2")
            if fx then
                fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
                fx:SetMaterial("shadow")
            end
        end),
        TimeEvent(50*FRAMES, function(inst)
            -- 真正的变身逻辑在TransformToDemon中已经处理
            inst.AnimState:SetBuild("vox_demon") -- 切换为恶魔外观
            inst.AnimState:SetMultColor(1.2, 0.5, 0.5, 1) -- 红色色调
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/taunt")
        end),
    },
    
    events = {
        EventHandler("animover", function(inst)
            inst:RemoveTag("notarget")
            inst.components.playercontroller:Enable(true)
            -- 产生烟雾特效
            local fx = SpawnPrefab("collapse_small")
            if fx then 
                fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
            end
            inst.sg:GoToState("idle")
        end),
    },
    
    onexit = function(inst)
        inst:RemoveTag("notarget")
        inst.components.playercontroller:Enable(true)
    end,
}

states.revert_human = State{
    name = "revert_human",
    tags = {"busy", "noattack", "nomorph", "nointerrupt"},
    
    onenter = function(inst)
        inst.components.locomotor:StopMoving()
        inst.AnimState:PlayAnimation("idle_loop", false) -- 替换成你的变回人类动画
        inst.SoundEmitter:PlaySound("dontstarve/characters/woodie/revert")
        inst.components.playercontroller:Enable(false)
        inst:AddTag("notarget")
    end,
    
    timeline = {
        TimeEvent(10*FRAMES, function(inst) 
            inst.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/spawn", nil, 0.5)
        end),
        TimeEvent(20*FRAMES, function(inst)
            local fx = SpawnPrefab("collapse_small")
            if fx then
                fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
            end
        end),
        TimeEvent(40*FRAMES, function(inst)
            -- 变回人类的逻辑在RevertToHuman中已经处理
            inst.AnimState:SetBuild("vox") -- 切换为人类外观
            inst.AnimState:SetMultColor(1, 1, 1, 1) -- 正常色调
        end),
    },
    
    events = {
        EventHandler("animover", function(inst)
            inst:RemoveTag("notarget")
            inst.components.playercontroller:Enable(true)
            inst.sg:GoToState("idle")
        end),
    },
    
    onexit = function(inst)
        inst:RemoveTag("notarget")
        inst.components.playercontroller:Enable(true)
    end,
}

-- 恶魔形态专用攻击状态
states.demon_attack = State{
    name = "demon_attack",
    tags = {"attack", "busy", "notalking"},
    
    onenter = function(inst, target)
        local buffedenemy = nil
        if inst.components.combat.target then
            buffedenemy = inst.components.combat.target:HasTag("health_as_oldage") or nil
        end
        inst.AnimState:PlayAnimation("attack") -- 使用普通攻击动画，但加入恶魔特效
        inst.components.locomotor:StopMoving()
        inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/attack")
        if target ~= nil then
            inst.components.combat:SetTarget(target)
            inst:FacePoint(target:GetPosition())
        end
    end,
    
    timeline = {
        TimeEvent(8*FRAMES, function(inst) 
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/attack")
        end),
        TimeEvent(10*FRAMES, function(inst) 
            inst.components.combat:DoAttack() 
            -- 产生攻击特效
            local fx = SpawnPrefab("shadow_despawn")
            if fx and inst.components.combat.target then
                local target = inst.components.combat.target
                fx.Transform:SetPosition(target.Transform:GetWorldPosition())
            end
        end),
        TimeEvent(16*FRAMES, function(inst) 
            inst.sg:RemoveStateTag("busy")
        end),
    },
    
    events = {
        EventHandler("animover", function(inst) 
            inst.sg:GoToState("idle") 
        end),
    },
}

-- 恶魔特殊技能
states.demon_special = State{
    name = "demon_special",
    tags = {"attack", "busy", "notalking"},
    
    onenter = function(inst)
        inst.AnimState:PlayAnimation("attack") -- 使用普通攻击动画，但用特殊效果
        inst.components.locomotor:StopMoving()
        inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/taunt")
    end,
    
    timeline = {
        TimeEvent(10*FRAMES, function(inst) 
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/hit")
        end),
        TimeEvent(15*FRAMES, function(inst) 
            -- 产生冲击波特效
            local pos = inst:GetPosition()
            local fx = SpawnPrefab("groundpoundring_fx")
            if fx then
                fx.Transform:SetPosition(pos.x, 0, pos.z)
                fx:SetScale(1.5)
            end
            
            -- 对周围敌人造成伤害
            local x, y, z = inst.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, y, z, 8, {"_combat"}, {"player", "companion", "INLIMBO"})
            for i, v in ipairs(ents) do
                if v ~= inst and v:IsValid() and not v:IsInLimbo() and v.components.health ~= nil and not v.components.health:IsDead() then
                    v.components.health:DoDelta(-20) -- 造成固定伤害
                    if v.components.freezable ~= nil then
                        v.components.freezable:AddColdness(2) -- 降低敌人温度
                    end
                    if v.components.combat ~= nil then
                        v.components.combat:GetAttacked(inst, 20)
                    end
                    -- 击退效果
                    if v.Physics ~= nil then
                        local distsq = v:GetDistanceSqToPoint(x, y, z)
                        local dist = math.max(2, math.sqrt(distsq))
                        local dir = Vector3(v.Transform:GetWorldPosition()) - Vector3(x, y, z)
                        dir:Normalize()
                        dir = dir * 4.5 / math.max(1, dist - 2)
                        if v.components.locomotor == nil then
                            v:DoTaskInTime(0.1, function() 
                                v.Physics:SetVel(dir.x, 3, dir.z) 
                            end)
                        else
                            v:DoTaskInTime(0.1, function() 
                                v.components.locomotor:External(true)
                                v.components.locomotor:ExternalSpeed(dir)
                                v:DoTaskInTime(1, function()
                                    v.components.locomotor:External(false)
                                end)
                            end)
                        end
                    end
                end
            end
            
            -- 消耗恶魔能量
            inst:PushEvent("demonenergydelta", {delta = -20})
        end),
        TimeEvent(25*FRAMES, function(inst) 
            inst.sg:RemoveStateTag("busy")
        end),
    },
    
    events = {
        EventHandler("animover", function(inst) 
            inst.sg:GoToState("idle") 
        end),
    },
}

-- 恶魔砍树、挖矿、敲击等可使用基础动画加特效处理

-- 添加通用状态重写
for k, v in pairs(SGWilson.states) do
    if states[k] == nil then
        states[k] = v
    end
end

-- 重写走路和跑步状态 (可选，如果需要恶魔形态特有的移动动画)
states.walk = State{
    name = "walk",
    tags = {"moving", "canrotate"},
    
    onenter = function(inst)
        inst.components.locomotor:WalkForward()
        if not inst.AnimState:IsCurrentAnimation("walk") then
            inst.AnimState:PlayAnimation("walk", true)
        end
        
        -- 恶魔形态特有的行走音效
        if inst.voxform ~= nil and inst.voxform:value() == 1 then
            if not inst.SoundEmitter:PlayingSound("demonwalk") then
                inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/step", "demonwalk")
            end
        else
            inst.SoundEmitter:KillSound("demonwalk")
        end
        
        inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
    end,
    
    onupdate = function(inst)
        if not inst.components.locomotor:WantsToMoveForward() then
            inst.sg:GoToState("idle")
        end
    end,
    
    ontimeout = function(inst)
        inst.sg:GoToState("walk")
    end,
    
    onexit = function(inst)
        -- 停止恶魔形态行走音效
        inst.SoundEmitter:KillSound("demonwalk")
    end,
}

states.run = State{
    name = "run",
    tags = {"moving", "running", "canrotate"},
    
    onenter = function(inst) 
        inst.components.locomotor:RunForward()
        if not inst.AnimState:IsCurrentAnimation("run") then
            inst.AnimState:PlayAnimation("run", true)
        end
        
        -- 恶魔形态特有的跑步音效
        if inst.voxform ~= nil and inst.voxform:value() == 1 then
            if not inst.SoundEmitter:PlayingSound("demonrun") then
                inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/step", "demonrun")
            end
        else
            inst.SoundEmitter:KillSound("demonrun")
        end
        
        inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
    end,
    
    onupdate = function(inst) 
        if not inst.components.locomotor:WantsToRun() then
            inst.sg:GoToState("idle")
        end
    end,
    
    ontimeout = function(inst)
        inst.sg:GoToState("run")
    end,
    
    onexit = function(inst)
        -- 停止恶魔形态跑步音效
        inst.SoundEmitter:KillSound("demonrun")
    end,
}

-- 重写待机状态
states.idle = State{
    name = "idle",
    tags = {"idle", "canrotate"},
    
    onenter = function(inst, pushanim)
        inst.components.locomotor:Stop()
        
        -- 根据形态选择不同的动画
        if inst.voxform ~= nil and inst.voxform:value() == 1 then
            -- 恶魔形态待机
            if pushanim then
                inst.AnimState:PushAnimation("idle_loop", true)
            else
                inst.AnimState:PlayAnimation("idle_loop", true)
            end
            
            -- 恶魔形态呼吸音效
            if not inst.SoundEmitter:PlayingSound("demonbreathing") then
                inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/breathing_LP", "demonbreathing", 0.5)
            end
        else
            -- 人类形态待机
            if pushanim then
                inst.AnimState:PushAnimation("idle_loop", true)
            else
                inst.AnimState:PlayAnimation("idle_loop", true)
            end
            
            -- 停止恶魔呼吸音效
            inst.SoundEmitter:KillSound("demonbreathing")
        end
    end,
    
    onexit = function(inst)
        -- 停止恶魔形态呼吸音效
        inst.SoundEmitter:KillSound("demonbreathing")
    end,
}

return StateGraph("vox", states, events, "idle", actionhandlers)