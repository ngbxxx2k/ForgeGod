--!strict

export type PassDefinition = {
	Id: string,
	GamePassId: number,
	GiftProductId: number,
	RobuxPrice: number,
}

export type CoinPackDefinition = {
	Id: string,
	ProductId: number,
	GiftProductId: number,
	Coins: number,
	RobuxPrice: number,
}

export type OrePackDefinition = {
	Id: string,
	ItemId: string,
	Amount: number,
	ProductId: number,
	RobuxPrice: number,
}

local PremiumShopConfig = {}

PremiumShopConfig.PassIds = {
	DoubleMoney = "DoubleMoney",
	DoubleLuck = "DoubleLuck",
}

PremiumShopConfig.PurchaseKinds = {
	Pass = "Pass",
	CoinPack = "CoinPack",
	OrePack = "OrePack",
}

PremiumShopConfig.DoubleMoneyMultiplier = 2
PremiumShopConfig.DoubleLuckMultiplier = 2

PremiumShopConfig.OreSingleAmount = 1
PremiumShopConfig.OreBundleAmount = 5

-- GiftProductId = Developer Product riêng để tặng pass
PremiumShopConfig.Passes = {
	{ Id = "DoubleMoney", GamePassId = 2098919857, GiftProductId = 3736224269, RobuxPrice = 99 },
	{ Id = "DoubleLuck", GamePassId = 2099273832, GiftProductId = 3736224338, RobuxPrice = 149 },
} :: { PassDefinition }

-- GiftProductId = Developer Product riêng để tặng gói
PremiumShopConfig.CoinPacks = {
	{ Id = "Coins30K", ProductId = 3736223274, GiftProductId = 3736224357, Coins = 30_000, RobuxPrice = 19 },
	{ Id = "Coins300K", ProductId = 3736223286, GiftProductId = 3736224370, Coins = 300_000, RobuxPrice = 39 },
	{ Id = "Coins3M", ProductId = 3736223299, GiftProductId = 3736224461, Coins = 3_000_000, RobuxPrice = 79 },
	{ Id = "Coins30M", ProductId = 3736223376, GiftProductId = 3736224474, Coins = 30_000_000, RobuxPrice = 149 },
	{ Id = "Coins300M", ProductId = 3736223390, GiftProductId = 3736224485, Coins = 300_000_000, RobuxPrice = 249 },
} :: { CoinPackDefinition }

-- { quặng, giá 1 viên, giá gói 5 viên, ProductId 1 viên, ProductId gói 5 viên }
local ORE_PRICES: { { any } } = {
	{ "Copper", 5, 22, 3736223690, 3736223754 },
	{ "Iron", 7, 31, 3736223766, 3736223779 },
	{ "Silver", 9, 39, 3736223849, 3736223869 },
	{ "Gold", 15, 67, 3736223886, 3736223962 },
	{ "Platinum", 25, 109, 3736223979, 3736223995 },
	{ "Emerald", 39, 175, 3736224083, 3736224092 },
	{ "DarkMoonstone", 69, 309, 3736224107, 3736224169 },
	{ "Mithril", 129, 579, 3736224182, 3736224196 },
	{ "GodsCore", 249, 1119, 3736224251, 3736224264 },
}

PremiumShopConfig.OrePacks = {} :: { OrePackDefinition }

for _, row in ORE_PRICES do
	local oreId, singlePrice, bundlePrice = row[1], row[2], row[3]
	local singleProductId, bundleProductId = row[4], row[5]
	table.insert(PremiumShopConfig.OrePacks, {
		Id = oreId .. "X" .. PremiumShopConfig.OreSingleAmount,
		ItemId = oreId,
		Amount = PremiumShopConfig.OreSingleAmount,
		ProductId = singleProductId,
		RobuxPrice = singlePrice,
	})
	table.insert(PremiumShopConfig.OrePacks, {
		Id = oreId .. "X" .. PremiumShopConfig.OreBundleAmount,
		ItemId = oreId,
		Amount = PremiumShopConfig.OreBundleAmount,
		ProductId = bundleProductId,
		RobuxPrice = bundlePrice,
	})
end

PremiumShopConfig.PassById = {} :: { [string]: PassDefinition }
PremiumShopConfig.CoinPackById = {} :: { [string]: CoinPackDefinition }
PremiumShopConfig.OrePackById = {} :: { [string]: OrePackDefinition }

for _, pass in PremiumShopConfig.Passes do
	PremiumShopConfig.PassById[pass.Id] = pass
end

for _, pack in PremiumShopConfig.CoinPacks do
	PremiumShopConfig.CoinPackById[pack.Id] = pack
end

for _, pack in PremiumShopConfig.OrePacks do
	PremiumShopConfig.OrePackById[pack.Id] = pack
end

return PremiumShopConfig
