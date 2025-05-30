local MakePlayerCharacter = require "prefabs/player_common"

local assets = {
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
    
    -- 待添加角色图片资源
    Asset("ANIM", "anim/vox.zip"),
    Asset("ANIM", "anim/ghost_vox_build.zip"),
    -- 添加形态相关的动画
    Asset("ANIM", "anim/vox_demon.zip"),        -- 恶魔形态
}

-- 初始物品
local start_inv = {
    "yamchaflower_robe",
    "onigiri",
    "cydonia_letter",
}

-- 缩放比例
local VOX_SCALE = 1.0

-- 角色专属音效
local VOX_SOUNDS = 
{
    ACTIONFAIL = "dontstarve/characters/wortox/emote_fistshake",
    BATTLECRY = "dontstarve/characters/wortox/battlecry",
    HURT = "dontstarve/characters/wortox/hurt",
    DEATH = "dontstarve/characters/wortox/death",
    TALK = "dontstarve/characters/wortox/voice",
    ATTACK = "dontstarve/creatures/krampus/attack", -- 先用恶魔音效顶替
    BUFF = "dontstarve/creatures/together/stalker/charge", 
    DEBUFF = "dontstarve/creatures/together/stalker/transform",
    -- 形态切换音效
    TRANSFORM = "dontstarve/characters/woodie/transform_weremoose",
    REVERT = "dontstarve/characters/woodie/revert",
}

-- 形态定义
local VOX_FORMS = {
    HUMAN = 0,
    DEMON = 1,
}

local VOX_FORM_NAMES = {
    "human",
    "demon",
}

-- 形态颜色
local VOX_FORM_COLORS = {
    [VOX_FORMS.HUMAN] = {r=1, g=1, b=1, a=1},
    [VOX_FORMS.DEMON] = {r=1.2, g=0.5, b=0.5, a=1},
}

-- 形态能力设置
local VOX_FORM_STATS = {
    [VOX_FORMS.HUMAN] = {
        speed_mult = 1.0,
        damage_mult = 1.0,
        absorb = 0,
        health_regen = 0,
        sanity_drain = 0,
    },
    [VOX_FORMS.DEMON] = {
        speed_mult = 1.5,
        damage_mult = 2.0,
        absorb = 0.25,
        health_regen = 1,
        sanity_drain = 2,
    },
}

-- 前置声明函数
local OnVoxFormDirty
local OnDemonEnergyDirty
local OnPlayerActivated
local OnPlayerDeactivated
local SetVoxForm
local SpawnDemonTransformFx
local OnDemonEnergyDelta
local OnHitOther
local OnAttacked
local TransformToDemon
local RevertToHuman
local OnBecameHuman
local OnBecameDemon

-- 为不同形态创建不同的动作
local function DemonActionString(inst, action)
    return (action.action == ACTIONS.ATTACK and STRINGS.ACTIONS.CLAW) 
        or (action.action == ACTIONS.USE_WEREFORM_SKILL and STRINGS.ACTIONS.USE_WEREFORM_SKILL.DEMON)
        or nil
end

-- 设置形态函数 (客户端)
SetVoxForm = function(inst, form)
    -- 更新视觉效果
    local color = VOX_FORM_COLORS[form]
    if color then
        inst.AnimState:SetMultColor(color.r, color.g, color.b, color.a)
    end
    
    -- 更新形态特定动画
    if form == VOX_FORMS.HUMAN then
        inst.AnimState:SetBuild("vox")
        -- 停止恶魔形态音效
        inst.SoundEmitter:KillSound("demoneffect")
    elseif form == VOX_FORMS.DEMON then
        inst.AnimState:SetBuild("vox_demon")
        -- 播放恶魔化特效
        SpawnDemonTransformFx(inst)
        -- 播放持续的恶魔形态音效
        inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/breathing_LP", "demoneffect")
    end
    
    -- 播放转换音效
    if form == VOX_FORMS.DEMON then
        inst.SoundEmitter:PlaySound(VOX_SOUNDS.TRANSFORM)
    else
        inst.SoundEmitter:PlaySound(VOX_SOUNDS.REVERT)
    end
end

-- 恶魔化特效
SpawnDemonTransformFx = function(inst)
    local fx = SpawnPrefab("statue_transition_2") -- 使用现有特效
    if fx then
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx:SetMaterial("shadow")
    end
end

-- 客户端形态变化处理
OnVoxFormDirty = function(inst)
    local form = inst.voxform:value()
    
    -- 更新标签
    if form == VOX_FORMS.DEMON then
        if not inst:HasTag("voxdemon") then
            inst:AddTag("voxdemon")
        end
    else
        if inst:HasTag("voxdemon") then
            inst:RemoveTag("voxdemon")
        end
    end
    
    -- 更新动作处理函数
    if form == VOX_FORMS.DEMON then
        inst.ActionStringOverride = DemonActionString
    else
        inst.ActionStringOverride = nil
    end
    
    -- 设置形态
    SetVoxForm(inst, form)
end

-- 客户端恶魔能量变化处理
OnDemonEnergyDirty = function(inst)
    -- 这个函数会与外部的恶魔饥饿UI组件交互
    -- 通知外部UI更新恶魔能量值
    if inst.components.demonhunger ~= nil then
        inst.components.demonhunger:SetPercent(inst.demon_energy:value() / 100)
    end
    
    -- 可以在此处添加能量条UI更新代码
    -- 如果存在UI组件的话
end

-- 客户端特效处理
OnPlayerActivated = function(inst)
    -- 初始化形态
    OnVoxFormDirty(inst)
    
    -- 初始化恶魔能量UI
    OnDemonEnergyDirty(inst)
    
    -- 根据当前形态设置角色外观
    SetVoxForm(inst, inst.voxform:value())
end

OnPlayerDeactivated = function(inst)
    inst:RemoveEventCallback("playeractivated", OnPlayerActivated)
    inst:RemoveEventCallback("playerdeactivated", OnPlayerDeactivated)
    inst:RemoveEventCallback("voxformdirty", OnVoxFormDirty)
    inst:RemoveEventCallback("demonenergydirty", OnDemonEnergyDirty)
    
    -- 确保所有音效都停止
    if inst.SoundEmitter ~= nil then
        inst.SoundEmitter:KillSound("demoneffect")
    end
end

-- 恶魔能量处理
OnDemonEnergyDelta = function(inst, data)
    if data == nil or data.delta == nil then return end
    
    local old_value = inst.demon_energy:value()
    local new_value = math.clamp(old_value + data.delta, 0, 100)
    
    if new_value ~= old_value then
        inst.demon_energy:set(new_value)
        
        -- 当能量满时自动变身
        if new_value >= inst.transform_threshold and inst.voxform:value() == VOX_FORMS.HUMAN then
            inst:PushEvent("transformtodemon")
        -- 当能量耗尽时自动变回人类
        elseif new_value <= inst.revert_threshold and inst.voxform:value() == VOX_FORMS.DEMON then
            inst:PushEvent("reverttohuman")
        end
    end
end

-- 战斗相关处理
OnHitOther = function(inst, data)
    if data and data.target then
        -- 增加恶魔能量
        if inst.voxform:value() == VOX_FORMS.HUMAN then
            -- 普通攻击增加恶魔能量
            inst:PushEvent("demonenergydelta", {delta = 5})
        end
        
        -- 恶魔形态击杀恢复
        if inst.voxform:value() == VOX_FORMS.DEMON and 
           data.target.components.health and 
           data.target.components.health:IsDead() then
            -- 杀死敌人恢复生命
            inst.components.health:DoDelta(5, true)
            
            -- 杀死boss额外恢复
            if data.target:HasTag("epic") or data.target:HasTag("monster") then
                inst.components.health:DoDelta(15, true)
                inst.components.sanity:DoDelta(20)
                
                -- 记录击杀的boss
                if not inst.killed_bosses[data.target.prefab] then
                    inst.killed_bosses[data.target.prefab] = 1
                else
                    inst.killed_bosses[data.target.prefab] = inst.killed_bosses[data.target.prefab] + 1
                end
                
                -- boss击杀经验
                inst:PushEvent("gainexperience", {amount = 50})
            else
                -- 普通怪物击杀经验
                inst:PushEvent("gainexperience", {amount = 5})
            end
        end
    end
end

-- 被攻击处理
OnAttacked = function(inst, data)
    if data and data.attacker then
        -- 恶魔形态受击反伤
        if inst.voxform:value() == VOX_FORMS.DEMON and data.attacker.components.health then
            local reflect_damage = math.floor(data.damage * 0.25)
            if reflect_damage > 0 then
                data.attacker.components.health:DoDelta(-reflect_damage)
                
                -- 反伤特效
                local fx = SpawnPrefab("shadow_despawn")
                if fx then
                    fx.Transform:SetPosition(data.attacker.Transform:GetWorldPosition())
                end
            end
        end
        
        -- 人类形态受击积累能量
        if inst.voxform:value() == VOX_FORMS.HUMAN then
            inst:PushEvent("demonenergydelta", {delta = math.floor(data.damage * 0.5)})
        end
    end
end

-- 人类形态回调
OnBecameHuman = function(inst)
    -- 这里可以添加任何人类形态特有的初始化
    
    -- 恢复正常移动速度
    inst.components.locomotor.walkspeed = TUNING.WILSON_WALK_SPEED * 1.05
    inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED * 1.05
    
    -- 确保所有状态都重置
    inst.components.health.absorb = 0
    inst.components.combat.damagemultiplier = 1.0
    
    -- 重设行走动画
    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("vox")
end

-- 恶魔形态回调
OnBecameDemon = function(inst)
    -- 这里可以添加恶魔形态特有的初始化
    
    -- 设置恶魔形态移动速度
    inst.components.locomotor.walkspeed = TUNING.WILSON_WALK_SPEED * VOX_FORM_STATS[VOX_FORMS.DEMON].speed_mult
    inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED * VOX_FORM_STATS[VOX_FORMS.DEMON].speed_mult
    
    -- 设置血条样式为恶魔模式
    -- 如果有特殊的血条系统，可以在这里切换
end

-- 变身为恶魔形态
TransformToDemon = function(inst)
    if inst.voxform:value() ~= VOX_FORMS.DEMON and 
       not inst:HasTag("playerghost") and
       not inst.sg:HasStateTag("nomorph") and
       inst.demon_energy:value() >= inst.transform_threshold then
        
        -- 切换到恶魔状态图
        inst.sg:GoToState("transform_demon")
        
        -- 设置标签
        inst:AddTag("voxdemon")
        
        -- 设置形态
        inst.voxform:set(VOX_FORMS.DEMON)
        
        -- 关闭背包界面
        if inst.components.inventory then
            inst.components.inventory:Close()
        end
        
        -- 设置恶魔状态属性
        inst.components.locomotor:SetExternalSpeedMultiplier(inst, "demonform", VOX_FORM_STATS[VOX_FORMS.DEMON].speed_mult)
        inst.components.combat.damagemultiplier = VOX_FORM_STATS[VOX_FORMS.DEMON].damage_mult
        inst.components.health.absorb = VOX_FORM_STATS[VOX_FORMS.DEMON].absorb
        
        -- 启动san值消耗和生命恢复任务
        if inst.demon_task then
            inst.demon_task:Cancel()
        end
        inst.demon_task = inst:DoPeriodicTask(1, function()
            -- 消耗恶魔能量
            inst:PushEvent("demonenergydelta", {delta = -1})
            
            -- 消耗san值
            inst.components.sanity:DoDelta(-VOX_FORM_STATS[VOX_FORMS.DEMON].sanity_drain)
            
            -- 恢复生命
            if VOX_FORM_STATS[VOX_FORMS.DEMON].health_regen > 0 then
                inst.components.health:DoDelta(VOX_FORM_STATS[VOX_FORMS.DEMON].health_regen, true)
            end
        end)
        
        -- 修改动作字符串覆盖
        inst.ActionStringOverride = DemonActionString
        
        -- 角色外观变化提示
        inst.components.talker:Say("恶魔之力爆发!")
        
        -- 触发形态变化回调
        OnBecameDemon(inst)
    end
end

-- 恢复人类形态
RevertToHuman = function(inst)
    if inst.voxform:value() ~= VOX_FORMS.HUMAN and 
       not inst:HasTag("playerghost") then
        
        -- 切换到变回人类的状态图
        inst.sg:GoToState("revert_human")
        
        -- 移除标签
        inst:RemoveTag("voxdemon")
        
        -- 设置形态
        inst.voxform:set(VOX_FORMS.HUMAN)
        
        -- 移除所有形态特殊效果
        inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "demonform")
        inst.components.combat.damagemultiplier = 1.0
        inst.components.health.absorb = 0
        
        -- 取消所有形态任务
        if inst.demon_task then
            inst.demon_task:Cancel()
            inst.demon_task = nil
        end
        
        -- 清除动作字符串覆盖
        inst.ActionStringOverride = nil
        
        -- 角色外观变化提示
        inst.components.talker:Say("恶魔之力消退...")
        
        -- 触发形态变化回调
        OnBecameHuman(inst)
    end
end

-- 这个接口函数用于外部的恶魔饥饿UI组件
local function GetDemonHungerPercent(inst)
    return inst.demon_energy:value() / 100
end

-- 主要函数
local function common_postinit(inst)
    -- 角色标签
    inst:AddTag("vox")
    inst:AddTag("demonicswordsman")
    inst:AddTag("soulstealer")
    
    -- 调整角色大小
    inst.Transform:SetScale(VOX_SCALE, VOX_SCALE, VOX_SCALE)
    
    -- 定义角色音效
    inst.soundsname = "wortox" -- 先用伍图斯音效顶替，后续更换
    
    -- 定义说话音效
    inst.talker_path_override = "dontstarve/characters/wortox/voice"
    
    -- 添加角色夜视能力
    inst.components.playervision:ForceNightVision(true)
    inst.components.playervision:SetCustomCCTable({day = {}, dusk = {}, night = {}})
    
    -- 添加网络同步变量
    inst.voxform = net_tinybyte(inst.GUID, "vox.voxform", "voxformdirty")
    inst.demon_energy = net_byte(inst.GUID, "vox.demon_energy", "demonenergydirty")
    
    -- 客户端处理形态改变
    inst:ListenForEvent("voxformdirty", function()
        if inst.HUD ~= nil and not inst:HasTag("playerghost") then
            OnVoxFormDirty(inst)
        end
    end)
    
    -- 客户端处理恶魔能量变化
    inst:ListenForEvent("demonenergydirty", function()
        if inst.HUD ~= nil then
            OnDemonEnergyDirty(inst)
        end
    end)
    
    -- 添加HUD元素初始化事件
    inst:ListenForEvent("playeractivated", OnPlayerActivated)
    inst:ListenForEvent("playerdeactivated", OnPlayerDeactivated)
end

-- 主世界初始化函数
local function master_postinit(inst)
    -- 设置角色属性
    inst.components.health:SetMaxHealth(TUNING.VOX_STATS.HEALTH)
    inst.components.hunger:SetMax(TUNING.VOX_STATS.HUNGER)
    inst.components.sanity:SetMax(TUNING.VOX_STATS.SANITY)
    
    -- 海鲜过敏
    inst:AddTag("hates_seafood")
    
    -- 设置伤害倍率
    inst.components.combat.damagemultiplier = 1.0
    
    -- 设置攻击范围
    inst.components.combat:SetRange(2)
    
    -- 添加形态系统
    inst.voxform:set(VOX_FORMS.HUMAN)
    inst.demon_energy:set(0)
    
    -- 恶魔形态任务
    inst.demon_task = nil
    
    -- 形态切换函数
    inst.TransformToDemon = TransformToDemon
    inst.RevertToHuman = RevertToHuman
    
    -- 设置状态转换所需能量阈值
    inst.transform_threshold = 100  -- 变身所需能量值
    inst.revert_threshold = 0       -- 低于此值时变回人类
    
    -- 初始化角色等级系统
    inst.level = 0
    inst.experience = 0
    inst.next_level_exp = 100
    
    -- 角色血条样式
    inst.components.health.currenthealth = TUNING.VOX_STATS.HEALTH
    inst.components.health.maxhealth = TUNING.VOX_STATS.HEALTH
    
    -- 添加恶魔形态相关事件处理
    inst:ListenForEvent("demonenergydelta", OnDemonEnergyDelta)
    inst:ListenForEvent("transformtodemon", function() inst:TransformToDemon() end)
    inst:ListenForEvent("reverttohuman", function() inst:RevertToHuman() end)
    
    -- 设置形态转换触发器
    inst:ListenForEvent("onhitother", OnHitOther)
    inst:ListenForEvent("attacked", OnAttacked)
    
    -- 添加角色特有能力
    inst.soulsteal = true -- 能够获得灵魂
    inst.demonrage = false -- 暴走状态标记
    
    -- 初始化Boss击杀记录
    inst.killed_bosses = {}
    
    -- 当角色受到过多伤害时的警告
    inst:ListenForEvent("healthdelta", function(inst, data)
        if inst.components.health:GetPercent() <= 0.3 and not inst.lowhealth_warned then
            inst.components.talker:Say("我需要饭团的力量...")
            inst.lowhealth_warned = true
            
            -- 10秒后重置警告标记
            inst:DoTaskInTime(10, function() 
                inst.lowhealth_warned = false 
            end)
        end
    end)
    
    -- 当san值过低时的特殊效果
    inst:ListenForEvent("sanitydelta", function(inst, data)
        if inst.components.sanity:GetPercent() <= 0.3 and not inst.lowsanity_effect then
            inst.lowsanity_effect = true
            
            -- 低san值时的特殊效果，比如恶魔化外观
            if inst.voxform:value() == VOX_FORMS.HUMAN then
                inst.AnimState:SetMultColor(0.9, 0.7, 0.7, 1)
            end
            
            -- 自动激活恶魔形态
            if inst.voxform:value() == VOX_FORMS.HUMAN and 
               inst.demon_energy:value() >= 50 then
                inst:PushEvent("transformtodemon")
            end
            
        elseif inst.components.sanity:GetPercent() > 0.3 and inst.lowsanity_effect then
            inst.lowsanity_effect = false
            
            -- 恢复正常外观
            if inst.voxform:value() == VOX_FORMS.HUMAN then
                inst.AnimState:SetMultColor(1, 1, 1, 1)
            end
        end
    end)
    
    -- 添加食物限制
    inst.components.eater:SetOnEatFn(function(inst, food)
        if food and food.components.edible then
            -- 如果吃了海鲜食物
            if food.components.edible.foodtype == FOODTYPE.SEAFOOD then
                inst.components.talker:Say("呕! 我讨厌海鲜!")
                inst.components.health:DoDelta(-5)
                inst.components.sanity:DoDelta(-10)
                
                -- 呕吐效果
                local puke = SpawnPrefab("vomit")
                if puke then
                    puke.Transform:SetPosition(inst.Transform:GetWorldPosition())
                end
            end
            
            -- 如果吃了灵魂，增加恶魔能量
            if food.prefab == "wortox_soul" then
                inst:PushEvent("demonenergydelta", {delta = 15})
                inst.components.sanity:DoDelta(-5)
            end
            
            -- 如果吃了噩梦燃料，大幅增加恶魔能量
            if food.prefab == "nightmarefuel" then
                inst:PushEvent("demonenergydelta", {delta = 25})
                inst.components.sanity:DoDelta(15)
                inst.components.health:DoDelta(10)
            end
        end
    end)
    
    -- 添加获取恶魔能量百分比的函数
    inst.GetDemonHungerPercent = GetDemonHungerPercent
end

-- 创建Vox角色实例
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddLight()
    inst.entity:AddNetwork()
    
    inst.Transform:SetFourFaced()
    
    MakeCharacterPhysics(inst, 75, .5)
    
    inst.Light:SetIntensity(0)
    inst.Light:SetRadius(2)
    inst.Light:SetFalloff(0.7)
    inst.Light:SetColour(180/255, 195/255, 225/255)
    inst.Light:Enable(false)
    
    inst.DynamicShadow:SetSize(1.3, .6)
    
    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("vox")
    inst.AnimState:PlayAnimation("idle")
    
    -- 设置血条和精神值颜色
    inst.AnimState:OverrideSymbol("swap_body", "vox", "swap_body")
    
    -- 在这里设置其他需要覆盖的符号
    
    inst:AddComponent("talker")
    inst.components.talker:StopUIAnimations()
    
    inst:AddTag("scarytoprey") -- 吓跑小动物
    inst:AddTag("vox")
    inst:AddTag("demonicswordsman")
    inst:AddTag("soulstealer")
    
    -- 通用初始化
    common_postinit(inst)
    
    inst.entity:SetPristine()
    
    if not TheWorld.ismastersim then
        return inst
    end
    
    -- 主服务器初始化
    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.WILSON_WALK_SPEED * 1.05 -- 基础速度稍快
    inst.components.locomotor.runspeed = TUNING.WILSON_RUN_SPEED * 1.05
    
    inst:AddComponent("inventory")
    inst:AddComponent("inspectable")
    
    inst:AddComponent("health")
    inst:AddComponent("hunger")
    inst:AddComponent("sanity")
    
    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "torso"
    
    inst:AddComponent("temperature")
    
    inst:AddComponent("eater")
    
    inst:AddComponent("builder")
    
    inst:AddComponent("moisture")
    
    inst:AddComponent("freezable")
    
    inst:AddComponent("grogginess")
    inst.components.grogginess:SetResistance(3) -- 抵抗催眠
    
    -- 添加道具收集者
    inst:AddComponent("itemaffinity")
    
    -- 主初始化完成
    master_postinit(inst)
    
    inst.OnLoad = function(inst, data)
        if data then
            -- 加载等级数据
            if data.level then
                inst.level = data.level
            end
            
            if data.experience then
                inst.experience = data.experience
            end
            
            if data.next_level_exp then
                inst.next_level_exp = data.next_level_exp
            end
            
            -- 加载恶魔能量
            if data.demon_energy then
                inst.demon_energy:set(data.demon_energy)
            end
            
            -- 加载击杀过的boss列表
            if data.killed_bosses then
                inst.killed_bosses = data.killed_bosses
            end
            
            -- 如果在恶魔形态下保存，恢复恶魔形态
            if data.voxform and data.voxform == VOX_FORMS.DEMON then
                inst:PushEvent("transformtodemon")
            end
        end
    end
    
    inst.OnSave = function(inst, data)
        data.level = inst.level
        data.experience = inst.experience
        data.next_level_exp = inst.next_level_exp
        data.demon_energy = inst.demon_energy:value()
        data.killed_bosses = inst.killed_bosses
        data.voxform = inst.voxform:value()
    end
    
    inst.OnNewSpawn = function(inst)
        -- 新角色生成时给予初始物品
        inst.components.inventory:GiveItem(SpawnPrefab("yamchaflower_robe"))
        inst.components.inventory:GiveItem(SpawnPrefab("onigiri"))
        inst.components.inventory:GiveItem(SpawnPrefab("cydonia_letter"))
    end
    
    return inst
end

return MakePlayerCharacter("vox", fn, start_inv, assets)