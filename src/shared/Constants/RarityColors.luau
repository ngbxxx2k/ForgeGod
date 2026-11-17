--!strict

export type RarityColor = {
	Gradient: ColorSequence,
	Rotation: number,
}

local VERTICAL = 90
local DIAGONAL = 45

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
	Mythic = {
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 70)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 160, 50)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 235, 70)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 230, 100)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(70, 200, 255)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(90, 110, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 90, 255)),
		}),
		Rotation = DIAGONAL,
	},
} :: { [string]: RarityColor }

RarityColors.Default = RarityColors.ByRarity.Common

function RarityColors.Get(rarity: string): RarityColor
	return RarityColors.ByRarity[rarity] or RarityColors.Default
end

return RarityColors
