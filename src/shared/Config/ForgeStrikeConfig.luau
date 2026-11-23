--!strict

export type WeaponModelStage = {
	MinShapeStage: number,
	ModelName: string,
}

local ForgeStrikeConfig = {}

ForgeStrikeConfig.AnimationName = "ForgeStrike"
ForgeStrikeConfig.HammerModelName = "Fantasy_Hammer"
ForgeStrikeConfig.HitTime = 16 / 30
ForgeStrikeConfig.AnimationLength = 36 / 30
ForgeStrikeConfig.FadeTime = 0.15

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
ForgeStrikeConfig.SpectatorFolderName = "ForgeSpectatorRuntime"

ForgeStrikeConfig.SurfaceProbeHeight = 5
ForgeStrikeConfig.SettleProbeStep = 0.1
ForgeStrikeConfig.SettleProbeDepth = 1
-- Khe hở nhỏ nhất giữa vũ khí và mặt đe (vũ khí lơ lửng, không chạm/xuyên đe)
ForgeStrikeConfig.AnvilGap = 0.01
-- Vũ khí dày hơn khe dưới búa sẽ bị ép dẹt theo chiều đứng; số lần lặp và sai số cho phép
ForgeStrikeConfig.FitIterations = 6
ForgeStrikeConfig.FitTolerance = 0.002
-- Khe hở giữa mặt búa và bề mặt vũ khí lúc chạm
ForgeStrikeConfig.StrikeClearance = 0.02
ForgeStrikeConfig.WeaponLength = 4.8
ForgeStrikeConfig.WeaponScalePasses = 4
ForgeStrikeConfig.WeaponScaleTolerance = 0.01

-- Model vũ khí đặt trên đe: ReplicatedStorage.Assets.Models/<WeaponType>, không có thì dùng model test
ForgeStrikeConfig.WeaponModelsFolderName = "Models"
-- PLACEHOLDER: mốc đổi model khi rèn (test): dạng >= MinShapeStage dùng ModelName trong World
ForgeStrikeConfig.DefaultShapeStage = 1
ForgeStrikeConfig.TestWeaponModelStages = {
	{ MinShapeStage = 1, ModelName = "Sword_level_1" },
	{ MinShapeStage = 2, ModelName = "Voidheart" },
} :: { WeaponModelStage }

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

-- Vũ khí lún xuống rồi nảy lại, rung lắc tắt dần mỗi lần búa chạm
ForgeStrikeConfig.Impact = {
	Duration = 0.3,
	Dip = 0.06,
	Decay = 14,
	BounceFrequency = 38,
	WobbleAngle = 2.5,
	WobbleFrequency = 55,
	WobbleRollRatio = 0.5,
}

-- Chữ kết quả vòng quay hiện tại chỗ búa chạm khi kim dừng: nảy lên, lắc trái phải, rồi mờ dần
ForgeStrikeConfig.OutcomePopup = {
	Font = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Bold),
	-- Kích thước chữ (pixel) và độ lệch so với điểm va chạm trên mặt vũ khí (stud)
	WidthPixels = 260,
	HeightPixels = 64,
	StudsOffset = Vector3.zero,
	StrokeColor = Color3.new(0, 0, 0),
	StrokeThickness = 3,
	-- Nảy lên: phóng từ StartScale tới PeakScale rồi về 1
	StartScale = 0.3,
	PeakScale = 1.25,
	PopTime = 0.12,
	SettleTime = 0.12,
	-- Lắc trái phải: góc nghiêng (độ), độ lệch ngang (pixel), tần số (lần/giây), tốc độ tắt dần
	ShakeAngle = 12,
	ShakeOffset = 10,
	ShakeFrequency = 9,
	ShakeDecay = 3.5,
	-- Giữ nguyên rồi bay lên và mờ dần (pixel, giây)
	HoldTime = 0.55,
	FadeTime = 0.35,
	FadeRise = 24,
}

return ForgeStrikeConfig
