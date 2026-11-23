--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ForgeAnimationConfig = require(ReplicatedStorage.Shared.Config.ForgeAnimationConfig)
local RarityGradient = require(script.Parent.RarityGradient)
local ResultLabel = require(script.Parent.Parent.Parent.Effects.ResultLabel)
local RevealCleanup = require(script.Parent.Parent.Parent.Effects.RevealCleanup)

local GUI_NAME = "ForgeRevealInfoCard"
local CENTER = Vector2.new(0.5, 0.5)
local ROW_COUNT = 4

export type Card = {
	Gui: ScreenGui,
	Scale: UIScale,
	Texts: { TextLabel },
	Strokes: { UIStroke },
	Cleanup: RevealCleanup.Cleanup,
}

local RevealInfoCard = {}

local function getCardHeight(): number
	local config = ForgeAnimationConfig.InfoCard
	local rows = ROW_COUNT - 1 + config.TitleHeightMultiplier
	return rows * config.RowHeightPixels + (ROW_COUNT - 1) * config.RowGap
end

local function createHolder(gui: ScreenGui): (Frame, UIScale)
	local config = ForgeAnimationConfig.InfoCard
	local holder = Instance.new("Frame")
	holder.AnchorPoint = CENTER
	holder.Position = UDim2.fromScale(CENTER.X, CENTER.Y)
	holder.Size = UDim2.fromOffset(config.WidthPixels, getCardHeight())
	holder.BackgroundTransparency = 1
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, config.RowGap)
	layout.Parent = holder
	local scale = Instance.new("UIScale")
	scale.Scale = config.PopStartScale
	scale.Parent = holder
	holder.Parent = gui
	return holder, scale
end

local function createRow(card: Card, holder: Frame, order: number, heightRows: number, text: string, rarity: string)
	local config = ForgeAnimationConfig.InfoCard
	local label = Instance.new("TextLabel")
	label.LayoutOrder = order
	label.Size = UDim2.new(1, 0, 0, config.RowHeightPixels * heightRows)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.FontFace = ForgeAnimationConfig.CutsceneFont
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextTransparency = 1
	label.Text = text
	RarityGradient.Apply(label, rarity)
	local stroke = Instance.new("UIStroke")
	stroke.Color = config.StrokeColor
	stroke.Thickness = config.StrokeThickness
	stroke.Transparency = 1
	stroke.Parent = label
	label.Parent = holder
	table.insert(card.Texts, label)
	table.insert(card.Strokes, stroke)
end

local function playTween(card: Card, target: Instance, info: TweenInfo, goal: { [string]: any })
	local tween = TweenService:Create(target, info, goal)
	RevealCleanup.Add(card.Cleanup, tween)
	tween:Play()
end

local function fadeAll(card: Card, info: TweenInfo, transparency: number)
	for _, text in card.Texts do
		playTween(card, text, info, { TextTransparency = transparency })
	end
	for _, stroke in card.Strokes do
		playTween(card, stroke, info, { Transparency = transparency })
	end
end

function RevealInfoCard.Show(lines: ResultLabel.ResultLines, cleanup: RevealCleanup.Cleanup): Card
	local config = ForgeAnimationConfig.InfoCard
	local gui = Instance.new("ScreenGui")
	gui.Name = GUI_NAME
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = config.DisplayOrder
	local holder, scale = createHolder(gui)
	local card: Card = { Gui = gui, Scale = scale, Texts = {}, Strokes = {}, Cleanup = cleanup }
	createRow(card, holder, 1, config.TitleHeightMultiplier, lines.RarityText, lines.Rarity)
	createRow(card, holder, 2, 1, lines.NameText, lines.Rarity)
	createRow(card, holder, 3, 1, lines.WeightText, lines.Rarity)
	createRow(card, holder, 4, 1, lines.PriceText, lines.Rarity)
	RevealCleanup.Add(cleanup, gui)
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	local info = TweenInfo.new(config.PopTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	playTween(card, scale, info, { Scale = 1 })
	fadeAll(card, info, 0)
	return card
end

function RevealInfoCard.Hide(card: Card)
	local config = ForgeAnimationConfig.InfoCard
	local info = TweenInfo.new(config.HideTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	playTween(card, card.Scale, info, { Scale = config.HideScale })
	fadeAll(card, info, 1)
	local gui = card.Gui
	task.delay(config.HideTime, function()
		gui:Destroy()
	end)
end

return RevealInfoCard
