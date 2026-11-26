--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeConfig = require(ReplicatedStorage.Shared.Config.ForgeConfig)

local FALLBACK_RARITY = "Mythic"

local WeaponMaxLevel = {}

function WeaponMaxLevel.Get(rarity: string?): number
	local byRarity = ForgeConfig.MaxLevelByRarity
	return (rarity and byRarity[rarity]) or byRarity[FALLBACK_RARITY]
end

function WeaponMaxLevel.IsReached(rarity: string?, level: number): boolean
	return level >= WeaponMaxLevel.Get(rarity)
end

return WeaponMaxLevel
