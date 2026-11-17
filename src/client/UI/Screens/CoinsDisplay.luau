--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HudMessages = require(ReplicatedStorage.Shared.Constants.HudMessages)
local PlayerStateController = require(script.Parent.Parent.Parent.Controllers.PlayerStateController)

local HUD_GUI_NAME = "HudGui"
local COINS_LABEL_NAME = "CoinsLabel"
local ABBREVIATE_FROM = 1_000_000
local ABBREVIATION_STEP = 1000
local ABBREVIATION_DECIMALS = 2
local THOUSANDS_PATTERN = "^(-?%d+)(%d%d%d)"

local CoinsDisplay = {}

local isInitialized = false
local coinsLabel: TextLabel? = nil

local function addThousandsSeparators(value: number): string
	local text = tostring(math.floor(value))
	local replacement = "%1" .. HudMessages.ThousandsSeparator .. "%2"
	local count = 1
	while count > 0 do
		text, count = string.gsub(text, THOUSANDS_PATTERN, replacement)
	end
	return text
end

local function trimDecimals(value: number): string
	local factor = 10 ^ ABBREVIATION_DECIMALS
	local truncated = math.floor(value * factor) / factor
	local text = string.format("%." .. ABBREVIATION_DECIMALS .. "f", truncated)
	text = string.gsub(text, "0+$", "")
	text = string.gsub(text, "%.$", "")
	return text
end

local function formatCoins(coins: number): string
	if coins < ABBREVIATE_FROM then
		return addThousandsSeparators(coins)
	end
	local suffixes = HudMessages.AbbreviationSuffixes
	local value = coins / ABBREVIATE_FROM
	local index = 1
	while value >= ABBREVIATION_STEP and index < #suffixes do
		value /= ABBREVIATION_STEP
		index += 1
	end
	return string.format(HudMessages.AbbreviatedFormat, trimDecimals(value), suffixes[index])
end

local function render()
	local label = coinsLabel
	local state = PlayerStateController.GetState()
	if not label or not state then
		return
	end
	label.Text = string.format(HudMessages.CoinsFormat, formatCoins(state.Coins))
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
