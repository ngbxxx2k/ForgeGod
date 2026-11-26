--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteNames = require(shared:WaitForChild("Network"):WaitForChild("RemoteNames"))
local ShopConfig = require(shared:WaitForChild("Config"):WaitForChild("ShopConfig"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local RateLimiter = require(script.Parent.Parent.Security.RateLimiter)
local PurchaseService = require(script.Parent.PurchaseService)
local ShopService = require(script.Parent.ShopService)

local REMOTES_FOLDER_NAME = "Remotes"
local RATE_LIMIT_KEY = "PremiumPurchase"
local ITEM_AMOUNT = 1

local PurchaseKinds = ShopConfig.RobuxPurchaseKinds

local ShopRobuxService = {}

local isInitialized = false
local notifyResult: RemoteEvent? = nil

local function sendResult(player: Player, ok: boolean, reason: string?, kind: string?, itemId: string?)
	if notifyResult ~= nil and player.Parent ~= nil then
		notifyResult:FireClient(player, ok, reason, kind, itemId)
	end
end

local function getProduct(kind: string, itemId: any): ShopConfig.RobuxProduct?
	if kind == PurchaseKinds.Restock then
		return ShopConfig.RestockProduct
	end
	if kind == PurchaseKinds.Item and type(itemId) == "string" then
		return ShopConfig.ItemRobuxProducts[itemId]
	end
	return nil
end

local function onRequestPurchase(player: Player, kind: any, itemId: any)
	if type(kind) ~= "string" then
		sendResult(player, false, "InvalidRequest")
		return
	end
	local product = getProduct(kind, itemId)
	if product == nil then
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
	local ok, reason = PurchaseService.Prompt(player, product.ProductId)
	if not ok then
		sendResult(player, false, reason, kind, itemId)
	end
end

local function createItemHandler(itemId: string): PurchaseService.ProductHandler
	return function(player: Player, purchaseId: string): boolean
		local ok, reason = DataActions.TryGrantPurchasedItem(player, itemId, ITEM_AMOUNT, purchaseId)
		if not ok then
			warn("[ShopRobuxService] Item grant failed:", player.Name, itemId, reason)
			return false
		end
		sendResult(player, true, nil, PurchaseKinds.Item, itemId)
		return true
	end
end

local function grantRestock(player: Player, purchaseId: string): boolean
	local ok, reason = DataActions.TryRecordPurchase(player, purchaseId)
	if not ok then
		warn("[ShopRobuxService] Restock record failed:", player.Name, reason)
		return false
	end
	ShopService.ApplyPaidRestock(player)
	sendResult(player, true, nil, PurchaseKinds.Restock, nil)
	return true
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

function ShopRobuxService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotesFolder = getRemotesFolder()
	local requestPurchase = createRemote(RemoteNames.RequestShopRobuxPurchase, remotesFolder)
	notifyResult = createRemote(RemoteNames.NotifyShopRobuxResult, remotesFolder)
	requestPurchase.OnServerEvent:Connect(onRequestPurchase)

	for itemId, product in ShopConfig.ItemRobuxProducts do
		PurchaseService.RegisterProduct(product.ProductId, createItemHandler(itemId))
	end
	PurchaseService.RegisterProduct(ShopConfig.RestockProduct.ProductId, grantRestock)
end

return ShopRobuxService
