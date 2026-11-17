--!strict

local MutationConfig = require(script.Parent.MutationConfig)

export type WeatherDefinition = {
	Id: string,
	MutationId: string,
	Rarity: string,
}

local WeatherConfig = {
	CycleInterval = 1800,
	Duration = 300,
	PollInterval = 1,
}

WeatherConfig.Weathers = {
	{ Id = "Heatwave", MutationId = "Molten", Rarity = "Common" },
	{ Id = "HeavyRain", MutationId = "Aqua", Rarity = "Common" },
	{ Id = "Thunderstorm", MutationId = "Thunder", Rarity = "Uncommon" },
	{ Id = "Aurora", MutationId = "Aurora", Rarity = "Rare" },
	{ Id = "Radiation", MutationId = "Radioactive", Rarity = "Rare" },
	{ Id = "LunarEclipse", MutationId = "Shadow", Rarity = "VeryRare" },
	{ Id = "PlasmaStorm", MutationId = "Plasma", Rarity = "VeryRare" },
} :: { WeatherDefinition }

WeatherConfig.ById = {} :: { [string]: WeatherDefinition }

for _, weather in WeatherConfig.Weathers do
	WeatherConfig.ById[weather.Id] = weather
	if MutationConfig.ById[weather.MutationId] == nil then
		warn("[WeatherConfig] Unknown mutation", weather.MutationId, "on weather", weather.Id)
	end
end

return WeatherConfig
