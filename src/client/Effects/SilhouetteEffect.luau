--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ForgeAnimationConfig = require(ReplicatedStorage.Shared.Config.ForgeAnimationConfig)
local RevealCleanup = require(script.Parent.RevealCleanup)
local RevealWeapon = require(script.Parent.RevealWeapon)

export type Silhouette = {
	Highlight: Highlight,
	SmokeEmitters: { ParticleEmitter },
	DisabledEffects: { Instance },
}

local HIGHLIGHT_NAME = "ForgeRevealSilhouette"
local SMOKE_NAME = "ForgeRevealSmoke"
local SHARD_NAME = "ForgeRevealShard"
local FULL_TURN = math.pi * 2
local HALF = 0.5
local SHARD_WIDTH = NumberRange.new(0.4, 1)
local SHARD_HEIGHT = NumberRange.new(0.6, 1.4)
local SHARD_DEPTH = NumberRange.new(0.1, 0.3)
local TRAVEL = NumberRange.new(0.6, 1.2)
local SHARD_END_SIZE = 0.2

local SilhouetteEffect = {}

local rng = Random.new()

local function isToggleableEffect(instance: Instance): boolean
	return instance:IsA("ParticleEmitter") or instance:IsA("Beam") or instance:IsA("Trail")
		or instance:IsA("Light")
end

local function disableEffects(model: Model): { Instance }
	local disabled = {}
	for _, descendant in model:GetDescendants() do
		if isToggleableEffect(descendant) and (descendant :: any).Enabled then
			(descendant :: any).Enabled = false
			table.insert(disabled, descendant)
		end
	end
	return disabled
end

local function createHighlight(model: Model): Highlight
	local config = ForgeAnimationConfig.Silhouette
	local highlight = Instance.new("Highlight")
	highlight.Name = HIGHLIGHT_NAME
	highlight.FillColor = config.FillColor
	highlight.FillTransparency = 0
	highlight.OutlineColor = config.OutlineColor
	highlight.OutlineTransparency = config.OutlineTransparency
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Adornee = model
	highlight.Parent = model
	return highlight
end

local function createSmoke(host: BasePart, worldPosition: Vector3, length: number): ParticleEmitter
	local config = ForgeAnimationConfig.Silhouette
	local attachment = Instance.new("Attachment")
	attachment.Name = SMOKE_NAME
	attachment.Position = host.CFrame:PointToObjectSpace(worldPosition)
	local size = config.SmokeSizePerStud * length
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = config.SmokeTexture
	emitter.Color = ColorSequence.new(config.SmokeColor)
	emitter.LightEmission = 0
	emitter.LightInfluence = 0
	emitter.Rate = config.SmokeRate
	emitter.Lifetime = config.SmokeLifetime
	emitter.Speed = config.SmokeSpeed
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.RotSpeed = config.SmokeRotSpeed
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.Size = NumberSequence.new(size * 0.6, size)
	emitter.Transparency = config.SmokeTransparency
	emitter.Parent = attachment
	attachment.Parent = host
	return emitter
end

local function createSmokeColumn(model: Model, length: number): { ParticleEmitter }
	local host = RevealWeapon.FindLargestPart(model)
	if host == nil then
		return {}
	end
	local emitters = {}
	local center = model:GetBoundingBox().Position
	local points = math.max(ForgeAnimationConfig.Silhouette.SmokePoints, 1)
	for index = 1, points do
		local fraction = if points == 1 then 0 else (index - 1) / (points - 1) - 0.5
		local position = center + Vector3.yAxis * (fraction * length)
		table.insert(emitters, createSmoke(host, position, length))
	end
	return emitters
end

local function createShard(center: Vector3, length: number): Part
	local config = ForgeAnimationConfig.Shatter
	local size = config.ShardSizePerStud * length
	local shard = Instance.new("Part")
	shard.Name = SHARD_NAME
	shard.Size = Vector3.new(
		rng:NextNumber(SHARD_WIDTH.Min, SHARD_WIDTH.Max) * size,
		rng:NextNumber(SHARD_HEIGHT.Min, SHARD_HEIGHT.Max) * size,
		rng:NextNumber(SHARD_DEPTH.Min, SHARD_DEPTH.Max) * size
	)
	shard.Color = config.ShardColor
	shard.Material = Enum.Material.SmoothPlastic
	shard.Anchored = true
	shard.CanCollide = false
	shard.CanQuery = false
	shard.CanTouch = false
	shard.CastShadow = false
	local offset = Vector3.new(0, rng:NextNumber(-HALF, HALF) * length, 0)
	shard.CFrame = CFrame.new(center + offset) * CFrame.fromOrientation(
		rng:NextNumber(0, FULL_TURN),
		rng:NextNumber(0, FULL_TURN),
		rng:NextNumber(0, FULL_TURN)
	)
	return shard
end

local function flingShard(shard: Part, length: number, cleanup: RevealCleanup.Cleanup)
	local config = ForgeAnimationConfig.Shatter
	local direction = rng:NextUnitVector()
	local travel = direction * config.ShardTravelPerStud * length * rng:NextNumber(TRAVEL.Min, TRAVEL.Max)
	local spin = CFrame.fromOrientation(rng:NextNumber(-math.pi, math.pi), rng:NextNumber(-math.pi, math.pi), 0)
	local info = TweenInfo.new(config.ShardLifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(shard, info, {
		CFrame = (shard.CFrame + travel) * spin,
		Size = shard.Size * SHARD_END_SIZE,
		Transparency = 1,
	})
	RevealCleanup.Add(cleanup, tween)
	tween:Play()
	task.delay(config.ShardLifetime, function()
		shard:Destroy()
	end)
end

local function shatterShell(model: Model, length: number, cleanup: RevealCleanup.Cleanup)
	local center = model:GetBoundingBox().Position
	for _ = 1, ForgeAnimationConfig.Shatter.ShardCount do
		local shard = createShard(center, length)
		shard.Parent = Workspace
		RevealCleanup.Add(cleanup, shard)
		flingShard(shard, length, cleanup)
	end
end

local function fadeHighlight(highlight: Highlight, cleanup: RevealCleanup.Cleanup)
	local info = TweenInfo.new(ForgeAnimationConfig.Shatter.RevealTime)
	local tween = TweenService:Create(highlight, info, { FillTransparency = 1, OutlineTransparency = 1 })
	RevealCleanup.Add(cleanup, tween)
	RevealCleanup.Add(cleanup, tween.Completed:Connect(function()
		highlight:Destroy()
	end))
	tween:Play()
end

function SilhouetteEffect.Apply(model: Model, length: number): Silhouette
	return {
		DisabledEffects = disableEffects(model),
		Highlight = createHighlight(model),
		SmokeEmitters = createSmokeColumn(model, length),
	}
end

function SilhouetteEffect.Reveal(silhouette: Silhouette, model: Model, length: number, cleanup: RevealCleanup.Cleanup)
	for _, emitter in silhouette.SmokeEmitters do
		local attachment = emitter.Parent
		if attachment then
			attachment:Destroy()
		end
	end
	for _, effect in silhouette.DisabledEffects do
		(effect :: any).Enabled = true
	end
	fadeHighlight(silhouette.Highlight, cleanup)
	shatterShell(model, length, cleanup)
end

return SilhouetteEffect
