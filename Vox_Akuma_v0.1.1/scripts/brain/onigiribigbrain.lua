-- onigiri_big的大脑行为，参考berniebigbrain.lua
require "behaviours/standandattack"
require "behaviours/standstill"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/wander"
require "behaviours/chaseandattack"
require "behaviours/leash"
require "behaviours/follow"
require "behaviours/faceentity"

local SEE_DIST = 30
local MAX_CHASE_DIST = 40
local MAX_CHASE_TIME = 6
local LEASH_MAX_DIST = 15
local ARRIVAL_DIST = 3

local onigiricommon = require "prefabs/onigiri_common"

local function GetOwner(inst)
    -- 暴走状态下使用记录的主人
    return inst.onigiriowner
end

local function GetHomePos(inst)
    local owner = GetOwner(inst)
    return owner ~= nil and owner:GetPosition() or inst:GetPosition()
end

local function GetFaceTargetFn(inst)
    local target = inst.components.combat.target
    if target ~= nil and target:IsValid() and not target:IsInLimbo() then
        return target
    end

    local owner = GetOwner(inst)
    if owner ~= nil then
        return owner
    end
    
    return nil
end

local function KeepFaceTargetFn(inst, target)
    local owner = GetOwner(inst)
    if target == owner then
        -- 总是面向主人
        return true
    end

    return not target:IsInLimbo()
        and owner ~= nil
        and inst:IsNear(target, 8)
end

local function ShouldStandStill(inst)
    local owner = GetOwner(inst)
    return owner ~= nil 
        and inst:IsNear(owner, 3) 
        and not inst.components.combat:HasTarget()
end

local function IsTargettingSquishy(inst)
    local target = inst.components.combat.target
    if target ~= nil and target.components.health ~= nil then
        local health = target.components.health
        local max_health = health:GetMaxWithPenalty()
        -- 与被攻击目标的健康状态无关，这个是暴走模式，总是会进攻
        return true
    end
    return false
end

local OnigiriBigBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function OnigiriBigBrain:OnStart()
    local root = PriorityNode({
        -- 追逐并攻击目标
        WhileNode(function() return self.inst.components.combat:HasTarget() end, "Has Target",
            ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST)),

        -- 跟随主人
        Follow(self.inst, GetOwner, ARRIVAL_DIST, 2, 5, true),

        -- 如果跟随主人，闲逛
        WhileNode(function() return GetOwner(self.inst) ~= nil end, "Stand or Wander",
            PriorityNode({
                WhileNode(function() return ShouldStandStill(self.inst) end, "Standing", 
                    FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn)),
                    
                Leash(self.inst, GetHomePos, LEASH_MAX_DIST, 3),
                
                Wander(self.inst, GetHomePos, 10, 
                    {minwalktime=0.5, randwalktime=0.5, minwaittime=5, randwaittime=2})
            }, .25)),
    }, .25)
    
    self.bt = BT(self.inst, root)
end

function OnigiriBigBrain:OnInitializationComplete()
    -- 设置主人，应该在初始化时已经设置好了
    local owner = GetOwner(self.inst)
    if owner ~= nil then
        self.inst:OnLeaderChanged(owner)
    end
    
    -- 查找并开始攻击附近的目标
    local target = onigiricommon.getBestTarget(self.inst, SEE_DIST)
    if target ~= nil then
        self.inst.components.combat:SetTarget(target)
    end
end

return OnigiriBigBrain