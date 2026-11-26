--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EquipMessages = require(ReplicatedStorage.Shared.Constants.EquipMessages)
local NumberFormat = require(ReplicatedStorage.Shared.Utils.NumberFormat)
local PlotConfig = require(ReplicatedStorage.Shared.Config.PlotConfig)
local RarityColors = require(ReplicatedStorage.Shared.Constants.RarityColors)
local WeaponIncome = require(ReplicatedStorage.Shared.Utils.WeaponIncome)
local WeaponDisplayName = require(ReplicatedStorage.Shared.Utils.WeaponDisplayName)

local BROKEN_STATE = "Broken"

local PedestalLabel = {}

local function createRow(name: string, text: string, top: number, height: number, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromScale(0, top)
	label.Size = UDim2.fromScale(1, height)
	label.Font = PlotConfig.LabelFont
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Color = PlotConfig.LabelStrokeColor
	stroke.Thickness = PlotConfig.LabelStrokeThickness
	stroke.Parent = label
	return label
end

local function addRarityGradient(label: TextLabel, rarity: string)
	local rarityColor = RarityColors.Get(rarity)
	local gradient = Instance.new("UIGradient")
	gradient.Color = rarityColor.Gradient
	gradient.Rotation = rarityColor.Rotation
	gradient.Parent = label
end

local function getIncomeText(weapon: any): string
	local income = WeaponIncome.PerSecond(weapon.Value, weapon.Mutation, weapon.State == BROKEN_STATE)
	return string.format(EquipMessages.IncomeFormat, NumberFormat.Abbreviate(income))
end

function PedestalLabel.Build(weapon: any, anchor: Attachment, weaponHeight: number): BillboardGui
	local heights = PlotConfig.LabelRowHeights
	local gui = Instance.new("BillboardGui")
	gui.Name = PlotConfig.LabelName
	gui.Adornee = anchor
	gui.Size = UDim2.fromScale(PlotConfig.LabelSize.X, PlotConfig.LabelSize.Y)
	gui.StudsOffsetWorldSpace = Vector3.yAxis * (weaponHeight + PlotConfig.LabelGap + PlotConfig.LabelSize.Y / 2)
	gui.MaxDistance = PlotConfig.LabelMaxDistance
	gui.LightInfluence = 0

	local rarityRow = createRow("RarityLabel", weapon.Rarity, 0, heights.Rarity, PlotConfig.LabelTextColor)
	addRarityGradient(rarityRow, weapon.Rarity)
	rarityRow.Parent = gui
	local nameText = WeaponDisplayName.Get(weapon.Rarity, weapon.WeaponType, weapon.ShapeStage)
	createRow("NameLabel", nameText, heights.Rarity, heights.Name, PlotConfig.LabelTextColor).Parent = gui
	local incomeTop = heights.Rarity + heights.Name
	createRow("IncomeLabel", getIncomeText(weapon), incomeTop, heights.Income, PlotConfig.LabelIncomeColor).Parent =
		gui
	return gui
end

return PedestalLabel
