--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ForgeFrenzyFxConfig = require(ReplicatedStorage.Shared.Config.ForgeFrenzyFxConfig)
local ForgeStrikeConfig = require(ReplicatedStorage.Shared.Config.ForgeStrikeConfig)
local Rainbow = require(ReplicatedStorage.Shared.Utils.Rainbow)

local FX_ATTACHMENT_NAME = "ForgeSparksFx"
local EMBER_FLICKER_STEPS = 8
local HALF_TURN = 180
local FULL_TURN = 360

export type SparkSet = {
	Attachment: Attachment,
	Base: CFrame,
	Sparks: ParticleEmitter,
	Embers: ParticleEmitter,
	Flare: ParticleEmitter,
	Smoke: ParticleEmitter,
	Dust: ParticleEmitter,
	Light: PointLight,
	FlashToken: number,
	IsRainbow: boolean,
	Palette: { [ParticleEmitter]: ColorSequence },
}

local ForgeSparks = {}

local random = Random.new()
local colors = ForgeStrikeConfig.Colors
local textures = ForgeStrikeConfig.Textures

local function pickInteger(range: NumberRange): number
	return random:NextInteger(math.floor(range.Min), math.floor(range.Max))
end

local function pickNumber(range: NumberRange): number
	return random:NextNumber(range.Min, range.Max)
end

local function shrinkSequence(size: number): NumberSequence
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, size),
		NumberSequenceKeypoint.new(1, 0),
	})
end

local function flickerSequence(): NumberSequence
	local points = { NumberSequenceKeypoint.new(0, 0) }
	for step = 1, EMBER_FLICKER_STEPS - 1 do
		local config = ForgeStrikeConfig.Embers
		local value = if step % 2 == 0 then config.FlickerBright else config.FlickerDim
		table.insert(points, NumberSequenceKeypoint.new(step / EMBER_FLICKER_STEPS, value))
	end
	table.insert(points, NumberSequenceKeypoint.new(1, 1))
	return NumberSequence.new(points)
end

local function newEmitter(parent: Attachment, properties: { [string]: any }): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Enabled = false
	emitter.Rate = 0
	emitter.LightInfluence = 0
	emitter.EmissionDirection = Enum.NormalId.Top
	for key, value in properties do
		(emitter :: any)[key] = value
	end
	emitter.Parent = parent
	return emitter
end

local function createSparks(parent: Attachment): ParticleEmitter
	local config = ForgeStrikeConfig.Sparks
	return newEmitter(parent, {
		Name = "Sparks",
		Texture = textures.Spark,
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		Squash = NumberSequence.new(config.Squash),
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, colors.SparkHot),
			ColorSequenceKeypoint.new(0.12, colors.SparkWarm),
			ColorSequenceKeypoint.new(0.45, colors.SparkOrange),
			ColorSequenceKeypoint.new(1, colors.SparkRed),
		}),
		LightEmission = 1,
		Lifetime = config.Lifetime,
		Speed = config.Speed,
		SpreadAngle = Vector2.new(config.SpreadAngle, config.SpreadAngle),
		Acceleration = Vector3.new(0, -config.Gravity, 0),
		Drag = config.Drag,
		Size = shrinkSequence(config.Size),
	})
end

local function createEmbers(parent: Attachment): ParticleEmitter
	local config = ForgeStrikeConfig.Embers
	return newEmitter(parent, {
		Name = "Embers",
		Texture = textures.Spark,
		Color = ColorSequence.new(colors.SparkWarm, colors.Ember),
		LightEmission = 1,
		Lifetime = config.Lifetime,
		Speed = config.Speed,
		SpreadAngle = Vector2.new(config.SpreadAngle, config.SpreadAngle),
		Acceleration = Vector3.new(0, -config.Gravity, 0),
		Drag = config.Drag,
		Size = shrinkSequence(config.Size),
		Transparency = flickerSequence(),
	})
end

local function createFlare(parent: Attachment): ParticleEmitter
	local config = ForgeStrikeConfig.Flare
	return newEmitter(parent, {
		Name = "Flare",
		Texture = textures.Spark,
		Color = ColorSequence.new(colors.SparkHot, colors.Flash),
		LightEmission = 1,
		Lifetime = config.Lifetime,
		Speed = NumberRange.new(0),
		LockedToPart = true,
		Size = shrinkSequence(config.Size),
	})
end

local function createSmoke(parent: Attachment): ParticleEmitter
	local config = ForgeStrikeConfig.Smoke
	return newEmitter(parent, {
		Name = "Smoke",
		Texture = textures.Smoke,
		Color = ColorSequence.new(colors.Smoke),
		Lifetime = config.Lifetime,
		Speed = config.Speed,
		SpreadAngle = Vector2.new(HALF_TURN, HALF_TURN),
		Acceleration = Vector3.new(0, config.Rise, 0),
		Rotation = NumberRange.new(0, FULL_TURN),
		RotSpeed = NumberRange.new(-config.RotSpeed, config.RotSpeed),
		Size = NumberSequence.new(config.StartSize, config.EndSize),
		Transparency = NumberSequence.new(config.Transparency, 1),
	})
end

local function createDust(parent: Attachment): ParticleEmitter
	local config = ForgeStrikeConfig.Dust
	return newEmitter(parent, {
		Name = "Dust",
		Texture = textures.Spark,
		Color = ColorSequence.new(colors.Dust),
		Lifetime = config.Lifetime,
		Speed = config.Speed,
		SpreadAngle = Vector2.new(config.SpreadAngle, config.SpreadAngle),
		Acceleration = Vector3.new(0, -config.Gravity, 0),
		Size = NumberSequence.new(config.Size),
	})
end

local function createLight(parent: Attachment): PointLight
	local light = Instance.new("PointLight")
	light.Color = colors.Flash
	light.Range = ForgeStrikeConfig.Flash.Range
	light.Brightness = 0
	light.Shadows = false
	light.Parent = parent
	return light
end

local function flash(set: SparkSet)
	local config = ForgeStrikeConfig.Flash
	set.FlashToken += 1
	local token = set.FlashToken
	set.Light.Brightness = pickNumber(config.Brightness)
	task.delay(pickNumber(config.HoldTime), function()
		if set.FlashToken ~= token or set.Light.Parent == nil then
			return
		end
		local info = TweenInfo.new(config.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(set.Light, info, { Brightness = 0 }):Play()
	end)
end

local function randomizeDirection(set: SparkSet)
	local config = ForgeStrikeConfig.Sparks
	local tilt = math.rad(config.TiltJitter)
	local yaw = random:NextNumber(0, 2 * math.pi)
	local pitch = random:NextNumber(-tilt, tilt)
	set.Attachment.CFrame = set.Base * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
	local spread = config.SpreadAngle + random:NextNumber(-config.SpreadJitter, config.SpreadJitter)
	set.Sparks.SpreadAngle = Vector2.new(spread, spread)
end

local function paintRainbow(set: SparkSet)
	local config = ForgeFrenzyFxConfig
	local steps = config.GradientSteps
	for emitter in set.Palette do
		emitter.Color = Rainbow.Sequence(random:NextNumber(), steps, config.Saturation, config.Brightness)
	end
	set.Light.Color = Rainbow.At(random:NextNumber(), config.Sparks.LightSaturation, config.Brightness)
end

local function restorePalette(set: SparkSet)
	for emitter, sequence in set.Palette do
		emitter.Color = sequence
	end
	set.Light.Color = colors.Flash
end

local function buildPalette(emitters: { ParticleEmitter }): { [ParticleEmitter]: ColorSequence }
	local palette = {}
	for _, emitter in emitters do
		palette[emitter] = emitter.Color
	end
	return palette
end

function ForgeSparks.Create(impact: Attachment): SparkSet?
	local parent = impact.Parent
	if parent == nil or not parent:IsA("BasePart") then
		warn("[ForgeSparks] ImpactPoint must be inside a BasePart")
		return nil
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = FX_ATTACHMENT_NAME
	attachment.CFrame = impact.CFrame
	attachment.Parent = parent
	local sparks = createSparks(attachment)
	local embers = createEmbers(attachment)
	local flare = createFlare(attachment)
	return {
		Attachment = attachment,
		Base = impact.CFrame,
		Sparks = sparks,
		Embers = embers,
		Flare = flare,
		Smoke = createSmoke(attachment),
		Dust = createDust(attachment),
		Light = createLight(attachment),
		FlashToken = 0,
		IsRainbow = false,
		Palette = buildPalette({ sparks, embers, flare }),
	}
end

function ForgeSparks.Burst(set: SparkSet)
	if set.Attachment.Parent == nil then
		return
	end
	randomizeDirection(set)
	if set.IsRainbow then
		paintRainbow(set)
	end
	set.Sparks:Emit(pickInteger(ForgeStrikeConfig.Sparks.Count))
	set.Embers:Emit(pickInteger(ForgeStrikeConfig.Embers.Count))
	set.Flare:Emit(1)
	set.Smoke:Emit(pickInteger(ForgeStrikeConfig.Smoke.Count))
	set.Dust:Emit(pickInteger(ForgeStrikeConfig.Dust.Count))
	flash(set)
end

function ForgeSparks.SetRainbow(set: SparkSet, isRainbow: boolean)
	set.IsRainbow = isRainbow
	if not isRainbow then
		restorePalette(set)
	end
end

function ForgeSparks.Destroy(set: SparkSet)
	set.FlashToken += 1
	set.Attachment:Destroy()
end

return ForgeSparks
