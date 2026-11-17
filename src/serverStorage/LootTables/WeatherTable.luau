--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedConfig = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local WeatherConfig = require(sharedConfig:WaitForChild("WeatherConfig"))

local WeatherTable = {}

WeatherTable.SeedOffset = 7919

WeatherTable.WeightByRarity = {
	Common = 40,
	Uncommon = 20,
	Rare = 10,
	VeryRare = 4,
} :: { [string]: number }

WeatherTable.Weights = {} :: { [string]: number }

for _, weather in WeatherConfig.Weathers do
	local weight = WeatherTable.WeightByRarity[weather.Rarity]
	if weight == nil then
		warn("[WeatherTable] No weight for rarity", weather.Rarity, "of", weather.Id)
	else
		WeatherTable.Weights[weather.Id] = weight
	end
end

return WeatherTable
