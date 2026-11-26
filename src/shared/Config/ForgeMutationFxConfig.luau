--!strict

local AssetIds = require(script.Parent.Parent.Constants.AssetIds)
local LightningTypes = require(script.Parent.Parent.Types.LightningTypes)

export type TierColor = {
	Core: Color3,
	Glow: Color3,
}

local ForgeMutationFxConfig = {
	DefaultTier = "Common",
	StrikeCount = 2,
	StrikeGap = 0.14,
	FlashEffectName = "ForgeMutationFlash",
	FlashBrightness = 0.35,
	FlashTintStrength = 0.6,
	FlashFadeTime = 0.4,
	BurstTexture = AssetIds.Weather.SoftDot,
	BurstCount = 40,
	BurstSpeed = NumberRange.new(8, 16),
	BurstLifetime = NumberRange.new(0.5, 0.9),
	BurstSize = NumberSequence.new(0.35, 0),
	BurstBrightness = 3,
	ThunderSoundIds = AssetIds.Weather.ForgeThunder,
	ThunderVolume = 2.5,
	ShakeStrength = 4,
	FollowUpShakeStrength = 2.5,
	ProbeHeight = 10,
	CleanupDelay = 1.5,
}

ForgeMutationFxConfig.BoltStyle = {
	StartHeight = 45,
	Segments = 10,
	Jitter = 2.5,
	BranchCount = NumberRange.new(2, 3),
	BranchLength = NumberRange.new(3, 7),
	BranchSegments = 4,
	Texture = AssetIds.Weather.BoltGlow,
	CoreWidth = 0.5,
	GlowWidth = 3,
	CoreBrightness = 6,
	GlowBrightness = 2,
	CoreColor = Color3.fromRGB(255, 255, 255),
	GlowColor = Color3.fromRGB(205, 215, 235),
	GlowTransparency = 0.2,
	Lifetime = 0.7,
	FlickerStrength = 0.4,
	ImpactLightRange = 12,
	ImpactLightBrightness = 4,
} :: LightningTypes.BoltStyle

ForgeMutationFxConfig.TierColors = {
	Common = { Core = Color3.fromRGB(255, 255, 255), Glow = Color3.fromRGB(205, 215, 235) },
	Uncommon = { Core = Color3.fromRGB(170, 255, 160), Glow = Color3.fromRGB(40, 210, 70) },
	Rare = { Core = Color3.fromRGB(170, 210, 255), Glow = Color3.fromRGB(30, 110, 255) },
} :: { [string]: TierColor }

return ForgeMutationFxConfig
