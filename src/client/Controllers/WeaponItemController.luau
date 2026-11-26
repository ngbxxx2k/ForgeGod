--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BackpackMessages = require(ReplicatedStorage.Shared.Constants.BackpackMessages)
local WeaponItemMessages = require(ReplicatedStorage.Shared.Constants.WeaponItemMessages)
local WeaponItemConfig = require(ReplicatedStorage.Shared.Config.WeaponItemConfig)
local RemoteNames = require(ReplicatedStorage.Shared.Network.RemoteNames)
local PlayerStateTypes = require(ReplicatedStorage.Shared.Types.PlayerStateTypes)
local Toast = require(script.Parent.Parent.UI.Components.Toast)
local InventoryItems = require(script.Parent.InventoryItems)
local PlayerStateController = require(script.Parent.PlayerStateController)
local WeaponPickerController = require(script.Parent.WeaponPickerController)

type BackpackItem = InventoryItems.BackpackItem
type PlayerState = PlayerStateTypes.PlayerState

local REMOTES_FOLDER_NAME = "Remotes"

local WeaponItemController = {}

local isInitialized = false
local requestUse: RemoteEvent? = nil

local function showNoTarget(itemId: string)
	local text = WeaponItemMessages.NoTargetText[itemId] or WeaponItemMessages.UnknownError
	Toast.Error(text)
end

local function fireUse(itemId: string, weapon: BackpackItem)
	local remote = requestUse
	if remote then
		remote:FireServer(itemId, weapon.Id)
	end
end

function WeaponItemController.IsWeaponItem(itemId: string): boolean
	return WeaponItemConfig.ById[itemId] ~= nil
end

function WeaponItemController.Use(itemId: string)
	local state = PlayerStateController.GetState()
	if state == nil or not WeaponItemController.IsWeaponItem(itemId) then
		return
	end
	if #InventoryItems.GetWeaponItemTargets(state, itemId) == 0 then
		showNoTarget(itemId)
		return
	end
	WeaponPickerController.OpenWith({
		ActionText = BackpackMessages.UseText,
		GetItems = function(current: PlayerState): { BackpackItem }
			return InventoryItems.GetWeaponItemTargets(current, itemId)
		end,
		OnSelected = function(weapon: BackpackItem)
			fireUse(itemId, weapon)
		end,
	})
end

local function onUseResult(ok: any, reason: any, itemId: any)
	if ok == true and type(itemId) == "string" then
		local itemName = BackpackMessages.ItemNames[itemId] or itemId
		local text = string.format(WeaponItemMessages.UsedFormat, itemName)
		Toast.Success(text)
		return
	end
	local message = type(reason) == "string" and WeaponItemMessages.Reasons[reason]
	Toast.Error(message or WeaponItemMessages.UnknownError)
end

function WeaponItemController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotes = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)
	requestUse = remotes:WaitForChild(RemoteNames.RequestUseWeaponItem) :: RemoteEvent
	local resultRemote = remotes:WaitForChild(RemoteNames.NotifyUseWeaponItemResult) :: RemoteEvent
	resultRemote.OnClientEvent:Connect(onUseResult)
end

return WeaponItemController
