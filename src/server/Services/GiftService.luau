--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteNames = require(shared:WaitForChild("Network"):WaitForChild("RemoteNames"))
local PremiumShopConfig = require(shared:WaitForChild("Config"):WaitForChild("PremiumShopConfig"))
local ShopConfig = require(shared:WaitForChild("Config"):WaitForChild("ShopConfig"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local RateLimiter = require(script.Parent.Parent.Security.RateLimiter)
local GamePassService = require(script.Parent.GamePassService)
local PurchaseService = require(script.Parent.PurchaseService)

local REMOTES_FOLDER_NAME = "Remotes"
local RATE_LIMIT_KEY = "PremiumPurchase"
local GIFT_ITEM_AMOUNT = 1
local ITEM_KIND = ShopConfig.RobuxPurchaseKinds.Item

type GiftOffer = {
	Kind: string,
	Id: string,
	ProductId: number,
	PassId: string?,
	Coins: number?,
	ItemId: string?,
}

type PendingGift = {
	ProductId: number,
	RecipientUserId: number,
}

local GiftService = {}

local isInitialized = false
local notifyResult: RemoteEvent? = nil
local notifyReceived: RemoteEvent? = nil
local pendingGifts: { [Player]: PendingGift } = {}

local function sendResult(
	player: Player,
	ok: boolean,
	reason: string?,
	recipientName: string?,
	isFallback: boolean?
)
	if notifyResult ~= nil and player.Parent ~= nil then
		notifyResult:FireClient(player, ok, reason, recipientName, isFallback)
	end
end

local function findOffer(kind: string, id: string): GiftOffer?
	if kind == PremiumShopConfig.PurchaseKinds.Pass then
		local pass = PremiumShopConfig.PassById[id]
		if pass == nil then
			return nil
		end
		return { Kind = kind, Id = id, ProductId = pass.GiftProductId, PassId = pass.Id }
	end
	if kind == PremiumShopConfig.PurchaseKinds.CoinPack then
		local pack = PremiumShopConfig.CoinPackById[id]
		if pack == nil then
			return nil
		end
		return { Kind = kind, Id = id, ProductId = pack.GiftProductId, Coins = pack.Coins }
	end
	if kind == ITEM_KIND then
		local product = ShopConfig.ItemRobuxProducts[id]
		if product == nil then
			return nil
		end
		return { Kind = kind, Id = id, ProductId = product.GiftProductId or 0, ItemId = id }
	end
	return nil
end

local function findRecipient(buyer: Player, recipientUserId: any): (Player?, string?)
	if type(recipientUserId) ~= "number" or recipientUserId ~= recipientUserId then
		return nil, "InvalidRequest"
	end
	if recipientUserId == buyer.UserId then
		return nil, "SelfGift"
	end
	local recipient = Players:GetPlayerByUserId(recipientUserId)
	if recipient == nil or not DataService.IsLoaded(recipient) then
		return nil, "InvalidRecipient"
	end
	return recipient
end

local function validateRequest(buyer: Player, kind: any, id: any, recipientUserId: any): (GiftOffer?, string?)
	if type(kind) ~= "string" or type(id) ~= "string" then
		return nil, "InvalidRequest"
	end
	if not DataService.IsLoaded(buyer) then
		return nil, "NotLoaded"
	end
	if not RateLimiter.Check(buyer, RATE_LIMIT_KEY) then
		return nil, "RateLimited"
	end
	local offer = findOffer(kind, id)
	if offer == nil then
		return nil, "InvalidRequest"
	end
	if offer.ProductId <= 0 then
		return nil, "NotAvailable"
	end
	local recipient, reason = findRecipient(buyer, recipientUserId)
	if recipient == nil then
		return nil, reason
	end
	if offer.PassId and GamePassService.HasPass(recipient, offer.PassId) then
		return nil, "AlreadyOwned"
	end
	return offer
end

local function onRequestGift(buyer: Player, kind: any, id: any, recipientUserId: any)
	local offer, reason = validateRequest(buyer, kind, id, recipientUserId)
	if offer == nil then
		sendResult(buyer, false, reason)
		return
	end
	pendingGifts[buyer] = { ProductId = offer.ProductId, RecipientUserId = recipientUserId }
	local ok, promptReason = PurchaseService.Prompt(buyer, offer.ProductId)
	if not ok then
		pendingGifts[buyer] = nil
		sendResult(buyer, false, promptReason)
	end
end

local function grantOffer(player: Player, offer: GiftOffer, purchaseId: string): (boolean, string?)
	if offer.PassId then
		local ok, reason = DataActions.TryGrantGiftedPass(player, offer.PassId, purchaseId)
		if ok then
			GamePassService.SyncGiftedPasses(player)
		end
		return ok, reason
	end
	if offer.ItemId then
		return DataActions.TryGrantPurchasedItem(player, offer.ItemId, GIFT_ITEM_AMOUNT, purchaseId)
	end
	return DataActions.TryGrantPurchasedCoins(player, offer.Coins or 0, purchaseId)
end

local function takeRecipient(buyer: Player, productId: number): Player?
	local pending = pendingGifts[buyer]
	if pending == nil or pending.ProductId ~= productId then
		return nil
	end
	pendingGifts[buyer] = nil
	local recipient = Players:GetPlayerByUserId(pending.RecipientUserId)
	if recipient == nil or not DataService.IsLoaded(recipient) then
		return nil
	end
	return recipient
end

local function deliverToRecipient(
	buyer: Player,
	recipient: Player,
	offer: GiftOffer,
	purchaseId: string
): boolean
	local ok, reason = grantOffer(recipient, offer, purchaseId)
	if not ok then
		warn("[GiftService] Gift grant failed:", buyer.Name, recipient.Name, offer.Id, reason)
		return false
	end
	DataActions.TryRecordPurchase(buyer, purchaseId)
	sendResult(buyer, true, nil, recipient.DisplayName, false)
	if notifyReceived ~= nil then
		notifyReceived:FireClient(recipient, offer.Kind, offer.Id, buyer.DisplayName)
	end
	return true
end

local function deliverToBuyer(buyer: Player, offer: GiftOffer, purchaseId: string): boolean
	if offer.PassId and GamePassService.HasPass(buyer, offer.PassId) then
		warn("[GiftService] Recipient gone and buyer already owns pass:", buyer.Name, offer.Id, purchaseId)
		DataActions.TryRecordPurchase(buyer, purchaseId)
		return true
	end
	local ok, reason = grantOffer(buyer, offer, purchaseId)
	if not ok then
		warn("[GiftService] Fallback grant failed:", buyer.Name, offer.Id, reason)
		return false
	end
	sendResult(buyer, true, nil, nil, true)
	return true
end

local function createGiftHandler(offer: GiftOffer): PurchaseService.ProductHandler
	return function(buyer: Player, purchaseId: string): boolean
		local recipient = takeRecipient(buyer, offer.ProductId)
		if recipient then
			return deliverToRecipient(buyer, recipient, offer, purchaseId)
		end
		return deliverToBuyer(buyer, offer, purchaseId)
	end
end

local function registerGiftProducts()
	for _, pass in PremiumShopConfig.Passes do
		local offer = findOffer(PremiumShopConfig.PurchaseKinds.Pass, pass.Id)
		if offer then
			PurchaseService.RegisterProduct(offer.ProductId, createGiftHandler(offer))
		end
	end
	for _, pack in PremiumShopConfig.CoinPacks do
		local offer = findOffer(PremiumShopConfig.PurchaseKinds.CoinPack, pack.Id)
		if offer then
			PurchaseService.RegisterProduct(offer.ProductId, createGiftHandler(offer))
		end
	end
	for itemId in ShopConfig.ItemRobuxProducts do
		local offer = findOffer(ITEM_KIND, itemId)
		if offer then
			PurchaseService.RegisterProduct(offer.ProductId, createGiftHandler(offer))
		end
	end
end

local function onPlayerRemoving(player: Player)
	pendingGifts[player] = nil
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

function GiftService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotesFolder = getRemotesFolder()
	local requestGift = createRemote(RemoteNames.RequestGiftPurchase, remotesFolder)
	notifyResult = createRemote(RemoteNames.NotifyGiftResult, remotesFolder)
	notifyReceived = createRemote(RemoteNames.NotifyGiftReceived, remotesFolder)
	requestGift.OnServerEvent:Connect(onRequestGift)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	registerGiftProducts()
end

return GiftService
