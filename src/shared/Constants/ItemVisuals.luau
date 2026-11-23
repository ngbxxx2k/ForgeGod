--!strict

local BuffConfig = require(script.Parent.Parent.Config.BuffConfig)
local AssetIds = require(script.Parent.AssetIds)

export type ItemVisual = {
	Image: string?,
	Color: Color3?,
	RarityLabel: string?,
}

-- PLACEHOLDER: màu tạm thay cho hình quặng, nhãn độ hiếm quặng chưa có trong doc
local ItemVisuals: { [string]: ItemVisual } = {
	Copper = { Image = AssetIds.Ores.Icons.Copper, RarityLabel = "Common" },
	Iron = { Image = AssetIds.Ores.Icons.Iron, RarityLabel = "Common" },
	Silver = { Image = AssetIds.Ores.Icons.Silver, RarityLabel = "Rare" },
	Gold = { Image = AssetIds.Ores.Icons.Gold, RarityLabel = "Rare" },
	Platinum = { Image = AssetIds.Ores.Icons.Platinum, RarityLabel = "Epic" },
	Emerald = { Image = AssetIds.Ores.Icons.Emerald, RarityLabel = "Epic" },
	DarkMoonstone = { Image = AssetIds.Ores.Icons.DarkMoonstone, RarityLabel = "Legendary" },
	Mithril = { Image = AssetIds.Ores.Icons.Mithril, RarityLabel = "Legendary" },
	GodsCore = { Image = AssetIds.Ores.Icons.GodsCore, RarityLabel = "Mythic" },

	-- PLACEHOLDER: điền "rbxassetid://..." cho icon buff (dùng chung Shop, Backpack, icon buff)
	BlessingPotion = { Image = AssetIds.Icons.BlessingPotion },
	LuckPotion = { Image = AssetIds.Icons.LuckPotion },
	Talisman = {},
	MerchantPotion = { Image = AssetIds.Icons.MerchantPotion },
	MutationCatalyst = { Image = AssetIds.Icons.MutationCatalyst },
	AlloyFluxPotion = {},
	StormPotion = {},
	MutationEraser = { Image = AssetIds.Icons.MutationEraser },
}

for _, buff in BuffConfig.Buffs do
	local visual = ItemVisuals[buff.Id] or {}
	visual.RarityLabel = buff.Rarity
	ItemVisuals[buff.Id] = visual
end

return ItemVisuals
