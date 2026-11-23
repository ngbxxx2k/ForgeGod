--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FurnaceMessages = require(ReplicatedStorage.Shared.Constants.FurnaceMessages)
local GuiPath = require(script.Parent.Parent.Components.GuiPath)
local OpenAnimation = require(script.Parent.Parent.Components.OpenAnimation)
local RarityGradient = require(script.Parent.Parent.Components.RarityGradient)

local FURNACE_GUI_NAME = "FurnaceGui"
local PANEL_NAME = "OddsPanel"
local ODDS_BUTTON_PATH = { "RightPanel", "SelectedPanel", "Header", "OddsButton" }
local CLOSE_BUTTON_PATH = { "Header", "CloseButton" }
local ROW_TEMPLATE_NAME = "RowTemplate"
local ROW_NAME = "OddsRow"
local FULL_PERCENT = 100
local MIN_FILL_SCALE = 0.02
local PERCENT_DECIMALS = 2

export type SmeltOdd = {
	Rarity: string,
	Percent: number,
}

local SmeltOddsScreen = {}

local isInitialized = false
local rowList: Frame? = nil
local rowTemplate: Frame? = nil
local hintLabel: GuiObject? = nil
local oddsPanel: GuiObject? = nil

local function formatPercent(percent: number): string
	local text = string.format("%." .. PERCENT_DECIMALS .. "f", percent)
	text = string.gsub(text, "0+$", "")
	text = string.gsub(text, "%.$", "")
	return string.format(FurnaceMessages.PercentFormat, text)
end

local function getFillScale(percent: number): number
	if percent <= 0 then
		return 0
	end
	return math.clamp(percent / FULL_PERCENT, MIN_FILL_SCALE, 1)
end

local function createRow(template: Frame, odd: SmeltOdd, order: number): Frame
	local row = template:Clone()
	row.Name = ROW_NAME
	row.LayoutOrder = order
	row.Visible = true
	GuiPath.SetText(row, { "NameLabel" }, odd.Rarity)
	GuiPath.SetText(row, { "PercentLabel" }, formatPercent(odd.Percent))
	local fill = GuiPath.Find(row, { "Track", "Fill" })
	if fill and fill:IsA("GuiObject") then
		fill.Size = UDim2.fromScale(getFillScale(odd.Percent), 1)
		fill.Visible = odd.Percent > 0
		RarityGradient.Apply(fill, odd.Rarity)
	end
	return row
end

local function clearRows()
	local list = rowList
	if list then
		GuiPath.ClearChildren(list, ROW_NAME)
	end
end

function SmeltOddsScreen.Render(odds: { SmeltOdd })
	local list, template = rowList, rowTemplate
	if not list or not template then
		warn("[SmeltOddsScreen] Render called before Init")
		return
	end
	clearRows()
	for index, odd in odds do
		createRow(template, odd, index).Parent = list
	end
	if hintLabel then
		hintLabel.Visible = false
	end
end

function SmeltOddsScreen.ShowHint()
	clearRows()
	if hintLabel then
		hintLabel.Visible = true
	end
end

local function setOpen(isOpen: boolean)
	local panel = oddsPanel
	if not panel then
		return
	end
	if isOpen then
		OpenAnimation.Open(panel)
	else
		OpenAnimation.Close(panel)
	end
end

local function bindButton(parent: Instance, path: { string }, onActivated: () -> ())
	local button = GuiPath.Find(parent, path)
	if not button or not button:IsA("GuiButton") then
		warn("[SmeltOddsScreen] Missing button", table.concat(path, "."))
		return
	end
	button.Activated:Connect(onActivated)
end

local function bindControls(main: Instance, panel: GuiObject)
	panel.Visible = false
	OpenAnimation.Watch(panel)
	oddsPanel = panel
	bindButton(main, ODDS_BUTTON_PATH, function()
		setOpen(not panel.Visible)
	end)
	bindButton(panel, CLOSE_BUTTON_PATH, function()
		setOpen(false)
	end)
	GuiPath.SetText(main, ODDS_BUTTON_PATH, FurnaceMessages.OddsButtonText)
end

function SmeltOddsScreen.Hide()
	local panel = oddsPanel
	if panel then
		panel.Visible = false
	end
end

function SmeltOddsScreen.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local main = playerGui:WaitForChild(FURNACE_GUI_NAME):WaitForChild("Main")
	local panel = main:WaitForChild(PANEL_NAME)
	if panel:IsA("GuiObject") then
		bindControls(main, panel)
	end
	local body = panel:WaitForChild("Body")
	local list = body:WaitForChild("RowList")
	local template = list:WaitForChild(ROW_TEMPLATE_NAME)
	local hint = body:WaitForChild("HintLabel")
	if not list:IsA("Frame") or not template:IsA("Frame") or not hint:IsA("GuiObject") then
		warn("[SmeltOddsScreen] OddsPanel has wrong structure")
		return
	end
	template.Visible = false
	rowList, rowTemplate, hintLabel = list, template, hint
	GuiPath.SetText(panel, { "Header", "Title" }, FurnaceMessages.OddsTitle)
	GuiPath.SetText(body, { "HintLabel" }, FurnaceMessages.OddsHint)
	SmeltOddsScreen.ShowHint()
end

return SmeltOddsScreen
