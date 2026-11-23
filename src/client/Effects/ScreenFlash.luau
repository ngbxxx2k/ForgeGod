--!strict

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ForgeAnimationConfig = require(ReplicatedStorage.Shared.Config.ForgeAnimationConfig)
local RevealCleanup = require(script.Parent.RevealCleanup)

local GUI_NAME = "ForgeRevealFlash"
local EFFECT_NAME = "ForgeRevealEffect"
local WHITE = Color3.new(1, 1, 1)

export type Flash = {
	Gui: ScreenGui,
	Frame: Frame,
	Correction: ColorCorrectionEffect,
	Blur: BlurEffect,
	Bloom: BloomEffect,
	Tweens: { [Instance]: Tween },
}

local ScreenFlash = {}

local function createGui(): (ScreenGui, Frame)
	local gui = Instance.new("ScreenGui")
	gui.Name = GUI_NAME
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = ForgeAnimationConfig.ScreenFlash.DisplayOrder
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BorderSizePixel = 0
	frame.BackgroundTransparency = 1
	frame.Parent = gui
	return gui, frame
end

local function createEffects(): (ColorCorrectionEffect, BlurEffect, BloomEffect)
	local correction = Instance.new("ColorCorrectionEffect")
	correction.Name = EFFECT_NAME
	local blur = Instance.new("BlurEffect")
	blur.Name = EFFECT_NAME
	blur.Size = 0
	local bloom = Instance.new("BloomEffect")
	bloom.Name = EFFECT_NAME
	bloom.Intensity = 0
	return correction, blur, bloom
end

local function playTween(flash: Flash, target: Instance, duration: number, goal: { [string]: any })
	local previous = flash.Tweens[target]
	if previous then
		previous:Cancel()
	end
	local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(target, info, goal)
	flash.Tweens[target] = tween
	tween:Play()
end

local function cancelTweens(flash: Flash)
	for _, tween in flash.Tweens do
		tween:Cancel()
	end
	table.clear(flash.Tweens)
end

function ScreenFlash.Create(cleanup: RevealCleanup.Cleanup): Flash
	local gui, frame = createGui()
	local correction, blur, bloom = createEffects()
	local flash: Flash = {
		Gui = gui,
		Frame = frame,
		Correction = correction,
		Blur = blur,
		Bloom = bloom,
		Tweens = {},
	}
	RevealCleanup.Add(cleanup, gui)
	RevealCleanup.Add(cleanup, correction)
	RevealCleanup.Add(cleanup, blur)
	RevealCleanup.Add(cleanup, bloom)
	RevealCleanup.Add(cleanup, function()
		cancelTweens(flash)
	end)
	correction.Parent = Lighting
	blur.Parent = Lighting
	bloom.Parent = Lighting
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return flash
end

function ScreenFlash.Dim(flash: Flash)
	local config = ForgeAnimationConfig.ScreenFlash
	playTween(flash, flash.Correction, config.DimTweenTime, {
		Brightness = config.DimBrightness,
		Saturation = config.DimSaturation,
	})
end

function ScreenFlash.Undim(flash: Flash, duration: number)
	playTween(flash, flash.Correction, duration, { Brightness = 0, Saturation = 0 })
end

function ScreenFlash.Flash(flash: Flash, color: Color3, isFinal: boolean)
	local config = ForgeAnimationConfig.ScreenFlash
	local fadeTime = if isFinal then config.FinalFadeTime else config.StrikeFadeTime
	local kick = if isFinal then config.FinalBrightnessKick else config.StrikeBrightnessKick
	flash.Frame.BackgroundColor3 = color
	flash.Frame.BackgroundTransparency = if isFinal then config.FinalTransparency else config.StrikeTransparency
	playTween(flash, flash.Frame, fadeTime, { BackgroundTransparency = 1 })
	flash.Correction.Brightness = config.DimBrightness + kick
	flash.Correction.TintColor = WHITE:Lerp(color, config.TintStrength)
	playTween(flash, flash.Correction, fadeTime, {
		Brightness = config.DimBrightness,
		Saturation = config.DimSaturation,
		TintColor = WHITE,
	})
	if not isFinal then
		return
	end
	flash.Blur.Size = config.FinalBlurSize
	flash.Bloom.Intensity = config.FinalBloomIntensity
	playTween(flash, flash.Blur, config.FinalEffectFadeTime, { Size = 0 })
	playTween(flash, flash.Bloom, config.FinalEffectFadeTime, { Intensity = 0 })
end

return ScreenFlash
