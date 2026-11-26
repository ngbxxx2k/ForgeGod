--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IndexScreen = require(script.Parent.Parent.UI.Screens.IndexScreen)
local IndexRewardConfig = require(ReplicatedStorage.Shared.Config.IndexRewardConfig)
local MutationConfig = require(ReplicatedStorage.Shared.Config.MutationConfig)
local BackpackMessages = require(ReplicatedStorage.Shared.Constants.BackpackMessages)
local IndexMessages = require(ReplicatedStorage.Shared.Constants.IndexMessages)
local ItemVisuals = require(ReplicatedStorage.Shared.Constants.ItemVisuals)
local WeaponCatalog = require(ReplicatedStorage.Shared.Constants.WeaponCatalog)
local WeaponIcons = require(ReplicatedStorage.Shared.Constants.WeaponIcons)
local IndexCollection = require(ReplicatedStorage.Shared.Utils.IndexCollection)
local IndexKey = require(ReplicatedStorage.Shared.Utils.IndexKey)

type IndexEntry = IndexScreen.IndexEntry
type IndexCollection = IndexScreen.IndexCollection
type IndexTab = IndexScreen.IndexTab
type RewardInfo = IndexScreen.RewardInfo
type IndexSet = { [string]: boolean }
type MutationDefinition = MutationConfig.MutationDefinition
type WeaponType = WeaponCatalog.WeaponType

local IndexData = {}

local function getRarityRank(rarity: string): number
	return table.find(WeaponCatalog.RarityOrder, rarity) or math.huge
end

local function sortMutations(a: MutationDefinition, b: MutationDefinition): boolean
	local rankA, rankB = getRarityRank(a.Rarity), getRarityRank(b.Rarity)
	if rankA ~= rankB then
		return rankA < rankB
	end
	return a.Multiplier < b.Multiplier
end

local function buildEntry(tabId: string, weaponType: WeaponType, stage: number, index: IndexSet): IndexEntry
	local key = IndexKey.Build(tabId, weaponType.Id, stage)
	local icon = WeaponIcons.Get(weaponType.Id, stage)
	local entry: IndexEntry = {
		Id = key,
		DisplayName = if icon then icon.DisplayName else weaponType.DisplayName,
		Rarity = weaponType.Rarity,
		IsUnlocked = index[key] == true,
		Image = icon and icon.Image,
		ImageRectOffset = icon and icon.RectOffset,
		ImageRectSize = icon and icon.RectSize,
	}
	return entry
end

local function buildReward(tabId: string, rarity: string, index: IndexSet, claimed: IndexSet): RewardInfo?
	local reward = IndexRewardConfig.ByRarity[rarity]
	if reward == nil then
		return nil
	end
	local visual = ItemVisuals[reward.ItemId]
	local isClaimed = claimed[IndexCollection.BuildRewardKey(tabId, rarity)] == true
	return {
		DisplayName = IndexData.GetRewardText(rarity),
		Image = visual and visual.Image,
		IsClaimable = not isClaimed and IndexCollection.IsComplete(index, tabId, rarity),
		IsClaimed = isClaimed,
	}
end

local function buildCollection(tabId: string, rarity: string, index: IndexSet, claimed: IndexSet): IndexCollection
	local entries = {}
	for _, weaponType in WeaponCatalog.Types[rarity] do
		for stage = 1, weaponType.MaxShapeStage do
			table.insert(entries, buildEntry(tabId, weaponType, stage, index))
		end
	end
	local showcase = entries[#entries]
	return {
		Id = tabId .. "_" .. rarity,
		Rarity = rarity,
		ChancePercent = "",
		Image = showcase and showcase.Image,
		ImageRectOffset = showcase and showcase.ImageRectOffset,
		ImageRectSize = showcase and showcase.ImageRectSize,
		Entries = entries,
		Reward = buildReward(tabId, rarity, index, claimed),
	}
end

function IndexData.GetRewardText(rarity: string): string
	local reward = IndexRewardConfig.ByRarity[rarity]
	if reward == nil then
		return ""
	end
	local name = BackpackMessages.ItemNames[reward.ItemId] or reward.ItemId
	return string.format(IndexMessages.RewardFormat, reward.Amount, name)
end

function IndexData.GetTabs(): { IndexTab }
	local mutations = table.clone(MutationConfig.Mutations)
	table.sort(mutations, sortMutations)
	local tabs: { IndexTab } = { { Id = IndexKey.NormalId, DisplayName = IndexKey.NormalId } }
	for _, mutation in mutations do
		table.insert(tabs, { Id = mutation.Id, DisplayName = mutation.Id })
	end
	return tabs
end

function IndexData.GetCollections(tabId: string, index: IndexSet, claimed: IndexSet): { IndexCollection }
	local collections = {}
	for _, rarity in WeaponCatalog.RarityOrder do
		table.insert(collections, buildCollection(tabId, rarity, index, claimed))
	end
	return collections
end

function IndexData.GetTabProgress(tabId: string, index: IndexSet): (number, number)
	local unlocked, total = 0, 0
	for _, collection in IndexData.GetCollections(tabId, index, {}) do
		for _, entry in collection.Entries do
			total += 1
			if entry.IsUnlocked then
				unlocked += 1
			end
		end
	end
	return unlocked, total
end

function IndexData.CountKeys(index: IndexSet): number
	local count = 0
	for _ in index do
		count += 1
	end
	return count
end

return IndexData
