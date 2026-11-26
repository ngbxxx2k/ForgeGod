--!strict

export type RewardKind = "Coins" | "Item" | "Spin"

export type SpinReward = {
	Id: string,
	Kind: RewardKind,
	Amount: number,
	ItemId: string?,
	Color: Color3,
}

local SpinConfig = {}

SpinConfig.RewardKinds = {
	Coins = "Coins" :: RewardKind,
	Item = "Item" :: RewardKind,
	Spin = "Spin" :: RewardKind,
}

SpinConfig.FreeSpinCooldown = 24 * 60 * 60
SpinConfig.MaxTokens = 999
SpinConfig.SpinDuration = 5
SpinConfig.FullTurns = 6
SpinConfig.LandingJitter = 0.35
SpinConfig.TickSoundName = "ForgeWheelTick"
SpinConfig.TickMinInterval = 0.04

-- Developer Product bán 1 lượt quay
SpinConfig.SpinProduct = {
	ProductId = 3736222101,
	RobuxPrice = 19,
	Spins = 1,
}

SpinConfig.Rewards = {
	{ Id = "Coins1M", Kind = "Coins", Amount = 1_000_000, Color = Color3.fromRGB(255, 160, 40) },
	{ Id = "Coins10M", Kind = "Coins", Amount = 10_000_000, Color = Color3.fromRGB(150, 75, 230) },
	{ Id = "ExtraSpin", Kind = "Spin", Amount = 1, Color = Color3.fromRGB(40, 150, 245) },
	{ Id = "Talisman", Kind = "Item", ItemId = "Talisman", Amount = 1, Color = Color3.fromRGB(110, 205, 60) },
	{
		Id = "MutationEraser",
		Kind = "Item",
		ItemId = "MutationEraser",
		Amount = 1,
		Color = Color3.fromRGB(245, 205, 50),
	},
	{ Id = "AngelHeart", Kind = "Item", ItemId = "AngelHeart", Amount = 1, Color = Color3.fromRGB(240, 80, 150) },
	{ Id = "GodsCore", Kind = "Item", ItemId = "GodsCore", Amount = 5, Color = Color3.fromRGB(235, 60, 60) },
} :: { SpinReward }

SpinConfig.RewardById = {} :: { [string]: SpinReward }

for index, reward in SpinConfig.Rewards do
	SpinConfig.RewardById[reward.Id] = reward
	if reward.Kind == SpinConfig.RewardKinds.Item and reward.ItemId == nil then
		warn("[SpinConfig] Item reward is missing ItemId:", reward.Id, index)
	end
end

return SpinConfig
