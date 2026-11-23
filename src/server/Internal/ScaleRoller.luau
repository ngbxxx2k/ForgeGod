--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local WeaponWeight = require(shared:WaitForChild("Utils"):WaitForChild("WeaponWeight"))

local WeaponScaleTable = require(ServerStorage:WaitForChild("LootTables"):WaitForChild("WeaponScaleTable"))
local WeightedPick = require(script.Parent.WeightedPick)

local ScaleRoller = {}

local function buildWeights(): { [string]: number }
	local weights = {}
	for bandId, band in WeaponScaleTable.Bands do
		weights[bandId] = band.Weight
	end
	return weights
end

local bandWeights = buildWeights()

function ScaleRoller.Roll(rng: Random): number
	local bandId = WeightedPick.Pick(bandWeights, rng)
	local band = bandId and WeaponScaleTable.Bands[bandId]
	if band == nil then
		return WeaponWeight.NormalizeScale(nil)
	end
	return WeaponWeight.NormalizeScale(rng:NextNumber(band.Min, band.Max))
end

return ScaleRoller
