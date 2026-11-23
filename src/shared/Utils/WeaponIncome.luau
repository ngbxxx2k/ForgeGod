--!strict

local LoadoutConfig = require(script.Parent.Parent.Config.LoadoutConfig)
local SellPrice = require(script.Parent.SellPrice)

local WeaponIncome = {}

function WeaponIncome.PerSecond(value: number, mutation: string?, isBroken: boolean): number
	if isBroken then
		return 0
	end
	local worth = SellPrice.Calculate(value, mutation, false, 1)
	return math.floor(worth * LoadoutConfig.ValueRatio)
end

return WeaponIncome
