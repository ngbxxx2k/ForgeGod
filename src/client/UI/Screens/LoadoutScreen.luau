--!strict

local Players = game:GetService("Players")

local GuiPath = require(script.Parent.Parent.Components.GuiPath)
local HudButton = require(script.Parent.Parent.Components.HudButton)
local HudSlide = require(script.Parent.Parent.Components.HudSlide)
local ScreenRegistry = require(script.Parent.Parent.Components.ScreenRegistry)
local RarityGradient = require(script.Parent.Parent.Components.RarityGradient)
local UiSound = require(script.Parent.Parent.Parent.Effects.UiSound)
local OpenAnimation = require(script.Parent.Parent.Components.OpenAnimation)
local ScrollCanvas = require(script.Parent.Parent.Components.ScrollCanvas)

local LOADOUT_GUI_NAME = "LoadoutGui"
local LOADOUT_BUTTON_NAME = "LoadoutButton"
local TEMPLATE_NAME = "WeaponCardTemplate"
local CARD_NAME = "WeaponCard"
local BORDER_NAME = "Border"
local WEAPON_ID_ATTRIBUTE = "WeaponId"
local HOVER_ATTRIBUTE = "HasHoverEffect"
local HOVER_BUTTON_NAMES = { "CloseButton", "EquipBestButton", "EquipButton" }
local EQUIPPED_BORDER_COLOR = Color3.fromRGB(120, 255, 70)
local DEFAULT_BORDER_COLOR = Color3.fromRGB(15, 15, 25)
local EQUIPPED_BORDER_THICKNESS = 4
local DEFAULT_BORDER_THICKNESS = 3
local EQUIP_BUTTON_COLORS = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(119, 206, 126)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 185, 70)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 139, 53)),
})
local UNEQUIP_BUTTON_COLORS = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(234, 108, 115)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(225, 45, 55)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(169, 34, 41)),
})

export type WeaponEntry = {
	Id: string,
	DisplayName: string,
	Rarity: string,
	IncomeText: string,
	ButtonText: string,
	IsEquipped: boolean,
	Image: string?,
	ImageRectOffset: Vector2?,
	ImageRectSize: Vector2?,
}

export type LoadoutSummary = {
	EquippedCount: number,
	Capacity: number,
	SlotsText: string,
	IncomeText: string,
	EmptyText: string,
}

export type EquipHandler = (weaponId: string) -> ()

local LoadoutScreen = {}

local isInitialized = false
local container: Frame? = nil
local main: Frame? = nil
local weaponList: ScrollingFrame? = nil
local cellTemplate: Frame? = nil
local equipHandler: EquipHandler? = nil
local equipBestHandler: (() -> ())? = nil
local openHandler: (() -> ())? = nil

local function setBorder(cell: Instance, isEquipped: boolean)
	local border = cell:FindFirstChild(BORDER_NAME)
	if border and border:IsA("UIStroke") then
		border.Color = if isEquipped then EQUIPPED_BORDER_COLOR else DEFAULT_BORDER_COLOR
		border.Thickness = if isEquipped then EQUIPPED_BORDER_THICKNESS else DEFAULT_BORDER_THICKNESS
	end
end

local function styleEquipButton(button: GuiButton, entry: WeaponEntry)
	GuiPath.SetText(button, {}, entry.ButtonText)
	local gradient = button:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Color = if entry.IsEquipped then UNEQUIP_BUTTON_COLORS else EQUIP_BUTTON_COLORS
	end
	button.Activated:Connect(function()
		local handler = equipHandler
		if handler then
			handler(entry.Id)
		end
	end)
end

local function createCard(template: Frame, entry: WeaponEntry, order: number): Frame
	local card = template:Clone()
	card.Name = CARD_NAME
	card.LayoutOrder = order
	card.Visible = true
	card:SetAttribute(WEAPON_ID_ATTRIBUTE, entry.Id)
	local slot = card:FindFirstChild("Slot")
	if slot and slot:IsA("GuiObject") then
		RarityGradient.Apply(slot, entry.Rarity)
	end
	setBorder(card, entry.IsEquipped)
	GuiPath.SetText(card, { "NameLabel" }, entry.DisplayName)
	GuiPath.SetText(card, { "RarityLabel" }, string.upper(entry.Rarity))
	GuiPath.SetText(card, { "IncomeLabel" }, entry.IncomeText)
	GuiPath.SetImage(card, { "Slot", "WeaponImage" }, entry.Image)
	GuiPath.SetImageRect(card, { "Slot", "WeaponImage" }, entry.ImageRectOffset, entry.ImageRectSize)
	local button = card:FindFirstChild("EquipButton")
	if button and button:IsA("GuiButton") then
		styleEquipButton(button, entry)
	end
	return card
end

local function setSlotsFill(summary: LoadoutSummary)
	local fill = main and GuiPath.Find(main, { "SlotsBar", "Fill" })
	if fill and fill:IsA("Frame") then
		local ratio = if summary.Capacity > 0 then summary.EquippedCount / summary.Capacity else 0
		fill.Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1)
	end
end

local function applySummary(summary: LoadoutSummary, isEmpty: boolean)
	local mainFrame = main
	if not mainFrame then
		return
	end
	GuiPath.SetText(mainFrame, { "SlotsBar", "SlotsText" }, summary.SlotsText)
	GuiPath.SetText(mainFrame, { "IncomePanel", "IncomeText" }, summary.IncomeText)
	GuiPath.SetText(mainFrame, { "EmptyLabel" }, summary.EmptyText)
	GuiPath.SetVisible(mainFrame, { "EmptyLabel" }, isEmpty)
	setSlotsFill(summary)
end

local function bindButton(button: Instance?, onActivated: () -> ())
	if button and button:IsA("GuiButton") then
		button.Activated:Connect(onActivated)
	end
end

local function bindButtons(mainFrame: Instance)
	bindButton(GuiPath.Find(mainFrame, { "Header", "CloseButton" }), function()
		if container then
			OpenAnimation.Close(container)
		end
	end)
	bindButton(GuiPath.Find(mainFrame, { "Footer", "EquipBestButton" }), function()
		local handler = equipBestHandler
		if handler then
			handler()
		end
	end)
end

local function enableHoverEffects(mainFrame: Instance)
	for _, name in HOVER_BUTTON_NAMES do
		local button = mainFrame:FindFirstChild(name, true)
		if button and button:IsA("GuiButton") then
			button:SetAttribute(HOVER_ATTRIBUTE, true)
		end
	end
end

local function toggleVisible(root: Frame)
	root.Visible = not root.Visible
	local handler = openHandler
	if root.Visible and handler then
		handler()
	end
end

function LoadoutScreen.Render(entries: { WeaponEntry }, summary: LoadoutSummary)
	local list = weaponList
	local template = cellTemplate
	if not list or not template then
		warn("[LoadoutScreen] Render called before Init")
		return
	end
	GuiPath.ClearChildren(list, CARD_NAME)
	for index, entry in entries do
		createCard(template, entry, index).Parent = list
	end
	applySummary(summary, #entries == 0)
end

function LoadoutScreen.IsVisible(): boolean
	return container ~= nil and container.Visible
end

function LoadoutScreen.FindEquipButton(weaponId: string): GuiButton?
	local list = weaponList
	if list == nil then
		return nil
	end
	for _, card in list:GetChildren() do
		if card.Name == CARD_NAME and card:GetAttribute(WEAPON_ID_ATTRIBUTE) == weaponId then
			local button = card:FindFirstChild("EquipButton")
			return if button and button:IsA("GuiButton") then button else nil
		end
	end
	return nil
end

function LoadoutScreen.SetEquipHandler(handler: EquipHandler)
	equipHandler = handler
end

function LoadoutScreen.SetEquipBestHandler(handler: () -> ())
	equipBestHandler = handler
end

function LoadoutScreen.SetOpenHandler(handler: () -> ())
	openHandler = handler
end

function LoadoutScreen.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = playerGui:WaitForChild(LOADOUT_GUI_NAME)
	local root = gui:WaitForChild("Container")
	local mainFrame = root:WaitForChild("Main")
	local list = mainFrame:WaitForChild("WeaponList")
	local template = list:WaitForChild(TEMPLATE_NAME)
	if not root:IsA("Frame") or not mainFrame:IsA("Frame") then
		warn("[LoadoutScreen] LoadoutGui has wrong structure")
		return
	end
	if not list:IsA("ScrollingFrame") or not template:IsA("Frame") then
		warn("[LoadoutScreen] LoadoutGui list or template has wrong structure")
		return
	end
	template.Visible = false
	root.Visible = false
	if gui:IsA("ScreenGui") then
		gui.Enabled = true
	end
	if not ScrollCanvas.BindToLayout(list) then
		warn("[LoadoutScreen] WeaponList has no layout")
	end
	container, main, weaponList, cellTemplate = root, mainFrame, list, template
	UiSound.WatchOpen(root)
	OpenAnimation.Watch(root)
	HudSlide.TrackScreen(root)
	ScreenRegistry.Register(root)

	enableHoverEffects(mainFrame)
	bindButtons(mainFrame)
	HudButton.Bind(LOADOUT_BUTTON_NAME, function()
		toggleVisible(root)
	end)
end

return LoadoutScreen
