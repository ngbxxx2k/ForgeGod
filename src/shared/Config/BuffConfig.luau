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
	DigLuckBonus = "DigLuckBonus",
}

BuffConfig.Buffs = {
	{
		Id = "BlessingPotion",
		Kind = "Timed",
		Duration = 180,
		Rarity = "Common",
		Price = 5_000,
		Effects = { DigLuckBonus = 0.2 },
	},
	{
		Id = "LuckPotion",
		Kind = "Timed",
		Duration = 180,
		Rarity = "Uncommon",
		Price = 10_000,
		Effects = { SuccessChanceMultiplier = 1.15 },
	},
	{
		Id = "Talisman",
		Kind = "OneUse",
		Rarity = "Legendary",
		Price = 10_000_000,
		Effects = { BreakProtection = 1 },
	},
	{
		Id = "MutationCatalyst",
		Kind = "Timed",
		Duration = 180,
		Rarity = "Rare",
		Price = 100_000,
		Effects = { MutationChanceMultiplier = 2 },
	},
	{
		Id = "AlloyFluxPotion",
		Kind = "Timed",
		Duration = 180,
		Rarity = "Epic",
		Price = 1_000_000,
		Effects = { SmeltLuckBonus = 0.15 },
	},
	{
		Id = "StormPotion",
		Kind = "Timed",
		Duration = 300,
		Rarity = "Epic",
		Price = 1_000_000,
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
