--!strict

local SpinRewardTable = {}

-- PLACEHOLDER: trọng số tạm, hiếm dần theo thứ tự 1M -> 10M -> +1 Spin -> Talisman -> Eraser -> Angel Heart -> God's Core
SpinRewardTable.Weights = {
	Coins1M = 30,
	Coins10M = 22,
	ExtraSpin = 16,
	Talisman = 12,
	MutationEraser = 10,
	AngelHeart = 6,
	GodsCore = 4,
} :: { [string]: number }

return SpinRewardTable
