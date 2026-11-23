--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HudMessages = require(ReplicatedStorage.Shared.Constants.HudMessages)
local NumberFormat = require(ReplicatedStorage.Shared.Utils.NumberFormat)
local PlayerStateController = require(script.Parent.Parent.Parent.Controllers.PlayerStateController)
local StatAnimation = require(script.Parent.Parent.Components.StatAnimation)

local HUD_GUI_NAME = "HudGui"
local COINS_LABEL_NAME = "CoinsLabel"

local CoinsDisplay = {}

local isInitialized = false
local coinsLabel: TextLabel? = nil
local hasRendered = false

local function formatCoinsText(coins: number): string
	return string.format(HudMessages.CoinsFormat, NumberFormat.Abbreviate(coins))
end

local function render()
	local label = coinsLabel
	local state = PlayerStateController.GetState()
	if not label or not state then
		return
	end
	if hasRendered then
		StatAnimation.CountTo(label, state.Coins, formatCoinsText)
	else
		StatAnimation.SetNumber(label, state.Coins, formatCoinsText)
		hasRendered = true
	end
end

local function bindHud(child: Instance)
	if child.Name ~= HUD_GUI_NAME then
		return
	end
	local label = child:FindFirstChild(COINS_LABEL_NAME, true)
	if not label or not label:IsA("TextLabel") then
		warn("[CoinsDisplay] Missing", COINS_LABEL_NAME)
		return
	end
	coinsLabel = label
	hasRendered = false
	render()
end

function CoinsDisplay.Init()
	if isInitialized then
		return
	end
	isInitialized = true
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	for _, child in playerGui:GetChildren() do
		bindHud(child)
	end
	playerGui.ChildAdded:Connect(bindHud)
	PlayerStateController.OnChanged(function()
		render()
	end)
	render()
end

return CoinsDisplay
