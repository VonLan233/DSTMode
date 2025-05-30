-- 恶魔饥饿条UI
-- widgets/demonhungerbadge.lua

local UIAnim = require "widgets/uianim"
local Image = require "widgets/image"
local Widget = require "widgets/widget"
local Text = require "widgets/text"

local DemonHungerBadge = Class(Widget, function(self, owner)
    Widget._ctor(self, "DemonHungerBadge")
    
    self.owner = owner
    
    -- 创建基础容器
    self.root = self:AddChild(Widget("demon_hunger_root"))
    
    -- 背景图
    self.bg = self.root:AddChild(Image("images/hud/demon_hunger.xml", "demon_hunger_bg.tex"))
    self.bg:SetScale(0.8, 0.8)
    
    -- 前景图（实际显示饥饿值的部分）
    self.fg = self.root:AddChild(Image("images/hud/demon_hunger.xml", "demon_hunger_fg.tex"))
    self.fg:SetScale(0.8, 0.8)
    self.fg:SetPosition(0, 0)
    
    -- 特效（暴走模式下显示）
    self.fx = self.root:AddChild(UIAnim())
    self.fx:GetAnimState():SetBank("demon_hunger_fx")
    self.fx:GetAnimState():SetBuild("demon_hunger")
    self.fx:GetAnimState():PlayAnimation("idle", true)
    self.fx:SetScale(0.8, 0.8)
    self.fx:Hide()
    
    -- 文本显示当前值
    self.num = self.root:AddChild(Text(NUMBERFONT, 28))
    self.num:SetPosition(2, 0)
    self.num:SetHAlign(ANCHOR_MIDDLE)
    self.num:SetVAlign(ANCHOR_MIDDLE)
    self.num:SetString("150")
    self.num:Hide() -- 默认隐藏数值，只在鼠标悬停时显示
    
    -- 设置初始大小
    self:SetScale(1, 1)
    
    -- 初始化状态
    self:UpdateState(1) -- 满格
    
    -- 注册监听事件
    self.inst:ListenForEvent("demohungerchange", function(owner, data) self:UpdateState(data.percent) end, owner)
    
    -- 注册鼠标事件
    self:SetOnGainFocus(function() self:OnGainFocus() end)
    self:SetOnLoseFocus(function() self:OnLoseFocus() end)
end)

function DemonHungerBadge:UpdateState(percent)
    -- 更新饥饿条显示
    self.fg:SetScale(0.8 * percent, 0.8)
    
    -- 更新数值显示
    local value = math.floor(percent * 150)
    self.num:SetString(tostring(value))
    
    -- 如果满了，显示暴走模式特效
    if percent >= 1 then
        self.fx:Show()
        self.fx:GetAnimState():PlayAnimation("full", true)
    else
        self.fx:Hide()
    end
    
    -- 根据饥饿程度变色
    if percent <= 0.25 then
        -- 低于25%显示红色
        self.fg:SetTint(1, 0.3, 0.3, 1)
    elseif percent >= 1 then
        -- 满值显示紫色（暴走模式）
        self.fg:SetTint(0.8, 0.2, 1, 1)
    else
        -- 正常显示蓝色
        self.fg:SetTint(0.3, 0.3, 1, 1)
    end
end

function DemonHungerBadge:OnGainFocus()
    self.num:Show()
end

function DemonHungerBadge:OnLoseFocus()
    self.num:Hide()
end

return DemonHungerBadge