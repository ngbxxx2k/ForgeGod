--!strict

export type UpgradeTier = {
	Id: string,
	DisplayName: string,
	Rarity: string,
	Multiplier: number,
	CoinPrice: number,
	RobuxPrice: number?,
}

export type UpgradeTrack = {
	Id: string,
	StatName: string,
	Tiers: { UpgradeTier },
}

local ForgeUpgradeConfig = {}

ForgeUpgradeConfig.TrackIds = {
	Anvil = "Anvil",
	Hammer = "Hammer",
}

ForgeUpgradeConfig.DefaultTrackId = ForgeUpgradeConfig.TrackIds.Anvil

-- PLACEHOLDER: tên cấp, chỉ số, hệ số, giá coins và giá Robux (chỉ để hiển thị, chưa chốt F13; nil = không bán bằng Robux)
ForgeUpgradeConfig.Tracks = {
	Anvil = {
		Id = "Anvil",
		StatName = "Safety",
		Tiers = {
			{ Id = "StoneAnvil", DisplayName = "Stone Anvil", Rarity = "Common", Multiplier = 1.1, CoinPrice = 10_000 },
			{
				Id = "IronAnvil",
				DisplayName = "Iron Anvil",
				Rarity = "Uncommon",
				Multiplier = 1.25,
				CoinPrice = 250_000,
				RobuxPrice = 6,
			},
			{
				Id = "GoldAnvil",
				DisplayName = "Gold Anvil",
				Rarity = "Rare",
				Multiplier = 1.5,
				CoinPrice = 5_000_000,
				RobuxPrice = 10,
			},
			{
				Id = "EmeraldAnvil",
				DisplayName = "Emerald Anvil",
				Rarity = "Epic",
				Multiplier = 2,
				CoinPrice = 100_000_000,
				RobuxPrice = 25,
			},
			{
				Id = "MithrilAnvil",
				DisplayName = "Mithril Anvil",
				Rarity = "Legendary",
				Multiplier = 2.5,
				CoinPrice = 2_500_000_000,
				RobuxPrice = 50,
			},
			{
				Id = "GodAnvil",
				DisplayName = "God Anvil",
				Rarity = "Mythic",
				Multiplier = 3,
				CoinPrice = 50_000_000_000,
				RobuxPrice = 99,
			},
		},
	},
	Hammer = {
		Id = "Hammer",
		StatName = "Power",
		Tiers = {
			{ Id = "StoneHammer", DisplayName = "Stone Hammer", Rarity = "Common", Multiplier = 1.1, CoinPrice = 10_000 },
			{
				Id = "IronHammer",
				DisplayName = "Iron Hammer",
				Rarity = "Uncommon",
				Multiplier = 1.25,
				CoinPrice = 250_000,
				RobuxPrice = 6,
			},
			{
				Id = "GoldHammer",
				DisplayName = "Gold Hammer",
				Rarity = "Rare",
				Multiplier = 1.5,
				CoinPrice = 5_000_000,
				RobuxPrice = 10,
			},
			{
				Id = "EmeraldHammer",
				DisplayName = "Emerald Hammer",
				Rarity = "Epic",
				Multiplier = 2,
				CoinPrice = 100_000_000,
				RobuxPrice = 25,
			},
			{
				Id = "MithrilHammer",
				DisplayName = "Mithril Hammer",
				Rarity = "Legendary",
				Multiplier = 2.5,
				CoinPrice = 2_500_000_000,
				RobuxPrice = 50,
			},
			{
				Id = "GodHammer",
				DisplayName = "God Hammer",
				Rarity = "Mythic",
				Multiplier = 3,
				CoinPrice = 50_000_000_000,
				RobuxPrice = 99,
			},
		},
	},
} :: { [string]: UpgradeTrack }

return ForgeUpgradeConfig
