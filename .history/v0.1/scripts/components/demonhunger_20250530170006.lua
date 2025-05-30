-- 恶魔饥饿值组件
-- components/demonhunger.lua

Assets = {
    Asset("ANIM", "anim/demon_hunger.zip"),
    Asset("ATLAS", "images/inventoryimages/hunger.xml"),
    Asset("IMAGE", "images/inventoryimages/hunger.tex"),
}

local DemonHunger = Class(function(self, inst)
    self.inst = inst
    self.max = 150
    self.current = 150
    self.rate = 0.75 -- 下降速度为普通饥饿值的75%
    self.hungertime = 0
    
    -- 启动更新任务
    self.inst:DoPeriodicTask(1, function() self:DoDec(1) end)
end)

function DemonHunger:OnSave()
    return {
        current = self.current,
    }
end

function DemonHunger:OnLoad(data)
    if data.current then
        self:SetCurrent(data.current)
    end
end

function DemonHunger:SetMax(amount)
    self.max = amount
end

function DemonHunger:GetMax()
    return self.max
end

function DemonHunger:SetCurrent(amount)
    self.current = math.clamp(amount, 0, self.max)
    self.inst:PushEvent("demohungerchange", { percent = self:GetPercent() })
end

function DemonHunger:GetCurrent()
    return self.current
end

function DemonHunger:GetPercent()
    return self.current / self.max
end

function DemonHunger:SetPercent(percent)
    self:SetCurrent(percent * self.max)
end

function DemonHunger:SetRate(rate)
    self.rate = rate
end

function DemonHunger:DoDec(dt)
    -- 根据rate计算实际消耗的饥饿值
    local hunger_amount = dt * self.rate * TUNING.WILSON_HUNGER_RATE
    
    self.hungertime = self.hungertime + dt
    
    if self.hungertime >= 1 then
        self.hungertime = 0
        if self.current > 0 then
            self:SetCurrent(self.current - hunger_amount)
        end
    end
end

function DemonHunger:DoDelta(delta)
    self:SetCurrent(self.current + delta)
    return true
end

-- 吃灵魂或噩梦燃料时调用的函数
function DemonHunger:Feed(food_type, amount)
    if food_type == "soul" then
        return self:DoDelta(20) -- 灵魂回复20点恶魔饥饿值
    elseif food_type == "nightmare_fuel" then
        return self:DoDelta(20) -- 噩梦燃料回复20点恶魔饥饿值
    end
    return false
end

-- 检查是否进入暴走模式（满150）
function DemonHunger:IsRampaging()
    return self.current >= self.max
end

return DemonHunger