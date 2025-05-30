require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.CHOP, "work"),
    ActionHandler(ACTIONS.MINE, "work"),
    ActionHandler(ACTIONS.DIG, "work"),
    ActionHandler(ACTIONS.HAMMER, "work"),
    ActionHandler(ACTIONS.GOHOME, "gohome"),
}

local events =
{
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
    EventHandler("locomote", function(inst, data)
        if not inst.sg:HasStateTag("busy") then
            local is_moving = inst.sg:HasStateTag("moving")
            local wants_to_move = inst.components.locomotor:WantsToMoveForward()
            
            if is_moving ~= wants_to_move then
                if wants_to_move then
                    inst.sg:GoToState("walk_start")
                else
                    inst.sg:GoToState("walk_stop")
                end
            end
        end
    end),
}

local states =
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("idle", true)
            
            -- 随机播放特殊动画
            if math.random() < 0.1 then
                inst.sg:GoToState("idle_special")
            end
        end,
    },
    
    State{
        name = "idle_special",
        tags = {"idle", "busy"},
        
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            
            -- 随机选择一个特殊动画
            local anims = {"emote_happy", "emote_impatient", "emote_hat", "scratch"}
            local anim = anims[math.random(#anims)]
            
            inst.AnimState:PlayAnimation(anim)
            inst.AnimState:PushAnimation("idle", true)
        end,
        
        events =
        {
            EventHandler("animqueueover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
    
    State{
        name = "death",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("death")
            inst.SoundEmitter:PlaySound("dontstarve/rabbit/death")
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(inst:GetPosition())
        end,
    },
    
    State{
        name = "walk_start",
        tags = {"moving", "canrotate"},
        
        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("walk_pre")
        end,
        
        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("walk")
            end),
        },
    },
    
    State{
        name = "walk",
        tags = {"moving", "canrotate"},
        
        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("walk_loop", true)
            inst.sg:SetTimeout(2 + math.random()*1)
        end,
        
        ontimeout = function(inst)
            -- 偶尔播放特殊行走动画
            if math.random() < 0.2 then
                inst.sg:GoToState("walk_special")
            end
        end,
    },
    
    State{
        name = "walk_special",
        tags = {"moving", "canrotate"},
        
        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            
            -- 随机选择一个特殊行走动画
            local anims = {"walk_happy", "walk_tired"}
            local anim = anims[math.random(#anims)]
            
            inst.AnimState:PlayAnimation(anim)
            inst.AnimState:PushAnimation("walk_loop", true)
        end,
        
        events =
        {
            EventHandler("animqueueover", function(inst)
                inst.sg:GoToState("walk")
            end),
        },
    },
    
    State{
        name = "walk_stop",
        tags = {"canrotate"},
        
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("walk_pst")
        end,
        
        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
    
    State{
        name = "run_start",
        tags = {"moving", "running", "canrotate"},
        
        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("run_pre")
        end,
        
        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("run")
            end),
        },
    },
    
    State{
        name = "run",
        tags = {"moving", "running", "canrotate"},
        
        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("run_loop", true)
        end,
    },
    
    State{
        name = "run_stop",
        tags = {"canrotate"},
        
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("run_pst")
        end,
        
        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
    
    State{
        name = "work",
        tags = {"busy"},
        
        onenter = function(inst, target)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("work")
        end,
        
        timeline =
        {
            TimeEvent(9*FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
        },
        
        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
    
    State{
        name = "hit",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey/hit")
        end,
        
        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
    
    State{
        name = "attack",
        tags = {"attack", "busy"},
        
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("atk")
            inst.components.combat:StartAttack()
        end,
        
        timeline =
        {
            TimeEvent(9*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey/attack")
            end),
            TimeEvent(11*FRAMES, function(inst)
                inst.components.combat:DoAttack()
            end),
        },
        
        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
    
    State{
        name = "emote",
        tags = {"busy", "canrotate"},
        
        onenter = function(inst, data)
            inst.components.locomotor:StopMoving()
            
            local anim = "emote_happy"
            if data and data.emote then
                anim = "emote_" .. data.emote
            end
            
            inst.AnimState:PlayAnimation(anim)
        end,
        
        timeline =
        {
            TimeEvent(7*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey/worried")
            end),
        },
        
        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
    
    State{
        name = "gohome",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("emote_sad")
        end,
        
        timeline = 
        {
            TimeEvent(10*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey/sad")
            end),
            TimeEvent(25*FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
        },
        
        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
}

-- 添加通用状态
CommonStates.AddSleepStates(states,
{
    sleeptimeline = 
    {
        TimeEvent(25*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/monkey/sleep") end),
    },
})

CommonStates.AddFrozenStates(states)

return StateGraph("kindred", states, events, "idle", actionhandlers)