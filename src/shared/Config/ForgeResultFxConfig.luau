--!strict

export type FxStyle = {
	GlowColor: Color3,
	GlowPulses: number,
	FlashColor: Color3?,
	FlashTransparency: number,
	ParticleCount: number,
	ParticleColors: { Color3 },
	ParticleShape: string,
	ParticleDistance: NumberRange,
	ShakeStrength: number,
	CrackCount: number,
	TextStartScale: number,
	TextEasing: Enum.EasingStyle,
	TextDuration: number,
	TextWobble: number,
	SoundName: string?,
}

local PURPLE = Color3.fromRGB(190, 110, 255)
local GOLD = Color3.fromRGB(255, 205, 90)
local GREEN = Color3.fromRGB(80, 230, 120)
local BLUE = Color3.fromRGB(90, 160, 255)
local ORANGE = Color3.fromRGB(255, 140, 50)
local YELLOW = Color3.fromRGB(255, 222, 50)
local RED = Color3.fromRGB(255, 60, 60)
local WHITE = Color3.fromRGB(255, 245, 230)

local ForgeResultFxConfig = {}

ForgeResultFxConfig.ParticleShapes = {
	Dot = "Dot",
	Spark = "Spark",
	Shard = "Shard",
}

ForgeResultFxConfig.MaxParticles = 60
ForgeResultFxConfig.ParticleStartRadius = 0.4
ForgeResultFxConfig.ParticleLifetime = NumberRange.new(0.45, 0.8)
ForgeResultFxConfig.DotSize = 0.035
ForgeResultFxConfig.SparkSize = Vector2.new(0.075, 0.014)
ForgeResultFxConfig.ShardSize = 0.045
ForgeResultFxConfig.GlowThickness = 12
ForgeResultFxConfig.GlowDuration = 0.5
ForgeResultFxConfig.FlashDuration = 0.35
ForgeResultFxConfig.ShakeDuration = 0.35
ForgeResultFxConfig.ShakeFrequency = 40
ForgeResultFxConfig.CrackLength = NumberRange.new(0.32, 0.55)
ForgeResultFxConfig.CrackThickness = 0.012
ForgeResultFxConfig.CrackColor = Color3.fromRGB(255, 220, 210)
ForgeResultFxConfig.CrackGrowTime = 0.08
ForgeResultFxConfig.CrackHoldTime = 0.5
ForgeResultFxConfig.CrackFadeTime = 0.35
ForgeResultFxConfig.RowHighlightTransparency = 0.55
ForgeResultFxConfig.RowFadeTime = 0.25

ForgeResultFxConfig.Styles = {
	GreatSuccess = {
		GlowColor = PURPLE,
		GlowPulses = 2,
		FlashColor = PURPLE,
		FlashTransparency = 0.6,
		ParticleCount = 26,
		ParticleColors = { PURPLE, GOLD, WHITE },
		ParticleShape = "Dot",
		ParticleDistance = NumberRange.new(0.3, 0.75),
		ShakeStrength = 0,
		CrackCount = 0,
		TextStartScale = 1.7,
		TextEasing = Enum.EasingStyle.Back,
		TextDuration = 0.45,
		TextWobble = 0,
		SoundName = "ForgeGreatSuccess",
	},
	Success = {
		GlowColor = GREEN,
		GlowPulses = 1,
		FlashColor = nil,
		FlashTransparency = 1,
		ParticleCount = 14,
		ParticleColors = { GREEN, WHITE },
		ParticleShape = "Dot",
		ParticleDistance = NumberRange.new(0.2, 0.5),
		ShakeStrength = 0,
		CrackCount = 0,
		TextStartScale = 0.7,
		TextEasing = Enum.EasingStyle.Back,
		TextDuration = 0.3,
		TextWobble = 0,
		SoundName = "ForgeSuccess",
	},
	Keep = {
		GlowColor = BLUE,
		GlowPulses = 1,
		FlashColor = nil,
		FlashTransparency = 1,
		ParticleCount = 8,
		ParticleColors = { BLUE },
		ParticleShape = "Dot",
		ParticleDistance = NumberRange.new(0.15, 0.35),
		ShakeStrength = 0,
		CrackCount = 0,
		TextStartScale = 0.9,
		TextEasing = Enum.EasingStyle.Quad,
		TextDuration = 0.25,
		TextWobble = 0,
		SoundName = "ForgeNoChange",
	},
	Downgrade = {
		GlowColor = YELLOW,
		GlowPulses = 1,
		FlashColor = YELLOW,
		FlashTransparency = 0.7,
		ParticleCount = 16,
		ParticleColors = { YELLOW, WHITE },
		ParticleShape = "Spark",
		ParticleDistance = NumberRange.new(0.25, 0.6),
		ShakeStrength = 4,
		CrackCount = 0,
		TextStartScale = 1.25,
		TextEasing = Enum.EasingStyle.Quad,
		TextDuration = 0.25,
		TextWobble = 8,
		SoundName = "ForgeDamaged",
	},
	Break = {
		GlowColor = RED,
		GlowPulses = 1,
		FlashColor = RED,
		FlashTransparency = 0.45,
		ParticleCount = 24,
		ParticleColors = { RED, Color3.fromRGB(70, 60, 55), ORANGE },
		ParticleShape = "Shard",
		ParticleDistance = NumberRange.new(0.3, 0.8),
		ShakeStrength = 9,
		CrackCount = 6,
		TextStartScale = 2.2,
		TextEasing = Enum.EasingStyle.Bounce,
		TextDuration = 0.5,
		TextWobble = 0,
		SoundName = "ForgeBreak",
	},
	Frenzy = {
		GlowColor = GOLD,
		GlowPulses = 1,
		FlashColor = nil,
		FlashTransparency = 1,
		ParticleCount = 6,
		ParticleColors = { GOLD, WHITE },
		ParticleShape = "Spark",
		ParticleDistance = NumberRange.new(0.15, 0.4),
		ShakeStrength = 0,
		CrackCount = 0,
		TextStartScale = 1.3,
		TextEasing = Enum.EasingStyle.Back,
		TextDuration = 0.15,
		TextWobble = 0,
		SoundName = nil,
	},
	Protected = {
		GlowColor = BLUE,
		GlowPulses = 2,
		FlashColor = BLUE,
		FlashTransparency = 0.7,
		ParticleCount = 12,
		ParticleColors = { BLUE, WHITE },
		ParticleShape = "Dot",
		ParticleDistance = NumberRange.new(0.2, 0.5),
		ShakeStrength = 3,
		CrackCount = 0,
		TextStartScale = 1.5,
		TextEasing = Enum.EasingStyle.Back,
		TextDuration = 0.35,
		TextWobble = 0,
		SoundName = "ForgeShieldBreak",
	},
} :: { [string]: FxStyle }

return ForgeResultFxConfig
