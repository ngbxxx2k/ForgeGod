--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TutorialConfig = require(ReplicatedStorage.Shared.Config.TutorialConfig)
local TutorialMessages = require(ReplicatedStorage.Shared.Constants.TutorialMessages)
local RemoteNames = require(ReplicatedStorage.Shared.Network.RemoteNames)
local PlayerStateTypes = require(ReplicatedStorage.Shared.Types.PlayerStateTypes)
local TutorialPointer = require(script.Parent.Parent.UI.Components.TutorialPointer)
local TutorialScreen = require(script.Parent.Parent.UI.Screens.TutorialScreen)
local TutorialArrow = require(script.Parent.Parent.Effects.TutorialArrow)
local PlayerStateController = require(script.Parent.PlayerStateController)
local TutorialGuides = require(script.Parent.TutorialGuides)
local TutorialState = require(script.Parent.TutorialState)

type TutorialData = PlayerStateTypes.TutorialState
type Guide = TutorialGuides.Guide

local REMOTES_FOLDER_NAME = "Remotes"

local TutorialController = {}

local isInitialized = false
local stepIndexById: { [string]: number } = {}
local requestAdvance: RemoteEvent? = nil
local requestStance: RemoteEvent? = nil
local hasSeenOpenTutorial = false
local completeHideAt = 0
local lastStepId: string? = nil
local lastReportAt = 0
local refreshElapsed = 0

local function clearGuide()
	TutorialArrow.SetTarget(nil)
	TutorialPointer.SetTarget(nil)
end

local function showComplete()
	clearGuide()
	local stepCount = #TutorialConfig.Steps
	TutorialScreen.SetSide("Right")
	TutorialScreen.Show({
		StepNumber = stepCount,
		StepCount = stepCount,
		Title = TutorialMessages.CompleteTitle,
		Description = TutorialMessages.CompleteDescription,
		Icon = TutorialConfig.CompleteIcon,
		Progress = 1,
		IsComplete = true,
	})
end

local function sendReport(stepId: string, guide: Guide)
	local now = os.clock()
	if guide.Report == nil or now - lastReportAt < TutorialConfig.ClientReportRetrySeconds then
		return
	end
	lastReportAt = now
	if guide.Report == "Advance" and requestAdvance then
		requestAdvance:FireServer(stepId)
	elseif guide.Report == "LeaveForge" and requestStance then
		requestStance:FireServer(nil)
	end
end

local function renderStep(tutorial: TutorialData)
	local stepIndex = stepIndexById[tutorial.StepId]
	local step = stepIndex and TutorialConfig.Steps[stepIndex]
	if step == nil then
		TutorialScreen.Hide()
		clearGuide()
		return
	end
	if lastStepId ~= tutorial.StepId then
		lastStepId = tutorial.StepId
		lastReportAt = 0
		TutorialGuides.ResetUpgradeTabs()
	end
	local guide = TutorialGuides.Build(tutorial)
	local text = guide.Text or TutorialMessages.Steps[step.Id]
	local stepCount = #TutorialConfig.Steps
	TutorialScreen.SetSide(guide.Side)
	TutorialScreen.Show({
		StepNumber = stepIndex,
		StepCount = stepCount,
		Title = if text then text.Title else step.Id,
		Description = if text then text.Description else "",
		Icon = step.Icon,
		Progress = (stepIndex - 1 + math.clamp(guide.Progress, 0, 1)) / stepCount,
		IsComplete = false,
	})
	TutorialArrow.SetTarget(guide.World)
	TutorialPointer.SetTarget(guide.Pointer)
	sendReport(step.Id, guide)
end

local function refresh()
	local tutorial = TutorialState.Get()
	if tutorial == nil then
		TutorialScreen.Hide()
		clearGuide()
		return
	end
	if not tutorial.IsComplete then
		hasSeenOpenTutorial = true
		renderStep(tutorial)
		return
	end
	if hasSeenOpenTutorial then
		hasSeenOpenTutorial = false
		completeHideAt = os.clock() + TutorialConfig.CompleteDisplaySeconds
		showComplete()
		return
	end
	if os.clock() >= completeHideAt then
		TutorialScreen.Hide()
		clearGuide()
	end
end

local function onHeartbeat(dt: number)
	refreshElapsed += dt
	if refreshElapsed < TutorialConfig.TargetRefreshSeconds then
		return
	end
	refreshElapsed = 0
	refresh()
end

local function connectRemotes()
	local remotes = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)
	requestAdvance = remotes:WaitForChild(RemoteNames.RequestTutorialAdvance) :: RemoteEvent
	requestStance = remotes:WaitForChild(RemoteNames.RequestForgeStance) :: RemoteEvent
end

function TutorialController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	for index, step in TutorialConfig.Steps do
		stepIndexById[step.Id] = index
	end
	task.spawn(connectRemotes)
	PlayerStateController.OnChanged(function()
		refresh()
	end)
	RunService.Heartbeat:Connect(onHeartbeat)
end

return TutorialController
