--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DigToolConfig = require(ReplicatedStorage.Shared.Config.DigToolConfig)
local DigMessages = require(ReplicatedStorage.Shared.Constants.DigMessages)
local RemoteNames = require(ReplicatedStorage.Shared.Network.RemoteNames)
local PlayerStateTypes = require(ReplicatedStorage.Shared.Types.PlayerStateTypes)
local PlayerStateController = require(script.Parent.PlayerStateController)
local DetectorSignalFx = require(script.Parent.Parent.Effects.DetectorSignalFx)
local DetectorSignalSound = require(script.Parent.Parent.Effects.DetectorSignalSound)
local DigActionFx = require(script.Parent.Parent.Effects.DigActionFx)
local DigMarkerFx = require(script.Parent.Parent.Effects.DigMarkerFx)
local DigToolAnimator = require(script.Parent.Parent.Effects.DigToolAnimator)
local OreRevealPopup = require(script.Parent.Parent.Effects.OreRevealPopup)
local DigPrompt = require(script.Parent.Parent.Input.DigPrompt)
local Toast = require(script.Parent.Parent.UI.Components.Toast)

type PlayerState = PlayerStateTypes.PlayerState

local REMOTES_FOLDER_NAME = "Remotes"
local FULL_SIGNAL = 1
local SILENT_REASONS = { Interrupted = true }

local DigController = {}

local isInitialized = false
local requestDig: RemoteEvent? = nil
local signal = 0
local isOnSpot = false
local isDetectorHeld = false

local function refresh()
	local isDigging = DigActionFx.IsActive()
	DetectorSignalFx.SetActive(isDetectorHeld and not isDigging)
	DetectorSignalFx.SetSignal(signal)
	DetectorSignalSound.Update(isDetectorHeld and not isDigging, signal)
	DigPrompt.SetEnabled(isDetectorHeld and not isDigging and isOnSpot)
end

local function onHeldChanged(kind: string?, model: Model?)
	isDetectorHeld = kind == DigToolConfig.ToolIds.Detector
	DetectorSignalFx.BindDetector(if isDetectorHeld then model else nil)
	refresh()
end

local function onSignal(value: any, onSpot: any)
	if type(value) ~= "number" or value ~= value then
		return
	end
	signal = math.clamp(value, 0, FULL_SIGNAL)
	isOnSpot = onSpot == true
	refresh()
end

local function onMarkers(markers: any)
	if type(markers) ~= "table" then
		return
	end
	DigMarkerFx.Set(markers)
end

local function onDigStarted(spot: any, duration: any)
	if typeof(spot) ~= "Vector3" or type(duration) ~= "number" or duration ~= duration then
		return
	end
	signal = 0
	isOnSpot = false
	DigActionFx.Start(spot, duration)
	refresh()
end

local function onDigResult(ok: any, reason: any, oreId: any)
	DigActionFx.Stop()
	refresh()
	if ok == true and type(oreId) == "string" then
		OreRevealPopup.Show(oreId)
		return
	end
	if type(reason) == "string" and SILENT_REASONS[reason] then
		return
	end
	local message = type(reason) == "string" and DigMessages.Reasons[reason]
	Toast.Error(message or DigMessages.UnknownError)
end

local function onTrigger()
	local remote = requestDig
	if remote and not DigActionFx.IsActive() then
		remote:FireServer()
	end
end

local function onStateChanged(state: PlayerState)
	local tiers = state.DigTools or {}
	local tierIndex = DigToolConfig.ClampTier(DigToolConfig.ToolIds.Detector, tiers[DigToolConfig.ToolIds.Detector])
	local tier = DigToolConfig.GetTier(DigToolConfig.ToolIds.Detector, tierIndex)
	if tier and tier.Radius then
		DetectorSignalFx.SetRadius(tier.Radius)
	end
end

local function onCharacterAdded(character: Model)
	DigActionFx.Stop()
	DigMarkerFx.Clear()
	signal = 0
	isOnSpot = false
	local root = character:WaitForChild("HumanoidRootPart")
	if root:IsA("BasePart") then
		DetectorSignalFx.SetRoot(root)
		DigPrompt.SetRoot(root)
	end
	refresh()
end

function DigController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	DigPrompt.SetTriggerHandler(onTrigger)
	DigToolAnimator.OnHeldChanged(onHeldChanged)

	local remotes = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)
	requestDig = remotes:WaitForChild(RemoteNames.RequestDig) :: RemoteEvent
	local signalRemote = remotes:WaitForChild(RemoteNames.NotifyDigSignal) :: RemoteEvent
	local startedRemote = remotes:WaitForChild(RemoteNames.NotifyDigStarted) :: RemoteEvent
	local resultRemote = remotes:WaitForChild(RemoteNames.NotifyDigResult) :: RemoteEvent
	local markersRemote = remotes:WaitForChild(RemoteNames.NotifyDigMarkers) :: RemoteEvent
	markersRemote.OnClientEvent:Connect(onMarkers)
	signalRemote.OnClientEvent:Connect(onSignal)
	startedRemote.OnClientEvent:Connect(onDigStarted)
	resultRemote.OnClientEvent:Connect(onDigResult)

	PlayerStateController.OnChanged(onStateChanged)
	local state = PlayerStateController.GetState()
	if state then
		onStateChanged(state)
	end
	local player = Players.LocalPlayer
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end
end

return DigController
