--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local StatusEffectConfig = require(ReplicatedStorage.Shared.Config.StatusEffectConfig)
local StatusEffectIcon = require(script.Parent.Parent.Components.StatusEffectIcon)
local StatusEffectTooltip = require(script.Parent.Parent.Components.StatusEffectTooltip)

local GUI_NAME = "StatusEffectsGui"
local CONTAINER_NAME = "Container"
local TEMPLATE_NAME = "IconTemplate"
local PRIORITY_STEP = 1_000_000

export type StatusEffectKind = "Weather" | "Buff"

export type StatusEffect = {
	Id: string,
	Kind: StatusEffectKind,
	ExpiresAt: number,
	Count: number?,
	Title: string,
	Description: string,
}

type IconEntry = {
	Root: GuiObject,
	Timer: TextLabel?,
	Scale: UIScale,
	ExpiresAt: number,
	Count: number?,
	Title: string,
	Description: string,
}

local StatusEffectsScreen = {}

local isInitialized = false
local container: Frame? = nil
local gridLayout: UIGridLayout? = nil
local iconTemplate: GuiObject? = nil
local icons: { [string]: IconEntry } = {}
local pendingEffects: { StatusEffect } = {}
local nextLayoutOrder = 0

local function getScreenScale(): number
	local camera = Workspace.CurrentCamera
	if not camera then
		return 1
	end
	local ratio = camera.ViewportSize.Y / StatusEffectConfig.ReferenceScreenHeight
	return math.clamp(ratio, StatusEffectConfig.MinScreenScale, 1)
end

local function applyScreenScale()
	local frame = container
	local layout = gridLayout
	if not frame or not layout then
		return
	end
	local scale = getScreenScale()
	local width = math.floor(StatusEffectConfig.IconSize * scale)
	local height = math.floor((StatusEffectConfig.IconSize + StatusEffectConfig.TimerHeight) * scale)
	local padding = math.floor(StatusEffectConfig.CellPadding * scale)
	local maxRow = StatusEffectConfig.MaxIconsPerRow
	layout.FillDirectionMaxCells = maxRow
	layout.CellSize = UDim2.fromOffset(width, height)
	layout.CellPadding = UDim2.fromOffset(padding, padding)
	frame.Size = UDim2.new(0, maxRow * width + (maxRow - 1) * padding, 1, 0)
	frame.Position = UDim2.new(
		1,
		-StatusEffectConfig.ScreenMarginRight,
		1,
		-StatusEffectConfig.ScreenMarginBottom
	)
end

local function tweenScale(scale: UIScale, target: number, duration: number, style: Enum.EasingStyle): Tween
	local info = TweenInfo.new(duration, style, Enum.EasingDirection.Out)
	local tween = TweenService:Create(scale, info, { Scale = target })
	tween:Play()
	return tween
end

local function getLayoutOrder(kind: StatusEffectKind): number
	nextLayoutOrder += 1
	local priority = StatusEffectConfig.KindPriority[kind] or 0
	return priority * PRIORITY_STEP + nextLayoutOrder
end

local function showTooltip(entry: IconEntry)
	StatusEffectTooltip.Show(entry.Root, entry.Title, entry.Description)
end

local function bindTooltip(entry: IconEntry)
	local root = entry.Root
	root.MouseEnter:Connect(function()
		showTooltip(entry)
	end)
	root.MouseLeave:Connect(function()
		StatusEffectTooltip.Hide(root)
	end)
	root.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		if StatusEffectTooltip.IsShowing(root) then
			StatusEffectTooltip.Hide(root)
		else
			showTooltip(entry)
		end
	end)
end

local function updateEntry(entry: IconEntry, effect: StatusEffect)
	entry.ExpiresAt = effect.ExpiresAt
	entry.Title = effect.Title
	entry.Description = effect.Description
	if entry.Count ~= effect.Count then
		entry.Count = effect.Count
		StatusEffectIcon.SetCount(entry.Root, effect.Count)
	end
	if StatusEffectTooltip.IsShowing(entry.Root) then
		showTooltip(entry)
	end
end

local function addIcon(parent: Frame, template: GuiObject, effect: StatusEffect)
	local root, timer = StatusEffectIcon.Create(template, effect.Id)
	root.LayoutOrder = getLayoutOrder(effect.Kind)
	local scale = Instance.new("UIScale")
	scale.Scale = 0
	scale.Parent = root
	StatusEffectIcon.SetCount(root, effect.Count)
	root.Parent = parent
	local entry: IconEntry = {
		Root = root,
		Timer = timer,
		Scale = scale,
		ExpiresAt = effect.ExpiresAt,
		Count = effect.Count,
		Title = effect.Title,
		Description = effect.Description,
	}
	icons[effect.Id] = entry
	bindTooltip(entry)
	tweenScale(scale, 1, StatusEffectConfig.PopInTime, Enum.EasingStyle.Back)
end

local function removeIcon(effectId: string)
	local entry = icons[effectId]
	if not entry then
		return
	end
	icons[effectId] = nil
	StatusEffectTooltip.Hide(entry.Root)
	local tween = tweenScale(entry.Scale, 0, StatusEffectConfig.PopOutTime, Enum.EasingStyle.Quad)
	tween.Completed:Once(function()
		entry.Root:Destroy()
	end)
end

local function refreshTimers()
	local now = Workspace:GetServerTimeNow()
	for effectId, entry in icons do
		local remaining = entry.ExpiresAt - now
		if remaining <= 0 then
			removeIcon(effectId)
		elseif entry.Timer and entry.Count == nil then
			entry.Timer.Text = StatusEffectIcon.FormatTime(remaining)
		end
	end
end

local function render()
	local parent = container
	local template = iconTemplate
	if not parent or not template then
		return
	end
	local wanted: { [string]: boolean } = {}
	for _, effect in pendingEffects do
		wanted[effect.Id] = true
		local entry = icons[effect.Id]
		if entry then
			updateEntry(entry, effect)
		else
			addIcon(parent, template, effect)
		end
	end
	for effectId in icons do
		if not wanted[effectId] then
			removeIcon(effectId)
		end
	end
	refreshTimers()
end

local function bindGui(child: Instance)
	if child.Name ~= GUI_NAME then
		return
	end
	local frame = child:FindFirstChild(CONTAINER_NAME)
	local template = child:FindFirstChild(TEMPLATE_NAME)
	local layout = if frame then frame:FindFirstChildWhichIsA("UIGridLayout") else nil
	local isValidFrame = frame ~= nil and frame:IsA("Frame")
	local isValidTemplate = template ~= nil and template:IsA("GuiObject")
	if not isValidFrame or not isValidTemplate or not layout then
		warn("[StatusEffectsScreen] Invalid", GUI_NAME)
		return
	end
	container = frame
	iconTemplate = template
	gridLayout = layout
	icons = {}
	if child:IsA("LayerCollector") then
		StatusEffectTooltip.Bind(child)
	end
	applyScreenScale()
	render()
end

function StatusEffectsScreen.SetEffects(effects: { StatusEffect })
	pendingEffects = effects
	render()
end

function StatusEffectsScreen.Init()
	if isInitialized then
		return
	end
	isInitialized = true
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	for _, child in playerGui:GetChildren() do
		bindGui(child)
	end
	playerGui.ChildAdded:Connect(bindGui)
	local camera = Workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyScreenScale)
	end
	task.spawn(function()
		while isInitialized do
			refreshTimers()
			task.wait(StatusEffectConfig.TimerRefreshInterval)
		end
	end)
end

return StatusEffectsScreen
