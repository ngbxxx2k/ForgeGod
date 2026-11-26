--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BackpackMessages = require(ReplicatedStorage.Shared.Constants.BackpackMessages)
local MutationColors = require(ReplicatedStorage.Shared.Constants.MutationColors)
local WeatherMessages = require(ReplicatedStorage.Shared.Constants.WeatherMessages)

local MutationText = {}

function MutationText.Format(mutation: string?): string
	if not mutation then
		return BackpackMessages.NoMutationText
	end
	local mutationName = WeatherMessages.MutationNames[mutation] or mutation
	return string.format(BackpackMessages.MutationFormat, MutationColors.GetTextHex(mutation), mutationName)
end

return MutationText
