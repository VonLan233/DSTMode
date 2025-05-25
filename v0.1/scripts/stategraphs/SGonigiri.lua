-- onigiri状态图，参考SGbernie.lua

require("stategraphs/commonstates")

local actionhandlers = 
{
    ActionHandler(ACTIONS.GOHOME, "action"),
    ActionHandler(ACTIONS.PICKUP, "action"),
    ActionHandler(ACTIONS.EQUIP, "action"),
    ActionHandler(ACTIONS.ADDFUEL, "action"),
}

local events=
{
    CommonHandlers.OnLocomote(false, true),
    CommonHandlers.OnSleep(),
    CommonHandlers.OnHop(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),

    EventHandler("dance", function(inst)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
            inst.sg:GoToState("dance")
        end
    end),
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
            TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/idle") end),
            TimeEvent(25*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/idle") end),
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
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/walk") end),
            TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/walk") end),
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
        name = "action",
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle_loop", true)
            inst:PerformBufferedAction()
        end,
        events=
        {
            EventHandler("animover", function (inst) inst.sg:GoToState("idle") end),
        }
    },

    State{
        name = "death",
        tags = {"busy"},
        
        onenter = function(inst)
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
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    },
    
    State{
        name = "dance",
        tags = {"busy", "canrotate"},
        
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("dance", true)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/walk")
        end,
    },
}

CommonStates.AddSleepStates(states,
{
    sleeptimeline = 
    {
        TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/bernie/sleep") end ),
    },
})

CommonStates.AddFrozenStates(states)

return StateGraph("SGonigiri", states, events, "idle", actionhandlers)