--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)

export type ProductHandler = (player: Player, purchaseId: string) -> boolean

local PurchaseService = {}

local isInitialized = false
local handlersByProduct: { [number]: ProductHandler } = {}

local function runHandler(handler: ProductHandler, player: Player, purchaseId: string): boolean
	local ok, result = pcall(handler, player, purchaseId)
	if not ok then
		warn("[PurchaseService] Handler failed:", result)
		return false
	end
	return result == true
end

local function processReceipt(receiptInfo: any): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	local handler = handlersByProduct[receiptInfo.ProductId]
	if player == nil or handler == nil or not DataService.IsLoaded(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local purchaseId = tostring(receiptInfo.PurchaseId)
	if DataActions.HasProcessedPurchase(player, purchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if not runHandler(handler, player, purchaseId) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local spent = receiptInfo.CurrencySpent
	if type(spent) == "number" and spent > 0 then
		DataActions.TryAddRobuxSpent(player, math.floor(spent))
	end
	DataService.Save(player)
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
