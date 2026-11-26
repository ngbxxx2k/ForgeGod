--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local ForgeUpgradeConfig = require(shared:WaitForChild("Config"):WaitForChild("ForgeUpgradeConfig"))
local StationConfig = require(shared:WaitForChild("Config"):WaitForChild("StationConfig"))
local PlayerAttributes = require(shared:WaitForChild("Constants"):WaitForChild("PlayerAttributes"))
local RemoteNames = require(shared:WaitForChild("Network"):WaitForChild("RemoteNames"))
local ForgeToolSkin = require(shared:WaitForChild("Utils"):WaitForChild("ForgeToolSkin"))
local PlotStations = require(shared:WaitForChild("Utils"):WaitForChild("PlotStations"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local RateLimiter = require(script.Parent.Parent.Security.RateLimiter)
local PlotService = require(script.Parent.PlotService)
local PurchaseService = require(script.Parent.PurchaseService)

local REMOTES_FOLDER_NAME = "Remotes"
local BUY_RATE_LIMIT_KEY = "ForgeToolBuy"
local SKIN_RATE_LIMIT_KEY = "ForgeToolSkin"

local TrackIds = ForgeUpgradeConfig.TrackIds

local ForgeUpgradeService = {}

local isInitialized = false
local notifyResult: RemoteEvent? = nil

local function sendResult(
	player: Player,
	ok: boolean,
	reason: string?,
	trackId: string?,
	tierIndex: number?,
	isSkinChange: boolean?
)
	if notifyResult ~= nil and player.Parent ~= nil then
		notifyResult:FireClient(player, ok, reason, trackId, tierIndex, isSkinChange)
	end
end

local function applyAnvilSkin(player: Player)
	local skin = DataActions.GetForgeSkin(player, TrackIds.Anvil)
	local anvil = PlotStations.FindOwnedStation(player.UserId, StationConfig.ForgeModelName)
	if skin and anvil then
		ForgeToolSkin.Apply(anvil, TrackIds.Anvil, skin)
	end
end

local function applySkins(player: Player)
	if player.Parent == nil then
		return
	end
	applyAnvilSkin(player)
	local hammerSkin = DataActions.GetForgeSkin(player, TrackIds.Hammer)
	player:SetAttribute(PlayerAttributes.HammerSkinTier, hammerSkin or ForgeUpgradeConfig.MinTier)
end

local function buyWithCoins(player: Player, trackId: string, tierIndex: number)
	local ok, reason = DataActions.TryBuyForgeToolTier(player, trackId, tierIndex)
	if ok then
		applySkins(player)
	end
	sendResult(player, ok, reason, trackId, tierIndex, false)
end

local function promptRobux(player: Player, trackId: string, tierIndex: number)
	if DataActions.OwnsForgeToolTier(player, trackId, tierIndex) then
		sendResult(player, false, "AlreadyOwned", trackId, tierIndex, false)
		return
	end
	local tier = ForgeUpgradeConfig.GetTier(trackId, tierIndex)
	local productId = if tier then tier.ProductId or 0 else 0
	local ok, reason = PurchaseService.Prompt(player, productId)
	if not ok then
		sendResult(player, false, reason, trackId, tierIndex, false)
	end
end

local function checkRequest(player: Player, trackId: any, tierIndex: any, rateKey: string): string?
	if not ForgeUpgradeConfig.IsValidTier(trackId, tierIndex) then
		return "InvalidRequest"
	end
	if not DataService.IsLoaded(player) then
		return "NotLoaded"
	end
	if not RateLimiter.Check(player, rateKey) then
		return "RateLimited"
	end
	return nil
end

local function onRequestBuy(player: Player, trackId: any, tierIndex: any, currency: any)
	local reason = checkRequest(player, trackId, tierIndex, BUY_RATE_LIMIT_KEY)
	if reason then
		sendResult(player, false, reason)
		return
	end
	if currency == ForgeUpgradeConfig.Currencies.Robux then
		promptRobux(player, trackId, tierIndex)
		return
	end
	buyWithCoins(player, trackId, tierIndex)
end

local function onRequestSetSkin(player: Player, trackId: any, tierIndex: any)
	local reason = checkRequest(player, trackId, tierIndex, SKIN_RATE_LIMIT_KEY)
	if reason then
		sendResult(player, false, reason)
		return
	end
	local ok, setReason = DataActions.TrySetForgeSkin(player, trackId, tierIndex)
	if ok then
		applySkins(player)
	end
	sendResult(player, ok, setReason, trackId, tierIndex, true)
end

local function createRobuxHandler(trackId: string, tierIndex: number): PurchaseService.ProductHandler
	return function(player: Player, purchaseId: string): boolean
		local ok, reason = DataActions.TryGrantForgeToolTier(player, trackId, tierIndex, purchaseId)
		if not ok then
			warn("[ForgeUpgradeService] Robux grant failed:", player.Name, trackId, tierIndex, reason)
			return false
		end
		applySkins(player)
		sendResult(player, true, nil, trackId, tierIndex, false)
		return true
	end
end

local function registerRobuxProducts()
	for trackId, track in ForgeUpgradeConfig.Tracks do
		for tierIndex, tier in track.Tiers do
			if tier.ProductId then
				PurchaseService.RegisterProduct(tier.ProductId, createRobuxHandler(trackId, tierIndex))
			end
		end
	end
end

local function getRemotesFolder(): Instance
	local remotesFolder = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)
	if remotesFolder == nil then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = REMOTES_FOLDER_NAME
		remotesFolder.Parent = ReplicatedStorage
	end
	return remotesFolder :: Instance
end

local function createRemote(name: string, parent: Instance): RemoteEvent
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = parent
	return remote
end

function ForgeUpgradeService.GetLuck(player: Player): number
	local luck = 0
	for trackId in ForgeUpgradeConfig.Tracks do
		local tierIndex = DataActions.GetBestForgeToolTier(player, trackId)
		local tier = tierIndex and ForgeUpgradeConfig.GetTier(trackId, tierIndex)
		if tier then
			luck += tier.Luck
		end
	end
	return luck
end

function ForgeUpgradeService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotesFolder = getRemotesFolder()
	local requestBuy = createRemote(RemoteNames.RequestBuyForgeTool, remotesFolder)
	local requestSkin = createRemote(RemoteNames.RequestSetForgeSkin, remotesFolder)
	notifyResult = createRemote(RemoteNames.NotifyForgeToolResult, remotesFolder)
	requestBuy.OnServerEvent:Connect(onRequestBuy)
	requestSkin.OnServerEvent:Connect(onRequestSetSkin)
	registerRobuxProducts()
	DataService.OnProfileLoaded(applySkins)
	PlotService.OnAssigned(function(player: Player)
		task.defer(applySkins, player)
	end)
	for _, player in Players:GetPlayers() do
		if DataService.IsLoaded(player) then
			task.spawn(applySkins, player)
		end
	end
end

return ForgeUpgradeService
