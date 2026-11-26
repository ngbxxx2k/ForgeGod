--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FurnaceConfig = require(ReplicatedStorage.Shared.Config.FurnaceConfig)
local StationConfig = require(ReplicatedStorage.Shared.Config.StationConfig)
local PlotStations = require(ReplicatedStorage.Shared.Utils.PlotStations)
local RemoteNames = require(ReplicatedStorage.Shared.Network.RemoteNames)
local FurnaceMessages = require(ReplicatedStorage.Shared.Constants.FurnaceMessages)
local ForgeRevealTypes = require(ReplicatedStorage.Shared.Types.ForgeRevealTypes)
local FurnaceScreen = require(script.Parent.Parent.UI.Screens.FurnaceScreen)
local SmeltOddsScreen = require(script.Parent.Parent.UI.Screens.SmeltOddsScreen)
local Toast = require(script.Parent.Parent.UI.Components.Toast)
local ForgeRevealController = require(script.Parent.ForgeRevealController)
local OreCrucibleFx = require(script.Parent.Parent.Effects.OreCrucibleFx)
local OreDropFx = require(script.Parent.Parent.Effects.OreDropFx)
local CrucibleStance = require(script.Parent.CrucibleStance)
local InventoryItems = require(script.Parent.InventoryItems)
local PlayerStateController = require(script.Parent.PlayerStateController)
local SmeltOddsController = require(script.Parent.SmeltOddsController)

type FurnaceOre = FurnaceScreen.FurnaceOre
type SmeltResult = ForgeRevealTypes.SmeltResult

local REMOTES_FOLDER_NAME = "Remotes"
local WEAPON_SLOT_COST = 1

local FurnaceController = {}

local isInitialized = false
local isSkipping = false
local ownedOres: { FurnaceOre } = {}
local selectedIds: { string } = {}
local pendingSelection: { string }? = nil

local function findCrucible(): Model?
	local userId = Players.LocalPlayer.UserId
	local crucible = PlotStations.FindOwnedStation(userId, StationConfig.FurnaceModelName)
	if crucible then
		return crucible
	end
	warn("[FurnaceController] Missing crucible", StationConfig.FurnaceModelName)
	return nil
end

local function loadOwnedOres()
	ownedOres = {}
	local state = PlayerStateController.GetState()
	if state == nil then
		return
	end
	for _, item in InventoryItems.GetOres(state) do
		table.insert(ownedOres, {
			Id = item.Id,
			DisplayName = item.DisplayName,
			Amount = item.Amount,
			Image = item.Image,
			Color = item.Color,
			Rarity = item.Rarity,
		})
	end
end

local function findOwnedOre(oreId: string): FurnaceOre?
	for _, ore in ownedOres do
		if ore.Id == oreId then
			return ore
		end
	end
	return nil
end

local function countSelected(oreId: string): number
	local count = 0
	for _, selectedId in selectedIds do
		if selectedId == oreId then
			count += 1
		end
	end
	return count
end

local function buildBagView(): { FurnaceOre }
	local bag = {}
	for _, ore in ownedOres do
		local remaining = table.clone(ore)
		remaining.Amount = ore.Amount - countSelected(ore.Id)
		table.insert(bag, remaining)
	end
	return bag
end

local function buildSelectedView(): { FurnaceOre }
	local selected = {}
	for _, oreId in selectedIds do
		local ore = findOwnedOre(oreId)
		if ore then
			table.insert(selected, ore)
		end
	end
	return selected
end

local function buildRecipe(): { [string]: number }
	local recipe = {}
	for _, oreId in selectedIds do
		recipe[oreId] = (recipe[oreId] or 0) + 1
	end
	return recipe
end

local function refresh()
	FurnaceScreen.Render(buildBagView(), buildSelectedView())
	FurnaceScreen.SetSkipChecked(isSkipping)
	SmeltOddsController.Update(buildRecipe(), #selectedIds == FurnaceConfig.RecipeSize)
end

local function addOre(oreId: string)
	local ore = findOwnedOre(oreId)
	if not ore or #selectedIds >= FurnaceConfig.RecipeSize then
		return
	end
	if countSelected(oreId) >= ore.Amount then
		return
	end
	table.insert(selectedIds, oreId)
	refresh()
	local crucible = findCrucible()
	if crucible then
		OreDropFx.Drop(oreId, crucible)
	end
end

local function removeOre(slotIndex: number)
	if selectedIds[slotIndex] == nil then
		return
	end
	table.remove(selectedIds, slotIndex)
	refresh()
end

local function onRevealFinished()
	if CrucibleStance.IsActive() then
		refresh()
		FurnaceScreen.SetVisible(true)
	end
end

local function isInventoryFull(): boolean
	local state = PlayerStateController.GetState()
	if state == nil then
		return false
	end
	return InventoryItems.GetUsedSlots(state) + WEAPON_SLOT_COST > state.Capacity
end

local function restorePendingSelection()
	local pending = pendingSelection
	pendingSelection = nil
	if pending == nil or #selectedIds > 0 then
		return
	end
	selectedIds = pending
	refresh()
end

local function startSmelting()
	if #selectedIds ~= FurnaceConfig.RecipeSize then
		return
	end
	if isInventoryFull() then
		Toast.Error(FurnaceMessages.Reasons.InventoryFull)
		return
	end
	local remotes = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)
	local requestSmelt = remotes and remotes:FindFirstChild(RemoteNames.RequestSmelt)
	if not requestSmelt or not requestSmelt:IsA("RemoteEvent") then
		warn("[FurnaceController] Missing remote", RemoteNames.RequestSmelt)
		return
	end
	requestSmelt:FireServer(buildRecipe())
	pendingSelection = selectedIds
	selectedIds = {}
	refresh()
	local crucible = findCrucible()
	if crucible == nil then
		return
	end
	OreCrucibleFx.Erupt(crucible)
	if not isSkipping then
		FurnaceScreen.SetVisible(false)
		ForgeRevealController.Begin(crucible, onRevealFinished)
	end
end

local function parseResult(weapon: any): SmeltResult?
	if type(weapon) ~= "table" then
		return nil
	end
	local isValid = type(weapon.Id) == "string" and type(weapon.Rarity) == "string"
		and type(weapon.WeaponType) == "string" and type(weapon.WeaponTypeId) == "string"
		and type(weapon.Value) == "number" and type(weapon.Scale) == "number"
	return if isValid then weapon :: SmeltResult else nil
end

local function onSmeltResult(ok: boolean, reason: string?, weapon: any)
	local result = if ok then parseResult(weapon) else nil
	if result == nil then
		ForgeRevealController.Cancel()
		restorePendingSelection()
		local message = reason and (FurnaceMessages.Reasons :: any)[reason]
		Toast.Error(message or FurnaceMessages.UnknownError)
		return
	end
	pendingSelection = nil
	if ForgeRevealController.IsWaitingForResult() then
		ForgeRevealController.ShowResult(result)
		return
	end
	local text = string.format(FurnaceMessages.ResultFormat, result.WeaponType, result.Rarity)
	Toast.Success(text)
end

local function connectResultRemote()
	local remotes = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)
	local resultRemote = remotes:WaitForChild(RemoteNames.NotifySmeltResult) :: RemoteEvent
	resultRemote.OnClientEvent:Connect(onSmeltResult)
end

local function pruneSelected()
	local kept = {}
	local usedCounts: { [string]: number } = {}
	for _, oreId in selectedIds do
		local ore = findOwnedOre(oreId)
		local used = (usedCounts[oreId] or 0) + 1
		if ore and used <= ore.Amount then
			usedCounts[oreId] = used
			table.insert(kept, oreId)
		end
	end
	selectedIds = kept
end

local function onStateChanged()
	loadOwnedOres()
	pruneSelected()
	refresh()
end

local function toggleSkip()
	isSkipping = not isSkipping
	FurnaceScreen.SetSkipChecked(isSkipping)
end

function FurnaceController.Open()
	selectedIds = {}
	pendingSelection = nil
	refresh()
	SmeltOddsScreen.Hide()
	local crucible = findCrucible()
	if crucible then
		CrucibleStance.Enter(crucible)
	end
	FurnaceScreen.SetVisible(true)
end

function FurnaceController.Close()
	FurnaceScreen.SetVisible(false)
	CrucibleStance.Exit()
end

function FurnaceController.GetSelectedCount(): number
	return #selectedIds
end

function FurnaceController.IsSkipping(): boolean
	return isSkipping
end

function FurnaceController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	loadOwnedOres()
	FurnaceScreen.SetHandlers({
		OnBagItem = addOre,
		OnSlot = removeOre,
		OnStart = startSmelting,
		OnSkip = toggleSkip,
		OnClose = FurnaceController.Close,
	})
	PlayerStateController.OnChanged(onStateChanged)
	task.spawn(connectResultRemote)
	Players.LocalPlayer.CharacterRemoving:Connect(function()
		ForgeRevealController.Cancel()
		if CrucibleStance.IsActive() then
			FurnaceController.Close()
		end
	end)
	refresh()
end

return FurnaceController
