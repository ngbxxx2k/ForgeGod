--!strict

local AssetIds = require(script.Parent.AssetIds)
local WeatherConfig = require(script.Parent.Parent.Config.WeatherConfig)

local StatusEffectIcons = {
	TimerFormat = "%d:%02d",
	TimerHoursFormat = "%d:%02d:%02d",
	CountFormat = "%d",
}

StatusEffectIcons.Images = {} :: { [string]: string }

for weatherId, weather in WeatherConfig.ById do
	local image = AssetIds.Mutations[weather.MutationId]
	if image then
		StatusEffectIcons.Images[weatherId] = image
	end
end

return StatusEffectIcons
