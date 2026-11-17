--!strict

local StatusEffectConfig = {
	MaxIconsPerRow = 10,
	IconSize = 52,
	TimerHeight = 18,
	CellPadding = 6,
	ScreenMarginRight = 16,
	ScreenMarginBottom = 16,
	TimerRefreshInterval = 0.25,
	PopInTime = 0.25,
	PopOutTime = 0.15,
	ReferenceScreenHeight = 720,
	MinScreenScale = 0.7,
	PlaceholderLabelLength = 2,
	CountLabelScale = 0.5,
	CountStrokeThickness = 1.5,
	CountTextColor = Color3.fromRGB(255, 255, 255),
	CountFont = Enum.Font.GothamBold,
	TooltipWidth = 220,
	TooltipPadding = 8,
	TooltipGap = 6,
	TooltipLineSpacing = 4,
	TooltipTitleSize = 16,
	TooltipTextSize = 14,
	TooltipCornerRadius = 6,
	TooltipZIndex = 10,
	TooltipBackgroundColor = Color3.fromRGB(20, 20, 28),
	TooltipBackgroundTransparency = 0.1,
	TooltipStrokeColor = Color3.fromRGB(255, 255, 255),
	TooltipStrokeTransparency = 0.7,
	TooltipTitleColor = Color3.fromRGB(255, 220, 120),
	TooltipTextColor = Color3.fromRGB(235, 235, 235),
	TooltipTitleFont = Enum.Font.GothamBold,
	TooltipTextFont = Enum.Font.Gotham,
}

StatusEffectConfig.KindPriority = {
	Weather = 0,
	Buff = 1,
}

return StatusEffectConfig
