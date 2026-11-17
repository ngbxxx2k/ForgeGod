--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FurnaceConfig = require(ReplicatedStorage.Shared.Config.FurnaceConfig)
local RemoteNames = require(ReplicatedStorage.Shared.Network.RemoteNames)
local FurnaceScreen = require(script.Parent.Parent.UI.Screens.FurnaceScreen)
local InventoryItems = require(script.Parent.InventoryItems)
local PlayerStateController = require(script.Parent.PlayerStateController)

type FurnaceOre = FurnaceScreen.FurnaceOre

local REMOTES_FOLDER_NAME = "Remotes"

local FurnaceController = {}

local isInitialized = false
local isSkipping = false
local ownedOres: { FurnaceOre } = {}
local selectedIds: { string } = {}

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

local function refresh()
	FurnaceScreen.Render(buildBagView(), buildSelectedView())
	FurnaceScreen.SetSkipChecked(isSkipping)
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
end

local function removeOre(slotIndex: number)
	if selectedIds[slotIndex] == nil then
		return
	end
	table.remove(selectedIds, slotIndex)
	refresh()
end

local function buildRecipe(): { [string]: number }
	local recipe = {}
	for _, oreId in selectedIds do
		recipe[oreId] = (recipe[oreId] or 0) + 1
	end
	return recipe
end

local function startSmelting()
	if #selectedIds ~= FurnaceConfig.RecipeSize then
		return
	end
	local remotes = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)
	local requestSmelt = remotes and remotes:FindFirstChild(RemoteNames.RequestSmelt)
	if not requestSmelt or not requestSmelt:IsA("RemoteEvent") then
		warn("[FurnaceController] Missing remote", RemoteNames.RequestSmelt)
		return
	end
	requestSmelt:FireServer(buildRecipe())
	selectedIds = {}
	refresh()
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
	refresh()
	FurnaceScreen.SetVisible(true)
end

function FurnaceController.Close()
	FurnaceScreen.SetVisible(false)
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
	refresh()
end

return FurnaceController
