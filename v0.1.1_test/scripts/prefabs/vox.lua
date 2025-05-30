local MakePlayerCharacter = require("prefabs/player_common")

local assets = {
    Asset("ANIM", "anim/wilson.zip"),
    Asset("ANIM", "anim/ghost_wilson_build.zip"),
}

local prefabs = {}

local function common_postinit(inst)
    inst:AddTag("vox")
    print("Vox character created - common_postinit")
end

local function master_postinit(inst)
    print("Vox character created - master_postinit")
    
    -- 设置属性
    inst.components.health:SetMaxHealth(200)
    inst.components.hunger:SetMax(150)
    inst.components.sanity:SetMax(120)
    
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
    
    -- 给予初始装备
    inst:DoTaskInTime(0.1, function()
        if inst.components.inventory then
            print("Giving starting items to Vox...")
            
            -- 山茶花羽织
            local robe = SpawnPrefab("yamachaflower_robe")
            if robe then
                inst.components.inventory:GiveItem(robe)
                print("Gave yamachaflower_robe")
            else
                print("Failed to spawn yamachaflower_robe")
            end
            
            -- 信件
            local letter = SpawnPrefab("cydonia_letter")
            if letter then
                inst.components.inventory:GiveItem(letter)
                print("Gave cydonia_letter")
            else
                print("Failed to spawn cydonia_letter")
            end
            
            -- 饭团
            local onigiri = SpawnPrefab("onigiri")
            if onigiri then
                inst.components.inventory:GiveItem(onigiri)
                print("Gave onigiri")
            else
                print("Failed to spawn onigiri")
            end
            
            -- 测试消息
            if inst.components.talker then
                inst.components.talker:Say("装备已装载完毕！")
            end
        end
    end)
end

return MakePlayerCharacter("vox", prefabs, assets, common_postinit, master_postinit)