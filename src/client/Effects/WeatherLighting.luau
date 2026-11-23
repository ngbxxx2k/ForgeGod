--!strict

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local WeatherFxTypes = require(ReplicatedStorage.Shared.Types.WeatherFxTypes)

type Goal = { [string]: any }

type Baseline = {
	Lighting: Goal,
	Atmosphere: Goal?,
	ColorCorrection: Goal?,
	Bloom: Goal?,
	DepthOfField: Goal,
}

local BASE_COLOR_CORRECTION_NAME = "ColorCorrection"
local WEATHER_DEPTH_OF_FIELD_NAME = "WeatherDepthOfField"
local LIGHTING_KEYS = { "Brightness", "ClockTime", "Ambient", "OutdoorAmbient" }
local EXTRA_LIGHTING_KEYS = { "ExposureCompensation" }
local ATMOSPHERE_KEYS = { "Density", "Offset", "Color", "Decay", "Glare", "Haze" }
local COLOR_CORRECTION_KEYS = { "Brightness", "Contrast", "Saturation", "TintColor" }
local BLOOM_KEYS = { "Intensity", "Size", "Threshold" }
local NO_DEPTH_OF_FIELD: Goal = { FarIntensity = 0, NearIntensity = 0 }

local WeatherLighting = {}

local baseline: Baseline? = nil
local atmosphere: Atmosphere? = nil
local colorCorrection: ColorCorrectionEffect? = nil
local bloom: BloomEffect? = nil
local depthOfField: DepthOfFieldEffect? = nil
local activeTweens: { Tween } = {}

local function capture(target: Instance, keyGroups: { { string } }): Goal
	local goal: Goal = {}
	for _, keys in keyGroups do
		for _, key in keys do
			goal[key] = (target :: any)[key]
		end
	end
	return goal
end

local function findBaseEffects()
	atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	for _, child in Lighting:GetChildren() do
		if child:IsA("ColorCorrectionEffect") and child.Name == BASE_COLOR_CORRECTION_NAME then
			colorCorrection = child
		end
	end
end

local function createDepthOfField(): DepthOfFieldEffect
	local effect = Instance.new("DepthOfFieldEffect")
	effect.Name = WEATHER_DEPTH_OF_FIELD_NAME
	effect.Archivable = false
	effect.FarIntensity = 0
	effect.NearIntensity = 0
	effect.Enabled = false
	effect.Parent = Lighting
	return effect
end

local function getBaseline(): Baseline
	if baseline then
		return baseline
	end
	findBaseEffects()
	depthOfField = createDepthOfField()
	local captured: Baseline = {
		Lighting = capture(Lighting, { LIGHTING_KEYS, EXTRA_LIGHTING_KEYS }),
		Atmosphere = if atmosphere then capture(atmosphere, { ATMOSPHERE_KEYS }) else nil,
		ColorCorrection = if colorCorrection
			then capture(colorCorrection, { COLOR_CORRECTION_KEYS })
			else nil,
		Bloom = if bloom then capture(bloom, { BLOOM_KEYS }) else nil,
		DepthOfField = NO_DEPTH_OF_FIELD,
	}
	baseline = captured
	return captured
end

local function cancelTweens()
	for _, tween in activeTweens do
		tween:Cancel()
	end
	table.clear(activeTweens)
end

local function playTween(target: Instance?, goal: Goal?, duration: number): Tween?
	if target == nil or goal == nil then
		return nil
	end
	local info = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local tween = TweenService:Create(target, info, goal)
	table.insert(activeTweens, tween)
	tween:Play()
	return tween
end

local function applyDepthOfField(goal: Goal?, base: Goal, duration: number)
	local effect = depthOfField
	if effect == nil then
		return
	end
	if goal then
		effect.Enabled = true
		playTween(effect, goal, duration)
		return
	end
	local tween = playTween(effect, base, duration)
	if tween then
		tween.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed then
				effect.Enabled = false
			end
		end)
	end
end

function WeatherLighting.Apply(profile: WeatherFxTypes.WeatherFxProfile?, duration: number)
	local base = getBaseline()
	cancelTweens()
	local weather: any = profile or {}
	playTween(Lighting, weather.Lighting or base.Lighting, duration)
	playTween(atmosphere, weather.Atmosphere or base.Atmosphere, duration)
	playTween(colorCorrection, weather.ColorCorrection or base.ColorCorrection, duration)
	playTween(bloom, weather.Bloom or base.Bloom, duration)
	applyDepthOfField(weather.DepthOfField, base.DepthOfField, duration)
end

return WeatherLighting
