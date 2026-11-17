--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BackpackMessages = require(ReplicatedStorage.Shared.Constants.BackpackMessages)
local UiIcons = require(ReplicatedStorage.Shared.Constants.UiIcons)
local BuffMessages = require(ReplicatedStorage.Shared.Constants.BuffMessages)
local EquipMessages = require(ReplicatedStorage.Shared.Constants.EquipMessages)
local SellMessages = require(ReplicatedStorage.Shared.Constants.SellMessages)
local WeaponLockMessages = require(ReplicatedStorage.Shared.Constants.WeaponLockMessages)
local NumberFormat = require(ReplicatedStorage.Shared.Utils.NumberFormat)
local SellPrice = require(ReplicatedStorage.Shared.Utils.SellPrice)
local ConfirmScreen = require(script.Parent.Parent.UI.Screens.ConfirmScreen)
local PlayerStateTypes = require(ReplicatedStorage.Shared.Types.PlayerStateTypes)
local RemoteNames = require(ReplicatedStorage.Shared.Network.RemoteNames)
local BackpackScreen = require(script.Parent.Parent.UI.Screens.BackpackScreen)
local Toast = require(script.Parent.Parent.UI.Components.Toast)
local UiSound = require(script.Parent.Parent.Effects.UiSound)
local InventoryItems = require(script.Parent.InventoryItems)
local PlayerStateController = require(script.Parent.PlayerStateController)

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
local requestEquip: RemoteEvent? = nil
local requestUnequip: RemoteEvent? = nil
local requestSell: RemoteEvent? = nil
local requestSellItem: RemoteEvent? = nil
local requestSetLock: RemoteEvent? = nil
local requestUseItem: RemoteEvent? = nil

local function getItems(state: PlayerState, tabId: string): { BackpackItem }
	if tabId == ORE_TAB_ID then
		return InventoryItems.GetOres(state)
	elseif tabId == BUFF_TAB_ID then
		return InventoryItems.GetBuffs(state)
	end
	return InventoryItems.GetWeapons(state)
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
		if requestUseItem then
			requestUseItem:FireServer(item.Id)
		end
		return
	end
	if item.Category ~= WEAPON_TAB_ID then
		return
	end
	local remote = if item.IsEquipped then requestUnequip else requestEquip
	if remote then
		remote:FireServer(item.Id)
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
			NumberFormat.WithCommas(total)
		),
		ConfirmText = SellMessages.SellText,
		OnConfirm = function()
			remote:FireServer(item.Id, amount)
		end,
	})
end

local function onSellItem(item: BackpackItem, isSellAll: boolean)
	if item.Category ~= WEAPON_TAB_ID then
		sellStackItem(item, isSellAll)
		return
	end
	local remote = requestSell
	if item.IsEquipped or item.IsLocked or not remote then
		return
	end
	local priceText = NumberFormat.WithCommas(getSellPrice(item))
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
		local text = string.format(SellMessages.SoldFormat, NumberFormat.WithCommas(coins))
		Toast.Show(SellMessages.NotificationTitle, text)
		UiSound.PlaySell()
		return
	end
	local message = type(reason) == "string" and SellMessages.Reasons[reason]
	Toast.Show(SellMessages.NotificationTitle, message or SellMessages.UnknownError)
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
	Toast.Show(WeaponLockMessages.NotificationTitle, message or WeaponLockMessages.UnknownError)
end

local function onUseItemResult(ok: any, reason: any, itemId: any)
	if ok == true and type(itemId) == "string" then
		local itemName = BackpackMessages.ItemNames[itemId] or itemId
		local text = string.format(BuffMessages.ActivatedFormat, itemName)
		Toast.Show(BuffMessages.NotificationTitle, text)
		return
	end
	local message = type(reason) == "string" and BuffMessages.Reasons[reason]
	Toast.Show(BuffMessages.NotificationTitle, message or BuffMessages.UnknownError)
end

local function onEquipResult(ok: any, reason: any)
	if ok == true then
		return
	end
	local message = type(reason) == "string" and EquipMessages.Reasons[reason]
	Toast.Show(EquipMessages.NotificationTitle, message or EquipMessages.UnknownError)
end

function BackpackController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotes = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)
	requestEquip = remotes:WaitForChild(RemoteNames.RequestEquip) :: RemoteEvent
	requestUnequip = remotes:WaitForChild(RemoteNames.RequestUnequip) :: RemoteEvent
	local resultRemote = remotes:WaitForChild(RemoteNames.NotifyEquipResult) :: RemoteEvent
	resultRemote.OnClientEvent:Connect(onEquipResult)
	requestSell = remotes:WaitForChild(RemoteNames.RequestSellWeapon) :: RemoteEvent
	requestSellItem = remotes:WaitForChild(RemoteNames.RequestSellItem) :: RemoteEvent
	local sellResult = remotes:WaitForChild(RemoteNames.NotifySellResult) :: RemoteEvent
	sellResult.OnClientEvent:Connect(onSellResult)
	requestSetLock = remotes:WaitForChild(RemoteNames.RequestSetWeaponLock) :: RemoteEvent
	local lockResult = remotes:WaitForChild(RemoteNames.NotifyWeaponLockResult) :: RemoteEvent
	lockResult.OnClientEvent:Connect(onLockResult)
	requestUseItem = remotes:WaitForChild(RemoteNames.RequestUseItem) :: RemoteEvent
	local useItemResult = remotes:WaitForChild(RemoteNames.NotifyUseItemResult) :: RemoteEvent
	useItemResult.OnClientEvent:Connect(onUseItemResult)

	BackpackScreen.SetActionHandler(onItemAction)
	BackpackScreen.SetSellHandler(onSellItem)
	BackpackScreen.SetLockHandler(onLockItem)
	BackpackScreen.SetOpenHandler(onOpen)
	BackpackScreen.RenderTabs(TABS, currentTabId, selectTab)
	PlayerStateController.OnChanged(function()
		render()
	end)
	render()
end

return BackpackController
