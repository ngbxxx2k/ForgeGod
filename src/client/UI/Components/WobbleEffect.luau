--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local WOBBLE_ATTRIBUTE = "WobbleLoop"
local WOBBLE_ANGLE_ATTRIBUTE = "WobbleAngle"
local WOBBLE_DURATION_ATTRIBUTE = "WobbleDuration"
local DEFAULT_ANGLE = 12
local DEFAULT_DURATION = 0.6
local REPEAT_FOREVER = -1

local WobbleEffect = {}

local isInitialized = false
local activeTweens: { [GuiObject]: Tween } = {}

local function readNumber(target: Instance, attribute: string, default: number): number
	local value = target:GetAttribute(attribute)
	return if typeof(value) == "number" then value else default
end

local function tryAttach(instance: Instance)
	if not instance:IsA("GuiObject") or instance:GetAttribute(WOBBLE_ATTRIBUTE) ~= true then
		return
	end
	WobbleEffect.Attach(instance)
end

function WobbleEffect.Attach(target: GuiObject)
	if activeTweens[target] then
		return
	end
	local angle = readNumber(target, WOBBLE_ANGLE_ATTRIBUTE, DEFAULT_ANGLE)
	local duration = readNumber(target, WOBBLE_DURATION_ATTRIBUTE, DEFAULT_DURATION)
	local tweenInfo = TweenInfo.new(
		duration,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut,
		REPEAT_FOREVER,
		true
	)
	target.Rotation = -angle
	local tween = TweenService:Create(target, tweenInfo, { Rotation = angle })
	activeTweens[target] = tween
	target.Destroying:Once(function()
		tween:Cancel()
		activeTweens[target] = nil
	end)
	tween:Play()
end

function WobbleEffect.Init()
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

return WobbleEffect
