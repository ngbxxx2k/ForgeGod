--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeMessages = require(ReplicatedStorage.Shared.Constants.ForgeMessages)
local PlayerStateTypes = require(ReplicatedStorage.Shared.Types.PlayerStateTypes)
local WeaponPickerScreen = require(script.Parent.Parent.UI.Screens.WeaponPickerScreen)
local ForgeController = require(script.Parent.ForgeController)
local InventoryItems = require(script.Parent.InventoryItems)
local PlayerStateController = require(script.Parent.PlayerStateController)

type BackpackItem = InventoryItems.BackpackItem
type PlayerState = PlayerStateTypes.PlayerState

export type PickerRequest = {
	ActionText: string,
	GetItems: (state: PlayerState) -> { BackpackItem },
	OnSelected: (item: BackpackItem) -> (),
}

local WeaponPickerController = {}

local isInitialized = false
local isOpen = false
local activeRequest: PickerRequest? = nil

local function openForge(item: BackpackItem)
	if item.IsEquipped then
		return
	end
	ForgeController.Open(item.Id)
end

local FORGE_REQUEST: PickerRequest = {
	ActionText = ForgeMessages.ForgeText,
	GetItems = InventoryItems.GetForgeableWeapons,
	OnSelected = openForge,
}

local function render()
	local request = activeRequest
	local state = PlayerStateController.GetState()
	if request == nil or state == nil then
		WeaponPickerScreen.Render({})
		return
	end
	WeaponPickerScreen.Render(request.GetItems(state))
end

local function onItemSelected(item: BackpackItem)
	local request = activeRequest
	if not isOpen or request == nil then
		return
	end
	isOpen = false
	WeaponPickerScreen.SetVisible(false)
	request.OnSelected(item)
end

local function onWeaponLost()
	ForgeController.Close()
	WeaponPickerController.Open()
end

local function onPickerClosed()
	isOpen = false
end

function WeaponPickerController.OpenWith(request: PickerRequest)
	activeRequest = request
	isOpen = true
	WeaponPickerScreen.SetActionText(request.ActionText)
	render()
	WeaponPickerScreen.SetVisible(true)
end

function WeaponPickerController.Open()
	WeaponPickerController.OpenWith(FORGE_REQUEST)
end

function WeaponPickerController.Close()
	WeaponPickerController.ClosePicker()
	ForgeController.Close()
end

function WeaponPickerController.ClosePicker()
	onPickerClosed()
	WeaponPickerScreen.SetVisible(false)
end

function WeaponPickerController.CloseForgePicker()
	if activeRequest == FORGE_REQUEST then
		WeaponPickerController.ClosePicker()
	end
end

function WeaponPickerController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	WeaponPickerScreen.SetEquipHandler(onItemSelected)
	WeaponPickerScreen.SetCloseHandler(onPickerClosed)
	ForgeController.SetWeaponLostHandler(onWeaponLost)
	PlayerStateController.OnChanged(function()
		if isOpen then
			render()
		end
	end)
end

return WeaponPickerController
