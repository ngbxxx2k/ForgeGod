--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local WeatherFxConfig = require(ReplicatedStorage.Shared.Config.WeatherFxConfig)
local WeatherFxTypes = require(ReplicatedStorage.Shared.Types.WeatherFxTypes)

type AuroraProfile = WeatherFxTypes.AuroraProfile

type Band = {
	Beam: Beam,
	Phase: number,
}

type AuroraSet = {
	Profile: AuroraProfile,
	Anchor: Part,
	Bands: { Band },
	Connection: RBXScriptConnection,
	Level: number,
	TargetLevel: number,
	FadeSpeed: number,
}

local ANCHOR_SIZE = Vector3.new(0.2, 0.2, 0.2)
local HIDDEN = 1
local ARC_CENTER = 0
local ARC_SPREAD = math.rad(140)
local FULL_TURN = math.pi * 2
local END_FADE = 0.15
local WIDTH_PULSE = 0.15

local WeatherAurora = {}

local random = Random.new()
local current: AuroraSet? = nil

local function createAnchor(): Part
	local anchor = Instance.new("Part")
	anchor.Name = WeatherFxConfig.AuroraFolderName
	anchor.Size = ANCHOR_SIZE
	anchor.Transparency = HIDDEN
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CastShadow = false
	anchor.Archivable = false
	return anchor
end

local function createAttachment(anchor: Part, position: Vector3): Attachment
	local attachment = Instance.new("Attachment")
	attachment.Position = position
	attachment.Parent = anchor
	return attachment
end

local function createBeam(anchor: Part, profile: AuroraProfile): Beam
	local angle = ARC_CENTER + random:NextNumber(-ARC_SPREAD, ARC_SPREAD) / 2
	local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
	local tangent = Vector3.new(-direction.Z, 0, direction.X)
	local distance = random:NextNumber(profile.Distance.Min, profile.Distance.Max)
	local center = direction * distance + Vector3.new(0, profile.Height, 0)
	local halfLength = tangent * profile.Length / 2
	local beam = Instance.new("Beam")
	beam.Attachment0 = createAttachment(anchor, center - halfLength)
	beam.Attachment1 = createAttachment(anchor, center + halfLength)
	beam.Texture = profile.Texture
	beam.TextureMode = Enum.TextureMode.Stretch
	beam.TextureSpeed = profile.TextureSpeed
	beam.Color = profile.Colors
	beam.Brightness = profile.Brightness
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.FaceCamera = true
	beam.Segments = 20
	beam.Width0 = profile.Width
	beam.Width1 = profile.Width
	beam.Parent = anchor
	return beam
end

local function transparencyFor(profile: AuroraProfile, level: number): NumberSequence
	local visible = HIDDEN - (HIDDEN - profile.Transparency) * level
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, HIDDEN),
		NumberSequenceKeypoint.new(END_FADE, visible),
		NumberSequenceKeypoint.new(1 - END_FADE, visible),
		NumberSequenceKeypoint.new(1, HIDDEN),
	})
end

local function updateBands(set: AuroraSet, now: number)
	local profile = set.Profile
	local transparency = transparencyFor(profile, set.Level)
	for _, band in set.Bands do
		local wave = math.sin(now * profile.SwaySpeed * FULL_TURN + band.Phase)
		band.Beam.CurveSize0 = profile.CurveSize * wave + profile.SwayAmount
		band.Beam.CurveSize1 = -profile.CurveSize * wave + profile.SwayAmount
		local width = profile.Width * (1 + WIDTH_PULSE * wave)
		band.Beam.Width0 = width
		band.Beam.Width1 = width
		band.Beam.Transparency = transparency
	end
end

local function step(set: AuroraSet, dt: number)
	local camera = Workspace.CurrentCamera
	if camera then
		set.Anchor.CFrame = CFrame.new(camera.CFrame.Position)
	end
	local delta = set.TargetLevel - set.Level
	set.Level += math.clamp(delta, -set.FadeSpeed * dt, set.FadeSpeed * dt)
	updateBands(set, os.clock())
	if set.TargetLevel == 0 and set.Level <= 0 then
		set.Connection:Disconnect()
		set.Anchor:Destroy()
	end
end

function WeatherAurora.Start(profile: AuroraProfile, duration: number)
	WeatherAurora.Stop(duration)
	local anchor = createAnchor()
	local set: AuroraSet = {
		Profile = profile,
		Anchor = anchor,
		Bands = {},
		Connection = nil :: any,
		Level = 0,
		TargetLevel = 1,
		FadeSpeed = 1 / math.max(duration, 1e-3),
	}
	for _ = 1, profile.Count do
		local phase = random:NextNumber(0, FULL_TURN)
		table.insert(set.Bands, { Beam = createBeam(anchor, profile), Phase = phase })
	end
	set.Connection = RunService.RenderStepped:Connect(function(dt: number)
		step(set, dt)
	end)
	anchor.Parent = Workspace
	current = set
end

function WeatherAurora.Stop(duration: number)
	local set = current
	if set == nil then
		return
	end
	current = nil
	set.TargetLevel = 0
	set.FadeSpeed = 1 / math.max(duration, 1e-3)
end

return WeatherAurora
