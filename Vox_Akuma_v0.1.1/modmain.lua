-- 修复后的 modmain.lua - 专注于基础功能并包含领主太刀
local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS
local TUNING = GLOBAL.TUNING
local RECIPETABS = GLOBAL.RECIPETABS
local TECH = GLOBAL.TECH
local Ingredient = GLOBAL.Ingredient
local Recipe = GLOBAL.Recipe
local FOODTYPE = GLOBAL.FOODTYPE

-- 基础配置
TUNING.VOX_STATS = {
    HEALTH = 200,
    HUNGER = 150,
    SANITY = 120,
}

-- PrefabFiles
PrefabFiles = {
    "vox",
    "yamachaflower_robe", 
    "cydonia_letter",
    "onigiri",
    "lord_tachi",
}

-- 添加角色
AddMinimapAtlas("images/map_icons/vox.xml")
AddModCharacter("vox", "MALE")

-- 基础字符串
STRINGS.CHARACTER_TITLES.vox = "恶魔剑客"
STRINGS.CHARACTER_NAMES.vox = "Vox"
STRINGS.CHARACTER_DESCRIPTIONS.vox = "• 拥有恶魔之力\n• 讨厌海鲜食物\n• 杀Boss获得能力\n• 与猴子有特殊亲和力"
STRINGS.CHARACTER_QUOTES.vox = "\"来自New Cydonia的战士\""
STRINGS.CHARACTER_SURVIVABILITY.vox = "奇特"

-- 海鲜食物类型
FOODTYPE.SEAFOOD = "SEAFOOD"
local SEAFOOD_LIST = {"fish", "fish_cooked", "eel", "eel_cooked", "fishsticks", "froglegs", "froglegs_cooked"}
for _, food_name in ipairs(SEAFOOD_LIST) do
    AddPrefabPostInit(food_name, function(inst)
        if inst.components.edible then
            inst.components.edible.foodtype = FOODTYPE.SEAFOOD
        end
    end)
end

-- Boss能力系统
GLOBAL.BOSS_ABILITIES = {
    spiderqueen = {name = "蜘蛛女王之力", duration = 120},
    deerclops = {name = "巨鹿之力", duration = 120},
    bearger = {name = "熊獾之力", duration = 120},
    dragonfly = {name = "龙蝇之力", duration = 120},
}

-- 猴子感应功能
local function DoMonkeySense(player)
    if not player or not player:HasTag("vox") then return end
    
    local x, y, z = player.Transform:GetWorldPosition()
    local monkeys = TheSim:FindEntities(x, y, z, 50, {"monkey"})
    
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
            local distance_msg = ""
            if nearestDist < 10 then
                distance_msg = "它们就在我身边!"
            elseif nearestDist < 20 then
                distance_msg = "很近了."
            elseif nearestDist < 40 then
                distance_msg = "猴子离我有点远."
            else
                distance_msg = "太远了."
            end
            
            player.components.talker:Say(distance_msg)
        end
    else
        player.components.talker:Say("感应不到任何猴子.")
    end
end

-- 角色后处理
AddPlayerPostInit(function(inst)
    if inst.prefab == "vox" then
        -- 海鲜厌恶
        inst:ListenForEvent("oneat", function(inst, data)
            if data and data.food and data.food.components.edible then
                if data.food.components.edible.foodtype == FOODTYPE.SEAFOOD then
                    if inst.components.talker then
                        inst.components.talker:Say("呕! 我讨厌海鲜!")
                    end
                    if inst.components.health then
                        inst.components.health:DoDelta(-5)
                    end
                    if inst.components.sanity then
                        inst.components.sanity:DoDelta(-10)
                    end
                end
            end
        end)
        
        -- 击杀事件
        inst:ListenForEvent("killed", function(inst, data)
            if data and data.victim then
                local victim = data.victim
                
                -- 击杀邪恶生物回复san
                if victim:HasTag("monster") then
                    if inst.components.sanity then
                        inst.components.sanity:DoDelta(5)
                    end
                end
                
                -- Boss能力获取
                if victim:HasTag("epic") then
                    local boss_name = victim.prefab
                    local ability = GLOBAL.BOSS_ABILITIES[boss_name]
                    
                    if ability then
                        -- 移除旧能力
                        if inst.current_boss_ability then
                            inst:RemoveTag(inst.current_boss_ability.."_buff")
                            if inst.boss_ability_task then
                                inst.boss_ability_task:Cancel()
                            end
                        end
                        
                        -- 添加新能力
                        inst.current_boss_ability = boss_name
                        inst:AddTag(boss_name.."_buff")
                        
                        if inst.components.talker then
                            inst.components.talker:Say("获得了"..ability.name.."!")
                        end
                        
                        -- 应用能力效果
                        if boss_name == "deerclops" then
                            -- 免疫冰冻
                            if inst.components.freezable then
                                inst.components.freezable:SetResistance(999)
                            end
                        elseif boss_name == "bearger" then
                            -- 工作效率提升
                            inst.work_efficiency_mult = 2
                        elseif boss_name == "dragonfly" then
                            -- 火焰免疫
                            inst.fire_immunity = true
                        elseif boss_name == "spiderqueen" then
                            -- 蜘蛛友好
                            inst:AddTag("spiderwhisperer")
                        end
                        
                        -- 设置到期时间
                        inst.boss_ability_task = inst:DoTaskInTime(ability.duration, function()
                            inst:RemoveTag(boss_name.."_buff")
                            inst.current_boss_ability = nil
                            
                            -- 移除效果
                            if boss_name == "deerclops" and inst.components.freezable then
                                inst.components.freezable:SetResistance(1)
                            elseif boss_name == "bearger" then
                                inst.work_efficiency_mult = nil
                            elseif boss_name == "dragonfly" then
                                inst.fire_immunity = nil
                            elseif boss_name == "spiderqueen" then
                                inst:RemoveTag("spiderwhisperer")
                            end
                            
                            if inst.components.talker then
                                inst.components.talker:Say(ability.name.."消失了...")
                            end
                        end)
                    end
                end
            end
        end)
    end
end)

-- 延迟添加配方
AddGamePostInit(function()
    -- 山茶花羽织配方
    local yamachaflower_robe = Recipe("yamachaflower_robe",
        { Ingredient("silk", 4), Ingredient("rope", 1), Ingredient("log", 4) },
        RECIPETABS.DRESS, TECH.SCIENCE_ONE)
    yamachaflower_robe.atlas = "images/inventoryimages/yamachaflower_robe.xml"
    
    -- 领主太刀配方
    local lord_tachi = Recipe("lord_tachi",
        { Ingredient("redgem", 1), Ingredient("goldnugget", 4), Ingredient("nightmarefuel", 2) },
        RECIPETABS.WAR, TECH.SCIENCE_TWO)
    lord_tachi.atlas = "images/inventoryimages/lord_tachi_normal.xml"
end)

-- 客户端按键处理
AddSimPostInit(function()
    -- 猴子感应按键
    if GLOBAL.TheInput and GLOBAL.ThePlayer then
        GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_H, function()
            if GLOBAL.ThePlayer and GLOBAL.ThePlayer:HasTag("vox") then
                DoMonkeySense(GLOBAL.ThePlayer)
            end
        end)
    end
end)