--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local OreCrucibleConfig = require(ReplicatedStorage.Shared.Config.OreCrucibleConfig)
local OreCrucibleEmitters = require(script.Parent.OreCrucibleEmitters)
local OreCrucibleRig = require(script.Parent.OreCrucibleRig)
local OreCrucibleSounds = require(script.Parent.OreCrucibleSounds)

type Controller = {
	Rig: OreCrucibleRig.Rig,
	Emitters: OreCrucibleEmitters.EmitterSet,
	Sounds: OreCrucibleSounds.SoundSet,
	State: string,
	IsAwake: boolean,
	EruptUntil: number,
	EruptToken: number,
	Connections: { RBXScriptConnection },
}

local OreCrucibleFx = {}

local isInitialized = false
local controllers: { [Model]: Controller } = {}

local function readState(model: Model): string
	local value = model:GetAttribute(OreCrucibleConfig.StateAttribute)
	if type(value) == "string" and (OreCrucibleConfig.States :: any)[value] then
		return value
	end
	return OreCrucibleConfig.States.Idle
end

local function effectiveState(controller: Controller): string
	if os.clock() < controller.EruptUntil then
		return OreCrucibleConfig.States.Max
	end
	return readState(controller.Rig.Model)
end

local function fadeTimeFor(state: string): number
	return (OreCrucibleConfig.AnimationFadeTimes :: any)[state] or 0
end

local function isNearCamera(controller: Controller): boolean
	local camera = Workspace.CurrentCamera
	if not camera then
		return false
	end
	local distance = (camera.CFrame.Position - controller.Rig.Body.Position).Magnitude
	return distance <= OreCrucibleConfig.CullDistance
end

local function setAwake(controller: Controller, isAwake: boolean)
	if controller.IsAwake == isAwake then
		return
	end
	controller.IsAwake = isAwake
	if isAwake then
		OreCrucibleRig.PlayState(controller.Rig, controller.State, 0)
	else
		OreCrucibleRig.StopAll(controller.Rig)
	end
	OreCrucibleEmitters.SetAwake(controller.Emitters, isAwake)
	OreCrucibleSounds.SetAwake(controller.Sounds, isAwake)
end

local function onStateChanged(controller: Controller)
	local state = effectiveState(controller)
	if state == controller.State then
		return
	end
	controller.State = state
	if controller.IsAwake then
		OreCrucibleRig.PlayState(controller.Rig, state, fadeTimeFor(state))
	end
	OreCrucibleEmitters.ApplyState(controller.Emitters, state, state == OreCrucibleConfig.States.Max)
	OreCrucibleSounds.ApplyState(controller.Sounds, state, true)
end

local function detach(model: Model)
	local controller = controllers[model]
	if not controller then
		return
	end
	controllers[model] = nil
	for _, connection in controller.Connections do
		connection:Disconnect()
	end
	OreCrucibleSounds.Destroy(controller.Sounds)
	OreCrucibleEmitters.Destroy(controller.Emitters)
	OreCrucibleRig.Destroy(controller.Rig)
end

local function attach(instance: Instance, attempt: number?)
	if not instance:IsA("Model") or controllers[instance] or not instance:IsDescendantOf(Workspace) then
		return
	end
	local currentAttempt = attempt or 1
	local isLastAttempt = currentAttempt >= OreCrucibleConfig.SetupRetries
	local rig = OreCrucibleRig.Build(instance, isLastAttempt)
	if not rig then
		if not isLastAttempt then
			task.delay(OreCrucibleConfig.SetupRetryDelay, attach, instance, currentAttempt + 1)
		end
		return
	end
	local state = readState(instance)
	local controller: Controller = {
		Rig = rig,
		Emitters = OreCrucibleEmitters.Create(rig, state),
		Sounds = OreCrucibleSounds.Create(rig, state),
		State = state,
		IsAwake = false,
		EruptUntil = 0,
		EruptToken = 0,
		Connections = {},
	}
	controllers[instance] = controller
	table.insert(controller.Connections, instance:GetAttributeChangedSignal(OreCrucibleConfig.StateAttribute):Connect(function()
		onStateChanged(controller)
	end))
	table.insert(controller.Connections, instance.Destroying:Connect(function()
		detach(instance)
	end))
	setAwake(controller, isNearCamera(controller))
end

local function onTagRemoved(instance: Instance)
	if instance:IsA("Model") then
		detach(instance)
	end
end

local function step(dt: number)
	for _, controller in controllers do
		if controller.IsAwake then
			OreCrucibleRig.UpdateLava(controller.Rig)
			OreCrucibleEmitters.Update(controller.Emitters, controller.Rig, dt)
			OreCrucibleSounds.Update(controller.Sounds, dt)
		end
	end
end

local function cullLoop()
	while isInitialized do
		task.wait(OreCrucibleConfig.CullCheckInterval)
		for _, controller in controllers do
			setAwake(controller, isNearCamera(controller))
		end
	end
end

local function replayBurst(controller: Controller)
	OreCrucibleEmitters.ApplyState(controller.Emitters, controller.State, true)
	OreCrucibleSounds.ApplyState(controller.Sounds, controller.State, true)
end

function OreCrucibleFx.Erupt(model: Model)
	local controller = controllers[model]
	if not controller then
		return
	end
	local duration = OreCrucibleConfig.EruptDuration
	controller.EruptUntil = os.clock() + duration
	controller.EruptToken += 1
	local token = controller.EruptToken
	if controller.State == OreCrucibleConfig.States.Max then
		replayBurst(controller)
	else
		onStateChanged(controller)
	end
	task.delay(duration, function()
		if controllers[model] == controller and controller.EruptToken == token then
			onStateChanged(controller)
		end
	end)
end

function OreCrucibleFx.Splash(model: Model)
	local controller = controllers[model]
	if not controller then
		return
	end
	for key, count in OreCrucibleConfig.SplashBursts do
		OreCrucibleEmitters.Emit(controller.Emitters, key, count)
	end
end

function OreCrucibleFx.Init()
	if isInitialized then
		return
	end
	isInitialized = true
	CollectionService:GetInstanceAddedSignal(OreCrucibleConfig.Tag):Connect(attach)
	CollectionService:GetInstanceRemovedSignal(OreCrucibleConfig.Tag):Connect(onTagRemoved)
	for _, instance in CollectionService:GetTagged(OreCrucibleConfig.Tag) do
		attach(instance)
	end
	RunService.RenderStepped:Connect(step)
	task.spawn(cullLoop)
end

return OreCrucibleFx
