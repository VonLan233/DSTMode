local Assets = {
    -- 角色相关
    Asset("IMAGE", "images/saveslot_portraits/vox.tex"),
    Asset("ATLAS", "images/saveslot_portraits/vox.xml"),
    Asset("IMAGE", "images/selectscreen_portraits/vox.tex"),
    Asset("ATLAS", "images/selectscreen_portraits/vox.xml"),
    Asset("IMAGE", "images/selectscreen_portraits/vox_silho.tex"),
    Asset("ATLAS", "images/selectscreen_portraits/vox_silho.xml"),
    Asset("IMAGE", "bigportraits/vox.tex"),
    Asset("ATLAS", "bigportraits/vox.xml"),
    Asset("IMAGE", "images/map_icons/vox.tex"),
    Asset("ATLAS", "images/map_icons/vox.xml"),
    Asset("IMAGE", "images/avatars/avatar_vox.tex"),
    Asset("ATLAS", "images/avatars/avatar_vox.xml"),
    Asset("IMAGE", "images/avatars/avatar_ghost_vox.tex"),
    Asset("ATLAS", "images/avatars/avatar_ghost_vox.xml"),
    Asset("IMAGE", "images/avatars/self_inspect_vox.tex"),
    Asset("ATLAS", "images/avatars/self_inspect_vox.xml"),
    
    -- 专属物品相关
    Asset("IMAGE", "images/inventoryimages/yamchaflower_robe.tex"),
    Asset("ATLAS", "images/inventoryimages/yamchaflower_robe.xml"),
    Asset("IMAGE", "images/inventoryimages/lord_tachi.tex"),
    Asset("ATLAS", "images/inventoryimages/lord_tachi.xml"),
    Asset("IMAGE", "images/inventoryimages/onigiri.tex"),
    Asset("ATLAS", "images/inventoryimages/onigiri.xml"),
    Asset("IMAGE", "images/inventoryimages/cydonia_letter.tex"),
    Asset("ATLAS", "images/inventoryimages/cydonia_letter.xml"),
    Asset("IMAGE", "images/inventoryimages/throne_ruins.tex"),
    Asset("ATLAS", "images/inventoryimages/throne_ruins.xml"),
    Asset("IMAGE", "images/hud/demon_hunger.tex"),
    Asset("ATLAS", "images/hud/demon_hunger.xml"),
}

PrefabFiles = {
    "vox",
    "vox_fx",
    "vox_none",
    "yamchaflower_robe",
    "lord_tachi",
    "onigiri",
    "cydonia_letter",
    "demonhunger",
    "onigiri_ragefx",
    "kindred",
    "throne_ruins", -- 后续实现
}

local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS
local TUNING = GLOBAL.TUNING
local ACTIONS = GLOBAL.ACTIONS
local ActionHandler = GLOBAL.ActionHandler
local EQUIPSLOTS = GLOBAL.EQUIPSLOTS
local State = GLOBAL.State
local TimeEvent = GLOBAL.TimeEvent
local EventHandler = GLOBAL.EventHandler
local FOODTYPE = GLOBAL.FOODTYPE
local SpawnPrefab = GLOBAL.SpawnPrefab

-- 恶魔饥饿条UI实现
-- 添加到modmain.lua

local require = GLOBAL.require
local Widget = require "widgets/widget"
local Image = require "widgets/image"
local Text = require "widgets/text"

local function AddDemonHungerImages()
    AddMinimapAtlas("images/hud/demon_hunger.xml")
end
AddGamePostInit(AddDemonHungerImages)

-- 恶魔饥饿条UI Widget
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
    
    -- 暴走模式指示器
    self.rage = self.root:AddChild(Image("images/hud/demon_hunger.xml", "demon_hunger_rampage.tex"))
    self.rage:SetScale(0.8, 0.8)
    self.rage:Hide()
    
    -- 文本显示当前值
    self.num = self.root:AddChild(Text(NUMBERFONT, 28))
    self.num:SetPosition(2, 0)
    self.num:SetHAlign(ANCHOR_MIDDLE)
    self.num:SetVAlign(ANCHOR_MIDDLE)
    self.num:SetString("0")
    self.num:Hide() -- 默认隐藏数值，只在鼠标悬停时显示
    
    -- 设置初始大小和位置
    self:SetScale(1, 1)
    self:UpdateState(0) -- 初始为空
    
    -- 注册监听事件
    self.inst:ListenForEvent("demonhungerdelta", function(owner, data) 
        self:UpdateState(data.newpercent)
    end, owner)
    
    -- 注册鼠标事件
    self:SetOnGainFocus(function() self:OnGainFocus() end)
    self:SetOnLoseFocus(function() self:OnLoseFocus() end)
end)

function DemonHungerBadge:UpdateState(percent)
    -- 更新填充图的缩放来表示当前值
    self.fg:SetScale(0.8 * percent, 0.8)
    
    -- 更新数值显示
    local value = math.floor(percent * 150)
    self.num:SetString(tostring(value))
    
    -- 不同状态下的颜色变化
    if percent <= 0.25 then
        -- 低于25%显示红色
        self.fg:SetTint(1, 0.3, 0.3, 1)
    elseif percent >= 1 then
        -- 满值显示紫色（暴走模式）
        self.fg:SetTint(0.8, 0.2, 1, 1)
        self.rage:Show()
    else
        -- 正常显示蓝色
        self.fg:SetTint(0.3, 0.3, 1, 1)
        self.rage:Hide()
    end
end

function DemonHungerBadge:OnGainFocus()
    self.num:Show()
end

function DemonHungerBadge:OnLoseFocus()
    self.num:Hide()
end

-- 添加恶魔饥饿条到VOX角色的HUD
local function AddDemonHungerBadge(self)
    -- 只为VOX角色添加
    if self.owner and self.owner:HasTag("vox") then
        self.demonhunger = self:AddChild(DemonHungerBadge(self.owner))
        
        -- 设置位置（根据你的UI布局调整）
        -- 这个位置在饥饿条右侧
        self.demonhunger:SetPosition(100, 40)
        
        -- 初始化
        if self.owner.components.hunger then
            local percent = self.owner.components.hunger:GetDemonPercent() or 0
            self.demonhunger:UpdateState(percent)
        end
    end
end

-- 将UI加入到状态显示
AddClassPostConstruct("widgets/statusdisplays", AddDemonHungerBadge)

-- 添加新的食物类型：海鲜
FOODTYPE.SEAFOOD = "SEAFOOD"

-- 为食物添加海鲜标签
local SEAFOOD_LIST = {
    "fish", "fish_cooked", "eel", "eel_cooked", "froglegs", "froglegs_cooked", "tropical_fish",
    "fishsticks", "surfnturf", "californiaroll", "seafoodgumbo", "lobster", "lobster_cooked", 
    "lobsterbisque", "lobsterdinner", "barnacle", "barnacle_cooked", "barnaclesushi", "barnaclepita",
    "barnaclewings", "crabmeat", "crabmeat_cooked", "ceviche", "mussel", "mussel_cooked", "sweet_potato_soup"
}

for k, v in pairs(GLOBAL.Prefabs) do
    if GLOBAL.table.contains(SEAFOOD_LIST, k) then
        AddPrefabPostInit(k, function(inst)
            if inst.components.edible then
                inst.components.edible.foodtype = FOODTYPE.SEAFOOD
            end
        end)
    end
end

-- 添加恶魔饥饿值组件
-- 修复方案：在modmain.lua中添加饥饿组件扩展
AddComponentPostInit("hunger", function(self, inst)
    if inst:HasTag("vox") then
        -- 添加恶魔饥饿值属性
        self.max_demon_hunger = 150
        self.current_demon_hunger = 0
        self.demon_hunger_rate = 0.75 -- 下降速度为普通饥饿值的75%
        
        -- 恶魔饥饿值相关函数
        function self:GetDemonPercent()
            return self.current_demon_hunger / self.max_demon_hunger
        end
        
        function self:SetDemonHunger(amount)
            self.current_demon_hunger = math.clamp(amount, 0, self.max_demon_hunger)
            self.inst:PushEvent("demonhungerdelta", {
                oldpercent = (self.current_demon_hunger - (amount - self.current_demon_hunger)) / self.max_demon_hunger,
                newpercent = self.current_demon_hunger / self.max_demon_hunger
            })
        end
        
        function self:DoDemonDelta(delta)
            local old = self.current_demon_hunger
            self:SetDemonHunger(self.current_demon_hunger + delta)
            return self.current_demon_hunger - old
        end
        
        -- 重写DoDelta以实现恶魔饥饿值为0时普通食物只能回复5%的机制
        local old_DoDelta = self.DoDelta
        function self:DoDelta(delta)
            if delta > 0 and self.current_demon_hunger <= 0 then
                delta = delta * 0.05 -- 恶魔饥饿值为0时，普通食物只能回复5%
            end
            return old_DoDelta(self, delta)
        end
        
        -- 暴走模式检查
        function self:CheckRageMode()
            if self.current_demon_hunger >= self.max_demon_hunger then
                self.inst:PushEvent("enterdemonrage")
            elseif self.current_demon_hunger <= 0 and self.inst:HasTag("demonrage") then
                self.inst:PushEvent("exitdemonrage")
            end
        end
        
        -- 恶魔饥饿值周期性下降
        self.inst:DoPeriodicTask(1, function()
            if self.current_demon_hunger > 0 then
                self:DoDemonDelta(-TUNING.WILSON_HUNGER_RATE * self.demon_hunger_rate)
                self:CheckRageMode()
            end
        end)
    end
end)

-- 添加Vox的技能和特性
AddPlayerPostInit(function(inst)
    if inst.prefab == "vox" then
        -- 基础属性设置
        if inst.components.health then
            inst.components.health.maxhealth = 200
        end
        
        if inst.components.sanity then
            inst.components.sanity.max = 120
        end
        
        if inst.components.hunger then
            inst.components.hunger.max = 150
            inst.components.hunger:DoDemonDelta(0) -- 初始化恶魔饥饿值
        end
        
        -- 记录已击杀的Boss
        inst.killedbosses = {}
        
        -- 等级系统
        inst.level = 0
        inst.maxlevel = 10
        inst.experience = 0
        inst.nextlevelexp = 100 -- 初始升级所需经验
        
        -- 添加升级经验值的函数
        inst.AddExperience = function(inst, amount)
            if inst.level >= inst.maxlevel then return end
            
            inst.experience = inst.experience + amount
            if inst.experience >= inst.nextlevelexp then
                -- 升级
                inst.level = inst.level + 1
                inst.experience = inst.experience - inst.nextlevelexp
                inst.nextlevelexp = inst.nextlevelexp * 1.5 -- 每级提高50%经验需求
                
                -- 升级奖励逻辑
                inst:PushEvent("levelup", {level = inst.level})
                
                if inst.level == inst.maxlevel then
                    -- 满级解锁混天绫
                    -- 添加满级解锁物品的逻辑
                    inst.components.talker:Say("我达到了最强形态！")
                else
                    inst.components.talker:Say("我变强了！等级: " .. inst.level)
                end
            end
        end
        
        -- 添加杀怪获得灵魂的能力
        inst:ListenForEvent("killed", function(inst, data)
            if data and data.victim then
                local victim = data.victim
                
                -- 杀邪恶生物回复san
                if victim:HasTag("monster") then
                    if inst.components.sanity then
                        inst.components.sanity:DoDelta(5)
                    end
                end
                
                -- 杀猴子扣san
                if victim:HasTag("monkey") then
                    if inst.components.sanity then
                        inst.components.sanity:DoDelta(-15)
                    end
                end
                
                -- 杀Boss获得能力
                if victim:HasTag("epic") then
                    -- 检查是否是首次杀死该Boss
                    local bossname = victim.prefab
                    if not inst.killedbosses[bossname] then
                        inst.killedbosses[bossname] = true
                        
                        -- 根据Boss类型添加对应buff
                        inst:AddBossBuff(bossname)
                        
                        -- 角变长的效果
                        inst:PushEvent("horngrow", {boss = bossname})
                    end
                end
                
                -- 获取经验值
                local exp = 0
                if victim:HasTag("epic") then
                    exp = 100 -- Boss经验值
                elseif victim:HasTag("monster") then
                    exp = 10 -- 怪物经验值
                else
                    exp = 1 -- 普通生物经验值
                end
                
                inst:AddExperience(exp)
                
                -- 生成灵魂
                if not victim:HasTag("veggie") and not victim:HasTag("structure") then
                    local soul = SpawnPrefab("wortox_soul")
                    if soul then
                        soul.Transform:SetPosition(victim.Transform:GetWorldPosition())
                    end
                end
            end
        end)
        
        -- 添加Boss Buff函数
        inst.AddBossBuff = function(inst, bossname)
            -- 清除当前所有临时buff
            if inst.bossbufftask then
                inst.bossbufftask:Cancel()
                inst.bossbufftask = nil
            end
            
            -- 重置所有boss技能
            inst:RemoveTag("spiderwhisperer") -- 蜘蛛女王技能
            inst:RemoveTag("dragonflybuff") -- 龙蝇技能
            inst:RemoveTag("deerbuff") -- 巨鹿技能
            inst:RemoveTag("moosebuff") -- 大鹅技能
            inst:RemoveTag("antlionbuff") -- 蚁狮技能
            inst:RemoveTag("bearbuff") -- 熊技能
            inst:RemoveTag("beequeen") -- 蜂后技能
            inst:RemoveTag("klausbuff") -- 克劳斯技能
            inst:RemoveTag("ancientshadow") -- 远古守护者技能
            inst:RemoveTag("toadbuff") -- 毒菌蟾蜍技能
            inst:RemoveTag("shadowweaverbuff") -- 织影者技能
            inst:RemoveTag("mutebuff") -- 邪天翁技能
            inst:RemoveTag("crabkingbuff") -- 帝王蟹技能
            inst:RemoveTag("celestialbuff") -- 天体英雄技能
            
            -- 添加新的buff
            local buffname = ""
            if bossname == "spiderqueen" then
                inst:AddTag("spiderwhisperer")
                buffname = "蜘蛛女王之力"
            elseif bossname == "dragonfly" then
                inst:AddTag("dragonflybuff")
                buffname = "龙蝇之力"
            elseif bossname == "deerclops" then
                inst:AddTag("deerbuff")
                buffname = "巨鹿之力"
            elseif bossname == "moose" or bossname == "mooseegg" or bossname == "mossling" then
                inst:AddTag("moosebuff")
                buffname = "大鹅之力"
            elseif bossname == "antlion" then
                inst:AddTag("antlionbuff")
                buffname = "蚁狮之力"
            elseif bossname == "bearger" then
                inst:AddTag("bearbuff")
                buffname = "熊之力"
            elseif bossname == "beequeen" then
                inst:AddTag("beequeen")
                buffname = "蜂后之力"
            elseif bossname == "klaus" then
                inst:AddTag("klausbuff")
                buffname = "克劳斯之力"
            elseif bossname == "ancient_fuelweaver" then
                inst:AddTag("ancientshadow")
                buffname = "远古守护者之力"
            elseif bossname == "toadstool" or bossname == "toadstool_dark" then
                inst:AddTag("toadbuff")
                buffname = "毒菌蟾蜍之力"
            elseif bossname == "shadowthrall_hands" or bossname == "stalker" or bossname == "stalker_forest" then
                inst:AddTag("shadowweaverbuff")
                buffname = "织影者之力"
            elseif bossname == "malbatross" then
                inst:AddTag("mutebuff")
                buffname = "邪天翁之力"
            elseif bossname == "crabking" then
                inst:AddTag("crabkingbuff")
                buffname = "帝王蟹之力"
            elseif bossname == "alterguardian_phase1" or bossname == "alterguardian_phase2" or bossname == "alterguardian_phase3" then
                inst:AddTag("celestialbuff")
                buffname = "天体英雄之力"
            end
            
            if buffname ~= "" then
                inst.components.talker:Say("获得了" .. buffname .. "！(持续5天)")
                
                -- 5天后移除buff
                inst.bossbufftask = inst:DoTaskInTime(5 * 480, function() -- 5天 * 一天480秒
                    inst:RemoveTag(inst:HasTag("spiderwhisperer") and "spiderwhisperer" or
                                   inst:HasTag("dragonflybuff") and "dragonflybuff" or
                                   inst:HasTag("deerbuff") and "deerbuff" or
                                   inst:HasTag("moosebuff") and "moosebuff" or
                                   inst:HasTag("antlionbuff") and "antlionbuff" or
                                   inst:HasTag("bearbuff") and "bearbuff" or
                                   inst:HasTag("beequeen") and "beequeen" or
                                   inst:HasTag("klausbuff") and "klausbuff" or
                                   inst:HasTag("ancientshadow") and "ancientshadow" or
                                   inst:HasTag("toadbuff") and "toadbuff" or
                                   inst:HasTag("shadowweaverbuff") and "shadowweaverbuff" or
                                   inst:HasTag("mutebuff") and "mutebuff" or
                                   inst:HasTag("crabkingbuff") and "crabkingbuff" or
                                   "celestialbuff")
                    inst.components.talker:Say(buffname .. "消失了...")
                    inst.bossbufftask = nil
                end)
            end
        end
        
        -- 恶魔饥饿值暴走模式 
        inst:ListenForEvent("enterdemonrage", function(inst)
            -- 进入暴走模式效果
            inst.components.talker:Say("恶魔之力爆发！")
            
            -- 95%的减伤
            if inst.components.health then
                inst.normalabsorption = inst.components.health.absorb or 0
                inst.components.health.absorb = 0.95
            end
            
            -- 每2秒回复1点血
            inst.ragehealtask = inst:DoPeriodicTask(2, function()
                if inst.components.health then
                    inst.components.health:DoDelta(1, true)
                end
            end)
            
            -- 每秒扣2点san
            inst.ragesantask = inst:DoPeriodicTask(1, function()
                if inst.components.sanity then
                    inst.components.sanity:DoDelta(-2)
                end
            end)

            -- 每秒扣除恶魔饥饿值
            inst:DoPeriodicTask(1, function()
                if inst.components.hunger then
                    inst.components.hunger:DoDemonDelta(-2)
                end
            end)
            
            -- 增加暴走模式动画效果
            inst.AnimState:SetMultColor(1, 0.7, 0.7, 1)
            
            -- 视觉效果
            local fx = SpawnPrefab("statue_transition_2")
            if fx then
                fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
                fx.Transform:SetScale(1, 1.5, 1)
            end
            
            -- 添加暴走模式标签
            inst:AddTag("demonrage")
        end)
        
        inst:ListenForEvent("exitdemonrage", function(inst)
            -- 退出暴走模式效果
            inst.components.talker:Say("恶魔之力消退...")
            
            -- 恢复正常伤害吸收
            if inst.components.health then
                inst.components.health.absorb = inst.normalabsorption or 0
                inst.normalabsorption = nil
            end
            
            -- 取消定时任务
            if inst.ragehealtask then
                inst.ragehealtask:Cancel()
                inst.ragehealtask = nil
            end
            
            if inst.ragesantask then
                inst.ragesantask:Cancel()
                inst.ragesantask = nil
            end
            
            -- 恢复正常外观
            inst.AnimState:SetMultColor(1, 1, 1, 1)
            
            -- 移除暴走模式标签
            inst:RemoveTag("demonrage")
        end)
        
        -- 添加对海鲜的厌恶
        inst:ListenForEvent("oneat", function(inst, data)
            if data and data.food and data.food.components.edible and data.food.components.edible.foodtype == FOODTYPE.SEAFOOD then
                inst.components.talker:Say("呕! 我讨厌海鲜!")
                if inst.components.health then
                    inst.components.health:DoDelta(-5)
                end
                if inst.components.sanity then
                    inst.components.sanity:DoDelta(-10)
                end
                
                -- 呕吐动画/效果
                local puke = SpawnPrefab("vomit")
                if puke then
                    puke.Transform:SetPosition(inst.Transform:GetWorldPosition())
                end
            end
        end)
        
        -- 可以吃噩梦燃料
        inst:ListenForEvent("oneat", function(inst, data)
            if data and data.food and data.food.prefab == "nightmarefuel" then
                -- 噩梦燃料：回复20恶魔饥饿值，15san，10生命值
                if inst.components.hunger then
                    inst.components.hunger:DoDemonDelta(20)
                end
                
                if inst.components.sanity then
                    inst.components.sanity:DoDelta(15)
                end
                
                if inst.components.health then
                    inst.components.health:DoDelta(10)
                end
            end
        end)
        
        -- 添加对猴子的亲和力
        local old_OnEntitySleep = inst.OnEntitySleep
        inst.OnEntitySleep = function(inst)
            if old_OnEntitySleep then
                old_OnEntitySleep(inst)
            end
            
            inst.monkeysentask = nil
        end
        
        local old_OnEntityWake = inst.OnEntityWake
        inst.OnEntityWake = function(inst)
            if old_OnEntityWake then
                old_OnEntityWake(inst)
            end
            
            if not inst.monkeysentask then
                inst.monkeysentask = inst:DoPeriodicTask(10, function()
                    local x, y, z = inst.Transform:GetWorldPosition()
                    local monkeys = TheSim:FindEntities(x, y, z, 10, {"monkey"})
                    
                    -- 靠近猴子回复san
                    if #monkeys > 0 and inst.components.sanity then
                        inst.components.sanity:DoDelta(1 * #monkeys)
                    end
                end)
            end
        end
        
        -- 靠近恶魔花恢复san
        inst:DoPeriodicTask(5, function()
            local x, y, z = inst.Transform:GetWorldPosition()
            local evilflowers = TheSim:FindEntities(x, y, z, 5, {"flower_evil"})
            
            if #evilflowers > 0 and inst.components.sanity then
                inst.components.sanity:DoDelta(0.5 * #evilflowers)
            end
        end)
        
        -- 开局给予物品
        inst:DoTaskInTime(0.5, function()
            -- 山茶花羽织
            local robe = SpawnPrefab("yamchaflower_robe")
            if robe and inst.components.inventory then
                inst.components.inventory:GiveItem(robe)
            end
            
            -- Onigiri挂件
            local onigiri = SpawnPrefab("onigiri")
            if onigiri and inst.components.inventory then
                inst.components.inventory:GiveItem(onigiri)
            end
            
            -- 信封
            local letter = SpawnPrefab("cydonia_letter")
            if letter and inst.components.inventory then
                inst.components.inventory:GiveItem(letter)
            end
        end)
    end
end)

-- 检测猴子位置的按键绑定
local KEY_H = 72 -- H键
TheInput:AddKeyDownHandler(KEY_H, function()
    local player = GLOBAL.ThePlayer
    if player and player.prefab == "vox" then
        local x, y, z = player.Transform:GetWorldPosition()
        local monkeys = TheSim:FindEntities(x, y, z, 60, {"monkey"})
        
        if #monkeys > 0 then
            local nearest = nil
            local nearestDist = math.huge
            
            for _, monkey in ipairs(monkeys) do
                local mx, my, mz = monkey.Transform:GetWorldPosition()
                local dist = math.sqrt((x - mx)^2 + (z - mz)^2)
                
                if dist < nearestDist then
                    nearest = monkey
                    nearestDist = dist
                end
            end
            
            if nearest then
                local direction = ""
                local mx, my, mz = nearest.Transform:GetWorldPosition()
                
                -- 计算方向
                local angle = math.atan2(mz - z, mx - x) * 180 / math.pi
                
                if angle > -22.5 and angle <= 22.5 then
                    direction = "东方"
                elseif angle > 22.5 and angle <= 67.5 then
                    direction = "东北方"
                elseif angle > 67.5 and angle <= 112.5 then
                    direction = "北方"
                elseif angle > 112.5 and angle <= 157.5 then
                    direction = "西北方"
                elseif angle > 157.5 or angle <= -157.5 then
                    direction = "西方"
                elseif angle > -157.5 and angle <= -112.5 then
                    direction = "西南方"
                elseif angle > -112.5 and angle <= -67.5 then
                    direction = "南方"
                elseif angle > -67.5 and angle <= -22.5 then
                    direction = "东南方"
                end
                
                local distance = ""
                if nearestDist < 10 then
                    distance = "很近"
                elseif nearestDist < 20 then
                    distance = "不远"
                elseif nearestDist < 40 then
                    distance = "有点远"
                else
                    distance = "很远"
                end
                
                player.components.talker:Say("我感觉到" .. distance .. "的" .. direction .. "有猴子!")
            end
        else
            player.components.talker:Say("附近没有猴子...")
        end
    end
end)

-- 添加角色选择界面的信息
STRINGS.CHARACTER_TITLES.vox = "恶魔剑客"
STRINGS.CHARACTER_NAMES.vox = "Vox"
STRINGS.CHARACTER_DESCRIPTIONS.vox = "• 拥有恶魔之力\n• 讨厌海鲜食物\n• 杀Boss获得能力\n• 与猴子有特殊亲和力"
STRINGS.CHARACTER_QUOTES.vox = "\"来自New Cydonia的战士\""
STRINGS.CHARACTER_SURVIVABILITY.vox = "奇特"

-- 自定义技能和配方
AddMinimapAtlas("images/map_icons/vox.xml")
AddModCharacter("vox", "MALE")

-- 添加配方
local yamchaflower_robe = Recipe("yamchaflower_robe", 
    {Ingredient("silk", 4), Ingredient("rope", 1), Ingredient("log", 4)}, 
    RECIPETABS.DRESS, TECH.SCIENCE_ONE)
yamchaflower_robe.atlas = "images/inventoryimages/yamchaflower_robe.xml"

local lord_tachi = Recipe("lord_tachi",
    {Ingredient("redgem", 1), Ingredient("goldnugget", 4), Ingredient("nightmarefuel", 2)},
    RECIPETABS.WAR, TECH.SCIENCE_TWO)
lord_tachi.atlas = "images/inventoryimages/lord_tachi.xml"

-- 确保只有VOX能够制作专属物品
yamchaflower_robe.sortkey = 0
yamchaflower_robe:AddTag("voxonly")
lord_tachi.sortkey = 0
lord_tachi:AddTag("voxonly")

-- 给VOX专属食谱添加可见性
AddIngredientValues({"nightmarefuel"}, {nightmarefuel = 1})

-- 创建放置饭团的动作
local PLACEONIGIRIS = Action({ priority=5, rmb=true, distance=1.5 })
PLACEONIGIRIS.id = "PLACEONIGIRIS"
PLACEONIGIRIS.str = "放置饭团"
PLACEONIGIRIS.fn = function(act)
    if act.doer and act.invobject and act.invobject.prefab == "onigiri" then
        local health_percent = act.doer.components.health:GetPercent()
        if health_percent <= 0.3 then
            local pos = act.pos or act.doer:GetPosition()
            local onigiri = act.invobject
            
            if onigiri.components.inventoryitem then
                onigiri.components.inventoryitem:RemoveFromOwner()
                onigiri.Transform:SetPosition(pos.x, pos.y, pos.z)
                
                if onigiri.can_rage_again ~= false then
                    onigiri:PushEvent("startrage")
                    return true
                else
                    if act.doer.components.talker then
                        act.doer.components.talker:Say("饭团需要休息...")
                    end
                    return false
                end
            end
        else
            if act.doer.components.talker then
                act.doer.components.talker:Say("现在不需要饭团的保护...")
            end
            return false
        end
    end
    return false
end

AddAction(PLACEONIGIRIS)

AddComponentAction("INVENTORY", "inventoryitem", function(inst, doer, actions, right)
    if inst.prefab == "onigiri" and right and doer.prefab == "vox" and doer.components.health and doer.components.health:GetPercent() <= 0.3 then
        table.insert(actions, ACTIONS.PLACEONIGIRIS)
    end
end)

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(ACTIONS.PLACEONIGIRIS, "dolongaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(ACTIONS.PLACEONIGIRIS, "dolongaction"))

-- 猴子相关的修改
AddPrefabPostInit("monkey", function(inst)
    local old_ShouldAcceptItem = nil
    if inst.components.trader then
        old_ShouldAcceptItem = inst.components.trader.ShouldAcceptItem
        inst.components.trader.ShouldAcceptItem = function(inst, item, giver)
            if giver and giver:HasTag("vox") then
                return item.prefab == "banana" or item.prefab == "cave_banana"
            end
            return old_ShouldAcceptItem(inst, item, giver)
        end
    end
    
    -- 不会偷Vox的东西
    if inst.components.thief then
        local old_StealItem = inst.components.thief.StealItem
        inst.components.thief.StealItem = function(self, target)
            if target and target:HasTag("vox") then
                return nil
            end
            return old_StealItem(self, target)
        end
    end
    
    -- 靠近时不会跑
    local old_OnEntityWake = inst.OnEntityWake
    inst.OnEntityWake = function(inst)
        if old_OnEntityWake then
            old_OnEntityWake(inst)
        end
        
        inst:DoPeriodicTask(1, function()
            local x, y, z = inst.Transform:GetWorldPosition()
            local players = TheSim:FindEntities(x, y, z, 10, {"player"})
            
            for _, player in ipairs(players) do
                if player:HasTag("vox") and inst.components.combat then
                    inst.components.combat:SetTarget(nil)
                    if inst.components.locomotor then
                        inst.components.locomotor:Stop()
                    end
                end
            end
        end)
    end
end)

-- 猴子海盗不抢劫Vox
AddPrefabPostInit("monkeybarrel", function(inst)
    local old_SpawnMonkeys = inst.SpawnMonkeys
    if old_SpawnMonkeys then
        inst.SpawnMonkeys = function(inst, boat, player)
            if player and player:HasTag("vox") then
                return -- 不对Vox生成海盗猴
            end
            return old_SpawnMonkeys(inst, boat, player)
        end
    end
end)

-- Vox对噩梦燃料和灵魂的使用
AddPrefabPostInit("wortox_soul", function(inst)
    local old_OnPickedUp = inst.OnPickedUp
    if inst.OnPickedUp then
        inst.OnPickedUp = function(inst, pickupguy, src_pos)
            if old_OnPickedUp then
                old_OnPickedUp(inst, pickupguy, src_pos)
            end
            
            if pickupguy and pickupguy:HasTag("vox") and pickupguy.components.hunger then
                if pickupguy.components.sanity then
                    pickupguy.components.sanity:DoDelta(-5) -- 减少san值
                end
                
                pickupguy.components.hunger:DoDemonDelta(15) -- 增加恶魔饥饿值
                
                inst:Remove() -- 移除灵魂
            end
        end
    end
end)

-- 添加恶魔饥饿值UI
local demonhunger_widget = require("widgets/demonhungerwidget")
AddClassPostConstruct("widgets/statusdisplays", function(self)
    if self.owner and self.owner:HasTag("vox") then
        self.demonhunger = self:AddChild(demonhunger_widget(self.owner))
        self.demonhunger:SetPosition(-100, 0, 0)
    end
end)

-- Boss修改 - 猴子岛不诅咒Vox
AddPrefabPostInit("monkeyisland_portal", function(inst)
    local old_fn = inst.components.teleporter.onActivate
    if inst.components.teleporter then
        inst.components.teleporter.onActivate = function(inst, obj)
            if obj and obj:HasTag("vox") then
                -- 不应用猴子诅咒
                obj:DoTaskInTime(1, function() 
                    obj:RemoveTag("wonkey")
                    
                    -- 寻找并移除猴子变身效果
                    local skin_fx = obj:GetSkinAnim()
                    if skin_fx and skin_fx:sub(-6) == "_wonkey" then
                        obj:SetSkinAnim(skin_fx:sub(1, -8))
                    end
                end)
            end
            if old_fn then
                old_fn(inst, obj)
            end
        end
    end
end)

-- 在火焰中不会烧伤
AddComponentPostInit("temperature", function(self, inst)
    local old_GetTemp = self.GetTemp
    function self:GetTemp()
        if self.inst:HasTag("vox") and self.inst:HasTag("dragonflybuff") then
            return 25 -- 适宜温度
        end
        return old_GetTemp(self)
    end
    
    local old_OnUpdate = self.OnUpdate
    function self:OnUpdate(dt)
        if self.inst:HasTag("vox") and self.inst:HasTag("dragonflybuff") then
            self.current = 25
            if self.inst.components.health then
                self.inst.components.health:SetInvincible("fire", true)
            end
        else
            if self.inst:HasTag("vox") and self.inst.components.health then
                self.inst.components.health:SetInvincible("fire", false)
            end
            if old_OnUpdate then
                old_OnUpdate(self, dt)
            end
        end
    end
end)

-- 当有巨鹿的能力时不会冻结
AddComponentPostInit("freezable", function(self, inst)
    local old_AddColdness = self.AddColdness
    function self:AddColdness(coldness, freezetime)
        if self.inst:HasTag("vox") and self.inst:HasTag("deerbuff") then
            return
        end
        return old_AddColdness(self, coldness, freezetime)
    end
end)

-- 有大鹅能力时不会被雷击和雨水影响
AddComponentPostInit("moisture", function(self, inst)
    local old_GetMoisture = self.GetMoisture
    function self:GetMoisture()
        if self.inst:HasTag("vox") and self.inst:HasTag("moosebuff") then
            return 0
        end
        return old_GetMoisture(self)
    end
end)

AddComponentPostInit("playerlightningtarget", function(self, inst)
    local old_SetHitChance = self.SetHitChance
    function self:SetHitChance(chance)
        if self.inst:HasTag("vox") and self.inst:HasTag("moosebuff") then
            return old_SetHitChance(self, 0)
        end
        return old_SetHitChance(self, chance)
    end
end)

-- 有蚁狮能力时获得灵魂跳跃能力
AddComponentPostInit("playercontroller", function(self, inst)
    local old_DoAction = self.DoAction
    function self:DoAction(buffaction)
        if buffaction and buffaction.action == ACTIONS.BLINK and self.inst:HasTag("vox") and not self.inst:HasTag("antlionbuff") then
            self.inst.components.talker:Say("我需要蚁狮的能力才能灵魂跳跃!")
            return false
        end
        return old_DoAction(self, buffaction)
    end
end)

-- 克劳斯的自动复活能力
AddComponentPostInit("health", function(self, inst)
    local old_DoDelta = self.DoDelta
    function self:DoDelta(amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
        if amount < 0 and self.currenthealth + amount <= 0 and self.inst:HasTag("vox") and self.inst:HasTag("klausbuff") then
            -- 触发克劳斯复活
            self.inst:PushEvent("klausrevive")
            self.inst:RemoveTag("klausbuff") -- 使用后移除能力
            
            -- 视觉效果
            local fx = SpawnPrefab("fx_book_light")
            if fx then
                fx.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
            end
            
            self.inst.components.talker:Say("克劳斯的能力拯救了我!")
            
            -- 恢复一半血量
            self:SetPercent(0.5)
            return 0
        end
        return old_DoDelta(self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    end
end)

-- 远古守护者的暗影触手攻击
AddComponentPostInit("combat", function(self, inst)
    local old_DoAttack = self.DoAttack
    function self:DoAttack(target, weapon, projectile, stimuli, instancemult)
        local result = old_DoAttack(self, target, weapon, projectile, stimuli, instancemult)
        
        if result and target and self.inst:HasTag("vox") and self.inst:HasTag("ancientshadow") then
            -- 生成暗影触手
            local x, y, z = target.Transform:GetWorldPosition()
            local tentacle = SpawnPrefab("shadowtentacle")
            if tentacle then
                tentacle.Transform:SetPosition(x, y, z)
                tentacle:DoTaskInTime(0.3, function()
                    if target and target.components.health and not target.components.health:IsDead() then
                        target.components.health:DoDelta(-34)
                        
                        -- 视觉效果
                        local fx = SpawnPrefab("statue_transition")
                        if fx then
                            fx.Transform:SetPosition(x, y, z)
                        end
                    end
                end)
            end
        end
        
        return result
    end
end)

-- 毒菌蟾蜍的物品保鲜效果
AddComponentPostInit("perishable", function(self, inst)
    local old_StartPerishing = self.StartPerishing
    function self:StartPerishing()
        old_StartPerishing(self)
        
        -- 查找物品是否在Vox的物品栏内
        local owner = self.inst.components.inventoryitem and self.inst.components.inventoryitem:GetGrandOwner()
        if owner and owner:HasTag("vox") and owner:HasTag("toadbuff") then
            self.perishremainingtime = self.perishremainingtime * 10 -- 腐烂速度减慢10倍
        end
    end
end)

-- 织影者的骨甲效果
AddPlayerPostInit(function(inst)
    if inst.prefab == "vox" and not inst.shadowweavertask then
        inst.shadowweavertask = inst:DoPeriodicTask(0.1, function()
            if inst:HasTag("shadowweaverbuff") then
                if not inst.boneguardtimer then
                    inst.boneguardtimer = 0
                end
                
                inst.boneguardtimer = inst.boneguardtimer + 0.1
                
                if inst.boneguardtimer >= 5 then
                    inst.boneguardtimer = 0
                    
                    -- 添加无敌效果
                    if inst.components.health then
                        inst.components.health:SetInvincible(true)
                        
                        -- 视觉效果
                        local fx = SpawnPrefab("statue_transition_2")
                        if fx then
                            fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
                        end
                        
                        -- 0.3秒后恢复正常
                        inst:DoTaskInTime(0.3, function()
                            if inst.components.health then
                                inst.components.health:SetInvincible(false)
                            end
                        end)
                    end
                end
            end
        end)
    end
end)

-- 邪天翁的踏水能力
AddComponentPostInit("locomotor", function(self, inst)
    local old_UpdateGroundSpeedMultiplier = self.UpdateGroundSpeedMultiplier
    function self:UpdateGroundSpeedMultiplier()
        old_UpdateGroundSpeedMultiplier(self)
        
        if self.inst:HasTag("vox") and self.inst:HasTag("mutebuff") then
            local is_on_water = self.inst:GetCurrentPlatform() == nil and self.inst:GetIsOnWater()
            if is_on_water then
                self.groundspeedmultiplier = math.max(self.groundspeedmultiplier, 1)
                
                -- 水上行走的视觉效果
                if not self.waterstepping and not self.inst.sg:HasStateTag("busy") then
                    local x, y, z = self.inst.Transform:GetWorldPosition()
                    local splash = SpawnPrefab("splash_water_drop")
                    if splash then
                        splash.Transform:SetPosition(x, 0, z)
                    end
                    self.waterstepping = self.inst:DoTaskInTime(0.3, function() self.waterstepping = nil end)
                end
            end
        end
    end
end)

-- 帝王蟹的吸血能力
AddComponentPostInit("combat", function(self, inst)
    local old_CalcDamage = self.CalcDamage
    function self:CalcDamage(target, weapon, multiplier)
        local damage = old_CalcDamage(self, target, weapon, multiplier)
        
        if self.inst:HasTag("vox") and self.inst:HasTag("crabkingbuff") and damage > 0 and self.inst.components.health then
            -- 造成20%伤害的吸血效果
            local lifesteal = damage * 0.2
            self.inst.components.health:DoDelta(lifesteal)
            
            -- 视觉效果
            local fx = SpawnPrefab("hitsplat")
            if fx then
                fx.Transform:SetPosition(self.inst.Transform:GetWorldPosition())
                fx.AnimState:SetAddColour(1, 0, 0, 0)
            end
        end
        
        return damage
    end
end)

-- 天体英雄的照明效果
AddPrefabPostInit("vox", function(inst)
    inst:ListenForEvent("celestialbuff", function(inst)
        if not inst.celestiallighttask then
            inst.celestiallighttask = inst:DoPeriodicTask(0.1, function()
                if inst:HasTag("celestialbuff") then
                    if not inst.celestiallight then
                        inst.celestiallight = SpawnPrefab("minerhatlight")
                        inst.celestiallight.Transform:SetPosition(inst.Transform:GetWorldPosition())
                        inst:AddChild(inst.celestiallight)
                    end
                else
                    if inst.celestiallight then
                        inst.celestiallight:Remove()
                        inst.celestiallight = nil
                    end
                end
            end)
        end
    end)
end)

-- 熊的砍树挖矿效果
AddComponentPostInit("worker", function(self, inst)
    local old_GetEffectiveness = self.GetEffectiveness
    function self:GetEffectiveness(action)
        local eff = old_GetEffectiveness(self, action)
        
        if self.inst:HasTag("vox") and self.inst:HasTag("bearbuff") and 
           (action == ACTIONS.CHOP or action == ACTIONS.MINE) then
            return eff * 2 -- 效率提高一倍
        end
        
        return eff
    end
end)

-- 蜂后的霸体效果
AddComponentPostInit("health", function(self, inst)
    local old_DoDelta = self.DoDelta
    function self:DoDelta(amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
        if amount < 0 and self.inst:HasTag("vox") and self.inst:HasTag("beequeen") then
            -- 减少受到的伤害
            amount = amount * 0.5
            
            -- 霸体效果：不会被击退
            if self.inst.components.locomotor then
                self.inst.components.locomotor:SetExternalSpeedMultiplier(self.inst, "beequeen_buff", 1)
            end
            
            -- 临时视觉效果
            self.inst.AnimState:SetMultColor(1.5, 1.5, 0.5, 1)
            self.inst:DoTaskInTime(0.3, function() self.inst.AnimState:SetMultColor(1, 1, 1, 1) end)
        end
        
        return old_DoDelta(self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    end
end)

-- 恶魔花相关修改
AddPrefabPostInit("flower_evil", function(inst)
    -- 采集恶魔花回复san
    if inst.components.pickable then
        local old_onpickedfn = inst.components.pickable.onpickedfn
        inst.components.pickable.onpickedfn = function(inst, picker)
            if picker and picker:HasTag("vox") and picker.components.sanity then
                picker.components.sanity:DoDelta(5)
            end
            
            if old_onpickedfn then
                old_onpickedfn(inst, picker)
            end
        end
    end
end)

-- 可以吃恶魔花
AddPrefabPostInit("petals_evil", function(inst)
    if not inst.components.edible then
        inst:AddComponent("edible")
        inst.components.edible.healthvalue = 1
        inst.components.edible.hungervalue = 0
        inst.components.edible.sanityvalue = -5 -- 普通人会降低san
    end
    
    local old_oneatfn = inst.components.edible.oneatfn
    inst.components.edible.oneatfn = function(inst, eater)
        if eater and eater:HasTag("vox") then
            if eater.components.sanity then
                eater.components.sanity:DoDelta(5) -- Vox吃了会增加san
            end
        end
        
        if old_oneatfn then
            old_oneatfn(inst, eater)
        end
    end
end)

-- 蜘蛛女王的蜘蛛人能力
AddPrefabPostInit("spider", function(inst)
    local old_SetTarget = nil
    if inst.components.combat then
        old_SetTarget = inst.components.combat.SetTarget
        inst.components.combat.SetTarget = function(self, target)
            if target and target:HasTag("vox") and target:HasTag("spiderwhisperer") then
                return
            end
            return old_SetTarget(self, target)
        end
    end
end)

AddPrefabPostInit("spider_warrior", function(inst)
    local old_SetTarget = nil
    if inst.components.combat then
        old_SetTarget = inst.components.combat.SetTarget
        inst.components.combat.SetTarget = function(self, target)
            if target and target:HasTag("vox") and target:HasTag("spiderwhisperer") then
                return
            end
            return old_SetTarget(self, target)
        end
    end
end)

AddPrefabPostInit("spiderqueen", function(inst)
    local old_SetTarget = nil
    if inst.components.combat then
        old_SetTarget = inst.components.combat.SetTarget
        inst.components.combat.SetTarget = function(self, target)
            if target and target:HasTag("vox") and target:HasTag("spiderwhisperer") then
                return
            end
            return old_SetTarget(self, target)
        end
    end
end)

-- 为onigiri添加放置动作
local PLACEONIGIRIS = Action({ priority=5, rmb=true, distance=1.5 })
PLACEONIGIRIS.id = "PLACEONIGIRIS"
PLACEONIGIRIS.str = "放置饭团"
PLACEONIGIRIS.fn = function(act)
    if act.doer and act.invobject and act.invobject.prefab == "onigiri" then
        if act.doer.components.health and act.doer.components.health:GetPercent() <= 0.3 then
            local pos = act.pos or act.doer:GetPosition()
            local onigiri = act.invobject
            
            if onigiri.components.inventoryitem then
                onigiri.components.inventoryitem:RemoveFromOwner()
                onigiri.Transform:SetPosition(pos.x, pos.y, pos.z)
                
                if onigiri.can_rage_again ~= false then
                    onigiri:PushEvent("startrage")
                    return true
                else
                    if act.doer.components.talker then
                        act.doer.components.talker:Say("饭团需要休息...")
                    end
                    return false
                end
            end
        else
            if act.doer.components.talker then
                act.doer.components.talker:Say("现在不需要饭团的保护...")
            end
            return false
        end
    end
    return false
end

AddAction(PLACEONIGIRIS)

-- 缓存设置
TUNING.VOX_STATS = {
    HEALTH = 200,
    HUNGER = 150,
    SANITY = 120,
    DEMONHUNGER = 150,
    DEMONHUNGER_DRAIN_MODIFIER = 0.75,
}

-- 添加生存指南描述
STRINGS.CHARACTERS.GENERIC.DESCRIBE.VOX = "他似乎不是来自这个世界的人。"