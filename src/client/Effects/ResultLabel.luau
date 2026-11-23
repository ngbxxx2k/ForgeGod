--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ForgeAnimationConfig = require(ReplicatedStorage.Shared.Config.ForgeAnimationConfig)
local RarityGradient = require(script.Parent.Parent.UI.Components.RarityGradient)
local RevealCleanup = require(script.Parent.RevealCleanup)

export type ResultLines = {
	Rarity: string,
	RarityText: string,
	NameText: string,
	WeightText: string,
	PriceText: string,
}

export type Label = {
	Anchor: Part,
	Fadeables: { GuiObject | UIStroke },
	Cleanup: RevealCleanup.Cleanup,
}

type Row = {
	Holder: Frame,
	Content: Frame,
	Fadeables: { GuiObject | UIStroke },
}

local ANCHOR_NAME = "ForgeRevealResultLabel"
local ANCHOR_SIZE = Vector3.new(0.2, 0.2, 0.2)
local ROW_COUNT = 4
local HEIGHT_FOR_TOP_HALF = 2

local ResultLabel = {}

local function createAnchor(position: Vector3): Part
	local anchor = Instance.new("Part")
	anchor.Name = ANCHOR_NAME
	anchor.Size = ANCHOR_SIZE
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CFrame = CFrame.new(position)
	return anchor
end

local function getTotalRows(): number
	return ROW_COUNT - 1 + ForgeAnimationConfig.ResultLabel.TitleHeightMultiplier
end

local function createBillboard(anchor: Part): Frame
	local config = ForgeAnimationConfig.ResultLabel
	local billboard = Instance.new("BillboardGui")
	local height = config.RowHeightPixels * getTotalRows()
	billboard.Size = UDim2.fromOffset(config.WidthPixels, height * HEIGHT_FOR_TOP_HALF)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.ResetOnSpawn = false
	billboard.Adornee = anchor
	local rows = Instance.new("Frame")
	rows.BackgroundTransparency = 1
	rows.Size = UDim2.fromScale(1, 1 / HEIGHT_FOR_TOP_HALF)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = rows
	rows.Parent = billboard
	billboard.Parent = anchor
	return rows
end

local function createText(parent: Instance, text: string, rarity: string): (TextLabel, UIStroke)
	local config = ForgeAnimationConfig.ResultLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.FontFace = ForgeAnimationConfig.CutsceneFont
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextTransparency = 1
	label.Text = text
	label.Size = UDim2.fromScale(1, 1)
	RarityGradient.Apply(label, rarity)
	local stroke = Instance.new("UIStroke")
	stroke.Color = config.StrokeColor
	stroke.Thickness = config.StrokeThickness
	stroke.Transparency = 1
	stroke.Parent = label
	label.Parent = parent
	return label, stroke
end

local function createRow(billboard: Frame, order: number, heightRows: number): Row
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, heightRows / getTotalRows())
	holder.LayoutOrder = order
	local content = Instance.new("Frame")
	content.BackgroundTransparency = 1
	content.Size = UDim2.fromScale(1, 1)
	content.Position = UDim2.fromScale(0, ForgeAnimationConfig.ResultLabel.SlideOffset)
	content.Parent = holder
	holder.Parent = billboard
	return { Holder = holder, Content = content, Fadeables = {} }
end

local function addTextRow(billboard: Frame, order: number, height: number, text: string, rarity: string): Row
	local row = createRow(billboard, order, height)
	local label, stroke = createText(row.Content, text, rarity)
	table.insert(row.Fadeables, label)
	table.insert(row.Fadeables, stroke)
	return row
end

local function fadeGoal(target: GuiObject | UIStroke, transparency: number): { [string]: number }
	if target:IsA("TextLabel") then
		return { TextTransparency = transparency }
	end
	return { Transparency = transparency }
end

local function playTween(target: Instance, info: TweenInfo, goal: { [string]: any }, cleanup: RevealCleanup.Cleanup)
	local tween = TweenService:Create(target, info, goal)
	RevealCleanup.Add(cleanup, tween)
	tween:Play()
end

local function revealRow(row: Row, delay: number, cleanup: RevealCleanup.Cleanup)
	local config = ForgeAnimationConfig.ResultLabel
	local info = TweenInfo.new(config.RowTweenTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, delay)
	playTween(row.Content, info, { Position = UDim2.fromScale(0, 0) }, cleanup)
	for _, target in row.Fadeables do
		playTween(target, info, fadeGoal(target, 0), cleanup)
	end
end

function ResultLabel.Show(position: Vector3, lines: ResultLines, cleanup: RevealCleanup.Cleanup): Label
	local config = ForgeAnimationConfig.ResultLabel
	local anchor = createAnchor(position)
	local billboard = createBillboard(anchor)
	local rows = {
		addTextRow(billboard, 1, config.TitleHeightMultiplier, lines.RarityText, lines.Rarity),
		addTextRow(billboard, 2, 1, lines.NameText, lines.Rarity),
		addTextRow(billboard, 3, 1, lines.WeightText, lines.Rarity),
		addTextRow(billboard, 4, 1, lines.PriceText, lines.Rarity),
	}
	anchor.Parent = Workspace
	RevealCleanup.Add(cleanup, anchor)
	local fadeables = {}
	for index, row in rows do
		revealRow(row, (index - 1) * config.RowDelay, cleanup)
		for _, target in row.Fadeables do
			table.insert(fadeables, target)
		end
	end
	return { Anchor = anchor, Fadeables = fadeables, Cleanup = cleanup }
end

function ResultLabel.Hide(label: Label)
	local info = TweenInfo.new(ForgeAnimationConfig.ResultLabel.FadeOutTime)
	for _, target in label.Fadeables do
		playTween(target, info, fadeGoal(target, 1), label.Cleanup)
	end
	task.delay(ForgeAnimationConfig.ResultLabel.FadeOutTime, function()
		label.Anchor:Destroy()
	end)
end

return ResultLabel
