--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedConfig = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local MutationConfig = require(sharedConfig:WaitForChild("MutationConfig"))

local MutationTable = {}

MutationTable.BaseChance = 0.01
MutationTable.WeatherChance = 0.05

MutationTable.WeightByRarity = {
	Common = 40,
	Uncommon = 20,
	Rare = 8,
} :: { [string]: number }

MutationTable.Weights = {} :: { [string]: number }

for _, mutation in MutationConfig.Mutations do
	local weight = MutationTable.WeightByRarity[mutation.Rarity]
	if weight == nil then
		warn("[MutationTable] No weight for rarity", mutation.Rarity, "of", mutation.Id)
	else
		MutationTable.Weights[mutation.Id] = weight
	end
end

return MutationTable
