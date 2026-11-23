--!strict

local AssetIds = require(script.Parent.Parent.Constants.AssetIds)

local ForgeFrenzyFxConfig = {}

-- Màu cầu vồng: số lần dải màu trôi qua một điểm mỗi giây
ForgeFrenzyFxConfig.HueSpeed = 0.8
ForgeFrenzyFxConfig.Saturation = 1
ForgeFrenzyFxConfig.Brightness = 1
-- Số mốc màu trong dải cầu vồng (gradient màn hình, tia lửa)
ForgeFrenzyFxConfig.GradientSteps = 7
ForgeFrenzyFxConfig.GlowSpinSpeed = 180

-- Dải cầu vồng chạy ngang vũ khí: độ dài một dải đủ 7 màu (stud)
ForgeFrenzyFxConfig.BandLength = 2.5
-- Ảnh dải cầu vồng (ngang và dọc) dán lên các mặt vũ khí
ForgeFrenzyFxConfig.BandTextures = {
	Horizontal = AssetIds.Textures.FrenzyBandHorizontal,
	Vertical = AssetIds.Textures.FrenzyBandVertical,
}
ForgeFrenzyFxConfig.BandTransparency = 0
ForgeFrenzyFxConfig.BandCrossTile = 1000
ForgeFrenzyFxConfig.TextureName = "FrenzyRainbowBand"
ForgeFrenzyFxConfig.WeaponMaterial = Enum.Material.Neon
ForgeFrenzyFxConfig.OutlineTransparency = 0
ForgeFrenzyFxConfig.OutlineHueOffset = 0.5
ForgeFrenzyFxConfig.HiddenTransparency = 0.99

-- Cảnh báo sắp hết frenzy: còn bao nhiêu giây thì nhấp nháy, số lần nháy mỗi giây
ForgeFrenzyFxConfig.WarningTime = 0.6
ForgeFrenzyFxConfig.BlinkFrequency = 8

-- Rung màn hình: rung nền suốt frenzy và cú rung mỗi lần búa chạm
ForgeFrenzyFxConfig.Shake = {
	SustainPosition = 0.025,
	SustainRotation = 0.35,
	KickPosition = 0.09,
	KickRotation = 1.4,
	KickDecay = 9,
	Frequency = 32,
}

-- Nháy sáng màn hình
ForgeFrenzyFxConfig.Screen = {
	GuiName = "ForgeFrenzyOverlay",
	DisplayOrder = 50,
	BaseTransparency = 0.88,
	BreathAmplitude = 0.04,
	BreathFrequency = 4,
	PulseTransparency = 0.5,
	PulseFadeTime = 0.3,
	SpinSpeed = 120,
}

-- Tia lửa cầu vồng
ForgeFrenzyFxConfig.Sparks = {
	LightSaturation = 0.6,
}

return ForgeFrenzyFxConfig
