--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local FriendBoostConfig = require(ReplicatedStorage.Shared.Config.FriendBoostConfig)
local HudMessages = require(ReplicatedStorage.Shared.Constants.HudMessages)

local HUD_GUI_NAME = "HudGui"
local DISPLAY_NAME = "FriendBoostDisplay"
local LABEL_NAME = "BoostLabel"
local INVITE_BUTTON_NAME = "InviteButton"

local FriendBoostDisplay = {}

local isInitialized = false
local boostLabel: TextLabel? = nil

local function render()
	local label = boostLabel
	if not label then
		return
	end
	local percent = Players.LocalPlayer:GetAttribute(FriendBoostConfig.LuckPercentAttribute)
	local value = if typeof(percent) == "number" then percent else 0
	label.Text = string.format(HudMessages.FriendBoostFormat, value)
end

local function promptInvite()
	local player = Players.LocalPlayer
	local ok, canInvite = pcall(function()
		return SocialService:CanSendGameInviteAsync(player)
	end)
	if not ok then
		warn("[FriendBoostDisplay] CanSendGameInviteAsync failed:", canInvite)
		return
	end
	if not canInvite then
		return
	end
	local promptOk, promptError = pcall(function()
		SocialService:PromptGameInvite(player)
	end)
	if not promptOk then
		warn("[FriendBoostDisplay] PromptGameInvite failed:", promptError)
	end
end

local function bindHud(child: Instance)
	if child.Name ~= HUD_GUI_NAME then
		return
	end
	local display = child:FindFirstChild(DISPLAY_NAME)
	local label = display and display:FindFirstChild(LABEL_NAME, true)
	local button = display and display:FindFirstChild(INVITE_BUTTON_NAME, true)
	if not label or not label:IsA("TextLabel") or not button or not button:IsA("GuiButton") then
		warn("[FriendBoostDisplay] Missing", DISPLAY_NAME, "parts")
		return
	end
	boostLabel = label
	button.Activated:Connect(function()
		task.spawn(promptInvite)
	end)
	render()
end

function FriendBoostDisplay.Init()
	if isInitialized then
		return
	end
	isInitialized = true
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	for _, child in playerGui:GetChildren() do
		bindHud(child)
	end
	playerGui.ChildAdded:Connect(bindHud)
	Players.LocalPlayer
		:GetAttributeChangedSignal(FriendBoostConfig.LuckPercentAttribute)
		:Connect(render)
	render()
end

return FriendBoostDisplay
