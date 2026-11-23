--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local WeatherFxConfig = require(ReplicatedStorage.Shared.Config.WeatherFxConfig)
local WeatherFxTypes = require(ReplicatedStorage.Shared.Types.WeatherFxTypes)

local SILENT = 0

local WeatherSounds = {}

local random = Random.new()
local soundGroup: SoundGroup? = nil
local ambients: { Sound } = {}

local function getGroup(): SoundGroup
	local existing = soundGroup
	if existing then
		return existing
	end
	local group = Instance.new("SoundGroup")
	group.Name = WeatherFxConfig.SoundGroupName
	group.Archivable = false
	group.Parent = SoundService
	soundGroup = group
	return group
end

local function fadeTo(sound: Sound, volume: number): Tween
	local info = TweenInfo.new(WeatherFxConfig.SoundFadeTime, Enum.EasingStyle.Sine)
	local tween = TweenService:Create(sound, info, { Volume = volume })
	tween:Play()
	return tween
end

local function createSound(soundId: string, volume: number): Sound
	local group = getGroup()
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume
	sound.SoundGroup = group
	sound.Parent = group
	return sound
end

function WeatherSounds.StartAmbient(profiles: { WeatherFxTypes.AmbientSoundProfile })
	WeatherSounds.StopAmbient()
	for _, profile in profiles do
		local sound = createSound(profile.SoundId, SILENT)
		sound.Looped = true
		sound:Play()
		fadeTo(sound, profile.Volume)
		table.insert(ambients, sound)
	end
end

function WeatherSounds.StopAmbient()
	for _, sound in ambients do
		fadeTo(sound, SILENT).Completed:Once(function()
			sound:Destroy()
		end)
	end
	table.clear(ambients)
end

function WeatherSounds.PlayOneShot(soundIds: { string }, volume: number)
	if #soundIds == 0 then
		return
	end
	local sound = createSound(soundIds[random:NextInteger(1, #soundIds)], volume)
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	sound:Play()
end

return WeatherSounds
