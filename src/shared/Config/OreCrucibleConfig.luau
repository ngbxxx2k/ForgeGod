--!strict

export type StateMap = { Idle: number, Active: number, Max: number }
export type ColorMap = { Idle: Color3, Active: Color3, Max: Color3 }

export type EmitterSpec = {
	Key: string,
	Anchor: string,
	Rates: StateMap?,
	Burst: number?,
	Properties: { [string]: any },
}

export type LightSpec = {
	Key: string,
	Anchor: string,
	Color: Color3,
	Brightness: StateMap,
	Range: StateMap,
	Flicker: number,
}

export type SoundSpec = {
	Key: string,
	Id: string,
	Anchor: string,
	Volume: number,
	Looped: boolean,
	State: string,
}

export type OrbitSpec = {
	Radius: number,
	Height: number,
	TiltX: number,
	TiltZ: number,
	Speed: number,
}

local OreCrucibleConfig = {}

OreCrucibleConfig.Tag = "OreCrucible"
OreCrucibleConfig.StateAttribute = "ItemState"

OreCrucibleConfig.States = {
	Idle = "Idle",
	Active = "Active",
	Max = "Max",
}

OreCrucibleConfig.Cycle = {
	{ State = "Idle", Duration = 20 },
	{ State = "Active", Duration = 8 },
	{ State = "Max", Duration = 4 },
}

OreCrucibleConfig.PollInterval = 0.25

OreCrucibleConfig.PartNames = {
	Body = "Crucible",
	Lava = "Lava_Glow",
	Rune = "Rune_Glow",
	Vent = "Vent_Glow",
}

OreCrucibleConfig.BoneNames = {
	Lava = "VFX_Lava",
	Top = "VFX_Top",
	Grate = "VFX_Grate",
	BackVent = "VFX_BackVent",
	Base = "VFX_Base",
}

OreCrucibleConfig.AnimationIds = {
	Idle = "rbxassetid://117359623468463",
	Active = "rbxassetid://83981730592817",
	Max = "rbxassetid://82994463595831",
}

OreCrucibleConfig.StudioKeyframesFolder = "OreCrucibleKeyframes"

OreCrucibleConfig.AnimationFadeTimes = {
	Idle = 2.5,
	Active = 1.2,
	Max = 0.6,
} :: StateMap

OreCrucibleConfig.IconId = "rbxassetid://128457679985428"

OreCrucibleConfig.SurfaceMaps = {
	ColorMap = "rbxassetid://105707820141450",
	NormalMap = "rbxassetid://111947881787911",
	RoughnessMap = "rbxassetid://109315329716509",
	MetalnessMap = "rbxassetid://87111297477456",
}

OreCrucibleConfig.Textures = {
	Ember = "rbxassetid://105087483312654",
	Spark = "rbxassetid://135622153420206",
	Droplet = "rbxassetid://137027728844221",
	Bubble = "rbxassetid://85075524619434",
	Smoke = "rbxassetid://92861015773380",
	Fire = "rbxassetid://113735401677355",
	Trail = "rbxassetid://127170178415103",
	LavaVeins = "rbxassetid://117046629968845",
	FloorCracks = "rbxassetid://130112349730731",
}

OreCrucibleConfig.LavaVolume = {
	Size = Vector3.new(3.4, 0.1, 3.4),
	Lift = 0.08,
}

OreCrucibleConfig.SetupRetries = 10
OreCrucibleConfig.SetupRetryDelay = 1

OreCrucibleConfig.CullDistance = 160
OreCrucibleConfig.CullCheckInterval = 0.5
OreCrucibleConfig.BlendRate = 1.6

OreCrucibleConfig.GlowColors = {
	Lava = {
		Idle = Color3.fromHex("B03C06"),
		Active = Color3.fromHex("D8520A"),
		Max = Color3.fromHex("F06A10"),
	},
	Rune = {
		Idle = Color3.fromHex("A85A10"),
		Active = Color3.fromHex("E8A018"),
		Max = Color3.fromHex("F8C830"),
	},
	Vent = {
		Idle = Color3.fromHex("8A2806"),
		Active = Color3.fromHex("C8400A"),
		Max = Color3.fromHex("E85A12"),
	},
} :: { [string]: ColorMap }

OreCrucibleConfig.Lights = {
	{
		Key = "LavaLight",
		Anchor = "LavaCenter",
		Color = Color3.fromHex("FF8A2A"),
		Brightness = { Idle = 0.8, Active = 1.6, Max = 2.8 },
		Range = { Idle = 10, Active = 13, Max = 18 },
		Flicker = 0.12,
	},
	{
		Key = "GrateLight",
		Anchor = "Grate",
		Color = Color3.fromHex("FF6A1A"),
		Brightness = { Idle = 0.4, Active = 0.8, Max = 1.4 },
		Range = { Idle = 6, Active = 7, Max = 9 },
		Flicker = 0.2,
	},
} :: { LightSpec }

OreCrucibleConfig.FloorCracks = {
	Size = 13,
	Thickness = 0.05,
	Color = Color3.fromHex("FF6A14"),
	Transparency = { Idle = 1, Active = 0.5, Max = 0.1 },
}

OreCrucibleConfig.SmokeColors = {
	Idle = ColorSequence.new(Color3.fromHex("6A5A5C"), Color3.fromHex("4A3E40")),
	Active = ColorSequence.new(Color3.fromHex("A0583E"), Color3.fromHex("4E4042")),
	Max = ColorSequence.new(Color3.fromHex("C8603A"), Color3.fromHex("5A4446")),
} :: { [string]: ColorSequence }

local textures = OreCrucibleConfig.Textures
local fireColor = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHex("FFE680")),
	ColorSequenceKeypoint.new(0.45, Color3.fromHex("FF8A1A")),
	ColorSequenceKeypoint.new(1, Color3.fromHex("C2380A")),
})
local emberColor = ColorSequence.new(Color3.fromHex("FFD27A"), Color3.fromHex("FF6A14"))
local dropColor = ColorSequence.new(Color3.fromHex("FFD040"), Color3.fromHex("FF6A10"))

OreCrucibleConfig.Emitters = {
	{
		Key = "Bubbles",
		Anchor = "LavaVolume",
		Rates = { Idle = 6, Active = 14, Max = 24 },
		Properties = {
			Texture = textures.Bubble,
			Color = ColorSequence.new(Color3.fromHex("FFD25A")),
			LightEmission = 0.6,
			Size = NumberSequence.new(0.15, 0.8),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.2),
				NumberSequenceKeypoint.new(0.7, 0.3),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Lifetime = NumberRange.new(0.35, 0.6),
			Speed = NumberRange.new(0.01, 0.02),
			Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		},
	},
	{
		Key = "LavaVeins",
		Anchor = "LavaVolume",
		Rates = { Idle = 1.2, Active = 2, Max = 3 },
		Properties = {
			Texture = textures.LavaVeins,
			Color = ColorSequence.new(Color3.fromHex("FFE680")),
			LightEmission = 0.8,
			Size = NumberSequence.new(2.2, 3.2),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.3, 0.35),
				NumberSequenceKeypoint.new(0.7, 0.35),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Lifetime = NumberRange.new(3, 5),
			Speed = NumberRange.new(0.01),
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-12, 12),
			Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		},
	},
	{
		Key = "Embers",
		Anchor = "LavaVolume",
		Rates = { Idle = 5, Active = 18, Max = 40 },
		Properties = {
			Texture = textures.Ember,
			Color = emberColor,
			LightEmission = 0.6,
			Size = NumberSequence.new(0.22, 0.05),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.8, 0.2),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Lifetime = NumberRange.new(1.5, 3),
			Speed = NumberRange.new(2, 5),
			Acceleration = Vector3.new(0, 1.5, 0),
			Drag = 0.8,
			SpreadAngle = Vector2.new(25, 25),
		},
	},
	{
		Key = "Sparks",
		Anchor = "LavaVolume",
		Rates = { Idle = 0, Active = 6, Max = 14 },
		Properties = {
			Texture = textures.Spark,
			Color = emberColor,
			LightEmission = 0.6,
			Size = NumberSequence.new(0.35, 0),
			Lifetime = NumberRange.new(0.4, 0.8),
			Speed = NumberRange.new(6, 10),
			Acceleration = Vector3.new(0, -12, 0),
			SpreadAngle = Vector2.new(35, 35),
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-180, 180),
		},
	},
	{
		Key = "Droplets",
		Anchor = "LavaVolume",
		Rates = { Idle = 0, Active = 7, Max = 16 },
		Properties = {
			Texture = textures.Droplet,
			Color = dropColor,
			LightEmission = 0.4,
			Size = NumberSequence.new(0.6, 0.3),
			Lifetime = NumberRange.new(0.7, 1.1),
			Speed = NumberRange.new(8, 13),
			Acceleration = Vector3.new(0, -32, 0),
			SpreadAngle = Vector2.new(28, 28),
			Orientation = Enum.ParticleOrientation.VelocityParallel,
		},
	},
	{
		Key = "Flames",
		Anchor = "LavaVolume",
		Rates = { Idle = 0, Active = 14, Max = 34 },
		Properties = {
			Texture = textures.Fire,
			FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4,
			FlipbookMode = Enum.ParticleFlipbookMode.Loop,
			FlipbookFramerate = NumberRange.new(24, 30),
			Color = fireColor,
			LightEmission = 0.1,
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1.4),
				NumberSequenceKeypoint.new(0.5, 2),
				NumberSequenceKeypoint.new(1, 0.6),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.15),
				NumberSequenceKeypoint.new(0.7, 0.3),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Lifetime = NumberRange.new(0.5, 0.8),
			Speed = NumberRange.new(1.5, 3),
			SpreadAngle = Vector2.new(8, 8),
			Rotation = NumberRange.new(-10, 10),
		},
	},
	{
		Key = "FlamePillar",
		Anchor = "LavaCenter",
		Rates = { Idle = 0, Active = 0, Max = 26 },
		Properties = {
			Texture = textures.Fire,
			FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4,
			FlipbookMode = Enum.ParticleFlipbookMode.Loop,
			FlipbookFramerate = NumberRange.new(24, 30),
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHex("FFF6C8")),
				ColorSequenceKeypoint.new(0.4, Color3.fromHex("FFB040")),
				ColorSequenceKeypoint.new(1, Color3.fromHex("FF5A14")),
			}),
			LightEmission = 0.15,
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 2.6),
				NumberSequenceKeypoint.new(0.5, 3.6),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.1),
				NumberSequenceKeypoint.new(0.75, 0.3),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Lifetime = NumberRange.new(0.6, 0.9),
			Speed = NumberRange.new(5, 8),
			SpreadAngle = Vector2.new(6, 6),
		},
	},
	{
		Key = "Smoke",
		Anchor = "LavaCenter",
		Rates = { Idle = 3, Active = 6, Max = 11 },
		Properties = {
			Texture = textures.Smoke,
			FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4,
			FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
			LightEmission = 0,
			LightInfluence = 0.7,
			Size = NumberSequence.new(1.6, 5.5),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.15, 0.45),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Lifetime = NumberRange.new(3.5, 5.5),
			Speed = NumberRange.new(2, 3.5),
			Acceleration = Vector3.new(0, 0.6, 0),
			Drag = 0.4,
			SpreadAngle = Vector2.new(12, 12),
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-18, 18),
		},
	},
	{
		Key = "GrateFlames",
		Anchor = "Grate",
		Rates = { Idle = 3, Active = 9, Max = 16 },
		Properties = {
			Texture = textures.Fire,
			FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4,
			FlipbookMode = Enum.ParticleFlipbookMode.Loop,
			FlipbookFramerate = NumberRange.new(24, 30),
			Color = fireColor,
			LightEmission = 0.1,
			Size = NumberSequence.new(0.7, 0.15),
			Lifetime = NumberRange.new(0.35, 0.6),
			Speed = NumberRange.new(1, 2),
			SpreadAngle = Vector2.new(12, 12),
		},
	},
	{
		Key = "VentEmbers",
		Anchor = "BackVent",
		Rates = { Idle = 1, Active = 4, Max = 8 },
		Properties = {
			Texture = textures.Ember,
			Color = emberColor,
			LightEmission = 0.6,
			Size = NumberSequence.new(0.18, 0.04),
			Lifetime = NumberRange.new(1, 2),
			Speed = NumberRange.new(1, 2.5),
			Acceleration = Vector3.new(0, 1, 0),
			SpreadAngle = Vector2.new(30, 30),
		},
	},
	{
		Key = "BurstDroplets",
		Anchor = "LavaVolume",
		Burst = 36,
		Properties = {
			Texture = textures.Droplet,
			Color = dropColor,
			LightEmission = 0.4,
			Size = NumberSequence.new(0.45, 0.2),
			Lifetime = NumberRange.new(0.9, 1.4),
			Speed = NumberRange.new(12, 20),
			Acceleration = Vector3.new(0, -30, 0),
			SpreadAngle = Vector2.new(40, 40),
			Orientation = Enum.ParticleOrientation.VelocityParallel,
		},
	},
	{
		Key = "BurstSparks",
		Anchor = "LavaVolume",
		Burst = 50,
		Properties = {
			Texture = textures.Spark,
			Color = emberColor,
			LightEmission = 0.6,
			Size = NumberSequence.new(0.5, 0),
			Lifetime = NumberRange.new(0.5, 1.1),
			Speed = NumberRange.new(10, 18),
			Acceleration = Vector3.new(0, -10, 0),
			SpreadAngle = Vector2.new(60, 60),
			Rotation = NumberRange.new(0, 360),
		},
	},
	{
		Key = "BurstSmoke",
		Anchor = "LavaCenter",
		Burst = 6,
		Properties = {
			Texture = textures.Smoke,
			FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4,
			FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
			Color = ColorSequence.new(Color3.fromHex("D06A40"), Color3.fromHex("5A4446")),
			LightInfluence = 0.6,
			Size = NumberSequence.new(3, 8),
			Transparency = NumberSequence.new(0.35, 1),
			Lifetime = NumberRange.new(1.8, 2.6),
			Speed = NumberRange.new(4, 7),
			SpreadAngle = Vector2.new(35, 35),
			Rotation = NumberRange.new(0, 360),
		},
	},
	{
		Key = "BurstFlash",
		Anchor = "LavaCenter",
		Burst = 1,
		Properties = {
			Texture = textures.Ember,
			Color = ColorSequence.new(Color3.fromHex("FFE6A0")),
			LightEmission = 0.8,
			Size = NumberSequence.new(3, 11),
			Transparency = NumberSequence.new(0, 1),
			Lifetime = NumberRange.new(0.3),
			Speed = NumberRange.new(0),
		},
	},
} :: { EmitterSpec }

OreCrucibleConfig.Orbits = {
	{ Radius = 4.2, Height = 0.4, TiltX = math.rad(22), TiltZ = math.rad(-8), Speed = 2.8 },
	{ Radius = 4.9, Height = 1.1, TiltX = math.rad(-18), TiltZ = math.rad(12), Speed = -2.2 },
} :: { OrbitSpec }

OreCrucibleConfig.OrbitTrail = {
	Width = 0.6,
	Properties = {
		Texture = textures.Trail,
		Lifetime = 0.55,
		Color = ColorSequence.new(Color3.fromHex("FFE07A"), Color3.fromHex("FF5A0A")),
		Transparency = NumberSequence.new(0, 1),
		WidthScale = NumberSequence.new(1, 0.3),
		LightEmission = 0.2,
		LightInfluence = 0,
		FaceCamera = true,
		MinLength = 0.05,
	},
}

OreCrucibleConfig.SoundRollOff = {
	Min = 10,
	Max = 80,
}

OreCrucibleConfig.Sounds = {
	{ Key = "IdleLoop", Id = "", Anchor = "LavaCenter", Volume = 0.35, Looped = true, State = "Idle" },
	{ Key = "ActiveLoop", Id = "", Anchor = "LavaCenter", Volume = 0.55, Looped = true, State = "Active" },
	{ Key = "MaxLoop", Id = "", Anchor = "Top", Volume = 0.8, Looped = true, State = "Max" },
	{ Key = "ActiveStart", Id = "", Anchor = "LavaCenter", Volume = 0.6, Looped = false, State = "Active" },
	{ Key = "MaxBurst", Id = "", Anchor = "Top", Volume = 0.9, Looped = false, State = "Max" },
} :: { SoundSpec }

return OreCrucibleConfig
