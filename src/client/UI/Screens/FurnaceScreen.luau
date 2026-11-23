--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FurnaceConfig = require(ReplicatedStorage.Shared.Config.FurnaceConfig)
local FurnaceMessages = require(ReplicatedStorage.Shared.Constants.FurnaceMessages)
local GuiPath = require(script.Parent.Parent.Components.GuiPath)
local RarityGradient = require(script.Parent.Parent.Components.RarityGradient)
local UiSound = require(script.Parent.Parent.Parent.Effects.UiSound)
local OpenAnimation = require(script.Parent.Parent.Components.OpenAnimation)
local HudSlide = require(script.Parent.Parent.Components.HudSlide)
local ScreenRegistry = require(script.Parent.Parent.Components.ScreenRegistry)

local FURNACE_GUI_NAME = "FurnaceGui"
local SLOT_TEMPLATE_NAME = "SlotTemplate"
local BAG_ITEM_TEMPLATE_NAME = "BagItemTemplate"
local SLOT_NAME = "Slot"
local BAG_ITEM_NAME = "BagItem"
local FILLED_STROKE_COLOR = Color3.new(1, 1, 1)
local EMPTY_STROKE_COLOR = Color3.fromRGB(15, 15, 25)

export type FurnaceOre = {
	Id: string,
	DisplayName: string,
	Amount: number,
	Image: string?,
	Color: Color3?,
	Rarity: string?,
}

export type FurnaceHandlers = {
	OnBagItem: (oreId: string) -> (),
	OnSlot: (slotIndex: number) -> (),
	OnStart: () -> (),
	OnSkip: () -> (),
	OnClose: () -> (),
}

local FurnaceScreen = {}

local isInitialized = false
local mainFrame: Frame? = nil
local selectedRow: Frame? = nil
local bagList: ScrollingFrame? = nil
local slotTemplate: GuiButton? = nil
local bagItemTemplate: GuiButton? = nil
local skipCheck: Frame? = nil
local handlers: FurnaceHandlers? = nil

local function findPath(parent: Instance, path: { string }): Instance?
	local current: Instance? = parent
	for _, name in path do
		if not current then
			return nil
		end
		current = current:FindFirstChild(name)
	end
	return current
end

local function setText(parent: Instance, path: { string }, text: string)
	GuiPath.SetText(parent, path, text)
end

local function setImage(parent: Instance, path: { string }, image: string?)
	local imageLabel = findPath(parent, path)
	if imageLabel and imageLabel:IsA("ImageLabel") then
		imageLabel.Image = image or ""
	end
end

local function setImageColor(parent: Instance, path: { string }, color: Color3?)
	local imageLabel = findPath(parent, path)
	if not imageLabel or not imageLabel:IsA("ImageLabel") then
		return
	end
	if color then
		imageLabel.BackgroundColor3 = color
	end
	imageLabel.BackgroundTransparency = if color then 0 else 1
end

local function setStrokeColor(target: Instance, color: Color3)
	local stroke = target:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = color
	end
end

local function clearChildren(parent: Instance, childName: string)
	for _, child in parent:GetChildren() do
		if child.Name == childName then
			child:Destroy()
		end
	end
end

local function createSlot(template: GuiButton, ore: FurnaceOre?, index: number): GuiButton
	local slot = template:Clone()
	slot.Name = SLOT_NAME
	slot.LayoutOrder = index
	slot.Visible = true
	local image = ore and ore.Image
	setImage(slot, { "ItemImage" }, image)
	setImageColor(slot, { "ItemImage" }, ore and ore.Color)
	setText(slot, { "NameLabel" }, if ore and not image then ore.DisplayName else "")
	setStrokeColor(slot, if ore then FILLED_STROKE_COLOR else EMPTY_STROKE_COLOR)
	if ore then
		RarityGradient.Apply(slot, ore.Rarity)
	end
	slot.Activated:Connect(function()
		local current = handlers
		if ore and current then
			current.OnSlot(index)
		end
	end)
	return slot
end

local function createBagItem(template: GuiButton, ore: FurnaceOre, index: number): GuiButton
	local item = template:Clone()
	item.Name = BAG_ITEM_NAME
	item.LayoutOrder = index
	item.Visible = true
	setText(item, { "NameLabel" }, ore.DisplayName)
	setText(item, { "IconFrame", "AmountLabel" }, string.format(FurnaceMessages.AmountFormat, ore.Amount))
	setImage(item, { "IconFrame", "ItemImage" }, ore.Image)
	setImageColor(item, { "IconFrame", "ItemImage" }, ore.Color)
	local iconFrame = item:FindFirstChild("IconFrame")
	if iconFrame and iconFrame:IsA("GuiObject") then
		RarityGradient.Apply(iconFrame, ore.Rarity)
	end
	item.Activated:Connect(function()
		local current = handlers
		if current then
			current.OnBagItem(ore.Id)
		end
	end)
	return item
end

local function renderSlots(selected: { FurnaceOre })
	local row, template = selectedRow, slotTemplate
	if not row or not template then
		return
	end
	clearChildren(row, SLOT_NAME)
	for index = 1, FurnaceConfig.RecipeSize do
		createSlot(template, selected[index], index).Parent = row
	end
end

local function renderBag(bag: { FurnaceOre })
	local list, template = bagList, bagItemTemplate
	if not list or not template then
		return
	end
	clearChildren(list, BAG_ITEM_NAME)
	local order = 0
	for _, ore in bag do
		if ore.Amount > 0 then
			order += 1
			createBagItem(template, ore, order).Parent = list
		end
	end
end

local function bindButton(parent: Instance, path: { string }, getCallback: (FurnaceHandlers) -> () -> ())
	local button = findPath(parent, path)
	if not button or not button:IsA("GuiButton") then
		warn("[FurnaceScreen] Missing button", table.concat(path, "."))
		return
	end
	button.Activated:Connect(function()
		local current = handlers
		if current then
			getCallback(current)()
		end
	end)
end

local function bindControls(main: Frame)
	bindButton(main, { "RightPanel", "SelectedPanel", "Header", "CloseButton" }, function(current)
		return current.OnClose
	end)
	bindButton(main, { "StartButton" }, function(current)
		return current.OnStart
	end)
	bindButton(main, { "SkipToggle" }, function(current)
		return current.OnSkip
	end)
end

local function applyTexts(main: Frame)
	setText(main, { "RightPanel", "SelectedPanel", "Header", "Title" }, FurnaceMessages.SelectedTitle)
	setText(main, { "RightPanel", "BagPanel", "Header", "Title" }, FurnaceMessages.BagTitle)
	setText(main, { "StartButton" }, FurnaceMessages.StartText)
	setText(main, { "SkipToggle", "Label" }, FurnaceMessages.SkipText)
end

function FurnaceScreen.Render(bag: { FurnaceOre }, selected: { FurnaceOre })
	if not mainFrame then
		warn("[FurnaceScreen] Render called before Init")
		return
	end
	renderSlots(selected)
	renderBag(bag)
end

function FurnaceScreen.SetSkipChecked(isChecked: boolean)
	if skipCheck then
		skipCheck.Visible = isChecked
	end
end

function FurnaceScreen.SetHandlers(newHandlers: FurnaceHandlers)
	handlers = newHandlers
end

function FurnaceScreen.SetVisible(isVisible: boolean)
	local frame = mainFrame
	if not frame then
		return
	end
	if isVisible then
		ScreenRegistry.CloseAllExcept(frame)
		OpenAnimation.Open(frame)
	else
		OpenAnimation.Close(frame)
	end
end

function FurnaceScreen.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local main = playerGui:WaitForChild(FURNACE_GUI_NAME):WaitForChild("Main")
	local panel = main:WaitForChild("RightPanel")
	local row = panel:WaitForChild("SelectedPanel"):WaitForChild("Body"):WaitForChild("SelectedRow")
	local list = panel:WaitForChild("BagPanel"):WaitForChild("Body"):WaitForChild("BagList")
	local slot = row:WaitForChild(SLOT_TEMPLATE_NAME)
	local bagItem = list:WaitForChild(BAG_ITEM_TEMPLATE_NAME)
	local check = main:WaitForChild("SkipToggle"):WaitForChild("Box"):WaitForChild("Check")
	if not main:IsA("Frame") or not row:IsA("Frame") or not list:IsA("ScrollingFrame") then
		warn("[FurnaceScreen] FurnaceGui has wrong structure")
		return
	end
	if not slot:IsA("GuiButton") or not bagItem:IsA("GuiButton") or not check:IsA("Frame") then
		warn("[FurnaceScreen] FurnaceGui templates have wrong structure")
		return
	end
	slot.Visible, bagItem.Visible, check.Visible = false, false, false
	main.Visible = false
	mainFrame, selectedRow, bagList = main, row, list
	UiSound.WatchOpen(main)
	OpenAnimation.Watch(main)
	HudSlide.TrackScreen(main)
	ScreenRegistry.Register(main, function()
		local current = handlers
		if current then
			current.OnClose()
		else
			main.Visible = false
		end
	end)
	slotTemplate, bagItemTemplate, skipCheck = slot, bagItem, check

	applyTexts(main)
	bindControls(main)
end

return FurnaceScreen
