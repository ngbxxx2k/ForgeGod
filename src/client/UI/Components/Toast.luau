--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local NotificationConfig = require(ReplicatedStorage.Shared.Config.NotificationConfig)

export type ToastKind = "Success" | "Error"

type Entry = {
	Card: Frame,
	IsClosing: boolean,
}

local POP_TWEEN = TweenInfo.new(NotificationConfig.PopInTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local FADE_TWEEN = TweenInfo.new(NotificationConfig.FadeOutTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local Toast = {}

local container: Frame? = nil
local entries: { Entry } = {}
local orderCounter = 0

local function createContainer(): Frame
	local gui = Instance.new("ScreenGui")
	gui.Name = NotificationConfig.GuiName
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = NotificationConfig.DisplayOrder
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local frame = Instance.new("Frame")
	frame.Name = "Stack"
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.new(0.5, 0, 0, NotificationConfig.TopOffset)
	frame.Size = UDim2.new(0, NotificationConfig.MaxWidth, 1, -NotificationConfig.TopOffset)
	frame.BackgroundTransparency = 1
	frame.Parent = gui

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, NotificationConfig.Spacing)
	layout.Parent = frame

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return frame
end

local function getContainer(): Frame
	local existing = container
	if existing and existing.Parent and existing.Parent.Parent then
		return existing
	end
	local created = createContainer()
	container = created
	return created
end

local function addOutline(parent: GuiObject, thickness: number, mode: Enum.ApplyStrokeMode)
	local stroke = Instance.new("UIStroke")
	stroke.Color = NotificationConfig.OutlineColor
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = mode
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = parent
end

local function addCardDecor(card: Frame, kind: ToastKind)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, NotificationConfig.CornerRadius)
	corner.Parent = card

	local gradient = Instance.new("UIGradient")
	gradient.Color = NotificationConfig.Gradients[kind]
	gradient.Rotation = NotificationConfig.GradientRotation
	gradient.Parent = card

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, NotificationConfig.HorizontalPadding)
	padding.PaddingRight = UDim.new(0, NotificationConfig.HorizontalPadding)
	padding.Parent = card

	local sizeLimit = Instance.new("UISizeConstraint")
	sizeLimit.MinSize = Vector2.new(NotificationConfig.MinWidth, NotificationConfig.Height)
	sizeLimit.MaxSize = Vector2.new(NotificationConfig.MaxWidth, NotificationConfig.Height)
	sizeLimit.Parent = card

	addOutline(card, NotificationConfig.OutlineThickness, Enum.ApplyStrokeMode.Border)
end

local function createLabel(text: string): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.fromScale(0, 1)
	label.BackgroundTransparency = 1
	label.Font = NotificationConfig.Font
	label.TextSize = NotificationConfig.TextSize
	label.TextColor3 = NotificationConfig.TextColor
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = text
	addOutline(label, NotificationConfig.TextStrokeThickness, Enum.ApplyStrokeMode.Contextual)
	return label
end

local function createCard(text: string, kind: ToastKind): Frame
	local card = Instance.new("Frame")
	card.Name = "Toast"
	card.AutomaticSize = Enum.AutomaticSize.X
	card.Size = UDim2.fromOffset(0, NotificationConfig.Height)
	card.BackgroundColor3 = Color3.new(1, 1, 1)
	card.BorderSizePixel = 0
	addCardDecor(card, kind)

	local label = createLabel(text)
	label.Parent = card

	local scale = Instance.new("UIScale")
	scale.Scale = NotificationConfig.PopInStartScale
	scale.Parent = card
	return card
end

local function removeEntry(entry: Entry)
	local index = table.find(entries, entry)
	if index then
		table.remove(entries, index)
	end
	entry.Card:Destroy()
end

local function fadeOut(entry: Entry)
	if entry.IsClosing or entry.Card.Parent == nil then
		return
	end
	entry.IsClosing = true
	local card = entry.Card
	TweenService:Create(card, FADE_TWEEN, { BackgroundTransparency = 1 }):Play()
	for _, child in card:GetDescendants() do
		if child:IsA("UIStroke") then
			TweenService:Create(child, FADE_TWEEN, { Transparency = 1 }):Play()
		elseif child:IsA("TextLabel") then
			TweenService:Create(child, FADE_TWEEN, { TextTransparency = 1 }):Play()
		end
	end
	task.delay(NotificationConfig.FadeOutTime, removeEntry, entry)
end

local function trimOverflow()
	while #entries > NotificationConfig.MaxVisible do
		removeEntry(entries[1])
	end
end

local function show(text: string, kind: ToastKind)
	local parent = getContainer()
	orderCounter += 1
	local card = createCard(text, kind)
	card.LayoutOrder = orderCounter
	card.Parent = parent
	local entry: Entry = { Card = card, IsClosing = false }
	table.insert(entries, entry)
	trimOverflow()
	local scale = card:FindFirstChildOfClass("UIScale")
	if scale then
		TweenService:Create(scale, POP_TWEEN, { Scale = 1 }):Play()
	end
	task.delay(NotificationConfig.Duration, fadeOut, entry)
end

function Toast.Success(text: string)
	show(text, "Success")
end

function Toast.Error(text: string)
	show(text, "Error")
end

return Toast
