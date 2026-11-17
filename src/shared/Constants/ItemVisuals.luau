--!strict

local BuffConfig = require(script.Parent.Parent.Config.BuffConfig)

export type ItemVisual = {
	Image: string?,
	Color: Color3?,
	RarityLabel: string?,
}

-- PLACEHOLDER: màu tạm thay cho hình quặng, nhãn độ hiếm quặng chưa có trong doc
local ItemVisuals: { [string]: ItemVisual } = {
	Copper = { Color = Color3.fromRGB(196, 112, 64), RarityLabel = "Common" },
	Iron = { Color = Color3.fromRGB(150, 150, 160), RarityLabel = "Common" },
	Silver = { Color = Color3.fromRGB(215, 220, 230), RarityLabel = "Rare" },
	Gold = { Color = Color3.fromRGB(240, 200, 60), RarityLabel = "Rare" },
	Platinum = { Color = Color3.fromRGB(170, 215, 235), RarityLabel = "Epic" },
	Emerald = { Color = Color3.fromRGB(60, 200, 110), RarityLabel = "Epic" },
	DarkMoonstone = { Color = Color3.fromRGB(80, 60, 140), RarityLabel = "Legendary" },
	Mithril = { Color = Color3.fromRGB(90, 230, 230), RarityLabel = "Legendary" },
	GodsCore = { Color = Color3.fromRGB(255, 90, 60), RarityLabel = "Mythic" },

	-- PLACEHOLDER: điền "rbxassetid://..." cho icon buff (dùng chung Shop, Backpack, icon buff)
	BlessingPotion = { Image = "rbxassetid://78094983031159" },
	LuckPotion = { Image = "rbxassetid://121876953896571" },
	Talisman = {},
	MerchantPotion = { Image = "rbxassetid://116963935438327" },
	MutationCatalyst = { Image = "rbxassetid://100327421950126" },
	AlloyFluxPotion = {},
	StormPotion = {},
	MutationEraser = { Image = "rbxassetid://76236204024421" },
}

for _, buff in BuffConfig.Buffs do
	local visual = ItemVisuals[buff.Id] or {}
	visual.RarityLabel = buff.Rarity
	ItemVisuals[buff.Id] = visual
end

return ItemVisuals
