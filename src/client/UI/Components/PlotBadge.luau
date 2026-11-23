--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetIds = require(ReplicatedStorage.Shared.Constants.AssetIds)
local PlotConfig = require(ReplicatedStorage.Shared.Config.PlotConfig)

local NAME_GAP = 4

local PlotBadge = {}

local function createIcon(image: string, isHome: boolean): ImageLabel
	local size = PlotConfig.BadgeIconSize
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.fromOffset(size, size)
	icon.Position = UDim2.fromScale(0.5, 0)
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.Image = image
	icon.ScaleType = Enum.ScaleType.Fit
	if isHome then
		icon.BackgroundTransparency = 1
		return icon
	end
	icon.BackgroundColor3 = PlotConfig.BadgeIconBackground
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = icon
	local stroke = Instance.new("UIStroke")
	stroke.Color = PlotConfig.BadgeOutlineColor
	stroke.Thickness = PlotConfig.BadgeOutlineThickness
	stroke.Parent = icon
	return icon
end

local function createName(text: string): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = "OwnerName"
	label.Size = UDim2.fromOffset(PlotConfig.BadgeNameWidth, PlotConfig.BadgeNameHeight)
	label.Position = UDim2.new(0.5, 0, 0, PlotConfig.BadgeIconSize + NAME_GAP)
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.BackgroundTransparency = 1
	label.Font = PlotConfig.LabelFont
	label.TextScaled = true
	label.TextColor3 = PlotConfig.LabelTextColor
	label.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Color = PlotConfig.BadgeOutlineColor
	stroke.Thickness = PlotConfig.LabelStrokeThickness
	stroke.Parent = label
	return label
end

function PlotBadge.Build(
	adornee: Attachment,
	userId: number,
	displayName: string,
	isHome: boolean
): BillboardGui
	local height = if isHome
		then PlotConfig.BadgeIconSize
		else PlotConfig.BadgeIconSize + NAME_GAP + PlotConfig.BadgeNameHeight
	local gui = Instance.new("BillboardGui")
	gui.Name = PlotConfig.BadgeName
	gui.Adornee = adornee
	gui.Size = UDim2.fromOffset(PlotConfig.BadgeNameWidth, height)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	local image = if isHome
		then AssetIds.Icons.Home
		else string.format(PlotConfig.BadgeThumbnailFormat, userId)
	createIcon(image, isHome).Parent = gui
	if not isHome then
		createName(displayName).Parent = gui
	end
	return gui
end

return PlotBadge
