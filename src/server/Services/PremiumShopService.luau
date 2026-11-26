--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteNames = require(shared:WaitForChild("Network"):WaitForChild("RemoteNames"))
local PremiumShopConfig = require(shared:WaitForChild("Config"):WaitForChild("PremiumShopConfig"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local RateLimiter = require(script.Parent.Parent.Security.RateLimiter)
local GamePassService = require(script.Parent.GamePassService)
local PurchaseService = require(script.Parent.PurchaseService)

local REMOTES_FOLDER_NAME = "Remotes"
local RATE_LIMIT_KEY = "PremiumPurchase"

local PremiumShopService = {}

local isInitialized = false
local notifyResult: RemoteEvent? = nil

local function sendResult(player: Player, ok: boolean, reason: string?, kind: string?, id: string?)
	if notifyResult ~= nil and player.Parent ~= nil then
		notifyResult:FireClient(player, ok, reason, kind, id)
	end
end

local function promptCoinPack(player: Player, packId: string): (boolean, string?)
	local pack = PremiumShopConfig.CoinPackById[packId]
	if pack == nil then
		return false, "InvalidRequest"
	end
	return PurchaseService.Prompt(player, pack.ProductId)
end

local function promptOrePack(player: Player, packId: string): (boolean, string?)
	local pack = PremiumShopConfig.OrePackById[packId]
	if pack == nil then
		return false, "InvalidRequest"
	end
	return PurchaseService.Prompt(player, pack.ProductId)
end

local function promptPurchase(player: Player, kind: string, id: string): (boolean, string?)
	if kind == PremiumShopConfig.PurchaseKinds.Pass then
		return GamePassService.Prompt(player, id)
	end
	if kind == PremiumShopConfig.PurchaseKinds.CoinPack then
		return promptCoinPack(player, id)
	end
	if kind == PremiumShopConfig.PurchaseKinds.OrePack then
		return promptOrePack(player, id)
	end
	return false, "InvalidRequest"
end

local function onRequestPurchase(player: Player, kind: any, id: any)
	if type(kind) ~= "string" or type(id) ~= "string" then
		sendResult(player, false, "InvalidRequest")
		return
	end
	if not DataService.IsLoaded(player) then
		sendResult(player, false, "NotLoaded")
		return
	end
	if not RateLimiter.Check(player, RATE_LIMIT_KEY) then
		sendResult(player, false, "RateLimited")
		return
	end
	local ok, reason = promptPurchase(player, kind, id)
	if not ok then
		sendResult(player, false, reason, kind, id)
	end
end

local function createCoinPackHandler(pack: PremiumShopConfig.CoinPackDefinition): PurchaseService.ProductHandler
	return function(player: Player, purchaseId: string): boolean
		local ok, reason = DataActions.TryGrantPurchasedCoins(player, pack.Coins, purchaseId)
		if not ok then
			warn("[PremiumShopService] Coin pack grant failed:", player.Name, pack.Id, reason)
			return false
		end
		sendResult(player, true, nil, PremiumShopConfig.PurchaseKinds.CoinPack, pack.Id)
		return true
	end
end

local function createOrePackHandler(pack: PremiumShopConfig.OrePackDefinition): PurchaseService.ProductHandler
	return function(player: Player, purchaseId: string): boolean
		local ok, reason = DataActions.TryGrantPurchasedItem(player, pack.ItemId, pack.Amount, purchaseId)
		if not ok then
			warn("[PremiumShopService] Ore pack grant failed:", player.Name, pack.Id, reason)
			return false
		end
		sendResult(player, true, nil, PremiumShopConfig.PurchaseKinds.OrePack, pack.Id)
		return true
	end
end

local function onPassPurchased(player: Player, passId: string)
	sendResult(player, true, nil, PremiumShopConfig.PurchaseKinds.Pass, passId)
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

function PremiumShopService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotesFolder = getRemotesFolder()
	local requestPurchase = createRemote(RemoteNames.RequestPremiumPurchase, remotesFolder)
	notifyResult = createRemote(RemoteNames.NotifyPremiumPurchaseResult, remotesFolder)
	requestPurchase.OnServerEvent:Connect(onRequestPurchase)

	GamePassService.OnPassPurchased(onPassPurchased)
	for _, pack in PremiumShopConfig.CoinPacks do
		PurchaseService.RegisterProduct(pack.ProductId, createCoinPackHandler(pack))
	end
	for _, pack in PremiumShopConfig.OrePacks do
		PurchaseService.RegisterProduct(pack.ProductId, createOrePackHandler(pack))
	end
end

return PremiumShopService
