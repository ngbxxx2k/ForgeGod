--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ForgeConfig = require(ReplicatedStorage.Shared.Config.ForgeConfig)
local ForgeResultFxConfig = require(ReplicatedStorage.Shared.Config.ForgeResultFxConfig)
local ForgeOutcomes = require(ReplicatedStorage.Shared.Constants.ForgeOutcomes)
local ForgeMessages = require(ReplicatedStorage.Shared.Constants.ForgeMessages)
local WeatherMessages = require(ReplicatedStorage.Shared.Constants.WeatherMessages)
local BackpackMessages = require(ReplicatedStorage.Shared.Constants.BackpackMessages)
local NumberFormat = require(ReplicatedStorage.Shared.Utils.NumberFormat)
local UiSound = require(script.Parent.Parent.Parent.Effects.UiSound)
local ForgeResultFx = require(script.Parent.Parent.Parent.Effects.ForgeResultFx)
local OpenAnimation = require(script.Parent.Parent.Components.OpenAnimation)
local HudSlide = require(script.Parent.Parent.Components.HudSlide)
local ScreenRegistry = require(script.Parent.Parent.Components.ScreenRegistry)
local StatAnimation = require(script.Parent.Parent.Components.StatAnimation)
local ForgeWheel = require(script.Parent.Parent.Components.ForgeWheel)
local WheelNeedle = require(script.Parent.Parent.Components.WheelNeedle)

local FORGE_GUI_NAME = "ForgeGui"
local ROW_NAME = "Rate"
local PIP_NAME = "Pip"
local PIP_LIT_COLOR = Color3.fromRGB(255, 214, 40)
local PIP_DIM_COLOR = Color3.fromRGB(95, 95, 95)
local PIP_POP_SCALE = 1.5
local LEVEL_UP_POP_SCALE = 1.45
local MESSAGE_COLOR = Color3.fromRGB(235, 225, 210)
local DETAIL_POP_SCALE = 1.12
local PIP_TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local ROW_TWEEN_INFO = TweenInfo.new(ForgeResultFxConfig.RowFadeTime, Enum.EasingStyle.Quad)
local FILL_TWEEN_INFO = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FULL_PERCENT = 100
local MIN_FILL_SCALE = 0.02
local FILL_LIGHTEN = 0.35
local FILL_ROTATION = 90
local MESSAGE_STYLE: StatAnimation.SwapStyle = {
	StartScale = 0.9,
	Duration = 0.2,
	EasingStyle = Enum.EasingStyle.Quad,
	Wobble = 0,
}

export type ForgeState = {
	WeaponName: string,
	Mutation: string?,
	Level: number,
	Value: number,
	ForgePoints: number,
	MaxForgePoints: number,
}

export type ResultView = {
	Text: string,
	Detail: string,
	Color: Color3,
	HighlightId: string?,
	ValueDetail: string?,
	SwapStyle: StatAnimation.SwapStyle,
}

type RateRow = {
	Frame: Frame,
	Stroke: UIStroke?,
	Percent: TextLabel?,
	Fill: Frame?,
	Color: Color3,
}

type Elements = {
	Panel: Frame,
	Body: Frame,
	WeaponName: TextLabel,
	MutationLabel: TextLabel,
	ValueLabel: TextLabel,
	ValueDetail: TextLabel,
	LevelLabel: TextLabel,
	PointsLabel: TextLabel,
	ResultLabel: TextLabel,
	ResultDetail: TextLabel,
}

local ForgeScreen = {}

local isInitialized = false
local elements: Elements? = nil
local closeHandler: (() -> ())? = nil
local surfaceGui: SurfaceGui? = nil
local exitButton: GuiButton? = nil
local rows: { [string]: RateRow } = {}
local pips: { Frame } = {}
local litPips = 0
local shownLevel: number? = nil

local function formatCoins(value: number): string
	return string.format(ForgeMessages.CoinsFormat, NumberFormat.Compact(value))
end

local function formatLevel(value: number): string
	return string.format(ForgeMessages.LevelFormat, value)
end

local function formatMutation(mutation: string?): string
	if mutation == nil then
		return BackpackMessages.NoMutationText
	end
	local mutationName = WeatherMessages.MutationNames[mutation] or mutation
	return string.format(BackpackMessages.MutationFormat, mutationName)
end

local function setPip(pip: Frame, isLit: boolean, isAnimated: boolean)
	local color = if isLit then PIP_LIT_COLOR else PIP_DIM_COLOR
	if not isAnimated then
		pip.BackgroundColor3 = color
		return
	end
	TweenService:Create(pip, PIP_TWEEN_INFO, { BackgroundColor3 = color }):Play()
	if isLit then
		StatAnimation.Pop(pip, PIP_POP_SCALE)
	end
end

local function renderPips(points: number, isAnimated: boolean)
	for index, pip in pips do
		local isLit = index <= points
		local wasLit = index <= litPips
		if isLit ~= wasLit or not isAnimated then
			setPip(pip, isLit, isAnimated)
		end
	end
	litPips = points
end

local function renderLevel(target: Elements, level: number, isAnimated: boolean)
	local previous = shownLevel
	shownLevel = level
	if not isAnimated or previous == nil then
		StatAnimation.SetNumber(target.LevelLabel, level, formatLevel)
		return
	end
	StatAnimation.CountTo(target.LevelLabel, level, formatLevel)
	if level > previous then
		StatAnimation.Pop(target.LevelLabel, LEVEL_UP_POP_SCALE)
	end
end

function ForgeScreen.Render(state: ForgeState, isAnimated: boolean)
	local target = elements
	if not target then
		warn("[ForgeScreen] Render called before Init")
		return
	end
	target.WeaponName.Text = state.WeaponName
	target.MutationLabel.Text = formatMutation(state.Mutation)
	local points = string.format(ForgeMessages.PointsFormat, state.ForgePoints, state.MaxForgePoints)
	if isAnimated and target.PointsLabel.Text ~= points then
		StatAnimation.Pop(target.PointsLabel)
	end
	target.PointsLabel.Text = points
	if isAnimated then
		StatAnimation.CountTo(target.ValueLabel, state.Value, formatCoins)
	else
		StatAnimation.SetNumber(target.ValueLabel, state.Value, formatCoins)
	end
	renderLevel(target, state.Level, isAnimated)
	renderPips(state.ForgePoints, isAnimated)
end

local function getFillScale(percent: number): number
	if percent <= 0 then
		return 0
	end
	return math.clamp(percent / FULL_PERCENT, MIN_FILL_SCALE, 1)
end

local function setFill(fill: Frame, percent: number, isAnimated: boolean)
	local size = UDim2.fromScale(getFillScale(percent), 1)
	fill.Visible = percent > 0
	if isAnimated then
		TweenService:Create(fill, FILL_TWEEN_INFO, { Size = size }):Play()
	else
		fill.Size = size
	end
end

function ForgeScreen.SetChances(chances: { [string]: number }, isAnimated: boolean)
	ForgeWheel.SetChances(chances, isAnimated)
	for id, row in rows do
		local percent = chances[id] or 0
		local percentLabel = row.Percent
		if percentLabel then
			percentLabel.Text = ForgeWheel.FormatPercent(percent)
		end
		local fill = row.Fill
		if fill then
			setFill(fill, percent, isAnimated)
		end
	end
end

function ForgeScreen.Highlight(outcomeId: string?)
	for id, row in rows do
		local isActive = id == outcomeId
		local transparency = if isActive then ForgeResultFxConfig.RowHighlightTransparency else 1
		TweenService:Create(row.Frame, ROW_TWEEN_INFO, {
			BackgroundTransparency = transparency,
			BackgroundColor3 = row.Color,
		}):Play()
		local stroke = row.Stroke
		if stroke then
			stroke.Color = row.Color
			TweenService:Create(stroke, ROW_TWEEN_INFO, { Transparency = if isActive then 0 else 1 }):Play()
		end
		if isActive then
			StatAnimation.Pop(row.Frame, 1.08)
		end
	end
end

function ForgeScreen.ShowResult(view: ResultView)
	local target = elements
	if not target then
		return
	end
	StatAnimation.SwapText(target.ResultLabel, view.Text, view.Color, view.SwapStyle)
	StatAnimation.SwapText(target.ResultDetail, view.Detail, MESSAGE_COLOR, MESSAGE_STYLE)
	ForgeScreen.Highlight(view.HighlightId)
	local valueDetail = view.ValueDetail
	if valueDetail then
		target.ValueDetail.Text = valueDetail
		StatAnimation.Pop(target.ValueDetail, DETAIL_POP_SCALE)
	end
end

function ForgeScreen.ShowMessage(text: string, detail: string?)
	local target = elements
	if not target then
		return
	end
	StatAnimation.SwapText(target.ResultLabel, text, MESSAGE_COLOR, MESSAGE_STYLE)
	StatAnimation.SwapText(target.ResultDetail, detail or "", MESSAGE_COLOR, MESSAGE_STYLE)
end

function ForgeScreen.ResetResult()
	local target = elements
	if not target then
		return
	end
	target.ResultLabel.Text = ForgeMessages.ReadyText
	target.ResultLabel.TextColor3 = MESSAGE_COLOR
	target.ResultLabel.TextTransparency = 0
	target.ResultDetail.Text = ForgeMessages.ReadyDetailText
	target.ResultDetail.TextTransparency = 0
	target.ValueDetail.Text = ""
	ForgeScreen.Highlight(nil)
end

function ForgeScreen.SetVisible(isVisible: boolean)
	local target = elements
	if not target then
		return
	end
	if isVisible then
		ScreenRegistry.CloseAllExcept(target.Panel)
	end
	target.Panel.Visible = isVisible
end

function ForgeScreen.SetCloseHandler(handler: () -> ())
	closeHandler = handler
end

function ForgeScreen.SetAdornee(part: BasePart?)
	local gui = surfaceGui
	if gui then
		gui.Adornee = part
	end
end

local function toCanvasPoint(gui: SurfaceGui, part: BasePart, screenPosition: Vector2): Vector2?
	local ray = Workspace.CurrentCamera:ScreenPointToRay(screenPosition.X, screenPosition.Y)
	local normal = part.CFrame.LookVector
	local facing = ray.Direction:Dot(normal)
	if math.abs(facing) < 1e-4 then
		return nil
	end
	local distance = (part.Position - ray.Origin):Dot(normal) / facing
	if distance <= 0 then
		return nil
	end
	local hit = part.CFrame:PointToObjectSpace(ray.Origin + ray.Direction * distance)
	local half = part.Size / 2
	local u = (half.X - hit.X) / part.Size.X
	local v = (half.Y - hit.Y) / part.Size.Y
	return Vector2.new(u * gui.AbsoluteSize.X, v * gui.AbsoluteSize.Y)
end

function ForgeScreen.IsOverExitButton(screenPosition: Vector2): boolean
	local gui, button = surfaceGui, exitButton
	local part = gui and gui.Adornee
	if gui == nil or button == nil or part == nil or not part:IsA("BasePart") then
		return false
	end
	local point = toCanvasPoint(gui, part, screenPosition)
	if point == nil then
		return false
	end
	local offset = point - button.AbsolutePosition
	local size = button.AbsoluteSize
	return offset.X >= 0 and offset.Y >= 0 and offset.X <= size.X and offset.Y <= size.Y
end

local function paintFill(row: Instance, color: Color3): Frame?
	local track = row:FindFirstChild("Track")
	local fill = track and track:FindFirstChild("Fill")
	if not fill or not fill:IsA("Frame") then
		return nil
	end
	fill.BackgroundColor3 = Color3.new(1, 1, 1)
	local gradient = fill:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), FILL_LIGHTEN), color)
	gradient.Rotation = FILL_ROTATION
	gradient.Parent = fill
	fill.Size = UDim2.fromScale(0, 1)
	return fill
end

local function buildRows(list: Instance, template: Frame)
	template.Visible = false
	for index, outcome in ForgeOutcomes do
		local row = template:Clone()
		row.Name = ROW_NAME .. outcome.Id
		row.LayoutOrder = index
		row.Visible = true
		local nameLabel = row:FindFirstChild("NameLabel")
		if nameLabel and nameLabel:IsA("TextLabel") then
			nameLabel.Text = outcome.Label
		end
		local percentLabel = row:FindFirstChild("PercentLabel")
		local percent = if percentLabel and percentLabel:IsA("TextLabel") then percentLabel else nil
		if percent then
			percent.Text = ""
		end
		local fill = paintFill(row, outcome.Color)
		row.Parent = list
		rows[outcome.Id] = {
			Frame = row,
			Stroke = row:FindFirstChildOfClass("UIStroke"),
			Percent = percent,
			Fill = fill,
			Color = outcome.Color,
		}
	end
end

local function buildPips(row: Instance, template: Frame)
	template.Visible = false
	for index = 1, ForgeConfig.MaxForgePoints do
		local pip = template:Clone()
		pip.Name = PIP_NAME
		pip.LayoutOrder = index
		pip.Visible = true
		pip.BackgroundColor3 = PIP_DIM_COLOR
		pip.Parent = row
		table.insert(pips, pip)
	end
end

local function findTyped(parent: Instance, name: string, className: string): any
	local child = parent:WaitForChild(name)
	assert(child:IsA(className), "[ForgeScreen] " .. name .. " must be a " .. className)
	return child
end

local function bindWheel(body: Frame): (TextLabel, TextLabel)
	local wheel = findTyped(body, "Wheel", "Frame") :: Frame
	local hub = wheel:WaitForChild("Hub")
	local glow = wheel:WaitForChild("Glow"):FindFirstChildOfClass("UIStroke")
	assert(glow, "[ForgeScreen] Wheel.Glow needs a UIStroke")
	ForgeWheel.Bind(wheel)
	WheelNeedle.Bind(findTyped(wheel, "NeedlePivot", "Frame"))
	ForgeResultFx.Bind({
		Wheel = wheel,
		Glow = glow,
		FxLayer = findTyped(wheel, "FxLayer", "Frame"),
		Body = body,
		Flash = findTyped(body, "Flash", "Frame"),
	})
	return findTyped(hub, "ResultLabel", "TextLabel"), findTyped(hub, "ResultDetail", "TextLabel")
end

local function bindExitButton(button: GuiButton)
	exitButton = button
	button.Activated:Connect(function()
		local handler = closeHandler
		if handler then
			handler()
		end
	end)
end

local function registerPanel(panel: Frame)
	UiSound.WatchOpen(panel)
	OpenAnimation.Watch(panel)
	HudSlide.TrackScreen(panel)
	ScreenRegistry.Register(panel, function()
		local handler = closeHandler
		if handler then
			handler()
		else
			panel.Visible = false
		end
	end)
end

function ForgeScreen.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = playerGui:WaitForChild(FORGE_GUI_NAME)
	if gui:IsA("SurfaceGui") then
		surfaceGui = gui
		gui.Adornee = nil
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	end
	local panel = findTyped(gui, "Panel", "Frame") :: Frame
	bindExitButton(findTyped(panel, "ExitButton", "GuiButton"))
	local body = findTyped(panel, "Body", "Frame") :: Frame
	local resultLabel, resultDetail = bindWheel(body)
	local rateList = body:WaitForChild("RateList")
	local pipRow = body:WaitForChild("PipRow")
	buildRows(rateList, findTyped(rateList, "RateTemplate", "Frame"))
	buildPips(pipRow, findTyped(pipRow, "PipTemplate", "Frame"))
	elements = {
		Panel = panel,
		Body = body,
		WeaponName = findTyped(body, "WeaponName", "TextLabel"),
		MutationLabel = findTyped(body, "MutationLabel", "TextLabel"),
		ValueLabel = findTyped(body, "ValueLabel", "TextLabel"),
		ValueDetail = findTyped(body, "ValueDetail", "TextLabel"),
		LevelLabel = findTyped(body, "LevelLabel", "TextLabel"),
		PointsLabel = findTyped(body, "PointsLabel", "TextLabel"),
		ResultLabel = resultLabel,
		ResultDetail = resultDetail,
	}
	panel.Visible = false
	registerPanel(panel)
	ForgeScreen.ResetResult()
end

return ForgeScreen
