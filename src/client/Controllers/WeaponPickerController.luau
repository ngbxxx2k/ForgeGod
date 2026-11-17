--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Shared.Network.RemoteNames)
local WeaponPickerScreen = require(script.Parent.Parent.UI.Screens.WeaponPickerScreen)
local ForgeController = require(script.Parent.ForgeController)
local InventoryItems = require(script.Parent.InventoryItems)
local PlayerStateController = require(script.Parent.PlayerStateController)

type BackpackItem = InventoryItems.BackpackItem

local REMOTES_FOLDER_NAME = "Remotes"

local WeaponPickerController = {}

local isInitialized = false
local isOpen = false
local pendingWeaponId: string? = nil
local requestEquip: RemoteEvent? = nil

local function render()
	local state = PlayerStateController.GetState()
	WeaponPickerScreen.Render(if state then InventoryItems.GetForgeableWeapons(state) else {})
end

local function onEquip(item: BackpackItem)
	local remote = requestEquip
	if not isOpen or pendingWeaponId ~= nil or not remote then
		return
	end
	pendingWeaponId = item.Id
	remote:FireServer(item.Id)
end

local function onEquipResult(ok: any, _reason: any)
	local weaponId = pendingWeaponId
	if weaponId == nil then
		return
	end
	pendingWeaponId = nil
	if ok ~= true or not isOpen then
		return
	end
	isOpen = false
	WeaponPickerScreen.SetVisible(false)
	ForgeController.Open(weaponId)
end

local function onWeaponLost()
	ForgeController.Close()
	WeaponPickerController.Open()
end

local function onPickerClosed()
	isOpen = false
	pendingWeaponId = nil
end

function WeaponPickerController.Open()
	isOpen = true
	pendingWeaponId = nil
	render()
	WeaponPickerScreen.SetVisible(true)
end

function WeaponPickerController.Close()
	onPickerClosed()
	WeaponPickerScreen.SetVisible(false)
	ForgeController.Close()
end

function WeaponPickerController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotes = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)
	requestEquip = remotes:WaitForChild(RemoteNames.RequestEquip) :: RemoteEvent
	local resultRemote = remotes:WaitForChild(RemoteNames.NotifyEquipResult) :: RemoteEvent
	resultRemote.OnClientEvent:Connect(onEquipResult)

	WeaponPickerScreen.SetEquipHandler(onEquip)
	WeaponPickerScreen.SetCloseHandler(onPickerClosed)
	ForgeController.SetWeaponLostHandler(onWeaponLost)
	PlayerStateController.OnChanged(function()
		if isOpen then
			render()
		end
	end)
end

return WeaponPickerController
