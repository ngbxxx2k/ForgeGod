--!strict

export type BuffKind = "Timed" | "OneUse"

export type BuffDefinition = {
	Id: string,
	Kind: BuffKind,
	Duration: number?,
	Rarity: string,
	Price: number,
	Effects: { [string]: number },
}

local BuffConfig = {}

BuffConfig.Kinds = {
	Timed = "Timed" :: BuffKind,
	OneUse = "OneUse" :: BuffKind,
}

BuffConfig.EffectIds = {
	BreakChanceMultiplier = "BreakChanceMultiplier",
	SuccessChanceMultiplier = "SuccessChanceMultiplier",
	BreakProtection = "BreakProtection",
	SellPriceMultiplier = "SellPriceMultiplier",
	MutationChanceMultiplier = "MutationChanceMultiplier",
	WeatherMutationChanceMultiplier = "WeatherMutationChanceMultiplier",
	SmeltLuckBonus = "SmeltLuckBonus",
}

BuffConfig.Buffs = {
	{
		Id = "BlessingPotion",
		Kind = "Timed",
		Duration = 180,
		Rarity = "Common",
		Price = 500,
		Effects = { BreakChanceMultiplier = 0.8 },
	},
	{
		Id = "LuckPotion",
		Kind = "Timed",
		Duration = 180,
		Rarity = "Common",
		Price = 500,
		Effects = { SuccessChanceMultiplier = 1.25 },
	},
	{
		Id = "Talisman",
		Kind = "OneUse",
		Rarity = "Rare",
		Price = 5000,
		Effects = { BreakProtection = 1 },
	},
	{
		Id = "MerchantPotion",
		Kind = "Timed",
		Duration = 180,
		Rarity = "Uncommon",
		Price = 1500,
		Effects = { SellPriceMultiplier = 1.2 },
	},
	{
		Id = "MutationCatalyst",
		Kind = "Timed",
		Duration = 180,
		Rarity = "Uncommon",
		Price = 2000,
		Effects = { MutationChanceMultiplier = 2 },
	},
	{
		Id = "AlloyFluxPotion",
		Kind = "Timed",
		Duration = 180,
		Rarity = "Rare",
		Price = 4000,
		Effects = { SmeltLuckBonus = 0.15 },
	},
	{
		Id = "StormPotion",
		Kind = "Timed",
		Duration = 300,
		Rarity = "Rare",
		Price = 4000,
		Effects = { WeatherMutationChanceMultiplier = 2 },
	},
} :: { BuffDefinition }

BuffConfig.ById = {} :: { [string]: BuffDefinition }

for _, buff in BuffConfig.Buffs do
	BuffConfig.ById[buff.Id] = buff
	for effectId in buff.Effects do
		if BuffConfig.EffectIds[effectId] == nil then
			warn("[BuffConfig] Unknown effect", effectId, "on buff", buff.Id)
		end
	end
	if buff.Kind == BuffConfig.Kinds.Timed and type(buff.Duration) ~= "number" then
		warn("[BuffConfig] Timed buff is missing Duration:", buff.Id)
	end
end

return BuffConfig
