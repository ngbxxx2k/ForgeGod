--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeatherFxConfig = require(ReplicatedStorage.Shared.Config.WeatherFxConfig)
local WeatherFxTypes = require(ReplicatedStorage.Shared.Types.WeatherFxTypes)
local WorldAttributes = require(ReplicatedStorage.Shared.Constants.WorldAttributes)
local WeatherAurora = require(script.Parent.WeatherAurora)
local WeatherLighting = require(script.Parent.WeatherLighting)
local WeatherLightning = require(script.Parent.WeatherLightning)
local WeatherParticles = require(script.Parent.WeatherParticles)
local WeatherSky = require(script.Parent.WeatherSky)
local WeatherSounds = require(script.Parent.WeatherSounds)
local WeatherVignette = require(script.Parent.WeatherVignette)

local WeatherFx = {}

local isInitialized = false
local activeWeatherId: string? = nil

local function readWeatherId(): string?
	local weatherId = ReplicatedStorage:GetAttribute(WorldAttributes.WeatherId)
	if type(weatherId) ~= "string" or weatherId == "" then
		return nil
	end
	return weatherId
end

local function stopLayers(duration: number)
	WeatherParticles.Stop()
	WeatherLightning.Stop()
	WeatherSounds.StopAmbient()
	WeatherAurora.Stop(duration)
	WeatherVignette.Hide(duration)
end

local function startLayers(profile: WeatherFxTypes.WeatherFxProfile, duration: number)
	if profile.Particles then
		WeatherParticles.Start(profile.Particles)
	end
	if profile.Lightning then
		WeatherLightning.Start(profile.Lightning)
	end
	if profile.AmbientSounds then
		WeatherSounds.StartAmbient(profile.AmbientSounds)
	end
	if profile.Aurora then
		WeatherAurora.Start(profile.Aurora, duration)
	end
	if profile.Vignette then
		WeatherVignette.Show(profile.Vignette, duration)
	end
end

local function refresh()
	local weatherId = readWeatherId()
	if weatherId == activeWeatherId then
		return
	end
	activeWeatherId = weatherId
	local profile = if weatherId then WeatherFxConfig.Profiles[weatherId] else nil
	local duration = WeatherFxConfig.TransitionTime
	stopLayers(duration)
	WeatherLighting.Apply(profile, duration)
	WeatherSky.Apply(if profile then profile.Sky else nil, duration)
	if profile then
		startLayers(profile, duration)
	end
end

function WeatherFx.Init()
	if isInitialized then
		return
	end
	isInitialized = true
	ReplicatedStorage:GetAttributeChangedSignal(WorldAttributes.WeatherId):Connect(refresh)
	refresh()
end

return WeatherFx
