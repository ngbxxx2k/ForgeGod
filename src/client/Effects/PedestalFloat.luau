--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local PlotAttributes = require(ReplicatedStorage.Shared.Constants.PlotAttributes)
local PlotConfig = require(ReplicatedStorage.Shared.Config.PlotConfig)

type Tracked = {
	Base: CFrame,
	Phase: number,
}

local PedestalFloat = {}

local isInitialized = false
local trackedParts: { [BasePart]: Tracked } = {}

local function findDisplayModel(part: BasePart): Model?
	local model = part:FindFirstAncestor(PlotConfig.DisplayModelName)
	return if model and model:IsA("Model") then model else nil
end

local function getPhase(model: Model): number
	local slot = model:GetAttribute(PlotAttributes.SlotIndex)
	return if type(slot) == "number" then slot * PlotConfig.BobPhaseStep else 0
end

local function track(descendant: Instance)
	if not descendant:IsA("BasePart") then
		return
	end
	local model = findDisplayModel(descendant)
	if model == nil then
		return
	end
	trackedParts[descendant] = { Base = descendant.CFrame, Phase = getPhase(model) }
end

local function getOffset(now: number, phase: number): Vector3
	local angle = (now + phase) / PlotConfig.BobPeriod * 2 * math.pi
	return Vector3.yAxis * (math.sin(angle) * PlotConfig.BobAmplitude)
end

local function step()
	local now = os.clock()
	local parts: { BasePart } = {}
	local cframes: { CFrame } = {}
	for part, tracked in trackedParts do
		if part.Parent == nil then
			trackedParts[part] = nil
			continue
		end
		table.insert(parts, part)
		table.insert(cframes, tracked.Base + getOffset(now, tracked.Phase))
	end
	if #parts > 0 then
		Workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

local function watchFolder(folder: Instance)
	folder.DescendantAdded:Connect(track)
	for _, descendant in folder:GetDescendants() do
		track(descendant)
	end
end

function PedestalFloat.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	task.spawn(function()
		local folder = Workspace:WaitForChild(PlotConfig.PlotsFolderName)
		watchFolder(folder)
	end)
	RunService.RenderStepped:Connect(step)
end

return PedestalFloat
