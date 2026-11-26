--!strict

export type WeaponType = {
	Id: string,
	Rarity: string,
	Family: string,
	DisplayName: string,
	MaxShapeStage: number,
}

type FamilyEntry = { Family: string, MaxShapeStage: number }

local RARITY_ORDER = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" }
local FAMILIES = { "Sword", "Axe", "Spear", "Dagger", "Hammer", "Scythe" }

local FAMILIES_BY_RARITY: { [string]: { FamilyEntry } } = {
	Common = {
		{ Family = "Sword", MaxShapeStage = 2 },
		{ Family = "Scythe", MaxShapeStage = 1 },
	},
	Uncommon = {
		{ Family = "Sword", MaxShapeStage = 2 },
		{ Family = "Axe", MaxShapeStage = 2 },
		{ Family = "Hammer", MaxShapeStage = 2 },
	},
	Rare = {
		{ Family = "Sword", MaxShapeStage = 3 },
		{ Family = "Axe", MaxShapeStage = 3 },
		{ Family = "Dagger", MaxShapeStage = 3 },
	},
	Epic = {
		{ Family = "Sword", MaxShapeStage = 4 },
		{ Family = "Scythe", MaxShapeStage = 4 },
		{ Family = "Axe", MaxShapeStage = 4 },
	},
	Legendary = {
		{ Family = "Sword", MaxShapeStage = 5 },
		{ Family = "Axe", MaxShapeStage = 5 },
		{ Family = "Spear", MaxShapeStage = 5 },
	},
	Mythic = {
		{ Family = "Sword", MaxShapeStage = 5 },
	},
}

local NAME_PREFIX = {
	Common = "Copper",
	Uncommon = "Iron",
	Rare = "Silver",
	Epic = "Golden",
	Legendary = "Platinum",
	Mythic = "Godly",
}

local WeaponCatalog = {}

WeaponCatalog.Families = FAMILIES
WeaponCatalog.RarityOrder = RARITY_ORDER

WeaponCatalog.Types = {} :: { [string]: { WeaponType } }
WeaponCatalog.ById = {} :: { [string]: WeaponType }

for _, rarity in RARITY_ORDER do
	local list = {}
	for _, entry in FAMILIES_BY_RARITY[rarity] do
		local weaponType: WeaponType = {
			Id = rarity .. entry.Family,
			Rarity = rarity,
			Family = entry.Family,
			DisplayName = NAME_PREFIX[rarity] .. " " .. entry.Family,
			MaxShapeStage = entry.MaxShapeStage,
		}
		table.insert(list, weaponType)
		WeaponCatalog.ById[weaponType.Id] = weaponType
	end
	WeaponCatalog.Types[rarity] = list
end

function WeaponCatalog.Resolve(weaponTypeId: string?): WeaponType?
	if weaponTypeId == nil then
		return nil
	end
	local exact = WeaponCatalog.ById[weaponTypeId]
	if exact then
		return exact
	end
	for _, rarity in RARITY_ORDER do
		if string.sub(weaponTypeId, 1, #rarity) == rarity then
			return WeaponCatalog.Types[rarity][1]
		end
	end
	return nil
end

return WeaponCatalog
