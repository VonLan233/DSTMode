-- onigiri_big状态图，参考SGberniebig.lua

require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.ACTIVATE, "activate"),
}

local function shake_camera(inst, shakeType, duration, speed, maxShake, maxDist)
    local player = FindClosestPlayerInRange(inst:GetPosition(), 20, true)
    if player and player.components.playercontroller ~= nil then
        player.components.playercontroller:ShakeCamera(player, shakeType or "VERTICAL", duration or .4, speed or .02, maxShake or .3, maxDist or 40)
    end
end

local events=
{
    CommonHandlers.OnLocomote(false, true),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnHop(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
}

local states=
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            if playanim then
                inst.AnimState:PlayAnimation(playanim)
                inst.AnimState:PushAnimation("idle_loop", true)
            else
                inst.AnimState:PlayAnimation("idle_loop", true)
            end
        end,
        
        timeline = 
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/idle") end),
            TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/idle") end),
            TimeEvent(19*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/idle") end),
            TimeEvent(32*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/idle") end),
        },
    },

    State{
        name = "run_start",
        tags = {"moving", "running", "canrotate"},
        
        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("run_pre")
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("run") end),
        },
    },

    State{
        name = "run",
        tags = {"moving", "running", "canrotate"},
        
        onenter = function(inst) 
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("run_loop", true)
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,

        timeline = 
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/walk") end),
            TimeEvent(5*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/walk") end),
            TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/walk") end),
            TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/walk") end),
            TimeEvent(21*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/walk") end),
            TimeEvent(21*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/walk") end),
            TimeEvent(29*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/walk") end),
            TimeEvent(29*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/walk") end),
        },

        ontimeout = function(inst) inst.sg:GoToState("run") end,
    },

    State{
        name = "run_stop",
        tags = {"idle", "canrotate"},
        
        onenter = function(inst) 
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("run_pst")
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "death",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/shrink_explo")
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)            
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))            
        end,
    },

    State{
        name = "hit",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/hit")
            inst.AnimState:PlayAnimation("hit")
            inst.Physics:Stop()
        end,
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
        
        timeline = 
        {
            TimeEvent(5*FRAMES, function(inst) shake_camera(inst) end),
        },
    },
    
    State{
        name = "attack",
        tags = {"attack", "busy"},

        onenter = function(inst, target)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("atk")
            
            if target ~= nil and target:IsValid() then
                inst.sg.statemem.target = target
                inst:ForceFacePoint(target.Transform:GetWorldPosition())
            end
            
            local attackspeed = 1
            inst.sg.statemem.attackspeed = attackspeed
            inst.AnimState:SetDeltaTimeMultiplier(attackspeed)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/atk")
            
            if inst.components.combat:GetWeapon() == nil then
                inst.sg.statemem.abouttoattack = true
            else
                inst.sg.statemem.abouttoattack = false
            end
            if target ~= nil then
                inst.components.combat:BattleCry()
            end
        end,

        timeline=
        {
            TimeEvent(6*FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/atk_grunt")
                shake_camera(inst)
            end),
            TimeEvent(18*FRAMES, function(inst)
                if inst.sg.statemem.abouttoattack then 
                    inst.sg.statemem.abouttoattack = false
                    inst.components.combat:DoAttack(inst.sg.statemem.target)
                end
            end),
        },
        
        onexit = function(inst)
            inst.AnimState:SetDeltaTimeMultiplier(1)
        end,
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "activate",
        tags = {"idle"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("idle_loop", true)
            inst:PerformBufferedAction()
            inst:GoInactive()
        end,
    },
}

CommonStates.AddSleepStates(states,
{
    sleeptimeline = 
    {
        TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/sleep") end),
    },
})

CommonStates.AddHopStates(states, true, 
{
    hop_pre =
    {
        TimeEvent(0, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/bounce")
        end),
    },
    hop_pst = 
    {
        TimeEvent(1*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/taunt")
        end),
        TimeEvent(6*FRAMES, function(inst)
            shake_camera(inst)
        end),
    }
})

CommonStates.AddFrozenStates(states)

return StateGraph("SGonigiribig", states, events, "idle", actionhandlers)