--!strict

local Players = game:GetService("Players")

local HudButton = require(script.Parent.Parent.Components.HudButton)
local HudSlide = require(script.Parent.Parent.Components.HudSlide)
local ScreenRegistry = require(script.Parent.Parent.Components.ScreenRegistry)
local RarityGradient = require(script.Parent.Parent.Components.RarityGradient)
local UiSound = require(script.Parent.Parent.Parent.Effects.UiSound)
local OpenAnimation = require(script.Parent.Parent.Components.OpenAnimation)

local INVENTORY_GUI_NAME = "InventoryGui"
local INVENTORY_BUTTON_NAME = "LoadoutButton"
local TEMPLATE_NAME = "WeaponCardTemplate"
local CARD_NAME = "WeaponCard"
local WEAPON_ID_ATTRIBUTE = "WeaponId"
local VALUE_FORMAT = "$%d"
local EQUIP_TEXT = "EQUIP"
local UNEQUIP_TEXT = "UNEQUIP"

export type WeaponEntry = {
	Id: string,
	DisplayName: string,
	Rarity: string,
	Value: number,
	IsEquipped: boolean,
	Image: string?,
}

local InventoryScreen = {}

local isInitialized = false
local mainFrame: Frame? = nil
local weaponList: ScrollingFrame? = nil
local cardTemplate: Frame? = nil

local function setText(parent: Instance, childName: string, text: string)
	local label = parent:FindFirstChild(childName)
	if label and (label:IsA("TextLabel") or label:IsA("TextButton")) then
		label.Text = text
	end
end

local function setImage(card: Instance, image: string?)
	local slot = card:FindFirstChild("Slot")
	local imageLabel = slot and slot:FindFirstChild("WeaponImage")
	if image and imageLabel and imageLabel:IsA("ImageLabel") then
		imageLabel.Image = image
	end
end

local function setSlotRarity(card: Instance, rarity: string)
	local slot = card:FindFirstChild("Slot")
	if slot and slot:IsA("GuiObject") then
		RarityGradient.Apply(slot, rarity)
	end
end

local function createCard(template: Frame, entry: WeaponEntry, order: number): Frame
	local card = template:Clone()
	card.Name = CARD_NAME
	card.LayoutOrder = order
	card.Visible = true
	card:SetAttribute(WEAPON_ID_ATTRIBUTE, entry.Id)
	setText(card, "WeaponName", entry.DisplayName)
	setText(card, "Rarity", entry.Rarity)
	setText(card, "Value", string.format(VALUE_FORMAT, entry.Value))
	setText(card, "EquipButton", if entry.IsEquipped then UNEQUIP_TEXT else EQUIP_TEXT)
	setImage(card, entry.Image)
	setSlotRarity(card, entry.Rarity)
	return card
end

local function setInventoryVisible(isVisible: boolean)
	if mainFrame then
		mainFrame.Visible = isVisible
	end
end

local function bindCloseButton(main: Instance)
	local closeButton = main:WaitForChild("Header"):WaitForChild("CloseButton")
	if closeButton:IsA("GuiButton") then
		closeButton.Activated:Connect(function()
			if mainFrame then
				OpenAnimation.Close(mainFrame)
			end
		end)
	end
end

function InventoryScreen.Render(entries: { WeaponEntry })
	local list = weaponList
	local template = cardTemplate
	if not list or not template then
		warn("[InventoryScreen] Render called before Init")
		return
	end
	for _, child in list:GetChildren() do
		if child.Name == CARD_NAME then
			child:Destroy()
		end
	end
	for index, entry in entries do
		createCard(template, entry, index).Parent = list
	end
end

function InventoryScreen.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local main = playerGui:WaitForChild(INVENTORY_GUI_NAME):WaitForChild("Main")
	local list = main:WaitForChild("WeaponList")
	local template = list:WaitForChild(TEMPLATE_NAME)
	if not main:IsA("Frame") or not list:IsA("ScrollingFrame") or not template:IsA("Frame") then
		warn("[InventoryScreen] InventoryGui has wrong structure")
		return
	end
	local mainAsFrame = main :: Frame
	local templateAsFrame = template :: Frame
	templateAsFrame.Visible = false
	mainAsFrame.Visible = false
	mainFrame = mainAsFrame
	UiSound.WatchOpen(mainAsFrame)
	OpenAnimation.Watch(mainAsFrame)
	HudSlide.TrackScreen(mainAsFrame)
	ScreenRegistry.Register(mainAsFrame)
	weaponList = list :: ScrollingFrame
	cardTemplate = templateAsFrame

	bindCloseButton(main)
	HudButton.Bind(INVENTORY_BUTTON_NAME, function()
		setInventoryVisible(not mainAsFrame.Visible)
	end)
end

return InventoryScreen
