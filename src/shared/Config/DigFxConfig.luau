--!strict

local AssetIds = require(script.Parent.Parent.Constants.AssetIds)

export type SoundSpec = {
	SoundId: string,
	Volume: number,
	PlaybackSpeed: number,
}

local DigFxConfig = {}

DigFxConfig.Ring = {
	Thickness = 0.35,
	Height = 0.12,
	GroundLift = 0.2,
	IdleColor = Color3.fromRGB(255, 255, 255),
	IdleTransparency = 0.75,
	SignalColor = Color3.fromRGB(60, 255, 110),
	OnSpotTransparency = 0.05,
	BlinkTransparency = NumberRange.new(0.05, 0.85),
	BlinkHz = NumberRange.new(1.2, 9),
}

DigFxConfig.Coil = {
	Radius = 0.95,
	InnerRadius = 0.75,
	Height = 0.2,
	IdleTransparency = 1,
}

DigFxConfig.Marker = {
	FolderName = "DigMarkers",
	Height = 18,
	CoreWidth = 0.5,
	GlowWidth = 1.6,
	BaseWidth = 2.6,
	BaseHeight = 0.08,
	GroundLift = 0.12,
	CoreTransparency = 0.2,
	GlowTransparency = 0.78,
	BaseTransparency = 0.35,
	PulseHz = 1.1,
	PulseAmount = 0.12,
	LightRange = 12,
	LightBrightness = 2,
	FadeTime = 0.3,
}

DigFxConfig.Prompt = {
	KeyCode = Enum.KeyCode.E,
	MaxActivationDistance = 12,
	HoldDuration = 0,
	PartName = "DigPromptAnchor",
}

DigFxConfig.Progress = {
	Size = UDim2.fromOffset(160, 22),
	StudsOffset = Vector3.new(0, 2.5, 0),
	BackColor = Color3.fromRGB(30, 30, 36),
	FillColor = Color3.fromRGB(255, 200, 60),
	CornerRadius = UDim.new(0.5, 0),
}

DigFxConfig.Dirt = {
	Color = ColorSequence.new(Color3.fromRGB(226, 196, 140), Color3.fromRGB(176, 140, 90)),
	BurstCount = 14,
	BurstInterval = 1.4,
	FirstBurstDelay = 0.35,
	Speed = NumberRange.new(8, 14),
	Lifetime = NumberRange.new(0.5, 0.9),
	Size = NumberSequence.new(0.35, 0.1),
	SpreadAngle = Vector2.new(35, 35),
	Acceleration = Vector3.new(0, -40, 0),
}

DigFxConfig.Animation = {
	FadeTime = 0.2,
	DigSpeed = 1,
}

DigFxConfig.Reveal = {
	GuiName = "DigRevealGui",
	DisplayOrder = 40,
	HudGuiName = "HudGui",
	InventoryButtonName = "InventoryButton",
	ViewportSize = 220,
	RingSize = 260,
	RaysSize = 520,
	RaysImage = "rbxassetid://101267161684975",
	RaysTransparency = 0.25,
	RaysSpinSeconds = 6,
	PopTime = 0.35,
	HoldTime = 1.6,
	FlyTime = 0.6,
	SpinSpeed = 1.6,
	NameFont = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Bold),
	NameTextSize = 34,
	RarityTextSize = 26,
	LabelWidth = 400,
	LabelGap = 4,
	LabelStrokeThickness = 2.5,
	CameraFieldOfView = 40,
	CenterHeight = 0.45,
	FlyEndScale = 0.05,
	RarityColors = {
		Common = Color3.fromRGB(225, 228, 235),
		Uncommon = Color3.fromRGB(70, 200, 90),
		Rare = Color3.fromRGB(60, 140, 255),
		Epic = Color3.fromRGB(175, 75, 255),
		Legendary = Color3.fromRGB(255, 200, 40),
		Mythic = Color3.fromRGB(255, 45, 45),
	} :: { [string]: Color3 },
	PopSound = { SoundId = AssetIds.DigSounds.OreFound, Volume = 0.7, PlaybackSpeed = 1 } :: SoundSpec,
	FlySound = { SoundId = "", Volume = 0.7, PlaybackSpeed = 1 } :: SoundSpec,
}

-- Tiếng xẻng đào: phát một lần khi bắt đầu đào, tắt khi xong lượt đào
DigFxConfig.ScoopSound = { SoundId = AssetIds.DigSounds.Scoop, Volume = 0.6, PlaybackSpeed = 1 } :: SoundSpec

-- Tiếng máy dò: lặp khi có tín hiệu; tín hiệu càng mạnh thì càng to và càng nhanh
DigFxConfig.DetectorSound = {
	SoundId = AssetIds.DigSounds.DetectorLoop,
	Volume = NumberRange.new(0.1, 0.4),
	PlaybackSpeed = NumberRange.new(0.9, 1.25),
}

return DigFxConfig
