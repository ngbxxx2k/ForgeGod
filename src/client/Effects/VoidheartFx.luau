--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local VoidheartFxConfig = require(ReplicatedStorage.Shared.Config.VoidheartFxConfig)
local VoidheartArcs = require(script.Parent.VoidheartArcs)
local VoidheartEmitters = require(script.Parent.VoidheartEmitters)
local VoidheartEnergy = require(script.Parent.VoidheartEnergy)
local VoidheartMotion = require(script.Parent.VoidheartMotion)
local VoidheartRibbons = require(script.Parent.VoidheartRibbons)
local VoidheartRig = require(script.Parent.VoidheartRig)

type Controller = {
	Rig: VoidheartRig.Rig,
	Motion: VoidheartMotion.MotionState,
	Emitters: VoidheartEmitters.EmitterSet,
	Arcs: VoidheartArcs.ArcSet,
	Ribbons: VoidheartRibbons.RibbonSet,
	StartTime: number,
	DestroyingConnection: RBXScriptConnection,
}

local VoidheartFx = {}

local isInitialized = false
local controllers: { [Model]: Controller } = {}

local function detach(model: Model)
	local controller = controllers[model]
	if not controller then
		return
	end
	controllers[model] = nil
	controller.DestroyingConnection:Disconnect()
	VoidheartEmitters.Destroy(controller.Emitters)
	VoidheartArcs.Destroy(controller.Arcs)
	VoidheartRibbons.Destroy(controller.Ribbons)
	if model.Parent then
		VoidheartRig.Restore(controller.Rig)
	end
end

local function attach(instance: Instance)
	if not instance:IsA("Model") or controllers[instance] or not instance:IsDescendantOf(Workspace) then
		return
	end
	local rig = VoidheartRig.Build(instance)
	if not rig then
		return
	end
	controllers[instance] = {
		Rig = rig,
		Motion = VoidheartMotion.NewState(),
		Emitters = VoidheartEmitters.Create(rig),
		Arcs = VoidheartArcs.Create(rig),
		Ribbons = VoidheartRibbons.Create(rig),
		StartTime = os.clock(),
		DestroyingConnection = instance.Destroying:Connect(function()
			detach(instance)
		end),
	}
end

local function onTagRemoved(instance: Instance)
	if instance:IsA("Model") then
		detach(instance)
	end
end

local function step(dt: number)
	local now = os.clock()
	for _, controller in controllers do
		local time = now - controller.StartTime
		local energy = VoidheartEnergy.Sample(time)
		local input: VoidheartMotion.StepInput = {
			Time = time,
			Dt = dt,
			Energy = energy,
			Surge = VoidheartEnergy.Surge(energy),
		}
		VoidheartMotion.Step(controller.Rig, controller.Motion, input)
		local frame = VoidheartRig.GetFrame(controller.Rig)
		VoidheartEmitters.Update(controller.Emitters, frame, input)
		VoidheartArcs.Update(controller.Arcs, controller.Rig, input.Surge)
		VoidheartRibbons.Update(controller.Ribbons, controller.Rig, frame, input)
	end
end

function VoidheartFx.Init()
	if isInitialized then
		return
	end
	isInitialized = true
	CollectionService:GetInstanceAddedSignal(VoidheartFxConfig.Tag):Connect(attach)
	CollectionService:GetInstanceRemovedSignal(VoidheartFxConfig.Tag):Connect(onTagRemoved)
	for _, instance in CollectionService:GetTagged(VoidheartFxConfig.Tag) do
		attach(instance)
	end
	RunService.RenderStepped:Connect(step)
end

return VoidheartFx
