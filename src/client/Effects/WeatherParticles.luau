--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local WeatherFxConfig = require(ReplicatedStorage.Shared.Config.WeatherFxConfig)
local WeatherFxTypes = require(ReplicatedStorage.Shared.Types.WeatherFxTypes)

type ParticleLayer = WeatherFxTypes.ParticleLayer

type Emitter = {
	Layer: ParticleLayer,
	Part: Part,
	Emitter: ParticleEmitter,
}

type ParticleSet = {
	Emitters: { Emitter },
	Connection: RBXScriptConnection,
}

local HIDDEN = 1
local NO_SQUASH = 0

local WeatherParticles = {}

local current: ParticleSet? = nil

local function createPart(layer: ParticleLayer): Part
	local part = Instance.new("Part")
	part.Name = WeatherFxConfig.EmitterPartName
	part.Size = layer.AreaSize
	part.Transparency = HIDDEN
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Archivable = false
	return part
end

local function applyLook(emitter: ParticleEmitter, layer: ParticleLayer)
	emitter.Texture = layer.Texture
	emitter.Size = layer.Size
	emitter.Transparency = layer.Transparency
	emitter.Color = layer.Color
	emitter.Squash = NumberSequence.new(layer.Squash or NO_SQUASH)
	emitter.LightEmission = layer.LightEmission or 0
	emitter.LightInfluence = layer.LightInfluence or 1
	emitter.Brightness = layer.Brightness or 1
	emitter.Orientation = layer.Orientation or Enum.ParticleOrientation.FacingCamera
	emitter.Rotation = layer.Rotation or NumberRange.new(0)
	emitter.RotSpeed = layer.RotSpeed or NumberRange.new(0)
end

local function applyMotion(emitter: ParticleEmitter, layer: ParticleLayer)
	emitter.Speed = layer.Speed
	emitter.Lifetime = layer.Lifetime
	emitter.EmissionDirection = layer.EmissionDirection or Enum.NormalId.Top
	emitter.SpreadAngle = layer.SpreadAngle or Vector2.zero
	emitter.Acceleration = layer.Acceleration or Vector3.zero
	emitter.Drag = layer.Drag or 0
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
end

local function createEmitter(layer: ParticleLayer): Emitter
	local part = createPart(layer)
	local emitter = Instance.new("ParticleEmitter")
	applyLook(emitter, layer)
	applyMotion(emitter, layer)
	emitter.Rate = 0
	emitter.Parent = part
	return { Layer = layer, Part = part, Emitter = emitter }
end

local function findGroundHeight(origin: Vector3): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local character = Players.LocalPlayer.Character
	params.FilterDescendantsInstances = if character then { character } else {}
	local direction = Vector3.new(0, -WeatherFxConfig.GroundRaycastDepth, 0)
	local result = Workspace:Raycast(origin, direction, params)
	return if result then result.Position.Y else origin.Y
end

local function follow(set: ParticleSet)
	local camera = Workspace.CurrentCamera
	if camera == nil then
		return
	end
	local cameraPosition = camera.CFrame.Position
	local groundHeight: number? = nil
	for _, entry in set.Emitters do
		local base = cameraPosition
		if entry.Layer.Anchor == "Ground" then
			groundHeight = groundHeight or findGroundHeight(cameraPosition)
			base = Vector3.new(cameraPosition.X, groundHeight :: number, cameraPosition.Z)
		end
		entry.Part.CFrame = CFrame.new(base + entry.Layer.Offset)
	end
end

local function destroy(set: ParticleSet)
	set.Connection:Disconnect()
	for _, entry in set.Emitters do
		entry.Part:Destroy()
	end
end

function WeatherParticles.Start(layers: { ParticleLayer })
	WeatherParticles.Stop()
	local set: ParticleSet = { Emitters = {}, Connection = nil :: any }
	for _, layer in layers do
		table.insert(set.Emitters, createEmitter(layer))
	end
	set.Connection = RunService.RenderStepped:Connect(function()
		follow(set)
	end)
	follow(set)
	for _, entry in set.Emitters do
		entry.Part.Parent = Workspace
		entry.Emitter.Rate = entry.Layer.Rate
	end
	current = set
end

function WeatherParticles.Stop()
	local set = current
	if set == nil then
		return
	end
	current = nil
	for _, entry in set.Emitters do
		entry.Emitter.Rate = 0
	end
	task.delay(WeatherFxConfig.ParticleFadeTime, destroy, set)
end

return WeatherParticles
