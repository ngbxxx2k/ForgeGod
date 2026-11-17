--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StatusEffectConfig = require(ReplicatedStorage.Shared.Config.StatusEffectConfig)

local TOOLTIP_NAME = "Tooltip"
local TITLE_NAME = "Title"
local DESCRIPTION_NAME = "Description"

local StatusEffectTooltip = {}

local tooltip: Frame? = nil
local titleLabel: TextLabel? = nil
local descriptionLabel: TextLabel? = nil
local currentAnchor: GuiObject? = nil

local function createLabel(name: string, order: number, font: Enum.Font, size: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.LayoutOrder = order
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = font
	label.TextSize = size
	label.ZIndex = StatusEffectConfig.TooltipZIndex
	return label
end

local function addDecorations(frame: Frame)
	local padding = Instance.new("UIPadding")
	local inset = UDim.new(0, StatusEffectConfig.TooltipPadding)
	padding.PaddingTop = inset
	padding.PaddingBottom = inset
	padding.PaddingLeft = inset
	padding.PaddingRight = inset
	padding.Parent = frame
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, StatusEffectConfig.TooltipCornerRadius)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = StatusEffectConfig.TooltipStrokeColor
	stroke.Transparency = StatusEffectConfig.TooltipStrokeTransparency
	stroke.Parent = frame
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, StatusEffectConfig.TooltipLineSpacing)
	layout.Parent = frame
end

local function createTooltip(gui: LayerCollector): Frame
	local frame = Instance.new("Frame")
	frame.Name = TOOLTIP_NAME
	frame.AnchorPoint = Vector2.new(1, 1)
	frame.Size = UDim2.fromOffset(StatusEffectConfig.TooltipWidth, 0)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.BackgroundColor3 = StatusEffectConfig.TooltipBackgroundColor
	frame.BackgroundTransparency = StatusEffectConfig.TooltipBackgroundTransparency
	frame.ZIndex = StatusEffectConfig.TooltipZIndex
	frame.Visible = false
	addDecorations(frame)
	local config = StatusEffectConfig
	local title = createLabel(TITLE_NAME, 1, config.TooltipTitleFont, config.TooltipTitleSize)
	title.TextColor3 = StatusEffectConfig.TooltipTitleColor
	title.Parent = frame
	local body = createLabel(DESCRIPTION_NAME, 2, config.TooltipTextFont, config.TooltipTextSize)
	body.TextColor3 = StatusEffectConfig.TooltipTextColor
	body.Parent = frame
	frame.Parent = gui
	titleLabel = title
	descriptionLabel = body
	return frame
end

function StatusEffectTooltip.Bind(gui: LayerCollector)
	local existing = gui:FindFirstChild(TOOLTIP_NAME)
	if existing then
		existing:Destroy()
	end
	currentAnchor = nil
	tooltip = createTooltip(gui)
end

function StatusEffectTooltip.Show(anchor: GuiObject, title: string, description: string)
	local frame, titleText, bodyText = tooltip, titleLabel, descriptionLabel
	if not frame or not titleText or not bodyText then
		return
	end
	titleText.Text = title
	bodyText.Text = description
	bodyText.Visible = description ~= ""
	local anchorRight = anchor.AbsolutePosition.X + anchor.AbsoluteSize.X
	local anchorTop = anchor.AbsolutePosition.Y - StatusEffectConfig.TooltipGap
	frame.Position = UDim2.fromOffset(anchorRight, anchorTop)
	frame.Visible = true
	currentAnchor = anchor
end

function StatusEffectTooltip.Hide(anchor: GuiObject?)
	local frame = tooltip
	if not frame or (anchor ~= nil and anchor ~= currentAnchor) then
		return
	end
	frame.Visible = false
	currentAnchor = nil
end

function StatusEffectTooltip.IsShowing(anchor: GuiObject): boolean
	return currentAnchor == anchor
end

return StatusEffectTooltip
