--!strict

local AssetIds = require(script.Parent.Parent.Constants.AssetIds)
local LightningTypes = require(script.Parent.Parent.Types.LightningTypes)
local WeatherFxTypes = require(script.Parent.Parent.Types.WeatherFxTypes)

type BoltProfile = WeatherFxTypes.BoltProfile
type ParticleLayer = WeatherFxTypes.ParticleLayer
type WeatherFxProfile = WeatherFxTypes.WeatherFxProfile

local Ids = AssetIds.Weather

local function fade(...: number): NumberSequence
	local values = { ... }
	if #values == 1 then
		return NumberSequence.new(values[1])
	end
	local keypoints = {}
	for index, value in values do
		table.insert(keypoints, NumberSequenceKeypoint.new((index - 1) / (#values - 1), value))
	end
	return NumberSequence.new(keypoints)
end

local function gradient(from: Color3, to: Color3): ColorSequence
	return ColorSequence.new(from, to)
end

local function solid(color: Color3): ColorSequence
	return ColorSequence.new(color)
end

local function withOverrides<T>(base: T, overrides: { [string]: any }): T
	local copy = table.clone(base :: any)
	for key, value in overrides do
		copy[key] = value
	end
	return copy :: any
end

local WeatherFxConfig = {
	TransitionTime = 4,
	SoundFadeTime = 3,
	ParticleFadeTime = 3,
	GroundRaycastDepth = 200,
	EmitterPartName = "WeatherParticles",
	SoundGroupName = "WeatherSounds",
	VignetteGuiName = "WeatherVignette",
	VignetteDisplayOrder = -10,
	AuroraFolderName = "WeatherAurora",
}

local BASE_BOLT_STYLE: LightningTypes.BoltStyle = {
	StartHeight = 260,
	Segments = 14,
	Jitter = 14,
	BranchCount = NumberRange.new(2, 4),
	BranchLength = NumberRange.new(30, 70),
	BranchSegments = 5,
	Texture = Ids.BoltGlow,
	CoreWidth = 3,
	GlowWidth = 18,
	CoreBrightness = 6,
	GlowBrightness = 2,
	CoreColor = Color3.fromRGB(255, 255, 255),
	GlowColor = Color3.fromRGB(150, 180, 255),
	GlowTransparency = 0.2,
	Lifetime = 0.45,
	FlickerStrength = 0.5,
	ImpactLightRange = 60,
	ImpactLightBrightness = 10,
}

local BASE_BOLT: BoltProfile = {
	Chance = 0.75,
	Distance = NumberRange.new(45, 160),
	RaycastDepth = 600,
	Style = BASE_BOLT_STYLE,
}

local BASE_RAIN: ParticleLayer = {
	Texture = Ids.RainStreak,
	Rate = 900,
	Speed = NumberRange.new(85, 105),
	Lifetime = NumberRange.new(1, 1.2),
	Size = fade(1.4),
	Transparency = fade(0.25),
	Color = solid(Color3.fromRGB(190, 205, 225)),
	Squash = 1.6,
	LightEmission = 0.2,
	LightInfluence = 0.6,
	Orientation = Enum.ParticleOrientation.FacingCameraWorldUp,
	EmissionDirection = Enum.NormalId.Bottom,
	Acceleration = Vector3.new(6, 0, 3),
	AreaSize = Vector3.new(70, 1, 70),
	Offset = Vector3.new(0, 60, 0),
	Anchor = "Camera",
}

local Thunderstorm: WeatherFxProfile = {
	Lighting = {
		Brightness = 1.8,
		ClockTime = 14.5,
		Ambient = Color3.fromRGB(70, 78, 96),
		OutdoorAmbient = Color3.fromRGB(92, 100, 122),
		ExposureCompensation = -0.1,
	},
	Atmosphere = {
		Density = 0.55,
		Offset = 0,
		Color = Color3.fromRGB(120, 126, 138),
		Decay = Color3.fromRGB(70, 76, 90),
		Glare = 0,
		Haze = 3,
	},
	ColorCorrection = {
		Brightness = -0.04,
		Contrast = 0.25,
		Saturation = -0.45,
		TintColor = Color3.fromRGB(215, 222, 238),
	},
	Particles = { BASE_RAIN },
	Lightning = {
		Interval = NumberRange.new(6, 14),
		Bolt = BASE_BOLT,
		FlashBrightness = 0.55,
		FlashTint = Color3.fromRGB(225, 232, 255),
		FlashFadeTime = 0.35,
		DoubleFlashChance = 0.4,
		DoubleFlashGap = 0.12,
		ThunderDelay = NumberRange.new(0.3, 1.6),
		ThunderSoundIds = Ids.Thunder,
		ThunderVolume = 0.8,
	},
	AmbientSounds = {
		{ SoundId = Ids.RainLoop, Volume = 0.45 },
	},
}

local HeavyRain: WeatherFxProfile = {
	Lighting = {
		Brightness = 2.2,
		ClockTime = 14.5,
		Ambient = Color3.fromRGB(90, 105, 120),
		OutdoorAmbient = Color3.fromRGB(110, 130, 150),
		ExposureCompensation = 0,
	},
	Atmosphere = {
		Density = 0.5,
		Offset = 0.05,
		Color = Color3.fromRGB(130, 150, 165),
		Decay = Color3.fromRGB(80, 100, 120),
		Glare = 0,
		Haze = 2.5,
	},
	ColorCorrection = {
		Brightness = 0,
		Contrast = 0.15,
		Saturation = -0.25,
		TintColor = Color3.fromRGB(215, 232, 245),
	},
	Particles = {
		withOverrides(BASE_RAIN, {
			Rate = 1400,
			Speed = NumberRange.new(95, 115),
			Color = solid(Color3.fromRGB(175, 215, 240)),
			Acceleration = Vector3.new(10, 0, 4),
		}),
		{
			Texture = Ids.SoftDot,
			Rate = 250,
			Speed = NumberRange.new(4, 8),
			Lifetime = NumberRange.new(0.25, 0.4),
			Size = fade(0.3, 0.05),
			Transparency = fade(0.3, 1),
			Color = solid(Color3.fromRGB(200, 230, 255)),
			LightInfluence = 0.6,
			EmissionDirection = Enum.NormalId.Top,
			SpreadAngle = Vector2.new(35, 35),
			Acceleration = Vector3.new(0, -40, 0),
			AreaSize = Vector3.new(50, 0.2, 50),
			Offset = Vector3.new(0, 0.2, 0),
			Anchor = "Ground",
		},
	},
	AmbientSounds = {
		{ SoundId = Ids.HeavyRainLoop, Volume = 0.5 },
		{ SoundId = Ids.RainLoop, Volume = 0.3 },
	},
}

local Heatwave: WeatherFxProfile = {
	Lighting = {
		Brightness = 5,
		ClockTime = 13,
		Ambient = Color3.fromRGB(160, 115, 60),
		OutdoorAmbient = Color3.fromRGB(210, 150, 70),
		ExposureCompensation = 0.25,
	},
	Atmosphere = {
		Density = 0.38,
		Offset = 0.1,
		Color = Color3.fromRGB(255, 190, 130),
		Decay = Color3.fromRGB(255, 140, 70),
		Glare = 1.2,
		Haze = 1.6,
	},
	ColorCorrection = {
		Brightness = 0.05,
		Contrast = 0.25,
		Saturation = 0.35,
		TintColor = Color3.fromRGB(255, 220, 165),
	},
	Bloom = { Intensity = 1.2, Size = 56, Threshold = 1.6 },
	DepthOfField = {
		FarIntensity = 0.25,
		FocusDistance = 40,
		InFocusRadius = 60,
		NearIntensity = 0,
	},
	Particles = {
		{
			Texture = Ids.SoftDot,
			Rate = 60,
			Speed = NumberRange.new(3, 7),
			Lifetime = NumberRange.new(4, 7),
			Size = fade(0.3, 0.05),
			Transparency = fade(0.1, 0.3, 1),
			Color = gradient(Color3.fromRGB(255, 180, 70), Color3.fromRGB(255, 70, 20)),
			LightEmission = 1,
			LightInfluence = 0,
			Brightness = 2,
			EmissionDirection = Enum.NormalId.Top,
			SpreadAngle = Vector2.new(25, 25),
			Acceleration = Vector3.new(2, 1, 1),
			Drag = 0.5,
			AreaSize = Vector3.new(80, 1, 80),
			Offset = Vector3.new(0, 0.5, 0),
			Anchor = "Ground",
		},
		{
			Texture = Ids.SoftDot,
			Rate = 25,
			Speed = NumberRange.new(2, 4),
			Lifetime = NumberRange.new(8, 10),
			Size = fade(0.18),
			Transparency = fade(0.2, 0.2, 1),
			Color = solid(Color3.fromRGB(120, 110, 105)),
			EmissionDirection = Enum.NormalId.Bottom,
			SpreadAngle = Vector2.new(20, 20),
			AreaSize = Vector3.new(80, 1, 80),
			Offset = Vector3.new(0, 30, 0),
			Anchor = "Camera",
		},
		{
			Texture = Ids.SmokeBlob,
			Rate = 12,
			Speed = NumberRange.new(1, 2),
			Lifetime = NumberRange.new(3, 5),
			Size = fade(6, 10),
			Transparency = fade(1, 0.93, 1),
			Color = solid(Color3.fromRGB(255, 210, 170)),
			LightInfluence = 0.5,
			EmissionDirection = Enum.NormalId.Top,
			RotSpeed = NumberRange.new(-20, 20),
			AreaSize = Vector3.new(70, 1, 70),
			Offset = Vector3.new(0, 1, 0),
			Anchor = "Ground",
		},
	},
	AmbientSounds = {
		{ SoundId = Ids.HeatFireLoop, Volume = 0.25 },
	},
}

local Aurora: WeatherFxProfile = {
	Lighting = {
		Brightness = 1.5,
		ClockTime = 22,
		Ambient = Color3.fromRGB(70, 90, 120),
		OutdoorAmbient = Color3.fromRGB(90, 120, 150),
		ExposureCompensation = 0.2,
	},
	Atmosphere = {
		Density = 0.3,
		Offset = 0.2,
		Color = Color3.fromRGB(90, 120, 150),
		Decay = Color3.fromRGB(60, 90, 140),
		Glare = 0,
		Haze = 0.5,
	},
	ColorCorrection = {
		Brightness = 0.02,
		Contrast = 0.1,
		Saturation = 0.15,
		TintColor = Color3.fromRGB(215, 240, 255),
	},
	Bloom = { Intensity = 1.4, Size = 40, Threshold = 1.2 },
	Sky = { StarCount = 5000 },
	Particles = {
		{
			Texture = Ids.SoftDot,
			Rate = 30,
			Speed = NumberRange.new(0.5, 1.5),
			Lifetime = NumberRange.new(6, 9),
			Size = fade(0, 0.35, 0.35, 0),
			Transparency = fade(1, 0.2, 1),
			Color = gradient(Color3.fromRGB(120, 255, 200), Color3.fromRGB(150, 90, 240)),
			LightEmission = 1,
			LightInfluence = 0,
			Brightness = 3,
			SpreadAngle = Vector2.new(180, 180),
			AreaSize = Vector3.new(90, 30, 90),
			Offset = Vector3.new(0, 10, 0),
			Anchor = "Camera",
		},
	},
	Aurora = {
		Texture = Ids.AuroraCurtain,
		Colors = gradient(Color3.fromRGB(120, 255, 200), Color3.fromRGB(150, 90, 240)),
		Count = 4,
		Height = 220,
		Distance = NumberRange.new(250, 450),
		Length = 500,
		Width = 140,
		Transparency = 0.25,
		Brightness = 2,
		TextureSpeed = 0.05,
		CurveSize = 120,
		SwayAmount = 60,
		SwaySpeed = 0.15,
	},
	AmbientSounds = {
		{ SoundId = Ids.AuroraLoop, Volume = 0.4 },
	},
}

local Radiation: WeatherFxProfile = {
	Lighting = {
		Brightness = 2.5,
		ClockTime = 14.5,
		Ambient = Color3.fromRGB(110, 130, 70),
		OutdoorAmbient = Color3.fromRGB(140, 170, 90),
		ExposureCompensation = 0,
	},
	Atmosphere = {
		Density = 0.5,
		Offset = 0.05,
		Color = Color3.fromRGB(190, 215, 110),
		Decay = Color3.fromRGB(120, 170, 50),
		Glare = 0.3,
		Haze = 2.5,
	},
	ColorCorrection = {
		Brightness = 0,
		Contrast = 0.2,
		Saturation = -0.2,
		TintColor = Color3.fromRGB(215, 255, 180),
	},
	Bloom = { Intensity = 1.3, Size = 50, Threshold = 1.4 },
	Particles = {
		{
			Texture = Ids.SoftDot,
			Rate = 120,
			Speed = NumberRange.new(0.5, 2),
			Lifetime = NumberRange.new(3, 6),
			Size = fade(0, 0.3, 0),
			Transparency = fade(0.1),
			Color = gradient(Color3.fromRGB(200, 255, 70), Color3.fromRGB(70, 170, 20)),
			LightEmission = 1,
			LightInfluence = 0,
			Brightness = 2.5,
			SpreadAngle = Vector2.new(180, 180),
			AreaSize = Vector3.new(80, 30, 80),
			Offset = Vector3.new(0, 8, 0),
			Anchor = "Camera",
		},
		{
			Texture = Ids.SoftDot,
			Rate = 80,
			Speed = NumberRange.new(3, 6),
			Lifetime = NumberRange.new(6, 9),
			Size = fade(0.15),
			Transparency = fade(0.3, 0.3, 1),
			Color = solid(Color3.fromRGB(170, 190, 120)),
			EmissionDirection = Enum.NormalId.Bottom,
			SpreadAngle = Vector2.new(15, 15),
			AreaSize = Vector3.new(80, 1, 80),
			Offset = Vector3.new(0, 40, 0),
			Anchor = "Camera",
		},
	},
	Lightning = {
		Interval = NumberRange.new(4, 9),
		FlashBrightness = 0.25,
		FlashTint = Color3.fromRGB(170, 255, 90),
		FlashFadeTime = 0.15,
		DoubleFlashChance = 0.7,
		DoubleFlashGap = 0.08,
		ThunderDelay = NumberRange.new(0, 0),
		ThunderSoundIds = {},
		ThunderVolume = 0,
	},
	AmbientSounds = {
		{ SoundId = Ids.GeigerLoop, Volume = 0.35 },
		{ SoundId = Ids.EerieLoop, Volume = 0.3 },
	},
}

local LunarEclipse: WeatherFxProfile = {
	Lighting = {
		Brightness = 2,
		ClockTime = 20.3,
		Ambient = Color3.fromRGB(125, 70, 105),
		OutdoorAmbient = Color3.fromRGB(160, 85, 120),
		ExposureCompensation = 0.7,
	},
	Atmosphere = {
		Density = 0.42,
		Offset = 0.15,
		Color = Color3.fromRGB(95, 50, 85),
		Decay = Color3.fromRGB(140, 40, 60),
		Glare = 0,
		Haze = 1.8,
	},
	ColorCorrection = {
		Brightness = -0.02,
		Contrast = 0.25,
		Saturation = -0.15,
		TintColor = Color3.fromRGB(255, 205, 215),
	},
	Sky = { MoonTextureId = Ids.BloodMoon, MoonAngularSize = 28, StarCount = 2500 },
	Vignette = { Texture = Ids.Vignette, Color = Color3.fromRGB(25, 0, 30), Transparency = 0.3 },
	Particles = {
		{
			Texture = Ids.SmokeBlob,
			Rate = 25,
			Speed = NumberRange.new(0.5, 1.5),
			Lifetime = NumberRange.new(8, 12),
			Size = fade(8, 14),
			Transparency = fade(1, 0.75, 0.75, 1),
			Color = solid(Color3.fromRGB(60, 30, 80)),
			LightInfluence = 0.3,
			EmissionDirection = Enum.NormalId.Top,
			SpreadAngle = Vector2.new(60, 60),
			Acceleration = Vector3.new(1, -0.2, 0.5),
			RotSpeed = NumberRange.new(-10, 10),
			AreaSize = Vector3.new(90, 1, 90),
			Offset = Vector3.new(0, 1, 0),
			Anchor = "Ground",
		},
	},
	AmbientSounds = {
		{ SoundId = Ids.GhostWindLoop, Volume = 0.4 },
		{ SoundId = Ids.EerieLoop, Volume = 0.35 },
	},
}

local PlasmaStorm: WeatherFxProfile = {
	Lighting = {
		Brightness = 1.4,
		ClockTime = 14.5,
		Ambient = Color3.fromRGB(110, 50, 120),
		OutdoorAmbient = Color3.fromRGB(150, 70, 160),
		ExposureCompensation = -0.25,
	},
	Atmosphere = {
		Density = 0.5,
		Offset = 0.05,
		Color = Color3.fromRGB(140, 70, 150),
		Decay = Color3.fromRGB(200, 40, 180),
		Glare = 0.5,
		Haze = 2.4,
	},
	ColorCorrection = {
		Brightness = 0,
		Contrast = 0.35,
		Saturation = 0.1,
		TintColor = Color3.fromRGB(255, 205, 250),
	},
	Bloom = { Intensity = 2, Size = 60, Threshold = 1 },
	Particles = {
		{
			Texture = Ids.PlasmaStreak,
			Rate = 120,
			Speed = NumberRange.new(40, 60),
			Lifetime = NumberRange.new(1, 1.5),
			Size = fade(1.2),
			Transparency = fade(0.2, 0.2, 1),
			Color = gradient(Color3.fromRGB(255, 110, 240), Color3.fromRGB(160, 30, 200)),
			LightEmission = 1,
			LightInfluence = 0,
			Brightness = 3,
			Orientation = Enum.ParticleOrientation.VelocityParallel,
			EmissionDirection = Enum.NormalId.Bottom,
			SpreadAngle = Vector2.new(30, 30),
			Acceleration = Vector3.new(60, 0, 20),
			AreaSize = Vector3.new(90, 1, 90),
			Offset = Vector3.new(-30, 35, 0),
			Anchor = "Camera",
		},
		{
			Texture = Ids.SoftDot,
			Rate = 60,
			Speed = NumberRange.new(1, 3),
			Lifetime = NumberRange.new(2, 4),
			Size = fade(0, 0.3, 0),
			Transparency = fade(0),
			Color = gradient(Color3.fromRGB(255, 160, 250), Color3.fromRGB(200, 60, 255)),
			LightEmission = 1,
			LightInfluence = 0,
			Brightness = 3,
			SpreadAngle = Vector2.new(180, 180),
			AreaSize = Vector3.new(70, 25, 70),
			Offset = Vector3.new(0, 6, 0),
			Anchor = "Camera",
		},
	},
	Lightning = {
		Interval = NumberRange.new(3, 7),
		Bolt = withOverrides(BASE_BOLT, {
			Chance = 0.9,
			Style = withOverrides(BASE_BOLT_STYLE, {
				CoreColor = Color3.fromRGB(255, 220, 255),
				GlowColor = Color3.fromRGB(255, 90, 230),
			}),
		}),
		FlashBrightness = 0.45,
		FlashTint = Color3.fromRGB(255, 170, 240),
		FlashFadeTime = 0.3,
		DoubleFlashChance = 0.5,
		DoubleFlashGap = 0.1,
		ThunderDelay = NumberRange.new(0, 0.3),
		ThunderSoundIds = Ids.PlasmaZap,
		ThunderVolume = 0.7,
	},
	AmbientSounds = {
		{ SoundId = Ids.PlasmaWindLoop, Volume = 0.4 },
		{ SoundId = Ids.ElectricHumLoop, Volume = 0.15 },
	},
}

WeatherFxConfig.Profiles = {
	Thunderstorm = Thunderstorm,
	HeavyRain = HeavyRain,
	Heatwave = Heatwave,
	Aurora = Aurora,
	Radiation = Radiation,
	LunarEclipse = LunarEclipse,
	PlasmaStorm = PlasmaStorm,
} :: { [string]: WeatherFxProfile }

return WeatherFxConfig
