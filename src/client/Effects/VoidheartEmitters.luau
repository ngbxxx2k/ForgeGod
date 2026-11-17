--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VoidheartFxConfig = require(ReplicatedStorage.Shared.Config.VoidheartFxConfig)
local VoidheartMotion = require(script.Parent.VoidheartMotion)
local VoidheartRig = require(script.Parent.VoidheartRig)

local FOLDER_NAME = "VoidheartFxRuntime"
local VOLUME_NAME = "VoidheartFxVolume"
local FULL_TURN = 360

type ScaledEmitter = { Emitter: ParticleEmitter, Min: number, Max: number }
type Volume = { Part: BasePart, Offset: CFrame }

export type EmitterSet = {
	Folder: Folder,
	Owned: { Instance },
	Volumes: { Volume },
	Scaled: { ScaledEmitter },
	CoreLight: PointLight?,
	BladeGlows: { BasePart },
	FlickerClock: number,
}

local VoidheartEmitters = {}

local random = Random.new()
local colors = VoidheartFxConfig.Colors
local textures = VoidheartFxConfig.Textures

local function lerp(from: number, to: number, alpha: number): number
	return from + (to - from) * alpha
end

local function fadeSequence(peak: number): NumberSequence
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, peak),
		NumberSequenceKeypoint.new(1, 1),
	})
end

local function newEmitter(parent: Instance, properties: { [string]: any }): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	for key, value in properties do
		(emitter :: any)[key] = value
	end
	emitter.Parent = parent
	return emitter
end

local function track(set: EmitterSet, emitter: ParticleEmitter, minRate: number, maxRate: number)
	table.insert(set.Scaled, { Emitter = emitter, Min = minRate, Max = maxRate })
end

local function newVolume(set: EmitterSet, size: Vector3, shape: Enum.PartType, offset: CFrame): Part
	local part = Instance.new("Part")
	part.Name = VOLUME_NAME
	part.Shape = shape
	part.Size = size
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Parent = set.Folder
	table.insert(set.Volumes, { Part = part, Offset = offset })
	return part
end

local function newAttachment(set: EmitterSet, parent: BasePart, worldPosition: Vector3): Attachment
	local attachment = Instance.new("Attachment")
	attachment.Name = FOLDER_NAME
	attachment.Parent = parent
	attachment.WorldPosition = worldPosition
	table.insert(set.Owned, attachment)
	return attachment
end

local function addCoreHalo(set: EmitterSet, rig: VoidheartRig.Rig)
	local halo = VoidheartFxConfig.CoreHalo
	local size = halo.SizeFraction * rig.Length
	local core = rig.Movers.Core.Parts[1]
	local center = newAttachment(set, core, core.Position)
	local shared = {
		Texture = textures.Smoke,
		Lifetime = NumberRange.new(halo.Lifetime),
		Rate = halo.Rate,
		Speed = NumberRange.new(0),
		LockedToPart = true,
		LightInfluence = 0,
		Rotation = NumberRange.new(0, FULL_TURN),
		RotSpeed = NumberRange.new(-FULL_TURN / 8, FULL_TURN / 8),
	}
	local dark = table.clone(shared)
	dark.Color, dark.LightEmission = ColorSequence.new(colors.Dark, colors.Void), 0
	dark.Size, dark.Transparency = NumberSequence.new(size), fadeSequence(halo.Transparency)
	newEmitter(center, dark)
	local glow = table.clone(shared)
	glow.Color, glow.LightEmission = ColorSequence.new(colors.Core, colors.Glow), 1
	glow.Size = NumberSequence.new(size * halo.GlowScale)
	glow.Transparency = fadeSequence(halo.Transparency)
	newEmitter(center, glow)
end

local function addCoreLight(set: EmitterSet, rig: VoidheartRig.Rig)
	local light = Instance.new("PointLight")
	light.Color = colors.Glow
	light.Range = VoidheartFxConfig.CoreLight.RangeFraction * rig.Length
	light.Brightness = VoidheartFxConfig.CoreLight.BrightnessMin
	light.Parent = rig.Movers.Core.Parts[1]
	table.insert(set.Owned, light)
	set.CoreLight = light
end

local function addInwardDust(set: EmitterSet, rig: VoidheartRig.Rig)
	local dust = VoidheartFxConfig.InwardDust
	local radius = dust.RadiusFraction * rig.Length
	local offset = CFrame.new(rig.Movers.Core.Pivot)
	local volume = newVolume(set, Vector3.one * radius * 2, Enum.PartType.Ball, offset)
	track(set, newEmitter(volume, {
		Shape = Enum.ParticleEmitterShape.Sphere,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
		Speed = NumberRange.new(radius / dust.Lifetime),
		Lifetime = NumberRange.new(dust.Lifetime),
		Size = NumberSequence.new(dust.SizeFraction * rig.Length, 0),
		Texture = textures.Sparkle,
		Color = ColorSequence.new(colors.Edge, colors.Glow),
		LightEmission = 1,
		LockedToPart = true,
	}), dust.RateMin, dust.RateMax)
end

local function addGripFlow(set: EmitterSet, rig: VoidheartRig.Rig, frame: CFrame)
	local flow = VoidheartFxConfig.GripFlow
	local height = VoidheartRig.HalfExtentAlong(rig.Root, frame.UpVector) * 2
	local width = flow.SizeFraction * rig.Length * 2
	local size = Vector3.new(width, height, width)
	local volume = newVolume(set, size, Enum.PartType.Block, CFrame.new())
	track(set, newEmitter(volume, {
		EmissionDirection = Enum.NormalId.Top,
		Speed = NumberRange.new(flow.SpeedFraction * rig.Length),
		Lifetime = NumberRange.new(flow.Lifetime),
		Size = NumberSequence.new(flow.SizeFraction * rig.Length, 0),
		Texture = textures.Sparkle,
		Color = ColorSequence.new(colors.Glow, colors.Edge),
		LightEmission = 1,
		LockedToPart = true,
	}), flow.RateMin, flow.RateMax)
end

local function addBladeShards(set: EmitterSet, rig: VoidheartRig.Rig)
	local cracks = VoidheartFxConfig.BladeCracks
	for _, blade in VoidheartFxConfig.Blades do
		local mover = rig.Movers[blade.Name]
		local emitter = newEmitter(mover.Parts[1], {
			SpreadAngle = Vector2.new(FULL_TURN / 2, FULL_TURN / 2),
			Speed = NumberRange.new(cracks.ShardSizeFraction * rig.Length),
			Drag = cracks.ShardDrag,
			Lifetime = NumberRange.new(cracks.ShardLifetime),
			Size = NumberSequence.new(cracks.ShardSizeFraction * rig.Length, 0),
			Rotation = NumberRange.new(0, FULL_TURN),
			Texture = textures.Sparkle,
			Color = ColorSequence.new(colors.Edge),
			LightEmission = 1,
		})
		track(set, emitter, cracks.ShardRateMin, cracks.ShardRateMax)
		table.insert(set.Owned, emitter)
		table.insert(set.BladeGlows, mover.Parts[2])
	end
end

local function addBodyVolume(set: EmitterSet, rig: VoidheartRig.Rig): Part
	local radius = VoidheartFxConfig.Mist.RadiusFraction * rig.Length
	local centerHeight = (rig.BottomHeight + rig.TopHeight) / 2
	local size = Vector3.new(radius * 2, rig.Length, radius * 2)
	return newVolume(set, size, Enum.PartType.Block, CFrame.new(0, centerHeight, 0))
end

local function addMistAndMotes(set: EmitterSet, rig: VoidheartRig.Rig)
	local mist, motes = VoidheartFxConfig.Mist, VoidheartFxConfig.Motes
	local volume = addBodyVolume(set, rig)
	track(set, newEmitter(volume, {
		Texture = textures.Smoke,
		Color = ColorSequence.new(colors.Void, colors.Dark),
		LightEmission = 0,
		LightInfluence = 0,
		Transparency = fadeSequence(mist.Transparency),
		Size = NumberSequence.new(mist.SizeFraction * rig.Length),
		Speed = NumberRange.new(0),
		Lifetime = NumberRange.new(mist.Lifetime),
		Rotation = NumberRange.new(0, FULL_TURN),
		RotSpeed = NumberRange.new(-FULL_TURN / 12, FULL_TURN / 12),
	}), mist.RateMin, mist.RateMax)
	track(set, newEmitter(volume, {
		Texture = textures.Sparkle,
		Color = ColorSequence.new(colors.Edge),
		LightEmission = 1,
		Transparency = fadeSequence(0),
		Size = NumberSequence.new(motes.SizeFraction * rig.Length),
		Speed = NumberRange.new(0),
		Acceleration = Vector3.new(0, motes.RiseFraction * rig.Length, 0),
		Lifetime = NumberRange.new(motes.Lifetime),
	}), motes.RateMin, motes.RateMax)
end

local function addRingTrails(set: EmitterSet, rig: VoidheartRig.Rig, frame: CFrame)
	local config = VoidheartFxConfig.RingTrail
	local width = config.WidthFraction * rig.Length
	for _, ring in VoidheartFxConfig.Rings do
		local mover = rig.Movers[ring.Name]
		local part = mover.Parts[1]
		local center = frame:PointToWorldSpace(mover.Pivot)
		local radius = VoidheartRig.HalfExtentAlong(part, frame.RightVector)
		for _, direction in { frame.RightVector, -frame.RightVector } do
			local trail = Instance.new("Trail")
			trail.Attachment0 = newAttachment(set, part, center + direction * (radius + width))
			trail.Attachment1 = newAttachment(set, part, center + direction * (radius - width))
			trail.Lifetime = config.Lifetime
			trail.Color = ColorSequence.new(colors.Edge, colors.Glow)
			trail.LightEmission = 1
			trail.Transparency = NumberSequence.new(0.2, 1)
			trail.Parent = part
			table.insert(set.Owned, trail)
		end
	end
end

local function updateBladeFlicker(set: EmitterSet, dt: number, surge: number)
	local cracks = VoidheartFxConfig.BladeCracks
	set.FlickerClock += dt
	if set.FlickerClock < 1 / cracks.FlickerRate then
		return
	end
	set.FlickerClock = 0
	local maxTransparency = math.max(lerp(cracks.FlickerMax, cracks.FlickerMin, surge), cracks.FlickerMin)
	for _, glow in set.BladeGlows do
		glow.Transparency = random:NextNumber(cracks.FlickerMin, maxTransparency)
	end
end

function VoidheartEmitters.Create(rig: VoidheartRig.Rig): EmitterSet
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	local set: EmitterSet = {
		Folder = folder,
		Owned = {},
		Volumes = {},
		Scaled = {},
		CoreLight = nil,
		BladeGlows = {},
		FlickerClock = 0,
	}
	local frame = VoidheartRig.GetFrame(rig)
	addCoreHalo(set, rig)
	addCoreLight(set, rig)
	addInwardDust(set, rig)
	addGripFlow(set, rig, frame)
	addBladeShards(set, rig)
	addMistAndMotes(set, rig)
	addRingTrails(set, rig, frame)
	folder.Parent = rig.Model
	return set
end

function VoidheartEmitters.Update(set: EmitterSet, frame: CFrame, input: VoidheartMotion.StepInput)
	for _, volume in set.Volumes do
		volume.Part.CFrame = frame * volume.Offset
	end
	for _, scaled in set.Scaled do
		scaled.Emitter.Rate = lerp(scaled.Min, scaled.Max, input.Energy)
	end
	local light = set.CoreLight
	if light then
		local config = VoidheartFxConfig.CoreLight
		light.Brightness = lerp(config.BrightnessMin, config.BrightnessMax, input.Energy)
	end
	updateBladeFlicker(set, input.Dt, input.Surge)
end

function VoidheartEmitters.Destroy(set: EmitterSet)
	for _, instance in set.Owned do
		instance:Destroy()
	end
	for _, glow in set.BladeGlows do
		glow.Transparency = 0
	end
	set.Folder:Destroy()
end

return VoidheartEmitters
