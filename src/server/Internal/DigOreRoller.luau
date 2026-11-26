--!strict

local ServerStorage = game:GetService("ServerStorage")

local DigOreTable = require(ServerStorage:WaitForChild("LootTables"):WaitForChild("DigOreTable"))
local WeightedPick = require(script.Parent.WeightedPick)

local FALLBACK_ORE = "Copper"

local DigOreRoller = {}

local rng = Random.new()

local function buildWeights(luck: number): { [string]: number }
	local weights = {}
	for oreId, entry in DigOreTable.Ores do
		local exponent = DigOreTable.LuckExponent[entry.Rarity] or 0
		weights[oreId] = entry.Weight * (math.max(luck, 1) ^ exponent)
	end
	return weights
end

function DigOreRoller.Roll(luck: number): string
	return WeightedPick.Pick(buildWeights(luck), rng) or FALLBACK_ORE
end

function DigOreRoller.GetRarity(oreId: string): string
	local entry = DigOreTable.Ores[oreId]
	return if entry then entry.Rarity else "Common"
end

return DigOreRoller
