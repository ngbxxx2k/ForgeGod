--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local WeatherFxConfig = require(ReplicatedStorage.Shared.Config.WeatherFxConfig)
local WeatherFxTypes = require(ReplicatedStorage.Shared.Types.WeatherFxTypes)

local HIDDEN = 1

local WeatherVignette = {}

local gui: ScreenGui? = nil
local image: ImageLabel? = nil
local activeTween: Tween? = nil

local function getImage(): ImageLabel
	local existing = image
	if existing then
		return existing
	end
	local screen = Instance.new("ScreenGui")
	screen.Name = WeatherFxConfig.VignetteGuiName
	screen.IgnoreGuiInset = true
	screen.ResetOnSpawn = false
	screen.DisplayOrder = WeatherFxConfig.VignetteDisplayOrder
	local label = Instance.new("ImageLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = HIDDEN
	label.ImageTransparency = HIDDEN
	label.Parent = screen
	screen.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	gui = screen
	image = label
	return label
end

local function fadeTo(label: ImageLabel, transparency: number, duration: number)
	if activeTween then
		activeTween:Cancel()
	end
	local info = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local tween = TweenService:Create(label, info, { ImageTransparency = transparency })
	activeTween = tween
	tween:Play()
end

function WeatherVignette.Show(profile: WeatherFxTypes.VignetteProfile, duration: number)
	local label = getImage()
	label.Image = profile.Texture
	label.ImageColor3 = profile.Color
	fadeTo(label, profile.Transparency, duration)
end

function WeatherVignette.Hide(duration: number)
	local label = image
	if label == nil or gui == nil then
		return
	end
	fadeTo(label, HIDDEN, duration)
end

return WeatherVignette
