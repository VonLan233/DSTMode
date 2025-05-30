-- 恶魔饥饿条Prefab
-- 用于VOX角色的专属恶魔饥饿值显示

local assets =
{
    Asset("ANIM", "anim/demon_hunger.zip"),   -- 假设你有一个自定义的饥饿条动画
    -- Asset("ATLAS", "images/hud/hunger.xml"),
    -- Asset("IMAGE", "images/hud/hunger.tex"),
}

-- 创建一个带有自定义组件的实体
local function fn()
    local inst = CreateEntity()
    
    -- 基本实体设置
    inst.entity:AddTransform()
    inst.entity:AddNetwork()
    
    -- 设置prefab为HUD元素
    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")
    inst:AddTag("demon_hunger")
    
    -- 初始化恶魔饥饿值组件
    inst:AddComponent("demonhunger")
    inst.components.demonhunger:SetMax(150)  -- 设置最大值为150
    inst.components.demonhunger:SetRate(0.75) -- 设置下降速度为普通饥饿值的75%
    inst.components.demonhunger:SetCurrent(150) -- 初始值为满
    
    -- 联网设置
    inst.entity:SetPristine()
    
    if not TheWorld.ismastersim then
        return inst
    end
    
    -- 服务器端逻辑
    inst.persists = false  -- 不在保存中持久化，因为它是UI元素
    
    return inst
end

-- 返回prefab定义
return Prefab("demon_hunger", fn, assets)