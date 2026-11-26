--!strict

export type WeaponIcon = {
	DisplayName: string,
	Image: string,
	RectOffset: Vector2,
	RectSize: Vector2,
}

local CELL_SIZE = 256

local SHEETS = {
	"rbxassetid://93736364933653",
	"rbxassetid://133014722728827",
	"rbxassetid://110689422184661",
	"rbxassetid://98611313377679",
}

local ENTRIES = {
	{ "CommonScythe", 1, "Field Scythe", 1, 0, 0 },
	{ "CommonSword", 1, "Iron Arming Sword", 1, 1, 0 },
	{ "CommonSword", 2, "Iron Greatsword", 1, 2, 0 },
	{ "UncommonAxe", 1, "Crescent Battleaxe", 1, 3, 0 },
	{ "UncommonAxe", 2, "Batwing Battleaxe", 1, 0, 1 },
	{ "UncommonHammer", 1, "Spiked War Pick", 1, 1, 1 },
	{ "UncommonHammer", 2, "Chevron War Pick", 1, 2, 1 },
	{ "UncommonSword", 1, "Notched Longsword", 1, 3, 1 },
	{ "UncommonSword", 2, "Bronzeguard Longsword", 1, 0, 2 },
	{ "RareAxe", 1, "Bearded Hatchet", 1, 1, 2 },
	{ "RareAxe", 2, "Gilded War Axe", 1, 2, 2 },
	{ "RareAxe", 3, "Hooked Battleaxe", 1, 3, 2 },
	{ "RareDagger", 1, "Leaf Dagger", 1, 0, 3 },
	{ "RareDagger", 2, "Gilded Dagger", 1, 1, 3 },
	{ "RareDagger", 3, "Spired Dagger", 1, 2, 3 },
	{ "RareSword", 1, "Slender Longsword", 1, 3, 3 },
	{ "RareSword", 2, "Wingguard Longsword", 2, 0, 0 },
	{ "RareSword", 3, "Crownguard Sword", 2, 1, 0 },
	{ "EpicAxe", 1, "Broad Double Axe", 2, 2, 0 },
	{ "EpicAxe", 2, "Twinfang Double Axe", 2, 3, 0 },
	{ "EpicAxe", 3, "Crown Double Axe", 2, 0, 1 },
	{ "EpicAxe", 4, "Gilded Double Axe", 2, 1, 1 },
	{ "EpicScythe", 1, "Reaper Scythe", 2, 2, 1 },
	{ "EpicScythe", 2, "Crescent Scythe", 2, 3, 1 },
	{ "EpicScythe", 3, "Thorn Scythe", 2, 0, 2 },
	{ "EpicScythe", 4, "Spined Scythe", 2, 1, 2 },
	{ "EpicSword", 1, "Needle Sword", 2, 2, 2 },
	{ "EpicSword", 2, "Warden Sword", 2, 3, 2 },
	{ "EpicSword", 3, "Fang Sword", 2, 0, 3 },
	{ "EpicSword", 4, "Thornguard Sword", 2, 1, 3 },
	{ "LegendaryAxe", 1, "Bearded War Axe", 2, 2, 3 },
	{ "LegendaryAxe", 2, "Winged War Axe", 2, 3, 3 },
	{ "LegendaryAxe", 3, "Crystal Halberd", 3, 0, 0 },
	{ "LegendaryAxe", 4, "Storm Double Axe", 3, 1, 0 },
	{ "LegendaryAxe", 5, "Crescent Double Axe", 3, 2, 0 },
	{ "LegendarySpear", 1, "Needle Spear", 3, 3, 0 },
	{ "LegendarySpear", 2, "Lance Spear", 3, 0, 1 },
	{ "LegendarySpear", 3, "Crystal Spear", 3, 1, 1 },
	{ "LegendarySpear", 4, "Gilded Spear", 3, 2, 1 },
	{ "LegendarySpear", 5, "Winged Spear", 3, 3, 1 },
	{ "LegendarySword", 1, "Runic Longsword", 3, 0, 2 },
	{ "LegendarySword", 2, "Broad Greatsword", 3, 1, 2 },
	{ "LegendarySword", 3, "Rune Greatsword", 3, 2, 2 },
	{ "LegendarySword", 4, "Thorn Greatsword", 3, 3, 2 },
	{ "LegendarySword", 5, "Winged Greatsword", 3, 0, 3 },
	{ "MythicSword", 1, "Slim Wingblade", 3, 1, 3 },
	{ "MythicSword", 2, "Pillar Greatsword", 3, 2, 3 },
	{ "MythicSword", 3, "Feather Greatsword", 3, 3, 3 },
	{ "MythicSword", 4, "Clawtip Greatsword", 4, 0, 0 },
	{ "MythicSword", 5, "Forktip Greatsword", 4, 1, 0 },
}

local WeaponIcons = {}

WeaponIcons.ByKey = {} :: { [string]: WeaponIcon }

function WeaponIcons.Key(weaponTypeId: string, shapeStage: number): string
	return weaponTypeId .. "|" .. tostring(shapeStage)
end

for _, entry in ENTRIES do
	local typeId, stage, displayName, sheet, column, row = table.unpack(entry :: { any })
	WeaponIcons.ByKey[WeaponIcons.Key(typeId, stage)] = {
		DisplayName = displayName,
		Image = SHEETS[sheet],
		RectOffset = Vector2.new(column * CELL_SIZE, row * CELL_SIZE),
		RectSize = Vector2.new(CELL_SIZE, CELL_SIZE),
	}
end

function WeaponIcons.Get(weaponTypeId: string, shapeStage: number): WeaponIcon?
	return WeaponIcons.ByKey[WeaponIcons.Key(weaponTypeId, shapeStage)]
end

return WeaponIcons
