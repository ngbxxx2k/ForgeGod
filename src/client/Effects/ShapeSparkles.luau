--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ForgeAnimationConfig = require(ReplicatedStorage.Shared.Config.ForgeAnimationConfig)
local RevealCleanup = require(script.Parent.RevealCleanup)

local HOST_NAME = "ForgeRevealSparkles"
local THICKNESS_RATIO = 0.25
local MIN_THICKNESS = 0.2

export type Sparkles = {
	Host: Part,
	Emitter: ParticleEmitter,
	Connection: RBXScriptConnection,
}

local ShapeSparkles = {}

local function getHostSize(length: number): Vector3
	local thickness = math.max(length * THICKNESS_RATIO, MIN_THICKNESS)
	return Vector3.new(thickness, length, thickness)
end

local function getParticleSize(length: number): NumberSequence
	local config = ForgeAnimationConfig.ShapeSparkles
	local size = math.max(config.SizePerStud * length, config.MinSize)
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.2, size),
		NumberSequenceKeypoint.new(1, 0),
	})
end

local function createHost(center: Vector3, length: number): Part
	local host = Instance.new("Part")
	host.Name = HOST_NAME
	host.Size = getHostSize(length)
	host.Transparency = 1
	host.Anchored = true
	host.CanCollide = false
	host.CanQuery = false
	host.CanTouch = false
	host.CastShadow = false
	host.CFrame = CFrame.new(center)
	return host
end

local function createEmitter(host: Part, length: number): ParticleEmitter
	local config = ForgeAnimationConfig.ShapeSparkles
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = config.Texture
	emitter.Color = config.Color
	emitter.LightEmission = config.LightEmission
	emitter.LightInfluence = 0
	emitter.Rate = config.Rate
	emitter.Lifetime = config.Lifetime
	emitter.Speed = config.Speed
	emitter.Drag = config.Drag
	emitter.ZOffset = config.ZOffset
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.Size = getParticleSize(length)
	emitter.Parent = host
	return emitter
end

function ShapeSparkles.Start(getCenter: () -> Vector3, length: number, cleanup: RevealCleanup.Cleanup): Sparkles
	local host = createHost(getCenter(), length)
	local emitter = createEmitter(host, length)
	host.Parent = Workspace
	RevealCleanup.Add(cleanup, host)
	local connection = RunService.RenderStepped:Connect(function()
		host.CFrame = CFrame.new(getCenter())
	end)
	RevealCleanup.Add(cleanup, connection)
	return { Host = host, Emitter = emitter, Connection = connection }
end

function ShapeSparkles.Burst(sparkles: Sparkles, length: number)
	sparkles.Host.Size = getHostSize(length)
	sparkles.Emitter.Size = getParticleSize(length)
	sparkles.Emitter:Emit(ForgeAnimationConfig.ShapeSparkles.BurstCount)
end

function ShapeSparkles.Stop(sparkles: Sparkles)
	sparkles.Emitter.Enabled = false
	sparkles.Connection:Disconnect()
	local host = sparkles.Host
	task.delay(ForgeAnimationConfig.ShapeSparkles.Lifetime.Max, function()
		host:Destroy()
	end)
end

return ShapeSparkles
