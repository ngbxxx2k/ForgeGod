--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local WeatherConfig = require(shared:WaitForChild("Config"):WaitForChild("WeatherConfig"))

local WeatherTable = require(ServerStorage:WaitForChild("LootTables"):WaitForChild("WeatherTable"))

local WeightedPick = require(script.Parent.WeightedPick)

local WeatherSchedule = {}

local function getCycleIndex(now: number): number
	return math.floor(now / WeatherConfig.CycleInterval)
end

function WeatherSchedule.GetWeatherForCycle(cycleIndex: number): string?
	local rng = Random.new(cycleIndex + WeatherTable.SeedOffset)
	return WeightedPick.Pick(WeatherTable.Weights, rng)
end

function WeatherSchedule.GetCurrent(now: number): (string?, number?)
	local cycleIndex = getCycleIndex(now)
	local endsAt = cycleIndex * WeatherConfig.CycleInterval + WeatherConfig.Duration
	if now >= endsAt then
		return nil, nil
	end
	return WeatherSchedule.GetWeatherForCycle(cycleIndex), endsAt
end

return WeatherSchedule
