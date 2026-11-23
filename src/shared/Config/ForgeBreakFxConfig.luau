--!strict

local AssetIds = require(script.Parent.Parent.Constants.AssetIds)

local ForgeBreakFxConfig = {
	FragmentName = "ForgeBreakFragment",
	FragmentCount = 16,
	FragmentSize = NumberRange.new(0.25, 0.6),
	WedgeChance = 0.5,
	OutwardSpeed = NumberRange.new(6, 14),
	UpwardSpeed = NumberRange.new(6, 12),
	SpinSpeed = NumberRange.new(10, 25),
	Lifetime = 1.4,
	FadeTime = 0.5,
	PuffTexture = AssetIds.Weather.SmokeBlob,
	PuffCount = 10,
	PuffColor = Color3.fromRGB(90, 85, 80),
	PuffSize = NumberSequence.new(1, 3),
	PuffTransparency = NumberSequence.new(0.4, 1),
	PuffSpeed = NumberRange.new(2, 5),
	PuffLifetime = NumberRange.new(0.6, 1),
}

return ForgeBreakFxConfig
