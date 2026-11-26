--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local DigToolConfig = require(shared:WaitForChild("Config"):WaitForChild("DigToolConfig"))
local RemoteNames = require(shared:WaitForChild("Network"):WaitForChild("RemoteNames"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local RateLimiter = require(script.Parent.Parent.Security.RateLimiter)
local DigToolService = require(script.Parent.DigToolService)
local PurchaseService = require(script.Parent.PurchaseService)

local REMOTES_FOLDER_NAME = "Remotes"
local RATE_LIMIT_KEY = "DigToolBuy"
local EQUIP_RATE_LIMIT_KEY = "DigToolEquip"

local DigUpgradeService = {}

local isInitialized = false
local notifyResult: RemoteEvent? = nil

local function sendResult(
	player: Player,
	ok: boolean,
	reason: string?,
	toolId: string?,
	tierIndex: number?,
	isEquip: boolean?
)
	if notifyResult ~= nil and player.Parent ~= nil then
		notifyResult:FireClient(player, ok, reason, toolId, tierIndex, isEquip)
	end
end

local function isValidTierIndex(toolId: any, tierIndex: any): boolean
	return type(toolId) == "string"
		and DigToolConfig.Tracks[toolId] ~= nil
		and type(tierIndex) == "number"
		and tierIndex == tierIndex
		and tierIndex == math.floor(tierIndex)
		and tierIndex >= DigToolConfig.MinTier
		and tierIndex <= DigToolConfig.GetMaxTier(toolId)
end

local function refreshHeldTool(player: Player, toolId: string)
	if DigToolService.GetShown(player) == toolId then
		DigToolService.Show(player, toolId)
	end
end

local function buyWithCoins(player: Player, toolId: string, tierIndex: number)
	local ok, reason = DataActions.TryBuyDigToolTier(player, toolId, tierIndex)
	if ok then
		refreshHeldTool(player, toolId)
	end
	sendResult(player, ok, reason, toolId, tierIndex)
end

local function promptRobux(player: Player, toolId: string, tierIndex: number)
	if DataActions.OwnsDigToolTier(player, toolId, tierIndex) then
		sendResult(player, false, "AlreadyOwned", toolId, tierIndex)
		return
	end
	local tier = DigToolConfig.GetTier(toolId, tierIndex)
	local productId = if tier then tier.ProductId or 0 else 0
	local ok, reason = PurchaseService.Prompt(player, productId)
	if not ok then
		sendResult(player, false, reason, toolId, tierIndex)
	end
end

local function checkRequest(player: Player, toolId: any, tierIndex: any, rateKey: string): string?
	if not isValidTierIndex(toolId, tierIndex) then
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

local function onRequestEquip(player: Player, toolId: any, tierIndex: any)
	local reason = checkRequest(player, toolId, tierIndex, EQUIP_RATE_LIMIT_KEY)
	if reason then
		sendResult(player, false, reason)
		return
	end
	local ok, equipReason = DataActions.TryEquipDigToolTier(player, toolId, tierIndex)
	if ok then
		refreshHeldTool(player, toolId)
	end
	sendResult(player, ok, equipReason, toolId, tierIndex, true)
end

local function onRequestBuy(player: Player, toolId: any, tierIndex: any, currency: any)
	local reason = checkRequest(player, toolId, tierIndex, RATE_LIMIT_KEY)
	if reason then
		sendResult(player, false, reason)
		return
	end
	if currency == DigToolConfig.Currencies.Robux then
		promptRobux(player, toolId, tierIndex)
		return
	end
	buyWithCoins(player, toolId, tierIndex)
end

local function createRobuxHandler(toolId: string, tierIndex: number): PurchaseService.ProductHandler
	return function(player: Player, purchaseId: string): boolean
		local ok, reason = DataActions.TryGrantDigToolTier(player, toolId, tierIndex, purchaseId)
		if not ok then
			warn("[DigUpgradeService] Robux grant failed:", player.Name, toolId, tierIndex, reason)
			return false
		end
		refreshHeldTool(player, toolId)
		sendResult(player, true, nil, toolId, tierIndex)
		return true
	end
end

local function registerRobuxProducts()
	for toolId, track in DigToolConfig.Tracks do
		for tierIndex, tier in track.Tiers do
			if tier.ProductId then
				PurchaseService.RegisterProduct(tier.ProductId, createRobuxHandler(toolId, tierIndex))
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

function DigUpgradeService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotesFolder = getRemotesFolder()
	local requestBuy = createRemote(RemoteNames.RequestBuyDigTool, remotesFolder)
	notifyResult = createRemote(RemoteNames.NotifyBuyDigToolResult, remotesFolder)
	local requestEquip = createRemote(RemoteNames.RequestEquipDigTool, remotesFolder)
	requestBuy.OnServerEvent:Connect(onRequestBuy)
	requestEquip.OnServerEvent:Connect(onRequestEquip)
	registerRobuxProducts()
end

return DigUpgradeService
