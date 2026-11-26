--!strict

export type Reward = {
	ItemId: string,
	Amount: number,
}

local IndexRewardConfig = {}

IndexRewardConfig.ByRarity = {
	Common = { ItemId = "Gold", Amount = 5 },
	Uncommon = { ItemId = "Platinum", Amount = 5 },
	Rare = { ItemId = "Emerald", Amount = 5 },
	Epic = { ItemId = "DarkMoonstone", Amount = 5 },
	Legendary = { ItemId = "Mithril", Amount = 5 },
	Mythic = { ItemId = "GodsCore", Amount = 5 },
} :: { [string]: Reward }

return IndexRewardConfig
