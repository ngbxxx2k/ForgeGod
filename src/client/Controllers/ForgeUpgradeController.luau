--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeStrikeConfig = require(ReplicatedStorage.Shared.Config.ForgeStrikeConfig)
local ForgeUpgradeConfig = require(ReplicatedStorage.Shared.Config.ForgeUpgradeConfig)
local AssetIds = require(ReplicatedStorage.Shared.Constants.AssetIds)
local ForgeUpgradeMessages = require(ReplicatedStorage.Shared.Constants.ForgeUpgradeMessages)
local RemoteNames = require(ReplicatedStorage.Shared.Network.RemoteNames)
local ForgeToolSkin = require(ReplicatedStorage.Shared.Utils.ForgeToolSkin)
local NumberFormat = require(ReplicatedStorage.Shared.Utils.NumberFormat)
local PlotStations = require(ReplicatedStorage.Shared.Utils.PlotStations)
local StationConfig = require(ReplicatedStorage.Shared.Config.StationConfig)
local ForgeUpgradeScreen = require(script.Parent.Parent.UI.Screens.ForgeUpgradeScreen)
local Toast = require(script.Parent.Parent.UI.Components.Toast)
local DigUpgradeController = require(script.Parent.DigUpgradeController)
local PlayerStateController = require(script.Parent.PlayerStateController)

type UpgradeCard = ForgeUpgradeScreen.UpgradeCard
type Currency = ForgeUpgradeScreen.Currency
type UpgradeTier = ForgeUpgradeConfig.UpgradeTier

local REMOTES_FOLDER_NAME = "Remotes"
local PERCENT_SCALE = 100

local ForgeUpgradeController = {}

local isInitialized = false
local localPlayer = Players.LocalPlayer
local currentTrackId = ForgeUpgradeConfig.DefaultTrackId
local requestBuy: RemoteEvent? = nil
local requestSkin: RemoteEvent? = nil

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

local function readTier(fieldName: string, trackId: string): number
	local state = PlayerStateController.GetState() :: any
	local tiers = state and state[fieldName] or {}
	return ForgeUpgradeConfig.ClampTier(trackId, tiers[trackId])
end

local function isTierOwned(trackId: string, index: number): boolean
	if index == ForgeUpgradeConfig.MinTier then
		return true
	end
	local state = PlayerStateController.GetState()
	local ownedTiers = state and state.OwnedForgeTiers
	local owned = ownedTiers and ownedTiers[trackId]
	return owned ~= nil and table.find(owned, index) ~= nil
end

local function getSkinTier(trackId: string): number
	local skin = readTier("ForgeSkins", trackId)
	return if isTierOwned(trackId, skin) then skin else ForgeUpgradeConfig.MinTier
end

local function getTrackTextures(trackId: string): { string }
	local textures = {}
	for _, texture in AssetIds.ForgeUpgradeTextures[trackId] or {} do
		table.insert(textures, texture)
	end
	return textures
end

local function getCoinText(tier: UpgradeTier, index: number, isOwned: boolean, skin: number): string
	if index == skin then
		return ForgeUpgradeMessages.EquippedText
	elseif isOwned then
		return ForgeUpgradeMessages.EquipText
	end
	return string.format(ForgeUpgradeMessages.CoinPriceFormat, NumberFormat.Abbreviate(tier.CoinPrice))
end

local function buildCard(trackId: string, index: number, statName: string, preview: Model?): UpgradeCard
	local tier = ForgeUpgradeConfig.Tracks[trackId].Tiers[index]
	local isOwned, skin = isTierOwned(trackId, index), getSkinTier(trackId)
	local robuxPrice = tier.RobuxPrice
	local luckPercent = math.floor(tier.Luck * PERCENT_SCALE + 0.5)
	return {
		Id = trackId .. ":" .. index,
		DisplayName = tier.DisplayName,
		Rarity = tier.Rarity,
		StatText = string.format(ForgeUpgradeMessages.LuckStatFormat, luckPercent, statName),
		CoinText = getCoinText(tier, index, isOwned, skin),
		RobuxText = if robuxPrice and not isOwned
			then string.format(ForgeUpgradeMessages.RobuxPriceFormat, NumberFormat.WithCommas(robuxPrice))
			else nil,
		PreviewModel = preview,
		PreviewTexture = ForgeToolSkin.GetTexture(trackId, index),
		BaseTextures = getTrackTextures(trackId),
	}
end

local function renderTrack(trackId: string, isKeepingScroll: boolean?)
	if DigUpgradeController.IsDigTrack(trackId) then
		currentTrackId = trackId
		ForgeUpgradeScreen.SelectTab(trackId)
		ForgeUpgradeScreen.Render(DigUpgradeController.BuildCards(trackId), isKeepingScroll)
		return
	end
	local track = ForgeUpgradeConfig.Tracks[trackId]
	if track == nil then
		warn("[ForgeUpgradeController] Unknown track:", trackId)
		return
	end
	currentTrackId = trackId
	local preview = getPreviewModel(trackId)
	local cards: { UpgradeCard } = {}
	for index in track.Tiers do
		table.insert(cards, buildCard(trackId, index, track.StatName, preview))
	end
	ForgeUpgradeScreen.SelectTab(trackId)
	ForgeUpgradeScreen.Render(cards, isKeepingScroll)
end

local function onTabSelected(trackId: string)
	if trackId ~= currentTrackId then
		renderTrack(trackId)
	end
end

local function parseCardId(cardId: string): (string?, number?)
	local trackId, indexText = string.match(cardId, "^(%a+):(%d+)$")
	local index = tonumber(indexText)
	if trackId == nil or index == nil or ForgeUpgradeConfig.Tracks[trackId] == nil then
		return nil, nil
	end
	return trackId, index
end

local function onBuy(cardId: string, currency: Currency)
	if DigUpgradeController.TryBuy(cardId, currency) then
		return
	end
	local trackId, index = parseCardId(cardId)
	if trackId == nil or index == nil then
		return
	end
	if isTierOwned(trackId, index) then
		if index ~= getSkinTier(trackId) and requestSkin then
			requestSkin:FireServer(trackId, index)
		end
		return
	end
	if requestBuy then
		requestBuy:FireServer(trackId, index, currency)
	end
end

local function onResult(ok: any, reason: any, trackId: any, tierIndex: any, isSkinChange: any)
	if ok ~= true then
		local message = type(reason) == "string" and ForgeUpgradeMessages.Reasons[reason]
		Toast.Error(message or ForgeUpgradeMessages.UnknownError)
		return
	end
	local tier = type(trackId) == "string" and type(tierIndex) == "number"
		and ForgeUpgradeConfig.GetTier(trackId, tierIndex)
	if not tier then
		return
	end
	local format = if isSkinChange == true
		then ForgeUpgradeMessages.SkinChangedFormat
		else ForgeUpgradeMessages.BoughtFormat
	Toast.Success(string.format(format, tier.DisplayName))
end

local function onStateChanged()
	if ForgeUpgradeScreen.IsOpen() then
		renderTrack(currentTrackId, true)
	end
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

	local remotes = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)
	requestBuy = remotes:WaitForChild(RemoteNames.RequestBuyForgeTool) :: RemoteEvent
	requestSkin = remotes:WaitForChild(RemoteNames.RequestSetForgeSkin) :: RemoteEvent
	local result = remotes:WaitForChild(RemoteNames.NotifyForgeToolResult) :: RemoteEvent
	result.OnClientEvent:Connect(onResult)
	ForgeUpgradeScreen.SetTabHandler(onTabSelected)
	ForgeUpgradeScreen.SetBuyHandler(onBuy)
	DigUpgradeController.OnChanged(onStateChanged)
end

return ForgeUpgradeController
