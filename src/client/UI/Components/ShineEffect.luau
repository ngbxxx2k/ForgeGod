--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local SHINE_ATTRIBUTE = "HasShineEffect"
local SHINE_NAME = "Shine"
local ICON_NAME = "Icon"
local STREAK_NAME = "Streak"
local STREAK_START_OFFSET = Vector2.new(-1, 0)
local STREAK_END_OFFSET = Vector2.new(1, 0)
local SHINE_ROTATION = 45
local SHINE_START_OFFSET = Vector2.new(-1, -1)
local SHINE_END_OFFSET = Vector2.new(1, 1)
local SHINE_INTERVAL = 2.5
local SHINE_TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local SHINE_TRANSPARENCY = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.4, 1),
	NumberSequenceKeypoint.new(0.5, 0.35),
	NumberSequenceKeypoint.new(1, 1),
	NumberSequenceKeypoint.new(1, 1),
})

local ShineEffect = {}

local isInitialized = false
local attachedButtons: { [GuiButton]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function getShineZIndex(button: GuiButton): number
	local icon = button:FindFirstChild(ICON_NAME)
	if icon and icon:IsA("GuiObject") then
		return icon.ZIndex + 1
	end
	return button.ZIndex + 1
end

local function createShine(button: GuiButton): UIGradient
	local shine = Instance.new("Frame")
	shine.Name = SHINE_NAME
	shine.Size = UDim2.fromScale(1, 1)
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BorderSizePixel = 0
	shine.ZIndex = getShineZIndex(button)
	local buttonCorner = button:FindFirstChildOfClass("UICorner")
	if buttonCorner then
		buttonCorner:Clone().Parent = shine
	end
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = SHINE_ROTATION
	gradient.Transparency = SHINE_TRANSPARENCY
	gradient.Offset = SHINE_START_OFFSET
	gradient.Parent = shine
	shine.Parent = button
	return gradient
end

local function findStreakGradient(button: GuiButton): UIGradient?
	local streak = button:FindFirstChild(STREAK_NAME)
	if not streak then
		return nil
	end
	return streak:FindFirstChildOfClass("UIGradient")
end

local function runShineLoop(
	button: GuiButton,
	gradient: UIGradient,
	startOffset: Vector2,
	endOffset: Vector2
)
	while button.Parent and gradient.Parent do
		gradient.Offset = startOffset
		TweenService:Create(gradient, SHINE_TWEEN_INFO, { Offset = endOffset }):Play()
		task.wait(SHINE_INTERVAL)
	end
end

local function tryAttach(instance: Instance)
	if not instance:IsA("GuiButton") or instance:GetAttribute(SHINE_ATTRIBUTE) ~= true then
		return
	end
	ShineEffect.Attach(instance)
end

function ShineEffect.Attach(button: GuiButton)
	if attachedButtons[button] then
		return
	end
	attachedButtons[button] = true
	local streakGradient = findStreakGradient(button)
	if streakGradient then
		task.spawn(runShineLoop, button, streakGradient, STREAK_START_OFFSET, STREAK_END_OFFSET)
		return
	end
	local gradient = createShine(button)
	task.spawn(runShineLoop, button, gradient, SHINE_START_OFFSET, SHINE_END_OFFSET)
end

function ShineEffect.Init()
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

return ShineEffect
