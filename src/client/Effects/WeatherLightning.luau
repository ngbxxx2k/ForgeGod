--!strict

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local WeatherFxTypes = require(ReplicatedStorage.Shared.Types.WeatherFxTypes)
local WeatherBolt = require(script.Parent.WeatherBolt)
local WeatherSounds = require(script.Parent.WeatherSounds)

local FLASH_EFFECT_NAME = "WeatherLightningFlash"
local WHITE = Color3.new(1, 1, 1)

local WeatherLightning = {}

local random = Random.new()
local runToken = 0
local flashEffect: ColorCorrectionEffect? = nil

local function getFlashEffect(): ColorCorrectionEffect
	local existing = flashEffect
	if existing then
		return existing
	end
	local effect = Instance.new("ColorCorrectionEffect")
	effect.Name = FLASH_EFFECT_NAME
	effect.Archivable = false
	effect.Parent = Lighting
	flashEffect = effect
	return effect
end

local function flash(profile: WeatherFxTypes.LightningProfile)
	local effect = getFlashEffect()
	effect.Brightness = profile.FlashBrightness
	effect.TintColor = profile.FlashTint
	local easing = Enum.EasingStyle.Quad
	local info = TweenInfo.new(profile.FlashFadeTime, easing, Enum.EasingDirection.Out)
	TweenService:Create(effect, info, { Brightness = 0, TintColor = WHITE }):Play()
end

local function strike(profile: WeatherFxTypes.LightningProfile)
	flash(profile)
	if profile.Bolt then
		WeatherBolt.Strike(profile.Bolt)
	end
	if random:NextNumber() < profile.DoubleFlashChance then
		task.delay(profile.DoubleFlashGap, flash, profile)
	end
	if #profile.ThunderSoundIds == 0 then
		return
	end
	local thunderDelay = random:NextNumber(profile.ThunderDelay.Min, profile.ThunderDelay.Max)
	local soundIds, volume = profile.ThunderSoundIds, profile.ThunderVolume
	task.delay(thunderDelay, WeatherSounds.PlayOneShot, soundIds, volume)
end

local function nextInterval(profile: WeatherFxTypes.LightningProfile): number
	return random:NextNumber(profile.Interval.Min, profile.Interval.Max)
end

function WeatherLightning.Start(profile: WeatherFxTypes.LightningProfile)
	runToken += 1
	local token = runToken
	task.spawn(function()
		while token == runToken do
			task.wait(nextInterval(profile))
			if token ~= runToken then
				return
			end
			strike(profile)
		end
	end)
end

function WeatherLightning.Stop()
	runToken += 1
end

return WeatherLightning
