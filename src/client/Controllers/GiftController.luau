--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BackpackMessages = require(ReplicatedStorage.Shared.Constants.BackpackMessages)
local GiftMessages = require(ReplicatedStorage.Shared.Constants.GiftMessages)
local PremiumShopConfig = require(ReplicatedStorage.Shared.Config.PremiumShopConfig)
local PremiumShopMessages = require(ReplicatedStorage.Shared.Constants.PremiumShopMessages)
local RemoteNames = require(ReplicatedStorage.Shared.Network.RemoteNames)
local ShopConfig = require(ReplicatedStorage.Shared.Config.ShopConfig)
local NumberFormat = require(ReplicatedStorage.Shared.Utils.NumberFormat)
local GiftScreen = require(script.Parent.Parent.UI.Screens.GiftScreen)
local Toast = require(script.Parent.Parent.UI.Components.Toast)

local REMOTES_FOLDER_NAME = "Remotes"

local GiftController = {}

local isInitialized = false
local requestGift: RemoteEvent? = nil

local function getItemName(kind: any, id: any): string
	if kind == PremiumShopConfig.PurchaseKinds.Pass then
		local text = PremiumShopMessages.Passes[id]
		return if text then text.Title else tostring(id)
	end
	if kind == ShopConfig.RobuxPurchaseKinds.Item then
		return BackpackMessages.ItemNames[id] or tostring(id)
	end
	local pack = PremiumShopConfig.CoinPackById[id]
	if pack then
		return string.format(PremiumShopMessages.CoinsFormat, NumberFormat.Compact(pack.Coins))
	end
	return tostring(id)
end

local function onGiftResult(ok: any, reason: any, recipientName: any, isFallback: any)
	if ok ~= true then
		local message = type(reason) == "string" and GiftMessages.Reasons[reason]
		Toast.Error(message or GiftMessages.UnknownError)
		return
	end
	if isFallback == true then
		Toast.Success(GiftMessages.FallbackToSelf)
		return
	end
	Toast.Success(string.format(GiftMessages.GiftSentFormat, tostring(recipientName)))
end

local function onGiftReceived(kind: any, id: any, senderName: any)
	local itemName = getItemName(kind, id)
	Toast.Success(string.format(GiftMessages.GiftReceivedFormat, tostring(senderName), itemName))
end

function GiftController.OpenGift(kind: string, id: string)
	GiftScreen.Open(function(userId: number)
		local remote = requestGift
		if remote then
			remote:FireServer(kind, id, userId)
		end
	end)
end

function GiftController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotes = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)
	requestGift = remotes:WaitForChild(RemoteNames.RequestGiftPurchase) :: RemoteEvent
	local resultRemote = remotes:WaitForChild(RemoteNames.NotifyGiftResult) :: RemoteEvent
	local receivedRemote = remotes:WaitForChild(RemoteNames.NotifyGiftReceived) :: RemoteEvent
	resultRemote.OnClientEvent:Connect(onGiftResult)
	receivedRemote.OnClientEvent:Connect(onGiftReceived)
end

return GiftController
