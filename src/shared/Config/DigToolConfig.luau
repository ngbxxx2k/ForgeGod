--!strict

export type ToolTier = {
	Id: string,
	DisplayName: string,
	Rarity: string,
	ModelName: string,
	CoinPrice: number,
	RobuxPrice: number?,
	ProductId: number?,
	Radius: number?,
	Luck: number?,
	Speed: number?,
}

export type ToolTrack = {
	Id: string,
	StatName: string,
	Tiers: { ToolTier },
}

export type HeldSpec = {
	FolderName: string,
	Scale: number,
	Grip: CFrame,
	AnimationId: string,
	CoilOffset: Vector3?,
}

local DigToolConfig = {}

DigToolConfig.ToolIds = {
	Detector = "Detector",
	Shovel = "Shovel",
}

DigToolConfig.ModelsFolderName = "DigTools"
DigToolConfig.HeldModelName = "HeldDigTool"
DigToolConfig.ToolKindAttribute = "DigToolKind"
DigToolConfig.HandPartName = "RightHand"
DigToolConfig.CoilAttachmentName = "CoilCenter"
DigToolConfig.MinTier = 1
DigToolConfig.Currencies = {
	Coins = "Coins",
	Robux = "Robux",
}

DigToolConfig.Held = {
	Detector = {
		FolderName = "MetalDetector",
		Scale = 0.85,
		Grip = CFrame.new(0, -2.0526, 1.2623, -1, 0, 0, 0, 0.7129, -0.7013, 0, -0.7013, -0.7129),
		AnimationId = "rbxassetid://87513360865172",
		CoilOffset = Vector3.new(0, 0.0912, 0.4089),
	},
	Shovel = {
		FolderName = "Shovel",
		Scale = 0.75,
		Grip = CFrame.new(0, -1.9014, -2.7155, -1, 0, 0, 0, 0.5736, 0.8192, 0, 0.8192, -0.5736),
		AnimationId = "rbxassetid://91175316484659",
	},
} :: { [string]: HeldSpec }

-- PLACEHOLDER: bán kính dò (stud), hệ số may mắn, tốc độ đào, giá coins và giá Robux (Robux chỉ hiển thị)
DigToolConfig.Tracks = {
	Detector = {
		Id = "Detector",
		StatName = "Luck",
		Tiers = {
			{ Id = "CopperDetector", DisplayName = "Copper Detector", Rarity = "Common", ModelName = "Copper", CoinPrice = 0, Radius = 5, Luck = 1 },
			{
				Id = "SilverDetector",
				DisplayName = "Silver Detector",
				Rarity = "Uncommon",
				ModelName = "Silver",
				CoinPrice = 15_000,
				RobuxPrice = 9,
				ProductId = 3736222704,
				Radius = 6,
				Luck = 1.2,
			},
			{
				Id = "GoldDetector",
				DisplayName = "Gold Detector",
				Rarity = "Rare",
				ModelName = "Gold",
				CoinPrice = 1_500_000,
				RobuxPrice = 29,
				ProductId = 3736222722,
				Radius = 7,
				Luck = 1.5,
			},
			{
				Id = "PlatinumDetector",
				DisplayName = "Platinum Detector",
				Rarity = "Epic",
				ModelName = "Platinum",
				CoinPrice = 500_000_000,
				RobuxPrice = 59,
				ProductId = 3736222740,
				Radius = 8.5,
				Luck = 2,
			},
			{
				Id = "EmeraldDetector",
				DisplayName = "Emerald Detector",
				Rarity = "Epic",
				ModelName = "Emerald",
				CoinPrice = 1e12,
				RobuxPrice = 119,
				ProductId = 3736222803,
				Radius = 10,
				Luck = 2.5,
			},
			{
				Id = "DarkMoonstoneDetector",
				DisplayName = "Dark Moonstone Detector",
				Rarity = "Legendary",
				ModelName = "DarkMoonstone",
				CoinPrice = 5e15,
				RobuxPrice = 229,
				ProductId = 3736222817,
				Radius = 12,
				Luck = 3,
			},
			{
				Id = "MithrilDetector",
				DisplayName = "Mithril Detector",
				Rarity = "Mythic",
				ModelName = "Mithril",
				CoinPrice = 5e17,
				RobuxPrice = 299,
				ProductId = 3736222830,
				Radius = 14,
				Luck = 4,
			},
		},
	},
	Shovel = {
		Id = "Shovel",
		StatName = "Dig Speed",
		Tiers = {
			{ Id = "CopperShovel", DisplayName = "Copper Shovel", Rarity = "Common", ModelName = "Copper", CoinPrice = 0, Speed = 1 },
			{
				Id = "SilverShovel",
				DisplayName = "Silver Shovel",
				Rarity = "Uncommon",
				ModelName = "Silver",
				CoinPrice = 10_000,
				RobuxPrice = 9,
				ProductId = 3736222891,
				Speed = 1.25,
			},
			{
				Id = "GoldShovel",
				DisplayName = "Gold Shovel",
				Rarity = "Rare",
				ModelName = "Gold",
				CoinPrice = 1_000_000,
				RobuxPrice = 29,
				ProductId = 3736222909,
				Speed = 1.5,
			},
			{
				Id = "PlatinumShovel",
				DisplayName = "Platinum Shovel",
				Rarity = "Epic",
				ModelName = "Platinum",
				CoinPrice = 400_000_000,
				RobuxPrice = 59,
				ProductId = 3736222922,
				Speed = 1.8,
			},
			{
				Id = "EmeraldShovel",
				DisplayName = "Emerald Shovel",
				Rarity = "Epic",
				ModelName = "Emerald",
				CoinPrice = 8e11,
				RobuxPrice = 119,
				ProductId = 3736222991,
				Speed = 2.2,
			},
			{
				Id = "DarkMoonstoneShovel",
				DisplayName = "Dark Moonstone Shovel",
				Rarity = "Legendary",
				ModelName = "DarkMoonstone",
				CoinPrice = 4e15,
				RobuxPrice = 229,
				ProductId = 3736223006,
				Speed = 2.7,
			},
			{
				Id = "MithrilShovel",
				DisplayName = "Mithril Shovel",
				Rarity = "Mythic",
				ModelName = "Mithril",
				CoinPrice = 4e17,
				RobuxPrice = 299,
				ProductId = 3736223016,
				Speed = 3.3,
			},
		},
	},
} :: { [string]: ToolTrack }

function DigToolConfig.GetTier(toolId: string, tierIndex: number): ToolTier?
	local track = DigToolConfig.Tracks[toolId]
	return if track then track.Tiers[tierIndex] else nil
end

function DigToolConfig.GetMaxTier(toolId: string): number
	local track = DigToolConfig.Tracks[toolId]
	return if track then #track.Tiers else DigToolConfig.MinTier
end

function DigToolConfig.ClampTier(toolId: string, tierIndex: any): number
	if type(tierIndex) ~= "number" or tierIndex ~= tierIndex then
		return DigToolConfig.MinTier
	end
	return math.clamp(math.floor(tierIndex), DigToolConfig.MinTier, DigToolConfig.GetMaxTier(toolId))
end

return DigToolConfig
