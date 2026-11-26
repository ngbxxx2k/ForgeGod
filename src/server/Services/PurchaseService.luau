--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)

export type ProductHandler = (player: Player, purchaseId: string) -> boolean

local PurchaseService = {}

local isInitialized = false
local handlersByProduct: { [number]: ProductHandler } = {}
local listedPrices: { [number]: number } = {}

local function runHandler(handler: ProductHandler, player: Player, purchaseId: string): boolean
	local ok, result = pcall(handler, player, purchaseId)
	if not ok then
		warn("[PurchaseService] Handler failed:", result)
		return false
	end
	return result == true
end

local function getListedPrice(productId: number): number
	local cached = listedPrices[productId]
	if cached then
		return cached
	end
	local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, productId, Enum.InfoType.Product)
	if not ok or type(info) ~= "table" or type(info.PriceInRobux) ~= "number" then
		warn("[PurchaseService] Could not read product price:", productId, info)
		return 0
	end
	local price = math.floor(info.PriceInRobux)
	listedPrices[productId] = price
	return price
end

local function getRobuxSpent(receiptInfo: any): number
	local spent = receiptInfo.CurrencySpent
	if type(spent) == "number" and spent > 0 then
		return math.floor(spent)
	end
	return getListedPrice(receiptInfo.ProductId)
end

local function processReceipt(receiptInfo: any): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	local handler = handlersByProduct[receiptInfo.ProductId]
	if player == nil or handler == nil or not DataService.IsLoaded(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local purchaseId = tostring(receiptInfo.PurchaseId)
	if not DataActions.HasProcessedPurchase(player, purchaseId) then
		if not runHandler(handler, player, purchaseId) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local spent = getRobuxSpent(receiptInfo)
		if spent > 0 then
			DataActions.TryAddRobuxSpent(player, spent)
		end
	end
	if not DataActions.HasProcessedPurchase(player, purchaseId) then
		DataActions.TryRecordPurchase(player, purchaseId)
	end
	if not DataService.WaitForPurchaseSaved(player, purchaseId) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function PurchaseService.RegisterProduct(productId: number, handler: ProductHandler)
	if productId <= 0 then
		return
	end
	if handlersByProduct[productId] ~= nil then
		warn("[PurchaseService] Product registered twice:", productId)
	end
	handlersByProduct[productId] = handler
end

function PurchaseService.Prompt(player: Player, productId: number): (boolean, string?)
	if productId <= 0 or handlersByProduct[productId] == nil then
		return false, "NotAvailable"
	end
	local ok, err = pcall(function()
		MarketplaceService:PromptProductPurchase(player, productId)
	end)
	if not ok then
		warn("[PurchaseService] Prompt failed:", err)
		return false, "PromptFailed"
	end
	return true
end

function PurchaseService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	MarketplaceService.ProcessReceipt = processReceipt
end

return PurchaseService
