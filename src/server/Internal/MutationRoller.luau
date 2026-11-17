--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local WeatherConfig = require(shared:WaitForChild("Config"):WaitForChild("WeatherConfig"))

local MutationTable =
	require(ServerStorage:WaitForChild("LootTables"):WaitForChild("MutationTable"))

local WeightedPick = require(script.Parent.WeightedPick)

export type ChanceMultipliers = {
	Base: number,
	Weather: number,
}

local MAX_CHANCE = 1

local MutationRoller = {}

local rng = Random.new()

local function rollChance(chance: number, multiplier: number): boolean
	return rng:NextNumber() < math.min(chance * multiplier, MAX_CHANCE)
end

function MutationRoller.Roll(weatherId: string?, multipliers: ChanceMultipliers): string?
	local weather = if weatherId then WeatherConfig.ById[weatherId] else nil
	if weather then
		if rollChance(MutationTable.WeatherChance, multipliers.Weather) then
			return weather.MutationId
		end
		return nil
	end
	if rollChance(MutationTable.BaseChance, multipliers.Base) then
		return WeightedPick.Pick(MutationTable.Weights, rng)
	end
	return nil
end

return MutationRoller
