--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local OreCrucibleConfig = require(shared:WaitForChild("Config"):WaitForChild("OreCrucibleConfig"))

local OreCrucibleSystem = {}

local isInitialized = false

local function getCycleLength(): number
	local total = 0
	for _, phase in OreCrucibleConfig.Cycle do
		total += phase.Duration
	end
	return total
end

local cycleLength = getCycleLength()

function OreCrucibleSystem.GetStateAt(now: number): string
	local elapsed = now % cycleLength
	for _, phase in OreCrucibleConfig.Cycle do
		if elapsed < phase.Duration then
			return phase.State
		end
		elapsed -= phase.Duration
	end
	return OreCrucibleConfig.States.Idle
end

local function applyState(instance: Instance, state: string)
	if not instance:IsA("Model") then
		return
	end
	if instance:GetAttribute(OreCrucibleConfig.StateAttribute) ~= state then
		instance:SetAttribute(OreCrucibleConfig.StateAttribute, state)
	end
end

local function publish()
	local state = OreCrucibleSystem.GetStateAt(os.time())
	for _, instance in CollectionService:GetTagged(OreCrucibleConfig.Tag) do
		applyState(instance, state)
	end
end

function OreCrucibleSystem.Init()
	if isInitialized then
		return
	end
	isInitialized = true
	if cycleLength <= 0 then
		warn("[OreCrucibleSystem] Cycle length must be positive")
		return
	end
	CollectionService:GetInstanceAddedSignal(OreCrucibleConfig.Tag):Connect(function(instance)
		applyState(instance, OreCrucibleSystem.GetStateAt(os.time()))
	end)
	publish()
	task.spawn(function()
		while isInitialized do
			task.wait(OreCrucibleConfig.PollInterval)
			publish()
		end
	end)
end

return OreCrucibleSystem
