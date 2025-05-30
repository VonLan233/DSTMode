-- 修改 modmain.lua
local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS
local FOODTYPE = GLOBAL.FOODTYPE
local TUNING = GLOBAL.TUNING
local RECIPETABS = GLOBAL.RECIPETABS
local TECH = GLOBAL.TECH
local Ingredient = GLOBAL.Ingredient
local Recipe = GLOBAL.Recipe

-- 基础配置
TUNING.VOX_STATS = {
    HEALTH = 200,
    HUNGER = 150,
    SANITY = 120,
}

-- 添加装备预制体
PrefabFiles = {
    "vox",
    "yamachaflower_robe",    -- 山茶花羽织
    "cydonia_letter",        -- 信件
    "onigiri",              -- 饭团
    "lord_tachi",         -- 恶魔剑
}

-- 添加角色
AddModCharacter("vox", "MALE")

-- 基础字符串
STRINGS.CHARACTER_TITLES.vox = "恶魔剑客"
STRINGS.CHARACTER_NAMES.vox = "Vox"
STRINGS.CHARACTER_DESCRIPTIONS.vox = "• 拥有恶魔之力\n• 200血量 150饥饿 120san\n• 讨厌海鲜食物\n• 自带专属装备"
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

-- 物品名称
STRINGS.NAMES.YAMACHAFLOWER_ROBE = "山茶花羽织"
STRINGS.NAMES.CYDONIA_LETTER = "来自新月球的信件"
STRINGS.NAMES.ONIGIRI = "饭团伙伴"

-- 物品描述
STRINGS.CHARACTERS.GENERIC.DESCRIBE.YAMACHAFLOWER_ROBE = "一件精美的羽织，提供防护。"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.CYDONIA_LETTER = "一封来自远方的信件。"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.ONIGIRI = "可爱的饭团伙伴。"

-- Vox的专属描述
STRINGS.CHARACTERS.VOX = STRINGS.CHARACTERS.VOX or {}
STRINGS.CHARACTERS.VOX.DESCRIBE = STRINGS.CHARACTERS.VOX.DESCRIBE or {}
STRINGS.CHARACTERS.VOX.DESCRIBE.YAMACHAFLOWER_ROBE = "我的专属羽织，嘿嘿。"
STRINGS.CHARACTERS.VOX.DESCRIBE.CYDONIA_LETTER = "Kindred们写给我的信。"
STRINGS.CHARACTERS.VOX.DESCRIBE.ONIGIRI = "老朋友，又想偷我的酒吗？"