--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PremiumShopMessages = require(ReplicatedStorage.Shared.Constants.PremiumShopMessages)
local UiIcons = require(ReplicatedStorage.Shared.Constants.UiIcons)
local GuiPath = require(script.Parent.Parent.Components.GuiPath)
local HudButton = require(script.Parent.Parent.Components.HudButton)
local HudSlide = require(script.Parent.Parent.Components.HudSlide)
local OpenAnimation = require(script.Parent.Parent.Components.OpenAnimation)
local PremiumOreSection = require(script.Parent.Parent.Components.PremiumOreSection)
local ScreenRegistry = require(script.Parent.Parent.Components.ScreenRegistry)
local ScrollCanvas = require(script.Parent.Parent.Components.ScrollCanvas)
local UiSound = require(script.Parent.Parent.Parent.Effects.UiSound)

local SHOP_GUI_NAME = "PremiumShopGui"
local HUD_BUTTON_NAME = "PremiumShopButton"
local CONTENT_PATH = { "Main", "Content" }
local CLOSE_BUTTON_PATH = { "Main", "Header", "CloseButton" }
local BUY_BUTTON_NAME = "BuyButton"
local GIFT_BUTTON_NAME = "GiftButton"
local HOVER_ATTRIBUTE = "HasHoverEffect"
local ORE_TITLE_TEMPLATE_NAME = "MoneyTitle"
local ORE_ROW_TEMPLATE_NAME = "PackRowTop"
local ORE_CARD_TEMPLATE_NAME = "Coins30K"
local OWNED_BUTTON_COLORS = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(190, 195, 205)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 125, 140)),
})

export type CardView = {
	Id: string,
	Kind: string,
	Image: string?,
	Title: string?,
	Description: string?,
	AmountText: string?,
	PriceText: string,
	IsOwned: boolean,
}

export type OreView = PremiumOreSection.OreView

type BuyHandler = (kind: string, id: string) -> ()

type GiftHandler = (kind: string, id: string) -> ()

local PremiumShopScreen = {}

local isInitialized = false
local container: GuiObject? = nil
local content: Instance? = nil
local buyHandler: BuyHandler? = nil
local giftHandler: GiftHandler? = nil
local boundCards: { [Instance]: CardView } = {}
local defaultButtonColors: { [Instance]: ColorSequence } = {}

local function close()
	local root = container
	if root then
		OpenAnimation.Close(root)
	end
end

local function toggle()
	local root = container
	if root == nil then
		return
	end
	if root.Visible then
		close()
		return
	end
	ScreenRegistry.CloseAllExcept(root)
	root.Visible = true
end

local function onBuyActivated(card: Instance)
	local view = boundCards[card]
	local handler = buyHandler
	if view and handler and not view.IsOwned then
		handler(view.Kind, view.Id)
	end
end

local function onGiftActivated(card: Instance)
	local view = boundCards[card]
	local handler = giftHandler
	if view and handler then
		handler(view.Kind, view.Id)
	end
end

local function bindGiftButton(card: Instance)
	local button = card:FindFirstChild(GIFT_BUTTON_NAME)
	if not button or not button:IsA("GuiButton") then
		return
	end
	button:SetAttribute(HOVER_ATTRIBUTE, true)
	local hasIcon = UiIcons.Gift ~= ""
	GuiPath.SetImage(button, { "Icon" }, UiIcons.Gift)
	GuiPath.SetVisible(button, { "Icon" }, hasIcon)
	GuiPath.SetVisible(button, { "IconFallback" }, not hasIcon)
	button.Activated:Connect(function()
		onGiftActivated(card)
	end)
end

local function bindCard(card: Instance)
	local button = card:FindFirstChild(BUY_BUTTON_NAME)
	if not button or not button:IsA("GuiButton") then
		warn("[PremiumShopScreen] Missing BuyButton on", card.Name)
		return
	end
	button:SetAttribute(HOVER_ATTRIBUTE, true)
	local gradient = button:FindFirstChildOfClass("UIGradient")
	if gradient then
		defaultButtonColors[button] = gradient.Color
	end
	button.Activated:Connect(function()
		onBuyActivated(card)
	end)
	bindGiftButton(card)
end

local function applyButtonState(card: Instance, isOwned: boolean)
	local button = card:FindFirstChild(BUY_BUTTON_NAME)
	if button == nil then
		return
	end
	local gradient = button:FindFirstChildOfClass("UIGradient")
	local defaultColors = defaultButtonColors[button]
	if gradient and defaultColors then
		gradient.Color = if isOwned then OWNED_BUTTON_COLORS else defaultColors
	end
	GuiPath.SetVisible(button, { "PriceRow" }, not isOwned)
	GuiPath.SetVisible(button, { "OwnedLabel" }, isOwned)
	GuiPath.SetText(button, { "OwnedLabel" }, PremiumShopMessages.Owned)
end

local function applyCard(card: Instance, view: CardView)
	GuiPath.SetImage(card, { "Icon" }, view.Image)
	if view.Title then
		GuiPath.SetText(card, { "Title" }, view.Title)
	end
	if view.Description then
		GuiPath.SetText(card, { "Description" }, view.Description)
	end
	if view.AmountText then
		GuiPath.SetText(card, { "AmountLabel" }, view.AmountText)
	end
	GuiPath.SetText(card, { BUY_BUTTON_NAME, "PriceRow", "PriceLabel" }, view.PriceText)
	GuiPath.SetImage(card, { BUY_BUTTON_NAME, "PriceRow", "RobuxIcon" }, UiIcons.Robux)
	applyButtonState(card, view.IsOwned)
end

function PremiumShopScreen.Render(views: { CardView })
	local list = content
	if list == nil then
		warn("[PremiumShopScreen] Render called before Init")
		return
	end
	for _, view in views do
		local card = list:FindFirstChild(view.Id, true)
		if card == nil then
			warn("[PremiumShopScreen] Missing card", view.Id)
			continue
		end
		if boundCards[card] == nil then
			bindCard(card)
		end
		boundCards[card] = view
		applyCard(card, view)
	end
end

local function getOreTemplates(list: Instance): PremiumOreSection.Templates?
	local title = list:FindFirstChild(ORE_TITLE_TEMPLATE_NAME)
	local row = list:FindFirstChild(ORE_ROW_TEMPLATE_NAME)
	local card = row and row:FindFirstChild(ORE_CARD_TEMPLATE_NAME)
	if not title or not title:IsA("GuiObject") or not row or not row:IsA("GuiObject") then
		return nil
	end
	if not card or not card:IsA("GuiObject") then
		return nil
	end
	return { Title = title, Row = row, Card = card, RobuxImage = UiIcons.Robux }
end

function PremiumShopScreen.RenderOres(views: { OreView })
	local list = content
	local templates = list and getOreTemplates(list)
	if list == nil or templates == nil then
		warn("[PremiumShopScreen] Cannot build ore section")
		return
	end
	PremiumOreSection.Build(list, templates, PremiumShopMessages.OresTitle, views, function(kind: string, id: string)
		if buyHandler then
			buyHandler(kind, id)
		end
	end)
end

function PremiumShopScreen.SetBuyHandler(handler: BuyHandler)
	buyHandler = handler
end

function PremiumShopScreen.SetGiftHandler(handler: GiftHandler)
	giftHandler = handler
end

local function applyStaticContent(root: Instance)
	GuiPath.SetImage(root, { "Main", "Header", "Icon" }, UiIcons.PremiumShop.Header)
	GuiPath.SetText(root, { "Main", "Content", "PassesTitle" }, PremiumShopMessages.PassesTitle)
	GuiPath.SetText(root, { "Main", "Content", "MoneyTitle" }, PremiumShopMessages.MoneyTitle)
end

function PremiumShopScreen.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = playerGui:WaitForChild(SHOP_GUI_NAME)
	local root = gui:WaitForChild("Container")
	local list = GuiPath.Find(root, CONTENT_PATH)
	if not root:IsA("GuiObject") or list == nil then
		warn("[PremiumShopScreen] PremiumShopGui has wrong structure")
		return
	end
	root.Visible = false
	if gui:IsA("ScreenGui") then
		gui.Enabled = true
	end
	container, content = root, list
	if list:IsA("ScrollingFrame") and not ScrollCanvas.BindToLayout(list) then
		warn("[PremiumShopScreen] Content has no layout")
	end
	UiSound.WatchOpen(root)
	OpenAnimation.Watch(root)
	HudSlide.TrackScreen(root)
	ScreenRegistry.Register(root)
	applyStaticContent(root)
	local closeButton = GuiPath.Find(root, CLOSE_BUTTON_PATH)
	if closeButton and closeButton:IsA("GuiButton") then
		closeButton:SetAttribute(HOVER_ATTRIBUTE, true)
		closeButton.Activated:Connect(close)
	end
	HudButton.Bind(HUD_BUTTON_NAME, toggle)
end

return PremiumShopScreen
