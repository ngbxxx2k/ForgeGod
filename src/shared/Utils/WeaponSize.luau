--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeAnimationConfig = require(ReplicatedStorage.Shared.Config.ForgeAnimationConfig)
local WeaponWeight = require(ReplicatedStorage.Shared.Utils.WeaponWeight)

local WeaponSize = {}

function WeaponSize.GetBaseLength(weaponTypeId: string): number
	local visual = ForgeAnimationConfig.WeaponVisuals[weaponTypeId] or ForgeAnimationConfig.DefaultVisual
	return visual.Length
end

function WeaponSize.GetLength(weaponTypeId: string, scale: number?): number
	return WeaponSize.GetBaseLength(weaponTypeId) * WeaponWeight.NormalizeScale(scale)
end

return WeaponSize
