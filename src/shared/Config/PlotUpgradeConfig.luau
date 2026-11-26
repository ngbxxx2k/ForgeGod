--!strict

export type UpgradeStep = {
	CoinPrice: number,
	RobuxPrice: number,
	ProductId: number,
}

export type FenceColors = {
	Post: Color3,
	Rail: Color3,
}

local PlotUpgradeConfig = {}

PlotUpgradeConfig.BaseSlots = 4
PlotUpgradeConfig.MaxSlots = 10

-- PLACEHOLDER: giá coins mỗi lần nâng cấp
PlotUpgradeConfig.Steps = {
	{ CoinPrice = 100_000, RobuxPrice = 9, ProductId = 3736223079 },
	{ CoinPrice = 25_000_000, RobuxPrice = 29, ProductId = 3736223095 },
	{ CoinPrice = 5e9, RobuxPrice = 59, ProductId = 3736223111 },
	{ CoinPrice = 5e12, RobuxPrice = 119, ProductId = 3736223185 },
	{ CoinPrice = 1e16, RobuxPrice = 229, ProductId = 3736223198 },
	{ CoinPrice = 5e18, RobuxPrice = 299, ProductId = 3736223207 },
} :: { UpgradeStep }

-- Màu hàng rào theo level plot (phần tử thứ i = level i): cột + nắp cột dùng Post (đậm), thanh ngang dùng Rail (nhạt)
-- Level 1 gỗ, sau đó theo quặng: Silver, Gold, Platinum, Emerald, DarkMoonstone (tím), Mithril (xanh)
PlotUpgradeConfig.FenceColors = {
	{ Post = Color3.fromRGB(150, 98, 52), Rail = Color3.fromRGB(196, 138, 78) },
	{ Post = Color3.fromRGB(150, 160, 175), Rail = Color3.fromRGB(221, 230, 240) },
	{ Post = Color3.fromRGB(215, 150, 20), Rail = Color3.fromRGB(255, 210, 80) },
	{ Post = Color3.fromRGB(110, 185, 185), Rail = Color3.fromRGB(207, 245, 242) },
	{ Post = Color3.fromRGB(25, 140, 75), Rail = Color3.fromRGB(80, 220, 140) },
	{ Post = Color3.fromRGB(70, 55, 170), Rail = Color3.fromRGB(135, 120, 235) },
	{ Post = Color3.fromRGB(25, 85, 200), Rail = Color3.fromRGB(95, 165, 255) },
} :: { FenceColors }

PlotUpgradeConfig.Currencies = {
	Coins = "Coins",
	Robux = "Robux",
}

return PlotUpgradeConfig
