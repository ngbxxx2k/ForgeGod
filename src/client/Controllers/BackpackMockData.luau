--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BackpackScreen = require(script.Parent.Parent.UI.Screens.BackpackScreen)
local BackpackMessages = require(ReplicatedStorage.Shared.Constants.BackpackMessages)
local ShopConfig = require(ReplicatedStorage.Shared.Config.ShopConfig)
local AssetIds = require(ReplicatedStorage.Shared.Constants.AssetIds)

type BackpackItem = BackpackScreen.BackpackItem
type BackpackTab = BackpackScreen.BackpackTab

local SAMPLE_WEAPON_IMAGE = AssetIds.Icons.TabWeapon
local STORAGE_CAPACITY = 50

local ORE_SAMPLES = {
	{ Id = "Copper", Amount = 12 },
	{ Id = "Iron", Amount = 5 },
	{ Id = "Silver", Amount = 3 },
	{ Id = "Gold", Amount = 1 },
	{ Id = "DarkMoonstone", Amount = 1 },
}

local BUFF_SAMPLES = {
	{ Id = "LuckPotion", Amount = 2 },
	{ Id = "BlessingPotion", Amount = 1 },
	{ Id = "MerchantPotion", Amount = 3 },
	{ Id = "Talisman", Amount = 1 },
	{ Id = "MutationEraser", Amount = 1 },
}

local WEAPON_SAMPLES: { BackpackItem } = {
	{
		Id = "W1",
		Category = "Weapon",
		DisplayName = "Copper Sword",
		Amount = 1,
		Price = 4500,
		Level = 10,
		Image = SAMPLE_WEAPON_IMAGE,
		IsEquipped = true,
	},
	{
		Id = "W2",
		Category = "Weapon",
		DisplayName = "Silver Axe",
		Amount = 1,
		Price = 12000,
		Level = 6,
		Image = SAMPLE_WEAPON_IMAGE,
		IsEquipped = false,
	},
	{
		Id = "W3",
		Category = "Weapon",
		DisplayName = "Golden Spear",
		Amount = 1,
		Price = 98000,
		Level = 23,
		Image = SAMPLE_WEAPON_IMAGE,
		IsEquipped = false,
	},
}

local BackpackMockData = {}

local function getName(itemId: string): string
	return BackpackMessages.ItemNames[itemId] or itemId
end

local function buildOres(): { BackpackItem }
	local items = {}
	for _, sample in ORE_SAMPLES do
		table.insert(items, {
			Id = sample.Id,
			Category = "Ore" :: "Ore",
			DisplayName = getName(sample.Id),
			Amount = sample.Amount,
			Price = ShopConfig.ItemPrices[sample.Id] or 0,
		})
	end
	return items
end

local function buildBuffs(): { BackpackItem }
	local items = {}
	for _, sample in BUFF_SAMPLES do
		table.insert(items, {
			Id = sample.Id,
			Category = "Buff" :: "Buff",
			DisplayName = getName(sample.Id),
			Amount = sample.Amount,
			Price = ShopConfig.ItemPrices[sample.Id] or 0,
			Description = BackpackMessages.ItemDescriptions[sample.Id],
		})
	end
	return items
end

local function countAmount(items: { BackpackItem }): number
	local total = 0
	for _, item in items do
		total += item.Amount
	end
	return total
end

function BackpackMockData.GetTabs(): { BackpackTab }
	return {
		{ Id = "Ore", DisplayName = BackpackMessages.TabNames.Ore },
		{ Id = "Buff", DisplayName = BackpackMessages.TabNames.Buff },
		{ Id = "Weapon", DisplayName = BackpackMessages.TabNames.Weapon },
	}
end

function BackpackMockData.GetItems(tabId: string): { BackpackItem }
	if tabId == "Ore" then
		return buildOres()
	elseif tabId == "Buff" then
		return buildBuffs()
	end
	return WEAPON_SAMPLES
end

function BackpackMockData.GetStorage(): (number, number)
	local used = countAmount(buildOres()) + countAmount(buildBuffs()) + #WEAPON_SAMPLES
	return used, STORAGE_CAPACITY
end

return BackpackMockData
