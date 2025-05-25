-- 参照bernie_common.lua的结构创建onigiri的通用函数

local fn = {}

-- 检查主人是否处于低生命值状态
fn.isOwnerInDanger = function(inst, owner)
    if owner.components.health and owner.components.health:GetPercent() <= 0.3 then
        return true
    end
    return false
end

-- 检查附近是否有敌对生物
local HOSTILES_DETECT_DIST = 20
local HOSTILE_MUST_TAGS = { "_combat", "hostile" }
local HOSTILE_CANT_TAGS = { "INLIMBO", "player", "companion" }
local HOSTILE_ONEOF_TAGS = { "monster", "epic" }

fn.hasNearbyHostiles = function(inst, owner)
    local x, y, z = inst.Transform:GetWorldPosition()
    local targets = TheSim:FindEntities(x, y, z, HOSTILES_DETECT_DIST, HOSTILE_MUST_TAGS, HOSTILE_CANT_TAGS, HOSTILE_ONEOF_TAGS)        
    if #targets > 0 then
        return true
    end
    return false
end

-- 获取主人当前目标
fn.getOwnerTarget = function(inst, owner)
    if owner and owner.components.combat and owner.components.combat:HasTarget() then
        return owner.components.combat.target
    end
    return nil
end

-- 获取附近最合适的攻击目标
fn.getBestTarget = function(inst, range)
    local x, y, z = inst.Transform:GetWorldPosition()
    local owner = inst.onigiriowner
    
    -- 优先攻击主人的目标
    if owner ~= nil and owner.components.combat ~= nil and owner.components.combat:HasTarget() then
        local target = owner.components.combat.target
        if target:IsValid() and not target:HasTag("player") and not target:HasTag("companion") then
            return target
        end
    end
    
    -- 其次是攻击玩家或同伴的敌人
    local players = FindPlayersInRange(x, y, z, range, true)
    for _, player in ipairs(players) do
        if player.components.combat ~= nil and player.components.combat:HasTarget() then
            local target = player.components.combat.target
            if target:IsValid() and not target:HasTag("player") and not target:HasTag("companion") then
                return target
            end
        end
    end
    
    -- 最后是附近的敌对生物
    local entities = TheSim:FindEntities(x, y, z, range, { "_combat" }, { "INLIMBO", "player", "companion" }, { "monster", "hostile" })
    if #entities > 0 then
        return entities[math.random(#entities)]
    end
    
    return nil
end

return fn