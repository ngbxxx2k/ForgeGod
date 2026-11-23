--!strict

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local WeatherFxTypes = require(ReplicatedStorage.Shared.Types.WeatherFxTypes)

type SkyState = {
	MoonTextureId: string,
	MoonAngularSize: number,
	StarCount: number,
}

local WeatherSky = {}

local baseline: SkyState? = nil
local activeTween: Tween? = nil

local function getSky(): Sky?
	return Lighting:FindFirstChildOfClass("Sky")
end

local function getBaseline(sky: Sky): SkyState
	if baseline then
		return baseline
	end
	local captured: SkyState = {
		MoonTextureId = sky.MoonTextureId,
		MoonAngularSize = sky.MoonAngularSize,
		StarCount = sky.StarCount,
	}
	baseline = captured
	return captured
end

local function resolve(profile: WeatherFxTypes.SkyProfile?, base: SkyState): SkyState
	if profile == nil then
		return base
	end
	return {
		MoonTextureId = profile.MoonTextureId or base.MoonTextureId,
		MoonAngularSize = profile.MoonAngularSize or base.MoonAngularSize,
		StarCount = profile.StarCount or base.StarCount,
	}
end

function WeatherSky.Apply(profile: WeatherFxTypes.SkyProfile?, duration: number)
	local sky = getSky()
	if sky == nil then
		return
	end
	local target = resolve(profile, getBaseline(sky))
	if activeTween then
		activeTween:Cancel()
	end
	sky.MoonTextureId = target.MoonTextureId
	sky.StarCount = target.StarCount
	local info = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local tween = TweenService:Create(sky, info, { MoonAngularSize = target.MoonAngularSize })
	activeTween = tween
	tween:Play()
end

return WeatherSky
