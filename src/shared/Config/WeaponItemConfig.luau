--!strict

export type WeaponItemTarget = "Broken" | "Mutated"

export type WeaponItemDefinition = {
	Id: string,
	Rarity: string,
	Price: number,
	Target: WeaponItemTarget,
}

local WeaponItemConfig = {}

WeaponItemConfig.Targets = {
	Broken = "Broken" :: WeaponItemTarget,
	Mutated = "Mutated" :: WeaponItemTarget,
}

WeaponItemConfig.Items = {
	{
		Id = "AngelHeart",
		Rarity = "Mythic",
		Price = 2_500_000,
		Target = "Broken",
	},
	{
		Id = "MutationEraser",
		Rarity = "Epic",
		Price = 2_500_000,
		Target = "Mutated",
	},
} :: { WeaponItemDefinition }

WeaponItemConfig.ById = {} :: { [string]: WeaponItemDefinition }

for _, item in WeaponItemConfig.Items do
	WeaponItemConfig.ById[item.Id] = item
end

return WeaponItemConfig
