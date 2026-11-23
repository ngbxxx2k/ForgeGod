--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GuiPath = require(script.Parent.Parent.Components.GuiPath)
local HudButton = require(script.Parent.Parent.Components.HudButton)
local HudSlide = require(script.Parent.Parent.Components.HudSlide)
local ScreenRegistry = require(script.Parent.Parent.Components.ScreenRegistry)
local ItemBrowser = require(script.Parent.Parent.Components.ItemBrowser)
local BackpackMessages = require(ReplicatedStorage.Shared.Constants.BackpackMessages)
local SellMessages = require(ReplicatedStorage.Shared.Constants.SellMessages)

local BACKPACK_GUI_NAME = "BackpackGui"
local BACKPACK_BUTTON_NAME = "InventoryButton"
local TAB_TEMPLATE_NAME = "TabButtonTemplate"
local TAB_NAME = "TabButton"
local TAB_ID_ATTRIBUTE = "TabId"
local TAB_SELECTED_COLOR = Color3.new(1, 1, 1)
local TAB_DEFAULT_COLOR = Color3.fromRGB(15, 15, 25)
local TAB_DEFAULT_TEXT_COLOR = Color3.fromRGB(170, 175, 195)
local STORAGE_BUTTON_GAP = 8

export type ItemCategory = ItemBrowser.ItemCategory
export type BackpackItem = ItemBrowser.BackpackItem

export type BackpackTab = {
	Id: string,
	DisplayName: string,
	Image: string?,
}

local BackpackScreen = {}

local isInitialized = false
local mainFrame: Frame? = nil
local tabList: Frame? = nil
local tabTemplate: GuiButton? = nil
local browser: ItemBrowser.ItemBrowser? = nil
local storageAddHandler: (() -> ())? = nil
local openHandler: (() -> ())? = nil

local function getActionText(item: BackpackItem): string?
	if item.Category == "Buff" then
		return BackpackMessages.UseText
	elseif item.Category == "Weapon" and item.IsHeld then
		return BackpackMessages.UnequipText
	elseif item.Category == "Weapon" and not item.IsBroken then
		return BackpackMessages.EquipText
	end
	return nil
end

local function canSell(item: BackpackItem): boolean
	if item.Category ~= "Weapon" then
		return item.Amount > 0
	end
	return not item.IsEquipped and not item.IsLocked
end

local function canSellAll(item: BackpackItem): boolean
	if item.Category == "Weapon" then
		return not item.IsLocked
	end
	return item.Amount > 0
end

local function getSellText(item: BackpackItem): string
	return if item.Category == "Weapon" then SellMessages.SellText else SellMessages.SellOneText
end

local function styleTab(button: Instance, isSelected: boolean)
	local circle = button:FindFirstChild("Circle")
	if circle then
		GuiPath.SetBorderColor(circle, if isSelected then TAB_SELECTED_COLOR else TAB_DEFAULT_COLOR)
	end
	local nameLabel = button:FindFirstChild("NameLabel")
	if nameLabel and nameLabel:IsA("TextLabel") then
		nameLabel.TextColor3 = if isSelected then TAB_SELECTED_COLOR else TAB_DEFAULT_TEXT_COLOR
	end
end

local function highlightTab(selectedId: string)
	local list = tabList
	if not list then
		return
	end
	for _, child in list:GetChildren() do
		if child.Name == TAB_NAME then
			styleTab(child, child:GetAttribute(TAB_ID_ATTRIBUTE) == selectedId)
		end
	end
end

local function createTab(template: GuiButton, tab: BackpackTab, order: number, onSelected: (string) -> ())
	local button = template:Clone()
	button.Name = TAB_NAME
	button.LayoutOrder = order
	button.Visible = true
	button:SetAttribute(TAB_ID_ATTRIBUTE, tab.Id)
	GuiPath.SetText(button, { "NameLabel" }, tab.DisplayName)
	GuiPath.SetImage(button, { "Circle", "Icon" }, tab.Image)
	button.Activated:Connect(function()
		highlightTab(tab.Id)
		onSelected(tab.Id)
	end)
	return button
end

local function bindStorageButton(main: Frame)
	local storageLabel = main:WaitForChild("StorageLabel")
	local addButton = main:WaitForChild("StorageAddButton")
	if not storageLabel:IsA("TextLabel") or not addButton:IsA("GuiButton") then
		warn("[BackpackScreen] Storage row has wrong structure")
		return
	end
	local function placeButton()
		local offset = storageLabel.TextBounds.X + STORAGE_BUTTON_GAP
		local labelX = storageLabel.Position.X.Scale
		addButton.Position = UDim2.new(labelX, offset, addButton.Position.Y.Scale, 0)
	end
	storageLabel:GetPropertyChangedSignal("TextBounds"):Connect(placeButton)
	placeButton()
	addButton.Activated:Connect(function()
		local handler = storageAddHandler
		if handler then
			handler()
		end
	end)
end

function BackpackScreen.RenderItems(items: { BackpackItem })
	local itemBrowser = browser
	if not itemBrowser then
		warn("[BackpackScreen] RenderItems called before Init")
		return
	end
	itemBrowser.Render(items)
end

function BackpackScreen.RenderTabs(tabs: { BackpackTab }, selectedId: string?, onSelected: (string) -> ())
	local list = tabList
	local template = tabTemplate
	if not list or not template then
		warn("[BackpackScreen] RenderTabs called before Init")
		return
	end
	GuiPath.ClearChildren(list, TAB_NAME)
	for index, tab in tabs do
		createTab(template, tab, index, onSelected).Parent = list
	end
	if selectedId then
		highlightTab(selectedId)
	end
end

function BackpackScreen.SetStorage(used: number, capacity: number)
	if mainFrame then
		local storageText = string.format(BackpackMessages.StorageFormat, used, capacity)
		GuiPath.SetText(mainFrame, { "StorageLabel" }, storageText)
	end
end

function BackpackScreen.SetActionHandler(handler: (BackpackItem) -> ())
	local itemBrowser = browser
	if itemBrowser then
		itemBrowser.SetActionHandler(handler)
	end
end

function BackpackScreen.SetSellHandler(handler: ItemBrowser.SellHandler)
	local itemBrowser = browser
	if itemBrowser then
		itemBrowser.SetSellHandler(handler)
	end
end

function BackpackScreen.SetLockHandler(handler: (BackpackItem) -> ())
	local itemBrowser = browser
	if itemBrowser then
		itemBrowser.SetLockHandler(handler)
	end
end

function BackpackScreen.SetStorageAddHandler(handler: () -> ())
	storageAddHandler = handler
end

function BackpackScreen.SetOpenHandler(handler: () -> ())
	openHandler = handler
end

function BackpackScreen.HighlightTab(tabId: string)
	highlightTab(tabId)
end

function BackpackScreen.ResetBrowser()
	local itemBrowser = browser
	if itemBrowser then
		itemBrowser.Reset()
	end
end

function BackpackScreen.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local main = playerGui:WaitForChild(BACKPACK_GUI_NAME):WaitForChild("Main")
	local tabs = main:WaitForChild("TabList")
	local tab = tabs:WaitForChild(TAB_TEMPLATE_NAME)
	if not main:IsA("Frame") or not tabs:IsA("Frame") or not tab:IsA("GuiButton") then
		warn("[BackpackScreen] BackpackGui has wrong structure")
		return
	end
	tab.Visible = false
	main.Visible = false
	mainFrame, tabList, tabTemplate = main, tabs, tab
	browser = ItemBrowser.Create(main, {
		GetActionText = getActionText,
		CanSell = canSell,
		CanSellAll = canSellAll,
		GetSellText = getSellText,
	})

	bindStorageButton(main)
	HudSlide.TrackScreen(main)
	ScreenRegistry.Register(main)
	HudButton.Bind(BACKPACK_BUTTON_NAME, function()
		local isOpening = not main.Visible
		local handler = openHandler
		if isOpening and handler then
			handler()
		end
		main.Visible = isOpening
	end)
end

return BackpackScreen
