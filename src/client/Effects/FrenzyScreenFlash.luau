--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeFrenzyFxConfig = require(ReplicatedStorage.Shared.Config.ForgeFrenzyFxConfig)
local Rainbow = require(ReplicatedStorage.Shared.Utils.Rainbow)

type Overlay = {
	Gui: ScreenGui,
	Frame: Frame,
	Gradient: UIGradient,
}

local FULL_TURN = 360

local FrenzyScreenFlash = {}

local overlay: Overlay? = nil
local pulseAt = -math.huge

local function create(): Overlay
	local config = ForgeFrenzyFxConfig.Screen
	local gui = Instance.new("ScreenGui")
	gui.Name = config.GuiName
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = config.DisplayOrder
	local frame = Instance.new("Frame")
	frame.Name = "Flash"
	frame.Active = false
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BackgroundTransparency = 1
	local gradient = Instance.new("UIGradient")
	gradient.Parent = frame
	frame.Parent = gui
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return { Gui = gui, Frame = frame, Gradient = gradient }
end

local function getTransparency(time: number): number
	local config = ForgeFrenzyFxConfig.Screen
	local breath = math.sin(time * config.BreathFrequency * 2 * math.pi) * config.BreathAmplitude
	local base = config.BaseTransparency + breath
	local fade = math.clamp((time - pulseAt) / config.PulseFadeTime, 0, 1)
	local pulse = config.PulseTransparency + (base - config.PulseTransparency) * fade
	return math.min(base, pulse)
end

function FrenzyScreenFlash.Pulse()
	pulseAt = os.clock()
end

function FrenzyScreenFlash.Update(time: number, isLit: boolean)
	local current = overlay
	if current == nil then
		current = create()
		overlay = current
	end
	local config = ForgeFrenzyFxConfig
	current.Gradient.Color = Rainbow.Sequence(time * config.HueSpeed, config.GradientSteps, 1, 1)
	current.Gradient.Rotation = (time * config.Screen.SpinSpeed) % FULL_TURN
	current.Frame.BackgroundTransparency = if isLit then getTransparency(time) else 1
end

function FrenzyScreenFlash.Hide()
	local current = overlay
	overlay = nil
	pulseAt = -math.huge
	if current then
		current.Gui:Destroy()
	end
end

return FrenzyScreenFlash
