--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeOutcomes = require(ReplicatedStorage.Shared.Constants.ForgeOutcomes)
local ForgeMessages = require(ReplicatedStorage.Shared.Constants.ForgeMessages)
local UiSound = require(script.Parent.Parent.Parent.Effects.UiSound)
local OpenAnimation = require(script.Parent.Parent.Components.OpenAnimation)
local HudSlide = require(script.Parent.Parent.Components.HudSlide)
local ScreenRegistry = require(script.Parent.Parent.Components.ScreenRegistry)

local FORGE_GUI_NAME = "ForgeGui"
local OUTCOME_TEMPLATE_NAME = "OutcomeTemplate"
local SEGMENT_TEMPLATE_NAME = "SegmentTemplate"
local PIP_TEMPLATE_NAME = "PipTemplate"
local OUTCOME_NAME = "Outcome"
local SEGMENT_NAME = "Segment"
local PIP_NAME = "Pip"
local PIP_LIT_COLOR = Color3.fromRGB(255, 215, 80)
local PIP_DIM_COLOR = Color3.fromRGB(60, 64, 88)
local THOUSANDS_PATTERN = "^(-?%d+)(%d%d%d)"
local THOUSANDS_REPLACE = "%1,%2"
local FRENZY_OUTCOME_ID = "Frenzy"
local FRENZY_COLOR = Color3.fromRGB(255, 200, 60)
local MESSAGE_COLOR = Color3.fromRGB(235, 235, 235)

export type ForgeResult = {
	OutcomeId: string,
	PointDelta: number,
	ValueDelta: number,
	Multiplier: number,
	FrenzyTimeLeft: number?,
	IsShapeChanged: boolean?,
}

export type ForgeState = {
	WeaponName: string,
	Level: number,
	Value: number,
	ForgePoints: number,
	MaxForgePoints: number,
	Chances: { [string]: number },
	LastResult: ForgeResult?,
}

local ForgeScreen = {}

local isInitialized = false
local panel: Frame? = nil
local closeHandler: (() -> ())? = nil
local outcomeRow: Frame? = nil
local chanceBar: Frame? = nil
local pipRow: Frame? = nil
local outcomeTemplate: Frame? = nil
local segmentTemplate: Frame? = nil
local pipTemplate: Frame? = nil

local function formatNumber(value: number): string
	local text = tostring(math.floor(value))
	local count = 1
	while count > 0 do
		text, count = string.gsub(text, THOUSANDS_PATTERN, THOUSANDS_REPLACE)
	end
	return text
end

local function setText(parent: Instance, childName: string, text: string, color: Color3?)
	local label = parent:FindFirstChild(childName)
	if not label or not label:IsA("TextLabel") then
		return
	end
	label.Text = text
	if color then
		label.TextColor3 = color
	end
end

local function clearChildren(parent: Instance, childName: string)
	for _, child in parent:GetChildren() do
		if child.Name == childName then
			child:Destroy()
		end
	end
end

local function findOutcome(outcomeId: string): ForgeOutcomes.ForgeOutcome?
	if outcomeId == FRENZY_OUTCOME_ID then
		return {
			Id = FRENZY_OUTCOME_ID,
			DisplayName = ForgeMessages.FrenzyDisplayName,
			Color = FRENZY_COLOR,
		}
	end
	for _, outcome in ForgeOutcomes do
		if outcome.Id == outcomeId then
			return outcome
		end
	end
	return nil
end

local function getTotalChance(chances: { [string]: number }): number
	local total = 0
	for _, outcome in ForgeOutcomes do
		total += math.max(chances[outcome.Id] or 0, 0)
	end
	return total
end

local function renderOutcomes(chances: { [string]: number })
	local row, template = outcomeRow, outcomeTemplate
	if not row or not template then
		return
	end
	clearChildren(row, OUTCOME_NAME)
	for index, outcome in ForgeOutcomes do
		local column = template:Clone()
		column.Name = OUTCOME_NAME
		column.LayoutOrder = index
		column.Visible = true
		local line = column:FindFirstChild("Line")
		if line and line:IsA("Frame") then
			line.BackgroundColor3 = outcome.Color
		end
		local percentText = string.format(ForgeMessages.PercentFormat, chances[outcome.Id] or 0)
		setText(column, "NameLabel", outcome.DisplayName, outcome.Color)
		setText(column, "PercentLabel", percentText, outcome.Color)
		column.Parent = row
	end
end

local function renderChanceBar(chances: { [string]: number })
	local bar, template = chanceBar, segmentTemplate
	if not bar or not template then
		return
	end
	clearChildren(bar, SEGMENT_NAME)
	local total = getTotalChance(chances)
	if total <= 0 then
		return
	end
	for index, outcome in ForgeOutcomes do
		local segment = template:Clone()
		segment.Name = SEGMENT_NAME
		segment.LayoutOrder = index
		segment.Visible = true
		segment.BackgroundColor3 = outcome.Color
		segment.Size = UDim2.fromScale(math.max(chances[outcome.Id] or 0, 0) / total, 1)
		segment.Parent = bar
	end
end

local function renderPips(points: number, maxPoints: number)
	local row, template = pipRow, pipTemplate
	if not row or not template then
		return
	end
	clearChildren(row, PIP_NAME)
	for index = 1, maxPoints do
		local pip = template:Clone()
		pip.Name = PIP_NAME
		pip.LayoutOrder = index
		pip.Visible = true
		pip.BackgroundColor3 = if index <= points then PIP_LIT_COLOR else PIP_DIM_COLOR
		pip.Parent = row
	end
end

local function formatResultDetail(result: ForgeResult): string
	local isLoss = result.ValueDelta < 0
	local sign = if isLoss then ForgeMessages.NegativeSign else ForgeMessages.PositiveSign
	local amount = formatNumber(math.abs(result.ValueDelta))
	if result.IsShapeChanged then
		return ForgeMessages.ShapeChangedText
	end
	if result.OutcomeId == FRENZY_OUTCOME_ID then
		local timeLeft = result.FrenzyTimeLeft or 0
		return string.format(ForgeMessages.FrenzyDetailFormat, sign, amount, timeLeft)
	end
	return string.format(ForgeMessages.ResultDetailFormat, sign, amount, tostring(result.Multiplier))
end

local function renderResult(target: Frame, result: ForgeResult?)
	local outcome = result and findOutcome(result.OutcomeId)
	local resultLabel = target:FindFirstChild("ResultLabel")
	local detailLabel = target:FindFirstChild("ResultDetail")
	if resultLabel and resultLabel:IsA("TextLabel") then
		resultLabel.Visible = outcome ~= nil
	end
	if detailLabel and detailLabel:IsA("TextLabel") then
		detailLabel.Visible = outcome ~= nil
	end
	if not result or not outcome then
		return
	end
	local delta = string.format(ForgeMessages.PointDeltaFormat, result.PointDelta)
	local resultText = string.format(ForgeMessages.ResultFormat, outcome.DisplayName, delta)
	setText(target, "ResultLabel", resultText, outcome.Color)
	setText(target, "ResultDetail", formatResultDetail(result))
end

function ForgeScreen.Render(state: ForgeState)
	local target = panel
	if not target then
		warn("[ForgeScreen] Render called before Init")
		return
	end
	setText(target, "WeaponName", state.WeaponName)
	setText(target, "LevelLabel", string.format(ForgeMessages.LevelFormat, state.Level))
	setText(target, "ValueLabel", string.format(ForgeMessages.MoneyFormat, formatNumber(state.Value)))
	local pointsText = string.format(ForgeMessages.PointsFormat, state.ForgePoints, state.MaxForgePoints)
	setText(target, "PointsLabel", pointsText)
	renderResult(target, state.LastResult)
	renderPips(state.ForgePoints, state.MaxForgePoints)
	renderOutcomes(state.Chances)
	renderChanceBar(state.Chances)
end

function ForgeScreen.ShowMessage(text: string)
	local target = panel
	if not target then
		return
	end
	local resultLabel = target:FindFirstChild("ResultLabel")
	local detailLabel = target:FindFirstChild("ResultDetail")
	if resultLabel and resultLabel:IsA("TextLabel") then
		resultLabel.Visible = true
	end
	if detailLabel and detailLabel:IsA("TextLabel") then
		detailLabel.Visible = false
	end
	setText(target, "ResultLabel", text, MESSAGE_COLOR)
end

function ForgeScreen.SetVisible(isVisible: boolean)
	local frame = panel
	if not frame then
		return
	end
	if isVisible then
		ScreenRegistry.CloseAllExcept(frame)
	end
	frame.Visible = isVisible
end

function ForgeScreen.SetCloseHandler(handler: () -> ())
	closeHandler = handler
end

function ForgeScreen.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local root = playerGui:WaitForChild(FORGE_GUI_NAME):WaitForChild("Panel")
	local outcomes = root:WaitForChild("OutcomeRow")
	local bar = root:WaitForChild("ChanceBar")
	local pips = root:WaitForChild("PipRow")
	local outcome = outcomes:WaitForChild(OUTCOME_TEMPLATE_NAME)
	local segment = bar:WaitForChild(SEGMENT_TEMPLATE_NAME)
	local pip = pips:WaitForChild(PIP_TEMPLATE_NAME)
	if not root:IsA("Frame") or not outcomes:IsA("Frame") then
		warn("[ForgeScreen] ForgeGui has wrong structure")
		return
	end
	if not bar:IsA("Frame") or not pips:IsA("Frame") then
		warn("[ForgeScreen] ForgeGui rows have wrong structure")
		return
	end
	if not outcome:IsA("Frame") or not segment:IsA("Frame") or not pip:IsA("Frame") then
		warn("[ForgeScreen] ForgeGui templates have wrong structure")
		return
	end
	outcome.Visible, segment.Visible, pip.Visible = false, false, false
	root.Visible = false
	panel, outcomeRow, chanceBar, pipRow = root, outcomes, bar, pips
	UiSound.WatchOpen(root)
	OpenAnimation.Watch(root)
	HudSlide.TrackScreen(root)
	ScreenRegistry.Register(root, function()
		local handler = closeHandler
		if handler then
			handler()
		else
			root.Visible = false
		end
	end)
	outcomeTemplate, segmentTemplate, pipTemplate = outcome, segment, pip
end

return ForgeScreen
