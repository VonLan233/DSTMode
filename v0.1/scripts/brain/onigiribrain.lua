-- onigiri的大脑行为，参考berniebrain.lua
require "behaviours/follow"
require "behaviours/wander"
require "behaviours/standstill"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/panic"

-- 行为数值配置
local STOP_RUN_DIST = 10
local SEE_PLAYER_DIST = 5
local WANDER_DIST = 6

local MAX_CHASE_TIME = 6
local MAX_CHASE_DIST = 9
local WANDER_TIMES = {minwalktime=2, randwalktime=3, minwaittime=1, randwaittime=2}

local function GetOwner(inst)
    return inst.components.inventoryitem:GetGrandOwner()
end

local function GetHomePos(inst)
    local owner = GetOwner(inst)
    return owner ~= nil and owner:GetPosition() or nil
end

local function ShouldRunAway(inst, target)
    -- 不跑离主人的目标
    local owner = GetOwner(inst)
    if owner ~= nil 
        and owner.components.combat ~= nil 
        and owner.components.combat.target == target then
        return false
    end

    return (target:HasTag("_combat") and not target:HasTag("player") and not target:HasTag("companion"))
end

local function ShouldGoBig(inst)
    local owner = GetOwner(inst)
    return owner ~= nil 
        and owner:HasTag("vox") 
        and owner.components.health ~= nil 
        and owner.components.health:GetPercent() <= 0.3
end

local OnigiryBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function OnigiryBrain:OnStart()
    local root = 
    PriorityNode(
    {
        -- 如果主人有低血量，变成暴走模式
        WhileNode(function() return ShouldGoBig(self.inst) end, "Should Go Big",
            DoAction(self.inst, function() 
                local owner = GetOwner(self.inst)
                if owner ~= nil then
                    self.inst:GoBig(owner)
                    return true
                end
                return false
            end)),

        -- 跟随主人
        Follow(self.inst, function() return GetOwner(self.inst) end, 2, 3, 7),

        -- 闲逛
        WhileNode(function() return GetHomePos(self.inst) ~= nil end, "Wander",
            Wander(self.inst, GetHomePos, 20, WANDER_TIMES)),
    }, .25)

    self.bt = BT(self.inst, root)
end

function OnigiryBrain:OnInitializationComplete()
    local owner = GetOwner(self.inst)
    if owner ~= nil and owner:HasTag("vox") then
        self.inst:ListenForEvent("attacked", function(owner, data) 
            if self.inst.CanRage(self.inst) then
                self.inst:GoBig(owner)
            end
        end, owner)
    end
end

return OnigiryBrain