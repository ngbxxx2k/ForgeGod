--!strict

export type UpgradeTier = {
	Id: string,
	DisplayName: string,
	Rarity: string,
	Material: string,
	Luck: number,
	CoinPrice: number,
	RobuxPrice: number?,
	ProductId: number?,
}

export type UpgradeTrack = {
	Id: string,
	StatName: string,
	Tiers: { UpgradeTier },
}

local ANVIL_PRODUCT_IDS = { 3736222284, 3736222297, 3736222311, 3736222380, 3736222393, 3736222409 }
local HAMMER_PRODUCT_IDS = { 3736222492, 3736222501, 3736222515, 3736222595, 3736222603, 3736222622 }

local ForgeUpgradeConfig = {}

ForgeUpgradeConfig.TrackIds = {
	Anvil = "Anvil",
	Hammer = "Hammer",
}

ForgeUpgradeConfig.DefaultTrackId = ForgeUpgradeConfig.TrackIds.Anvil
ForgeUpgradeConfig.MinTier = 1
ForgeUpgradeConfig.Currencies = {
	Coins = "Coins",
	Robux = "Robux",
}

local function buildTiers(suffix: string, productIds: { number }): { UpgradeTier }
	return {
		{
			Id = "Copper" .. suffix,
			DisplayName = "Copper " .. suffix,
			Material = "Default",
			Rarity = "Common",
			Luck = 0,
			CoinPrice = 0,
		},
		{
			Id = "Silver" .. suffix,
			DisplayName = "Silver " .. suffix,
			Material = "Silver",
			Rarity = "Common",
			Luck = 0.05,
			CoinPrice = 25_000,
			RobuxPrice = 9,
			ProductId = productIds[1],
		},
		{
			Id = "Gold" .. suffix,
			DisplayName = "Gold " .. suffix,
			Material = "Gold",
			Rarity = "Uncommon",
			Luck = 0.1,
			CoinPrice = 2_500_000,
			RobuxPrice = 29,
			ProductId = productIds[2],
		},
		{
			Id = "Platinum" .. suffix,
			DisplayName = "Platinum " .. suffix,
			Material = "Platinum",
			Rarity = "Rare",
			Luck = 0.2,
			CoinPrice = 1e9,
			RobuxPrice = 59,
			ProductId = productIds[3],
		},
		{
			Id = "Emerald" .. suffix,
			DisplayName = "Emerald " .. suffix,
			Material = "Emerald",
			Rarity = "Epic",
			Luck = 0.35,
			CoinPrice = 2.5e12,
			RobuxPrice = 119,
			ProductId = productIds[4],
		},
		{
			Id = "DarkMoonstone" .. suffix,
			DisplayName = "Dark Moonstone " .. suffix,
			Material = "DarkMoonstone",
			Rarity = "Legendary",
			Luck = 0.5,
			CoinPrice = 1e16,
			RobuxPrice = 229,
			ProductId = productIds[5],
		},
		{
			Id = "Mithril" .. suffix,
			DisplayName = "Mithril " .. suffix,
			Material = "Mithril",
			Rarity = "Mythic",
			Luck = 0.75,
			CoinPrice = 1e18,
			RobuxPrice = 299,
			ProductId = productIds[6],
		},
	}
end

-- PLACEHOLDER: Luck cộng vào may mắn khi rèn
ForgeUpgradeConfig.Tracks = {
	Anvil = { Id = "Anvil", StatName = "Forge Luck", Tiers = buildTiers("Anvil", ANVIL_PRODUCT_IDS) },
	Hammer = { Id = "Hammer", StatName = "Forge Luck", Tiers = buildTiers("Hammer", HAMMER_PRODUCT_IDS) },
} :: { [string]: UpgradeTrack }

function ForgeUpgradeConfig.GetTier(trackId: string, tierIndex: number): UpgradeTier?
	local track = ForgeUpgradeConfig.Tracks[trackId]
	return if track then track.Tiers[tierIndex] else nil
end

function ForgeUpgradeConfig.GetMaxTier(trackId: string): number
	local track = ForgeUpgradeConfig.Tracks[trackId]
	return if track then #track.Tiers else ForgeUpgradeConfig.MinTier
end

function ForgeUpgradeConfig.ClampTier(trackId: string, tierIndex: any): number
	if type(tierIndex) ~= "number" or tierIndex ~= tierIndex then
		return ForgeUpgradeConfig.MinTier
	end
	local maxTier = ForgeUpgradeConfig.GetMaxTier(trackId)
	return math.clamp(math.floor(tierIndex), ForgeUpgradeConfig.MinTier, maxTier)
end

function ForgeUpgradeConfig.IsValidTier(trackId: any, tierIndex: any): boolean
	return type(trackId) == "string"
		and ForgeUpgradeConfig.Tracks[trackId] ~= nil
		and type(tierIndex) == "number"
		and tierIndex == math.floor(tierIndex)
		and tierIndex >= ForgeUpgradeConfig.MinTier
		and tierIndex <= ForgeUpgradeConfig.GetMaxTier(trackId)
end

return ForgeUpgradeConfig
