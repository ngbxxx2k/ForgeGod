--!strict

local ForgeUpgradeColors = {}

ForgeUpgradeColors.InactiveTabGradient = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(165, 168, 180)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 123, 135)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(85, 88, 100)),
})

ForgeUpgradeColors.HudButtonGradient = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(105, 40, 220)),
	ColorSequenceKeypoint.new(0.55, Color3.fromRGB(150, 95, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(232, 220, 255)),
})

return ForgeUpgradeColors
