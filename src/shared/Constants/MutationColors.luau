--!strict

export type MutationColor = {
	Gradient: ColorSequence,
	Rotation: number,
}

local VERTICAL = 90

local function vertical(top: Color3, bottom: Color3): MutationColor
	return { Gradient = ColorSequence.new(top, bottom), Rotation = VERTICAL }
end

local MutationColors = {}

MutationColors.ById = {
	Normal = vertical(Color3.fromRGB(225, 228, 235), Color3.fromRGB(150, 156, 170)),
	Molten = vertical(Color3.fromRGB(255, 150, 60), Color3.fromRGB(205, 50, 20)),
	Aqua = vertical(Color3.fromRGB(110, 225, 255), Color3.fromRGB(25, 130, 220)),
	Thunder = vertical(Color3.fromRGB(255, 240, 90), Color3.fromRGB(230, 160, 0)),
	Aurora = vertical(Color3.fromRGB(120, 255, 200), Color3.fromRGB(150, 90, 240)),
	Radioactive = vertical(Color3.fromRGB(200, 255, 70), Color3.fromRGB(70, 170, 20)),
	Shadow = vertical(Color3.fromRGB(120, 100, 150), Color3.fromRGB(40, 30, 60)),
	Plasma = vertical(Color3.fromRGB(255, 110, 240), Color3.fromRGB(160, 30, 200)),
} :: { [string]: MutationColor }

MutationColors.Default = MutationColors.ById.Normal

function MutationColors.Get(mutationId: string): MutationColor
	return MutationColors.ById[mutationId] or MutationColors.Default
end

function MutationColors.GetTextHex(mutationId: string): string
	local keypoints = MutationColors.Get(mutationId).Gradient.Keypoints
	return "#" .. keypoints[1].Value:ToHex()
end

return MutationColors
