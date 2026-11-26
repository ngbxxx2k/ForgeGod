--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeaponCatalog = require(ReplicatedStorage.Shared.Constants.WeaponCatalog)
local WeaponWeightConfig = require(ReplicatedStorage.Shared.Config.WeaponWeightConfig)

local WeaponWeight = {}

local function roundTo(value: number, decimals: number): number
	local factor = 10 ^ decimals
	return math.floor(value * factor + 0.5) / factor
end

function WeaponWeight.NormalizeScale(scale: number?): number
	if type(scale) ~= "number" or scale ~= scale then
		return WeaponWeightConfig.MinScale
	end
	local clamped = math.clamp(scale, WeaponWeightConfig.MinScale, WeaponWeightConfig.MaxScale)
	return roundTo(clamped, WeaponWeightConfig.ScaleDecimals)
end

function WeaponWeight.FindFamily(weaponTypeId: string): string?
	local weaponType = WeaponCatalog.Resolve(weaponTypeId)
	return if weaponType then weaponType.Family else nil
end

function WeaponWeight.Get(weaponTypeId: string, scale: number?): number
	local family = WeaponWeight.FindFamily(weaponTypeId)
	local base = family and WeaponWeightConfig.BaseWeights[family] or WeaponWeightConfig.DefaultBaseWeight
	local weight = base * WeaponWeight.NormalizeScale(scale)
	return roundTo(weight, WeaponWeightConfig.WeightDecimals)
end

function WeaponWeight.Format(weight: number): string
	return string.format(WeaponWeightConfig.WeightFormat, weight)
end

return WeaponWeight
