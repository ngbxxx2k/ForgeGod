--!strict

export type BoardDefinition = {
	Id: string,
	ModelName: string,
	StatName: string,
	ValueColor: Color3,
}

local LeaderboardConfig = {}

-- Chu kỳ làm mới bảng xếp hạng (giây), mọi server cùng mốc os.time()
LeaderboardConfig.RefreshInterval = 600
-- Số người hiển thị tối đa trên mỗi bảng
LeaderboardConfig.TopCount = 100

LeaderboardConfig.HubFolderPath = { "Map", "Hub" }
LeaderboardConfig.PanelName = "Panel"

LeaderboardConfig.Boards = {
	{
		Id = "Money",
		ModelName = "LeaderboardCoins",
		StatName = "TotalCoinsEarned",
		ValueColor = Color3.fromRGB(125, 255, 75),
	},
	{
		Id = "Level",
		ModelName = "LeaderboardLevel",
		StatName = "HighestWeaponLevel",
		ValueColor = Color3.fromRGB(110, 225, 255),
	},
	{
		Id = "WeaponIncome",
		ModelName = "LeaderboardWeaponIncome",
		StatName = "HighestWeaponIncome",
		ValueColor = Color3.fromRGB(125, 255, 75),
	},
	{
		Id = "Donated",
		ModelName = "LeaderboardDonated",
		StatName = "TotalRobuxSpent",
		ValueColor = Color3.fromRGB(255, 220, 90),
	},
} :: { BoardDefinition }

LeaderboardConfig.PixelsPerStud = 50
LeaderboardConfig.MaxViewDistance = 250
LeaderboardConfig.Font = Enum.Font.FredokaOne

LeaderboardConfig.Colors = {
	Rim = Color3.fromRGB(110, 210, 60),
	RimDark = Color3.fromRGB(55, 150, 35),
	Inner = Color3.fromRGB(28, 34, 68),
	Outline = Color3.fromRGB(12, 12, 20),
	Text = Color3.fromRGB(255, 255, 255),
	DarkText = Color3.fromRGB(25, 25, 35),
	Row = Color3.fromRGB(44, 54, 102),
	RankBadge = Color3.fromRGB(64, 78, 140),
	Avatar = Color3.fromRGB(120, 170, 230),
	ScrollBar = Color3.fromRGB(200, 210, 240),
	TopRanks = {
		Color3.fromRGB(255, 214, 70),
		Color3.fromRGB(215, 225, 240),
		Color3.fromRGB(240, 160, 85),
	},
}

return LeaderboardConfig
