--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LeaderboardConfig = require(ReplicatedStorage.Shared.Config.LeaderboardConfig)
local LeaderboardMessages = require(ReplicatedStorage.Shared.Constants.LeaderboardMessages)

local ROW_HEIGHT = 64
local ROW_SCROLLBAR_GAP = 16
local ROW_CORNER = UDim.new(0, 14)
local ROW_STROKE = 3
local CIRCLE_SIZE = 48
local BADGE_X = 8
local AVATAR_X = 64
local NAME_X = 122
local NAME_HEIGHT = 30
local NAME_MAX_TEXT = 26
local VALUE_WIDTH = 0.36
local VALUE_HEIGHT = 32
local VALUE_MAX_TEXT = 28
local VALUE_RIGHT_PADDING = 10
local TEXT_STROKE = 3

export type Row = {
	Frame: Frame,
	Badge: TextLabel,
	Avatar: ImageLabel,
	NameLabel: TextLabel,
	ValueLabel: TextLabel,
}

local LeaderboardRow = {}

local Colors = LeaderboardConfig.Colors

local function addCorner(target: GuiObject, radius: UDim)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = target
end

local function addStroke(target: GuiObject, thickness: number, mode: Enum.ApplyStrokeMode): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = Colors.Outline
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = mode
	stroke.Parent = target
	return stroke
end

local function createText(name: string, maxSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = LeaderboardConfig.Font
	label.TextScaled = true
	label.TextColor3 = Colors.Text
	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MaxTextSize = maxSize
	constraint.Parent = label
	return label
end

local function createCircle(name: string, positionX: number, color: Color3): Frame
	local circle = Instance.new("Frame")
	circle.Name = name
	circle.AnchorPoint = Vector2.new(0, 0.5)
	circle.Position = UDim2.new(0, positionX, 0.5, 0)
	circle.Size = UDim2.fromOffset(CIRCLE_SIZE, CIRCLE_SIZE)
	circle.BackgroundColor3 = color
	addCorner(circle, UDim.new(0.5, 0))
	addStroke(circle, ROW_STROKE, Enum.ApplyStrokeMode.Border)
	return circle
end

local function createBadge(): (Frame, TextLabel)
	local circle = createCircle("RankBadge", BADGE_X, Colors.RankBadge)
	local label = createText("Rank", NAME_MAX_TEXT)
	label.Size = UDim2.fromScale(1, 0.7)
	label.Position = UDim2.fromScale(0, 0.15)
	addStroke(label, TEXT_STROKE, Enum.ApplyStrokeMode.Contextual)
	label.Parent = circle
	return circle, label
end

local function createAvatar(): Frame
	local circle = createCircle("AvatarFrame", AVATAR_X, Colors.Avatar)
	circle.ClipsDescendants = true
	local image = Instance.new("ImageLabel")
	image.Name = "Avatar"
	image.Size = UDim2.fromScale(1, 1)
	image.BackgroundTransparency = 1
	addCorner(image, UDim.new(0.5, 0))
	image.Parent = circle
	return circle
end

local function createLabels(frame: Frame): (TextLabel, TextLabel)
	local nameLabel = createText("PlayerName", NAME_MAX_TEXT)
	nameLabel.AnchorPoint = Vector2.new(0, 0.5)
	nameLabel.Position = UDim2.new(0, NAME_X, 0.5, 0)
	nameLabel.Size = UDim2.new(1 - VALUE_WIDTH, -NAME_X - VALUE_RIGHT_PADDING, 0, NAME_HEIGHT)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = frame
	local valueLabel = createText("Value", VALUE_MAX_TEXT)
	valueLabel.AnchorPoint = Vector2.new(1, 0.5)
	valueLabel.Position = UDim2.new(1, -VALUE_RIGHT_PADDING, 0.5, 0)
	valueLabel.Size = UDim2.new(VALUE_WIDTH, 0, 0, VALUE_HEIGHT)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	addStroke(valueLabel, TEXT_STROKE, Enum.ApplyStrokeMode.Contextual)
	valueLabel.Parent = frame
	return nameLabel, valueLabel
end

function LeaderboardRow.Create(): Row
	local frame = Instance.new("Frame")
	frame.Name = "Row"
	frame.Size = UDim2.new(1, -ROW_SCROLLBAR_GAP, 0, ROW_HEIGHT)
	frame.BackgroundColor3 = Colors.Row
	addCorner(frame, ROW_CORNER)
	addStroke(frame, ROW_STROKE, Enum.ApplyStrokeMode.Border)
	local badgeFrame, badge = createBadge()
	badgeFrame.Parent = frame
	local avatarFrame = createAvatar()
	avatarFrame.Parent = frame
	local nameLabel, valueLabel = createLabels(frame)
	return {
		Frame = frame,
		Badge = badge,
		Avatar = avatarFrame:FindFirstChild("Avatar") :: ImageLabel,
		NameLabel = nameLabel,
		ValueLabel = valueLabel,
	}
end

function LeaderboardRow.Render(
	row: Row,
	rank: number,
	userId: number,
	name: string,
	valueText: string,
	valueColor: Color3
)
	local topColor = Colors.TopRanks[rank]
	row.Frame.LayoutOrder = rank
	row.Frame.BackgroundColor3 = topColor or Colors.Row
	row.Badge.Text = tostring(rank)
	row.Avatar.Image = string.format(LeaderboardMessages.AvatarFormat, userId)
	row.NameLabel.Text = if name ~= "" then name else LeaderboardMessages.UnknownName
	row.NameLabel.TextColor3 = if topColor then Colors.DarkText else Colors.Text
	row.ValueLabel.Text = valueText
	row.ValueLabel.TextColor3 = valueColor
	row.Frame.Visible = true
end

return LeaderboardRow
