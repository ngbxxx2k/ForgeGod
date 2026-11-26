--!strict

local DigOreTable = {}

-- PLACEHOLDER: trọng số ra quặng khi đào ở bãi cát (tổng ~1000), độ hiếm dùng để tính thời gian đào
DigOreTable.Ores = {
	Copper = { Weight = 494, Rarity = "Common" },
	Iron = { Weight = 206, Rarity = "Common" },
	Silver = { Weight = 200, Rarity = "Rare" },
	Gold = { Weight = 70, Rarity = "Rare" },
	Platinum = { Weight = 20, Rarity = "Epic" },
	Emerald = { Weight = 8, Rarity = "Epic" },
	DarkMoonstone = { Weight = 1.6, Rarity = "Legendary" },
	Mithril = { Weight = 0.4, Rarity = "Legendary" },
	GodsCore = { Weight = 0.04, Rarity = "Mythic" },
} :: { [string]: { Weight: number, Rarity: string } }

-- Độ hiếm được nhân trọng số theo may mắn của máy dò (luck ^ exponent)
DigOreTable.LuckExponent = {
	Common = 0,
	Uncommon = 0.5,
	Rare = 1,
	Epic = 1.25,
	Legendary = 1.5,
	Mythic = 1.75,
} :: { [string]: number }

return DigOreTable
