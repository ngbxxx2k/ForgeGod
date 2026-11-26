--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DigToolConfig = require(ReplicatedStorage.Shared.Config.DigToolConfig)
local DigMessages = require(ReplicatedStorage.Shared.Constants.DigMessages)
local ForgeUpgradeMessages = require(ReplicatedStorage.Shared.Constants.ForgeUpgradeMessages)
local RemoteNames = require(ReplicatedStorage.Shared.Network.RemoteNames)
local NumberFormat = require(ReplicatedStorage.Shared.Utils.NumberFormat)
local ForgeUpgradeScreen = require(script.Parent.Parent.UI.Screens.ForgeUpgradeScreen)
local Toast = require(script.Parent.Parent.UI.Components.Toast)
local PlayerStateController = require(script.Parent.PlayerStateController)

type UpgradeCard = ForgeUpgradeScreen.UpgradeCard
type Currency = ForgeUpgradeScreen.Currency
type ToolTier = DigToolConfig.ToolTier

local REMOTES_FOLDER_NAME = "Remotes"
local MULTIPLIER_FORMAT = "%g"
local TAB_ORDER = { DigToolConfig.ToolIds.Shovel, DigToolConfig.ToolIds.Detector }
local TAB_LABELS = {
	Shovel = DigMessages.ShovelTabLabel,
	Detector = DigMessages.DetectorTabLabel,
}
local FIRST_TAB_LAYOUT_ORDER = 10

local DigUpgradeController = {}

local isInitialized = false
local requestBuy: RemoteEvent? = nil
local requestEquip: RemoteEvent? = nil
local changedListeners: { () -> () } = {}

local function isTierOwned(toolId: string, index: number): boolean
	if index == DigToolConfig.MinTier then
		return true
	end
	local state = PlayerStateController.GetState()
	local ownedTiers = state and state.OwnedDigTiers
	local owned = ownedTiers and ownedTiers[toolId]
	return owned ~= nil and table.find(owned, index) ~= nil
end

local function getEquippedTier(toolId: string): number
	local state = PlayerStateController.GetState()
	local tiers = state and state.DigTools or {}
	local equipped = DigToolConfig.ClampTier(toolId, tiers[toolId])
	return if isTierOwned(toolId, equipped) then equipped else DigToolConfig.MinTier
end

local function findPreview(toolId: string, tier: ToolTier): Model?
	local root = ReplicatedStorage:FindFirstChild(DigToolConfig.ModelsFolderName)
	local folder = root and root:FindFirstChild(DigToolConfig.Held[toolId].FolderName)
	local model = folder and folder:FindFirstChild(tier.ModelName)
	return if model and model:IsA("Model") then model else nil
end

local function getStatText(toolId: string, tier: ToolTier, statName: string): string
	if toolId == DigToolConfig.ToolIds.Detector then
		return string.format(DigMessages.RadiusFormat, tostring(tier.Radius or 0), string.format(MULTIPLIER_FORMAT, tier.Luck or 1))
	end
	return string.format(DigMessages.SpeedFormat, string.format(MULTIPLIER_FORMAT, tier.Speed or 1), statName)
end

local function getPriceText(index: number, equipped: number, isOwned: boolean, tier: ToolTier): string
	if index == equipped then
		return DigMessages.EquippedText
	elseif isOwned then
		return DigMessages.EquipText
	end
	return string.format(ForgeUpgradeMessages.CoinPriceFormat, NumberFormat.Abbreviate(tier.CoinPrice))
end

local function buildCard(toolId: string, index: number, equipped: number, statName: string): UpgradeCard
	local tier = DigToolConfig.Tracks[toolId].Tiers[index]
	local robuxPrice = tier.RobuxPrice
	local isOwned = isTierOwned(toolId, index)
	local isLocked = not isOwned
	return {
		Id = toolId .. ":" .. index,
		DisplayName = tier.DisplayName,
		Rarity = tier.Rarity,
		StatText = getStatText(toolId, tier, statName),
		CoinText = getPriceText(index, equipped, isOwned, tier),
		RobuxText = if isLocked and robuxPrice
			then string.format(ForgeUpgradeMessages.RobuxPriceFormat, NumberFormat.WithCommas(robuxPrice))
			else nil,
		PreviewModel = findPreview(toolId, tier),
	}
end

local function parseCardId(cardId: string): (string?, number?)
	local toolId, indexText = string.match(cardId, "^(%a+):(%d+)$")
	local index = tonumber(indexText)
	if toolId == nil or index == nil or DigToolConfig.Tracks[toolId] == nil then
		return nil, nil
	end
	return toolId, index
end

local function onBuyResult(ok: any, reason: any, toolId: any, tierIndex: any, isEquip: any)
	if ok == true and type(toolId) == "string" and type(tierIndex) == "number" then
		local tier = DigToolConfig.GetTier(toolId, tierIndex)
		local format = if isEquip == true then DigMessages.EquippedFormat else DigMessages.BoughtFormat
		if tier then
			Toast.Success(string.format(format, tier.DisplayName))
		end
		return
	end
	local message = type(reason) == "string" and DigMessages.Reasons[reason]
	Toast.Error(message or DigMessages.UnknownError)
end

function DigUpgradeController.IsDigTrack(trackId: string): boolean
	return DigToolConfig.Tracks[trackId] ~= nil
end

function DigUpgradeController.BuildCards(trackId: string): { UpgradeCard }
	local track = DigToolConfig.Tracks[trackId]
	local equipped = getEquippedTier(trackId)
	local cards: { UpgradeCard } = {}
	for index in track.Tiers do
		table.insert(cards, buildCard(trackId, index, equipped, track.StatName))
	end
	return cards
end

function DigUpgradeController.TryBuy(cardId: string, currency: Currency): boolean
	local toolId, index = parseCardId(cardId)
	if toolId == nil or index == nil then
		return false
	end
	if isTierOwned(toolId, index) then
		local equipRemote = requestEquip
		if index ~= getEquippedTier(toolId) and equipRemote then
			equipRemote:FireServer(toolId, index)
		end
		return true
	end
	local remote = requestBuy
	if remote then
		remote:FireServer(toolId, index, currency)
	end
	return true
end

function DigUpgradeController.OnChanged(listener: () -> ())
	table.insert(changedListeners, listener)
end

function DigUpgradeController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	for order, toolId in TAB_ORDER do
		ForgeUpgradeScreen.AddTab(toolId, TAB_LABELS[toolId], FIRST_TAB_LAYOUT_ORDER + order)
	end
	local remotes = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)
	requestBuy = remotes:WaitForChild(RemoteNames.RequestBuyDigTool) :: RemoteEvent
	requestEquip = remotes:WaitForChild(RemoteNames.RequestEquipDigTool) :: RemoteEvent
	local result = remotes:WaitForChild(RemoteNames.NotifyBuyDigToolResult) :: RemoteEvent
	result.OnClientEvent:Connect(onBuyResult)
	PlayerStateController.OnChanged(function()
		for _, listener in changedListeners do
			task.spawn(listener)
		end
	end)
end

return DigUpgradeController
