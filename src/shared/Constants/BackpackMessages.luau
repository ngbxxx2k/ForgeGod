--!strict

local BackpackMessages = {
	AmountFormat = "x%d",
	StorageFormat = "Storage: %d/%d",
	StorageExpandedFormat = "Storage expanded to %d slots!",
	StorageUnknownError = "Something went wrong.",
	PriceFormat = "$%s",
	IncomeFormat = "$%s/s",
	LevelFormat = "+%d",
	MaxLevelFormat = "+%d MAX",
	UseText = "USE",
	EquipText = "EQUIP",
	UnequipText = "UNEQUIP",
	BrokenNameFormat = "%s (Broken)",
	NoMutationText = "No Mutation",
	MutationFormat = "Mutation: <font color=\"%s\">%s</font>",
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
	BlessingPotion = "Prospector Potion",
	LuckPotion = "Forge Luck Potion",
	Talisman = "Guardian Talisman",
	MutationCatalyst = "Mutation Catalyst",
	AlloyFluxPotion = "Alloy Flux Potion",
	StormPotion = "Storm Potion",
	MutationEraser = "Mutation Eraser",
	AngelHeart = "Angel Heart",
}

BackpackMessages.ItemDescriptions = {
	BlessingPotion = "Increases your luck when digging for ores by 20% for 3 minutes.",
	LuckPotion = "Increases your luck when forging by 15% for 3 minutes.",
	Talisman = "Blocks one weapon break. Your weapon stays exactly as it was.",
	MutationCatalyst = "Doubles the mutation chance on every forge strike for 3 minutes.",
	AlloyFluxPotion = "Increases the chance of higher rarity weapons by 15% when smelting "
		.. "for 3 minutes.",
	StormPotion = "Doubles the weather mutation chance for 5 minutes.",
	MutationEraser = "Removes the mutation from a weapon so it can get a new one when forged.",
	AngelHeart = "Revives a broken weapon as a level 0 blank. Its mutation is removed.",
}

BackpackMessages.StorageReasons = {
	MaxStorage = "Your storage is already expanded.",
	NotLoaded = "Your data is still loading, please wait.",
	RateLimited = "Slow down!",
	NotAvailable = "This item is not available yet.",
	PromptFailed = "Could not open the purchase window.",
}

return BackpackMessages
