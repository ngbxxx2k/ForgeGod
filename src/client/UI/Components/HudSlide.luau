--!strict

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local HUD_GUI_NAME = "HudGui"
local KEEP_VISIBLE_NAMES: { [string]: boolean } = {
	CoinsDisplay = true,
}
local SLIDE_DURATION = 0.3
local HIDE_TWEEN_INFO = TweenInfo.new(SLIDE_DURATION, Enum.EasingStyle.Back, Enum.EasingDirection.In)
local SHOW_TWEEN_INFO = TweenInfo.new(SLIDE_DURATION, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local OFFSCREEN_MARGIN = 20

type ElementState = {
	Position: UDim2,
	Visible: boolean,
	Interactable: boolean,
}

local HudSlide = {}

local isInitialized = false
local isHidden = false
local isRefreshQueued = false
local hudGui: ScreenGui? = nil
local openScreens: { [GuiObject]: boolean } = {}
local elementStates: { [GuiObject]: ElementState } = {}
local activeTweens: { [GuiObject]: Tween } = {}

local function getShownAbsolutePosition(element: GuiObject, original: UDim2): Vector2
	local current = element.Position
	local shiftX = current.X.Offset - original.X.Offset
	local shiftY = current.Y.Offset - original.Y.Offset
	return element.AbsolutePosition - Vector2.new(shiftX, shiftY)
end

local function getHiddenPosition(gui: ScreenGui, element: GuiObject, original: UDim2): UDim2
	local screen = gui.AbsoluteSize
	local topInset = if gui.IgnoreGuiInset then 0 else GuiService:GetGuiInset().Y
	local position = getShownAbsolutePosition(element, original)
	local size = element.AbsoluteSize
	local center = position + size / 2
	local toLeft = position.X + size.X + OFFSCREEN_MARGIN
	local toRight = screen.X - position.X + OFFSCREEN_MARGIN
	local toTop = position.Y + size.Y + topInset + OFFSCREEN_MARGIN
	local toBottom = screen.Y - position.Y + OFFSCREEN_MARGIN
	local edgeDistances = {
		{ Distance = center.X, Shift = Vector2.new(-toLeft, 0) },
		{ Distance = screen.X - center.X, Shift = Vector2.new(toRight, 0) },
		{ Distance = center.Y, Shift = Vector2.new(0, -toTop) },
		{ Distance = screen.Y - center.Y, Shift = Vector2.new(0, toBottom) },
	}
	local nearest = edgeDistances[1]
	for _, edge in edgeDistances do
		if edge.Distance < nearest.Distance then
			nearest = edge
		end
	end
	return original + UDim2.fromOffset(nearest.Shift.X, nearest.Shift.Y)
end

local function cancelTween(element: GuiObject)
	local previous = activeTweens[element]
	if previous then
		activeTweens[element] = nil
		previous:Cancel()
	end
end

local function playTween(element: GuiObject, tweenInfo: TweenInfo, target: UDim2, onCompleted: (() -> ())?)
	local tween = TweenService:Create(element, tweenInfo, { Position = target })
	activeTweens[element] = tween
	tween.Completed:Connect(function(playbackState: Enum.PlaybackState)
		if playbackState ~= Enum.PlaybackState.Completed or activeTweens[element] ~= tween then
			return
		end
		activeTweens[element] = nil
		if onCompleted then
			onCompleted()
		end
	end)
	tween:Play()
end

local function hideElement(gui: ScreenGui, element: GuiObject, state: ElementState, isAnimated: boolean)
	cancelTween(element)
	element.Interactable = false
	local target = getHiddenPosition(gui, element, state.Position)
	if not isAnimated then
		element.Position = target
		element.Visible = false
		return
	end
	playTween(element, HIDE_TWEEN_INFO, target, function()
		element.Visible = false
	end)
end

local function showElement(element: GuiObject, state: ElementState, isAnimated: boolean)
	cancelTween(element)
	element.Visible = state.Visible
	element.Interactable = state.Interactable
	if not isAnimated then
		element.Position = state.Position
		return
	end
	playTween(element, SHOW_TWEEN_INFO, state.Position)
end

local function getElementState(element: GuiObject): ElementState
	local state = elementStates[element]
	if state then
		return state
	end
	local captured: ElementState = {
		Position = element.Position,
		Visible = element.Visible,
		Interactable = element.Interactable,
	}
	elementStates[element] = captured
	return captured
end

local function applyState(isAnimated: boolean)
	local gui = hudGui
	if not gui then
		return
	end
	for _, child in gui:GetChildren() do
		if not child:IsA("GuiObject") or KEEP_VISIBLE_NAMES[child.Name] then
			continue
		end
		local state = getElementState(child)
		if isHidden then
			hideElement(gui, child, state, isAnimated)
		else
			showElement(child, state, isAnimated)
		end
	end
end

local function refresh()
	isRefreshQueued = false
	local shouldHide = next(openScreens) ~= nil
	if shouldHide == isHidden then
		return
	end
	isHidden = shouldHide
	applyState(true)
end

local function queueRefresh()
	if isRefreshQueued then
		return
	end
	isRefreshQueued = true
	task.defer(refresh)
end

local function bindHud(child: Instance)
	if child.Name ~= HUD_GUI_NAME or not child:IsA("ScreenGui") then
		return
	end
	for _, tween in activeTweens do
		tween:Cancel()
	end
	table.clear(activeTweens)
	table.clear(elementStates)
	hudGui = child
	applyState(false)
end

function HudSlide.TrackScreen(frame: GuiObject)
	local function update()
		openScreens[frame] = if frame.Visible then true else nil
		queueRefresh()
	end
	frame:GetPropertyChangedSignal("Visible"):Connect(update)
	frame.Destroying:Connect(function()
		openScreens[frame] = nil
		queueRefresh()
	end)
	update()
end

function HudSlide.Init()
	if isInitialized then
		return
	end
	isInitialized = true
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	for _, child in playerGui:GetChildren() do
		bindHud(child)
	end
	playerGui.ChildAdded:Connect(bindHud)
end

return HudSlide
