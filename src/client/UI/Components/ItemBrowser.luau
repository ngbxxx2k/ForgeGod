--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BackpackMessages = require(ReplicatedStorage.Shared.Constants.BackpackMessages)
local SellMessages = require(ReplicatedStorage.Shared.Constants.SellMessages)
local UiIcons = require(ReplicatedStorage.Shared.Constants.UiIcons)
local NumberFormat = require(ReplicatedStorage.Shared.Utils.NumberFormat)
local WeaponWeight = require(ReplicatedStorage.Shared.Utils.WeaponWeight)
local WeatherMessages = require(ReplicatedStorage.Shared.Constants.WeatherMessages)
local GuiPath = require(script.Parent.GuiPath)
local RarityGradient = require(script.Parent.RarityGradient)
local UiSound = require(script.Parent.Parent.Parent.Effects.UiSound)
local OpenAnimation = require(script.Parent.OpenAnimation)

local SLOT_TEMPLATE_NAME = "ItemSlotTemplate"
local SLOT_NAME = "ItemSlot"
local DETAIL_PANEL_NAME = "DetailPanel"
local DETAIL_CONTENT_NAME = "Content"
local ACTION_BUTTON_NAME = "ActionButton"
local SELL_BUTTON_NAME = "SellButton"
local SELL_ALL_BUTTON_NAME = "SellAllButton"
local BUTTON_LABEL_NAME = "Label"
local LOCK_BUTTON_NAME = "LockButton"
local MUTATION_LABEL_NAME = "MutationLabel"
local WEIGHT_LABEL_NAME = "WeightLabel"
local ITEM_ID_ATTRIBUTE = "ItemId"
local SLOT_SELECTED_COLOR = Color3.new(1, 1, 1)
local SLOT_DEFAULT_COLOR = Color3.fromRGB(15, 15, 25)

export type ItemCategory = "Ore" | "Buff" | "Weapon"

export type BackpackItem = {
	Id: string,
	Category: ItemCategory,
	DisplayName: string,
	Amount: number,
	Price: number,
	Image: string?,
	Color: Color3?,
	Rarity: string?,
	Level: number?,
	Description: string?,
	IsEquipped: boolean?,
	IsHeld: boolean?,
	Income: number?,
	IsBroken: boolean?,
	IsLocked: boolean?,
	Mutation: string?,
	Weight: number?,
}

export type Options = {
	GetActionText: (BackpackItem) -> string?,
	CanSell: ((BackpackItem) -> boolean)?,
	CanSellAll: ((BackpackItem) -> boolean)?,
	GetSellText: ((BackpackItem) -> string)?,
	OnClose: (() -> ())?,
}

export type SellHandler = (item: BackpackItem, isSellAll: boolean) -> ()

export type ItemBrowser = {
	Render: (items: { BackpackItem }) -> (),
	SetActionHandler: (handler: (BackpackItem) -> ()) -> (),
	SetSellHandler: (handler: SellHandler) -> (),
	SetLockHandler: (handler: (BackpackItem) -> ()) -> (),
	SetVisible: (isVisible: boolean) -> (),
	IsVisible: () -> boolean,
	Reset: () -> (),
}

type Parts = {
	Main: Frame,
	Grid: ScrollingFrame,
	Detail: Frame,
	Template: GuiButton,
	Search: TextBox,
}

local ItemBrowser = {}

local function getMutationText(mutation: string?): string
	if not mutation then
		return BackpackMessages.NoMutationText
	end
	local mutationName = WeatherMessages.MutationNames[mutation] or mutation
	return string.format(BackpackMessages.MutationFormat, mutationName)
end

local function getSlotBadgeText(item: BackpackItem): string
	if item.Category == "Weapon" then
		return string.format(BackpackMessages.LevelFormat, item.Level or 0)
	end
	return string.format(BackpackMessages.AmountFormat, item.Amount)
end

local function ensureWeightLabel(content: Instance): TextLabel?
	local existing = content:FindFirstChild(WEIGHT_LABEL_NAME)
	if existing and existing:IsA("TextLabel") then
		return existing
	end
	local mutation = content:FindFirstChild(MUTATION_LABEL_NAME)
	if not mutation or not mutation:IsA("TextLabel") then
		return nil
	end
	local order = mutation.LayoutOrder
	for _, sibling in content:GetChildren() do
		if sibling:IsA("GuiObject") and sibling.LayoutOrder > order then
			sibling.LayoutOrder += 1
		end
	end
	local label = mutation:Clone()
	label.Name = WEIGHT_LABEL_NAME
	label.LayoutOrder = order + 1
	label.Parent = content
	return label
end

local function showWeight(content: Instance, item: BackpackItem, isWeapon: boolean)
	local label = ensureWeightLabel(content)
	if label == nil then
		return
	end
	local weight = item.Weight
	label.Visible = isWeapon and weight ~= nil
	if weight then
		label.Text = string.format(BackpackMessages.WeightFormat, WeaponWeight.Format(weight))
	end
end

local function showWeaponInfo(content: Instance, item: BackpackItem, isWeapon: boolean)
	GuiPath.SetVisible(content, { "RarityLabel" }, isWeapon and item.Rarity ~= nil)
	GuiPath.SetVisible(content, { "MutationLabel" }, isWeapon)
	showWeight(content, item, isWeapon)
	if not isWeapon then
		return
	end
	GuiPath.SetText(content, { "RarityLabel" }, item.Rarity or "")
	local rarityLabel = content:FindFirstChild("RarityLabel")
	if rarityLabel and rarityLabel:IsA("GuiObject") then
		RarityGradient.Apply(rarityLabel, item.Rarity)
	end
	GuiPath.SetText(content, { "MutationLabel" }, getMutationText(item.Mutation))
end

local function setButton(detail: Frame, buttonName: string, text: string?)
	local button = detail:FindFirstChild(buttonName, true)
	if button and button:IsA("GuiButton") then
		button.Visible = text ~= nil
		if not text then
			return
		end
		local innerLabel = button:FindFirstChild(BUTTON_LABEL_NAME)
		if innerLabel and innerLabel:IsA("TextLabel") then
			innerLabel.Text = text
		elseif button:IsA("TextButton") then
			button.Text = text
		end
	end
end

local function showLockButton(detail: Frame, item: BackpackItem)
	local button = detail:FindFirstChild(LOCK_BUTTON_NAME)
	if not button or not button:IsA("ImageButton") then
		return
	end
	button.Visible = item.Category == "Weapon"
	button.Image = if item.IsLocked then UiIcons.Locked else UiIcons.Unlocked
end

local function fillDetail(detail: Frame, item: BackpackItem, actionText: string?)
	local content = detail:FindFirstChild(DETAIL_CONTENT_NAME)
	if not content then
		warn("[ItemBrowser] Missing", DETAIL_CONTENT_NAME)
		return
	end
	local isWeapon = item.Category == "Weapon"
	GuiPath.SetText(content, { "NameLabel" }, item.DisplayName)
	local levelText = string.format(BackpackMessages.LevelFormat, item.Level or 0)
	GuiPath.SetText(content, { "PriceRow", "LevelLabel" }, levelText)
	GuiPath.SetVisible(content, { "PriceRow", "LevelLabel" }, isWeapon and item.Level ~= nil)
	local priceText = if isWeapon and item.Income
		then string.format(BackpackMessages.IncomeFormat, NumberFormat.Abbreviate(item.Income))
		else string.format(BackpackMessages.PriceFormat, NumberFormat.Abbreviate(item.Price))
	GuiPath.SetText(content, { "PriceRow", "PriceLabel" }, priceText)
	GuiPath.SetImage(content, { "ItemImage" }, item.Image)
	GuiPath.SetImageColor(content, { "ItemImage" }, item.Color)
	showWeaponInfo(content, item, isWeapon)
	GuiPath.SetText(content, { "InfoBox", "DescriptionLabel" }, item.Description or "")
	GuiPath.SetVisible(content, { "InfoBox" }, item.Category == "Buff")
	setButton(detail, ACTION_BUTTON_NAME, actionText)
	showLockButton(detail, item)
end

local function highlightSlot(grid: ScrollingFrame, itemId: string)
	for _, child in grid:GetChildren() do
		if child.Name == SLOT_NAME then
			local isSelected = child:GetAttribute(ITEM_ID_ATTRIBUTE) == itemId
			local color = if isSelected then SLOT_SELECTED_COLOR else SLOT_DEFAULT_COLOR
			GuiPath.SetBorderColor(child, color)
		end
	end
end

local function applySearch(grid: ScrollingFrame, input: TextBox)
	local query = string.lower(input.Text)
	for _, child in grid:GetChildren() do
		local nameLabel = child:FindFirstChild("NameLabel")
		if child.Name ~= SLOT_NAME or not child:IsA("GuiObject") then
			continue
		end
		if nameLabel and nameLabel:IsA("TextLabel") then
			local name = string.lower(nameLabel.Text)
			child.Visible = query == "" or string.find(name, query, 1, true) ~= nil
		end
	end
end

local function createSlot(template: GuiButton, item: BackpackItem, order: number): GuiButton
	local slot = template:Clone()
	slot.Name = SLOT_NAME
	slot.LayoutOrder = order
	slot.Visible = true
	slot:SetAttribute(ITEM_ID_ATTRIBUTE, item.Id)
	RarityGradient.Apply(slot, item.Rarity)
	GuiPath.SetText(slot, { "NameLabel" }, item.DisplayName)
	GuiPath.SetText(slot, { "AmountLabel" }, getSlotBadgeText(item))
	GuiPath.SetImage(slot, { "ItemImage" }, item.Image)
	GuiPath.SetImageColor(slot, { "ItemImage" }, item.Color)
	return slot
end

local function findParts(main: Frame): Parts?
	local grid = main:FindFirstChild("ItemGrid")
	local detail = main:FindFirstChild(DETAIL_PANEL_NAME)
	local template = grid and grid:FindFirstChild(SLOT_TEMPLATE_NAME)
	local search = GuiPath.Find(main, { "Header", "SearchBox", "SearchInput" })
	if not grid or not grid:IsA("ScrollingFrame") or not detail or not detail:IsA("Frame") then
		warn("[ItemBrowser] Wrong structure in", main:GetFullName())
		return nil
	end
	if not template or not template:IsA("GuiButton") or not search or not search:IsA("TextBox") then
		warn("[ItemBrowser] Missing template or search in", main:GetFullName())
		return nil
	end
	return { Main = main, Grid = grid, Detail = detail, Template = template, Search = search }
end

local function bindButton(parent: Instance, path: { string }, onActivated: () -> ())
	local button = GuiPath.Find(parent, path)
	if button and button:IsA("GuiButton") then
		button.Activated:Connect(onActivated)
	end
end

local function bindDetailButton(detail: Frame, buttonName: string, onActivated: () -> ())
	local button = detail:FindFirstChild(buttonName, true)
	if button and button:IsA("GuiButton") then
		button.Activated:Connect(onActivated)
	end
end

function ItemBrowser.Create(main: Frame, options: Options): ItemBrowser?
	local parts = findParts(main)
	if not parts then
		return nil
	end
	parts.Template.Visible = false
	local selectedItem: BackpackItem? = nil
	local actionHandler: ((BackpackItem) -> ())? = nil
	local sellHandler: SellHandler? = nil
	local lockHandler: ((BackpackItem) -> ())? = nil

	local function showSellButtons(item: BackpackItem)
		local canSell = options.CanSell ~= nil and options.CanSell(item)
		local canSellAll = options.CanSellAll ~= nil and options.CanSellAll(item)
		local sellText = if options.GetSellText then options.GetSellText(item) else SellMessages.SellText
		setButton(parts.Detail, SELL_BUTTON_NAME, if canSell then sellText else nil)
		setButton(parts.Detail, SELL_ALL_BUTTON_NAME, if canSellAll then SellMessages.SellAllText else nil)
	end

	local function showDetail(item: BackpackItem)
		parts.Detail.Visible = true
		selectedItem = item
		fillDetail(parts.Detail, item, options.GetActionText(item))
		showSellButtons(item)
	end

	local function sellSelected(isSellAll: boolean)
		local item, handler = selectedItem, sellHandler
		if item and handler then
			handler(item, isSellAll)
		end
	end

	local function getDefaultFocus(items: { BackpackItem }): BackpackItem?
		local previous = selectedItem
		local first = items[1]
		if previous and (first == nil or first.Category == previous.Category) then
			return nil
		end
		return first
	end

	local function render(items: { BackpackItem })
		local previousId = selectedItem and selectedItem.Id
		GuiPath.ClearChildren(parts.Grid, SLOT_NAME)
		local focusItem = getDefaultFocus(items)
		for index, item in items do
			local slot = createSlot(parts.Template, item, index)
			slot.Activated:Connect(function()
				highlightSlot(parts.Grid, item.Id)
				showDetail(item)
			end)
			slot.Parent = parts.Grid
			if item.Id == previousId then
				focusItem = item
			end
		end
		applySearch(parts.Grid, parts.Search)
		if focusItem then
			highlightSlot(parts.Grid, focusItem.Id)
			showDetail(focusItem)
		else
			selectedItem = nil
			parts.Detail.Visible = false
		end
	end

	UiSound.WatchOpen(main)
	OpenAnimation.Watch(main)
	bindButton(main, { "Header", "CloseButton" }, function()
		OpenAnimation.Close(main)
		if options.OnClose then
			options.OnClose()
		end
	end)
	bindDetailButton(parts.Detail, ACTION_BUTTON_NAME, function()
		local item, handler = selectedItem, actionHandler
		if item and handler then
			handler(item)
		end
	end)
	bindDetailButton(parts.Detail, SELL_BUTTON_NAME, function()
		sellSelected(false)
	end)
	bindDetailButton(parts.Detail, SELL_ALL_BUTTON_NAME, function()
		sellSelected(true)
	end)
	bindDetailButton(parts.Detail, LOCK_BUTTON_NAME, function()
		local item, handler = selectedItem, lockHandler
		if item and handler then
			handler(item)
		end
	end)
	parts.Search:GetPropertyChangedSignal("Text"):Connect(function()
		applySearch(parts.Grid, parts.Search)
	end)

	return {
		Render = render,
		SetActionHandler = function(handler: (BackpackItem) -> ())
			actionHandler = handler
		end,
		SetSellHandler = function(handler: SellHandler)
			sellHandler = handler
		end,
		SetLockHandler = function(handler: (BackpackItem) -> ())
			lockHandler = handler
		end,
		SetVisible = function(isVisible: boolean)
			main.Visible = isVisible
		end,
		IsVisible = function(): boolean
			return main.Visible
		end,
		Reset = function()
			selectedItem = nil
			parts.Detail.Visible = false
			parts.Search.Text = ""
		end,
	}
end

return ItemBrowser
