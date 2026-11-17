--!strict

local VoidheartFxConfig = {}

VoidheartFxConfig.Tag = "VoidheartFx"

VoidheartFxConfig.PartNames = {
	Root = "Grip",
	Top = "TopFinial",
	Bottom = "PommelSpike",
	Core = "Core_Glow",
	Orb = "PommelOrb_Glow",
	GripGlow = "Grip_Glow",
}

VoidheartFxConfig.GlowSuffix = "_Glow"

VoidheartFxConfig.Colors = {
	Glow = Color3.fromHex("873BFF"),
	Edge = Color3.fromHex("C7A6FF"),
	Core = Color3.fromHex("842CCB"),
	Void = Color3.fromHex("25123F"),
	Dark = Color3.fromHex("08050F"),
}

VoidheartFxConfig.Cycle = {
	{ Duration = 4, From = 0.15, To = 0.15 },
	{ Duration = 2.5, From = 0.15, To = 0.6 },
	{ Duration = 0.5, From = 0.6, To = 1 },
	{ Duration = 2, From = 1, To = 1 },
	{ Duration = 2, From = 1, To = 0.15 },
}

VoidheartFxConfig.SurgeStart = 0.65
VoidheartFxConfig.SurgeFull = 0.95

VoidheartFxConfig.Rings = {
	{ Name = "Ring_A", Glow = "Ring_A_Glow", Speed = 0.4, Variation = 0, VariationRate = 0 },
	{ Name = "Ring_B", Glow = "Ring_B_Glow", Speed = -0.7, Variation = 0, VariationRate = 0 },
	{ Name = "Ring_C", Glow = "Ring_C_Glow", Speed = 1.2, Variation = 0.8, VariationRate = 1.7 },
}
VoidheartFxConfig.RingEnergyBoost = 2
VoidheartFxConfig.RingWobbleAngle = math.rad(6)
VoidheartFxConfig.RingWobbleRate = 0.9

VoidheartFxConfig.CoreSpinRates = Vector3.new(0.6, 0.9, 0.4)
VoidheartFxConfig.CoreEnergyBoost = 1
VoidheartFxConfig.CorePulsePeriodIdle = 2.5
VoidheartFxConfig.CorePulsePeriodSurge = 1.2
VoidheartFxConfig.CorePulseDepth = 0.2
VoidheartFxConfig.CorePulseWindow = 0.2

VoidheartFxConfig.OrbSpinSpeed = 0.8

VoidheartFxConfig.Blades = {
	{ Name = "Blade_R", Glow = "Blade_R_Glow" },
	{ Name = "Blade_L", Glow = "Blade_L_Glow" },
}
VoidheartFxConfig.BladeSlideFraction = 0.035

VoidheartFxConfig.Claws = {
	{ Name = "Claw_UpperR", Direction = 1 },
	{ Name = "Claw_UpperL", Direction = 1 },
	{ Name = "Claw_LowerR", Direction = 1 },
	{ Name = "Claw_LowerL", Direction = 1 },
}
VoidheartFxConfig.ClawOpenAngle = math.rad(28)

VoidheartFxConfig.Textures = {
	Sparkle = "rbxasset://textures/particles/sparkles_main.dds",
	Smoke = "rbxasset://textures/particles/smoke_main.dds",
}

VoidheartFxConfig.CoreLight = {
	RangeFraction = 1.2,
	BrightnessMin = 1,
	BrightnessMax = 5,
}

VoidheartFxConfig.CoreHalo = {
	SizeFraction = 0.28,
	Lifetime = 1.2,
	Rate = 4,
	Transparency = 0.55,
	GlowScale = 0.6,
}

VoidheartFxConfig.InwardDust = {
	RadiusFraction = 0.32,
	Lifetime = 0.9,
	RateMin = 6,
	RateMax = 30,
	SizeFraction = 0.008,
}

VoidheartFxConfig.RingTrail = {
	Lifetime = 0.3,
	WidthFraction = 0.006,
	PointsPerRing = 2,
}

VoidheartFxConfig.GripFlow = {
	Lifetime = 0.5,
	RateMin = 4,
	RateMax = 24,
	SizeFraction = 0.01,
	SpeedFraction = 0.35,
}

VoidheartFxConfig.ClawArcs = {
	MinSurge = 0.3,
	WidthFraction = 0.004,
	CurveFraction = 0.06,
	Segments = 8,
	FlickerChance = 0.7,
}

VoidheartFxConfig.BladeCracks = {
	FlickerMin = 0,
	FlickerMax = 0.55,
	FlickerRate = 12,
	ShardRateMin = 1,
	ShardRateMax = 10,
	ShardLifetime = 0.7,
	ShardDrag = 2,
	ShardSizeFraction = 0.012,
}

VoidheartFxConfig.Mist = {
	RadiusFraction = 0.22,
	Lifetime = 2.2,
	RateMin = 3,
	RateMax = 10,
	SizeFraction = 0.16,
	Transparency = 0.7,
}

VoidheartFxConfig.Motes = {
	Lifetime = 1.6,
	RateMin = 6,
	RateMax = 26,
	SizeFraction = 0.006,
	RiseFraction = 0.25,
}

VoidheartFxConfig.Ribbons = {
	Count = 3,
	FirstEnergy = 0.35,
	EnergyStep = 0.2,
	AngularSpeed = 2.4,
	RadiusFraction = 0.24,
	RadiusEnergyFraction = 0.14,
	HeightMinFraction = 0.12,
	HeightMaxFraction = 0.9,
	HeightRate = 0.55,
	WidthFraction = 0.12,
	Lifetime = 0.8,
	StartTransparency = 0.35,
}

return VoidheartFxConfig
