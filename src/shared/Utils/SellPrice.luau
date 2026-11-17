--!strict

local BuffConfig = require(script.Parent.Parent.Config.BuffConfig)
local MutationConfig = require(script.Parent.Parent.Config.MutationConfig)
local SellConfig = require(script.Parent.Parent.Config.SellConfig)
local ShopConfig = require(script.Parent.Parent.Config.ShopConfig)
local BuffEffects = require(script.Parent.BuffEffects)

local SellPrice = {}

function SellPrice.GetBuffMultiplier(holder: BuffEffects.BuffHolder, now: number): number
	return BuffEffects.GetMultiplier(holder, BuffConfig.EffectIds.SellPriceMultiplier, now)
end

function SellPrice.Calculate(
	value: number,
	mutation: string?,
	isBroken: boolean,
	buffMultiplier: number
): number
	local mutationMultiplier = 1
	if not isBroken and mutation ~= nil then
		mutationMultiplier = MutationConfig.GetMultiplier(mutation)
	end
	return math.floor(value * mutationMultiplier * buffMultiplier)
end

function SellPrice.GetItemUnitPrice(itemId: string): number?
	local buyPrice = ShopConfig.ItemPrices[itemId]
	if type(buyPrice) ~= "number" then
		return nil
	end
	return math.floor(buyPrice * SellConfig.ItemSellRatio)
end

function SellPrice.CalculateItem(itemId: string, amount: number): number?
	local unitPrice = SellPrice.GetItemUnitPrice(itemId)
	if unitPrice == nil then
		return nil
	end
	return unitPrice * amount
end

return SellPrice
