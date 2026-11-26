--!strict

local ForgeConfig = {}

ForgeConfig.FrenzyDuration = 4
-- PLACEHOLDER: doc chưa có thời gian tạm dừng thao tác sau khi hết chế độ đập liên tục
ForgeConfig.FrenzyLockDuration = 1
ForgeConfig.BrokenValueRatio = 0.5
ForgeConfig.MaxForgePoints = 10
ForgeConfig.MaxLevelByRarity = {
	Common = 10,
	Uncommon = 20,
	Rare = 30,
	Epic = 40,
	Legendary = 50,
	Mythic = 100,
} :: { [string]: number }
-- Thời gian một nhịp đập búa (giây): animation búa và vòng quay đều chạy đúng trong nhịp này
ForgeConfig.StrikeDuration = 0.8
ForgeConfig.StrikeServerTolerance = 0.2
-- PLACEHOLDER: thời gian hiện kết quả vỡ trước khi quay lại màn chọn vũ khí
ForgeConfig.BreakReturnDelay = 3

return ForgeConfig
