--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlotConfig = require(ReplicatedStorage.Shared.Config.PlotConfig)
local PlotUpgradeMessages = require(ReplicatedStorage.Shared.Constants.PlotUpgradeMessages)
local UiSound = require(script.Parent.Parent.Parent.Effects.UiSound)
local HoverEffect = require(script.Parent.HoverEffect)

local HOVER_ATTRIBUTE = "HasHoverEffect"
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local OUTLINE_COLOR = Color3.fromRGB(15, 15, 25)
local OUTLINE_THICKNESS = 3
local BUTTON_OUTLINE_THICKNESS = 4
local CORNER_RADIUS = UDim.new(0, 10)
local CONTENT_WIDTH = 0.92
local BUTTON_GAP = 0.04

export type SignView = {
	Level: number,
	IsMax: boolean,
	CoinText: string,
	RobuxText: string,
}

export type Sign = {
	Model: Model,
	Board: Part,
	Gui: SurfaceGui,
	LevelLabel: TextLabel,
	MaxLabel: TextLabel,
	ButtonRow: Frame,
	CoinButton: TextButton,
	RobuxButton: TextButton,
}

local PlotUpgradeSign = {}

local function createPart(name: string, size: Vector3, color: Color3, cframe: CFrame): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanTouch = false
	part.CFrame = cframe
	return part
end

local function createModel(origin: CFrame): (Model, Part)
	local model = Instance.new("Model")
	model.Name = PlotConfig.UpgradeSignName
	local postSize = PlotConfig.UpgradePostSize
	local boardSize = PlotConfig.UpgradeBoardSize
	local postCFrame = origin + origin.UpVector * (postSize.Y / 2)
	local post = createPart("Post", postSize, PlotConfig.UpgradePostColor, postCFrame)
	post.Parent = model
	local boardCFrame = origin + origin.UpVector * (postSize.Y + boardSize.Y / 2)
	local board = createPart("Board", boardSize, PlotConfig.UpgradeBoardColor, boardCFrame)
	board.CanQuery = true
	board.Parent = model
	model.PrimaryPart = board
	return model, board
end

local function addOutline(target: GuiObject, thickness: number)
	local stroke = Instance.new("UIStroke")
	stroke.Color = OUTLINE_COLOR
	stroke.Thickness = thickness
	stroke.Parent = target
end

local function createLabel(name: string, top: number, height: number, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.fromScale(0.5, top)
	label.Size = UDim2.fromScale(CONTENT_WIDTH, height)
	label.BackgroundTransparency = 1
	label.Font = PlotConfig.LabelFont
	label.TextScaled = true
	label.TextColor3 = color
	addOutline(label, OUTLINE_THICKNESS)
	return label
end

local function createButton(name: string, color: Color3, positionX: number): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.AnchorPoint = Vector2.new(positionX, 0)
	button.Position = UDim2.fromScale(positionX, 0)
	button.Size = UDim2.fromScale((1 - BUTTON_GAP) / 2, 1)
	button.BackgroundColor3 = color
	button.AutoButtonColor = false
	button.Font = PlotConfig.LabelFont
	button.TextScaled = true
	button.TextColor3 = TEXT_COLOR
	button:SetAttribute(HOVER_ATTRIBUTE, true)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = CORNER_RADIUS
	corner.Parent = button
	local stroke = Instance.new("UIStroke")
	stroke.Color = OUTLINE_COLOR
	stroke.Thickness = BUTTON_OUTLINE_THICKNESS
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = button
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0.18, 0)
	padding.PaddingBottom = UDim.new(0.18, 0)
	padding.Parent = button
	return button
end

local function createButtonRow(): (Frame, TextButton, TextButton)
	local row = Instance.new("Frame")
	row.Name = "ButtonRow"
	row.AnchorPoint = Vector2.new(0.5, 0)
	row.Position = UDim2.fromScale(0.5, 0.52)
	row.Size = UDim2.fromScale(CONTENT_WIDTH, 0.38)
	row.BackgroundTransparency = 1
	local coinButton = createButton("CoinButton", PlotConfig.UpgradeCoinButtonColor, 0)
	coinButton.Parent = row
	local robuxButton = createButton("RobuxButton", PlotConfig.UpgradeRobuxButtonColor, 1)
	robuxButton.Parent = row
	return row, coinButton, robuxButton
end

local function createGui(): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Name = PlotConfig.UpgradeSignName
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = PlotConfig.UpgradePixelsPerStud
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.LightInfluence = 0
	return gui
end

function PlotUpgradeSign.Build(origin: CFrame): Sign
	local model, board = createModel(origin)
	local gui = createGui()
	local title = createLabel("Title", 0.05, 0.22, TEXT_COLOR)
	title.Text = PlotUpgradeMessages.Title
	title.Parent = gui
	local levelLabel = createLabel("Level", 0.3, 0.16, PlotConfig.UpgradeLevelColor)
	levelLabel.Parent = gui
	local maxLabel = createLabel("MaxLevel", 0.56, 0.28, PlotConfig.UpgradeLevelColor)
	maxLabel.Text = PlotUpgradeMessages.MaxLevelText
	maxLabel.Parent = gui
	local row, coinButton, robuxButton = createButtonRow()
	row.Parent = gui
	return {
		Model = model,
		Board = board,
		Gui = gui,
		LevelLabel = levelLabel,
		MaxLabel = maxLabel,
		ButtonRow = row,
		CoinButton = coinButton,
		RobuxButton = robuxButton,
	}
end

function PlotUpgradeSign.Mount(sign: Sign, worldParent: Instance)
	sign.Model.Parent = worldParent
	sign.Gui.Parent = sign.Board
	for _, button in { sign.CoinButton, sign.RobuxButton } do
		HoverEffect.Attach(button)
		UiSound.AttachButton(button)
	end
end

function PlotUpgradeSign.Render(sign: Sign, view: SignView)
	sign.LevelLabel.Text = if view.IsMax
		then string.format(PlotUpgradeMessages.CurrentLevelFormat, view.Level)
		else string.format(PlotUpgradeMessages.LevelFormat, view.Level, view.Level + 1)
	sign.MaxLabel.Visible = view.IsMax
	sign.ButtonRow.Visible = not view.IsMax
	sign.CoinButton.Text = view.CoinText
	sign.RobuxButton.Text = view.RobuxText
end

function PlotUpgradeSign.Destroy(sign: Sign)
	sign.Gui:Destroy()
	sign.Model:Destroy()
end

return PlotUpgradeSign
