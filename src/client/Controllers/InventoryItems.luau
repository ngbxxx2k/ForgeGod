--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BackpackMessages = require(ReplicatedStorage.Shared.Constants.BackpackMessages)
local ItemVisuals = require(ReplicatedStorage.Shared.Constants.ItemVisuals)
local PlayerAttributes = require(ReplicatedStorage.Shared.Constants.PlayerAttributes)
local WeaponIncome = require(ReplicatedStorage.Shared.Utils.WeaponIncome)
local PlayerStateTypes = require(ReplicatedStorage.Shared.Types.PlayerStateTypes)
local ShopConfig = require(ReplicatedStorage.Shared.Config.ShopConfig)
local SellPrice = require(ReplicatedStorage.Shared.Utils.SellPrice)
local WeaponDisplayName = require(ReplicatedStorage.Shared.Utils.WeaponDisplayName)
local WeaponWeight = require(ReplicatedStorage.Shared.Utils.WeaponWeight)
local WeaponItemTarget = require(ReplicatedStorage.Shared.Utils.WeaponItemTarget)
local WeaponMaxLevel = require(ReplicatedStorage.Shared.Utils.WeaponMaxLevel)
local BackpackScreen = require(script.Parent.Parent.UI.Screens.BackpackScreen)

export type BackpackItem = BackpackScreen.BackpackItem
type PlayerState = PlayerStateTypes.PlayerState
type WeaponSummary = PlayerStateTypes.WeaponSummary

local BROKEN_STATE = "Broken"

local InventoryItems = {}

local function getItemName(itemId: string): string
	return BackpackMessages.ItemNames[itemId] or itemId
end

local function getItemColor(itemId: string): Color3?
	local visual = ItemVisuals[itemId]
	return if visual then visual.Color else nil
end

local function getItemImage(itemId: string): string?
	local visual = ItemVisuals[itemId]
	return if visual then visual.Image else nil
end

local function getItemRarity(itemId: string): string?
	local visual = ItemVisuals[itemId]
	return if visual then visual.RarityLabel else nil
end

local function compareWeapons(a: BackpackItem, b: BackpackItem): boolean
	local isHeldA, isHeldB = a.IsHeld == true, b.IsHeld == true
	if isHeldA ~= isHeldB then
		return isHeldA
	end
	local isBrokenA, isBrokenB = a.IsBroken == true, b.IsBroken == true
	if isBrokenA ~= isBrokenB then
		return isBrokenB
	end
	local incomeA, incomeB = a.Income or 0, b.Income or 0
	if incomeA ~= incomeB then
		return incomeA > incomeB
	end
	if a.Price ~= b.Price then
		return a.Price > b.Price
	end
	return a.Id < b.Id
end

function InventoryItems.GetWeaponName(weapon: WeaponSummary): string
	local name = WeaponDisplayName.Get(weapon.Rarity, weapon.WeaponType, weapon.ShapeStage)
	if weapon.State == BROKEN_STATE then
		return string.format(BackpackMessages.BrokenNameFormat, name)
	end
	return name
end

function InventoryItems.GetOres(state: PlayerState): { BackpackItem }
	local items = {}
	for _, oreId in ShopConfig.OreDisplayOrder do
		local amount = state.Items[oreId]
		if amount and amount > 0 then
			table.insert(items, {
				Id = oreId,
				Category = "Ore" :: "Ore",
				DisplayName = getItemName(oreId),
				Amount = amount,
				Price = SellPrice.GetItemUnitPrice(oreId) or 0,
				Image = getItemImage(oreId),
				Color = getItemColor(oreId),
				Rarity = getItemRarity(oreId),
			})
		end
	end
	return items
end

function InventoryItems.GetBuffs(state: PlayerState): { BackpackItem }
	local items = {}
	for itemId, amount in state.Items do
		if table.find(ShopConfig.OreDisplayOrder, itemId) == nil and amount > 0 then
			table.insert(items, {
				Id = itemId,
				Category = "Buff" :: "Buff",
				DisplayName = getItemName(itemId),
				Amount = amount,
				Price = SellPrice.GetItemUnitPrice(itemId) or 0,
				Image = getItemImage(itemId),
				Color = getItemColor(itemId),
				Rarity = getItemRarity(itemId),
				Description = BackpackMessages.ItemDescriptions[itemId],
			})
		end
	end
	table.sort(items, function(a: BackpackItem, b: BackpackItem): boolean
		return a.Id < b.Id
	end)
	return items
end

function InventoryItems.GetWeapons(state: PlayerState): { BackpackItem }
	local heldWeaponId = Players.LocalPlayer:GetAttribute(PlayerAttributes.HeldWeaponId)
	local items = {}
	for _, weapon in state.Weapons do
		local icon = WeaponDisplayName.GetIcon(weapon.WeaponType, weapon.ShapeStage)
		table.insert(items, {
			Id = weapon.Id,
			Category = "Weapon" :: "Weapon",
			DisplayName = InventoryItems.GetWeaponName(weapon),
			Amount = 1,
			Price = weapon.Value,
			Image = icon and icon.Image,
			ImageRectOffset = icon and icon.RectOffset,
			ImageRectSize = icon and icon.RectSize,
			Level = weapon.Level,
			MaxLevel = WeaponMaxLevel.Get(weapon.Rarity),
			Rarity = weapon.Rarity,
			IsEquipped = table.find(state.Equipped, weapon.Id) ~= nil,
			IsHeld = weapon.Id == heldWeaponId,
			Income = WeaponIncome.PerSecond(weapon.Value, weapon.Mutation, weapon.State == BROKEN_STATE),
			IsBroken = weapon.State == BROKEN_STATE,
			IsLocked = weapon.IsLocked == true,
			Mutation = weapon.Mutation,
			Weight = WeaponWeight.Get(weapon.WeaponType, weapon.Scale),
		})
	end
	table.sort(items, compareWeapons)
	return items
end

function InventoryItems.GetBackpackWeapons(state: PlayerState): { BackpackItem }
	local items = {}
	for _, item in InventoryItems.GetWeapons(state) do
		if not item.IsEquipped then
			table.insert(items, item)
		end
	end
	return items
end

function InventoryItems.GetForgeableWeapons(state: PlayerState): { BackpackItem }
	local items = {}
	for _, item in InventoryItems.GetWeapons(state) do
		if not item.IsBroken and not item.IsLocked and not item.IsEquipped then
			table.insert(items, item)
		end
	end
	return items
end

function InventoryItems.GetWeaponItemTargets(state: PlayerState, itemId: string): { BackpackItem }
	local targetIds: { [string]: boolean } = {}
	for _, weapon in state.Weapons do
		local isEquipped = table.find(state.Equipped, weapon.Id) ~= nil
		if WeaponItemTarget.Check(itemId, weapon, isEquipped) then
			targetIds[weapon.Id] = true
		end
	end
	local items = {}
	for _, item in InventoryItems.GetWeapons(state) do
		if targetIds[item.Id] then
			table.insert(items, item)
		end
	end
	return items
end

function InventoryItems.GetUsedSlots(state: PlayerState): number
	return #state.Weapons
end

return InventoryItems
