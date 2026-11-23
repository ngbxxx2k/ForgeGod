--!strict

local WeaponPickerScreen = require(script.Parent.Parent.UI.Screens.WeaponPickerScreen)
local ForgeController = require(script.Parent.ForgeController)
local InventoryItems = require(script.Parent.InventoryItems)
local PlayerStateController = require(script.Parent.PlayerStateController)

type BackpackItem = InventoryItems.BackpackItem

local WeaponPickerController = {}

local isInitialized = false
local isOpen = false

local function render()
	local state = PlayerStateController.GetState()
	WeaponPickerScreen.Render(if state then InventoryItems.GetForgeableWeapons(state) else {})
end

local function onForgeSelected(item: BackpackItem)
	if not isOpen or item.IsEquipped then
		return
	end
	isOpen = false
	WeaponPickerScreen.SetVisible(false)
	ForgeController.Open(item.Id)
end

local function onWeaponLost()
	ForgeController.Close()
	WeaponPickerController.Open()
end

local function onPickerClosed()
	isOpen = false
end

function WeaponPickerController.Open()
	isOpen = true
	render()
	WeaponPickerScreen.SetVisible(true)
end

function WeaponPickerController.Close()
	WeaponPickerController.ClosePicker()
	ForgeController.Close()
end

function WeaponPickerController.ClosePicker()
	onPickerClosed()
	WeaponPickerScreen.SetVisible(false)
end

function WeaponPickerController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	WeaponPickerScreen.SetEquipHandler(onForgeSelected)
	WeaponPickerScreen.SetCloseHandler(onPickerClosed)
	ForgeController.SetWeaponLostHandler(onWeaponLost)
	PlayerStateController.OnChanged(function()
		if isOpen then
			render()
		end
	end)
end

return WeaponPickerController
