--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HudSlide = require(script.Parent.Parent.Components.HudSlide)
local ScreenRegistry = require(script.Parent.Parent.Components.ScreenRegistry)
local RarityGradient = require(script.Parent.Parent.Components.RarityGradient)
local ScrollCanvas = require(script.Parent.Parent.Components.ScrollCanvas)
local UiSound = require(script.Parent.Parent.Parent.Effects.UiSound)
local OpenAnimation = require(script.Parent.Parent.Components.OpenAnimation)
local ShopColors = require(ReplicatedStorage.Shared.Constants.ShopColors)

local SHOP_GUI_NAME = "ShopGui"
local BUTTON_LABEL_NAME = "Label"
local ITEM_CARD_NAME = "ItemCard"
local TEMPLATE_NAME = "ItemCardTemplate"
local BUY_ROW_NAME = "BuyRow"
local STOCK_FORMAT = "X%d STOCK"
local PRICE_FORMAT = "$%d"
local CARD_ORDER_STEP = 10
local SELECTED_STROKE_COLOR = Color3.new(1, 1, 1)
local DEFAULT_STROKE_COLOR = Color3.fromRGB(15, 15, 25)

local RARITY_BADGE_NAME = "RarityBadge"

export type ShopCategory = "Ore" | "Item"

export type ShopEntry = {
	Id: string,
	DisplayName: string,
	Stock: number,
	Price: number,
	Rarity: string,
	Image: string?,
	Color: Color3?,
}

local ShopScreen = {}

local isInitialized = false
local mainFrame: Frame? = nil
local itemList: ScrollingFrame? = nil
local cardTemplate: Frame? = nil
local buyRow: Frame? = nil
local selectedCard: Frame? = nil
local entryByCard: { [Frame]: ShopEntry } = {}
local restockLabel: TextLabel? = nil
local buyHandler: ((itemId: string) -> ())? = nil
local categoryHandler: ((category: ShopCategory) -> ())? = nil
local currentCategory: ShopCategory? = nil

local function setText(parent: Instance, childName: string, text: string)
	local target = parent:FindFirstChild(childName)
	local innerLabel = target and target:IsA("TextButton") and target:FindFirstChild(BUTTON_LABEL_NAME)
	local label = if innerLabel and innerLabel:IsA("TextLabel") then innerLabel else target
	if label and (label:IsA("TextLabel") or label:IsA("TextButton")) then
		label.Text = text
	end
end

local function setCardHighlight(card: Frame, isSelected: boolean)
	local slot = card:FindFirstChild("Slot")
	local stroke = slot and slot:FindFirstChild("SelectStroke")
	if stroke and stroke:IsA("UIStroke") then
		stroke.Color = if isSelected then SELECTED_STROKE_COLOR else DEFAULT_STROKE_COLOR
	end
end

local function deselectCard()
	if selectedCard then
		setCardHighlight(selectedCard, false)
	end
	selectedCard = nil
	if buyRow then
		buyRow.Visible = false
	end
end

local function showBuyRow(card: Frame)
	local row = buyRow
	if not row then
		return
	end
	local entry = entryByCard[card]
	if entry then
		setText(row, "BuyCoinsButton", string.format(PRICE_FORMAT, entry.Price))
	end
	row.LayoutOrder = card.LayoutOrder + 1
	row.Visible = true
end

local function selectCard(card: Frame)
	if selectedCard == card then
		deselectCard()
		return
	end
	deselectCard()
	selectedCard = card
	setCardHighlight(card, true)
	showBuyRow(card)
end

local function bindCard(child: Instance)
	if child.Name ~= ITEM_CARD_NAME or not child:IsA("Frame") then
		return
	end
	local card = child :: Frame
	local selectButton = card:WaitForChild("SelectButton")
	if not selectButton:IsA("GuiButton") then
		return
	end
	selectButton.Activated:Connect(function()
		selectCard(card)
	end)
	card.Destroying:Connect(function()
		entryByCard[card] = nil
		if selectedCard == card then
			deselectCard()
		end
	end)
end

local function fillCard(card: Frame, entry: ShopEntry)
	setText(card, "ItemName", entry.DisplayName)
	setText(card, "Stock", string.format(STOCK_FORMAT, entry.Stock))
	setText(card, "Price", string.format(PRICE_FORMAT, entry.Price))
	setText(card, "Rarity", entry.Rarity)
	local rarityBadge = card:FindFirstChild(RARITY_BADGE_NAME)
	if rarityBadge and rarityBadge:IsA("GuiObject") then
		RarityGradient.Apply(rarityBadge, entry.Rarity)
	end
	local slot = card:FindFirstChild("Slot")
	if slot and slot:IsA("GuiObject") then
		RarityGradient.Apply(slot, entry.Rarity)
	end
	local image = slot and slot:FindFirstChild("ItemImage")
	if not image or not image:IsA("ImageLabel") then
		return
	end
	if entry.Image then
		image.Image = entry.Image
	end
	if entry.Color then
		image.BackgroundColor3 = entry.Color
		image.BackgroundTransparency = 0
	end
end

local function findCardById(itemId: string): Frame?
	for card, entry in entryByCard do
		if entry.Id == itemId then
			return card
		end
	end
	return nil
end

local function bindBuyButton(row: Frame)
	local buyButton = row:FindFirstChild("BuyCoinsButton")
	if not buyButton or not buyButton:IsA("GuiButton") then
		warn("[ShopScreen] Missing BuyCoinsButton")
		return
	end
	buyButton.Activated:Connect(function()
		local card = selectedCard
		local entry = card and entryByCard[card]
		if entry and buyHandler then
			buyHandler(entry.Id)
		end
	end)
end

local function applyHeaderColor(category: ShopCategory)
	local header = mainFrame and mainFrame:FindFirstChild("Header")
	local gradient = header and header:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Color = ShopColors.HeaderGradients[category]
	end
end

local function selectCategory(category: ShopCategory)
	if currentCategory == category then
		return
	end
	deselectCard()
	currentCategory = category
	applyHeaderColor(category)
	if categoryHandler then
		categoryHandler(category)
	end
end

local function closeShop()
	local frame = mainFrame
	if not frame or not frame.Visible then
		return
	end
	deselectCard()
	OpenAnimation.Close(frame)
end

local function bindCloseButton(main: Instance)
	local closeButton = main:WaitForChild("Header"):WaitForChild("CloseButton")
	if closeButton:IsA("GuiButton") then
		closeButton.Activated:Connect(closeShop)
	end
end

function ShopScreen.Render(entries: { ShopEntry })
	local list = itemList
	local template = cardTemplate
	if not list or not template then
		warn("[ShopScreen] Render called before Init")
		return
	end
	local previousCard = selectedCard
	local previousEntry = previousCard and entryByCard[previousCard]
	local selectedId = previousEntry and previousEntry.Id
	deselectCard()
	for _, child in list:GetChildren() do
		if child.Name == ITEM_CARD_NAME then
			entryByCard[child :: Frame] = nil
			child:Destroy()
		end
	end
	for index, entry in entries do
		local card = template:Clone()
		card.Name = ITEM_CARD_NAME
		card.LayoutOrder = index * CARD_ORDER_STEP
		card.Visible = true
		fillCard(card, entry)
		entryByCard[card] = entry
		card.Parent = list
	end
	local reselectCard = selectedId and findCardById(selectedId)
	if reselectCard then
		selectCard(reselectCard)
	end
end

function ShopScreen.SetBuyHandler(handler: (itemId: string) -> ())
	buyHandler = handler
end

function ShopScreen.SetCategoryHandler(handler: (category: ShopCategory) -> ())
	categoryHandler = handler
end

function ShopScreen.GetCategory(): ShopCategory?
	return currentCategory
end

function ShopScreen.Open(category: ShopCategory)
	local frame = mainFrame
	if not frame then
		return
	end
	selectCategory(category)
	ScreenRegistry.CloseAllExcept(frame)
	OpenAnimation.Open(frame)
end

function ShopScreen.Close()
	closeShop()
end

function ShopScreen.SetHeaderIcon(image: string)
	local header = mainFrame and mainFrame:FindFirstChild("Header")
	local icon = header and header:FindFirstChild("Icon")
	if icon and icon:IsA("ImageLabel") then
		icon.Image = image
	end
end

function ShopScreen.SetRestockText(text: string)
	if restockLabel then
		restockLabel.Text = text
	end
end

function ShopScreen.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local main = playerGui:WaitForChild(SHOP_GUI_NAME):WaitForChild("Main")
	local list = main:WaitForChild("ItemList")
	local template = list:WaitForChild(TEMPLATE_NAME)
	local row = list:WaitForChild(BUY_ROW_NAME)
	if not main:IsA("Frame") or not list:IsA("ScrollingFrame") then
		warn("[ShopScreen] ShopGui has wrong structure")
		return
	end
	local mainAsFrame = main :: Frame
	local templateAsFrame = template :: Frame
	local rowAsFrame = row :: Frame
	templateAsFrame.Visible = false
	rowAsFrame.Visible = false
	mainAsFrame.Visible = false
	mainFrame = mainAsFrame
	UiSound.WatchOpen(mainAsFrame)
	OpenAnimation.Watch(mainAsFrame)
	HudSlide.TrackScreen(mainAsFrame)
	ScreenRegistry.Register(mainAsFrame)
	itemList = list :: ScrollingFrame
	cardTemplate = templateAsFrame
	buyRow = rowAsFrame
	local timer = main:WaitForChild("Header"):FindFirstChild("RestockTimer")
	if timer and timer:IsA("TextLabel") then
		restockLabel = timer
	end

	if not ScrollCanvas.BindToLayout(list :: ScrollingFrame) then
		warn("[ShopScreen] ItemList missing layout")
	end
	bindBuyButton(rowAsFrame)
	bindCloseButton(main)
	list.ChildAdded:Connect(bindCard)
end

return ShopScreen
