--!strict

local function gradient(top: Color3, middle: Color3, bottom: Color3): ColorSequence
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, top),
		ColorSequenceKeypoint.new(0.5, middle),
		ColorSequenceKeypoint.new(1, bottom),
	})
end

local NotificationConfig = {
	GuiName = "NotificationGui",
	DisplayOrder = 50,
	MaxVisible = 4,
	Duration = 2.5,
	TopOffset = 6,
	Spacing = 8,
	Height = 46,
	MinWidth = 220,
	MaxWidth = 560,
	HorizontalPadding = 22,
	CornerRadius = 12,
	OutlineColor = Color3.fromRGB(15, 15, 25),
	OutlineThickness = 3,
	TextColor = Color3.fromRGB(255, 255, 255),
	TextSize = 22,
	TextStrokeThickness = 2.5,
	Font = Enum.Font.FredokaOne,
	GradientRotation = 90,
	PopInTime = 0.25,
	PopInStartScale = 0.6,
	FadeOutTime = 0.25,
}

NotificationConfig.Gradients = {
	Success = gradient(Color3.fromRGB(140, 235, 100), Color3.fromRGB(80, 200, 55), Color3.fromRGB(45, 150, 35)),
	Error = gradient(Color3.fromRGB(234, 108, 115), Color3.fromRGB(225, 45, 55), Color3.fromRGB(169, 34, 41)),
} :: { [string]: ColorSequence }

return NotificationConfig
