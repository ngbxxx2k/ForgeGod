--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BackpackMessages = require(ReplicatedStorage.Shared.Constants.BackpackMessages)
local UiIcons = require(ReplicatedStorage.Shared.Constants.UiIcons)
local BuffMessages = require(ReplicatedStorage.Shared.Constants.BuffMessages)
local EquipMessages = require(ReplicatedStorage.Shared.Constants.EquipMessages)
local PlayerAttributes = require(ReplicatedStorage.Shared.Constants.PlayerAttributes)
local SellMessages = require(ReplicatedStorage.Shared.Constants.SellMessages)
local WeaponLockMessages = require(ReplicatedStorage.Shared.Constants.WeaponLockMessages)
local NumberFormat = require(ReplicatedStorage.Shared.Utils.NumberFormat)
local SellPrice = require(ReplicatedStorage.Shared.Utils.SellPrice)
local ConfirmScreen = require(script.Parent.Parent.UI.Screens.ConfirmScreen)
local PlayerStateTypes = require(ReplicatedStorage.Shared.Types.PlayerStateTypes)
local RemoteNames = require(ReplicatedStorage.Shared.Network.RemoteNames)
local StorageConfig = require(ReplicatedStorage.Shared.Config.StorageConfig)
local BackpackScreen = require(script.Parent.Parent.UI.Screens.BackpackScreen)
local Toast = require(script.Parent.Parent.UI.Components.Toast)
local UiSound = require(script.Parent.Parent.Effects.UiSound)
local InventoryItems = require(script.Parent.InventoryItems)
local PlayerStateController = require(script.Parent.PlayerStateController)
local WeaponItemController = require(script.Parent.WeaponItemController)

type BackpackItem = BackpackScreen.BackpackItem
type BackpackTab = BackpackScreen.BackpackTab
type PlayerState = PlayerStateTypes.PlayerState

local ORE_TAB_ID = "Ore"
local BUFF_TAB_ID = "Buff"
local WEAPON_TAB_ID = "Weapon"
local REMOTES_FOLDER_NAME = "Remotes"

local TABS: { BackpackTab } = {
	{
		Id = WEAPON_TAB_ID,
		DisplayName = BackpackMessages.TabNames.Weapon,
		Image = UiIcons.BackpackTabs.Weapon,
	},
	{
		Id = ORE_TAB_ID,
		DisplayName = BackpackMessages.TabNames.Ore,
		Image = UiIcons.BackpackTabs.Ore,
	},
	{
		Id = BUFF_TAB_ID,
		DisplayName = BackpackMessages.TabNames.Buff,
		Image = UiIcons.BackpackTabs.Buff,
	},
}

local BackpackController = {}

local isInitialized = false
local currentTabId = WEAPON_TAB_ID
local requestHold: RemoteEvent? = nil
local requestSell: RemoteEvent? = nil
local requestBuyStorage: RemoteEvent? = nil
local requestSellItem: RemoteEvent? = nil
local requestSellAllWeapons: RemoteEvent? = nil
local requestSetLock: RemoteEvent? = nil
local requestUseItem: RemoteEvent? = nil

local function getItems(state: PlayerState, tabId: string): { BackpackItem }
	if tabId == ORE_TAB_ID then
		return InventoryItems.GetOres(state)
	elseif tabId == BUFF_TAB_ID then
		return InventoryItems.GetBuffs(state)
	end
	return InventoryItems.GetBackpackWeapons(state)
end

local function render()
	local state = PlayerStateController.GetState()
	if state == nil then
		BackpackScreen.RenderItems({})
		return
	end
	BackpackScreen.RenderItems(getItems(state, currentTabId))
	BackpackScreen.SetStorage(InventoryItems.GetUsedSlots(state), state.Capacity)
end

local function selectTab(tabId: string)
	currentTabId = tabId
	render()
end

local function onOpen()
	BackpackScreen.ResetBrowser()
	BackpackScreen.HighlightTab(WEAPON_TAB_ID)
	selectTab(WEAPON_TAB_ID)
end

local function onItemAction(item: BackpackItem)
	if item.Category == BUFF_TAB_ID then
		if WeaponItemController.IsWeaponItem(item.Id) then
			WeaponItemController.Use(item.Id)
		elseif requestUseItem then
			requestUseItem:FireServer(item.Id)
		end
		return
	end
	if item.Category ~= WEAPON_TAB_ID then
		return
	end
	if requestHold then
		requestHold:FireServer(item.Id)
	end
end

local function getSellPrice(item: BackpackItem): number
	local state = PlayerStateController.GetState()
	local buffMultiplier = if state
		then SellPrice.GetBuffMultiplier(state, Workspace:GetServerTimeNow())
		else 1
	return SellPrice.Calculate(item.Price, item.Mutation, item.IsBroken == true, buffMultiplier)
end

local function sellStackItem(item: BackpackItem, isSellAll: boolean)
	local remote = requestSellItem
	local amount = if isSellAll then item.Amount else 1
	local total = SellPrice.CalculateItem(item.Id, amount)
	if not remote or amount <= 0 or total == nil then
		return
	end
	ConfirmScreen.Show({
		Title = SellMessages.ConfirmItemTitle,
		Message = string.format(
			SellMessages.ConfirmItemFormat,
			NumberFormat.WithCommas(amount),
			item.DisplayName,
			NumberFormat.Abbreviate(total)
		),
		ConfirmText = SellMessages.SellText,
		OnConfirm = function()
			remote:FireServer(item.Id, amount)
		end,
	})
end

local function getSellableWeapons(): ({ string }, number)
	local state = PlayerStateController.GetState()
	local weaponIds: { string } = {}
	local total = 0
	if state == nil then
		return weaponIds, total
	end
	for _, weapon in InventoryItems.GetWeapons(state) do
		if not weapon.IsEquipped and not weapon.IsLocked then
			table.insert(weaponIds, weapon.Id)
			total += getSellPrice(weapon)
		end
	end
	return weaponIds, total
end

local function sellAllWeapons()
	local remote = requestSellAllWeapons
	if not remote then
		return
	end
	local weaponIds, total = getSellableWeapons()
	if #weaponIds == 0 then
		Toast.Error(SellMessages.NoWeaponsToSell)
		return
	end
	ConfirmScreen.Show({
		Title = SellMessages.ConfirmAllWeaponsTitle,
		Message = string.format(
			SellMessages.ConfirmAllWeaponsFormat,
			NumberFormat.WithCommas(#weaponIds),
			NumberFormat.Abbreviate(total)
		),
		ConfirmText = SellMessages.SellAllText,
		OnConfirm = function()
			remote:FireServer(weaponIds)
		end,
	})
end

local function onSellItem(item: BackpackItem, isSellAll: boolean)
	if item.Category ~= WEAPON_TAB_ID then
		sellStackItem(item, isSellAll)
		return
	end
	if isSellAll then
		sellAllWeapons()
		return
	end
	local remote = requestSell
	if item.IsEquipped or item.IsLocked or not remote then
		return
	end
	local priceText = NumberFormat.Abbreviate(getSellPrice(item))
	ConfirmScreen.Show({
		Title = SellMessages.ConfirmTitle,
		Message = string.format(SellMessages.ConfirmFormat, item.DisplayName, priceText),
		ConfirmText = SellMessages.SellText,
		OnConfirm = function()
			remote:FireServer(item.Id)
		end,
	})
end

local function onSellResult(ok: any, reason: any, coins: any)
	if ok == true and type(coins) == "number" then
		local text = string.format(SellMessages.SoldFormat, NumberFormat.Abbreviate(coins))
		Toast.Success(text)
		UiSound.PlaySell()
		return
	end
	local message = type(reason) == "string" and SellMessages.Reasons[reason]
	Toast.Error(message or SellMessages.UnknownError)
end

local function onLockItem(item: BackpackItem)
	local remote = requestSetLock
	if item.Category == WEAPON_TAB_ID and remote then
		remote:FireServer(item.Id, not item.IsLocked)
	end
end

local function onLockResult(ok: any, reason: any)
	if ok == true then
		return
	end
	local message = type(reason) == "string" and WeaponLockMessages.Reasons[reason]
	Toast.Error(message or WeaponLockMessages.UnknownError)
end

local function onUseItemResult(ok: any, reason: any, itemId: any)
	if ok == true and type(itemId) == "string" then
		local itemName = BackpackMessages.ItemNames[itemId] or itemId
		local text = string.format(BuffMessages.ActivatedFormat, itemName)
		Toast.Success(text)
		return
	end
	local message = type(reason) == "string" and BuffMessages.Reasons[reason]
	Toast.Error(message or BuffMessages.UnknownError)
end

local function onHoldResult(ok: any, reason: any)
	if ok == true then
		return
	end
	local message = type(reason) == "string" and EquipMessages.Reasons[reason]
	Toast.Error(message or EquipMessages.UnknownError)
end

local function onStorageAdd()
	local remote = requestBuyStorage
	if remote then
		remote:FireServer()
	end
end

local function onBuyStorageResult(ok: any, reason: any)
	if ok == true then
		Toast.Success(string.format(BackpackMessages.StorageExpandedFormat, StorageConfig.ExpandedSlots))
		return
	end
	local message = type(reason) == "string" and BackpackMessages.StorageReasons[reason]
	Toast.Error(message or BackpackMessages.StorageUnknownError)
end

function BackpackController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotes = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)
	requestHold = remotes:WaitForChild(RemoteNames.RequestHoldWeapon) :: RemoteEvent
	local holdResult = remotes:WaitForChild(RemoteNames.NotifyHoldResult) :: RemoteEvent
	holdResult.OnClientEvent:Connect(onHoldResult)
	requestSell = remotes:WaitForChild(RemoteNames.RequestSellWeapon) :: RemoteEvent
	requestSellItem = remotes:WaitForChild(RemoteNames.RequestSellItem) :: RemoteEvent
	requestSellAllWeapons = remotes:WaitForChild(RemoteNames.RequestSellAllWeapons) :: RemoteEvent
	local sellResult = remotes:WaitForChild(RemoteNames.NotifySellResult) :: RemoteEvent
	sellResult.OnClientEvent:Connect(onSellResult)
	requestSetLock = remotes:WaitForChild(RemoteNames.RequestSetWeaponLock) :: RemoteEvent
	local lockResult = remotes:WaitForChild(RemoteNames.NotifyWeaponLockResult) :: RemoteEvent
	lockResult.OnClientEvent:Connect(onLockResult)
	requestUseItem = remotes:WaitForChild(RemoteNames.RequestUseItem) :: RemoteEvent
	local useItemResult = remotes:WaitForChild(RemoteNames.NotifyUseItemResult) :: RemoteEvent
	useItemResult.OnClientEvent:Connect(onUseItemResult)
	requestBuyStorage = remotes:WaitForChild(RemoteNames.RequestBuyStorage) :: RemoteEvent
	local storageResult = remotes:WaitForChild(RemoteNames.NotifyBuyStorageResult) :: RemoteEvent
	storageResult.OnClientEvent:Connect(onBuyStorageResult)
	BackpackScreen.SetStorageAddHandler(onStorageAdd)

	BackpackScreen.SetActionHandler(onItemAction)
	BackpackScreen.SetSellHandler(onSellItem)
	BackpackScreen.SetLockHandler(onLockItem)
	BackpackScreen.SetOpenHandler(onOpen)
	BackpackScreen.RenderTabs(TABS, currentTabId, selectTab)
	PlayerStateController.OnChanged(function()
		render()
	end)
	Players.LocalPlayer:GetAttributeChangedSignal(PlayerAttributes.HeldWeaponId):Connect(render)
	render()
end

return BackpackController
