-- onigiri.lua - 主要的饭团预制体文件

local assets =
{
    Asset("ANIM", "anim/onigiri.zip"),
    Asset("ATLAS", "images/inventoryimages/onigiri.xml"),
    Asset("IMAGE", "images/inventoryimages/onigiri.tex"),
}

local prefabs =
{
    "onigiri_inactive",
    "onigiri_active", 
    "onigiri_big",
}

local function fn()
    -- 默认返回非激活状态的饭团
    return SpawnPrefab("onigiri_inactive")
end

return Prefab("onigiri", fn, assets, prefabs)