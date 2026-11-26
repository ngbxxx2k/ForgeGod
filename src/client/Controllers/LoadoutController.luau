--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EquipMessages = require(ReplicatedStorage.Shared.Constants.EquipMessages)
local LoadoutConfig = require(ReplicatedStorage.Shared.Config.LoadoutConfig)
local NumberFormat = require(ReplicatedStorage.Shared.Utils.NumberFormat)
local PlayerStateTypes = require(ReplicatedStorage.Shared.Types.PlayerStateTypes)
local RemoteNames = require(ReplicatedStorage.Shared.Network.RemoteNames)
local LoadoutScreen = require(script.Parent.Parent.UI.Screens.LoadoutScreen)
local Toast = require(script.Parent.Parent.UI.Components.Toast)
local InventoryItems = require(script.Parent.InventoryItems)
local PlayerStateController = require(script.Parent.PlayerStateController)

type PlayerState = PlayerStateTypes.PlayerState
type BackpackItem = InventoryItems.BackpackItem
type WeaponEntry = LoadoutScreen.WeaponEntry
type LoadoutSummary = LoadoutScreen.LoadoutSummary

local REMOTES_FOLDER_NAME = "Remotes"

local LoadoutController = {}

local isInitialized = false
local requestEquip: RemoteEvent? = nil
local requestUnequip: RemoteEvent? = nil
local requestEquipBest: RemoteEvent? = nil

local function formatIncome(income: number): string
	return string.format(EquipMessages.IncomeFormat, NumberFormat.Abbreviate(income))
end

local function buildEntry(item: BackpackItem): WeaponEntry
	return {
		Id = item.Id,
		DisplayName = item.DisplayName,
		Rarity = item.Rarity or "",
		IncomeText = formatIncome(item.Income or 0),
		ButtonText = if item.IsEquipped then EquipMessages.UnequipText else EquipMessages.EquipText,
		IsEquipped = item.IsEquipped == true,
		Image = item.Image,
		ImageRectOffset = item.ImageRectOffset,
		ImageRectSize = item.ImageRectSize,
	}
end

local function getUsableWeapons(state: PlayerState): { BackpackItem }
	local weapons = {}
	for _, item in InventoryItems.GetWeapons(state) do
		if not item.IsBroken then
			table.insert(weapons, item)
		end
	end
	table.sort(weapons, function(a: BackpackItem, b: BackpackItem): boolean
		if a.IsEquipped ~= b.IsEquipped then
			return a.IsEquipped == true
		end
		return (a.Income or 0) > (b.Income or 0)
	end)
	return weapons
end

local function buildSummary(state: PlayerState, weapons: { BackpackItem }): LoadoutSummary
	local totalIncome = 0
	for _, item in weapons do
		if item.IsEquipped then
			totalIncome += item.Income or 0
		end
	end
	local capacity = state.LoadoutCapacity or LoadoutConfig.DefaultSlots
	return {
		EquippedCount = #state.Equipped,
		Capacity = capacity,
		SlotsText = string.format(EquipMessages.SlotsFormat, #state.Equipped, capacity),
		IncomeText = formatIncome(totalIncome),
		EmptyText = EquipMessages.EmptyText,
	}
end

local function render()
	local state = PlayerStateController.GetState()
	if state == nil then
		return
	end
	local weapons = getUsableWeapons(state)
	local entries = {}
	for _, item in weapons do
		table.insert(entries, buildEntry(item))
	end
	LoadoutScreen.Render(entries, buildSummary(state, weapons))
end

local function isEquipped(weaponId: string): boolean
	local state = PlayerStateController.GetState()
	return state ~= nil and table.find(state.Equipped, weaponId) ~= nil
end

local function onEquip(weaponId: string)
	local remote = if isEquipped(weaponId) then requestUnequip else requestEquip
	if remote then
		remote:FireServer(weaponId)
	end
end

local function onEquipBest()
	if requestEquipBest then
		requestEquipBest:FireServer()
	end
end

local function onEquipResult(ok: any, reason: any)
	if ok == true then
		return
	end
	local message = type(reason) == "string" and EquipMessages.Reasons[reason]
	Toast.Error(message or EquipMessages.UnknownError)
end

function LoadoutController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotes = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)
	requestEquip = remotes:WaitForChild(RemoteNames.RequestEquip) :: RemoteEvent
	requestUnequip = remotes:WaitForChild(RemoteNames.RequestUnequip) :: RemoteEvent
	requestEquipBest = remotes:WaitForChild(RemoteNames.RequestEquipBest) :: RemoteEvent
	local resultRemote = remotes:WaitForChild(RemoteNames.NotifyEquipResult) :: RemoteEvent
	resultRemote.OnClientEvent:Connect(onEquipResult)

	LoadoutScreen.SetEquipHandler(onEquip)
	LoadoutScreen.SetEquipBestHandler(onEquipBest)
	LoadoutScreen.SetOpenHandler(render)
	PlayerStateController.OnChanged(function()
		if LoadoutScreen.IsVisible() then
			render()
		end
	end)
end

return LoadoutController
