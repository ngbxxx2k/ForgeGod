--!strict

local function verticalGradient(top: Color3, middle: Color3, bottom: Color3): ColorSequence
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, top),
		ColorSequenceKeypoint.new(0.5, middle),
		ColorSequenceKeypoint.new(1, bottom),
	})
end

local ShopColors = {}

ShopColors.HeaderGradients = {
	Item = verticalGradient(
		Color3.fromRGB(130, 235, 110),
		Color3.fromRGB(60, 190, 70),
		Color3.fromRGB(30, 130, 45)
	),
} :: { [string]: ColorSequence }

return ShopColors
