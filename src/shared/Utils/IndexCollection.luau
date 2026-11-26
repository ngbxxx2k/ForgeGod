--!strict

local MutationConfig = require(script.Parent.Parent.Config.MutationConfig)
local WeaponCatalog = require(script.Parent.Parent.Constants.WeaponCatalog)
local IndexKey = require(script.Parent.IndexKey)

local REWARD_KEY_SEPARATOR = "|"

local IndexCollection = {}

function IndexCollection.IsValidTab(tabId: any): boolean
	if type(tabId) ~= "string" then
		return false
	end
	return tabId == IndexKey.NormalId or MutationConfig.ById[tabId] ~= nil
end

function IndexCollection.IsValidRarity(rarity: any): boolean
	return type(rarity) == "string" and WeaponCatalog.Types[rarity] ~= nil
end

function IndexCollection.GetKeys(tabId: string, rarity: string): { string }
	local keys = {}
	for _, weaponType in WeaponCatalog.Types[rarity] or {} do
		for stage = 1, weaponType.MaxShapeStage do
			table.insert(keys, IndexKey.Build(tabId, weaponType.Id, stage))
		end
	end
	return keys
end

function IndexCollection.IsComplete(index: { [string]: boolean }, tabId: string, rarity: string): boolean
	local keys = IndexCollection.GetKeys(tabId, rarity)
	if #keys == 0 then
		return false
	end
	for _, key in keys do
		if index[key] ~= true then
			return false
		end
	end
	return true
end

function IndexCollection.BuildRewardKey(tabId: string, rarity: string): string
	return tabId .. REWARD_KEY_SEPARATOR .. rarity
end

return IndexCollection
