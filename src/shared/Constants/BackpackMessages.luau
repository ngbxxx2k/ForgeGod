--!strict

local BackpackMessages = {
	AmountFormat = "x%d",
	StorageFormat = "Storage: %d/%d",
	PriceFormat = "$%s",
	IncomeFormat = "$%s/s",
	LevelFormat = "+%d",
	UseText = "USE",
	EquipText = "EQUIP",
	UnequipText = "UNEQUIP",
	BrokenNameFormat = "%s (Broken)",
	NoMutationText = "No Mutation",
	MutationFormat = "Mutation: %s",
	WeightFormat = "Weight: %s",
}

BackpackMessages.TabNames = {
	Ore = "Ores",
	Buff = "Buffs",
	Weapon = "Weapons",
}

BackpackMessages.ItemNames = {
	Copper = "Copper",
	Iron = "Iron",
	Silver = "Silver",
	Gold = "Gold",
	Platinum = "Platinum",
	Emerald = "Emerald",
	DarkMoonstone = "Dark Moonstone",
	Mithril = "Mithril",
	GodsCore = "God's Core",
	BlessingPotion = "Blessing Potion",
	LuckPotion = "Luck Potion",
	Talisman = "Guardian Talisman",
	MerchantPotion = "Merchant Potion",
	MutationCatalyst = "Mutation Catalyst",
	AlloyFluxPotion = "Alloy Flux Potion",
	StormPotion = "Storm Potion",
	MutationEraser = "Mutation Eraser",
}

BackpackMessages.ItemDescriptions = {
	BlessingPotion = "Reduces the chance of breaking your weapon by 20% for 3 minutes.",
	LuckPotion = "Increases the chance of Success and Great Success by 25% for 3 minutes.",
	Talisman = "Blocks one weapon break. Your weapon stays exactly as it was.",
	MerchantPotion = "Weapons sell for 20% more for 3 minutes.",
	MutationCatalyst = "Doubles the mutation chance on every forge strike for 3 minutes.",
	AlloyFluxPotion = "Increases the chance of higher rarity weapons by 15% when smelting "
		.. "for 3 minutes.",
	StormPotion = "Doubles the weather mutation chance for 5 minutes.",
	MutationEraser = "Removes the current mutation from a weapon.",
}

return BackpackMessages
