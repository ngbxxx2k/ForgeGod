--!strict

local IndexScreen = require(script.Parent.Parent.UI.Screens.IndexScreen)

type IndexEntry = IndexScreen.IndexEntry
type IndexCollection = IndexScreen.IndexCollection
type IndexTab = IndexScreen.IndexTab
type RewardInfo = IndexScreen.RewardInfo

type RaritySample = {
	Rarity: string,
	ChancePercent: string,
	ItemCount: number,
	UnlockedCount: number,
}

local SAMPLE_IMAGE = "rbxassetid://118131434042679"
local WEAPON_SUFFIX = "Sword"
local TOTAL_ENTRIES = 160
local TOTAL_UNLOCKED = 14

local TABS: { IndexTab } = {
	{ Id = "Plasma", DisplayName = "Plasma" },
	{ Id = "Thunder", DisplayName = "Thunder" },
	{ Id = "Normal", DisplayName = "Normal" },
}

local RARITY_SAMPLES: { RaritySample } = {
	{ Rarity = "Common", ChancePercent = "38", ItemCount = 6, UnlockedCount = 3 },
	{ Rarity = "Rare", ChancePercent = "12", ItemCount = 9, UnlockedCount = 4 },
}

local REWARDS: { [string]: RewardInfo } = {
	Plasma = { DisplayName = "Diamond", IsClaimable = false, IsClaimed = false },
	Thunder = { DisplayName = "Ruby", IsClaimable = true, IsClaimed = false },
	Normal = { DisplayName = "Iron", IsClaimable = false, IsClaimed = true },
}

local IndexMockData = {}

local function buildEntries(mutation: string, sample: RaritySample): { IndexEntry }
	local entries = {}
	for i = 1, sample.ItemCount do
		table.insert(entries, {
			Id = string.format("%s_%s_%d", mutation, sample.Rarity, i),
			DisplayName = string.format("%s %s %d", mutation, WEAPON_SUFFIX, i),
			Rarity = sample.Rarity,
			IsUnlocked = i <= sample.UnlockedCount,
			Image = SAMPLE_IMAGE,
		})
	end
	return entries
end

function IndexMockData.GetTabs(): { IndexTab }
	return TABS
end

function IndexMockData.GetCollections(tabId: string): { IndexCollection }
	local collections = {}
	for _, sample in RARITY_SAMPLES do
		table.insert(collections, {
			Id = tabId .. "_" .. sample.Rarity,
			Rarity = sample.Rarity,
			ChancePercent = sample.ChancePercent,
			Image = SAMPLE_IMAGE,
			Entries = buildEntries(tabId, sample),
		})
	end
	return collections
end

function IndexMockData.GetReward(tabId: string): RewardInfo?
	return REWARDS[tabId]
end

function IndexMockData.GetTotalProgress(): (number, number)
	return TOTAL_UNLOCKED, TOTAL_ENTRIES
end

return IndexMockData
