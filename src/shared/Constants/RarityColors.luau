--!strict

export type RarityColor = {
	Gradient: ColorSequence,
	Rotation: number,
}

local VERTICAL = 90

local function vertical(top: Color3, bottom: Color3): RarityColor
	return { Gradient = ColorSequence.new(top, bottom), Rotation = VERTICAL }
end

local RarityColors = {}

RarityColors.ByRarity = {
	Common = vertical(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 204, 214)),
	Uncommon = vertical(Color3.fromRGB(140, 235, 130), Color3.fromRGB(50, 170, 70)),
	Rare = vertical(Color3.fromRGB(100, 180, 255), Color3.fromRGB(30, 100, 225)),
	Epic = vertical(Color3.fromRGB(205, 120, 255), Color3.fromRGB(125, 40, 210)),
	Legendary = vertical(Color3.fromRGB(255, 230, 90), Color3.fromRGB(235, 160, 20)),
	Mythic = vertical(Color3.fromRGB(255, 90, 90), Color3.fromRGB(190, 20, 30)),
} :: { [string]: RarityColor }

RarityColors.Default = RarityColors.ByRarity.Common

function RarityColors.Get(rarity: string): RarityColor
	return RarityColors.ByRarity[rarity] or RarityColors.Default
end

return RarityColors
