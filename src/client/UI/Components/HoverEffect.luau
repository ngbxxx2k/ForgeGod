--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local HOVER_ATTRIBUTE = "HasHoverEffect"
local HOVER_SCALE_NAME = "HoverScale"
local SCALE_PARENT_ATTRIBUTE = "HoverScaleParent"
local HOVER_SCALE_ATTRIBUTE = "HoverScale"
local PRESS_SCALE_ATTRIBUTE = "PressScale"
local ICON_NAME = "Icon"
local BUTTON_HOVER_SCALE = 1.1
local ICON_HOVER_SCALE = 1.2
local ICON_HOVER_ROTATION = -12
local BUTTON_PRESS_SCALE = 0.9
local TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PRESS_TWEEN_INFO = TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local RELEASE_TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

type ButtonState = {
	ButtonScale: UIScale,
	Icon: GuiObject?,
	IconScale: UIScale?,
	HoverScale: number,
	PressScale: number,
	IsHovered: boolean,
	IsPressed: boolean,
}

local HoverEffect = {}

local isInitialized = false
local attachedButtons: { [GuiButton]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function getOrCreateScale(parent: GuiObject): UIScale
	local existing = parent:FindFirstChild(HOVER_SCALE_NAME)
	if existing and existing:IsA("UIScale") then
		return existing
	end
	local scale = Instance.new("UIScale")
	scale.Name = HOVER_SCALE_NAME
	scale.Parent = parent
	return scale
end

local function getButtonScale(state: ButtonState): number
	if state.IsPressed then
		return state.PressScale
	end
	return if state.IsHovered then state.HoverScale else 1
end

local function playButtonScale(state: ButtonState, tweenInfo: TweenInfo)
	TweenService:Create(state.ButtonScale, tweenInfo, { Scale = getButtonScale(state) }):Play()
end

local function playHover(state: ButtonState, isHovered: boolean)
	state.IsHovered = isHovered
	if not isHovered then
		state.IsPressed = false
	end
	playButtonScale(state, TWEEN_INFO)
	local icon, iconScale = state.Icon, state.IconScale
	if not icon or not iconScale then
		return
	end
	TweenService:Create(iconScale, TWEEN_INFO, {
		Scale = if isHovered then ICON_HOVER_SCALE else 1,
	}):Play()
	TweenService:Create(icon, TWEEN_INFO, {
		Rotation = if isHovered then ICON_HOVER_ROTATION else 0,
	}):Play()
end

local function isPressInput(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function playPress(state: ButtonState, isPressed: boolean)
	if state.IsPressed == isPressed then
		return
	end
	state.IsPressed = isPressed
	playButtonScale(state, if isPressed then PRESS_TWEEN_INFO else RELEASE_TWEEN_INFO)
end

local function bindPress(button: GuiButton, state: ButtonState)
	button.InputBegan:Connect(function(input: InputObject)
		if isPressInput(input) then
			playPress(state, true)
		end
	end)
	button.InputEnded:Connect(function(input: InputObject)
		if isPressInput(input) then
			playPress(state, false)
		end
	end)
end

local function readNumber(button: GuiButton, attribute: string, default: number): number
	local value = button:GetAttribute(attribute)
	return if typeof(value) == "number" then value else default
end

local function getScaleTarget(button: GuiButton): GuiObject
	local parent = button.Parent
	if button:GetAttribute(SCALE_PARENT_ATTRIBUTE) == true and parent and parent:IsA("GuiObject") then
		return parent
	end
	return button
end

local function tryAttach(instance: Instance)
	if not instance:IsA("GuiButton") or instance:GetAttribute(HOVER_ATTRIBUTE) ~= true then
		return
	end
	HoverEffect.Attach(instance)
end

function HoverEffect.Attach(button: GuiButton)
	if attachedButtons[button] then
		return
	end
	attachedButtons[button] = true
	local iconInstance = button:FindFirstChild(ICON_NAME)
	local icon: GuiObject? = if iconInstance and iconInstance:IsA("GuiObject") then iconInstance else nil
	local state: ButtonState = {
		ButtonScale = getOrCreateScale(getScaleTarget(button)),
		Icon = icon,
		IconScale = if icon then getOrCreateScale(icon) else nil,
		HoverScale = readNumber(button, HOVER_SCALE_ATTRIBUTE, BUTTON_HOVER_SCALE),
		PressScale = readNumber(button, PRESS_SCALE_ATTRIBUTE, BUTTON_PRESS_SCALE),
		IsHovered = false,
		IsPressed = false,
	}
	button.MouseEnter:Connect(function()
		playHover(state, true)
	end)
	button.MouseLeave:Connect(function()
		playHover(state, false)
	end)
	bindPress(button, state)
end

function HoverEffect.Init()
	if isInitialized then
		return
	end
	isInitialized = true
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	for _, descendant in playerGui:GetDescendants() do
		tryAttach(descendant)
	end
	playerGui.DescendantAdded:Connect(tryAttach)
end

return HoverEffect
