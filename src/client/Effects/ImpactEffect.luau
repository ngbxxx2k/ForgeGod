--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ForgeAnimationConfig = require(ReplicatedStorage.Shared.Config.ForgeAnimationConfig)
local RevealCleanup = require(script.Parent.RevealCleanup)

local PART_NAME = "ForgeRevealImpact"
local START_SIZE = 0.2
local QUARTER_TURN = math.pi / 2

local ImpactEffect = {}

local function createPart(shape: Enum.PartType, material: Enum.Material, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = PART_NAME
	part.Shape = shape
	part.Material = material
	part.Color = color
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	return part
end

local function tween(target: Instance, duration: number, goal: { [string]: any }, cleanup: RevealCleanup.Cleanup): Tween
	local info = TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local created = TweenService:Create(target, info, goal)
	RevealCleanup.Add(cleanup, created)
	created:Play()
	return created
end

local function destroyLater(instance: Instance, delay: number)
	task.delay(delay, function()
		instance:Destroy()
	end)
end

local function spawnPart(part: Part, cleanup: RevealCleanup.Cleanup)
	part.Parent = Workspace
	RevealCleanup.Add(cleanup, part)
end

local function playRing(center: Vector3, color: Color3, radius: number, cleanup: RevealCleanup.Cleanup)
	local config = ForgeAnimationConfig.Impact
	local ring = createPart(Enum.PartType.Cylinder, Enum.Material.Neon, color)
	ring.Size = Vector3.new(config.RingThickness, START_SIZE, START_SIZE)
	ring.CFrame = CFrame.new(center) * CFrame.Angles(0, 0, QUARTER_TURN)
	ring.Transparency = config.RingTransparency
	spawnPart(ring, cleanup)
	local diameter = radius * 2
	tween(ring, config.RingTime, {
		Size = Vector3.new(config.RingThickness, diameter, diameter),
		Transparency = 1,
	}, cleanup)
	destroyLater(ring, config.RingTime)
end

local function playBubble(center: Vector3, color: Color3, magnitude: number, cleanup: RevealCleanup.Cleanup)
	local config = ForgeAnimationConfig.Impact
	local bubble = createPart(Enum.PartType.Ball, Enum.Material.ForceField, color)
	bubble.Size = Vector3.one * START_SIZE
	bubble.CFrame = CFrame.new(center)
	spawnPart(bubble, cleanup)
	local diameter = config.BubbleRadius * 2 * magnitude
	tween(bubble, config.BubbleTime, { Size = Vector3.one * diameter, Transparency = 1 }, cleanup)
	destroyLater(bubble, config.BubbleTime)
end

local function playPillar(center: Vector3, color: Color3, magnitude: number, cleanup: RevealCleanup.Cleanup)
	local config = ForgeAnimationConfig.Impact
	local width = config.PillarWidth * magnitude
	local pillar = createPart(Enum.PartType.Cylinder, Enum.Material.Neon, color)
	pillar.Size = Vector3.new(config.PillarHeight, START_SIZE, START_SIZE)
	pillar.CFrame = CFrame.new(center + Vector3.yAxis * config.PillarHeight / 2) * CFrame.Angles(0, 0, QUARTER_TURN)
	pillar.Transparency = config.PillarTransparency
	spawnPart(pillar, cleanup)
	tween(pillar, config.PillarRiseTime, { Size = Vector3.new(config.PillarHeight, width, width) }, cleanup)
	task.delay(config.PillarRiseTime + config.PillarHoldTime, function()
		if pillar.Parent then
			tween(pillar, config.PillarFadeTime, {
				Size = Vector3.new(config.PillarHeight, START_SIZE, START_SIZE),
				Transparency = 1,
			}, cleanup)
		end
	end)
	destroyLater(pillar, config.PillarRiseTime + config.PillarHoldTime + config.PillarFadeTime)
end

local function playBurst(anchor: Part, color: Color3, magnitude: number, cleanup: RevealCleanup.Cleanup)
	local config = ForgeAnimationConfig.Impact
	local attachment = Instance.new("Attachment")
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = config.BurstTexture
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 1
	emitter.Speed = config.BurstSpeed
	emitter.Lifetime = config.BurstLifetime
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new(config.BurstSize * magnitude, 0)
	emitter.Drag = config.BurstDrag
	emitter.Enabled = false
	emitter.Parent = attachment
	attachment.Parent = anchor
	emitter:Emit(math.floor(config.BurstCount * magnitude))
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = config.LightRange * magnitude
	light.Brightness = config.LightBrightness
	light.Shadows = false
	light.Parent = anchor
	tween(light, config.LightFadeTime, { Brightness = 0 }, cleanup)
end

function ImpactEffect.Play(center: Vector3, color: Color3, magnitude: number, length: number, cleanup: RevealCleanup.Cleanup)
	local config = ForgeAnimationConfig.Impact
	local radius = (config.RingRadius + length * config.RingRadiusPerStud) * magnitude
	playRing(center, color, radius, cleanup)
	playBubble(center, color, magnitude, cleanup)
	playPillar(center, color, magnitude, cleanup)
	local anchor = createPart(Enum.PartType.Block, Enum.Material.SmoothPlastic, color)
	anchor.Size = Vector3.one * START_SIZE
	anchor.Transparency = 1
	anchor.CFrame = CFrame.new(center)
	spawnPart(anchor, cleanup)
	playBurst(anchor, color, magnitude, cleanup)
	destroyLater(anchor, config.BurstLifetime.Max + config.LightFadeTime)
end

return ImpactEffect
