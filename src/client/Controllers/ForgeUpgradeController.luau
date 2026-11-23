--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeStrikeConfig = require(ReplicatedStorage.Shared.Config.ForgeStrikeConfig)
local ForgeUpgradeConfig = require(ReplicatedStorage.Shared.Config.ForgeUpgradeConfig)
local ForgeUpgradeMessages = require(ReplicatedStorage.Shared.Constants.ForgeUpgradeMessages)
local NumberFormat = require(ReplicatedStorage.Shared.Utils.NumberFormat)
local PlotStations = require(ReplicatedStorage.Shared.Utils.PlotStations)
local StationConfig = require(ReplicatedStorage.Shared.Config.StationConfig)
local ForgeUpgradeScreen = require(script.Parent.Parent.UI.Screens.ForgeUpgradeScreen)
local Toast = require(script.Parent.Parent.UI.Components.Toast)

type UpgradeCard = ForgeUpgradeScreen.UpgradeCard
type Currency = ForgeUpgradeScreen.Currency

local MULTIPLIER_FORMAT = "%g"

local ForgeUpgradeController = {}

local isInitialized = false
local localPlayer = Players.LocalPlayer
local currentTrackId = ForgeUpgradeConfig.DefaultTrackId

local function getHammerModel(): Model?
	local models = ReplicatedStorage:FindFirstChild("Assets")
	local folder = models and models:FindFirstChild("Models")
	local hammer = folder and folder:FindFirstChild(ForgeStrikeConfig.HammerModelName)
	return if hammer and hammer:IsA("Model") then hammer else nil
end

local function getPreviewModel(trackId: string): Model?
	if trackId == ForgeUpgradeConfig.TrackIds.Hammer then
		return getHammerModel()
	end
	return PlotStations.FindOwnedStation(localPlayer.UserId, StationConfig.ForgeModelName)
end

local function buildCard(tier: ForgeUpgradeConfig.UpgradeTier, statName: string, preview: Model?): UpgradeCard
	local multiplier = string.format(MULTIPLIER_FORMAT, tier.Multiplier)
	local robuxPrice = tier.RobuxPrice
	return {
		Id = tier.Id,
		DisplayName = tier.DisplayName,
		Rarity = tier.Rarity,
		StatText = string.format(ForgeUpgradeMessages.StatFormat, multiplier, statName),
		CoinText = string.format(ForgeUpgradeMessages.CoinPriceFormat, NumberFormat.Abbreviate(tier.CoinPrice)),
		RobuxText = if robuxPrice
			then string.format(ForgeUpgradeMessages.RobuxPriceFormat, NumberFormat.WithCommas(robuxPrice))
			else nil,
		PreviewModel = preview,
	}
end

local function renderTrack(trackId: string)
	local track = ForgeUpgradeConfig.Tracks[trackId]
	if track == nil then
		warn("[ForgeUpgradeController] Unknown track:", trackId)
		return
	end
	currentTrackId = trackId
	local preview = getPreviewModel(trackId)
	local cards: { UpgradeCard } = {}
	for _, tier in track.Tiers do
		table.insert(cards, buildCard(tier, track.StatName, preview))
	end
	ForgeUpgradeScreen.SelectTab(trackId)
	ForgeUpgradeScreen.Render(cards)
end

local function onTabSelected(trackId: string)
	if trackId ~= currentTrackId then
		renderTrack(trackId)
	end
end

local function onBuy(_cardId: string, _currency: Currency)
	Toast.Show(ForgeUpgradeMessages.NotificationTitle, ForgeUpgradeMessages.ComingSoon)
end

function ForgeUpgradeController.Open()
	if ForgeUpgradeScreen.IsOpen() then
		return
	end
	renderTrack(currentTrackId)
	ForgeUpgradeScreen.Open()
end

function ForgeUpgradeController.Close()
	ForgeUpgradeScreen.Close()
end

function ForgeUpgradeController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	ForgeUpgradeScreen.SetTabHandler(onTabSelected)
	ForgeUpgradeScreen.SetBuyHandler(onBuy)
end

return ForgeUpgradeController
