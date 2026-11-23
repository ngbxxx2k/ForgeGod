--!strict

local ServerStorage = game:GetService("ServerStorage")

local ForgeEventTable =
	require(ServerStorage:WaitForChild("LootTables"):WaitForChild("ForgeEventTable"))

local ForgeEventRoller = {}

local rng = Random.new()

function ForgeEventRoller.Roll(strikes: number): boolean
	if strikes <= ForgeEventTable.CooldownStrikes then
		return false
	end
	if strikes >= ForgeEventTable.PityStrikes then
		return true
	end
	return rng:NextNumber() < ForgeEventTable.Chance
end

return ForgeEventRoller
