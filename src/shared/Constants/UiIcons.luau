--!strict

local AssetIds = require(script.Parent.AssetIds)

local UiIcons = {
	Locked = AssetIds.Icons.Locked,
	Unlocked = AssetIds.Icons.Unlocked,
	BackpackTabs = {
		Weapon = AssetIds.Icons.TabWeapon,
		Ore = AssetIds.Icons.TabOre,
		Buff = AssetIds.Icons.TabBuff,
	},
	ShopCategories = {
		Ore = AssetIds.Icons.TabOre,
		Item = AssetIds.Icons.TabBuff,
	},
}

return UiIcons
