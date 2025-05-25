-- kindredbrain.lua (Kindred宠物的AI)

require "behaviours/wander"
require "behaviours/follow"
require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/doaction"
require "behaviours/panic"

local MIN_FOLLOW_DIST = 2
local MAX_FOLLOW_DIST = 6
local TARGET_FOLLOW_DIST = 3
local WANDER_DIST = 5

local KindredBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function GetLeader(inst)
    return inst.components.follower.leader
end

local function GetFaceTargetFn(inst)
    local target = FindClosestPlayerInRange(inst, 5, true)
    return target ~= nil and not target:HasTag("notarget") and target or nil
end

local function KeepFaceTargetFn(inst, target)
    return inst:IsNear(target, 6)
end

local function ShouldWorkAction(inst)
    if not inst:HasTag("worker") then
        return false
    end
    
    local leader = GetLeader(inst)
    if leader == nil then
        return false
    end
    
    -- 检查附近是否有可以工作的目标
    local x, y, z = inst.Transform:GetWorldPosition()
    local targets = {}
    
    -- 搜索可以砍的树
    local trees = TheSim:FindEntities(x, y, z, 10, {"tree"}, {"stump"})
    for _, tree in ipairs(trees) do
        if tree.components.workable and tree.components.workable:CanBeWorked() and tree.components.workable:GetWorkAction() == ACTIONS.CHOP then
            table.insert(targets, tree)
        end
    end
    
    -- 搜索可以挖的石头
    local rocks = TheSim:FindEntities(x, y, z, 10, {"boulder"})
    for _, rock in ipairs(rocks) do
        if rock.components.workable and rock.components.workable:CanBeWorked() and rock.components.workable:GetWorkAction() == ACTIONS.MINE then
            table.insert(targets, rock)
        end
    end
    
    if #targets > 0 then
        -- 随机选择一个工作目标
        inst.worktarget = targets[math.random(#targets)]
        return true
    end
    
    return false
end

local function DoWorkAction(inst)
    if inst.worktarget and inst.worktarget:IsValid() and not inst.worktarget:IsInLimbo() then
        local action = nil
        if inst.worktarget.components.workable then
            local work_action = inst.worktarget.components.workable:GetWorkAction()
            if work_action == ACTIONS.CHOP and inst.components.worker:CanDoAction(ACTIONS.CHOP) then
                action = BufferedAction(inst, inst.worktarget, ACTIONS.CHOP)
            elseif work_action == ACTIONS.MINE and inst.components.worker:CanDoAction(ACTIONS.MINE) then
                action = BufferedAction(inst, inst.worktarget, ACTIONS.MINE)
            end
        end
        
        if action then
            local success = true
            if inst.components.talker then
                inst.components.talker:Say("Let me help you!")
            end
            return action
        end
    end
    
    inst.worktarget = nil
    return nil
end

function KindredBrain:OnStart()
    local root = PriorityNode({
        -- 逃跑条件
        WhileNode(function() return self.inst.components.health and self.inst.components.health:GetPercent() < 0.2 end, "Panic",
            Panic(self.inst)),
        
        -- 跟随主人
        WhileNode(function() return GetLeader(self.inst) ~= nil end, "Has Leader",
            PriorityNode({
                -- 战斗
                WhileNode(function() 
                    local leader = GetLeader(self.inst)
                    return leader ~= nil and leader.components.combat ~= nil and leader.components.combat.target ~= nil
                end, "Fight! Fight!",
                    ChaseAndAttack(self.inst, 10)),
                
                -- 主人在战斗中
                ChaseAndAttack(self.inst, 15),
                
                -- 如果是工人，执行工作
                WhileNode(function() return ShouldWorkAction(self.inst) end, "Should Work",
                    DoAction(self.inst, function() return DoWorkAction(self.inst) end)),
                
                -- 跟随主人
                Follow(self.inst, function() return GetLeader(self.inst) end, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),
                
                -- 面向主人
                FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
                
                -- 在主人附近徘徊
                Wander(self.inst, function()
                    local leader = GetLeader(self.inst)
                    if leader ~= nil then
                        return leader:GetPosition()
                    end
                    return self.inst.components.knownlocations:GetLocation("home")
                end, WANDER_DIST)
            }, 0.25)),
        
        -- 独自徘徊
        Wander(self.inst, function()
            return self.inst.components.knownlocations:GetLocation("home")
        end, WANDER_DIST)
    }, 0.25)
    
    self.bt = BT(self.inst, root)
end

return KindredBrain