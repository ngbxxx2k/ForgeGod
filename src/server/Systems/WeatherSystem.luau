--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local WeatherConfig = require(shared:WaitForChild("Config"):WaitForChild("WeatherConfig"))
local WorldAttributes = require(shared:WaitForChild("Constants"):WaitForChild("WorldAttributes"))

local WeatherSchedule = require(script.Parent.Parent.Internal.WeatherSchedule)

local WeatherSystem = {}

local isInitialized = false

local function publishWeather()
	local weatherId, endsAt = WeatherSchedule.GetCurrent(os.time())
	if ReplicatedStorage:GetAttribute(WorldAttributes.WeatherEndsAt) ~= endsAt then
		ReplicatedStorage:SetAttribute(WorldAttributes.WeatherEndsAt, endsAt)
	end
	if ReplicatedStorage:GetAttribute(WorldAttributes.WeatherId) ~= weatherId then
		ReplicatedStorage:SetAttribute(WorldAttributes.WeatherId, weatherId)
	end
end

function WeatherSystem.Init()
	if isInitialized then
		return
	end
	isInitialized = true
	publishWeather()
	task.spawn(function()
		while isInitialized do
			task.wait(WeatherConfig.PollInterval)
			publishWeather()
		end
	end)
end

return WeatherSystem
