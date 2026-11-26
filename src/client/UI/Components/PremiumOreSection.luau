--!strict

local GuiPath = require(script.Parent.GuiPath)
local RarityGradient = require(script.Parent.RarityGradient)

export type OreOption = {
	Kind: string,
	Id: string,
	AmountText: string,
	PriceText: string,
}

export type OreView = {
	OreId: string,
	Title: string,
	Image: string?,
	Rarity: string?,
	Options: { OreOption },
}

export type Templates = {
	Title: GuiObject,
	Row: GuiObject,
	Card: GuiObject,
	RobuxImage: string,
}

type BuyCallback = (kind: string, id: string) -> ()

local SECTION_TITLE_NAME = "OresTitle"
local ROW_NAME = "OreRow"
local CARD_NAME_PREFIX = "Ore_"
local BUY_BUTTON_NAME = "BuyButton"
local GIFT_BUTTON_NAME = "GiftButton"
local AMOUNT_LABEL_NAME = "AmountLabel"
local PRICE_ROW_NAME = "PriceRow"
local PRICE_LABEL_NAME = "PriceLabel"
local ROBUX_ICON_NAME = "RobuxIcon"
local QUANTITY_LABEL_NAME = "QuantityLabel"
local HOVER_ATTRIBUTE = "HasHoverEffect"
local CARDS_PER_ROW = 3
local FIRST_LAYOUT_ORDER = 100
local BUTTON_WIDTH = 0.44
local BUTTON_EDGE = 0.04
local QUANTITY_WIDTH = 0.28
local PRICE_WIDTH = 0.42
local QUANTITY_ORDER = 1
local ICON_ORDER = 2
local PRICE_ORDER = 3

local PremiumOreSection = {}

local function clearGuiChildren(parent: Instance)
	for _, child in parent:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function preparePriceRow(button: Instance, option: OreOption, robuxImage: string)
	local row = button:FindFirstChild(PRICE_ROW_NAME)
	local price = row and row:FindFirstChild(PRICE_LABEL_NAME)
	if not row or not price or not price:IsA("TextLabel") then
		return
	end
	local layout = row:FindFirstChildOfClass("UIListLayout")
	if layout then
		layout.SortOrder = Enum.SortOrder.LayoutOrder
	end
	local quantity = price:Clone()
	quantity.Name = QUANTITY_LABEL_NAME
	quantity.Text = option.AmountText
	quantity.LayoutOrder = QUANTITY_ORDER
	quantity.Size = UDim2.fromScale(QUANTITY_WIDTH, 1)
	quantity.Parent = row
	price.Text = option.PriceText
	price.LayoutOrder = PRICE_ORDER
	price.Size = UDim2.fromScale(PRICE_WIDTH, 1)
	GuiPath.SetImage(row, { ROBUX_ICON_NAME }, robuxImage)
	local icon = row:FindFirstChild(ROBUX_ICON_NAME)
	if icon and icon:IsA("GuiObject") then
		icon.LayoutOrder = ICON_ORDER
	end
end

local function placeButton(button: GuiObject, isRight: boolean)
	local height = button.Size.Y
	local positionY = button.Position.Y
	button.Size = UDim2.new(BUTTON_WIDTH, 0, height.Scale, height.Offset)
	if isRight then
		button.AnchorPoint = Vector2.new(1, 1)
		button.Position = UDim2.new(1 - BUTTON_EDGE, 0, positionY.Scale, positionY.Offset)
	else
		button.AnchorPoint = Vector2.new(0, 1)
		button.Position = UDim2.new(BUTTON_EDGE, 0, positionY.Scale, positionY.Offset)
	end
end

local function createOptionButton(
	source: GuiButton,
	option: OreOption,
	isRight: boolean,
	robuxImage: string,
	onBuy: BuyCallback
): GuiButton
	local button = source:Clone()
	button.Name = BUY_BUTTON_NAME .. option.Id
	button:SetAttribute(HOVER_ATTRIBUTE, true)
	GuiPath.SetVisible(button, { "OwnedLabel" }, false)
	placeButton(button, isRight)
	preparePriceRow(button, option, robuxImage)
	button.Activated:Connect(function()
		onBuy(option.Kind, option.Id)
	end)
	return button
end

local function createCard(templates: Templates, view: OreView, order: number, onBuy: BuyCallback): GuiObject?
	local card = templates.Card:Clone()
	local source = card:FindFirstChild(BUY_BUTTON_NAME)
	if not source or not source:IsA("GuiButton") then
		card:Destroy()
		return nil
	end
	card.Name = CARD_NAME_PREFIX .. view.OreId
	card.LayoutOrder = order
	local gift = card:FindFirstChild(GIFT_BUTTON_NAME)
	if gift then
		gift:Destroy()
	end
	source.Parent = nil
	GuiPath.SetImage(card, { "Icon" }, view.Image)
	GuiPath.SetText(card, { AMOUNT_LABEL_NAME }, view.Title)
	RarityGradient.Apply(card, view.Rarity)
	for index, option in view.Options do
		createOptionButton(source, option, index > 1, templates.RobuxImage, onBuy).Parent = card
	end
	source:Destroy()
	return card
end

local function createRow(templates: Templates, order: number): GuiObject
	local row = templates.Row:Clone()
	row.Name = ROW_NAME
	row.LayoutOrder = order
	clearGuiChildren(row)
	return row
end

local function createTitle(templates: Templates, text: string, order: number): GuiObject
	local title = templates.Title:Clone()
	title.Name = SECTION_TITLE_NAME
	title.LayoutOrder = order
	if title:IsA("TextLabel") then
		title.Text = text
	end
	return title
end

function PremiumOreSection.Build(
	content: Instance,
	templates: Templates,
	titleText: string,
	views: { OreView },
	onBuy: BuyCallback
)
	createTitle(templates, titleText, FIRST_LAYOUT_ORDER).Parent = content
	local row: GuiObject? = nil
	for index, view in views do
		local slot = (index - 1) % CARDS_PER_ROW
		if slot == 0 then
			local newRow = createRow(templates, FIRST_LAYOUT_ORDER + index)
			newRow.Parent = content
			row = newRow
		end
		local card = createCard(templates, view, slot + 1, onBuy)
		if card and row then
			card.Parent = row
		end
	end
end

return PremiumOreSection
