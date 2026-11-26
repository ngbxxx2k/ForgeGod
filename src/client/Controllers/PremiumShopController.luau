--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerAttributes = require(ReplicatedStorage.Shared.Constants.PlayerAttributes)
local PremiumShopConfig = require(ReplicatedStorage.Shared.Config.PremiumShopConfig)
local PremiumShopMessages = require(ReplicatedStorage.Shared.Constants.PremiumShopMessages)
local RemoteNames = require(ReplicatedStorage.Shared.Network.RemoteNames)
local UiIcons = require(ReplicatedStorage.Shared.Constants.UiIcons)
local NumberFormat = require(ReplicatedStorage.Shared.Utils.NumberFormat)
local BackpackMessages = require(ReplicatedStorage.Shared.Constants.BackpackMessages)
local ItemVisuals = require(ReplicatedStorage.Shared.Constants.ItemVisuals)
local PremiumShopScreen = require(script.Parent.Parent.UI.Screens.PremiumShopScreen)
local PremiumOreSection = require(script.Parent.Parent.UI.Components.PremiumOreSection)
local GiftController = require(script.Parent.GiftController)
local Toast = require(script.Parent.Parent.UI.Components.Toast)

type CardView = PremiumShopScreen.CardView
type OreView = PremiumShopScreen.OreView
type PremiumOreOption = PremiumOreSection.OreOption

local REMOTES_FOLDER_NAME = "Remotes"

local PremiumShopController = {}

local isInitialized = false
local localPlayer = Players.LocalPlayer
local requestPurchase: RemoteEvent? = nil

local function isPassOwned(passId: string): boolean
	return localPlayer:GetAttribute(PlayerAttributes.OwnedPassPrefix .. passId) == true
end

local function formatPrice(robuxPrice: number): string
	return string.format(PremiumShopMessages.PriceFormat, NumberFormat.WithCommas(robuxPrice))
end

local function buildPassView(pass: PremiumShopConfig.PassDefinition): CardView
	local text = PremiumShopMessages.Passes[pass.Id]
	return {
		Id = pass.Id,
		Kind = PremiumShopConfig.PurchaseKinds.Pass,
		Image = UiIcons.PremiumShop.Passes[pass.Id],
		Title = if text then text.Title else pass.Id,
		Description = if text then text.Description else nil,
		PriceText = formatPrice(pass.RobuxPrice),
		IsOwned = isPassOwned(pass.Id),
	}
end

local function buildCoinPackView(pack: PremiumShopConfig.CoinPackDefinition): CardView
	return {
		Id = pack.Id,
		Kind = PremiumShopConfig.PurchaseKinds.CoinPack,
		Image = UiIcons.PremiumShop.CoinPacks[pack.Id],
		AmountText = string.format(PremiumShopMessages.CoinsFormat, NumberFormat.Compact(pack.Coins)),
		PriceText = formatPrice(pack.RobuxPrice),
		IsOwned = false,
	}
end

local function buildOreOption(pack: PremiumShopConfig.OrePackDefinition): PremiumOreOption
	return {
		Kind = PremiumShopConfig.PurchaseKinds.OrePack,
		Id = pack.Id,
		AmountText = string.format(PremiumShopMessages.OreAmountFormat, pack.Amount),
		PriceText = NumberFormat.WithCommas(pack.RobuxPrice),
	}
end

local function buildOreViews(): { OreView }
	local views: { OreView } = {}
	local viewByOre: { [string]: OreView } = {}
	for _, pack in PremiumShopConfig.OrePacks do
		local view = viewByOre[pack.ItemId]
		if view == nil then
			local visual = ItemVisuals[pack.ItemId]
			local newView: OreView = {
				OreId = pack.ItemId,
				Title = BackpackMessages.ItemNames[pack.ItemId] or pack.ItemId,
				Image = visual and visual.Image,
				Rarity = visual and visual.RarityLabel,
				Options = {},
			}
			viewByOre[pack.ItemId] = newView
			table.insert(views, newView)
			view = newView
		end
		table.insert(view.Options, buildOreOption(pack))
	end
	return views
end

local function render()
	local views: { CardView } = {}
	for _, pass in PremiumShopConfig.Passes do
		table.insert(views, buildPassView(pass))
	end
	for _, pack in PremiumShopConfig.CoinPacks do
		table.insert(views, buildCoinPackView(pack))
	end
	PremiumShopScreen.Render(views)
end

local function onBuyRequested(kind: string, id: string)
	local remote = requestPurchase
	if remote then
		remote:FireServer(kind, id)
	end
end

local function onPurchaseResult(ok: any, reason: any, kind: any, id: any)
	if ok ~= true then
		local message = type(reason) == "string" and PremiumShopMessages.Reasons[reason]
		Toast.Error(message or PremiumShopMessages.UnknownError)
		return
	end
	local passText = kind == PremiumShopConfig.PurchaseKinds.Pass and PremiumShopMessages.Passes[id]
	if passText then
		Toast.Success(string.format(PremiumShopMessages.PassOwnedNotice, passText.Title))
	else
		Toast.Success(PremiumShopMessages.PurchaseSuccess)
	end
	render()
end

local function watchPassAttributes()
	for _, pass in PremiumShopConfig.Passes do
		local attribute = PlayerAttributes.OwnedPassPrefix .. pass.Id
		localPlayer:GetAttributeChangedSignal(attribute):Connect(render)
	end
end

function PremiumShopController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotes = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)
	requestPurchase = remotes:WaitForChild(RemoteNames.RequestPremiumPurchase) :: RemoteEvent
	local resultRemote = remotes:WaitForChild(RemoteNames.NotifyPremiumPurchaseResult) :: RemoteEvent

	PremiumShopScreen.SetBuyHandler(onBuyRequested)
	PremiumShopScreen.SetGiftHandler(GiftController.OpenGift)
	resultRemote.OnClientEvent:Connect(onPurchaseResult)
	watchPassAttributes()
	PremiumShopScreen.RenderOres(buildOreViews())
	render()
end

return PremiumShopController
