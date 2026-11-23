--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ForgeAnimationConfig = require(ReplicatedStorage.Shared.Config.ForgeAnimationConfig)
local RevealCleanup = require(script.Parent.RevealCleanup)

local GUI_NAME = "ForgeRevealBurst"
local CENTER = Vector2.new(0.5, 0.5)
local FULL_TURN_DEGREES = 360
local WHITE = Color3.new(1, 1, 1)
local RAY_END_THICKNESS = 0.3
local STAR_TRAVEL = NumberRange.new(0.5, 1)
local STAR_SCALE = NumberRange.new(0.6, 1.4)

local ScreenBurst = {}

local rng = Random.new()

local function centerOffset(direction: Vector2, distance: number): UDim2
	return UDim2.new(CENTER.X, direction.X * distance, CENTER.Y, direction.Y * distance)
end

local function playTween(target: Instance, duration: number, goal: { [string]: any }, cleanup: RevealCleanup.Cleanup)
	local info = TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local tween = TweenService:Create(target, info, goal)
	RevealCleanup.Add(cleanup, tween)
	tween:Play()
end

local function spawnRay(gui: ScreenGui, angle: number, length: number, color: Color3, cleanup: RevealCleanup.Cleanup)
	local config = ForgeAnimationConfig.ScreenBurst
	local direction = Vector2.new(math.cos(math.rad(angle)), math.sin(math.rad(angle)))
	local ray = Instance.new("Frame")
	ray.AnchorPoint = CENTER
	ray.Position = centerOffset(direction, 0)
	ray.Size = UDim2.fromOffset(0, config.RayThickness)
	ray.Rotation = angle
	ray.BorderSizePixel = 0
	ray.BackgroundColor3 = WHITE:Lerp(color, rng:NextNumber())
	ray.Parent = gui
	playTween(ray, config.Time, {
		Position = centerOffset(direction, length / 2),
		Size = UDim2.fromOffset(length, config.RayThickness * RAY_END_THICKNESS),
		BackgroundTransparency = 1,
	}, cleanup)
end

local function spawnStar(gui: ScreenGui, travel: number, color: Color3, cleanup: RevealCleanup.Cleanup)
	local config = ForgeAnimationConfig.ScreenBurst
	local angle = rng:NextNumber(0, math.pi * 2)
	local direction = Vector2.new(math.cos(angle), math.sin(angle))
	local size = config.StarSize * rng:NextNumber(STAR_SCALE.Min, STAR_SCALE.Max)
	local star = Instance.new("ImageLabel")
	star.AnchorPoint = CENTER
	star.Position = centerOffset(direction, 0)
	star.Size = UDim2.fromOffset(size, size)
	star.BackgroundTransparency = 1
	star.Image = config.StarImage
	star.ImageColor3 = WHITE:Lerp(color, rng:NextNumber())
	star.Parent = gui
	local distance = travel * rng:NextNumber(STAR_TRAVEL.Min, STAR_TRAVEL.Max)
	playTween(star, config.Time, {
		Position = centerOffset(direction, distance),
		Rotation = rng:NextNumber(-FULL_TURN_DEGREES, FULL_TURN_DEGREES),
		ImageTransparency = 1,
	}, cleanup)
end

function ScreenBurst.Play(color: Color3, cleanup: RevealCleanup.Cleanup)
	local config = ForgeAnimationConfig.ScreenBurst
	local gui = Instance.new("ScreenGui")
	gui.Name = GUI_NAME
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = config.DisplayOrder
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	RevealCleanup.Add(cleanup, gui)
	local camera = Workspace.CurrentCamera
	local screen = if camera then camera.ViewportSize else gui.AbsoluteSize
	local shortSide = math.min(screen.X, screen.Y)
	local rayLength = shortSide * config.RayLengthScale
	local step = FULL_TURN_DEGREES / math.max(config.RayCount, 1)
	for index = 1, config.RayCount do
		spawnRay(gui, index * step + rng:NextNumber(0, step / 2), rayLength, color, cleanup)
	end
	for _ = 1, config.StarCount do
		spawnStar(gui, shortSide * config.StarTravelScale, color, cleanup)
	end
	task.delay(config.Time, function()
		gui:Destroy()
	end)
end

return ScreenBurst
