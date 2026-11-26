--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local DigFxConfig = require(ReplicatedStorage.Shared.Config.DigFxConfig)
local DigMessages = require(ReplicatedStorage.Shared.Constants.DigMessages)
local DigZone = require(ReplicatedStorage.Shared.Utils.DigZone)

local DigPrompt = {}

local isInitialized = false
local anchor: Part? = nil
local prompt: ProximityPrompt? = nil
local rootPart: BasePart? = nil
local triggerHandler: (() -> ())? = nil

local function createAnchor(): Part
	local part = Instance.new("Part")
	part.Name = DigFxConfig.Prompt.PartName
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.one
	part.Parent = Workspace
	return part
end

local function createPrompt(parent: Instance): ProximityPrompt
	local config = DigFxConfig.Prompt
	local newPrompt = Instance.new("ProximityPrompt")
	newPrompt.ObjectText = DigMessages.PromptObjectText
	newPrompt.ActionText = DigMessages.PromptActionText
	newPrompt.KeyboardKeyCode = config.KeyCode
	newPrompt.MaxActivationDistance = config.MaxActivationDistance
	newPrompt.HoldDuration = config.HoldDuration
	newPrompt.RequiresLineOfSight = false
	newPrompt.Enabled = false
	newPrompt.Parent = parent
	return newPrompt
end

local function onRender()
	local part = anchor
	local root = rootPart
	if part == nil or root == nil or root.Parent == nil then
		return
	end
	part.CFrame = CFrame.new(DigZone.GetScanPoint(root.CFrame) + Vector3.yAxis)
end

function DigPrompt.SetRoot(root: BasePart?)
	rootPart = root
end

function DigPrompt.SetEnabled(enabled: boolean)
	local current = prompt
	if current then
		current.Enabled = enabled
	end
end

function DigPrompt.SetTriggerHandler(handler: () -> ())
	triggerHandler = handler
end

function DigPrompt.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local part = createAnchor()
	anchor = part
	local newPrompt = createPrompt(part)
	prompt = newPrompt
	newPrompt.Triggered:Connect(function()
		if triggerHandler then
			triggerHandler()
		end
	end)
	RunService.RenderStepped:Connect(onRender)
end

return DigPrompt
