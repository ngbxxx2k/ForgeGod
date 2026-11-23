--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OreCrucibleConfig = require(ReplicatedStorage.Shared.Config.OreCrucibleConfig)
local OreCrucibleRig = require(script.Parent.OreCrucibleRig)

local LAVA_VOLUME_ANCHOR = "LavaVolume"
local SMOKE_KEY = "Smoke"
local CRACKS_NAME = "OreCrucibleFloorCracks"
local ORBIT_NAME = "OreCrucibleOrbit"
local NOISE_SPEED = 3
local FULL_TURN = math.pi * 2

type Orbit = {
	Spec: OreCrucibleConfig.OrbitSpec,
	Pivot: Part,
	Trail: Trail,
	Angle: number,
}

type LightState = {
	Spec: OreCrucibleConfig.LightSpec,
	Light: PointLight,
	Brightness: number,
	Range: number,
	Seed: number,
}

export type EmitterSet = {
	Emitters: { [string]: ParticleEmitter },
	Lights: { LightState },
	Cracks: Decal,
	CracksTransparency: number,
	Orbits: { Orbit },
	GlowColors: { [string]: Color3 },
	State: string,
	IsAwake: boolean,
	Clock: number,
}

local OreCrucibleEmitters = {}

local random = Random.new()

local function stateValue(map: OreCrucibleConfig.StateMap, state: string): number
	return (map :: any)[state] or map.Idle
end

local function getAnchor(rig: OreCrucibleRig.Rig, name: string): Instance
	if name == LAVA_VOLUME_ANCHOR then
		return rig.LavaVolume
	end
	return rig.Anchors[name]
end

local function newEmitter(parent: Instance, spec: OreCrucibleConfig.EmitterSpec): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = spec.Key
	emitter.Archivable = false
	emitter.Enabled = false
	emitter.Rate = 0
	emitter.LightInfluence = 0
	emitter.EmissionDirection = Enum.NormalId.Top
	for key, value in spec.Properties do
		(emitter :: any)[key] = value
	end
	emitter.Parent = parent
	return emitter
end

local function newLight(rig: OreCrucibleRig.Rig, spec: OreCrucibleConfig.LightSpec): LightState
	local light = Instance.new("PointLight")
	light.Name = spec.Key
	light.Archivable = false
	light.Color = spec.Color
	light.Shadows = false
	light.Brightness = spec.Brightness.Idle
	light.Range = spec.Range.Idle
	light.Parent = getAnchor(rig, spec.Anchor)
	return {
		Spec = spec,
		Light = light,
		Brightness = spec.Brightness.Idle,
		Range = spec.Range.Idle,
		Seed = random:NextNumber(0, 100),
	}
end

local function newCracks(rig: OreCrucibleRig.Rig): Decal
	local settings = OreCrucibleConfig.FloorCracks
	local part = Instance.new("Part")
	part.Name = CRACKS_NAME
	part.Size = Vector3.new(settings.Size, settings.Thickness, settings.Size)
	part.CFrame = CFrame.new(rig.Anchors.Base.WorldPosition - Vector3.yAxis * settings.Thickness * 0.4)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Archivable = false
	part.Parent = rig.Folder
	local decal = Instance.new("Decal")
	decal.Texture = OreCrucibleConfig.Textures.FloorCracks
	decal.Face = Enum.NormalId.Top
	decal.Color3 = settings.Color
	decal.Transparency = 1
	decal.Parent = part
	return decal
end

local function newOrbit(rig: OreCrucibleRig.Rig, spec: OreCrucibleConfig.OrbitSpec): Orbit
	local trailSettings = OreCrucibleConfig.OrbitTrail
	local pivot = Instance.new("Part")
	pivot.Name = ORBIT_NAME
	pivot.Size = Vector3.one * 0.2
	pivot.Anchored = true
	pivot.CanCollide = false
	pivot.CanQuery = false
	pivot.CanTouch = false
	pivot.Transparency = 1
	pivot.Archivable = false
	pivot.Parent = rig.Folder
	local upper = Instance.new("Attachment")
	upper.Position = Vector3.new(spec.Radius, trailSettings.Width * 0.5, 0)
	upper.Parent = pivot
	local lower = Instance.new("Attachment")
	lower.Position = Vector3.new(spec.Radius, -trailSettings.Width * 0.5, 0)
	lower.Parent = pivot
	local trail = Instance.new("Trail")
	trail.Enabled = false
	for key, value in trailSettings.Properties do
		(trail :: any)[key] = value
	end
	trail.Attachment0 = upper
	trail.Attachment1 = lower
	trail.Parent = pivot
	return { Spec = spec, Pivot = pivot, Trail = trail, Angle = random:NextNumber(0, FULL_TURN) }
end

local function applyRates(set: EmitterSet)
	for _, spec in OreCrucibleConfig.Emitters do
		local emitter = set.Emitters[spec.Key]
		local rates = spec.Rates
		if emitter and rates then
			local rate = stateValue(rates, set.State)
			emitter.Rate = rate
			emitter.Enabled = set.IsAwake and rate > 0
		end
	end
	local smoke = set.Emitters[SMOKE_KEY]
	local smokeColor = OreCrucibleConfig.SmokeColors[set.State]
	if smoke and smokeColor then
		smoke.Color = smokeColor
	end
end

local function applyOrbits(set: EmitterSet)
	local isMax = set.State == OreCrucibleConfig.States.Max
	for _, orbit in set.Orbits do
		local enabled = set.IsAwake and isMax
		if orbit.Trail.Enabled and not enabled then
			orbit.Trail:Clear()
		end
		orbit.Trail.Enabled = enabled
	end
end

local function emitBurst(set: EmitterSet)
	for _, spec in OreCrucibleConfig.Emitters do
		local emitter = set.Emitters[spec.Key]
		if emitter and spec.Burst then
			emitter:Emit(spec.Burst)
		end
	end
end

function OreCrucibleEmitters.Create(rig: OreCrucibleRig.Rig, state: string): EmitterSet
	local emitters = {}
	for _, spec in OreCrucibleConfig.Emitters do
		emitters[spec.Key] = newEmitter(getAnchor(rig, spec.Anchor), spec)
	end
	local lights = {}
	for _, spec in OreCrucibleConfig.Lights do
		table.insert(lights, newLight(rig, spec))
	end
	local orbits = {}
	for _, spec in OreCrucibleConfig.Orbits do
		table.insert(orbits, newOrbit(rig, spec))
	end
	local set: EmitterSet = {
		Emitters = emitters,
		Lights = lights,
		Cracks = newCracks(rig),
		CracksTransparency = 1,
		Orbits = orbits,
		GlowColors = {},
		State = state,
		IsAwake = false,
		Clock = 0,
	}
	for key, part in rig.Glows do
		set.GlowColors[key] = part.Color
	end
	return set
end

function OreCrucibleEmitters.ApplyState(set: EmitterSet, state: string, playBurst: boolean)
	set.State = state
	applyRates(set)
	applyOrbits(set)
	if playBurst and set.IsAwake then
		emitBurst(set)
	end
end

function OreCrucibleEmitters.Emit(set: EmitterSet, key: string, count: number)
	local emitter = set.Emitters[key]
	if emitter and set.IsAwake then
		emitter:Emit(count)
	end
end

function OreCrucibleEmitters.SetAwake(set: EmitterSet, isAwake: boolean)
	set.IsAwake = isAwake
	applyRates(set)
	applyOrbits(set)
	for _, lightState in set.Lights do
		lightState.Light.Enabled = isAwake
	end
	set.Cracks.Transparency = if isAwake then set.CracksTransparency else 1
end

local function blend(current: number, target: number, alpha: number): number
	return current + (target - current) * alpha
end

local function updateLights(set: EmitterSet, alpha: number)
	for _, lightState in set.Lights do
		local spec = lightState.Spec
		lightState.Brightness = blend(lightState.Brightness, stateValue(spec.Brightness, set.State), alpha)
		lightState.Range = blend(lightState.Range, stateValue(spec.Range, set.State), alpha)
		local flicker = 1 + spec.Flicker * math.noise(set.Clock * NOISE_SPEED, lightState.Seed)
		lightState.Light.Brightness = lightState.Brightness * flicker
		lightState.Light.Range = lightState.Range
	end
end

local function updateGlows(set: EmitterSet, rig: OreCrucibleRig.Rig, alpha: number)
	for key, part in rig.Glows do
		local colors = OreCrucibleConfig.GlowColors[key]
		local current = set.GlowColors[key]
		if colors and current then
			local target = (colors :: any)[set.State] :: Color3
			local nextColor = current:Lerp(target, alpha)
			set.GlowColors[key] = nextColor
			part.Color = nextColor
		end
	end
end

local function updateOrbits(set: EmitterSet, rig: OreCrucibleRig.Rig, dt: number)
	local center = rig.Anchors.Top.WorldPosition
	for _, orbit in set.Orbits do
		if orbit.Trail.Enabled then
			local spec = orbit.Spec
			orbit.Angle = (orbit.Angle + spec.Speed * dt) % FULL_TURN
			orbit.Pivot.CFrame = CFrame.new(center + Vector3.yAxis * spec.Height)
				* CFrame.fromOrientation(spec.TiltX, 0, spec.TiltZ)
				* CFrame.Angles(0, orbit.Angle, 0)
		end
	end
end

function OreCrucibleEmitters.Update(set: EmitterSet, rig: OreCrucibleRig.Rig, dt: number)
	set.Clock += dt
	local alpha = math.clamp(dt * OreCrucibleConfig.BlendRate, 0, 1)
	updateLights(set, alpha)
	updateGlows(set, rig, alpha)
	local target = stateValue(OreCrucibleConfig.FloorCracks.Transparency, set.State)
	set.CracksTransparency = blend(set.CracksTransparency, target, alpha)
	set.Cracks.Transparency = set.CracksTransparency
	updateOrbits(set, rig, dt)
end

function OreCrucibleEmitters.Destroy(set: EmitterSet)
	for _, emitter in set.Emitters do
		emitter:Destroy()
	end
	for _, lightState in set.Lights do
		lightState.Light:Destroy()
	end
	for _, orbit in set.Orbits do
		orbit.Pivot:Destroy()
	end
	table.clear(set.Emitters)
	table.clear(set.Lights)
	table.clear(set.Orbits)
end

return OreCrucibleEmitters
