--!strict

local ForgeStrikeConfig = {}

ForgeStrikeConfig.AnimationName = "ForgeStrike"
ForgeStrikeConfig.HammerModelName = "Fantasy_Hammer"
ForgeStrikeConfig.HitTime = 16 / 30
ForgeStrikeConfig.AnimationLength = 36 / 30
ForgeStrikeConfig.FadeTime = 0.15
-- PLACEHOLDER: tốc độ vung búa tối đa khi click nhanh và hệ số làm mượt nhịp click
ForgeStrikeConfig.MaxStrikeSpeed = 3
ForgeStrikeConfig.StrikeSpeedSmoothing = 0.5

ForgeStrikeConfig.SoundNames = {
	Clang = "ForgeHammerClang",
	Sizzle = "ForgeSparkSizzle",
}
ForgeStrikeConfig.ClangSpeed = NumberRange.new(0.9, 1.1)
ForgeStrikeConfig.SizzleSpeed = NumberRange.new(0.95, 1.05)

ForgeStrikeConfig.AttachmentNames = {
	HandGrip = "HammerGrip",
	HammerGrip = "HammerGrip",
	ForgePoint = "ForgePoint",
	ImpactPoint = "ImpactPoint",
	WeaponAnchor = "ForgeAnchor",
}

ForgeStrikeConfig.HandPartName = "RightHand"
ForgeStrikeConfig.HandGrip = CFrame.Angles(math.rad(-20), 0, 0)
ForgeStrikeConfig.HammerGrip = CFrame.fromMatrix(
	Vector3.new(0, -0.543, -0.008),
	Vector3.new(0, 0, 1),
	Vector3.new(-1, 0, 0)
)

ForgeStrikeConfig.AnvilSize = Vector3.new(4.156, 2.2, 2.184)
ForgeStrikeConfig.AnvilSizeTolerance = 0.05
ForgeStrikeConfig.ForgePointOffset = Vector3.new(0.798, 1.1, 0)
ForgeStrikeConfig.ImpactPointOffset = Vector3.new(0.798, 1.251, 0)
ForgeStrikeConfig.StandOffset = CFrame.new(-0.302, 1.9, 2.9)
ForgeStrikeConfig.WeaponRotation = CFrame.fromMatrix(Vector3.zero, Vector3.new(0, 0, 1), Vector3.new(-1, 0, 0))

ForgeStrikeConfig.RuntimeFolderName = "ForgeStrikeRuntime"

ForgeStrikeConfig.Textures = {
	Spark = "rbxasset://textures/particles/sparkles_main.dds",
	Smoke = "rbxasset://textures/particles/smoke_main.dds",
}

ForgeStrikeConfig.Colors = {
	SparkHot = Color3.fromRGB(255, 250, 225),
	SparkWarm = Color3.fromRGB(255, 200, 80),
	SparkOrange = Color3.fromRGB(255, 120, 30),
	SparkRed = Color3.fromRGB(200, 40, 15),
	Ember = Color3.fromRGB(255, 110, 25),
	Flash = Color3.fromRGB(255, 170, 80),
	Smoke = Color3.fromRGB(120, 115, 110),
	Dust = Color3.fromRGB(70, 65, 60),
}

ForgeStrikeConfig.Sparks = {
	Count = NumberRange.new(30, 60),
	Lifetime = NumberRange.new(0.2, 0.7),
	Speed = NumberRange.new(15, 40),
	SpreadAngle = 55,
	SpreadJitter = 12,
	TiltJitter = 18,
	Gravity = 70,
	Drag = 5,
	Size = 0.09,
	Squash = 2.5,
}

ForgeStrikeConfig.Embers = {
	Count = NumberRange.new(6, 12),
	Lifetime = NumberRange.new(0.8, 1.6),
	Speed = NumberRange.new(2, 6),
	SpreadAngle = 70,
	Gravity = 4,
	Drag = 1.5,
	Size = 0.07,
	FlickerBright = 0.1,
	FlickerDim = 0.6,
}

ForgeStrikeConfig.Flare = {
	Lifetime = NumberRange.new(0.08, 0.12),
	Size = 1.4,
}

ForgeStrikeConfig.Flash = {
	Brightness = NumberRange.new(4, 6),
	Range = 10,
	HoldTime = NumberRange.new(0.05, 0.1),
	FadeTime = 0.25,
}

ForgeStrikeConfig.Smoke = {
	Count = NumberRange.new(2, 4),
	Lifetime = NumberRange.new(0.7, 1.3),
	Speed = NumberRange.new(0.5, 1.5),
	Rise = 1.5,
	RotSpeed = 30,
	StartSize = 0.3,
	EndSize = 1.6,
	Transparency = 0.8,
}

ForgeStrikeConfig.Dust = {
	Count = NumberRange.new(8, 14),
	Lifetime = NumberRange.new(0.3, 0.6),
	Speed = NumberRange.new(3, 8),
	SpreadAngle = 75,
	Gravity = 30,
	Size = 0.04,
}

return ForgeStrikeConfig
