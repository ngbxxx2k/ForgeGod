--!strict

local ServerStorage = game:GetService("ServerStorage")

local ForgeOutcomeTable =
	require(ServerStorage:WaitForChild("LootTables"):WaitForChild("ForgeOutcomeTable"))

local ForgeDifficulty = {}

local function lerp(from: number, to: number, alpha: number): number
	return from + (to - from) * math.clamp(alpha, 0, 1)
end

function ForgeDifficulty.GetMultiplier(level: number): number
	local steps = ForgeOutcomeTable.DifficultySteps
	local previous = steps[1]
	if level <= previous.Level then
		return previous.Multiplier
	end
	for index = 2, #steps do
		local step = steps[index]
		if level <= step.Level then
			local alpha = (level - previous.Level) / (step.Level - previous.Level)
			return lerp(previous.Multiplier, step.Multiplier, alpha)
		end
		previous = step
	end
	return previous.Multiplier
end

return ForgeDifficulty
