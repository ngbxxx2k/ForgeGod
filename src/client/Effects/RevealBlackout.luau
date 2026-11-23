--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ForgeAnimationConfig = require(ReplicatedStorage.Shared.Config.ForgeAnimationConfig)
local RevealCleanup = require(script.Parent.RevealCleanup)

local GUI_NAME = "ForgeRevealBlackout"
local CENTER = Vector2.new(0.5, 0.5)
local BLACK = Color3.new(0, 0, 0)
local CIRCLE_RADIUS = UDim.new(0.5, 0)

export type Blackout = {
	Gui: ScreenGui,
	Black: Frame,
	White: Frame,
	Tweens: { [Instance]: Tween },
}

local RevealBlackout = {}

local function createFrame(gui: ScreenGui, color: Color3, zIndex: number): Frame
	local frame = Instance.new("Frame")
	frame.AnchorPoint = CENTER
	frame.Position = UDim2.fromScale(CENTER.X, CENTER.Y)
	frame.Size = UDim2.fromScale(1, 1)
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = 1
	frame.ZIndex = zIndex
	frame.Parent = gui
	return frame
end

local function createCircle(gui: ScreenGui): Frame
	local circle = createFrame(gui, ForgeAnimationConfig.Blackout.WhiteColor, 2)
	circle.Size = UDim2.fromOffset(0, 0)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = CIRCLE_RADIUS
	corner.Parent = circle
	return circle
end

local function playTween(blackout: Blackout, target: Instance, info: TweenInfo, goal: { [string]: any })
	local previous = blackout.Tweens[target]
	if previous then
		previous:Cancel()
	end
	local tween = TweenService:Create(target, info, goal)
	blackout.Tweens[target] = tween
	tween:Play()
end

local function getCoverDiameter(gui: ScreenGui): number
	local camera = Workspace.CurrentCamera
	local size = if camera then camera.ViewportSize else gui.AbsoluteSize
	return size.Magnitude * ForgeAnimationConfig.Blackout.WhiteOverscan
end

function RevealBlackout.Create(cleanup: RevealCleanup.Cleanup): Blackout
	local gui = Instance.new("ScreenGui")
	gui.Name = GUI_NAME
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = ForgeAnimationConfig.Blackout.DisplayOrder
	local blackout: Blackout = {
		Gui = gui,
		Black = createFrame(gui, BLACK, 1),
		White = createCircle(gui),
		Tweens = {},
	}
	RevealCleanup.Add(cleanup, gui)
	RevealCleanup.Add(cleanup, function()
		for _, tween in blackout.Tweens do
			tween:Cancel()
		end
		table.clear(blackout.Tweens)
	end)
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return blackout
end

function RevealBlackout.Flicker(blackout: Blackout)
	local config = ForgeAnimationConfig.Blackout
	blackout.Black.BackgroundTransparency = config.FlickerTransparency
	local info = TweenInfo.new(config.FlickerFadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	playTween(blackout, blackout.Black, info, { BackgroundTransparency = 1 })
end

function RevealBlackout.FadeToBlack(blackout: Blackout)
	local info = TweenInfo.new(ForgeAnimationConfig.Blackout.FadeToBlackTime, Enum.EasingStyle.Quad)
	playTween(blackout, blackout.Black, info, { BackgroundTransparency = 0 })
end

function RevealBlackout.ExpandWhite(blackout: Blackout)
	local config = ForgeAnimationConfig.Blackout
	local white = blackout.White
	white.Size = UDim2.fromOffset(0, 0)
	white.BackgroundTransparency = 0
	local diameter = getCoverDiameter(blackout.Gui)
	local info = TweenInfo.new(config.WhiteExpandTime, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
	playTween(blackout, white, info, { Size = UDim2.fromOffset(diameter, diameter) })
end

function RevealBlackout.FadeOut(blackout: Blackout)
	local config = ForgeAnimationConfig.Blackout
	local previous = blackout.Tweens[blackout.Black]
	if previous then
		previous:Cancel()
	end
	blackout.Black.BackgroundTransparency = 1
	local info = TweenInfo.new(config.WhiteFadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	playTween(blackout, blackout.White, info, { BackgroundTransparency = 1 })
end

return RevealBlackout
